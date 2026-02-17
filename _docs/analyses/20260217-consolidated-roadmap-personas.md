# Feuille de Route Consolidee : Personas, Attracteurs, Frictions et Strategies

**Date** : 2026-02-17
**Objectif** : Consolider les 4 feuilles de route (juridique, acquisition, technique, financiere) en une timeline unifiee M0-M12, cartographier les attracteurs et frictions par persona, et identifier les meilleures strategies de reduction de friction.
**Sources** : `legal-workstream.md` v2.0, `client-acquisition-plan.md` v3.0, `financial-model.md` v3.0, `REMEDIATION-PLAN.md`, `feedback-synthesis.md` v3.0, `roadmap-impact-study.md`, `Analyse_rm.md`, analyses onboarding et concurrentielles.

---

## 1. Cartographie des Personas

### 1.1 Cote Offre (Contributeurs)

| Persona | Profil | Phase d'entree | Volume cible M12 |
|---------|--------|----------------|------------------|
| **Consultant A** "Expert Mission" | Senior 5-15 ans, ex-Malt/Upwork, specialiste metier | M0 | 30+ actifs |
| **Consultant B** "Auteur d'Agent IA" | Expert senior technophile, veut des revenus passifs | M1-M3 | 10-15 operateurs |
| **Consultant C** "Curateur" | Expert editorial, valide et note les livrables | M3-M6 | 5-10 actifs |
| **Guild Member N0/N1/N2** | Contributeur en progression dans la Guild Metier | M0 (N0), M1+ (N1), M3+ (N2) | 50+ membres |
| **Guild Operator** | Animateur de la communaute Guild | M0 (fondateurs), M3+ (dedie) | 1-2 par guild |
| **Champion Metier** | N2 certifie, valide les livrables a enjeu sur le fond | M3-M6 | 2-3 par guild |

### 1.2 Cote Demande (Clients)

| Persona | Profil | Phase d'entree | Volume cible M12 |
|---------|--------|----------------|------------------|
| **Client PME/Startup** | DG/COO, budget 5-30k EUR/mission, sensible aux frais | M0 | 8-10 actifs |
| **Client ETI** | DSI/CTO/CDO/DG, budget 10-200k EUR, processus procurement | M3-M6 | 3-5 actifs |
| **Early Adopter IA** | CTO/CDO tech, veut des equipes hybrides humain+IA | M1-M3 | 2-3 actifs |

---

## 2. Matrice Attracteurs / Frictions par Persona

### 2.1 Consultant A — "Expert Mission"

| Attracteurs (ce qui attire) | Frictions (ce qui bloque) |
|-----------------------------|---------------------------|
| Frais 0% consultant (vs 10-20% Malt/Upwork) | Inconfort technique wallet/blockchain |
| Reputation portable on-chain (REP soulbound) | Pas de track record initial sur la plateforme |
| Escrow = garantie de paiement | Fiscalite tokens DAOS complexe |
| Paiement instantane (vs 30-60j facture) | Delai pour decrocher la 1ere mission (2-4 sem.) |
| Gouvernance (co-proprietaire de la plateforme) | Transparence symetrique (track record public) |
| Progression meritocratique N0→N2 | Tests d'admission Guild exigeants (rubric >= 8/12) |

**Friction dominante** : L'inconfort crypto et l'absence de masse critique (pas de clients = pas de missions).

### 2.2 Consultant B — "Auteur d'Agent IA"

| Attracteurs | Frictions |
|-------------|-----------|
| Revenus passifs (agent tourne 24/7) | Investissement initial 3-5 jours/agent |
| ROI documente : 4 000 EUR/mois en passif | AIAgentRegistry.sol non implemente |
| Seule plateforme "vendre expertise, pas temps" | Admission exigeante (3 cas tests + curateur) |
| Accumulation REP automatique de l'agent | Risque reputationnel si agent produit mal |

**Friction dominante** : L'infrastructure technique n'existe pas encore (AIAgentRegistry non deploye). Aucun "proof of concept" visible.

### 2.3 Consultant C — "Curateur"

