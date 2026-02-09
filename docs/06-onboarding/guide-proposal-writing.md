# Guide : Rédiger une proposition gagnante

## Objectif

Ce guide vous aide à structurer une proposition de consulting qui maximise vos chances de sélection par les clients DAO. Une proposition gagnante répond aux 5 critères de scoring automatique tout en démontrant votre expertise.

---

## Template de proposition (1000-2000 mots)

### 1. Compréhension des enjeux (30%)

**Objectif** : Démontrer que vous avez analysé le brief client en profondeur.

**Checklist** :
- ✅ Reformuler les objectifs client avec vos propres mots
- ✅ Identifier les contraintes (délais, budget, ressources)
- ✅ Poser 2-3 questions clarificatrices pertinentes
- ✅ Démontrer connaissance du domaine métier

**Exemple** :
```
D'après votre brief, vous recherchez un audit de sécurité smart contracts
pour votre marketplace NFT avant le lancement mainnet prévu dans 6 semaines.
Les contraintes identifiées :
- Budget maximum : 5000 DAOS (~15 000 EUR au taux actuel)
- Délais serrés : Audit complet en 3 semaines
- Stack technique : Solidity 0.8.20, OpenZeppelin 5.0, Foundry

Questions clarificatrices :
1. Avez-vous déjà réalisé un audit interne ? Si oui, quels outils ?
2. Périmètre exact : contrats core uniquement ou infrastructure complète ?
3. Niveau de documentation actuel du code ?
```

---

### 2. Méthodologie détaillée (25%)

**Objectif** : Prouver que vous avez un plan d'exécution structuré.

**Checklist** :
- ✅ Découper en phases (3-5 étapes)
- ✅ Définir deliverables par phase
- ✅ Mentionner outils/frameworks utilisés
- ✅ Prévoir points de validation intermédiaires

**Exemple** :
```
**Phase 1 : Analyse statique (Semaine 1)**
- Outils : Slither, Mythril, Aderyn
- Deliverables : Rapport vulnérabilités automatiques + faux positifs triés
- Validation : Call 30 min présentation findings

**Phase 2 : Audit manuel (Semaine 2)**
- Focus : Logique métier, accès controls, reentrancy patterns
- Deliverables : Document détaillé par contrat (STRIDE analysis)
- Validation : Draft report review

**Phase 3 : Tests fuzzing (Semaine 3)**
- Outils : Echidna, Foundry invariant tests
- Deliverables : Suite tests property-based + rapport final
- Validation : Présentation findings + recommandations
```

---

### 3. Expérience pertinente (20%)

**Objectif** : Rassurer le client sur votre track record.

**Checklist** :
- ✅ Mentionner 2-3 missions similaires (sans violer NDA)
- ✅ Quantifier résultats (bugs trouvés, économies réalisées)
- ✅ Technologies maîtrisées (certifications si applicable)
- ✅ Liens vers portfolio public

**Exemple** :
```
**Missions similaires récentes** :
1. Audit marketplace DeFi (Q4 2025)
   - 12 vulnérabilités identifiées (3 critiques, 9 moyennes)
   - Économie estimée : $200k pertes potentielles évitées
   - Technologies : Solidity, Hardhat, Slither

2. Audit protocole lending (Q3 2025)
   - Focus : Flash loan attacks, oracle manipulation
   - 8 vulnérabilités (2 critiques corrigées avant mainnet)
   - Technologies : Foundry, Echidna, Certora

**Certifications** :
- Consensys Smart Contract Security (2024)
- Trail of Bits Security Reviews (2025)

**Portfolio public** :
- GitHub : github.com/username (15 audits publics)
- Immunefi profile : 3 bugs reportés (Severity High)
```

---

### 4. Références et portfolio (15%)

**Objectif** : Fournir preuves sociales de qualité.

**Checklist** :
- ✅ Liens GitHub/GitLab avec projets pertinents
- ✅ Témoignages clients précédents (anonymisés si nécessaire)
- ✅ Articles/talks techniques publiés
- ✅ Réputation on-chain (si missions DAO précédentes)

