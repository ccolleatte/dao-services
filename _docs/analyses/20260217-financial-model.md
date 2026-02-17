# Modèle Financier : Projections M0-M12

**Date** : 2026-02-17
**Hypothèses** : Basées sur les données marché (analyse concurrentielle 20260216), l'état du code, et les benchmarks Malt/Upwork
**Méthode** : 3 scénarios (pessimiste, réaliste, optimiste) avec identification du breakeven

---

## 1. Hypothèses Structurelles

### Revenus

| Source de revenus | Taux | Activation | Notes |
|-------------------|------|------------|-------|
| Commission marketplace (côté client) | 5% du budget mission | M0 | Seule source M0-M3 |
| Commission marketplace (côté consultant) | 0% | — | Argument d'acquisition, non monétisable |
| Licences livrables tokenisés (Parcours C) | 50% pour la DAO (20% Treasury + 10% curateurs + 20% client) | M4+ | Conditionné à la validation du Parcours C |
| Services premium (formation, intégration IA) | 500-2 000 EUR/prestation | M3+ | Optionnel, low-touch |
| Treasury proposal Polkadot | Variable | M6+ | Non garanti, dépendant de OpenGov |

### Coûts

| Poste | Montant mensuel | Notes |
|-------|-----------------|-------|
| Hébergement infra (Supabase, RPC nodes, IPFS) | 100-500 EUR | Scale avec usage |
| Gas fees Polkadot (Agile Coretime) | 50-200 EUR | ~0,01 EUR/transaction |
| Domaine + DNS + monitoring | 50 EUR | Fixe |
| Outils SaaS (GitHub, Vercel, analytics) | 100-200 EUR | Tiers gratuits possibles M0-M3 |
| Juridique (avocat + comptable) | 500-1 000 EUR (amortissement) | Pic M0-M3 puis maintenance |
| RC Pro | 125-250 EUR (amortissement annuel) | 1 500-3 000 EUR/an |
| Marketing (M3+) | 0-5 000 EUR | 0 M0-M3, puis croissant |
| **Développement** | **Bénévolat/fondateurs M0-M6** | Pas de salaires avant Gate 2 |

**Hypothèse critique** : Pas de salaires M0-M6. Les fondateurs/développeurs travaillent sans rémunération jusqu'à Gate 2. C'est réaliste pour un projet early-stage mais constitue un risque de rétention si la traction tarde.

---

## 2. Scénario Pessimiste : "Validation Lente"

**Hypothèse** : Adoption lente, Parcours B (agents IA) non validé, focus exclusif Parcours A.

### Métriques opérationnelles

| Mois | Missions/mois | Budget moyen | GMV mensuel | Consultants actifs | Clients actifs |
|------|--------------|-------------|-------------|-------------------|----------------|
| M1 | 1 | 5 000 EUR | 5 000 EUR | 3 | 1 |
| M2 | 2 | 6 000 EUR | 12 000 EUR | 5 | 2 |
| M3 | 3 | 7 000 EUR | 21 000 EUR | 8 | 3 |
| M4 | 4 | 7 000 EUR | 28 000 EUR | 10 | 4 |
| M5 | 5 | 8 000 EUR | 40 000 EUR | 12 | 5 |
| M6 | 6 | 8 000 EUR | 48 000 EUR | 15 | 6 |
| M7 | 7 | 8 000 EUR | 56 000 EUR | 18 | 7 |
| M8 | 8 | 8 000 EUR | 64 000 EUR | 20 | 8 |
| M9 | 9 | 9 000 EUR | 81 000 EUR | 22 | 9 |
| M10 | 10 | 9 000 EUR | 90 000 EUR | 25 | 10 |
| M11 | 11 | 9 000 EUR | 99 000 EUR | 28 | 11 |
| M12 | 12 | 10 000 EUR | 120 000 EUR | 30 | 12 |

### P&L Pessimiste

