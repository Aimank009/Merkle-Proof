// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/NFTMerkelPool.sol";

contract MockNFTCollection {
    uint256 private _nextTokenId;
    address public minter;
    address public owner;
    mapping(uint256 => address) public ownerOf;

    constructor() {
        owner = msg.sender;
    }

    function setMinter(address _minter) external {
        minter = _minter;
    }

    function minterMint(address to) external returns (uint256) {
        require(msg.sender == minter || msg.sender == owner, "Not authorized");
        uint256 tokenId = _nextTokenId;
        _nextTokenId++;
        ownerOf[tokenId] = to;
        return tokenId;
    }
}

contract NFTMerklePoolTest is Test {
    NFTMerklePool public pool;
    MockNFTCollection public nft;

    address public owner = address(this);
    address public user1 = address(0x1);
    address public user2 = address(0x2);
    address public user3 = address(0x3);
    address public user4 = address(0x4);
    address public nonWhitelisted = address(0x9999);

    bytes32 public merkleRoot;
    uint256 public constant MINT_PRICE = 0.05 ether;

    bytes32[] public user1Proof;
    bytes32[] public user2Proof;

    function setUp() public {
        bytes32 leaf1 = keccak256(abi.encodePacked(user1));
        bytes32 leaf2 = keccak256(abi.encodePacked(user2));
        bytes32 leaf3 = keccak256(abi.encodePacked(user3));
        bytes32 leaf4 = keccak256(abi.encodePacked(user4));

        bytes32 node1 = _hashPair(leaf1, leaf2);
        bytes32 node2 = _hashPair(leaf3, leaf4);

        merkleRoot = _hashPair(node1, node2);

        user1Proof.push(leaf2);
        user1Proof.push(node2);

        user2Proof.push(leaf1);
        user2Proof.push(node2);

        nft = new MockNFTCollection();
        pool = new NFTMerklePool(address(nft), merkleRoot, MINT_PRICE);

        nft.setMinter(address(pool));

        vm.deal(user1, 10 ether);
        vm.deal(user2, 10 ether);
        vm.deal(user3, 10 ether);
        vm.deal(nonWhitelisted, 10 ether);
    }

    function _hashPair(bytes32 a, bytes32 b) internal pure returns (bytes32) {
        return
            a < b
                ? keccak256(abi.encodePacked(a, b))
                : keccak256(abi.encodePacked(b, a));
    }

    //Done here

    receive() external payable {}

    function test_Constructor() public view {
        assertEq(pool.nftCollection(), address(nft));
        assertEq(pool.merkleRoot(), merkleRoot);
        assertEq(pool.mintPrice(), MINT_PRICE);
        assertEq(pool.whitelistMintEnabled(), false);
    }

    function test_IsWhitelisted() public view {
        assertTrue(pool.isWhitelisted(user1, user1Proof));
        assertTrue(pool.isWhitelisted(user2, user2Proof));
    }

    function test_IsNotWhitelisted() public view {
        assertFalse(pool.isWhitelisted(nonWhitelisted, user1Proof));
    }

    function test_WhitelistMint() public {
        pool.setWhiteListEnabled(true);

        vm.prank(user1);
        uint256 tokenId = pool.whitelistMint{value: MINT_PRICE}(user1Proof);

        assertEq(tokenId, 0);
        assertEq(nft.ownerOf(0), user1);
        assertTrue(pool.hasMinted(user1));
    }

    function test_WhitelistMintMultipleUsers() public {
        pool.setWhiteListEnabled(true);

        vm.prank(user1);
        pool.whitelistMint{value: MINT_PRICE}(user1Proof);

        vm.prank(user2);
        pool.whitelistMint{value: MINT_PRICE}(user2Proof);

        assertEq(nft.ownerOf(0), user1);
        assertEq(nft.ownerOf(1), user2);
    }

    function test_WhitelistMintRevertsNotEnabled() public {
        vm.prank(user1);
        vm.expectRevert("WhiteList mint not enabled");
        pool.whitelistMint{value: MINT_PRICE}(user1Proof);
    }

    function test_WhitelistMintRevertsInsufficientPayment() public {
        pool.setWhiteListEnabled(true);

        vm.prank(user1);
        vm.expectRevert("Insufficient Payment");
        pool.whitelistMint{value: 0.01 ether}(user1Proof);
    }

    function test_WhitelistMintRevertsAlreadyMinted() public {
        pool.setWhiteListEnabled(true);

        vm.prank(user1);
        pool.whitelistMint{value: MINT_PRICE}(user1Proof);

        vm.prank(user1);
        vm.expectRevert("Already Minted");
        pool.whitelistMint{value: MINT_PRICE}(user1Proof);
    }

    function test_WhitelistMintRevertsNotWhitelisted() public {
        pool.setWhiteListEnabled(true);

        vm.prank(nonWhitelisted);
        vm.expectRevert("Not Whitelisted");
        pool.whitelistMint{value: MINT_PRICE}(user1Proof);
    }

    function test_SetMerkleRoot() public {
        bytes32 newRoot = keccak256("new root");
        pool.setMerkleRoot(newRoot);
        assertEq(pool.merkleRoot(), newRoot);
    }

    function test_SetMerkleRootRevertsNotOwner() public {
        vm.prank(user1);
        vm.expectRevert();
        pool.setMerkleRoot(keccak256("new root"));
    }

    function test_SetWhiteListEnabled() public {
        pool.setWhiteListEnabled(true);
        assertTrue(pool.whitelistMintEnabled());

        pool.setWhiteListEnabled(false);
        assertFalse(pool.whitelistMintEnabled());
    }

    function test_SetWhiteListEnabledRevertsNotOwner() public {
        vm.prank(user1);
        vm.expectRevert();
        pool.setWhiteListEnabled(true);
    }

    function test_Withdraw() public {
        pool.setWhiteListEnabled(true);

        vm.prank(user1);
        pool.whitelistMint{value: MINT_PRICE}(user1Proof);

        uint256 contractBalance = address(pool).balance;
        uint256 ownerBalanceBefore = owner.balance;

        pool.withdraw();

        assertEq(address(pool).balance, 0);
        assertEq(owner.balance, ownerBalanceBefore + contractBalance);
    }

    function test_WithdrawRevertsNoBalance() public {
        vm.expectRevert("Insufficient balance");
        pool.withdraw();
    }

    function test_WithdrawRevertsNotOwner() public {
        pool.setWhiteListEnabled(true);

        vm.prank(user1);
        pool.whitelistMint{value: MINT_PRICE}(user1Proof);

        vm.prank(user1);
        vm.expectRevert();
        pool.withdraw();
    }
}
