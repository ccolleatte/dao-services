# DAOTreasury - Business Logic Specification

**Version** : 1.0.0
**Date** : 2026-02-10
**Source** : DAOTreasury.sol (333 lines)

---

## Purpose

Gestion treasury DAO avec governance-controlled spending, budget categories tracking, et spending limits pour prévenir abus/erreurs.

---

## Spending Proposal Data Model

### Proposal Attributes

| Attribute | Type | Constraints | Description |
|-----------|------|-------------|-------------|
| `id` | uint256 | Unique, auto-increment | Proposal identifier |
| `beneficiary` | Address (payable) | Non-null, valid address | Recipient of funds |
| `amount` | uint256 | > 0, ≤ maxSingleSpend | Amount to transfer (in wei) |
| `description` | String | Not empty, max 500 chars | Proposal rationale |
| `proposer` | Address | Non-null, member rank > 0 | Account that created proposal |
| `status` | ProposalStatus enum | Pending \| Approved \| Executed \| Cancelled | Proposal lifecycle state |
| `createdAt` | Timestamp | Non-null | Block timestamp at creation |
| `approvedAt` | Timestamp | Nullable | Block timestamp when approved |
| `executedAt` | Timestamp | Nullable | Block timestamp when executed |

### ProposalStatus Enum

```
Pending     → Awaiting TREASURER approval
Approved    → Ready for SPENDER execution
Executed    → Funds transferred, immutable state
Cancelled   → Rejected by proposer or treasurer, immutable state
```

---

## Proposal Lifecycle

### State Machine

```
[Draft] --createProposal()--> [Pending] --approveProposal()--> [Approved] --executeProposal()--> [Executed]
                                   |                                  |
                                   +--cancelProposal()--> [Cancelled] +
```

**Immutable states** : `Executed`, `Cancelled` (no further state changes allowed)

---

## Core Operations

### 1. Create Proposal

**Preconditions** :
- Caller is active member (DAOMembership)
- Caller rank > 0 (rank 1+ = Consultant or above)
- Amount > 0
- Beneficiary address valid
- Description not empty
- If category specified → Budget active AND (budget.spent + amount ≤ budget.allocated)

**Effects** :
- Increment proposal counter (nextProposalId++)
- Create proposal with status `Pending`
- Set proposer = msg.sender
- Set createdAt = block.timestamp
- Emit ProposalCreated event

**Post-conditions** :
- Proposal exists with unique ID
- Status = Pending
- Awaiting TREASURER_ROLE approval

**Example** :
```solidity
function createProposal(
    address payable beneficiary,
    uint256 amount,
    string memory description,
    string memory category
) external returns (uint256)
{
    // Verify proposer is active member with rank > 0
    (uint8 rank,,,, bool active) = membership.members(msg.sender);
    if (!active || rank == 0) revert Unauthorized();

    // Check budget if category provided
    if (bytes(category).length > 0) {
        bytes32 categoryHash = keccak256(bytes(category));
        Budget storage budget = budgets[categoryHash];
        if (budget.active && budget.spent + amount > budget.allocated) {
            revert BudgetExceeded();
        }
    }

    // Create proposal
    uint256 proposalId = nextProposalId++;
    proposals[proposalId] = SpendingProposal({
        id: proposalId,
        beneficiary: beneficiary,
        amount: amount,
        description: description,
        proposer: msg.sender,
        status: ProposalStatus.Pending,
        createdAt: block.timestamp,
        approvedAt: 0,
        executedAt: 0
    });

    emit ProposalCreated(proposalId, msg.sender, beneficiary, amount);
    return proposalId;
}
```

---

### 2. Approve Proposal

**Preconditions** :
- Caller has TREASURER_ROLE
- Proposal exists
- Proposal status = Pending
- Amount ≤ maxSingleSpend

**Effects** :
- Update status to `Approved`
- Set approvedAt = block.timestamp
- Emit ProposalApproved event

**Post-conditions** :
- Proposal status = Approved
- Ready for execution by SPENDER_ROLE
- Irreversible (cannot go back to Pending)

