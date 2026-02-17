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

## Phase 3 : WEEK 4-5 — Audit Sécurité Backend (off-chain)

### Pourquoi cette phase est critique

Les données 2024-2025 montrent que **80,5% des fonds volés en crypto proviennent d'attaques off-chain** (phishing, compromission de clés, ingénierie sociale). L'audit smart contract seul est insuffisant. Le backend (event-sync, API routes, webhooks) est la surface d'attaque la plus exposée.

Source : QuillAudits 2024 Web3 Security Report, DeepStrike Crypto Hacking Statistics 2025

---

### Jour 1-2 : Threat Modeling Backend

**Task 3.1 : Cartographier les surfaces d'attaque off-chain**

| Surface | Fichier | Risque | Sévérité |
|---------|---------|--------|----------|
| Event-sync worker | `backend/services/event-sync-worker.ts` (564 lignes) | Injection de faux événements blockchain, replay attacks | CRITIQUE |
| API routes missions | `backend/api/routes/missions.ts` | Injection SQL via Supabase, IDOR (accès missions d'autrui) | HAUTE |
| API routes applications | `backend/api/routes/applications.ts` | Manipulation de candidature, usurpation d'identité | HAUTE |
| Webhooks | `backend/services/webhooks.ts` | Webhook spoofing, SSRF | MOYENNE |
| Supabase helpers | `backend/services/supabase-helpers.ts` | Privilege escalation via RLS bypass | HAUTE |
| Validation | `backend/services/validation.ts` | Input validation insuffisante | MOYENNE |

**Task 3.2 : Audit event-sync-worker.ts (priorité absolue)**

Vérifier les 4 TODOs identifiés dans DEBT-AUDIT + :

```
Checklist event-sync :
[ ] Les événements blockchain sont-ils authentifiés (vérification signature) ?
[ ] Existe-t-il une protection contre le replay (nonce, block height) ?
[ ] Les adresses blockchain sont-elles validées (checksum, format) ?
[ ] Les montants sont-ils vérifiés contre overflow/underflow ?
[ ] La connexion RPC est-elle sécurisée (TLS, auth token) ?
[ ] Le worker gère-t-il la réorganisation de chaîne (reorg) ?
[ ] Les erreurs de sync sont-elles loguées sans exposer de secrets ?
[ ] Le rate limiting est-il en place pour les appels RPC ?
```

---

### Jour 3-4 : Hardening Backend

**Task 3.3 : Sécuriser les API routes**

| Action | Fichier | Détail |
|--------|---------|--------|
| Ajouter rate limiting | Toutes les routes | 100 req/min par IP, 20 req/min par wallet |
| Valider les inputs | `validation.ts` | Zod schemas stricts pour chaque endpoint |
| Implémenter CORS strict | Config serveur | Whitelist domaines autorisés uniquement |
| Ajouter auth wallet | Routes protégées | Signature EIP-712 pour chaque requête authentifiée |
| Protéger contre IDOR | Routes missions/applications | Vérifier que `msg.sender == mission.client` côté backend aussi |

**Task 3.4 : Sécuriser les webhooks**

```
Checklist webhooks :
[ ] Vérification HMAC sur chaque webhook entrant
[ ] Timeout < 5 secondes sur les appels sortants
[ ] Pas de SSRF : whitelist d'URLs cibles (pas d'URL user-controlled)
[ ] Idempotence : le même webhook reçu 2x ne produit pas d'effet double
[ ] Logging de tous les webhooks (entrée/sortie) sans données sensibles
```

**Task 3.5 : Sécuriser Supabase**

```
Checklist Supabase :
[ ] Row Level Security (RLS) activé sur toutes les tables
[ ] Policies RLS testées (un user ne peut pas lire/écrire les données d'un autre)
[ ] Service key jamais exposée côté client
[ ] API key (anon) limitée aux opérations read-only publiques
[ ] Pas de requêtes SQL brutes (uniquement le client Supabase typé)
```

---

### Jour 5 : Tests de sécurité automatisés

**Task 3.6 : Écrire les tests de sécurité backend**

```typescript
// backend/__tests__/security.test.ts

describe('Security: Event Sync', () => {
  it('rejects events with invalid block signature', async () => { /* ... */ });
  it('rejects replayed events (same nonce)', async () => { /* ... */ });
  it('rejects events with invalid contract address', async () => { /* ... */ });
  it('handles chain reorganization gracefully', async () => { /* ... */ });
});

describe('Security: API Routes', () => {
  it('returns 429 on rate limit exceeded', async () => { /* ... */ });
  it('rejects requests without valid wallet signature', async () => { /* ... */ });
  it('prevents IDOR: user A cannot access user B missions', async () => { /* ... */ });
  it('validates all input fields with Zod schema', async () => { /* ... */ });
});

describe('Security: Webhooks', () => {
  it('rejects webhooks with invalid HMAC', async () => { /* ... */ });
  it('handles duplicate webhooks idempotently', async () => { /* ... */ });
  it('does not follow redirects (SSRF protection)', async () => { /* ... */ });
});

// Target: 12-15 security tests
```

---

### Budget Audit Backend

| Option | Coût | Durée | Couverture |
|--------|------|-------|------------|
| **Auto-audit interne** (ce plan) | 0 EUR (temps dev) | 5 jours | 70% des vulnérabilités courantes |
| **Audit externe léger** (freelance sécurité) | 3 000 - 5 000 EUR | 1-2 semaines | 85% |
| **Audit externe complet** (cabinet spécialisé) | 8 000 - 15 000 EUR | 3-4 semaines | 95% |

**Recommandation** : Auto-audit interne (Phase 3 ci-dessus) + audit externe léger à M3 si budget disponible. L'audit externe complet est justifié uniquement avant mainnet avec des fonds réels.

---

### Gate 1 Checklist Mise à Jour (incluant backend security)

```
✅ Backend tests:
  [ ] Vitest setup
  [ ] 15+ critical tests passing
  [ ] 70%+ coverage on backend/services
  [ ] Event-sync tests (10+ test cases)

✅ Backend security (NOUVEAU):
  [ ] Threat model documenté (surfaces d'attaque listées)
  [ ] Event-sync hardened (8 points checklist)
  [ ] API routes protégées (rate limit, auth, IDOR)
  [ ] Webhooks sécurisés (HMAC, idempotence, anti-SSRF)
  [ ] Supabase RLS activé et testé
  [ ] 12+ security tests passing

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

## Effort Summary (Mis à Jour)

| Phase | Duration | Owner | Deliverable |
|-------|----------|-------|-------------|
| **Phase 1 Week** | 5 days | Backend + Solidity | Gate 1 MVP tests |
| **Phase 2 Weeks** | 6.5 days | Backend + Audit firm | Audit-ready contracts |
| **Phase 3 Weeks** | 5 days | Backend + Security | Backend security hardening |
| **TOTAL** | 16.5 days (3-4 weeks) | Full team | Production readiness |

---

## How This Enables Lean Swarm

Once remediation complete:

1. **Snapshot tracks progress** :
   - Before: 0 tests, 14 TODOs, 0 security tests
   - After: 70%+ coverage, 0 TODOs → GitHub issues, 12+ security tests

2. **Precedents document decisions** :
   - Why we migrated require()→custom errors
   - Why we split MissionEscrow
   - Voting logic edge cases discovered
   - Backend threat model as reference for future changes

3. **Lenses analyze trade-offs** :
   - Test now (5 days) vs debug later (weeks)
   - Refactor now (2 days) vs technical debt (months)
   - Secure now (5 days) vs breach later (catastrophic)

4. **Team learns** :
   - Retrospective documents lessons
   - Next decisions faster + better

---

**Status** : READY FOR TEAM PLANNING
**Approval needed** : PM review + sprint planning
**Risk if delayed** : Audit failure, MVP blocked, backend exploitation on testnet
