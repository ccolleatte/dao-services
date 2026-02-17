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

## Positionnement : Ce Qu'on Vend (et Ce Qu'on Ne Vend Pas)

> **Origine** : Vague 1 §3 — "Le libellé 'cabinet 100% blockchain' déclenche chez
> l'entreprise : peur juridique, peur conformité, peur procurement, peur réputation."

### Le Reframing Enterprise

**Ce qu'on NE dit PAS** : "Cabinet de conseil 100% blockchain" / "DAO de consultants" / "Marketplace décentralisée"

**Ce qu'on DIT** : **"Cabinet d'expertise composable et productisé"**

| Terme | Ce que l'entreprise comprend | Pourquoi c'est bon |
|-------|------------------------------|---------------------|
| **Composable** | "Je choisis les compétences dont j'ai besoin, pas un package" | Différenciation vs. cabinet classique |
| **Productisé** | "J'achète un résultat, pas du temps" | Différenciation vs. Malt/Upwork |
| **Expertise** | "C'est du conseil sérieux, pas un side-project" | Crédibilité enterprise |

La blockchain = **couche de confiance invisible**. Le client achète un livrable, pas un token.

### Le Test de Réalité Enterprise (5 critères)

> **Origine** : Vague 1 §7 — "Votre proposition marche si une entreprise peut acheter
> un livrable/mission : sans changer son SI, avec une responsabilité claire, avec des
> droits IP non ambigus, avec une qualité fiable, et avec une expérience aussi simple
> qu'un SaaS."

Chaque mission pilote doit valider ces 5 points. C'est le **filtre d'acceptation** :

| # | Critère | Comment on le garantit dès le MVP |
|---|---------|-----------------------------------|
| 1 | **Sans changer son SI** | Onboarding = email + brief. Pas d'API, pas de wallet, pas de token. Blockchain invisible. |
| 2 | **Responsabilité claire** | La SAS est le prime contractor. Un interlocuteur unique, un contrat de prestation en droit français. |
| 3 | **Droits IP non ambigus** | 3 modèles de licence standard (L1/L2/L3). Conditions off-chain signées + hash on-chain. |
| 4 | **Qualité fiable** | Curation gate obligatoire sur tout livrable IA. Matching transparent sur 5 critères. Dispute resolution en 3 niveaux. |
| 5 | **Expérience SaaS** | Interface Web2 : dashboard, suivi mission, paiement CB/virement. Zéro friction crypto. |

**Usage** : Intégrer ce test dans le **feedback client** (Semaine 4). Poser explicitement : "Sur une échelle de 1-5, à quel point chacun de ces critères est satisfait ?" Si un critère < 3 → action corrective immédiate.

---

## Packaging : "Produits de Connaissance" avec Quality Card

> **Origine** : Vague 2 §A.1 — "Transformer chaque offre en 'produit de connaissance'
> avec spec et DoD explicites." §A.2 — "Afficher des critères objectivables de qualité
> sous forme de 'Quality Card'."

### Pourquoi ce packaging est critique pour les ETI

Une ETI n'achète pas "du conseil". Elle achète un **résultat documenté**. Le problème de toutes les marketplaces (Malt, Upwork) : le client ne sait pas ce qu'il achète avant de l'avoir reçu. La Quality Card résout cette asymétrie d'information **avant achat**.

### Definition of Done (DoD) par type de livrable

Chaque offre sur la marketplace est un "produit de connaissance" avec une spec publique :

