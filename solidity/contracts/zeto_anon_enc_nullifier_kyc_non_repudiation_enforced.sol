pragma solidity ^0.8.27;

import {Commonlib} from "./lib/common/common.sol";
import {IGroth16Verifier} from "./lib/interfaces/izeto_verifier.sol";
import {IZetoInitializable} from "./lib/interfaces/izeto_initializable.sol";
import {IZetoEnforced} from "./lib/interfaces/izeto_enforced.sol";
import {IZetoNullifierStorageView} from "./lib/interfaces/izeto_nullifier_storage_view.sol";
import {Zeto_AnonNullifier} from "./zeto_anon_nullifier.sol";
import {Registry} from "./lib/registry.sol";
import {ComplianceRootRegistry} from "./lib/compliance_root_registry.sol";

/// @title Zeto AENKNR-E: anonymous encrypted nullifier token with KYC,
///   non-repudiation, compliance enforcement, and enforcer-initiated seizure
/// @dev Four proof paths, each backed by a distinct Groth16 circuit:
///   - transfer: owner spends UTXOs, both owner + enforcement nullifiers marked
///   - deposit:  mint UTXOs from ERC-20, no nullifiers
///   - withdraw: burn UTXOs to ERC-20, both owner + enforcement nullifiers marked
///   - forcedTransfer: enforcer seizes frozen-owner UTXOs, only enforcement nullifiers marked
///
///   Extends Zeto_AnonNullifier directly (not Zeto_AnonEncNullifierNonRepudiation)
///   because every function the intermediate parents provide is either private,
///   fully overridden here, or redundant. Each circuit has a different proof ABI
///   and signal ordering, making the parent's hook-based extension model
///   (extraInputs) incompatible. See AENKNR-E_ARCHITECTURAL_REVIEW.md.
///
///   Each proof path has its own struct + decoder because each circuit encodes
///   different fields in its proof bytes. Structs keep decoded data in a single
///   memory pointer (1 stack slot) instead of N locals — required to stay within
///   the Yul IR stack depth limit.
contract Zeto_AnonEncNullifierKycNonRepudiationEnforced is
    Zeto_AnonNullifier,
    Registry,
    ComplianceRootRegistry,
    IZetoEnforced
{
    struct _DecodedProof_Transfer {
        uint256 root;
        uint256[] enforcementNullifiers;
        uint256 encryptionNonce;
        uint256[2] ecdhPublicKey;
        uint256[] encryptedValuesForReceiver;
        uint256[] encryptedValuesForArbiter;
        uint256[] encryptedValuesForEnforcer;
    }

    // No root or nullifiers — deposit mints new UTXOs without spending existing ones.
    struct _DecodedProof_Deposit {
        uint256 encryptionNonce;
        uint256[2] ecdhPublicKey;
        uint256[] encryptedValuesForReceiver;
        uint256[] encryptedValuesForArbiter;
        uint256[] encryptedValuesForEnforcer;
    }

    // No arbiter/receiver ciphertexts — the withdrawal amount and ERC-20 destination
    // are already public on-chain. Only the change output preimage is encrypted to
    // the enforcer so they can seize it if needed.
    struct _DecodedProof_Withdraw {
        uint256 root;
        uint256[] enforcementNullifiers;
        uint256 encryptionNonce;
        uint256[2] ecdhPublicKey;
        uint256[] encryptedValuesForEnforcer;
    }

    // enabledInputs is in the proof (not derived from nullifier padding) because
    // the forced transfer path has no owner nullifiers to derive them from.
    struct _DecodedProof_ForcedTransfer {
        uint256[] enforcementNullifiers;
        uint256 root;
        uint256[] enabledInputs;
        uint256 encryptionNonce;
        uint256[2] ecdhPublicKey;
        uint256[] encryptedValuesForReceiver;
        uint256[] encryptedValuesForArbiter;
        uint256[] encryptedValuesForEnforcer;
    }

    // Bridges enforcement nullifiers from constructPublicInputs (where they're
    // decoded) to processInputsAndOutputs (where they're marked spent). Needed
    // because the ZetoFungible.transfer() flow calls these as separate hooks
    // with no shared parameter for proof bytes.
    uint256[] private _pendingEnfNullifiers;

    IGroth16Verifier private _forcedTransferVerifier;
    // Rotatable key — arbiterKeyId increments on each rotation so off-chain
    // indexers can associate ciphertexts with the correct decryption key.
    uint256[2] private _arbiterPub;
    uint256 private _arbiterKeyId;
    // Set-once — rotating the enforcer key would orphan all existing enforcement
    // nullifiers (they're derived via ECDH with the enforcer key).
    uint256[2] private _enforcerPub;
    bool private _enforcerSet;
    // Separate from owner nullifiers (tracked in external NullifierStorage).
    // A UTXO is considered spent if EITHER its owner OR enforcement nullifier
    // has been marked — see isSpent() for the OR semantics.
    mapping(uint256 => bool) private _enforcementNullifierSpent;

    // Initialization

    function initialize(
        string calldata name,
        string calldata symbol,
        address initialOwner,
        IZetoInitializable.VerifiersInfo calldata verifiers
    ) public override initializer {
        __ZetoAnonEncNullifierKycNonRepudiationEnforced_init(
            name,
            symbol,
            initialOwner,
            verifiers
        );
    }

    function __ZetoAnonEncNullifierKycNonRepudiationEnforced_init(
        string calldata name_,
        string calldata symbol_,
        address initialOwner,
        IZetoInitializable.VerifiersInfo calldata verifiers
    ) internal onlyInitializing {
        __Registry_init();
        __ComplianceRootRegistry_init();
        __ZetoAnonNullifier_init(name_, symbol_, initialOwner, verifiers);
        _forcedTransferVerifier = verifiers.forcedTransferVerifier;
    }

    // Admin API

    function setArbiter(uint256[2] memory newKey) public onlyOwner {
        _arbiterPub = newKey;
        _arbiterKeyId++;
        emit ArbiterUpdated(newKey, _arbiterKeyId);
    }

    function getArbiter() public view returns (uint256[2] memory) {
        return _arbiterPub;
    }

    function getArbiterKeyId() public view returns (uint256) {
        return _arbiterKeyId;
    }

    function setEnforcer(uint256[2] memory newKey) public onlyOwner {
        if (_enforcerSet) revert EnforcerAlreadySet();
        _enforcerPub = newKey;
        _enforcerSet = true;
        emit EnforcerSet(newKey);
    }

    function getEnforcer() public view returns (uint256[2] memory) {
        return _enforcerPub;
    }

    function _requireEnforcerSet() internal view {
        if (!_enforcerSet) revert EnforcerNotSet();
    }

    // Hook overrides
    //
    // Called by ZetoFungible.transfer(), deposit(), withdraw().
    // Each override fully replaces the parent's proof assembly because our circuits
    // have different ABIs and interleaved signal orderings that are incompatible
    // with the parent's extraInputs() hook.

    // Transfer circuit public signal ordering (58 elements, 0-indexed):
    //   [0-1]    ecdhPublicKey[2]
    //   [2-9]    encryptedValuesForReceiver[8]
    //   [10-25]  encryptedValuesForArbiter[16]
    //   [26-41]  encryptedValuesForEnforcer[16]
    //   [42-43]  ownerNullifiers[2]
    //   [44-45]  enforcementNullifiers[2]
    //   [46]     utxosRoot
    //   [47-48]  enabledInputs[2]
    //   [49]     identitiesRoot
    //   [50]     complianceRoot
    //   [51-52]  outputCommitments[2]
    //   [53]     encryptionNonce
    //   [54-55]  arbiterPublicKey[2]
    //   [56-57]  enforcerPublicKey[2]
    function constructPublicInputs(
        uint256[] memory nullifiers,
        uint256[] memory outputs,
        bytes memory proof,
        bool
    )
        internal
        virtual
        override
        returns (uint256[] memory, Commonlib.Proof memory)
    {
        _requireEnforcerSet();
        (
            _DecodedProof_Transfer memory dp,
            Commonlib.Proof memory proofStruct
        ) = _decodeProof_Transfer(proof);
        _pendingEnfNullifiers = dp.enforcementNullifiers;
        _checkEnforcementNullifiersUnspent(dp.enforcementNullifiers);

        uint256[] memory pi = new uint256[](58);
        uint256 idx = _fillCiphertexts(
            pi, 0, dp.ecdhPublicKey,
            dp.encryptedValuesForReceiver,
            dp.encryptedValuesForArbiter,
            dp.encryptedValuesForEnforcer
        );
        _fillTransferSignals(pi, idx, nullifiers, outputs, dp);
        return (pi, proofStruct);
    }

    // Deposit circuit public signal ordering (52 elements, 0-indexed):
    //   [0]      amount (circuit output "out" = sum of output values)
    //   [1-2]    ecdhPublicKey[2]
    //   [3-10]   encryptedValuesForReceiver[8]
    //   [11-26]  encryptedValuesForArbiter[16]
    //   [27-42]  encryptedValuesForEnforcer[16]
    //   [43-44]  outputCommitments[2]
    //   [45]     identitiesRoot
    //   [46]     complianceRoot
    //   [47]     encryptionNonce
    //   [48-49]  arbiterPublicKey[2]
    //   [50-51]  enforcerPublicKey[2]
    function constructPublicInputsForDeposit(
        uint256 amount,
        uint256[] memory outputs,
        bytes memory proof
    )
        public
        virtual
        override
        returns (uint256[] memory, Commonlib.Proof memory)
    {
        _requireEnforcerSet();
        (
            _DecodedProof_Deposit memory dp,
            Commonlib.Proof memory proofStruct
        ) = _decodeProof_Deposit(proof);

        uint256[] memory pi = new uint256[](52);
        pi[0] = amount;
        uint256 idx = _fillCiphertexts(
            pi, 1, dp.ecdhPublicKey,
            dp.encryptedValuesForReceiver,
            dp.encryptedValuesForArbiter,
            dp.encryptedValuesForEnforcer
        );
        for (uint256 i = 0; i < outputs.length; ++i) pi[idx++] = outputs[i];
        pi[idx++] = getIdentitiesRoot();
        pi[idx++] = getComplianceRoot();
        pi[idx++] = dp.encryptionNonce;
        pi[idx++] = _arbiterPub[0];
        pi[idx++] = _arbiterPub[1];
        pi[idx++] = _enforcerPub[0];
        pi[idx++] = _enforcerPub[1];
        return (pi, proofStruct);
    }

    // Withdraw circuit public signal ordering (20 elements, 0-indexed):
    //   [0-1]    ecdhPublicKey[2]
    //   [2-5]    encryptedValuesForEnforcer[4]
    //   [6]      amount
    //   [7-8]    ownerNullifiers[2]
    //   [9-10]   enforcementNullifiers[2]
    //   [11]     outputCommitments[1]
    //   [12]     utxosRoot
    //   [13]     identitiesRoot
    //   [14]     complianceRoot
    //   [15-16]  enabledInputs[2]
    //   [17]     encryptionNonce
    //   [18-19]  enforcerPublicKey[2]
    function constructPublicInputsForWithdraw(
        uint256 amount,
        uint256[] memory nullifiers,
        uint256 output,
        bytes memory proof
    )
        internal
        virtual
        override
        returns (uint256[] memory, Commonlib.Proof memory)
    {
        _requireEnforcerSet();
        (
            _DecodedProof_Withdraw memory dp,
            Commonlib.Proof memory proofStruct
        ) = _decodeProof_Withdraw(proof);
        _pendingEnfNullifiers = dp.enforcementNullifiers;
        _checkEnforcementNullifiersUnspent(dp.enforcementNullifiers);

        uint256[] memory pi = new uint256[](20);
        pi[0] = dp.ecdhPublicKey[0];
        pi[1] = dp.ecdhPublicKey[1];
        uint256 idx = 2;
        // Withdraw uses only enforcer ciphertext (no _fillCiphertexts — different layout)
        uint256[] memory arr = dp.encryptedValuesForEnforcer;
        for (uint256 i = 0; i < arr.length; ++i) pi[idx++] = arr[i];
        pi[idx++] = amount;
        for (uint256 i = 0; i < nullifiers.length; ++i)
            pi[idx++] = nullifiers[i];
        arr = dp.enforcementNullifiers;
        for (uint256 i = 0; i < arr.length; ++i) pi[idx++] = arr[i];
        pi[idx++] = output;
        pi[idx++] = dp.root;
        pi[idx++] = getIdentitiesRoot();
        pi[idx++] = getComplianceRoot();
        for (uint256 i = 0; i < nullifiers.length; ++i)
            pi[idx++] = (nullifiers[i] == 0) ? 0 : 1;
        pi[idx++] = dp.encryptionNonce;
        pi[idx++] = _enforcerPub[0];
        pi[idx++] = _enforcerPub[1];
        return (pi, proofStruct);
    }

    /// @dev Extends the parent to also mark enforcement nullifiers as spent.
    ///   Owner nullifiers are marked by super (via external NullifierStorage).
    function processInputsAndOutputs(
        uint256[] memory inputs,
        uint256[] memory outputs,
        bool inputsLocked
    ) internal virtual override {
        super.processInputsAndOutputs(inputs, outputs, inputsLocked);
        for (uint256 i = 0; i < _pendingEnfNullifiers.length; ++i) {
            if (_pendingEnfNullifiers[i] != 0)
                _enforcementNullifierSpent[_pendingEnfNullifiers[i]] = true;
        }
    }

    /// @dev Re-decodes proof bytes from memory rather than reading from storage.
    ///   The proof parameter is still in memory from the transfer() call, so
    ///   a second abi.decode is cheaper than round-tripping through SSTORE/SLOAD.
    function emitTransferEvent(
        uint256[] memory nullifiers,
        uint256[] memory outputs,
        bytes memory proof,
        bytes memory data
    ) internal virtual override {
        (_DecodedProof_Transfer memory dp, ) = _decodeProof_Transfer(proof);
        emit UTXOTransferNonRepudiationEnforced(
            nullifiers,
            outputs,
            dp.enforcementNullifiers,
            dp.encryptionNonce,
            dp.ecdhPublicKey,
            dp.encryptedValuesForReceiver,
            dp.encryptedValuesForArbiter,
            dp.encryptedValuesForEnforcer,
            _arbiterKeyId,
            msg.sender,
            data
        );
    }

    // Public API

    /// @dev Standalone seizure path — does NOT go through ZetoFungible.transfer()
    ///   because that flow requires owner nullifiers (which the enforcer cannot
    ///   compute without the owner's private key). Instead, this function handles
    ///   the full lifecycle: validate, verify, spend enforcement nullifiers, mint outputs.
    //
    // Forced transfer circuit public signal ordering (56 elements, 0-indexed):
    //   [0-1]    ecdhPublicKey[2]
    //   [2-9]    encryptedValuesForReceiver[8]
    //   [10-25]  encryptedValuesForArbiter[16]
    //   [26-41]  encryptedValuesForEnforcer[16]
    //   [42-43]  enforcementNullifiers[2]
    //   [44-45]  outputCommitments[2]
    //   [46]     utxosRoot
    //   [47]     identitiesRoot
    //   [48]     complianceRoot
    //   [49-50]  enabledInputs[2]
    //   [51-52]  enforcerPublicKey[2]
    //   [53]     encryptionNonce
    //   [54-55]  arbiterPublicKey[2]
    function forcedTransfer(
        uint256[] calldata outputs,
        bytes calldata proof,
        bytes calldata data
    ) public onlyOwner {
        _requireEnforcerSet();
        validateOutputs(outputs);
        (
            _DecodedProof_ForcedTransfer memory dp,
            Commonlib.Proof memory proofStruct
        ) = _decodeProof_ForcedTransfer(proof);
        validateRoot(dp.root, false);
        _checkEnforcementNullifiersUnspent(dp.enforcementNullifiers);

        uint256[] memory pi = new uint256[](56);
        uint256 idx = _fillCiphertexts(
            pi, 0, dp.ecdhPublicKey,
            dp.encryptedValuesForReceiver,
            dp.encryptedValuesForArbiter,
            dp.encryptedValuesForEnforcer
        );
        uint256[] memory arr = dp.enforcementNullifiers;
        for (uint256 i = 0; i < arr.length; ++i) pi[idx++] = arr[i];
        for (uint256 i = 0; i < outputs.length; ++i) pi[idx++] = outputs[i];
        pi[idx++] = dp.root;
        pi[idx++] = getIdentitiesRoot();
        pi[idx++] = getComplianceRoot();
        arr = dp.enabledInputs;
        for (uint256 i = 0; i < arr.length; ++i) pi[idx++] = arr[i];
        pi[idx++] = _enforcerPub[0];
        pi[idx++] = _enforcerPub[1];
        pi[idx++] = dp.encryptionNonce;
        pi[idx++] = _arbiterPub[0];
        pi[idx++] = _arbiterPub[1];

        require(
            _forcedTransferVerifier.verify(
                proofStruct.pA,
                proofStruct.pB,
                proofStruct.pC,
                pi
            ),
            "Invalid proof"
        );

        // Only enforcement nullifiers — no owner nullifiers in the seizure path
        arr = dp.enforcementNullifiers;
        for (uint256 i = 0; i < arr.length; ++i) {
            if (arr[i] != 0) _enforcementNullifierSpent[arr[i]] = true;
        }
        processOutputs(outputs);

        emit UTXOForcedTransferEnforced(
            dp.enforcementNullifiers,
            outputs,
            dp.encryptionNonce,
            dp.ecdhPublicKey,
            dp.encryptedValuesForReceiver,
            dp.encryptedValuesForArbiter,
            dp.encryptedValuesForEnforcer,
            _arbiterKeyId,
            msg.sender,
            data
        );
    }

    /// @dev Reads from external NullifierStorage (owner nullifiers live there,
    ///   not in this contract). Public so isSpent() can call it internally.
    function ownerNullifierSpent(uint256 n) public view returns (bool) {
        return
            IZetoNullifierStorageView(address(_storage)).nullifierSpent(n);
    }

    function enforcementNullifierSpent(
        uint256 n
    ) external view returns (bool) {
        return _enforcementNullifierSpent[n];
    }

    /// @dev OR semantics: spent if either owner OR enforcement nullifier is marked.
    ///   Wallets should call this before attempting an owner spend — if the
    ///   enforcement nullifier is already spent (via forcedTransfer), the UTXO
    ///   has been seized and an owner-spend proof would pass verification but
    ///   fail at processInputs (double-spend of the same economic value).
    function isSpent(
        uint256 ownerN,
        uint256 enfN
    ) external view returns (bool) {
        return ownerNullifierSpent(ownerN) || _enforcementNullifierSpent[enfN];
    }

    // Private helpers

    function _decodeProof_Transfer(
        bytes memory proof
    )
        private
        pure
        returns (
            _DecodedProof_Transfer memory dp,
            Commonlib.Proof memory proofStruct
        )
    {
        (
            dp.root,
            dp.enforcementNullifiers,
            dp.encryptionNonce,
            dp.ecdhPublicKey,
            dp.encryptedValuesForReceiver,
            dp.encryptedValuesForArbiter,
            dp.encryptedValuesForEnforcer,
            proofStruct
        ) = abi.decode(
            proof,
            (
                uint256,
                uint256[],
                uint256,
                uint256[2],
                uint256[],
                uint256[],
                uint256[],
                Commonlib.Proof
            )
        );
    }

    function _decodeProof_Deposit(
        bytes memory proof
    )
        private
        pure
        returns (
            _DecodedProof_Deposit memory dp,
            Commonlib.Proof memory proofStruct
        )
    {
        (
            dp.encryptionNonce,
            dp.ecdhPublicKey,
            dp.encryptedValuesForReceiver,
            dp.encryptedValuesForArbiter,
            dp.encryptedValuesForEnforcer,
            proofStruct
        ) = abi.decode(
            proof,
            (
                uint256,
                uint256[2],
                uint256[],
                uint256[],
                uint256[],
                Commonlib.Proof
            )
        );
    }

    function _decodeProof_Withdraw(
        bytes memory proof
    )
        private
        pure
        returns (
            _DecodedProof_Withdraw memory dp,
            Commonlib.Proof memory proofStruct
        )
    {
        (
            dp.root,
            dp.enforcementNullifiers,
            dp.encryptionNonce,
            dp.ecdhPublicKey,
            dp.encryptedValuesForEnforcer,
            proofStruct
        ) = abi.decode(
            proof,
            (
                uint256,
                uint256[],
                uint256,
                uint256[2],
                uint256[],
                Commonlib.Proof
            )
        );
    }

    function _decodeProof_ForcedTransfer(
        bytes memory proof
    )
        private
        pure
        returns (
            _DecodedProof_ForcedTransfer memory dp,
            Commonlib.Proof memory proofStruct
        )
    {
        (
            dp.enforcementNullifiers,
            dp.root,
            dp.enabledInputs,
            dp.encryptionNonce,
            dp.ecdhPublicKey,
            dp.encryptedValuesForReceiver,
            dp.encryptedValuesForArbiter,
            dp.encryptedValuesForEnforcer,
            proofStruct
        ) = abi.decode(
            proof,
            (
                uint256[],
                uint256,
                uint256[],
                uint256,
                uint256[2],
                uint256[],
                uint256[],
                uint256[],
                Commonlib.Proof
            )
        );
    }

    /// @dev Fills ecdhPublicKey[2] + receiver + arbiter + enforcer ciphertexts
    ///   into pi starting at startIdx. Shared across transfer (0), deposit (1,
    ///   after amount), and forced transfer (0). Withdraw has a different
    ///   ciphertext layout (enforcer-only) and fills inline.
    function _fillCiphertexts(
        uint256[] memory pi,
        uint256 startIdx,
        uint256[2] memory ecdhPub,
        uint256[] memory encReceiver,
        uint256[] memory encArbiter,
        uint256[] memory encEnforcer
    ) private pure returns (uint256 idx) {
        pi[startIdx] = ecdhPub[0];
        pi[startIdx + 1] = ecdhPub[1];
        idx = startIdx + 2;
        for (uint256 i = 0; i < encReceiver.length; ++i)
            pi[idx++] = encReceiver[i];
        for (uint256 i = 0; i < encArbiter.length; ++i)
            pi[idx++] = encArbiter[i];
        for (uint256 i = 0; i < encEnforcer.length; ++i)
            pi[idx++] = encEnforcer[i];
    }

    /// @dev Split from constructPublicInputs to stay within the Yul IR stack
    ///   depth limit. The transfer path's trailing signals include storage reads
    ///   (roots, authority keys) that push past the limit when combined with the
    ///   ciphertext fills in a single function body.
    function _fillTransferSignals(
        uint256[] memory pi,
        uint256 idx,
        uint256[] memory nullifiers,
        uint256[] memory outputs,
        _DecodedProof_Transfer memory dp
    ) private view {
        for (uint256 i = 0; i < nullifiers.length; ++i)
            pi[idx++] = nullifiers[i];
        uint256[] memory enfN = dp.enforcementNullifiers;
        for (uint256 i = 0; i < enfN.length; ++i) pi[idx++] = enfN[i];
        pi[idx++] = dp.root;
        for (uint256 i = 0; i < nullifiers.length; ++i)
            pi[idx++] = (nullifiers[i] == 0) ? 0 : 1;
        pi[idx++] = getIdentitiesRoot();
        pi[idx++] = getComplianceRoot();
        for (uint256 i = 0; i < outputs.length; ++i) pi[idx++] = outputs[i];
        pi[idx++] = dp.encryptionNonce;
        pi[idx++] = _arbiterPub[0];
        pi[idx++] = _arbiterPub[1];
        pi[idx++] = _enforcerPub[0];
        pi[idx++] = _enforcerPub[1];
    }

    function _checkEnforcementNullifiersUnspent(
        uint256[] memory enfNullifiers
    ) internal view {
        for (uint256 i = 0; i < enfNullifiers.length; ++i) {
            if (enfNullifiers[i] == 0) continue;
            if (_enforcementNullifierSpent[enfNullifiers[i]])
                revert EnforcementNullifierAlreadySpent(enfNullifiers[i]);
        }
    }
}
