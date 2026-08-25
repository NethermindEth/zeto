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

import {Commonlib} from "./lib/common/common.sol";
import {IAENKNRECodec} from "./lib/interfaces/iaenknre_codec.sol";
import {IGroth16Verifier} from "./lib/interfaces/IZetoVerifier.sol";
import {IZetoInitializable} from "./lib/interfaces/IZetoInitializable.sol";
import {IZetoEnforced} from "./lib/interfaces/izeto_enforced.sol";
import {IZetoNullifierStorageView} from "./lib/interfaces/izeto_nullifier_storage_view.sol";
import {AENKNREStorage} from "./lib/zeto_aenknre_storage.sol";
import {Zeto_AnonNullifier} from "./zeto_anon_nullifier.sol";
import {ZetoCommonStorage} from "./lib/zeto_common.sol";
import {Registry} from "./lib/registry.sol";
import {ComplianceRootRegistry} from "./lib/compliance_root_registry.sol";
import {IZetoLockableCapability} from "./lib/interfaces/IZetoLockableCapability.sol";

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
        // Linearized order: the ZetoFungible chain owns the Ownable and
        // ReentrancyGuard initialization, so it runs before the mixins.
        __ZetoAnonNullifier_init(name_, symbol_, initialOwner, verifiers);
        __Registry_init();
        __ComplianceRootRegistry_init();
        _s().forcedTransferVerifier = verifiers.forcedTransferVerifier;
    }

    /// @dev Both setters store a target that is later reached with a low-level
    ///   call: `_callCodec` STATICCALLs the codec and `_forwardToFacet`
    ///   DELEGATECALLs the facet. Both of those succeed with empty return data
    ///   against an account holding no code, so a codeless target is never
    ///   reported as an error downstream -- a transfer would return a status-1
    ///   receipt having done nothing. Checking at the write is enough: since
    ///   EIP-6780 a contract can only lose its code in the transaction that
    ///   created it, so a target with code here keeps it.
    function _requireContract(address target) private view {
        if (target.code.length == 0) revert NotAContract(target);
    }

    function setCodec(address codec) public onlyOwner {
        if (address(_s().codec) != address(0)) revert CodecAlreadySet();
        _requireContract(codec);
        _s().codec = IAENKNRECodec(codec);
    }

    function setTransferFacet(address facet) public onlyOwner {
        require(facet != address(0), "Zero address");
        _requireContract(facet);
        _s().transferFacet = facet;
    }

    // ── Arbiter and enforcer management ──

    /// @dev BabyJubJub is defined over the BN254 scalar field, which is also the
    ///   field the generated Groth16 verifiers accept public signals in.
    uint256 private constant BABYJUB_FIELD =
        21888242871839275222246405745257275088548364400416034343698204186575808495617;
    uint256 private constant BABYJUB_A = 168700;
    uint256 private constant BABYJUB_D = 168696;

    /// @dev Reverts unless `key` is usable as an authority key in a proof.
    ///   Mirrors circomlib's `BabyCheck` plus the `xIsZero === 0` constraint the
    ///   AENKNR-E circuits apply to both authority keys, and additionally bounds
    ///   each coordinate by the field, because a coordinate at or above it is
    ///   rejected by the verifiers' own `checkField`. Storing a key that fails
    ///   any of these makes every transfer, deposit, withdraw and forcedTransfer
    ///   unprovable; for the enforcer that state is irreversible, because
    ///   `setEnforcer` is set-once.
    function _requireValidBabyJubKey(uint256[2] memory key) private pure {
        uint256 x = key[0];
        uint256 y = key[1];
        if (x == 0 || x >= BABYJUB_FIELD || y >= BABYJUB_FIELD) {
            revert InvalidBabyJubKey(x, y);
        }
        uint256 x2 = mulmod(x, x, BABYJUB_FIELD);
        uint256 y2 = mulmod(y, y, BABYJUB_FIELD);
        // a * x2 + y2 == 1 + d * x2 * y2
        uint256 lhs = addmod(mulmod(BABYJUB_A, x2, BABYJUB_FIELD), y2, BABYJUB_FIELD);
        uint256 rhs = addmod(
            1,
            mulmod(BABYJUB_D, mulmod(x2, y2, BABYJUB_FIELD), BABYJUB_FIELD),
            BABYJUB_FIELD
        );
        if (lhs != rhs) {
            revert InvalidBabyJubKey(x, y);
        }
    }

    function setArbiter(uint256[2] memory newKey) public onlyOwner {
        _requireValidBabyJubKey(newKey);
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

    /// @dev Set-once, so the enforcer capability is not revocable: possession
    ///   of the matching private key is half of the seizure authority described
    ///   on `forcedTransfer`, and only a UUPS upgrade can withdraw it. A second
    ///   call reverts `EnforcerAlreadySet` regardless of the key offered.
    function setEnforcer(uint256[2] memory newKey) public onlyOwner {
        AENKNREStorage.Layout storage s = _s();
        if (s.enforcerSet) revert EnforcerAlreadySet();
        _requireValidBabyJubKey(newKey);
        s.enforcerPub = newKey;
        s.enforcerSet = true;
        emit EnforcerSet(newKey);
    }

    function getEnforcer() public view returns (uint256[2] memory) {
        return _s().enforcerPub;
    }

    // ── Nullifier read APIs ──

    function ownerNullifierSpent(uint256 n) public view returns (bool) {
        return
            IZetoNullifierStorageView(
                address(ZetoCommonStorage.layout().utxoStorage)
            ).nullifierSpent(n);
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

    /// @dev Seizure. Single-party in this implementation: the owner account and
    ///   the enforcer BabyJubJub private key are the only two requirements, and
    ///   `setEnforcer` makes the second permanent. There is no independent
    ///   authorising party, no per-seizure nonce and no deadline. See
    ///   `IZetoEnforced.forcedTransfer` for the full model.
    function forcedTransfer(
        uint256[] calldata outputs,
        bytes calldata proof,
        bytes calldata data
    ) external {
        _forwardToFacet();
    }

    // ── Locking is not supported ──

    /// @dev The router is the deployed contract, so the inherited lock entry
    ///   points ({createLock}, {spendLock}) resolve against this code rather
    ///   than the facet's. Both hooks refuse here for the same reason they do
    ///   in {Zeto_AENKNRETransferFacet}: AENKNR-E has no locked-transfer
    ///   circuit and its lock verifier is the zero address, so a lock could
    ///   never be settled.
    function _doLockTransition(
        IZetoLockableCapability.ZetoCreateLockArgs calldata
    ) internal pure override {
        revert LockingNotSupported();
    }

    /// @dev See {_doLockTransition}.
    function _transferLocked(
        bytes32,
        uint256[] calldata,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata,
        bytes calldata
    ) internal pure override {
        revert LockingNotSupported();
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
