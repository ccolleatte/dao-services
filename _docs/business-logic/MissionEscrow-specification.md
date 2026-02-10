# MissionEscrow - Business Logic Specification

**Version** : 1.0.0
**Date** : 2026-02-10
**Source** : MissionEscrow.sol (472 lines)

---

## Purpose

Gestion escrow pour missions marketplace avec milestone-based payment, dispute resolution via jury 5 membres, auto-release 7 jours, et sequential milestone validation.

---

## Milestone Data Model

### Milestone Attributes

| Attribute | Type | Constraints | Description |
|-----------|------|-------------|-------------|
| `id` | uint256 | Unique, auto-increment | Milestone identifier |
| `missionId` | uint256 | Non-null, exists in ServiceMarketplace | Parent mission reference |
| `description` | String | Not empty, max 500 chars | Milestone deliverable description |
| `amount` | uint256 | > 0, sum(milestones) = mission.budget | Payment amount for this milestone (in wei) |
| `deadline` | Timestamp | Non-null, future timestamp | Deadline for deliverable submission |
| `status` | MilestoneStatus enum | Pending \| Submitted \| Approved \| Rejected \| Disputed | Milestone lifecycle state |
| `deliverable` | String | IPFS hash (46 chars) | IPFS hash of deliverable file/document |
| `submittedAt` | Timestamp | Nullable | Block timestamp when consultant submitted |
| `approvedAt` | Timestamp | Nullable | Block timestamp when client approved |
| `rejectedAt` | Timestamp | Nullable | Block timestamp when client rejected |

### MilestoneStatus Enum

```
Pending     → Consultant working on deliverable
Submitted   → Consultant submitted deliverable, awaiting client review
Approved    → Client approved, payment released
Rejected    → Client rejected, consultant can resubmit or dispute
Disputed    → Dispute raised by consultant, jury voting in progress
```

---

## Dispute Data Model

### Dispute Attributes

| Attribute | Type | Constraints | Description |
|-----------|------|-------------|-------------|
| `id` | uint256 | Unique, auto-increment | Dispute identifier |
| `milestoneId` | uint256 | Non-null, exists | Disputed milestone reference |
| `initiator` | Address | Non-null, must be consultant | Account that raised dispute |
| `reason` | String | Not empty, max 1000 chars | Consultant's reason for disputing rejection |
| `consultantResponse` | String | Max 1000 chars | Consultant's detailed response |
| `jurors` | Address[] | Length = 5, rank ≥ 3 members | 5 jury members (pseudo-randomly selected) |
| `hasVoted` | mapping(address => bool) | Non-null | Track who voted |
| `votesFor` | uint256 | 0-5 | Votes in favor of consultant |
| `votesAgainst` | uint256 | 0-5 | Votes in favor of client |
| `status` | DisputeStatus enum | Open \| Voting \| Resolved | Dispute lifecycle state |
| `winner` | Address | Nullable | Winner address (consultant or client) |
| `createdAt` | Timestamp | Non-null | Block timestamp at dispute creation |
| `votingDeadline` | Timestamp | createdAt + 72 hours | Voting period deadline |

### DisputeStatus Enum

```
Open        → Dispute created, jury being selected
Voting      → Jury voting in progress (72 hours)
Resolved    → Voting complete, winner determined, funds released
```

---

## Milestone Lifecycle

### State Machine

```
[Created] --createMilestone()--> [Pending] --submitMilestone()--> [Submitted]
                                                                       |
                                                                       v
[Approved] <--approveMilestone()-- [Submitted] --rejectMilestone()--> [Rejected]
    |                                                                     |
    v                                                                     v
[Payment Released]                                         [Resubmit OR raiseDispute()]
                                                                     |
                                                                     v
                                                                [Disputed]
                                                                     |
                                                                     v
                                                              [Jury Voting]
                                                                     |
                                                                     v
                                                           [Resolved → Payment]
```

**Sequential Validation Rule** : Milestone N+1 cannot be submitted until Milestone N is approved.

**Auto-Release Rule** : If client does not approve/reject within 7 days after submission → Milestone automatically approved, payment released.

---

## Core Operations

### 1. Create Milestone

**Preconditions** :
- Caller is mission client (ServiceMarketplace)
- Mission exists and status = Active
- Sum(milestone amounts) = mission.budget
- Deadline > current timestamp

**Effects** :
- Increment milestone counter (nextMilestoneId++)
- Create milestone with status `Pending`
- Lock mission budget in escrow contract
- Emit MilestoneCreated event

