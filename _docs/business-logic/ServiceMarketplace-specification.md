# ServiceMarketplace - Business Logic Specification

**Version** : 1.0.0
**Date** : 2026-02-10
**Source** : ServiceMarketplace.sol (356 lines)

---

## Purpose

Marketplace pour création missions DAO, application consultants, match scoring transparent on-chain, et sélection consultants par clients. Bridge entre clients (DAO members) et consultants qualifiés.

---

## Mission Data Model

### Mission Attributes

| Attribute | Type | Constraints | Description |
|-----------|------|-------------|-------------|
| `id` | uint256 | Unique, auto-increment | Mission identifier |
| `client` | Address | Non-null, valid address | Client who posted the mission |
| `title` | String | Not empty, max 200 chars | Mission title |
| `description` | String | Not empty, max 2000 chars | Detailed mission description |
| `budget` | uint256 | > 0 | Total budget in DAOS tokens (wei) |
| `minRank` | uint8 | 0-4 | Minimum consultant rank required |
| `requiredSkills` | String[] | Max 10 skills, each max 50 chars | Required skills (hashed for matching) |
| `status` | MissionStatus enum | Draft \| Active \| OnHold \| Disputed \| Completed \| Cancelled | Mission lifecycle state |
| `selectedConsultant` | Address | Nullable | Selected consultant address (null if not yet selected) |
| `createdAt` | Timestamp | Non-null | Block timestamp at creation |
| `updatedAt` | Timestamp | Non-null | Block timestamp at last update |

### MissionStatus Enum

```
Draft       → Mission created but not posted yet (budget not locked)
Active      → Mission posted, accepting applications (budget locked)
OnHold      → Consultant selected, awaiting escrow creation (budget prepared for transfer)
Disputed    → Active dispute in escrow system
Completed   → All milestones completed, payment released
Cancelled   → Mission cancelled by client or system
```

---

## Application Data Model

### Application Attributes

| Attribute | Type | Constraints | Description |
|-----------|------|-------------|-------------|
| `missionId` | uint256 | Non-null, exists in missions mapping | Parent mission reference |
| `consultant` | Address | Non-null, active member | Consultant applicant address |
| `proposal` | String | IPFS hash (46 chars) | IPFS hash of proposal document |
| `proposedBudget` | uint256 | > 0, ≤ mission.budget | Consultant's proposed budget |
| `submittedAt` | Timestamp | Non-null | Application submission timestamp |
| `matchScore` | uint256 | 0-100 | Calculated match score (on-chain) |

**Composite Key** : `(missionId, consultant)` - One application per consultant per mission

---

## Mission Lifecycle

### State Machine

```
[Draft] --postMission()--> [Active] --selectConsultant()--> [OnHold] --createEscrow()--> [Disputed/Completed]
                                |                                           |
                                +--cancelMission()--> [Cancelled]           +
```

**Valid Transitions** :
- Draft → Active : `postMission()` (locks budget)
- Active → OnHold : `selectConsultant()` (prepares budget transfer)
- Active → Cancelled : `cancelMission()` (refunds locked budget)
- OnHold → Disputed : Dispute raised in escrow system
- OnHold → Completed : All milestones completed
- OnHold → Cancelled : Client cancels before escrow creation

**Immutable States** : `Completed`, `Cancelled`

---

## Core Operations

### 1. Create Mission (Draft)

**Preconditions** :
- Caller is active member (DAOMembership)
- Budget > 0
- MinRank 0-4 (valid)
- RequiredSkills ≤ 10 skills, each ≤ 50 chars
- Title not empty, ≤ 200 chars
- Description not empty, ≤ 2000 chars

**Effects** :
- Increment mission counter (nextMissionId++)
- Create mission with status `Draft`
- Set client = msg.sender
- Set createdAt = block.timestamp
- Emit MissionCreated event

**Post-conditions** :
- Mission exists with unique ID
- Status = Draft (budget NOT locked yet)
- Can be edited or deleted by client

