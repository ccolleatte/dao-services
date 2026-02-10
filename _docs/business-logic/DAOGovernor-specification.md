# DAOGovernor - Business Logic Specification

**Version** : 1.0.0
**Date** : 2026-02-10
**Source** : DAOGovernor.sol (395 lines)

---

## Purpose

Système de gouvernance OpenGov-inspired avec tracks spécialisées (Technical/Treasury/Membership), intégration DAOMembership pour vote weights triangulaires, et quorums adaptatifs par track.

---

## Track System

### Track Types

| Track | Purpose | Decision Scope |
|-------|---------|----------------|
| **Technical** | Architecture, tech stack, security fixes | Technical decisions requiring deep expertise |
| **Treasury** | Budget allocation, spending, revenue distribution | Financial decisions affecting DAO funds |
| **Membership** | Promotions, demotions, rank durations, suspensions | HR-like decisions about member status |

### Track Configurations

**Technical Track** :
- `minRank` : 2 (Senior+ required to propose)
- `votingDelay` : 2 days (172,800 blocks @ 1s)
- `votingPeriod` : 7 days (604,800 blocks)
- `quorumPercent` : 66% (supermajority required)
- **Rationale** : High technical bar to propose, supermajority for safety-critical changes

**Treasury Track** :
- `minRank` : 1 (Consultant+ can propose spending)
- `votingDelay` : 1 day (86,400 blocks)
- `votingPeriod` : 14 days (1,209,600 blocks)
- `quorumPercent` : 51% (simple majority)
- **Rationale** : Lower barrier for financial proposals, longer voting period for careful review

**Membership Track** :
- `minRank` : 3 (Manager+ required for HR decisions)
- `votingDelay` : 1 day (86,400 blocks)
- `votingPeriod` : 7 days (604,800 blocks)
- `quorumPercent` : 75% (high consensus for people decisions)
- **Rationale** : High rank requirement + high quorum for sensitive HR changes

---

## Proposal Lifecycle

### States

```
[Draft] --propose()--> [Pending] --votingDelay()--> [Active] --votingPeriod()--> [Succeeded/Defeated]
                                                         |
                                                         +--cancel()--> [Canceled]
                                                         |
                                        [Succeeded] --queue()--> [Queued] --execute()--> [Executed]
```

### Proposal Data Model

| Attribute | Type | Constraints | Description |
|-----------|------|-------------|-------------|
| `proposalId` | uint256 | Unique | Keccak256 hash of proposal details |
| `track` | Track enum | Technical \| Treasury \| Membership | Track assignment determines config |
| `proposer` | Address | Must be member | Account that created proposal |
| `targets` | Address[] | ≥1 | Contract addresses to call |
| `values` | uint256[] | Same length as targets | ETH amounts to send |
| `calldatas` | bytes[] | Same length as targets | Function call data |
| `description` | String | Not empty | Proposal rationale |
| `voteStart` | uint256 | Future block | Block when voting starts |
| `voteEnd` | uint256 | After voteStart | Block when voting ends |
| `forVotes` | uint256 | ≥0 | Total vote weight "For" |
| `againstVotes` | uint256 | ≥0 | Total vote weight "Against" |
| `abstainVotes` | uint256 | ≥0 | Total vote weight "Abstain" |

---

## Core Operations

### 1. Propose with Track

**Preconditions** :
- Caller is active member (DAOMembership)
- Caller rank ≥ track.minRank
- targets.length = values.length = calldatas.length
- targets.length ≥ 1 (at least one action)
- description not empty

**Effects** :
- Create proposal with unique ID (hash of encoded params)
- Store track assignment
- Set proposer = msg.sender
- Calculate voteStart = block.number + votingDelay
- Calculate voteEnd = voteStart + votingPeriod
- Emit ProposalCreated event

**Post-conditions** :
- Proposal exists with status Pending
- Voting starts after votingDelay blocks
- Only members with rank ≥ minRank at snapshot block can vote

**Example** :
```solidity
// Technical proposal: Upgrade smart contract
proposeWithTrack(
    targets: [0xContractAddress],
    values: [0],
    calldatas: [upgradeCalldata],
    description: "Upgrade to v2.0 with security fixes",
    track: Track.Technical
)
```

---

### 2. Cast Vote

**Preconditions** :
- Caller is active member
- Proposal in Active state (voteStart ≤ block.number < voteEnd)
- Caller has not voted yet
- Caller rank ≥ track.minRank (eligible to vote on this track)

**Effects** :
- Calculate vote weight using DAOMembership.calculateVoteWeight(voter, track.minRank)
- Add vote weight to appropriate counter (forVotes, againstVotes, or abstainVotes)
- Mark voter as having voted (prevent double voting)
- Emit VoteCast event

