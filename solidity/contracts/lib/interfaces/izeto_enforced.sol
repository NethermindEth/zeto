pragma solidity ^0.8.27;

/// @title IZetoEnforcedEvents — errors and events for enforced Zeto token variants
/// @dev Separated from IZetoEnforced so contracts that only emit events
///   (e.g. the TransferFacet) can inherit without implementing admin functions.
interface IZetoEnforcedEvents {
    error EnforcerAlreadySet();
    error EnforcerNotSet();
    error EnforcementNullifierAlreadySpent(uint256 nullifier);

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

    // enforcer key management (set-once — rotating would orphan existing
    // enforcement nullifiers derived via ECDH with this key)
    function setEnforcer(uint256[2] memory newKey) external;
    function getEnforcer() external view returns (uint256[2] memory);

    // seizure: redirects frozen-owner UTXOs, marks only enforcement nullifiers
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