pragma solidity ^0.8.27;

import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {IZetoComplianceRoot} from "./interfaces/izeto_compliance_root.sol";

/// @title On-chain compliance root registry for Zeto tokens
/// @dev Stores only the compliance SMT root hash on-chain. The full
///   Sparse Merkle Tree is maintained off-chain by a compliance
///   service, which posts updated roots via setComplianceRoot.
abstract contract ComplianceRootRegistry is
    OwnableUpgradeable,
    IZetoComplianceRoot
{
    uint256 internal _complianceRoot;

    function __ComplianceRootRegistry_init() internal onlyInitializing {}

    /**
     * @dev Set a new compliance root
     * @param newRoot The new compliance SMT root hash
     * @param data Additional data for external tracking
     *
     * Emits a {ComplianceRootUpdated} event.
     */
    function setComplianceRoot(
        uint256 newRoot,
        bytes calldata data
    ) public onlyOwner {
        uint256 oldRoot = _complianceRoot;
        _complianceRoot = newRoot;
        emit ComplianceRootUpdated(oldRoot, newRoot, data);
    }

    /**
     * @dev Returns the current compliance root
     * @return uint256 the current compliance SMT root hash
     */
    function getComplianceRoot() public view returns (uint256) {
        return _complianceRoot;
    }
}