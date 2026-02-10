# Lentille : Sandbox (TDD Strict + 0 Régressions - Blockchain)

**Purpose** : Garantir tests exhaustifs, TDD strict, et 0 régressions pour smart contracts sécurisés.

## Règles Absolues Blockchain

### 1. TDD Strict (RED-GREEN-REFACTOR)

**NE DOIT PAS** :
- ❌ Code sans tests (0 tolérance)
- ❌ Tests écrits APRÈS implémentation
- ❌ Tests "ça devrait marcher"
- ❌ Deploy sans tests 100% passing

**DOIT** :
- ✅ Tests AVANT ou EN MÊME TEMPS que code
- ✅ Red-Green-Refactor cycle strict
- ✅ Tests unitaires + integration
- ✅ Edge cases + attack vectors

**Workflow TDD Blockchain** :
```bash
# Step 1: RED - Write failing test
forge test -vv --match-test testCreateProposal

# Step 2: GREEN - Minimal implementation
# ... write code ...
forge test -vv --match-test testCreateProposal

# Step 3: REFACTOR - Optimize
# ... refactor ...
forge test -vv  # All tests must still pass
```

---

### 2. Coverage Thresholds (STRICTER)

**NE DOIT PAS** :
- ❌ Coverage <80% lines (vs 70% TypeScript)
- ❌ Coverage <70% branches (vs 60% TypeScript)
- ❌ Critical paths non testés
- ❌ Happy path uniquement

**DOIT** :
- ✅ Coverage ≥80% lines (target 90%)
- ✅ Coverage ≥70% branches (target 80%)
- ✅ Test tous les require/revert paths
- ✅ Test tous les modifiers
- ✅ Test tous les events

**Commandes Foundry** :
```bash
# Coverage report
forge coverage --report summary

# Detailed coverage per contract
forge coverage --report lcov

# Check coverage thresholds
forge coverage --check 80  # Fail if <80%
```

**Example Coverage Target** :
```solidity
// DAOMembership.sol Coverage Report
Lines: 285/310 (91.9%) ✓
Branches: 42/58 (72.4%) ✓
Functions: 14/15 (93.3%) ✓
```

---

### 3. Test Categories (MANDATORY)

**NE DOIT PAS** :
- ❌ Tests unitaires seuls
- ❌ Skip integration tests
- ❌ Skip edge cases tests
- ❌ Skip security tests

**DOIT** :
- ✅ Unit tests (53 minimum pour dao)
- ✅ Integration tests (6 minimum pour dao)
- ✅ Edge case tests (0 values, max values, boundaries)
- ✅ Attack vector tests (reentrancy, overflow, access control)

**Test Structure** :
```
test/
├── unit/
│   ├── DAOMembership.t.sol        # 18 tests unitaires
│   ├── DAOGovernor.t.sol          # 20 tests unitaires
│   └── DAOTreasury.t.sol          # 15 tests unitaires
├── integration/
│   ├── ProposalLifecycle.t.sol    # 3 tests E2E
│   ├── VotingWorkflow.t.sol       # 2 tests E2E
│   └── TreasuryWorkflow.t.sol     # 1 test E2E
└── security/
    ├── Reentrancy.t.sol           # Attack vectors
    ├── AccessControl.t.sol        # Permission tests
    └── Overflow.t.sol             # Edge cases
```

---

### 4. Test Naming Convention

**NE DOIT PAS** :
- ❌ Noms vagues (`test1`, `testFunction`)
- ❌ Manque de contexte
- ❌ Pas de distinction success/failure

**DOIT** :
- ✅ Format : `test_<FunctionName>_<Scenario>_<ExpectedResult>`
- ✅ Descriptif comportement attendu
- ✅ Distinction success/revert cases

**Examples** :
```solidity
// ❌ WRONG - Vague
function testProposal() public { }
function testVote() public { }

// ✅ CORRECT - Descriptive
function test_createProposal_withValidInputs_succeeds() public { }
function test_createProposal_withInsufficientRank_reverts() public { }
function test_vote_afterDeadline_reverts() public { }
function test_executeProposal_withQuorumMet_succeeds() public { }
function test_executeProposal_beforeTimelock_reverts() public { }
```

---

### 5. Edge Case Coverage (MANDATORY)

**NE DOIT PAS** :
- ❌ Test happy path uniquement
- ❌ Skip boundary values
- ❌ Skip 0/max values
- ❌ Skip empty arrays

