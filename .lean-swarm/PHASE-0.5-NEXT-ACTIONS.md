# Phase 0.5 - Next Actions

**Date** : 2026-02-10
**Status** : ⚠️ PARTIAL SUCCESS (5/8 criteria met)
**Decision** : Complete P0 fixes before Phase 1

---

## Phase 0.5 Results Summary

| Critère | Target | Résultat | Status |
|---------|--------|----------|--------|
| Setup Time | <4h | 9.9s | ✅ |
| Validation Time | <3h/contract | 1h/contract | ✅ |
| Tests Passing | 100% | 100% (85/85) | ✅ |
| Coverage Lines | ≥80% | 66.67% | ❌ |
| Coverage Branches | ≥70% | 41.71% | ❌ |
| Gas Regressions | 0 | 0 | ✅ |
| HIGH Violations | 0 | 3 | ❌ |
| ROI | >0 | 2550-3150% | ✅ |

**ROI** : **2550-3150%** (53-65h saved vs 2h setup)
**Time Savings** : **75-87%** per contract (4-8h → 1h)

---

## P0 : CRITICAL Actions (Block Phase 1)

### 1. Improve Test Coverage (8-12h)

**Target** : Lines 66.67% → 80%, Branches 41.71% → 70%

**Missing Tests Identified** :

**DAOMembership.sol** :
```solidity
// Edge cases
test_RemoveMember_AtIndexZero() // Array pop logic edge case
test_CalculateTotalVoteWeight_AllInactive() // All members inactive edge case
test_GetActiveMembersByRank_EmptyResult() // No members of rank X

// Attack vectors
test_GetActiveMembersByRank_GasDoS() // >1000 members iteration
test_AddMember_DuplicateGithubHandle() // Duplicate handle validation
```

**DAOGovernor.sol** :
```solidity
// Edge cases
test_ProposeWithTrack_EmptyTargets() // 0 targets/values/calldatas
test_QuorumCalculation_ZeroEligibleVoters() // No voters eligible for track
test_CastVote_AfterVotingPeriodEnds() // Boundary condition

// Attack vectors
test_ProposeWithTrack_RankCheckBypass() // Attempt bypass rank requirement
test_CastVote_DoubleVoting() // Vote twice on same proposal
```

**DAOTreasury.sol** :
```solidity
// Edge cases
test_ExecuteProposal_DailyLimitResetMidnight() // Boundary condition (midnight)
test_CreateProposal_BudgetExhaustion() // Multiple concurrent proposals exhaust budget
test_ReceiveETH_ReentrancyProtection() // Validate nonReentrant modifier

// Attack vectors
test_ExecuteProposal_ReentrancyAttack() // Attempt reentrancy on executeProposal()
test_ApproveProposal_FrontRunning() // Front-run approval with higher gas
```

**MissionEscrow.sol** (HIGH priority - 31.67% branches) :
```solidity
// Missing branches coverage
test_SubmitMilestone_InvalidStatus() // Boundary conditions
test_VoteOnDispute_QuorumBoundaries() // Edge cases for quorum calculation
test_AutoReleaseMilestone_TimeBoundaries() // Exactly at release time
```

**Commands** :
```bash
# Run tests with coverage
forge coverage --report summary

# Check specific contract coverage
forge coverage --report lcov && lcov --list coverage/lcov.info | grep "DAOGovernor.sol"

# Run specific test file
forge test --match-path contracts/test/DAOMembership.t.sol -vv
```

---

### 2. Implement Pausable Mechanism (4-6h)

**Rationale** : Emergency pause for critical operations (HIGH security violation)

**Contracts Affected** :
- DAOMembership.sol
- DAOGovernor.sol
- DAOTreasury.sol

**Implementation Pattern** :