**Example** :
```solidity
function createMission(
    string memory title,
    string memory description,
    uint256 budget,
    uint8 minRank,
    string[] memory requiredSkills
) external returns (uint256)
{
    // Verify caller is active member
    (uint8 rank,,,, bool active) = membership.members(msg.sender);
    if (!active) revert Unauthorized();

    // Validate inputs
    if (budget == 0) revert InvalidBudget();
    if (minRank > 4) revert InvalidRank();
    if (requiredSkills.length > 10) revert TooManySkills();

    // Create mission
    uint256 missionId = nextMissionId++;
    missions[missionId] = Mission({
        id: missionId,
        client: msg.sender,
        title: title,
        description: description,
        budget: budget,
        minRank: minRank,
        requiredSkills: requiredSkills,
        status: MissionStatus.Draft,
        selectedConsultant: address(0),
        createdAt: block.timestamp,
        updatedAt: block.timestamp
    });

    emit MissionCreated(missionId, msg.sender, budget, minRank);
    return missionId;
}
```

---

### 2. Post Mission (Activate)

**Preconditions** :
- Caller is mission client
- Mission status = Draft
- Client has approved ERC20 token spending for marketplace contract (≥ budget amount)
- Client has sufficient DAOS token balance (≥ budget)

**Effects** :
- Transfer budget from client to marketplace contract (ERC20 transferFrom)
- Update status to `Active`
- Set updatedAt = block.timestamp
- Emit MissionPosted event

**Post-conditions** :
- Mission status = Active
- Budget locked in marketplace contract
- Accepting consultant applications
- Cannot be deleted (can only be cancelled with budget refund)

**Example** :
```solidity
function postMission(uint256 missionId)
    external nonReentrant
{
    Mission storage mission = missions[missionId];

    // Verify authorization
    if (msg.sender != mission.client) revert UnauthorizedClient();
    if (mission.status != MissionStatus.Draft) revert InvalidMissionStatus();

    // Lock budget in contract (client must have approved first)
    bool success = daosToken.transferFrom(msg.sender, address(this), mission.budget);
    require(success, "Budget transfer failed");

    // Activate mission
    mission.status = MissionStatus.Active;
    mission.updatedAt = block.timestamp;

    emit MissionPosted(missionId, mission.budget);
}
```

---

### 3. Apply to Mission

**Preconditions** :
- Caller is active member
- Caller rank ≥ mission.minRank
- Mission status = Active
- No existing application from caller for this mission (prevent duplicates)
- Proposed budget > 0 AND ≤ mission.budget
- Proposal IPFS hash valid (46 chars)

**Effects** :
- Calculate match score on-chain (5 weighted criteria)
- Create application record
- Set submittedAt = block.timestamp
- Emit ApplicationSubmitted event

**Post-conditions** :
- Application exists with unique (missionId, consultant) key
- Match score calculated and stored
- Consultant can update proposal before selection

**Example** :
```solidity
function applyToMission(
    uint256 missionId,
    string memory proposalIPFS,
    uint256 proposedBudget
) external nonReentrant returns (uint256 matchScore)
{
    Mission storage mission = missions[missionId];

    // Verify mission is active
    if (mission.status != MissionStatus.Active) revert InvalidMissionStatus();

    // Verify consultant is active member with sufficient rank
    (uint8 consultantRank,,,, bool active) = membership.members(msg.sender);
    if (!active) revert Unauthorized();
    if (consultantRank < mission.minRank) revert InsufficientRank();

    // Verify proposed budget
    if (proposedBudget == 0 || proposedBudget > mission.budget) {
        revert InvalidProposedBudget();
    }

    // Verify no duplicate application
    bytes32 applicationKey = keccak256(abi.encodePacked(missionId, msg.sender));
    if (applications[applicationKey].submittedAt != 0) revert DuplicateApplication();

    // Calculate match score on-chain
    matchScore = calculateMatchScore(missionId, msg.sender, proposedBudget, consultantRank);

    // Create application
    applications[applicationKey] = Application({
        missionId: missionId,
        consultant: msg.sender,
        proposal: proposalIPFS,
        proposedBudget: proposedBudget,
        submittedAt: block.timestamp,
        matchScore: matchScore
    });

    emit ApplicationSubmitted(missionId, msg.sender, matchScore);
    return matchScore;
}
```

