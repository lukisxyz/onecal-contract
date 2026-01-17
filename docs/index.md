# OneCal Contracts Documentation

Welcome to the OneCal contracts documentation directory.

## 📁 Directory Structure

```
docs/
├── adr/                    # Architecture Decision Records
│   ├── README.md          # ADR guidelines and process
│   └── adr-001-token-extensions.md  # MockIDRX extensions decision
└── index.md               # This file
```

## 🚀 Quick Links

### Architecture Decisions
- **[ADR-001: Token Extensions](adr/adr-001-token-extensions.md)** - Documents the decision to add AccessControl, Pausable, Burnable, and Capped extensions to MockIDRX

### Code
- **[MockIDRX Contract](../src/MockIDRX.sol)** - The main ERC20 token contract
- **[Deployment Script](../script/MockIDRX.s.sol)** - Deployment automation
- **[Test Suite](../test/MockIDRX.t.sol)** - Comprehensive test coverage

## 📚 ADR Process

ADRs (Architecture Decision Records) are used to document important architectural decisions. See [ADR README](adr/README.md) for the full process and guidelines.

## 🔗 Related Resources

- [Foundry Book](https://book.getfoundry.sh/) - Testing and deployment framework
- [OpenZeppelin Contracts](https://docs.openzeppelin.com/contracts/) - Secure smart contract library
- [Solidity Documentation](https://docs.soliditylang.org/) - Programming language reference
