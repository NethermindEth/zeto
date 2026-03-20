pragma solidity ^0.8.27;

interface IZetoNullifierStorageView {
    /**
     * @dev Returns whether a nullifier has been spent
     * @param n The nullifier to check
     * @return bool whether the nullifier is spent
     */
    function nullifierSpent(uint256 n) external view returns (bool);
}