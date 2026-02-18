# ADR — Réorientation MVP (2026-02-18)

**Statut** : Adopté
**Date** : 2026-02-18
**Source** : 3 sessions de débat PMF (2 débats 8 experts + stress-test), consensus documenté dans `.claude/swarm/`
**Supersède** : `docs/05-extensions/polkadot-dao-services-ai-design.md` (version initiale — architecture de référence pour Phase 5+, pas pour MVP)

---

## Contexte

Avant de construire le reste du marketplace (ServiceMarketplace.sol, MissionEscrow.sol, etc.), une analyse PMF a été conduite. Elle a révélé des hypothèses critiques non validées et des risques de conformité bloquants. Ce document capture les décisions d'architecture qui en découlent.

---

## Décisions adoptées

### 1. Repositionnement produit

**Avant** : "DAO décentralisée de services — contributeurs IA, compute et humains rétribués proportionnellement"
**Après** : "Cabinet de conseil sans murs, augmenté par l'IA, gouverné comme une coopérative"

**Implication** : Le mot "blockchain" disparaît du discours commercial. "Smart contract" reste acceptable en contexte B2B juridique/financier. La gouvernance DAO est présentée comme holacracie ou coopérative augmentée — message secondaire, jamais premier.

---

### 2. Entonnoir IA AVANT marketplace (Phase P0 — 3 mois)

**Décision** : Les 3 premiers mois sont dédiés à un outil de scoping IA standalone, sans marketplace ouvert.

**Rationale** :
- Résout le cold-start triple (agents + consultants + clients simultanément)
- Terrain vierge : les plateformes existantes (Malt, Upwork) n'ont pas d'IA de scoping intégrée
- Acquisition gratuite → rétention par valeur outils

**Circuit-breaker LLM** : 3 sessions gratuites/entreprise, puis abonnement outils IA (€49-149/mois).

---

### 3. Réputation on-chain = seul usage blockchain côté clients (MVP)

**Décision** : Créer `Reputation.sol`. Retirer escrow et paiements de la blockchain pour le MVP.

**Périmètre Reputation.sol** :
- Badges portables (missions complétées, notes reçues)
- Historique missions vérifiable (hashes IPFS)
- Notes croisées consultant ↔ client
- Intégration DAOMembership (rangs ↔ réputation)

**Contrats annulés pour le MVP** :
- ~~MissionEscrow.sol~~ → remplacé par PSP (voir §4)
- ~~HybridPaymentSplitter.sol~~ → remplacé par PSP
- ~~Token DAOS comme paiement~~ → différé (voir §6)

**Contrats conservés (gouvernance interne DAO)** :
- DAOMembership.sol ✅ (rangs, vote weights)
- DAOGovernor.sol ✅ (gouvernance interne)
- DAOTreasury.sol ✅ (trésorerie)

---

### 4. Escrow via PSP (Mangopay / Stripe Connect), pas smart contract

**Décision** : `MissionEscrow.sol` est abandonné. L'escrow est géré par un PSP agréé ACPR.

**Rationale** : La séquestration de fonds pour compte de tiers en France est une activité réglementée (ACPR). Un smart contract autonome ne peut pas légalement jouer ce rôle sans agrément.

**Options retenues** :
- **Mangopay Connect** : Marketplaces B2B, escrow milestones, KYC intégré, agréé UE
- **Stripe Connect** (alternative) : Plus simple pour PME, moins adapté aux jalons complexes

**Architecture** :
```
Client → PSP (séquestre EUR/USDC) → Libération sur jalons → Consultant
                                   ↑
                         Mangopay API (pas MissionEscrow.sol)
```

---

### 5. Paiement EUR/USDC avant token DAOS

**Décision** : Tous les paiements de missions sont en EUR ou USDC stablecoin. Le token DAOS n'est pas utilisé pour les paiements clients.

**Rationale** : Volatilité token = friction adoption bloquante pour B2B. Les DAF rejettent les crypto-actifs volatils dans leurs achats.

**Timeline DAOS** : Reporter après 12 mois de traction en stablecoin. Le token reste un outil de gouvernance et d'intéressement interne.

---

### 6. Token DAOS : deux couches distinctes (différé)

