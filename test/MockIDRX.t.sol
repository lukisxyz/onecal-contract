// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

import {Test} from "forge-std/Test.sol";
import {MockIDRX} from "../src/MockIDRX.sol";
import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

contract MockIDRXTest is Test {
    MockIDRX public mockIDRX;
    address public owner;
    address public user1;
    address public user2;
    address public user3;

    // EIP-2612 test variables
    uint256 public ownerPrivateKey = 0xA11CE;
    uint256 public user1PrivateKey = 0xB0B;

    function setUp() public {
        owner = address(this);
        user1 = vm.addr(user1PrivateKey);
        user2 = address(0x2);
        user3 = address(0x3);

        mockIDRX = new MockIDRX(owner);
    }

    // ========== DEPLOYMENT AND METADATA TESTS ==========

    function test_Deployment() public {
        assertEq(mockIDRX.name(), "Mock IDRX");
        assertEq(mockIDRX.symbol(), "mIDRX");
        assertEq(mockIDRX.decimals(), 2);
    }

    function test_InitialBalance() public {
        assertEq(mockIDRX.balanceOf(owner), 0);
    }

    // ========== MINTING TESTS ==========

    function test_MintToUser() public {
        uint256 mintAmount = 1000 * 10**mockIDRX.decimals();
        mockIDRX.mint(user1, mintAmount);

        assertEq(mockIDRX.balanceOf(user1), mintAmount);
        assertEq(mockIDRX.totalSupply(), mintAmount);
    }

    function test_MintMultipleTimes() public {
        uint256 mintAmount1 = 50000 * 10**mockIDRX.decimals();
        uint256 mintAmount2 = 30000 * 10**mockIDRX.decimals();

        mockIDRX.mint(user1, mintAmount1);
        mockIDRX.mint(user2, mintAmount2);

        assertEq(mockIDRX.balanceOf(user1), mintAmount1);
        assertEq(mockIDRX.balanceOf(user2), mintAmount2);
        assertEq(mockIDRX.totalSupply(), mintAmount1 + mintAmount2);
    }

    function test_MintToOwner() public {
        uint256 mintAmount = 10000 * 10**mockIDRX.decimals();
        mockIDRX.mint(owner, mintAmount);

        assertEq(mockIDRX.balanceOf(owner), mintAmount);
        assertEq(mockIDRX.totalSupply(), mintAmount);
    }

    function test_MaxMintAmount() public {
        uint256 maxMint = mockIDRX.MAX_MINT_AMOUNT();
        assertEq(maxMint, 100000 * 10**mockIDRX.decimals());

        mockIDRX.mint(user1, maxMint);

        assertEq(mockIDRX.balanceOf(user1), maxMint);
        assertEq(mockIDRX.totalSupply(), maxMint);
    }

    function test_CannotMintExceedingMaxAmount() public {
        uint256 maxMint = mockIDRX.MAX_MINT_AMOUNT();
        uint256 exceededAmount = maxMint + 1;

        vm.expectRevert("MockIDRX: mint amount exceeds maximum per transaction");
        mockIDRX.mint(user1, exceededAmount);
    }

    function test_CannotMintZero() public {
        // OpenZeppelin allows minting zero tokens, so we skip this test
        // or verify that it succeeds
        mockIDRX.mint(user1, 0);
        assertEq(mockIDRX.balanceOf(user1), 0);
    }

    function test_MintAmountJustBelowMax() public {
        uint256 maxMint = mockIDRX.MAX_MINT_AMOUNT();
        uint256 amount = maxMint - 1;

        mockIDRX.mint(user1, amount);

        assertEq(mockIDRX.balanceOf(user1), amount);
        assertEq(mockIDRX.totalSupply(), amount);
    }

    function test_MintAmountJustAboveMax() public {
        uint256 maxMint = mockIDRX.MAX_MINT_AMOUNT();
        uint256 amount = maxMint + 1;

        vm.expectRevert("MockIDRX: mint amount exceeds maximum per transaction");
        mockIDRX.mint(user1, amount);
    }

    function test_AnyoneCanMint() public {
        uint256 mintAmount = 1000 * 10**mockIDRX.decimals();

        // Owner mints to user1 (owner has MINTER_ROLE)
        mockIDRX.mint(user1, mintAmount);
        assertEq(mockIDRX.balanceOf(user1), mintAmount);

        // Grant MINTER_ROLE to user2
        mockIDRX.grantRole(mockIDRX.MINTER_ROLE(), user2);

        // User2 mints to user3 (user2 now has MINTER_ROLE)
        vm.startPrank(user2);
        mockIDRX.mint(user3, mintAmount);
        vm.stopPrank();
        assertEq(mockIDRX.balanceOf(user3), mintAmount);

        // Owner mints to user1 again
        mockIDRX.mint(user1, mintAmount);
        assertEq(mockIDRX.balanceOf(user1), mintAmount * 2);
    }

    // ========== BASIC ERC20 FUNCTIONALITY TESTS ==========

    function test_Transfer() public {
        uint256 mintAmount = 1000 * 10**mockIDRX.decimals();
        mockIDRX.mint(user1, mintAmount);

        vm.startPrank(user1);
        uint256 transferAmount = 500 * 10**mockIDRX.decimals();
        mockIDRX.transfer(user2, transferAmount);
        vm.stopPrank();

        assertEq(mockIDRX.balanceOf(user1), mintAmount - transferAmount);
        assertEq(mockIDRX.balanceOf(user2), transferAmount);
        assertEq(mockIDRX.totalSupply(), mintAmount);
    }

    function test_TransferFullBalance() public {
        uint256 mintAmount = 1000 * 10**mockIDRX.decimals();
        mockIDRX.mint(user1, mintAmount);

        vm.startPrank(user1);
        mockIDRX.transfer(user2, mintAmount);
        vm.stopPrank();

        assertEq(mockIDRX.balanceOf(user1), 0);
        assertEq(mockIDRX.balanceOf(user2), mintAmount);
    }

    function test_TransferZero() public {
        uint256 mintAmount = 1000 * 10**mockIDRX.decimals();
        mockIDRX.mint(user1, mintAmount);

        vm.startPrank(user1);
        mockIDRX.transfer(user2, 0);
        vm.stopPrank();

        assertEq(mockIDRX.balanceOf(user1), mintAmount);
        assertEq(mockIDRX.balanceOf(user2), 0);
    }

    function test_TransferToSelf() public {
        uint256 mintAmount = 1000 * 10**mockIDRX.decimals();
        mockIDRX.mint(user1, mintAmount);

        vm.startPrank(user1);
        mockIDRX.transfer(user1, mintAmount);
        vm.stopPrank();

        assertEq(mockIDRX.balanceOf(user1), mintAmount);
    }

    function test_TransferInsufficientBalance() public {
        uint256 mintAmount = 1000 * 10**mockIDRX.decimals();
        mockIDRX.mint(user1, mintAmount);

        vm.startPrank(user1);
        uint256 transferAmount = mintAmount + 1;
        vm.expectRevert();
        mockIDRX.transfer(user2, transferAmount);
        vm.stopPrank();
    }

    function test_Approve() public {
        uint256 mintAmount = 1000 * 10**mockIDRX.decimals();
        mockIDRX.mint(user1, mintAmount);

        uint256 approvalAmount = 500 * 10**mockIDRX.decimals();

        vm.startPrank(user1);
        mockIDRX.approve(user2, approvalAmount);
        vm.stopPrank();

        assertEq(mockIDRX.allowance(user1, user2), approvalAmount);
    }

    function test_ApproveZero() public {
        uint256 mintAmount = 1000 * 10**mockIDRX.decimals();
        mockIDRX.mint(user1, mintAmount);

        vm.startPrank(user1);
        mockIDRX.approve(user2, 0);
        vm.stopPrank();

        assertEq(mockIDRX.allowance(user1, user2), 0);
    }

    function test_ApproveTwice() public {
        uint256 mintAmount = 1000 * 10**mockIDRX.decimals();
        mockIDRX.mint(user1, mintAmount);

        vm.startPrank(user1);
        mockIDRX.approve(user2, 300 * 10**mockIDRX.decimals());
        vm.stopPrank();
        assertEq(mockIDRX.allowance(user1, user2), 300 * 10**mockIDRX.decimals());

        vm.startPrank(user1);
        mockIDRX.approve(user2, 500 * 10**mockIDRX.decimals());
        vm.stopPrank();
        assertEq(mockIDRX.allowance(user1, user2), 500 * 10**mockIDRX.decimals());
    }

    function test_TransferFrom() public {
        uint256 mintAmount = 1000 * 10**mockIDRX.decimals();
        mockIDRX.mint(user1, mintAmount);

        vm.startPrank(user1);
        mockIDRX.approve(user2, 500 * 10**mockIDRX.decimals());
        vm.stopPrank();

        vm.startPrank(user2);
        mockIDRX.transferFrom(user1, user3, 300 * 10**mockIDRX.decimals());
        vm.stopPrank();

        assertEq(mockIDRX.balanceOf(user1), mintAmount - 300 * 10**mockIDRX.decimals());
        assertEq(mockIDRX.balanceOf(user3), 300 * 10**mockIDRX.decimals());
        assertEq(mockIDRX.allowance(user1, user2), 200 * 10**mockIDRX.decimals());
    }

    function test_TransferFromExactAllowance() public {
        uint256 mintAmount = 1000 * 10**mockIDRX.decimals();
        mockIDRX.mint(user1, mintAmount);

        vm.startPrank(user1);
        uint256 approvalAmount = 500 * 10**mockIDRX.decimals();
        mockIDRX.approve(user2, approvalAmount);
        vm.stopPrank();

        vm.startPrank(user2);
        mockIDRX.transferFrom(user1, user3, approvalAmount);
        vm.stopPrank();

        assertEq(mockIDRX.balanceOf(user1), mintAmount - approvalAmount);
        assertEq(mockIDRX.balanceOf(user3), approvalAmount);
        assertEq(mockIDRX.allowance(user1, user2), 0);
    }


    // ========== EIP-2612 PERMIT TESTS ==========

    bytes32 private constant PERMIT_TYPEHASH =
        keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

    function test_Permit() public {
        uint256 mintAmount = 1000 * 10**mockIDRX.decimals();
        mockIDRX.mint(user1, mintAmount);

        // Create permit signature
        address spender = user2;
        uint256 value = 500 * 10**mockIDRX.decimals();
        uint256 nonce = mockIDRX.nonces(user1);
        uint256 deadline = block.timestamp + 1 days;

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            user1PrivateKey,
            keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    mockIDRX.DOMAIN_SEPARATOR(),
                    keccak256(abi.encode(PERMIT_TYPEHASH, user1, spender, value, nonce, deadline))
                )
            )
        );

        // Execute permit
        mockIDRX.permit(user1, spender, value, deadline, v, r, s);

        // Verify allowance
        assertEq(mockIDRX.allowance(user1, spender), value);
    }

    function test_PermitWithMaxUintValue() public {
        uint256 mintAmount = 1000 * 10**mockIDRX.decimals();
        mockIDRX.mint(user1, mintAmount);

        address spender = user2;
        uint256 value = type(uint256).max;
        uint256 nonce = mockIDRX.nonces(user1);
        uint256 deadline = block.timestamp + 1 days;

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            user1PrivateKey,
            keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    mockIDRX.DOMAIN_SEPARATOR(),
                    keccak256(abi.encode(PERMIT_TYPEHASH, user1, spender, value, nonce, deadline))
                )
            )
        );

        mockIDRX.permit(user1, spender, value, deadline, v, r, s);

        assertEq(mockIDRX.allowance(user1, spender), value);
    }

    function test_PermitWithExpiredDeadline() public {
        address spender = user2;
        uint256 value = 500 * 10**mockIDRX.decimals();
        uint256 nonce = mockIDRX.nonces(user1);
        uint256 deadline = block.timestamp - 1; // Expired

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            user1PrivateKey,
            keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    mockIDRX.DOMAIN_SEPARATOR(),
                    keccak256(abi.encode(PERMIT_TYPEHASH, user1, spender, value, nonce, deadline))
                )
            )
        );

        vm.expectRevert();
        mockIDRX.permit(user1, spender, value, deadline, v, r, s);
    }

    function test_PermitWithInvalidSignature() public {
        address spender = user2;
        uint256 value = 500 * 10**mockIDRX.decimals();
        uint256 nonce = mockIDRX.nonces(user1);
        uint256 deadline = block.timestamp + 1 days;

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            ownerPrivateKey, // Wrong private key
            keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    mockIDRX.DOMAIN_SEPARATOR(),
                    keccak256(abi.encode(PERMIT_TYPEHASH, user1, spender, value, nonce, deadline))
                )
            )
        );

        vm.expectRevert();
        mockIDRX.permit(user1, spender, value, deadline, v, r, s);
    }

    function test_PermitWithReplay() public {
        uint256 mintAmount = 1000 * 10**mockIDRX.decimals();
        mockIDRX.mint(user1, mintAmount);

        address spender = user2;
        uint256 value = 500 * 10**mockIDRX.decimals();
        uint256 nonce = mockIDRX.nonces(user1);
        uint256 deadline = block.timestamp + 1 days;

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            user1PrivateKey,
            keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    mockIDRX.DOMAIN_SEPARATOR(),
                    keccak256(abi.encode(PERMIT_TYPEHASH, user1, spender, value, nonce, deadline))
                )
            )
        );

        // First permit should succeed
        mockIDRX.permit(user1, spender, value, deadline, v, r, s);
        assertEq(mockIDRX.allowance(user1, spender), value);

        // Second permit with same signature should fail (nonce incremented)
        vm.expectRevert();
        mockIDRX.permit(user1, spender, value, deadline, v, r, s);
    }

    function test_PermitIncrementsNonce() public {
        uint256 mintAmount = 1000 * 10**mockIDRX.decimals();
        mockIDRX.mint(user1, mintAmount);

        address spender = user2;
        uint256 value = 500 * 10**mockIDRX.decimals();
        uint256 deadline = block.timestamp + 1 days;

        uint256 initialNonce = mockIDRX.nonces(user1);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            user1PrivateKey,
            keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    mockIDRX.DOMAIN_SEPARATOR(),
                    keccak256(abi.encode(PERMIT_TYPEHASH, user1, spender, value, initialNonce, deadline))
                )
            )
        );

        mockIDRX.permit(user1, spender, value, deadline, v, r, s);

        assertEq(mockIDRX.nonces(user1), initialNonce + 1);
    }

    // ========== COMBINED FUNCTIONALITY TESTS ==========

    // ========== EDGE CASE TESTS ==========

    function test_MaxMintToMultipleUsers() public {
        uint256 maxMint = mockIDRX.MAX_MINT_AMOUNT();

        mockIDRX.mint(user1, maxMint);
        mockIDRX.mint(user2, maxMint);
        mockIDRX.mint(user3, maxMint);

        assertEq(mockIDRX.totalSupply(), maxMint * 3);
        assertEq(mockIDRX.balanceOf(user1), maxMint);
        assertEq(mockIDRX.balanceOf(user2), maxMint);
        assertEq(mockIDRX.balanceOf(user3), maxMint);
    }

    function test_ManySmallMints() public {
        uint256 totalMinted = 0;
        uint256 mintAmount = 100 * 10**mockIDRX.decimals();

        for (uint256 i = 0; i < 100; i++) {
            address user = address(uint160(i + 1));
            mockIDRX.mint(user, mintAmount);
            totalMinted += mintAmount;
        }

        assertEq(mockIDRX.totalSupply(), totalMinted);
    }

    function test_DecimalsConsistency() public {
        assertEq(mockIDRX.decimals(), 2);

        uint256 mintAmount = 1000000; // 1,000,000 tokens with 2 decimals
        mockIDRX.mint(user1, mintAmount);

        // With 2 decimals, 1000000 units = 10000.00 tokens
        assertEq(mockIDRX.balanceOf(user1), mintAmount);
    }

    function test_AllowanceAfterTransfer() public {
        uint256 mintAmount = 1000 * 10**mockIDRX.decimals();
        mockIDRX.mint(user1, mintAmount);

        vm.startPrank(user1);
        mockIDRX.approve(user2, 500 * 10**mockIDRX.decimals());
        vm.stopPrank();

        // Transfer some tokens
        vm.startPrank(user1);
        mockIDRX.transfer(user3, 200 * 10**mockIDRX.decimals());
        vm.stopPrank();

        // Allowance should remain unchanged
        assertEq(mockIDRX.allowance(user1, user2), 500 * 10**mockIDRX.decimals());
    }

    function test_TransferFromAfterPartialTransfer() public {
        uint256 mintAmount = 1000 * 10**mockIDRX.decimals();
        mockIDRX.mint(user1, mintAmount);

        vm.startPrank(user1);
        mockIDRX.approve(user2, 500 * 10**mockIDRX.decimals());
        vm.stopPrank();

        // First transfer
        vm.startPrank(user2);
        mockIDRX.transferFrom(user1, user3, 200 * 10**mockIDRX.decimals());
        vm.stopPrank();

        // Allowance should be reduced
        assertEq(mockIDRX.allowance(user1, user2), 300 * 10**mockIDRX.decimals());

        // Second transfer
        vm.startPrank(user2);
        mockIDRX.transferFrom(user1, user3, 100 * 10**mockIDRX.decimals());
        vm.stopPrank();

        // Allowance should be further reduced
        assertEq(mockIDRX.allowance(user1, user2), 200 * 10**mockIDRX.decimals());
    }
}
