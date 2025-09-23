// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console2} from "forge-std/Test.sol";
import {MerkleAirdrop} from "../src/MerkleAirdrop.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {BagelToken} from "../src/BagelToken.sol";
import {ZkSyncChainChecker} from "lib/foundry-devops/src/ZkSyncChainChecker.sol";
import {DeployMerkleAirdrop} from "../script/DeployMerkleAirdrop.s.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title Comprehensive Test Suite for BagelToken and MerkleAirdrop contracts
 * @author Varun Chauhan
 * @notice Tests cover all functionality including edge cases, security features, and error conditions
 */
contract MerkleAirdropTest is ZkSyncChainChecker, Test {
    /*//////////////////////////////////////////////////////////////
                            STATE VARIABLES
    //////////////////////////////////////////////////////////////*/
    
    MerkleAirdrop public merkleAirdrop;
    BagelToken public bagelToken;
    
    // Test accounts
    address public owner;
    address public gasPayer;
    address public user;
    address public user2;
    address public unauthorizedUser;
    uint256 public privateKey;
    uint256 public privateKey2;
    uint256 public unauthorizedPrivateKey;
    
    // Merkle proof data (from the actual merkle tree)
    bytes32 proof1 = 0x0fd7c981d39bece61f7499702bf59b3114a90e66b51ba2c53abdf7b62986c00a;
    bytes32 proof2 = 0xe5ebd1e1b5a5478a944ecab36a9a954ac3b6b8216875f6524caa7a1d87096576;
    bytes32[] public PROOF = [proof1, proof2];
    
    // Invalid proof for testing
    bytes32[] public INVALID_PROOF;
    
    // Test constants
    uint256 public constant AMOUNT_TO_CLAIM = 25e18;
    uint256 public constant INVALID_AMOUNT = 30e18;
    uint256 public constant AMOUNT_TO_SEND = AMOUNT_TO_CLAIM * 4;
    uint256 public constant INITIAL_MINT = 1000e18;
    
    bytes32 public merkleRoot = 0xaa5d581231e596618465a56aa0f5870ba6e20785fe436d5bfb82b08662ccc7c4;

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/
    
    event Claimed(address indexed account, uint256 amount);

    /*//////////////////////////////////////////////////////////////
                               SETUP
    //////////////////////////////////////////////////////////////*/
    
    function setUp() public {
        // Create test accounts
        (user, privateKey) = makeAddrAndKey("user");
        (user2, privateKey2) = makeAddrAndKey("user2");
        (unauthorizedUser, unauthorizedPrivateKey) = makeAddrAndKey("unauthorizedUser");
        gasPayer = makeAddr("gasPayer");
        
        // Deploy contracts
        if (!isZkSyncChain()) {
            DeployMerkleAirdrop deployer = new DeployMerkleAirdrop();
            (merkleAirdrop, bagelToken) = deployer.deployMerkleAirdrop();
            owner = bagelToken.owner();
        } else {
            bagelToken = new BagelToken();
            owner = address(this);
            merkleAirdrop = new MerkleAirdrop(merkleRoot, bagelToken);
            
            // Mint and transfer tokens to airdrop contract
            bagelToken.mint(owner, AMOUNT_TO_SEND);
            bagelToken.transfer(address(merkleAirdrop), AMOUNT_TO_SEND);
        }
        
        // Fund gasPayer for transaction costs
        vm.deal(gasPayer, 10 ether);
        
        // Initialize invalid proof array
        INVALID_PROOF.push(0x1234567890123456789012345678901234567890123456789012345678901234);
        INVALID_PROOF.push(0x5678901234567890123456789012345678901234567890123456789012345678);
    }

    /*//////////////////////////////////////////////////////////////
                         BAGELTOKEN TESTS
    //////////////////////////////////////////////////////////////*/
    
    /**
     * @notice Test BagelToken deployment and initial state
     */
    function test_BagelToken_DeploymentState() public view {
        assertEq(bagelToken.name(), "Bagel Token");
        assertEq(bagelToken.symbol(), "BT");
        assertEq(bagelToken.decimals(), 18);
        assertEq(bagelToken.totalSupply(), AMOUNT_TO_SEND);
        assertNotEq(bagelToken.owner(), address(0));
    }
    
    /**
     * @notice Test successful minting by owner
     */
    function test_BagelToken_MintSuccess() public {
        uint256 mintAmount = 100e18;
        uint256 initialSupply = bagelToken.totalSupply();
        uint256 initialBalance = bagelToken.balanceOf(user);
        
        vm.prank(owner);
        bagelToken.mint(user, mintAmount);
        
        assertEq(bagelToken.totalSupply(), initialSupply + mintAmount);
        assertEq(bagelToken.balanceOf(user), initialBalance + mintAmount);
    }
    
    /**
     * @notice Test minting by non-owner should revert
     */
    function test_BagelToken_MintUnauthorizedReverts() public {
        uint256 mintAmount = 100e18;
        
        vm.prank(unauthorizedUser);
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, unauthorizedUser));
        bagelToken.mint(user, mintAmount);
    }
    
    /**
     * @notice Test minting to zero address should revert
     */
    function test_BagelToken_MintToZeroAddressReverts() public {
        uint256 mintAmount = 100e18;
        
        vm.prank(owner);
        vm.expectRevert();
        bagelToken.mint(address(0), mintAmount);
    }
    
    /**
     * @notice Test ownership transfer functionality
     */
    function test_BagelToken_OwnershipTransfer() public {
        vm.prank(owner);
        bagelToken.transferOwnership(user);
        
        assertEq(bagelToken.owner(), user);
        
        // Test that old owner can't mint anymore
        vm.prank(owner);
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, owner));
        bagelToken.mint(user2, 100e18);
        
        // Test that new owner can mint
        vm.prank(user);
        bagelToken.mint(user2, 100e18);
        assertEq(bagelToken.balanceOf(user2), 100e18);
    }

    /*//////////////////////////////////////////////////////////////
                       MERKLEAIRDROP TESTS
    //////////////////////////////////////////////////////////////*/
    
    /**
     * @notice Test MerkleAirdrop deployment and initial state
     */
    function test_MerkleAirdrop_DeploymentState() public view {
        assertEq(merkleAirdrop.getMerkleRoot(), merkleRoot);
        assertEq(address(merkleAirdrop.getAirdropToken()), address(bagelToken));
        assertEq(merkleAirdrop.hasClaimed(user), false);
        assertEq(merkleAirdrop.hasClaimed(user2), false);
    }
    
    /**
     * @notice Test successful claim with valid signature and proof
     */
    function test_MerkleAirdrop_SuccessfulClaim() public {
        uint256 userBalanceBefore = bagelToken.balanceOf(user);
        uint256 contractBalanceBefore = bagelToken.balanceOf(address(merkleAirdrop));
        
        // Generate valid signature
        bytes32 digest = merkleAirdrop.getMessageHash(user, AMOUNT_TO_CLAIM);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(privateKey, digest);
        
        // Expect Claimed event to be emitted
        vm.expectEmit(true, false, false, true);
        emit Claimed(user, AMOUNT_TO_CLAIM);
        
        // Execute claim
        vm.prank(gasPayer);
        merkleAirdrop.claim(user, AMOUNT_TO_CLAIM, PROOF, v, r, s);
        
        // Verify results
        assertEq(bagelToken.balanceOf(user), userBalanceBefore + AMOUNT_TO_CLAIM);
        assertEq(bagelToken.balanceOf(address(merkleAirdrop)), contractBalanceBefore - AMOUNT_TO_CLAIM);
        assertEq(merkleAirdrop.hasClaimed(user), true);
    }
    
    /**
     * @notice Test claim with invalid signature should revert
     */
    function test_MerkleAirdrop_InvalidSignatureReverts() public {
        // Generate signature for different user
        bytes32 digest = merkleAirdrop.getMessageHash(user2, AMOUNT_TO_CLAIM);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(privateKey2, digest);
        
        // Try to claim with wrong signature
        vm.prank(gasPayer);
        vm.expectRevert(MerkleAirdrop.MerkleAirdrop__InvalidSignature.selector);
        merkleAirdrop.claim(user, AMOUNT_TO_CLAIM, PROOF, v, r, s);
    }
    
    /**
     * @notice Test claim with invalid merkle proof should revert
     */
    function test_MerkleAirdrop_InvalidProofReverts() public {
        // Generate valid signature
        bytes32 digest = merkleAirdrop.getMessageHash(user, AMOUNT_TO_CLAIM);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(privateKey, digest);
        
        // Use invalid proof
        vm.prank(gasPayer);
        vm.expectRevert(MerkleAirdrop.MerkleAirdrop__InvalidProof.selector);
        merkleAirdrop.claim(user, AMOUNT_TO_CLAIM, INVALID_PROOF, v, r, s);
    }
    
    /**
     * @notice Test claim with wrong amount should revert
     */
    function test_MerkleAirdrop_WrongAmountReverts() public {
        // Generate signature for wrong amount
        bytes32 digest = merkleAirdrop.getMessageHash(user, INVALID_AMOUNT);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(privateKey, digest);
        
        // Try to claim with wrong amount
        vm.prank(gasPayer);
        vm.expectRevert(MerkleAirdrop.MerkleAirdrop__InvalidProof.selector);
        merkleAirdrop.claim(user, INVALID_AMOUNT, PROOF, v, r, s);
    }
    
    /**
     * @notice Test double claim should revert
     */
    function test_MerkleAirdrop_DoubleClaimReverts() public {
        // First successful claim
        bytes32 digest = merkleAirdrop.getMessageHash(user, AMOUNT_TO_CLAIM);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(privateKey, digest);
        
        vm.prank(gasPayer);
        merkleAirdrop.claim(user, AMOUNT_TO_CLAIM, PROOF, v, r, s);
        
        // Second attempt should revert
        vm.prank(gasPayer);
        vm.expectRevert(MerkleAirdrop.MerkleAirdrop__AlreadyClaimed.selector);
        merkleAirdrop.claim(user, AMOUNT_TO_CLAIM, PROOF, v, r, s);
    }
    
    /**
     * @notice Test malformed signature should revert
     */
    function test_MerkleAirdrop_MalformedSignatureReverts() public {
        // Use invalid signature components
        uint8 v = 0;
        bytes32 r = bytes32(0);
        bytes32 s = bytes32(0);
        
        vm.prank(gasPayer);
        vm.expectRevert(MerkleAirdrop.MerkleAirdrop__InvalidSignature.selector);
        merkleAirdrop.claim(user, AMOUNT_TO_CLAIM, PROOF, v, r, s);
    }
    
    /**
     * @notice Test EIP712 message hash generation
     */
    function test_MerkleAirdrop_MessageHashGeneration() public view {
        bytes32 hash1 = merkleAirdrop.getMessageHash(user, AMOUNT_TO_CLAIM);
        bytes32 hash2 = merkleAirdrop.getMessageHash(user, AMOUNT_TO_CLAIM);
        bytes32 hash3 = merkleAirdrop.getMessageHash(user2, AMOUNT_TO_CLAIM);
        bytes32 hash4 = merkleAirdrop.getMessageHash(user, INVALID_AMOUNT);
        
        // Same inputs should produce same hash
        assertEq(hash1, hash2);
        
        // Different inputs should produce different hashes
        assertNotEq(hash1, hash3);
        assertNotEq(hash1, hash4);
        
        // Hash should not be zero
        assertNotEq(hash1, bytes32(0));
    }
    
    /**
     * @notice Test claim state tracking
     */
    function test_MerkleAirdrop_ClaimStateTracking() public {
        // Initially, no one has claimed
        assertFalse(merkleAirdrop.hasClaimed(user));
        assertFalse(merkleAirdrop.hasClaimed(user2));
        
        // After user claims
        bytes32 digest = merkleAirdrop.getMessageHash(user, AMOUNT_TO_CLAIM);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(privateKey, digest);
        
        vm.prank(gasPayer);
        merkleAirdrop.claim(user, AMOUNT_TO_CLAIM, PROOF, v, r, s);
        
        // Only user should be marked as claimed
        assertTrue(merkleAirdrop.hasClaimed(user));
        assertFalse(merkleAirdrop.hasClaimed(user2));
    }
    
    /**
     * @notice Test view functions return correct values
     */
    function test_MerkleAirdrop_ViewFunctions() public view {
        bytes32 root = merkleAirdrop.getMerkleRoot();
        IERC20 token = merkleAirdrop.getAirdropToken();
        
        assertEq(root, merkleRoot);
        assertEq(address(token), address(bagelToken));
    }

    /*//////////////////////////////////////////////////////////////
                         INTEGRATION TESTS
    //////////////////////////////////////////////////////////////*/
    
    /**
     * @notice Test multiple users claiming successfully
     */
    function test_Integration_MultipleUsersClaiming() public {
        // This test would require multiple valid merkle proofs
        // For now, we'll test that multiple users can have different claim states
        
        // User1 claims
        bytes32 digest1 = merkleAirdrop.getMessageHash(user, AMOUNT_TO_CLAIM);
        (uint8 v1, bytes32 r1, bytes32 s1) = vm.sign(privateKey, digest1);
        
        vm.prank(gasPayer);
        merkleAirdrop.claim(user, AMOUNT_TO_CLAIM, PROOF, v1, r1, s1);
        
        // Verify user1 claimed, user2 hasn't
        assertTrue(merkleAirdrop.hasClaimed(user));
        assertFalse(merkleAirdrop.hasClaimed(user2));
        
        // Verify balances
        assertEq(bagelToken.balanceOf(user), AMOUNT_TO_CLAIM);
        assertEq(bagelToken.balanceOf(user2), 0);
    }
    
    /**
     * @notice Test contract can handle insufficient token balance
     */
    function test_Integration_InsufficientTokenBalance() public {
        // Deploy new contracts with insufficient balance
        BagelToken newToken = new BagelToken();
        MerkleAirdrop newAirdrop = new MerkleAirdrop(merkleRoot, newToken);
        
        // Only mint 1 token (insufficient for claim)
        newToken.mint(address(newAirdrop), 1);
        
        // Generate valid signature for new airdrop
        bytes32 digest = newAirdrop.getMessageHash(user, AMOUNT_TO_CLAIM);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(privateKey, digest);
        
        // Should revert due to insufficient balance
        vm.prank(gasPayer);
        vm.expectRevert();
        newAirdrop.claim(user, AMOUNT_TO_CLAIM, PROOF, v, r, s);
    }

    /*//////////////////////////////////////////////////////////////
                           FUZZ TESTS
    //////////////////////////////////////////////////////////////*/
    
    /**
     * @notice Fuzz test for BagelToken minting with various amounts
     */
    function testFuzz_BagelToken_Mint(uint256 amount) public {
        // Bound amount to reasonable range to avoid overflow
        amount = bound(amount, 1, type(uint128).max);
        
        uint256 initialSupply = bagelToken.totalSupply();
        uint256 initialBalance = bagelToken.balanceOf(user);
        
        vm.prank(owner);
        bagelToken.mint(user, amount);
        
        assertEq(bagelToken.totalSupply(), initialSupply + amount);
        assertEq(bagelToken.balanceOf(user), initialBalance + amount);
    }
    
    /**
     * @notice Fuzz test for MerkleAirdrop message hash generation
     */
    function testFuzz_MerkleAirdrop_MessageHash(address account, uint256 amount) public view {
        vm.assume(account != address(0));
        amount = bound(amount, 1, type(uint128).max);
        
        bytes32 hash = merkleAirdrop.getMessageHash(account, amount);
        
        // Hash should never be zero for valid inputs
        assertNotEq(hash, bytes32(0));
        
        // Same inputs should always produce same hash
        assertEq(hash, merkleAirdrop.getMessageHash(account, amount));
    }

    /*//////////////////////////////////////////////////////////////
                         EDGE CASE TESTS
    //////////////////////////////////////////////////////////////*/
    
    /**
     * @notice Test claiming with maximum uint256 amount (edge case)
     */
    function test_EdgeCase_MaxAmount() public {
        // This would fail at merkle proof verification since the amount 
        // wouldn't be in the tree, but tests the signature mechanism
        uint256 maxAmount = type(uint256).max;
        
        bytes32 digest = merkleAirdrop.getMessageHash(user, maxAmount);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(privateKey, digest);
        
        vm.prank(gasPayer);
        vm.expectRevert(MerkleAirdrop.MerkleAirdrop__InvalidProof.selector);
        merkleAirdrop.claim(user, maxAmount, PROOF, v, r, s);
    }
    
    /**
     * @notice Test with empty merkle proof array
     */
    function test_EdgeCase_EmptyProof() public {
        bytes32[] memory emptyProof = new bytes32[](0);
        
        bytes32 digest = merkleAirdrop.getMessageHash(user, AMOUNT_TO_CLAIM);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(privateKey, digest);
        
        vm.prank(gasPayer);
        vm.expectRevert(MerkleAirdrop.MerkleAirdrop__InvalidProof.selector);
        merkleAirdrop.claim(user, AMOUNT_TO_CLAIM, emptyProof, v, r, s);
    }

    /*//////////////////////////////////////////////////////////////
                            HELPER FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    
    /**
     * @notice Helper function to create a valid claim
     */
    function _createValidClaim(address claimant, uint256 claimantPrivateKey) internal {
        bytes32 digest = merkleAirdrop.getMessageHash(claimant, AMOUNT_TO_CLAIM);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(claimantPrivateKey, digest);
        
        vm.prank(gasPayer);
        merkleAirdrop.claim(claimant, AMOUNT_TO_CLAIM, PROOF, v, r, s);
    }
}