| Mois | Revenus (5% GMV) | Coûts fixes | Coûts marketing | Résultat net | Cumul |
|------|-----------------|-------------|-----------------|-------------|-------|
| M1 | 250 EUR | 825 EUR | 0 EUR | **-575 EUR** | -575 EUR |
| M2 | 600 EUR | 825 EUR | 0 EUR | **-225 EUR** | -800 EUR |
| M3 | 1 050 EUR | 925 EUR | 0 EUR | **+125 EUR** | -675 EUR |
| M4 | 1 400 EUR | 925 EUR | 1 000 EUR | **-525 EUR** | -1 200 EUR |
| M5 | 2 000 EUR | 925 EUR | 1 500 EUR | **-425 EUR** | -1 625 EUR |
| M6 | 2 400 EUR | 925 EUR | 2 000 EUR | **-525 EUR** | -2 150 EUR |
| M7 | 2 800 EUR | 925 EUR | 2 500 EUR | **-625 EUR** | -2 775 EUR |
| M8 | 3 200 EUR | 925 EUR | 2 500 EUR | **-225 EUR** | -3 000 EUR |
| M9 | 4 050 EUR | 925 EUR | 3 000 EUR | **+125 EUR** | -2 875 EUR |
| M10 | 4 500 EUR | 925 EUR | 3 000 EUR | **+575 EUR** | -2 300 EUR |
| M11 | 4 950 EUR | 925 EUR | 3 000 EUR | **+1 025 EUR** | -1 275 EUR |
| M12 | 6 000 EUR | 925 EUR | 3 500 EUR | **+1 575 EUR** | +300 EUR |

**Breakeven opérationnel** : M12 (hors juridique initial)
**Cash needed** : ~3 000 EUR max de trésorerie négative (M8)
**GMV annuel** : ~663 000 EUR
**Revenu annuel** : ~33 200 EUR

**Verdict** : Le projet survit mais ne génère pas assez pour rémunérer une équipe. Si à M6 le rythme est < 6 missions/mois, il faut pivoter ou chercher du financement.

---

## 3. Scénario Réaliste : "Traction Progressive"

**Hypothèse** : Parcours A validé M1, Parcours B (agents IA) validé M3, croissance organique + paid M3+.

### Métriques opérationnelles

| Mois | Missions classiques | Missions IA | Total missions | Budget moyen | GMV mensuel |
|------|-------------------|-------------|----------------|-------------|-------------|
| M1 | 1 | 0 | 1 | 6 000 EUR | 6 000 EUR |
| M2 | 3 | 0 | 3 | 7 000 EUR | 21 000 EUR |
| M3 | 4 | 1 | 5 | 7 000 EUR | 35 000 EUR |
| M4 | 5 | 3 | 8 | 6 000 EUR | 48 000 EUR |
| M5 | 6 | 5 | 11 | 5 500 EUR | 60 500 EUR |
| M6 | 8 | 7 | 15 | 5 000 EUR | 75 000 EUR |
| M7 | 9 | 10 | 19 | 5 000 EUR | 95 000 EUR |
| M8 | 10 | 13 | 23 | 5 000 EUR | 115 000 EUR |
| M9 | 11 | 16 | 27 | 5 000 EUR | 135 000 EUR |
| M10 | 12 | 20 | 32 | 5 000 EUR | 160 000 EUR |
| M11 | 13 | 24 | 37 | 5 000 EUR | 185 000 EUR |
| M12 | 15 | 28 | 43 | 5 000 EUR | 215 000 EUR |

**Note** : Le budget moyen baisse car les missions IA sont moins chères (1 000-3 000 EUR vs 8 000-15 000 EUR pour les classiques). Mais le volume compense.

### Revenus additionnels (Parcours C : licences livrables)

| Mois | Livrables disponibles | Licences vendues/mois | Prix moyen licence | Revenus licences |
|------|----------------------|-----------------------|-------------------|-----------------|
| M1-M4 | 0 | 0 | — | 0 EUR |
| M5 | 5 | 1 | 200 EUR | 200 EUR |
| M6 | 12 | 3 | 200 EUR | 600 EUR |
| M7 | 20 | 5 | 250 EUR | 1 250 EUR |
| M8 | 30 | 8 | 250 EUR | 2 000 EUR |
| M9 | 42 | 12 | 250 EUR | 3 000 EUR |
| M10 | 55 | 16 | 300 EUR | 4 800 EUR |
| M11 | 70 | 20 | 300 EUR | 6 000 EUR |
| M12 | 88 | 25 | 300 EUR | 7 500 EUR |