**Post-conditions** :
- Milestone exists with unique ID
- Status = Pending
- Consultant can start working on deliverable

**Example** :
```solidity
function createMilestone(
    uint256 missionId,
    string memory description,
    uint256 amount,
    uint256 deadline
) external returns (uint256)
{
    // Verify caller is client
    Mission storage mission = missions[missionId];
    require(msg.sender == mission.client, "Only client can create milestones");

    // Verify budget consistency
    uint256 totalAllocated = 0;
    for (uint256 i = 0; i < mission.milestoneCount; i++) {
        totalAllocated += milestones[mission.milestones[i]].amount;
    }
    require(totalAllocated + amount <= mission.budget, "Budget exceeded");

    // Create milestone
    uint256 milestoneId = nextMilestoneId++;
    milestones[milestoneId] = Milestone({
        id: milestoneId,
        missionId: missionId,
        description: description,
        amount: amount,
        deadline: deadline,
        status: MilestoneStatus.Pending,
        deliverable: "",
        submittedAt: 0,
        approvedAt: 0,
        rejectedAt: 0
    });

    emit MilestoneCreated(milestoneId, missionId, amount, deadline);
    return milestoneId;
}
```

---

### 2. Submit Milestone

**Preconditions** :
- Caller is mission consultant
- Milestone status = Pending OR Rejected (resubmission allowed)
- Deliverable IPFS hash provided (46 chars)
- Sequential validation : If milestone N → All previous milestones (0 to N-1) MUST be approved

**Effects** :
- Update status to `Submitted`
- Set deliverable = IPFS hash
- Set submittedAt = block.timestamp
- Start auto-release timer (7 days)
- Emit MilestoneSubmitted event

**Post-conditions** :
- Milestone status = Submitted
- Client can approve/reject
- Auto-release triggers if no action within 7 days

**Sequential Validation Example** :
```solidity
function submitMilestone(uint256 milestoneId, string memory deliverable)
    external nonReentrant
{
    Milestone storage milestone = milestones[milestoneId];

    // Verify consultant
    Mission storage mission = missions[milestone.missionId];
    require(msg.sender == mission.consultant, "Only consultant can submit");

    // Sequential validation
    if (milestoneId > 0) {
        Milestone storage prevMilestone = milestones[milestoneId - 1];
        require(
            prevMilestone.status == MilestoneStatus.Approved,
            "Previous milestone must be approved"
        );
    }

    // Verify deliverable format (IPFS hash)
    require(bytes(deliverable).length == 46, "Invalid IPFS hash");

    milestone.status = MilestoneStatus.Submitted;
    milestone.deliverable = deliverable;
    milestone.submittedAt = block.timestamp;

    emit MilestoneSubmitted(milestoneId, deliverable);
}
```

---

### 3. Approve Milestone

**Preconditions** :
- Caller is mission client
- Milestone status = Submitted
- Deliverable IPFS hash exists

**Effects** :
- Update status to `Approved`
- Set approvedAt = block.timestamp
- Release payment to consultant (with ReentrancyGuard)
- Emit MilestoneApproved event

**Post-conditions** :
- Milestone status = Approved (immutable)
- Payment transferred to consultant
- Next milestone (N+1) can now be submitted

**Example** :
```solidity
function approveMilestone(uint256 milestoneId)
    external nonReentrant
{
    Milestone storage milestone = milestones[milestoneId];
    Mission storage mission = missions[milestone.missionId];

    require(msg.sender == mission.client, "Only client can approve");
    require(milestone.status == MilestoneStatus.Submitted, "Invalid status");

    // Update status
    milestone.status = MilestoneStatus.Approved;
    milestone.approvedAt = block.timestamp;

    // Release payment (reentrancy protected)
    (bool success, ) = mission.consultant.call{value: milestone.amount}("");
    require(success, "Payment transfer failed");

    emit MilestoneApproved(milestoneId, milestone.amount);
}
```

---

### 4. Reject Milestone

**Preconditions** :
- Caller is mission client
- Milestone status = Submitted
- Rejection reason provided

**Effects** :
- Update status to `Rejected`
- Set rejectedAt = block.timestamp
- Store rejection reason
- Emit MilestoneRejected event

**Post-conditions** :
- Milestone status = Rejected
- Consultant can resubmit OR raise dispute
- Payment remains locked in escrow

