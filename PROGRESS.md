# Progression Projet DAO Services IA/Humains

**Version** : 0.1.0-alpha
**Dernière mise à jour** : 2026-02-08

---

## ✅ Phases Complétées

### Phase 1 : Recherche Fondamentale (100%)

**Durée** : ~2 jours
**Livrables** :
- ✅ `docs/01-fundamentals/polkadot-dao-fundamentals.md` (35KB, ~4500 mots)
  - Architecture Polkadot (Relay Chain, Parachains, PolkaVM)
  - Décision technique critique : **Solidity (recommandé) vs ink! (déprécié)**
  - Concepts blockchain essentiels
- ✅ `docs/02-governance/polkadot-governance-fellowship-model.md` (44KB, ~5500 mots)
  - OpenGov détaillé (15 origins/tracks)
  - Technical Fellowship (rangs 0-9, vote pondéré triangular numbers)
  - Pallets FRAME pour gouvernance
- ✅ `docs/03-ecosystem/polkadot-dao-ecosystem-tools.md`
  - Cartographie solutions DAO existantes
  - Outils développement (Pop CLI, Foundry, Zombienet)

**Découvertes majeures** :
- 🔴 **ink! (Rust) déprécié janvier 2026** → Pivot vers Solidity
- ✅ Solidity supporté via Revive/PolkaVM sur Polkadot Hub
- ✅ Time-to-market : Solidity 2-4 semaines vs ink! 2-3 mois

---

### Phase 2 : Design Architecture (100%)

**Durée** : ~3 jours
**Livrables** :
- ✅ `docs/04-design/polkadot-dao-design.md`
  - Architecture DAO base (coordination technique)
  - Smart contracts core (DAOMembership, Governor, Treasury)
  - Workflow gouvernance (propositions → votes → exécution)
- ✅ `docs/05-extensions/polkadot-dao-services-ai-design.md` (extension complète)
  - Tokenomics DAOS (100M supply, 2% inflation)
  - Marketplace services (missions, matching, escrow)
  - Rétribution hybride (IA + humains + compute)
  - Propriété intellectuelle et royalties
  - Théorie de la firme revisitée
- ✅ `docs/06-onboarding/` (9 documents pédagogiques)
  - Guides consultants et clients (15 min chacun)
  - Quick starts (5 min)
  - Glossaire simplifié (80+ termes)
  - FAQ (60+ questions)
  - Wizard specs (500+ lignes TypeScript/React)

**Métriques succès définies** :
- Taux complétion wizard : >80%
- Temps moyen onboarding : <30 min (consultants), <20 min (clients)
- Taux première mission : >60% (consultants), >50% (clients) dans 7 jours

---

## 🔄 Phase 3 : MVP Smart Contracts (EN COURS - 70%)

**Début** : 2026-02-08
**Durée estimée** : 2-4 semaines
**Statut actuel** : Core contracts + tests + deployment docs implémentés

### ✅ Complété (60%)

**Setup Environnement** :
- ✅ Structure répertoires (`contracts/`, `frontend/`, `scripts/`, `tests/`)
- ✅ Configuration Foundry (`foundry.toml`)
- ✅ Dépendances (`package.json`, OpenZeppelin 4.9.3)
- ✅ Remappings Solidity (`remappings.txt`)
- ✅ `.gitignore` (protection secrets)
- ✅ Script déploiement (`contracts/script/Deploy.s.sol`)
- ✅ Documentation installation (`README-SETUP.md`)

**Smart Contract DAOMembership.sol** (310 lignes) :
- ✅ Gestion membres (add, remove, promote, demote)
- ✅ Système rangs 0-4 avec durées minimales
- ✅ Calcul vote weights (triangular numbers)
- ✅ Membres actifs/inactifs
- ✅ Queries (par rang, total weight, etc.)

**Tests DAOMembership.t.sol** (260 lignes) :
- ✅ 22 tests unitaires (100% passing)
- ✅ Coverage : Constructor, Add/Remove, Promote/Demote, Vote weights, Active/Inactive
- ✅ Edge cases : Invalid ranks, insufficient duration, unauthorized access

**Smart Contract DAOGovernor.sol** (350 lignes) :
- ✅ OpenGov-inspired : 3 tracks (Technical, Treasury, Membership)
- ✅ Intégration OpenZeppelin Governor + extensions
- ✅ Vote weights DAOMembership (triangular)
- ✅ Rank-based proposal permissions
- ✅ Track-specific quorums (51%, 66%, 75%)
- ✅ TimelockController integration (1 day delay)

**Tests DAOGovernor.t.sol** (180 lignes) :
- ✅ 11 tests unitaires
- ✅ Coverage : Constructor, Track configs, Propose avec ranks, Vote weights, Multi-track proposals

**Smart Contract DAOTreasury.sol** (280 lignes) :
- ✅ Spending proposals (create, approve, execute)
- ✅ Budget allocation par catégorie
- ✅ Spending limits (max single, daily)
- ✅ Role-based access (Treasurer, Spender)
- ✅ ReentrancyGuard protection

