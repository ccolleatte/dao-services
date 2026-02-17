Analyse
Probleme reel : Le codebase et les docs actuels convergent vers un Malt decentralise (brief → matching → mission → paiement) avec des frais plus bas et de la transparence. C'est necessaire mais pas suffisant. Le vrai differentiateur est ailleurs : dans la nature meme de ce qui est vendu (des outputs, pas du temps) et dans la composition des equipes (humain + IA + compute comme primitives combinables).

Trois constats critiques issus des docs :

Le modele de billing conditionnel (20260216-strategic-note-smart-contracts-billing.md) suppose que les clients exposent leurs APIs (CRM, ERP, SIRH) a un oracle Chainlink. Tu as raison : c'est irrealiste pour le MVP. Meme les grands comptes mettent 6-12 mois a brancher un partenaire sur leur SI. Il faut un chemin de verification plus pragmatique.

Le HybridPaymentSplitter.sol existe deja (contracts/src/HybridPaymentSplitter.sol:13) avec Human/AI/Compute + metering. C'est la brique technique cle. Mais il est utilise comme un mecanisme de repartition post-mission. Il devrait etre un mecanisme de composition d'equipe pre-mission : le client choisit un assemblage humain + agent IA + compute avant de demarrer.

L'IP Registry est prevu en P2 (polkadot-dao-services-ai-design.md:741) mais c'est un des differentiateurs les plus forts. La tokenisation des livrables n'est pas un "nice to have" — c'est ce qui transforme un marche de services en un marche de connaissances avec des revenus recurrents.

Trois parcours clients viables
Parcours A — "Brief classique, equipe augmentee"
Le client a un probleme, il cherche de l'aide. Proche du marche actuel mais avec des differences structurelles.

Client poste brief (UX Web2 pure)
    |
    v
Matching engine score les candidats (5 criteres, on-chain, auditable)
    |
    v
Client voit un shortlist de PROFILS COMPOSES :
    - "Alice (Senior Strategy) + Agent IA Market Research" → score 87/100
    - "Bob (Manager Finance) seul" → score 72/100
    - "Agent IA GenReport v3.1 (auteur: Charlie)" → score 65/100
    |
    v
Client CHOISIT l'assemblage (pas juste une personne)
    |
    v
Escrow → Milestones → Livraison → Paiement auto via HybridPaymentSplitter

Difference avec Malt/Upwork : Le client ne choisit pas une personne, il choisit une configuration d'equipe avec une transparence totale sur qui fait quoi et pour combien. Le match score est public, pas une boite noire.

Verification des resultats (realiste) :

