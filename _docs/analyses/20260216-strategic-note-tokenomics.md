# Note stratégique : Tokenomics détaillée

**Date** : 2026-02-16
**Axe** : Conception des tokens de gouvernance et d'utilité
**Horizon** : M0 → M24

---

## 1. Contexte et enjeux

Le choix du modèle de tokenomics conditionne l'intégralité de la gouvernance. Un mauvais design reproduit exactement les travers des cabinets traditionnels : concentration du pouvoir, opacité, conflits d'intérêts. Le taux de participation moyen dans les DAOs existantes est alarmant (0,79% en moyenne sur Decentraland, 0,16% en médiane). La tokenomics doit contrer structurellement cette apathie.

**Sources** :
- [Frontiers in Blockchain — DAO Governance Challenges](https://www.frontiersin.org/journals/blockchain/articles/10.3389/fbloc.2025.1538227/full)
- [SSRN — Reputation Tokenomics: DAO Governance Design](https://papers.ssrn.com/sol3/papers.cfm?abstract_id=5018833)

---

## 2. Architecture à deux tokens

Le consensus académique et industriel 2025-2026 converge vers une séparation valeur / gouvernance via un modèle dual-token.

### Token 1 : REP (Réputation) — Soulbound, non transférable

| Caractéristique | Détail | Justification |
|----------------|--------|---------------|
| **Nature** | Soulbound Token (SBT) — non transférable, non achetable | Élimine la ploutocratie : impossible d'acheter du pouvoir de vote |
| **Émission** | Automatique à chaque mission complétée + évaluation client | Lie la gouvernance à la contribution réelle |
| **Poids de vote** | Vote quadratique : coût du nème vote = n² tokens REP | Réduit l'influence disproportionnée des gros contributeurs |
| **Décroissance** | -10% par an si inactivité (aucune mission livrée) | Force l'engagement continu, empêche les "rentiers" |
| **Plafond** | Max 100 REP par consultant | Évite la concentration même pour les plus anciens |
| **Standard technique** | ERC-5484 (Consensual SBT) sur Polygon | Faibles coûts gas, écosystème mature |

**Sources** :
- [Vitalik Buterin — Soulbound (2022)](https://vitalik.ca/general/2022/01/26/soulbound.html)
- [CoinGecko — Soulbound Tokens Guide](https://www.coingecko.com/learn/soulbound-tokens-sbt)

**Mécanisme d'émission REP** :

```
Mission livrée
    |
    |-- NPS client >= 8/10        -> +5 REP
    |-- KPIs atteints >= 100%     -> +3 REP
    |-- Participation vote DAO    -> +1 REP / vote
    |-- Proposition adoptée       -> +2 REP
    +-- Mentorat junior validé    -> +2 REP
```

### Token 2 : CRED (Crédits mission) — Utilitaire, transférable en interne

| Caractéristique | Détail | Justification |
|----------------|--------|---------------|
| **Nature** | Token utilitaire (pas financier) — accès aux missions et ressources | Évite la qualification réglementaire de titre financier |
| **Obtention** | Achat par le client lors de la contractualisation mission | Flux financier classique, pas de spéculation |
| **Usage** | 1 CRED = 1h de travail consultant (unité de compte interne) | Transparence facturation absolue |
| **Destruction** | Burn à la consommation (heures effectuées) | Pas d'inflation, pas de marché secondaire |
| **Conversion** | CRED -> EUR via smart contract (paiement consultant) | Traçabilité complète du flux financier |

### Vote quadratique — Fonctionnement détaillé

Validé à grande échelle par Gitcoin (50M$ distribués, 10 000 contributeurs uniques par round).

| REP engagés | Votes obtenus | Coût marginal du vote | Effet |
|-------------|---------------|----------------------|-------|
| 1 | 1 | 1 REP | Accessibilité maximale |
| 4 | 2 | 3 REP | Influence modérée |
| 9 | 3 | 5 REP | Désincentive la domination |
| 16 | 4 | 7 REP | Barrière naturelle anti-ploutocratie |
| 25 | 5 | 9 REP | Plafond pratique d'influence |

**Protection anti-Sybil** : Identité vérifiée via KYC professionnel (LinkedIn + vérification cabinet comptable). Un consultant = un wallet = un "Soul". Modèle Gitcoin Passport avec badges NFT de preuve d'identité.

**Sources** :
- [Stanford Research — Sybil Resistance in Quadratic Voting](https://purl.stanford.edu/hj860vc2584)
- [Gitcoin Blog — Grants 23 Retro](https://www.gitcoin.co/blog/gitcoin-grants-23-retro)
- [Gitcoin Governance — Anti-Sybil Flywheel](https://gov.gitcoin.co/t/the-gitcoin-anti-sybil-flywheel/9417)

---

## 3. Priorités opérationnelles

| Priorité | Action | Effort | Prérequis |
|----------|--------|--------|-----------|
| **P0** | Spécifier le contrat ERC-5484 (REP soulbound) | 2-3 semaines dev | Audit juridique Token != titre financier |
| **P0** | Définir la grille d'émission REP (missions, votes, mentorat) | 1 semaine | Consensus fondateurs sur critères |
| **P1** | Implémenter le vote quadratique sur Snapshot | 1-2 semaines | REP déployé sur Polygon |
| **P1** | Déployer CRED comme token utilitaire (ERC-20 simple) | 1 semaine | Smart contract audité |
| **P2** | Mécanisme de décroissance REP annuel | 1 semaine | Cron on-chain ou Chainlink Automation |
| **P2** | Dashboard public de distribution REP | 2 semaines | Frontend connecté The Graph |

---

## 4. Quick wins

| Quick win | Horizon | Impact immédiat | Coût |
|-----------|---------|-----------------|------|
| **Prototype Snapshot** (votes off-chain, gratuit, sans gas) | Semaine 1 | Démonstration immédiate de la gouvernance participative aux prospects | 0 EUR |
| **Grille REP publique** (tableau simple des critères d'émission) | Semaine 2 | Transparence totale sur "qui gagne du pouvoir et pourquoi" — argument commercial massif | 0 EUR |
| **Simulation vote quadratique** (tableur partagé, 10 consultants pilotes) | Semaine 3 | Valider empiriquement que la ploutocratie est éliminée avant le développement | 0 EUR |

---

## 5. Horizon temporel par maturité

| Phase projet | Maturité tokenomics | Technologie |
|-------------|---------------------|-------------|
| **M0-M3** (fondations) | Vote Snapshot off-chain + REP manuels (tableur) | Aucune blockchain nécessaire |
| **M3-M6** (pilote) | REP on-chain Polygon + Snapshot connecté | ERC-5484 déployé, coût gas ~0,01 EUR/tx |
| **M6-M12** (clients) | CRED déployé + vote quadratique actif | Smart contracts audités par tiers |
| **M12-M18** (écosystème) | Sous-DAOs sectorielles avec REP cross-domain | Governance framework complet |
| **M18-M24** (maturité) | Décroissance REP active + analytics avancés | The Graph + Dashboard public |
