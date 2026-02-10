# Snapshot Codebase

> Fichier genere automatiquement par scripts/generate-snapshot.sh
> Ne pas modifier manuellement.

## Metadata
```yaml
generated_at: "2026-02-10T22:34:00Z"
staleness_threshold: "48h"
project_root: "."
ecosystem: "javascript + solidity + rust (substrate)"
analyzed_files: 60+
last_update: "setup-swarm installation"
```

## Structure du Projet
```
DAO/
├── contracts/              # Solidity smart contracts (Ethereum)
│   ├── out/               # Compiled artifacts
│   ├── src/
│   │   ├── Marketplace.sol
│   │   ├── Governance.sol  (OpenGov-compatible)
│   │   ├── Treasury.sol
│   │   ├── Membership.sol
│   │   ├── Bonds.sol
│   │   └── Plugins.sol
│   └── test/              # Foundry tests
├── backend/               # TypeScript backend (tRPC + Prisma)
│   ├── api/
│   │   └── routes/        (tRPC procedures)
│   └── services/          (event sync, webhooks)
├── frontend/              # React UI
├── substrate/             # Substrate POC (untracked)
├── substrate-runtime/     # Substrate runtime (in development)
├── .claude/
│   └── swarm/             # Lean Swarm v3.2 (installed 2026-02-10)
└── [docs, scripts, tests, lib/]
```

## Patterns Detectes
```
openzeppelin-libraries|112|contracts/src/*.sol (AccessControl, ReentrancyGuard, Pausable, Governor)
custom-errors-solidity|112|contracts/src/*.sol (gas-optimized over require strings)
tRPC-procedures|15+|backend/api/routes/*.ts (type-safe API procedures)
event-sync-pattern|3|backend/services/event-sync-worker.ts (blockchain → DB sync)
governance-tracks|6|contracts/src/Governance.sol (OpenGov rank-based voting)
```

## Conventions en Vigueur
```yaml
naming:
  files: ""
  functions: ""
  types: ""
  constants: ""
structure:
  test_location: ""
  test_naming: ""
  module_pattern: ""
error_handling: ""
state_management: ""
async_pattern: ""
```

## Metriques par Zone
```
[A GENERER]
# Format : chemin|complexite_cognitive_moyenne|couplage|couverture_test
# src/services/|8.2|moderate|72%
# src/api/routes/|4.1|low|85%
# src/core/engine/|14.7|high|45%  <- ZONE DE FRAGILITE
```

## Zones de Fragilite
```
substrate/|untracked, POC incomplete|evaluate Gate 2 (Month 6) before prioritizing
backend/services/event-sync-worker.ts|critical integration point, 0 tests|add E2E tests + Vitest coverage
contracts/src/Governance.sol|complex multi-track voting logic, 59 tests (total)|maintain 80%+ coverage on changes
No TypeScript tests (backend)|0 tests frontend/backend TypeScript|HIGH priority: add Vitest + Playwright E2E
10 TODO comments scattered|technical debt indicators|convert to GitHub issues + priority labels
```

## Elements Reutilisables
```
OpenZeppelin AccessControl|contracts/src/*.sol|112 usages|reuse in all new Solidity contracts
Custom error patterns|contracts/src/*.sol|112 usages|gas-optimized error handling template
tRPC procedure pattern|backend/api/routes/*.ts|15+ usages|standardized API endpoint template
Event sync pattern|backend/services/event-sync-worker.ts|1 usage|reusable for new event listeners
Governance tracks mapping|contracts/src/Governance.sol|6 tracks|reference implementation for voting logic
```

## Dependances Cles
```
@openzeppelin/contracts|5.0+|access control, security patterns|core library, not replaceable
ethers.js|6.x|blockchain interaction (calls, events, signing)|used with Solidity contracts
Solidity|0.8.20|smart contract language|primary for EVM contracts
tRPC|11.x|type-safe API procedures|backend API framework
Prisma|5.x|database ORM + migrations|database access layer
```

## Code Mort Detecte
```
substrate/|untracked POC directory, no active development|keep until Gate 2 evaluation (Month 6)
_archive/|moved from main implementation|contains abandoned ink! migration (33% complete)
10 TODO comments|scattered across contracts/backend/frontend|should be converted to GitHub issues
```