```solidity
import "@openzeppelin/contracts/security/Pausable.sol";

contract DAOMembership is AccessControl, Pausable {
    bytes32 public constant EMERGENCY_ROLE = keccak256("EMERGENCY_ROLE");

    function addMember(...) external whenNotPaused onlyRole(MEMBER_MANAGER_ROLE) {
        // Existing logic
    }

    function emergencyPause() external onlyRole(EMERGENCY_ROLE) {
        _pause();
    }

    function emergencyUnpause() external onlyRole(EMERGENCY_ROLE) {
        _unpause();
    }
}
```

**Tests Required** :
```solidity
test_EmergencyPause_BlocksAddMember()
test_EmergencyUnpause_RestoresAddMember()
test_EmergencyPause_OnlyEmergencyRole()
```

**Commands** :
```bash
# Install OpenZeppelin Pausable (already in project)
forge install OpenZeppelin/openzeppelin-contracts

# Run tests after implementation
forge test --match-test "test_Emergency" -vv
```

---

### 3. Fix Unbounded Arrays (2-4h)

**Rationale** : DoS risk with >1000 members (MEDIUM security violation)

**DAOMembership.sol** :

**Option A : Pagination** (Recommended)
```solidity
function getActiveMembersByRank(uint8 _rank, uint256 _offset, uint256 _limit)
    external
    view
    returns (address[] memory, uint256 total)
{
    // Count total first
    uint256 total = 0;
    for (uint256 i = 0; i < memberAddresses.length; i++) {
        if (members[memberAddresses[i]].active && members[memberAddresses[i]].rank == _rank) {
            total++;
        }
    }

    // Apply pagination
    uint256 resultSize = _limit;
    if (_offset + _limit > total) {
        resultSize = total - _offset;
    }

    address[] memory result = new address[](resultSize);
    uint256 index = 0;
    uint256 count = 0;

    for (uint256 i = 0; i < memberAddresses.length && index < resultSize; i++) {
        address memberAddr = memberAddresses[i];
        Member memory member = members[memberAddr];

        if (member.active && member.rank == _rank) {
            if (count >= _offset) {
                result[index] = memberAddr;
                index++;
            }
            count++;
        }
    }

    return (result, total);
}
```

**Option B : BoundedVec (Substrate-style, not available in Solidity)**
Not applicable - use pagination instead.

**Tests Required** :
```solidity
test_GetActiveMembersByRank_Pagination()
test_GetActiveMembersByRank_OffsetBeyondTotal()
test_GetActiveMembersByRank_GasDoS1000Members()
```

---

## P1 : HIGH Actions (Phase 1 Scope)

### 4. Extract DRY Violations (1-2h)

**DAOMembership.sol** : Triangular number formula duplicated

```solidity
// Extract helper function
function _computeTriangularNumber(uint8 rank) internal pure returns (uint256) {
    return uint256(rank) * (uint256(rank) + 1) / 2;
}

// Update calculateVoteWeight()
function calculateVoteWeight(address _member, uint8 _minRank)
    public
    view
    returns (uint256 weight)
{
    require(isMember(_member), "Not a member");
    Member memory member = members[_member];
    require(member.active, "Member inactive");
    require(member.rank >= _minRank, "Rank too low for this proposal");

    return _computeTriangularNumber(member.rank);
}

// Update calculateTotalVoteWeight()
function calculateTotalVoteWeight(uint8 _minRank)
    public
    view
    returns (uint256 totalWeight)
{
    for (uint256 i = 0; i < memberAddresses.length; i++) {
        address memberAddr = memberAddresses[i];
        Member memory member = members[memberAddr];

        if (member.active && member.rank >= _minRank) {
            totalWeight += _computeTriangularNumber(member.rank);
        }
    }
}
```

---

### 5. Remove console.log from Production (30 min)

**DAOGovernor.sol** : Lines 261-265, 299-305

