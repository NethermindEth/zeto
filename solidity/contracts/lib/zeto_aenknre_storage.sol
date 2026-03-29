pragma solidity ^0.8.27;

import {IAENKNRECodec} from "./interfaces/iaenknre_codec.sol";
import {IGroth16Verifier} from "./interfaces/izeto_verifier.sol";

/// @title AENKNREStorage — ERC-7201 namespaced storage shared by the AENKNR-E router and facet
/// @dev Both the router and the TransferFacet import this library so they
///   read/write the same storage slots when the facet executes via DELEGATECALL.
library AENKNREStorage {
    /// @custom:storage-location erc7201:zeto.storage.aenknre
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
        keccak256(abi.encode(uint256(keccak256("zeto.storage.aenknre")) - 1));

    function layout() internal pure returns (Layout storage s) {
        bytes32 slot = STORAGE_SLOT;
        /// @solidity memory-safe-assembly
        assembly {
            s.slot := slot
        }
    }
}