**Example** :
```solidity
function rejectMilestone(uint256 milestoneId, string memory reason)
    external
{
    Milestone storage milestone = milestones[milestoneId];
    Mission storage mission = missions[milestone.missionId];

    require(msg.sender == mission.client, "Only client can reject");
    require(milestone.status == MilestoneStatus.Submitted, "Invalid status");

    milestone.status = MilestoneStatus.Rejected;
    milestone.rejectedAt = block.timestamp;

    emit MilestoneRejected(milestoneId, reason);
}
```

---

### 5. Auto-Release Milestone

**Trigger** : Called by anyone if 7 days elapsed since submission without client action

**Preconditions** :
- Milestone status = Submitted
- block.timestamp >= milestone.submittedAt + 7 days
- Client has NOT approved or rejected

**Effects** :
- Automatically approve milestone (same as approveMilestone)
- Release payment to consultant
- Emit MilestoneAutoReleased event

**Post-conditions** :
- Milestone status = Approved
- Payment transferred to consultant
- Client lost opportunity to reject

**Example** :
```solidity
function autoReleaseMilestone(uint256 milestoneId)
    external nonReentrant
{
    Milestone storage milestone = milestones[milestoneId];

    require(milestone.status == MilestoneStatus.Submitted, "Invalid status");
    require(
        block.timestamp >= milestone.submittedAt + AUTO_RELEASE_DELAY,
        "Auto-release not ready"
    );

    // Approve automatically
    milestone.status = MilestoneStatus.Approved;
    milestone.approvedAt = block.timestamp;

    // Release payment
    Mission storage mission = missions[milestone.missionId];
    (bool success, ) = mission.consultant.call{value: milestone.amount}("");
    require(success, "Payment transfer failed");

    emit MilestoneAutoReleased(milestoneId, milestone.amount);
}
```

---

## Dispute Resolution System

### 6. Raise Dispute

**Preconditions** :
- Caller is mission consultant
- Milestone status = Rejected
- Deposit = 100 DAOS (refunded to winner)
- Reason provided (max 1000 chars)

**Effects** :
- Update status to `Disputed`
- Lock dispute deposit from consultant
- Select 5-member jury (pseudo-randomly from rank ≥ 3 members)
- Create dispute record with 72-hour voting deadline
- Emit DisputeRaised event

**Post-conditions** :
- Dispute status = Voting
- 72-hour voting period starts
- Jury members can vote

**Jury Selection Algorithm** :
```solidity
function selectJury() internal view returns (address[] memory) {
    address[] memory eligibleMembers = membership.getActiveMembersByRank(3); // Rank 3+ (Manager, Partner)

    // Exclude client and consultant
    Mission storage mission = missions[milestone.missionId];
    address[] memory filtered = new address[](eligibleMembers.length);
    uint256 count = 0;

    for (uint256 i = 0; i < eligibleMembers.length; i++) {
        if (eligibleMembers[i] != mission.client && eligibleMembers[i] != mission.consultant) {
            filtered[count++] = eligibleMembers[i];
        }
    }

    require(count >= JURY_SIZE, "Not enough eligible jurors");

    // Pseudo-random selection (5 members)
    address[] memory jurors = new address[](JURY_SIZE);
    uint256 seed = uint256(keccak256(abi.encodePacked(block.timestamp, block.prevrandao)));

    for (uint256 i = 0; i < JURY_SIZE; i++) {
        uint256 index = seed % count;
        jurors[i] = filtered[index];
        seed = uint256(keccak256(abi.encodePacked(seed, i)));
    }

    return jurors;
}
```

**Example** :
```solidity
function raiseDispute(uint256 milestoneId, string memory reason)
    external payable nonReentrant returns (uint256)
{
    Milestone storage milestone = milestones[milestoneId];
    Mission storage mission = missions[milestone.missionId];

    require(msg.sender == mission.consultant, "Only consultant can dispute");
    require(milestone.status == MilestoneStatus.Rejected, "Invalid status");
    require(msg.value >= DISPUTE_DEPOSIT, "Insufficient deposit");

    // Update milestone status
    milestone.status = MilestoneStatus.Disputed;

    // Select jury
    address[] memory jurors = selectJury();

    // Create dispute
    uint256 disputeId = nextDisputeId++;
    disputes[disputeId] = Dispute({
        id: disputeId,
        milestoneId: milestoneId,
        initiator: msg.sender,
        reason: reason,
        consultantResponse: "",
        jurors: jurors,
        votesFor: 0,
        votesAgainst: 0,
        status: DisputeStatus.Voting,
        winner: address(0),
        createdAt: block.timestamp,
        votingDeadline: block.timestamp + VOTING_PERIOD
    });

    emit DisputeRaised(disputeId, milestoneId, msg.sender, reason);
    return disputeId;
}
```