**Décision** : Quand le token sera introduit, il aura deux couches :
- **Stock** (tokens accumulés) → droits de gouvernance (vote)
- **Flux annuel** (tokens acquis dans l'année) → base d'intéressement communautaire

**Principe anti-rente** : L'intéressement est calculé sur l'acquisition annuelle, pas sur la détention totale. Un contributeur dormant ne touche pas d'intéressement.

**Prérequis introduction token** :
- >50 membres actifs (quadratic scoring viable sinon Sybil attack)
- Avis juridique AMF (risque qualification instrument financier)
- 12+ mois de traction en stablecoin

---

### 7. IA = outil d'augmentation, pas contributeur (correction)

**Avant** : L'analyse PMF initiale envisageait les agents IA comme contributeurs équivalents aux humains
**Après** : L'IA est une infrastructure de la plateforme (comme Copilot pour GitHub). Elle n'est pas rémunérée directement.

**Implication architecturale** :
- Pas de wallet pour les agents IA
- Pas de token allocation pour les agents
- Les agents sont un service payant pour les consultants et les clients (abonnement outils)

**Architecture agents IA (Phase 5)** :
- PME → RAG as a Service (vector stores isolés par client, IPFS)
- Grands comptes → déploiement on-premise (données ne quittent pas le périmètre client)
- Obsolescence : risque continu (mise à jour LLM fournisseur peut dégrader un agent validé)

---

### 8. Commission = levier tactique, pas taux fixe

**Décision** :
- Mois 1-4 : 0% (bootstrap, acquisition)
- Missions 1-20 : 0% (premières 20 missions gratuites pour tout consultant)
- Mois 5+ : Commission progressive votée par la communauté DAO
- Cible stabilisée : 5% missions standards + 2% missions récurrentes

**Garantie** : La plateforme ne peut pas augmenter les commissions unilatéralement — vote communauté obligatoire.

---

### 9. KYC consultant obligatoire (J1)

**Décision** : Tout consultant doit être KYC'd avant d'accéder à la plateforme.

**Périmètre KYC** :
- **Fiscal** : SIRET actif (API Sirene INSEE), RC Pro valide (upload + validation manuelle)
- **Social** : Contrôle statut (éviter requalification travail non déclaré ou prêt illicite main-d'œuvre)
- **Identité** : Prestataire KYC (Onfido, Sumsub, ou Mangopay intégré)
- **Distinct du KYC paiement** : Mangopay impose son propre KYC ACPR en parallèle

**Résultat KYC** → badges portables dans Reputation.sol

---

### 10. DPA RGPD = prérequis absolu J1 (pas Phase 3)

**Décision** : Le Data Processing Agreement doit être en place avant tout accès B2B à la plateforme.

**Rationale** : Les RSSI de grands comptes refusent d'uploader des documents sans DPA. C'est un bloquant d'accès, pas une amélioration future.

**Éléments requis** :
- DPA template signable
- Hébergement EU (Vercel + Supabase = OK si data centers EU)
- Politique de rétention des données
- Pas SOC2 requis au MVP, mais les bases RGPD oui

---

### 11. Structure légale : SAS d'abord, SCIC ensuite

**Décision** : Démarrer en SAS. Évaluer la transformation en SCIC si >50 membres actifs.

**Rationale** :
- SAS = flexibilité maximale + levée VC possible
- SCIC interdit >57.5% distribution bénéfices → levée VC quasi impossible si SCIC trop tôt
- SCOP incompatible avec des indépendants non-salariés
- La DAO = gouvernance interne de la SAS, jamais exposée contractuellement

---

### 12. Burn rate — règle de décision financement

**Variable décisive** : Le fondateur est-il CTO technique ?

| Scénario | Total 8 mois | Net (–revenues M5-M8) | Verdict |
|----------|-------------|----------------------|---------|
| A — Fondateurs sans salaire | ~€33K | ~€26K | Bootstrap épargne |
| B — + 1 dev part-time portage | ~€51K | ~€41K | Bootstrap / love money €50-60K |
| C — ≥1 salarié | ~€107K | ~€97K | Pré-seed si +1 recrutement |

**Circuit-breaker LLM** : prévoir limite sessions gratuites dès le lancement.

---

## Questions ouvertes (ADR à résoudre avant Phase 4)

| Question | Impact | Urgence |
|----------|--------|---------|
| **DoD/DoR missions consulting** : quand déclencher la libération PSP ? Critères de "fait" dans le conseil | Escrow, tokens flux | Avant Phase 4 |
| **Token DAOS** : quand introduire ? Risque AMF ? | Gouvernance | Avant Phase 5 |
| **Grades objectivés** : critères Consultant → Senior → Directeur (missions + notes + pairs) | Réputation, CSM | Phase 5 |
| **Marque blanche** : présenter en marque blanche pour cabinets d'indépendants ? Impact réputation et réseau | Commercial | À trancher |
| **Valorisation contributions Polkadot 2.0** : coretime, compute, stockage comme tokens flux | Tokenomics | Phase 5+ |

---

## Fichiers de référence

- Synthèse débats : `.claude/swarm/memory/debate-pmf-2026-02-17.md`
- ADR légers : `.claude/swarm/snapshots/precedents.md`
- Rétrospective : `.claude/swarm/memory/retrospective.md`
- Design initial (Phase 5+) : `docs/05-extensions/polkadot-dao-services-ai-design.md`

---

*Dernière mise à jour : 2026-02-18*
*Auteurs : Fondateur + débat 8 experts (Intelligence Hybride MIT framework)*
