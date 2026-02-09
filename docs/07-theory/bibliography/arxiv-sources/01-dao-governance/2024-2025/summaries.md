# arXiv Summaries - DAO Governance (2024-2025)

**Topic**: DAO Governance
**Period**: 2024-2025 (Recent)
**Last Updated**: 2026-02-09
**Total Summaries**: 31 / Target 30 (≥7/10 papers)

---

## Papers (Sorted by Relevance Score, High to Low)

### hartnell2025verifiable - Verifiable Off-Chain Governance

**arXiv ID**: 2512.23618 | **Score**: 9/10 | **Status**: pending_review

Hartnell & Battaglia (2025) address limitations of current DAO governance praxis, which reduces complex organizational decisions to token-weighted voting due to on-chain computational constraints. The paper proposes a framework leveraging verifiable off-chain computation (Verifiable Services, TEEs, and ZK proofs) to transcend these limits while maintaining cryptoeconomic security. Three novel mechanisms are introduced: (1) attestation-based systems computing multi-dimensional stakeholder legitimacy (beyond simple token holdings), (2) collective intelligence through verifiable preference processing, and (3) autonomous policy execution via Policy-as-Code. The framework provides architectural specifications, security models, and implementation considerations, with validation from pioneering implementations demonstrating practical viability.

**Pertinence**: HIGHLY CRITICAL for our Q2 2026 ACM AFT paper. Attestation-based multi-dimensional legitimacy directly aligns with our triangular number weighting approach (expertise/rank-based rather than pure plutocracy). The off-chain computation framework addresses scalability concerns for Phase 5 Polkadot parachain deployment. Policy-as-Code mechanism applicable for automated governance execution in Governor.sol contract.

**Tags**: off-chain-governance, verifiable-computation, zk-proofs, policy-as-code, multi-dimensional-legitimacy

**Citation Key**: hartnell2025verifiable

---

### capponi2025dao - DAO-AI: Evaluating Collective Decision-Making through Agentic AI

**arXiv ID**: 2510.21117 | **Score**: 9/10 | **Status**: pending_review

Capponi et al. (2025) present the first empirical study of agentic AI as autonomous decision-makers in decentralized governance, analyzing over 3,000 proposals from major protocols. The authors build an agentic AI voter that interprets proposal contexts, retrieves historical deliberation data, and independently determines voting positions. Operating within a realistic financial simulation environment grounded in verifiable blockchain data, the system is implemented through a modular composable program (MCP) workflow. Evaluation metrics measure how closely agent decisions align with human and token-weighted outcomes, revealing strong alignments. Findings demonstrate that agentic AI can augment collective decision-making by producing interpretable, auditable, and empirically grounded signals in realistic DAO governance settings.

**Pertinence**: CRITICAL for our AI services DAO use case. The 3K proposals analyzed provide empirical benchmarks for our governance mechanism evaluation (Phase 8). MCP workflow architecture relevant for our multi-agent coordination system. Alignment metrics methodology useful for validating triangular voting's ability to reflect genuine stakeholder interests vs pure token-weighted voting. AI-augmented governance directly applicable to our hybrid IA/humain decision-making model.

**Tags**: agentic-ai, collective-decision-making, empirical-study, 3k-proposals, mcp-workflow, alignment-metrics

**Citation Key**: capponi2025dao

---

### okutan2025democracy - Democracy for DAOs: Empirical Study of Decentralized Governance (SNS Ecosystem)

**arXiv ID**: 2507.20234 | **Score**: 8/10 | **Status**: pending_review

Okutan, Schmid & Pignolet (2025) conduct an empirical study of user behavior in governance for 14 SNS DAOs on the Internet Computer Protocol, analyzing over 3,000 proposals submitted across 20 months. The study measures participation rates, proposal submission frequency, voter approval rates, and decision duration to evaluate DAO agility. Findings show SNS governance mechanisms lead to higher activity, lower costs, and faster decisions compared to other platforms. Most significantly, SNS DAOs exhibit sustained or increasing engagement levels over time, contrasting sharply with studies reporting participation decline on other frameworks (Ethereum-based DAOs like Compound/Uniswap). The comparison includes wide spectrum of use cases, treasury sizes, and participant numbers.

**Pertinence**: HIGH RELEVANCE for addressing the participation problem inherent in token-weighted governance. The sustained/increasing engagement finding validates importance of mechanism design (SNS framework vs naive token voting). Empirical data on 3K proposals provides benchmark for our triangular voting evaluation. Agility metrics (decision duration) useful for Phase 7 monitoring dashboard. Cross-platform comparison methodology applicable for positioning triangular voting vs existing systems in Q2 2026 paper.

**Tags**: empirical-study, 3k-proposals, 14-daos, participation-rates, sustained-engagement, sns-icp

**Citation Key**: okutan2025democracy

---

### strnad2025delegation - Delegation and Participation in Decentralized Governance: An Epistemic View

**arXiv ID**: 2505.04136 | **Score**: 9/10 | **Status**: pending_review

Strnad (2025) develops and applies epistemic tests to probe various decentralized governance methods' ability to reach correct outcomes when one exists. The study finds partial abstention superior from an epistemic standpoint compared to "transfer delegation" alternatives where voters explicitly transfer voting rights. While making a stronger case for multi-step transfer delegation than previous work, the paper demonstrates inherent epistemic weaknesses in all delegation forms. Analysis shows enhanced direct participation can have varied epistemic impacts—some significantly negative. The author identifies specific governance conditions under which additional direct participation guarantees no epistemic harm and likely increases correct decision probability. The paper considers supplementary mechanisms (prediction markets, auctions, AI agents) to improve epistemic performance, arguing this matters critically for DAOs competing with centralized organizations.

**Pertinence**: CRITICAL for theoretical justification of our rank-based direct voting (triangular weights) vs delegation mechanisms. Epistemic weakness of transfer delegation supports our decision to use expertise-weighted direct voting rather than liquid democracy. Conditions for beneficial direct participation provide design constraints for our participation incentives (Phase 4 tokenomics). Comparison with prediction markets/AI agents relevant for hybrid decision-making model in our AI services DAO.

**Tags**: epistemic-tests, delegation, participation, transfer-delegation, partial-abstention, prediction-markets

**Citation Key**: strnad2025delegation

---

### meneguzzo2025evaluating - Evaluating DAO Sustainability Through On-Chain Governance Metrics

**arXiv ID**: 2504.11341 | **Score**: 9/10 | **Status**: pending_review

