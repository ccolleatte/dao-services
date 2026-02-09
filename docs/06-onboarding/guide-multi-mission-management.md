# Guide : Gestion multi-missions

## Vue d'ensemble

Ce guide aide les consultants DAO à gérer plusieurs missions simultanées tout en maintenant qualité, respect des deadlines, et satisfaction clients. Stratégies éprouvées par consultants Rank 3-4 avec 10+ missions complétées.

**Objectifs** :
- 🎯 Éviter burnout (charge travail réaliste)
- ⏰ Respecter 100% deadlines (buffer temps)
- ⭐ Maintenir rating ≥4.5/5 (qualité constante)
- 💰 Maximiser revenus (optimisation capacité)

---

## Capacité maximale recommandée

### Par niveau expérience

| Expérience | Missions simultanées max | Heures totales/semaine | Marge sécurité |
|------------|-------------------------|------------------------|----------------|
| **Junior** (<1 an) | 2 missions | 30h | 30% buffer |
| **Intermediate** (1-3 ans) | 3 missions | 40h | 25% buffer |
| **Senior** (3-5 ans) | 4 missions | 50h | 20% buffer |
| **Expert** (5+ ans) | 5 missions | 60h | 15% buffer |

**Calcul buffer** :
```
Mission estimée 20h → Allouer 20h × 1.30 = 26h (Junior)
Mission estimée 40h → Allouer 40h × 1.20 = 48h (Senior)
```

**Raison buffer** :
- Scope creep (10-15%)
- Révisions clients (5-10%)
- Blockers imprévus (5-10%)
- Communication overhead (5%)

---

## Matrice priorisation missions

### Critères scoring (0-100)

| Critère | Poids | Calcul |
|---------|-------|--------|
| **Urgence deadline** | 30% | Jours restants vs durée estimée |
| **Budget/heure** | 25% | Taux horaire DAOS/h |
| **Complexité** | 20% | Score difficulté technique |
| **Réputation client** | 15% | Rating client + historique |
| **Impact portfolio** | 10% | Visibilité + skills nouvelles |

**Formule scoring** :
```javascript
function calculateMissionScore(mission) {
  const urgency = (mission.daysRemaining / mission.estimatedDays) * 30;
  const budget = (mission.hourlyRate / 100) * 25; // 100 DAOS/h = max
  const complexity = (5 - mission.complexityLevel) * 4; // Inverse: easy = high score
  const reputation = (mission.clientRating / 5) * 15;
  const impact = mission.portfolioValue * 10; // 0-1 scale

  return urgency + budget + complexity + reputation + impact;
}
```

**Exemple** :
```
Mission A (Audit sécurité)
- Deadline : 7 jours / Estimé 5 jours → Urgence 42% (12.6 points)
- Budget : 80 DAOS/h → 20 points
- Complexité : 4/5 (difficile) → 4 points
- Client rating : 4.8/5 → 14.4 points
- Impact portfolio : 0.8 → 8 points
→ Score total : 59 points (priorité moyenne)

Mission B (Stratégie marketing)
- Deadline : 14 jours / Estimé 10 jours → Urgence 71% (21.3 points)
- Budget : 60 DAOS/h → 15 points
- Complexité : 2/5 (facile) → 12 points
- Client rating : 4.2/5 → 12.6 points
- Impact portfolio : 0.3 → 3 points
→ Score total : 63.9 points (priorité HAUTE)
```

**Dashboard affichage** :
```
🔴 Priority HIGH (score >70)
🟡 Priority MEDIUM (score 50-70)
🟢 Priority LOW (score <50)
```

---

## Calendrier type (Semaine 40h)

### Répartition temps par mission

**Consultant Senior (4 missions)** :

