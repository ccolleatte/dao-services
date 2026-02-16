# Phase 3.1 : ServiceMarketplace Implementation Plan

**Version** : 1.0.0
**Date** : 2026-02-16
**Effort Estimé** : 14h (10h dev + 4h tests)
**Milestone** : M1.1 - Transparent Matching On-Chain

---

## Objectif

Implémenter le contrat **ServiceMarketplace.sol** pour valider l'UVP #1 : **Matching transparent on-chain avec scoring algorithmique public**.

**Deliverables** :
- ✅ Mission lifecycle management (Draft → Active → OnHold → Completed/Cancelled)
- ✅ Application system (consultants apply, match score calculated on-chain)
- ✅ **Match score algorithm** (5 critères transparents, total 100 points)
- ✅ Consultant selection (client choose, budget locked)
- ✅ Budget locking mechanism (escrow-ready)
- ✅ 25 unit tests + 3 integration tests (100% passing)
- ✅ Coverage ≥80% lines, ≥70% branches

---

## 1. Spécifications Techniques

### 1.1 Data Models

#### Mission Struct

```solidity
struct Mission {
    uint256 id;                      // Unique mission identifier (auto-increment)
    address client;                  // Mission creator (active DAO member)
    string title;                    // Mission title (max 200 chars)
    string description;              // Detailed description (max 2000 chars)
    uint256 budget;                  // Total budget in DAOS tokens (wei)
    uint8 minRank;                   // Minimum consultant rank required (0-4)
    string[] requiredSkills;         // Required skills (max 10, each max 50 chars)
    MissionStatus status;            // Current lifecycle status
    address selectedConsultant;      // Selected consultant address (nullable)
    uint256 createdAt;               // Creation timestamp
    uint256 updatedAt;               // Last update timestamp
}

enum MissionStatus {
    Draft,      // Created but not posted (budget not locked)
    Active,     // Posted, accepting applications (budget locked)
    OnHold,     // Consultant selected, awaiting escrow creation
    Disputed,   // Active dispute in escrow system
    Completed,  // All milestones completed
    Cancelled   // Cancelled by client or system
}
```

**Storage** :
```solidity
mapping(uint256 => Mission) public missions;
uint256 public nextMissionId;
```

**Constraints** :
- `title` : Not empty, max 200 chars
- `description` : Not empty, max 2000 chars
- `budget` : > 0
- `minRank` : 0-4 (valid rank)
- `requiredSkills` : ≤10 skills, each ≤50 chars
- `client` : Active DAO member (verified via DAOMembership)

---

#### Application Struct

```solidity
struct Application {
    uint256 missionId;               // Parent mission reference
    address consultant;              // Applicant address
    string proposal;                 // IPFS hash (46 chars) - detailed proposal
    uint256 proposedBudget;          // Consultant's proposed budget (≤ mission.budget)
    uint256 submittedAt;             // Application timestamp
    uint256 matchScore;              // Calculated match score (0-100)
}
```

**Storage** :
```solidity
// Composite key: keccak256(abi.encodePacked(missionId, consultant))
mapping(bytes32 => Application) public applications;

// Index for querying applications by mission
mapping(uint256 => address[]) public missionApplicants;
```

**Constraints** :
- One application per consultant per mission (prevent duplicates)
- `proposal` : IPFS hash (46 chars)
- `proposedBudget` : > 0 AND ≤ mission.budget
- `consultant` : Active member with rank ≥ mission.minRank

---

### 1.2 Core Functions

#### 1.2.1 Create Mission (Draft)

```solidity
function createMission(
    string memory title,
    string memory description,
    uint256 budget,
    uint8 minRank,
    string[] memory requiredSkills
) external returns (uint256 missionId)
```

**Preconditions** :
- Caller is active DAO member
- Budget > 0
- MinRank 0-4
- RequiredSkills ≤10, each ≤50 chars
- Title not empty, ≤200 chars
- Description not empty, ≤2000 chars

**Effects** :
- Increment `nextMissionId`
- Create mission with status `Draft`
- Set `client = msg.sender`
- Set `createdAt = block.timestamp`
- Emit `MissionCreated` event

**Post-conditions** :
- Mission exists with unique ID
- Status = Draft (budget NOT locked yet)
- Client can edit or delete

**Gas Estimate** : ~150k gas (storage writes + array copy)

---

#### 1.2.2 Post Mission (Activate)

```solidity
function postMission(uint256 missionId)
    external
    nonReentrant
```

**Preconditions** :
- Caller is mission client
- Mission status = Draft
- Client has approved ERC20 token spending (≥ budget amount)
- Client has sufficient DAOS token balance

**Effects** :
- Transfer budget from client to marketplace contract (ERC20 `transferFrom`)
- Update status to `Active`
- Set `updatedAt = block.timestamp`
- Emit `MissionPosted` event

