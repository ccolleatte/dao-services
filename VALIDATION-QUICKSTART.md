# Contract Validation - Guide de Démarrage Rapide

**Date** : 2026-02-10
**Version** : 1.0.0
**Audience** : DAO Development Team

---

## 🎯 Objectif

Ce guide fournit les commandes essentielles pour valider les contrats Solidity selon les critères Phase 0.5.

**Target** : Production-ready dans 14-22h (P0 fixes)

---

## 📋 Prerequisites

### Outils Requis

```powershell
# Vérifier Foundry
forge --version
# Expected: forge 1.5.1 ou supérieur

# Vérifier Node.js (pour Slither)
node --version
# Expected: v18+ ou v20+

# Installer Slither (optionnel)
pip install slither-analyzer

# Vérifier installation
slither --version
```

### Structure Projet

```
C:\dev\DAO\
├── contracts/
│   ├── src/           # Contrats Solidity
│   ├── test/          # Tests Foundry
│   └── foundry.toml   # Configuration Foundry
├── _scripts/
│   └── validation/
│       └── validate-contracts.ps1
└── _docs/
    └── guides/
        └── contract-validation-strategy.md
```

---

## ⚡ Quick Commands

### Validation Rapide (Tests Seulement)

```powershell
# Depuis C:\dev\DAO\contracts\
forge test

# Verbose output
forge test -vv

# Specific test file
forge test --match-path test/DAOMembership.t.sol -vv

# Specific test function
forge test --match-test "test_AddMember" -vv
```

### Validation Complète (Automated Script)

```powershell
# Depuis C:\dev\DAO\
.\_scripts\validation\validate-contracts.ps1 -Full

# Quick validation (tests only)
.\_scripts\validation\validate-contracts.ps1 -Quick

# Coverage analysis
.\_scripts\validation\validate-contracts.ps1 -Coverage

# Security scan
.\_scripts\validation\validate-contracts.ps1 -Security

# Gas profiling
.\_scripts\validation\validate-contracts.ps1 -Gas
```

### Coverage Analysis

```powershell
# Depuis C:\dev\DAO\contracts\

# Summary report
forge coverage --report summary

# Detailed LCOV report
forge coverage --report lcov

# View specific contract coverage
forge coverage --report lcov && lcov --list coverage/lcov.info | grep "DAOMembership.sol"

# HTML report (requires lcov-cli)
genhtml coverage/lcov.info --output-directory coverage/html
start coverage/html/index.html
```

### Gas Profiling

```powershell
# Depuis C:\dev\DAO\contracts\

# Generate snapshot
forge snapshot

# Compare with previous
forge snapshot --diff .gas-snapshot

# Gas report per function
forge test --gas-report

# Save gas report
forge test --gas-report > gas-report.txt
```

### Security Analysis (Slither)

```powershell
# Depuis C:\dev\DAO\contracts\

# Full analysis
slither .

# Exclude dependencies
slither . --filter-paths "lib/" --exclude-dependencies

# Focus high/medium severity
slither . --filter-paths "lib/" --exclude-dependencies --fail-high

# JSON report
slither . --json slither-report.json

# Human-readable summary
slither . --print human-summary
```

---

## 📊 Current Status (Phase 0.5)

### Metrics Dashboard

| Métrique | Current | Target | Status |
|----------|---------|--------|--------|
| Tests Passing | 85/85 (100%) | 100% | ✅ |
| Coverage Lines | 66.67% | ≥80% | ❌ |
| Coverage Branches | 41.71% | ≥70% | ❌ |
| HIGH Violations | 3 | 0 | ❌ |
| Slither Errors | ? | 0 | ⏸️ |
| Gas Snapshot | ✅ | ✅ | ✅ |

### P0 Blockers (14-22h)

1. **Coverage Gaps** (8-12h)
   - [ ] DAOMembership: Edge cases + attack vectors
   - [ ] DAOGovernor: Empty inputs + authorization bypass
   - [ ] DAOTreasury: Reentrancy + front-running
   - [ ] MissionEscrow: Status transitions (31.67% branches)

2. **Pausable Mechanism** (4-6h)
   - [ ] DAOMembership.sol
   - [ ] DAOGovernor.sol
   - [ ] DAOTreasury.sol
   - [ ] MissionEscrow.sol
   - [ ] ServiceMarketplace.sol

