pragma solidity ^0.8.27;

import {Commonlib} from "./lib/common/common.sol";
import {IZetoInitializable} from "./lib/interfaces/izeto_initializable.sol";
import {Zeto_AnonEncNullifierNonRepudiation} from "./zeto_anon_enc_nullifier_non_repudiation.sol";
import {Registry} from "./lib/registry.sol";
import {ComplianceRootRegistry} from "./lib/compliance_root_registry.sol";

/// @title A Zeto based fungible token with anonymity, encryption, nullifiers,
///   KYC, compliance enforcement, non-repudiation, and enforcer-initiated seizure
/// @author Kaleido, Inc.
/// @dev Extends the non-repudiation variant with:
///        - KYC registry membership enforcement via identities SMT
///        - Compliance status enforcement (ACTIVE/FROZEN) via compliance SMT
///        - Dual-authority non-repudiation (arbiter + enforcer ciphertexts)
///        - Enforcement nullifiers for enforcer-initiated forced transfers
///        - forcedTransfer path for seizure of frozen user UTXOs
contract Zeto_AnonEncNullifierKycNonRepudiationEnforced is
    Zeto_AnonEncNullifierNonRepudiation,
    Registry,
    ComplianceRootRegistry
{
    error EnforcerAlreadySet();
    error EnforcerNotSet();
    error EnforcementNullifierAlreadySpent(uint256 nullifier);

    event ArbiterUpdated(uint256[2] newKey, uint256 keyId);
    event EnforcerSet(uint256[2] newKey);
    event UTXOTransferNonRepudiationEnforced(
        uint256[] inputs,
        uint256[] outputs,
        uint256[] enforcementNullifiers,
        uint256 encryptionNonce,
        uint256[2] ecdhPublicKey,
        uint256[] encryptedValuesForReceiver,
        uint256[] encryptedValuesForArbiter,
        uint256[] encryptedValuesForEnforcer,
        uint256 arbiterKeyId,
        address indexed submitter,
        bytes data
    );

    struct _DecodedProof_Enforced {
        uint256 root;
        uint256[] enforcementNullifiers;
        uint256 encryptionNonce;
        uint256[2] ecdhPublicKey;
        uint256[] encryptedValuesForReceiver;
        uint256[] encryptedValuesForArbiter;
        uint256[] encryptedValuesForEnforcer;
    }

    // only the enforcement nullifiers need to survive across the
    // constructPublicInputs → processInputsAndOutputs boundary;
    // all other decoded proof fields are passed via memory struct
    uint256[] private _pendingEnfNullifiers;

    // the arbiter public key and rotation counter;
    // shadows the parent's private arbiter variable so that
    // this contract owns the canonical copy for reads
    uint256[2] private _arbiterPub;
    uint256 private _arbiterKeyId;
    // the enforcer public key (set-once for this release)
    uint256[2] private _enforcerPub;
    bool private _enforcerSet;
    // enforcement nullifier spend tracking (local to this contract;
    // owner nullifiers are in the external NullifierStorage via _storage)
    mapping(uint256 => bool) private _enforcementNullifierSpent;

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
        __ZetoAnonEncNullifierNonRepudiation_init(
            name_,
            symbol_,
            initialOwner,
            verifiers
        );
    }

    function setArbiter(
        uint256[2] memory newKey
    ) public override onlyOwner {
        super.setArbiter(newKey);
        _arbiterPub = newKey;
        _arbiterKeyId++;
        emit ArbiterUpdated(newKey, _arbiterKeyId);
    }

    function getArbiter()
        public
        view
        override
        returns (uint256[2] memory)
    {
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

    // Verifier public signal ordering (0-indexed publicInputs[]):
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
        bool inputsLocked
    )
        internal
        virtual
        override
        returns (uint256[] memory, Commonlib.Proof memory)
    {
        _requireEnforcerSet();
        (
            _DecodedProof_Enforced memory dp,
            Commonlib.Proof memory proofStruct
        ) = decodeProof_Enforced(proof);
        // persist only what processInputsAndOutputs needs later
        _pendingEnfNullifiers = dp.enforcementNullifiers;
        _checkEnforcementNullifiersUnspent(dp.enforcementNullifiers);

        uint256 size = _calculatePublicInputsSize_Enforced(
            nullifiers,
            outputs,
            dp
        );
        uint256[] memory publicInputs = new uint256[](size);
        uint256 piIndex = _fillEcdhAndReceiver_Enforced(publicInputs, dp);
        piIndex = _fillAuthorityCiphertexts_Enforced(
            publicInputs,
            piIndex,
            dp
        );
        _fillSignalsAndKeys_Enforced(
            publicInputs,
            piIndex,
            nullifiers,
            outputs,
            dp
        );

        return (publicInputs, proofStruct);
    }

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
        return super.constructPublicInputsForDeposit(amount, outputs, proof);
    }

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
        return
            super.constructPublicInputsForWithdraw(
                amount,
                nullifiers,
                output,
                proof
            );
    }

    function processInputsAndOutputs(
        uint256[] memory inputs,
        uint256[] memory outputs,
        bool inputsLocked
    ) internal virtual override {
        super.processInputsAndOutputs(inputs, outputs, inputsLocked);
        _markEnforcementNullifiersSpent(_pendingEnfNullifiers);
    }

    function emitTransferEvent(
        uint256[] memory nullifiers,
        uint256[] memory outputs,
        bytes memory proof,
        bytes memory data
    ) internal virtual override {
        // re-decode from proof bytes (memory) to avoid reading
        // many storage variables; mirrors the parent's pattern
        (_DecodedProof_Enforced memory dp, ) = decodeProof_Enforced(proof);
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

    function extraInputs()
        internal
        view
        virtual
        override
        returns (uint256[] memory)
    {
        uint256[] memory extras = new uint256[](1);
        extras[0] = getIdentitiesRoot();
        return extras;
    }

    function extraInputsForDeposit()
        internal
        view
        virtual
        override
        returns (uint256[] memory)
    {
        uint256[] memory extras = new uint256[](1);
        extras[0] = getIdentitiesRoot();
        return extras;
    }

    function forcedTransfer(
        uint256[] calldata outputs,
        bytes calldata proof,
        bytes calldata data
    ) public onlyOwner {
        // Implementation in P8.6
    }

    function decodeProof_Enforced(
        bytes memory proof
    )
        private
        pure
        returns (
            _DecodedProof_Enforced memory dp,
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

    function _checkEnforcementNullifiersUnspent(
        uint256[] memory enfNullifiers
    ) internal view {
        for (uint256 i = 0; i < enfNullifiers.length; i++) {
            if (enfNullifiers[i] == 0) continue;
            if (_enforcementNullifierSpent[enfNullifiers[i]]) {
                revert EnforcementNullifierAlreadySpent(enfNullifiers[i]);
            }
        }
    }

    function _markEnforcementNullifiersSpent(
        uint256[] storage enfNullifiers
    ) internal {
        for (uint256 i = 0; i < enfNullifiers.length; i++) {
            if (enfNullifiers[i] == 0) continue;
            _enforcementNullifierSpent[enfNullifiers[i]] = true;
        }
    }

    function _calculatePublicInputsSize_Enforced(
        uint256[] memory nullifiers,
        uint256[] memory outputs,
        _DecodedProof_Enforced memory dp
    ) internal pure returns (uint256) {
        return
            dp.ecdhPublicKey.length +
            dp.encryptedValuesForReceiver.length +
            dp.encryptedValuesForArbiter.length +
            dp.encryptedValuesForEnforcer.length +
            nullifiers.length +
            dp.enforcementNullifiers.length +
            1 + // utxosRoot
            nullifiers.length + // enabledInputs
            2 + // identitiesRoot, complianceRoot
            outputs.length +
            1 + // encryptionNonce
            2 + // arbiterPublicKey
            2; // enforcerPublicKey
    }

    function _fillEcdhAndReceiver_Enforced(
        uint256[] memory publicInputs,
        _DecodedProof_Enforced memory dp
    ) internal pure returns (uint256) {
        publicInputs[0] = dp.ecdhPublicKey[0];
        publicInputs[1] = dp.ecdhPublicKey[1];
        // cache to avoid struct traversal inside the loop
        uint256[] memory enc = dp.encryptedValuesForReceiver;
        for (uint256 i = 0; i < enc.length; ++i) {
            publicInputs[2 + i] = enc[i];
        }
        return 2 + enc.length;
    }

    function _fillAuthorityCiphertexts_Enforced(
        uint256[] memory publicInputs,
        uint256 piIndex,
        _DecodedProof_Enforced memory dp
    ) internal pure returns (uint256) {
        uint256[] memory arb = dp.encryptedValuesForArbiter;
        for (uint256 i = 0; i < arb.length; ++i) {
            publicInputs[piIndex++] = arb[i];
        }
        uint256[] memory enf = dp.encryptedValuesForEnforcer;
        for (uint256 i = 0; i < enf.length; ++i) {
            publicInputs[piIndex++] = enf[i];
        }
        return piIndex;
    }

    function _fillSignalsAndKeys_Enforced(
        uint256[] memory publicInputs,
        uint256 piIndex,
        uint256[] memory nullifiers,
        uint256[] memory outputs,
        _DecodedProof_Enforced memory dp
    ) internal view {
        // owner nullifiers
        for (uint256 i = 0; i < nullifiers.length; i++) {
            publicInputs[piIndex++] = nullifiers[i];
        }
        // enforcement nullifiers
        uint256[] memory enfN = dp.enforcementNullifiers;
        for (uint256 i = 0; i < enfN.length; i++) {
            publicInputs[piIndex++] = enfN[i];
        }
        publicInputs[piIndex++] = dp.root;
        // enabled flags
        for (uint256 i = 0; i < nullifiers.length; i++) {
            publicInputs[piIndex++] = (nullifiers[i] == 0) ? 0 : 1;
        }
        publicInputs[piIndex++] = getIdentitiesRoot();
        publicInputs[piIndex++] = getComplianceRoot();
        // output commitments
        for (uint256 i = 0; i < outputs.length; i++) {
            publicInputs[piIndex++] = outputs[i];
        }
        publicInputs[piIndex++] = dp.encryptionNonce;
        publicInputs[piIndex++] = _arbiterPub[0];
        publicInputs[piIndex++] = _arbiterPub[1];
        publicInputs[piIndex++] = _enforcerPub[0];
        publicInputs[piIndex++] = _enforcerPub[1];
    }
}