**DOIT** :
- ✅ Test 0 values (address(0), amount=0, array.length=0)
- ✅ Test max values (uint256.max, array at limit)
- ✅ Test boundaries (rank 0-4, quorum threshold)
- ✅ Test overflow/underflow (Solidity 0.8+ reverts automatically)

**Example Edge Cases** :
```solidity
// Edge Case 1: Zero address
function test_addMember_withZeroAddress_reverts() public {
    vm.expectRevert("Invalid address");
    membership.addMember(address(0), "Member", 0);
}

// Edge Case 2: Empty array
function test_createProposal_withEmptyTargets_reverts() public {
    address[] memory targets = new address[](0);
    uint256[] memory values = new uint256[](0);
    bytes[] memory calldatas = new bytes[](0);

    vm.expectRevert("No targets");
    governor.createProposal("Test", targets, values, calldatas, ProposalType.Technical);
}

// Edge Case 3: Max value
function test_vote_withMaxVotingPower_succeeds() public {
    // Setup member with rank 4 (max voting power = 10)
    membership.addMember(alice, "Alice", 4);

    uint256 proposalId = _createProposal();

    vm.prank(alice);
    governor.vote(proposalId, VoteType.For);

    // Verify voting power correctly applied
    (uint256 forVotes,,) = governor.getVotes(proposalId);
    assertEq(forVotes, 10, "Max voting power applied");
}

// Edge Case 4: Boundary (rank transition)
function test_promoteToRank_fromRank3ToRank4_succeeds() public {
    membership.addMember(alice, "Alice", 3);

    membership.promoteToRank(alice, 4);

    uint256 rank = membership.getRank(alice);
    assertEq(rank, 4, "Promoted to max rank");

    uint256 votingPower = membership.getVotingPower(alice);
    assertEq(votingPower, 10, "Voting power updated");
}
```

---

### 6. Attack Vector Tests (SECURITY CRITICAL)

**NE DOIT PAS** :
- ❌ Skip reentrancy tests
- ❌ Skip access control tests
- ❌ Skip overflow tests (même si Solidity 0.8+)
- ❌ Skip front-running tests

**DOIT** :
- ✅ Test reentrancy attack vectors
- ✅ Test unauthorized access attempts
- ✅ Test integer edge cases
- ✅ Test tx.origin vs msg.sender
- ✅ Test delegate call vulnerabilities

**Example Security Tests** :
```solidity
// Security Test 1: Reentrancy (даже si ReentrancyGuard)
contract MaliciousContract {
    DAOTreasury public treasury;
    uint256 public attackCount;

    constructor(address _treasury) {
        treasury = DAOTreasury(_treasury);
    }

    function attack() external {
        treasury.withdrawFromTreasury(1 ether);
    }

    receive() external payable {
        if (attackCount < 2) {
            attackCount++;
            treasury.withdrawFromTreasury(1 ether);
        }
    }
}

function test_treasury_reentrancyAttack_blocked() public {
    MaliciousContract attacker = new MaliciousContract(address(treasury));

    vm.deal(address(treasury), 10 ether);
    vm.expectRevert("ReentrancyGuard: reentrant call");

    attacker.attack();
}

// Security Test 2: Unauthorized access
function test_executeProposal_byNonGovernor_reverts() public {
    uint256 proposalId = _createProposal();

    vm.prank(attacker); // Unauthorized user
    vm.expectRevert("AccessControl: unauthorized");

    governor.executeProposal(proposalId);
}

// Security Test 3: tx.origin attack
function test_vote_withtxOrigin_reverts() public {
    // Verify msg.sender is used, not tx.origin
    uint256 proposalId = _createProposal();

    vm.prank(alice);
    vm.expectRevert(); // Should revert if using tx.origin

    governor.vote(proposalId, VoteType.For);
}
```

---

### 7. Gas Profiling (MANDATORY)

**NE DOIT PAS** :
- ❌ Deploy sans gas snapshots
- ❌ Ignorer gas regressions
- ❌ Fonctions >1M gas
- ❌ Gas non optimisé

**DOIT** :
- ✅ Gas snapshots baseline (`forge snapshot`)
- ✅ Check gas regressions (`forge snapshot --check`)
- ✅ Gas report par fonction (`forge test --gas-report`)
- ✅ Target <500k gas per function

**Commandes Gas** :
```bash
# Generate gas snapshot baseline
forge snapshot

# Check for gas regressions
forge snapshot --check

# Gas report per function
forge test --gas-report

# Detailed gas report
forge test --gas-report --json > gas-report.json
```

