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

import {IAENKNRECodec} from "./interfaces/IAENKNRECodec.sol";
import {IGroth16Verifier} from "./interfaces/IZetoVerifier.sol";

/// @title AENKNREStorage — ERC-7201 namespaced storage shared by the AENKNR-E router and facet
/// @author Kaleido, Inc.
/// @dev Both the router and the TransferFacet import this library so they
///   read/write the same storage slots when the facet executes via DELEGATECALL.
/// @dev ERC-7201 (`erc7201:zeto.storage.aenknre`): slot =
///   `keccak256(abi.encode(uint256(keccak256(bytes("zeto.storage.aenknre"))) - 1)) & ~bytes32(uint256(0xff))`.
library AENKNREStorage {
    struct Layout {
        uint256[] pendingEnfNullifiers;
        IAENKNRECodec codec;
        IGroth16Verifier forcedTransferVerifier;
        uint256[2] arbiterPub;
        uint256 arbiterKeyId;
        uint256[2] enforcerPub;
        bool enforcerSet;
        mapping(uint256 => bool) enforcementNullifierSpent;
        address transferFacet;
    }

    bytes32 private constant STORAGE_SLOT =
        keccak256(
            abi.encode(uint256(keccak256("zeto.storage.aenknre")) - 1)
        ) & ~bytes32(uint256(0xff));

    function layout() internal pure returns (Layout storage s) {
        bytes32 slot = STORAGE_SLOT;
        /// @solidity memory-safe-assembly
        assembly {
            s.slot := slot
        }
    }
}