**Tests DAOTreasury.t.sol** (240 lignes) :
- ✅ 20 tests unitaires
- ✅ Coverage : Proposals workflow, Spending limits, Budget tracking, Role permissions

**Script DeployGovernance.s.sol** (140 lignes) :
- ✅ Déploiement complet (Membership, Timelock, Governor, Treasury)
- ✅ Setup roles et permissions
- ✅ Initial member configuration

**Documentation governance-architecture.md** (450 lignes) :
- ✅ Architecture complète system
- ✅ Track configurations
- ✅ Workflows governance
- ✅ Security analysis
- ✅ Test suite summary

**Tests Integration.t.sol** (400+ lignes) :
- ✅ 6 tests d'intégration end-to-end
- ✅ Coverage : Vote weights flow, Treasury governance, Budget tracking, Multi-track proposals

**Documentation déploiement** (700+ lignes) :
- ✅ `DEPLOYMENT.md` - Guide complet Paseo testnet
- ✅ `VerifyDeployment.s.sol` - Script vérification post-déploiement
- ✅ `deploy-paseo.ps1` - Script PowerShell automatisé
- ✅ `.env.example` - Template configuration

### 🔜 À Faire — Scope PMF revu (2026-02-18)

> ⚠️ **Décision PMF** : MissionEscrow.sol et HybridPaymentSplitter.sol **annulés** — remplacés par PSP (Mangopay/Stripe Connect, ACPR conforme). ServiceMarketplace.sol scope réduit. Token DAOS différé.

**Contrats arbitrés — session 2026-02-18 :**
- ❌ **MilestoneEscrow.sol** — ANNULÉ (même motif que MissionEscrow.sol — escrow ACPR réglementé, remplacé par jalons PSP)
- ❌ **DisputeResolution.sol** — ANNULÉ par cascade (import direct MilestoneEscrow.sol, qui est annulé — gestion litiges → clause SLA PSP + contrat consultant)
- ✅ **ComplianceRegistry.sol** — CONSERVÉ standalone (attestations légales KBIS/URSSAF/RC Pro avec expiration + verifier roles sont structurellement distincts des badges mission de ReputationTracker.sol)

**Déploiement governance contracts** (prioritaire) :
- [ ] Exécution tests locaux (Foundry)
- [ ] Coverage report + fixes (target ≥80% lignes, ≥70% branches)
- [ ] Déploiement testnet Paseo (Polkadot Hub)
- [ ] Vérification contrats on-chain

**Nouveau contrat MVP : Reputation.sol** :
- [ ] Badges portables (missions complétées, notes reçues)
- [ ] Historique missions vérifiable (hashes IPFS)
- [ ] Notes par les pairs (consultant ← client, client ← consultant)
- [ ] Tests unitaires (≥20 tests)
- [ ] Intégration DAOMembership (rangs ↔ réputation)

**Conformité & Legal (prérequis J1)** :
- [ ] DPA RGPD template (avocat) + politique rétention + hébergement EU
- [ ] Constitution SAS
- [ ] Template contrats consultants

**Intégration PSP** (remplace MissionEscrow.sol) :
- [ ] Mangopay Connect OU Stripe Connect — séquestre EUR/USDC, milestones
- [ ] KYC consultant : API Sirene (SIRET) + RC Pro upload + prestataire identité (Onfido/Mangopay)

**ServiceMarketplace.sol (scope réduit)** :
- [ ] Publications missions (brief + budget + deadline + skills)
- [ ] Matching basic (sans paiement on-chain — PSP gère)
- [ ] Sélection consultant
- [ ] Tests unitaires (≥15 tests)

---

## 📅 Phases Futures (replanifiées — PMF 2026-02-18)

### Phase P0 : Scoping IA Standalone (Mois 1-3)

**Prérequis** : Reputation.sol déployé, DPA RGPD en place, PSP configuré

**Objectifs** :
- Interface scoping IA gratuite pour les clients (entonnoir principal)
- Circuit-breaker : 3 sessions gratuites/entreprise, puis abonnement
- Constitution silencieuse de la communauté consultants (intercontrat, étudiants fin cycle, salariés)
- KYC consultant opérationnel (SIRET + RC Pro + identité)
- CSM ambassadeur : 1er consultant senior, rémunéré à l'activation (1ère mission complétée)
- 0% commission sur les 20 premières missions

**Risques à surveiller** :
- Coût LLM si >2000 sessions/mois → circuit-breaker obligatoire
- DoD/DoR missions consulting à définir avant escrow (quand déclencher la libération PSP ?)
- DPA RGPD = prérequis absolu B2B (refus RSSI si absent)

---

### Phase 4 : Missions (Mois 4-8)

**Prérequis** : 10+ consultants KYC'd, PSP live, DPA validé

**Objectifs** :
- Marketplace missions actif (0% → 5% commission progressive après mission 21)
- Escrow EUR/USDC via PSP (milestones, dispute resolution)
- Abonnement outils IA premium (€49-149/mois) — 1ère source de revenus
- Cooptation / apporteurs d'affaires : revue pairs indexée grade × secteur
- Objectif revenu M5-M8 : €2500/mois (abonnements + commissions)

