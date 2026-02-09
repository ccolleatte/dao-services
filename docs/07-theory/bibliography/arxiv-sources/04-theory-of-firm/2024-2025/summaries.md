# Theory of Firm - Summaries (2024-2025)

**Topic**: Theory of Firm, Organizational Governance, Mechanism Design
**Time Period**: 2024-2025
**Total Papers**: 13
**Last Updated**: 2026-02-09

---

## gersbach2025propose - Propose or Vote: A Canonical Democratic Procedure

**arXiv ID**: 2506.05998v2 | **Score**: 7/10 | **Status**: pending_review

Gersbach (2025) introduces Propose or Vote (PoV), a democratic procedure for collective decision-making that eliminates the need for a central mechanism designer. In the first stage, polity members choose whether to become proposal-makers or voters. In the second stage, voters decide by majority voting over submitted proposals. With appropriately chosen default points, PoV implements the Condorcet winner in a single round whenever one exists. The author demonstrates global uniqueness for odd-numbered members and shows how uniqueness can be restored for even numbers by adding an artificial agent. This mechanism can be applied to both policy decisions and candidate elections, offering a decentralized alternative to traditional voting systems.

**Pertinence**: MEDIUM relevance for DAO governance design. The decentralized nature of PoV aligns with blockchain governance principles, and the single-round Condorcet implementation could inspire on-chain voting mechanisms that minimize gas costs while maintaining democratic properties.

**Tags**: voting-mechanisms, condorcet-winner, decentralization, democratic-theory

**Citation Key**: gersbach2025propose

---

## bahel2024anonymous - Anonymous and Strategy-Proof Voting under Subjective Expected Utility Preferences

**arXiv ID**: 2401.04060v2 | **Score**: 8/10 | **Status**: pending_review

Bahel (2024) studies voting mechanisms under uncertainty where agents have subjective expected utility preferences and different states have different available outcomes. The paper characterizes social choice functions satisfying three axioms: anonymity (agents' labels don't matter), strategy-proofness (truthful reporting is dominant), and range unanimity (unanimous favorites must be selected). The author proves that such functions can be factored as products of voting rules that are either constant or binary, describing four basic types of binary factors that exploit voters' subjective beliefs. This represents a novel contribution to mechanism design under uncertainty, extending classical results to environments with heterogeneous belief structures.

**Pertinence**: HIGH relevance for blockchain governance under uncertainty. DAOs often face decisions where outcomes depend on uncertain future states (e.g., protocol upgrades, treasury allocations). The characterization of strategy-proof mechanisms with subjective beliefs could inform the design of Governor.sol voting extensions for conditional proposals.

**Tags**: mechanism-design, strategy-proofness, uncertainty, subjective-beliefs

**Citation Key**: bahel2024anonymous

---

## das2025strategic - Strategic Bid Shading in Real-Time Bidding Auctions Using Minority Game Theory

**arXiv ID**: 2512.15717v1 | **Score**: 7/10 | **Status**: pending_review

Das (2025) investigates bid shading behaviors in real-time bidding (RTB) auctions through the lens of minority game theory. Using large-scale Yahoo Webscope data, the study analyzes how advertisers strategically submit bids below private valuations in first-price auction settings. By integrating minority game theory with clustering algorithms, the author reveals that agents partition hourly ad slots into submarkets and place bids where they anticipate being in the numerical minority. This strategic heterogeneity enables reduced expenditure while enhancing win probability. The analysis demonstrates computational and economic implications for pricing dynamics in decentralized, high-frequency auction environments.

**Pertinence**: MEDIUM relevance for DAO token auction mechanisms. The minority game framework could inform MEV-resistant auction designs where validators strategically bid for block space. The empirical findings on bid shading provide insights for designing Dutch auctions or sealed-bid mechanisms in Governor.sol treasury management.

**Tags**: auction-theory, game-theory, bid-shading, minority-game

**Citation Key**: das2025strategic

---

## cha2025mechanism - Mechanism Design and Equilibrium Analysis of Smart Contract Mediated Resource Allocation

