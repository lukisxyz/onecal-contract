# Architecture Decision Records (ADR)

This directory contains Architecture Decision Records (ADRs) for the OneCal contracts project.

## What is an ADR?

An Architecture Decision Record (ADR) is a document that captures an important architectural decision made along with its context and consequences. ADRs help document:

- **Why** we made specific architectural choices
- **What** alternatives we considered
- **How** these decisions impact the system
- **When** these decisions were made and by whom

## ADR Format

Each ADR should be a markdown file with the following structure:

1. **Title** - Brief description of the decision
2. **Status** - Proposed, Accepted, Deprecated, or Superseded
3. **Context** - The situation or problem that prompted this decision
4. **Decision** - What we decided to do
5. **Alternatives** - Other options we considered
6. **Consequences** - Positive, negative, and neutral outcomes

## ADR Naming Convention

ADRs should be numbered sequentially and named using kebab-case:

```
adr-001-token-extensions.md
adr-002-contract-upgrades.md
adr-003-security-review-process.md
```

## How to Contribute

When making significant architectural changes to the codebase:

1. Create a new ADR in this directory
2. Follow the standard format
3. Include relevant code examples and diagrams if helpful
4. Link to related ADRs and documentation
5. Get team review and acceptance before implementation

## ADR Index

| ADR | Title | Status | Date |
|-----|-------|--------|------|
| [001](adr-001-token-extensions.md) | MockIDRX Token Extensions and Security Enhancements | Accepted | 2026-01-17 |

## References

- [ADR GitHub Organization](https://adr.github.io/)
- [The Strangler Fig Application](https://martinfowler.com/bliki/StranglerFigApplication.html)
- [Documenting Architecture Decisions](https://cognitect.com/blog/2011/11/15/documenting-architecture-decisions)