**Exemple** :
```
**Témoignages** :
"Audit extrêmement rigoureux, 2 vulnérabilités critiques identifiées
avant notre launch. Communication claire et livrables pédagogiques."
- CTO, DeFi Protocol X (anonymisé)

**Publications** :
- "Reentrancy Patterns in NFT Marketplaces" (Medium, 5k vues)
- Talk @ ETHGlobal Paris 2025 : "Fuzzing Solidity with Echidna"

**Réputation DAO** :
- 8 missions complétées sur DAO XYZ (rating moyen 4.8/5)
- Rank 3 membre actif (250 DAOS tokens stakés)
```

---

### 5. Budget justifié (10%)

**Objectif** : Démontrer transparence et value for money.

**Checklist** :
- ✅ Décomposer par phase ou par taux horaire
- ✅ Justifier écarts si budget > demande client
- ✅ Proposer options (scope réduit si budget serré)
- ✅ Mentionner conditions paiement (milestones)

**Exemple** :
```
**Budget détaillé** :
- Phase 1 (Analyse statique) : 1200 DAOS (24h × 50 DAOS/h)
- Phase 2 (Audit manuel) : 2000 DAOS (40h × 50 DAOS/h)
- Phase 3 (Fuzzing + rapport final) : 1500 DAOS (30h × 50 DAOS/h)

**Total** : 4700 DAOS (vs 5000 DAOS budget max)

**Option budget réduit** :
Si contrainte budgétaire, possibilité phase 3 allégée (fuzzing contrats
core uniquement) : -500 DAOS → Total 4200 DAOS

**Paiement par milestones** :
- 30% à signature (1410 DAOS)
- 40% après Phase 2 (1880 DAOS)
- 30% à livraison finale (1410 DAOS)
```

---

## Scoring automatique (Frontend)

Votre proposition sera évaluée automatiquement selon ces critères :

| Critère | Poids | Calcul |
|---------|-------|--------|
| **Longueur sections** | 20% | Chaque section ≥200 mots = 4 points |
| **Keywords métier** | 25% | Détection 15+ termes techniques pertinents |
| **Références vérifiables** | 20% | Liens GitHub/portfolio actifs |
| **Expérience quantifiée** | 20% | Chiffres concrets (X bugs, Y économies) |
| **Budget compétitif** | 15% | ≤ budget max client = 15 points |

**Score minimum recommandé** : 70/100 pour compétitivité

**Tips pour améliorer votre score** :
- Utilisez vocabulaire technique précis (noms outils, frameworks)
- Quantifiez TOUS vos résultats (évitez "beaucoup", "plusieurs")
- Incluez minimum 2 liens externes vérifiables
- Structurez avec titres Markdown (facilite parsing)

---

## Exemples de propositions gagnantes

### Exemple 1 : Stratégie digitale (Score 85/100)

```markdown
# Proposition : Stratégie marketing Web3 pour lancement DAO

## 1. Compréhension enjeux

Votre DAO de gouvernance de protocole DeFi cherche à atteindre 1000 membres
actifs dans les 6 mois suivant le TGE (Token Generation Event). Défis identifiés :
- Marché saturé : 500+ DAOs lancées en 2025
- Budget marketing limité : 10 000 DAOS (~30k EUR)
- Target : Développeurs crypto + investisseurs retail

Insight clé : D'après Dune Analytics, 80% des DAOs échouent à dépasser
100 membres actifs faute de stratégie acquisition claire.

[... reste de la proposition ...]
```

**Pourquoi ça marche** :
- ✅ Données chiffrées (1000 membres, 6 mois, 500 DAOs)
- ✅ Source externe citée (Dune Analytics)
- ✅ Identification pain point clair
- ✅ Langage métier Web3 (TGE, protocole DeFi)

---

### Exemple 2 : Audit sécurité (Score 92/100)

```markdown
# Proposition : Audit sécurité smart contracts Marketplace NFT

## 1. Compréhension enjeux

[Voir exemple complet section Méthodologie ci-dessus]

## 2. Méthodologie

**Approche STRIDE** (Threat Modeling Microsoft) :
- Spoofing : Validation signatures EIP-712
- Tampering : Analyse mutations storage
- Repudiation : Audit logs events
- Information Disclosure : Review visibility functions
- Denial of Service : Gas optimization patterns
- Elevation of Privilege : Access controls (Ownable, RBAC)

[... reste de la proposition ...]
```