**Example** :
```solidity
function approveProposal(uint256 proposalId)
    external onlyRole(TREASURER_ROLE)
{
    SpendingProposal storage proposal = proposals[proposalId];

    if (proposal.status != ProposalStatus.Pending) {
        revert InvalidProposalStatus();
    }

    if (proposal.amount > maxSingleSpend) {
        revert ExceedsMaxSpend();
    }

    proposal.status = ProposalStatus.Approved;
    proposal.approvedAt = block.timestamp;

    emit ProposalApproved(proposalId);
}
```

---

### 3. Execute Proposal

**Preconditions** :
- Caller has SPENDER_ROLE
- Proposal status = Approved
- Treasury contract balance ≥ proposal.amount
- Daily spend limit not exceeded : (dailySpent + amount ≤ dailySpendLimit) OR day rolled over
- If category specified → Budget active AND (budget.spent + amount ≤ budget.allocated)

**Effects** :
- Update daily spend tracking :
  - If current day > lastSpendDay → Reset dailySpent = 0, lastSpendDay = current day
  - Increment dailySpent += amount
- If category specified → Increment budget.spent += amount
- Transfer funds to beneficiary (with ReentrancyGuard)
- Update status to `Executed`
- Set executedAt = block.timestamp
- Emit ProposalExecuted event

**Post-conditions** :
- Proposal status = Executed (immutable)
- Funds transferred to beneficiary
- Budget tracking updated (if category)
- Daily spend limit enforced

**Example** :
```solidity
function executeProposal(uint256 proposalId, string memory category)
    external nonReentrant onlyRole(SPENDER_ROLE)
{
    SpendingProposal storage proposal = proposals[proposalId];

    if (proposal.status != ProposalStatus.Approved) {
        revert InvalidProposalStatus();
    }

    // Daily spend limit with reset mechanism
    uint256 currentDay = block.timestamp / 1 days;
    if (currentDay > lastSpendDay) {
        dailySpent = 0;
        lastSpendDay = currentDay;
    }

    if (dailySpent + proposal.amount > dailySpendLimit) {
        revert ExceedsDailyLimit();
    }

    // Update budget tracking (if category specified)
    if (bytes(category).length > 0) {
        bytes32 categoryHash = keccak256(bytes(category));
        Budget storage budget = budgets[categoryHash];
        if (!budget.active) revert BudgetNotActive();
        if (budget.spent + proposal.amount > budget.allocated) {
            revert BudgetExceeded();
        }
        budget.spent += proposal.amount;
    }

    // Update daily spend
    dailySpent += proposal.amount;

    // Transfer funds (reentrancy protected)
    (bool success, ) = proposal.beneficiary.call{value: proposal.amount}("");
    require(success, "Transfer failed");

    // Update proposal state
    proposal.status = ProposalStatus.Executed;
    proposal.executedAt = block.timestamp;

    emit ProposalExecuted(proposalId, proposal.beneficiary, proposal.amount);
}
```

---

### 4. Cancel Proposal

**Preconditions** :
- Caller is proposer OR caller has TREASURER_ROLE
- Proposal status = Pending OR Approved (cannot cancel Executed/Cancelled)

**Effects** :
- Update status to `Cancelled`
- Emit ProposalCancelled event

**Post-conditions** :
- Proposal status = Cancelled (immutable)
- No funds transferred
- Cannot be re-activated

**Example** :
```solidity
function cancelProposal(uint256 proposalId) external
{
    SpendingProposal storage proposal = proposals[proposalId];

    // Authorization: proposer OR TREASURER_ROLE
    bool isProposer = msg.sender == proposal.proposer;
    bool isTreasurer = hasRole(TREASURER_ROLE, msg.sender);
    if (!isProposer && !isTreasurer) revert Unauthorized();

    // Cannot cancel executed or already cancelled proposals
    if (proposal.status == ProposalStatus.Executed ||
        proposal.status == ProposalStatus.Cancelled) {
        revert InvalidProposalStatus();
    }

    proposal.status = ProposalStatus.Cancelled;

    emit ProposalCancelled(proposalId, msg.sender);
}
```

---

## Budget System

### Budget Data Model

