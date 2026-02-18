# Index des Precedents

> Genere partiellement par scripts/generate-snapshot.sh.
> Complete manuellement au fil des decisions.

## Metadata
```yaml
generated_at: "2025-01-01T00:00:00Z"
last_manual_update: "2026-02-18T00:00:00Z"
```

## Solutions Internes — Problemes Deja Resolus
```
api-routes|tRPC procedures|backend/api/routes/*.ts|utiliser pour nouvelles routes API
event-sync|blockchain event listener|backend/services/event-sync-worker.ts|pour sync contrats Solidity → DB
solidity-patterns|OpenZeppelin imports|contracts/src/*.sol|AccessControl, ReentrancyGuard, Pausable
custom-errors|gas-optimized errors|contracts/src/*.sol|112+ usages, preferez aux require()
governance-tracks|OpenGov integration|contracts/src/Governance.sol|rank-based voting, multi-track
```

## Libs et Packages Adoptes
```
@openzeppelin/contracts|Access control, reentrancy, pausable patterns|112+ usages in Solidity
tRPC|Type-safe API procedures|backend/api/routes/* for type-safe client/server
Solidity|Smart contracts (EVM)|6 core contracts (Governance, Marketplace, Treasury, Membership, Bonds, Plugins)
ethers.js|Blockchain interaction|for contract calls, event listening, signing
Prisma|ORM + DB migrations|backend database access + event sync
```

## Anti-Patterns Connus — Erreurs a Ne Pas Reproduire
```
ink!-migration|33% abandoned, maintenance paused (Parity Jan 2026)|use Substrate runtime instead (native, supported)
custom-bridges|trust assumptions, security risk|use Snowbridge (trustless) or Hyperbridge (ZK)
unbounded-storage|DoS attacks, storage bloat (Solidity)|use BoundedVec with explicit limits
no-emergency-pause|cannot stop in case of exploit|implement Pausable pattern (OpenZeppelin)
direct-instantiation-llm|provider lock-in, hard testing|use Backend Abstraction Factory pattern
```