**Post-conditions** :
- Mission status = Active
- Budget locked in marketplace contract
- Accepting consultant applications
- Cannot be deleted (only cancelled with refund)

**Gas Estimate** : ~80k gas (ERC20 transfer + storage write)

---

#### 1.2.3 Apply to Mission

```solidity
function applyToMission(
    uint256 missionId,
    string memory proposalIPFS,
    uint256 proposedBudget
) external nonReentrant returns (uint256 matchScore)
```

**Preconditions** :
- Caller is active member
- Caller rank ≥ mission.minRank
- Mission status = Active
- No existing application from caller for this mission
- Proposed budget > 0 AND ≤ mission.budget
- Proposal IPFS hash valid (46 chars)

**Effects** :
- Calculate match score on-chain (see algorithm below)
- Create application record
- Add consultant to `missionApplicants[missionId]`
- Set `submittedAt = block.timestamp`
- Emit `ApplicationSubmitted` event

**Post-conditions** :
- Application exists with unique (missionId, consultant) key
- Match score calculated and stored
- Consultant can update proposal before selection

**Gas Estimate** : ~180k gas (match score computation + storage writes)

---

#### 1.2.4 Calculate Match Score (On-Chain)

```solidity
function calculateMatchScore(
    uint256 missionId,
    address consultant,
    uint256 proposedBudget,
    uint8 consultantRank
) public view returns (uint256 score)
```

**Algorithm Transparent (5 Critères)** :

| Critère | Weight | Max Points | Formula |
|---------|--------|------------|---------|
| **1. Rank Match** | 25% | 25 | `(consultantRank × 25) / 4` |
| **2. Skills Overlap** | 25% | 25 | `(matchingSkills × 25) / requiredSkills.length` |
| **3. Budget Competitiveness** | 20% | 20 | `20 - ((proposedBudget × 20) / mission.budget)` |
| **4. Track Record** | 15% | 15 | `min(completedMissions, 10) + (averageRating × 5) / 100` |
| **5. Responsiveness** | 15% | 15 | `15 - ((elapsed × 15) / 7 days)` (linear decay) |

**Implementation** :
```solidity
function calculateMatchScore(
    uint256 missionId,
    address consultant,
    uint256 proposedBudget,
    uint8 consultantRank
) public view returns (uint256) {
    Mission storage mission = missions[missionId];

    // 1. Rank match (25 points max)
    uint256 rankScore = (uint256(consultantRank) * 25) / 4;

    // 2. Skills overlap (25 points max)
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

    // 3. Budget competitiveness (20 points max)
    uint256 budgetRatio = (proposedBudget * 100) / mission.budget;
    uint256 budgetScore = budgetRatio <= 100
        ? 20 - ((budgetRatio * 20) / 100)
        : 0;

    // 4. Track record (15 points max)
    (uint256 completedMissions, uint256 averageRating) = membership.getTrackRecord(consultant);
    uint256 missionsScore = completedMissions > 10 ? 10 : completedMissions;
    uint256 ratingScore = (averageRating * 5) / 100;
    uint256 trackRecordScore = missionsScore + ratingScore;

    // 5. Responsiveness (15 points max)
    uint256 timeElapsed = block.timestamp - mission.createdAt;
    uint256 responsivenessScore;

    if (timeElapsed < 7 days) {
        responsivenessScore = 15 - ((timeElapsed * 15) / 7 days);
    } else {
        responsivenessScore = 0;
    }

    // Total score (capped at 100)
    uint256 totalScore = rankScore + skillsScore + budgetScore + trackRecordScore + responsivenessScore;
    return totalScore > 100 ? 100 : totalScore;
}
```

**Gas Estimate** : ~50k gas (read-only, view function)

---

#### 1.2.5 Select Consultant

```solidity
function selectConsultant(uint256 missionId, address consultant)
    external
    nonReentrant
```

**Preconditions** :
- Caller is mission client
- Mission status = Active
- Application exists for selected consultant
- Selected consultant application has proposedBudget > 0

**Effects** :
- Set `mission.selectedConsultant = consultant`
- Update status to `OnHold`
- Set `updatedAt = block.timestamp`
- Emit `ConsultantSelected` event

**Post-conditions** :
- Mission status = OnHold
- No longer accepting new applications
- Budget locked in marketplace, prepared for escrow transfer
- Awaiting escrow contract creation (next step in full workflow)

**Gas Estimate** : ~60k gas (storage writes)

---

#### 1.2.6 Cancel Mission

```solidity
function cancelMission(uint256 missionId)
    external
    nonReentrant
```

**Preconditions** :
- Caller is mission client
- Mission status = Active OR OnHold (before escrow creation)
- If status = OnHold → escrow contract NOT yet created