3. **Unbounded Arrays** (2-4h)
   - [ ] DAOMembership: Pagination for `getActiveMembersByRank()`

---

## 🔧 Common Workflows

### Daily Development Workflow

```powershell
# 1. Make code changes
# ...

# 2. Run tests
forge test -vv

# 3. Check coverage (if new code)
forge coverage --report summary

# 4. Gas snapshot (if modifying contracts)
forge snapshot --check

# 5. Pre-commit validation
.\_scripts\validation\validate-contracts.ps1 -Quick
```

### Pre-Commit Workflow

```powershell
# Full validation before commit
.\_scripts\validation\validate-contracts.ps1 -Full

# If all checks pass:
git add .
git commit -m "feat: implement pausable mechanism"

# If checks fail:
# - Fix issues
# - Re-run validation
# - Commit only when all checks pass
```

### Pre-PR Workflow

```powershell
# 1. Full validation
.\_scripts\validation\validate-contracts.ps1 -Full

# 2. Security scan
slither . --filter-paths "lib/" --exclude-dependencies

# 3. Generate reports
forge coverage --report lcov
forge test --gas-report > gas-report.txt

# 4. Create PR with reports
# - Include coverage report in PR description
# - Attach gas report if significant changes
# - Note any Slither warnings (with justification)
```

### Pre-Audit Workflow

```powershell
# 1. Full validation with strict mode
.\_scripts\validation\validate-contracts.ps1 -Full -CI

# 2. Generate comprehensive reports
forge coverage --report lcov
genhtml coverage/lcov.info --output-directory coverage/html

forge test --gas-report > gas-report.txt

slither . --json slither-report.json
slither . --print human-summary > slither-summary.txt

# 3. Verify all checklist items
# See: _docs/guides/contract-validation-strategy.md §3.1 Pre-Audit Checklist

# 4. Package for auditor
# - contracts/src/ (all source files)
# - coverage/ (HTML reports)
# - gas-report.txt
# - slither-report.json
# - Architecture documentation
# - Known issues / limitations
```

---

## 📈 Improving Coverage

### Identify Missing Tests

```powershell
# Depuis C:\dev\DAO\contracts\

# Generate detailed coverage
forge coverage --report lcov

# View coverage per file
lcov --list coverage/lcov.info

# Find uncovered lines
lcov --list coverage/lcov.info | grep -A5 "DAOMembership.sol"
```

### Test Categories to Add

**Edge Cases** :
- Zero/empty inputs
- Boundary values (min/max)
- Single-element arrays
- Array boundaries (first/last index)

**Attack Vectors** :
- Reentrancy attacks
- Front-running scenarios
- Authorization bypass attempts
- DoS attacks (gas exhaustion)
- Double-spending / double-action

**State Transitions** :
- Invalid state transitions
- Concurrent state changes
- State consistency checks

### Example: Adding Missing Tests

```solidity
// File: test/DAOMembership.t.sol

// Edge case: Remove member at index 0
function test_RemoveMember_AtIndexZero() public {
    // Add 3 members
    membership.addMember(alice, "alice", 1);
    membership.addMember(bob, "bob", 2);
    membership.addMember(charlie, "charlie", 3);

    // Remove first member
    membership.removeMember(alice);

    // Verify
    assertFalse(membership.isMember(alice));
    assertTrue(membership.isMember(bob));
    assertTrue(membership.isMember(charlie));
}

// Attack vector: DoS with 1000 members
function test_GetActiveMembersByRank_GasDoS_1000Members() public {
    // Add 1000 members
    for (uint256 i = 0; i < 1000; i++) {
        address member = address(uint160(i + 1));
        membership.addMember(member, string(abi.encodePacked("user", i)), 1);
    }

    // Call should not revert (gas limit check)
    uint256 gasBefore = gasleft();
    membership.getActiveMembersByRank(1);
    uint256 gasUsed = gasBefore - gasleft();

    // Assert gas usage within acceptable range
    assertLt(gasUsed, 1_000_000, "Gas usage too high (DoS risk)");
}
```

---

## 🐛 Debugging Failed Tests

### Verbose Output

```powershell
# Detailed error messages
forge test -vvv

# With trace (shows all calls)
forge test -vvvv

# Specific failing test
forge test --match-test "test_FailingTest" -vvvv
```

### Gas Debugging

```powershell
# Show gas usage per test
forge test --gas-report

# Identify gas-heavy operations
forge test --match-test "test_ExpensiveOperation" --gas-report
```