T1 (40%) : Livraison validee par signature multi-sig client + lead consultant (ce qui existe deja dans MissionEscrow.sol)
T2 (30%) : NPS client >= 8/10 (simple formulaire, pas d'API ERP)
T3 (20%) : Bonus si livrable reutilise/licence (on-chain verifiable)
T4 (10%) : Retention 3 mois (auto-release timer, deja implemente)
Pas besoin d'oracle Chainlink au MVP. Le multi-sig + NPS + timer couvrent 80% des cas.

Parcours B — "Brief → Agent IA repond, humain supervise"
C'est le parcours que tu decris. Le plus innovant. Aucune plateforme ne fait ca.

Client poste brief
    |
    v
Agents IA enregistres sur le marketplace recoivent le brief
    |
    v
En < 2 heures, l'agent genere un LIVRABLE BRUT :
    - Etude de marche preliminaire
    - Audit financier automatise
    - Analyse concurrentielle
    - Maquette strategie
    |
    v
Client recoit le livrable IA avec :
    - Score de confiance (auto-evalue par l'agent)
    - Profil de l'auteur de l'agent (reputation, track record agent)
    - Prix : X CRED (calcule sur tokens LLM + compute utilises + marge auteur)
    |
    v
Trois options :
    |
    +-- ACCEPTER tel quel → Paiement :
    |       - 60% auteur de l'agent (passive income)
    |       - 25% cout IA/compute (metering HybridPaymentSplitter)
    |       - 10% plateforme
    |       - 5% pool reputation DAO
    |
    +-- DEMANDER RAFFINEMENT HUMAIN → Un consultant qualifie
    |       prend le livrable IA et l'enrichit/valide/corrige
    |       → Mission hybride : split via HybridPaymentSplitter
    |
    +-- REJETER → Pas de paiement, feedback enregistre
            (reputation agent diminue si rejets recurrents)

Pourquoi c'est viable :

L'auteur de l'agent est un consultant qui a investi du temps pour creer/entrainer/prompter un agent specialise
C'est un modele "SaaS consultant" : investissement initial puis revenus recurrents
Le client obtient un resultat en 2h au lieu de 2 semaines
Le cout est 5-10x inferieur a une mission classique
L'humain intervient si necessaire (pas de tout-ou-rien)
Ce qui existe deja dans le code : Le HybridPaymentSplitter gere exactement ce split. Il manque un AIAgentRegistry (prevu P2 dans le design doc, polkadot-dao-services-ai-design.md:742) qui doit monter en P0/P1.

Anti-pattern a eviter : Ne pas transformer ca en un "GPT wrapper marketplace". L'agent doit etre specialise (un agent = un domaine d'expertise specifique), pas generique.

Parcours C — "Marketplace de livrables tokenises"
Le client n'a pas forcement un probleme unique. Il cherche de la connaissance existante.

Client browse le catalogue de livrables (pas de brief)
    |
    v
Chaque livrable est un NFT avec :
    - Hash IPFS du contenu (rapport, modele, code, dataset)
    - Metadata : domaine, date, auteur, mission d'origine
    - Prix de licence : 5-20% du cout original
    - Score qualite : note moyenne des acheteurs precedents
    |
    v
Client achete une LICENCE (pas le livrable complet)
    |
    v
Revenue distribue automatiquement :
    - 50% auteur(s) original(aux) — humain et/ou agent IA
    - 20% client original (s'il a opte pour shared IP)
    - 20% DAO Treasury
    - 10% curateurs (ceux qui ont note/valide le livrable)

Pourquoi c'est un game changer :

Aujourd'hui un client paie 10k EUR pour une etude de marche qui a de la valeur pour 50 autres entreprises. Sur Malt, cette valeur est perdue.
Avec la tokenisation, chaque livrable devient un actif reutilisable avec un revenu recurrent
L'auteur gagne a la fois sur la mission originale ET sur les licences futures
Le client original peut choisir de partager l'IP en echange d'un budget reduit (-30%, comme prevu dans polkadot-dao-services-ai-design.md:556)
Ca cree un flywheel de connaissances : plus de missions → plus de livrables → plus de licences → plus de revenus → plus de missions
Ce qui existe dans le code : L'IPRegistry.sol est prevu dans le design doc (polkadot-dao-services-ai-design.md:740) avec IPRights struct + purchaseLicense(). Il n'est pas encore implemente.

Protection anti-copie : Le contenu est sur IPFS (public si licence MIT, chiffre si proprietaire). L'acces au lien IPFS est gate par le smart contract de licence. Ca n'empeche pas la copie (rien ne peut), mais ca garantit la tracabilite et la remuneration.

Trois parcours consultants viables
Consultant A — "Expert mission" (classique ameliore)
Parcours existant dans le codebase actuel. Le consultant recoit des briefs, propose, execute, est paye.

Amelioration cle : La reputation est portable (NFT on-chain), les frais sont 0% consultant (vs 10-20% ailleurs), l'escrow protege le paiement, et la progression rank 0→4 est meritocratique.

Consultant B — "Auteur d'agent IA"
Consultant expert cree un agent specialise
    |
    +-- Entraine un modele / fine-tune un LLM
    |   sur son domaine d'expertise
    |
    +-- Definit les prompts, les workflows,
    |   les sources de donnees
    |
    +-- Enregistre l'agent sur le AIAgentRegistry
    |   (nom, domaine, prix, track record)
    |
    v
L'agent travaille de maniere autonome :
    - Recoit des briefs via le matching engine
    - Genere des livrables
    - Accumule reputation (REP) pour son auteur
    |
    v
Revenue model :
    - Chaque livrable accepte → auteur touche 60%
    - Agent tourne 24/7 → revenus passifs
    - Auteur peut superviser/ameliorer l'agent
    - Track record de l'agent = reputation on-chain

Economie : Un consultant senior facture 800 EUR/jour chez Malt. En 5 jours (4000 EUR d'investissement temps), il cree un agent specialise qui genere 5 livrables/semaine a 200 EUR chacun = 4000 EUR/mois en passif. ROI en 1 mois. Le consultant peut avoir N agents + faire des missions manuelles en parallele.

Consultant C — "Curateur de connaissances"
Le consultant ne fait pas de missions mais :

Valide/note les livrables des autres (qualite editoriale)
Cree des compilations thematiques (meta-analyses)
Forme les juniors (mentorat → +2 REP)
Participe a la gouvernance
Revenue : commission de curation (10% sur les licences des livrables qu'il a valides) + REP pour participation.

Facteurs cles de succes Web3 appliques
En croisant les facteurs identifies dans 20260216-web3-success-failure-factors.md :

Facteur	Risque projet	Mitigation par ces parcours
PMF reel (n.1 facteur echec)	"Decentralized Malt" = pas assez differentie	Parcours B (agents IA) et C (livrables tokenises) sont des marches qui n'existent pas encore
Tokenomics durables	REP soulbound + CRED burn-on-use = solide	Revenus licences ajoutent un flux recurrent (pas que des frais de transaction)
UX trop complexe (barriere n.1)	Blockchain invisible pour clients	Parcours A/B/C sont 100% Web2 cote client
Token avant produit (n.1 cause echec)	REP pas necessaire avant M3	Parcours B/C fonctionnent sans token au MVP (paiement fiat)
Gouvernance faible	0.79% participation moyenne DAOs	REP soulbound + vote quadratique + decay = incitation structurelle
Securite	3 P0 identifies dans audit interne	Avant mainnet, pas avant MVP testnet
Feuille de route ajustee
Phase 0 — Maintenant → M1 : "Proof of Concept Agents IA"
Objectif : Valider le parcours B (agent IA repond a brief) avec 5 clients pilotes.

Action	Effort	Prealable
Finaliser Solidity MVP (30% restant)	3-4 sem	En cours
Creer AIAgentRegistry.sol minimal (register + match + payout)	1-2 sem	HybridPaymentSplitter OK
3 agents IA pilotes (etude marche, audit financier, analyse concurrentielle)	2 sem	Auteurs consultant identifies
5 briefs clients reels traites par agents	2 sem	Agents deployes
Mesurer : taux d'acceptation, satisfaction, cout vs mission classique	-	Briefs traites
Go/No-Go : Si taux acceptation agent > 30% → Parcours B valide. Si < 10% → Pivoter sur Parcours A seul.

Phase 1 — M1 → M3 : "MVP Marketplace hybride"
Action	Effort
ServiceMarketplace avec profils composes (humain + agent + compute)	3-4 sem
Frontend client : browse profils, voir agents disponibles, poster brief	3-4 sem
Escrow simplifie : multi-sig + NPS (pas d'oracle)	1-2 sem
Deploy Paseo testnet	1 sem
10 missions pilotes (mix humain + agent)	4 sem
Metrics : 10 missions completees, NPS >= 7, cout moyen -40% vs Malt

Phase 2 — M3 → M6 : "Tokenisation des livrables"
Action	Effort
IPRegistry.sol : NFT livrables + licences + royalties	3-4 sem
Catalogue livrables (issu des missions Phase 1)	2 sem
Frontend catalogue : browse, licence, paiement	3-4 sem
REP token ERC-5484 deploye	2-3 sem
Audit securite pre-mainnet	4-6 sem
Metrics : 5 licences vendues, revenue recurrent > 0, 50 membres actifs

Phase 3 — M6 → M12 : "Scale"
Action	Effort
Mainnet deployment	4 sem
20+ agents IA enregistres	Continu
Programme auteurs d'agents (formation + incentives)	2 sem
Compute marketplace (GPU providers)	6-8 sem
Decision Gate Substrate : si >100 missions/jour → POC Substrate	-
Ce que ca change dans le positionnement
Le projet n'est plus "Malt avec des frais plus bas et de la transparence" (necessaire mais copiable). Il devient :

"Un marche de l'expertise ou les livrables sont des actifs, les agents IA sont des consultants, et la reputation est un capital portable."

Trois marches en un :

Marche de missions (brief → equipe → livraison) — compete avec Malt, moins les frais
Marche d'agents IA (brief → reponse instantanee) — n'existe nulle part
Marche de connaissances (livrables tokenises → licences) — n'existe nulle part
Le moat n'est plus "blockchain = transparence" (argument faible, les clients s'en moquent). Le moat est : les agents IA et les livrables tokenises creent des effets de reseau que Malt/Upwork ne peuvent pas repliquer sans reconstruire toute leur architecture.

Je peux formaliser ca en document strategique et le committer sur la branche. Veux-tu qu'on approfondisse un parcours en particulier, ou qu'on ajuste la feuille de route ?