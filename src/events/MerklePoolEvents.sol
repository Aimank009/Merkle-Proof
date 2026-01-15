// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

abstract contract MerklePoolEvents {
    event WhitelistMint(address indexed user, uint256 indexed tokenId);
    event MerkleRootUpdated(bytes32 oldRoot, bytes32 newRoot);
    event WhitelistMintingEnabled(bool enabled);
}
