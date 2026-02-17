# Workstream Juridique : Plan de Travail Daté

**Date** : 2026-02-17
**Priorité** : P0 — Prérequis mainnet
**Dépendance** : Bloque le déploiement production (Phase 4+)
**Budget estimé** : 8 000 - 15 000 EUR (hors frais notaire SAS)

---

## Pourquoi ce workstream est bloquant

Un smart contract d'escrow qui détient des fonds clients est potentiellement un **service sur actifs numériques** au sens de la loi PACTE (2019) et du règlement MiCA (2024). Déployer sur mainnet sans qualification juridique expose les fondateurs à :

- Sanction AMF (jusqu'à 100M EUR d'amende pour exercice non autorisé)
- Responsabilité personnelle illimitée (absence de structure juridique)
- Requalification des tokens en instruments financiers (gel des actifs)

Ce workstream est **parallèle** au développement technique. Il ne bloque pas le testnet Paseo mais bloque le mainnet.

---

## Jalons et Calendrier

### Semaine 1 (17-23 fév) : Consultation avocat Web3

**Objectif** : Obtenir un avis écrit sur la faisabilité juridique du modèle.

| Action | Livrable | Coût | Responsable |
|--------|----------|------|-------------|
| Identifier 2-3 cabinets spécialisés Web3/crypto en France | Shortlist cabinets | 0 EUR | Fondateurs |
| Consultation flash 2h avec cabinet retenu | Compte-rendu écrit | 500-800 EUR | Fondateurs + avocat |

**Questions à poser impérativement** :

1. **Token REP (Soulbound, non transférable)** : Est-ce un actif numérique au sens de MiCA ? Réponse attendue : non (non transférable, non monétisable), mais confirmation nécessaire.
2. **Token CRED (utilitaire, burn-on-use)** : Risque de qualification comme instrument de paiement ou e-money ? Le fait qu'il soit détruit à la consommation et non échangeable sur marché secondaire devrait l'exclure, mais il faut un avis formel.
3. **Escrow smart contract** : Le service d'escrow nécessite-t-il un enregistrement PSAN auprès de l'AMF ? Le séquestre de fonds en crypto pour le compte de tiers est a priori un service de conservation d'actifs numériques.
4. **KYC/AML** : Quelles obligations de vérification d'identité pour les utilisateurs du marketplace ? Seuils de transaction déclenchant une obligation ?
5. **Structure SAS + Association** : Confirmation que la clause de gouvernance DAO dans les statuts SAS est légale et opposable.

**Cabinets recommandés** (spécialisés Web3 France) :
- **ORWL Avocats** (Paris) — Spécialistes blockchain/crypto, auteurs de publications sur DAOs
- **ADH Avocats** (Paris) — Cités dans la note SAS-DAO, expertise structuration DAO
- **Kramer Levin** (Paris) — Département fintech/crypto

**Critère de succès Semaine 1** : Avis écrit reçu avec recommandations claires sur chacune des 5 questions.

---

### Semaine 2-3 (24 fév - 9 mars) : Création Association loi 1901

**Objectif** : Entité légale pour héberger la gouvernance DAO.

| Action | Livrable | Coût | Délai |
|--------|----------|------|-------|
| Rédiger les statuts de l'Association | Statuts signés | 0 EUR (modèle adapté) | 3 jours |
| Rédiger le règlement intérieur intégrant le protocole de vote on-chain | RI annexé aux statuts | 0 EUR | 2 jours |
| Déclaration en préfecture (en ligne via le-compte-asso.asso.gouv.fr) | Récépissé de déclaration | 0 EUR | 1 jour + 5 jours traitement |
| Publication au Journal Officiel (JOAFE) | Annonce publiée | 0 EUR (gratuit depuis 2020) | 1-2 semaines |

**Contenu clé des statuts Association** :

```
Article 1 — Objet
L'association a pour objet de développer et gouverner un protocole décentralisé
de mise en relation entre clients et prestataires de services (consultants,
agents IA, fournisseurs de compute), incluant la gestion d'une trésorerie
commune via smart contracts sur la blockchain Polkadot.

Article X — Décisions collectives
Les décisions sont prises par vote des membres selon le protocole défini
dans le règlement intérieur. Le vote peut être exercé :
- Par voie électronique via le protocole de vote on-chain (Snapshot ou
  smart contract de gouvernance) ;
- Le résultat du vote, horodaté et enregistré sur la blockchain, fait foi.

Article Y — Bureau
Le Président est élu par vote des membres pour un mandat de 2 ans,
renouvelable. Le résultat du vote on-chain, une fois certifié conforme
par le secrétaire, vaut procès-verbal d'assemblée générale.
```