| Type de livrable | Structure attendue | Profondeur | Sources | Hors-scope (explicite) | Délai type |
|------------------|--------------------|------------|---------|------------------------|------------|
| **Audit concurrentiel** | Executive summary + matrice + fiches acteurs + recommandations | 5-10 acteurs, 3 axes d'analyse min. | Publiques uniquement (Crunchbase, presse, rapports) | Pas de données propriétaires, pas de pricing confidentiel | 5-10 jours |
| **Note de cadrage stratégique** | Contexte + enjeux + options + recommandation argumentée | 1 décision, 3-5 options évaluées | Entretiens internes + benchmark externe | Pas de business plan, pas de chiffrage financier détaillé | 3-5 jours |
| **Étude de marché** | Sizing + segmentation + tendances + opportunités | TAM/SAM/SOM + 3 segments min. | Études publiques + données marché | Pas d'enquête terrain, pas de panel consommateurs | 7-15 jours |
| **Analyse de risques** | Matrice risques + probabilité/impact + mitigations | 10-20 risques identifiés | Documentation projet + entretiens | Pas d'audit technique, pas de pen-testing | 3-7 jours |
| **Livrable IA (Parcours B)** | Brut IA + rapport de curation + sources + limites déclarées | Dépend du brief | Sources autorisées de l'agent uniquement | Ce que l'agent ne sait pas faire (cf. Agent Listing Standard) | 2-48h |

### Quality Card (visible avant achat)

Chaque livrable publié ou mis en vente affiche une **Quality Card** avec 4 critères objectivables :

```
┌─────────────────────────────────────────────────┐
│              QUALITY CARD                        │
│                                                  │
│  📋 Traçabilité        ████████░░  8/10         │
│     Sources citées, hypothèses explicites,       │
│     limites déclarées, versioning                │
│                                                  │
│  📖 Clarté             █████████░  9/10         │
│     Executive summary, plan structuré,           │
│     annexes séparées                             │
│                                                  │
│  ✅ Adéquation          ███████░░░  7/10         │
│     Couverture du brief : 7/10 exigences         │
│     remplies (checklist publique)                │
│                                                  │
│  ♻️  Réutilisabilité    ██████░░░░  6/10         │
│     Templates réutilisables, assets extractibles │
│                                                  │
│  Curé par : Marie L. (REP 92)                   │
│  Méthode : Humain supervisé (Parcours A)        │
│  Taux de rework : 0% (1ère soumission acceptée) │
└─────────────────────────────────────────────────┘
```

**Qui remplit la Quality Card ?**
- **Gate 1 (auto)** : Traçabilité (comptage sources, détection limites) + Adéquation (matching brief ↔ livrable)
- **Gate 2 (curateur)** : Clarté (jugement humain) + Réutilisabilité (évaluation assets) + score global
- **Post-mission (client)** : Feedback qui ajuste les scores (NPS + évaluation par critère)

**Métriques de robustesse** (pas seulement la "beauté") :

> **Origine** : Vague 2 §B.5 — "Mesurer la robustesse (répétabilité),
> le taux de rework, la traçabilité — pas seulement la beauté."

| Métrique | Définition | Cible | Alerte |
|----------|------------|-------|--------|
| **Taux de rework** | % de livrables renvoyés pour correction | < 20% | > 40% |
| **Répétabilité** (agents IA) | Score moyen sur 3 exécutions du même brief | ≥ 7/10 | < 5/10 |
| **Taux de traçabilité** | % de claims avec source citée | > 80% | < 50% |
| **Taux d'adéquation brief** | % d'exigences du brief couvertes | > 85% | < 60% |

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

**Si Go** → Développer AIAgentRegistry.sol + Agent Listing Standard
**Si Pivot** → Focus exclusif Parcours A (missions classiques augmentées)

---

### Curation Gate Obligatoire (Parcours B)

> **Origine** : Vague 1 §4.1 — "Un agent qui 'livre vite' mais parfois faux abîme
> la confiance plus vite qu'il ne crée de la valeur."
> §4.2 — "Pas d'agent sans 'preuve de spécialisation'."

**Règle non négociable** : Aucun livrable IA "brut" ne peut être vendu/livré au client sans passer par un contrôle qualité (automatisé + humain).

**Pipeline de curation (avant livraison client)** :

