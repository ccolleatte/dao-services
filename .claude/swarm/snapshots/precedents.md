# Index des Precedents

> Genere partiellement par scripts/generate-snapshot.sh.
> Complete manuellement au fil des decisions.

## Metadata
```yaml
generated_at: "2025-01-01T00:00:00Z"
last_manual_update: "2025-01-01T00:00:00Z"
```

## Solutions Internes — Problemes Deja Resolus
```
api-routes|tRPC procedures|backend/api/routes/*.ts|utiliser pour nouvelles routes API
event-sync|blockchain event listener|backend/services/event-sync-worker.ts|pour sync contrats Solidity → DB
solidity-patterns|OpenZeppelin imports|contracts/src/*.sol|AccessControl, ReentrancyGuard, Pausable
custom-errors|gas-optimized errors|contracts/src/*.sol|112+ usages, preferez aux require()
governance-tracks|OpenGov integration|contracts/src/Governance.sol|rank-based voting, multi-track
```

## Libs et Packages Adoptes
```
@openzeppelin/contracts|Access control, reentrancy, pausable patterns|112+ usages in Solidity
tRPC|Type-safe API procedures|backend/api/routes/* for type-safe client/server
Solidity|Smart contracts (EVM)|6 core contracts (Governance, Marketplace, Treasury, Membership, Bonds, Plugins)
ethers.js|Blockchain interaction|for contract calls, event listening, signing
Prisma|ORM + DB migrations|backend database access + event sync
```

## Anti-Patterns Connus — Erreurs a Ne Pas Reproduire
```
ink!-migration|33% abandoned, maintenance paused (Parity Jan 2026)|use Substrate runtime instead (native, supported)
custom-bridges|trust assumptions, security risk|use Snowbridge (trustless) or Hyperbridge (ZK)
unbounded-storage|DoS attacks, storage bloat (Solidity)|use BoundedVec with explicit limits
no-emergency-pause|cannot stop in case of exploit|implement Pausable pattern (OpenZeppelin)
direct-instantiation-llm|provider lock-in, hard testing|use Backend Abstraction Factory pattern
```

## Decisions Architecturales (ADR legers)
```
2026-02-10|Abandon ink! migration, focus Solidity MVP|ink! maintenance paused, 33% effort wasted|Complete Phase 3 Solidity (30% remaining = 3-4 weeks)
2026-02-10|Substrate runtime preference (long-term)|Performance 0% overhead (native) vs 10-20% WASM|Evaluate Gate 2 (Month 6) if throughput >100 missions/day
2026-02-10|Agile Coretime for MVP phase|Cost-efficient pay-per-use vs 2M DOT parachain slot|Use until >1000 missions/day, then parachain ROI clear
2026-02-10|Solidity MVP deployment (3-4 months)|EVM-compatible, battle-tested, faster to market|Security audit required before mainnet (Gate 1 blocker)
2026-01|OpenZeppelin security libraries mandatory|Access control, reentrancy, pause patterns battle-tested|Use for all new Solidity contracts
```