| Attracteurs | Frictions |
|-------------|-----------|
| Commission 10% sur licences des livrables cures | Revenus faibles tant que le catalogue est petit |
| REP pour participation → influence gouvernance | Responsabilite si livrable cure est defaillant |
| Role valorisant de "gardien qualite" | Pas de parcours d'onboarding dedie au MVP |
| Modele flexible (pas d'obligation de mission active) | Audit aleatoire 1/10 par le GAB |

**Friction dominante** : Pas de revenu significatif avant M6+ (depend du volume Parcours C).

### 2.4 Client PME/Startup

| Attracteurs | Frictions |
|-------------|-----------|
| Frais 5% (vs 20% Malt) = economie 1 500 EUR/10k EUR | Peur du mot "blockchain" |
| Scoring transparent 5 criteres | Pas de reference terrain (0 mission completee) |
| Escrow automatique (0 risque non-paiement) | Obligation initiale d'achat de tokens |
| Dispute resolution neutre (3 niveaux) | Pas de facturation classique EUR au MVP |
| Quality Card visible avant achat | Pas de SAS/structure juridique encore creee |

**Friction dominante** : L'absence de structure juridique (SAS) et l'absence de premiere reference terrain. Sans la SAS, pas de facture, pas de contrat, pas de client enterprise.

### 2.5 Client ETI

| Attracteurs | Frictions |
|-------------|-----------|
| Acheter des resultats documentes (DoD + Quality Card) | Le mot "blockchain" declenche peur compliance |
| Cabinet composable : choisir les competences a la carte | Process procurement 6-12 mois |
| Missions standardisees (Diagnostic, TOM, SDSI, RACI) | Exigence de confidentialite (NDA automatique) |
| Human refinement = filet de securite sur IA | Pas de reference PME validee au M3 |
| SAS prime contractor (responsabilite claire) | Droits IP : besoin des 3 modeles L1/L2/L3 actifs |
| Facturation droit francais | RC Pro etendue requise |

**Friction dominante** : L'ETI ne signe pas sans reference, sans SAS, sans cadre IP, et sans RC Pro. Toutes les conditions doivent etre reunies simultanement — c'est une gate "tout ou rien".

### 2.6 Early Adopter IA/Compute

| Attracteurs | Frictions |
|-------------|-----------|
| Livrable IA en < 2h (Parcours B) | AIAgentRegistry non implemente |
| HybridPaymentSplitter natif (70/20/10) | Pas de catalogue d'agents existant |
| Cout 5-10x inferieur a une mission classique | Risque confusion "GPT wrapper marketplace" |
| Agents IA comme first-class citizens | Curation gate ajoute un delai |

**Friction dominante** : Aucun agent IA n'existe sur la plateforme. L'early adopter IA n'a rien a acheter avant M3.

---

## 3. Timeline Consolidee M0-M12

### Phase 0 : Fondations (S1-S4 / M0-M1)

```
JURIDIQUE         ACQUISITION          TECHNIQUE           FINANCIER
S1: Avocat Web3   S1: 20 contacts      Week 1-2: Vitest    One-shot: 17-37k EUR
    8 questions       15 messages           + event-sync     Cout fixe: 825 EUR/mois
S2-3: Association S2: 5 appels quali    Week 3: Tests       Rev M1: 250-800 EUR
      loi 1901       3 pilotes              15+ passing
                  S3: 1 mission         Week 4-5: Docs
                     manuelle E2E           + pre-commit
                  S4: Feedback loop
```

**Personas actifs** : Consultant A (3-5 pionniers), Client PME (1-3 pilotes)
**Gate Phase 0** : >= 1 mission completee, NPS >= 7, <= 2 frictions bloquantes

| Persona | Ce qu'il fait | Ce qui le bloque encore |
|---------|---------------|------------------------|
| **Consultant A** | Rejoint via reseau fondateurs. Fait 1 mission pilote manuelle. | Pas de plateforme. Matching = tableur. Escrow = virement. |
| **Client PME** | Envoie un brief par email. Evalue le scoring sur tableur. | Pas de SAS → pas de facture. Pas d'escrow crypto. Trust = confiance personnelle dans le fondateur. |

**Frictions critiques de la phase** :
1. Pas de SAS (en cours S4-S6) → facturation impossible
2. Pas d'Association → pas de structure d'accueil
3. 0 reference terrain → tout repose sur le reseau personnel
4. Backend sans tests → risque technique latent

### Phase 1 : Traction (M2-M3)

```
JURIDIQUE           ACQUISITION           TECHNIQUE            FINANCIER
S4-6: Creation SAS  S5-S8: 3-5 leads/sem  Week 4-5: Backend    Rev M3: 1 050-3 500 EUR
S6-7: Convention     S6-8: Test Parcours B  security audit      Breakeven op.: M3 (real.)
  + RC Pro           10 missions            (Phase 3 Remed.)    ou M12 (pessim.)
S6-8: Templates IP   20 consultants                             Gate 1 financier
  + Pacte contrib.                                               >=10 missions, >=1k EUR/m
```

**Personas actifs** : +Consultant B (premiers agents), +Early Adopter IA (test Parcours B), +N0/N1 Guild

| Persona | Ce qu'il fait | Ce qui le bloque encore |
|---------|---------------|------------------------|
| **Consultant A** | 10-20 inscrits. Premieres missions via plateforme. N0→N1 possible. | Masse critique faible (peu de clients = peu de missions). |
| **Consultant B** | Cree 1 agent IA specialise. Propose 3 livrables IA pilotes. | AIAgentRegistry minimal. Admission exigeante. |
| **Client PME** | 3-5 actifs. Achete missions classiques. Teste 1 livrable IA. | Cadre IP pas encore formalise si Parcours C pas active. |
| **Early Adopter IA** | Teste le Parcours B sur un brief reel. Evalue cout/qualite. | Catalogue IA quasi inexistant. Curation gate a roder. |
| **Guild N0→N1** | Passe le test standardise. Fait 1 mission supervisee. | Score rubric >= 8/12 peut sembler arbitraire sans historique. |

**Frictions critiques de la phase** :
1. Gate 1 Parcours B : taux acceptation livrable IA > 30% ou pivot
2. SAS operationnelle mais pas encore de RC Pro etendue → gap assurance
3. Cadre IP pas finalise → blocage Parcours C
4. Audit securite backend pas termine → risque exploit testnet

**Decision Gate M3** :

| Critere | Go | Pivot | Stop |
|---------|----|-------|------|
| Missions completees (cumul) | >= 10 | 5-9 | < 5 |
| Revenu mensuel | > 1 000 EUR | 500-1 000 EUR | < 500 EUR |
| NPS moyen | >= 7 | 5-7 | < 5 |
| Clients recurrents | >= 2 | 1 | 0 |
| Parcours B teste | Oui (1 mission IA) | Non mais demande | Aucun interet |

### Phase 2 : Product-Market Fit (M3-M6)

```
JURIDIQUE           ACQUISITION           TECHNIQUE            FINANCIER
S8-10: Qualif PSAN  5-15 missions/mois    Mainnet deploy       Rev M6: 4 350-14 500 EUR
  + KYC/AML         50 consultants         (si PSAN OK)        Marketing: 2-5k EUR/mois
                    15 clients actifs      Audit Solidity       Gate 2: GMV > 50k EUR
                    LinkedIn Ads           5+ agents IA          1er salaire si Go
                    Ambassadeurs
```

**Personas actifs** : +Consultant C (curateurs), +Client ETI (premiers), +Champion Metier, +Guild Operator dedie

| Persona | Ce qu'il fait | Ce qui le bloque encore |
|---------|---------------|------------------------|
| **Consultant A** | 30-50 inscrits. N1→N2 possibles. Missions regulieres. | Concurrence Malt/Upwork sur les memes profils. |
| **Consultant B** | 5-10 agents actifs. Revenus passifs commencent. | Qualite variable des agents → NPS a surveiller. |
| **Consultant C** | Premiers curateurs actifs. Curation Gate 2 operationnelle. | Volume de licences encore faible (Parcours C naissant). |
| **Client PME** | 8-12 actifs. Missions recurrentes. Case studies publies. | Eventuel retard PSAN → pas de crypto/mainnet. |
| **Client ETI** | 1-3 entrent. Testent le Pack Diagnostic SI & Gouvernance 360. | Process procurement long. Exige reference PME prealable. |
| **Early Adopter IA** | Commande regulierement des livrables IA cures. | Veut plus d'agents et de domaines couverts. |
| **Champion Metier** | Valide livrables > 5k EUR ou strategiques (Gate 2b). | Disponibilite limitee (role non remunere). |
| **Guild Operator** | Anime weekly reviews. Maintient catalogue. Publie scoreboard. | Charge croissante. Remuneration 500-1 000 EUR/mois. |

**Frictions critiques de la phase** :
1. PSAN potentiellement requis → retard mainnet 3-6 mois
2. ETI exige reference + RC Pro + cadre IP → gate "tout ou rien"
3. Scalabilite Guild Operator (1 personne pour 50 missions/mois ?)
4. Seuil rubric 8/12 : trop haut ? Trop bas ? Donnees terrain manquent

**Decision Gate M6** :

| Critere | Go (Scale) | Pivot |
|---------|-----------|-------|
| GMV mensuel | > 50k EUR | 20-50k EUR |
| Revenu mensuel | > 3 000 EUR | 1 500-3 000 EUR |
| Missions IA (si Parcours B valide) | > 30% du total | < 10% |
| Taux conversion brief→mission | > 40% | < 25% |

### Phase 3 : Scale (M6-M12)

```
JURIDIQUE           ACQUISITION           TECHNIQUE            FINANCIER
Maintenance         50+ missions/mois     Migration Substrate  Rev M12: 18 250-62 500 EUR
Veille MiCA         100+ consultants       POC (si Gate 2 OK)  Marge nette > 50%
Expansion inter.?   30+ clients            Parachain eval.     Gate 3: GMV > 150k EUR
                    20+ agents IA          (si > 100 mis/j)    1er salaire dev/ops
                    Parcours C actif
```

**Personas actifs** : Tous. +Sous-DAOs sectorielles potentielles.

| Persona | Ce qu'il fait | Ce qui le bloque encore |
|---------|---------------|------------------------|
| **Consultant A** | Fidele. N2 certifie. Recommande la plateforme. | Si NPS < 8, risque churn vers Malt/Toptal. |
| **Consultant B** | 15+ agents. Revenus passifs significatifs (4 000+ EUR/mois). | Qualite variable si trop d'agents. Besoin de curation forte. |
| **Consultant C** | Curateurs actifs. Revenus Parcours C croissants. | Risque de complaisance si volume trop eleve/personne. |
| **Client PME** | Fidele. Plusieurs missions. Recommande. | Eventuel plafonnement si offre trop specialisee. |
| **Client ETI** | 3-5 actifs. Missions recurrentes. Upsell TOM→SDSI. | Exige SLA formels, reporting, confidentialite renforcee. |
| **Guild Operator** | Potentiellement 2 operators (1 par guild si 2eme guild lancee). | Formaliser le role, governance du role. |

---

## 4. Analyse Croisee : Frictions Structurelles par Phase

### 4.1 Carte de Chaleur des Frictions

```
                    M0-M1    M2-M3    M3-M6    M6-M12
                    ------   ------   ------   ------
Pas de SAS/facture   ████     ██       ░░       ░░
Pas de reference     ████     ███      ██       ░░
Peur blockchain      ███      ███      ██       █░
Pas d'agent IA       ███      ██       █░       ░░
Masse critique       ████     ███      ██       █░
Cadre IP manquant    ███      ██       ░░       ░░
PSAN incertain       ██       ███      ███      █░
Fiscalite tokens     ██       ██       ██       ██
Rubric calibrage     ░░       ██       ███      ██
Scalab. Operator     ░░       ░░       ██       ███
```

`████` = bloquant | `███` = friction forte | `██` = friction moderee | `█░` = friction faible | `░░` = resolu

### 4.2 Les 5 Frictions les Plus Critiques (ordonnees par impact)

| # | Friction | Personas impactes | Phase critique | Impact si non resolue |
|---|----------|-------------------|----------------|------------------------|
| **F1** | Absence de structure juridique (SAS + Association) | TOUS | M0-M1 | Aucune mission facturee, aucun contrat, responsabilite personnelle des fondateurs |
| **F2** | Zero reference terrain (0 mission completee) | Tous les clients | M0-M3 | 90% d'echec Web3 = pas de cas d'usage reel. Impossible de convaincre un 2e client sans 1er success story |
| **F3** | Masse critique insuffisante (poule et oeuf) | Consultant A + Client PME | M0-M6 | Pas de client → pas de consultant → pas de client. Spirale negative. |
| **F4** | Peur du mot "blockchain" cote enterprise | Client PME + ETI | M0-M6 | Rejet immediat par procurement, conformite, reputation |
| **F5** | Infrastructure IA inexistante (AIAgentRegistry) | Consultant B + Early Adopter | M0-M3 | Le differenciateur principal (Parcours B) n'est pas livrable |

---

## 5. Strategies de Reduction de Friction

### Strategie 1 : "Structure First" — Debloquer F1 en priorite absolue

**Friction ciblee** : F1 (pas de SAS/Association)
**Personas debloques** : TOUS
**Timeline** : S1-S6 (deja planifie dans `legal-workstream.md`)

| Action | Semaine | Effet sur les personas |
|--------|---------|------------------------|
| Consultation avocat Web3 (8 questions) | S1 | Securise le modele → fondateurs rassures |
| Creation Association loi 1901 | S2-S3 | Structure d'accueil pour gouvernance → Consultant A peut "rejoindre" |
| Creation SAS + clause DAO | S4-S6 | Facturation possible → **debloque Client PME** |
| Convention + RC Pro | S6-S7 | Responsabilite claire → **prerequis Client ETI** |
| Templates IP + Pacte contributeur | S6-S8 | Cadre IP → **debloque Parcours C** |

**Cout** : 10 500-19 500 EUR (incompressible)
**ROI** : Sans cette depense, revenu = 0 EUR.

### Strategie 2 : "Reference Zero" — Resoudre F2 par l'execution manuelle

**Friction ciblee** : F2 (zero reference)
**Personas debloques** : Client PME (confiance), Consultant A (preuve que ca marche)
**Timeline** : S1-S4

| Action | Detail | Persona implique |
|--------|--------|------------------|
| 1 mission pilote 100% manuelle (S3) | Brief par email, matching tableur, escrow = virement SAS | Client PME + Consultant A |
| NPS > 7 collecte (S4) | Typeform post-mission | Client PME |
| Case study redige et publie (S4) | 1 page LinkedIn + blog | Tous les prospects |
| Verbatim client cite dans les messages d'approche | "Economie de 1 200 EUR, matching transparent, mission livree en 12j" | Client PME prospect |

**Cout** : 0 EUR
**Principe** : Pas de code, pas de blockchain. Prouver la valeur avec des outils existants (email, tableur, virement).
**Condition** : L'Association (ou au minimum un compte bancaire personnel) doit exister pour recevoir l'escrow fiat.

### Strategie 3 : "Bowling Pin" — Resoudre F3 par la sequentialite

**Friction ciblee** : F3 (masse critique)
**Personas debloques** : Tous (en sequence)
**Timeline** : M0-M12

Le probleme poule-oeuf se resout en ciblant les segments dans un ordre precis (strategie "bowling pin") :

```
Pin 1 (M0-M1) : Consultants tech/data du reseau personnel des fondateurs
                 → 3-5 consultants → 1-3 clients PME (reseau croise)
                 |
Pin 2 (M1-M3) : PME "frustres Malt" (sensibles aux frais 5%)
                 → 5-8 clients PME → 10-20 consultants attires par les missions
                 |
Pin 3 (M3-M6) : ETI (via reference PME + Pack Diagnostic SI)
                 → 1-3 ETI → consultants seniors attires par budgets ETI
                 |
Pin 4 (M6+)   : Ecosystem (agents IA, licences, sous-DAOs)
                 → Flywheel : chaque livrable genere du contenu vendable
```

**Mecanismes d'acceleration** :

| Mecanisme | Comment ca accelere | Phase |
|-----------|---------------------|-------|
| **Frais 0% consultant** | Argument de recrutement massif vs Malt (20%) | M0+ |
| **Frais 0% 3 premieres missions client** | Reduit le risque d'essai a zero | M0-M3 |
| **Sponsor/Vouch (+5 REP)** | Les bons consultants recrutent d'autres bons | M1+ |
| **Case study publics** | Chaque mission terminee genere une preuve sociale | M1+ |
| **Programme ambassadeurs (200 EUR/referral)** | Viralite incentivee a M3+ | M3+ |

### Strategie 4 : "Blockchain Invisible" — Resoudre F4 par le reframing

**Friction ciblee** : F4 (peur blockchain)
**Personas debloques** : Client PME, Client ETI
**Timeline** : M0+ (permanent)

| Principe | Application concrete |
|----------|---------------------|
| **Ne jamais dire "blockchain"** dans le pitch commercial | "Cabinet d'expertise composable et productise" |
| **Ne jamais exiger un wallet** pour le client | Wallet-as-a-Service (Magic.link/Privy) invisible |
| **Ne jamais exiger d'achat de tokens** pour commencer | Paiement CB/virement. Token = mecanisme interne. |
| **Blockchain = couche de preuve** | "Votre contrat est securise par un registre immuable" (pas "smart contract") |
| **Test de realite 5 points** | Verifier a chaque mission : SI, responsabilite, IP, qualite, UX |
| **Experience SaaS** | Dashboard, suivi mission, paiement CB. Zero friction crypto. |

**Vocabulaire interdit vs autorise** :

| Interdit | Autorise |
|----------|----------|
| Smart contract | Contrat automatise / registre securise |
| Token REP | Indice de reputation / badge |
| DAO | Collectif d'experts / gouvernance partagee |
| Wallet | Compte securise |
| Escrow on-chain | Budget bloque et protege |
| Mint / burn | Attribuer / retirer |

### Strategie 5 : "IA Progressive" — Resoudre F5 par le MVP minimal

**Friction ciblee** : F5 (pas d'infrastructure IA)
**Personas debloques** : Consultant B, Early Adopter IA
**Timeline** : M1-M3

Le differenciateur (Parcours B) est le plus risque car l'infrastructure n'existe pas. La strategie est de **valider la demande avant de construire** :

| Etape | Semaine | Ce qu'on fait | Ce qu'on apprend |
|-------|---------|---------------|------------------|
| **1. Agent artisanal** | S6 | 1 agent IA construit manuellement (GPT-4 API + prompts + templates). Pas de smart contract. | Le client veut-il un livrable IA ? A quel prix ? |
| **2. Test 3 clients** | S7 | Proposer l'agent a 3 clients pilotes sur un brief existant | Taux d'acceptation, qualite percue, prix acceptable |
| **3. Curation manuelle** | S7-S8 | Fondateur cure le livrable IA a la main (pas de Gate 1 auto) | Temps de curation, % de rework, qualite post-curation |
| **4. Go/No-Go** | S8 | Decide : investir dans AIAgentRegistry ou pivoter Parcours A seul | Parcours B valide ou non |

**Si Go Parcours B** :
- M3 : Agent Listing Standard + admission par curateur
- M3-M4 : AIAgentRegistry.sol deploye sur Paseo
- M4+ : Catalogue d'agents public + Quality Card

**Si No-Go Parcours B** :
- Focus exclusif Parcours A (missions classiques augmentees)
- Budget dev economise (~4-6 semaines)
- Les consultants B sont rediriges vers des missions classiques

### Strategie 6 : "Quality Card comme Convertisseur ETI" — Reduire la friction de confiance

**Friction ciblee** : Confiance qualite (Client ETI + Client PME)
**Timeline** : M1+ (incrementale)

L'ETI ne signe pas sur promesse. Elle signe sur **preuve documentee**. La Quality Card + le human refinement sont les deux mecanismes de conversion :

```
ETI hesite (M3)
    |
    ├─ Voit la Quality Card d'un livrable similaire deja produit
    │    → "Tracabilite 8/10, Clarte 9/10, Adequation 7/10"
    │    → "Cure par Marie L. (REP 92), taux rework 0%"
    │
    ├─ Choisit l'option "Human Refinement" (IA brut + humain = 1 500-5 000 EUR)
    │    → Filet de securite. Resultat garanti par un consultant senior.
    │
    ├─ Recoit le livrable avec rubric 10/12 + champion metier valide
    │    → Confiance etablie. 2eme mission sans human refinement.
    │
    └─ Parcours de confiance : human refinement → IA curee seule → full IA
         (6-12 mois de maturation)
```

**KPI de cette strategie** :
- Taux de conversion ETI ayant vu Quality Card vs. sans : cible +30%
- Taux de human refinement sur 1ere mission ETI : cible > 70%
- Taux de human refinement sur 3eme mission ETI : cible < 30%

### Strategie 7 : "Guild comme Marque de Confiance" — Reduire la friction structurelle

**Friction ciblee** : Qualite variable + onboarding + retention communaute
**Personas debloques** : Consultant A/B/C + Client ETI
**Timeline** : M0-M6

La Guild n'est pas un "nice-to-have communautaire". C'est **l'unite de production qui garantit la qualite** :

| Probleme | Comment la Guild le resout |
|----------|---------------------------|
| Qualite variable des consultants | Rubric 4 criteres × 0-3 = score objectif. Seuil 8/12 pour N1. |
| Pas de filtrage a l'entree | 3 paliers (N0/N1/N2) avec tests standardises par ligne de produit |
| Pas de consequences en cas de sous-performance | Sponsor perd REP (-10/mission ratee). Entrant desactive apres 2 echecs. |
| Pas de curation de confiance | Audit aleatoire 1/10 par le GAB. Complaisance = perte role curateur. |
| Pas de standards metier | Guild Quality Rubric + templates + DoD par type de livrable |
| Pas d'animation communaute | Guild Operator : 5 rituels (weekly, catalogue, onboarding, scoreboard, retro) |

**La guild pilote "Org & SI"** est strategique car :
1. Le conseil en organisation et SI est hyper productisable (livrables cadres)
2. Forte demande ETI (toute ETI en croissance a besoin d'un SDSI)
3. 4 lignes de produits progressives : Diagnostic → TOM → SDSI → Gouvernance RACI
4. Le Pack #1 Diagnostic (8-15k EUR) est le meilleur point d'entree ETI

---

## 6. Synthese : Matrice Strategie × Phase × Persona

| Strategie | M0-M1 | M2-M3 | M3-M6 | M6-M12 | Personas cles |
|-----------|-------|-------|-------|--------|---------------|
| **S1 Structure First** | `████` | `██░░` | `░░░░` | `░░░░` | TOUS |
| **S2 Reference Zero** | `████` | `██░░` | `░░░░` | `░░░░` | Client PME, Consultant A |
| **S3 Bowling Pin** | `████` | `████` | `████` | `██░░` | TOUS (en sequence) |
| **S4 Blockchain Invisible** | `████` | `████` | `████` | `████` | Client PME, Client ETI |
| **S5 IA Progressive** | `░░░░` | `████` | `██░░` | `░░░░` | Consultant B, Early Adopter |
| **S6 Quality Card Convertisseur** | `░░░░` | `██░░` | `████` | `████` | Client ETI |
| **S7 Guild comme Marque** | `██░░` | `████` | `████` | `████` | Consultant A/B/C, Client ETI |

`████` = effort maximal cette phase | `██░░` = effort modere | `░░░░` = pas encore ou resolu

---

## 7. Plan d'Action Consolide par Quinzaine

### Q1 (S1-S2) — "Demarrer sans rien"

| Piste | Actions | Personas actives | Livrable |
|-------|---------|------------------|----------|
| S1 Structure | Consultation avocat 8 questions. Demarrer Association. | Fondateurs | Avis ecrit |
| S2 Reference | 15 messages LinkedIn. 5 appels quali. | Consultant A, Client PME | 3 pilotes identifies |
| S4 Blockchain Invisible | Rediger pitch "cabinet composable" (pas "DAO blockchain") | Client PME | Script d'approche valide |

### Q2 (S3-S4) — "Premiere mission"

| Piste | Actions | Personas actives | Livrable |
|-------|---------|------------------|----------|
| S1 Structure | Association declaree. SAS en cours. | Fondateurs | Recepisse Association |
| S2 Reference | 1 mission pilote manuelle E2E. Feedback. Case study. | Consultant A, Client PME | NPS >= 7, case study |
| S3 Bowling Pin | Pin 1 : 3-5 consultants + 1-3 clients (reseau) | Consultant A, Client PME | Pipeline actif |
| Technique | Vitest setup. 15+ tests. Event-sync hardening. | Dev | Gate 1 technique |

### Q3 (S5-S6) — "Premieres missions plateforme"

| Piste | Actions | Personas actives | Livrable |
|-------|---------|------------------|----------|
| S1 Structure | SAS immatriculee. Kbis recu. | Fondateurs | SAS operationnelle |
| S3 Bowling Pin | Pin 2 : 3-5 leads/sem. 1 mission/sem. | Consultant A, Client PME | 3-5 missions (cumul) |
| S5 IA Progressive | 1 agent artisanal. Test 3 clients. | Consultant B, Early Adopter | Go/No-Go Parcours B |
| S7 Guild | Lancer Guild "Org & SI". Premiers N0 cooptes. | Guild N0, Fondateurs (Operator) | 5 membres N0 |

### Q4 (S7-S8) — "Scale initial"

| Piste | Actions | Personas actives | Livrable |
|-------|---------|------------------|----------|
| S1 Structure | Convention + RC Pro + templates IP + pacte contributeur | Fondateurs, Avocat | Cadre juridique complet |
| S3 Bowling Pin | 5-8 leads/sem. 2 missions/sem. | Consultant A/B, Client PME | 10 missions (cumul) |
| S5 IA Progressive | Si Go : Agent Listing Standard. Admission curateur. | Consultant B | Premiers agents listes |
| S6 Quality Card | Deployer Quality Card sur livrables cures | Client PME, Curateur | Quality Cards visibles |
| S7 Guild | Premiers N1 (test rubric >= 8/12 + 1 livrable accepte) | Guild N0→N1 | 3-5 N1 valides |
| Technique | Backend security audit (Phase 3 Remediation) | Dev | 12+ security tests |

### Q5-Q6 (S9-S12 / M3) — "Gate 1"

| Piste | Actions | Personas actives | Livrable |
|-------|---------|------------------|----------|
| S1 Structure | Qualification PSAN (si necessaire). KYC/AML. | Fondateurs, Avocat | Avis AMF |
| S3 Bowling Pin | Pin 3 : premiers contacts ETI (via reference PME) | Client ETI, Champion Metier | 1-3 ETI en pipeline |
| S5 IA Progressive | AIAgentRegistry deploye Paseo. 3-5 agents. | Consultant B, Early Adopter | Catalogue minimal |
| S6 Quality Card | Human refinement operationnel | Client ETI | 1ere mission ETI lancee |
| S7 Guild | Guild Operator dedie (M3+). GAB constitue. | Guild Operator, GAB | Governance Guild formelle |
| Financier | **GATE 1** : >= 10 missions, >= 1 000 EUR/mois, NPS >= 7 | Fondateurs | Decision Go/Pivot/Stop |

### M4-M6 — "Product-Market Fit"

| Piste | Actions | Personas actives | Livrable |
|-------|---------|------------------|----------|
| S3 Bowling Pin | 8-15 missions/mois. LinkedIn Ads. Ambassadeurs. | TOUS | 50 missions (cumul) |
| S4 Blockchain Invisible | Experience SaaS complete. CB/virement. 0 friction crypto. | Client PME, ETI | Dashboard + paiement |
| S6 Quality Card | Parcours de confiance ETI (human refinement → IA seule) | Client ETI | 2-3 ETI recurrents |
| S7 Guild | Premiers N2 (3 missions + score >= 9/12 + vote GAB) | Guild N2, GAB | Champions metier actifs |
| Financier | **GATE 2** : GMV > 50k EUR, > 3 000 EUR/mois, conversion > 40% | Fondateurs | Decision Scale/Pivot |

### M6-M12 — "Scale"

| Piste | Actions | Personas actives | Livrable |
|-------|---------|------------------|----------|
| S3 Bowling Pin | 30-50 missions/mois. Parcours C actif (licences). | TOUS | 100+ missions (cumul) |
| S7 Guild | 2eme guild ? Evaluation. | Fondateurs | Decision multi-guild |
| Technique | Substrate POC (si Gate 2 OK et performance > 2x) | Dev | POC livre |
| Financier | **GATE 3** : GMV > 150k EUR, licences > 30% revenus | Fondateurs | Decision Scale/Maintien |

---

## 8. Indicateurs de Suivi par Persona

### Dashboard mensuel recommande

| Persona | KPI principal | Cible M3 | Cible M6 | Cible M12 | Signal d'alerte |
|---------|---------------|----------|----------|-----------|-----------------|
| **Consultant A** | Churn mensuel | < 20% | < 15% | < 10% | > 25% |
| **Consultant A** | NPS consultant | >= 7 | >= 8 | >= 9 | < 6 |
| **Consultant B** | Agents actifs | 1-3 | 5-10 | 15-20 | 0 a M6 |
| **Consultant B** | NPS livrable IA | >= 6 | >= 7 | >= 8 | < 5 |
| **Consultant C** | Livrables cures/mois | 5 | 15 | 40 | < 3 a M6 |
| **Client PME** | NPS client | >= 7 | >= 8 | >= 8 | < 6 |
| **Client PME** | Missions recurrentes (% clients) | >= 30% | >= 50% | >= 60% | < 20% |
| **Client ETI** | Nombre actifs | 0 | 1-3 | 3-5 | 0 a M6 |
| **Client ETI** | Taux human refinement (1ere mission) | — | > 70% | < 30% (3e mission) | 100% a M9 |
| **Early Adopter IA** | Taux acceptation livrable IA | > 30% | > 50% | > 70% | < 10% a M3 |
| **Guild** | Membres N1+ | 3-5 | 10-15 | 25-30 | < 5 a M6 |
| **Guild** | Score rubric moyen | >= 8/12 | >= 9/12 | >= 9/12 | < 7/12 |

---

## 9. Risques Residuels et Mitigations

| Risque | Probabilite | Personas impactes | Mitigation | Plan B |
|--------|-------------|-------------------|------------|--------|
| 0 client M0-M3 | 15% | TOUS | Reference Zero (S2) + bowling pin (S3) | Pivoter segment ou proposition de valeur |
| PSAN bloque mainnet | 40% | Client PME/ETI, Consultant B | Escrow fiat via SAS (plan B legal) | Tiers PSAN (Gnosis Pay, Request Finance) |
| Parcours B echoue (NPS < 5) | 30% | Consultant B, Early Adopter | Pivot Parcours A seul | Budget dev economise (4-6 semaines) |
| Sybil/gaming M3+ | 20% | Guild, Tous | 5 regles anti-gaming + audit aleatoire | Communaute fermee prolongee |
| Guild Operator sature M6+ | 40% | Guild, Consultant A/B | 2eme operator + automatisation scoreboard | Reduire frequence rituels |
| ETI ne signe jamais | 25% | Client ETI, Champion Metier | Focus PME uniquement | Revenu PME suffit (scenario realiste) |
| Hack testnet (reputation) | 10% | TOUS | Audit securite backend (Phase 3) + audit Solidity | Bug bounty program |
| Fondateur quitte M0-M6 | 15% | TOUS | Documentation + succession plan | Recruter (possible seulement si revenus > 0) |

---

## 10. Verdict : Les 3 Actions les Plus Impactantes

Si l'equipe ne pouvait faire que 3 choses dans les 30 prochains jours :

### Action 1 : Creer la SAS (Semaine 1-6)

**Pourquoi** : Sans SAS, aucun persona ne peut etre active. Pas de facture, pas de contrat, pas de RC Pro, pas de responsabilite. C'est le verrou numero 1.
**Impact** : Debloque TOUS les personas.
**Cout** : 2 200-4 300 EUR + 500-800 EUR avocat.

### Action 2 : Completer 1 mission pilote manuelle (Semaine 3-4)

**Pourquoi** : 0 reference = 0 credibilite. 1 mission completee avec NPS >= 7 = proof of concept. Le case study genere devient l'argument commercial pour les 10 suivantes.
**Impact** : Debloque Client PME + Consultant A.
**Cout** : 0 EUR.

### Action 3 : Tester 1 agent IA sur 3 clients (Semaine 6-8)

**Pourquoi** : Le Parcours B est le vrai differenciateur mais il est non valide. Un test artisanal (0 code, GPT-4 API + prompts) en 3 jours revele si la demande existe.
**Impact** : Go/No-Go sur le differenciateur principal. Si Go → Consultant B + Early Adopter entrent. Si No-Go → focus Parcours A, economie 4-6 semaines de dev.
**Cout** : 0 EUR (API costs negligeables).

---

**Version** : 1.0.0
**Date** : 2026-02-17
**Documents source** : `legal-workstream.md` v2.0, `client-acquisition-plan.md` v3.0, `financial-model.md` v3.0, `REMEDIATION-PLAN.md`, `feedback-synthesis.md` v3.0
