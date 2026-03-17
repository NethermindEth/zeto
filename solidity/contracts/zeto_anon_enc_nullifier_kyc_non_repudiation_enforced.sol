pragma solidity ^0.8.27;

import {Commonlib} from "./lib/common/common.sol";
import {IZetoInitializable} from "./lib/interfaces/izeto_initializable.sol";
import {Zeto_AnonNullifier} from "./zeto_anon_nullifier.sol";
import {Registry} from "./lib/registry.sol";
import {ComplianceRootRegistry} from "./lib/compliance_root_registry.sol";

/// @title A Zeto based fungible token with anonymity, encryption, nullifiers,
///   KYC, compliance enforcement, non-repudiation, and enforcer-initiated seizure
/// @author Kaleido, Inc.
/// @dev Extends the base nullifier variant with:
///        - KYC registry membership enforcement via identities SMT
///        - Compliance status enforcement (ACTIVE/FROZEN) via compliance SMT
///        - Dual-authority non-repudiation (arbiter + enforcer ciphertexts)
///        - Enforcement nullifiers for enforcer-initiated forced transfers
///        - forcedTransfer path for seizure of frozen user UTXOs
contract Zeto_AnonEncNullifierKycNonRepudiationEnforced is
    Zeto_AnonNullifier,
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

    struct _DecodedProof_Transfer {
        uint256 root;
        uint256[] enforcementNullifiers;
        uint256 encryptionNonce;
        uint256[2] ecdhPublicKey;
        uint256[] encryptedValuesForReceiver;
        uint256[] encryptedValuesForArbiter;
        uint256[] encryptedValuesForEnforcer;
    }

    struct _DecodedProof_Deposit {
        uint256 encryptionNonce;
        uint256[2] ecdhPublicKey;
        uint256[] encryptedValuesForReceiver;
        uint256[] encryptedValuesForArbiter;
        uint256[] encryptedValuesForEnforcer;
    }

    struct _DecodedProof_Withdraw {
        uint256 root;
        uint256[] enforcementNullifiers;
        uint256 encryptionNonce;
        uint256[2] ecdhPublicKey;
        uint256[] encryptedValuesForEnforcer;
    }

    uint256[] private _pendingEnfNullifiers;

    uint256[2] private _arbiterPub;
    uint256 private _arbiterKeyId;
    uint256[2] private _enforcerPub;
    bool private _enforcerSet;
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
        __ZetoAnonNullifier_init(name_, symbol_, initialOwner, verifiers);
    }

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
        uint256 idx = _fillCiphertexts(pi, dp);
        _fillSignals(pi, idx, nullifiers, outputs, dp);
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
        pi[1] = dp.ecdhPublicKey[0];
        pi[2] = dp.ecdhPublicKey[1];
        uint256 idx = 3;
        uint256[] memory arr = dp.encryptedValuesForReceiver;
        for (uint256 i = 0; i < arr.length; ++i) pi[idx++] = arr[i];
        arr = dp.encryptedValuesForArbiter;
        for (uint256 i = 0; i < arr.length; ++i) pi[idx++] = arr[i];
        arr = dp.encryptedValuesForEnforcer;
        for (uint256 i = 0; i < arr.length; ++i) pi[idx++] = arr[i];
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

    function forcedTransfer(
        uint256[] calldata,
        bytes calldata,
        bytes calldata
    ) public onlyOwner {
        // TODO
    }

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

    function _fillCiphertexts(
        uint256[] memory pi,
        _DecodedProof_Transfer memory dp
    ) private pure returns (uint256 idx) {
        pi[0] = dp.ecdhPublicKey[0];
        pi[1] = dp.ecdhPublicKey[1];
        idx = 2;
        uint256[] memory arr = dp.encryptedValuesForReceiver;
        for (uint256 i = 0; i < arr.length; ++i) pi[idx++] = arr[i];
        arr = dp.encryptedValuesForArbiter;
        for (uint256 i = 0; i < arr.length; ++i) pi[idx++] = arr[i];
        arr = dp.encryptedValuesForEnforcer;
        for (uint256 i = 0; i < arr.length; ++i) pi[idx++] = arr[i];
    }

    function _fillSignals(
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