**Post-conditions** :
- Vote recorded with triangular weight
- Voter cannot vote again on this proposal
- Total vote weights updated

**Vote Support Types** :
- `0` : Against
- `1` : For
- `2` : Abstain

---

### 3. Queue Proposal

**Preconditions** :
- Proposal in Succeeded state
- Quorum reached: forVotes ≥ quorum(proposalId)
- Majority achieved: forVotes > againstVotes

**Effects** :
- Queue operations in TimelockController
- Set queuedAt = block.timestamp
- Emit ProposalQueued event

**Post-conditions** :
- Proposal status = Queued
- Execution possible after timelock delay (default 2 days)

---

### 4. Execute Proposal

**Preconditions** :
- Proposal in Queued state
- Timelock delay elapsed (queuedAt + 2 days ≤ block.timestamp)

**Effects** :
- Execute all operations via TimelockController
- For each (target, value, calldata):
  - Call target.call{value: value}(calldata)
  - Revert entire transaction if any call fails (atomic execution)
- Set executedAt = block.timestamp
- Emit ProposalExecuted event

**Post-conditions** :
- Proposal status = Executed
- All on-chain state changes applied atomically

---

### 5. Cancel Proposal

**Preconditions** :
- Caller has GUARDIAN_ROLE or is proposer
- Proposal not yet executed

**Effects** :
- Set proposal status to Canceled
- Emit ProposalCanceled event

**Post-conditions** :
- Proposal cannot be voted on, queued, or executed

---

## Quorum Calculation

### Adaptive Quorum Formula

**Formula** :
```
quorum(proposalId) = eligibleVoterWeight × track.quorumPercent / 100

where:
  eligibleVoterWeight = membership.calculateTotalVoteWeight(track.minRank)
```

**Rationale** : Quorum adapts to number of eligible voters (members with rank ≥ minRank), not total membership. Ensures proposals require meaningful participation from qualified voters.

**Example** :

**Scenario** : Technical Track proposal (minRank = 2, quorumPercent = 66%)
- Member A (rank 1, weight 1) : NOT eligible (rank < 2)
- Member B (rank 2, weight 3) : ELIGIBLE
- Member C (rank 3, weight 6) : ELIGIBLE
- Member D (rank 4, weight 10) : ELIGIBLE

**Calculation** :
```
eligibleVoterWeight = 3 + 6 + 10 = 19
quorum = 19 × 66 / 100 = 12.54 ≈ 13 (rounded up)

Required for success:
- forVotes ≥ 13 (quorum reached)
- forVotes > againstVotes (majority achieved)
```

---

## Vote Weight Integration

### Snapshot Mechanism

**Problem** : Vote weight changes during voting period could manipulate results

**Solution** : Snapshot vote weights at proposal creation block

**Implementation** :
- When proposal created → store `voteStart` block
- When member votes → calculate weight using **historical state** at voteStart block
- If using checkpoints: `membership.getPastVotes(voter, voteStart)`
- If no checkpoints: use current weight (simplified, noted as limitation)

**Note** : Current Solidity implementation uses current weights (not historical snapshots). For Substrate, use `frame_support::traits::VoteTally` or equivalent with pallet-membership checkpoints.

---

## Access Control

### Roles Required

| Operation | Role Required | Additional Constraints |
|-----------|--------------|------------------------|
| `proposeWithTrack` | None (member check only) | Rank ≥ track.minRank |
| `castVote` | None (member check only) | Rank ≥ track.minRank, proposal Active |
| `queue` | PUBLIC | Proposal succeeded, quorum reached |
| `execute` | PUBLIC | Timelock delay elapsed |
| `cancel` | GUARDIAN_ROLE OR proposer | Proposal not executed |
| `setTrackConfig` | DEFAULT_ADMIN_ROLE | Admin only |

---

## Integration Requirements

### DAOMembership Integration

**Required Functions** :
- `isMember(address)` : Verify member status
- `calculateVoteWeight(address, uint8 minRank)` : Get triangular vote weight for eligible voter
- `calculateTotalVoteWeight(uint8 minRank)` : Calculate quorum denominator
- `members(address)` : Access member struct (rank, active status)

