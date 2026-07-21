pragma solidity ^0.8.27;

import {Commonlib} from "./lib/common/common.sol";
import {IAENKNRECodec} from "./lib/interfaces/iaenknre_codec.sol";
import {IGroth16Verifier} from "./lib/interfaces/izeto_verifier.sol";
import {IZetoInitializable} from "./lib/interfaces/izeto_initializable.sol";
import {IZetoEnforced} from "./lib/interfaces/izeto_enforced.sol";
import {IZetoNullifierStorageView} from "./lib/interfaces/izeto_nullifier_storage_view.sol";
import {AENKNREStorage} from "./lib/zeto_aenknre_storage.sol";
import {Zeto_AnonNullifier} from "./zeto_anon_nullifier.sol";
import {Registry} from "./lib/registry.sol";
import {ComplianceRootRegistry} from "./lib/compliance_root_registry.sol";

/// @title A Zeto based enforced fungible token with KYC, compliance, non-repudiation, and seizure
/// @dev Extends Zeto_AnonNullifier with enforcement nullifiers, three-stream
///   encryption (receiver, arbiter, enforcer), compliance-gated transfers,
///   and owner-initiated forced transfers (seizure).
///
///   The contract is split into two deployment units to fit within EIP-170:
///     - This contract (router): admin, views, initialization, UUPS upgrade
///     - Zeto_AENKNRETransferFacet: transfer, deposit, withdraw, forcedTransfer
///   The router forwards proof-path calls to the facet via DELEGATECALL.
///   Both share AENKNR-E state via ERC-7201 namespaced storage.
contract Zeto_AnonEncNullifierKycNonRepudiationEnforced is
    Zeto_AnonNullifier,
    Registry,
    ComplianceRootRegistry,
    IZetoEnforced
{
    using AENKNREStorage for *;

    error CodecAlreadySet();
    error FacetNotSet();

    function _s() private pure returns (AENKNREStorage.Layout storage) {
        return AENKNREStorage.layout();
    }

    // ── Initialization ──

    function initialize(
        string calldata name,
        string calldata symbol,
        address initialOwner,
        IZetoInitializable.VerifiersInfo calldata verifiers
    ) public override initializer {
        __ZetoAnonEncNullifierKycNonRepudiationEnforced_init(
            name, symbol, initialOwner, verifiers
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
        _s().forcedTransferVerifier = verifiers.forcedTransferVerifier;
    }

    function setCodec(address codec) public onlyOwner {
        if (address(_s().codec) != address(0)) revert CodecAlreadySet();
        _s().codec = IAENKNRECodec(codec);
    }

    function setTransferFacet(address facet) public onlyOwner {
        require(facet != address(0), "Zero address");
        _s().transferFacet = facet;
    }

    // ── Arbiter and enforcer management ──

    function setArbiter(uint256[2] memory newKey) public onlyOwner {
        AENKNREStorage.Layout storage s = _s();
        s.arbiterPub = newKey;
        s.arbiterKeyId++;
        emit ArbiterUpdated(newKey, s.arbiterKeyId);
    }

    function getArbiter() public view returns (uint256[2] memory) {
        return _s().arbiterPub;
    }

    function getArbiterKeyId() public view returns (uint256) {
        return _s().arbiterKeyId;
    }

    function setEnforcer(uint256[2] memory newKey) public onlyOwner {
        AENKNREStorage.Layout storage s = _s();
        if (s.enforcerSet) revert EnforcerAlreadySet();
        s.enforcerPub = newKey;
        s.enforcerSet = true;
        emit EnforcerSet(newKey);
    }

    function getEnforcer() public view returns (uint256[2] memory) {
        return _s().enforcerPub;
    }

    // ── Nullifier read APIs ──

    function ownerNullifierSpent(uint256 n) public view returns (bool) {
        return IZetoNullifierStorageView(address(_storage)).nullifierSpent(n);
    }

    function enforcementNullifierSpent(uint256 n) external view returns (bool) {
        return _s().enforcementNullifierSpent[n];
    }

    function isSpent(uint256 ownerN, uint256 enfN) external view returns (bool) {
        return ownerNullifierSpent(ownerN) || _s().enforcementNullifierSpent[enfN];
    }

    // ── DELEGATECALL routing to TransferFacet ──

    function transfer(
        uint256[] calldata inputs,
        uint256[] calldata outputs,
        bytes calldata proof,
        bytes calldata data
    ) public virtual override {
        _forwardToFacet();
    }

    function deposit(
        uint256 amount,
        uint256[] calldata outputs,
        bytes calldata proof,
        bytes calldata data
    ) public virtual override {
        _forwardToFacet();
    }

    function withdraw(
        uint256 amount,
        uint256[] calldata inputs,
        uint256 output,
        bytes calldata proof,
        bytes calldata data
    ) public virtual override {
        _forwardToFacet();
    }

    function forcedTransfer(
        uint256[] calldata outputs,
        bytes calldata proof,
        bytes calldata data
    ) external {
        _forwardToFacet();
    }

    function _forwardToFacet() private {
        address facet = _s().transferFacet;
        if (facet == address(0)) revert FacetNotSet();
        /// @solidity memory-safe-assembly
        assembly {
            calldatacopy(0, 0, calldatasize())
            let ok := delegatecall(gas(), facet, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            switch ok
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }
}
