# Plan d'Acquisition Clients : Semaine par Semaine

**Date** : 2026-02-17
**Horizon** : M0 → M6
**Objectif** : Passer de 0 à 50 missions complétées en 6 mois
**Budget marketing** : 0 EUR (M0-M3), 2 000-5 000 EUR/mois (M3-M6)

---

## Principe : Pas de Code Sans Client

> "90% des échecs Web3 sont attribués à l'absence de cas d'usage réel" — C-Leads 2025

Le plan d'acquisition **précède** le développement. L'objectif n'est pas de construire puis de trouver des clients. C'est de trouver des clients, de comprendre ce qu'ils veulent, puis de construire ce qui manque.

---

## Phase 0 : Validation Terrain (Semaine 1-4)

### Cible : 3-5 clients pilotes, 1 mission complétée manuellement

**Segment cible initial** : Consultants tech/data et leurs clients PME/startups.

Pourquoi ce segment :
- Sensibles à la transparence et aux outils tech (early adopters naturels)
- Budgets missions élevés (8-15k EUR) → GMV rapide
- Familiers avec l'IA → réceptifs au Parcours B (agents IA)
- Réseau personnel atteignable des fondateurs (pas d'acquisition paid)

---

### Semaine 1 : Identifier et Contacter

**Actions quotidiennes** :

| Jour | Action | Volume | Canal |
|------|--------|--------|-------|
| Lun | Lister 20 contacts personnels (ex-collègues, réseau LinkedIn) susceptibles d'avoir un besoin de conseil | 20 contacts | Tableur |
| Mar | Rédiger le message d'approche (voir script ci-dessous) | 1 template | — |
| Mar-Mer | Envoyer 15 messages personnalisés (LinkedIn DM + email) | 15 messages | LinkedIn + email |
| Jeu | Relancer les non-répondants de mardi | 5-10 relances | LinkedIn + email |
| Ven | Planifier les premiers appels (15-20 min chacun) | 3-5 appels planifiés | Calendly |

**Script d'approche (LinkedIn DM)** :

```
Salut [Prénom],

Je travaille sur un projet qui change la façon dont les missions de conseil
sont structurées : escrow automatique (le budget est bloqué avant le démarrage),
matching transparent (scoring public sur 5 critères), et frais à 5% au lieu
des 20% de Malt.

On cherche 3 pilotes pour tester le concept avec de vrais briefs. Pas besoin
de connaître la blockchain — tout est invisible côté client.

Tu aurais un besoin de conseil en ce moment (stratégie, data, dev, IA) ?
Ou tu connais quelqu'un ? 15 min d'échange suffisent.

[Prénom]
```

**Script d'approche (email pour clients potentiels)** :

```
Objet : Vos missions de conseil à 5% au lieu de 20%

Bonjour [Prénom],

[1 phrase de contexte personnalisé : "J'ai vu que [entreprise] recrute
un consultant data / vient de lever / lance un nouveau produit..."]

Nous lançons une plateforme de mise en relation consultant-client avec
3 différences structurelles :
- Frais 5% (vs 20% Malt/Upwork)
- Budget bloqué en escrow avant démarrage (0 risque de non-paiement)
- Matching transparent : vous voyez exactement pourquoi un consultant
  a un score de 87/100

Nous cherchons 3 entreprises pilotes pour tester le concept en conditions
réelles. En échange : frais 0% sur les 3 premières missions + accès
prioritaire au matching.

Intéressé(e) ? 15 min cette semaine ?

[Signature]
```

**Métriques Semaine 1** :

| Métrique | Cible | Mesure |
|----------|-------|--------|
| Messages envoyés | 15 | Compteur tableur |
| Taux de réponse | ≥ 30% (5 réponses) | Réponses / envois |
| Appels planifiés | 3-5 | Calendly |

---

### Semaine 2 : Qualifier et Comprendre

**Objectif** : Identifier les 3 pilotes et comprendre leur besoin réel.

**Structure de l'appel de qualification (15-20 min)** :

```
1. [2 min] Contexte : "On construit X, on cherche des pilotes"
2. [5 min] Leur besoin :
   - "C'est quoi votre prochain besoin de conseil ?"
   - "Comment vous trouvez vos consultants aujourd'hui ?"
   - "Qu'est-ce qui vous frustre dans le process actuel ?"
3. [5 min] Test de valeur :
   - "Si le budget était bloqué en escrow avant le début, ça changerait quoi ?"
   - "Si vous voyiez un score de matching transparent, ça aiderait ?"
   - "Si un agent IA pouvait produire un premier livrable en 2h, vous paieriez ?"
4. [3 min] Qualification :
   - Budget estimé de leur mission ?
   - Timeline ? (urgent = bon, "un jour" = mauvais)
   - Prêt à tester en conditions réelles ?
5. [2 min] Next step : "On vous envoie un brief type lundi"
```

**Grille de scoring prospect** :

| Critère | Score 1 (faible) | Score 3 (fort) |
|---------|------------------|----------------|
| Besoin identifié | "Peut-être un jour" | "J'en ai besoin ce mois-ci" |
| Budget disponible | < 3k EUR | > 5k EUR |
| Frustration actuelle | "Ça va" | "Malt/Upwork me coûte trop cher" |
| Réceptivité IA | "Bof" | "Exactement ce qu'il me faut" |
| Disponibilité | "Pas avant avril" | "Cette semaine" |

**Score ≥ 12/15** = pilote prioritaire.

**Métriques Semaine 2** :

| Métrique | Cible |
|----------|-------|
| Appels réalisés | 5 |
| Prospects qualifiés (score ≥ 12) | 3 |
| Briefs reçus (besoin formalisé) | 2 |

---

### Semaine 3 : Exécuter la Première Mission (Manuellement)

**Objectif** : 1 mission complétée end-to-end, sans blockchain.

**Workflow manuel** :

```
Client envoie brief (email/doc)
    |
    v
Fondateur fait le matching manuellement (tableur scoring)
    → Score calculé sur les 5 critères (rank, skills, budget, track record, réactivité)
    → Présentation du shortlist au client avec scores
    |
    v
Client choisit le consultant
    |
    v
"Escrow" = Virement bancaire sur compte SAS/Association
    → 50% à la signature
    → 50% à la livraison
    |
    v
Consultant exécute la mission
    |
    v
Client valide la livraison (email)
    |
    v
Paiement releasé (virement au consultant)
    |
    v
NPS collecté (formulaire Typeform)
```

**Pourquoi exécuter manuellement** :
- Valide le workflow AVANT d'écrire du code
- Identifie les frictions réelles (pas celles qu'on imagine)
- Génère un cas concret pour les prochains prospects ("on a déjà fait une mission")
- Coût : 0 EUR de développement

**Ce qu'on mesure** :

| Métrique | Ce qu'elle nous dit |
|----------|---------------------|
| Le client a-t-il compris le scoring ? | UX du matching |
| Le client a-t-il fait confiance à l'escrow manuel ? | Besoin réel de blockchain ou non |
| Le consultant a-t-il trouvé le process fluide ? | Friction onboarding |
| NPS client (1-10) | Satisfaction globale |
| NPS consultant (1-10) | Satisfaction prestataire |
| Temps total brief → paiement | Efficacité du process |
| Frais réels facturés vs. Malt | Argument commercial validé |

**Métriques Semaine 3** :

| Métrique | Cible |
|----------|-------|
| Mission démarrée | 1 |
| Escrow (virement) réalisé | 1 |
| Matching présenté au client | 1 (avec scoring visible) |

---

### Semaine 4 : Feedback Loop et Itération

**Actions** :

| Action | Livrable |
|--------|----------|
| Interview de retour avec le client pilote (30 min) | Verbatim documenté |
| Interview de retour avec le consultant (30 min) | Verbatim documenté |
| Synthèse des frictions identifiées | Liste priorisée |
| Ajustement du workflow si nécessaire | Process V2 |
| Rédaction du "case study" pilote | 1 page utilisable commercialement |

**Questions clés du retour client** :

1. "Qu'est-ce qui vous a le plus convaincu dans le process ?"
2. "Qu'est-ce qui vous a le plus gêné ?"
3. "Auriez-vous payé pour ce service ? Combien ?"
4. "Recommanderiez-vous à un collègue ? Pourquoi / pourquoi pas ?"
5. "Si on ajoutait un agent IA qui produit un premier livrable en 2h, vous l'utiliseriez ?"

**Gate Phase 0** :

| Critère | Seuil Go | Seuil No-Go |
|---------|----------|-------------|
| Mission complétée | ≥ 1 | 0 |
| NPS client | ≥ 7/10 | < 5/10 |
| NPS consultant | ≥ 7/10 | < 5/10 |
| Client recommanderait | Oui | Non |
| Frictions bloquantes identifiées | ≤ 2 | > 5 |

**Si Go** → Phase 1 (scale à 10 missions)
**Si No-Go** → Pivoter (changer le segment ou la proposition de valeur)

---

## Phase 1 : Traction Initiale (M2-M3)

### Cible : 10 missions complétées, 20 consultants, 5 clients actifs

**Canaux d'acquisition (0 EUR budget)** :

| Canal | Action | Volume/semaine | Conversion attendue |
|-------|--------|----------------|---------------------|
| **LinkedIn organique** | Posts sur le concept (transparence, frais, IA) | 3 posts/semaine | 2-5 leads/semaine |
| **Réseau personnel** | Demander des introductions aux pilotes satisfaits | 5 intros/semaine | 1-2 qualifiés/semaine |
| **Communauté Polkadot** | Post sur le Forum Polkadot (showcase) | 1 post/mois | 3-5 leads (long cycle) |
| **Événements meetup** | Présentation lors de meetups blockchain Paris | 1-2/mois | 2-3 leads/event |
| **Case study pilote** | Partager le case study Semaine 4 dans les canaux | Continu | Credibilité |

**Template post LinkedIn** :

```
On a fait notre première mission via DAO Services :

🔍 Matching : Score transparent 87/100 (5 critères publics)
💰 Frais : 5% au lieu de 20% (économie de 1 200 EUR sur cette mission)
🔒 Escrow : Budget bloqué avant démarrage, libéré à la livraison
⏱️ Durée : Brief → livraison en 12 jours

Le client a noté 9/10. Le consultant n'a payé 0% de commission.

Détails dans le case study [lien].

On cherche 5 prochains pilotes. DM si intéressé.
```

**Métriques hebdomadaires Phase 1** :

| Métrique | Cible S5-S8 | Cible S9-S12 |
|----------|-------------|--------------|
| Leads qualifiés/semaine | 3-5 | 5-8 |
| Missions démarrées/semaine | 1 | 2 |
| Missions complétées (cumul) | 3-5 | 10 |
| Consultants inscrits (cumul) | 10 | 20 |
| Clients actifs (cumul) | 3 | 5 |
| NPS moyen | ≥ 7 | ≥ 8 |

---

### Test Parcours B : Agent IA (Semaine 6-8)

En parallèle des missions classiques (Parcours A), tester le différenciateur :

| Action | Semaine | Livrable |
|--------|---------|----------|
| Créer 1 agent IA spécialisé (étude de marché ou analyse concurrentielle) | S6 | Agent opérationnel (GPT-4 API + prompts + templates) |
| Proposer l'agent à 3 clients pilotes (brief existant) | S7 | 3 livrables IA générés |
| Collecter feedback : utilité, qualité, prix acceptable | S8 | Données quantitatives |

**Gate Parcours B** :

| Critère | Seuil Go | Seuil Pivot |
|---------|----------|-------------|
| Taux d'acceptation livrable IA | > 30% | < 10% |
| Client prêt à payer (même réduit) | > 50% | < 20% |
| NPS livrable IA | ≥ 6/10 | < 4/10 |

**Si Go** → Développer AIAgentRegistry.sol
**Si Pivot** → Focus exclusif Parcours A (missions classiques augmentées)

---

## Phase 2 : Product-Market Fit (M3-M6)

### Cible : 50 missions complétées, 50 consultants, 15 clients actifs, 100k EUR GMV

**Canaux d'acquisition (budget 2-5k EUR/mois)** :

| Canal | Budget | Action | ROI attendu |
|-------|--------|--------|-------------|
| **LinkedIn Ads** (audience ciblée : DG, CTO, CDO PME France) | 1 500 EUR/mois | Campagne "5% au lieu de 20%" avec case study | CPA < 100 EUR |
| **Content marketing** | 0 EUR (temps) | 2 articles/mois (blog + LinkedIn) sur transparence, IA, gouvernance | SEO long-terme |
| **Partenariats cabinets** | 500 EUR/mois (events) | Approcher 3 cabinets de conseil boutique pour référencement croisé | 5-10 missions/mois |
| **Programme ambassadeurs** | 1 000 EUR/mois (incentives) | Consultants satisfaits recommandent → bonus 200 EUR/mission référée | CAC < 200 EUR |
| **Événements** | 1 000 EUR/mois | Sponsoring meetups blockchain + conférences sectorielles | Visibilité + leads |

**Tunnel de conversion cible** :

```
1 000 visiteurs site/mois
    → 10% inscription (100 comptes)
    → 30% profil complété (30 profils)
    → 20% première candidature (6 applications)
    → 50% mission complétée (3 missions/mois via paid)

+ 5-8 missions/mois via réseau organique
= 8-11 missions/mois total

× 8 000 EUR budget moyen × 5% = 3 200 - 4 400 EUR revenus/mois
```

**Métriques mensuelles Phase 2** :

| Métrique | Cible M3 | Cible M4 | Cible M5 | Cible M6 |
|----------|----------|----------|----------|----------|
| Missions complétées (mois) | 5 | 8 | 12 | 15 |
| Missions complétées (cumul) | 15 | 23 | 35 | 50 |
| GMV mensuel | 40k EUR | 64k EUR | 96k EUR | 120k EUR |
| Revenus (5%) | 2 000 EUR | 3 200 EUR | 4 800 EUR | 6 000 EUR |
| Consultants actifs | 20 | 30 | 40 | 50 |
| Clients actifs | 5 | 8 | 12 | 15 |
| NPS moyen | ≥ 7 | ≥ 7 | ≥ 8 | ≥ 8 |
| Churn consultant | < 20% | < 15% | < 10% | < 10% |

---

## Decision Gates

### Gate 1 (M3) : Viabilité du modèle

| Critère | Seuil | Source |
|---------|-------|--------|
| 10 missions complétées | Cumul | Données plateforme |
| NPS client ≥ 7 | Moyenne | Typeform |
| NPS consultant ≥ 7 | Moyenne | Typeform |
| 3 clients récurrents | Au moins 2 missions chacun | Données plateforme |
| 1 mission Parcours B (IA) testée | Go/No-Go | Feedback client |

**Si Gate 1 OK** → Investir en acquisition (budget marketing)
**Si Gate 1 KO** → Pivoter (segment, proposition de valeur, ou abandon)

### Gate 2 (M6) : Product-Market Fit

| Critère | Seuil | Source |
|---------|-------|--------|
| 50 missions complétées | Cumul | Données plateforme |
| GMV > 80k EUR/mois | Mensuel | Données plateforme |
| Revenus > 4k EUR/mois | Mensuel | Comptabilité |
| Churn consultant < 15% | Mensuel | Données plateforme |
| 5 agents IA enregistrés (si Parcours B validé) | Cumul | AIAgentRegistry |

**Si Gate 2 OK** → Lever des fonds / Treasury proposal Polkadot
**Si Gate 2 KO** → Réduire les coûts, itérer sur le produit

---

## Ce Plan Ne Couvre Pas (Explicitement)

- **SEO** : Trop long cycle (6-12 mois) pour être pertinent M0-M6. À lancer M3+ en parallèle.
- **Acquisition paid hors LinkedIn** : Google Ads trop cher (CPA > 200 EUR pour B2B niche), pas pertinent avant PMF.
- **International** : Focus France/francophone M0-M6. International = M6+ si PMF validé.
- **Presse/RP** : Pas avant d'avoir 50+ missions et un case study solide.

---

**Version** : 1.0.0
**Date** : 2026-02-17
