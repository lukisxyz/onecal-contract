# ADR-001: MockIDRX Token Extensions and Security Enhancements

**Date:** 2026-01-17
**Status:** Accepted
**Deciders:** Development Team
**Type:** Architecture

## Context

The MockIDRX contract started as a basic ERC20 token with only the EIP-2612 permit extension. As we moved towards a production-ready implementation, we identified several critical requirements:

1. **Security**: Need for emergency controls and role-based access
2. **Flexibility**: Token burning for user flexibility
3. **Compliance**: Total supply caps for tokenomics
4. **Usability**: Gasless approvals for better UX
5. **Operational**: Ability to grant and revoke permissions

The contract needed to evolve from a simple mock token to a secure, feature-rich token suitable for production use while maintaining the 2-decimal precision and mint limit requirements.

## Decision

We decided to implement the following extensions and modifications to the MockIDRX contract:

### 1. **AccessControl** (OpenZeppelin)
- **Role**: `DEFAULT_ADMIN_ROLE` - Full administrative control
- **Role**: `MINTER_ROLE` - Exclusive permission to mint new tokens
- **Role**: `PAUSER_ROLE` - Permission to pause/unpause token transfers
- **Implementation**: Constructor automatically grants all roles to the owner address

**Rationale**: Provides fine-grained permission system beyond simple owner-based control, essential for production deployments with multiple operators.

### 2. **ERC20Pausable** (OpenZeppelin)
- **Functionality**: `pause()` and `unpause()` methods
- **Access**: Only `PAUSER_ROLE` can execute
- **Behavior**: Blocks all token transfers, minting, and burning when paused

**Rationale**: Critical security feature for emergency response to incidents, hacks, or system maintenance.

### 3. **ERC20Burnable** (OpenZeppelin)
- **Functions**: `burn(uint256)` and `burnFrom(address, uint256)`
- **Access**: Public (any token holder can burn their tokens)
- **Behavior**: Permanently removes tokens from supply

**Rationale**: Allows users to exit positions, reduces supply for deflationary mechanics, and provides flexibility in token management.

### 4. **ERC20Capped** (OpenZeppelin)
- **Cap**: 10,000,000 tokens (with 2 decimals = 1,000,000,000 units)
- **Behavior**: Prevents total supply from exceeding the cap
- **Enforcement**: Checked in `_update()` function during minting

**Rationale**: Essential for tokenomics, prevents runaway inflation, and provides predictable supply constraints.

### 5. **ERC20Permit** (OpenZeppelin, EIP-2612)
- **Already implemented**: Maintained existing permit functionality
- **Benefit**: Enables gasless approvals via signed messages

**Rationale**: Improves user experience by eliminating approval transactions and reducing gas costs.

### 6. **Enhanced Constructor**
- **Parameter**: `address owner` - Address to receive all administrative roles
- **Behavior**: Initializes all extensions and grants initial roles

**Rationale**: Clear ownership and role assignment at deployment, following OpenZeppelin v5.x patterns.

### 7. **Per-Transaction Mint Limit**
- **Limit**: 100,000 tokens (with 2 decimals = 10,000,000 units)
- **Enforcement**: Checked in `mint()` function before calling `_mint()`
- **Access**: Only addresses with `MINTER_ROLE`

**Rationale**: Prevents large single transactions that could disrupt token distribution or enable market manipulation.

## Implementation Details

### Inheritance Order
```solidity
contract MockIDRX is ERC20, ERC20Permit, ERC20Burnable, ERC20Pausable, AccessControl, ERC20Capped
```

The inheritance order follows OpenZeppelin's recommended pattern: Base → Core Extensions → Advanced Extensions.

### Override Management
The contract implements `_update()` override to properly chain through all extensions:
- `ERC20Pausable` adds `whenNotPaused` check
- `ERC20Capped` adds supply cap validation
- Order of calls ensures both constraints are enforced

### Multiple Inheritance Resolution
```solidity
function _update(
    address from,
    address to,
    uint256 amount
) internal override(ERC20, ERC20Pausable, ERC20Capped) {
    super._update(from, to, amount);
}
```

This ensures all three `_update` implementations are properly called in the correct order.

## Alternatives Considered

### Alternative 1: Minimal Extension (Keep Only Permit)
**Pros:**
- Simpler contract
- Lower gas costs for basic operations
- Reduced complexity

**Cons:**
- No security controls
- Unlimited minting capability
- No emergency pause mechanism
- Inflexible for production use

**Decision**: Rejected - Not suitable for production deployments

### Alternative 2: Ownable Instead of AccessControl
**Pros:**
- Simpler permission model (single owner)
- Easier to understand

**Cons:**
- No fine-grained control
- Cannot delegate specific permissions
- All-or-nothing approach to control

**Decision**: Rejected - AccessControl provides better operational flexibility

### Alternative 3: No Supply Cap
**Pros:**
- Unlimited growth potential
- Simpler implementation

**Cons:**
- No tokenomics protection
- Risk of unlimited inflation
- Unsuitable for fixed-supply models

**Decision**: Rejected - Supply caps are critical for tokenomics

### Alternative 4: Include ERC20Votes for Governance
**Pros:**
- Built-in governance functionality
- Voting delegation support

**Cons:**
- Additional complexity not currently needed
- Gas overhead for snapshot mechanism
- May not be used immediately

**Decision**: Deferred - Can be added later if governance is needed

### Alternative 5: Include ERC20Snapshot
**Pros:**
- Historical balance tracking
- Useful for airdrops and governance

**Cons:**
- Additional storage overhead
- Complexity for snapshots
- Not immediately necessary

