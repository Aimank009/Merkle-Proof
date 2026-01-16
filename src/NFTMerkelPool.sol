// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./interfaces/IMerklePool.sol";
import "./events/MerklePoolEvents.sol";
import "./interfaces/INFTCollection.sol";

contract NFTMerklePool is
    Ownable,
    ReentrancyGuard,
    IMerklePool,
    MerklePoolEvents
{
    address public nftCollection;
    bytes32 public merkleRoot;
    uint256 public mintPrice;
    bool public whitelistMintEnabled;
    mapping(address => bool) public hasMinted;

    constructor(
        address _nftCollection,
        bytes32 _merkleRoot,
        uint256 _mintPrice
    ) Ownable(msg.sender) {
        nftCollection = _nftCollection;
        merkleRoot = _merkleRoot;
        mintPrice = _mintPrice;
    }

    function isWhitelisted(
        address _user,
        bytes32[] calldata _proof
    ) public view override returns (bool) {
        bytes32 leaf = keccak256((abi.encodePacked(_user)));

        return MerkleProof.verify(_proof, merkleRoot, leaf);
    }

    function whitelistMint(
        bytes32[] calldata _proof
    ) external payable override nonReentrant returns (uint256) {
        require(whitelistMintEnabled, "WhiteList mint not enabled");
        require(msg.value >= mintPrice, "Insufficient Payment");
        require(!hasMinted[msg.sender], "Already Minted");
        require(isWhitelisted(msg.sender, _proof), "Not Whitelisted");

        hasMinted[msg.sender] = true;

        uint256 tokenId = INFTCollection(nftCollection).minterMint(msg.sender);
        emit WhitelistMint(msg.sender, tokenId);

        return tokenId;
    }

    function setMerkleRoot(bytes32 _newRoot) external onlyOwner {
        bytes32 oldMerkleRoot = merkleRoot;
        merkleRoot = _newRoot;
        emit MerkleRootUpdated(oldMerkleRoot, merkleRoot);
    }

    function setWhiteListEnabled(bool _enabled) external onlyOwner {
        whitelistMintEnabled = _enabled;
        emit WhitelistMintingEnabled(_enabled);
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "Insufficient balance");
        (bool success, ) = payable(owner()).call{value: balance}("");
        require(success, "Withdraw failed");
    }
}
