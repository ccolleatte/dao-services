# Analyse des facteurs de succes et d'echec des projets web3

**Date** : 2026-02-16
**Scope** : Polkadot, Ethereum, web3/DAO en general
**Sources** : 12 recherches web, donnees 2023-2026
**Methode** : Compilation de donnees factuelles uniquement (pas de speculation)

---

## 1. Taux de survie et statistiques globales

### Taux d'echec

| Metrique | Valeur | Source |
|----------|--------|--------|
| Taux d'echec global projets web3 | ~90% | [CapitalForce88 / Medium](https://medium.com/@CapitalForce88/why-90-of-web3-projects-fail-and-how-the-remaining-10-are-quietly-changing-the-world-1893953f325a) |
| Projets crypto "morts" en 2025 (au 31 mars) | 1.8 million | [Cryptopolitan](https://www.cryptopolitan.com/failed-cryptos-launch-since-2021-2024-2025/) |
| Part des fermetures 2021-2025 survenues en 2024-2025 | 49.7% | [Cryptopolitan](https://www.cryptopolitan.com/failed-cryptos-launch-since-2021-2024-2025/) |
| Tokens lances en 2024 activement trades dans les 30 jours | 1.7% | [Chainalysis via Cryptopolitan](https://www.cryptopolitan.com/failed-cryptos-launch-since-2021-2024-2025/) |
| Projets VC-backed (2023-2024) generant < $1,000/mois de revenus | 77% | [ainvest.com](https://www.ainvest.com/news/systemic-failure-web3-99-projects-sustain-2601/) |
| Projets web3 avec $0 de revenus (30 derniers jours) | >99% (~200 projets seulement generent >$0.10) | [CoinGecko](https://www.coingecko.com/learn/how-do-unprofitable-web3-projects-survive) |
| Projets en faillite/cessation 2023 | ~120 | [DailyCoin](https://dailycoin.com/2023-web3-funding-reaches-9b-failed-projects-drop-by-half/) |
| Projets en faillite/cessation 2022 | ~239 | [DailyCoin](https://dailycoin.com/2023-web3-funding-reaches-9b-failed-projects-drop-by-half/) |

### Survie des projets open-source blockchain

| Metrique | Valeur | Source |
|----------|--------|--------|
| Projets blockchain open-source activement maintenus sur GitHub | 8% | [SSRN / Code-Washing study](https://papers.ssrn.com/sol3/papers.cfm?abstract_id=5068292) |
| Taux de succes fondateurs avec track record | 30% | [Medium / Rajat](https://medium.com/@RajZuvomo/why-most-web3-startups-never-raise-only-1-in-10-make-it-and-heres-the-ugly-truth-69b966753cbe) |
| Taux de succes fondateurs premiere fois | 18% | [Medium / Rajat](https://medium.com/@RajZuvomo/why-most-web3-startups-never-raise-only-1-in-10-make-it-and-heres-the-ugly-truth-69b966753cbe) |
| Projets avec bonne tokenomics - survie bear market | 63% plus eleve | [CoinGecko 2025 report via Quecko](https://quecko.com/tokenomics-design-in-2025-building-sustainable-crypto-economies) |

### Correlation financement vs succes

| Metrique | Valeur | Source |
|----------|--------|--------|
| Financement total crypto VC 2025 | $34-40 milliards | [Cointelegraph](https://cointelegraph.com/research/crypto-vc-funding-doubled-in-2025-as-rwa-tokenization-took-the-lead) |
| Financement total crypto VC 2024 | ~$17 milliards | [Cointelegraph](https://cointelegraph.com/news/vc-roundup-crypto-funding-climbs-13-6-billion-2024) |
| L1 tokens performance 2025 malgre TVL en hausse | Negative ou flat | [Cointelegraph](https://cointelegraph.com/research/crypto-vc-funding-doubled-in-2025-as-rwa-tokenization-took-the-lead) |
| Later-stage rounds (% du capital Q1 2025) | 65% | [DeFi Planet](https://defi-planet.com/2025/07/web3-in-2025-where-we-are-whats-next-and-what-the-data-says/) |

**Constat** : Le financement VC a double entre 2024 et 2025, mais les tokens L1 ont sous-performe malgre la hausse de TVL. Le financement eleve ne garantit pas le succes. Les investisseurs se concentrent desormais sur les late-stage rounds (65% du capital) au detriment des seed rounds, favorisant des projets plus matures avec product-market fit demontre.

---

## 2. Facteurs de succes

### 2.1 Product-market fit et utilite reelle

**Facteur determinant n.1** : Les projets qui survivent resolvent un probleme reel, pas un probleme imaginaire.

- 90% des echecs sont attribues a l'absence de cas d'usage reel ([C-Leads](https://www.c-leads.com/blog/web3-startup-failure-report-real-sales-mistakes-to-avoid-in-2025))
- Les projets qui reussissent priorisent la construction de produit fonctionnel avant le lancement de token
- En 2025, les VCs sont devenus "plus pragmatiques, cherchant des projets avec un produit viable" ([Cointelegraph](https://cointelegraph.com/research/crypto-vc-funding-doubled-in-2025-as-rwa-tokenization-took-the-lead))

**Exemples de reussite** :
- Uniswap : Resout un probleme reel (echange decentralise), revenus de frais reels
- Aave : Pret/emprunt decentralise avec revenus on-chain verifiables
- Chainlink : Infrastructure d'oracles utilisee par des centaines de protocoles

### 2.2 Tokenomics durables

**Caracteristiques des tokenomics viables** ([Quecko](https://quecko.com/tokenomics-design-in-2025-building-sustainable-crypto-economies), [Mitosis University](https://university.mitosis.org/ponzinomics-vs-sustainable-tokenomics-a-deep-dive-into-crypto-economics/)) :

| Critere | Tokenomics durable | Ponzinomics (a eviter) |
|---------|-------------------|----------------------|
| Source de rendement | Frais de protocole, utilite reelle | Nouveaux entrants financent anciens |
| Distribution communaute | 20-60% (ex: UNI = 60%) | <10% communaute, >50% equipe |
| Vesting equipe | 3-4 ans avec cliff | Deblocage rapide, vente immediate |
| Emissions | Controlees, decroissantes (ex: halving BTC) | Inflation front-loaded sans plan |
| Promesses rendement | Basees sur revenus protocole | APY >100% sans source de revenus |
| Token lance | Apres produit fonctionnel | Avant le produit, finance le dev |

**Statistique cle** : Les projets avec de bonnes tokenomics ont 63% plus de chances de survivre un bear market (CoinGecko 2025).

### 2.3 Modeles de gouvernance qui fonctionnent

**Modele hybride** (meilleur taux de succes) :
- Decisions quotidiennes : informelles, culture communautaire
- Decisions strategiques majeures : processus de gouvernance formel
- Permet de maintenir un "community feel" tout en protegeant contre les erreurs catastrophiques
([Medium / Slime](https://medium.com/@lee645521797/blockchain-dao-a-democratic-utopia-of-web3-or-a-governance-trap-b265b4df8c2b))

**Tendances gouvernance 2024-2025** ([Blockworks](https://blockworks.co/news/dao-governance-experiments-2024)) :
- Delegation active : deleguer le vote a des experts par domaine
- Comites specialises : groupes dedies (securite, tresorerie, dev)
- Timelock et multisig : delais de securite sur les propositions

### 2.4 Architecture technique

**Choix correles au succes** :
- **Ethereum L2** : Les 3 L2 leaders (Arbitrum, Optimism, Base) traitent ~90% des transactions L2. Arbitrum mene avec ~$19B TVS en mid-2025 ([CoinLaw](https://coinlaw.io/gas-fee-markets-on-layer-2-statistics/))
- **EIP-4844 / blobs** : Reduction de 50-90% des frais L2 depuis mars 2024, ameliorant la retention utilisateur ([CoinTribune](https://www.cointribune.com/en/ethereum-layer-2-the-gas-fee-revolution-with-eip-4844/))
- **AI + Web3** : La part de projets web3 utilisant l'IA est passee de 27% (2023) a 34% (2024) ([DeFi Planet](https://defi-planet.com/2025/07/web3-in-2025-where-we-are-whats-next-and-what-the-data-says/))
- **Audits de securite** : Projets audites par des firmes reconnues (Trail of Bits, OpenZeppelin) ont une meilleure retention utilisateur

### 2.5 Engagement communautaire

- Les projets dont les propositions, reviews, matching et reglements sont tous enregistres on-chain montrent un impact tracable et reduisent le "performative funding" ([DeFi Planet](https://defi-planet.com/2025/07/web3-in-2025-where-we-are-whats-next-and-what-the-data-says/))
- Les treasuries DAO totalisent plus de $40 milliards debut 2025 ([Digitap](https://digitap.app/news/guide/dao-models-to-watch-in-2025))
- La complexite UX reste la barriere n.1 a l'adoption de masse ([Web3Auth](https://blog.web3auth.io/top-web3-trends-to-watch-in-2024-for-2025-success/))

---

## 3. Facteurs d'echec et post-mortems

### 3.1 Raisons principales d'echec

| Rang | Raison | Details | Source |
|------|--------|---------|--------|
| 1 | Pas de cas d'usage reel | Token lance avant produit, pas de PMF | [C-Leads](https://www.c-leads.com/blog/web3-startup-failure-report-real-sales-mistakes-to-avoid-in-2025) |
| 2 | Tokenomics insoutenables | Ponzinomics, emissions non controlees | [DeFi Planet](https://defi-planet.com/2025/08/why-most-web3-projects-dont-deserve-a-token-yet-still-have-one/) |
| 3 | Marketing > Produit | Airdrops et giveaways sans valeur durable | [Kreatorverse](https://kreatorverse.com/blog/why-web3-fail/) |
| 4 | Equipe/execution faible | Roadmaps irrealistes, equipes desalignees | [Medium / Silent Killers](https://medium.com/the-crypto-kiosk/the-silent-killers-of-90-of-web3-startups-a28649c0658c) |
| 5 | Fraude et rug pulls | 94% des pools DEX suspects sont rug-pulled | [QuillAudits](https://www.quillaudits.com/blog/web3-security/breaking-rugs-2024-web3-security-report) |
| 6 | Vulnerabilites securite | $2.1B perdus en hacks/scams/rug pulls en 2024 | [QuillAudits](https://www.quillaudits.com/blog/web3-security/breaking-rugs-2024-web3-security-report) |
| 7 | UX trop complexe | Barriere a l'adoption de masse | [Web3Auth](https://blog.web3auth.io/top-web3-trends-to-watch-in-2024-for-2025-success/) |

### 3.2 Vulnerabilites smart contract (2024-2025)

**Pertes totales** :

| Periode | Montant perdu | Source |
|---------|--------------|--------|
| 2022 (pic) | $3.8 milliards | [DeepStrike](https://deepstrike.io/blog/crypto-hacking-incidents-statistics-2025-losses-trends) |
| 2023 | ~$1.7 milliard | [DeepStrike](https://deepstrike.io/blog/crypto-hacking-incidents-statistics-2025-losses-trends) |
| 2024 | ~$2.2 milliards | [DeepStrike](https://deepstrike.io/blog/crypto-hacking-incidents-statistics-2025-losses-trends) |
| H1 2025 | ~$3.1 milliards (344 incidents) | [CoinLaw](https://coinlaw.io/smart-contract-security-risks-and-audits-statistics/) |

**Hacks majeurs 2024-2025** :

| Hack | Montant | Type | Source |
|------|---------|------|--------|
| Bybit (2025) | $1.5 milliard | Vol exchange (plus gros hack crypto histoire) | [DeepStrike](https://deepstrike.io/blog/crypto-hacking-incidents-statistics-2025-losses-trends) |
| Cetus (2025) | ~$220 millions | Exploit protocole | [DeepStrike](https://deepstrike.io/blog/crypto-hacking-incidents-statistics-2025-losses-trends) |
| Balancer (2025) | ~$128 millions | Exploit smart contract | [DeepStrike](https://deepstrike.io/blog/crypto-hacking-incidents-statistics-2025-losses-trends) |

**Vulnerabilites les plus courantes** ([CoinLaw](https://coinlaw.io/smart-contract-security-risks-and-audits-statistics/), [Hacken](https://hacken.io/discover/smart-contract-vulnerabilities/)) :

| Vulnerabilite | Frequence/Impact | Details |
|---------------|-----------------|---------|
| Validation input manquante/defaillante | 34.6% des cas | Premier vecteur d'exploitation directe |
| Failles controle d'acces | $953.2M de pertes | Cause leader des breaches |
| Attaques off-chain (phishing, comptes compromis) | 80.5% des fonds voles en 2024 | Comptes compromis = 55.6% des incidents |
| Phishing (Q2 2025) | 49.3% des pertes | Tendance croissante |
| Vulnerabilites code (Q2 2025) | 29.4% des pertes | En baisse relative (mais montants en hausse absolue) |
| Reentrancy | Connue depuis des annees | Toujours exploitee regulierement |
| Oracle manipulation | Multiples incidents | Flashloan + oracle = vecteur classique |

**Tendance importante** : Les attaques se deplacent du on-chain (smart contracts purs) vers le off-chain (phishing, compromission de cles privees, ingenierie sociale). Les smart contracts deviennent plus robustes, mais l'humain reste le maillon faible.

### 3.3 Attaques et echecs de gouvernance DAO

**Compound DAO - Attaque "GoldenBoyz" (2024)** :
- 3 propositions progressives (247, 279, 289) pour transferer 499,000 COMP (~$25M)
- Turnout faible (4-5% du supply total) rendant la capture de gouvernance faisable
- COMP a chute de 6.7% apres l'attaque
([CoinDesk](https://www.coindesk.com/markets/2024/07/29/comp-down-67-after-supposed-governance-attack-on-compound-dao))

**Beanstalk Protocol - Flash Loan Governance Attack (2022)** :
- $181 millions de pertes
- Attaquant emprunte des tokens de gouvernance via flashloan, vote, rembourse dans un seul bloc
([QuillAudits](https://www.quillaudits.com/blog/web3-security/dao-governance-attacks))

**Problemes structurels gouvernance (2025)** ([DL News](https://www.dlnews.com/articles/defi/daos-grew-quieter-in-2025-per-state-of-defi-report/)) :
- Les DAOs sont devenues "plus silencieuses et plus concentrees" en 2025
- Nombre de propositions et de votants en baisse significative
- Probleme "baleine" : les gros detenteurs de tokens ont des interets divergents des petits porteurs
- Participation a la gouvernance trop faible pour etre representative
- Exemples : Arbitrum avec participation declinante et debats repetitifs retardant les propositions majeures

---

## 4. Facteurs specifiques Polkadot

### 4.1 Polkadot 2.0 et Agile Coretime

**Timeline** :
- Agile Coretime lance : septembre 2024 ([Bitget](https://www.bitget.com/news/detail/12560604227380))
- Polkadot 2.0 SDK v2509 : octobre 2025 ([Parity](https://www.parity.io/blog/polkadot-upgrade-2025-what-you-need-to-know))
- 3 piliers techniques finalises : Asynchronous Backing, Agile Coretime, Elastic Scaling

**Impact Agile Coretime** :
- Elimination des encheres de slots parachain (ancien modele couteux ~2M DOT)
- Modele flexible : coretime on-demand ou en bulk (NFT, periodes de 28 jours)
- Peut etre split, partage ou revendu sur marketplace
- Reaction marche : DOT +8% au lancement, +3.82% pre-annonce
([Polkadot Blog](https://polkadot.com/blog/scaling-ambition-with-agile-coretime))

**Pas de donnees quantitatives d'adoption** trouvees sur le nombre de projets utilisant Agile Coretime vs l'ancien modele parachains.

### 4.2 Treasury Polkadot et OpenGov

| Metrique | Valeur | Source |
|----------|--------|--------|
| Treasury Polkadot | 41M DOT (~$410M) | [OpenGov.Watch](https://www.opengov.watch/reports/governance-reports/2025-04-governance-report) |
| Treasury QoQ (recent) | Baisse a $109.7M | [ainvest](https://www.ainvest.com/news/polkadot-upcoming-network-upgrade-implications-price-ecosystem-growth-2509/) |
| Hausse propositions sous OpenGov | +405% | [OpenGov.Watch](https://www.opengov.watch/reports/governance-reports/2025-04-governance-report) |
| Premier resultat positif OpenGov | +1.6M DOT net profit | [The Defiant](https://thedefiant.io/news/blockchains/polkadot-treasury-posts-first-opengov-profit-as-dot-price-lags) |

**Problemes identifies** :
- Grandes demandes de financement (>1.5M DOT / >$5M) provoquent des red flags immediats chez les token holders
- Financement retroactif de plus en plus conteste, surtout pour les propositions couteuses
- Resoumission de propositions rejetees avec modifications mineures ("clutters OpenGov")
- Propositions bien structurees (ex: UX Bounty Q3) approuvees ; propositions vagues rejetees
([OpenGov.Watch](https://www.opengov.watch/reports/governance-reports/2025-07-governance-report))

### 4.3 Projets Polkadot notables - succes et echecs

**Acala - aUSD Depeg (aout 2022)** :
- Bug dans pool de liquidite iBTC/aUSD permettant le mint illimite de 1.28 milliard aUSD
- aUSD chute de 99%
- Pertes estimees < $10M (hors depeg du stablecoin)
- Mesures d'urgence : reseau en mode maintenance, swaps et transferts cross-chain suspendus
- Acala toujours actif mais reputation durablement endommagee
([CryptoBriefing](https://cryptobriefing.com/acala-stablecoin-ausd-collapses-following-parachain-exploit/), [Decrypt](https://decrypt.co/107446/acala-exploit-causes-polkadot-based-defi-platforms-stablecoin-to-drop-99))

**Parallel Finance - Exploit runtime (octobre 2024)** :
- Attaquant exploite une runtime upgrade malveillante
- Vol de 312,185 DOT et 126,837 USDT
- Fermeture des produits crowdloan annoncee en aout 2024 (avant l'attaque)
- DOT crowdloanes restitues aux contributeurs
([Parallel Finance / Medium](https://parallelfinance.medium.com/rebuilding-after-the-parachain-attack-a-message-to-our-community-9dccd6c2a080), [Polkadot Forum](https://forum.polkadot.network/t/what-happen-to-dots-on-a-ceased-parachain/14897/1))

**Moonbeam - Relatif succes** :
- "Excellente performance en developpement ecosysteme et mises a jour techniques"
- Integrations avec outils dev courants facilitant le deploiement
- Compatibilite EVM = avantage majeur pour attirer developpeurs Ethereum
([Parachains.info](https://parachains.info/details/moonbeam))

**Challenges ecosystem-wide** :
- Substrate puissant mais intimidant (Rust-heavy)
- Developer tooling et UX en retard par rapport aux chaines EVM
- Crowdloans devenus des "concours de popularite" plutot que des selections de merite
- Petites equipes exclues par les couts du modele parachain (resolu par Agile Coretime)
([Medium / Ludovic Domingues](https://medium.com/@ludovic.domingues96/the-polkadot-you-knew-is-gone-and-thats-a-good-thing-444b37802686))

### 4.4 XCM et cross-chain

Pas de donnees quantitatives trouvees sur les taux d'adoption XCM ou les challenges specifiques en 2025. Les resultats indiquent que XCM fait partie des 3 piliers techniques de Polkadot 2.0 mais sans metriques d'usage.

---

## 5. Facteurs specifiques Ethereum

### 5.1 L2 vs L1

| Metrique | Valeur | Source |
|----------|--------|--------|
| Part transactions L2 (top 3) | ~90% de toutes les transactions L2 | [CoinLaw](https://coinlaw.io/gas-fee-markets-on-layer-2-statistics/) |
| Arbitrum TVS (mid-2025) | ~$19 milliards | [CoinLaw](https://coinlaw.io/gas-fee-markets-on-layer-2-statistics/) |
| Cout swap DeFi sur Arbitrum | $0.03 | [PayRam](https://payram.com/blog/arbitrum-vs-optimism-vs-base) |
| Revenus quotidiens Base | $185,291/jour (moy 180j) | [PayRam](https://payram.com/blog/arbitrum-vs-optimism-vs-base) |
| Revenus quotidiens Arbitrum | ~$55,025/jour | [PayRam](https://payram.com/blog/arbitrum-vs-optimism-vs-base) |
| Reduction frais L2 post-EIP-4844 | 50-90% | [CoinTribune](https://www.cointribune.com/en/ethereum-layer-2-the-gas-fee-revolution-with-eip-4844/) |
| L2 rollups : actifs securises Q1 2025 | >$40 milliards | [CoinLaw](https://coinlaw.io/gas-fee-markets-on-layer-2-statistics/) |
| L2 rollups : volume DEX (part Ethereum) | ~50% | [CoinLaw](https://coinlaw.io/gas-fee-markets-on-layer-2-statistics/) |
| Ethereum L1 TPS | ~15 | [CoinLaw](https://coinlaw.io/gas-fee-markets-on-layer-2-statistics/) |
| L2 TPS | Milliers | [CoinLaw](https://coinlaw.io/gas-fee-markets-on-layer-2-statistics/) |

**Constat** : L2 a clairement gagne. Les projets DeFi deployes sur L2 beneficient de frais 50-90% plus bas, ce qui impacte directement la retention utilisateur. Le marche s'est consolide autour de 3 acteurs (Arbitrum pour DeFi, Base pour retail, Optimism pour ecosystemes subventionnes).

### 5.2 DeFi - Financement et survie

| Metrique | Valeur | Source |
|----------|--------|--------|
| Financement DeFi Q2 2025 | $483M (-50% QoQ) | [DappRadar](https://dappradar.com/blog/state-of-the-dapp-industry-q2-2025) |
| Financement DeFi YTD 2025 | $1.4 milliard | [DappRadar](https://dappradar.com/blog/state-of-the-dapp-industry-q2-2025) |
| Taux echec contrat on-chain Ethereum | 1.9% | [CoinLaw](https://coinlaw.io/ethereum-statistics/) |
| DeFi security breaches 2025 | ~$3.1 milliards (+40% YoY) | [CoinLaw](https://coinlaw.io/smart-contract-security-risks-and-audits-statistics/) |
| DApps AI inactives (croissance) | +129% | [DappRadar](https://dappradar.com/blog/state-of-the-dapp-industry-q2-2025) |

### 5.3 Gas et retention utilisateur

L'impact de EIP-4844 (mars 2024) a ete transformateur :
- Frais L2 reduits de 50-90%, rendant les micro-transactions viables
- Volume DEX sur L2 = ~50% du volume DEX Ethereum total en Q1 2025
- Les projets deployes sur L2 plutot que L1 ont un avantage competitif net en retention

**Anti-pattern observe** : Les projets qui restent sur L1 Ethereum sans justification (securite maximale, composabilite directe) perdent des utilisateurs au profit de L2 equivalents moins couteux.

---

## 6. Synthese : patterns distinctifs succes vs echec

### Facteurs de succes (par ordre d'importance)

| # | Facteur | Evidence | Impact |
|---|---------|----------|--------|
| 1 | **Product-market fit reel** | 90% des echecs = pas de cas d'usage reel | Eliminatoire |
| 2 | **Tokenomics durables** | +63% survie bear market | Fort |
| 3 | **Securite auditee** | $3.1B perdus H1 2025 | Eliminatoire si absent |
| 4 | **Gouvernance hybride** | DAOs "pures" = participation faible + capture | Fort |
| 5 | **UX simplifiee** | Barriere n.1 adoption de masse | Fort |
| 6 | **Deploiement L2** (Ethereum) | Frais -90%, retention superieure | Moyen-Fort |
| 7 | **Equipe avec track record** | 30% succes vs 18% premiere fois | Moyen |
| 8 | **Transparence on-chain** | Propositions + financements tracables | Moyen |

### Facteurs d'echec (par frequence)

| # | Facteur | Frequence | Consequence |
|---|---------|-----------|-------------|
| 1 | **Token avant produit** | Tres frequent | Speculation sans fondation, crash inevitable |
| 2 | **Ponzinomics** | 94% des pools DEX rug-pulled | Perte totale pour utilisateurs |
| 3 | **Failles securite non auditees** | $2.2B/an perdu | Perte de fonds, reputation detruite |
| 4 | **Gouvernance sans quorum reel** | 4-5% participation (Compound) | Capture par des acteurs malveillants |
| 5 | **Marketing > Ingenierie** | Frequent | Echec post-hype, pas de retention |
| 6 | **Complexite dev (Rust/Substrate)** | Specifique Polkadot | Frein a l'adoption developpeur |
| 7 | **Off-chain attack surface** | 80.5% des vols en 2024 | Audit smart contract insuffisant seul |

---

## 7. Implications pour un projet DAO sur Polkadot

### Risques specifiques identifies

1. **Complexite Substrate** : Rust-heavy, tooling en retard vs EVM. Mitigation : Solidity MVP sur Moonbeam (EVM-compatible) avant migration eventuelle.

2. **Treasury OpenGov** : Propositions de financement >$5M provoquent des red flags. Mitigation : Propositions modulaires, bien structurees, avec livrables mesurables.

3. **Agile Coretime non prouve** : Pas de donnees d'adoption a grande echelle. Mitigation : Commencer on-demand, evaluer cout vs parachain apres 100+ transactions/jour.

4. **Securite critique** : Les projets Polkadot (Acala, Parallel Finance) ont subi des exploits majeurs. Mitigation : Audit obligatoire avant mainnet, emergency pause, bounded storage.

5. **Gouvernance DAO** : Participation en baisse ecosystem-wide, risque de capture. Mitigation : Modele hybride, delegation, quorum minimum.

### Opportunites identifiees

1. **Cout reduit Agile Coretime** : Plus de slot auction a 2M DOT, pay-per-use accessible aux petites equipes.
2. **Polkadot 2.0 maturite technique** : Async Backing + Elastic Scaling = infrastructure competitive.
3. **Niche sous-exploitee** : Les marketplaces de services/missions sur Polkadot sont rares vs Ethereum.
4. **Cross-chain via XCM** : Potentiel de differenciation si bien execute.
5. **RWA tokenization** : Secteur en forte croissance ($2.5B VC en 2025), applicable aux missions DAO.

---

## Sources

- [CapitalForce88 - Why 90% of Web3 Projects Fail](https://medium.com/@CapitalForce88/why-90-of-web3-projects-fail-and-how-the-remaining-10-are-quietly-changing-the-world-1893953f325a)
- [C-Leads - Web3 Startup Failure Report 2025](https://www.c-leads.com/blog/web3-startup-failure-report-real-sales-mistakes-to-avoid-in-2025)
- [ainvest - Systemic Failure of Web3](https://www.ainvest.com/news/systemic-failure-web3-99-projects-sustain-2601/)
- [Cryptopolitan - 53% of cryptos launched since 2021 have failed](https://www.cryptopolitan.com/failed-cryptos-launch-since-2021-2024-2025/)
- [QuillAudits - 2024 Web3 Security Report](https://www.quillaudits.com/blog/web3-security/breaking-rugs-2024-web3-security-report)
- [DeepStrike - Crypto Hacking Statistics 2025](https://deepstrike.io/blog/crypto-hacking-incidents-statistics-2025-losses-trends)
- [CoinLaw - Smart Contract Security Statistics 2025](https://coinlaw.io/smart-contract-security-risks-and-audits-statistics/)
- [Hacken - Smart Contract Vulnerabilities 2025](https://hacken.io/discover/smart-contract-vulnerabilities/)
- [CoinDesk - Compound DAO Governance Attack](https://www.coindesk.com/markets/2024/07/29/comp-down-67-after-supposed-governance-attack-on-compound-dao)
- [a16z - DAO Governance Attacks and How to Avoid Them](https://a16zcrypto.com/posts/article/dao-governance-attacks-and-how-to-avoid-them/)
- [DL News - DAOs grew quieter in 2025](https://www.dlnews.com/articles/defi/daos-grew-quieter-in-2025-per-state-of-defi-report/)
- [Parity - Polkadot Upgrade 2025](https://www.parity.io/blog/polkadot-upgrade-2025-what-you-need-to-know)
- [Polkadot Blog - Agile Coretime](https://polkadot.com/blog/scaling-ambition-with-agile-coretime)
- [Bitget - Polkadot Agile Coretime Launch](https://www.bitget.com/news/detail/12560604227380)
- [OpenGov.Watch - April 2025 Report](https://www.opengov.watch/reports/governance-reports/2025-04-governance-report)
- [OpenGov.Watch - July 2025 Report](https://www.opengov.watch/reports/governance-reports/2025-07-governance-report)
- [The Defiant - Polkadot Treasury First Profit](https://thedefiant.io/news/blockchains/polkadot-treasury-posts-first-opengov-profit-as-dot-price-lags)
- [CryptoBriefing - Acala aUSD Exploit](https://cryptobriefing.com/acala-stablecoin-ausd-collapses-following-parachain-exploit/)
- [Parallel Finance - Post-Attack](https://parallelfinance.medium.com/rebuilding-after-the-parachain-attack-a-message-to-our-community-9dccd6c2a080)
- [Medium / Ludovic Domingues - Polkadot Transformation](https://medium.com/@ludovic.domingues96/the-polkadot-you-knew-is-gone-and-thats-a-good-thing-444b37802686)
- [CoinLaw - L2 Gas Fee Markets 2025](https://coinlaw.io/gas-fee-markets-on-layer-2-statistics/)
- [PayRam - Arbitrum vs Optimism vs Base](https://payram.com/blog/arbitrum-vs-optimism-vs-base)
- [CoinTribune - EIP-4844 Gas Revolution](https://www.cointribune.com/en/ethereum-layer-2-the-gas-fee-revolution-with-eip-4844/)
- [DappRadar - State of Dapp Industry Q2 2025](https://dappradar.com/blog/state-of-the-dapp-industry-q2-2025)
- [DeFi Planet - Web3 in 2025](https://defi-planet.com/2025/07/web3-in-2025-where-we-are-whats-next-and-what-the-data-says/)
- [Quecko - Tokenomics Design 2025](https://quecko.com/tokenomics-design-in-2025-building-sustainable-crypto-economies)
- [Mitosis University - Ponzinomics vs Sustainable Tokenomics](https://university.mitosis.org/ponzinomics-vs-sustainable-tokenomics-a-deep-dive-into-crypto-economics/)
- [Cointelegraph - Crypto VC Funding 2025](https://cointelegraph.com/research/crypto-vc-funding-doubled-in-2025-as-rwa-tokenization-took-the-lead)
- [CoinGecko - How Unprofitable Web3 Projects Survive](https://www.coingecko.com/learn/how-do-unprofitable-web3-projects-survive)
- [SSRN - Code-Washing Evidence](https://papers.ssrn.com/sol3/papers.cfm?abstract_id=5068292)
- [Medium / Rajat - Web3 Startups Fundraising](https://medium.com/@RajZuvomo/why-most-web3-startups-never-raise-only-1-in-10-make-it-and-heres-the-ugly-truth-69b966753cbe)
- [Blockworks - DAO Governance Trends 2024](https://blockworks.co/news/dao-governance-experiments-2024)
- [Digitap - DAO Models 2025](https://digitap.app/news/guide/dao-models-to-watch-in-2025)
- [Web3Auth - Web3 Trends 2024-2025](https://blog.web3auth.io/top-web3-trends-to-watch-in-2024-for-2025-success/)