| Attribute | Type | Constraints | Description |
|-----------|------|-------------|-------------|
| `allocated` | uint256 | ≥ 0 | Total budget allocated for category |
| `spent` | uint256 | ≥ 0, ≤ allocated | Amount already spent from budget |
| `active` | Boolean | Non-null | Budget enforcement enabled |

### Category Tracking

Budgets stored as mapping : `categoryHash => Budget`

**categoryHash** : `keccak256(bytes(category))` (e.g., "Marketing", "Operations", "R&D")

### Budget Operations

**Create/Update Budget** :
- Only ADMIN_ROLE can create/modify budgets
- Set allocated amount
- Toggle active status (enable/disable enforcement)

**Budget Validation** :
- At proposal creation : Check `budget.spent + amount ≤ budget.allocated` (if category active)
- At proposal execution : Re-check budget (prevent TOCTOU race condition)
- If budget exceeded → Revert with `BudgetExceeded` error

---

## Spending Limits

### Limit Types

| Limit | Default Value | Purpose | Enforced At |
|-------|---------------|---------|-------------|
| `maxSingleSpend` | 100 ETH | Prevent single large unauthorized spend | approveProposal() |
| `dailySpendLimit` | 500 ETH | Rate limiting for daily treasury outflows | executeProposal() |

### Daily Spend Reset Mechanism

**Principle** : Daily limit resets automatically at midnight UTC

**Implementation** :
```solidity
uint256 public dailySpent;
uint256 public lastSpendDay;  // block.timestamp / 1 days

function executeProposal(...) {
    uint256 currentDay = block.timestamp / 1 days;

    // Auto-reset if day rolled over
    if (currentDay > lastSpendDay) {
        dailySpent = 0;
        lastSpendDay = currentDay;
    }

    // Check daily limit
    if (dailySpent + amount > dailySpendLimit) {
        revert ExceedsDailyLimit();
    }

    dailySpent += amount;
    // ... transfer funds
}
```

**Benefits** :
- No manual reset required
- Automatic rollover at midnight UTC
- Prevents rapid fund drainage attacks

---

## Access Control

### Roles Required

| Operation | Role Required | Additional Constraints |
|-----------|--------------|------------------------|
| `createProposal` | Member (rank > 0) | Budget check if category specified |
| `approveProposal` | TREASURER_ROLE | Amount ≤ maxSingleSpend |
| `executeProposal` | SPENDER_ROLE | Daily limit, budget check, reentrancy guard |
| `cancelProposal` | Proposer OR TREASURER_ROLE | Status = Pending or Approved |
| `createBudget` | ADMIN_ROLE | Admin only |
| `updateSpendingLimits` | ADMIN_ROLE | Admin only |

### Separation of Duties

| Phase | Role | Rationale |
|-------|------|-----------|
| **Proposal** | Any member (rank > 0) | Democratic proposal creation |
| **Approval** | TREASURER_ROLE | Financial oversight, spending limits check |
| **Execution** | SPENDER_ROLE | Operational role, separate from approval |

**Security rationale** : Separation prevents single actor from proposing + approving + executing without oversight

---

## Security Considerations

### Reentrancy Protection

**Requirement** : MUST use ReentrancyGuard on executeProposal()

**Attack Vector** : Malicious beneficiary contract calls back during transfer

**Mitigation** :
```solidity
function executeProposal(uint256 proposalId, string memory category)
    external nonReentrant onlyRole(SPENDER_ROLE)
{
    // State changes BEFORE external call
    proposal.status = ProposalStatus.Executed;
    dailySpent += proposal.amount;

    // External call (protected by nonReentrant)
    (bool success, ) = proposal.beneficiary.call{value: proposal.amount}("");
    require(success, "Transfer failed");
}
```

**Pattern** : Checks-Effects-Interactions + ReentrancyGuard

---

### Budget Enforcement

**TOCTOU Race Condition** : Time-Of-Check-Time-Of-Use

**Attack Vector** :
1. Proposer creates proposal with remaining budget = 10 ETH
2. Proposal approved
3. Before execution, another proposal executes and consumes budget
4. First proposal executes and exceeds budget

**Mitigation** :
- Re-check budget at execution time (not just creation time)
- Budget check in both createProposal() AND executeProposal()

---

### Daily Limit Bypass Prevention

