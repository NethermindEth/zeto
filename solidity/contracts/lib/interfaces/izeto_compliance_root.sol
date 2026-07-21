pragma solidity ^0.8.27;

interface IZetoComplianceRoot {
    event ComplianceRootUpdated(
        uint256 oldRoot,
        uint256 newRoot,
        bytes data
    );

    function setComplianceRoot(
        uint256 newRoot,
        bytes calldata data
    ) external;

    function getComplianceRoot() external view returns (uint256);
}