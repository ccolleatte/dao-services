# Quick Start Developer Guide

Guide rapide pour contribuer au projet DAO Services IA/Humains.

---

## Prerequisites

```bash
# Node.js 20+
node --version  # v20.x.x

# Foundry (Ethereum smart contract toolkit)
curl -L https://foundry.paradigm.xyz | bash
foundryup
forge --version  # Should show foundry version
```

---

## Setup (5 min)

```bash
# 1. Clone repo
git clone https://github.com/your-org/dao-services.git
cd dao-services

# 2. Install dependencies
cd contracts
forge install

# 3. Build contracts
forge build

# 4. Run tests
forge test -vv
```

**Expected output** :
```
Running 53 tests for test/DAOMembership.t.sol:DAOMembershipTest
[PASS] testAddMember() (gas: 123456)
[PASS] testCalculateVoteWeight() (gas: 78910)
...
Test result: ok. 53 passed; 0 failed; 0 skipped; finished in 2.34s
```

---

## Project Structure

```
dao-services/
├── contracts/
│   ├── src/                    # Smart contracts
│   │   ├── DAOMembership.sol   # ✅ Ranks + vote weights
│   │   ├── DAOGovernor.sol     # ✅ 3-track governance
│   │   └── DAOTreasury.sol     # ✅ Spending proposals
│   ├── test/                   # Foundry tests
│   │   ├── DAOMembership.t.sol # 22 tests
│   │   ├── DAOGovernor.t.sol   # 11 tests
│   │   └── DAOTreasury.t.sol   # 20 tests
│   └── script/                 # Deploy scripts
│       └── DeployGovernance.s.sol
├── docs/
│   ├── 07-implementation/
│   │   ├── governance-architecture.md      # Architecture complète
│   │   └── IMPLEMENTATION-SUMMARY.md       # Résumé phase 3
│   └── ...
├── frontend/                   # Next.js app (🔜 semaine +2)
└── README.md
```

---

## Key Concepts

### 1. Membership System (DAOMembership.sol)

**Ranks** : Hierarchical system (0-4)

| Rank | Name | Vote Weight | Min Duration |
|------|------|-------------|--------------|
| 0 | Observer | 0 | - |
| 1 | Active Contributor | 1 | 30 days |
| 2 | Mid-Level | 3 | 90 days |
| 3 | Core Team | 6 | 180 days |
| 4 | Founder | 10 | 365 days |

**Vote weights** : Triangular numbers (0, 1, 3, 6, 10)

```solidity
// Calculate vote weight
uint256 weight = membership.calculateVoteWeight(address);
// Rank 2 → weight = 3
```

---

### 2. Governance System (DAOGovernor.sol)

**3 Tracks OpenGov-Inspired** :

| Track | Min Rank | Period | Quorum | Use Cases |
|-------|----------|--------|--------|-----------|
| Technical | Rank 2+ | 7 days | 66% | Architecture, security |
| Treasury | Rank 1+ | 14 days | 51% | Budget, spending |
| Membership | Rank 3+ | 7 days | 75% | Promote/demote |

**Workflow** :
```
Propose → Voting Delay (1 day) → Voting Period (7-14d) → Timelock (1 day) → Execute
```

**Example** :
```solidity
// Create Technical proposal
uint256 proposalId = governor.proposeWithTrack(
    targets,
    values,
    calldatas,
    "Update marketplace fee to 5%",
    DAOGovernor.Track.Technical
);

// Vote
governor.castVote(proposalId, 1); // 1 = For

// Execute (after timelock)
governor.execute(...);
```

---

### 3. Treasury Management (DAOTreasury.sol)

**Spending Proposals** :
```
Create → Approve (Treasurer) → Execute (Spender) → Transfer ETH
```

**Limits** :
- Max single spend : 100 ETH
- Daily limit : 500 ETH
- Budget per category (e.g., "marketing": 100 ETH)

**Example** :
```solidity
// Create spending proposal
uint256 proposalId = treasury.createProposal(
    payable(beneficiary),
    10 ether,
    "Payment for service X",
    "development"
);

// Approve + Execute
treasury.approveProposal(proposalId);
treasury.executeProposal(proposalId, "development");
```

---

## Development Workflow

### 1. Write Contract

```bash
# Create new contract
touch contracts/src/MyNewContract.sol
```

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/...";

contract MyNewContract {
    // Your code here
}
```

---

### 2. Write Tests

```bash
# Create test file
touch contracts/test/MyNewContract.t.sol
```

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/MyNewContract.sol";

contract MyNewContractTest is Test {
    MyNewContract public contract;

    function setUp() public {
        contract = new MyNewContract();
    }

    function testFeature() public {
        // Test your feature
        assertEq(contract.myFunction(), expectedValue);
    }
}
```

---

### 3. Run Tests

```bash
# Run all tests
forge test

# Run specific contract tests
forge test --match-path test/MyNewContract.t.sol -vv

# Run with gas report
forge test --gas-report

# Coverage
forge coverage --report summary
```

---

### 4. Deploy

```bash
# Local deployment (Anvil)
anvil &  # Start local node
forge script script/Deploy.s.sol --rpc-url http://localhost:8545 --broadcast

# Testnet deployment (Paseo)
export PRIVATE_KEY="0x..."
export RPC_URL="https://paseo-rpc.polkadot.io"
forge script script/DeployGovernance.s.sol:DeployGovernance \
    --rpc-url $RPC_URL \
    --broadcast \
    --verify
```

---

## Testing Guidelines

### Test Structure