**arXiv ID**: 2510.05504v2 | **Score**: 8/10 | **Status**: pending_review

Cha et al. (2025) develop a mechanism design framework for smart contract-based resource allocation that explicitly embeds efficiency and fairness in decentralized coordination. The authors establish existence and uniqueness of contract equilibria, extending classical mechanism design results, and introduce a decentralized price adjustment algorithm with provable convergence guarantees implementable in real time. The framework is evaluated through synthetic benchmarks and a MovieLens case study, demonstrating substantial improvements in both efficiency and equity while remaining resilient to abrupt perturbations. The study highlights broad applicability to supply chains, energy markets, healthcare resource allocation, and public infrastructure where transparent coordination is critical.

**Pertinence**: HIGH relevance for DAO resource allocation mechanisms. The smart contract implementation with convergence guarantees directly applies to Governor.sol extensions for treasury fund allocation, grant distribution, and on-chain procurement. The fairness-efficiency trade-off analysis is particularly valuable for designing allocation rules that balance utilitarian and egalitarian principles in DAOs.

**Tags**: mechanism-design, smart-contracts, resource-allocation, convergence

**Citation Key**: cha2025mechanism

---

## luo2025toward - Toward Resilient Airdrop Mechanisms: Empirical Measurement and Game Theory Modeling

**arXiv ID**: 2503.14316v1 | **Score**: 8/10 | **Status**: pending_review

Luo et al. (2025) conduct an empirical analysis of airdrop hunter profits and develop a game-theoretic model for resilient airdrop mechanism design. Using transaction data from Hop Protocol and LayerZero, the study identifies prevalent Sybil attack patterns and estimates hunters' expected profits. The authors propose a three-player game model (attackers, organizers, bounty hunters) and derive optimal incentive structures that enhance detection while minimizing organizational costs. The empirical findings show that current airdrop mechanisms are vulnerable to systematic exploitation, with hunters achieving positive expected returns through multi-identity strategies.

**Pertinence**: HIGH relevance for DAO token distribution mechanisms. Airdrops are commonly used by DAOs for initial token distribution and community building. The Sybil-resistant mechanism design insights directly apply to Governor.sol extensions for fair token allocation, and the bounty hunter incentive model could inform decentralized detection systems for manipulation in on-chain voting.

**Tags**: airdrop, sybil-attacks, game-theory, token-distribution

**Citation Key**: luo2025toward

---

## delafuente2024game - Game Theory and Multi-Agent Reinforcement Learning: Nash Equilibria to Evolutionary Dynamics

**arXiv ID**: 2412.20523v1 | **Score**: 7/10 | **Status**: pending_review

De La Fuente et al. (2024) explore advanced topics in multi-agent systems, examining four fundamental challenges in Multi-Agent Reinforcement Learning (MARL): non-stationarity, partial observability, scalability, and decentralized learning. The paper provides mathematical formulations of recent algorithmic advancements and investigates how game-theoretic concepts (Nash equilibria, evolutionary game theory, correlated equilibrium, adversarial dynamics) can be incorporated into MARL algorithms. The synthesis demonstrates how combining game theory and MARL enhances robustness in complex, dynamic multi-agent environments.

**Pertinence**: MEDIUM relevance for DAO agent-based governance. As DAOs explore AI-assisted governance (e.g., delegate AI agents, automated parameter tuning), MARL frameworks could inform the design of decentralized coordination mechanisms. The Nash equilibrium analysis is particularly relevant for understanding strategic interactions in Governor.sol voting coalitions.

**Tags**: game-theory, reinforcement-learning, nash-equilibrium, multi-agent

**Citation Key**: delafuente2024game

---

## ganesh2024revisiting - Revisiting the Primitives of Transaction Fee Mechanism Design

**arXiv ID**: 2410.07566v1 | **Score**: 8/10 | **Status**: pending_review

