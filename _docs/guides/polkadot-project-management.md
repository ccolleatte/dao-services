# Polkadot Project Management Guide

**Date** : 2026-02-10
**Projet** : DAO Services IA/Humains
**Version** : 1.0.0

---

## Vue d'ensemble

Ce guide couvre la gestion de projet dans l'écosystème Polkadot, du développement à la gouvernance décentralisée.

---

## 1. Development Lifecycle Polkadot

### Timeline

```
Research     POC      Testnet    Audit     Mainnet    Parachain
  (1-2mo)  (1-3mo)   (2-4mo)   (1-2mo)    (1mo)      (12-18mo)
    ↓         ↓         ↓         ↓          ↓           ↓
  Ideas   Prototype  Paseo    Security  Production  Crowdloan
          Solidity   Deploy    Trail of    Deploy    + Auction
          + ink!              Bits/Oak
```

### Phase Breakdown

**Phase 0 : Research (1-2 mois)**
- Whitepaper draft
- Technical specifications
- Tokenomics design
- Community feedback (Polkadot Forum)

**Phase 1 : POC (1-3 mois)**
- Solidity MVP (EVM-compatible)
- ink! contracts (optional)
- Local testing (Foundry, Chopsticks)
- First user demos

**Phase 2 : Testnet (2-4 mois)**
- Deploy to Paseo
- Stress testing (1000+ transactions)
- Gas optimization (<50k gas per operation)
- Community testing program (rewards)

**Phase 3 : Audit (1-2 mois)**
- Security audit (Trail of Bits, Oak Security)
- Fix findings
- Re-audit critical issues
- Public disclosure

**Phase 4 : Mainnet (1 mois)**
- Deploy to Polkadot Hub (Solidity) or mainnet (Substrate)
- Initial liquidity (treasury allocation)
- Monitoring infrastructure
- Incident response plan

**Phase 5 : Parachain (12-18 mois post-MVP)**
- Crowdloan campaign (2M DOT target)
- Auction bidding
- Parachain onboarding
- XCM integration

---

## 2. Treasury Proposal Process (OpenGov)

### OpenGov Tracks

| Track | Spending Limit | Decision Period | Use Case DAO |
|-------|----------------|-----------------|--------------|
| **Small Spender** | <10k USD | 7 days | Bug bounties, minor features |
| **Medium Spender** | 10k-100k USD | 14 days | Security audits, Phase 2-3 development |
| **Big Spender** | >100k USD | 28 days | Parachain crowdloan, major features |
| **Treasurer** | <100k USD (fast) | 7 days | Emergency funding |

**Approval Criteria** :

```
Approval = Support × Conviction
Support = Total votes / Total possible votes
Conviction = Lock multiplier (0.1x to 6x)
```

**Curves** (Approval vs Support) :

```
Technical Track:
  Approval >= 50% (minimum)
  Support >= 10% (minimum)

Treasury Track:
  Approval >= 60% (minimum)
  Support >= 20% (minimum)
```

### Proposal Format

**Template** :

```markdown
# DAO Services - Phase 3 Security Audit

## Problem
DAO marketplace contracts (Solidity) require professional security audit before mainnet deployment.

## Solution
Engage Trail of Bits for 4-week audit covering:
- DAOGovernance.sol (OpenGov implementation)
- DAOMembership.sol (Role-based access)
- DAOTreasury.sol (Milestone payments)
- DAOMarketplace.sol (Mission lifecycle)

## Budget
- Audit cost: 50,000 USD (~7,140 DOT at $7/DOT)
- Breakdown:
  - Week 1-2: Initial review (25k USD)
  - Week 3: Penetration testing (15k USD)
  - Week 4: Report + fixes verification (10k USD)

## Milestones
1. **Milestone 1 (Week 2)** : Initial findings report → 25k USD
2. **Milestone 2 (Week 4)** : Final report + re-audit → 25k USD

## Team
- DAO Core Team (contract authors)
- Trail of Bits (auditor)
- OpenZeppelin Defender (monitoring)

## Expected Outcomes
- 0 CRITICAL vulnerabilities
- <3 HIGH severity findings
- Public audit report
- Mainnet deployment approval

## Timeline
- Proposal submission: 2026-03-01
- Voting period: 14 days (Treasury track)
- Audit start: 2026-03-20
- Audit completion: 2026-04-20
- Mainnet deployment: 2026-05-01
```

