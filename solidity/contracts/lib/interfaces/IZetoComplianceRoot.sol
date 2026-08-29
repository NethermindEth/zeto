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

/// @title The compliance-root projection an enforced Zeto token publishes
/// @author Kaleido, Inc.
/// @dev The compliance tree records a status per identity, and its root is a
///   public input to every enforced proof. A token exposes the current root so
///   a prover can build against the same one the verifier will be given.
interface IZetoComplianceRoot {
    /// @dev Emitted when the compliance root moves. Proofs built against
    ///   `oldRoot` stop verifying at that point.
    /// @param oldRoot The root being replaced.
    /// @param newRoot The root now in force.
    /// @param data Caller-supplied data, carried through for indexers.
    event ComplianceRootUpdated(
        uint256 oldRoot,
        uint256 newRoot,
        bytes data
    );

    /// @dev Replaces the compliance root.
    /// @param newRoot The root to put in force.
    /// @param data Caller-supplied data, emitted with the event.
    function setComplianceRoot(
        uint256 newRoot,
        bytes calldata data
    ) external;

    /// @dev Returns the compliance root currently in force.
    function getComplianceRoot() external view returns (uint256);
}