Ganesh et al. (2024) propose a novel desideratum for transaction fee mechanisms: off-chain influence proofness, requiring that miners cannot achieve additional revenue by running separate auctions off-chain. The authors demonstrate that Ethereum's EIP-1559, while satisfying prior desiderata, fails this property because Bayesian revenue-maximizing miners can profit by threatening to censor bids without off-chain tips. They reconsider the Cryptographic Second Price Auction mechanism and prove it satisfies simplicity and off-chain influence proofness when miners set reserves directly. A strong impossibility result shows no mechanism satisfies all properties simultaneously, even with unlimited supply.

**Pertinence**: HIGH relevance for DAO treasury fee mechanisms. The off-chain influence proofness concept directly applies to Governor.sol execution fee designs, where malicious validators could extract value through side channels. The impossibility result suggests fundamental trade-offs in designing incentive-compatible fee structures for on-chain governance operations.

**Tags**: transaction-fees, mechanism-design, eip-1559, collusion-resistance

**Citation Key**: ganesh2024revisiting

---

## behera2024pfedgame - pFedGame: Decentralized Federated Learning Using Game Theory in Dynamic Topology

**arXiv ID**: 2410.04058v1 | **Score**: 7/10 | **Status**: pending_review

Behera and Chakraborty (2024) propose pFedGame, a game theory-based approach for decentralized federated learning in temporally dynamic networks. Operating without centralized aggregation servers, the algorithm addresses vanishing gradients and poor convergence in dynamic topologies. The solution comprises peer selection for collaboration and a two-player constant sum cooperative game to reach convergence through optimal aggregation strategies. Experiments on heterogeneous data demonstrate accuracy exceeding 70%, with improved resilience to model poisoning attacks compared to centralized approaches.

**Pertinence**: MEDIUM relevance for DAO decentralized oracle networks. The game-theoretic peer selection mechanism could inform the design of decentralized oracle aggregation in Governor.sol for off-chain data integration. The cooperative game framework provides insights for incentivizing honest reporting in multi-party computation scenarios common in DAOs.

**Tags**: game-theory, decentralization, federated-learning, cooperative-games

**Citation Key**: behera2024pfedgame

---

## chung2024collusion - Collusion-Resilience in Transaction Fee Mechanism Design

**arXiv ID**: 2402.09321v3 | **Score**: 7/10 | **Status**: pending_review