---

### 7. Vote on Dispute

**Preconditions** :
- Caller is jury member (one of 5 selected jurors)
- Dispute status = Voting
- Voting deadline not passed (block.timestamp < votingDeadline)
- Caller has NOT voted yet

**Effects** :
- Record vote (for consultant OR for client)
- Increment votesFor OR votesAgainst
- Mark hasVoted[juror] = true
- If majority reached (3/5 votes) → Resolve dispute automatically
- Emit DisputeVoted event

**Post-conditions** :
- Vote recorded
- If majority reached → Dispute resolved, payment released to winner

**Example** :
```solidity
function voteOnDispute(uint256 disputeId, bool favorConsultant)
    external
{
    Dispute storage dispute = disputes[disputeId];

    // Verify juror
    bool isJuror = false;
    for (uint256 i = 0; i < dispute.jurors.length; i++) {
        if (dispute.jurors[i] == msg.sender) {
            isJuror = true;
            break;
        }
    }
    require(isJuror, "Not a juror");

    // Verify not voted yet
    require(!dispute.hasVoted[msg.sender], "Already voted");

    // Verify voting period
    require(block.timestamp < dispute.votingDeadline, "Voting period ended");

    // Record vote
    dispute.hasVoted[msg.sender] = true;
    if (favorConsultant) {
        dispute.votesFor++;
    } else {
        dispute.votesAgainst++;
    }

    emit DisputeVoted(disputeId, msg.sender, favorConsultant);

    // Check if majority reached (3/5)
    if (dispute.votesFor >= 3 || dispute.votesAgainst >= 3) {
        resolveDispute(disputeId);
    }
}
```

---

### 8. Resolve Dispute

**Trigger** : Automatically called when 3/5 majority reached OR manually after voting deadline

**Preconditions** :
- Dispute status = Voting
- Majority reached (votesFor ≥ 3 OR votesAgainst ≥ 3) OR voting deadline passed

**Effects** :
- Update status to `Resolved`
- Determine winner (consultant if votesFor ≥ 3, client otherwise)
- If consultant wins → Release milestone payment + dispute deposit refund
- If client wins → Release dispute deposit to client
- Update milestone status based on outcome
- Emit DisputeResolved event

**Post-conditions** :
- Dispute status = Resolved (immutable)
- Funds released to winner
- Milestone status = Approved (consultant wins) OR remains Rejected (client wins)

**Example** :
```solidity
function resolveDispute(uint256 disputeId)
    internal nonReentrant
{
    Dispute storage dispute = disputes[disputeId];

    require(dispute.status == DisputeStatus.Voting, "Invalid status");

    // Determine winner
    address winner;
    bool consultantWins = dispute.votesFor >= 3;

    if (consultantWins) {
        winner = dispute.initiator; // Consultant
        Milestone storage milestone = milestones[dispute.milestoneId];
        milestone.status = MilestoneStatus.Approved;
        milestone.approvedAt = block.timestamp;

        // Release milestone payment + deposit refund
        (bool success, ) = winner.call{value: milestone.amount + DISPUTE_DEPOSIT}("");
        require(success, "Payment transfer failed");
    } else {
        Mission storage mission = missions[milestones[dispute.milestoneId].missionId];
        winner = mission.client;

        // Release deposit to client
        (bool success, ) = winner.call{value: DISPUTE_DEPOSIT}("");
        require(success, "Deposit refund failed");
    }

    dispute.status = DisputeStatus.Resolved;
    dispute.winner = winner;

    emit DisputeResolved(disputeId, winner, consultantWins);
}
```

---

## Security Considerations

### Reentrancy Protection

**Requirement** : MUST use ReentrancyGuard on all payment operations

**Attack Vector** : Malicious consultant/client contract calls back during payment transfer

**Mitigation** :
```solidity
function approveMilestone(uint256 milestoneId)
    external nonReentrant // <-- ReentrancyGuard
{
    // State changes BEFORE external call
    milestone.status = MilestoneStatus.Approved;
    milestone.approvedAt = block.timestamp;

    // External call (protected by nonReentrant)
    (bool success, ) = mission.consultant.call{value: milestone.amount}("");
    require(success, "Payment transfer failed");
}
```