---

### 4. Calculate Match Score (On-Chain)

**Principle** : Transparent, deterministic scoring algorithm with 5 weighted criteria totaling 100 points.

**Algorithm** :

```solidity
function calculateMatchScore(
    uint256 missionId,
    address consultant,
    uint256 proposedBudget,
    uint8 consultantRank
) public view returns (uint256)
{
    Mission storage mission = missions[missionId];

    // 1. Rank match (25 points max) - Linear scaling
    // Rank 0 = 0 points, Rank 4 = 25 points
    uint256 rankScore = (uint256(consultantRank) * 25) / 4;

    // 2. Skills overlap (25 points max)
    // Count matching skills via keccak256 comparison
    string[] memory consultantSkills = membership.getSkills(consultant);
    uint256 matchingSkills = 0;

    for (uint256 i = 0; i < mission.requiredSkills.length; i++) {
        bytes32 requiredHash = keccak256(bytes(mission.requiredSkills[i]));
        for (uint256 j = 0; j < consultantSkills.length; j++) {
            if (requiredHash == keccak256(bytes(consultantSkills[j]))) {
                matchingSkills++;
                break;
            }
        }
    }

    uint256 skillsScore = mission.requiredSkills.length > 0
        ? (matchingSkills * 25) / mission.requiredSkills.length
        : 0;

    // 3. Budget competitiveness (20 points max) - Inverse relationship
    // Lower proposed budget = higher score
    // proposedBudget ≤ mission.budget guaranteed by validation
    uint256 budgetRatio = (proposedBudget * 100) / mission.budget; // 0-100%
    uint256 budgetScore = budgetRatio <= 100
        ? 20 - ((budgetRatio * 20) / 100)
        : 0;

    // 4. Track record (15 points max)
    // Completed missions (max 10 points) + average rating (max 5 points)
    (uint256 completedMissions, uint256 averageRating) = membership.getTrackRecord(consultant);

    uint256 missionsScore = completedMissions > 10 ? 10 : completedMissions;
    uint256 ratingScore = (averageRating * 5) / 100; // averageRating 0-100

    uint256 trackRecordScore = missionsScore + ratingScore;

    // 5. Responsiveness (15 points max)
    // Early application bonus with 7-day linear decay
    uint256 timeElapsed = block.timestamp - mission.createdAt;
    uint256 responsivenessScore;

    if (timeElapsed < 7 days) {
        // Linear decay: 15 points at t=0, 0 points at t=7 days
        responsivenessScore = 15 - ((timeElapsed * 15) / 7 days);
    } else {
        responsivenessScore = 0;
    }

    // Total score (capped at 100)
    uint256 totalScore = rankScore + skillsScore + budgetScore + trackRecordScore + responsivenessScore;
    return totalScore > 100 ? 100 : totalScore;
}
```

**Scoring Matrix** :

| Criteria | Weight | Max Points | Calculation |
|----------|--------|------------|-------------|
| **Rank match** | 25% | 25 | Linear scaling: `(consultantRank × 25) / 4` |
| **Skills overlap** | 25% | 25 | `(matchingSkills × 25) / requiredSkills.length` |
| **Budget competitiveness** | 20% | 20 | Inverse: `20 - ((proposedBudget × 20) / mission.budget)` |
| **Track record** | 15% | 15 | Completed missions (max 10) + rating (max 5) |
| **Responsiveness** | 15% | 15 | Linear decay over 7 days: `15 - ((elapsed × 15) / 7 days)` |

**Benefits** :
- **Transparency** : All criteria on-chain, verifiable by all parties
- **Determinism** : Same inputs always produce same score
- **Fairness** : Multiple dimensions prevent gaming single metric
- **Client guidance** : High scores guide client selection decisions

---

### 5. Select Consultant

**Preconditions** :
- Caller is mission client
- Mission status = Active
- Application exists for selected consultant
- Selected consultant application has proposedBudget > 0

