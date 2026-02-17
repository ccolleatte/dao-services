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

---

**Prochaine action immédiate** : Contacter 2-3 cabinets spécialisés Web3 cette semaine pour la consultation flash.

**Version** : 1.0.0
**Date** : 2026-02-17