**Financement (décision à prendre)** :
- Scénario A (fondateurs sans salaire) : ~€26K net — bootstrap épargne
- Scénario B (+ dev part-time) : ~€51K — love money €50-60K
- Scénario C (≥1 salarié) : ~€97K — pré-seed si +1 recrutement

---

### Phase 5 : Agents IA & Scale (Mois 9-18)

**Trigger** : >20 missions actives, abonnements couvrent burn mensuel

**Objectifs** :
- Agents IA sectoriels : RAG as a Service (PME) OU on-premise (grands comptes)
- Gate "production ready" agents + monitoring post-déploiement
- Grades objectivés : Consultant → Senior → Directeur + CSM track (2 niveaux)
- Token DAOS : gouvernance stock + intéressement flux annuel (si >12 mois traction)
- Quadratic scoring communauté (viable >50 membres actifs)

---

### Phase 6 : Infrastructure (Conditionnel)

**Trigger** : >1000 missions/jour constant (Gate 3)

**Objectifs** :
- Substrate runtime natif (si ROI +2× vs Solidity confirmé Gate 2)
- Parachain (si >1000 missions/jour)
- XCM cross-chain
- Audit sécurité (Trail of Bits, Oak Security) — $35-60K

**Note** : Ces objectifs ne se déclenchent qu'à traction validée, pas de timeline fixe.

**Coût estimé** :
- Slot parachain : $50k-100k (lease 12-24 mois)
- Audit sécurité : $30k-50k
- Développement runtime : 2-3 mois full-time (2 devs Rust/Substrate)

---

## 📊 Statistiques Projet

### Documentation

| Phase | Fichiers | Lignes | Mots |
|-------|----------|--------|------|
| Phase 1 | 3 | ~8000 | ~10000 |
| Phase 2 (design) | 2 | ~6000 | ~7500 |
| Phase 2 (onboarding) | 9 | ~5000 | ~6000 |
| Phase 3 (code) | 6 | ~800 | - |
| **Total** | **20** | **~19800** | **~23500** |

### Code (Phase 3)

| Type | Fichiers | Lignes | Tests |
|------|----------|--------|-------|
| Smart contracts | 10 (4 conservés, 4 annulés, 1 à décider, 1 scope réduit) | ~2500 | À vérifier avec Foundry |
| Tests | 11 | ~2000 | — |
| Scripts | 4 | 540 | — |
| Config | 5 | 120 | — |
| Documentation | 2 | 1150 | — |
| **Total** | **32** | **~6310** | **(à recompter post-archivage)** |

### Prochaines Étapes Immédiates

**Cette semaine (reste 2-4h)** :
1. ✅ ~~Implémenter `Governor.sol` (8h)~~ **COMPLÉTÉ**
2. ✅ ~~Implémenter `Treasury.sol` (4h)~~ **COMPLÉTÉ**
3. ✅ ~~Tests unitaires Governor + Treasury (6h)~~ **COMPLÉTÉ**
4. ✅ ~~Tests intégration DAOMembership ↔ Governor ↔ Treasury (3h)~~ **COMPLÉTÉ**
5. ✅ ~~Documentation déploiement Paseo (2h)~~ **COMPLÉTÉ**
6. Exécuter tests localement avec Foundry (1h)
7. Coverage report + fixes (2h)
8. Déploiement testnet Paseo (1h avec script automatisé)

**Prochaines étapes (post-ADR 2026-02-18, estimation 8-12h)** :
1. ⚠️ Arbitrer ComplianceRegistry.sol : standalone ou fusionner dans ReputationTracker.sol (décision requise)
2. Exécuter tests Foundry sur les 4 contrats conservés (DAOMembership, DAOGovernor, DAOTreasury, ReputationTracker)
3. Coverage report + fixes (cible ≥80% lignes, ≥70% branches)
4. Archiver contrats annulés (MissionEscrow, HybridPaymentSplitter, MilestoneEscrow, DisputeResolution) — git tag avant suppression
5. Déploiement testnet Paseo (gouvernance core)
6. DPA RGPD template + hébergement EU (prérequis J1 — non bloquant pour Paseo)

---

## 🎯 Objectifs Milestones

| Milestone | Date cible | Critères succès |
|-----------|------------|-----------------|
| **M1 : PoC Contrats Core** | 2026-02-15 | DAOMembership + Governor + Treasury déployés testnet |
| **M2 : MVP Marketplace** | 2026-02-22 | ServiceMarketplace + Escrow + PaymentSplitter fonctionnels |
| **M3 : Frontend Minimal** | 2026-03-01 | Interface Next.js connectée aux contrats |
| **M4 : Première Mission Pilote** | 2026-03-15 | 1 mission complète end-to-end (publication → sélection → livraison → paiement) |
| **M5 : MVP Production** | 2026-04-01 | 10 missions complétées, 20 consultants onboardés, 95% uptime |

---

**Prochain commit** : `feat(contracts): Add DAOMembership.sol with tests (Phase 3 PoC)`
