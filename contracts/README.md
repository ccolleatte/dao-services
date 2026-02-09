# DAO Smart Contracts

Smart contracts for decentralized service marketplace with hybrid AI/human contributors.

---

## Architecture

### Core Contracts

- **DAOMembership.sol** : Hierarchical membership system with rank-based vote weights
- **DAOGovernor.sol** : Multi-track governance (Technical, Treasury, Membership)
- **DAOTreasury.sol** : Treasury management with spending proposals
- **TimelockController** : Security delay (OpenZeppelin)

### Status

| Contract | Lines | Tests | Status |
|----------|-------|-------|--------|
| DAOMembership | 310 | 22 | ✅ Complete |
| DAOGovernor | 350 | 11 | ✅ Complete |
| DAOTreasury | 280 | 20 | ✅ Complete |
| **Total** | **940** | **53** | **Phase 3: 60%** |

---

## Quick Start

### Prerequisites

```bash
# Install Foundry
curl -L https://foundry.paradigm.xyz | bash
foundryup

# Verify installation
forge --version
```

### Installation

```bash
# Clone repo
git clone https://github.com/your-org/dao-services.git
cd dao-services/contracts

# Install dependencies
forge install
```

### Build

```bash
# Compile contracts
forge build

# With optimizer
forge build --optimize --optimizer-runs 200
```

### Tests

```bash
# Run all tests
forge test

# Run with verbosity
forge test -vv

# Run specific contract tests
forge test --match-path test/DAOMembership.t.sol -vv
forge test --match-path test/DAOGovernor.t.sol -vv
forge test --match-path test/DAOTreasury.t.sol -vv

# Coverage report
forge coverage --report summary
```

### Deploy (Testnet Paseo)

```bash
# Setup environment
export PRIVATE_KEY="0x..."
export RPC_URL="https://paseo-rpc.polkadot.io"

# Deploy all contracts
forge script script/DeployGovernance.s.sol:DeployGovernance \
    --rpc-url $RPC_URL \
    --broadcast \
    --verify

# Verify contracts individually
forge verify-contract <CONTRACT_ADDRESS> <CONTRACT_NAME> \
    --rpc-url $RPC_URL \
    --constructor-args $(cast abi-encode "constructor(...)" <ARGS>)
```

---

## Contracts Overview

### 1. DAOMembership

**Purpose** : Manage members and vote weights

**Key Features** :
- Hierarchical ranks (0-4): Observer → Founder
- Triangular vote weights (Rank 0: 0, Rank 1: 1, Rank 2: 3, Rank 3: 6, Rank 4: 10)
- Minimum rank durations (Rank 1: 30d, Rank 2: 90d, Rank 3: 180d, Rank 4: 365d)
- Active/inactive status

**Usage** :
```solidity
// Add new member (Rank 1)
membership.addMember(0xABC..., 1);

// Promote to Rank 2 (after 30 days)
membership.promoteMember(0xABC...);

// Calculate vote weight
uint256 weight = membership.calculateVoteWeight(0xABC...); // Returns 3 for Rank 2
```

---

### 2. DAOGovernor

**Purpose** : Multi-track governance system

**Tracks** :

| Track | Min Rank | Period | Quorum | Use Cases |
|-------|----------|--------|--------|-----------|
| Technical | Rank 2+ | 7 days | 66% | Architecture, security |
| Treasury | Rank 1+ | 14 days | 51% | Budget, spending |
| Membership | Rank 3+ | 7 days | 75% | Promote/demote |

**Usage** :
```solidity
// Create Technical proposal
address[] memory targets = new address[](1);
targets[0] = address(serviceMarketplace);

uint256[] memory values = new uint256[](1);
values[0] = 0;

bytes[] memory calldatas = new bytes[](1);
calldatas[0] = abi.encodeWithSignature("setFeePercentage(uint256)", 5);

uint256 proposalId = governor.proposeWithTrack(
    targets,
    values,
    calldatas,
    "Update marketplace fee to 5%",
    DAOGovernor.Track.Technical
);

// Vote (after delay)
governor.castVote(proposalId, 1); // 1 = For, 0 = Against, 2 = Abstain

// Execute (after timelock)
governor.execute(targets, values, calldatas, keccak256(bytes(description)));
```