### Voting Mechanics

**Conviction Voting** :

| Lock Duration | Multiplier | Example |
|---------------|------------|---------|
| No lock | 0.1× | 100 DOT = 10 votes |
| 1 week | 1× | 100 DOT = 100 votes |
| 2 weeks | 2× | 100 DOT = 200 votes |
| 4 weeks | 3× | 100 DOT = 300 votes |
| 8 weeks | 4× | 100 DOT = 400 votes |
| 16 weeks | 5× | 100 DOT = 500 votes |
| 32 weeks | 6× | 100 DOT = 600 votes |

**Optimal Strategy** :
- High conviction (6×) for critical proposals (security audits, mainnet deployment)
- Low conviction (1×) for non-critical (minor features, experiments)

### Passing Criteria

**Technical Track** (DAO governance parameters) :

```
Support curve : Linear decreasing (100% → 10%)
Approval curve : Linear decreasing (100% → 50%)

Example:
  Day 1 : Support >= 50%, Approval >= 100% (impossible to pass early)
  Day 7 : Support >= 10%, Approval >= 50% (realistic threshold)
```

**Treasury Track** (funding proposals) :

```
Support curve : Linear decreasing (100% → 20%)
Approval curve : Linear decreasing (100% → 60%)

Example:
  Day 1 : Support >= 60%, Approval >= 100%
  Day 14 : Support >= 20%, Approval >= 60% (pass)
```

**Voting Power** :

```
Total votes = Sum(voter_balance × conviction_multiplier)

Example proposal:
  - Alice: 1000 DOT × 6× = 6000 votes (AYE)
  - Bob: 500 DOT × 2× = 1000 votes (NAY)
  - Charlie: 2000 DOT × 1× = 2000 votes (AYE)

  Total AYE: 8000 votes
  Total NAY: 1000 votes
  Approval: 8000 / 9000 = 88.9% ✅
```

---

## 3. Security Audit Requirements

### Recommended Auditors

| Auditor | Specialization | Avg Cost | Timeline | Recommendation |
|---------|----------------|----------|----------|----------------|
| **Trail of Bits** | Smart contracts, Runtime | $50-80k | 4-6 weeks | ✅ Recommandé (best reputation) |
| **Oak Security** | Polkadot-native, XCM | $30-60k | 3-5 weeks | ✅ Recommandé (Polkadot expert) |
| **Zellic** | Smart contracts, ZK | $40-70k | 4-6 weeks | ✅ Good alternative |
| **OpenZeppelin** | Solidity, governance | $30-50k | 3-4 weeks | ✅ For Solidity MVP |

**Recommendation DAO** :
- **Phase 3 MVP** : OpenZeppelin (Solidity focus, $30-50k)
- **Phase 5 Substrate** : Oak Security (Polkadot native, $30-60k)

### Audit Scope

**Solidity Contracts** (Phase 3) :

```
Contracts:
  - DAOGovernance.sol (350 lines)
  - DAOMembership.sol (200 lines)
  - DAOTreasury.sol (250 lines)
  - DAOMarketplace.sol (400 lines)

  Total: ~1200 lines

Focus areas:
  - Access control (roles, permissions)
  - Reentrancy guards
  - Integer overflow/underflow
  - Emergency pause mechanisms
  - OpenGov implementation (quorum, voting)
```

**Substrate Runtime** (Phase 5) :