**Effects** :
- Set mission.selectedConsultant = consultant address
- Update status to `OnHold`
- Set updatedAt = block.timestamp
- Emit ConsultantSelected event

**Post-conditions** :
- Mission status = OnHold
- No longer accepting new applications
- Budget locked in marketplace, prepared for escrow transfer
- Awaiting escrow contract creation (next step: transfer to MissionEscrow)

**Example** :
```solidity
function selectConsultant(uint256 missionId, address consultant)
    external nonReentrant
{
    Mission storage mission = missions[missionId];

    // Verify authorization
    if (msg.sender != mission.client) revert UnauthorizedClient();
    if (mission.status != MissionStatus.Active) revert InvalidMissionStatus();

    // Verify application exists
    bytes32 applicationKey = keccak256(abi.encodePacked(missionId, consultant));
    Application storage application = applications[applicationKey];
    if (application.submittedAt == 0) revert ApplicationNotFound();

    // Update mission
    mission.selectedConsultant = consultant;
    mission.status = MissionStatus.OnHold;
    mission.updatedAt = block.timestamp;

    emit ConsultantSelected(missionId, consultant, application.matchScore);

    // NOTE: Budget transfer to escrow happens in separate transaction
    // Client or system must call createEscrow() with this mission
}
```

---

### 6. Cancel Mission

**Preconditions** :
- Caller is mission client
- Mission status = Active OR OnHold (before escrow creation)
- If status = OnHold → escrow contract NOT yet created

**Effects** :
- Refund locked budget to client (ERC20 transfer)
- Update status to `Cancelled`
- Set updatedAt = block.timestamp
- Emit MissionCancelled event

**Post-conditions** :
- Mission status = Cancelled (immutable)
- Budget refunded to client
- No longer accepting applications
- Cannot be reactivated

**Example** :
```solidity
function cancelMission(uint256 missionId)
    external nonReentrant
{
    Mission storage mission = missions[missionId];

    // Verify authorization
    if (msg.sender != mission.client) revert UnauthorizedClient();

    // Verify status allows cancellation
    if (mission.status != MissionStatus.Active && mission.status != MissionStatus.OnHold) {
        revert InvalidMissionStatus();
    }

    // If OnHold, verify escrow not yet created
    if (mission.status == MissionStatus.OnHold) {
        if (escrowCreated(missionId)) revert EscrowAlreadyCreated();
    }

    // Refund budget to client
    bool success = daosToken.transfer(mission.client, mission.budget);
    require(success, "Refund transfer failed");

    // Update mission
    mission.status = MissionStatus.Cancelled;
    mission.updatedAt = block.timestamp;

    emit MissionCancelled(missionId, mission.client);
}
```

---

## Query Operations

### Get Mission Details

**Input** : `missionId` (uint256)

**Output** : Mission struct (all fields)

---

### Get Application Details

**Input** : `missionId` (uint256), `consultant` (address)

**Output** : Application struct (all fields)

---

### Get Applications for Mission

**Input** : `missionId` (uint256)

**Output** : Array of Application structs, sorted by matchScore descending

**Note** : Pagination required for >100 applications to prevent DoS

---

### Get Missions by Status

**Input** : `status` (MissionStatus enum)

**Output** : Array of Mission structs matching status

**Note** : Pagination required, filter client-side if needed

---

## Integration Requirements

### DAOMembership Integration