```solidity
// BEFORE (Lines 261-265)
function proposalQuorum(uint256 proposalId) public view returns (uint256) {
    Track track = proposalTrack[proposalId];
    TrackConfig memory config = trackConfigs[track];
    uint256 eligibleVoterWeight = membership.calculateTotalVoteWeight(config.minRank);
    console.log("proposalQuorum - proposalId:", proposalId); // ❌ REMOVE
    console.log("  track:", uint(track)); // ❌ REMOVE
    // ...
}

// AFTER
function proposalQuorum(uint256 proposalId) public view returns (uint256) {
    Track track = proposalTrack[proposalId];
    TrackConfig memory config = trackConfigs[track];
    uint256 eligibleVoterWeight = membership.calculateTotalVoteWeight(config.minRank);
    // console.log removed for production
    // ...
}
```

**Same for** : `_quorumReached()` lines 299-305

**Test** :
```bash
# Verify no console.log in production contracts
grep -r "console.log" contracts/src/

# Should return 0 matches
```

---

### 6. Standardize Test Naming (1h)

**Convention** : `test_Function_Scenario_Result`

**Examples** :

**BEFORE (camelCase)** :
```solidity
testAddMember() // ❌
testPromoteMemberRevertsIfMaxRank() // ❌
testGetActiveMembersByRank() // ❌
```

**AFTER (snake_case with underscores)** :
```solidity
test_AddMember_Success() // ✅
test_PromoteMember_RevertsIfMaxRank() // ✅
test_GetActiveMembersByRank_ReturnsCorrectList() // ✅
```

**Script** : Create `_scripts/standardize-test-names.ps1`
```powershell
# Rename tests in all .t.sol files
Get-ChildItem -Path "contracts/test" -Filter "*.t.sol" -Recurse | ForEach-Object {
    $content = Get-Content $_.FullName -Raw
    # Convert testFunctionName() to test_FunctionName()
    $content = $content -replace 'function (test)([A-Z][a-z]+)', 'function $1_$2'
    Set-Content $_.FullName -Value $content
}
```

---

## P2 : MEDIUM Actions (Phase 2 Optimization)

### 7. Optimize Gas (Cache calculateTotalVoteWeight) (2-3h)

**Problem** : `calculateTotalVoteWeight()` iterates all members (O(n) gas cost)

**Solution** : Cache result, recalculate only on state changes

```solidity
// Add cached storage
mapping(uint8 => uint256) private _cachedTotalVoteWeight;
bool private _cacheValid = false;

function calculateTotalVoteWeight(uint8 _minRank)
    public
    view
    returns (uint256 totalWeight)
{
    if (_cacheValid) {
        return _cachedTotalVoteWeight[_minRank];
    }

    // Fallback to iteration (cache invalidated)
    for (uint256 i = 0; i < memberAddresses.length; i++) {
        // ... existing logic
    }
}

// Invalidate cache on state changes
function addMember(...) external {
    // ... existing logic
    _cacheValid = false;
}

function promoteMember(...) external {
    // ... existing logic
    _cacheValid = false;
}
```

---

### 8. Split Contract Responsibilities (4-6h)

**DAOMembership** : Extract IVotes interface to separate contract

**Problem** : 3 responsibilities (membership + voting + IVotes interface) = borderline complexity

**Solution** :
```solidity
// NEW FILE: contracts/src/DAOMembershipVotes.sol
contract DAOMembershipVotes {
    DAOMembership public immutable membership;

    constructor(DAOMembership _membership) {
        membership = _membership;
    }

    function clock() public view returns (uint48) {
        return uint48(block.number);
    }

    function CLOCK_MODE() public pure returns (string memory) {
        return "mode=blocknumber&from=default";
    }

    function getPastTotalSupply(uint256 timepoint) public view returns (uint256) {
        return membership.calculateTotalVoteWeight(0);
    }

    function getPastVotes(address account, uint256 timepoint) public view returns (uint256) {
        return membership.calculateVoteWeight(account, 0);
    }
}
```