| Mission | Budget | Heures/sem | % temps | Jours deadline | Priority |
|---------|--------|------------|---------|----------------|----------|
| **A** (Audit) | 3000 DAOS | 15h | 37.5% | 7 jours | 🔴 HIGH |
| **B** (Stratégie) | 2000 DAOS | 10h | 25% | 14 jours | 🟡 MEDIUM |
| **C** (Analysis) | 1500 DAOS | 8h | 20% | 21 jours | 🟢 LOW |
| **D** (Report) | 1000 DAOS | 5h | 12.5% | 30 jours | 🟢 LOW |
| Buffer (imprévus) | - | 2h | 5% | - | - |
| **TOTAL** | 7500 DAOS | 40h | 100% | - | - |

**Calendrier hebdomadaire** :

```
LUNDI (8h)
├─ 08:00-10:00 : Mission A (Audit) - Analyse statique Slither
├─ 10:00-11:00 : Mission B (Stratégie) - Research concurrents
├─ 11:00-12:00 : Emails/Discord (communications clients)
├─ 13:00-16:00 : Mission A (Audit) - Review manuel contrats core
└─ 16:00-17:00 : Mission C (Analysis) - Setup environnement

MARDI (8h)
├─ 08:00-11:00 : Mission A (Audit) - Tests fuzzing Echidna
├─ 11:00-12:00 : Mission D (Report) - Rédaction executive summary
├─ 13:00-15:00 : Mission B (Stratégie) - Draft plan marketing
└─ 15:00-17:00 : Mission A (Audit) - Rapport findings preliminary

MERCREDI (8h)
├─ 08:00-10:00 : Mission A (Audit) - Présentation client (call)
├─ 10:00-11:00 : Buffer - Révisions demandées Mission A
├─ 11:00-12:00 : Mission C (Analysis) - Extraction données
├─ 13:00-16:00 : Mission B (Stratégie) - Analyse SWOT détaillée
└─ 16:00-17:00 : Emails/Discord (communications)

JEUDI (8h)
├─ 08:00-11:00 : Mission A (Audit) - Finalisation rapport
├─ 11:00-12:00 : Mission D (Report) - Visualisations dashboards
├─ 13:00-15:00 : Mission C (Analysis) - Transformation données
└─ 15:00-17:00 : Mission A (Audit) - Livraison + suivi client

VENDREDI (8h)
├─ 08:00-10:00 : Mission B (Stratégie) - Présentation plan (call)
├─ 10:00-11:00 : Buffer - Révisions demandées Mission B
├─ 11:00-12:00 : Mission C (Analysis) - Modélisation prédictive
├─ 13:00-15:00 : Mission D (Report) - Rédaction recommandations
└─ 15:00-17:00 : Admin DAO (gouvernance, updates, networking)
```

**Principes** :
- ✅ Missions HIGH le matin (focus maximal)
- ✅ Communications 11h-12h (emails/Discord batch)
- ✅ Calls clients 08h-10h ou 15h-17h (éviter interruptions mid-day)
- ✅ Buffer 5% intégré (flex Friday pm si pas utilisé)

---

## Outils de gestion

### Dashboard consultant (recommandé)

**URL** : dashboard.dao.xyz/consultant

**Features** :

1. **Vue missions actives** (Kanban)
   - 🟥 To Do | 🟨 In Progress | 🟩 Review | ✅ Done
   - Drag & drop priorités
   - Badges deadline urgence

2. **Calendrier intégré** (Google Calendar sync)
   - Time blocks par mission (couleurs)
   - Calls clients (reminders 15 min avant)
   - Milestones deadlines (notifications push)

3. **Time tracking automatique**
   - Start/Stop timer par mission
   - Export CSV hebdomadaire
   - Calcul revenus temps réel (heures × taux)

4. **Notifications intelligentes**
   - 🔴 Deadline <48h : "Mission A deadline dans 36h"
   - 🟡 Milestone pending : "Livraison Phase 2 attendue"
   - 🟢 New message client : "Client B a commenté votre draft"

5. **Analytics performance**
   - Average rating (30 jours glissant)
   - On-time delivery rate (%)
   - Revenue per hour (DAOS/h moyen)
   - Capacity utilization (heures facturées / heures dispo)

