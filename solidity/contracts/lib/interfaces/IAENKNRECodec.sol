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

/// @title IAENKNRECodec — proof decoder and public-input assembler for AENKNR-E
/// @dev Called via STATICCALL from the TransferFacet. Decodes the proof bytes
///   and assembles the public-input array (pi) for each circuit. Returns flat
///   types (uint256[], uint256[8]) rather than structs.
///
///   All build functions accept two bytes parameters:
///     proof — ABI-encoded circuit-specific fields + Groth16 proof struct
///     args  — abi.encode(params...) ++ rawCtx(192 bytes)
///   The 192-byte tail encodes ProofContext as 6 consecutive uint256 words.
interface IAENKNRECodec {
    struct ProofContext {
        uint256 idRoot;
        uint256 compRoot;
        uint256[2] arbiterPub;
        uint256[2] enforcerPub;
    }

    function buildTransfer(
        bytes calldata proof,
        bytes calldata args
    ) external pure returns (
        uint256[] memory pi,
        uint256[] memory enfNullifiers,
        uint256 root,
        uint256[8] memory proofWords
    );

    function buildDeposit(
        bytes calldata proof,
        bytes calldata args
    ) external pure returns (
        uint256[] memory pi,
        uint256[8] memory proofWords
    );

    function buildWithdraw(
        bytes calldata proof,
        bytes calldata args
    ) external pure returns (
        uint256[] memory pi,
        uint256[] memory enfNullifiers,
        uint256 root,
        uint256[8] memory proofWords
    );

    function buildForcedTransfer(
        bytes calldata proof,
        bytes calldata args
    ) external pure returns (
        uint256[] memory pi,
        uint256[] memory enfNullifiers,
        uint256 root,
        uint256[8] memory proofWords
    );
}