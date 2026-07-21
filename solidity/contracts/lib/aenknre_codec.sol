pragma solidity ^0.8.27;

import {Commonlib} from "./common/common.sol";
import {IAENKNRECodec} from "./interfaces/iaenknre_codec.sol";

/// @title AENKNRECodec — proof decoder and public-input assembler for AENKNR-E
/// @dev Each build* function decodes the proof bytes (circuit-specific fields +
///   Groth16 proof), decodes the packed args (call parameters + ProofContext),
///   and assembles the public-input array matching the circuit's signal ordering.
contract AENKNRECodec is IAENKNRECodec {
    // Decoded proof field structs — one per circuit
    struct TransferFields {
        uint256 root; uint256[] enfN; uint256 encNonce;
        uint256[2] ecdhPub; uint256[] encR; uint256[] encA; uint256[] encE;
    }
    struct DepositFields {
        uint256 encNonce; uint256[2] ecdhPub;
        uint256[] encR; uint256[] encA; uint256[] encE;
    }
    struct WithdrawFields {
        uint256 root; uint256[] enfN; uint256 encNonce;
        uint256[2] ecdhPub; uint256[] encA; uint256[] encE;
    }
    struct ForcedTransferFields {
        uint256[] enfN; uint256 root; uint256[] enabled; uint256 encNonce;
        uint256[2] ecdhPub; uint256[] encR; uint256[] encA; uint256[] encE;
    }

    // ── Proof decoders ──

    function _proofToWords(Commonlib.Proof memory ps) private pure returns (uint256[8] memory w) {
        w[0] = ps.pA[0]; w[1] = ps.pA[1];
        w[2] = ps.pB[0][0]; w[3] = ps.pB[0][1];
        w[4] = ps.pB[1][0]; w[5] = ps.pB[1][1];
        w[6] = ps.pC[0]; w[7] = ps.pC[1];
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

    // ── Shared helpers ──

    /// @dev Fills ecdhPub + encReceiver + encArbiter + encEnforcer into pi starting at index s.
    function _fillCipher(
        uint256[] memory pi, uint256 s,
        uint256[2] memory ep, uint256[] memory eR, uint256[] memory eA, uint256[] memory eE
    ) private pure returns (uint256 idx) {
        pi[s] = ep[0]; pi[s+1] = ep[1]; idx = s + 2;
        for (uint256 i; i < eR.length; ++i) pi[idx++] = eR[i];
        for (uint256 i; i < eA.length; ++i) pi[idx++] = eA[i];
        for (uint256 i; i < eE.length; ++i) pi[idx++] = eE[i];
    }

    /// @dev Decodes the packed args: the first portion is standard ABI encoding,
    ///   the last 192 bytes are 6 raw uint256 words encoding ProofContext.
    function _splitArgs(bytes calldata args) private pure returns (uint256 ctxOff) {
        ctxOff = args.length - 192;
    }

    // ── Public-input assemblers ──
    // Each function matches one circuit's signal ordering exactly.
    // Signal counts: transfer=58, deposit=52, withdraw=50, forcedTransfer=56.

    function buildTransfer(
        bytes calldata proof,
        bytes calldata args
    ) external pure override returns (uint256[] memory pi, uint256[] memory enfNullifiers, uint256[8] memory proofWords) {
        (TransferFields memory f, Commonlib.Proof memory ps) = _decodeTransfer(proof);
        uint256 ctxOff = _splitArgs(args);
        (uint256[] memory nullifiers, uint256[] memory outputs) =
            abi.decode(args[:ctxOff], (uint256[], uint256[]));
        ProofContext memory ctx = abi.decode(args[ctxOff:], (ProofContext));

        enfNullifiers = f.enfN;
        proofWords = _proofToWords(ps);
        pi = new uint256[](58);
        uint256 idx = _fillCipher(pi, 0, f.ecdhPub, f.encR, f.encA, f.encE);
        for (uint256 i; i < nullifiers.length; ++i) pi[idx++] = nullifiers[i];
        for (uint256 i; i < f.enfN.length; ++i) pi[idx++] = f.enfN[i];
        pi[idx++] = f.root;
        for (uint256 i; i < nullifiers.length; ++i) pi[idx++] = (nullifiers[i] == 0) ? 0 : 1;
        pi[idx++] = ctx.idRoot; pi[idx++] = ctx.compRoot;
        for (uint256 i; i < outputs.length; ++i) pi[idx++] = outputs[i];
        pi[idx++] = f.encNonce;
        pi[idx++] = ctx.arbiterPub[0]; pi[idx++] = ctx.arbiterPub[1];
        pi[idx++] = ctx.enforcerPub[0]; pi[idx++] = ctx.enforcerPub[1];
    }

    function buildDeposit(
        bytes calldata proof,
        bytes calldata args
    ) external pure override returns (uint256[] memory pi, uint256[8] memory proofWords) {
        (DepositFields memory f, Commonlib.Proof memory ps) = _decodeDeposit(proof);
        uint256 ctxOff = _splitArgs(args);
        (uint256 amount, uint256[] memory outputs) =
            abi.decode(args[:ctxOff], (uint256, uint256[]));
        ProofContext memory ctx = abi.decode(args[ctxOff:], (ProofContext));

        proofWords = _proofToWords(ps);
        pi = new uint256[](52);
        pi[0] = amount;
        uint256 idx = _fillCipher(pi, 1, f.ecdhPub, f.encR, f.encA, f.encE);
        for (uint256 i; i < outputs.length; ++i) pi[idx++] = outputs[i];
        pi[idx++] = ctx.idRoot; pi[idx++] = ctx.compRoot;
        pi[idx++] = f.encNonce;
        pi[idx++] = ctx.arbiterPub[0]; pi[idx++] = ctx.arbiterPub[1];
        pi[idx++] = ctx.enforcerPub[0]; pi[idx++] = ctx.enforcerPub[1];
    }

    function buildWithdraw(
        bytes calldata proof,
        bytes calldata args
    ) external pure override returns (uint256[] memory pi, uint256[] memory enfNullifiers, uint256[8] memory proofWords) {
        (WithdrawFields memory f, Commonlib.Proof memory ps) = _decodeWithdraw(proof);
        uint256 ctxOff = _splitArgs(args);
        (uint256 amount, uint256[] memory nullifiers, uint256 output) =
            abi.decode(args[:ctxOff], (uint256, uint256[], uint256));
        ProofContext memory ctx = abi.decode(args[ctxOff:], (ProofContext));

        enfNullifiers = f.enfN;
        proofWords = _proofToWords(ps);
        pi = new uint256[](50);
        pi[0] = f.ecdhPub[0]; pi[1] = f.ecdhPub[1]; uint256 idx = 2;
        for (uint256 i; i < f.encA.length; ++i) pi[idx++] = f.encA[i];
        for (uint256 i; i < f.encE.length; ++i) pi[idx++] = f.encE[i];
        pi[idx++] = amount;
        for (uint256 i; i < nullifiers.length; ++i) pi[idx++] = nullifiers[i];
        for (uint256 i; i < f.enfN.length; ++i) pi[idx++] = f.enfN[i];
        pi[idx++] = output; pi[idx++] = f.root;
        pi[idx++] = ctx.idRoot; pi[idx++] = ctx.compRoot;
        for (uint256 i; i < nullifiers.length; ++i) pi[idx++] = (nullifiers[i] == 0) ? 0 : 1;
        pi[idx++] = f.encNonce;
        pi[idx++] = ctx.arbiterPub[0]; pi[idx++] = ctx.arbiterPub[1];
        pi[idx++] = ctx.enforcerPub[0]; pi[idx++] = ctx.enforcerPub[1];
    }

    function buildForcedTransfer(
        bytes calldata proof,
        bytes calldata args
    ) external pure override returns (uint256[] memory pi, uint256[] memory enfNullifiers, uint256 root, uint256[8] memory proofWords) {
        (ForcedTransferFields memory f, Commonlib.Proof memory ps) = _decodeForcedTransfer(proof);
        uint256 ctxOff = _splitArgs(args);
        (uint256[] memory outputs) =
            abi.decode(args[:ctxOff], (uint256[]));
        ProofContext memory ctx = abi.decode(args[ctxOff:], (ProofContext));

        enfNullifiers = f.enfN; root = f.root;
        proofWords = _proofToWords(ps);
        pi = new uint256[](56);
        uint256 idx = _fillCipher(pi, 0, f.ecdhPub, f.encR, f.encA, f.encE);
        for (uint256 i; i < f.enfN.length; ++i) pi[idx++] = f.enfN[i];
        for (uint256 i; i < outputs.length; ++i) pi[idx++] = outputs[i];
        pi[idx++] = f.root; pi[idx++] = ctx.idRoot; pi[idx++] = ctx.compRoot;
        for (uint256 i; i < f.enabled.length; ++i) pi[idx++] = f.enabled[i];
        pi[idx++] = ctx.enforcerPub[0]; pi[idx++] = ctx.enforcerPub[1];
        pi[idx++] = f.encNonce;
        pi[idx++] = ctx.arbiterPub[0]; pi[idx++] = ctx.arbiterPub[1];
    }
}