**Critère de succès Semaine 3** : Récépissé de déclaration reçu, Association juridiquement existante.

---

### Semaine 4-6 (10-23 mars) : Création SAS avec clause DAO

**Objectif** : Entité commerciale pour facturation, contrats clients, responsabilité limitée.

| Action | Livrable | Coût | Délai |
|--------|----------|------|-------|
| Rédiger statuts SAS avec clause de gouvernance DAO (avec avocat) | Statuts SAS | 2 000 - 4 000 EUR (avocat) | 2 semaines |
| Capital social initial | Dépôt capital | 1 EUR minimum (SAS) | 1 jour |
| Immatriculation RCS (via guichet unique INPI) | Extrait Kbis | 37,45 EUR | 1-2 semaines |
| Publication annonce légale | Attestation | 150-250 EUR | 1 jour |

**Clause de gouvernance DAO dans les statuts SAS** (à rédiger avec l'avocat) :

```
Article [N] — Gouvernance déléguée

Les décisions relevant de [liste des catégories : stratégie, budget annuel,
nomination/révocation du Président, modification des frais de la plateforme]
sont soumises au vote préalable des membres de l'Association "[Nom]",
selon le protocole de vote décentralisé défini dans le règlement intérieur
de ladite Association.

Le Président de la SAS est tenu d'exécuter les décisions adoptées par vote
qualifié (≥ 66% des votes exprimés). Le résultat du vote, horodaté et
enregistré sur la blockchain Polkadot, fait foi entre les parties conformément
à l'article 1366 du Code civil.

En cas de désaccord entre le Président et le résultat du vote, une assemblée
générale extraordinaire est convoquée dans les 15 jours.
```

**Critère de succès Semaine 6** : Kbis reçu, SAS immatriculée.

---

### Semaine 6-7 (24-30 mars) : Convention de mandat + assurance

**Objectif** : Lier formellement Association et SAS.

| Action | Livrable | Coût | Délai |
|--------|----------|------|-------|
| Rédiger convention de mandat Association → SAS | Convention signée | 1 000 - 2 000 EUR (avocat) | 1 semaine |
| Souscrire RC Pro couvrant le modèle hybride | Police d'assurance | 1 500 - 3 000 EUR/an | 1-2 semaines |
| Ouvrir compte bancaire SAS (avec mention activité crypto) | RIB professionnel | 0 EUR | 1-2 semaines |

**Contenu de la convention de mandat** :
- L'Association mandate la SAS pour l'exécution opérationnelle (facturation, contrats clients, emploi/contractualisation consultants)
- La SAS rend compte à l'Association trimestriellement (rapport financier + décisions exécutées)
- La trésorerie commune reste sur le Gnosis Safe contrôlé par l'Association (multi-sig)
- Révocabilité du mandat par vote qualifié (≥ 66%)

**Banques acceptant les activités crypto** (France, 2026) :
- **Société Générale / Forge** (filiale crypto SocGen)
- **Delubac & Cie** (première banque française enregistrée PSAN)
- **Olky** (néobanque luxembourgeoise, accepte les entreprises crypto)

**Critère de succès Semaine 7** : Convention signée, RC Pro active, compte bancaire ouvert.

---

### Semaine 8-10 (avril) : Qualification réglementaire

**Objectif** : Sécuriser la conformité avant mainnet.

| Action | Livrable | Coût | Délai |
|--------|----------|------|-------|
| Demander avis formel AMF sur qualification tokens (si nécessaire) | Réponse AMF | 0 EUR | 4-8 semaines |
| Évaluer nécessité enregistrement PSAN | Avis avocat | Inclus dans accompagnement | 1 semaine |
| Si PSAN requis : préparer dossier d'enregistrement | Dossier complet | 3 000 - 5 000 EUR (accompagnement) | 4-6 semaines |
| Mettre en place procédures KYC/AML (si requis) | Process documenté | 500 - 2 000 EUR (provider KYC) | 2 semaines |

**Scénarios possibles** :

| Scénario | Probabilité | Conséquence | Action |
|----------|-------------|-------------|--------|
| REP et CRED hors périmètre MiCA | 60% | Pas d'enregistrement requis | Documenter l'avis, continuer |
| CRED = e-money token | 20% | Enregistrement EME requis | Pivoter vers modèle sans CRED (paiement fiat direct) |
| Escrow = service de conservation | 40% | PSAN requis | Engager procédure PSAN (3-6 mois) |
| Pas d'obligation KYC < 1 000 EUR/tx | 50% | KYC allégé | Vérification email + identité basique |

**Point critique** : Si l'escrow smart contract nécessite un PSAN, le mainnet est retardé de 3-6 mois. **Alternative** : Utiliser un tiers enregistré PSAN (ex: Gnosis Pay, Request Finance) comme intermédiaire pour l'escrow, évitant l'enregistrement direct.

**Critère de succès Semaine 10** : Qualification réglementaire obtenue, stratégie de conformité définie.

---

### Semaine 6-8 (en parallèle) : Cadre IP et Licensing des Livrables

> **Origine** : Vague 1 §2.3 — "Posséder un NFT ≠ posséder les droits IP par défaut.
> Il faut que la licence soit explicitement définie."

**Problème** : Le Parcours C (marketplace de livrables tokenisés) repose sur la vente de licences d'usage. Or un NFT on-chain ne confère **aucun droit de propriété intellectuelle** par défaut. Sans cadre juridique explicite, chaque vente de licence est un litige potentiel.

**Objectif** : Produire un cadre de licensing hybride (off-chain terms + hash on-chain) utilisable dès le MVP.

| Action | Livrable | Coût | Délai |
|--------|----------|------|-------|
| Définir 3 modèles de licence standard (voir ci-dessous) | Templates de licence | 1 000 - 2 000 EUR (avocat) | 1 semaine |
| Rédiger les CGV/CGU incluant la clause IP | CGV mises à jour | Inclus | 1 semaine |
| Valider la compatibilité avec le droit français (CPI) et le droit européen (directive copyright) | Avis écrit | Inclus dans consultation | — |
| Implémenter le hash on-chain des conditions de licence | Spec technique pour `purchaseLicense()` | 0 EUR (dev) | 2 jours |

**3 modèles de licence standard** :

| Licence | Usage | Dérivés | Redistribution | Exclusivité | Prix indicatif |
|---------|-------|---------|----------------|-------------|----------------|
| **L1 — Interne** | Usage interne uniquement | Non | Non | Non | 100-500 EUR |
| **L2 — Commerciale** | Usage interne + intégration dans offre client | Autorisés avec attribution | Non | Non | 500-2 000 EUR |
| **L3 — Exclusive** | Tous usages | Autorisés | Autorisée | Oui (territoire/durée) | 2 000-10 000 EUR |

**Mécanisme hybride off-chain + on-chain** :

```
1. Conditions de licence rédigées en droit français (off-chain, PDF signé)
2. Hash SHA-256 du document de licence stocké on-chain (IPRegistry)
3. purchaseLicense(deliverableId, licenseType) → émet un NFT-licence
   qui référence le hash des conditions
4. Le NFT prouve l'achat ; le PDF prouve les droits
5. En cas de litige → le PDF fait foi (droit civil français, art. 1366 C.civ)
```

**Ce que ça ne couvre PAS (explicitement)** :
- Les livrables produits par un agent IA : qui est l'auteur ? L'opérateur de l'agent ? Le client qui a fourni le brief ? Le droit français (CPI L.111-1) ne reconnaît pas l'IA comme auteur. → L'auteur juridique est **l'opérateur de l'agent** (personne physique ou morale qui l'a paramétré et supervisé).
- Le plagiat / la contrefaçon dans un livrable : → Clause de garantie dans les CGV ("le contributeur garantit que le livrable est original et ne porte pas atteinte aux droits de tiers").