### P&L Réaliste

| Mois | Rev. commission | Rev. licences | Rev. total | Coûts fixes | Marketing | Résultat net | Cumul |
|------|----------------|--------------|-----------|-------------|-----------|-------------|-------|
| M1 | 300 EUR | 0 | 300 EUR | 825 EUR | 0 | **-525 EUR** | -525 EUR |
| M2 | 1 050 EUR | 0 | 1 050 EUR | 825 EUR | 0 | **+225 EUR** | -300 EUR |
| M3 | 1 750 EUR | 0 | 1 750 EUR | 925 EUR | 0 | **+825 EUR** | +525 EUR |
| M4 | 2 400 EUR | 0 | 2 400 EUR | 925 EUR | 1 500 EUR | **-25 EUR** | +500 EUR |
| M5 | 3 025 EUR | 200 | 3 225 EUR | 925 EUR | 2 000 EUR | **+300 EUR** | +800 EUR |
| M6 | 3 750 EUR | 600 | 4 350 EUR | 925 EUR | 3 000 EUR | **+425 EUR** | +1 225 EUR |
| M7 | 4 750 EUR | 1 250 | 6 000 EUR | 1 125 EUR | 3 500 EUR | **+1 375 EUR** | +2 600 EUR |
| M8 | 5 750 EUR | 2 000 | 7 750 EUR | 1 125 EUR | 4 000 EUR | **+2 625 EUR** | +5 225 EUR |
| M9 | 6 750 EUR | 3 000 | 9 750 EUR | 1 125 EUR | 4 000 EUR | **+4 625 EUR** | +9 850 EUR |
| M10 | 8 000 EUR | 4 800 | 12 800 EUR | 1 125 EUR | 4 500 EUR | **+7 175 EUR** | +17 025 EUR |
| M11 | 9 250 EUR | 6 000 | 15 250 EUR | 1 125 EUR | 4 500 EUR | **+9 625 EUR** | +26 650 EUR |
| M12 | 10 750 EUR | 7 500 | 18 250 EUR | 1 125 EUR | 5 000 EUR | **+12 125 EUR** | +38 775 EUR |

**Breakeven opérationnel** : M2-M3
**Cash max négatif** : ~525 EUR (M1)
**GMV annuel** : ~1 150 000 EUR
**Revenu annuel** : ~82 825 EUR (commissions + licences)
**Marge nette M12** : ~66% (avant salaires)

**Verdict** : Le projet est rentable opérationnellement dès M3, mais les revenus ne permettent de rémunérer 1 personne à temps plein qu'à partir de M7-M8 (~6 000 EUR/mois de revenus). Les licences de livrables deviennent le principal moteur de croissance à partir de M10.

---

## 4. Scénario Optimiste : "Product-Market Fit Rapide"

**Hypothèse** : Parcours A + B validés rapidement, viral loop via consultants satisfaits, Treasury proposal Polkadot acceptée M6.

### Métriques opérationnelles

| Mois | Total missions | Budget moyen | GMV mensuel | Revenus totaux |
|------|----------------|-------------|-------------|----------------|
| M1 | 2 | 8 000 EUR | 16 000 EUR | 800 EUR |
| M2 | 5 | 7 000 EUR | 35 000 EUR | 1 750 EUR |
| M3 | 10 | 6 000 EUR | 60 000 EUR | 3 500 EUR |
| M4 | 18 | 5 500 EUR | 99 000 EUR | 5 950 EUR |
| M5 | 28 | 5 000 EUR | 140 000 EUR | 9 500 EUR |
| M6 | 40 | 5 000 EUR | 200 000 EUR | 14 500 EUR |
| M7 | 55 | 5 000 EUR | 275 000 EUR | 21 250 EUR |
| M8 | 70 | 5 000 EUR | 350 000 EUR | 28 500 EUR |
| M9 | 85 | 5 000 EUR | 425 000 EUR | 36 750 EUR |
| M10 | 100 | 5 000 EUR | 500 000 EUR | 45 000 EUR |
| M11 | 115 | 5 000 EUR | 575 000 EUR | 53 750 EUR |
| M12 | 130 | 5 000 EUR | 650 000 EUR | 62 500 EUR |