**Effects** :
- Refund locked budget to client (ERC20 transfer)
- Update status to `Cancelled`
- Set `updatedAt = block.timestamp`
- Emit `MissionCancelled` event

**Post-conditions** :
- Mission status = Cancelled (immutable)
- Budget refunded to client
- No longer accepting applications
- Cannot be reactivated

**Gas Estimate** : ~70k gas (ERC20 transfer + storage write)

---

### 1.3 Events

```solidity
event MissionCreated(
    uint256 indexed missionId,
    address indexed client,
    uint256 budget,
    uint8 minRank
);

event MissionPosted(
    uint256 indexed missionId,
    uint256 budgetLocked
);

event ApplicationSubmitted(
    uint256 indexed missionId,
    address indexed consultant,
    uint256 matchScore
);

event ConsultantSelected(
    uint256 indexed missionId,
    address indexed consultant,
    uint256 matchScore
);

event MissionCancelled(
    uint256 indexed missionId,
    address indexed client
);

event BudgetTransferredToEscrow(
    uint256 indexed missionId,
    address indexed escrowContract,
    uint256 amount
);
```

---

### 1.4 Access Control & Security

#### ReentrancyGuard

**Protected Functions** :
- `postMission()` : ERC20 transferFrom (client → marketplace)
- `applyToMission()` : State changes before external calls
- `selectConsultant()` : No transfer but state changes
- `cancelMission()` : ERC20 transfer (marketplace → client)

**Pattern** : Checks-Effects-Interactions + OpenZeppelin `ReentrancyGuard`

---

#### Budget Locking Mechanism

**Principle** : Budget locked at posting, released only on:
1. Consultant selection → Transfer to escrow contract
2. Mission cancellation → Refund to client

**Security Benefits** :
- Client cannot withdraw budget while mission active (prevents rug pull)
- Atomic transfer to escrow = no race condition
- Double spending prevented (status transitions enforce single release)

---

#### Match Score Gaming Prevention

| Attack Vector | Mitigation |
|---------------|------------|
| **Sybil attack** (multiple accounts) | Active member requirement + rank threshold |
| **Skill spam** (list all skills) | Max 10 skills per consultant (DAOMembership) |
| **Early application farming** | Acceptable behavior (rewards responsiveness) |

**Transparency** :
- All scores calculated on-chain = verifiable by all parties
- Deterministic algorithm = no hidden manipulation
- Client retains final selection authority = can override score

---

## 2. Architecture Integration

### 2.1 Dependencies

#### DAOMembership Interface

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
- `createMission()` : Verify caller is active member
- `applyToMission()` : Verify consultant rank ≥ minRank AND active
- `calculateMatchScore()` : Fetch skills + track record

**Status** : ✅ DAOMembership.sol already deployed (Phase 3 - 70%)

**Action Required** :
- ⚠️ Add `getSkills()` function to DAOMembership.sol (not implemented yet)
- ⚠️ Add `getTrackRecord()` function to DAOMembership.sol (not implemented yet)

**Effort** : 2h (add functions + tests)

---

#### DAOS Token (ERC20)

```solidity
interface IERC20 {
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function transfer(address to, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
}
```

**Usage** :
- `postMission()` : `transferFrom(client, marketplace, budget)`
- `cancelMission()` : `transfer(client, budget)`
- Future `transferBudgetToEscrow()` : `transfer(escrowContract, budget)`

**Status** : ⚠️ Mock ERC20 token pour tests (use OpenZeppelin ERC20Mock)

**Action Required** :
- Deploy mock DAOS token on Paseo testnet
- Add to deployment script

**Effort** : 1h

---

#### MissionEscrow Interface (Future)

```solidity
interface IMissionEscrow {
    function createEscrow(
        uint256 missionId,
        address consultant,
        Milestone[] memory milestones
    ) external returns (uint256 escrowId);
}
```

**Usage** :
- After consultant selection → External system calls `createEscrow()`
- Escrow contract calls `marketplace.transferBudgetToEscrow(missionId)`

**Status** : 🔜 Not implemented yet (Phase 3.4)

**Action Required** :
- Add `transferBudgetToEscrow()` function (placeholder for now)
- Interface for future integration

**Effort** : 1h (placeholder implementation)

---

### 2.2 Contract Architecture Diagram

