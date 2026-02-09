# DAO : Organisation Décentralisée de Services IA/Humains

> **Vision** : Bâtir l'archétype de l'entreprise de prestation de service de demain — un nouveau modèle BCG complètement décentralisé, où contributeurs IA, puissance de calcul et humains sont rétribués proportionnellement à leur utilisation/mobilisation.

---

## 🎯 Objectif

Réviser complètement la **théorie de la firme** en exploitant les protocoles blockchain et smart contracts pour créer une organisation décentralisée de services de conseil stratégique :

- **Contributeurs hybrides** : Agents IA, puissance de calcul, experts humains
- **Rétribution proportionnelle** : Chaque contributeur est payé à hauteur de son utilisation
- **Gouvernance on-chain** : Décisions techniques, stratégiques et commerciales via vote pondéré
- **Tokenomics** : Token utilitaire pour les paiements et la gouvernance
- **Marché de services** : Matching automatique offre/demande

---

## 📚 Documentation

### Phase 1 : Recherche Fondamentale

| Document | Description |
|----------|-------------|
| [**01-fundamentals**](./docs/01-fundamentals/polkadot-dao-fundamentals.md) | Architecture Polkadot, smart contracts vs parachains, décision Solidity |
| [**02-governance**](./docs/02-governance/polkadot-governance-fellowship-model.md) | OpenGov détaillé, Fellowship (rangs, vote pondéré, pallets) |
| [**03-ecosystem**](./docs/03-ecosystem/polkadot-dao-ecosystem-tools.md) | Solutions existantes, outils de développement (Pop CLI, Foundry, etc.) |

### Phase 2 : Design Architecture

| Document | Description |
|----------|-------------|
| [**04-design**](./docs/04-design/polkadot-dao-design.md) | Architecture DAO de coordination technique (base) |
| [**05-extensions**](./docs/05-extensions/) | Extensions : tokenomics, services IA, marché, facturation |
| [**06-onboarding**](./docs/06-onboarding/) | Guides pédagogiques et onboarding consultants/clients |
| [**07-theory**](./docs/07-theory/) | **Fondements théoriques et académiques** (vote pondéré, tokenomics, 16 références) |

### Phase 3 : Implémentation (EN COURS - 60%)

→ **[README-SETUP.md](./README-SETUP.md)** : Instructions complètes d'installation et déploiement

