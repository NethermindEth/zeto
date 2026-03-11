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

    event ArbiterUpdated(uint256[2] newKey, uint256 keyId);
    event EnforcerSet(uint256[2] newKey);

    // the arbiter public key and rotation counter;
    // shadows the parent's private arbiter variable so that
    // this contract owns the canonical copy for P8.3+ reads
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
        return
            super.constructPublicInputs(
                nullifiers,
                outputs,
                proof,
                inputsLocked
            );
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

    function emitTransferEvent(
        uint256[] memory nullifiers,
        uint256[] memory outputs,
        bytes memory proof,
        bytes memory data
    ) internal virtual override {
        super.emitTransferEvent(nullifiers, outputs, proof, data);
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
        //TODO
    }
}