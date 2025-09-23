// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console2} from "forge-std/Test.sol";
import {BagelToken} from "../src/BagelToken.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title BagelToken Comprehensive Test Suite
 * @author Varun Chauhan
 * @notice Focused test suite for BagelToken contract functionality
 * @dev Tests cover all ERC20 functionality, ownership features, and edge cases
 */
contract BagelTokenTest is Test {
    /*//////////////////////////////////////////////////////////////
                            STATE VARIABLES
    //////////////////////////////////////////////////////////////*/

    BagelToken public bagelToken;
    address public owner;
    address public user1;
    address public user2;
    address public unauthorizedUser;

    // Test constants
    uint256 public constant INITIAL_MINT = 1000e18;
    uint256 public constant MINT_AMOUNT = 100e18;
    uint256 public constant TRANSFER_AMOUNT = 50e18;

    /*//////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    /*//////////////////////////////////////////////////////////////
                               SETUP
    //////////////////////////////////////////////////////////////*/

    function setUp() public {
        // Deploy BagelToken
        bagelToken = new BagelToken();
        owner = address(this);

        // Create test users
        user1 = makeAddr("user1");
        user2 = makeAddr("user2");
        unauthorizedUser = makeAddr("unauthorizedUser");

        // Mint initial supply to owner
        bagelToken.mint(owner, INITIAL_MINT);
    }

    /*//////////////////////////////////////////////////////////////
                         DEPLOYMENT TESTS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Test contract deployment and initial state
     */
    function test_Deployment_InitialState() public view {
        assertEq(bagelToken.name(), "Bagel Token");
        assertEq(bagelToken.symbol(), "BT");
        assertEq(bagelToken.decimals(), 18);
        assertEq(bagelToken.owner(), owner);
        assertEq(bagelToken.totalSupply(), INITIAL_MINT);
        assertEq(bagelToken.balanceOf(owner), INITIAL_MINT);
    }

    /*//////////////////////////////////////////////////////////////
                           MINTING TESTS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Test successful minting by owner
     */
    function test_Mint_SuccessfulByOwner() public {
        uint256 initialSupply = bagelToken.totalSupply();
        uint256 initialBalance = bagelToken.balanceOf(user1);

        // Expect Transfer event
        vm.expectEmit(true, true, false, true);
        emit Transfer(address(0), user1, MINT_AMOUNT);

        bagelToken.mint(user1, MINT_AMOUNT);

        assertEq(bagelToken.totalSupply(), initialSupply + MINT_AMOUNT);
        assertEq(bagelToken.balanceOf(user1), initialBalance + MINT_AMOUNT);
    }

    /**
     * @notice Test minting by non-owner should revert
     */
    function test_Mint_RevertWhenNotOwner() public {
        vm.prank(unauthorizedUser);
        vm.expectRevert(
            abi.encodeWithSelector(
                Ownable.OwnableUnauthorizedAccount.selector,
                unauthorizedUser
            )
        );
        bagelToken.mint(user1, MINT_AMOUNT);
    }

    /**
     * @notice Test minting to zero address should revert
     */
    function test_Mint_RevertWhenMintingToZeroAddress() public {
        vm.expectRevert();
        bagelToken.mint(address(0), MINT_AMOUNT);
    }

    /**
     * @notice Test minting zero amount
     */
    function test_Mint_ZeroAmount() public {
        uint256 initialSupply = bagelToken.totalSupply();
        uint256 initialBalance = bagelToken.balanceOf(user1);

        bagelToken.mint(user1, 0);

        assertEq(bagelToken.totalSupply(), initialSupply);
        assertEq(bagelToken.balanceOf(user1), initialBalance);
    }

    /**
     * @notice Test minting maximum amount
     */
    function test_Mint_MaxAmount() public {
        uint256 maxMint = type(uint256).max - bagelToken.totalSupply();

        bagelToken.mint(user1, maxMint);

        assertEq(bagelToken.totalSupply(), type(uint256).max);
        assertEq(bagelToken.balanceOf(user1), maxMint);
    }

    /*//////////////////////////////////////////////////////////////
                        OWNERSHIP TESTS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Test ownership transfer process
     */
    function test_Ownership_TransferProcess() public {
        // Transfer ownership to user1
        bagelToken.transferOwnership(user1);

        // Ownership should be transferred immediately
        assertEq(bagelToken.owner(), user1);
    }

    /**
     * @notice Test old owner cannot mint after transfer
     */
    function test_Ownership_OldOwnerCannotMintAfterTransfer() public {
        // Transfer ownership
        bagelToken.transferOwnership(user1);

        // Old owner should not be able to mint
        vm.expectRevert(
            abi.encodeWithSelector(
                Ownable.OwnableUnauthorizedAccount.selector,
                owner
            )
        );
        bagelToken.mint(user2, MINT_AMOUNT);
    }

    /**
     * @notice Test new owner can mint after transfer
     */
    function test_Ownership_NewOwnerCanMintAfterTransfer() public {
        // Transfer ownership
        bagelToken.transferOwnership(user1);

        // New owner should be able to mint
        vm.prank(user1);
        bagelToken.mint(user2, MINT_AMOUNT);

        assertEq(bagelToken.balanceOf(user2), MINT_AMOUNT);
    }

    /**
     * @notice Test renouncing ownership
     */
    function test_Ownership_Renounce() public {
        bagelToken.renounceOwnership();

        assertEq(bagelToken.owner(), address(0));

        // Should not be able to mint anymore
        vm.expectRevert(
            abi.encodeWithSelector(
                Ownable.OwnableUnauthorizedAccount.selector,
                owner
            )
        );
        bagelToken.mint(user1, MINT_AMOUNT);
    }

    /*//////////////////////////////////////////////////////////////
                         ERC20 FUNCTIONALITY TESTS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Test standard ERC20 transfer
     */
    function test_ERC20_Transfer() public {
        uint256 initialBalance1 = bagelToken.balanceOf(owner);
        uint256 initialBalance2 = bagelToken.balanceOf(user1);

        vm.expectEmit(true, true, false, true);
        emit Transfer(owner, user1, TRANSFER_AMOUNT);

        bagelToken.transfer(user1, TRANSFER_AMOUNT);

        assertEq(
            bagelToken.balanceOf(owner),
            initialBalance1 - TRANSFER_AMOUNT
        );
        assertEq(
            bagelToken.balanceOf(user1),
            initialBalance2 + TRANSFER_AMOUNT
        );
    }

    /**
     * @notice Test ERC20 approve and transferFrom
     */
    function test_ERC20_ApproveAndTransferFrom() public {
        // Owner approves user1 to spend tokens
        vm.expectEmit(true, true, false, true);
        emit Approval(owner, user1, TRANSFER_AMOUNT);

        bagelToken.approve(user1, TRANSFER_AMOUNT);

        assertEq(bagelToken.allowance(owner, user1), TRANSFER_AMOUNT);

        // user1 transfers from owner to user2
        vm.prank(user1);
        vm.expectEmit(true, true, false, true);
        emit Transfer(owner, user2, TRANSFER_AMOUNT);

        bagelToken.transferFrom(owner, user2, TRANSFER_AMOUNT);

        assertEq(bagelToken.balanceOf(user2), TRANSFER_AMOUNT);
        assertEq(bagelToken.allowance(owner, user1), 0);
    }

    /**
     * @notice Test transfer with insufficient balance
     */
    function test_ERC20_TransferInsufficientBalance() public {
        vm.prank(user1);
        vm.expectRevert();
        bagelToken.transfer(user2, TRANSFER_AMOUNT);
    }

    /**
     * @notice Test transferFrom with insufficient allowance
     */
    function test_ERC20_TransferFromInsufficientAllowance() public {
        bagelToken.approve(user1, TRANSFER_AMOUNT - 1);

        vm.prank(user1);
        vm.expectRevert();
        bagelToken.transferFrom(owner, user2, TRANSFER_AMOUNT);
    }

    /*//////////////////////////////////////////////////////////////
                           FUZZ TESTS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Fuzz test minting with various amounts
     */
    function testFuzz_Mint_VariousAmounts(uint256 amount) public {
        // Bound amount to prevent overflow
        amount = bound(amount, 0, type(uint128).max);

        uint256 initialSupply = bagelToken.totalSupply();
        uint256 initialBalance = bagelToken.balanceOf(user1);

        bagelToken.mint(user1, amount);

        assertEq(bagelToken.totalSupply(), initialSupply + amount);
        assertEq(bagelToken.balanceOf(user1), initialBalance + amount);
    }

    /**
     * @notice Fuzz test transfer with various amounts and addresses
     */
    function testFuzz_Transfer_VariousAmountsAndAddresses(
        address to,
        uint256 amount
    ) public {
        vm.assume(to != address(0));
        vm.assume(to != owner);
        amount = bound(amount, 0, bagelToken.balanceOf(owner));

        uint256 initialBalanceOwner = bagelToken.balanceOf(owner);
        uint256 initialBalanceTo = bagelToken.balanceOf(to);

        bagelToken.transfer(to, amount);

        assertEq(bagelToken.balanceOf(owner), initialBalanceOwner - amount);
        assertEq(bagelToken.balanceOf(to), initialBalanceTo + amount);
    }

    /**
     * @notice Fuzz test approve with various amounts and spenders
     */
    function testFuzz_Approve_VariousAmountsAndSpenders(
        address spender,
        uint256 amount
    ) public {
        vm.assume(spender != address(0));
        amount = bound(amount, 0, type(uint256).max);

        bagelToken.approve(spender, amount);

        assertEq(bagelToken.allowance(owner, spender), amount);
    }

    /*//////////////////////////////////////////////////////////////
                          INVARIANT TESTS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Test that total supply is always sum of all balances (simplified)
     */
    function test_Invariant_TotalSupplyConsistency() public {
        // Mint to multiple users
        bagelToken.mint(user1, 100e18);
        bagelToken.mint(user2, 200e18);

        uint256 expectedTotal = bagelToken.balanceOf(owner) +
            bagelToken.balanceOf(user1) +
            bagelToken.balanceOf(user2);

        assertEq(bagelToken.totalSupply(), expectedTotal);
    }

    /**
     * @notice Test that minting always increases total supply
     */
    function test_Invariant_MintingIncreasesTotalSupply() public {
        uint256 initialSupply = bagelToken.totalSupply();

        bagelToken.mint(user1, MINT_AMOUNT);

        assertGt(bagelToken.totalSupply(), initialSupply);
        assertEq(bagelToken.totalSupply() - initialSupply, MINT_AMOUNT);
    }

    /*//////////////////////////////////////////////////////////////
                          EDGE CASE TESTS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Test multiple mints to same address
     */
    function test_EdgeCase_MultipleMintsSameAddress() public {
        uint256 mint1 = 100e18;
        uint256 mint2 = 150e18;

        bagelToken.mint(user1, mint1);
        bagelToken.mint(user1, mint2);

        assertEq(bagelToken.balanceOf(user1), mint1 + mint2);
    }

    /**
     * @notice Test self-transfer
     */
    function test_EdgeCase_SelfTransfer() public {
        uint256 initialBalance = bagelToken.balanceOf(owner);

        bagelToken.transfer(owner, TRANSFER_AMOUNT);

        assertEq(bagelToken.balanceOf(owner), initialBalance);
    }

    /**
     * @notice Test approve to self
     */
    function test_EdgeCase_SelfApprove() public {
        bagelToken.approve(owner, TRANSFER_AMOUNT);

        assertEq(bagelToken.allowance(owner, owner), TRANSFER_AMOUNT);
    }

    /**
     * @notice Test maximum approval amount
     */
    function test_EdgeCase_MaxApproval() public {
        uint256 maxAmount = type(uint256).max;
        uint256 ownerBalance = bagelToken.balanceOf(owner);

        bagelToken.approve(user1, maxAmount);

        assertEq(bagelToken.allowance(owner, user1), maxAmount);

        // Should be able to transfer any amount up to balance
        vm.prank(user1);
        bagelToken.transferFrom(owner, user2, ownerBalance);

        assertEq(bagelToken.balanceOf(owner), 0);
        assertEq(bagelToken.balanceOf(user2), ownerBalance);
        // With max approval, allowance should remain max (OpenZeppelin optimization)
        assertEq(bagelToken.allowance(owner, user1), maxAmount);
    }

    /*//////////////////////////////////////////////////////////////
                          INTEGRATION TESTS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Test complex scenario with multiple operations
     */
    function test_Integration_ComplexScenario() public {
        // Mint to user1
        bagelToken.mint(user1, 500e18);

        // user1 approves user2
        vm.prank(user1);
        bagelToken.approve(user2, 200e18);

        // user2 transfers from user1 to themselves
        vm.prank(user2);
        bagelToken.transferFrom(user1, user2, 150e18);

        // Verify final state
        assertEq(bagelToken.balanceOf(user1), 350e18);
        assertEq(bagelToken.balanceOf(user2), 150e18);
        assertEq(bagelToken.allowance(user1, user2), 50e18);
    }

    /**
     * @notice Test ownership transfer with minting operations
     */
    function test_Integration_OwnershipTransferWithMinting() public {
        // Original owner mints
        bagelToken.mint(user1, 100e18);

        // Transfer ownership
        bagelToken.transferOwnership(user1);

        // New owner mints
        vm.prank(user1);
        bagelToken.mint(user2, 200e18);

        // Verify balances and ownership
        assertEq(bagelToken.owner(), user1);
        assertEq(bagelToken.balanceOf(user1), 100e18);
        assertEq(bagelToken.balanceOf(user2), 200e18);
    }
}