```
Pallets:
  - pallet-marketplace (~800 lines)
  - pallet-governance (built-in, focus on config)
  - pallet-treasury (built-in, focus on integration)

Focus areas:
  - Weight calculations (DoS prevention)
  - Origin checks (authorization)
  - Storage bounds (prevent bloat)
  - XCM integration (cross-chain security)
```

### Audit Timeline

**Week 1-2 : Initial Review**
- Static analysis (Slither, Mythril)
- Manual code review
- Architecture assessment
- Preliminary findings report

**Week 3 : Penetration Testing**
- Exploit development
- Fuzzing (Echidna, Foundry invariants)
- Gas optimization review
- Integration testing

**Week 4 : Final Report**
- Comprehensive findings report
- Severity classification (CRITICAL/HIGH/MEDIUM/LOW)
- Remediation recommendations
- Re-audit of fixes

### Deliverables

1. **Initial Findings Report** (Week 2)
   - CRITICAL and HIGH severity issues
   - Quick wins (low-effort fixes)

2. **Final Audit Report** (Week 4)
   - All findings (CRITICAL → LOW)
   - Executive summary
   - Detailed explanations
   - Proof-of-concept exploits
   - Remediation verification

3. **Public Disclosure** (Post-fixes)
   - Redacted public report
   - Blog post summary
   - Community AMA

### Cost Breakdown

**OpenZeppelin Audit** (Solidity MVP) :

| Item | Cost | Duration |
|------|------|----------|
| Initial review | $15k | 1-2 weeks |
| Penetration testing | $10k | 1 week |
| Final report + re-audit | $10k | 1 week |
| **Total** | **$35k** | **4 weeks** |

**Oak Security Audit** (Substrate Runtime) :

| Item | Cost | Duration |
|------|------|----------|
| Runtime review | $25k | 2-3 weeks |
| XCM integration review | $15k | 1-2 weeks |
| Weight benchmarking | $10k | 1 week |
| Final report | $10k | 1 week |
| **Total** | **$60k** | **5-7 weeks** |

---

## 4. Community Engagement

### Polkadot Forum

**URL** : https://forum.polkadot.network/

**Best Practices** :

1. **Pre-Proposal Discussion**
   - Post idea in "General" category
   - Gather feedback (2-4 weeks)
   - Iterate on design

2. **Formal Proposal**
   - Post in "Treasury" category
   - Use template (Problem/Solution/Budget/Milestones)
   - Link to technical specs (GitHub, Google Docs)

3. **Voting Period**
   - Respond to questions (daily monitoring)
   - Address concerns (technical, budget, timeline)
   - Provide updates (weekly summaries)

### Subsquare

**URL** : https://polkadot.subsquare.io/

**Features** :
- On-chain proposal tracking
- Voting stats (AYE/NAY breakdown)
- Timeline visualization
- Conviction analysis

**Usage** :
- Monitor proposal status
- Analyze voting patterns
- Identify whale voters (>10k DOT)
- Engage via comments

### Element (Matrix)

**Channels** :
- `#polkadot:matrix.org` : General discussion
- `#substrate-technical:matrix.org` : Development help
- `#polkadot-watercooler:matrix.org` : Community chat

**Best Practices** :
- Ask technical questions (real-time responses)
- Share updates (major milestones)
- Collaborate with other teams

### Twitter/X