**Pattern** : Checks-Effects-Interactions + ReentrancyGuard

---

### Sequential Milestone Validation

**Attack Vector** : Consultant submits milestones out of order to bypass previous rejections

**Mitigation** :
- Enforce sequential submission : Milestone N+1 CANNOT be submitted if Milestone N NOT approved
- Check performed in submitMilestone()

---

### Jury Manipulation Prevention

**Attack Vector 1** : Client/consultant creates multiple accounts to become jury members

**Mitigation** :
- Jury selection EXCLUDES client and consultant addresses
- Require rank ≥ 3 (Manager+ only) → Reduces sybil attack surface

**Attack Vector 2** : Predictable jury selection (bribery)

**Mitigation** :
- Pseudo-random selection based on block.timestamp + block.prevrandao
- Not cryptographically secure but sufficient for game-theoretic discouragement

---

### Auto-Release Abuse Prevention

**Attack Vector** : Client deliberately delays review to block consultant payment

**Mitigation** :
- 7-day auto-release mechanism
- Anyone can trigger auto-release after delay (not just consultant)

---

### Dispute Deposit Spam Prevention

**Attack Vector** : Consultant raises frivolous disputes

**Mitigation** :
- 100 DAOS deposit required
- Deposit refunded ONLY to winner
- Creates financial disincentive for bad-faith disputes

---

## Integration Requirements

### DAOMembership Integration

**Required Functions** :
- `getActiveMembersByRank(uint8 rank)` : Get all members with rank ≥ 3 for jury selection

**Interface** :
```solidity
interface IDAOMembership {
    function getActiveMembersByRank(uint8 _rank)
        external view returns (address[] memory);
}
```

**Usage** :
- raiseDispute() : Select jury from rank ≥ 3 members (Manager, Partner)

---

### ServiceMarketplace Integration

**Required Functions** :
- `missions(uint256 missionId)` : Access mission struct (client, consultant, budget, status)

**Interface** :
```solidity
interface IServiceMarketplace {
    function missions(uint256 _missionId)
        external view returns (
            address client,
            address consultant,
            uint256 budget,
            MissionStatus status
        );
}
```

**Usage** :
- All milestone operations verify mission ownership and status

---

## Constants

| Constant | Default Value | Description |
|----------|---------------|-------------|
| `AUTO_RELEASE_DELAY` | 7 days (604,800 seconds) | Delay before auto-approval of submitted milestone |
| `DISPUTE_DEPOSIT` | 100 DAOS (100 ether) | Deposit required to raise dispute |
| `JURY_SIZE` | 5 | Number of jury members for dispute voting |
| `VOTING_PERIOD` | 72 hours (259,200 seconds) | Voting period deadline for disputes |
| `MILESTONE_DESCRIPTION_MAX_LENGTH` | 500 characters | Prevent spam/DoS |
| `DISPUTE_REASON_MAX_LENGTH` | 1000 characters | Prevent spam/DoS |

---

## Query Operations

### Get Milestone Details

**Input** : `milestoneId` (uint256)

**Output** : Milestone struct (all fields)

---

### Get Dispute Details

**Input** : `disputeId` (uint256)

**Output** : Dispute struct (all fields including jurors array)

---

### Get Mission Milestones

**Input** : `missionId` (uint256)

**Output** : Array of milestone IDs for this mission

---

### Get Active Disputes

**Output** : Array of dispute IDs with status = Voting

---

## Migration Notes (Substrate)

### Pallet Mapping

Ce contrat sera migré vers **custom pallet `pallet-mission-escrow`** car :
- Milestone-based payment system unique
- Dispute resolution avec jury selection
- Sequential validation logic spécifique
- Pas de pallet existant dans l'écosystème Polkadot

**Potential Reuse** :
- `pallet-collective` : Réutilisable pour jury voting mechanism (adapter for dispute context)
- `pallet-treasury` : Patterns de spending limits (adapter for escrow release)

---

### Bounded Types

