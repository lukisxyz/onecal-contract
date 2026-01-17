// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

import {ERC20} from "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import {ERC20Permit} from "openzeppelin-contracts/contracts/token/ERC20/extensions/ERC20Permit.sol";
import {ERC20Burnable} from "openzeppelin-contracts/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import {ERC20Pausable} from "openzeppelin-contracts/contracts/token/ERC20/extensions/ERC20Pausable.sol";
import {AccessControl} from "openzeppelin-contracts/contracts/access/AccessControl.sol";
import {ERC20Capped} from "openzeppelin-contracts/contracts/token/ERC20/extensions/ERC20Capped.sol";

/**
 * @title MockIDRX
 * @dev Mock ERC20 token with comprehensive security and utility extensions
 * @custom:dev-run-script ../script/MockIDRX.s.sol
 *
 * Features:
 * - EIP-2612 permit for gasless approvals
 * - Role-based access control
 * - Emergency pause functionality
 * - Token burning capability
 * - Maximum total supply cap
 * - Per-transaction mint limit
 */
contract MockIDRX is ERC20, ERC20Permit, ERC20Burnable, ERC20Pausable, AccessControl, ERC20Capped {
    /// @notice Role that allows minting new tokens
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    /// @notice Role that allows pausing/unpausing the token
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    /// @notice Maximum amount that can be minted in a single transaction (100,000 tokens with 2 decimals)
    uint256 public constant MAX_MINT_AMOUNT = 100_000 * 10**2;

    /// @notice Maximum total supply cap (10,000,000 tokens with 2 decimals)
    uint256 public constant CAP = 10_000_000 * 10**2;

    /**
     * @dev Constructor that initializes the token with name, symbol, and sets up roles
     * @param owner The address that will be granted the DEFAULT_ADMIN_ROLE
     */
    constructor(address owner)
        ERC20("Mock IDRX", "mIDRX")
        ERC20Permit("Mock IDRX")
        ERC20Capped(CAP)
    {
        // Grant owner admin role and minter/pauser roles
        _grantRole(DEFAULT_ADMIN_ROLE, owner);
        _grantRole(MINTER_ROLE, owner);
        _grantRole(PAUSER_ROLE, owner);
    }

    /**
     * @dev Override decimals to return 2 instead of 18
     */
    function decimals() public pure override returns (uint8) {
        return 2;
    }

    /**
     * @dev Mint tokens to an address (only callable by MINTER_ROLE)
     * @param to The address to mint tokens to
     * @param amount The amount of tokens to mint
     * @notice Enforces both per-transaction and total supply caps
     */
    function mint(address to, uint256 amount) public onlyRole(MINTER_ROLE) {
        require(amount <= MAX_MINT_AMOUNT, "MockIDRX: mint amount exceeds maximum per transaction");
        _mint(to, amount);
    }

    /**
     * @dev Burn tokens from caller's account
     * @param amount The amount of tokens to burn
     */
    function burn(uint256 amount) public override(ERC20Burnable) {
        super.burn(amount);
    }

    /**
     * @dev Burn tokens from account (with allowance)
     * @param account The account to burn tokens from
     * @param amount The amount of tokens to burn
     */
    function burnFrom(address account, uint256 amount) public override(ERC20Burnable) {
        super.burnFrom(account, amount);
    }

    /**
     * @dev Pause all token transfers
     * Only callable by PAUSER_ROLE
     */
    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    /**
     * @dev Unpause all token transfers
     * Only callable by PAUSER_ROLE
     */
    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    /**
     * @dev Override required to properly handle multiple inheritance with ERC20 extensions
     * @param from The address tokens are transferred from
     * @param to The address tokens are transferred to
     * @param amount The amount of tokens being transferred
     */
    function _update(
        address from,
        address to,
        uint256 amount
    ) internal override(ERC20, ERC20Pausable, ERC20Capped) {
        super._update(from, to, amount);
    }
}
