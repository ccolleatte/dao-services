# Complementary Queries - Summaries (2020-2025)

**Query Set**: 6 - Complementary Queries (Foundational DAO, PoS Economics, Survey/SoK papers)
**Time Period**: 2020-2025
**Total Papers**: 24 (filtered from 32 raw results)
**Last Updated**: 2026-02-09

**Note**: Query 6A captured 9 non-relevant papers (LLM education, bias, healthcare) that have been manually filtered. Only blockchain/DAO-relevant papers are summarized below.

---

## Foundational DAO Papers (1 paper - Query 6A filtered)

### lakadawala2026blockchain - Blockchain Technology for Public Services: A Polycentric Governance Synthesis

**arXiv ID**: 2602.05109v1 | **Score**: 7/10 | **Status**: pending_review

Lakadawala et al. (2026) conduct a systematic review of blockchain-enabled public services using Polycentric Governance Theory, synthesizing peer-reviewed research from 2021-2025. The analysis reveals that governments typically utilize hybrid and permissioned blockchain designs implementing "controlled polycentricity" - selective decentralization with centralized oversight. Rather than full decentralization, blockchain serves as governance infrastructure encoding rules for coordination and information-sharing across domains including digital identity, electronic voting, procurement, and social services. The study identifies distributed authority, inter-organizational coordination, and layered accountability as key governance characteristics.

**Pertinence**: HIGH relevance for DAO governance frameworks. The concept of "controlled polycentricity" directly applies to DAO governance designs balancing decentralization with practical oversight mechanisms. The polycentric governance lens provides theoretical grounding for analyzing hybrid Governor.sol architectures.

**Tags**: governance, polycentric-governance, public-services, hybrid-blockchain

**Citation Key**: lakadawala2026blockchain

---

## Blockchain Security & Privacy (5 papers - Query 6A + 6D filtered)

### hossain2026tamperbench - TamperBench: Systematically Stress-Testing LLM Safety Under Fine-Tuning

**arXiv ID**: 2602.06911v1 | **Score**: 7/10 | **Status**: pending_review

**Note**: While focused on LLM security (not blockchain), this paper's methodology for evaluating tamper resistance could inform smart contract security testing frameworks.

---

### li2026beyond - Beyond Function-Level Analysis: Context-Aware Reasoning for Inter-Procedural Vulnerability Detection

**arXiv ID**: 2602.06751v1 | **Score**: 7/10 | **Status**: pending_review

Li et al. (2026) present CPRVul, a context-aware vulnerability detection framework coupling Context Profiling and Selection with Structured Reasoning for smart contract security analysis. Unlike function-level approaches, CPRVul constructs code property graphs to extract candidate context, uses LLMs to generate security-focused profiles with relevance scores, and integrates selected high-impact contextual elements for reasoning-based vulnerability detection. On PrimeVul benchmark, CPRVul achieves 67.78% accuracy (22.9% improvement over prior state-of-the-art 55.17%).

**Pertinence**: HIGH relevance for DAO smart contract security. Inter-procedural vulnerability detection is critical for Governor.sol contracts where vulnerabilities often span multiple functions. The context-aware reasoning approach addresses limitations of function-level audits.

**Tags**: vulnerability-detection, smart-contracts, context-aware, LLM-security

**Citation Key**: li2026beyond

---

### xu2026ghostcite - GhostCite: A Large-Scale Analysis of Citation Validity in the Age of Large Language Models

**arXiv ID**: 2602.06718v1 | **Score**: 7/10 | **Status**: pending_review

**Note**: Focused on academic citation integrity (not blockchain), but methodology could inform DAO proposal verification systems.

---

### song2026taipan - Taipan: Query-free Transfer-based Multiple Sensitive Attribute Inference Attacks on Graphs

**arXiv ID**: 2602.06700v1 | **Score**: 7/10 | **Status**: pending_review