```
┌─────────────────────────────────────────────────────┐
│                  DAO ECOSYSTEM                      │
│                                                     │
│  ┌──────────────┐      ┌──────────────────────┐   │
│  │ DAOMembership│◄─────┤ ServiceMarketplace   │   │
│  │              │      │                      │   │
│  │ - ranks      │      │ - missions           │   │
│  │ - skills     │      │ - applications       │   │
│  │ - track rec  │      │ - match scoring      │   │
│  └──────────────┘      └──────────┬───────────┘   │
│                                   │               │
│  ┌──────────────┐                 │               │
│  │  DAOS Token  │◄────────────────┘               │
│  │  (ERC20)     │                                 │
│  │              │                                 │
│  │ - transfers  │                                 │
│  └──────────────┘                                 │
│                                                     │
│  ┌──────────────────────────┐                     │
│  │  MissionEscrow (Future)  │                     │
│  │  - milestones            │                     │
│  │  - disputes              │                     │
│  └──────────────────────────┘                     │
└─────────────────────────────────────────────────────┘
```

---

### 2.3 Storage Layout Optimization

**Pattern** : Minimize storage slots (gas optimization)

```solidity
// Struct packing (256 bits = 1 slot)
struct Mission {
    uint256 id;              // Slot 0
    address client;          // Slot 1 (160 bits)
    uint8 minRank;           // Slot 1 (8 bits) - packed with client
    // ... remaining fields in separate slots
}
```

**Gas Savings** : ~20k gas per mission creation (vs non-packed)

---

## 3. Test Plan

### 3.1 Unit Tests (20 tests)

#### Mission Lifecycle Tests (8 tests)

```solidity
// test/ServiceMarketplace.t.sol

function testCreateMissionSuccess() public {
    // Given: Active member with budget
    // When: Create mission
    uint256 missionId = marketplace.createMission(
        "Strategy Consulting",
        "Help with growth strategy",
        10 ether,
        1,
        ["Strategy", "Growth"]
    );
    // Then: Mission created with status Draft
    assertEq(missionId, 0);
    assertEq(uint(missions[0].status), uint(MissionStatus.Draft));
}

function testCreateMissionRevertInactiveMember() public {
    // Given: Inactive member
    vm.prank(inactiveMember);
    // When: Create mission
    // Then: Revert with Unauthorized
    vm.expectRevert("Unauthorized");
    marketplace.createMission(...);
}

function testPostMissionSuccess() public {
    // Given: Mission created, client approved tokens
    token.approve(address(marketplace), 10 ether);
    // When: Post mission
    marketplace.postMission(missionId);
    // Then: Budget locked, status Active
    assertEq(token.balanceOf(address(marketplace)), 10 ether);
    assertEq(uint(missions[missionId].status), uint(MissionStatus.Active));
}

function testPostMissionRevertInsufficientBalance() public {
    // Given: Client balance < budget
    token.burn(client, token.balanceOf(client) - 5 ether);
    // When: Post mission
    // Then: Revert with ERC20 transfer failed
    vm.expectRevert("ERC20: insufficient balance");
    marketplace.postMission(missionId);
}

function testCancelMissionRefundsBudget() public {
    // Given: Mission posted (10 ether locked)
    marketplace.postMission(missionId);
    uint256 balanceBefore = token.balanceOf(client);
    // When: Cancel mission
    marketplace.cancelMission(missionId);
    // Then: Budget refunded, status Cancelled
    assertEq(token.balanceOf(client), balanceBefore + 10 ether);
    assertEq(uint(missions[missionId].status), uint(MissionStatus.Cancelled));
}

function testCancelMissionRevertNotClient() public {
    // Given: Mission posted
    marketplace.postMission(missionId);
    // When: Non-client cancels
    vm.prank(attacker);
    // Then: Revert with UnauthorizedClient
    vm.expectRevert("UnauthorizedClient");
    marketplace.cancelMission(missionId);
}

function testSelectConsultantSuccess() public {
    // Given: Mission active, consultant applied
    marketplace.postMission(missionId);
    vm.prank(consultant);
    marketplace.applyToMission(missionId, "QmIPFS...", 8 ether);
    // When: Select consultant
    marketplace.selectConsultant(missionId, consultant);
    // Then: Status OnHold, selectedConsultant set
    assertEq(uint(missions[missionId].status), uint(MissionStatus.OnHold));
    assertEq(missions[missionId].selectedConsultant, consultant);
}

function testSelectConsultantRevertNoApplication() public {
    // Given: Mission active, consultant NOT applied
    marketplace.postMission(missionId);
    // When: Select consultant
    // Then: Revert with ApplicationNotFound
    vm.expectRevert("ApplicationNotFound");
    marketplace.selectConsultant(missionId, consultant);
}
```

---

#### Application Tests (6 tests)

