// Copyright © 2025 Kaleido, Inc.
//
// SPDX-License-Identifier: Apache-2.0
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
pragma solidity ^0.8.27;

import {Ownable2StepUpgradeable} from "@openzeppelin/contracts-upgradeable/access/Ownable2StepUpgradeable.sol";
import {IZetoComplianceRoot} from "./interfaces/izeto_compliance_root.sol";

/// @title On-chain compliance root registry for Zeto tokens
/// @dev Stores only the compliance SMT root hash on-chain. The full
///   Sparse Merkle Tree is maintained off-chain by a compliance
///   service, which posts updated roots via setComplianceRoot.
///
///   Inherits {Ownable2StepUpgradeable} for the same reason {Registry} does:
///   the token this mixes into already reaches ownership through
///   {ZetoCommon}, which is {Ownable2StepUpgradeable}, so both branches of
///   the inheritance graph must resolve to the same implementation. The
///   Ownable initialization itself is performed once by the token's
///   `__ZetoCommon_init`.
abstract contract ComplianceRootRegistry is
    Ownable2StepUpgradeable,
    IZetoComplianceRoot
{
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
        ComplianceRootRegistryStorage.Layout storage $ = ComplianceRootRegistryStorage
            .layout();
        uint256 oldRoot = $.complianceRoot;
        $.complianceRoot = newRoot;
        emit ComplianceRootUpdated(oldRoot, newRoot, data);
    }

    /**
     * @dev Returns the current compliance root
     * @return uint256 the current compliance SMT root hash
     */
    function getComplianceRoot() public view returns (uint256) {
        return ComplianceRootRegistryStorage.layout().complianceRoot;
    }
}

/// @dev ERC-7201 (`erc7201:zeto.storage.ComplianceRootRegistry`). Namespaced
///   for the same reason the rest of the Zeto mixins are: this contract is
///   composed into a token whose other bases all claim namespaced slots, so a
///   sequential variable here would be the only thing pinned to the proxy's
///   slot 0 and the only thing that could collide on a future re-composition.
library ComplianceRootRegistryStorage {
    struct Layout {
        uint256 complianceRoot;
    }

    bytes32 private constant STORAGE_LOCATION =
        keccak256(
            abi.encode(
                uint256(keccak256("zeto.storage.ComplianceRootRegistry")) - 1
            )
        ) & ~bytes32(uint256(0xff));

    function layout() internal pure returns (Layout storage $) {
        bytes32 slot = STORAGE_LOCATION;
        /// @solidity memory-safe-assembly
        assembly {
            $.slot := slot
        }
    }
}