---

### 3. DAOTreasury

**Purpose** : Manage DAO funds with spending proposals

**Features** :
- Milestone-based spending proposals
- Budget allocation by category
- Daily spend limits (500 ETH default)
- Max single spend (100 ETH default)

**Usage** :
```solidity
// Create spending proposal
uint256 proposalId = treasury.createProposal(
    payable(0xBeneficiary...),
    10 ether,
    "Payment for service X",
    "development" // Budget category
);

// Approve (Treasurer role)
treasury.approveProposal(proposalId);

// Execute (Spender role)
treasury.executeProposal(proposalId, "development");

// Allocate budget
treasury.allocateBudget("marketing", 100 ether);
```

---

## Development

### Project Structure

```
contracts/
├── src/
│   ├── DAOMembership.sol       # Membership + vote weights
│   ├── DAOGovernor.sol         # Multi-track governance
│   └── DAOTreasury.sol         # Treasury management
├── test/
│   ├── DAOMembership.t.sol     # 22 tests
│   ├── DAOGovernor.t.sol       # 11 tests
│   └── DAOTreasury.t.sol       # 20 tests
├── script/
│   ├── Deploy.s.sol            # Single contract deploy
│   └── DeployGovernance.s.sol  # Full system deploy
└── foundry.toml                # Foundry config
```

### Testing Guidelines

```bash
# Test single function
forge test --match-test testAddMember -vv

# Test with gas report
forge test --gas-report

# Test with traces
forge test --match-test testProposalFails -vvvv

# Snapshot tests (gas optimization)
forge snapshot
```

### Code Coverage

```bash
# Generate coverage report
forge coverage --report lcov

# View in browser (requires lcov)
genhtml lcov.info --branch-coverage --output-dir coverage
open coverage/index.html
```

---

## Deployed Contracts (Testnet Paseo)

| Contract | Address | Explorer |
|----------|---------|----------|
| DAOMembership | `0x...` | [View](https://paseo.subscan.io/account/0x...) |
| TimelockController | `0x...` | [View](https://paseo.subscan.io/account/0x...) |
| DAOGovernor | `0x...` | [View](https://paseo.subscan.io/account/0x...) |
| DAOTreasury | `0x...` | [View](https://paseo.subscan.io/account/0x...) |

---

## Security

### Audits

- **Phase 3** : Slither (automated) - ⏳ Pending
- **Phase 4** : OpenZeppelin Defender - 🔜 Scheduled
- **Phase 5** : Zellic/Oak Security - 📅 Conditional (on traction)

### Bug Bounty

Coming soon via Immunefi.

---

## Next Steps

### Phase 3 (Current - 60% → 100%)

- [ ] Integration tests (Membership ↔ Governor ↔ Treasury)
- [ ] Coverage report + fixes (target ≥80%)
- [ ] Testnet deployment (Paseo)

### Phase 3.5 (Next Week)

- [ ] ServiceMarketplace.sol (missions, matching)
- [ ] MissionEscrow.sol (milestone payments)
- [ ] HybridPaymentSplitter.sol (AI/human/compute splits)

---

## Resources

### Documentation

- [Architecture Overview](../docs/07-implementation/governance-architecture.md)
- [OpenGov Model](../docs/02-governance/polkadot-governance-fellowship-model.md)
- [Setup Guide](../README-SETUP.md)

### References

- [OpenZeppelin Governor](https://docs.openzeppelin.com/contracts/4.x/governance)
- [Polkadot OpenGov](https://wiki.polkadot.network/docs/learn-opengov)
- [Foundry Book](https://book.getfoundry.sh/)

---

## Contributing

See [CONTRIBUTING.md](../CONTRIBUTING.md) for guidelines.

---

## License

MIT