---

### Semaine 6-8 (en parallèle) : Pacte Contributeurs

> **Origine** : Vague 1 §6.A — "Créer un 'pacte' contributeurs :
> droits, devoirs, confidentialité, conflit d'intérêt, réutilisation."

**Problème** : Sans cadre contractuel entre la plateforme et les contributeurs (consultants, auteurs d'agents, curateurs), la responsabilité est diffuse et l'enterprise n'achètera pas.

**Objectif** : Rédiger un pacte contributeur applicable à l'onboarding.

| Action | Livrable | Coût | Délai |
|--------|----------|------|-------|
| Rédiger le pacte contributeur (avec avocat) | Document type | 500 - 1 000 EUR | 1 semaine |
| Intégrer la signature du pacte dans le workflow d'onboarding | Spec produit | 0 EUR | 1 jour |

**Contenu obligatoire du pacte** :

```
1. CONFIDENTIALITÉ
   - Le contributeur s'engage à ne pas divulguer les informations client
     (brief, données, résultats) à des tiers
   - Exception : les livrables rendus publics par le client ou via IPRegistry

2. PROPRIÉTÉ INTELLECTUELLE
   - Le contributeur cède à la plateforme (SAS) une licence non-exclusive
     de reproduction et de distribution des livrables aux fins de licensing
   - Le contributeur conserve le droit moral (attribution)
   - Le contributeur garantit l'originalité du livrable

3. CONFLIT D'INTÉRÊT
   - Le contributeur déclare ne pas être en situation de conflit d'intérêt
     avec le client de la mission
   - Obligation de déclaration si conflit survient en cours de mission

4. QUALITÉ ET RESPONSABILITÉ
   - Le contributeur s'engage à livrer un travail conforme au brief
   - En cas de défaut avéré : la SAS (prime contractor) assume la
     responsabilité vis-à-vis du client et exerce son recours contre
     le contributeur
   - Limitation de responsabilité du contributeur : plafonnée au montant
     de sa rémunération sur la mission

5. GOUVERNANCE
   - Le contributeur accepte les décisions de gouvernance de l'Association
   - Le contributeur peut participer aux votes (si membre de l'Association)

6. RÉSILIATION
   - Le pacte est résiliable à tout moment par le contributeur
   - Les obligations de confidentialité survivent 2 ans après résiliation
```

---

### Semaine 8-10 (en parallèle) : Modèle de Responsabilité "Prime Contractor"

> **Origine** : Vague 1 §4.3 — "L'entreprise acheteuse voudra un interlocuteur
> responsable (un 'prime contractor') — au moins au démarrage."

**Problème** : Une DAO n'a pas de responsabilité juridique en droit français. L'entreprise cliente ne peut pas poursuivre un smart contract. Il faut un interlocuteur identifié.

**Solution** : La SAS est le **prime contractor**. Elle porte la responsabilité contractuelle vis-à-vis du client. La redistribution on-chain est un mécanisme interne.

**Articulation juridique** :

```
CLIENT ←→ SAS (contrat de prestation, droit français)
              |
              ├→ Consultant (sous-traitance, pacte contributeur)
              ├→ Agent IA (opéré par un contributeur identifié)
              └→ Curateur (vérification qualité)

Responsabilité :
- Vis-à-vis du CLIENT : SAS responsable (contrat + RC Pro)
- Vis-à-vis du CONTRIBUTEUR : SAS → recours contractuel
- Paiement : SAS reçoit le paiement fiat → smart contract distribue on-chain
```

**Questions à valider avec l'avocat S1** (à ajouter aux 5 existantes) :

6. **Responsabilité prime contractor** : La SAS peut-elle contractuellement assumer la responsabilité d'un livrable produit par un consultant indépendant ou un agent IA, tout en limitant sa responsabilité au montant de la mission ?
7. **Sous-traitance IA** : Si un agent IA produit un livrable défectueux, qui est responsable juridiquement ? L'opérateur de l'agent ? La SAS ? Le client qui a approuvé ?
8. **Assurance RC Pro** : La RC Pro standard couvre-t-elle les livrables IA ? Faut-il une extension spécifique ?

---

### Semaine 8-10 (en parallèle) : Mécanisme de Dispute Resolution

> **Origine** : Vague 1 §4.3 — "Comment se gère un litige
> (acceptation/rejet abusif, non-conformité, plagiat) ?"

**Problème** : Le smart contract d'escrow a un mécanisme `raiseDispute()` mais pas de cadre juridique pour la résolution.

**Mécanisme en 3 niveaux** :

| Niveau | Déclencheur | Résolution | Délai | Coût |
|--------|-------------|------------|-------|------|
| **1. Médiation interne** | Client ou consultant conteste | Curateur évalue le livrable vs. brief | 5 jours | 0 EUR (curateur rémunéré via commission) |
| **2. Arbitrage DAO** | Médiation échouée | Vote des membres (stake-weighted, quorum 30%) | 7 jours | 0 EUR |
| **3. Arbitrage juridique** | Arbitrage DAO contesté | Tribunal de commerce de Paris (clause attributive) | Variable | Frais judiciaires |

**Clause contractuelle** (à intégrer dans les CGV) :

```
Article [N] — Résolution des litiges

En cas de litige relatif à l'exécution ou la qualité d'une mission,
les parties s'engagent à suivre la procédure suivante :

1. Médiation : le litige est soumis à un curateur qualifié désigné
   par la plateforme. Le curateur rend un avis motivé sous 5 jours
   ouvrés. L'avis est consultatif.

2. Arbitrage communautaire : si la médiation échoue, le litige est
   soumis au vote des membres de l'Association, selon le protocole
   de gouvernance. La décision est exécutoire entre les parties.

3. Juridiction : à défaut d'accord, les parties conviennent de la
   compétence exclusive du Tribunal de commerce de Paris.
```

**Cas d'usage types** :

| Cas | Niveau | Résolution attendue |
|-----|--------|---------------------|
| Client refuse le livrable sans motif | 1 (curateur) | Curateur valide le livrable → paiement libéré |
| Livrable non conforme au brief | 1 (curateur) | Curateur demande correction → nouveau délai |
| Plagiat avéré | 2 (DAO vote) | Contributeur sanctionné (REP burn), client remboursé |
| Consultant disparaît en cours de mission | 1 (auto) | Timer expiré → escrow retourné au client |
| Client refuse de payer malgré livrable validé | 3 (tribunal) | Tribunal de commerce |

---

## Budget Total Workstream Juridique (Mis à Jour)

| Poste | Estimation basse | Estimation haute |
|-------|-----------------|-----------------|
| Consultation avocat Web3 (initiale, 8 questions) | 800 EUR | 1 200 EUR |
| Rédaction statuts SAS (avec avocat) | 2 000 EUR | 4 000 EUR |
| Immatriculation SAS + annonce légale | 200 EUR | 300 EUR |
| Convention de mandat | 1 000 EUR | 2 000 EUR |
| **Templates licences IP (3 modèles)** | **1 000 EUR** | **2 000 EUR** |
| **Pacte contributeurs** | **500 EUR** | **1 000 EUR** |
| RC Pro (annuel, extension IA si nécessaire) | 2 000 EUR | 4 000 EUR |
| Accompagnement PSAN (si nécessaire) | 3 000 EUR | 5 000 EUR |
| **Total** | **10 500 EUR** | **19 500 EUR** |

*Delta vs. version 1.0 : +2 300 EUR (basse) / +4 400 EUR (haute) pour IP + pacte + RC Pro étendue*

---

## Synchronisation avec la Roadmap Technique

| Jalon technique | Prérequis juridique | Gate |
|-----------------|---------------------|------|
| Deploy Paseo testnet | Aucun (testnet = pas de fonds réels) | — |
| Première mission pilote (fiat) | Association créée (structure d'accueil) | Semaine 3 |
| Première mission pilote (crypto) | SAS créée + avis tokens reçu | Semaine 6 |
| Deploy mainnet | SAS + Convention + Qualification PSAN (si requis) | Semaine 10+ |
| Première facturation client | SAS immatriculée + compte bancaire | Semaine 7 |

---

## Budget Total Workstream Juridique

| Poste | Estimation basse | Estimation haute |
|-------|-----------------|-----------------|
| Consultation avocat Web3 (initiale) | 500 EUR | 800 EUR |
| Rédaction statuts SAS (avec avocat) | 2 000 EUR | 4 000 EUR |
| Immatriculation SAS + annonce légale | 200 EUR | 300 EUR |
| Convention de mandat | 1 000 EUR | 2 000 EUR |
| RC Pro (annuel) | 1 500 EUR | 3 000 EUR |
| Accompagnement PSAN (si nécessaire) | 3 000 EUR | 5 000 EUR |
| **Total** | **8 200 EUR** | **15 100 EUR** |

---

## Risques et Mitigations

| Risque | Probabilité | Impact | Mitigation |
|--------|-------------|--------|------------|
| CRED qualifié d'instrument financier | 20% | Bloquant | Pivoter vers paiement fiat pur, CRED = unité de compte interne off-chain |
| PSAN requis pour escrow | 40% | Retard 3-6 mois | Utiliser tiers PSAN ou escrow fiat via SAS |
| Avocat injoignable (délais) | 15% | Retard 2-4 semaines | Contacter 3 cabinets en parallèle |
| Coût > budget | 10% | Dépassement 5-10k EUR | Prioriser : avocat Web3 seul (pas de gros cabinet) |
| Législation DAO France adoptée | 5% (2026) | Simplification possible | Veille juridique continue |
| Litige IP sur livrable IA (auteur indéterminé) | 30% | Litige client | Pacte contributeur + clause "opérateur = auteur" + garantie d'originalité |
| RC Pro ne couvre pas livrables IA | 25% | Gap assurance | Vérifier extension IA dès S1 + assurance complémentaire si nécessaire |
| Client conteste la responsabilité SAS (prime contractor) | 20% | Risque judiciaire | Clause de limitation de responsabilité + médiation 3 niveaux |

---

**Prochaine action immédiate** : Contacter 2-3 cabinets spécialisés Web3 cette semaine pour la consultation flash.

**Version** : 2.0.0 (renforcé vague 1)
**Date** : 2026-02-17