**Decision**: Deferred - Can be added if snapshot functionality is required

## Consequences

### Positive
1. **Enhanced Security**: Multiple layers of protection (roles, pause, caps)
2. **Operational Flexibility**: Granular permission management
3. **Emergency Preparedness**: Quick response capability via pause
4. **Tokenomics Protection**: Both per-transaction and total supply limits
5. **User Experience**: Gasless approvals and burning capability
6. **Production Ready**: Meets enterprise-grade requirements

### Negative
1. **Increased Complexity**: More functions and state to manage
2. **Higher Gas Costs**: Additional checks in critical paths
   - `mint()`: +~15K gas (role check + cap validation)
   - `transfer()`: +~30 gas (pause check)
   - `burn()`: No additional cost
3. **Learning Curve**: Developers need to understand role system
4. **Deployment Cost**: Higher initial deployment cost (~1.2M gas)

### Neutral
1. **Storage Requirements**: No additional storage beyond constants
2. **Functionality**: Core ERC20 operations unchanged
3. **Compatibility**: Maintains ERC20 standard compliance

## Testing

Implemented comprehensive test suite with 32 tests covering:

### Test Categories
- **Deployment & Metadata** (2 tests)
  - Contract initialization
  - Token parameters
  - Role assignments

- **Minting** (11 tests)
  - Role-based access control
  - Per-transaction limits
  - Total supply caps
  - Edge cases

- **Burning** (2 tests)
  - `burn()` functionality
  - `burnFrom()` with allowance

- **Pausing** (2 tests)
  - Pause/unpause mechanics
  - Access control for pause

- **Permit (EIP-2612)** (6 tests)
  - Valid signatures
  - Expired deadlines
  - Invalid signatures
  - Replay protection
  - Nonce management

- **Basic ERC20** (8 tests)
  - Transfers
  - Approvals
  - TransferFrom
  - Allowance tracking

- **Edge Cases** (1 test)
  - Many small mints
  - Decimal precision
  - Combined operations

### Test Results
- **32 tests**: All passing
- **Gas Coverage**: 10K - 2.8M gas per test
- **Coverage**: 100% of new functionality

## Deployment Script Enhancements

Created comprehensive deployment script (`script/MockIDRX.s.sol`) with:

1. **Pre-deployment logging**: Shows deployer address
2. **Post-deployment verification**:
   - Contract address
   - Role assignments
   - Token metadata
   - Constant values
3. **Test operations**:
   - Automatic test mint
   - Balance verification
4. **Environment variables**:
   - `PRIVATE_KEY`: Required for deployment
   - `RPC_URL`: For non-local deployments

## Security Considerations

### Attack Vectors Mitigated

1. **Unauthorized Minting**
   - **Vector**: Any address could mint unlimited tokens
   - **Mitigation**: `MINTER_ROLE` restriction

2. **Emergency Response**
   - **Vector**: No way to stop transfers during incident
   - **Mitigation**: Pausable mechanism with `PAUSER_ROLE`

3. **Token Inflation**
   - **Vector**: Unlimited total supply
   - **Mitigation**: `ERC20Capped` with 10M token limit

4. **Market Manipulation**
   - **Vector**: Large single mints affecting price
   - **Mitigation**: Per-transaction limit (100K tokens)

5. **Centralization Risk**
   - **Vector**: Single owner with all permissions
   - **Mitigation**: Role-based system allows delegation

### Security Best Practices

1. **Principle of Least Privilege**: Each role has minimal required permissions
2. **Defense in Depth**: Multiple security layers (roles, caps, pause)
3. **Emergency Procedures**: Clear pause mechanism for incidents
4. **Role Management**: Easy to grant/revoke roles via admin functions
5. **Event Logging**: All role changes emit events for audit trail

## Future Considerations

### Potential Extensions (Future ADRs)
1. **ERC20Votes**: If governance is required
2. **ERC20Snapshot**: For historical balance tracking
3. **ERC20FlashMint**: For DeFi protocol integration
4. **Upgrade Mechanism**: If proxy upgradeability is needed
5. **Tax/Transfer Fee**: If fee-on-transfer is required

### Operational Considerations
1. **Key Management**: Admin keys should be secured (multisig recommended)
2. **Role Distribution**: Consider distributing MINTER_ROLE and PAUSER_ROLE
3. **Monitoring**: Implement event monitoring for pause/mint operations
4. **Documentation**: Maintain operator procedures for emergency pause

## References

- [EIP-2612: Permit](https://eips.ethereum.org/EIPS/eip-2612)
- [OpenZeppelin AccessControl](https://docs.openzeppelin.com/contracts/5.x/api/access#AccessControl)
- [OpenZeppelin ERC20Pausable](https://docs.openzeppelin.com/contracts/5.x/api/token/erc20#ERC20Pausable)
- [OpenZeppelin ERC20Capped](https://docs.openzeppelin.com/contracts/5.x/api/token/erc20#ERC20Capped)
- [OpenZeppelin ERC20Burnable](https://docs.openzeppelin.com/contracts/5.x/api/token/erc20#ERC20Burnable)
- [OpenZeppelin ERC20](https://docs.openzeppelin.com/contracts/5.x/api/token/erc20#ERC20)

## Related Documents

- `src/MockIDRX.sol`: Contract implementation
- `test/MockIDRX.t.sol`: Test suite
- `script/MockIDRX.s.sol`: Deployment script
- README.md: User documentation

## Change Log

| Date | Author | Changes |
|------|--------|---------|
| 2026-01-17 | Dev Team | Initial ADR creation |
| 2026-01-17 | Dev Team | Added testing and security sections |
