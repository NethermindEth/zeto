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

    function constructPublicInputs(
        uint256[] memory,
        uint256[] memory,
        bytes memory,
        bool
    )
        internal
        virtual
        override
        returns (
            uint256[] memory publicInputs,
            Commonlib.Proof memory proof
        )
    {
        // TODO
    }

    function constructPublicInputsForDeposit(
        uint256,
        uint256[] memory,
        bytes memory
    )
        public
        virtual
        override
        returns (
            uint256[] memory publicInputs,
            Commonlib.Proof memory proof
        )
    {
        // TODO
    }

    function constructPublicInputsForWithdraw(
        uint256,
        uint256[] memory,
        uint256,
        bytes memory
    )
        internal
        virtual
        override
        returns (
            uint256[] memory publicInputs,
            Commonlib.Proof memory proof
        )
    {
        // TODO
    }

    function emitTransferEvent(
        uint256[] memory,
        uint256[] memory,
        bytes memory,
        bytes memory
    ) internal virtual override {
        // TODO
    }

    function forcedTransfer(
        uint256[] calldata,
        bytes calldata,
        bytes calldata
    ) public onlyOwner {
        // TODO
    }
}