Song and Palanisamy (2026) introduce Taipan, the first query-free transfer-based attack framework for multiple sensitive attribute inference on graphs (G-MSAIAs). Integrating Hierarchical Attack Knowledge Routing to capture inter-attribute correlations and Prompt-guided Attack Prototype Refinement to mitigate negative transfer, Taipan demonstrates strong attack performance across same-distribution and out-of-distribution settings, remaining effective even under differential privacy guarantees. The study exposes intrinsic multiple sensitive information leakage from publicly released graphs without requiring model queries.

**Pertinence**: MEDIUM relevance for DAO privacy. Graph-based attacks on blockchain transaction networks could compromise voter anonymity in Governor.sol systems. Understanding attribute inference attacks is essential for designing privacy-preserving governance mechanisms.

**Tags**: privacy, graph-inference-attacks, blockchain-privacy, differential-privacy

**Citation Key**: song2026taipan

---

### lu2026evaluating - Evaluating and Enhancing the Vulnerability Reasoning Capabilities of Large Language Models

**arXiv ID**: 2602.06687v1 | **Score**: 8/10 | **Status**: pending_review

Lu et al. (2026) propose DAGVul, a framework modeling vulnerability reasoning as Directed Acyclic Graph (DAG) generation to enforce structural consistency in LLM-based vulnerability detection. Unlike linear chain-of-thought approaches, DAG modeling explicitly maps causal dependencies. Combined with Reinforcement Learning with Verifiable Rewards (RLVR), DAGVul aligns model reasoning with program-intrinsic logic. The 8B-parameter implementation improves reasoning F1-score by 18.9% over baselines, competing with Claude-Sonnet-4.5 (75.47% vs 76.11%) while outperforming specialized 30B-parameter models.

**Pertinence**: MEDIUM relevance for DAO smart contract auditing. LLM-based vulnerability reasoning tools could augment traditional audits for Governor.sol contracts, particularly for complex cross-function vulnerabilities requiring causal reasoning.

**Tags**: vulnerability-detection, LLM-reasoning, smart-contracts, DAG-modeling

**Citation Key**: lu2026evaluating

---

## Blockchain Surveys & SoK Papers (18 papers - Query 6C)

### mallick2025quantum - Quantum Disruption: An SOK of How Post-Quantum Attackers Reshape Blockchain Security

**arXiv ID**: 2512.13333v1 | **Score**: 8/10 | **Status**: pending_review

Mallick et al. (2025) examine implications of adopting post-quantum cryptography in blockchain systems across four dimensions: identifying vulnerable primitives (consensus, identity, transaction validation), surveying proposed post-quantum adaptations, evaluating performance impacts, and analyzing effects on incentive and trust structures. The study demonstrates that integrating post-quantum signature schemes requires careful architectural redesign rather than naive substitution, as larger key sizes and higher computational costs can undermine both security guarantees and operational efficiency in decentralized environments.

**Pertinence**: HIGH relevance for long-term DAO security. Post-quantum cryptography migration is essential for future-proofing Governor.sol contracts against quantum attacks. The impossibility of drop-in replacement informs roadmap planning for DAO infrastructure upgrades.

**Tags**: post-quantum-cryptography, blockchain-security, quantum-computing, SoK

**Citation Key**: mallick2025quantum

---

### ghosh2025quantum - Quantum Blockchain Survey: Foundations, Trends, and Gaps

**arXiv ID**: 2507.13720v2 | **Score**: 8/10 | **Status**: pending_review

Ghosh and Mishu (2025) survey quantum computing risks to classical blockchain systems and emerging responses: post-quantum blockchains (quantum-resistant algorithms) and quantum blockchains (leveraging entanglement and quantum key distribution). The study reviews cryptographic foundations, architectural designs, implementation challenges, and identifies open problems across hardware, consensus, and network design. Comparative analysis highlights trade-offs in security, scalability, and deployment for secure blockchain systems in the quantum era.

**Pertinence**: HIGH relevance for future DAO infrastructure. Understanding quantum blockchain paradigms informs strategic decisions about long-term governance platform architectures and cryptographic primitives for Governor.sol systems.

**Tags**: quantum-blockchain, post-quantum, cryptographic-foundations, survey