**Substrate Requirements** :
```rust
pub struct Milestone<AccountId, Balance, BlockNumber> {
    pub id: u64,
    pub mission_id: u64,
    pub description: BoundedVec<u8, ConstU32<500>>,  // Max 500 chars
    pub amount: Balance,
    pub deadline: BlockNumber,
    pub status: MilestoneStatus,
    pub deliverable: BoundedVec<u8, ConstU32<46>>,  // IPFS hash (46 chars)
    pub submitted_at: Option<BlockNumber>,
    pub approved_at: Option<BlockNumber>,
    pub rejected_at: Option<BlockNumber>,
}

pub struct Dispute<AccountId, BlockNumber> {
    pub id: u64,
    pub milestone_id: u64,
    pub initiator: AccountId,
    pub reason: BoundedVec<u8, ConstU32<1000>>,  // Max 1000 chars
    pub consultant_response: BoundedVec<u8, ConstU32<1000>>,
    pub jurors: BoundedVec<AccountId, ConstU32<5>>,  // Fixed 5 jurors
    pub votes_for: u8,
    pub votes_against: u8,
    pub status: DisputeStatus,
    pub winner: Option<AccountId>,
    pub created_at: BlockNumber,
    pub voting_deadline: BlockNumber,
}

// Vote tracking
#[pallet::storage]
pub type DisputeVotes<T: Config> = StorageDoubleMap<
    _,
    Blake2_128Concat,
    u64,  // Dispute ID
    Blake2_128Concat,
    T::AccountId,  // Juror
    bool  // Has voted
>;
```

---

### Weight Benchmarking

**Extrinsics requiring benchmarking** :
- `submit_milestone()` : Weight depends on sequential validation check (iterate previous milestones)
- `raise_dispute()` : Weight includes jury selection (iterate rank ≥ 3 members)
- `vote_on_dispute()` : Weight includes majority check + potential resolve_dispute call
- `auto_release_milestone()` : Weight includes payment transfer + state update

**Formula** :
```rust
weight = base_weight
    + T::DbWeight::get().reads(5)  // milestone, mission, membership check, dispute, jurors
    + T::DbWeight::get().writes(3)  // milestone status, dispute record, payment transfer
    + jury_selection_weight()  // O(n) where n = rank ≥ 3 members
```

---

### Pseudo-Random Jury Selection (Substrate)

**Solidity** : Uses `block.prevrandao` (post-Merge randomness)

**Substrate Migration** :
```rust
use frame_support::traits::Randomness;

fn select_jury<T: Config>() -> Result<BoundedVec<T::AccountId, ConstU32<5>>, Error<T>> {
    let eligible_members = pallet_membership::Pallet::<T>::get_active_members_by_rank(3)?;

    // Filter out client and consultant
    let filtered: Vec<T::AccountId> = eligible_members.into_iter()
        .filter(|m| m != &mission.client && m != &mission.consultant)
        .collect();

    ensure!(filtered.len() >= 5, Error::<T>::NotEnoughJurors);

    // Use pallet-randomness-collective-flip or pallet-babe for randomness
    let random_seed = T::Randomness::random_seed().0;
    let mut jurors = BoundedVec::<T::AccountId, ConstU32<5>>::new();

    for i in 0..5 {
        let index = (random_seed[i] as usize) % filtered.len();
        jurors.try_push(filtered[index].clone())
            .map_err(|_| Error::<T>::JurySelectionFailed)?;
    }

    Ok(jurors)
}
```

**Note** : `pallet-babe` provides better randomness than `block.prevrandao` (VRF-based)

---

### Auto-Release Mechanism (Substrate)

**Solidity** : Anyone can call `autoReleaseMilestone()` if 7 days elapsed

**Substrate Migration** :
```rust
use frame_support::pallet_prelude::*;

#[pallet::hooks]
impl<T: Config> Hooks<BlockNumberFor<T>> for Pallet<T> {
    fn on_initialize(n: BlockNumberFor<T>) -> Weight {
        // Check all submitted milestones for auto-release
        let now = <frame_system::Pallet<T>>::block_number();

        for (milestone_id, milestone) in Milestones::<T>::iter() {
            if milestone.status == MilestoneStatus::Submitted {
                let elapsed = now.saturating_sub(milestone.submitted_at.unwrap_or(now));

                if elapsed >= AUTO_RELEASE_DELAY {
                    let _ = Self::auto_release_milestone(milestone_id);
                }
            }
        }

        T::DbWeight::get().reads_writes(10, 5)  // Benchmark this
    }
}
```

**Alternative** : Off-chain worker with on-chain callback (more gas-efficient)

---

## Related Specifications

- **DAOMembership-specification.md** : Rank ≥ 3 verification for jury selection (Manager, Partner only)
- **ServiceMarketplace-specification.md** : Mission lifecycle integration (client/consultant verification)
- **DAOTreasury-specification.md** : Spending limits patterns (escrow release similar to proposal execution)

---

**Version** : 1.0.0
**Date** : 2026-02-10
