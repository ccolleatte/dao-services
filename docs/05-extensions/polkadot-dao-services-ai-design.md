---
title: "Extension : DAO de Services Hybrides IA/Humains"
date: 2026-02-08
version: 1.0.0
author: Conception architecture - workspace C:\dev
purpose: Architecture d'une organisation décentralisée de prestation de services (nouveau modèle BCG)
audience: Développeur expérimenté, entrepreneur blockchain
extends: ../04-design/polkadot-dao-design.md
---

# Extension : DAO de Services Hybrides IA/Humains

## Table des matières

1. [Vision étendue](#1-vision-étendue)
2. [Théorie de la firme revisitée](#2-théorie-de-la-firme-revisitée)
3. [Architecture tokenomics](#3-architecture-tokenomics)
4. [Marché de services](#4-marché-de-services)
5. [Rétribution hybride (IA + Humains + Compute)](#5-rétribution-hybride-ia--humains--compute)
6. [Gouvernance étendue](#6-gouvernance-étendue)
7. [Propriété intellectuelle et royalties](#7-propriété-intellectuelle-et-royalties)
8. [Cas d'usage : BCG décentralisé](#8-cas-dusage--bcg-décentralisé)
9. [Architecture smart contracts étendue](#9-architecture-smart-contracts-étendue)
10. [Roadmap implémentation](#10-roadmap-implémentation)

---

## 1. Vision étendue

### 1.1. Du DAO technique au DAO de services

Le [design de base](../04-design/polkadot-dao-design.md) fournit une **fondation solide** (gouvernance, rangs, votes pondérés) pour un DAO de coordination technique. Cette extension transforme cette fondation en une **organisation décentralisée de prestation de services** complète.

**Évolution conceptuelle** :

```
DAO Technique (Base)          →    DAO Services IA/Humains (Extension)
────────────────────────────       ────────────────────────────────────
• Membres experts humains          • Contributeurs hybrides (IA + humains + compute)
• Vote sur décisions techniques    • Vote sur décisions tech + business + stratégiques
• Trésorerie simple                • Tokenomics complexe (revenus, distribution)
• Pas de marché                    • Marché de services (offre/demande)
• Rémunération fixe                • Rétribution proportionnelle à l'usage
```

### 1.2. Mission : Réviser la théorie de la firme

**Théorie classique de la firme** (Coase, 1937) :
- Coûts de transaction → intégration verticale (employés salariés)
- Hiérarchie centralisée pour coordination
- Capital et travail comme facteurs de production

**Théorie revisitée (DAO blockchain-native)** :
- Smart contracts → coûts de transaction ≈ 0
- Coordination décentralisée via gouvernance on-chain
- Contributeurs autonomes (DAO workers, agents IA, compute providers)
- Rétribution proportionnelle à la valeur créée (usage)
- Token utilitaire comme mécanisme de coordination

**Analogie** : Transformer BCG (Boston Consulting Group) en un réseau décentralisé où :
- Les consultants sont des contributeurs autonomes (pas des salariés)
- Les agents IA augmentent les capacités humaines
- Les clients paient à l'usage (tokens)
- La gouvernance est décentralisée (vote pondéré par expertise)
- Les profits sont redistribués automatiquement via smart contracts

---

## 2. Théorie de la firme revisitée

### 2.1. Contributeurs autonomes vs employés

| Dimension | Firme classique | DAO Services |
|-----------|-----------------|--------------|
| **Relation contractuelle** | Contrat de travail (CDI/CDD) | Smart contract (mission-based) |
| **Rémunération** | Salaire fixe mensuel | Rétribution par usage/mission |
| **Coordination** | Hiérarchie (manager → employé) | Gouvernance on-chain (vote) |
| **Capital** | Actionnaires propriétaires | Token holders (contributeurs = actionnaires) |
| **Prise de décision** | Top-down (C-suite) | Bottom-up (vote pondéré) |
| **Mobilité** | Faible (licenciement coûteux) | Totale (entrée/sortie fluide) |
| **Expertise** | Évaluée par RH/manager | Prouvée on-chain (rangs, contributions) |

### 2.2. Économie de l'usage (usage economy)

**Principe** : Chaque contributeur (humain, IA, compute) est rémunéré **proportionnellement à son utilisation** dans la production de valeur.

**Métriques d'usage** :

| Type contributeur | Métrique d'usage | Unité |
|-------------------|------------------|-------|
| **Expert humain** | Temps de conseil | Heures facturables |
| **Agent IA** | Tokens générés | Tokens GPT (input + output) |
| **Compute GPU** | Temps de calcul | GPU-heures |
| **Compute CPU** | Temps de calcul | CPU-heures |
| **Stockage** | Données stockées | GB-mois |
| **Bande passante** | Transferts | GB transférés |

**Exemple concret** :
- Client paie 1000 tokens DAO pour une mission de conseil stratégique
- Mission utilise :
  - Expert humain A : 10 heures (40% de la valeur créée) → 400 tokens
  - Agent IA (GPT-4) : 50k tokens générés (30%) → 300 tokens
  - Expert humain B : 5 heures (20%) → 200 tokens
  - Compute GPU : 2 heures (10%) → 100 tokens
- Total : 1000 tokens distribués automatiquement via smart contract

### 2.3. Token holders = contributeurs actifs

**Différence clé avec l'actionnariat classique** :
- Dans une firme classique : actionnaires ≠ employés (souvent)
- Dans le DAO : token holders = contributeurs actifs (généralement)

**Mécanisme** :
- Les contributeurs reçoivent des tokens en rémunération
- Ces tokens donnent un pouvoir de gouvernance (vote)
- Plus un contributeur crée de valeur → plus il reçoit de tokens → plus il a d'influence
- Cercle vertueux : expertise → valeur créée → tokens → gouvernance → décisions alignées

**Staking** : Les contributeurs peuvent staker leurs tokens pour :
- Augmenter leur poids de vote (conviction voting)
- Accéder à des missions premium
- Recevoir une part des revenus du protocole (dividendes)

---

## 3. Architecture tokenomics

### 3.1. Token utilitaire (DAO Token)

**Symbole** : DAOS (DAO Services)
**Supply initiale** : 100M tokens
**Émission** : Inflationnaire modérée (2% annuel pour récompenser contributeurs)

**Utilités du token** :

| Utilité | Description | Exemple |
|---------|-------------|---------|
| **Paiement services** | Clients paient en tokens DAOS | Mission 1000 DAOS |
| **Gouvernance** | Vote sur propositions (technique, budget, stratégique) | Voter pour adopter GPT-5 |
| **Staking** | Augmente poids de vote + accès missions premium | Staker 10k DAOS pour conviction 6x |
| **Dividendes** | Recevoir part des revenus protocole | 5% des revenus → stakers |
| **Collateral** | Garantir qualité des missions (slashing si mauvaise qualité) | Staker 1k DAOS pour mission critique |

### 3.2. Distribution initiale

| Allocation | % | Tokens | Vesting | Justification |
|-----------|---|--------|---------|---------------|
| **Core Team** | 20% | 20M | 4 ans (1 an cliff) | Fondateurs et développeurs initiaux |
| **Early Contributors** | 15% | 15M | 2 ans (6 mois cliff) | Premiers consultants et agents IA |
| **DAO Treasury** | 30% | 30M | Immédiat (géré par gouvernance) | Financement croissance, missions, R&D |
| **Investors (optionnel)** | 10% | 10M | 3 ans (1 an cliff) | Levée de fonds initiale (si nécessaire) |
| **Community Rewards** | 20% | 20M | 10 ans (libération progressive) | Récompenser contributions (missions, code, content) |
| **Liquidity Mining** | 5% | 5M | 2 ans | Bootstrap liquidité sur DEX |

### 3.3. Modèle de revenus et distribution

**Sources de revenus** :

1. **Fees missions** : 15% de commission sur chaque mission (clients paient 1150 DAOS, 1000 vont aux contributeurs, 150 à la DAO)
2. **Subscription premium** : Clients corporate paient un abonnement mensuel (accès prioritaire, support dédié)
3. **Marketplace fees** : 5% de commission sur le marché de compute/IA

**Distribution des revenus** :

```
Revenus totaux (100%)
    │
    ├─ 50% → Treasury (gouvernance décide usage : R&D, marketing, salaires core team)
    ├─ 30% → Stakers (dividendes)
    ├─ 10% → Burn (déflationniste, augmente valeur token)
    └─ 10% → Liquidity providers (incitation liquidité DEX)
```

**Exemple chiffré** (revenus mensuels 100k DAOS) :
- Treasury : 50k DAOS (vote sur allocations)
- Stakers : 30k DAOS (distribués proportionnellement au stake)
- Burn : 10k DAOS (réduction supply)
- Liquidity providers : 10k DAOS (récompense LP)

### 3.4. Mécanismes de stabilité

**Problème** : Volatilité du token DAOS → difficulté à fixer prix des missions.

**Solutions** :

| Mécanisme | Description | Avantage |
|-----------|-------------|----------|
| **Pricing en USD** | Prix missions fixés en USD, convertis en DAOS au taux du moment | Stabilité pour clients |
| **Stablecoin payments** | Clients paient en USDC/USDT, convertis en DAOS via DEX | Pas d'exposition volatilité |
| **Treasury reserves** | DAO maintient réserves stablecoins pour racheter tokens si crash | Soutien du prix |
| **Bonding curve** | Émission tokens suit une courbe (plus supply → plus cher) | Limite inflation |

**Recommandation MVP** : Pricing en USD + paiements stablecoin (USDC). Conversion automatique USDC → DAOS via Uniswap/Curve.

---

## 4. Marché de services

### 4.1. Architecture marketplace

```
┌─────────────────────────────────────────────────────────┐
│               MARCHÉ DE SERVICES DAO                    │
│                                                         │
│  ┌──────────────────┐         ┌──────────────────────┐ │
│  │  DEMANDE (Clients)│         │ OFFRE (Contributeurs)│ │
│  │                  │         │                      │ │
│  │ • Mission brief  │         │ • Profils experts    │ │
│  │ • Budget max     │         │ • Agents IA dispo    │ │
│  │ • Deadline       │◄───────►│ • Compute capacity   │ │
│  │ • Compétences    │         │ • Tarifs/dispo       │ │
│  │   requises       │         │                      │ │
│  └──────────────────┘         └──────────────────────┘ │
│           │                            │                │
│           └────────────┬───────────────┘                │
│                        ▼                                │
│          ┌──────────────────────────┐                   │
│          │   MATCHING ENGINE        │                   │
│          │  - Algorithme scoring    │                   │
│          │  - Reputation            │                   │
│          │  - Disponibilité         │                   │
│          │  - Budget fit            │                   │
│          └──────────────────────────┘                   │
│                        │                                │
│                        ▼                                │
│          ┌──────────────────────────┐                   │
│          │    MISSION ACTIVE        │                   │
│          │  - Escrow funds          │                   │
│          │  - Metering usage        │                   │
│          │  - Milestones            │                   │
│          │  - Dispute resolution    │                   │
│          └──────────────────────────┘                   │
│                        │                                │
│                        ▼                                │
│          ┌──────────────────────────┐                   │
│          │   PAIEMENT AUTO          │                   │
│          │  - Payment splitter      │                   │
│          │  - Distribution usage    │                   │
│          │  - Reputation update     │                   │
│          └──────────────────────────┘                   │
└─────────────────────────────────────────────────────────┘
```

### 4.2. Cycle de vie d'une mission

**Phase 1 : Publication demande (Client)**

1. Client crée une demande de mission via frontend
2. Spécifie : brief, budget max, deadline, compétences requises
3. Dépose les fonds en escrow (smart contract `MissionEscrow`)
4. Mission publiée sur le marché

**Phase 2 : Matching (Automatique + Manuel)**

1. **Matching automatique** : Algorithme score tous les contributeurs disponibles selon :
   - Compétences (profil vs brief)
   - Reputation score (missions passées)
   - Disponibilité (agenda)
   - Tarif (fit avec budget)
2. **Top 5 contributeurs** notifiés
3. **Application manuelle** : Contributeurs peuvent aussi postuler manuellement
4. **Sélection** : Client choisit parmi les candidats ou accepte la recommandation auto

**Phase 3 : Exécution mission**

1. Contributeur(s) acceptent la mission → contrat activé
2. **Metering** : Smart contract enregistre l'usage en temps réel :
   - Humains : logging heures via app (timesheet on-chain)
   - Agents IA : compteur tokens API automatique
   - Compute : metering GPU/CPU heures
3. **Milestones** (optionnel) : Paiements intermédiaires à validation
4. **Communication** : Chat off-chain (Discord/Slack) + updates on-chain

**Phase 4 : Livraison et paiement**

1. Contributeur marque la mission "completed"
2. Client a 48h pour valider ou ouvrir un dispute
3. Si validation → **paiement automatique** :
   - Fonds libérés de l'escrow
   - Distribution proportionnelle à l'usage (payment splitter)
   - Fees DAO prélevées (15%)
   - Reputation scores mis à jour
4. Si dispute → arbitrage par le Council (vote)

**Phase 5 : Post-mission**

1. Client et contributeurs s'évaluent mutuellement (rating 1-5 étoiles)
2. Ratings enregistrés on-chain → impact reputation
3. Mission archivée (historique public)

### 4.3. Scoring et reputation

**Reputation score** (0-100) calculé selon :

| Facteur | Poids | Calcul |
|---------|-------|--------|
| **Missions complétées** | 30% | Nombre missions × taux succès |
| **Ratings clients** | 40% | Moyenne ratings × nombre reviews |
| **Rang DAO** | 20% | Rang 0-4 → score 0-20 |
| **Ancienneté** | 10% | Mois d'activité (cap à 24 mois) |

**Formule** :
```
reputation = (missions_completed * 0.3 * success_rate) +
             (avg_rating * 0.4 * num_reviews / 10) +
             (rank * 5 * 0.2) +
             (min(months_active, 24) / 24 * 10 * 0.1)
```

**Exemple** :
- Alice : 50 missions, 95% succès, 4.8/5 rating (30 reviews), rang 3, 18 mois
- Score = (50 * 0.3 * 0.95) + (4.8 * 0.4 * 3) + (3 * 5 * 0.2) + (18/24 * 10 * 0.1)
- Score = 14.25 + 5.76 + 3 + 0.75 = **23.76** → Reputation élevée

**Impacts reputation** :
- Accès missions premium (budget >10k DAOS)
- Tarif recommandé plus élevé (marketplace suggère tarif selon reputation)
- Poids dans disputes (arbitrage pondéré par reputation)

---

## 5. Rétribution hybride (IA + Humains + Compute)

### 5.1. Metering multi-contributeurs

**Challenge** : Comment mesurer équitablement la contribution de chaque type de contributeur dans une mission collaborative ?

**Solution** : **Metering granulaire + attribution de valeur**

#### 5.1.1. Humains (experts)

**Métrique** : Heures facturables

**Tracking** :
- App mobile/web avec timesheet
- Start/stop timer intégré
- Screenshots périodiques (optionnel, paramétrable)
- Validation par client ou pairs

**Tarif** : Dépend du rang et de la spécialisation

| Rang | Tarif moyen (DAOS/heure) | Équivalent USD (@ 1 DAOS = $2) |
|:----:|:------------------------:|:-----------------------------:|
| 0 | 25 | $50 |
| 1 | 50 | $100 |
| 2 | 100 | $200 |
| 3 | 200 | $400 |
| 4 | 400 | $800 |

#### 5.1.2. Agents IA

**Métrique** : Tokens générés (input + output)

**Tracking** :
- API wrapper compte tokens automatiquement
- Chaque appel IA enregistre : model, tokens_in, tokens_out, latence
- Stocké on-chain (events)

**Tarif** : Dépend du modèle et du fournisseur

| Modèle | Coût input (DAOS/1M tokens) | Coût output (DAOS/1M tokens) |
|--------|:---------------------------:|:----------------------------:|
| GPT-4o | 2.5 | 10 |
| Claude 3.5 Sonnet | 3 | 15 |
| Llama 3 70B | 0.5 | 2 |
| GPT-3.5 Turbo | 0.5 | 1.5 |

**Conversion** : Prix en USD (API providers) convertis en DAOS au taux du moment + marge DAO (10%)

#### 5.1.3. Compute (GPU/CPU)

**Métrique** : GPU-heures ou CPU-heures

**Tracking** :
- Instances compute enregistrent start/stop times
- Type GPU/CPU (A100, H100, etc.)
- Utilisation % (monitoring)

**Tarif** : Marché dynamique (offre/demande)

| Ressource | Tarif moyen (DAOS/heure) | Équivalent USD |
|-----------|:------------------------:|:--------------:|
| NVIDIA A100 (40GB) | 1.5 | $3 |
| NVIDIA H100 (80GB) | 4 | $8 |
| AMD EPYC CPU (64 cores) | 0.5 | $1 |

### 5.2. Payment Splitter automatique

**Smart contract** : `PaymentSplitter.sol`

**Logique** :
1. Mission complétée → fonds libérés de l'escrow
2. `PaymentSplitter` lit les métriques d'usage (events on-chain)
3. Calcule la contribution de chaque participant :
   - Humain A : 10h × 100 DAOS/h = 1000 DAOS (40%)
   - Agent IA : 50k tokens × (2.5 + 10)/1M × 1.1 = 687.5 DAOS (27.5%)
   - Humain B : 5h × 200 DAOS/h = 1000 DAOS (40%)
   - Total = 2500 DAOS (après fees DAO 15% = 2941 DAOS payés par client)
4. Transferts automatiques vers les comptes des contributeurs

**Code simplifié** :
```solidity
function settleMission(uint256 missionId) external {
    Mission memory mission = missions[missionId];
    require(mission.status == Status.Completed, "Not completed");

    // Lire métriques usage
    UsageMetrics memory metrics = usageTracking[missionId];

    // Calculer parts
    uint256 totalValue = 0;
    for (uint i = 0; i < metrics.contributors.length; i++) {
        uint256 value = calculateContributorValue(metrics.contributors[i]);
        contributorShares[i] = value;
        totalValue += value;
    }

    // Distribuer
    uint256 availableFunds = mission.escrowAmount * 85 / 100; // 15% fees
    for (uint i = 0; i < metrics.contributors.length; i++) {
        uint256 payment = availableFunds * contributorShares[i] / totalValue;
        payable(metrics.contributors[i].account).transfer(payment);
    }
}
```

### 5.3. Cas d'usage : Mission collaborative

**Scénario** : Étude de marché pour un client fintech

**Équipe** :
- Lead consultant (humain, rang 3) : coordination, stratégie
- Junior analyst (humain, rang 1) : recherche de données
- Agent IA (GPT-4) : génération de rapports, synthèse
- Compute GPU : entraînement modèle de prédiction custom

**Déroulé** :
1. Client publie mission : budget 5000 DAOS, deadline 2 semaines
2. Lead consultant accepte, compose son équipe
3. Travail collaboratif :
   - Lead : 20h × 200 DAOS/h = 4000 DAOS
   - Junior : 40h × 50 DAOS/h = 2000 DAOS
   - Agent IA : 200k tokens × 12.5/1M × 1.1 = 2750 DAOS
   - GPU (A100) : 10h × 1.5 DAOS/h = 15 DAOS
   - **Total valeur créée** : 8765 DAOS
4. Client valide livraison
5. Paiement : 5000 DAOS × 0.85 = 4250 DAOS disponibles (après fees DAO)
6. Distribution proportionnelle :
   - Lead : 4250 × 4000/8765 = **1940 DAOS** (46%)
   - Junior : 4250 × 2000/8765 = **970 DAOS** (23%)
   - Provider IA : 4250 × 2750/8765 = **1333 DAOS** (31%)
   - Provider GPU : 4250 × 15/8765 = **7 DAOS** (0.2%)

**Note** : Le total valeur créée (8765) > budget (4250) → chaque contributeur reçoit ~48% de sa valeur nominale. C'est un indicateur de compétitivité : si valeur créée << budget, contributeurs sur-rémunérés (mauvais matching).

---

## 6. Gouvernance étendue

### 6.1. Trois domaines de gouvernance

Le [design de base](../04-design/polkadot-dao-design.md) définit 3 tracks (TECHNIQUE, BUDGET, MEMBERSHIP). Pour un DAO de services, on ajoute des tracks spécialisés :

| Track | Portée | Votants | Seuil | Durée |
|-------|--------|---------|-------|-------|
| **TECHNIQUE** | Architecture, stack, outils | Rangs 1+ | 60% | 14j |
| **BUSINESS** | Stratégie, pricing, partnerships | Tous membres | 50% | 7j |
| **MARKETING** | Brand, communication, growth | Rangs 0+ | 50% | 5j |
| **LEGAL/COMPLIANCE** | Conformité, KYC, régulations | Council + Rangs 3+ | 66% | 10j |
| **TOKENOMICS** | Distribution, emissions, burns | Tous token holders | 60% | 14j |
| **MARKETPLACE** | Fees, algorithmes matching, reputation | Tous membres | 55% | 7j |

### 6.2. Décisions business typiques

**Exemples de propositions BUSINESS** :
- Cibler le marché européen vs américain en priorité
- Partenariat avec un cabinet de conseil classique (ex: Accenture)
- Pricing : augmenter les fees de 15% à 20%
- Lancer une offre "enterprise" avec support dédié
- Accepter des paiements en fiat (stripe integration)

**Processus** :
1. Membre rang 1+ soumet proposition avec business case détaillé
2. Discussion 7 jours (forum + Discord)
3. Vote tous membres (poids = rang)
4. Si >50% approval → adoption
5. Exécution par le Council (ou automatique si codable)

### 6.3. Décisions tokenomics critiques

**Exemples** :
- Modifier la distribution des revenus (actuellement 50/30/10/10)
- Changer le taux d'inflation (actuellement 2% annuel)
- Burn exceptionnel (ex: burn 10% supply pour augmenter valeur)
- Airdrop pour attirer nouveaux contributeurs

**Seuil élevé (60%)** car impact direct sur tous les token holders.

---

## 7. Propriété intellectuelle et royalties

### 7.1. Challenge de l'IP dans un DAO

**Question** : Qui possède les outputs d'une mission ? Le client ? Les contributeurs ? Le DAO ?

**Réponses possibles** :

| Modèle | Propriétaire | Avantages | Inconvénients |
|--------|--------------|-----------|---------------|
| **Client full ownership** | Client | Simple, standard marché | Contributeurs ne peuvent pas réutiliser |
| **DAO ownership** | DAO (licence au client) | DAO construit un patrimoine IP | Clients peuvent refuser |
| **Shared ownership** | Client + Contributeurs | Équitable | Complexe juridiquement |
| **Open source** | Public (licence MIT/Apache) | Attractif pour clients open-source | Pas de monétisation IP |

**Recommandation** : **Modèle hybride configurable par mission**

### 7.2. Modèle hybride configurable

**Paramètres définis dans le brief mission** :

```solidity
struct IPRights {
    address owner;              // Client, DAO, ou adresse custom
    uint8 clientUsageRights;    // 0-100% (100 = full ownership)
    uint8 daoRoyaltyRate;       // 0-50% (royalties sur réutilisation)
    bool openSource;            // Si true, outputs sous licence MIT
    string licenseURI;          // Lien vers licence custom
}
```

**Cas d'usage** :

#### Cas 1 : Client corporate (full ownership)
```
IPRights {
    owner: clientAddress,
    clientUsageRights: 100,
    daoRoyaltyRate: 0,
    openSource: false
}
```
- Client possède 100% des outputs
- DAO et contributeurs ne peuvent pas réutiliser sans permission

#### Cas 2 : Client startup (shared ownership + royalties)
```
IPRights {
    owner: daoAddress,
    clientUsageRights: 80,
    daoRoyaltyRate: 20,
    openSource: false
}
```
- Client peut utiliser les outputs librement (80% des droits)
- Si le DAO réutilise l'IP pour d'autres missions → 20% royalties au client
- Budget mission réduit (-30%) car client partage l'IP

#### Cas 3 : Projet open-source (MIT)
```
IPRights {
    owner: address(0),  // Public
    clientUsageRights: 100,
    daoRoyaltyRate: 0,
    openSource: true,
    licenseURI: "ipfs://Qm.../MIT-LICENSE"
}
```
- Outputs publiés sous licence MIT
- Tout le monde peut réutiliser
- Budget mission réduit (-50%) car client contribue au bien commun

### 7.3. Smart contract royalties

**Implémentation** : Chaque output (rapport, code, dataset) est enregistré on-chain avec un hash (IPFS).

```solidity
struct IPAsset {
    bytes32 contentHash;        // IPFS hash
    uint256 missionId;          // Mission d'origine
    IPRights rights;            // Droits définis ci-dessus
    uint256 createdAt;
    mapping(address => bool) licensees;  // Qui a payé une licence
}

function purchaseLicense(bytes32 assetHash) external payable {
    IPAsset storage asset = ipAssets[assetHash];
    require(!asset.licensees[msg.sender], "Already licensed");

    // Calcul prix licence (ex: 10% du budget original)
    uint256 licensePrice = missions[asset.missionId].budget / 10;
    require(msg.value >= licensePrice, "Insufficient payment");

    // Distribution royalties
    if (asset.rights.daoRoyaltyRate > 0) {
        uint256 royalty = licensePrice * asset.rights.daoRoyaltyRate / 100;
        payable(asset.rights.owner).transfer(royalty);  // Client original
        payable(daoTreasury).transfer(licensePrice - royalty);
    } else {
        payable(daoTreasury).transfer(licensePrice);
    }

    asset.licensees[msg.sender] = true;
}
```

**Cas d'usage** : Rapport de marché créé pour Client A est pertinent pour Client B.
- Client B achète une licence (10% du budget original)
- Client A reçoit 20% de royalties (si modèle shared ownership)
- DAO reçoit 80%

---

## 8. Cas d'usage : BCG décentralisé

### 8.1. Comparaison modèle classique vs DAO

**Boston Consulting Group (classique)** :

| Dimension | BCG Classique |
|-----------|---------------|
| **Structure** | Hiérarchie (Partner → Principal → Consultant → Analyst) |
| **Recrutement** | Sélectif (MBA top tier, tests rigoureux) |
| **Rémunération** | Salaire fixe + bonus (200k-500k USD/an pour Partner) |
| **Clients** | Entreprises Fortune 500, gouvernements |
| **Pricing** | Facture journalière (2k-10k USD/jour selon seniority) |
| **IP** | Propriété BCG, accumulée depuis 1963 |
| **Marque** | Réputation décennies, valeur immatérielle |

**BCG Décentralisé (DAO Services)** :

| Dimension | DAO Services |
|-----------|--------------|
| **Structure** | Réseau décentralisé (rangs 0-4 pondérés) |
| **Recrutement** | Méritocratie on-chain (contributions prouvées) |
| **Rémunération** | Par usage (50-800 USD/heure selon rang) + tokens |
| **Clients** | Startups, DAOs, PMEs, Fortune 500 (progressivement) |
| **Pricing** | Transparent on-chain (tarif selon rang + reputation) |
| **IP** | Partagée (modèle hybride configurable) |
| **Marque** | Réputation on-chain (reputation score public) |

### 8.2. Avantages compétitifs du modèle DAO

| Avantage | Description | Impact |
|----------|-------------|--------|
| **Coûts opérationnels faibles** | Pas de bureaux, pas de middle management | Prix -30% vs BCG |
| **Scalabilité** | Contributeurs ajoutés dynamiquement | Capacité infinie |
| **Transparence** | Tarifs, reputation, historique publics | Confiance clients |
| **Agents IA** | Augmentation capacités humaines | Productivité ×2-5 |
| **Paiement usage** | Clients paient que ce qu'ils consomment | Attractif PMEs |
| **Global talent pool** | Experts monde entier, pas de frontières | Meilleurs talents |

### 8.3. Services offerts (Phase 1)

**Portfolio services** (inspiré BCG) :

| Service | Description | Tarif moyen (DAOS) | Durée |
|---------|-------------|-------------------|-------|
| **Strategy consulting** | Business strategy, market entry, M&A | 5000-20000 | 2-8 semaines |
| **Digital transformation** | Architecture cloud, data strategy, IA | 3000-15000 | 1-6 semaines |
| **Operations improvement** | Optimisation supply chain, lean | 2000-10000 | 1-4 semaines |
| **Marketing strategy** | Go-to-market, branding, growth hacking | 1000-5000 | 1-3 semaines |
| **Financial modeling** | Projections, valuation, fundraising deck | 500-3000 | 1-2 semaines |
| **Tech audit** | Code review, security audit, due diligence | 1000-5000 | 1-2 semaines |

**Phase 2** : Services IA-first

| Service | Description | IA impliquée | Tarif (DAOS) |
|---------|-------------|--------------|-------------|
| **AI-powered market research** | Analyse marché automatisée (web scraping + GPT) | GPT-4 + Perplexity | 500-2000 |
| **Automated financial reports** | Génération rapports financiers depuis data | Claude 3.5 + Code | 300-1000 |
| **Instant competitor analysis** | Veille concurrentielle temps réel | Agent IA custom | 200-800 |
| **Predictive analytics** | Modèles ML prédictifs (churn, sales...) | AutoML + H100 | 2000-10000 |

### 8.4. Client journey

**Étape 1 : Découverte** (Website + Dashboard public)
- Client découvre le DAO via website ou referral
- Explore le marché : voir contributeurs disponibles, ratings, tarifs
- Pas besoin de wallet pour browsing

**Étape 2 : Inscription** (KYC optionnel)
- Client crée compte (email + password ou wallet Polkadot)
- KYC optionnel pour missions >10k DAOS (conformité)
- Achète tokens DAOS (fiat via Stripe ou crypto)

**Étape 3 : Briefing mission**
- Client remplit formulaire détaillé :
  - Contexte entreprise
  - Problème à résoudre
  - Livrables attendus
  - Budget max et deadline
  - Compétences requises
- Brief publié sur marché (public ou privé selon choix)

**Étape 4 : Matching et sélection**
- Algorithme suggère top 5 contributeurs
- Client peut aussi chercher manuellement (filtres : rang, reputation, spécialité)
- Contributeurs postulent ou sont invités
- Client sélectionne équipe (1-5 personnes généralement)

**Étape 5 : Kick-off**
- Appel visio de lancement (optionnel)
- Contributeurs accèdent aux documents (Google Drive, Notion partagé)
- Fonds déposés en escrow (smart contract)
- Travail commence

**Étape 6 : Exécution**
- Communication async (Discord, Slack)
- Updates hebdomadaires (standup on-chain optionnel)
- Client suit avancement via dashboard (heures loggées, milestones)

**Étape 7 : Livraison**
- Contributeurs déposent livrables (IPFS + hash on-chain)
- Client valide sous 48h ou demande révisions (1-2 rounds inclus)
- Validation → paiement automatique

**Étape 8 : Post-mission**
- Ratings mutuels (client ↔ contributeurs)
- Client peut réembaucher mêmes contributeurs (relation long terme)
- Accès aux outputs (selon IP rights)

---

## 9. Architecture smart contracts étendue

### 9.1. Nouveaux contrats (au-delà du design de base)

Le design de base définit : `DAOMembership`, `DAOGovernor`, `DAOTreasury`, `DAOIdentity`.

**Extensions requises** :

| Contrat | Rôle | Priorité |
|---------|------|----------|
| **ServiceMarketplace.sol** | Marché de services (offre/demande, matching) | P0 |
| **MissionEscrow.sol** | Escrow des fonds (missions actives) | P0 |
| **UsageMetering.sol** | Enregistrement usage (heures, tokens IA, compute) | P0 |
| **PaymentSplitter.sol** | Distribution automatique paiements | P0 |
| **ReputationOracle.sol** | Calcul et stockage reputation scores | P1 |
| **IPRegistry.sol** | Registre IP (assets, licences, royalties) | P1 |
| **ComputeMarketplace.sol** | Sous-marché GPU/CPU (providers + demandeurs) | P2 |
| **AIAgentRegistry.sol** | Registre agents IA disponibles (modèles, tarifs) | P2 |
| **DisputeResolution.sol** | Arbitrage disputes (client vs contributeur) | P2 |

### 9.2. Contrat clé : `ServiceMarketplace.sol`

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./DAOMembership.sol";
import "./MissionEscrow.sol";
import "./ReputationOracle.sol";

contract ServiceMarketplace {
    DAOMembership public membership;
    MissionEscrow public escrow;
    ReputationOracle public reputation;

    enum MissionStatus { Open, Assigned, Active, Completed, Disputed, Cancelled }

    struct Mission {
        uint256 id;
        address client;
        string briefURI;            // IPFS hash du brief
        uint256 budgetMax;          // En DAOS tokens
        uint256 deadline;           // Timestamp
        string[] requiredSkills;    // Tags compétences
        MissionStatus status;
        address[] contributors;     // Équipe assignée
        uint256 createdAt;
    }

    struct Application {
        address contributor;
        string proposalURI;         // IPFS hash de la proposition
        uint256 proposedBudget;
        uint256 appliedAt;
    }

    mapping(uint256 => Mission) public missions;
    mapping(uint256 => Application[]) public applications;
    uint256 public missionCount;

    event MissionPublished(uint256 indexed missionId, address indexed client, uint256 budget);
    event ApplicationSubmitted(uint256 indexed missionId, address indexed contributor);
    event MissionAssigned(uint256 indexed missionId, address[] contributors);
    event MissionCompleted(uint256 indexed missionId);

    constructor(address _membership, address _escrow, address _reputation) {
        membership = DAOMembership(_membership);
        escrow = MissionEscrow(_escrow);
        reputation = ReputationOracle(_reputation);
    }

    // Publier une nouvelle mission
    function publishMission(
        string calldata _briefURI,
        uint256 _budgetMax,
        uint256 _deadline,
        string[] calldata _requiredSkills
    ) external payable returns (uint256) {
        require(msg.value >= _budgetMax, "Insufficient escrow");

        uint256 missionId = missionCount++;
        missions[missionId] = Mission({
            id: missionId,
            client: msg.sender,
            briefURI: _briefURI,
            budgetMax: _budgetMax,
            deadline: _deadline,
            requiredSkills: _requiredSkills,
            status: MissionStatus.Open,
            contributors: new address[](0),
            createdAt: block.timestamp
        });

        // Transférer fonds à l'escrow
        escrow.deposit{value: msg.value}(missionId, msg.sender);

        emit MissionPublished(missionId, msg.sender, _budgetMax);
        return missionId;
    }

    // Postuler à une mission
    function applyToMission(
        uint256 _missionId,
        string calldata _proposalURI,
        uint256 _proposedBudget
    ) external {
        Mission storage mission = missions[_missionId];
        require(mission.status == MissionStatus.Open, "Mission not open");
        require(membership.members(msg.sender).active, "Not a DAO member");

        applications[_missionId].push(Application({
            contributor: msg.sender,
            proposalURI: _proposalURI,
            proposedBudget: _proposedBudget,
            appliedAt: block.timestamp
        }));

        emit ApplicationSubmitted(_missionId, msg.sender);
    }

    // Client assigne la mission à des contributeurs
    function assignMission(
        uint256 _missionId,
        address[] calldata _contributors
    ) external {
        Mission storage mission = missions[_missionId];
        require(msg.sender == mission.client, "Not client");
        require(mission.status == MissionStatus.Open, "Not open");

        // Vérifier que tous les contributeurs sont membres
        for (uint i = 0; i < _contributors.length; i++) {
            require(membership.members(_contributors[i]).active, "Contributor not member");
        }

        mission.status = MissionStatus.Assigned;
        mission.contributors = _contributors;

        emit MissionAssigned(_missionId, _contributors);
    }

    // Contributeur marque la mission comme complétée
    function completeMission(uint256 _missionId) external {
        Mission storage mission = missions[_missionId];
        require(mission.status == MissionStatus.Active, "Mission not active");
        require(isContributor(_missionId, msg.sender), "Not contributor");

        mission.status = MissionStatus.Completed;

        emit MissionCompleted(_missionId);
    }

    // Helper: vérifier si adresse est contributeur
    function isContributor(uint256 _missionId, address _addr) internal view returns (bool) {
        Mission storage mission = missions[_missionId];
        for (uint i = 0; i < mission.contributors.length; i++) {
            if (mission.contributors[i] == _addr) return true;
        }
        return false;
    }

    // Obtenir toutes les missions ouvertes
    function getOpenMissions() external view returns (Mission[] memory) {
        uint256 openCount = 0;
        for (uint256 i = 0; i < missionCount; i++) {
            if (missions[i].status == MissionStatus.Open) openCount++;
        }

        Mission[] memory openMissions = new Mission[](openCount);
        uint256 index = 0;
        for (uint256 i = 0; i < missionCount; i++) {
            if (missions[i].status == MissionStatus.Open) {
                openMissions[index] = missions[i];
                index++;
            }
        }

        return openMissions;
    }
}
```

---

## 10. Roadmap implémentation

### Phase 1 : MVP Marché (4-6 semaines)

**Objectif** : Marketplace fonctionnel avec paiements de base.

| Étape | Durée | Livrables |
|-------|-------|-----------|
| **Contrats smart** | 2 semaines | ServiceMarketplace, MissionEscrow, UsageMetering, PaymentSplitter |
| **Tests** | 1 semaine | Foundry tests (100% coverage) |
| **Frontend marché** | 2 semaines | Pages : Browse, Publish, Apply, Dashboard client/contributeur |
| **Déploiement testnet** | 3 jours | Paseo testnet |
| **Tests utilisateurs** | 1 semaine | 5-10 missions pilotes |

**Validation** :
- [ ] Client peut publier mission
- [ ] Contributeur peut postuler
- [ ] Client peut assigner équipe
- [ ] Paiement automatique fonctionne (sans metering avancé)

### Phase 2 : Metering & Tokenomics (6-8 semaines)

**Objectif** : Rétribution proportionnelle à l'usage + token DAOS.

| Étape | Durée | Livrables |
|-------|-------|-----------|
| **Token DAOS** | 1 semaine | ERC20 contract + distribution initiale |
| **Metering avancé** | 2 semaines | Tracking heures (app), tokens IA (API wrapper), compute (monitoring) |
| **Reputation Oracle** | 1 semaine | Calcul scores, ratings |
| **Payment Splitter v2** | 1 semaine | Distribution proportionnelle usage |
| **DEX listing** | 2 semaines | Uniswap v3 pool DAOS/USDC |
| **Governance tracks** | 1 semaine | Ajout tracks BUSINESS, TOKENOMICS, MARKETPLACE |

**Validation** :
- [ ] Token DAOS tradable sur Uniswap
- [ ] Missions utilisent metering (heures + IA + compute)
- [ ] Paiements distribués proportionnellement
- [ ] Reputation scores à jour

### Phase 3 : IA & Compute (8-12 semaines)

**Objectif** : Intégration agents IA et marché compute.

| Étape | Durée | Livrables |
|-------|-------|-----------|
| **AI Agent Registry** | 2 semaines | Registre modèles IA, API wrappers |
| **Compute Marketplace** | 3 semaines | Marché GPU/CPU, providers, monitoring |
| **IP Registry** | 2 semaines | Enregistrement assets, licences, royalties |
| **Dispute Resolution** | 2 semaines | Arbitrage on-chain (Council vote) |
| **Analytics dashboard** | 2 semaines | Métriques business (revenus, missions, utilisation) |

**Validation** :
- [ ] Agent IA utilisé dans une mission (metering tokens)
- [ ] Compute GPU loué pour une mission
- [ ] Licence IP achetée avec royalties payées
- [ ] Dispute arbitrée par le Council

### Phase 4 : Scale & Parachain (6-12 mois)

**Objectif** : Migration parachain + scale international.

| Étape | Durée | Livrables |
|-------|-------|-----------|
| **Runtime Substrate** | 2 mois | Pallets custom (marketplace, metering, reputation) |
| **Token natif** | 1 mois | Tokenomics complète, staking, dividendes |
| **XCM bridges** | 1 mois | Interopérabilité Ethereum, autres parachains |
| **Audit sécurité** | 1 mois | Audit externe runtime + contrats |
| **KYC/Compliance** | 2 mois | Intégration KYC provider (Deloitte, Fractal) |
| **Marketing & Growth** | 3 mois | Onboarding 100+ contributeurs, 50+ clients |
| **Déploiement production** | 1 mois | Polkadot mainnet |

**Validation** :
- [ ] Parachain opérationnelle sur Polkadot
- [ ] 100+ contributeurs actifs
- [ ] 50+ clients payants
- [ ] Revenus >50k DAOS/mois

---

## Conclusion

Ce document étend le [design de base](../04-design/polkadot-dao-design.md) pour créer une **organisation décentralisée de prestation de services** complète, inspirée du modèle BCG mais blockchain-native.

**Points clés** :
- **Théorie de la firme revisitée** : Smart contracts réduisent les coûts de transaction à ≈0, permettant une coordination décentralisée de contributeurs autonomes (humains + IA + compute).
- **Tokenomics** : Token utilitaire DAOS pour paiements, gouvernance, staking. Distribution revenus automatique (50% treasury, 30% stakers, 10% burn, 10% LPs).
- **Marché de services** : Matching automatique offre/demande, escrow, metering usage, paiement automatique, reputation on-chain.
- **Rétribution hybride** : Contributeurs (humains, IA, compute) payés proportionnellement à leur usage dans chaque mission.
- **Gouvernance étendue** : 6 tracks (TECHNIQUE, BUSINESS, MARKETING, LEGAL, TOKENOMICS, MARKETPLACE) pour décisions multi-domaines.
- **IP & Royalties** : Modèle hybride configurable par mission (client full ownership, shared, ou open-source).
- **BCG décentralisé** : Portfolio services (strategy, digital transformation, operations...) avec tarifs transparents et contributeurs globaux.

**Next steps** : Implémentation Phase 1 (MVP Marché, 4-6 semaines).

---

**Date de création** : 2026-02-08
**Version** : 1.0.0
**Dépend de** : polkadot-dao-design.md (architecture de base)
