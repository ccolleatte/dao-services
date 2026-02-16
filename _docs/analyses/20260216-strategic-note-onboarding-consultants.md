# Note stratégique : Onboarding consultants

**Date** : 2026-02-16
**Axe** : Suppression des barrières techniques pour l'adoption DAO par les consultants
**Horizon** : M0 -> M24

---

## 1. Contexte et enjeux

La barrière technique est la faiblesse la plus immédiatement disqualifiante du modèle DAO pour le conseil. Les consultants seniors (cible primaire) sont rarement familiers avec les wallets blockchain. Les processus d'onboarding Web3 conventionnels impliquent seed phrases, extensions navigateur et téléchargements logiciels — créant des barrières à l'entrée considérables.

Le consensus de l'industrie en 2025-2026 est clair : l'expérience doit être custodiale au départ, puis progresser vers l'auto-custody quand l'utilisateur est prêt.

**Sources** :
- [Magic.link — Web3 Onboarding Challenges](https://magic.link/posts/user-onboarding-web3-challenges-best-practices)
- [a16z Crypto — Missing Link Web2/Web3 Custody](https://a16zcrypto.com/posts/article/missing-link-web2-web3-custody-wallets/)
- [MetaMask — Embedded Wallets](https://metamask.io/news/metamask-embedded-wallets-frictionless-web3-onboarding-built-in)

---

## 2. Principe directeur : "zéro friction crypto"

**Règle fondamentale** : A aucun moment du parcours consultant, les mots "wallet", "seed phrase", "gas", "blockchain" ou "token" ne doivent apparaître dans l'interface utilisateur.

| Ce que voit le consultant | Ce qui se passe en coulisse |
|---------------------------|---------------------------|
| "Connectez-vous avec Google/LinkedIn" | Wallet custodial créé automatiquement (Wallet-as-a-Service) |
| "Votre score de réputation : 47/100" | Solde tokens REP soulbound sur Polygon |
| "Votez sur la proposition #12" | Transaction Snapshot signée via wallet embedded |
| "Mission validée — votre réputation augmente" | +5 REP mintés dans le wallet soulbound |
| "Consultez vos missions et évaluations" | Historique on-chain rendu lisible via dashboard |

**Technologie** : Les embedded wallets (MetaMask Embedded, Magic.link) créent un wallet auto-custodial au nom de l'utilisateur lors de la connexion via login Web2 classique (Google, Apple, LinkedIn). L'utilisateur bénéficie de la propriété Web3 avec l'expérience Web2.

**Source** : [Flow — Walletless Onboarding](https://flow.com/post/flow-blockchain-mainstream-adoption-easy-onboarding-wallets)

---

## 3. Parcours d'onboarding en 3 niveaux

### Niveau 1 — Découverte (Jour 1 -> Semaine 2)

**Objectif** : Le consultant participe à la gouvernance sans aucune connaissance blockchain.

| Étape | Action consultant | Infrastructure invisible | Durée |
|-------|-------------------|-------------------------|-------|
| 1 | Inscription via LinkedIn SSO | Wallet custodial créé (Magic.link / Privy) | 30 secondes |
| 2 | Compléter profil (expertise, expérience, références) | Profil stocké IPFS, hash ancré on-chain | 10 minutes |
| 3 | Lecture charte de gouvernance (PDF interactif) | Signature électronique = première transaction on-chain | 5 minutes |
| 4 | Premier vote (proposition test) | Vote Snapshot via wallet embedded | 2 minutes |
| 5 | Recevoir premiers REP (bonus onboarding : 5 REP) | Mint SBT sur Polygon, gas sponsorisé | Automatique |

**Durée totale** : < 20 minutes. **Compétence crypto requise** : Zéro.

### Niveau 2 — Participation active (Semaine 2 -> Mois 3)

**Objectif** : Le consultant comprend le système de réputation et participe activement.

| Activité | Mécanisme | Formation requise |
|----------|-----------|-------------------|
| Soumettre une proposition stratégique | Formulaire web classique -> converti en proposal Snapshot | Tutoriel vidéo 5 min |
| Consulter son historique de missions | Dashboard web -> lecture données on-chain | Aucune (interface Web2) |
| Comprendre le vote quadratique | Simulation interactive ("combien de votes pour X REP ?") | Atelier 30 min |
| Participer à l'évaluation de pairs | Formulaire NPS -> résultat on-chain | Aucune |

### Niveau 3 — Autonomie (Mois 3+, optionnel)

**Objectif** : Les consultants technophiles peuvent migrer vers l'auto-custody.

| Étape | Action | Bénéfice |
|-------|--------|----------|
| Exporter son wallet vers MetaMask | Migration assistée (1 clic) | Contrôle total de son identité on-chain |
| Vérifier ses transactions sur Polygonscan | Lien direct depuis dashboard | Transparence totale, indépendance vis-à-vis de la plateforme |
| Participer aux discussions techniques gouvernance | Accès forum avancé + propositions d'amélioration protocole | Influence sur l'évolution du système |

**Point critique** : Le niveau 3 reste strictement optionnel. Un consultant peut rester indéfiniment au niveau 1 sans aucune perte de fonctionnalité ni de pouvoir de vote.

---

## 4. Programme de formation

| Module | Format | Durée | Audience | Contenu |
|--------|--------|-------|----------|---------|
| **"Votre réputation, votre pouvoir"** | Vidéo + FAQ interactive | 15 min | Tous (Niveau 1) | Comment REP sont gagnés, à quoi ils servent, comment voter |
| **"Le vote qui compte"** | Atelier pratique (visio) | 30 min | Tous (Niveau 2) | Exercice vote quadratique sur cas réel, simulation résultats |
| **"Transparence totale"** | Démo live dashboard | 20 min | Consultants seniors | Lire le dashboard KPI, comprendre escrow, facturation conditionnelle |
| **"Sous le capot"** | Workshop technique | 2h | Volontaires (Niveau 3) | Blockchain, smart contracts, wallet auto-custody, Polygonscan |

---

## 5. Métriques d'adoption

| Indicateur | Cible M6 | Cible M12 | Cible M24 | Méthode de mesure |
|------------|---------|----------|----------|-------------------|
| Taux d'inscription (Niveau 1) | 100% consultants | 100% | 100% | Comptes créés / effectif |
| Taux de participation aux votes | >=50% | >=70% | >=80% | Snapshot analytics |
| Temps moyen d'onboarding | <20 min | <15 min | <10 min | Timer automatique |
| Taux de migration Niveau 3 | 5% | 15% | 25% | Wallets exportés |
| NPS onboarding | >=30 | >=50 | >=60 | Enquête post-inscription |
| Tickets support "comment voter ?" | <10/mois | <5/mois | <2/mois | Helpdesk |

---

## 6. Priorités opérationnelles

| Priorité | Action | Effort | Prérequis |
|----------|--------|--------|-----------|
| **P0** | Choisir le provider Wallet-as-a-Service (Magic.link vs Privy vs MetaMask Embedded) | 1 semaine benchmark | Aucun |
| **P0** | Développer le parcours Niveau 1 (SSO -> profil -> premier vote) | 3-4 semaines | Provider WaaS choisi |
| **P0** | Produire vidéo "Votre réputation, votre pouvoir" (15 min) | 1 semaine | Script validé par fondateurs |
| **P1** | Développer dashboard consultant (réputation, missions, votes) | 3-4 semaines | REP déployé on-chain |
| **P1** | Organiser premier atelier vote quadratique (10 consultants pilotes) | 1 jour | Snapshot configuré |
| **P2** | Implémenter migration auto-custody Niveau 3 | 2 semaines | Wallet embedded opérationnel |
| **P2** | Créer programme ambassadeurs (consultants early adopters forment les suivants) | Continu | 5+ consultants Niveau 2 actifs |

---

## 7. Quick wins

| Quick win | Horizon | Impact | Coût |
|-----------|---------|--------|------|
| **Démo Snapshot en 5 minutes** : créer un espace Snapshot, inviter 5 consultants par email, lancer un vote test | Jour 1 | Preuve immédiate que voter dans une DAO = aussi simple que répondre à un sondage | 0 EUR |
| **Profil LinkedIn -> Profil DAO** : script de pré-remplissage du profil consultant à partir de LinkedIn (OAuth) | Semaine 1-2 | Réduction friction inscription de 10 min -> 2 min | 1-2 jours dev |
| **FAQ vidéo courte** (3 min) : "Pourquoi ce modèle est différent" — destinée aux prospects consultants | Semaine 2 | Outil de recrutement consultants + argument commercial | Coût production vidéo minimal |

---

## 8. Horizon temporel par maturité

| Phase | Maturité onboarding | Expérience consultant |
|-------|---------------------|----------------------|
| **M0-M3** | Snapshot par email + tableur REP manuels | "C'est un sondage amélioré" |
| **M3-M6** | Wallet embedded + SSO LinkedIn + dashboard basique | "C'est une app comme les autres" |
| **M6-M12** | Dashboard complet + formation structurée + premiers 50 consultants | "Je comprends le système et j'y participe activement" |
| **M12-M18** | Programme ambassadeurs + migration auto-custody disponible | "Je peux expliquer le modèle à un prospect" |
| **M18-M24** | Onboarding < 10 min + NPS >= 60 + taux participation >= 80% | "Je ne pourrais plus revenir à un modèle classique" |