**Required Functions** :
- `members(address)` : Access member struct (rank, active status)
- `getSkills(address)` : Get consultant skills array for matching
- `getTrackRecord(address)` : Get (completedMissions, averageRating) for match score

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

    function getSkills(address _consultant)
        external view returns (string[] memory skills);

    function getTrackRecord(address _consultant)
        external view returns (
            uint256 completedMissions,
            uint256 averageRating
        );
}
```

**Usage** :
- `applyToMission()` : Verify consultant rank ≥ minRank AND active = true
- `calculateMatchScore()` : Fetch skills for matching, track record for scoring

---

### MissionEscrow Integration

**Required Operations** :
- Budget transfer from marketplace to escrow after consultant selection
- Mission status sync (OnHold → Disputed/Completed)
- Milestone creation triggered by escrow contract initialization

**Workflow** :
1. Client posts mission → Budget locked in marketplace (status = Active)
2. Consultants apply → Match scores calculated on-chain
3. Client selects consultant → Status = OnHold, selectedConsultant set
4. **Escrow creation** (separate transaction):
   - Client or system calls `escrow.createEscrow(missionId, consultant, milestones[])`
   - Escrow contract calls `marketplace.transferBudgetToEscrow(missionId)`
   - Marketplace transfers locked budget to escrow contract
   - Mission status updated via callback or event monitoring
5. Milestones executed in escrow system
6. Mission status synced (Disputed/Completed)

**Interface** :
```solidity
interface IMissionEscrow {
    function createEscrow(
        uint256 missionId,
        address consultant,
        Milestone[] memory milestones
    ) external returns (uint256 escrowId);
}

// In ServiceMarketplace contract
function transferBudgetToEscrow(uint256 missionId, address escrowContract)
    external nonReentrant
{
    Mission storage mission = missions[missionId];

    // Verify authorization (only escrow factory contract)
    if (msg.sender != escrowFactory) revert Unauthorized();
    if (mission.status != MissionStatus.OnHold) revert InvalidMissionStatus();

    // Transfer budget to escrow
    bool success = daosToken.transfer(escrowContract, mission.budget);
    require(success, "Escrow transfer failed");

    emit BudgetTransferredToEscrow(missionId, escrowContract, mission.budget);
}
```

---

## Security Considerations

### Reentrancy Protection

**Requirement** : MUST use ReentrancyGuard on all external calls involving token transfers

**Operations protected** :
- `postMission()` : ERC20 transferFrom (client → marketplace)
- `selectConsultant()` : No transfer, but state changes before external calls
- `cancelMission()` : ERC20 transfer (marketplace → client)
- `transferBudgetToEscrow()` : ERC20 transfer (marketplace → escrow)

**Pattern** : Checks-Effects-Interactions + ReentrancyGuard

---

### Budget Locking Mechanism

**Principle** : Budget locked at mission posting, released only on consultant selection (escrow transfer) or cancellation (refund).

**Security Benefits** :
- Client cannot withdraw budget while mission active (prevents rug pull)
- Budget locked in contract = escrow mechanism guarantee
- Atomic transfer to escrow contract = no race condition

**Attack Prevention** :
- **Double spending** : Budget locked once, can only be released once (status = Cancelled OR transferred to escrow)
- **Front-running** : Consultant selection atomic operation, no external calls before state update

---

### Match Score Gaming Prevention

**Vulnerabilities** :
- **Sybil attack** : Consultant creates multiple accounts → Mitigated by active member requirement + rank threshold
- **Skill spam** : Consultant lists all possible skills → Mitigated by max 10 skills per consultant in DAOMembership
- **Early application farming** : Apply immediately to all missions → Acceptable, rewards responsiveness (intended behavior)

**On-Chain Transparency** :
- All scores calculated on-chain = verifiable by all parties
- Deterministic algorithm = no hidden manipulation
- Client retains final selection authority = override score if needed

---

### Access Control

**Operations by Role** :

| Operation | Role Required | Additional Constraints |
|-----------|--------------|------------------------|
| `createMission` | Active member | Budget > 0, valid inputs |
| `postMission` | Mission client | Status = Draft, ERC20 approval |
| `applyToMission` | Active member | Rank ≥ minRank, no duplicate |
| `selectConsultant` | Mission client | Status = Active, application exists |
| `cancelMission` | Mission client | Status = Active/OnHold (before escrow) |
| `transferBudgetToEscrow` | Escrow factory contract | Status = OnHold |

---

## Constants

| Constant | Default Value | Description |
|----------|---------------|-------------|
| `MAX_REQUIRED_SKILLS` | 10 | Maximum skills per mission |
| `MAX_SKILL_LENGTH` | 50 characters | Maximum length per skill string |
| `MAX_TITLE_LENGTH` | 200 characters | Maximum mission title length |
| `MAX_DESCRIPTION_LENGTH` | 2000 characters | Maximum mission description length |
| `IPFS_HASH_LENGTH` | 46 characters | Standard IPFS hash length |
| `RESPONSIVENESS_DECAY_PERIOD` | 7 days | Period for responsiveness score linear decay |

---

## Migration Notes (Substrate)

### Pallet Mapping

Ce contrat sera migré vers un **custom pallet `pallet-marketplace`** car :
- Match score algorithm unique (5 weighted criteria)
- Mission lifecycle specific to DAO workflow
- Integration tight avec pallet-dao-membership et pallet-mission-escrow
- Pas de pallet existant dans l'écosystème Polkadot

---

### Bounded Types

**Substrate Requirements** :
```rust
pub struct Mission<AccountId, Balance> {
    pub client: AccountId,
    pub title: BoundedVec<u8, ConstU32<200>>,
    pub description: BoundedVec<u8, ConstU32<2000>>,
    pub budget: Balance,
    pub min_rank: u8,
    pub required_skills: BoundedVec<BoundedVec<u8, ConstU32<50>>, ConstU32<10>>,
    pub status: MissionStatus,
    pub selected_consultant: Option<AccountId>,
    pub created_at: Moment,
    pub updated_at: Moment,
}