**Interface** :
```solidity
interface IDAOMembership {
    function isMember(address _account) external view returns (bool);

    function calculateVoteWeight(address _member, uint8 _minRank)
        external view returns (uint256 weight);

    function calculateTotalVoteWeight(uint8 _minRank)
        external view returns (uint256 totalWeight);

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

### TimelockController Integration

**Purpose** : 2-day delay between proposal approval and execution (safety buffer for community review)

**Workflow** :
1. Proposal succeeds → `queue()` schedules operations in Timelock
2. Wait 2 days (configurable)
3. Anyone can call `execute()` to trigger operations

**Note** : OpenZeppelin TimelockController standard used, no custom logic required

---

## Security Considerations

### Emergency Pause

**Requirement** : MUST implement pause mechanism for proposal creation and voting

**Triggers** :
- Smart contract vulnerability discovered
- Governance attack in progress
- Treasury funds at risk

**Effects** :
- Block `proposeWithTrack()` and `castVote()` when paused
- Allow `cancel()` and `execute()` (already queued proposals can proceed)

---

### Double Voting Prevention

**Attack Vector** : Member votes multiple times on same proposal

**Mitigation** :
- Track votes in `mapping(uint256 proposalId => mapping(address voter => bool hasVoted))`
- Require `hasVoted[proposalId][msg.sender] == false` before voting
- Set `hasVoted[proposalId][msg.sender] = true` after vote recorded

---

### Quorum Manipulation

**Attack Vector** : Demote members during voting to reduce eligibleVoterWeight and lower quorum threshold

**Mitigation** :
- Snapshot eligibleVoterWeight at proposal creation (voteStart block)
- Do NOT recalculate quorum dynamically during voting period
- Use historical state for vote weights (if checkpoints available)

---

### Front-Running Mitigation

**Attack Vector** : Proposer front-runs vote execution to cancel proposal

**Mitigation** :
- Only GUARDIAN_ROLE or proposer can cancel
- Execution is PUBLIC (anyone can execute after timelock)
- Timelock delay (2 days) prevents immediate cancellation after queueing

---

## Constants

| Constant | Value | Description |
|----------|-------|-------------|
| `VOTING_DELAY_TECHNICAL` | 172,800 blocks (~2 days) | Delay before Technical voting starts |
| `VOTING_DELAY_TREASURY` | 86,400 blocks (~1 day) | Delay before Treasury voting starts |
| `VOTING_DELAY_MEMBERSHIP` | 86,400 blocks (~1 day) | Delay before Membership voting starts |
| `VOTING_PERIOD_TECHNICAL` | 604,800 blocks (~7 days) | Technical voting duration |
| `VOTING_PERIOD_TREASURY` | 1,209,600 blocks (~14 days) | Treasury voting duration |
| `VOTING_PERIOD_MEMBERSHIP` | 604,800 blocks (~7 days) | Membership voting duration |
| `QUORUM_TECHNICAL` | 66% | Technical track quorum threshold |
| `QUORUM_TREASURY` | 51% | Treasury track quorum threshold |
| `QUORUM_MEMBERSHIP` | 75% | Membership track quorum threshold |
| `TIMELOCK_DELAY` | 172,800 seconds (~2 days) | Delay between queue and execute |

---

## Migration Notes (Substrate)

### Pallet Mapping

Ce contrat sera migré en **combinant** :
1. **pallet-collective** (réutilisé) : Vote counting, proposal lifecycle
2. **pallet-democracy** (réutilisé) : Referendum mechanics, voting periods
3. **custom pallet-dao-governor** : Track-specific logic, adaptive quorum, DAOMembership integration

**Rationale** : Reuse battle-tested governance pallets, extend with track system and triangular vote weights

### Track Configuration Storage

**Bounded Types** :
```rust
#[derive(Encode, Decode, Clone, PartialEq, Eq, RuntimeDebug, TypeInfo)]
pub struct TrackConfig {
    pub min_rank: u8,
    pub voting_delay: BlockNumberFor<T>,
    pub voting_period: BlockNumberFor<T>,
    pub quorum_percent: u8,
}

#[pallet::storage]
pub type TrackConfigs<T: Config> = StorageMap<_, Blake2_128Concat, Track, TrackConfig>;
```

### Weight Benchmarking

**Extrinsics requiring benchmarking** :
- `propose_with_track()` : Weight depends on number of operations (targets.len())
- `cast_vote()` : Weight includes DAOMembership vote weight calculation
- `queue()` : Weight depends on timelock scheduling
- `execute()` : Weight depends on number of operations to execute

**Formula** :
```rust
weight = base_weight
    + T::DbWeight::get().reads(3)  // proposal, track config, membership
    + T::DbWeight::get().writes(2)  // vote record, vote totals
    + membership::calculateVoteWeight::weight()
```

---

## Related Specifications

- **DAOMembership-specification.md** : Vote weight calculation (triangular formula), member rank verification
- **DAOTreasury-specification.md** : Treasury track proposals target treasury spending operations
- **MissionEscrow-specification.md** : Technical track may include dispute resolution parameter changes

---

**Version** : 1.0.0
**Date** : 2026-02-10