**Example Gas Snapshot** :
```
DAOMembershipTest:testAddMember() (gas: 145234)
DAOGovernorTest:testCreateProposal() (gas: 387621)
DAOGovernorTest:testVote() (gas: 98432)
DAOTreasuryTest:testWithdraw() (gas: 234567)
```

**Gas Regression Detection** :
```bash
# Baseline established
forge snapshot

# After code changes
forge snapshot --check

# Output
❌ FAIL: testCreateProposal() gas increased from 387621 to 425000 (+37379 gas)
```

---

### 8. Integration Tests (E2E Workflows)

**NE DOIT PAS** :
- ❌ Unit tests uniquement
- ❌ Skip end-to-end workflows
- ❌ Mock tous les contracts
- ❌ Tests isolés sans interaction

**DOIT** :
- ✅ Test workflows complets (create → vote → execute)
- ✅ Test multi-contract interactions
- ✅ Test state transitions
- ✅ Test event emissions chained

**Example Integration Test** :
```solidity
// Integration Test: Complete Proposal Lifecycle
function test_integration_proposalLifecycle_completeWorkflow() public {
    // Setup: Add members with different ranks
    membership.addMember(alice, "Alice", 4); // Rank 4 (voting power 10)
    membership.addMember(bob, "Bob", 3);     // Rank 3 (voting power 6)
    membership.addMember(charlie, "Charlie", 2); // Rank 2 (voting power 3)

    // Step 1: Create proposal (Technical track, 66% quorum)
    address[] memory targets = new address[](1);
    targets[0] = address(membership);

    uint256[] memory values = new uint256[](1);
    values[0] = 0;

    bytes[] memory calldatas = new bytes[](1);
    calldatas[0] = abi.encodeWithSignature("promoteToRank(address,uint256)", charlie, 3);

    vm.prank(alice);
    uint256 proposalId = governor.createProposal(
        "Promote Charlie to Rank 3",
        targets,
        values,
        calldatas,
        ProposalType.Technical
    );

    // Step 2: Vote (Alice + Bob vote For = 10+6=16 votes)
    vm.prank(alice);
    governor.vote(proposalId, VoteType.For);

    vm.prank(bob);
    governor.vote(proposalId, VoteType.For);

    // Step 3: Fast-forward to voting period end
    vm.warp(block.timestamp + 7 days);

    // Step 4: Check quorum met (16 votes >= 66% of 19 total = 12.54)
    (uint256 forVotes,,) = governor.getVotes(proposalId);
    assertGe(forVotes, 12, "Quorum met");

    // Step 5: Execute proposal (after timelock)
    vm.warp(block.timestamp + 2 days); // Timelock delay
    governor.executeProposal(proposalId);

    // Step 6: Verify state change (Charlie promoted)
    uint256 charlieRank = membership.getRank(charlie);
    assertEq(charlieRank, 3, "Charlie promoted to Rank 3");

    // Step 7: Verify events emitted
    // (Events checked via vm.expectEmit in separate assertions)
}
```

---

### 9. Fuzz Testing (RECOMMENDED)

**NE DOIT PAS** :
- ❌ Manual edge case enumeration uniquement
- ❌ Skip property-based testing
- ❌ Assume inputs valides

**DOIT** :
- ✅ Fuzz test avec inputs aléatoires
- ✅ Invariant testing (properties qui doivent TOUJOURS hold)
- ✅ Bound fuzzed inputs pour pertinence

**Example Fuzz Test** :
```solidity
// Fuzz Test: Vote with random voting power
function testFuzz_vote_withRandomVotingPower(uint256 randomRank) public {
    // Bound randomRank to valid range [0, 4]
    randomRank = bound(randomRank, 0, 4);

    membership.addMember(alice, "Alice", randomRank);
    uint256 proposalId = _createProposal();

    vm.prank(alice);
    governor.vote(proposalId, VoteType.For);

    (uint256 forVotes,,) = governor.getVotes(proposalId);

    // Verify voting power matches rank (triangular formula)
    uint256 expectedPower = (randomRank * (randomRank + 1)) / 2;
    assertEq(forVotes, expectedPower, "Voting power matches rank");
}

// Invariant Test: Total voting power always consistent
function invariant_totalVotingPowerConsistent() public {
    uint256 calculatedTotal = 0;

    // Sum all members' voting power
    for (uint256 i = 0; i < membership.getMemberCount(); i++) {
        address member = membership.getMemberByIndex(i);
        calculatedTotal += membership.getVotingPower(member);
    }

    uint256 storedTotal = membership.getTotalVotingPower();

    assertEq(calculatedTotal, storedTotal, "Total voting power consistent");
}
```

