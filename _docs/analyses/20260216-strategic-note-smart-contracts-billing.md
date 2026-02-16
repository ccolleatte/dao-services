# Note stratégique : Smart contracts de facturation conditionnelle

**Date** : 2026-02-16
**Axe** : Facturation liée aux résultats via escrow et oracles
**Horizon** : M0 -> M24

---

## 1. Contexte et enjeux

Le grief central contre les consultants traditionnels ("ROI non prouvé") exige un mécanisme où le paiement est structurellement lié aux résultats. Les smart contracts d'escrow conditionnels répondent à ce besoin : les termes sont codifiés, les données vérifiées par oracle, et le paiement libéré automatiquement.

**Principe** : "Release funds if and only if KPIs verified by oracle reach predefined thresholds" — sans intervention humaine, sans contestation possible, sans délai.

**Sources** :
- [Secured Trust Escrow — Smart Contract M&A](https://securedtrustescrow.com/smart-contract-escrow-the-future-of-ma-transactions/)
- [Chainlink — Blockchain Oracles](https://chain.link/education/blockchain-oracles)

---

## 2. Architecture technique

```
Client signe contrat
        |
        v
+-------------------------------+
|   SMART CONTRACT ESCROW       |
|   (Gnosis Safe + Module)      |
|                               |
|  40% libéré immédiatement     |<-- Tranche 1 : Cadrage/Diagnostic
|    (milestone: livraison)     |
|                               |
|  30% conditionné KPIs         |<-- Tranche 2 : Performance
|    (oracle vérifie atteinte)  |
|                               |
|  20% bonus si >115% KPIs      |<-- Tranche 3 : Surperformance
|    (calcul automatique)       |
|                               |
|  10% retenue 6 mois           |<-- Tranche 4 : Pérennité
|    (timer + KPIs maintenus)   |
+---------------+---------------+
                |
                v
+-------------------------------+
|   ORACLE CHAINLINK            |
|                               |
|  Vérifie KPIs depuis :        |
|  - API client (CRM, ERP)     |
|  - Dashboard analytics        |
|  - Données financières        |
|                               |
|  Fréquence : hebdomadaire     |
|  Consensus : 3 noeuds min     |
+-------------------------------+
```

### Détail des tranches

| Tranche | % | Condition de libération | Mécanisme technique | Délai |
|---------|---|------------------------|---------------------|-------|
| **T1 — Cadrage** | 40% | Livraison livrables validée (signature client on-chain) | Multi-sig 2/3 (client + consultant + tiers) | J+7 après livraison |
| **T2 — Performance** | 30% | KPIs contractuels atteints >= 100% | Oracle Chainlink vérifie données API client | Deadline contractuelle (ex: M+6) |
| **T3 — Bonus** | 20% | KPIs dépassés >= 115% | Calcul automatique par smart contract | Même deadline que T2 |
| **T4 — Pérennité** | 10% | KPIs maintenus 6 mois post-mission | Timer on-chain + vérification oracle | M+12 après début mission |

### Vérification KPI par oracle

Chainlink fonctionne comme un messager de confiance : il écoute des événements spécifiques, récupère les données réelles depuis des sources externes, et les injecte dans le smart contract de manière vérifiable et inaltérable.

**Processus de vérification** :

| Étape | Acteur | Action | Garantie |
|-------|--------|--------|----------|
| 1 | Client + Consultant | Co-définissent KPIs mesurables + sources de données lors du cadrage | KPIs non ambigus, vérifiables |
| 2 | Développeur | Configure l'oracle Chainlink pour requêter les APIs sources | Automatisation totale |
| 3 | Oracle (3 noeuds min) | Agrège données multi-sources, calcule médiane | Résistant à la manipulation |
| 4 | Smart contract | Compare KPI vérifié vs seuil contractuel | Exécution déterministe, pas de contestation |
| 5 | Gnosis Safe | Libère fonds si condition remplie | Multi-sig pour sécurité supplémentaire |

**Source** : [Chainlink — Smart Contracts & External Data](https://chain.link/article/smart-contracts-external-data)

### Exemples de KPIs vérifiables par oracle

| Type de mission | KPI | Source de données | Mesurabilité |
|----------------|-----|-------------------|--------------|
| Optimisation commerciale | +15% CA trimestriel | API ERP client (Salesforce, SAP) | Haute |
| Transformation digitale | Taux d'adoption outil >= 80% | Analytics plateforme (Mixpanel, Amplitude) | Haute |
| Réduction coûts | -10% charges opérationnelles | Comptabilité client (API comptable) | Haute |
| Satisfaction client | NPS >= +20 points | API enquêtes (Typeform, SurveyMonkey) | Moyenne |
| Performance RH | Turnover <= 8% | SIRH client (API BambooHR, Workday) | Haute |

### Gestion des cas limites

| Cas limite | Traitement | Mécanisme |
|-----------|------------|-----------|
| **KPI non atteint à la deadline** | T2 retournée au client (escrow expire) | Timer on-chain + refund automatique |
| **Données oracle indisponibles** | Prolongation 30 jours + fallback multi-sig 2/3 | Circuit de secours contractuel |
| **Contestation client sur données** | Arbitrage on-chain (3 arbitres élus par DAO) | Dispute resolution protocol |
| **Force majeure** | Libération proportionnelle au prorata d'avancement | Vote multi-sig 2/3 exceptionnel |
| **KPI partiellement atteint** (85% au lieu de 100%) | Libération proportionnelle : 85% x montant T2 | Calcul linéaire par smart contract |

---

## 3. Priorités opérationnelles

| Priorité | Action | Effort | Prérequis |
|----------|--------|--------|-----------|
| **P0** | Définir catalogue de KPIs vérifiables par type de mission (5 types) | 1 semaine | Expérience missions passées |
| **P0** | Spécifier le smart contract escrow (tranches, conditions, timeouts) | 2 semaines dev | Catalogue KPIs validé |
| **P1** | Configurer oracle Chainlink pour 3 sources de données courantes (CRM, analytics, comptabilité) | 2-3 semaines | Smart contract déployé testnet |
| **P1** | Audit sécurité smart contract par tiers spécialisé | 2-3 semaines, budget 5-15K EUR | Contract finalisé |
| **P2** | Interface client dashboard temps réel (KPIs + état tranches) | 3-4 semaines frontend | Oracle + contract opérationnels |
| **P2** | Protocole d'arbitrage on-chain (dispute resolution) | 2 semaines | Règlement intérieur DAO adopté |
| **P3** | Intégration APIs additionnelles (SIRH, ERP, CRM niches) | Continu | Demande client effective |

---

## 4. Quick wins

| Quick win | Horizon | Impact | Coût |
|-----------|---------|--------|------|
| **Escrow Gnosis Safe simple** (multi-sig 2/3, sans oracle) — client dépose, libération manuelle sur validation mutuelle | Semaine 1-2 | Transparence immédiate : le client voit ses fonds en escrow on-chain, libération traçable | 0 EUR (Gnosis Safe gratuit) |
| **Contrat-type avec clause de facturation conditionnelle** (juridique classique, exécution manuelle) | Semaine 2-3 | Argument commercial immédiat : "30% de nos honoraires sont conditionnés à vos résultats" | Coût avocat seul |
| **Prototype dashboard KPI** (Google Sheets connecté aux données client, pas encore on-chain) | Semaine 3-4 | Démonstration du concept de transparence temps réel sans infrastructure blockchain | 0 EUR |

---

## 5. Horizon temporel par maturité

| Phase | Maturité smart contract | Niveau d'automatisation |
|-------|------------------------|------------------------|
| **M0-M3** | Escrow Gnosis Safe manuel (multi-sig 2/3, pas d'oracle) | 20% — Libération validée à la main |
| **M3-M6** | Smart contract escrow avec tranches temporelles (timer) | 50% — T1 et T4 automatiques, T2/T3 manuels |
| **M6-M12** | Oracle Chainlink connecté pour 3 types de KPIs | 80% — T2/T3 automatisés pour missions standards |
| **M12-M18** | Catalogue élargi d'APIs + arbitrage on-chain | 90% — Quasi-totalité des missions automatisées |
| **M18-M24** | Machine learning sur corrélation KPIs / facturation | 95% — Self-improving |