```solidity
function testApplyToMissionSuccess() public {
    // Given: Mission active, consultant rank ≥ minRank
    marketplace.postMission(missionId);
    vm.prank(consultant);
    // When: Apply to mission
    uint256 score = marketplace.applyToMission(missionId, "QmIPFS...", 8 ether);
    // Then: Application created, match score calculated
    assertGt(score, 0);
    assertLe(score, 100);
    Application memory app = marketplace.applications(
        keccak256(abi.encodePacked(missionId, consultant))
    );
    assertEq(app.consultant, consultant);
}

function testApplyRevertInsufficientRank() public {
    // Given: Mission minRank = 2, consultant rank = 1
    Mission memory mission = missions[missionId];
    mission.minRank = 2;
    vm.prank(consultantRank1);
    // When: Apply
    // Then: Revert with InsufficientRank
    vm.expectRevert("InsufficientRank");
    marketplace.applyToMission(missionId, "QmIPFS...", 8 ether);
}

function testApplyRevertDuplicateApplication() public {
    // Given: Consultant already applied
    marketplace.postMission(missionId);
    vm.prank(consultant);
    marketplace.applyToMission(missionId, "QmIPFS...", 8 ether);
    // When: Apply again
    // Then: Revert with DuplicateApplication
    vm.expectRevert("DuplicateApplication");
    marketplace.applyToMission(missionId, "QmIPFS...", 7 ether);
}

function testApplyRevertProposedBudgetExceedsMission() public {
    // Given: Mission budget = 10 ether
    marketplace.postMission(missionId);
    vm.prank(consultant);
    // When: Propose 12 ether
    // Then: Revert with InvalidProposedBudget
    vm.expectRevert("InvalidProposedBudget");
    marketplace.applyToMission(missionId, "QmIPFS...", 12 ether);
}

function testApplyRevertMissionNotActive() public {
    // Given: Mission status = Draft
    vm.prank(consultant);
    // When: Apply
    // Then: Revert with InvalidMissionStatus
    vm.expectRevert("InvalidMissionStatus");
    marketplace.applyToMission(missionId, "QmIPFS...", 8 ether);
}

function testApplyStoresCorrectMatchScore() public {
    // Given: Mission with specific requirements
    marketplace.postMission(missionId);
    vm.prank(consultant);
    // When: Apply
    uint256 score = marketplace.applyToMission(missionId, "QmIPFS...", 8 ether);
    // Then: Application stored with correct score
    Application memory app = marketplace.applications(
        keccak256(abi.encodePacked(missionId, consultant))
    );
    assertEq(app.matchScore, score);
}
```

---

#### Match Score Tests (6 tests)

```solidity
function testMatchScoreRankComponent() public {
    // Given: Consultant rank 2 (mid-level)
    // When: Calculate score
    uint256 score = marketplace.calculateMatchScore(missionId, consultant, 8 ether, 2);
    // Then: Rank component = (2 × 25) / 4 = 12.5 (12 in Solidity integer math)
    // Full score varies, but rank component verified
    assertGe(score, 12); // At least rank component present
}

function testMatchScoreSkillsOverlap() public {
    // Given: Mission requires ["Strategy", "Growth", "Marketing"]
    // Consultant has ["Strategy", "Growth", "Sales"] (2/3 overlap)
    // When: Calculate score
    uint256 score = marketplace.calculateMatchScore(missionId, consultant, 8 ether, 2);
    // Then: Skills component = (2 × 25) / 3 = 16.66 (16 in Solidity)
    // Verify skills contributed to score
    assertGe(score, 28); // Rank (12) + Skills (16) = 28 minimum
}

function testMatchScoreBudgetCompetitiveness() public {
    // Given: Mission budget 10 ether, consultant proposes 5 ether (50%)
    // When: Calculate score
    uint256 score = marketplace.calculateMatchScore(missionId, consultant, 5 ether, 2);
    // Then: Budget component = 20 - ((50 × 20) / 100) = 10
    // Lower proposed budget = higher score
    uint256 scoreHighBudget = marketplace.calculateMatchScore(missionId, consultant, 9 ether, 2);
    assertGt(score, scoreHighBudget); // 5 ether proposal scores higher than 9 ether
}

function testMatchScoreTrackRecord() public {
    // Given: Consultant with 5 completed missions, 80% rating
    // Mock membership.getTrackRecord() returns (5, 80)
    // When: Calculate score
    uint256 score = marketplace.calculateMatchScore(missionId, consultant, 8 ether, 2);
    // Then: Track record component = 5 + (80 × 5) / 100 = 5 + 4 = 9
    assertGe(score, 37); // Rank (12) + Skills (16) + Track (9) = 37 minimum
}

function testMatchScoreResponsiveness() public {
    // Given: Mission created 1 day ago
    vm.warp(block.timestamp + 1 days);
    // When: Calculate score
    uint256 score = marketplace.calculateMatchScore(missionId, consultant, 8 ether, 2);
    // Then: Responsiveness = 15 - ((1 day × 15) / 7 days) = 15 - 2.14 = 12.86 (~12)
    assertGe(score, 40); // Includes responsiveness component
}

function testMatchScoreCappedAt100() public {
    // Given: Perfect consultant (rank 4, all skills, low budget, high track record, instant apply)
    // When: Calculate score
    uint256 score = marketplace.calculateMatchScore(missionId, perfectConsultant, 1 ether, 4);
    // Then: Score capped at 100
    assertLe(score, 100);
}
```

