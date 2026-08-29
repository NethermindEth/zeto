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
import {IAENKNRECodec} from "./lib/interfaces/IAENKNRECodec.sol";
import {IZetoEnforcedEvents} from "./lib/interfaces/IZetoEnforced.sol";
import {IZetoInitializable} from "./lib/interfaces/IZetoInitializable.sol";
import {AENKNREStorage} from "./lib/zeto_aenknre_storage.sol";
import {Zeto_AnonNullifier} from "./zeto_anon_nullifier.sol";
import {Registry} from "./lib/registry.sol";
import {ComplianceRootRegistry} from "./lib/compliance_root_registry.sol";
import {IZetoLockableCapability} from "./lib/interfaces/IZetoLockableCapability.sol";
import {ZetoFungibleStorage} from "./lib/zeto_fungible.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";

/// @title AENKNR-E Transfer Facet
/// @dev Implements the four proof paths (transfer, deposit, withdraw,
///   forcedTransfer) for the AENKNR-E token. Deployed separately and
///   called via DELEGATECALL from the router contract. Inherits the same
///   base chain as the router to guarantee identical storage layout.
contract Zeto_AENKNRETransferFacet is
    Zeto_AnonNullifier,
    Registry,
    ComplianceRootRegistry,
    IZetoEnforcedEvents
{
    error InitializationDisabled();

    struct _DecodedProof_EventFields {
        uint256[] enforcementNullifiers;
        uint256 encryptionNonce;
        uint256[2] ecdhPublicKey;
        uint256[] encryptedValuesForReceiver;
        uint256[] encryptedValuesForArbiter;
        uint256[] encryptedValuesForEnforcer;
    }

    function _s() private pure returns (AENKNREStorage.Layout storage) {
        return AENKNREStorage.layout();
    }

    function _requireEnforcerSet() private view {
        if (!_s().enforcerSet) {
            revert EnforcerNotSet();
        }
    }

    // The codec is an external contract called via STATICCALL. Its return data
    // is decoded with abi.decode against each builder's declared return tuple,
    // so a malformed buffer reverts rather than being read past its bounds, and
    // the codec's own custom errors reach the caller unchanged.

    function _callCodec(
        bytes memory callData
    ) private view returns (bytes memory) {
        return Address.functionStaticCall(address(_s().codec), callData);
    }

    function _toProof(
        uint256[8] memory w
    ) private pure returns (Commonlib.Proof memory ps) {
        ps.pA = [w[0], w[1]];
        ps.pB = [[w[2], w[3]], [w[4], w[5]]];
        ps.pC = [w[6], w[7]];
    }

    /// @dev Rejects a tag that is already spent, and a tag repeated within this
    ///   batch. The owner-nullifier and output-commitment domains have always
    ///   rejected an in-batch duplicate (`lib/storage/nullifier.sol`); this is
    ///   the third domain, and without it `_markEnforcementNullifiersSpent`
    ///   absorbs the repeat silently. Zero is exempt: it marks a disabled slot,
    ///   and several disabled slots in one batch are legitimate.
    function _checkEnforcementNullifiersUnspent(
        uint256[] memory enfNullifiers
    ) private view {
        AENKNREStorage.Layout storage s = _s();
        for (uint256 i = 0; i < enfNullifiers.length; ++i) {
            if (enfNullifiers[i] == 0) {
                continue;
            }
            for (uint256 j = 0; j < i; ++j) {
                if (enfNullifiers[j] == enfNullifiers[i]) {
                    revert EnforcementNullifierDuplicate(enfNullifiers[i]);
                }
            }
            if (s.enforcementNullifierSpent[enfNullifiers[i]]) {
                revert EnforcementNullifierAlreadySpent(enfNullifiers[i]);
            }
        }
    }

    function _markEnforcementNullifiersSpent(
        uint256[] memory enfNullifiers
    ) private {
        AENKNREStorage.Layout storage s = _s();
        for (uint256 i = 0; i < enfNullifiers.length; ++i) {
            if (enfNullifiers[i] != 0) {
                s.enforcementNullifierSpent[enfNullifiers[i]] = true;
            }
        }
    }

    // The codec accepts (bytes proof, bytes args), where args is
    // abi.encode(params...) followed by the 192-byte ProofContext tail. The
    // codec splits the decode at that boundary.

    /// @dev Encodes ProofContext as its 6 constituent words:
    ///   [idRoot, compRoot, arbiterPub[0], arbiterPub[1], enforcerPub[0], enforcerPub[1]]
    function _encodeCtx() private view returns (bytes memory) {
        AENKNREStorage.Layout storage s = _s();
        return
            abi.encode(
                getIdentitiesRoot(),
                getComplianceRoot(),
                s.arbiterPub[0],
                s.arbiterPub[1],
                s.enforcerPub[0],
                s.enforcerPub[1]
            );
    }

    function constructPublicInputs(
        uint256[] memory nullifiers,
        uint256[] memory outputs,
        bytes memory proof,
        bool
    ) internal virtual override returns (uint256[] memory, Commonlib.Proof memory) {
        _requireEnforcerSet();
        bytes memory args = bytes.concat(
            abi.encode(nullifiers, outputs),
            _encodeCtx()
        );
        bytes memory ret = _callCodec(
            abi.encodeWithSelector(IAENKNRECodec.buildTransfer.selector, proof, args)
        );
        (
            uint256[] memory pi,
            uint256[] memory enfN,
            uint256 root,
            uint256[8] memory proofWords
        ) = abi.decode(ret, (uint256[], uint256[], uint256, uint256[8]));
        validateRoot(root);
        _checkEnforcementNullifiersUnspent(enfN);
        _s().pendingEnfNullifiers = enfN;
        return (pi, _toProof(proofWords));
    }

    function constructPublicInputsForDeposit(
        uint256 amount,
        uint256[] memory outputs,
        bytes memory proof
    ) public virtual override returns (uint256[] memory, Commonlib.Proof memory) {
        _requireEnforcerSet();
        bytes memory args = bytes.concat(abi.encode(amount, outputs), _encodeCtx());
        bytes memory ret = _callCodec(
            abi.encodeWithSelector(IAENKNRECodec.buildDeposit.selector, proof, args)
        );
        (uint256[] memory pi, uint256[8] memory proofWords) = abi.decode(
            ret,
            (uint256[], uint256[8])
        );
        return (pi, _toProof(proofWords));
    }

    function constructPublicInputsForWithdraw(
        uint256 amount,
        uint256[] memory nullifiers,
        uint256 output,
        bytes memory proof
    ) internal virtual override returns (uint256[] memory, Commonlib.Proof memory) {
        _requireEnforcerSet();
        // The facet runs under delegatecall, so msg.sender is the original caller
        // — the same address `ZetoFungible.withdraw` pays the ERC-20 to. Binding
        // it into the proof stops a copied withdrawal from paying anyone else.
        bytes memory args = bytes.concat(
            abi.encode(amount, nullifiers, output, uint256(uint160(msg.sender))),
            _encodeCtx()
        );
        bytes memory ret = _callCodec(
            abi.encodeWithSelector(IAENKNRECodec.buildWithdraw.selector, proof, args)
        );
        (
            uint256[] memory pi,
            uint256[] memory enfN,
            uint256 root,
            uint256[8] memory proofWords
        ) = abi.decode(ret, (uint256[], uint256[], uint256, uint256[8]));
        validateRoot(root);
        _checkEnforcementNullifiersUnspent(enfN);
        _s().pendingEnfNullifiers = enfN;
        return (pi, _toProof(proofWords));
    }

    function processInputsAndOutputs(
        uint256[] memory inputs,
        uint256[] memory outputs,
        bool inputsLocked
    ) internal virtual override {
        super.processInputsAndOutputs(inputs, outputs, inputsLocked);
        // mark enforcement nullifiers staged during constructPublicInputs
        _markEnforcementNullifiersSpent(_s().pendingEnfNullifiers);
        // Staging is transaction-scoped but lives in persistent storage, so it
        // must not outlive the transaction that decoded and verified it. Clear
        // it once consumed, leaving nothing a later frame could re-mark.
        delete _s().pendingEnfNullifiers;
    }

    function emitTransferEvent(
        uint256[] memory nullifiers,
        uint256[] memory outputs,
        bytes memory proof,
        bytes memory data
    ) internal virtual override {
        _DecodedProof_EventFields memory dp = _readTransferEventFields(proof);
        emit UTXOTransferNonRepudiationEnforced(
            nullifiers, outputs,
            dp.enforcementNullifiers, dp.encryptionNonce, dp.ecdhPublicKey,
            dp.encryptedValuesForReceiver, dp.encryptedValuesForArbiter,
            dp.encryptedValuesForEnforcer,
            _s().arbiterKeyId, msg.sender, data
        );
    }

    /// @dev Seizure, executed under DELEGATECALL from the router. The only
    ///   authority this path checks is `onlyOwner` here plus the circuit's
    ///   `BabyPbk(enforcerPrivateKey) === enforcerPublicKey` against the
    ///   contract-injected enforcer key — no authorizing party, no per-seizure
    ///   nonce, no deadline. Replay is bounded solely by the enforcement
    ///   nullifiers: `_checkEnforcementNullifiersUnspent` rejects one already
    ///   spent (`EnforcementNullifierAlreadySpent`) or repeated within this
    ///   batch (`EnforcementNullifierDuplicate`), and
    ///   `_markEnforcementNullifiersSpent` records them after `verify`. See
    ///   `IZetoEnforced.forcedTransfer` for the full model.
    function forcedTransfer(
        uint256[] calldata outputs,
        bytes calldata proof,
        bytes calldata data
    ) public onlyOwner {
        _requireEnforcerSet();
        validateOutputs(outputs);

        bytes memory args = bytes.concat(abi.encode(outputs), _encodeCtx());
        bytes memory ret = _callCodec(
            abi.encodeWithSelector(IAENKNRECodec.buildForcedTransfer.selector, proof, args)
        );

        (
            uint256[] memory pi,
            uint256[] memory enfN,
            uint256 root,
            uint256[8] memory proofWords
        ) = abi.decode(ret, (uint256[], uint256[], uint256, uint256[8]));
        validateRoot(root);
        _checkEnforcementNullifiersUnspent(enfN);

        Commonlib.Proof memory ps = _toProof(proofWords);
        if (!_s().forcedTransferVerifier.verify(ps.pA, ps.pB, ps.pC, pi)) {
            revert InvalidProof();
        }

        _markEnforcementNullifiersSpent(enfN);
        processOutputs(outputs);
        _emitForcedTransferEvent(outputs, proof, data);
    }

    function _emitForcedTransferEvent(
        uint256[] calldata outputs,
        bytes calldata proof,
        bytes calldata data
    ) private {
        _DecodedProof_EventFields memory dp = _readForcedTransferEventFields(proof);
        emit UTXOForcedTransferEnforced(
            dp.enforcementNullifiers, outputs,
            dp.encryptionNonce, dp.ecdhPublicKey,
            dp.encryptedValuesForReceiver, dp.encryptedValuesForArbiter,
            dp.encryptedValuesForEnforcer,
            _s().arbiterKeyId, msg.sender, data
        );
    }

    // The proof encodings are the ones lib/aenknre_codec.sol decodes; these
    // keep only the fields the events publish.

    function _readTransferEventFields(
        bytes memory proof
    ) private pure returns (_DecodedProof_EventFields memory dp) {
        (
            ,
            dp.enforcementNullifiers,
            dp.encryptionNonce,
            dp.ecdhPublicKey,
            dp.encryptedValuesForReceiver,
            dp.encryptedValuesForArbiter,
            dp.encryptedValuesForEnforcer,

        ) = abi.decode(
            proof,
            (
                uint256,
                uint256[],
                uint256,
                uint256[2],
                uint256[],
                uint256[],
                uint256[],
                Commonlib.Proof
            )
        );
    }

    function _readForcedTransferEventFields(
        bytes memory proof
    ) private pure returns (_DecodedProof_EventFields memory dp) {
        (
            dp.enforcementNullifiers,
            ,
            ,
            dp.encryptionNonce,
            dp.ecdhPublicKey,
            dp.encryptedValuesForReceiver,
            dp.encryptedValuesForArbiter,
            dp.encryptedValuesForEnforcer,

        ) = abi.decode(
            proof,
            (
                uint256[],
                uint256,
                uint256[],
                uint256,
                uint256[2],
                uint256[],
                uint256[],
                uint256[],
                Commonlib.Proof
            )
        );
    }

    /// @dev An AENKNR-E note is backed 1:1 by the ERC-20 held here, and
    ///   `amount` is bound both into the deposit proof and into the value the
    ///   new commitments carry. SafeERC20 reports only that the transfer
    ///   succeeded, not how much arrived, so a backing token that withholds
    ///   part of it — a fee-on-transfer asset, or one that credits less than
    ///   it reports — would mint commitments the pool cannot redeem. Measure
    ///   the credited delta and reject anything short.
    function _collectDeposit(uint256 amount) internal override {
        IERC20 erc20 = ZetoFungibleStorage.layout().erc20Token;
        uint256 balanceBefore = erc20.balanceOf(address(this));
        super._collectDeposit(amount);
        uint256 credited = erc20.balanceOf(address(this)) - balanceBefore;
        if (credited < amount) {
            revert InsufficientDepositCredited(amount, credited);
        }
    }

    /// @dev AENKNR-E has no locked-transfer circuit, so its lock verifier is
    ///   the zero address and no locked spend could ever be proved. Both
    ///   {ZetoLockable} hooks therefore refuse outright: `createLock` reaches
    ///   {_doLockTransition} and `spendLock` reaches {_transferLocked}, so
    ///   reverting in the pair closes the whole lock lifecycle at its two
    ///   entry points. Without this the refusal would be incidental — the
    ///   base hook would build a 7-signal public-input vector and hand it to
    ///   a verifier expecting 58 — and an accidental refusal is not a
    ///   security property.
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

    /// @dev The facet only ever runs under DELEGATECALL from the router, which
    ///   owns the initialized state, so its own {initialize} has nothing to do.
    ///   Overriding it is not only about the error: it keeps the inherited
    ///   initializer body out of the facet's bytecode, which is worth about
    ///   6.6 KiB against the EIP-170 limit that split this token in two.
    function initialize(
        string calldata,
        string calldata,
        address,
        IZetoInitializable.VerifiersInfo calldata
    ) public pure override {
        revert InitializationDisabled();
    }
}