Chung et al. (2024) prove the first impossibility result for transaction fee mechanisms (TFMs) under contention: no randomized TFM satisfying user incentive compatibility (UIC), miner incentive compatibility (MIC), and OCA-proofness (collusion-resilience) exists when demand exceeds block capacity. This resolves the main open question in Roughgarden (EC'21). OCA-proofness asserts that users and miners cannot "steal from the protocol," while UIC requires truthful bidding. The authors show that Ethereum's EIP-1559 loses UIC under contention and propose several model relaxations to circumvent the impossibility result.

**Pertinence**: HIGH relevance for DAO execution fee markets. The impossibility result directly constrains the design space for Governor.sol execution priority mechanisms when multiple proposals compete for limited block space. Understanding fundamental trade-offs between collusion-resistance and incentive compatibility is critical for designing robust on-chain governance fee structures.

**Tags**: transaction-fees, collusion, impossibility-result, incentive-compatibility

**Citation Key**: chung2024collusion

---

## damle2024no - No Transaction Fees? No Problem! Achieving Fairness in Transaction Fee Mechanism Design

**arXiv ID**: 2402.04634v1 | **Score**: 7/10 | **Status**: pending_review

Damle et al. (2024) introduce novel fairness notions for transaction fee mechanisms (TFMs): Zero-fee Transaction Inclusion (ensuring free transactions can be included) and Monotonicity (higher bids increase inclusion probability). The authors prove that satisfying both properties while preventing miner manipulation is generally impossible. Existing TFMs either violate these fairness notions or sacrifice significant miner utility. The paper proposes rTFM, a novel mechanism using on-chain randomness that guarantees incentive compatibility for miners and users while satisfying the fairness constraints.

**Pertinence**: MEDIUM relevance for DAO governance accessibility. The zero-fee inclusion property directly addresses concerns about plutocratic voting where only wealthy token holders can afford governance participation. The rTFM design could inform Governor.sol extensions that balance gas fee requirements with democratic inclusivity, ensuring proposals from smaller stakeholders can reach on-chain execution.

**Tags**: transaction-fees, fairness, mechanism-design, randomness

**Citation Key**: damle2024no

---

## tang2023transaction - Transaction Fee Mining and Mechanism Design

**arXiv ID**: 2302.06769v1 | **Score**: 7/10 | **Status**: pending_review

Tang and Zhang (2023) provide a comprehensive survey of transaction fee mechanisms, analyzing incentive compatibility issues arising from user bids, miner allocation rules, and mining location choices in longest-chain consensus. The paper examines mining attacks (undercutting, fee sniping, fee-optimized selfish mining) and mechanistic notions of incentive compatibility (user IC, myopic miner IC, off-chain-agreement-proofness). The authors discuss why full compatibility is provably impossible and explore weaker notions (nearly IC, γ-weak IC) in classical mechanisms and recent designs like EIP-1559 and burning second-price auctions.

**Pertinence**: HIGH relevance for understanding fundamental constraints in DAO fee mechanism design. The survey provides essential context for Governor.sol execution priority mechanisms, particularly regarding impossibility results that constrain the design space. The analysis of fee-optimized selfish mining informs security considerations for time-sensitive governance proposals vulnerable to censorship attacks.

**Tags**: transaction-fees, mechanism-design, survey, incentive-compatibility

**Citation Key**: tang2023transaction

---

## mustafa2025simulation - A Simulation-Based Conceptual Model for Tokenized Recycling

**arXiv ID**: 2507.19901v1 | **Score**: 7/10 | **Status**: pending_review

Mustafa (2025) develops a conceptual simulation model for tokenized recycling that integrates blockchain infrastructure, market-driven pricing, behavioral economics, and carbon credit mechanisms. The model addresses limitations of traditional recycling systems by introducing dynamic token values linked to supply-demand conditions and incorporating non-monetary behavioral drivers (social norms, reputational incentives). Using Monte Carlo simulations, the framework estimates outcomes under scenarios involving operational costs, carbon pricing, token volatility, and behavioral adoption rates. Remaining theoretical due to lack of real-world implementations, the model serves as a prototype for future policy experimentation.

**Pertinence**: MEDIUM relevance for DAO incentive mechanism design. The dual-incentive structure (economic + behavioral) provides insights for Governor.sol reward mechanisms that combine token incentives with reputation-based voting power. The simulation-based approach to modeling token volatility and adoption dynamics is valuable for designing resilient DAO treasury management strategies.

**Tags**: tokenomics, behavioral-economics, carbon-credits, simulation

**Citation Key**: mustafa2025simulation

---

## kiayias2024single - Single-token vs Two-token Blockchain Tokenomics

**arXiv ID**: 2403.15429v3 | **Score**: 8/10 | **Status**: pending_review

Kiayias et al. (2024) study long-term equilibria in proof-of-stake (PoS) tokenomics, comparing single-token and two-token systems. The authors introduce Quantitative Rewarding (QR), a mechanism achieving viability (sustained engagement), decentralization (multiple invested validators), stability (stable token prices), and feasibility (smart contract implementability without fiat reserves). The analysis demonstrates concrete advantages of two-token settings for effective QR implementation and reveals inherent limitations of single-token systems for blockchain monetary policy. The paper provides the first systematic comparison of tokenomic architectures in PoS systems.

**Pertinence**: HIGH relevance for DAO tokenomics design. The single-token vs two-token analysis directly applies to decisions about Governor.sol native token economics versus dual-token governance structures (e.g., governance token + utility token). The QR mechanism provides a framework for designing sustainable validator incentives and treasury management strategies that maintain token price stability while ensuring decentralization.

**Tags**: tokenomics, proof-of-stake, monetary-policy, two-token-model

**Citation Key**: kiayias2024single

---

**Total Summaries**: 13
**Score Distribution**: 8/10 (5 papers), 7/10 (8 papers)