---

### Outils externes intégrables

| Outil | Usage | Integration |
|-------|-------|-------------|
| **Notion** | Kanban missions + notes | Webhook DAO → Notion DB |
| **Todoist** | Todo lists granulaires | API bidirectionnelle |
| **Toggl Track** | Time tracking précis | Export CSV → Dashboard DAO |
| **Google Calendar** | Calls clients + deadlines | iCal sync |
| **Slack/Discord** | Communications clients | Notifications centralisées |

**Setup recommandé** :
```
Dashboard DAO (source vérité)
   ↓ Webhook
Notion (vue projet détaillée)
   ↓ API
Todoist (tasks quotidiennes)
   ↓ Export
Toggl (time tracking)
```

---

## Stratégies communication clients

### Fréquence updates par mission

| Type mission | Durée | Fréquence updates | Format |
|--------------|-------|-------------------|--------|
| **Sprint court** (<2 sem) | 1-10 jours | Daily standup (async) | Discord 3 lignes |
| **Sprint moyen** (2-4 sem) | 10-30 jours | 2× par semaine | Email structuré |
| **Sprint long** (1-3 mois) | 30+ jours | Hebdomadaire | Call 30 min + rapport |

### Template update async (Discord/Email)

```markdown
**Mission** : [Nom mission]
**Date** : [JJ/MM/AAAA]
**Progression** : [X%] (vs [Y%] prévu)

**Accompli aujourd'hui** :
- ✅ [Tâche 1 complétée]
- ✅ [Tâche 2 complétée]
- 🚧 [Tâche 3 en cours - 50%]

**Plan demain** :
- 📋 [Tâche A à démarrer]
- 📋 [Tâche B à continuer]

**Blockers** :
- ❌ [Blocker 1 - Action client requise : fournir API keys]
- ⚠️ [Risk 1 - Deadline serrée, nécessite clarification scope]

**Questions** :
- ❓ [Question 1 pour client]
- ❓ [Question 2 pour client]

ETA milestone : [Date] (on track ✅ / at risk ⚠️)
```

**Exemple réel** :
```markdown
**Mission** : Audit sécurité smart contracts NFT Marketplace
**Date** : 15/02/2026
**Progression** : 40% (vs 35% prévu) ✅

**Accompli aujourd'hui** :
- ✅ Analyse statique Slither complète (12 findings)
- ✅ Review manuel Marketplace.sol (250 lignes)
- 🚧 Tests fuzzing Escrow.sol (50% coverage)

**Plan demain** :
- 📋 Finaliser tests fuzzing Escrow.sol
- 📋 Démarrer review Auction.sol

**Blockers** :
- ❌ Accès testnet manquant - Besoin RPC URL Sepolia

**Questions** :
- ❓ Modifier Auction.sol réservé enchères vs buy-now ou séparé ?
- ❓ Timelock admin 24h ou 48h ?

ETA rapport preliminary : 18/02/2026 (on track ✅)
```

---

## Gestion scope creep

### Détection précoce

| Signal | Exemple | Action |
|--------|---------|--------|
| **Demande hors spec** | "Peux-tu aussi auditer contrat XYZ ?" | Clarifier scope initial |
| **Feature additionnelle** | "Ajoute section architecture système" | Proposer amendment budget |
| **Délai compression** | "Peux-tu livrer 5 jours plus tôt ?" | Négocier priorités |

### Template réponse scope creep

