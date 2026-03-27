pragma solidity ^0.8.27;

/// @title IZetoEnforced — public API surface for enforced Zeto token variants
/// @dev Paladin's Go domain embeds the compiled ABI of this interface
///   (via go:embed) to call admin, seizure, and nullifier-read functions.
///   Any contract implementing this interface MUST also inherit IZeto,
///   IZetoKyc, and IZetoComplianceRoot for the full enforced feature set.
interface IZetoEnforced {
    // ── errors ──

    error EnforcerAlreadySet();
    error EnforcerNotSet();
    error EnforcementNullifierAlreadySpent(uint256 nullifier);

    // ── events ──

    event ArbiterUpdated(uint256[2] newKey, uint256 keyId);
    event EnforcerSet(uint256[2] newKey);

    /// @dev Emitted by transfer(). Includes all three ciphertext streams
    ///   (receiver, arbiter, enforcer) plus the arbiterKeyId for off-chain
    ///   key version correlation.
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

    /// @dev Emitted by forcedTransfer(). Uses enforcement nullifiers as the
    ///   "inputs" field — input commitments are private witnesses in the
    ///   forced transfer circuit and must never appear on-chain.
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

    // ── authority management ──

    /// @dev Rotatable. Each call increments arbiterKeyId so off-chain
    ///   indexers can version-match ciphertexts to the correct decryption key.
    function setArbiter(uint256[2] memory newKey) external;
    function getArbiter() external view returns (uint256[2] memory);
    function getArbiterKeyId() external view returns (uint256);

    /// @dev Set-once. Rotating the enforcer key would orphan all existing
    ///   enforcement nullifiers (they're derived via ECDH with this key).
    function setEnforcer(uint256[2] memory newKey) external;
    function getEnforcer() external view returns (uint256[2] memory);

    // ── seizure ──

    /// @dev Enforcer-initiated transfer of frozen-owner UTXOs. Only marks
    ///   enforcement nullifiers as spent (not owner nullifiers — the enforcer
    ///   cannot compute them without the owner's private key).
    function forcedTransfer(
        uint256[] calldata outputs,
        bytes calldata proof,
        bytes calldata data
    ) external;

    // ── nullifier read APIs ──

    /// @dev Reads from the external NullifierStorage contract.
    function ownerNullifierSpent(uint256 n) external view returns (bool);

    /// @dev Reads from the local enforcement nullifier mapping.
    function enforcementNullifierSpent(uint256 n) external view returns (bool);

    /// @dev OR semantics: a UTXO is spent if either its owner nullifier or
    ///   its enforcement nullifier has been marked. Wallets should call this
    ///   before attempting an owner spend to detect seized UTXOs.
    function isSpent(uint256 ownerN, uint256 enfN) external view returns (bool);
}