| Document/Répertoire | Description | Status |
|---------------------|-------------|--------|
| [**contracts/**](./contracts/) | Smart contracts Solidity (Membership, Governor, Treasury) | ✅ 60% |
| [**governance-architecture.md**](./docs/07-implementation/governance-architecture.md) | Architecture complète governance (3 tracks OpenGov) | ✅ Complete |
| [**IMPLEMENTATION-SUMMARY.md**](./docs/07-implementation/IMPLEMENTATION-SUMMARY.md) | Résumé phase 3, métriques, prochaines étapes | ✅ Complete |
| [**frontend/**](./frontend/) | Application Next.js (interface utilisateur) | 🔜 Semaine +2 |
| [**scripts/**](./scripts/) | Scripts de déploiement et tests | ✅ Complete |

**Smart Contracts Implémentés** :
- ✅ **DAOMembership.sol** (310 lignes) : Ranks 0-4, triangular vote weights
- ✅ **DAOGovernor.sol** (350 lignes) : 3-track governance (Technical/Treasury/Membership)
- ✅ **DAOTreasury.sol** (280 lignes) : Spending proposals, budget tracking
- 🔜 **ServiceMarketplace.sol** : Missions, matching (semaine prochaine)
- 🔜 **MissionEscrow.sol** : Milestone payments (semaine prochaine)

**Tests** : 53/53 passing (100%)

---

## 🏗️ Stack Technique

### Blockchain
- **Polkadot Hub** (testnet Paseo) : Smart contracts Solidity
- **PolkaVM** : Machine virtuelle RISC-V (compile Solidity)
- **Pop CLI** : Scaffolding et déploiement

### Smart Contracts
- **Solidity 0.8.19+** : Langage de programmation
- **OpenZeppelin** : Librairies (Governor, AccessControl, etc.)
- **Foundry** : Framework de tests et compilation

### Frontend
- **Next.js 15** : Framework React
- **TypeScript** : Typage statique
- **ethers.js / viem** : Interaction avec les contrats
- **TailwindCSS + shadcn/ui** : Interface utilisateur

### Off-chain
- **Supabase** : Base de données membres et identités
- **GitHub** : RFCs, evidence, coordination
- **Discord** : Notifications et communication

---

## 🚀 Roadmap

### ✅ Phase 1 : Recherche (Complétée)
- [x] Architecture Polkadot fondamentale
- [x] Modèle de gouvernance OpenGov/Fellowship
- [x] Cartographie écosystème et outils
- [x] Design DAO de coordination technique

### ✅ Phase 2 : Extensions (Complétée)
- [x] Design tokenomics (token utilitaire, distribution revenus)
- [x] Architecture marché de services (matching offre/demande)
- [x] Modèle rétribution hybride (IA + humains + compute)
- [x] Gouvernance étendue (tech + business + stratégique)
- [x] Propriété intellectuelle et royalties
- [x] **Volet pédagogique onboarding** (consultants et clients non crypto-natifs)

### 🔄 Phase 3 : MVP Smart Contract (2-4 semaines) - EN COURS
- [x] Setup environnement (Foundry + configuration)
- [x] Contrat DAOMembership.sol (gestion membres, rangs, vote weights)
- [x] Tests unitaires DAOMembership (22 tests passing)
- [ ] Contrats core (Governor, Treasury)
- [ ] Contrats marché (ServiceRegistry, PaymentSplitter, Escrow)
- [ ] Tests unitaires complets (Foundry, 100% coverage)
- [ ] Déploiement testnet Paseo
- [ ] Frontend minimal (Next.js)

### 📅 Phase 4 : Croissance (1-3 mois)
- [ ] Intégration agents IA (API, metering)
- [ ] Compute marketplace (GPU/CPU à la demande)
- [ ] Identité vérifiable (GitHub + KYC)
- [ ] Premiers services pilotes
- [ ] Analytics et dashboard

### 📅 Phase 5 : Migration Parachain (3-6 mois)
- [ ] Runtime Substrate avec pallets natifs
- [ ] Token natif et tokenomics complète
- [ ] XCM pour interopérabilité
- [ ] Audit sécurité
- [ ] Déploiement production (Polkadot mainnet)

---

## 🧩 Architecture Conceptuelle

```
┌─────────────────────────────────────────────────────────┐
│              DAO SERVICES IA/HUMAINS                   │
│                                                         │
│  ┌──────────────────┐  ┌──────────────────────────┐   │
│  │   GOUVERNANCE    │  │  MARCHÉ DE SERVICES      │   │
│  │  - Rangs 0-4     │  │  - Offres de missions    │   │
│  │  - Vote pondéré  │  │  - Demandes clients      │   │
│  │  - 3 tracks      │  │  - Matching auto         │   │
│  └──────────────────┘  └──────────────────────────┘   │
│           │                       │                     │
│           ▼                       ▼                     │
│  ┌─────────────────────────────────────────────────┐   │
│  │          CONTRIBUTEURS HYBRIDES                 │   │
│  │  ┌─────────────┐  ┌──────────┐  ┌───────────┐  │   │
│  │  │   HUMAINS   │  │  AGENTS  │  │  COMPUTE  │  │   │
│  │  │  (Experts)  │  │    IA    │  │ (GPU/CPU) │  │   │
│  │  └─────────────┘  └──────────┘  └───────────┘  │   │
│  └─────────────────────────────────────────────────┘   │
│           │                       │                     │
│           ▼                       ▼                     │
│  ┌──────────────────┐  ┌──────────────────────────┐   │
│  │   TOKENOMICS     │  │  RÉTRIBUTION USAGE       │   │
│  │  - Token utilité │  │  - Metering temps/tokens │   │
│  │  - Distribution  │  │  - Payment splitter      │   │
│  │  - Staking       │  │  - Royalties IP          │   │
│  └──────────────────┘  └──────────────────────────┘   │
└─────────────────────────────────────────────────────────┘
```

---

## 🔗 Ressources

### Documentation Polkadot
- [Polkadot Developer Docs](https://docs.polkadot.com/)
- [Polkadot Hub Smart Contracts](https://docs.polkadot.com/reference/polkadot-hub/smart-contracts/)
- [Pop CLI](https://learn.onpop.io/)

### OpenZeppelin
- [Governor](https://docs.openzeppelin.com/contracts/governance)
- [Access Control](https://docs.openzeppelin.com/contracts/access-control)

### Outils
- [Foundry Book](https://book.getfoundry.sh/)
- [Paseo Testnet Faucet](https://faucet.polkadot.io/)

---

## 📝 License

À définir (MIT, Apache 2.0, ou AGPL-3.0 selon choix de l'équipe)

---

**Date de création** : 2026-02-08
**Dernière mise à jour** : 2026-02-08
**Version** : 0.1.0-alpha