```
Agent IA produit un livrable brut
    |
    v
GATE 1 — Contrôle automatisé (M3+)
    - Détection de plagiat (similarity check vs corpus existant)
    - Vérification de cohérence (le livrable répond-il au brief ?)
    - Détection d'hallucinations (claims vérifiables → fact-check)
    → Score de confiance automatique (0-100)
    → Si score < 60 → rejet automatique, retour à l'agent
    |
    v
GATE 2 — Curation humaine (obligatoire au MVP)
    - Un curateur qualifié (REP > seuil) review le livrable
    - Checklist : Guild Quality Rubric (conformité brief, structure,
      traçabilité, opérabilité — cf. section Quality Card)
    - Curateur approuve, demande correction, ou rejette
    → Si approuvé → livraison au client
    → Si rejeté → feedback à l'opérateur de l'agent
    |
    v
GATE 2b — Champion métier (livrables à enjeu uniquement)
    - Activé si : livrable stratégie, finance, juridique, ou > 5k EUR
    - Un champion de la Guild concernée valide la pertinence métier
      (même 10-15 minutes : "est-ce que c'est solide sur le fond ?")
    → Si OK → livraison au client
    → Si KO → retour au curateur avec feedback métier
    |
    v
Client reçoit le livrable avec mention "curated by [curateur]"
+ Quality Card remplie (4 critères + score)
```

**Rémunération curateur** : 10% du montant de la mission IA (prélevé sur la commission plateforme, pas en supplément pour le client).

**Option "Human Refinement"** (systématique sur Parcours B) :

> **Origine** : Vague 2 §A.1 — "Mettre un filet de sécurité : option 'raffinement humain'
> si le brut IA n'est pas suffisant."

Si le client le souhaite ou si le curateur le recommande, un consultant humain affine le livrable IA brut. Le surcoût est transparent :

| Mode | Livrable | Délai | Prix indicatif |
|------|----------|-------|----------------|
| **IA brut + curation** | Livrable automatisé, curé | 2-48h | 500-2 000 EUR |
| **IA brut + human refinement** | Livrable IA revu et enrichi par un consultant | 3-5 jours | 1 500-5 000 EUR |
| **100% humain (Parcours A)** | Mission classique | 5-15 jours | 5 000-15 000 EUR |

L'option human refinement est le **convertisseur ETI** : les entreprises hésitantes peuvent tester avec filet de sécurité, puis migrer progressivement vers le pur Parcours B une fois la confiance établie.

---

### Agent Listing Standard (Anti-GPT-Wrapper)

> **Origine** : Vague 1 §4.2 — "Créez un 'Agent Listing Standard' :
> fiches obligatoires + tests minimaux + disclosure des sources/outils."

**Règle** : Pas d'agent enregistré sur la marketplace sans remplir la fiche suivante.

**Fiche obligatoire pour chaque agent** :

| Champ | Obligatoire | Exemple |
|-------|-------------|---------|
| **Nom** | Oui | "MarketScope Analyst" |
| **Domaine de spécialisation** | Oui | "Analyse concurrentielle B2B SaaS" |
| **Périmètre** | Oui | "Marchés européens, secteur tech, données publiques uniquement" |
| **Limites déclarées** | Oui | "Ne traite pas les données financières non publiques. Pas d'analyse juridique." |
| **Stack technique** | Oui | "Claude Sonnet 4.5 + web search + templates propriétaires" |
| **Sources autorisées** | Oui | "Crunchbase, LinkedIn, rapports SEC, presse spécialisée" |
| **Cas de tests passés** | Oui (min. 3) | "Brief X → livrable Y → score qualité Z" |
| **Opérateur** | Oui | "Jean Dupont (contributeur vérifié, REP 85)" |
| **Historique** | Auto-généré | "12 missions, NPS moyen 7.8, taux d'acceptation 78%" |