---

### 3.2 Integration Tests (3 tests)

```solidity
// test/MarketplaceIntegration.t.sol

function testFullMissionWorkflow() public {
    // Given: Complete DAO setup (Membership, Token, Marketplace)

    // 1. Client creates mission
    vm.prank(client);
    uint256 missionId = marketplace.createMission(
        "Strategy Consulting",
        "Help with growth strategy",
        10 ether,
        1,
        ["Strategy", "Growth"]
    );

    // 2. Client posts mission (locks budget)
    vm.prank(client);
    token.approve(address(marketplace), 10 ether);
    marketplace.postMission(missionId);
    assertEq(token.balanceOf(address(marketplace)), 10 ether);

    // 3. Three consultants apply
    vm.prank(consultant1);
    uint256 score1 = marketplace.applyToMission(missionId, "QmIPFS1...", 9 ether);

    vm.prank(consultant2);
    uint256 score2 = marketplace.applyToMission(missionId, "QmIPFS2...", 8 ether);

    vm.prank(consultant3);
    uint256 score3 = marketplace.applyToMission(missionId, "QmIPFS3...", 7 ether);

    // Verify scores calculated
    assertGt(score1, 0);
    assertGt(score2, 0);
    assertGt(score3, 0);

    // 4. Client selects best match
    vm.prank(client);
    marketplace.selectConsultant(missionId, consultant2);

    // Verify selection
    assertEq(missions[missionId].selectedConsultant, consultant2);
    assertEq(uint(missions[missionId].status), uint(MissionStatus.OnHold));

    // Budget still locked in marketplace (awaiting escrow)
    assertEq(token.balanceOf(address(marketplace)), 10 ether);
}

function testMultipleMissionsParallel() public {
    // Given: 3 clients, 3 missions
    vm.prank(client1);
    uint256 mission1 = marketplace.createMission("Mission 1", "...", 10 ether, 1, []);

    vm.prank(client2);
    uint256 mission2 = marketplace.createMission("Mission 2", "...", 15 ether, 2, []);

    vm.prank(client3);
    uint256 mission3 = marketplace.createMission("Mission 3", "...", 8 ether, 0, []);

    // When: Post all missions
    vm.prank(client1);
    token.approve(address(marketplace), 10 ether);
    marketplace.postMission(mission1);

    vm.prank(client2);
    token.approve(address(marketplace), 15 ether);
    marketplace.postMission(mission2);

    vm.prank(client3);
    token.approve(address(marketplace), 8 ether);
    marketplace.postMission(mission3);

    // Then: All budgets locked correctly
    assertEq(token.balanceOf(address(marketplace)), 33 ether);

    // Consultant applies to multiple missions
    vm.prank(consultant);
    marketplace.applyToMission(mission1, "QmIPFS1...", 9 ether);
    marketplace.applyToMission(mission2, "QmIPFS2...", 14 ether);
    marketplace.applyToMission(mission3, "QmIPFS3...", 7 ether);

    // Verify 3 applications created
    assertEq(marketplace.missionApplicants(mission1).length, 1);
    assertEq(marketplace.missionApplicants(mission2).length, 1);
    assertEq(marketplace.missionApplicants(mission3).length, 1);
}

function testMissionCancellationRefundsCorrectly() public {
    // Given: 2 missions posted, budgets locked
    vm.prank(client1);
    token.approve(address(marketplace), 10 ether);
    marketplace.postMission(mission1);

    vm.prank(client2);
    token.approve(address(marketplace), 15 ether);
    marketplace.postMission(mission2);

    uint256 balance1Before = token.balanceOf(client1);
    uint256 balance2Before = token.balanceOf(client2);

    // When: Client 1 cancels mission
    vm.prank(client1);
    marketplace.cancelMission(mission1);

    // Then: Only client 1 refunded, client 2 budget still locked
    assertEq(token.balanceOf(client1), balance1Before + 10 ether);
    assertEq(token.balanceOf(client2), balance2Before); // Unchanged
    assertEq(token.balanceOf(address(marketplace)), 15 ether); // Only mission2 locked
}
```

---

### 3.3 Edge Cases & Security Tests (5 tests)

