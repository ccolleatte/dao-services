# DAO Services IA/Humains

<div align="center">

![Version](https://img.shields.io/badge/version-0.1.0--alpha-blue.svg)
![Tests](https://img.shields.io/badge/tests-59%20passing-brightgreen.svg)
![Phase](https://img.shields.io/badge/phase-3%20(70%25)-yellow.svg)
![Solidity](https://img.shields.io/badge/solidity-0.8.20-363636.svg)
![License](https://img.shields.io/badge/license-MIT-blue.svg)

**Cabinet de conseil sans murs, augmenté par l'IA, gouverné comme une coopérative**

*Réinventer la firme de conseil : IA gratuite pour capter les clients, réputation on-chain portable pour fidéliser les consultants, gouvernance communautaire pour aligner les intérêts.*

[Documentation](./docs/) • [Quick Start](#-quick-start) • [Architecture](#-architecture) • [Roadmap](#-roadmap)

</div>

---

## 🛠️ Stack Technique

- **Blockchain** : Polkadot 2.0 (Async Backing, Agile Coretime, Elastic Scaling)
- **Smart Contracts** : Solidity 0.8.20 (EVM-compatible, Polkadot Hub)
- **Future Runtime** : Substrate pallets (native Polkadot, evaluation en cours)
- **Development** : Foundry (contracts), Cargo (runtime future)
- **Testnet** : Paseo (public testnet)
- **Mainnet Target** : Q2 2026

---

## 🎯 Vision

Réviser complètement la **théorie de la firme** en exploitant les protocoles blockchain et smart contracts pour créer une organisation décentralisée de services de conseil stratégique.

### Principes Fondamentaux

- **🤖 IA comme infrastructure** : Scoping gratuit pour les clients (entonnoir), outils d'augmentation pour les consultants — pas de remplacement humain
- **💰 Rétribution juste** : Commissions réduites (0% → 5% progressif, votées par la communauté), réputation portable, anti-captation
- **🗳️ Gouvernance communautaire** : Les consultants votent les commissions, standards qualité, orientations — pas de décision unilatérale plateforme
- **💶 Paiement EUR/USDC d'abord** : Stablecoin avant token DAOS — adoption B2B sans friction crypto (ACPR conforme via PSP)
- **🔍 Réputation vérifiable on-chain** : Historique de missions, notes, badges portables — seul usage blockchain exposé aux clients

---

## ✨ Features

### ✅ Implémenté (Phase 3 - 70%)

#### Smart Contracts Core (940 lignes)

- **DAOMembership.sol** (310 lignes)
  - Système de rangs hiérarchiques (0-4) inspiré du Polkadot Fellowship
  - Vote weights triangulaires (0, 1, 3, 6, 10)
  - Gestion membres actifs/inactifs
  - Durées minimales par rang (30j → 365j)

- **DAOGovernor.sol** (350 lignes)
  - 3 tracks OpenGov-inspired : Technical, Treasury, Membership
  - Rank-based proposal permissions
  - Track-specific quorums (51%, 66%, 75%)
  - TimelockController integration (1 day delay)
  - OpenZeppelin Governor compatible

- **DAOTreasury.sol** (280 lignes)
  - Spending proposals workflow (create → approve → execute)
  - Budget allocation par catégorie
  - Spending limits (max 100 ETH single, 500 ETH daily)
  - Role-based access (Treasurer, Spender)
  - ReentrancyGuard protection

#### Tests & Qualité

- ✅ **59 tests** (53 unit + 6 integration) - 100% passing
- ✅ **Coverage** : ~75% estimé (target 80%)
- ✅ **Integration tests** : Vote weights flow, Treasury governance, Multi-track proposals

#### Infrastructures

- ✅ Deployment scripts (Foundry + PowerShell automation)
- ✅ Paseo testnet ready ([DEPLOYMENT.md](./contracts/DEPLOYMENT.md))
- ✅ Verification scripts (post-deployment checks)
- ✅ Complete documentation (1150+ lignes)

### 🔜 En Développement (Scope MVP revu — 2026-02-18)

#### Réputation On-Chain (contrat MVP prioritaire)

- **Reputation.sol** : Badges portables, historique missions, notes par les pairs — seul contrat exposé côté clients
- **Profiles** : Identité vérifiable (KYC SIRET + RC Pro + Onfido)

#### Intégration PSP (remplace MissionEscrow on-chain)

- **Mangopay Connect** : Séquestre fonds conforme ACPR, paiement EUR/USDC — pas de MissionEscrow.sol
- **KYC consultant** : APIs Sirene (INSEE) + URSSAF + prestataire identité
- **Stripe Connect** (alternative PME) : pour facturation directe

#### Scoping IA Standalone (Phase P0 — 3 mois avant marketplace)

- **Interface scoping gratuite** : Le client formule son problème, l'IA cadre, un consultant convertit
- **Circuit-breaker** : 3 sessions gratuites/entreprise, puis abonnement outils IA (€49-149/mois)
- **CSM ambassadeur** : Consultant senior communautaire, rémunéré à l'activation (1ère mission)

---

## 🚀 Quick Start

### Prerequisites

```bash
# Node.js 20+
node --version  # v20.x.x

# Foundry (Ethereum development toolkit)
curl -L https://foundry.paradigm.xyz | bash
foundryup

# Verify installation
forge --version
cast --version
```

### Installation (5 min)

```bash
# Clone repository
git clone https://github.com/ccolleatte/dao-services.git
cd dao-services/contracts

# Install dependencies
forge install

# Build contracts
forge build

# Run tests
forge test -vv
```

**Expected output**:
```
Running 59 tests
[PASS] testAddMember() (gas: 123456)
[PASS] testCalculateVoteWeight() (gas: 78910)
...
Test result: ok. 59 passed; 0 failed; 0 skipped; finished in 2.34s
```

### Deploy to Paseo Testnet

```bash
# Setup environment
cp .env.example .env
# Edit .env with your PRIVATE_KEY and ADMIN_ADDRESS

# Get testnet tokens
# Visit: https://faucet.polkadot.io/

# Deploy (automated script)
./deploy-paseo.ps1 -All
```

See [DEPLOYMENT.md](./contracts/DEPLOYMENT.md) for complete deployment guide.

---

## 🏗️ Architecture

### System Overview

```
┌─────────────────────────────────────────────────┐
│         DAO SERVICES IA/HUMAINS                 │
│                                                 │
│  ┌──────────────┐      ┌──────────────────┐   │
│  │  GOVERNANCE  │      │  SERVICE MARKET  │   │
│  │  - Ranks 0-4 │      │  - Missions      │   │
│  │  - 3 Tracks  │      │  - Matching      │   │
│  │  - Timelock  │      │  - Escrow        │   │
│  └──────────────┘      └──────────────────┘   │
│         │                       │              │
│         └───────────┬───────────┘              │
│                     ▼                          │
│  ┌──────────────────────────────────────────┐ │
│  │      HYBRID CONTRIBUTORS                 │ │
│  │  [Humans] [AI Agents] [Compute]         │ │
│  └──────────────────────────────────────────┘ │
│                     │                          │
│                     ▼                          │
│  ┌──────────────────────────────────────────┐ │
│  │  TOKENOMICS & REVENUE DISTRIBUTION       │ │
│  │  [Treasury] [Payment Splitter] [Royalty] │ │
│  └──────────────────────────────────────────┘ │
└─────────────────────────────────────────────────┘
```

### Governance Model (OpenGov-Inspired)

| Track | Min Rank | Voting Period | Quorum | Use Cases |
|-------|----------|---------------|--------|-----------|
| **Technical** | Rank 2+ | 7 days | 66% | Architecture, security fixes |
| **Treasury** | Rank 1+ | 14 days | 51% | Budget allocation, spending |
| **Membership** | Rank 3+ | 7 days | 75% | Promote/demote, suspensions |

### Vote Weights (Triangular Numbers)

| Rank | Name | Weight | Min Duration |
|------|------|--------|--------------|
| 0 | Observer | 0 | - |
| 1 | Active Contributor | 1 | 30 days |
| 2 | Mid-Level | 3 | 90 days |
| 3 | Core Team | 6 | 180 days |
| 4 | Founder | 10 | 365 days |

See [governance-architecture.md](./docs/07-implementation/governance-architecture.md) for complete architecture details.

---

## 📊 Stack Technique

### Blockchain

- **Polkadot Hub** (testnet Paseo) : Smart contracts Solidity EVM-compatible
- **Polkadot 2.0** : Async Backing (6s blocks), Agile Coretime (on-demand blockspace), Elastic Scaling
- **Solidity 0.8.20** : Smart contract language (current MVP)
- **OpenZeppelin 4.9.3** : Battle-tested libraries (Governor, AccessControl, ReentrancyGuard)
- **Substrate Runtime** : Evaluation en cours pour migration future (performance native, XCM intégré)

### Development

- **Foundry** : Compilation, testing, deployment (Solidity)
- **Cargo** : Build toolchain (Substrate runtime - future)
- **Pop CLI** : Polkadot scaffolding
- **Foundry Devtools** : Gas profiling, coverage

### Frontend (Planned)

- **Next.js 15** : React framework
- **TypeScript** : Type safety
- **ethers.js / viem** : Contract interaction
- **TailwindCSS + shadcn/ui** : UI components

### Off-chain

- **Supabase** : Member database, identities
- **GitHub** : RFCs, evidence, coordination
- **Discord** : Notifications, communication

---

## 🗺️ Roadmap

### ✅ Phase 1 : Research (Complete)
**Duration** : ~2 days

- ✅ Polkadot architecture fundamentals
- ✅ OpenGov/Fellowship governance model
- ✅ Ecosystem tools and solutions
- ✅ DAO coordination architecture

### ✅ Phase 2 : Design (Complete)
**Duration** : ~3 days

- ✅ Tokenomics design (DAOS token, distribution)
- ✅ Service marketplace architecture
- ✅ Hybrid remuneration model (AI + humans + compute)
- ✅ Extended governance (tech + business + strategic)
- ✅ Onboarding guides (consultants & clients)

### 🔄 Phase 3 : MVP Smart Contracts (In Progress - 70%)
**Duration** : 2-4 weeks | **Started** : 2026-02-08

**✅ Completed (70%)**:
- ✅ Environment setup (Foundry + config)
- ✅ DAOMembership.sol (ranks, vote weights)
- ✅ DAOGovernor.sol (3-track governance)
- ✅ DAOTreasury.sol (spending proposals, budgets)
- ✅ Unit tests (53 tests, 100% passing)
- ✅ Integration tests (6 scenarios)
- ✅ Deployment infrastructure (Paseo testnet)
- ✅ Complete documentation (1150+ lines)

**🔜 Remaining (30%) — Scope PMF-validated**:
- [ ] Coverage report (target ≥80% lignes)
- [ ] Deploy to Paseo testnet (governance contracts)
- [ ] **Reputation.sol** : badges portables, notes, historique missions
- [ ] **DPA RGPD template** : hébergement EU, politique rétention (prérequis J1)
- [ ] **KYC consultant** : intégration Sirene API + RC Pro upload
- [ ] **PSP intégration** : Mangopay Connect ou Stripe Connect (remplace MissionEscrow.sol)
- [ ] ServiceMarketplace.sol (scope réduit : matching sans paiement on-chain)

> ⚠️ **Décision PMF 2026-02-18** : MissionEscrow.sol et HybridPaymentSplitter.sol **annulés** — remplacés par PSP (ACPR conforme). Token DAOS différé à 12 mois de traction.

**Milestone M1** : Governance PoC + Reputation.sol - Target **2026-03-08**

### 📅 Phase P0 : Scoping IA Standalone (Mois 1-3)
**Prérequis** : Reputation.sol + DPA RGPD + PSP setup

- [ ] Interface scoping IA gratuite (client → problème → cadrage → consultant)
- [ ] Circuit-breaker : 3 sessions gratuites/entreprise puis abonnement
- [ ] Constitution communauté consultants en parallèle (silencieuse)
- [ ] KYC consultant (SIRET + RC Pro + identité)
- [ ] CSM ambassadeur : 1er consultant senior rémunéré à l'activation

### 📅 Phase 4 : Missions (Mois 4-8)
**Prérequis** : 10+ consultants onboardés, PSP opérationnel, DPA validé

- [ ] Marketplace missions (0% commission sur 20 premières)
- [ ] Escrow EUR/USDC via Mangopay (milestones, dispute resolution)
- [ ] Abonnement outils IA premium (€49-149/mois) — première source de revenus
- [ ] Commission progressive : 0% → 5% à partir de la 21ème mission (vote communauté)
- [ ] Cooptation / apporteurs d'affaires : revue pairs indexée grade × secteur

### 📅 Phase 5 : Agents IA & Scale (Mois 9-18)
**Trigger** : >20 missions actives, abonnements couvrant burn rate

- [ ] Agents IA sectoriels (RAG as a Service pour PME, on-premise pour grands comptes)
- [ ] Gate "production ready" : validation plateforme avant mise en ligne agent
- [ ] Monitoring post-déploiement (obsolescence LLM = risque continu)
- [ ] Grades objectivés : Consultant → Senior → Directeur + CSM track
- [ ] Token DAOS : gouvernance stock + intéressement flux (si traction >12 mois validée)

### 📅 Phase 6 : Infrastructure (Conditionnel)
**Trigger** : >1000 missions/jour constant, trésorerie >500K DOT

- [ ] Substrate runtime natif (si ROI confirmé Gate 2)
- [ ] Parachain (si >1000 missions/jour)
- [ ] XCM cross-chain
- [ ] Audit sécurité (Trail of Bits, Oak Security)

---

## 📖 Documentation

### Getting Started

- [Quick Start Developer Guide](./QUICKSTART-DEV.md) - 5 min setup
- [Installation Guide](./README-SETUP.md) - Complete setup instructions
- [Deployment Guide](./contracts/DEPLOYMENT.md) - Paseo testnet deployment

### Architecture & Design

- [Polkadot Fundamentals](./docs/01-fundamentals/polkadot-dao-fundamentals.md) - Architecture, smart contracts vs parachains
- [Governance Model](./docs/02-governance/polkadot-governance-fellowship-model.md) - OpenGov, Fellowship, vote weighting
- [DAO Design](./docs/04-design/polkadot-dao-design.md) - Core DAO architecture
- [Governance Architecture](./docs/07-implementation/governance-architecture.md) - Complete governance system
- [Implementation Summary](./docs/07-implementation/IMPLEMENTATION-SUMMARY.md) - Phase 3 progress, metrics, next steps

### Décisions stratégiques (PMF 2026-02-18)

- **[ADR — Réorientation MVP](./_docs/analyses/20260218-mvp-reorientation-decisions.md)** — Scope MVP revu après analyse PMF : Reputation.sol, PSP, entonnoir IA, financement

### Polkadot 2.0 Development Guides

- **[Polkadot 2.0 Architecture](./_docs/guides/polkadot-2.0-architecture.md)** - Async Backing, Agile Coretime, Elastic Scaling, XCM v3/v4
- **[ink! vs Substrate Decision](./_docs/guides/ink-vs-substrate-decision.md)** - Décision stratégique critique : abandon ink!, focus Substrate POC
- **[Substrate Pallet Patterns](./_docs/guides/substrate-pallet-patterns.md)** - Development patterns, weight calculation, testing
- **[XCM Integration Patterns](./_docs/guides/xcm-integration-patterns.md)** - Cross-chain transfers, bridges Ethereum, XCM security
- **[Polkadot Deployment Guide](./_docs/guides/polkadot-deployment-guide.md)** - Testnet Paseo, mainnet, parachain path
- **[Polkadot Project Management](./_docs/guides/polkadot-project-management.md)** - Treasury proposals, security audits, community
- **[Polkadot Best Practices](./_docs/guides/polkadot-best-practices.md)** - Security, performance, governance, testing strategies

### Smart Contracts

- [Contracts README](./contracts/README.md) - Contract documentation
- [DAOMembership.sol](./contracts/src/DAOMembership.sol) - Membership & ranks
- [DAOGovernor.sol](./contracts/src/DAOGovernor.sol) - 3-track governance
- [DAOTreasury.sol](./contracts/src/DAOTreasury.sol) - Treasury management

### Testing

- [Unit Tests](./contracts/test/) - 53 unit tests
- [Integration Tests](./contracts/test/Integration.t.sol) - 6 E2E scenarios

---

## 🧪 Testing

```bash
# Run all tests
forge test -vv

# Run specific test file
forge test --match-path test/DAOGovernor.t.sol -vv

# Run with gas report
forge test --gas-report

# Coverage report
forge coverage --report summary
forge coverage --report lcov
```

**Current metrics**:
- ✅ 59 tests passing (53 unit + 6 integration)
- ⏳ Coverage: ~75% (target 80%)
- ✅ All critical paths covered

---

## 🤝 Contributing

Contributions are welcome! Please follow these guidelines:

1. **Fork** the repository
2. **Create** a feature branch (`git checkout -b feature/amazing-feature`)
3. **Write tests** for new functionality (TDD approach)
4. **Ensure** all tests pass (`forge test`)
5. **Commit** changes (`git commit -m 'feat: add amazing feature'`)
6. **Push** to branch (`git push origin feature/amazing-feature`)
7. **Open** a Pull Request

### Development Guidelines

- **TDD Strict** : Write tests before implementation
- **Test Coverage** : Maintain ≥80% line coverage
- **Gas Optimization** : Use `forge snapshot` to track gas changes
- **Documentation** : Update relevant docs with your changes
- **Conventional Commits** : Use semantic commit messages

See [CONTRIBUTING.md](./CONTRIBUTING.md) for detailed guidelines.

---

## 📊 Project Statistics

### Code Metrics (Phase 3)

| Metric | Value |
|--------|-------|
| **Smart Contracts** | 3 contracts (940 lines) |
| **Tests** | 59 tests (1080 lines) |
| **Test Coverage** | ~75% (target 80%) |
| **Documentation** | 1150+ lines |
| **Total Files** | 18 files |
| **Total Lines** | 3830 lines |

### Milestones

| Milestone | Target Date | Status |
|-----------|-------------|--------|
| **M1 : PoC Core Contracts** | 2026-02-15 | 🔄 In Progress (70%) |
| **M2 : MVP Marketplace** | 2026-02-22 | 📅 Planned |
| **M3 : Frontend Minimal** | 2026-03-01 | 📅 Planned |
| **M4 : First Pilot Mission** | 2026-03-15 | 📅 Planned |
| **M5 : Production MVP** | 2026-04-01 | 📅 Planned |

---

## 🔗 Resources

### Polkadot Ecosystem

- [Polkadot Developer Docs](https://docs.polkadot.com/)
- [Polkadot Hub Smart Contracts](https://docs.polkadot.com/reference/polkadot-hub/smart-contracts/)
- [Pop CLI](https://learn.onpop.io/)
- [Paseo Testnet Faucet](https://faucet.polkadot.io/)

### Development Tools

- [Foundry Book](https://book.getfoundry.sh/)
- [OpenZeppelin Contracts](https://docs.openzeppelin.com/contracts/)
- [Solidity Documentation](https://docs.soliditylang.org/)

### Community

- **GitHub** : https://github.com/ccolleatte/dao-services
- **Issues** : https://github.com/ccolleatte/dao-services/issues

---

## 📄 License

This project is licensed under the **MIT License** - see the [LICENSE](./LICENSE) file for details.

---

## 📞 Contact & Support

- **Project Lead** : [@ccolleatte](https://github.com/ccolleatte)
- **Repository** : https://github.com/ccolleatte/dao-services
- **Issues** : https://github.com/ccolleatte/dao-services/issues

---

<div align="center">

**Built with ❤️ using Polkadot, Solidity, and OpenZeppelin**

*Réviser la théorie de la firme pour l'ère de l'IA et de la blockchain*

</div>