**Admission** :
- L'agent doit passer 3 cas de tests standardisés (briefs types du domaine)
- Un curateur (REP > 70) valide la fiche et les résultats de tests
- L'opérateur stake un montant symbolique (CRED ou fiat) comme engagement qualité
- Si NPS < 5 sur 3 missions consécutives → agent désactivé + review obligatoire

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

## Guild Métier : Structuration Communautaire et Onboarding

> **Origine** : Vague 2 §B + Vague 3 §1-6 — "Structurer la communauté métier comme
> une Guild. Une guild = un référentiel de qualité et des champions."
> Vague 1 §5 — "Attention sybil/farming/capture de gouvernance."

### Pourquoi des Guilds (et pas juste une "communauté")

Pour une ETI, **"la guild est la marque de confiance"** : l'entreprise n'achète pas une promesse individuelle, elle achète un livrable passé par des règles métier. La guild est l'unité organisationnelle qui :
- Définit les standards (templates, DoD, grille qualité)
- Valide les entrants (cooptation + tests)
- Cure les livrables (champions métier)
- Anime la communauté (rituels, lessons learned)

### Guild Pilote : "Org & SI" (Conseil en Organisation et Systèmes d'Information)

> **Origine** : Vague 3 §1-3 — "Conseil en organisation et SI = hyper productisable."