pub struct Application<AccountId, Balance> {
    pub mission_id: u64,
    pub consultant: AccountId,
    pub proposal: BoundedVec<u8, ConstU32<46>>, // IPFS hash
    pub proposed_budget: Balance,
    pub submitted_at: Moment,
    pub match_score: u8, // 0-100
}

#[derive(Encode, Decode, Clone, PartialEq, Eq, RuntimeDebug, TypeInfo)]
pub enum MissionStatus {
    Draft,
    Active,
    OnHold,
    Disputed,
    Completed,
    Cancelled,
}

// Storage maps
#[pallet::storage]
pub type Missions<T: Config> = StorageMap<
    _,
    Blake2_128Concat,
    u64,
    Mission<AccountIdOf<T>, BalanceOf<T>>
>;

#[pallet::storage]
pub type Applications<T: Config> = StorageDoubleMap<
    _,
    Blake2_128Concat,
    u64, // missionId
    Blake2_128Concat,
    AccountIdOf<T>, // consultant
    Application<AccountIdOf<T>, BalanceOf<T>>
>;
```

---

### Weight Benchmarking

**Extrinsics requiring benchmarking** :
- `create_mission()` : Weight depends on requiredSkills.len()
- `post_mission()` : Weight includes ERC20 transfer (pallet-assets call)
- `apply_to_mission()` : Weight depends on calculateMatchScore complexity (skills comparison loops)
- `select_consultant()` : Lightweight (storage writes only)
- `cancel_mission()` : Weight includes ERC20 transfer refund

**Formula** :
```rust
weight = base_weight
    + T::DbWeight::get().reads(4)  // mission, membership, skills, track record
    + T::DbWeight::get().writes(2)  // mission status, application
    + calculate_match_score_weight(required_skills.len(), consultant_skills.len())
    + pallet_assets::transfer_weight()
```

---

### Match Score Optimization

**Challenge** : On-chain calculation with nested loops (skills comparison)

**Optimization strategies** :
1. **Skills hashing** : Pre-compute keccak256 hashes of skills in pallet-dao-membership
2. **Bounded loops** : Max 10 required skills × max 20 consultant skills = max 200 comparisons
3. **Early termination** : Break inner loop on first skill match
4. **Weight benchmarking** : Measure worst-case (10 × 20 comparisons)

**Alternative** : Off-chain workers for match score calculation (submit result on-chain with proof)

---

## Related Specifications

- **DAOMembership-specification.md** : Rank verification, skills matching, track record retrieval
- **MissionEscrow-specification.md** : Budget transfer workflow, milestone management, mission status sync
- **DAOGovernor-specification.md** : Governance proposals may modify marketplace parameters (max skills, responsiveness decay period)
- **Polkadot pallet-assets** : ERC20-like token management for DAOS token transfers

---

**Version** : 1.0.0
**Date** : 2026-02-10