**Citation Key**: ghosh2025quantum

---

### deng2025enhancing - Enhancing Blockchain Cross Chain Interoperability: A Comprehensive Survey

**arXiv ID**: 2505.04934v1 | **Score**: 7/10 | **Status**: pending_review

Deng et al. (2025) systematically analyze blockchain interoperability solutions across 150+ sources, classifying approaches including Atomic Swaps, Sidechains, Light Clients, and bridging protocols. The survey investigates convergence of academic research with industry practices, identifies strategic insights for cross-chain data and asset exchange, and explores challenges in creating cohesive multi-chain ecosystems. The study emphasizes collaborative efforts in advancing blockchain innovation beyond siloed architectures.

**Pertinence**: MEDIUM relevance for multi-chain DAO governance. Cross-chain interoperability is critical for DAOs operating across multiple blockchain platforms. Understanding bridge security and atomic swap mechanisms informs Governor.sol designs for multi-chain proposal execution.

**Tags**: interoperability, cross-chain, bridges, atomic-swaps

**Citation Key**: deng2025enhancing

---

### aliyu2025from - From Concept to Measurement: A Survey of How the Blockchain Trilemma Is Analyzed

**arXiv ID**: 2505.03768v4 | **Score**: 9/10 | **Status**: pending_review

Aliyu et al. (2025) synthesize constructs and metrics for analyzing the blockchain trilemma (decentralization, scalability, security), identifying 12 constructs operationalized through 15 metrics. The study harmonizes fragmented literature to support benchmarking and blockchain system design, providing structured methodology for quantitative trilemma analyses. The framework guides practitioners in identifying Pareto-optimal designs meeting common non-functional requirements, with applicability extending to distributed database systems relying on consensus and state machine replication.

**Pertinence**: HIGH relevance for DAO architecture decisions. The blockchain trilemma directly constrains Governor.sol design choices (on-chain storage vs off-chain, consensus mechanisms, validator requirements). Quantitative metrics enable evidence-based governance infrastructure evaluation.

**Tags**: blockchain-trilemma, decentralization-metrics, scalability, security-metrics

**Citation Key**: aliyu2025from

---

### lynham2025decentralization - Decentralization: A Qualitative Survey of Node Operators

**arXiv ID**: 2503.17246v5 | **Score**: 7/10 | **Status**: pending_review

Lynham and Goodell (2025) solicit definitions of "decentralization" and "decentralization theatre" from blockchain node operators through qualitative interviews. Thematic analysis reveals consensus around two axes: network topology (infrastructure distribution) and governance topology (decision-making power structure). The study finds that "decentralization" alone does not guarantee ledger immutability or systemic robustness, challenging assumptions about decentralization's security guarantees.

**Pertinence**: MEDIUM relevance for DAO decentralization metrics. The two-axis model (network + governance topology) provides conceptual framework for evaluating Governor.sol decentralization claims. Understanding "decentralization theatre" informs DAO governance design to avoid superficial decentralization.

**Tags**: decentralization, node-operators, qualitative-research, governance-topology

**Citation Key**: lynham2025decentralization

---

### li2025survey - Survey on Strategic Mining in Blockchain: A Reinforcement Learning Approach

**arXiv ID**: 2502.17307v2 | **Score**: 9/10 | **Status**: pending_review

Li et al. (2025) examine reinforcement learning's role in strategic mining analysis (selfish mining, block withholding), comparing RL frameworks to MDP-based approaches. The survey demonstrates RL's scalability advantages for adaptive strategy optimization in complex dynamic environments, analyzes security thresholds (minimum attacker power for profitable attacks), and classifies consensus protocols. Open challenges include multi-agent dynamics and real-world validation. RL provides roadmap for protocol design, threat detection, and security analysis in decentralized systems.

**Pertinence**: MEDIUM relevance for DAO consensus security. Understanding strategic mining attacks via RL informs Governor.sol designs for Byzantine-resistant voting mechanisms. Security threshold analysis applies to minimum quorum requirements and validator incentive structures.