```markdown
Bonjour [Client],

Merci pour votre demande concernant [feature additionnelle].

**Analyse** :
J'ai bien noté votre besoin d'ajouter [description]. D'après mon estimation,
cela représente environ [X heures] de travail supplémentaire.

**Options** :

**Option A - Amendment budget** (recommandé)
- Ajout scope : [Feature détaillée]
- Effort : [X heures] × [Y DAOS/h] = [Z DAOS]
- Nouveau deadline : [Date] (+[N jours])
- Nouveau budget total : [Budget initial + Z DAOS]

**Option B - Priorités ajustées**
- Intégrer [feature] en remplaçant [feature moins prioritaire]
- Effort : 0 DAOS additionnel
- Deadline inchangée : [Date]
- Trade-off : [Feature remplacée] livrée en Phase 2 (hors scope initial)

**Option C - Décliner poliment**
- Focus qualité scope initial
- Livraison on-time : [Date]
- Possibilité nouvelle mission pour [feature additionnelle]

Merci de confirmer option préférée sous 48h pour ajuster planning.

Cordialement,
[Nom consultant]
```

---

## Checklist hebdomadaire (Vendredi pm)

### Admin DAO (1h)

- [ ] **Time tracking** : Vérifier heures loggées par mission
- [ ] **Invoicing** : Soumettre milestones complétées (escrow release)
- [ ] **Updates clients** : Envoyer rapports hebdomadaires (missions actives)
- [ ] **Dashboard review** : Vérifier deadlines semaine prochaine
- [ ] **Buffer allocation** : Réallouer heures buffer non utilisées

### Planning semaine suivante (30 min)

- [ ] **Prioriser missions** : Recalculer scores (deadlines updated)
- [ ] **Bloquer calendrier** : Time blocks par mission (Google Calendar)
- [ ] **Anticiper blockers** : Identifier besoins clients (accès, feedback)
- [ ] **Calls planifier** : Réserver slots clients (Calendly)

### Self-care & learning (30 min)

- [ ] **Review performance** : Rating missions complétées, feedback clients
- [ ] **Skills gap** : Identifier besoins formation (tools, frameworks)
- [ ] **Networking DAO** : Participer Discord discussions, gouvernance
- [ ] **Repos** : Vérifier charge semaine prochaine (éviter >50h)

---

## Signaux burnout (alertes)

### Indicateurs précoces

| Indicateur | Seuil alerte | Action |
|------------|--------------|--------|
| **Heures facturées** | >55h/sem pendant 3 sem | Refuser nouvelles missions |
| **On-time delivery** | <80% (vs 95% baseline) | Réviser capacité max |
| **Rating moyen** | <4.3/5 (vs 4.7 baseline) | Pause 1 semaine, QA focus |
| **Messages non lus** | >20 Discord/Email | Batch processing 2×/jour |
| **Sleep quality** | <6h/nuit pendant 5 jours | Weekend off forcé |

### Plan recovery burnout

**Semaine 1 - Stabilisation** :
- ⛔ Refuser toutes nouvelles missions
- 📉 Réduire heures 50% (20h/sem)
- 🗣️ Communication transparente clients (delays justifiés)

**Semaine 2 - Re-evaluation** :
- 📊 Audit missions actives (priorités vs capacité)
- 🤝 Négocier extensions deadlines (2-3 missions)
- 💼 Clore missions quick-wins (libérer mental load)

**Semaine 3 - Redémarrage graduel** :
- ➕ Augmenter heures 75% (30h/sem)
- ✅ Focus qualité (rating recovery)
- 🎯 1-2 missions max simultanées (vs 4-5 before)

**Semaine 4 - Normalisation** :
- 📈 Retour capacité normale (40h/sem)
- 🔄 Ré-implémenter best practices (buffer, priorisation)
- 📝 Post-mortem : Identifier causes burnout (scope creep, sur-booking)

---

## Cas d'étude : Consultant Senior (Rank 4)

### Profil

- **Expérience** : 3 ans consulting DAO
- **Spécialité** : Smart contract audits + DeFi analysis
- **Rating** : 4.8/5 (50 missions complétées)
- **Capacité** : 50h/sem (4 missions simultanées)

### Semaine type (Janvier 2026)

**Missions actives** :