### Coverage Debugging

```powershell
# Show uncovered lines
forge coverage --report lcov
lcov --list coverage/lcov.info | grep "0%"

# Visual coverage in HTML
genhtml coverage/lcov.info --output-directory coverage/html
start coverage/html/index.html
```

---

## 🎓 Best Practices

### Test Naming Convention

```solidity
// ✅ CORRECT: test_Function_Scenario_Result
test_AddMember_Success()
test_AddMember_AlreadyExists_Reverts()
test_RemoveMember_NotFound_Reverts()

// ❌ WRONG: camelCase without structure
testAddMember()
testRemoveMember()
```

### Test Organization

```solidity
contract DAOMembershipTest is Test {
    // Setup
    function setUp() public { ... }

    // ============================================
    // AddMember Tests
    // ============================================

    function test_AddMember_Success() public { ... }
    function test_AddMember_AlreadyExists_Reverts() public { ... }
    function test_AddMember_NotAuthorized_Reverts() public { ... }

    // ============================================
    // RemoveMember Tests
    // ============================================

    function test_RemoveMember_Success() public { ... }
    function test_RemoveMember_NotFound_Reverts() public { ... }
}
```

### Assertion Best Practices

```solidity
// ✅ CORRECT: Specific assertions with custom messages
assertEq(membership.getMemberCount(), 3, "Member count should be 3");
assertTrue(membership.isMember(alice), "Alice should be a member");

// ✅ CORRECT: Expect reverts with specific errors
vm.expectRevert("Not authorized");
membership.removeMember(alice);

// ❌ WRONG: Generic assertions without context
assertEq(membership.getMemberCount(), 3);
assertTrue(membership.isMember(alice));
```

---

## 🚨 Troubleshooting

### Common Issues

**Issue** : `forge not found`

```powershell
# Solution: Install Foundry
curl -L https://foundry.paradigm.xyz | bash
foundryup
```

**Issue** : `slither not found`

```powershell
# Solution: Install Slither
pip install slither-analyzer

# If pip not found, install Python first
# Download from: https://www.python.org/downloads/
```

**Issue** : Tests passing locally but failing in CI

```powershell
# Check Foundry version
forge --version

# Update to latest
foundryup

# Clean cache
forge clean
forge test
```

**Issue** : Coverage report shows 0%

```powershell
# Rebuild contracts
forge clean
forge build

# Regenerate coverage
forge coverage --report summary
```

---

## 📚 Resources

### Documentation

- **Strategy détaillée** : `_docs/guides/contract-validation-strategy.md`
- **Audit environnement** : `_docs/reports/20260210-polkadot-environment-audit.md`
- **Phase 0.5 actions** : `.lean-swarm/PHASE-0.5-NEXT-ACTIONS.md`
- **Polkadot patterns** : `.claude/rules/polkadot-patterns.md`

### External Links

- **Foundry Book** : https://book.getfoundry.sh/
- **OpenZeppelin Docs** : https://docs.openzeppelin.com/contracts/5.x/
- **Slither Documentation** : https://github.com/crytic/slither
- **Solidity Style Guide** : https://docs.soliditylang.org/en/latest/style-guide.html

### Support

- **GitHub Issues** : https://github.com/ccolleatte/DAO/issues
- **Team Contact** : DAO Development Team

---

## ✅ Next Steps

### Immediate Actions (Today)

1. ✅ Run validation script once
   ```powershell
   .\_scripts\validation\validate-contracts.ps1 -Full
   ```

2. ✅ Review current status
   - Check coverage gaps
   - Identify missing tests
   - Note security violations

3. ✅ Assign P0 tasks
   - Coverage improvement (8-12h)
   - Pausable implementation (4-6h)
   - Unbounded arrays fix (2-4h)

### This Week (P0 Execution)

1. ⏸️ Execute P0 fixes
2. ⏸️ Daily validation checks
3. ⏸️ Track progress (coverage metrics)
4. ⏸️ Verify completion criteria

### Next Week (P1 + Pre-Audit)

1. ⏸️ Code quality refactoring
2. ⏸️ Setup CI/CD pipeline
3. ⏸️ Generate security reports
4. ⏸️ Prepare audit documentation

---

**Created** : 2026-02-10
**Last Updated** : 2026-02-10
**Maintainer** : DAO Development Team
