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

import {Commonlib} from "./common/common.sol";
import {IAENKNRECodec} from "./interfaces/IAENKNRECodec.sol";

/// @title AENKNRECodec — proof decoder and public-input assembler for AENKNR-E
/// @author Kaleido, Inc.
/// @dev Each build* function decodes the proof bytes (circuit-specific fields +
///   Groth16 proof), decodes the packed args (call parameters + ProofContext),
///   and assembles the public-input array matching the circuit's signal ordering.
contract AENKNRECodec is IAENKNRECodec {
    // Every AENKNR-E circuit has a fixed public-signal layout, but the proof
    // payload carries several of its fields as dynamic arrays. Because each
    // build* function fills a fixed-size `pi` sequentially, a caller who makes
    // one field longer and an adjacent one shorter by the same amount produces a
    // vector that is bit-identical to a genuine proof's while the facet records
    // different values — most damagingly, swapping the owner- and
    // enforcement-nullifier slots. Every arity is therefore required exactly,
    // before any `pi` write.
    uint256 private constant ENC_RECEIVER_LEN = 8; // 2 outputs x 4 fields
    uint256 private constant ENC_AUTHORITY_LEN = 16; // padded 14-field plaintext
    uint256 private constant NULLIFIERS_LEN = 2;
    uint256 private constant ENF_NULLIFIERS_LEN = 2;
    uint256 private constant OUTPUTS_LEN = 2;
    uint256 private constant ENABLED_LEN = 2;

    // Public-signal counts, matching nPublic in each circuit's verifying key.
    uint256 private constant PI_LEN_TRANSFER = 58;
    uint256 private constant PI_LEN_DEPOSIT = 52;
    uint256 private constant PI_LEN_WITHDRAW = 51;
    uint256 private constant PI_LEN_FORCED_TRANSFER = 56;

    /// @dev The 6-word ProofContext tail the facet appends to every args buffer.
    uint256 private constant CTX_BYTES = 192;

    error InvalidProofFieldArity(uint256 expected, uint256 actual);
    error InvalidArgsLength(uint256 actual);
    error PublicInputLengthMismatch(uint256 expected, uint256 actual);

    function _requireArity(uint256 actual, uint256 expected) private pure {
        if (actual != expected) {
            revert InvalidProofFieldArity(expected, actual);
        }
    }

    /// @dev Total-coverage check: every `pi` slot must have been written exactly
    ///   once. Cheap insurance against future layout drift.
    function _requireComplete(uint256 idx, uint256 expected) private pure {
        if (idx != expected) {
            revert PublicInputLengthMismatch(expected, idx);
        }
    }

    // Decoded proof field structs — one per circuit
    struct TransferFields {
        uint256 root;
        uint256[] enfN;
        uint256 encNonce;
        uint256[2] ecdhPub;
        uint256[] encR;
        uint256[] encA;
        uint256[] encE;
    }

    struct DepositFields {
        uint256 encNonce;
        uint256[2] ecdhPub;
        uint256[] encR;
        uint256[] encA;
        uint256[] encE;
    }

    struct WithdrawFields {
        uint256 root;
        uint256[] enfN;
        uint256 encNonce;
        uint256[2] ecdhPub;
        uint256[] encA;
        uint256[] encE;
    }

    struct ForcedTransferFields {
        uint256[] enfN;
        uint256 root;
        uint256[] enabled;
        uint256 encNonce;
        uint256[2] ecdhPub;
        uint256[] encR;
        uint256[] encA;
        uint256[] encE;
    }

    function _proofToWords(
        Commonlib.Proof memory ps
    ) private pure returns (uint256[8] memory w) {
        w[0] = ps.pA[0];
        w[1] = ps.pA[1];
        w[2] = ps.pB[0][0];
        w[3] = ps.pB[0][1];
        w[4] = ps.pB[1][0];
        w[5] = ps.pB[1][1];
        w[6] = ps.pC[0];
        w[7] = ps.pC[1];
    }

    function _decodeTransfer(bytes calldata p) private pure returns (TransferFields memory d, Commonlib.Proof memory ps) {
        (d.root, d.enfN, d.encNonce, d.ecdhPub, d.encR, d.encA, d.encE, ps) =
            abi.decode(p, (uint256, uint256[], uint256, uint256[2], uint256[], uint256[], uint256[], Commonlib.Proof));
    }

    function _decodeDeposit(bytes calldata p) private pure returns (DepositFields memory d, Commonlib.Proof memory ps) {
        (d.encNonce, d.ecdhPub, d.encR, d.encA, d.encE, ps) =
            abi.decode(p, (uint256, uint256[2], uint256[], uint256[], uint256[], Commonlib.Proof));
    }

    function _decodeWithdraw(bytes calldata p) private pure returns (WithdrawFields memory d, Commonlib.Proof memory ps) {
        (d.root, d.enfN, d.encNonce, d.ecdhPub, d.encA, d.encE, ps) =
            abi.decode(p, (uint256, uint256[], uint256, uint256[2], uint256[], uint256[], Commonlib.Proof));
    }

    // Split into two calls to stay within stack limits
    function _decodeForcedTransfer(bytes calldata p) private pure returns (ForcedTransferFields memory d, Commonlib.Proof memory ps) {
        _decodeForcedTransfer1(p, d);
        ps = _decodeForcedTransfer2(p, d);
    }
    function _decodeForcedTransfer1(bytes calldata p, ForcedTransferFields memory d) private pure {
        (d.enfN, d.root, d.enabled, d.encNonce, , , , , ) =
            abi.decode(p, (uint256[], uint256, uint256[], uint256, uint256[2], uint256[], uint256[], uint256[], Commonlib.Proof));
    }
    function _decodeForcedTransfer2(bytes calldata p, ForcedTransferFields memory d) private pure returns (Commonlib.Proof memory ps) {
        (, , , , d.ecdhPub, d.encR, d.encA, d.encE, ps) =
            abi.decode(p, (uint256[], uint256, uint256[], uint256, uint256[2], uint256[], uint256[], uint256[], Commonlib.Proof));
    }

    /// @dev Fills ecdhPub + encReceiver + encArbiter + encEnforcer into pi starting at index s.
    function _fillCipher(
        uint256[] memory pi, uint256 s,
        uint256[2] memory ep, uint256[] memory eR, uint256[] memory eA, uint256[] memory eE
    ) private pure returns (uint256 idx) {
        pi[s] = ep[0];
        pi[s + 1] = ep[1];
        idx = s + 2;
        for (uint256 i; i < eR.length; ++i) {
            pi[idx++] = eR[i];
        }
        for (uint256 i; i < eA.length; ++i) {
            pi[idx++] = eA[i];
        }
        for (uint256 i; i < eE.length; ++i) {
            pi[idx++] = eE[i];
        }
    }

    /// @dev Returns the offset at which the ProofContext tail begins: the first
    ///   portion of args is standard ABI encoding, and the last 192 bytes are 6
    ///   raw uint256 words encoding ProofContext.
    function _ctxOffset(bytes calldata args) private pure returns (uint256 ctxOff) {
        if (args.length < CTX_BYTES) {
            revert InvalidArgsLength(args.length);
        }
        ctxOff = args.length - CTX_BYTES;
    }

    // Each function matches one circuit's signal ordering exactly.
    // Signal counts: transfer=58, deposit=52, withdraw=51, forcedTransfer=56.

    function buildTransfer(
        bytes calldata proof,
        bytes calldata args
    ) external pure override returns (uint256[] memory pi, uint256[] memory enfNullifiers, uint256 root, uint256[8] memory proofWords) {
        (TransferFields memory f, Commonlib.Proof memory ps) = _decodeTransfer(proof);
        uint256 ctxOff = _ctxOffset(args);
        (uint256[] memory nullifiers, uint256[] memory outputs) =
            abi.decode(args[:ctxOff], (uint256[], uint256[]));
        ProofContext memory ctx = abi.decode(args[ctxOff:], (ProofContext));

        _requireArity(f.encR.length, ENC_RECEIVER_LEN);
        _requireArity(f.encA.length, ENC_AUTHORITY_LEN);
        _requireArity(f.encE.length, ENC_AUTHORITY_LEN);
        _requireArity(f.enfN.length, ENF_NULLIFIERS_LEN);
        _requireArity(nullifiers.length, NULLIFIERS_LEN);
        _requireArity(outputs.length, OUTPUTS_LEN);

        enfNullifiers = f.enfN;
        root = f.root;
        proofWords = _proofToWords(ps);
        pi = new uint256[](PI_LEN_TRANSFER);
        uint256 idx = _fillCipher(pi, 0, f.ecdhPub, f.encR, f.encA, f.encE);
        for (uint256 i; i < nullifiers.length; ++i) {
            pi[idx++] = nullifiers[i];
        }
        for (uint256 i; i < f.enfN.length; ++i) {
            pi[idx++] = f.enfN[i];
        }
        pi[idx++] = f.root;
        for (uint256 i; i < nullifiers.length; ++i) {
            pi[idx++] = (nullifiers[i] == 0) ? 0 : 1;
        }
        pi[idx++] = ctx.idRoot;
        pi[idx++] = ctx.compRoot;
        for (uint256 i; i < outputs.length; ++i) {
            pi[idx++] = outputs[i];
        }
        pi[idx++] = f.encNonce;
        pi[idx++] = ctx.arbiterPub[0];
        pi[idx++] = ctx.arbiterPub[1];
        pi[idx++] = ctx.enforcerPub[0];
        pi[idx++] = ctx.enforcerPub[1];
        _requireComplete(idx, PI_LEN_TRANSFER);
    }

    function buildDeposit(
        bytes calldata proof,
        bytes calldata args
    ) external pure override returns (uint256[] memory pi, uint256[8] memory proofWords) {
        (DepositFields memory f, Commonlib.Proof memory ps) = _decodeDeposit(proof);
        uint256 ctxOff = _ctxOffset(args);
        (uint256 amount, uint256[] memory outputs) =
            abi.decode(args[:ctxOff], (uint256, uint256[]));
        ProofContext memory ctx = abi.decode(args[ctxOff:], (ProofContext));

        _requireArity(f.encR.length, ENC_RECEIVER_LEN);
        _requireArity(f.encA.length, ENC_AUTHORITY_LEN);
        _requireArity(f.encE.length, ENC_AUTHORITY_LEN);
        _requireArity(outputs.length, OUTPUTS_LEN);

        proofWords = _proofToWords(ps);
        pi = new uint256[](PI_LEN_DEPOSIT);
        pi[0] = amount;
        uint256 idx = _fillCipher(pi, 1, f.ecdhPub, f.encR, f.encA, f.encE);
        for (uint256 i; i < outputs.length; ++i) {
            pi[idx++] = outputs[i];
        }
        pi[idx++] = ctx.idRoot;
        pi[idx++] = ctx.compRoot;
        pi[idx++] = f.encNonce;
        pi[idx++] = ctx.arbiterPub[0];
        pi[idx++] = ctx.arbiterPub[1];
        pi[idx++] = ctx.enforcerPub[0];
        pi[idx++] = ctx.enforcerPub[1];
        _requireComplete(idx, PI_LEN_DEPOSIT);
    }

    function buildWithdraw(
        bytes calldata proof,
        bytes calldata args
    ) external pure override returns (uint256[] memory pi, uint256[] memory enfNullifiers, uint256 root, uint256[8] memory proofWords) {
        (WithdrawFields memory f, Commonlib.Proof memory ps) = _decodeWithdraw(proof);
        uint256 ctxOff = _ctxOffset(args);
        // `recipient` travels in the args head, not the ProofContext tail: the
        // 192-byte context is shared by all four builders and must not change.
        (uint256 amount, uint256[] memory nullifiers, uint256 output, uint256 recipient) =
            abi.decode(args[:ctxOff], (uint256, uint256[], uint256, uint256));
        ProofContext memory ctx = abi.decode(args[ctxOff:], (ProofContext));

        _requireArity(f.encA.length, ENC_AUTHORITY_LEN);
        _requireArity(f.encE.length, ENC_AUTHORITY_LEN);
        _requireArity(f.enfN.length, ENF_NULLIFIERS_LEN);
        _requireArity(nullifiers.length, NULLIFIERS_LEN);

        enfNullifiers = f.enfN;
        root = f.root;
        proofWords = _proofToWords(ps);
        pi = new uint256[](PI_LEN_WITHDRAW);
        pi[0] = f.ecdhPub[0];
        pi[1] = f.ecdhPub[1];
        uint256 idx = 2;
        for (uint256 i; i < f.encA.length; ++i) {
            pi[idx++] = f.encA[i];
        }
        for (uint256 i; i < f.encE.length; ++i) {
            pi[idx++] = f.encE[i];
        }
        pi[idx++] = amount;
        for (uint256 i; i < nullifiers.length; ++i) {
            pi[idx++] = nullifiers[i];
        }
        for (uint256 i; i < f.enfN.length; ++i) {
            pi[idx++] = f.enfN[i];
        }
        pi[idx++] = output;
        pi[idx++] = f.root;
        pi[idx++] = ctx.idRoot;
        pi[idx++] = ctx.compRoot;
        for (uint256 i; i < nullifiers.length; ++i) {
            pi[idx++] = (nullifiers[i] == 0) ? 0 : 1;
        }
        pi[idx++] = f.encNonce;
        pi[idx++] = ctx.arbiterPub[0];
        pi[idx++] = ctx.arbiterPub[1];
        pi[idx++] = ctx.enforcerPub[0];
        pi[idx++] = ctx.enforcerPub[1];
        pi[idx++] = recipient;
        _requireComplete(idx, PI_LEN_WITHDRAW);
    }

    function buildForcedTransfer(
        bytes calldata proof,
        bytes calldata args
    ) external pure override returns (uint256[] memory pi, uint256[] memory enfNullifiers, uint256 root, uint256[8] memory proofWords) {
        (ForcedTransferFields memory f, Commonlib.Proof memory ps) = _decodeForcedTransfer(proof);
        uint256 ctxOff = _ctxOffset(args);
        (uint256[] memory outputs) =
            abi.decode(args[:ctxOff], (uint256[]));
        ProofContext memory ctx = abi.decode(args[ctxOff:], (ProofContext));

        _requireArity(f.encR.length, ENC_RECEIVER_LEN);
        _requireArity(f.encA.length, ENC_AUTHORITY_LEN);
        _requireArity(f.encE.length, ENC_AUTHORITY_LEN);
        _requireArity(f.enfN.length, ENF_NULLIFIERS_LEN);
        _requireArity(f.enabled.length, ENABLED_LEN);
        _requireArity(outputs.length, OUTPUTS_LEN);

        enfNullifiers = f.enfN;
        root = f.root;
        proofWords = _proofToWords(ps);
        pi = new uint256[](PI_LEN_FORCED_TRANSFER);
        uint256 idx = _fillCipher(pi, 0, f.ecdhPub, f.encR, f.encA, f.encE);
        for (uint256 i; i < f.enfN.length; ++i) {
            pi[idx++] = f.enfN[i];
        }
        for (uint256 i; i < outputs.length; ++i) {
            pi[idx++] = outputs[i];
        }
        pi[idx++] = f.root;
        pi[idx++] = ctx.idRoot;
        pi[idx++] = ctx.compRoot;
        for (uint256 i; i < f.enabled.length; ++i) {
            pi[idx++] = f.enabled[i];
        }
        pi[idx++] = ctx.enforcerPub[0];
        pi[idx++] = ctx.enforcerPub[1];
        pi[idx++] = f.encNonce;
        pi[idx++] = ctx.arbiterPub[0];
        pi[idx++] = ctx.arbiterPub[1];
        _requireComplete(idx, PI_LEN_FORCED_TRANSFER);
    }
}