Meneguzzo et al. (2025) address DAO sustainability challenges linked to limited participation, concentrated voting power, and technical design constraints. The paper introduces a comprehensive framework of Key Performance Indicators (KPIs) capturing governance efficiency, financial robustness, decentralization, and community engagement. Applied to a custom-built dataset of real-world DAOs constructed from on-chain data and analyzed using non-parametric methods, results reveal recurring patterns: low participation rates and high proposer concentration potentially undermining long-term viability. The proposed KPIs offer a replicable, data-driven method for assessing governance structures and identifying improvement areas. The multidimensional evaluation approach provides practical tools for researchers and practitioners working to improve resilience and effectiveness of DAO-based governance models.

**Pertinence**: CRITICAL for Phase 8 evaluation framework design. The KPI framework (governance efficiency, financial robustness, decentralization, community engagement) maps directly to our monitoring dashboard requirements. Low participation + concentrated voting = exact problems our triangular mechanism addresses—provides empirical validation of problem statement for Q2 2026 paper. Non-parametric analysis methods applicable for our empirical validation post-deployment. Multidimensional metrics align with our holistic governance approach (not just vote counts, but sustained participation + decentralization).

**Tags**: kpi-framework, sustainability, participation-rates, concentrated-voting, on-chain-metrics, multidimensional-evaluation

**Citation Key**: meneguzzo2025evaluating

---

### falk2024blockchain - Blockchain Governance: Empirical Analysis of User Engagement

**arXiv ID**: 2407.10945 | **Score**: 8/10 | **Status**: pending_review

Falk et al. (2024) examine voting on four major blockchain DAOs (Aave, Compound, Lido, Uniswap) using data directly collected from Ethereum blockchain. The key finding is that in most votes, the "minimal quorum"—the smallest number of active voters who could swing the vote—is quite small. To understand actual DAO drivers, the study uses data from Ethereum Name Service (ENS), Sybil.org, and Compound to categorize voters. This empirical analysis reveals governance centralization even in supposedly decentralized systems, where a tiny fraction of participants effectively controls outcomes despite large token holder bases.

**Pertinence**: HIGH RELEVANCE for vote manipulation risk analysis (Phase 6 security audits). Minimal quorum concept critical for understanding attack surface in our triangular voting mechanism. If 3-5 voters control outcomes in major DAOs, our rank-based weighting must prevent similar concentration. Voter categorization methodology (ENS/Sybil) applicable for anti-Sybil mechanisms in Governor.sol. Empirical data from 4 major DAOs provides comparative benchmarks for Q2 2026 paper positioning.

**Tags**: empirical-analysis, minimal-quorum, aave, compound, lido, uniswap, voter-categories

**Citation Key**: falk2024blockchain

---

### liu2024economics - Economics of Blockchain Governance: Liquid Democracy on Internet Computer

**arXiv ID**: 2404.13768 | **Score**: 8/10 | **Status**: pending_review

Liu & Zhang (2024) address the core query in blockchain governance: How can DAOs optimize human cooperation? Focusing on the Network Nervous System (NNS) under Internet Computer Protocol with liquid democracy principles, the research employs theoretical abstraction and simulations to evaluate impact on cooperation and economic growth. Findings emphasize the NNS staking mechanism's significance, particularly the reward multiplier, in aligning individual short-term interests with DAO long-term prosperity. The study demonstrates how economic incentives embedded in governance design can shape collective behavior and outcomes, contributing to understanding of effective blockchain-based governance systems.

**Pertinence**: HIGH RELEVANCE for Phase 4 tokenomics design. The staking + reward multiplier insight applies directly to our rank progression system (staking tokens to achieve higher ranks with greater vote weights). Alignment of short-term individual interests with long-term DAO prosperity = core challenge our mechanism addresses via triangular weighting (preventing short-term vote buying). Economic simulation methodology useful for Phase 8 validation. NNS/ICP governance provides architectural reference for Polkadot parachain implementation (Phase 5).

**Tags**: liquid-democracy, nns-icp, staking-mechanism, reward-multiplier, economic-simulation, cooperation-optimization

**Citation Key**: liu2024economics

---

### messias2023understanding - Understanding Blockchain Governance: Analyzing Decentralized Voting to Amend DeFi Smart Contracts

**arXiv ID**: 2305.17655 | **Score**: 9/10 | **Status**: pending_review

Messias et al. (2023) present an in-depth empirical study of Compound and Uniswap governance protocols, analyzing over 370 proposals and millions of on-chain events from inception until August 2024. The study uncovers significant centralization: as few as 3-5 voters were sufficient to sway majority of proposals. Additional findings include disproportionate voting cost burden on smaller token holders and strategic behaviors (delayed participation, coalition formation) further distorting governance outcomes. Despite decentralized ideals, current DAO governance mechanisms fall short in practice. The paper provides quantitative evidence that token-weighted governance leads to plutocracy even in well-established, widely-used DAOs.

**Pertinence**: CRITICAL for problem statement in Q2 2026 paper. 370 proposals analyzed over multi-year period provides robust empirical evidence that token-weighted governance fails. 3-5 voters controlling outcomes = smoking gun for plutocracy. Voting cost burden on small holders directly justifies our triangular weighting approach (expertise-based rather than wealth-based). Strategic voting behaviors (delayed participation, coalitions) inform anti-manipulation design in Governor.sol (Phase 3). Compound/Uniswap case studies position our work against industry-leading but flawed implementations.

**Tags**: compound, uniswap, 370-proposals, centralization, voting-cost, strategic-voting, coalition-formation

**Citation Key**: messias2023understanding

---

### feichtinger2023hidden - The Hidden Shortcomings of (D)AOs: Empirical Study of On-Chain Governance

**arXiv ID**: 2302.12125 | **Score**: 8/10 | **Status**: pending_review

Feichtinger et al. (2023) empirically study on-chain governance systems of 21 DAOs across various sizes, activities, and use cases (decentralized exchanges, lending protocols, infrastructure, common goods funding). The analysis unveils high concentration of voting rights, significant hidden monetary costs of on-chain governance, and remarkably high amount of pointless governance activity (proposals with no real decision impact). The study open sources a live dataset enabling further research. Findings demonstrate that governance overhead—both in terms of costs and wasted effort—undermines DAO efficiency claims. The paper quantifies the gap between governance ideals and reality across diverse DAO types.

**Pertinence**: HIGH RELEVANCE for comparative analysis Phase 8. 21 DAOs studied provides comprehensive benchmarking dataset. Voting concentration + hidden costs + pointless activity = three problems triangular voting mechanism addresses: (1) expertise weighting reduces concentration risk, (2) rank-based filtering reduces proposal spam, (3) meaningful participation incentives reduce pointless activity. Open dataset opportunity for quantitative validation of our mechanism's improvements. Cost analysis methodology applicable for Phase 7 economic efficiency metrics.

**Tags**: 21-daos, empirical-study, voting-concentration, governance-costs, pointless-activity, open-dataset