**Attack Vector** : Execute multiple proposals simultaneously to bypass daily limit

**Mitigation** :
- Sequential execution enforced by nonReentrant modifier
- dailySpent updated BEFORE transfer (Checks-Effects-Interactions)

---

### Emergency Pause

**Requirement** : MUST implement pause mechanism for proposal execution

**Triggers** :
- Smart contract vulnerability discovered
- Treasury funds at risk
- Governance attack in progress

**Effects** :
- Block executeProposal() when paused
- Allow cancelProposal() (emergency stop)
- Allow proposal creation + approval (prepare queue for unpause)

---

## Integration Requirements

### DAOMembership Integration

**Required Functions** :
- `members(address)` : Access member struct (rank, active status)

**Interface** :
```solidity
interface IDAOMembership {
    function members(address _account)
        external view returns (
            uint8 rank,
            uint256 joinedAt,
            uint256 lastPromotedAt,
            string memory githubHandle,
            bool active
        );
}
```

**Usage** :
- createProposal() : Verify proposer rank > 0 AND active = true

---

## Constants

| Constant | Default Value | Description |
|----------|---------------|-------------|
| `MAX_SINGLE_SPEND` | 100 ETH | Maximum amount per proposal |
| `DAILY_SPEND_LIMIT` | 500 ETH | Maximum daily treasury outflows |
| `PROPOSAL_DESCRIPTION_MAX_LENGTH` | 500 characters | Prevent spam/DoS |

---

## Query Operations

### Get Proposal Details

**Input** : `proposalId` (uint256)

**Output** : SpendingProposal struct (all fields)

---

### Get Budget Details

**Input** : `category` (string)

**Output** : Budget struct (allocated, spent, active)

---

### Get Spending Limits

**Output** :
- maxSingleSpend (uint256)
- dailySpendLimit (uint256)
- dailySpent (uint256)
- lastSpendDay (uint256)

---

## Migration Notes (Substrate)

### Pallet Mapping

Ce contrat sera migré en **réutilisant pallet-treasury** (ecosystem battle-tested) avec **extensions custom** :

1. **pallet-treasury (réutilisé)** : Core spending logic, proposal lifecycle
2. **Custom extensions** :
   - Budget categories tracking (custom storage)
   - Daily spend limits with auto-reset (custom logic)
   - Role-based approval workflow (TREASURER/SPENDER separation)

**Rationale** : pallet-treasury fournit fondation solid + governance integration. Extensions légères pour features DAO-specific (budgets, limits).

---

### Bounded Types

**Substrate Requirements** :
```rust
pub struct SpendingProposal<AccountId, Balance> {
    pub beneficiary: AccountId,
    pub amount: Balance,
    pub description: BoundedVec<u8, ConstU32<500>>,  // Max 500 chars
    pub proposer: AccountId,
    pub status: ProposalStatus,
    // ... timestamps
}

pub struct Budget<Balance> {
    pub allocated: Balance,
    pub spent: Balance,
    pub active: bool,
}

// Category hash map
#[pallet::storage]
pub type Budgets<T: Config> = StorageMap<
    _,
    Blake2_128Concat,
    BoundedVec<u8, ConstU32<50>>,  // Category name max 50 chars
    Budget<BalanceOf<T>>
>;
```

---

### Weight Benchmarking

**Extrinsics requiring benchmarking** :
- `create_proposal()` : Weight depends on category budget check
- `approve_proposal()` : Weight includes spending limit validation
- `execute_proposal()` : Weight includes transfer + daily limit reset logic
- `cancel_proposal()` : Lightweight (status update only)

**Formula** :
```rust
weight = base_weight
    + T::DbWeight::get().reads(3)  // proposal, budget, membership
    + T::DbWeight::get().writes(2)  // proposal status, budget.spent
    + transfer_weight()
```

---

## Related Specifications

- **DAOMembership-specification.md** : Rank verification for proposal creation (rank > 0 required)
- **DAOGovernor-specification.md** : Treasury track proposals may modify spending limits or budgets via governance
- **Polkadot pallet-treasury** : Core treasury management pallet to reuse

---

**Version** : 1.0.0
**Date** : 2026-02-10