**Update DAOGovernor constructor** :
```solidity
constructor(
    DAOMembership _membership,
    TimelockController _timelock
)
    Governor("DAO Governor")
    GovernorVotes(IVotes(address(new DAOMembershipVotes(_membership))))
    // ...
```

---

## Commands Cheat Sheet

### Run Tests
```bash
# All tests
forge test -vv

# Specific test file
forge test --match-path contracts/test/DAOMembership.t.sol -vv

# Specific test function
forge test --match-test "test_AddMember" -vv

# With coverage
forge coverage --report summary

# Gas report
forge test --gas-report
```

### Coverage Analysis
```bash
# Generate coverage report
forge coverage --report summary

# Generate lcov report (detailed)
forge coverage --report lcov

# View specific contract coverage
forge coverage --report lcov && lcov --list coverage/lcov.info | grep "DAOMembership.sol"
```

### Gas Profiling
```bash
# Generate gas snapshot
forge snapshot

# Compare gas with previous snapshot
forge snapshot --diff .gas-snapshot

# Gas report per function
forge test --gas-report
```

### Code Quality
```bash
# Check for console.log
grep -r "console.log" contracts/src/

# Check test naming convention
grep -r "function test[A-Z]" contracts/test/

# Check contract size
forge build --sizes
```

---

## Timeline Estimates

### P0 : CRITICAL (14-22h total)

| Task | Estimated Time | Status |
|------|---------------|--------|
| Improve Test Coverage | 8-12h | ⏸️ TODO |
| Implement Pausable | 4-6h | ⏸️ TODO |
| Fix Unbounded Arrays | 2-4h | ⏸️ TODO |

**Target Completion** : 2-3 days (assuming full-time work)

### P1 : HIGH (2.5-3.5h total)

| Task | Estimated Time | Status |
|------|---------------|--------|
| Extract DRY Violations | 1-2h | ⏸️ TODO |
| Remove console.log | 30 min | ⏸️ TODO |
| Standardize Test Naming | 1h | ⏸️ TODO |

**Target Completion** : 0.5-1 day

### P2 : MEDIUM (6-9h total)

| Task | Estimated Time | Status |
|------|---------------|--------|
| Optimize Gas (Cache) | 2-3h | ⏸️ TODO |
| Split Contract Responsibilities | 4-6h | ⏸️ TODO |

**Target Completion** : 1-1.5 days

---

## Success Criteria (After P0 Complete)

| Critère | Target | Current | After P0 |
|---------|--------|---------|----------|
| Coverage Lines | ≥80% | 66.67% | ✅ 80%+ |
| Coverage Branches | ≥70% | 41.71% | ✅ 70%+ |
| HIGH Violations | 0 | 3 | ✅ 0 |
| Tests Passing | 100% | 100% | ✅ 100% |
| Gas Regressions | 0 | 0 | ✅ 0 |

**Phase 1 Ready** : ✅ After P0 completion (14-22h)

---

## Decision Matrix

| Option | Effort | Outcome | Risk | Recommendation |
|--------|--------|---------|------|----------------|
| **A : Complete P0 Fixes** | 14-22h | 8/8 criteria met | LOW | ✅ RECOMMENDED |
| **B : Proceed Phase 1 (Partial)** | 0h | 5/8 criteria met | MEDIUM | ⚠️ RISKY |
| **C : Adjust Thresholds** | 1h | 8/8 criteria met (compromised) | HIGH | ❌ NOT RECOMMENDED |

**Recommendation** : **Option A (Complete P0 Fixes)**

**Rationale** :
- Even with 22h fixes, ROI = (53-65h - 2h - 22h) / 24h = **1.2-1.7× positive ROI**
- Ensures production-ready security (Pausable, coverage)
- Avoids tech debt accumulation
- Phase 1 marketplace contracts build on solid foundation

---

**Next Step** : Execute P0 tasks (14-22h) → Re-run Lean Swarm validation → Proceed Phase 1

**Created** : 2026-02-10
**Last Updated** : 2026-02-10