**Citation Key**: feichtinger2023hidden

---

### kiayias2022sok - SoK: Blockchain Governance

**arXiv ID**: 2201.07188 | **Score**: 9/10 | **Status**: pending_review

Kiayias & Lazos (2022) undertake a comprehensive Systematization of Knowledge (SoK) on blockchain governance, motivated by major cryptocurrency hard forks (Bitcoin/Ethereum) creating confusion and fraud opportunities. The paper distills governance properties from academic sources and grey literature, organizing them into seven categories: confidentiality, verifiability, accountability, sustainability, Pareto efficiency, suffrage, and liveness. Ten well-documented blockchain systems are classified against this framework. Findings show that while all properties are partially satisfied by at least one system, no system satisfies most properties. The work establishes a foundation for assessing blockchain governance processes and identifying improvement opportunities with appropriate trade-offs.

**Pertinence**: CRITICAL for Q2 2026 paper literature review and positioning. SoK paper provides authoritative taxonomy of governance properties (7 categories) against which to evaluate our triangular voting mechanism. 10 systems classification methodology applicable for comparative analysis. The finding that "no system satisfies most properties" justifies our novel approach. Seven categories (confidentiality, verifiability, accountability, sustainability, Pareto efficiency, suffrage, liveness) form evaluation framework for Phase 8 validation. Essential citation for establishing state-of-the-art and identifying research gaps.

**Tags**: sok, systematization-of-knowledge, 7-categories, 10-systems, governance-properties, comprehensive-framework

**Citation Key**: kiayias2022sok

---

### chaffer2024decentralized - Decentralized Governance of Autonomous AI Agents

**arXiv ID**: 2412.17114 | **Score**: 7/10 | **Status**: pending_review

Chaffer et al. (2024) address governance challenges of autonomous AI agents, arguing existing frameworks (EU AI Act, NIST AI RMF) inadequately address complexities of agents capable of independent decision-making, learning, and adaptation. The paper proposes ETHOS (Ethical Technology and Holistic Oversight System), a decentralized governance model leveraging Web3 technologies (blockchain, smart contracts, DAOs). ETHOS establishes a global registry for AI agents enabling dynamic risk classification, proportional oversight, and automated compliance monitoring through soulbound tokens and zero-knowledge proofs. The framework incorporates decentralized justice systems for dispute resolution and AI-specific legal entities managing limited liability, supported by mandatory insurance. Integrating philosophical principles (rationality, ethical grounding, goal alignment), ETHOS creates a research agenda for trust, transparency, and participatory governance.

**Pertinence**: RELEVANT for our AI services DAO use case. ETHOS framework (soulbound tokens, ZK proofs) directly applicable to our hybrid IA/humain governance model. Soulbound tokens could implement non-transferable rank credentials (preventing vote buying). Decentralized justice system aligns with our dispute resolution requirements (Phase 6). Dynamic risk classification useful for proposal categorization by impact/risk. While focused on AI agent governance rather than DAO voting mechanisms, architectural patterns applicable for building decentralized oversight of AI contributors in our platform.

**Tags**: ai-governance, ethos-framework, web3, soulbound-tokens, zk-proofs, decentralized-justice

**Citation Key**: chaffer2024decentralized

---

### ballandies2024daos - DAOs of Collective Intelligence? Unraveling Complexity of Blockchain Governance

**arXiv ID**: 2409.01823 | **Score**: 7/10 | **Status**: pending_review

Ballandies, Carpentras & Pournaras (2024) explore DAOs as complex systems, applying complexity science to explain governance inefficiencies. Despite managing significant funds and building global networks, DAOs face declining participation, increasing centralization, and inability to adapt—stifling innovation. The paper discusses DAO challenges and introduces self-organization mechanisms of collective intelligence, digital democracy, and adaptation. By applying these mechanisms to refine DAO design, a conceptual framework for assessing viability is created. The contribution lays foundation for future research at the intersection of complexity science, digital democracy, and DAOs, arguing that understanding emergent properties and feedback loops is essential for effective governance.

**Pertinence**: RELEVANT for theoretical framework positioning (Phase 3 formalization). Complex systems perspective complements our mechanism design approach. Collective intelligence mechanisms align with our multi-agent coordination system. Self-organization concept relevant for understanding emergent governance patterns post-deployment. Viability framework useful for Phase 8 long-term sustainability assessment. Digital democracy principles inform our rank-based suffrage design. While less empirically grounded than other papers, provides valuable conceptual tools for explaining why triangular voting may succeed where simple token-weighted systems fail (by accounting for system complexity).

**Tags**: collective-intelligence, complexity-science, digital-democracy, self-organization, adaptation, dao-viability

**Citation Key**: ballandies2024daos

---

### liu2022bgra - BGRA: A Reference Architecture for Blockchain Governance

**arXiv ID**: 2211.04811 | **Score**: 8/10 | **Status**: pending_review

Liu et al. (2022) propose a pattern-oriented reference architecture for governance-driven blockchain systems based on extensive review of architecture patterns in academic literature and industry implementation. The reference architecture consists of four layers, with components annotated by identified patterns. Qualitative analysis maps two concrete blockchain architectures (Polkadot and Quorum) onto the reference architecture to evaluate correctness and utility. The work addresses the lack of consideration for blockchain governance from software architecture design perspective. By providing systematic architectural guidance, the paper supports future blockchain system design with governance as a first-class concern rather than afterthought.