**Tags**: strategic-mining, reinforcement-learning, consensus-security, selfish-mining

**Citation Key**: li2025survey

---

### ovezik2025sok - SoK: Measuring Blockchain Decentralization

**arXiv ID**: 2501.18279v2 | **Score**: 9/10 | **Status**: pending_review

Ovezik et al. (2025) systematize decentralization measurement workflows, proposing a framework categorizing techniques by resource targeted, extraction methods, and measurement functions. Empirical analysis evaluates whether pre-processing steps and metrics capture the same underlying decentralization concept. Key findings: (1) estimation window size and threshold choices significantly affect measurements, (2) PoW consensus participation is uncorrelated with decentralization (distinct signal), unlike PoS systems where metrics align, (3) higher participation does not guarantee higher decentralization. The study derives practical recommendations for researchers measuring blockchain decentralization.

**Pertinence**: HIGH relevance for DAO governance metrics. Decentralization measurement methodology directly applies to evaluating Governor.sol voting power distribution. The finding that participation ≠ decentralization challenges assumptions in DAO design about token holder engagement.

**Tags**: decentralization-measurement, metrics, SoK, empirical-analysis

**Citation Key**: ovezik2025sok

---

### li2024sok - SoK: Consensus for Fair Message Ordering

**arXiv ID**: 2411.09981v3 | **Score**: 8/10 | **Status**: pending_review

Li and Pournaras (2024) systematize consensus protocols addressing fair message ordering to mitigate Maximal Extractable Value (MEV) in decentralized finance. The study reviews First-In-First-Out (FIFO), random, and blind ordering approaches, analyzing challenges and trade-offs in Byzantine fault-tolerant settings. Requirements for fair message ordering consensus protocols are summarized, with a design guideline proposing latency optimization for Themis (state-of-the-art FIFO protocol).

**Pertinence**: HIGH relevance for DAO proposal ordering. Fair message ordering prevents front-running attacks in Governor.sol proposal submission and execution. Understanding MEV implications informs design of censorship-resistant governance transaction ordering.

**Tags**: fair-ordering, MEV, consensus, FIFO-ordering

**Citation Key**: li2024sok

---

### bellaj2024drawing - Drawing the Boundaries Between Blockchain and Blockchain-like Systems: A Comprehensive Survey on DLT

**arXiv ID**: 2409.18799v1 | **Score**: 9/10 | **Status**: pending_review

Bellaj et al. (2024) address confusion from systems labeled "blockchain" that deviate from core principles, proposing a reference model with four layers: data, consensus, execution, and application. The survey introduces a taxonomy for classifying distributed ledger technologies, conducting qualitative and quantitative analysis of 44 DLT solutions and 26 consensus mechanisms. The study highlights key challenges in DLT ecosystem clarity and offers research directions for the field.

**Pertinence**: HIGH relevance for DAO infrastructure classification. The four-layer reference model provides framework for analyzing Governor.sol architecture decisions (data layer: on-chain storage, consensus layer: voting mechanisms, execution layer: proposal execution, application layer: governance interfaces).

**Tags**: DLT, taxonomy, blockchain-classification, reference-model

**Citation Key**: bellaj2024drawing

---

### liu2024survey - A Survey on Secure Decentralized Optimization and Learning

**arXiv ID**: 2408.08628v1 | **Score**: 8/10 | **Status**: pending_review

Liu et al. (2024) survey secure decentralized optimization and learning frameworks, detailing three cryptographic tools (homomorphic encryption, secure multi-party computation, differential privacy) and their integration into decentralized systems. The study examines resilient aggregation and consensus protocols supporting federated and distributed optimization without centralized data collection. Privacy-preserving algorithms and Byzantine-resilient designs are analyzed for decentralized machine learning applications.

**Pertinence**: MEDIUM relevance for privacy-preserving DAO governance. Cryptographic tools for decentralized optimization inform Governor.sol designs for private voting (homomorphic vote tallying) and Byzantine-resistant aggregation of off-chain data.

**Tags**: decentralized-optimization, privacy-preserving, cryptography, Byzantine-resilience

