// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IMerklePool {
    function whitelistMint(
        bytes32[] calldata proof
    ) external payable returns (uint256);
    function isWhitelisted(
        address user,
        bytes32[] calldata proof
    ) external view returns (bool);
    function merkleRoot() external view returns (bytes32);
    function hasMinted(address user) external view returns (bool);
}