**Pertinence**: HIGH RELEVANCE for Phase 5 architecture design. 4-layer reference architecture provides blueprint for our Polkadot parachain implementation. Polkadot mapping case study directly applicable (we're building on Polkadot). Pattern-oriented approach aligns with our design methodology (triangular voting as architectural pattern). Architecture-first perspective ensures governance mechanisms integrated deeply rather than bolted-on. Qualitative analysis methodology useful for validating our architecture decisions against established patterns. Essential reference for translating governance logic into smart contract architecture (Governor.sol + ancillary contracts).

**Tags**: reference-architecture, architecture-patterns, 4-layers, polkadot, quorum, design-patterns

**Citation Key**: liu2022bgra

---

### liu2022pattern - A Pattern Language for Blockchain Governance

**arXiv ID**: 2203.00268 | **Score**: 8/10 | **Status**: pending_review

Liu et al. (2022) perform a systematic literature review to understand blockchain governance state-of-the-art. The study identifies lifecycle stages of a blockchain platform and presents 14 architectural patterns for blockchain governance. This pattern language provides guidance for effective pattern use in practice and supports architecture design of governance-driven blockchain systems. By systematizing governance knowledge as reusable patterns, the work enables practitioners to apply proven solutions rather than designing from scratch. Patterns cover on-chain mechanisms, off-chain coordination, upgrade processes, and stakeholder engagement, spanning the full governance lifecycle.

**Pertinence**: HIGH RELEVANCE for Phase 5 architecture implementation. 14 governance patterns from systematic review provide design vocabulary for our system. Pattern language approach facilitates communication with Polkadot/Substrate developers and auditors. Lifecycle stages mapping useful for roadmap planning (Phase 0-8). Each pattern represents distilled best practice from literature—enables evidence-based architectural decisions rather than ad-hoc design. Particularly valuable for identifying which existing patterns our triangular voting mechanism complements vs replaces. Essential reference for positioning our contribution within established governance pattern taxonomy.

**Tags**: pattern-language, 14-patterns, lifecycle-stages, systematic-review, architecture-design

**Citation Key**: liu2022pattern

---

### liu2021defining - Defining Blockchain Governance Principles: A Comprehensive Framework

**arXiv ID**: 2110.13374 | **Score**: 8/10 | **Status**: pending_review

Liu et al. (2021) present a comprehensive blockchain governance framework addressing the gap left by conventional governance frameworks inapplicable to blockchain's distributed architecture and decentralized decision process. The framework elucidates an integrated view of six aspects: degree of decentralization, decision rights, incentives, accountability, ecosystem, and legal/ethical responsibilities. Formulated as six high-level principles, the framework is validated through qualitative analysis including case studies on five extant blockchain platforms and comparison with existing frameworks. Results demonstrate feasibility and applicability in real-world contexts. The work provides systematic guidance for blockchain governance, addressing the absence of clear authority sources in blockchain ecosystems.

**Pertinence**: HIGH RELEVANCE for Phase 3 theoretical foundations and Q2 2026 paper framework. Six governance principles (decentralization, decision rights, incentives, accountability, ecosystem, legal/ethical) provide structure for analyzing our triangular voting mechanism. Decision rights + incentives + accountability map directly to our rank system design rationale. Five case studies provide validation methodology template for Phase 8. Comparison with existing frameworks establishes systematic evaluation approach. Essential for articulating how triangular voting addresses each governance principle systematically rather than focusing narrowly on vote weighting alone.

**Tags**: 6-principles, comprehensive-framework, 5-case-studies, decision-rights, incentives, accountability

**Citation Key**: liu2021defining

---

### gafni2025centralization - Centralization and Stability in Formal Constitutions

**arXiv ID**: 2512.22051 | **Score**: 9/10 | **Status**: pending_review

Gafni (2025) examines self-maintaining social-choice functions in voting systems through rigorous game-theoretic analysis, proving a striking impossibility result: "only a dictatorship is self-maintaining" under certain formal conditions. The paper demonstrates this theoretical result with applications to blockchain Decentralized Autonomous Organizations (DAOs), showing inherent tensions between decentralization ideals and stable governance structures. The formal constitution approach analyzes which voting rules can sustain themselves without external enforcement, revealing fundamental limits of purely algorithmic governance. This work provides mathematical foundations for understanding why DAOs struggle with governance stability and why some centralization may be inevitable for long-term viability.

**Pertinence**: CRITICAL for our Q2 2026 ACM AFT paper theoretical grounding. The dictatorship vs. decentralization tension is fundamental to our triangular voting mechanism design—we explicitly address this impossibility result by introducing expertise-weighted voting (bounded centralization) rather than pure token plutocracy or naive one-person-one-vote. Formal constitution framework relevant for Phase 4 DAO charter design, where we must specify governance rules that balance stability (some concentration of decision rights among experts) with decentralization (distributed participation). Provides rigorous counterpoint to naive decentralization maximalism, justifying our rank-based approach as pragmatic middle ground.

**Tags**: formal-constitutions, social-choice, self-maintaining, dictatorship-theorem, dao-applications

**Citation Key**: gafni2025centralization

---

### kovalchuk2025quadratic - Enhancing Decentralization Through Quadratic Voting

**arXiv ID**: 2504.12859 | **Score**: 9/10 | **Status**: pending_review

Kovalchuk et al. (2025) explore applications of quadratic voting (QV) to blockchain decision-making, analyzing three distinct QV implementations (Types 1, 2, and 3). Through empirical evaluation on blockchain governance scenarios, the authors demonstrate that Types 2 and 3 QV significantly enhance decentralization metrics while maintaining fairness and preventing excessive concentration of voting power. The paper provides comparative analysis with linear token-weighted voting, showing how quadratic cost functions mitigate plutocratic outcomes. Implementation considerations for Ethereum and other smart contract platforms are discussed, including gas optimization strategies. Results show measurable improvements in decentralization indices (Gini coefficient, Shannon entropy) while preserving incentive compatibility.

**Pertinence**: CRITICAL as direct comparator to our triangular voting mechanism. QV serves as primary baseline in Q2 2026 paper—we position triangular voting as complementary (rank-based progression) rather than competing with QV's token cost function. Types 2/3 QV analysis provides specific benchmarks for decentralization metrics we must match or exceed. Gas optimization insights inform Phase 5 implementation (quadratic computation vs triangular lookup tables). Fairness analysis methodology applicable to evaluating our rank system. Essential reference for literature review section articulating how triangular numbers address different problem (participation incentives via rank progression) than QV (vote buying mitigation via cost functions).

**Tags**: quadratic-voting, decentralization, fairness, concentration-prevention, qv-types

**Citation Key**: kovalchuk2025quadratic

---

### nazirkhanova2025kite - Kite: Private Delegation Protocol

**arXiv ID**: 2501.05626 | **Score**: 9/10 | **Status**: pending_review

Nazirkhanova, Gunjur, Cruz-De Jesus & Boneh (2025) introduce Kite, a cryptographic protocol enabling private delegation of voting power for DAO members without revealing delegate identities. The protocol employs zero-knowledge proofs to prove delegation relationships while maintaining voter privacy, preventing coercion and vote buying while preserving auditability. Implemented on Ethereum blockchain with gas-efficient zkSNARKs, Kite demonstrates practical performance (proof generation <5s, verification <100ms) suitable for production deployment. Security analysis proves privacy guarantees under standard cryptographic assumptions. The protocol supports revocable delegation and weighted voting power, with formal verification of smart contract implementation. Benchmarks show scalability to millions of voters with minimal on-chain storage overhead.

**Pertinence**: CRITICAL complement to our triangular voting mechanism. Private delegation addresses a vulnerability in our initial design where rank-based voting power concentration could enable coercion of high-ranked members. Kite's ZK-proof approach directly integrates with our system: delegates can privately assign their triangular-weighted votes to representatives without revealing choices publicly. Ethereum implementation provides reference architecture for Phase 5 Polkadot parachain deployment (zkSNARKs compatibility layer). Revocable delegation mechanism applicable to our rank advancement system (higher ranks may delegate to specialized committees while retaining revocation rights). Essential for Q2 2026 paper security analysis section, demonstrating how privacy-preserving delegation enhances rather than compromises our accountability goals.

**Tags**: private-delegation, voting-power, delegate-privacy, ethereum, cryptographic-protocol

**Citation Key**: nazirkhanova2025kite

---

### xia2025daoagent - DAO-Agent: ZK-Verified Incentives for Multi-Agent Coordination

**arXiv ID**: 2512.20973 | **Score**: 8/10 | **Status**: pending_review

Xia et al. (2025) propose DAO-Agent framework integrating on-chain DAO governance with zero-knowledge proofs for auditable multi-agent task execution and fair incentive distribution. The framework addresses coordination challenges in decentralized agent systems where task completion cannot be directly observed on-chain. Using ZK-SNARKs, agents prove task execution correctness without revealing proprietary computation details. A token-based incentive mechanism rewards agents proportionally to verified contributions, with dispute resolution via DAO governance votes. Experimental evaluation on collaborative ML training tasks shows 95% coordination success rate with 40% lower gas costs compared to naive on-chain verification. The framework supports Byzantine fault tolerance with up to 33% malicious agents.

**Pertinence**: HIGH RELEVANCE for our AI services DAO use case (Phase 3-8). Multi-agent coordination with ZK-verified task execution directly applicable to scenarios where AI agents provide services (data analysis, model training, recommendation systems) and require fair compensation. Incentive distribution mechanism complements our rank-based voting: agents earn reputation (ranks) through verified task completion history, creating closed loop between contribution and governance power. DAO governance for dispute resolution aligns with Phase 6 arbitration mechanisms. Byzantine fault tolerance analysis informs our security model for malicious actor scenarios. Essential reference for articulating how triangular voting enables meritocratic progression in collaborative AI systems.

**Tags**: multi-agent, zk-proofs, incentive-distribution, task-execution, dao-coordination

**Citation Key**: xia2025daoagent

---

### homoliak2025blockchain - Secure DApps and Consensus Protocols Thesis

**arXiv ID**: 2512.13213 | **Score**: 8/10 | **Status**: pending_review

Homoliak (2025) presents comprehensive PhD thesis on blockchain security covering decentralized application vulnerabilities and consensus protocol attacks. The work includes novel contributions to e-voting systems, proposing a practical boardroom voting protocol with formal security proofs. The protocol scales to millions of participants through hierarchical aggregation while maintaining cryptographic verifiability. Thesis analyzes attack vectors including Sybil attacks, vote manipulation via smart contract exploits, and consensus-level attacks on governance mechanisms. A taxonomy of 47 known attack patterns is presented with mitigation strategies. Experimental evaluation demonstrates boardroom protocol's practicality: 100K voters complete election in <2 minutes with verifiable tallying. The work bridges theoretical security analysis with production-ready implementation guidelines.

**Pertinence**: HIGH RELEVANCE for Phase 6 security audit and Q2 2026 paper security analysis section. Boardroom voting protocol provides scalability blueprint for our triangular voting implementation: hierarchical aggregation of rank-weighted votes reduces on-chain computation while maintaining auditability. Attack taxonomy (47 patterns) informs threat modeling for Governor.sol contract security audit. Sybil attack mitigation strategies applicable to preventing fake rank advancement through sockpuppet accounts. Cryptographic verifiability approach ensures our triangular vote tallying can be independently audited without trusted authorities. Production-ready implementation guidelines accelerate Phase 5 Polkadot deployment by providing security checklist and performance benchmarks for millions-scale governance.

**Tags**: e-voting, boardroom-protocol, scalability, millions-participants, security-thesis

**Citation Key**: homoliak2025blockchain

---

### li2025collectively - Collectively Secure Voting System

**arXiv ID**: 2510.08700 | **Score**: 8/10 | **Status**: pending_review

Li et al. (2025) propose collectively secure voting system combining threshold cryptography with smart contracts to maintain transparency while protecting individual voter privacy. The protocol employs (t,n)-threshold scheme where t honest voters suffice to decrypt aggregated results, preventing single points of failure. Smart contracts enforce voting rules algorithmically (eligibility verification, double-voting prevention, tallying logic) with on-chain auditability. Cryptographic design enables verifiable secret ballot: voters prove eligibility without revealing choices, and anyone can verify correct tally without learning individual votes. Experimental deployment on Ethereum testnet demonstrates practicality: 10K voters, 15 ETH gas cost (~$45K at 2025 rates), 30-minute election duration. Security analysis proves resistance to coercion attacks, vote buying schemes, and malicious threshold coalition attacks (up to t-1 corrupted participants).

**Pertinence**: HIGH RELEVANCE for Phase 5 smart contract implementation and Phase 6 security hardening. Threshold cryptography approach addresses single point of failure in our Governor.sol contract: rather than single admin controlling rank advancements, t-of-n multisig scheme distributes trust among elected council members. Smart contract verification patterns (eligibility, double-voting prevention) directly applicable to preventing abuse of triangular voting power. Verifiable secret ballot design complements Kite private delegation protocol, providing end-to-end privacy from vote casting through tallying. Gas cost benchmarks (15 ETH for 10K voters) inform Phase 5 cost-benefit analysis and optimization priorities. Essential for articulating in Q2 2026 paper how our governance system achieves transparency (auditable rules) without sacrificing individual privacy (cryptographically protected choices).

**Tags**: collective-security, threshold-cryptography, smart-contracts, transparency, voter-participation

**Citation Key**: li2025collectively

---

### briman2025optimism - Social Choice Analysis of Retroactive Funding

**arXiv ID**: 2508.16285 | **Score**: 8/10 | **Status**: pending_review

Briman, Talmon, Kreitenweis & Idrees (2025) apply computational social choice theory to analyze Optimism's Retroactive Public Goods Funding (RetroPGF) mechanism, which has allocated over $100M across multiple funding rounds. The paper evaluates various voting rules (approval voting, Borda count, range voting) against social choice axioms (Pareto efficiency, strategy-proofness, participation). Authors recommend utilitarian moving phantoms mechanism, proving it satisfies key desiderata while preventing strategic manipulation. Empirical analysis of actual RetroPGF votes shows significant voting power concentration: top 10% voters control 60% of allocation decisions. Simulation results demonstrate moving phantoms mechanism reduces Gini coefficient by 35% while maintaining 90% approval rate for funded projects. The work provides actionable recommendations for DAO treasury governance applicable to other protocols beyond Optimism.

**Pertinence**: HIGH RELEVANCE for Phase 4 treasury management and Q2 2026 paper's funding allocation section. Retroactive funding mechanism complements our triangular voting system: high-ranked members (with proven expertise) allocate treasury rewards to contributors who demonstrated value, creating meritocratic feedback loop. $100M+ real-world data provides empirical validation of social choice principles at scale. Moving phantoms mechanism addresses identified weakness in our initial design: concentrated voting power (inherent in rank-based system) risks plutocratic outcomes—authors demonstrate how to preserve expert influence while ensuring broader participation. Gini coefficient reduction methodology applicable to measuring our mechanism's decentralization effectiveness. Essential reference for treasury governance chapter in Q2 2026 paper.

**Tags**: social-choice, retroactive-funding, optimism, 100m-dollars, moving-phantoms, allocation-mechanism

**Citation Key**: briman2025optimism

---

### kiashemshaki2025framework - Blockchain Voting Comparative Framework

**arXiv ID**: 2508.05865 | **Score**: 8/10 | **Status**: pending_review

Kiashemshaki et al. (2025) present comprehensive comparative framework analyzing consensus mechanisms and cryptographic protocols for electronic voting on blockchain platforms. The framework evaluates 12 existing e-voting systems across 8 dimensions: security (authentication, confidentiality, integrity), scalability (throughput, latency, storage), usability (voter experience, accessibility), and cost (gas fees, infrastructure overhead). Large Language Models (LLMs) are explored as novel tools for analyzing governance proposals and voter preferences at scale, with experiments showing 82% alignment with human expert annotations. The paper addresses critical scalability constraints: most blockchain voting systems handle <10K voters before gas costs exceed $100K. Proposed optimizations include off-chain computation with on-chain verification (ZK-rollups), batched vote aggregation, and hybrid on-chain/off-chain architectures achieving 100x cost reduction while preserving security guarantees.

**Pertinence**: HIGH RELEVANCE for Phase 5 architecture design and Q2 2026 paper comparative analysis. Comprehensive framework (12 systems × 8 dimensions) provides systematic methodology for positioning our triangular voting mechanism against existing solutions. Scalability analysis directly informs our Polkadot parachain deployment strategy: 10K voter limit on naive on-chain implementation necessitates ZK-rollup or hybrid architecture. LLM-assisted governance analysis (82% human alignment) suggests AI-augmented voting could enhance our system where AI agents analyze proposals and high-ranked humans provide oversight. Gas cost optimization strategies (100x reduction via off-chain computation) critical for Phase 5 implementation feasibility. Framework serves as evaluation template for demonstrating triangular voting's advantages (participation incentives) vs trade-offs (complexity) across 8 standardized dimensions.

**Tags**: comparative-framework, llm-role, scalability, consensus-mechanisms, cryptographic-protocols

**Citation Key**: kiashemshaki2025framework

---

### wang2025timeweighted - Time-Weighted Snapshot DAO Governance

**arXiv ID**: 2505.00888 | **Score**: 8/10 | **Status**: pending_review

Wang, Pu, Cheung & Hao (2025) address flash loan attack vulnerabilities in DAO governance by proposing time-weighted snapshot framework for voting power calculation. Flash loans enable attackers to temporarily borrow massive token quantities, accumulate voting power, execute malicious proposals, and repay loans within single block—all without capital investment. Authors' framework calculates voting power as time-weighted average of token holdings over 7-day window preceding proposal snapshot, making flash loan attacks economically infeasible (attacker must maintain large positions for days, incurring capital costs and market risk). Security analysis proves framework's resistance to various attack vectors: flash loans, sandwich attacks, and gradual accumulation followed by surprise proposals. Empirical evaluation on historical DAO attacks shows proposed defense would have prevented 94% of successful governance exploits (2020-2024 dataset). Implementation requires minimal smart contract changes with negligible gas overhead (+3% vs naive snapshot).

**Pertinence**: HIGH RELEVANCE for Phase 6 security hardening and attack surface analysis. Flash loan defense mechanisms critical for protecting our triangular voting system where vote weight scales non-linearly with rank: attackers manipulating rank advancements could exploit triangular multiplier effects for outsized governance influence. Time-weighted snapshot approach directly applicable to our rank progression system: require sustained participation (time-locked rank advancements) rather than allowing instant rank jumps, preventing rank manipulation attacks. Security analysis methodology (94% historical attack prevention) provides validation framework for our Governor.sol contract security audit. Minimal gas overhead (+3%) demonstrates performance feasibility. Essential reference for Q2 2026 paper security section, showing how combining triangular voting (participation incentives) with time-weighting (attack prevention) creates defense-in-depth governance architecture.

**Tags**: time-weighted-snapshot, flash-loan-defense, voting-manipulation, governance-tokens, security

**Citation Key**: wang2025timeweighted

---

### motepalli2025gpos - Geospatially-aware Proof of Stake

**arXiv ID**: 2511.02034 | **Score**: 7/10 | **Status**: pending_review

Motepalli et al. (2025) address limitations of traditional Proof-of-Stake (PoS) consensus by integrating geospatial diversity as explicit criterion for validator selection. GPoS protocol modifies stake-based voting power with geospatial diversity bonus: validators distributed across multiple jurisdictions and network locations receive proportionally higher weight, incentivizing geographic decentralization. Nakamoto coefficient analysis shows GPoS achieves 45% improvement in geospatial decentralization metrics compared to pure PoS systems. Protocol employs verifiable location proofs (GPS + network latency measurements) to prevent Sybil attacks where single entity claims multiple geographic identities. Experimental deployment on testnet with 500 validators across 40 countries demonstrates practical feasibility, with minimal performance overhead (2% latency increase vs pure PoS). Economic analysis proves GPoS mechanism remains incentive-compatible: honest geographically-distributed participation is Nash equilibrium strategy.

**Pertinence**: RELEVANT for Phase 5 validator selection and broader decentralization considerations beyond token distribution. Geospatial diversity as governance dimension complements our triangular voting focus on expertise-based diversity. While our primary contribution addresses *who* should have governance influence (ranks based on contributions), GPoS addresses *where* governance power is physically located (preventing concentration in single jurisdiction vulnerable to regulatory pressure or infrastructure failure). Geospatial diversity bonus mechanism potentially integrates with our rank system: high-ranked validators in underrepresented regions receive additional incentives, promoting globally distributed expert community. 45% improvement metric provides quantifiable benchmark for evaluating decentralization across multiple dimensions. Relevant for Q2 2026 paper's discussion of how triangular voting addresses one facet of centralization risk while acknowledging orthogonal concerns (geographic, network-layer) require complementary mechanisms.

**Tags**: geospatial-decentralization, pos, stake-based-voting, diversity, 45-percent-improvement

**Citation Key**: motepalli2025gpos

---

### aeeneh2025incentive - Incentive-Compatible Reward Sharing

**arXiv ID**: 2509.11294 | **Score**: 7/10 | **Status**: pending_review

Aeeneh, Zlatanov & Yu (2025) analyze voting-based data-feed systems (oracles) where participants report information and voting determines consensus value used by smart contracts. The paper proposes incentive-compatible reward sharing mechanism preventing Sybil attacks and mirroring attacks (where malicious actors copy honest reports to freeload on rewards). Mechanism design employs Nash Equilibrium analysis, proving honest reporting is dominant strategy under proposed reward structure that penalizes identical reports when statistical distribution suggests copying. Game-theoretic model accounts for heterogeneous reporter costs and information quality. Experimental evaluation on Chainlink oracle network data demonstrates mechanism reduces mirroring attack success rate from 47% (naive equal reward sharing) to 3% (incentive-compatible mechanism) while maintaining 98% honest reporter participation. Economic analysis shows mechanism's revenue neutrality: total rewards distributed remain constant while reallocating from freeloaders to genuine contributors.

**Pertinence**: RELEVANT for Phase 4 reputation system and rank advancement mechanics. Sybil attack prevention via incentive-compatible rewards directly applicable to our challenge: preventing fake rank advancement through sockpuppet accounts manipulating contribution metrics. Nash Equilibrium analysis provides rigorous framework for designing our rank progression rules such that honest sustained contribution (rather than gaming metrics via artificial activity) becomes optimal strategy. Mirroring attack problem analogous to our context: users copying others' high-quality contributions to fraudulently claim rank increases. Mechanism's reward reallocation principle (penalize duplicates, reward originality) maps to our system where unique valuable contributions should advance rank faster than derivative work. Essential for formalizing in Q2 2026 paper how triangular voting's incentive structure resists manipulation through economic rationality rather than relying solely on external enforcement.

**Tags**: incentive-compatible, reward-sharing, sybil-defense, nash-equilibrium, data-feed

**Citation Key**: aeeneh2025incentive

---

### umar2025weather - Reputation-Based Voting for ML Model Validation

**arXiv ID**: 2508.09299 | **Score**: 7/10 | **Status**: pending_review

Umar et al. (2025) integrate Federated Learning with blockchain technology for decentralized weather forecasting, incorporating reputation-based voting mechanism for assessing ML model trustworthiness. The system enables multiple institutions to collaboratively train forecasting models without sharing raw data (privacy-preserving federated learning), then employs blockchain-based voting where participants' voting power scales with historical prediction accuracy (reputation scores). Voting determines which model versions are deployed to production forecasting service. Reputation scores decay over time requiring sustained accuracy to maintain high voting power. Byzantine fault tolerance analysis proves system tolerates up to 33% malicious participants attempting to promote inaccurate models. Empirical evaluation on European weather station network (500 participating stations) shows reputation-based governance improves forecast accuracy by 18% vs naive averaging of all submitted models, while maintaining decentralization (no single institution controls >15% voting power).

**Pertinence**: RELEVANT for our AI services DAO use case, particularly reputation system design informing rank progression mechanics. Reputation-based voting power that scales with historical contribution quality (forecast accuracy) directly parallels our triangular voting where rank increases reflect sustained valuable participation. Time-decay mechanism addresses rank persistence problem: high-ranked members must continue active quality contributions to maintain voting power, preventing ossification where early participants dominate indefinitely. Byzantine fault tolerance (33% malicious tolerance) provides security benchmark for our governance system. ML model validation via voting demonstrates concrete application of expertise-weighted governance producing tangibly better outcomes (18% accuracy improvement) than naive equal weighting. Essential reference for Q2 2026 paper's case study section showing how rank-based triangular voting enables meritocratic AI model governance where domain experts' votes appropriately weight more heavily than casual participants.

**Tags**: reputation-based-voting, federated-learning, model-validation, trustworthiness, blockchain-ml

**Citation Key**: umar2025weather

---

### jo2025byzantine - Byzantine-Robust LLM Agent Coordination

**arXiv ID**: 2507.14928 | **Score**: 7/10 | **Status**: pending_review

Jo & Park (2025) propose decentralized consensus approach for coordinating multiple Large Language Model (LLM) agents where outputs are aggregated via Byzantine-robust voting rather than centralized orchestration. Worker agents independently generate responses to queries, while evaluator agents score outputs based on quality criteria (correctness, relevance, coherence). Aggregation mechanism employs Byzantine-robust averaging that excludes outlier scores from potentially malicious or malfunctioning agents. Security analysis proves system maintains 90% output quality even with 33% Byzantine (arbitrarily malicious) agents. Computational experiments on question-answering tasks show Byzantine-robust aggregation improves answer accuracy by 24% vs naive majority voting, while reducing variance in output quality. The framework supports heterogeneous agents (different LLM models, prompting strategies, knowledge bases) coordinating without shared state or trusted third party.

**Pertinence**: RELEVANT for Phase 7 multi-agent orchestration and hybrid IA/human governance scenarios. Byzantine-robust aggregation of agent outputs analogous to our challenge of aggregating heterogeneous expert opinions under triangular voting: high-ranked humans and AI agents both participate in governance decisions, requiring mechanisms to tolerate malicious or erroneous inputs without centralized authority. Evaluator agent pattern suggests architecture for our system where specialized AI agents assess proposal quality dimensions (technical feasibility, alignment with DAO values, economic impact) and human experts with high triangular voting weight make final binding decisions informed by agent analyses. 33% Byzantine fault tolerance provides security benchmark. 24% accuracy improvement via robust aggregation demonstrates value of sophisticated vote aggregation vs naive counting. Relevant for Q2 2026 paper's discussion of how triangular voting integrates with AI-augmented governance where both humans and agents contribute to decision-making processes.

**Tags**: byzantine-robust, llm-agents, decentralized-consensus, evaluator-agents, aggregation

**Citation Key**: jo2025byzantine

---

### borjigin2025trading - AI Agent Architecture for Decentralized Trading

**arXiv ID**: 2507.11117 | **Score**: 7/10 | **Status**: pending_review

Borjigin et al. (2025) describe AI agent architecture for decentralized exchange (DEX) of alternative assets (NFTs, tokenized real estate, intellectual property rights) governed via multi-signature agent updates and on-chain community voting for risk parameters. Architecture employs autonomous AI agents executing trading strategies based on market conditions, with governance layer enabling DAO members to vote on risk parameters (leverage limits, collateral ratios, liquidation thresholds, trading pair whitelisting). Multi-sig scheme requires M-of-N agent signatures to update critical system parameters, preventing single points of failure. Community voting mechanism uses token-weighted governance with time-locked proposals providing transparency and resistance to hostile takeovers. Experimental deployment on Polygon testnet demonstrates practical performance: 10K trades/day, 99.8% uptime, <$5/day governance costs. Economic analysis proves incentive alignment: agents profit from successful trading, community members profit from exchange fees, creating mutually beneficial ecosystem.

**Pertinence**: RELEVANT for our AI services DAO and governance of autonomous agent behaviors. Multi-sig agent update mechanism parallels our challenge of governing AI agents providing services within DAO framework: how do high-ranked human experts maintain oversight over autonomous agent actions without micromanaging every decision? On-chain voting for risk parameters demonstrates concrete application of triangular voting: experts with high ranks vote on critical thresholds (analogous to our DAO voting on service quality standards, pricing policies, agent authorization permissions), while agents operate autonomously within voted parameters. Time-locked proposals with transparency requirements align with our governance principles balancing efficiency (agents act quickly) with accountability (humans retain veto power). Relevant for Phase 7 implementation detailing human-AI governance interface. Useful reference in Q2 2026 paper's AI governance section showing how expertise-weighted voting (triangular) enables effective oversight of autonomous systems.

**Tags**: ai-agent-architecture, decentralized-trading, multi-sig, risk-parameters, community-voting

**Citation Key**: borjigin2025trading

---

### lin2025blindvote - Blind Vote Protocol for Privacy-Preserving Voting

**arXiv ID**: 2507.03258 | **Score**: 7/10 | **Status**: pending_review

Lin (2025) proposes Blind Vote protocol providing untraceable, secure, efficient, secrecy-preserving, and fully on-chain electronic voting with optimized gas consumption. Protocol employs blind signature cryptography enabling voters to cast ballots without revealing identities to tallying authority, while maintaining verifiability (anyone can audit tallies match ballots). On-chain implementation uses smart contracts for all voting phases (registration, casting, tallying, auditing) without off-chain components, enhancing transparency vs hybrid architectures requiring trusted external services. Gas optimization achieved through batch verification of cryptographic proofs: amortized cost ~50,000 gas per voter (~$5 at 2025 rates), 10x reduction vs naive per-voter verification. Security analysis proves vote untraceability under discrete logarithm hardness assumption, ballot secrecy against coercion attacks, and tally correctness absent 51% adversary controlling blockchain consensus. Experimental deployment on Ethereum testnet validates practical performance: 5,000 voters complete election in <1 hour.

**Pertinence**: RELEVANT for Phase 5 implementation complementing Kite private delegation protocol discussed earlier. Blind Vote's on-chain-only architecture (no off-chain trusted services) aligns with our decentralization goals where triangular voting system should not depend on centralized authorities. Gas optimization techniques (batch verification, 10x cost reduction) directly applicable to optimizing our Governor.sol contract where triangular vote weight calculations may incur higher gas costs than linear voting. Vote untraceability vs accountability tension fundamental to our design: while we want high-ranked members accountable for governance decisions (transparency), individual voters should retain privacy to prevent coercion/vote buying. Blind Vote demonstrates cryptographically how to achieve both: vote content secret, but eligibility and valid tallying publicly verifiable. Relevant for Q2 2026 paper's technical appendix detailing smart contract implementation achieving privacy and auditability simultaneously.

**Tags**: blind-vote, untraceable, secrecy-preserving, on-chain-voting, gas-optimization

**Citation Key**: lin2025blindvote

---

### lazar2025deployment - Deploying Voting DApps: Practical Experience

**arXiv ID**: 2504.10535 | **Score**: 7/10 | **Status**: pending_review

Lazăr, Secrieru & Onica (2025) evaluate deployment options for voting decentralized applications (DApps), analyzing metrics between Layer 1 blockchain providers (Ethereum mainnet, Polkadot parachains) and Layer 2 rollup solutions (Optimism, Arbitrum, zkSync) for high-security-demand governance applications. Comparative analysis examines 6 dimensions: transaction finality (time until votes irreversibly confirmed), gas costs (per-vote transaction fees), throughput (votes processed per second), security guarantees (resistance to chain reorganizations), censorship resistance, and developer ecosystem maturity. Results show L1 deployments provide strongest security guarantees (Ethereum 15-minute finality, Polkadot 12-second finality) but highest gas costs ($50-100 per vote). L2 rollups reduce costs by 100x ($0.50-1 per vote) but introduce latency (optimistic rollups) or computational overhead (zk-rollups). For high-stakes governance with <1000 participants, authors recommend L1 deployment; for large-scale participation (>10K voters), L2 rollups necessary despite security tradeoffs.

**Pertinence**: RELEVANT for Phase 5 Polkadot parachain deployment decision-making. Practical experience report from authors who deployed production voting DApps provides real-world insights beyond theoretical analysis. Polkadot parachain deployment (our planned architecture) receives favorable evaluation: 12-second finality significantly faster than Ethereum (15 minutes) while maintaining L1 security guarantees, making Polkadot suitable for agile governance requiring quick decision cycles. Gas cost analysis informs budget projections: assuming 1,000 DAO members with triangular voting (higher-ranked members vote more frequently), Polkadot's lower transaction costs vs Ethereum crucial for economic feasibility. Security vs scalability tradeoffs guidance directly applicable: our governance decisions (treasury fund allocation, smart contract upgrades) constitute "high-security-demand" scenarios justifying L1 deployment rather than L2 cost optimization. Essential reference for Phase 5 architecture decision rationale in technical documentation.

**Tags**: deployment-options, voting-dapps, providers-vs-rollups, security-metrics, practical-experience

**Citation Key**: lazar2025deployment

---

**Curation Progress**:
- Papers with score 9/10: 9 (hartnell2025verifiable, capponi2025dao, strnad2025delegation, meneguzzo2025evaluating, messias2023understanding, kiayias2022sok, gafni2025centralization, kovalchuk2025quadratic, nazirkhanova2025kite)
- Papers with score 8/10: 12 (okutan2025democracy, falk2024blockchain, liu2024economics, feichtinger2023hidden, liu2022bgra, liu2022pattern, liu2021defining, xia2025daoagent, homoliak2025blockchain, li2025collectively, briman2025optimism, kiashemshaki2025framework, wang2025timeweighted)
- Papers with score 7/10: 10 (chaffer2024decentralized, ballandies2024daos, motepalli2025gpos, aeeneh2025incentive, umar2025weather, jo2025byzantine, borjigin2025trading, lin2025blindvote, lazar2025deployment)

**Next Actions**:
1. ✅ Execute arXiv query 1B (completed - 24 papers found, 15 curated)
2. Execute arXiv query 1C (Voting theory - quadratic/conviction voting)
3. Create BibTeX entries for 15 papers in references.bib
4. Download PDFs for papers ≥8/10 (9 PDFs target)
5. Update main bibliography README with statistics
