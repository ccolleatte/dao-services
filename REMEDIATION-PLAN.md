# PLAN DE REMÉDIATION — Dépendances critiques

**Objectif** : Gate 1 readiness en 2-3 semaines
**Blockers** : Tests + event-sync + gas optimization

---

## Phase 1 : WEEK 1 (5 jours)

### Jour 1-2 : Setup tests backend + Event-sync hardening

**Task 1.1 : Initialize Vitest**
```bash
# Install Vitest + coverage
npm install -D vitest @vitest/coverage-v8

# Create vitest.config.ts
cat > vitest.config.ts << 'EOF'
import { defineConfig } from 'vitest/config'

export default defineConfig({
  test: {
    environment: 'node',
    coverage: {
      provider: 'v8',
      reporter: ['text', 'json', 'html'],
      include: ['backend/**/*.ts'],
      exclude: ['backend/**/*.test.ts', 'node_modules'],
      lines: 70,
      functions: 70,
      branches: 60,
      statements: 70
    }
  }
})
EOF

# Create test stubs for 4 files
mkdir -p backend/__tests__/
touch backend/__tests__/api.routes.test.ts
touch backend/__tests__/missions.routes.test.ts
touch backend/__tests__/applications.routes.test.ts
touch backend/__tests__/event-sync.test.ts
```

**Task 1.2 : Event-sync error handling**
```bash
# Read event-sync-worker.ts current implementation
# Add try-catch around blockchain calls
# Add validation for blockchain addresses
# Add logging (winston or pino)

# Expected changes:
# - +100 lines error handling
# - +50 lines validation
# - +20 lines logging
```

**Task 1.3 : Migrate 50% require() → custom errors**
```bash
# Identify largest require() concentrations
grep -n "require(" contracts/src/*.sol | head -20

# Batch migrate errors in high-impact files
# Start with MissionEscrow.sol (9 errors already defined)
```

---

### Jour 3 : Complete error migration + first tests

**Task 1.4 : Finish require()→custom errors**
```bash
# Complete 100% migration
# Verify all require() removed
grep -c "require(" contracts/src/*.sol
# Should return 0 for all files
```

**Task 1.5 : First backend test suite**
```bash
# Backend event-sync critical tests
# Critical paths:
#   1. Valid blockchain event sync
#   2. Invalid event data handling
#   3. Database write error handling
#   4. Timeout scenarios

# Backend API route tests
# Critical paths:
#   1. Happy path: create mission
#   2. Validation error handling
#   3. Database errors

# Expected: 15-20 tests passing
npm run test
```

---

### Jour 4-5 : Document + TODOs → Issues

**Task 1.6 : Convert TODOs to GitHub issues**
```bash
# Extract all TODOs
grep -r "TODO\|FIXME" backend contracts --include="*.ts" --include="*.sol"

# Create GitHub issues:
# - Label: tech-debt
# - Priority: depends on criticality
# - Assignee: respective owners
```

**Task 1.7 : Create initial API docs**
```bash
# backend/API.md
# Document all tRPC routes
# - Input schemas
# - Output schemas
# - Error codes
# - Example calls
```

---

## Phase 2 : WEEK 2-3 (6.5 jours)

### Jour 1-2 : E2E tests + Refactoring

**Task 2.1 : Setup Playwright**
```bash
npm install -D @playwright/test

# Create e2e tests for critical flows
# (assuming frontend exists or mock it)
# - Test marketplace creation flow
# - Test governance voting flow
```

**Task 2.2 : Refactor MissionEscrow.sol**
```bash
# Current: 471 lines, 13 functions
# Target: 2-3 smaller contracts if >400 lines

# Split into:
#   - EscrowCore (state management)
#   - EscrowPayment (payment logic)
#   - EscrowDispute (dispute resolution)

# Or keep if cyclomatic complexity < 10
```

---

### Jour 3-4 : Security audit preparation

**Task 2.3 : Contract documentation**
```bash
# contracts/CONTRACTS.md
# For each contract:
#   - Purpose
#   - State variables
#   - Functions (public/external)
#   - Events emitted
#   - Security considerations
```

**Task 2.4 : Audit firm engagement**
```bash
# Request quotes from:
#   - Trail of Bits ($50-80k, 4-6 weeks)
#   - Oak Security ($30-60k, 3-5 weeks)

# Budget: $35-60k
# Timeline: Should start Week 2, deliver Week 4-5
```

---

### Jour 5-6.5 : Pre-audit cleanup

**Task 2.5 : Code review + edge case tests**
```bash
# For DAOGovernor.sol:
#   - Voting period transitions
#   - Quorum edge cases
#   - Proposal state machine

# For DAOMembership.sol:
#   - Membership grant/revoke
#   - Delegation edge cases
```

**Task 2.6 : Pre-commit hooks**
```bash
# Setup husky + lint-staged
npm install -D husky lint-staged

# .husky/pre-commit:
#   - npm run test (backend)
#   - npm run test:coverage (check thresholds)
#   - npm run lint (Solidity + TypeScript)
#   - npm run build (verify no TS errors)
```

---

## Gate 1 Checklist (End of Week 3)

```
✅ Backend tests:
  [ ] Vitest setup
  [ ] 15+ critical tests passing
  [ ] 70%+ coverage on backend/services
  [ ] Event-sync tests (10+ test cases)

✅ Solidity:
  [ ] 100% require() → custom errors
  [ ] MissionEscrow refactored (if needed)
  [ ] DAOGovernor edge cases tested
  [ ] Security audit firm engaged

✅ Documentation:
  [ ] API documentation (routes, schemas)
  [ ] Contract documentation (functions, state)
  [ ] ADRs for key decisions

✅ Tooling:
  [ ] Pre-commit hooks enforcing tests
  [ ] GitHub Actions CI/CD
  [ ] Coverage reporting

✅ Cleanup:
  [ ] All TODOs converted to issues
  [ ] No hardcoded values in event-sync
  [ ] Error handling comprehensive
```

---

## Effort Summary

| Phase | Duration | Owner | Deliverable |
|-------|----------|-------|-------------|
| **Phase 1 Week** | 5 days | Backend + Solidity | Gate 1 MVP tests |
| **Phase 2 Weeks** | 6.5 days | Backend + Audit firm | Audit-ready contracts |
| **TOTAL** | 11.5 days (2-3 weeks) | Full team | Production readiness |

---

## How This Enables Lean Swarm

Once remediation complete:

1. **Snapshot tracks progress** :
   - Before: 0 tests, 14 TODOs
   - After: 70%+ coverage, 0 TODOs → GitHub issues

2. **Precedents document decisions** :
   - Why we migrated require()→custom errors
   - Why we split MissionEscrow
   - Voting logic edge cases discovered

3. **Lenses analyze trade-offs** :
   - Test now (5 days) vs debug later (weeks)
   - Refactor now (2 days) vs technical debt (months)

4. **Team learns** :
   - Retrospective documents lessons
   - Next decisions faster + better

---

**Status** : READY FOR TEAM PLANNING
**Approval needed** : PM review + sprint planning
**Risk if delayed** : Audit failure, MVP blocked
