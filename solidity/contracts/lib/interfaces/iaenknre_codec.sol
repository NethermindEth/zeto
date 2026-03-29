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