```solidity
function testReentrancyAttackOnPostMission() public {
    // Given: Malicious ERC20 token with reentrant callback
    MaliciousToken maliciousToken = new MaliciousToken();

    // When: Post mission with malicious token
    // Then: Revert with ReentrancyGuard
    vm.expectRevert("ReentrancyGuard: reentrant call");
    marketplace.postMission(missionId);
}

function testReentrancyAttackOnCancelMission() public {
    // Given: Malicious client contract
    MaliciousClient attacker = new MaliciousClient(marketplace);

    // When: Cancel mission with reentrant callback
    // Then: Revert with ReentrancyGuard
    vm.expectRevert("ReentrancyGuard: reentrant call");
    attacker.attackCancelMission(missionId);
}

function testOverflowBudgetCalculation() public {
    // Given: Extremely large budget (near uint256 max)
    uint256 hugeBudget = type(uint256).max;

    // When: Create mission
    // Then: Should handle without overflow
    // (Solidity 0.8.x has built-in overflow checks)
    vm.expectRevert(); // Arithmetic overflow
    marketplace.createMission("Huge", "...", hugeBudget, 1, []);
}

function testGasLimitMatchScoreComputation() public {
    // Given: Mission with 10 required skills, consultant with 20 skills
    string[] memory requiredSkills = new string[](10);
    for (uint i = 0; i < 10; i++) {
        requiredSkills[i] = string(abi.encodePacked("Skill", i));
    }

    marketplace.createMission("Complex", "...", 10 ether, 1, requiredSkills);

    // When: Calculate match score (worst case: 10 × 20 = 200 comparisons)
    uint256 gasBefore = gasleft();
    marketplace.calculateMatchScore(missionId, consultant, 8 ether, 2);
    uint256 gasUsed = gasBefore - gasleft();

    // Then: Gas used < 100k (acceptable for on-chain computation)
    assertLt(gasUsed, 100_000);
}

function testUnicodeHandlingInStrings() public {
    // Given: Mission with Unicode characters (émoji, accents)
    string memory title = "Stratégie Consulting 🚀";
    string memory description = "Développement croissance européenne";

    // When: Create mission
    uint256 missionId = marketplace.createMission(
        title,
        description,
        10 ether,
        1,
        ["Stratégie", "Développement"]
    );

    // Then: Mission created correctly (UTF-8 stored on-chain)
    assertEq(missions[missionId].title, title);
}
```

---

### 3.4 Coverage Targets

**Minimum Thresholds** :
- ✅ **80% line coverage** (acceptable for production)
- ✅ **70% branch coverage** (all critical paths tested)
- ✅ **100% function coverage** (all public functions tested)

**Coverage Report Command** :
```bash
forge coverage --report summary
forge coverage --report lcov
```

**CI Integration** :
```yaml
# .github/workflows/test.yml
- name: Run coverage
  run: forge coverage --report summary

- name: Check coverage thresholds
  run: |
    forge coverage --report summary | grep "Total" | awk '{
      if ($2 < 80) exit 1;  # Line coverage
      if ($4 < 70) exit 1;  # Branch coverage
    }'
```

---

## 4. Timeline & Effort Breakdown

### Phase 3.1.1 : Core Contract (6h)

**Day 1-2** :
- [ ] Implement data models (Mission, Application structs)
- [ ] Implement mission lifecycle functions (create, post, cancel)
- [ ] Implement application system (apply, select)
- [ ] **Match score algorithm** (5 criteria on-chain)
- [ ] Events emission

**Checkpoint** : Contract compiles without errors

---

### Phase 3.1.2 : DAOMembership Integration (2h)

**Day 2** :
- [ ] Add `getSkills()` to DAOMembership.sol
- [ ] Add `getTrackRecord()` to DAOMembership.sol
- [ ] Update DAOMembership tests (2 new functions)
- [ ] Deploy updated DAOMembership

**Checkpoint** : Integration functions working

---

### Phase 3.1.3 : Unit Tests (4h)

**Day 3** :
- [ ] Mission lifecycle tests (8 tests)
- [ ] Application tests (6 tests)
- [ ] Match score tests (6 tests)

**Checkpoint** : 20 unit tests passing

---

### Phase 3.1.4 : Integration Tests (2h)

**Day 4** :
- [ ] Full workflow test
- [ ] Multiple missions parallel test
- [ ] Cancellation refunds test
- [ ] Edge cases + security tests (5 tests)

**Checkpoint** : 25 tests passing (20 unit + 5 integration)

---

### Phase 3.1.5 : Coverage & Documentation (2h)

**Day 4** :
- [ ] Generate coverage report
- [ ] Fix uncovered branches (target ≥70%)
- [ ] Update contract documentation (NatSpec comments)
- [ ] Gas optimization (if >200k gas per operation)

**Checkpoint** : Coverage ≥80% lines, ≥70% branches

---

**Total Effort** : 14h

**Milestone Complete** : ServiceMarketplace.sol ready for Paseo deployment

---

## 5. Success Criteria

