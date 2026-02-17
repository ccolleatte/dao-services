# Étude d'Impact sur la Feuille de Route Métier et Technologique

**Date** : 2026-02-17
**Scope** : Analyse transversale de l'ensemble de la documentation stratégique, technique et opérationnelle
**Méthode** : Croisement des 17 documents stratégiques avec l'état réel du code, les données marché et les facteurs de succès/échec Web3
**Posture** : Critique constructive — identifier les angles morts, les incohérences et les leviers sous-exploités

---

## Résumé Exécutif

Le projet DAO Services IA/Humains possède une vision ambitieuse et un socle technique solide (10 contrats Solidity, 59 tests, architecture Polkadot 2.0). Cependant, l'analyse croisée révèle **cinq tensions structurelles** entre la feuille de route métier et la feuille de route technologique qui, si elles ne sont pas résolues, risquent de compromettre le time-to-market et le product-market fit.

| # | Tension | Sévérité | Impact |
|---|---------|----------|--------|
| 1 | Scope technologique en expansion vs. capacité d'exécution limitée | **CRITIQUE** | Retard MVP, dispersion |
| 2 | Trois marchés annoncés mais zéro validation terrain | **CRITIQUE** | Risque PMF (90% des échecs Web3) |
| 3 | Incohérence entre tokenomics théorique et implémentation réelle | **HAUTE** | Confusion architecturale |
| 4 | Dette technique croissante masquée par la vélocité documentaire | **HAUTE** | Fragilité pré-audit |
| 5 | Dépendance Polkadot sous-estimée dans un écosystème incertain | **MOYENNE** | Risque plateforme |

---

## 1. Analyse de la Feuille de Route Métier

### 1.1 Force : Vision différenciatrice claire

L'`Analyse_rm.md` repositionne correctement le projet au-delà du "Malt décentralisé" vers trois marchés :

1. **Marché de missions** (brief → équipe → livraison) — compétitif avec Malt
2. **Marché d'agents IA** (brief → réponse instantanée) — inexistant ailleurs
3. **Marché de connaissances** (livrables tokenisés → licences) — inexistant ailleurs

C'est le bon positionnement. Le moat n'est pas "blockchain = transparence" (argument faible pour les clients) mais "agents IA + livrables tokenisés = effets de réseau impossibles à répliquer".

### 1.2 Critique : Trois marchés, zéro validation

**Problème fondamental** : Les trois marchés sont conceptualisés dans les documents mais aucun n'a été confronté à un client réel. L'analyse des facteurs d'échec Web3 (`20260216-web3-success-failure-factors.md`) est sans appel :

> "90% des échecs sont attribués à l'absence de cas d'usage réel" (C-Leads)
> "77% des projets VC-backed génèrent < $1,000/mois de revenus" (ainvest)

Le projet accumule de la documentation (50+ fichiers, 16 000+ lignes) sans feedback terrain. C'est un anti-pattern classique : **construire en chambre avant de valider la demande**.

**Recommandation** :

| Action | Priorité | Effort | Impact |
|--------|----------|--------|--------|
| Recruter 3-5 clients pilotes AVANT de finir le code | **P0** | 2 semaines | Éliminatoire |
| Tester le Parcours B (agent IA) en mode mock (pas de blockchain) | **P0** | 1 semaine | Valide le différenciateur |
| Exécuter 1 mission end-to-end manuellement (escrow = virement bancaire) | **P0** | 1 semaine | Valide le workflow |

Le code peut attendre. Le product-market fit ne peut pas.

### 1.3 Critique : Cibles clients mal hiérarchisées

L'analyse concurrentielle (`20260216-competitive-analysis-marketplaces.md`) identifie trois segments :