(Revenus totaux incluent commissions 5% + licences livrables croissantes)

**GMV annuel** : ~3 325 000 EUR
**Revenu annuel** : ~283 750 EUR
**Breakeven opérationnel** : M1

**Verdict** : Ce scénario justifie l'embauche de 2-3 personnes à M6 et la levée de fonds / Treasury proposal. C'est le scénario qui valide la migration Substrate (>100 missions/jour atteint vers M11).

---

## 5. Investissement Initial et Runway

### Coûts one-shot (hors développement)

| Poste | Montant | Timing |
|-------|---------|--------|
| Consultation avocat Web3 | 500-800 EUR | M0 Semaine 1 |
| Création SAS (statuts + immatriculation) | 2 200-4 300 EUR | M0-M1 |
| RC Pro (année 1) | 1 500-3 000 EUR | M1 |
| Audit sécurité Solidity (pré-mainnet) | 5 000-15 000 EUR | M3-M4 |
| Audit backend (léger) | 3 000-5 000 EUR | M3 |
| Enregistrement PSAN (si nécessaire) | 3 000-5 000 EUR | M3-M4 |
| **Total one-shot** | **15 200 - 33 100 EUR** | M0-M4 |

### Runway par scénario (hors salaires)

| Scénario | Cash nécessaire M0-M6 | Cash généré M0-M12 | Résultat net M12 |
|----------|----------------------|--------------------|--------------------|
| **Pessimiste** | ~18 000 - 36 000 EUR (one-shot + pertes) | ~33 200 EUR | ~+300 EUR |
| **Réaliste** | ~15 700 - 33 600 EUR (one-shot seulement) | ~82 825 EUR | ~+38 775 EUR |
| **Optimiste** | ~15 200 - 33 100 EUR (one-shot seulement) | ~283 750 EUR | ~+230 000 EUR |

### Besoin de financement

| Scénario | Financement externe nécessaire | Source recommandée |
|----------|-------------------------------|--------------------|
| **Pessimiste** | 30 000 - 40 000 EUR | Apport fondateurs ou love money |
| **Réaliste** | 15 000 - 35 000 EUR | Apport fondateurs (couvre le one-shot) |
| **Optimiste** | 15 000 - 35 000 EUR | Apport fondateurs → autofinancement M3+ |

**Point critique** : Dans tous les scénarios, il faut ~15 000-35 000 EUR de cash initial pour les frais juridiques, RC Pro et audits. C'est le ticket d'entrée incompressible.

---

## 6. Métriques de Pilotage (KPIs Mensuels)

### KPIs Activité

| KPI | Formule | Cible M3 | Cible M6 | Cible M12 | Alerte si |
|-----|---------|----------|----------|-----------|-----------|
| **Missions complétées / mois** | Compteur | 5 | 15 | 43 | < 50% de la cible |
| **GMV mensuel** | Sum(budgets) | 35k EUR | 75k EUR | 215k EUR | < 50% de la cible |
| **Taux de conversion brief → mission** | Missions / briefs | ≥ 40% | ≥ 50% | ≥ 60% | < 25% |
| **Taux de complétion** | Complétées / démarrées | ≥ 80% | ≥ 85% | ≥ 90% | < 70% |

### KPIs Financiers

| KPI | Formule | Cible M3 | Cible M6 | Cible M12 | Alerte si |
|-----|---------|----------|----------|-----------|-----------|
| **Revenu mensuel** | 5% GMV + licences | 1 750 EUR | 4 350 EUR | 18 250 EUR | < breakeven |
| **Marge opérationnelle** | (Rev - Coûts) / Rev | > 0% | > 10% | > 50% | Négatif 3 mois consécutifs |
| **CAC** (coût acquisition client) | Marketing / nouveaux clients | < 500 EUR | < 300 EUR | < 200 EUR | > 1 000 EUR |
| **LTV** (lifetime value client) | Rev moyen × durée relation | > 500 EUR | > 2 000 EUR | > 5 000 EUR | < 2× CAC |
| **Ratio LTV/CAC** | LTV / CAC | > 2 | > 3 | > 5 | < 2 |

### KPIs Satisfaction