**Pourquoi ça marche** :
- ✅ Framework reconnu (STRIDE)
- ✅ Décomposition technique précise
- ✅ 6 angles d'analyse détaillés
- ✅ Termes techniques exacts (EIP-712, RBAC)

---

### Exemple 3 : Analyse données (Score 78/100)

```markdown
# Proposition : Dashboard analytics on-chain pour DAO Treasury

## 1. Compréhension enjeux

Votre Treasury DAO gère 2.5M USDC + 500 ETH + 1M tokens natifs.
Problème actuel : Absence de visibilité temps réel sur :
- Allocation assets (% stablecoins vs volatile)
- Performance investments (APY réalisés vs benchmarks)
- Risques concentration (top 10 positions = X% total)

Objectif : Dashboard Dune Analytics + Grafana pour décisions éclairées.

## 2. Méthodologie

**Phase 1 : Data pipeline (Semaine 1-2)**
- Extraction : Etherscan API, Dune SQL queries, Subgraph The Graph
- Transformation : Calcul P&L par asset, allocation %, risk metrics
- Load : PostgreSQL + TimescaleDB (time-series)

**Phase 2 : Visualisations (Semaine 3)**
- Dune dashboard public : KPIs macro (TVL, diversification)
- Grafana privé : Alertes risques (concentration >20%, drawdown >10%)
- Exports CSV hebdomadaires pour comptabilité

[... reste de la proposition ...]
```

**Pourquoi ça marche** :
- ✅ Chiffres concrets Treasury (2.5M USDC, 500 ETH)
- ✅ Stack technique précise (Dune, Grafana, TimescaleDB)
- ✅ Méthodologie ETL standard (Extract-Transform-Load)
- ✅ Alertes configurables avec seuils

---

## Erreurs fréquentes à éviter

| Erreur | Impact | Correction |
|--------|--------|------------|
| ❌ Proposition <500 mots | Score -30 points | Développer chaque section (min 200 mots/section) |
| ❌ Pas de chiffres concrets | Score -20 points | Quantifier résultats passés |
| ❌ Langage vague ("je peux faire") | Score -15 points | Utiliser termes techniques précis |
| ❌ Budget sans décomposition | Score -10 points | Détailler par phase ou taux horaire |
| ❌ Aucun lien externe | Score -15 points | GitHub, portfolio, certifications |

---

## Checklist finale avant soumission

- [ ] Proposition 1000-2000 mots (vérifier compteur)
- [ ] Chaque section ≥200 mots
- [ ] Minimum 15 termes techniques métier
- [ ] 2+ liens externes vérifiables (GitHub, portfolio)
- [ ] Résultats quantifiés (X bugs, Y économies, Z clients)
- [ ] Budget détaillé avec justification
- [ ] Aucune faute d'orthographe (Grammarly/LanguageTool)
- [ ] Format Markdown (titres ##, listes, code blocks)

---

## Outils recommandés

| Outil | Usage | Lien |
|-------|-------|------|
| **Grammarly** | Correction orthographe/grammaire | grammarly.com |
| **Hemingway Editor** | Simplifier phrases complexes | hemingwayapp.com |
| **Word Counter** | Vérifier longueur sections | wordcounter.net |
| **Markdown Preview** | Visualiser rendu final | markdownlivepreview.com |

---

## Prochaines étapes

1. ✅ Rédiger proposition selon template
2. ✅ Vérifier scoring ≥70/100 (calculateur frontend)
3. ✅ Soumettre via interface DAO
4. ⏳ Répondre questions client (délai 48h)
5. ⏳ Attendre sélection (processus 5-7 jours)

---

**Besoin d'aide ?** Rejoignez le Discord DAO, canal `#consultants-support`
**Feedback** : Ce guide vous a aidé ? Notez-le dans `#feedback` (amélioration continue)