1. Consultants mid-level frustrés (80% du marché)
2. Clients PME/startups sensibles prix (60% du marché)
3. Early adopters IA/Compute (5% aujourd'hui, 40% en 2030)

**Problème** : Le segment 3 (IA/Compute) est le plus différenciant mais le plus petit. Le segment 1 (consultants frustrés) est le plus large mais le moins différencié par rapport à Malt. Aucun document ne tranche clairement quel segment attaquer en premier avec quelle proposition de valeur.

**Recommandation** : Adopter une stratégie "bowling pin" :
- **Pin 1 (M0-M3)** : Consultants tech/data (10-20 personnes), missions IA-augmentées, budget 5-15k€. Ce segment est à la fois sensible à la transparence ET prêt pour l'IA.
- **Pin 2 (M3-M6)** : Élargir aux consultants stratégie/management via les agents IA validés en Pin 1.
- **Pin 3 (M6+)** : Ouvrir aux clients PME via les livrables tokenisés et le catalogue.

### 1.4 Critique : Modèle de revenus fragile

Le modèle annoncé est "5% client + 0% consultant". Calcul :

```
10 missions/mois × 8 000 EUR budget moyen × 5% = 4 000 EUR/mois
100 missions/mois × 10 000 EUR × 5% = 50 000 EUR/mois
```

À 10 missions/mois, les revenus (4 000 EUR) ne couvrent même pas un développeur. Le breakeven opérationnel nécessite ~100 missions/mois régulières.

**Problème** : La feuille de route ne contient aucune projection financière réaliste. Les Decision Gates (Month 3 : ">$10k/month revenue") sont mentionnés dans `ink-vs-substrate-decision.md` mais sans plan d'acquisition client concret pour y arriver.

**Recommandation** :
- Modéliser le tunnel de conversion : combien de leads → combien de briefs → combien de missions → quel revenu.
- Envisager un modèle hybride M0-M6 : frais 5% on-chain + services premium off-chain (accompagnement onboarding, formation DAO, intégration IA). Le "0% consultant" est un argument d'acquisition puissant mais le 5% seul ne suffit pas à financer l'opération.
- Les licences de livrables tokenisés (Parcours C) sont le seul flux récurrent scalable. Accélérer leur mise en œuvre.

### 1.5 Critique : Structure juridique SAS-DAO déconnectée du planning technique

La note `20260216-strategic-note-sas-dao-legal.md` décrit une architecture SAS + Association loi 1901 avec des priorités P0 claires (consultation avocat Web3, rédaction statuts, création association). Ces priorités sont **totalement absentes** de la feuille de route technique dans `PROGRESS.md` et `REMEDIATION-PLAN.md`.

**Risque** : Déployer des smart contracts sur mainnet sans structure juridique = exposition personnelle des fondateurs. Un contrat Solidity qui gère de l'escrow est un service de paiement — la qualification réglementaire est nécessaire AVANT le mainnet.

**Recommandation** : Ajouter un workstream juridique parallèle dans la roadmap avec des jalons synchronisés :
- M0 : Consultation avocat Web3 (qualification tokens REP/CRED)
- M1 : Création Association loi 1901
- M2 : Statuts SAS avec clause de gouvernance DAO
- M3 (Gate 1) : Convention de mandat Association → SAS signée = prérequis mainnet

---

## 2. Analyse de la Feuille de Route Technologique

### 2.1 Force : Architecture Solidity bien structurée

L'état du code est réel et cohérent :
- 10 contrats Solidity (`contracts/src/`) couvrant Membership, Governor, Treasury, Marketplace, Escrow, Compliance, Dispute, Reputation, PaymentSplitter
- 59 tests (100% passing)
- Patterns OpenZeppelin (AccessControl, ReentrancyGuard, Pausable, Governor)
- Scripts de déploiement Paseo prêts

La décision d'abandonner ink! au profit de Solidity MVP + Substrate POC parallèle (`ink-vs-substrate-decision.md`) est correcte et bien argumentée.

### 2.2 Critique : Explosion du scope technique

Le nombre de contrats et de fonctionnalités planifiés a considérablement dérivé depuis la Phase 3 initiale. Comparaison :

| Document | Date | Scope Phase 3 |
|----------|------|---------------|
| `PROGRESS.md` | 2026-02-08 | 5 contrats (Membership, Governor, Treasury, Marketplace, Escrow) |
| `Analyse_rm.md` | 2026-02-16 | +AIAgentRegistry, +IPRegistry, profils composés, catalogue livrables |
| `phase-3.1-servicemarketplace-plan.md` | 2026-02-16 | Match scoring 5 critères on-chain, getSkills(), getTrackRecord() |
| `20260216-strategic-note-tokenomics.md` | 2026-02-16 | REP (ERC-5484 Soulbound), CRED (ERC-20), vote quadratique |
| `20260216-strategic-note-smart-contracts-billing.md` | 2026-02-16 | Escrow 4 tranches, Chainlink oracles, Gnosis Safe |

En 8 jours, le scope a doublé sans que la capacité d'exécution ait changé. C'est un signe classique de "scope creep par documentation".

**Impact concret** :
- Le `ServiceMarketplace.sol` planifié requiert `getSkills()` et `getTrackRecord()` dans `DAOMembership.sol` — fonctions qui n'existent pas encore.
- Le modèle de tokenomics (REP soulbound + CRED) est incompatible avec le système de vote weights triangulaire (0,1,3,6,10) déjà implémenté dans `DAOMembership.sol:310` et `DAOGovernor.sol:350`.
- L'`AIAgentRegistry.sol` est annoncé P0/P1 dans `Analyse_rm.md` mais absent de tout plan d'implémentation.

**Recommandation** : Appliquer un "feature freeze" strict :

**Phase 3 MVP (à livrer d'abord, sans déviation)** :
1. Finaliser ServiceMarketplace.sol (avec match scoring simplifié, sans getSkills/getTrackRecord — utiliser uniquement le rank)
2. Finaliser MissionEscrow.sol (multi-sig + timer, sans oracle Chainlink)
3. Deploy Paseo testnet
4. 1 mission pilote end-to-end

**Phase 3.5 (uniquement si Phase 3 validée)** :
5. AIAgentRegistry.sol minimal
6. IPRegistry.sol minimal

Tout le reste (REP soulbound, CRED, vote quadratique, Chainlink, Gnosis Safe) = Phase 4+.

### 2.3 Critique : Incohérence entre tokenomics et implémentation

Deux systèmes de gouvernance contradictoires coexistent dans la documentation :

| Système | Source | Mécanisme |
|---------|--------|-----------|
| **Système A** (implémenté) | `DAOMembership.sol`, `DAOGovernor.sol` | Ranks 0-4, vote weights triangulaires (0,1,3,6,10), 3 tracks, quorums fixes |
| **Système B** (documenté) | `20260216-strategic-note-tokenomics.md` | REP soulbound (ERC-5484), CRED utilitaire, vote quadratique, décroissance -10%/an |

Le Système B est théoriquement supérieur (anti-ploutocratie, incitation à la participation) mais il invalide une partie significative du code déjà écrit. Aucun document ne traite explicitement la transition A → B ni la coexistence des deux systèmes.

**Recommandation** :
- **Court terme (M0-M3)** : Garder le Système A (déjà implémenté, fonctionnel). Le MVP ne nécessite pas de tokenomics sophistiquée.
- **Moyen terme (M3-M6)** : Concevoir la migration A → B comme un projet à part entière avec ses propres specs, tests et migration de données. Ne pas le mélanger avec le développement du marketplace.
- Documenter explicitement la décision dans un ADR (Architecture Decision Record).

### 2.4 Critique : Dette technique sous-estimée dans le planning

Le `DEBT-AUDIT.md` identifie un score de dette technique de 47% (seuil "Elevated"). Les blockers critiques sont :

| Blocker | État actuel | Impact |
|---------|-------------|--------|
| 0 tests backend (TypeScript) | Non résolu | API changes silently break consumers |
| event-sync-worker.ts (564 lignes, 4 TODOs) | Non résolu | Blockchain→DB sync fragile |
| 43 require() vs 30 custom errors | Non résolu | ~10% gas inefficiency |
| Frontend structure vide | Non résolu | Pas d'interface utilisable |

Le `REMEDIATION-PLAN.md` propose 11.5 jours d'effort pour atteindre "Gate 1 readiness". Mais la feuille de route dans `PROGRESS.md` continue d'ajouter des features (ServiceMarketplace, MissionEscrow, HybridPaymentSplitter) sans intégrer ce plan de remédiation.

**Problème** : On développe de nouveaux contrats Solidity pendant que le backend qui les consomme n'a zéro test et un event-sync fragile. C'est construire un deuxième étage sur des fondations non vérifiées.

**Recommandation** : Séquencer strictement :

```
Semaine 1-2 : Remédiation (DEBT-AUDIT items)
    → Backend tests, event-sync hardening, custom errors
Semaine 3-4 : ServiceMarketplace.sol + tests
    → Avec backend tests pour les nouvelles routes
Semaine 5   : Deploy Paseo + smoke tests
    → Uniquement si coverage > 70%
Semaine 6   : Mission pilote
    → Go/No-Go pour Phase 3.5
```

### 2.5 Critique : Duplication Substrate injustifiée

Le codebase contient **deux** répertoires Substrate parallèles :
- `substrate/` : 3 pallets (dao-membership, marketplace, mission-escrow)
- `substrate-runtime/` : 5 pallets (governance, marketplace, membership, payment-splitter, treasury) + runtime + tests d'intégration

Aucun document n'explique pourquoi deux versions coexistent. Le `codebase.md` snapshot mentionne `substrate/` comme "untracked, POC incomplete". Le `ink-vs-substrate-decision.md` planifie le POC Substrate pour Month 3-6.

**Problème** : Du code Substrate existe déjà dans le repo mais n'est référencé nulle part dans la roadmap. C'est soit du code mort (à archiver comme ink!), soit un début de POC non documenté.

**Recommandation** :
- Si `substrate-runtime/` est le POC actif → archiver `substrate/` comme `_archive/20260217-substrate-poc-v1/`
- Si les deux sont des explorations abandonnées → tout archiver et reporter au Month 3-6 comme prévu
- Documenter la décision dans `precedents.md`

### 2.6 Critique : Polkadot Hub comme cible de déploiement — risque sous-évalué

Toute la feuille de route technique repose sur Polkadot Hub (EVM-compatible via Revive/PolkaVM) pour le MVP Solidity. Cependant :

1. **Polkadot Hub est récent (2025)** et l'écosystème d'outils autour est immature comparé à Ethereum L2 (Arbitrum, Base, Optimism).
2. **Les données d'adoption Agile Coretime sont absentes** : `20260216-web3-success-failure-factors.md` note explicitement "Pas de données quantitatives d'adoption trouvées sur le nombre de projets utilisant Agile Coretime".
3. **L'analyse des L2 Ethereum** dans le même document montre que les L2 dominent (frais -90%, ~$40B d'actifs sécurisés, 50% du volume DEX). Moonbeam (EVM-compatible sur Polkadot) est mentionné comme un succès relatif, mais pas Polkadot Hub directement.

**Risque** : Déployer sur une infrastructure EVM relativement nouvelle (Polkadot Hub) plutôt que sur des L2 Ethereum battle-tested. Si le tooling Polkadot Hub n'est pas prêt (Blockscout incomplèt, RPC instable, gas estimation problématique), le MVP est bloqué.

**Recommandation** :
- Maintenir Polkadot Hub comme cible primaire (cohérent avec la vision Substrate long-terme)
- Préparer un plan B sur Moonbeam (EVM Polkadot battle-tested) ou Base (Ethereum L2, frais ultra-bas)
- Tester le déploiement sur Paseo dès la Semaine 5, pas plus tard. Tout problème d'infrastructure doit être détecté tôt.

---

## 3. Analyse Croisée : Incohérences entre Métier et Technique

### 3.1 Décalage temporel entre ambition et réalité

| Milestone PROGRESS.md | Date cible | État réel (17 fév) | Écart |
|------------------------|------------|---------------------|-------|
| M1 : PoC Contrats Core sur testnet | 2026-02-15 | Pas déployé (Foundry local non testé) | **+2 jours et croissant** |
| M2 : MVP Marketplace | 2026-02-22 | ServiceMarketplace non commencé, plan détaillé seulement | **Irréaliste à cette date** |
| M3 : Frontend Minimal | 2026-03-01 | Frontend = structure vide, 0 composants fonctionnels | **Irréaliste à cette date** |
| M4 : Première Mission Pilote | 2026-03-15 | Aucun client pilote identifié | **À risque** |
| M5 : MVP Production | 2026-04-01 | Audit non planifié, structure juridique absente | **Très à risque** |

Le planning de `PROGRESS.md` a été défini le 08 février et n'a jamais été recalibré malgré l'ajout de scope significatif (agents IA, livrables tokenisés, tokenomics dual, structure juridique).

**Recommandation** : Recalibrer les milestones de manière réaliste :

| Milestone | Nouvelle cible | Périmètre strict |
|-----------|---------------|-------------------|
| M1 : Contrats core déployés Paseo | 2026-03-03 | Membership + Governor + Treasury (existants) |
| M2 : Marketplace déployé Paseo | 2026-03-17 | ServiceMarketplace + MissionEscrow simplifié |
| M3 : Mission pilote manuelle | 2026-03-24 | 1 mission avec 1 vrai client, workflow semi-manuel |
| M4 : Frontend minimal | 2026-04-07 | Dashboard read-only + wallet connect |
| M5 : MVP opérationnel | 2026-04-28 | 5 missions complétées, 10 consultants onboardés |

### 3.2 L'onboarding "zéro friction crypto" vs. l'état du frontend

La note `20260216-strategic-note-onboarding-consultants.md` promet une expérience "zéro friction" :
- Connexion LinkedIn SSO
- Wallet custodial invisible (Magic.link / Privy)
- Profil pré-rempli
- Vote via Snapshot embedded

Mais le frontend est actuellement **vide** : pas de composants fonctionnels au-delà de prototypes isolés (`frontend/components/` contient des fichiers mais aucune app routée). Le provider Wallet-as-a-Service n'a pas été choisi (identifié comme P0 dans la note, non planifié dans la roadmap technique).

**Problème** : La promesse métier (onboarding < 20 min, zéro crypto visible) nécessite un investissement frontend significatif qui n'est pas budgété dans le planning technique.

**Recommandation** :
- Phase 1 de l'onboarding = pas de frontend custom. Utiliser Snapshot (votes) + formulaire Typeform (inscription) + Google Sheets (suivi). Coût : 0 EUR. Validable en 1 semaine.
- Phase 2 (M3+) : Frontend minimal Next.js uniquement si la Phase 1 confirme l'intérêt des consultants.
- Ne pas investir dans Magic.link/Privy avant d'avoir 20+ consultants actifs qui demandent l'expérience blockchain.

### 3.3 Le billing conditionnel vs. la réalité des clients

Le smart contract d'escrow à 4 tranches avec oracle Chainlink (`20260216-strategic-note-smart-contracts-billing.md`) est techniquement élégant mais opérationnellement irréaliste au MVP. L'`Analyse_rm.md` le reconnaît :

> "Même les grands comptes mettent 6-12 mois à brancher un partenaire sur leur SI"

La solution proposée (multi-sig + NPS + timer) est pragmatique. Mais le document de billing conditionnel reste dans la roadmap sans être explicitement reporté à M12+.

**Recommandation** : Marquer explicitement le billing Chainlink comme "M12+ / conditionné à >50 missions/mois". Le MVP utilise :
- T1 (50%) : Livraison validée multi-sig 2/3
- T2 (40%) : NPS client ≥ 7/10 via formulaire simple
- T3 (10%) : Auto-release 30 jours

### 3.4 Le paradoxe Substrate : coût d'option vs. coût d'attention

La décision Substrate POC (Month 3-6, budget $140-170k) est correcte en théorie mais crée un paradoxe dans un projet early-stage :

- **Coût d'option** : Ne pas préparer Substrate = blocage si le Solidity MVP décolle et que les performances sont insuffisantes
- **Coût d'attention** : Les 5 pallets dans `substrate-runtime/` et les 8 documents Polkadot monopolisent l'attention cognitive de l'équipe

Le calcul de ROI dans `ink-vs-substrate-decision.md` montre un breakeven à 44 000 missions (15 mois à 100 missions/jour). Mais à ce stade le projet n'a pas une seule mission complétée.

**Recommandation** : Reporter toute activité Substrate à M6 minimum. Critère déclencheur : **50 missions complétées sur Solidity + 1 plainte de performance documentée**. Avant cela, c'est de l'optimisation prématurée.

---

## 4. Analyse des Risques Critiques Non Couverts

### 4.1 Risque réglementaire : PSAN / MiCA

Aucun document ne traite la question de l'enregistrement PSAN (Prestataire de Services sur Actifs Numériques) auprès de l'AMF, ni la conformité MiCA (Markets in Crypto-Assets) entrée en vigueur en 2024.

Un smart contract d'escrow qui gère des fonds clients est potentiellement un service sur actifs numériques. Le token CRED ("1 CRED = 1h de travail") pourrait être qualifié d'instrument financier selon sa mise en œuvre.

**Impact** : Risque d'interdiction d'activité post-lancement.

**Recommandation** : La consultation avocat Web3 identifiée P0 dans `20260216-strategic-note-sas-dao-legal.md` doit inclure explicitement :
- Qualification CRED au regard de MiCA
- Nécessité d'enregistrement PSAN pour le service d'escrow
- Conformité KYC/AML pour les utilisateurs de la marketplace

### 4.2 Risque sécurité : surface d'attaque off-chain

L'analyse des vulnérabilités (`20260216-web3-success-failure-factors.md`) révèle que **80,5% des fonds volés en 2024 provenaient d'attaques off-chain** (phishing, compromission de clés privées). L'`event-sync-worker.ts` (564 lignes, 0 tests) est exactement ce type de surface d'attaque.

Le `threat-model.md` et l'`owasp-checklist.md` existent mais ne sont pas intégrés dans le cycle de développement. Les tests backend sont à 0%.

**Recommandation** : Le hardening du backend (event-sync, validation, error handling) est aussi critique que l'audit des smart contracts. Budgéter un audit backend séparé ($5-10k) en plus de l'audit Solidity.

### 4.3 Risque de gouvernance : capture et apathie

Les données montrent :
- Participation moyenne dans les DAOs : 0,79% (Frontiers in Blockchain)
- Compound DAO attaqué avec seulement 4-5% de turnout
- Les DAOs sont devenues "plus silencieuses et plus concentrées" en 2025

Le système de ranks (0-4) avec durées minimales (30j-365j) protège contre les flash loans mais pas contre l'apathie. Le quorum de 51% (Treasury track) peut être inatteignable si la participation est basse.

**Recommandation** :
- Implémenter des quorums adaptatifs (baisser le seuil si la participation est régulièrement < 30%)
- Le vote quadratique (tokenomics note) est la bonne direction mais doit être implémenté dès que la base de membres dépasse 20 personnes, pas en M12+
- La délégation de vote (mentionnée dans les tendances 2024-2025) est absente de toute roadmap — l'ajouter en M3-M6

### 4.4 Risque de rétention : la portabilité de la réputation est un couteau à double tranchant

La réputation on-chain portable (NFT) est présentée comme un avantage compétitif. C'est vrai du point de vue du consultant — mais c'est aussi un risque pour la plateforme : un consultant avec une réputation portable n'a aucun coût de sortie. C'est anti-lock-in par design.

**Problème** : Contrairement à Malt/Upwork qui retiennent les utilisateurs par lock-in de réputation, la DAO doit retenir par la valeur. Si les frais augmentent ou si le service se dégrade, les consultants partent avec leur réputation.

**Recommandation** : C'est en réalité un **point fort** si le service reste excellent, mais il impose une discipline opérationnelle plus élevée que les plateformes centralisées. Documenter ce risque et s'assurer que le modèle de gouvernance permet aux consultants de voter contre toute augmentation de frais (déjà possible via Treasury track, mais à expliciter).

---

## 5. Recommandations Synthétiques

### 5.1 Actions Immédiates (Semaine 1-2)

| # | Action | Responsable | Critère de succès |
|---|--------|-------------|-------------------|
| 1 | **Recruter 3 clients pilotes** (réseau personnel, pas acquisition paid) | Fondateurs | 3 briefs réels reçus |
| 2 | **Exécuter 1 mission manuellement** (escrow = virement, matching = humain) | Fondateurs | 1 mission complétée, feedback documenté |
| 3 | **Lancer consultation avocat Web3** (qualification tokens, PSAN, MiCA) | Fondateurs | Avis écrit reçu |
| 4 | **Résoudre la dette technique backend** (REMEDIATION-PLAN Semaine 1) | Dev | Backend tests > 70% coverage |
| 5 | **Archiver le code Substrate mort** (`substrate/` → `_archive/`) | Dev | 1 seul répertoire Substrate clair |

### 5.2 Actions Court Terme (Semaine 3-6)

| # | Action | Critère de succès |
|---|--------|-------------------|
| 6 | **Finaliser ServiceMarketplace.sol** (scope réduit : pas de getSkills) | Contract compile, 25 tests passing |
| 7 | **Déployer sur Paseo** (Membership + Governor + Treasury + Marketplace) | Transactions on-chain validées |
| 8 | **Créer la structure juridique** (Association loi 1901 + SAS) | Entités créées, convention signée |
| 9 | **Tester Parcours B** (agent IA → livrable) avec 1 agent prototype | 3 livrables générés, 1 accepté par client |
| 10 | **Recalibrer les milestones** avec dates réalistes | Planning validé par l'équipe |

### 5.3 Actions Moyen Terme (M2-M6)

| # | Action | Critère de succès |
|---|--------|-------------------|
| 11 | **Audit sécurité Solidity** (OpenZeppelin ou Oak Security) | 0 CRITICAL, < 3 HIGH |
| 12 | **Frontend minimal** (dashboard + wallet + vote) | 5 consultants onboardés via l'interface |
| 13 | **AIAgentRegistry.sol** (register + payout, minimal) | 3 agents enregistrés, 10 livrables |
| 14 | **Documenter la transition tokenomics** (Système A → B) | ADR rédigé, plan de migration |
| 15 | **50 missions complétées** (Gate 1 de la vraie validation) | Données d'usage réelles |

---

## 6. Matrice d'Impact sur la Roadmap

### 6.1 Ce qui est Confirmé (garder tel quel)

| Élément | Justification |
|---------|---------------|
| Abandon ink! → Solidity MVP | Décision correcte, bien documentée, consensus industrie |
| Architecture Polkadot 2.0 (Agile Coretime) | Cohérent avec la stratégie cost-effective |
| Système de ranks 0-4 avec durées minimales | Protection anti-flash loan simple et efficace |
| OpenZeppelin comme base de sécurité | Battle-tested, réduit la surface d'audit |
| Frais 5% client + 0% consultant | Argument d'acquisition puissant |
| Escrow multi-sig + timer (sans oracle MVP) | Pragmatique, validé dans Analyse_rm.md |

### 6.2 Ce qui Doit Changer

| Élément | Changement | Raison |
|---------|------------|--------|
| Milestones M1-M5 dans PROGRESS.md | Recalibrer +3 semaines | Dates dépassées, scope augmenté |
| ServiceMarketplace.sol scope | Supprimer getSkills/getTrackRecord au MVP | Fonctions non existantes dans DAOMembership |
| Tokenomics dual (REP/CRED) | Reporter à M6+ | Incompatible avec le code actuel, prématuré |
| Billing conditionnel Chainlink | Reporter à M12+ | Irréaliste MVP, reconnu dans Analyse_rm.md |
| Substrate POC timing | Reporter à M6+ minimum | Zéro mission complétée = prématuré |
| Frontend full stack | Remplacer par outils no-code M0-M3 | Snapshot + Typeform + Google Sheets |

### 6.3 Ce qui Manque (à ajouter)

| Élément | Priorité | Raison |
|---------|----------|--------|
| Workstream juridique (SAS + Association + PSAN) | **P0** | Prérequis mainnet, risque réglementaire |
| Plan d'acquisition clients (pas juste des personas) | **P0** | 90% des échecs = pas de PMF |
| Audit backend (event-sync, API routes) | **P1** | 80% des attaques = off-chain |
| ADR pour transition tokenomics A → B | **P1** | Deux systèmes contradictoires dans les docs |
| Modèle financier détaillé (revenus, coûts, breakeven) | **P1** | Aucune projection chiffrée réaliste |
| Délégation de vote | **P2** | Absent de toute roadmap, nécessaire M3+ |
| Plan de contingence infrastructure (backup L2) | **P2** | Polkadot Hub immature, risque plateforme |

---

## 7. Conclusion

Le projet DAO Services IA/Humains possède trois atouts rares dans l'écosystème Web3 :

1. **Un différenciateur réel** (agents IA + livrables tokenisés ≠ "yet another DeFi")
2. **Un socle technique fonctionnel** (10 contrats, 59 tests, patterns OpenZeppelin)
3. **Une documentation stratégique solide** (analyses marché, tokenomics, juridique)

Le risque principal n'est pas technique — c'est la **dispersion**. Le projet accumule de la complexité documentaire et technique (Substrate POC, tokenomics dual, oracles Chainlink, structure SAS-DAO, vote quadratique) sans avoir validé la demande avec un seul client réel.

La recommandation centrale est simple : **réduire le scope, valider le marché, puis réinvestir**.

```
Semaine 1-2 : Remédier la dette + trouver 3 clients pilotes
Semaine 3-4 : Finaliser Marketplace + déployer Paseo
Semaine 5-6 : 1ère mission pilote + structure juridique
M2-M3      : 10 missions complétées = Gate 1 réelle
M3-M6      : Scale si Gate 1 validée, pivot sinon
```

Tout le reste est de l'optimisation prématurée.

---

**Version** : 1.0.0
**Date** : 2026-02-17
**Méthode** : Analyse croisée de 17 documents stratégiques + état du codebase
**Documents analysés** :
- `PROGRESS.md`, `IMPLEMENTATION-REPORT.md`, `DEBT-AUDIT.md`, `REMEDIATION-PLAN.md`
- `ink-vs-substrate-decision.md`, `polkadot-2.0-architecture.md`, `polkadot-project-management.md`
- `polkadot-patterns.md` (rules)
- `20260216-competitive-analysis-marketplaces.md`
- `20260216-strategic-note-tokenomics.md`
- `20260216-strategic-note-smart-contracts-billing.md`
- `20260216-strategic-note-onboarding-consultants.md`
- `20260216-strategic-note-sas-dao-legal.md`
- `20260216-web3-success-failure-factors.md`
- `Analyse_rm.md`
- `phase-3.1-servicemarketplace-plan.md`
- `.claude/swarm/snapshots/codebase.md`