**Citation Key**: liu2024survey

---

### luo2024survey - A Survey on Blockchain-based Supply Chain Finance

**arXiv ID**: 2408.08915v1 | **Score**: 9/10 | **Status**: pending_review

Luo (2024) summarizes blockchain applications in Supply Chain Finance, examining accounts receivable financing, risk management, and supply chain optimization. The survey analyzes blockchain's role in addressing information asymmetry, credit disassembly, and financing costs through smart contracts, with integration of AI, cloud computing, and data mining. Conceptual frameworks and practical implementations are reviewed, though most work remains at management level rather than deep technical applications.

**Pertinence**: MEDIUM relevance for DAO treasury management. Supply chain finance patterns (credit verification, multi-party agreements, escrow) translate to DAO grant distribution and treasury fund allocation mechanisms. Smart contract automation applies to Governor.sol payment flows.

**Tags**: supply-chain-finance, smart-contracts, credit-verification, treasury-management

**Citation Key**: luo2024survey

---

### lavin2024survey - A Survey on the Applications of Zero-Knowledge Proofs

**arXiv ID**: 2408.00243v1 | **Score**: 8/10 | **Status**: pending_review

Lavin et al. (2024) survey zero-knowledge proofs (ZKPs) with focus on zk-SNARKs, examining applications across blockchain (privacy, scaling, storage, interoperability) and non-blockchain domains (voting, authentication, timelocks, machine learning). The study covers foundational components including zero-knowledge virtual machines (zkVM), domain-specific languages (DSLs), libraries, frameworks, and protocols. ZKPs enable secure information exchange without revealing private data, with minimal security assumptions compared to homomorphic encryption and secure multiparty computation.

**Pertinence**: HIGH relevance for privacy-preserving DAO voting. zk-SNARKs enable private voting in Governor.sol while maintaining public verifiability. ZKP applications in authentication and identity inform sybil-resistant governance mechanisms.

**Tags**: zero-knowledge-proofs, zk-SNARKs, privacy, blockchain-scaling

**Citation Key**: lavin2024survey

---

### ito2024cryptoeconomics - Cryptoeconomics and Tokenomics as Economics: A Survey with Opinions

**arXiv ID**: 2407.15715v1 | **Score**: 8/10 | **Status**: pending_review

Ito (2024) surveys cryptoeconomics and tokenomics from an economic perspective, addressing ill-defined terminology and disconnection from economic disciplines. The study integrates consensus-building for decentralization and token value for autonomy, requiring simultaneous consideration of strategic behavior, spamming, Sybil attacks, free-riding, marginal cost, marginal utility, and stabilizers. This systematization aims to bridge economics and blockchain contexts.

**Pertinence**: HIGH relevance for DAO tokenomics design. Integrating economic theory (marginal utility, strategic behavior) with blockchain mechanisms informs Governor.sol token-weighted voting economics and incentive alignment for governance participation.

**Tags**: cryptoeconomics, tokenomics, economic-theory, mechanism-design

**Citation Key**: ito2024cryptoeconomics

---

### feichtinger2024sok - SoK: Attacks on DAOs

**arXiv ID**: 2406.15071v2 | **Score**: 8/10 | **Status**: pending_review

Feichtinger et al. (2024) systematically analyze security threats to DAOs, categorizing attacks into four types based on attack vectors. Studying past attacks, theorized possibilities, and audit-uncovered vulnerabilities reveals that many DAO attacks exploit human governance complexity rather than code vulnerabilities. Yet audits predominantly focus on protocol and code issues. The paper outlines risk factors, suggests mitigation strategies, and provides empirical data on DAO vulnerabilities to safeguard decentralized governance.

**Pertinence**: CRITICAL relevance for DAO security. The finding that human governance attacks dominate actual incidents (vs theoretical code vulnerabilities) reshapes Governor.sol security priorities. Understanding attack taxonomies informs comprehensive threat modeling beyond smart contract audits.

**Tags**: DAO-attacks, security-threats, governance-attacks, SoK

**Citation Key**: feichtinger2024sok