**Pourquoi ce métier en premier** :
- Le plus standardisable (livrables cadrés : TOM, SDSI, Diagnostic, RACI)
- Le plus facile à évaluer (grille qualité applicable)
- Le meilleur entonnoir vers des missions plus complexes (TOM → SDSI → transformation)
- Forte demande ETI (toute ETI en croissance a besoin d'un schéma directeur SI)

**4 lignes de produits** :

| # | Ligne | Livrable type | Délai | Prix indicatif |
|---|-------|---------------|-------|----------------|
| 1 | **Diagnostic SI & Gouvernance 360** | Support de lancement, plan d'audit, guides d'entretiens, diagnostic maturité, analyse d'écart, recommandations + plan d'actions priorisé | 10-15 jours | 8 000-15 000 EUR |
| 2 | **TOM IT (niveau 0/1)** | Modèle de capacités, gouvernance, organisation, processus/outils (IT4IT), RH/compétences, KPI, roadmap macro | 10-20 jours | 10 000-20 000 EUR |
| 3 | **SDSI Express (cible 3 ans)** | Diagnostic, cible SI, trajectoire, gouvernance d'architecture | 15-25 jours | 15 000-30 000 EUR |
| 4 | **Gouvernance & RACI** | Clarification rôles/responsabilités, comitologie, RACI présentable en COMEX | 5-10 jours | 5 000-10 000 EUR |

**Pack MVP de lancement** : démarrer avec la ligne 1 (Diagnostic SI & Gouvernance 360) car :
- Le plus standardisable (liste de livrables déjà cadrée)
- Le plus facile à évaluer (rubric applicable)
- Le meilleur entonnoir vers TOM/SDSI (upsell naturel)

### Guild Quality Rubric (grille d'évaluation unique)

> **Origine** : Vague 2 §A.2 + Vague 3 §3.1 — "Critères objectivables : structure,
> clarté, réponse aux exigences, traçabilité. Logique bonus/malus."

**4 critères, notés 0-3 chacun** (score max = 12) :

| Critère | 0 (insuffisant) | 1 (partiel) | 2 (conforme) | 3 (excellent) |
|---------|-----------------|-------------|---------------|---------------|
| **Conformité au brief** | < 50% exigences couvertes | 50-70% | 70-90% | > 90% + hors-scope explicite |
| **Structure & lisibilité** | Pas de plan, pas de synthèse | Plan présent mais confus | Exec summary + plan + annexes | Livrable autonome, compréhensible sans contexte |
| **Traçabilité** | Pas de sources ni d'hypothèses | Sources partielles | Hypothèses + sources + limites documentées | Alternatives évaluées + décisions justifiées |
| **Opérabilité** | Pas de recommandations actionnables | Recommandations vagues | Actions concrètes + owners + timeline | Roadmap macro réaliste + quick wins identifiés |

**Usage de la rubric** :
- **Onboarding** : le candidat doit scorer ≥ 8/12 sur son test d'admission
- **Curation** : chaque livrable est évalué avant livraison client
- **Réputation** : le score moyen alimente le REP du contributeur
- **Marketplace** : le score est visible dans la Quality Card du livrable

### Onboarding en 3 Paliers

> **Origine** : Vague 2 §B.1 + Vague 3 §2.1 — "Pipeline d'entrée en 3 niveaux,
> simple, lisible, scalable."

| Palier | Nom | Accès | Comment y arriver | Durée typique |
|--------|-----|-------|-------------------|---------------|
| **N0** | **Coopté** | Missions à faible criticité (Diagnostic partiel, RACI simple). Sous supervision. | Coopté par un membre N1/N2. Identité vérifiée. | M0-M3 : invitation fondateurs. M3+ : parrainage. |
| **N1** | **Vérifié** | Toutes missions Guild. Peut contribuer à la curation. | 1 test standard réussi (rubric ≥ 8/12) + 1 livrable accepté en mission réelle. | 2-4 semaines après entrée N0 |
| **N2** | **Certifié Guild** | Missions sensibles (TOM, SDSI). Peut publier des assets/livrables réutilisables. Peut être champion métier. | Validé par le Guild Acceptance Board (3 missions N1 + score moyen ≥ 9/12 + vote GAB). | 2-3 mois après entrée N1 |

**Tests standardisés par ligne de produit** (exemples Guild Org & SI) :

| Test | Brief | Livrable attendu | Durée | Rubric appliquée |
|------|-------|-------------------|-------|------------------|
| Test Diagnostic | "Auditer l'organisation IT d'une PME de 200 personnes (cas fictif)" | Mini-diagnostic 5 pages + 5 recommandations | 4h | Les 4 critères |
| Test TOM | "Produire les principes directeurs + risques + macro-roadmap d'un TOM IT" | 3 pages structurées | 3h | Les 4 critères |
| Test RACI | "Produire un RACI Demand/Delivery/Service management présentable en COMEX" | Matrice RACI + note d'accompagnement 1 page | 2h | Les 4 critères |

### Cooptation "Sponsor/Vouch" (Réputation Symétrique)

> **Origine** : Vague 2 §B.2 + Vague 3 §2.2 — "Quand A coopte B, A met sa
> réputation en garantie sur B pendant 3 premières missions."

**Mécanisme** :

```
Membre N1/N2 ("Sponsor") parraine un candidat ("Entrant")
    |
    v
Entrant rejoint au niveau N0
    |
    v
Pendant les 3 premières missions de l'Entrant :
    |
    ├─ Si Entrant performe (rubric ≥ 8/12 + acceptation client) :
    │     → Sponsor : +5 REP par mission réussie
    │     → Sponsor : débloque droit de parrainage supplémentaire
    │
    └─ Si Entrant sous-performe (rubric < 6/12 OU rejet client) :
          → Sponsor : -10 REP par mission ratée
          → Sponsor : perd le droit de parrainage pendant 3 mois
          → Entrant : reste N0, doit repasser le test
          |
          └─ Si 2 échecs consécutifs de l'Entrant :
                → Entrant désactivé
                → Sponsor : -20 REP + review par Guild Acceptance Board
```

**Pourquoi c'est puissant** : la communauté **s'auto-filtre**. Les bons recruteurs sont récompensés, les mauvais sont pénalisés. Pas besoin d'un comité central de vérification — le skin in the game fait le travail.

**Limites** : 1 parrainage actif maximum par sponsor (pas de mass-onboarding). Sponsor doit être N1+ avec REP > 50.

### Guild Acceptance Board (GAB)

> **Origine** : Vague 3 §4 — "Créer un Guild Acceptance Board (3-5 personnes)
> qui valide l'entrée N2, tranche les litiges, maintient le référentiel."

**Composition** : 3-5 membres N2 de la Guild, élus par les membres N1+N2 (mandat 6 mois, renouvelable).

**Attributions** :

| Décision | Quorum | Fréquence |
|----------|--------|-----------|
| Promotion N1 → N2 (Certifié Guild) | 3/5 | Sur candidature |
| Litige qualité (rejet contesté par contributeur ou client) | 3/5 | À la demande |
| Évolution de la rubric / des templates | 4/5 | Trimestrielle |
| Exclusion d'un membre (manquement grave) | 5/5 (unanimité) | Exceptionnelle |

**Au MVP** : le GAB = les fondateurs + 1-2 premiers contributeurs N2. Il se formalise quand la Guild atteint 10+ membres.

### Guild Operator (Rôle d'Animation)

> **Origine** : Vague 3 §5 — "Une communauté ne tient pas sans animation structurée.
> Prévoir un 'Guild Operator'."

**1 personne** (fondateur au MVP, puis rôle dédié) responsable de :

| Rituel | Fréquence | Contenu |
|--------|-----------|---------|
| **Weekly Review** | Hebdomadaire (30 min) | Revue des livrables de la semaine, scores rubric, lessons learned |
| **Catalogue Maintenance** | Continue | Mise à jour des templates, DoD, grille qualité |
| **Onboarding Support** | À chaque nouvelle entrée | Accompagnement N0, explication process, attribution de test |
| **Scoreboard Publication** | Mensuelle | Taux d'acceptation, NPS, taux de rework, top contributeurs |
| **Retrospective** | Mensuelle | Ce qui a marché, ce qui a échoué, ajustements process |

**Coût** : 0 EUR M0-M3 (fondateur). ~500-1 000 EUR/mois M3+ (si rôle délégué à un contributeur rémunéré en CRED ou fiat).

### Règles Anti-Gaming (intégrées dans le modèle Guild)

| Vecteur d'attaque | Protection | Sanction |
|--------------------|-----------|----------|
| **Sybil** (faux comptes) | Identité vérifiée obligatoire pour N1+. 1 humain = 1 compte. REP soulbound (ERC-5484). | Burn REP + ban permanent |
| **Auto-validation** (faux clients) | Escrow réel requis. Client et consultant = entités distinctes vérifiées. | Annulation REP + mission invalidée |
| **Capture de gouvernance** | Quorum 30%. Plafond voting power 10%. GAB = élection. | Veto communautaire (33%) |
| **Farming de parrainage** | 1 parrainage actif max. Sponsor perd REP si entrant échoue. | Perte droit de parrainage 3-6 mois |
| **Complaisance de curation** | Curateur audité aléatoirement (1/10 livrables re-reviewé par GAB). | Perte rôle curateur + REP |

### Transparence des incentives

Tout mécanisme d'incentive est **publié et auditable** :
- Tableau de distribution des commissions (visible on-chain)
- Historique de curation (qui a validé quoi, avec quel score rubric)
- Historique de vote (qui a voté quoi, visible on-chain)
- Pénalités appliquées (visibles dans le registre REP)
- Scoreboard Guild (mensuel, public)

---

## Ce Plan Ne Couvre Pas (Explicitement)

- **SEO** : Trop long cycle (6-12 mois) pour être pertinent M0-M6. À lancer M3+ en parallèle.
- **Acquisition paid hors LinkedIn** : Google Ads trop cher (CPA > 200 EUR pour B2B niche), pas pertinent avant PMF.
- **International** : Focus France/francophone M0-M6. International = M6+ si PMF validé.
- **Presse/RP** : Pas avant d'avoir 50+ missions et un case study solide.

---

**Version** : 3.0.0 (renforcé vagues 1+2+3)
**Date** : 2026-02-17
