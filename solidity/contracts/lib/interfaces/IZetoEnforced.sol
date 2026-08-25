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

/// @title IZetoEnforcedEvents — errors and events for enforced Zeto token variants
/// @dev Separated from IZetoEnforced so contracts that only emit events
///   (e.g. the TransferFacet) can inherit without implementing admin functions.
interface IZetoEnforcedEvents {
    error EnforcerAlreadySet();
    error EnforcerNotSet();
    error EnforcementNullifierAlreadySpent(uint256 nullifier);
    /// @dev The same enforcement nullifier appears twice in one batch.
    error EnforcementNullifierDuplicate(uint256 nullifier);
    error InvalidEnforcementNullifierArity(uint256 expected, uint256 actual);
    /// @dev An arbiter or enforcer key that is off-curve, out of field, or
    ///   has x == 0, and would therefore make every proof path unverifiable.
    error InvalidBabyJubKey(uint256 x, uint256 y);
    /// @dev A codec or transfer-facet address that holds no code, and would
    ///   therefore make every low-level call to it succeed silently.
    error NotAContract(address target);
    /// @dev A deposit that credited this contract with less than the amount
    ///   the proof and the new commitments were built against.
    error InsufficientDepositCredited(uint256 expected, uint256 credited);
    /// @dev Any lock entry point reached on an enforced token. The enforced
    ///   circuits have no locked-transfer flavour, so no lock can ever be
    ///   settled; refusing at creation keeps that explicit rather than
    ///   leaving it to a downstream verifier mismatch.
    error LockingNotSupported();

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

    event UTXOForcedTransferEnforced(
        uint256[] enforcementNullifiers,
        uint256[] outputs,
        uint256 encryptionNonce,
        uint256[2] ecdhPublicKey,
        uint256[] encryptedValuesForReceiver,
        uint256[] encryptedValuesForArbiter,
        uint256[] encryptedValuesForEnforcer,
        uint256 arbiterKeyId,
        address indexed submitter,
        bytes data
    );
}

/// @title IZetoEnforced — public API for enforced Zeto token variants
/// @author Kaleido, Inc.
/// @dev Paladin's Go domain embeds the compiled ABI of this interface
///   to call admin, seizure, and nullifier-read functions.
interface IZetoEnforced is IZetoEnforcedEvents {
    // arbiter key management (rotatable, keyId increments each rotation)
    function setArbiter(uint256[2] memory newKey) external;
    function getArbiter() external view returns (uint256[2] memory);
    function getArbiterKeyId() external view returns (uint256);

    /// @notice Sets the enforcer BabyJubJub public key. Set-once: rotating it
    ///   would orphan every enforcement nullifier already derived via ECDH with
    ///   this key.
    /// @dev Set-once also means the enforcer capability is NOT revocable.
    ///   Possession of the matching private key is half of the seizure
    ///   authority described on `forcedTransfer`, and once this key is stored
    ///   the only way to withdraw that capability is a UUPS upgrade.
    function setEnforcer(uint256[2] memory newKey) external;
    function getEnforcer() external view returns (uint256[2] memory);

    /// @notice Seizure: redirects a frozen owner's UTXOs to new recipients,
    ///   marking only the enforcement nullifiers.
    /// @dev Authority model, as implemented. Executing a seizure requires two
    ///   things and nothing else: the contract owner's account, because this
    ///   function is `onlyOwner`, and the enforcer BabyJubJub private key,
    ///   because the forced-transfer circuit's only authorisation constraint is
    ///   `BabyPbk(enforcerPrivateKey) === enforcerPublicKey` against the key the
    ///   contract injects as a public input. There is no third party: the proof
    ///   carries no authorisation hash and no signature, the circuit's public
    ///   inputs contain no per-seizure nonce and no deadline, and replay is
    ///   bounded only by the enforcement nullifiers the call marks spent.
    ///
    ///   So a single holder of both the owner account and the enforcer private
    ///   key can seize any frozen note, to any KYC-registered recipient, at any
    ///   time — and because `setEnforcer` is set-once, that capability cannot be
    ///   withdrawn short of a UUPS upgrade. In the deployments this repository
    ///   configures, the two are one operational role.
    ///
    ///   Separating authorization from execution is not implemented. Adding an
    ///   independent authorizing party, a per-seizure nonce, a deadline, or a
    ///   revocable enforcer changes the circuit's public inputs, so every
    ///   generated verifier has to be regenerated alongside it.
    function forcedTransfer(
        uint256[] calldata outputs,
        bytes calldata proof,
        bytes calldata data
    ) external;

    // nullifier reads (OR semantics: spent if either nullifier type is marked)
    function ownerNullifierSpent(uint256 n) external view returns (bool);
    function enforcementNullifierSpent(uint256 n) external view returns (bool);
    function isSpent(uint256 ownerN, uint256 enfN) external view returns (bool);
}