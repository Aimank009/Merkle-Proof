// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface INFTCollection {
    function mint(address to) external payable returns (uint256);
    function totalSupply() external view returns (uint256);
    function maxSupply() external view returns (uint256);
    function baseURI() external view returns (string memory);
    function minterMint(address to) external returns (uint256);
}