| Mission | Type | Budget | Deadline | Heures/sem | Priority |
|---------|------|--------|----------|------------|----------|
| **M1** | Audit Uniswap V4 hooks | 5000 DAOS | 7 jours | 20h | 🔴 |
| **M2** | DeFi strategy Aave V3 | 3000 DAOS | 14 jours | 15h | 🟡 |
| **M3** | Report MEV analysis | 2000 DAOS | 21 jours | 10h | 🟢 |
| **M4** | Advisory DAO treasury | 1500 DAOS | 30 jours | 5h | 🟢 |

**Résultats semaine** :
- ✅ M1 livré on-time (rating 5/5)
- ✅ M2 milestone 1 validé (rating 4.8/5)
- 🚧 M3 en cours (50% progression)
- 🚧 M4 en cours (25% progression)

**Revenus semaine** : 50h × 80 DAOS/h moyen = 4000 DAOS (~12 000 EUR)

**Lessons learned** :
- ✅ Priorisation matrice efficace (M1 deadline respectée)
- ⚠️ Buffer 5% insuffisant (M2 révisions 10% temps)
- ✅ Communication async clients (0 calls imprévus)
- ⚠️ Charge 50h/sem limite supérieure (fatigue vendredi)

**Adjustements semaine suivante** :
- 📉 Réduire heures 45h/sem (clôture M1)
- 🛡️ Buffer 10% (au lieu de 5%)
- 📞 Call M4 client (clarifier ambiguïtés scope)

---

## Templates documents

### Time log hebdomadaire (CSV)

```csv
Date,Mission,Task,Hours,Notes
15/02/2026,M1 Audit Uniswap,Slither analysis,2.5,"12 findings identified"
15/02/2026,M1 Audit Uniswap,Manual review hooks,3.0,"BeforeSwap logic complex"
15/02/2026,M2 DeFi Aave,Research liquidation params,1.5,"Health factor calculations"
15/02/2026,Communications,Emails clients + Discord,1.0,"M1 questions clarified"
16/02/2026,M1 Audit Uniswap,Fuzzing tests Echidna,4.0,"Coverage 85%"
16/02/2026,M3 MEV Report,Data extraction Dune,2.0,"Sandwich attacks Q1"
```

### Invoice milestone (Markdown)

```markdown
**INVOICE #2026-015**

**Consultant** : [Nom] (Rank 4)
**Client** : [Client XYZ]
**Mission** : Audit sécurité Uniswap V4 hooks
**Milestone** : Phase 2 - Manual review + Fuzzing
**Date** : 18/02/2026

---

**Détail heures** :

| Date | Task | Hours |
|------|------|-------|
| 15/02 | Slither analysis | 2.5h |
| 15/02 | Manual review hooks | 3.0h |
| 16/02 | Fuzzing tests Echidna | 4.0h |
| 17/02 | Report findings preliminary | 3.5h |
| 18/02 | Présentation client (call) | 2.0h |
| **TOTAL** | | **15h** |

**Montant** : 15h × 80 DAOS/h = **1200 DAOS**

**Deliverables** :
- ✅ Rapport Slither (12 findings)
- ✅ Tests Echidna (85% coverage)
- ✅ Rapport preliminary findings (PDF 25 pages)
- ✅ Présentation slides (call 30 min)

**Escrow release** :
- Milestone amount : 1200 DAOS
- Client validation : [Pending]
- Expected release : 20/02/2026

---

Merci de valider milestone sous 48h pour release escrow.

Cordialement,
[Nom consultant]
```

---

## Ressources complémentaires

- **Dashboard consultant** : dashboard.dao.xyz/consultant
- **Templates documents** : docs/06-onboarding/templates/
- **Time tracking tools** : Toggl Track, Clockify, Harvest
- **Project management** : Notion, Todoist, Asana
- **Support burnout** : Discord `#consultant-wellness`

---

**Besoin d'aide ?** Rejoignez le Discord DAO, canal `#consultants-support`
**Mentoring** : Demandez conseil membres Rank 4 (canal `#mentorship`)