```solidity
contract MyContractTest is Test {
    // 1. State variables
    MyContract public myContract;
    address public user1 = address(1);

    // 2. Setup (runs before each test)
    function setUp() public {
        myContract = new MyContract();
    }

    // 3. Test functions (prefix with "test")
    function testFeatureName() public {
        // Arrange
        vm.prank(user1);  // Simulate call from user1

        // Act
        uint256 result = myContract.myFunction();

        // Assert
        assertEq(result, expectedValue);
    }

    // 4. Test reverts
    function testFeatureReverts() public {
        vm.expectRevert(MyContract.CustomError.selector);
        myContract.functionThatReverts();
    }
}
```

### Common Cheatcodes

```solidity
// Time manipulation
vm.warp(block.timestamp + 1 days);  // Fast-forward time
vm.roll(block.number + 100);        // Fast-forward blocks

// Address manipulation
vm.prank(address);                  // Next call from address
vm.startPrank(address);             // All subsequent calls from address
vm.stopPrank();

// Balance manipulation
vm.deal(address, 100 ether);        // Give 100 ETH to address

// Expectations
vm.expectRevert();                  // Expect next call reverts
vm.expectEmit(true, true, false, false);  // Expect event
```

---

## Code Style

### Solidity

```solidity
// 1. SPDX + pragma
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// 2. Imports (sorted)
import "@openzeppelin/contracts/...";
import "./MyContract.sol";

// 3. Contract
contract MyContract {
    // 3.1 Type declarations (struct, enum)
    enum Status { Pending, Active, Completed }

    // 3.2 State variables
    uint256 public totalSupply;

    // 3.3 Events
    event Transfer(address indexed from, address indexed to, uint256 amount);

    // 3.4 Errors
    error InsufficientBalance();

    // 3.5 Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    // 3.6 Constructor
    constructor() {
        owner = msg.sender;
    }

    // 3.7 External functions
    function publicFunction() external {}

    // 3.8 Public functions
    function publicView() public view returns (uint256) {}

    // 3.9 Internal functions
    function _internalFunction() internal {}

    // 3.10 Private functions
    function _privateFunction() private {}
}
```

### Naming Conventions

- **Contracts** : PascalCase (`MyContract`)
- **Functions** : camelCase (`calculateReward`)
- **State variables** : camelCase (`totalSupply`)
- **Constants** : UPPER_SNAKE_CASE (`MAX_SUPPLY`)
- **Private functions** : prefix `_` (`_internalHelper`)
- **Events** : PascalCase (`Transfer`)
- **Errors** : PascalCase (`InsufficientBalance`)

---

## Common Tasks

### Add New Member

```solidity
// Admin adds member with Rank 1
membership.addMember(0xABC..., 1);
```

### Create Governance Proposal

```solidity
// Create Technical proposal (requires Rank 2+)
address[] memory targets = new address[](1);
targets[0] = address(targetContract);

uint256[] memory values = new uint256[](1);
values[0] = 0;

bytes[] memory calldatas = new bytes[](1);
calldatas[0] = abi.encodeWithSignature("updateParameter(uint256)", 42);

uint256 proposalId = governor.proposeWithTrack(
    targets,
    values,
    calldatas,
    "Update parameter to 42",
    DAOGovernor.Track.Technical
);
```

### Create Treasury Spending Proposal

```solidity
// Create spending proposal
uint256 proposalId = treasury.createProposal(
    payable(0xBeneficiary...),
    50 ether,
    "Payment for consultancy services",
    "development"
);

// Treasurer approves
treasury.approveProposal(proposalId);

// Spender executes
treasury.executeProposal(proposalId, "development");
```

---

## Debugging

### Gas Optimization

```bash
# Gas report
forge test --gas-report

# Gas snapshot (compare across commits)
forge snapshot
forge snapshot --diff .gas-snapshot
```

### Traces

```bash
# Full traces
forge test --match-test testMyFunction -vvvv

# Specific contract traces
forge test --match-contract MyContractTest -vvvv
```

### Console Logs

```solidity
import "forge-std/console.sol";

function myFunction() public {
    console.log("Debug value:", someVariable);
    console.log("Address:", msg.sender);
}
```

---

## Resources

### Documentation

- [Governance Architecture](./docs/07-implementation/governance-architecture.md)
- [Implementation Summary](./docs/07-implementation/IMPLEMENTATION-SUMMARY.md)
- [Contracts README](./contracts/README.md)

### External

- [Foundry Book](https://book.getfoundry.sh/)
- [OpenZeppelin Docs](https://docs.openzeppelin.com/contracts/4.x/)
- [Solidity Docs](https://docs.soliditylang.org/)
- [Polkadot Wiki](https://wiki.polkadot.network/)

---

## Next Steps

### Current Sprint (Cette semaine)

- [ ] Integration tests (Membership ↔ Governor ↔ Treasury)
- [ ] Coverage report + fixes (target ≥80%)
- [ ] Testnet deployment (Paseo)

### Next Sprint (Semaine prochaine)

- [ ] ServiceMarketplace.sol (missions, matching)
- [ ] MissionEscrow.sol (milestone payments)
- [ ] HybridPaymentSplitter.sol (AI/human/compute splits)

---

## Support

### Getting Help

1. **Documentation** : Check [docs/](./docs/) first
2. **Issues** : Open GitHub issue for bugs/features
3. **Discord** : Join Polkadot Discord for ecosystem questions
4. **Stack Exchange** : Ethereum Stack Exchange for Solidity questions

### Contributing

See [CONTRIBUTING.md](./CONTRIBUTING.md) for guidelines.

---

**Last updated** : 2026-02-09
**Phase 3 Status** : 60% complete