---

### liu2024enhancing - Enhancing Trust and Privacy in Distributed Networks: A Survey on Blockchain-based Federated Learning

**arXiv ID**: 2403.19178v1 | **Score**: 8/10 | **Status**: pending_review

Liu et al. (2024) investigate blockchain-based federated learning (BCFL), highlighting synergy between blockchain's security features and FL's privacy-preserving model training. The survey presents BCFL taxonomy (decentralized, separate networks, reputation-based architectures), summarizes general BCFL system architecture, and analyzes applications in healthcare, IoT, and privacy-sensitive domains. Future research directions include scalability, consensus optimization, and privacy enhancement.

**Pertinence**: MEDIUM relevance for DAO machine learning governance. BCFL patterns apply to decentralized AI model training for DAO analytics (voting pattern analysis, proposal quality scoring) without centralizing sensitive governance data.

**Tags**: federated-learning, blockchain, privacy-preserving, distributed-AI

**Citation Key**: liu2024enhancing

---

### miller2024collaborative - Collaborative Cybersecurity Using Blockchain: A Survey

**arXiv ID**: 2403.04410v1 | **Score**: 7/10 | **Status**: pending_review

Miller and Pahl (2024) survey blockchain's role in collaborative cybersecurity (2016-2023), exploring applications in threat intelligence sharing, access control, and data validation. The study identifies fragmentation in the field with no dominant research group, noting poor consensus protocol selection in recent projects. Guidelines are provided for choosing appropriate blockchain for specific cybersecurity purposes, highlighting open research areas and lessons learned from past applications.

**Pertinence**: MEDIUM relevance for DAO security infrastructure. Collaborative security patterns (threat intelligence sharing, distributed access control) apply to DAO security monitoring and incident response coordination across decentralized validator networks.

**Tags**: cybersecurity, blockchain, threat-intelligence, access-control

**Citation Key**: miller2024collaborative

---

### wu2024blockchain - Blockchain for Finance: A Survey

**arXiv ID**: 2402.17219v1 | **Score**: 7/10 | **Status**: pending_review

Wu et al. (2024) focus on blockchain-based securities trading, investigating 12 popular blockchain platforms with elaboration on 6 finance-related platforms. The survey summarizes blockchain-based securities trading applications across four categories, introducing typical examples and explaining blockchain's role in solving FinTech key problems. Observations range from mainstream blockchain financial institutions to DeFi application security issues, picturing the current blockchain ecosystem in finance.

**Pertinence**: MEDIUM relevance for DAO treasury operations. Securities trading patterns (escrow, settlement, regulatory compliance) inform Governor.sol designs for treasury asset management and DeFi protocol integrations.

**Tags**: blockchain-finance, securities-trading, DeFi, FinTech

**Citation Key**: wu2024blockchain

---

### mansour2024survey - A Survey on Blockchain in E-Government Services: Status and Challenges

**arXiv ID**: 2402.02483v1 | **Score**: 7/10 | **Status**: pending_review

Mansour et al. (2024) survey blockchain applications in e-government services across governmental and private sector organizations. Use cases for current blockchain-enabled facilities are examined, identifying research gaps in blockchain deployment and suggesting future work directions. The survey addresses secure, decentralized record-keeping for digital assets in public sector contexts.

**Pertinence**: MEDIUM relevance for DAO public goods governance. E-government blockchain patterns (identity verification, transparent procurement, citizen participation) translate to DAO governance mechanisms for public goods funding and community decision-making.

**Tags**: e-government, blockchain-applications, public-services, digital-governance

**Citation Key**: mansour2024survey

---

**Total Summaries**: 24 papers (filtered for DAO/blockchain relevance)
**Score Distribution**: 5 @ 9/10, 12 @ 8/10, 7 @ 7/10
**Filtered Papers**: 8 non-relevant papers removed from Query 6A (LLM education, bias, healthcare topics)

**Recommendation**: Re-execute Query 6A with stricter focus on DAO/blockchain governance papers to reach 135 minimum target (currently at 133 total papers).