**Strategy** :
- Announce milestones (#Polkadot, #DAO)
- Share educational threads (governance, XCM)
- Engage with ecosystem projects (@Polkadot, @ParityTech)

### Polkassembly

**URL** : https://polkadot.polkassembly.io/

**Features** :
- Proposal comments
- Voting delegation
- Timeline tracking

---

## 5. Risk Management

### Technical Risks

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| **Smart contract vulnerability** | Medium | CRITICAL | Security audit, bug bounty |
| **Gas costs too high** | Low | HIGH | Optimize before mainnet |
| **XCM integration failure** | Medium | MEDIUM | Test on Chopsticks, Paseo |
| **Runtime upgrade bug** | Low | CRITICAL | Comprehensive testing, staging |

### Economic Risks

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| **DOT price crash** | Medium | HIGH | Treasury diversification (stablecoins) |
| **Insufficient liquidity** | High | MEDIUM | Bootstrap liquidity pools |
| **Parachain auction failure** | Medium | MEDIUM | Backup: Stay on Agile Coretime |

### Governance Risks

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| **Proposal rejection** | Medium | MEDIUM | Pre-proposal community feedback |
| **Governance attack** | Low | CRITICAL | Conviction voting (time-locked) |
| **Low participation** | High | MEDIUM | Incentivize voting (rewards) |

---

## 6. Budget Planning

### Phase 3 MVP (Solidity)

| Item | Cost | Source |
|------|------|--------|
| Development (3 months) | $60k | Treasury proposal |
| Security audit (OpenZeppelin) | $35k | Treasury proposal |
| Testnet deployment | Free | Paseo faucet |
| Monitoring (3 months) | $3k | Treasury proposal |
| **Total Phase 3** | **$98k** | **Treasury** |

### Phase 4 Mainnet

| Item | Cost | Source |
|------|------|--------|
| Mainnet deployment gas | 10 DOT | Treasury |
| Initial liquidity | 1000 DOT | Treasury |
| Monitoring (12 months) | $12k | Treasury |
| Bug bounty program | $50k | Treasury |
| **Total Phase 4** | **~$70k + 1010 DOT** | **Treasury** |

### Phase 5 Parachain (Optional)

| Item | Cost | Source |
|------|------|--------|
| Substrate development (6 months) | $180k | Treasury |
| Security audit (Oak Security) | $60k | Treasury |
| Crowdloan incentives (20% tokens) | N/A | Token inflation |
| Collator infrastructure (12 months) | $6k | Treasury |
| **Total Phase 5** | **~$246k + 2M DOT (crowdloan)** | **Treasury + Crowdloan** |

**Total Project Budget** : ~$414k + 1010 DOT (Phases 3-4 only)

**With Parachain** : ~$660k + 2M DOT crowdloan (Phases 3-5)

---

## 7. Timeline Planning

### Realistic Milestones

```
2026 Q1:
  - Phase 3 completion (30% restant)
  - Paseo deployment
  - Security audit start

2026 Q2:
  - Security audit completion
  - Mainnet deployment
  - Initial users (100+)

2026 Q3:
  - Substrate POC (if ROI positive)
  - XCM integration testing
  - User growth (1000+)

2026 Q4:
  - Substrate production (if migrated)
  - Treasury diversification (USDT)
  - Parachain evaluation

2027 Q1:
  - Crowdloan preparation (if parachain path)
  - Community governance transfer
  - Ecosystem integrations
```

### Critical Path

```
Phase 3 MVP (CRITICAL)
      ↓
Security Audit (BLOCKER)
      ↓
Mainnet Deployment (CRITICAL)
      ↓
User Acquisition (HIGH)
      ↓
[Decision Gate: ink! vs Substrate vs Stay Solidity]
      ↓
Phase 5 (OPTIONAL - if >100 missions/day)
```

---

## Références

**Official Documentation** :
- [Polkadot Treasury Guide](https://wiki.polkadot.network/docs/learn-treasury)
- [OpenGov Track Parameters](https://wiki.polkadot.network/docs/learn-polkadot-opengov-origins)
- [Conviction Voting](https://wiki.polkadot.network/docs/learn-guides-polkadot-opengov)

**Community Resources** :
- [Polkadot Forum](https://forum.polkadot.network/)
- [Subsquare](https://polkadot.subsquare.io/)
- [Polkassembly](https://polkadot.polkassembly.io/)

**Auditors** :
- [Trail of Bits](https://www.trailofbits.com/)
- [Oak Security](https://www.oaksecurity.io/)
- [OpenZeppelin Defender](https://defender.openzeppelin.com/)

---

**Version** : 1.0.0
**Dernière mise à jour** : 2026-02-10