## Decisions Architecturales (ADR legers)
```
2026-02-10|Abandon ink! migration, focus Solidity MVP|ink! maintenance paused, 33% effort wasted|Complete Phase 3 Solidity (30% remaining = 3-4 weeks)
2026-02-10|Substrate runtime preference (long-term)|Performance 0% overhead (native) vs 10-20% WASM|Evaluate Gate 2 (Month 6) if throughput >100 missions/day
2026-02-10|Agile Coretime for MVP phase|Cost-efficient pay-per-use vs 2M DOT parachain slot|Use until >1000 missions/day, then parachain ROI clear
2026-02-10|Solidity MVP deployment (3-4 months)|EVM-compatible, battle-tested, faster to market|Security audit required before mainnet (Gate 1 blocker)
2026-01|OpenZeppelin security libraries mandatory|Access control, reentrancy, pause patterns battle-tested|Use for all new Solidity contracts
2026-02-18|Entonnoir IA AVANT marketplace — terrain vierge, pas optimisation existant|Ambition : réinventer théorie de la firme (Coase 1937) via blockchain. Coûts de transaction → 0 = firme traditionnelle obsolète|Spectre consultant : indépendant | porté SAS | contributeur DAO | salarié core team
2026-02-17|MVP scope réduit : 3 contracts (Profiles + MissionEscrow + Ratings) avant full marketplace|H2 (crypto paiement) et H5 (agents IA) sont hypothèses CRITIQUES non validées|Valider PMF avec 3 expériences terrain avant de construire HybridPaymentSplitter et gouvernance
2026-02-17|Paiement EUR/USDC avant token DAOS|Volatilité token = friction adoption bloquante pour clients B2B|Reporter lancement DAOS après 12 mois traction en stablecoin
2026-02-17|IA = outil d'augmentation, pas contributeur (CORRIGE analyse PMF)|Débat 8 experts : IA augmente consultants (comme Copilot), ne les remplace pas|Scoping IA gratuit = acquisition, outils IA premium = rétention (49-149 EUR/mois)
2026-02-17|Repositionnement : "cabinet sans murs augmenté par l'IA"|Verbiage blockchain = repoussoir B2B, confiance + qualité = message|Zéro blockchain dans discours commercial, badges portables uniquement
2026-02-17|Structure légale reconnue obligatoire, DAO = gouvernance interne|Facturation EUR, TVA FR, contrats standards, conformité ACPR|[OPEN] Forme exacte : SAS (flexibilité) vs SCOP (coopérative salariés) vs SCIC (multi-collèges clients+consultants+équipe — plus proche architecture DAO). Communication gouvernance possible en message secondaire (holacracie, coopérative augmentée)
2026-02-17|Escrow via PSP (Stripe Connect / Mangopay), pas smart contract|Conformité ACPR obligatoire pour séquestration fonds tiers|MissionEscrow.sol → Mangopay API, ServiceMarketplace.sol → Stripe Connect
2026-02-17|Réputation on-chain = seul usage blockchain du MVP|Badges portables, historique missions, validation par les pairs|Créer Reputation.sol, retirer escrow/paiement de la blockchain
2026-02-18|ComplianceRegistry.sol standalone (pas fusionné dans ReputationTracker.sol)|Attestations légales (KBIS/URSSAF/RC Pro) avec expiration + verifier roles = préoccupation distincte des badges mission|Deux contrats : ComplianceRegistry (compliance légale) + ReputationTracker (réputation professionnelle)
2026-02-18|MilestoneEscrow.sol ANNULÉ — escrow ACPR réglementé, remplacé par jalons PSP|Séquestration fonds tiers réglementée ACPR — même motif que MissionEscrow.sol|Jalons PSP (Mangopay Connect)
2026-02-18|DisputeResolution.sol ANNULÉ par cascade — dépend de MilestoneEscrow (annulé)|Couplage fort : import direct MilestoneEscrow.sol|Gestion litiges → clause SLA PSP + contrat consultant standard
2026-02-17|Commission hybride : 5% missions + 2% récurrentes + abonnement outils|Désintermédiation inévitable, monétiser par valeur outils plutôt que commission seule|Relation directe préservée si client/consultant le souhaitent
2026-02-18|Commission = levier tactique, pas taux fixe — gouvernance DAO vote les ajustements|0% bootstrap → progressif traction → 5-8% nominal. Garantie : plateforme ne peut pas augmenter unilatéralement|Différenciant commercial fort vs Malt/Upwork/BCG qui changent conditions sans recours
2026-02-18|Token DAOS = deux couches distinctes (stock gouvernance / flux intéressement)|Stock accumulé → droits de vote. Flux annuel acquis → base intéressement. Anti-rente : contributeur dormant = 0 intéressement même avec stock historique|Cohérent droit français (intéressement sur critères activité, pas patrimoniaux). Unité de mesure objective sans subjectivité managériale.
2026-02-18|[OPEN] Valorisation contributions non-monétaires Polkadot 2.0|Coretime, compute, stockage, validation = contributions en nature qui réduisent coûts variables|3 questions ouvertes : coût LLM phase early, taux de conversion contributions, lien avec gouvernance
2026-02-18|Thèse Coase nuancée (stress-test 8/8 consensus)|"blockchain + IA + communauté → nouvelle forme organisationnelle viable" remplace "transaction costs → 0 → firme obsolète"|Philosophie de conception, pas message marketing. Valeur économique d'abord, valeurs ensuite. Ce n'est pas une ONG.
2026-02-18|[OPEN Phase 2] Grades objectivés (non déclaratifs) — deux tracks|Track consultant : Consultant → Senior → Directeur de mission. Track CSM : Niveau 1 (remote) → Niveau 2 (peut voir le client)|Critères : missions + notes + validation pairs. Connexion Reputation.sol + token flux
2026-02-18|Hiérarchie motivations : travail d'abord, valeurs ensuite|Acquisition = proposition de valeur économique (missions, paiement, outils). Fidélisation = alignement valeurs|Message consultant : "missions sans 20% d'intermédiaire + réputation portable + outils IA". Thèse Coase réservée à fundraising + contenus longs
2026-02-18|SAS d'abord, SCIC ensuite, jamais SCOP (stress-test 8/8 consensus)|SAS = flexibilité + levée possible. SCIC à évaluer si >50 membres actifs. SCOP incompatible indépendants non-salariés|François (avocat) : SCIC interdit >57.5% distribution bénéfices → levée VC quasi impossible. Transformer SAS→SCIC possible juridiquement
2026-02-18|Portage salarial = partenariat externe, pas internalisation|Devenir société de portage = 50-100k€ + 6 mois procédure. ROI négatif pour 10 consultants|Modèle Kicklox validé en France : plateforme matche, partenaire porte, commission d'apport partagée
2026-02-18|DPA RGPD + sécurité documentaire = prérequis jour 1 (pas Phase 3)|Claire (DSI CAC 40) : conformité bloque accès plateforme AVANT test. RSSI refuse upload documents sans DPA|DPA template + hébergement EU + politique rétention. Ne JAMAIS communiquer "grands comptes" sans sécurité au niveau
2026-02-18|Modèle éditorial pour agents IA : core team technique + expertise communautaire|Romain (CTO IA) : 3 rôles distincts nécessaires (domain expert + prompt engineer + QA). Consultants ≠ ingénieurs IA|Core team = "rédaction" (prompt + QA), communauté = expertise métier. Core team ne disparaît jamais, même à l'échelle
2026-02-18|Architecture données agents : deux modes selon segment (RAG as a Service / on-premise)|PME → RAG as a Service (vector stores isolés par client, IPFS). Grand compte → déploiement on-premise (données ne quittent pas périmètre client)|Implication recrutement : infra + MLOps nécessaires en plus prompt engineers
2026-02-18|Obsolescence agents IA = risque continu, pas ponctuel|Mise à jour modèle fournisseur peut dégrader agent validé sans avertissement|Monitoring post-déploiement + maintenance valorisée en tokens flux + dépréciation formelle avec critères objectifs
2026-02-18|Séquençage scoping-first : 3 mois IA seul → 10 consultants → missions → agents|Cold-start triple résolu par séquençage. Mois 1-3 = aussi constitution silencieuse communauté consultants|Spectre élargi : intercontrat + étudiants fin cycle + salariés testant "à l'abri". Commission 0% sur 20 premières missions. CSM dès mois 4
2026-02-18|KYC consultant obligatoire à l'onboarding — fiscal + social + image|Risques : requalification travail non déclaré (fiscal), prêt illicite main-d'œuvre (social), consultant défaillant (image)|Automatiser via APIs Sirene + URSSAF + prestataire KYC identité. RC Pro = upload + validation. KYC paiement (Mangopay) distinct et complémentaire. Résultat → badges portables Reputation.sol
2026-02-18|[OPEN — ADR] DoD/DoR missions consulting = épine du modèle|"Fait" non binaire dans le conseil. Critique pour : escrow (qui libère ?), gate agents (qui valide ?), tokens flux (quand compter ?)|Nécessite arbitrage avant Phase 2 : critères de complétude, rôle client vs pairs vs plateforme
2026-02-18|Burn rate chiffré — règle de décision : variable décisive = CTO technique fondateur ?|Scénario A (fondateurs sans salaire) : ~€26K net → bootstrap épargne. B (+ dev part-time) : ~€51K → love money. C (≥1 salarié) : ~€107K → pré-seed nécessaire|Circuit-breaker LLM : 3 sessions gratuites/entreprise puis abonnement. Revenue offset M5-M8 : ~€10K (abonnements + commissions)
2026-02-18|[OPEN] Token flux : quand introduire ? Quadratic scoring viable >50 membres seulement|Karim : Sybil attack sur micro-contributions. François : risque qualification AMF instrument financier|En phase early : validation centralisée core team. Quadratic scoring à >50 membres actifs
```