| KPI | Formule | Cible M3 | Cible M6 | Cible M12 | Alerte si |
|-----|---------|----------|----------|-----------|-----------|
| **NPS client** | Enquête post-mission | ≥ 7 | ≥ 8 | ≥ 8 | < 6 |
| **NPS consultant** | Enquête post-mission | ≥ 7 | ≥ 8 | ≥ 9 | < 6 |
| **Churn consultant** | Départs / actifs | < 20% | < 15% | < 10% | > 25% |
| **Taux participation gouvernance** | Votants / éligibles | ≥ 30% | ≥ 50% | ≥ 70% | < 20% |

---

## 7. Decision Gates Financiers

### Gate 1 (M3) : Viabilité minimale

| Critère | Seuil Go | Seuil Pivot | Seuil Stop |
|---------|----------|-------------|------------|
| Missions complétées (cumul) | ≥ 10 | 5-9 | < 5 |
| Revenu mensuel | > 1 000 EUR | 500-1 000 EUR | < 500 EUR |
| NPS moyen | ≥ 7 | 5-7 | < 5 |
| Clients récurrents | ≥ 2 | 1 | 0 |

**Si Go** → Investir en marketing (2-5k EUR/mois), continuer développement
**Si Pivot** → Changer segment cible ou proposition de valeur, nouvelle Phase 0
**Si Stop** → Arrêter les dépenses, post-mortem, décision fondateurs

### Gate 2 (M6) : Product-Market Fit

| Critère | Seuil Go | Seuil Pivot |
|---------|----------|-------------|
| GMV mensuel | > 50k EUR | 20-50k EUR |
| Revenu mensuel | > 3 000 EUR | 1 500-3 000 EUR |
| Missions IA (si Parcours B validé) | > 30% du total | < 10% |
| Taux de conversion | > 40% | < 25% |

**Si Go** → Premier salaire (dev/ops), Treasury proposal Polkadot, préparation audit mainnet
**Si Pivot** → Refocus Parcours A seul, réduire les coûts

### Gate 3 (M12) : Scale

| Critère | Seuil Scale | Seuil Maintien |
|---------|-------------|----------------|
| GMV mensuel | > 150k EUR | 80-150k EUR |
| Revenu mensuel | > 12 000 EUR | 6 000-12 000 EUR |
| Revenu licences | > 30% du revenu total | < 10% |
| Consultants actifs | > 30 | 15-30 |

**Si Scale** → Levée de fonds, migration Substrate, expansion internationale
**Si Maintien** → Croissance organique, pas de levée, optimisation unit economics

---

## 8. Sensibilité aux Hypothèses

### Variables les plus impactantes

| Variable | Impact d'un changement de +/- 1 point | Levier de contrôle |
|----------|----------------------------------------|---------------------|
| **Taux de commission** (5% → 7% ou 3%) | +/- 40% sur les revenus | Décision prix (attention au positionnement) |
| **Budget moyen mission** (5k → 8k ou 3k) | +/- 60% sur GMV | Segment client (PME vs startup vs grand compte) |
| **Nombre de missions/mois** | Proportionnel aux revenus | Marketing + produit + bouche-à-oreille |
| **Revenus licences** (Parcours C) | +50% revenus à M12 si activé | Développement IPRegistry, curation |
| **Coûts marketing** | Marge directement impactée | Efficacité acquisition (CAC) |

### Scénario catastrophe : que se passe-t-il si...

| Événement | Impact financier | Mitigation |
|-----------|-----------------|------------|
| 0 client M1-M3 | -825 EUR/mois (coûts fixes), trésorerie -2 475 EUR | Pivoter ou arrêter M3 |
| Hack/exploit testnet | 0 EUR (pas de fonds réels) mais réputation | Audit sécurité pré-mainnet |
| Régulation PSAN bloquante | +3-6 mois délai mainnet, +5k EUR | Plan B : escrow fiat via SAS |
| Polkadot Hub non opérationnel | Retard deploy, coût migration L2 | Plan B : Moonbeam ou Base |
| Fondateur quitte | Perte 50% capacité dev | Documentation code + succession plan |

---

**Version** : 1.0.0
**Date** : 2026-02-17
**Actualisation** : Recalculer à chaque Gate (M3, M6, M12) avec les données réelles