### Phase 3.1 Complete When :

- ✅ ServiceMarketplace.sol implemented (356 lines)
- ✅ DAOMembership integration functions added (getSkills, getTrackRecord)
- ✅ 25 tests passing (20 unit + 5 integration)
- ✅ Coverage ≥80% lines, ≥70% branches
- ✅ Match score algorithm transparent on-chain (5 criteria public)
- ✅ Budget locking mechanism secure (ReentrancyGuard)
- ✅ Gas usage <200k per operation
- ✅ Contract compiles without warnings
- ✅ Documentation complete (NatSpec + README)

---

## 6. Next Steps (After Phase 3.1)

### Phase 3.2 : Deploy Paseo Testnet (2h)

**Actions** :
- Deploy ServiceMarketplace to Paseo
- Deploy mock DAOS token
- Verify contracts on Paseo explorer
- Test transactions on-chain

**Deliverable** : ServiceMarketplace live on Paseo

---

### Phase 3.3 : Pilot Mission #1 (5h)

**Actions** :
- Recruit 1 test client + 3 test consultants
- Execute real mission workflow (create → apply → select)
- Collect feedback (match score clarity, UX friction)

**Metrics** :
- Match score comprehensible ? (target 90% understand)
- Frais 5% acceptable ? (vs 20% Malt)
- Trust blockchain ? (comfortable payer on-chain)

**Go/No-Go** : If satisfaction <80% → Iterate before Phase 3.4

---

### Phase 3.4 : MissionEscrow Implementation (6h)

**Dependencies** :
- ServiceMarketplace deployed + validated (pilot successful)
- Feedback integrated

**Deliverable** : Milestone-based escrow + dispute resolution

---

### Phase 3.5 : HybridPaymentSplitter (4h)

**Dependencies** :
- ServiceMarketplace + MissionEscrow deployed

**Deliverable** : IA/Humain/Compute revenue split

---

## 7. Risk Mitigation

| Risk | Impact | Probability | Mitigation |
|------|--------|-------------|------------|
| **DAOMembership functions missing** | HIGH | HIGH | Add getSkills() + getTrackRecord() first (2h) |
| **Gas too high (>200k)** | MEDIUM | MEDIUM | Optimize match score loops, cap skills at 10 |
| **Coverage <80%** | MEDIUM | LOW | Write edge case tests early |
| **Pilot feedback negative** | HIGH | MEDIUM | Iterate on UX before MissionEscrow |
| **Revert bugs in production** | HIGH | LOW | Thorough testing + Foundry fuzzing |

---

## 8. Appendix : Contract Skeleton

```solidity
// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/IDAOMembership.sol";

contract ServiceMarketplace is ReentrancyGuard {
    // State variables
    IDAOMembership public membership;
    IERC20 public daosToken;

    uint256 public nextMissionId;
    mapping(uint256 => Mission) public missions;
    mapping(bytes32 => Application) public applications;
    mapping(uint256 => address[]) public missionApplicants;

    // Data structures
    enum MissionStatus { Draft, Active, OnHold, Disputed, Completed, Cancelled }

    struct Mission {
        uint256 id;
        address client;
        string title;
        string description;
        uint256 budget;
        uint8 minRank;
        string[] requiredSkills;
        MissionStatus status;
        address selectedConsultant;
        uint256 createdAt;
        uint256 updatedAt;
    }

    struct Application {
        uint256 missionId;
        address consultant;
        string proposal;
        uint256 proposedBudget;
        uint256 submittedAt;
        uint256 matchScore;
    }

    // Events
    event MissionCreated(uint256 indexed missionId, address indexed client, uint256 budget, uint8 minRank);
    event MissionPosted(uint256 indexed missionId, uint256 budgetLocked);
    event ApplicationSubmitted(uint256 indexed missionId, address indexed consultant, uint256 matchScore);
    event ConsultantSelected(uint256 indexed missionId, address indexed consultant, uint256 matchScore);
    event MissionCancelled(uint256 indexed missionId, address indexed client);

    // Constructor
    constructor(address _membership, address _daosToken) {
        membership = IDAOMembership(_membership);
        daosToken = IERC20(_daosToken);
    }

    // Core functions
    function createMission(...) external returns (uint256) { ... }
    function postMission(uint256 missionId) external nonReentrant { ... }
    function applyToMission(...) external nonReentrant returns (uint256) { ... }
    function calculateMatchScore(...) public view returns (uint256) { ... }
    function selectConsultant(...) external nonReentrant { ... }
    function cancelMission(uint256 missionId) external nonReentrant { ... }
}
```

---

**Version** : 1.0.0
**Date** : 2026-02-16
**Status** : READY FOR IMPLEMENTATION
**Author** : Claude Code (Lean Swarm v3.2)