---

### 10. 0 Régressions Policy (ABSOLUTE)

**NE DOIT PAS** :
- ❌ Tests qui passaient → échouent maintenant
- ❌ Gas qui augmente >10% sans justification
- ❌ Coverage qui baisse
- ❌ Fonctionnalités existantes cassées

**DOIT** :
- ✅ Tous tests existants passent TOUJOURS
- ✅ Gas regressions explicitement justifiées
- ✅ Coverage maintenue ou améliorée
- ✅ Baseline snapshots à jour

**Validation Checklist** :
```bash
# 1. Tests passing (baseline)
forge test -vv
# Output: 59/59 tests passed ✓

# 2. Coverage maintained
forge coverage --check 80
# Output: Coverage 81.2% ≥ 80% ✓

# 3. Gas regressions checked
forge snapshot --check
# Output: All gas snapshots within tolerance ✓

# 4. Build successful
forge build
# Output: Compiled 3 Solidity files successfully ✓
```

---

## Integration Lean Swarm Modes

### MODE ANALYTIQUE : Test Gap Analysis

**Question** : "Quels tests manquent ?"

**Checklist** :
- Coverage <80% → Identifier fonctions non testées
- Branches non testées → Identifier conditions manquées
- Edge cases manquants → Lister 0/max/boundary values
- Attack vectors non testés → STRIDE analysis

---

### MODE CONTEXTUEL : Existing Test Patterns

**Question** : "Ce pattern de test existe-t-il ?"

**Action** :
```bash
# Chercher patterns de tests similaires
grep -r "test.*Proposal.*reverts" test/

# Chercher mocks/fixtures réutilisables
grep -r "vm.prank\|vm.expectRevert" test/
```

---

### MODE GÉNÉRATIF : Generate Missing Tests

**Question** : "Générer tests manquants pour coverage 80%"

**Workflow** :
1. Run `forge coverage --report lcov`
2. Identifier lignes/branches non testées
3. Générer tests ciblés pour gaps
4. Vérifier coverage après

---

### MODE ÉVALUATIF : Test Quality Score

**Question** : "Qualité tests mesurable ?"

**Metrics** :
- Coverage : 81.2% ✓
- Edge cases : 15/20 scenarios (75%) ⚠️
- Attack vectors : 8/10 tested (80%) ✓
- Integration : 6/6 workflows (100%) ✓

---

### MODE ABDUCTIF : Test Impact

**Question** : "Effets de second ordre ?"

**Analysis** :
- Tests complets = -80% bugs production
- Gas profiling = -30% deployment cost
- Fuzz testing = +200% edge cases discovered

---

## Validation Workflow

**AVANT git commit** :
1. ✅ `forge test -vv` → 100% passing
2. ✅ `forge coverage --check 80` → ≥80% coverage
3. ✅ `forge snapshot --check` → No gas regressions
4. ✅ `forge build` → Compilation success

**APRÈS Implementation** :
1. ✅ Integration tests pass (E2E workflows)
2. ✅ Edge cases covered (0/max/boundary)
3. ✅ Attack vectors tested (security)
4. ✅ Fuzz tests pass (property-based)

---

## Metrics Dashboard

**Current Status** :
```json
{
  "tests": {
    "total": 59,
    "unit": 53,
    "integration": 6,
    "passing": 59,
    "pass_rate": "100%"
  },
  "coverage": {
    "lines": 81.2,
    "branches": 72.4,
    "functions": 93.3,
    "target_lines": 80,
    "target_branches": 70
  },
  "gas": {
    "avg_function_gas": 234567,
    "max_function_gas": 450000,
    "target_max": 500000
  },
  "regressions": 0
}
```

---

## Related Contracts

- **DAOMembership.sol** : 18 unit tests, 2 integration tests
- **DAOGovernor.sol** : 20 unit tests, 3 integration tests
- **DAOTreasury.sol** : 15 unit tests, 1 integration test

---

**Confidence** : 98% (TDD blockchain well-established)
**Domain** : Smart contracts testing Solidity 0.8+
**Testing Framework** : Foundry (forge test, forge coverage, forge snapshot)
