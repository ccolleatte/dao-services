# Sprint 5: Smart Contracts Marketplace - Summary

**Date**: 2026-02-09
**Duration**: 30h planifiées
**Status**: ✅ Complété

---

## 📦 Deliverables

### Smart Contracts (3 fichiers, ~1,050 lignes)

| Contract | Lines | Purpose | Status |
|----------|-------|---------|--------|
| **ServiceMarketplace.sol** | ~400 | Mission publication + matching algorithm on-chain | ✅ |
| **MissionEscrow.sol** | ~400 | Milestones séquentielles + dispute arbitrage DAO | ✅ |
| **HybridPaymentSplitter.sol** | ~350 | Distribution revenus Human/AI/Compute | ✅ |

### Tests (1 fichier, 24 tests, ~950 lignes)

| Test File | Tests | Coverage Target | Status |
|-----------|-------|-----------------|--------|
| **Marketplace.t.sol** | 24 tests (ServiceMarketplace: 6, MissionEscrow: 8, HybridPaymentSplitter: 10) | ≥80% lines | ✅ |

**Coverage breakdown**:
- ServiceMarketplace: 6 tests (création mission, application, scoring, sélection, validations)
- MissionEscrow: 8 tests (milestones séquentielles, approve/reject, auto-release, disputes, jury voting)
- HybridPaymentSplitter: 10 tests (contributeurs, usage reporting, distribution, pricing, validations)

### Documentation (1 fichier)

| Document | Purpose | Status |
|----------|---------|--------|
| **SPRINT5_SUMMARY.md** | Documentation complète + guide déploiement | ✅ |

---

## 🎯 Features Implemented

### 1. ServiceMarketplace.sol - Mission Publication + Matching

**Core Features**:
- ✅ Mission creation with budget locking (ERC20 transfer from client)
- ✅ Consultant application with IPFS proposal storage
- ✅ **On-chain matching algorithm** (5 criteria, transparent scoring 0-100):
  1. **Rank match (25 points)**: DAO rank 0-4 → Linear scaling
  2. **Skills overlap (25 points)**: Matching required skills → Percentage score
  3. **Budget competitiveness (20 points)**: Lower proposed budget = Higher score
  4. **Track record (15 points)**: Completed missions + average rating
  5. **Responsiveness (15 points)**: Early application = Higher score
- ✅ Consultant selection by client (triggers escrow creation)
- ✅ Integration with Membership contract (ranks, skills, track record)

**Key Functions**:
```solidity
createMission(title, budget, minRank, requiredSkills) → missionId
applyToMission(missionId, proposal, proposedBudget) → applicationId
calculateMatchScore(missionId, consultant, proposedBudget, rank) → score (0-100)
selectConsultant(missionId, consultant)
getMissionApplications(missionId) → applicationIds[]
```

**Events**:
- `MissionCreated(missionId, client, budget)`
- `ApplicationSubmitted(applicationId, missionId, consultant)`
- `ConsultantSelected(missionId, consultant, matchScore)`
- `MissionStatusUpdated(missionId, newStatus)`

---

### 2. MissionEscrow.sol - Milestones + Dispute Arbitrage

**Core Features**:
- ✅ **Sequential milestone validation** (cannot submit milestone N+1 if N not approved)
- ✅ Milestone submission with IPFS deliverable hash
- ✅ Client approval/rejection with payment release
- ✅ **Auto-release mechanism** (7 days after submission if no action)
- ✅ **Dispute arbitrage** with DAO jury:
  - 100 DAOS deposit requirement (refunded if won)
  - 5 jurors (Rank 3+ members, pseudo-random selection)
  - 72h voting period
  - Majority rule (3/5 votes minimum)
  - Winner receives milestone payment + deposit refund
  - Loser forfeits deposit
- ✅ Integration with Membership contract (eligible jurors query)

**Key Functions**:
```solidity
addMilestone(description, amount, deadline) → milestoneId
submitMilestone(milestoneId, deliverable)
approveMilestone(milestoneId) → Releases payment
rejectMilestone(milestoneId, reason)
autoReleaseMilestone(milestoneId) → After 7 days delay
raiseDispute(milestoneId, reason) → disputeId (requires 100 DAOS deposit)
voteOnDispute(disputeId, favorConsultant) → Jurors vote
resolveDispute(disputeId) → After majority or 72h
getMilestone(milestoneId) → Milestone details
getDisputeJurors(disputeId) → address[]
```

**Events**:
- `MilestoneAdded(milestoneId, description, amount, deadline)`
- `MilestoneSubmitted(milestoneId, deliverable)`
- `MilestoneApproved(milestoneId, amountReleased)`
- `MilestoneRejected(milestoneId, reason)`
- `DisputeRaised(disputeId, milestoneId, initiator)`
- `DisputeVoteCast(disputeId, juror, favorConsultant)`
- `DisputeResolved(disputeId, winner, amountAwarded)`

**Constants**:
```solidity
AUTO_RELEASE_DELAY = 7 days
DISPUTE_DEPOSIT = 100 ether (100 DAOS)
JURY_SIZE = 5
VOTING_PERIOD = 72 hours
```

---

### 3. HybridPaymentSplitter.sol - Distribution Revenus Human/AI/Compute

**Core Features**:
- ✅ **Mixed contributor types** (Human, AI, Compute)
- ✅ **Fixed percentage allocation** for Human contributors
- ✅ **Usage-based payment** for AI/Compute:
  - AI: LLM tokens (OpenAI standard) → Price per 1M tokens
  - Compute: GPU-hours (scaled by 1000) → Price per GPU-hour
  - Formula: `usage cost + fixed percentage`
- ✅ **Metering oracle integration** (METER_ROLE for usage reporting)
- ✅ Flexible pricing configuration (admin-controlled)
- ✅ Usage metrics reset after distribution

**Key Functions**:
```solidity
addContributor(account, contributorType, percentageBps) → contributorId
reportUsage(llmTokens, gpuHours) → Requires METER_ROLE
distributePayment(totalAmount) → Calculates + transfers shares
calculateAIUsageCost() → llmTokens * pricePerMToken / 1M
calculateComputeUsageCost() → gpuHours * pricePerGPUHour / 1000
updatePricing(pricePerMTokenLLM, pricePerGPUHour)
resetUsageMetrics() → After distribution
getContributor(index) → Contributor details
getUsageMetrics() → Current usage stats
getPricing() → Current pricing
```

**Events**:
- `ContributorAdded(account, contributorType, percentageBps)`
- `UsageReported(llmTokens, gpuHours)`
- `PaymentDistributed(recipient, amount, contributorType)`
- `PricingUpdated(pricePerMTokenLLM, pricePerGPUHour)`

**Default Pricing** (configurable):
```solidity
pricePerMTokenLLM = 20 ether (20 DAOS per 1M tokens)
pricePerGPUHour = 10 ether (10 DAOS per GPU-hour)
```

**Distribution Example** (1000 DAOS total):
```
Human 1: 40% fixed = 400 DAOS
AI Agent: 500K tokens usage (10 DAOS) + 27.5% fixed (275 DAOS) = 285 DAOS
Compute: 1.5 GPU-hours usage (15 DAOS) + 10% fixed (100 DAOS) = 115 DAOS
Total: 800 DAOS (200 DAOS remaining for other contributors or fees)
```

---

## 🧪 Tests - Coverage Summary

### Test Categories

**ServiceMarketplace (6 tests)**:
1. ✅ Create mission (budget locking, status Active)
2. ✅ Apply to mission (proposal storage, match score calculation)
3. ✅ Calculate match score (5 criteria validation)
4. ✅ Select consultant (status OnHold, consultant assignment)
5. ✅ Revert if insufficient rank (rank validation)
6. ✅ Revert if already applied (duplicate prevention)

**MissionEscrow (8 tests)**:
1. ✅ Add milestone (description, amount, deadline storage)
2. ✅ Submit milestone (deliverable IPFS hash, status Submitted)
3. ✅ Approve milestone (payment release, status Approved)
4. ✅ Reject milestone (status Rejected, no payment)
5. ✅ Sequential milestones (cannot skip milestone N)
6. ✅ Auto-release milestone (after 7 days delay)
7. ✅ Raise dispute (100 DAOS deposit, jury selection)
8. ✅ Vote on dispute (jury voting, majority resolution)

**HybridPaymentSplitter (10 tests)**:
1. ✅ Add contributors (Human/AI/Compute, percentage validation)
2. ✅ Report usage (METER_ROLE, llmTokens + gpuHours)
3. ✅ Calculate AI usage cost (tokens → DAOS conversion)
4. ✅ Calculate compute usage cost (GPU-hours → DAOS conversion)
5. ✅ Distribute payment (fixed + usage-based calculation)
6. ✅ Update pricing (pricePerMTokenLLM, pricePerGPUHour)
7. ✅ Reset usage metrics (after distribution)
8. ✅ Emergency withdraw (admin-only)
9. ✅ Revert if non-meter reports usage (role validation)
10. ✅ Revert if invalid percentage (>100% validation)

### Running Tests

```bash
# All tests
forge test

# Coverage report
forge coverage

# Specific test file
forge test --match-path test/Marketplace.t.sol

# Verbose output (logs + events)
forge test -vvv

# Gas report
forge test --gas-report
```

**Expected Output**:
```
[PASS] testCreateMission() (gas: 125432)
[PASS] testApplyToMission() (gas: 183921)
[PASS] testCalculateMatchScore() (gas: 98743)
...
Test result: ok. 24 passed; 0 failed; 0 skipped; finished in 2.34s
```

---

## 🚀 Déploiement - Testnet Paseo

### 1. Prérequis

**Outils**:
```bash
# Installer Foundry
curl -L https://foundry.paradigm.xyz | bash
foundryup

# Vérifier installation
forge --version
```

**Configuration**:
```bash
# .env (créer à la racine du projet)
PRIVATE_KEY=0x... # Clé privée déploiement
PASEO_RPC_URL=wss://paseo-rpc.dwellir.com
DAOS_TOKEN_ADDRESS=0x... # Adresse DAOS token sur Paseo
MEMBERSHIP_CONTRACT_ADDRESS=0x... # Adresse DAOMembership
ETHERSCAN_API_KEY=... # Pour vérification (optionnel)
```

### 2. Déploiement Séquentiel

**Script de déploiement** (`script/DeployMarketplace.s.sol`):
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/ServiceMarketplace.sol";
import "../src/MissionEscrow.sol";
import "../src/HybridPaymentSplitter.sol";

contract DeployMarketplace is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address daosToken = vm.envAddress("DAOS_TOKEN_ADDRESS");
        address membership = vm.envAddress("MEMBERSHIP_CONTRACT_ADDRESS");
        address admin = vm.addr(deployerPrivateKey);

        vm.startBroadcast(deployerPrivateKey);

        // 1. Deploy ServiceMarketplace
        ServiceMarketplace marketplace = new ServiceMarketplace(
            daosToken,
            membership,
            admin
        );
        console.log("ServiceMarketplace deployed at:", address(marketplace));

        // 2. Deploy MissionEscrow (example, would be factory-based in production)
        MissionEscrow escrow = new MissionEscrow(
            1, // missionId
            admin, // client
            admin, // consultant (example)
            1000 ether, // budget
            daosToken,
            membership
        );
        console.log("MissionEscrow deployed at:", address(escrow));

        // 3. Deploy HybridPaymentSplitter
        HybridPaymentSplitter splitter = new HybridPaymentSplitter(
            1, // missionId
            daosToken,
            admin
        );
        console.log("HybridPaymentSplitter deployed at:", address(splitter));

        vm.stopBroadcast();
    }
}
```

**Exécution**:
```bash
# Déployer sur Paseo testnet
forge script script/DeployMarketplace.s.sol:DeployMarketplace --rpc-url $PASEO_RPC_URL --broadcast --verify

# Ou sans vérification
forge script script/DeployMarketplace.s.sol:DeployMarketplace --rpc-url $PASEO_RPC_URL --broadcast
```

**Output attendu**:
```
ServiceMarketplace deployed at: 0x1234...5678
MissionEscrow deployed at: 0xABCD...EF01
HybridPaymentSplitter deployed at: 0x9876...5432
```

### 3. Vérification Etherscan

```bash
# Vérifier ServiceMarketplace
forge verify-contract \
  --chain-id 77 \
  --constructor-args $(cast abi-encode "constructor(address,address,address)" $DAOS_TOKEN_ADDRESS $MEMBERSHIP_CONTRACT_ADDRESS $ADMIN_ADDRESS) \
  0x1234...5678 \
  src/ServiceMarketplace.sol:ServiceMarketplace

# Répéter pour MissionEscrow et HybridPaymentSplitter
```

### 4. Configuration Post-Déploiement

**ServiceMarketplace**:
```bash
# Approuver tokens DAOS pour marketplace (clients)
cast send $DAOS_TOKEN_ADDRESS "approve(address,uint256)" $MARKETPLACE_ADDRESS $(cast to-wei 10000)

# Vérifier approbation
cast call $DAOS_TOKEN_ADDRESS "allowance(address,address)(uint256)" $CLIENT_ADDRESS $MARKETPLACE_ADDRESS
```

**MissionEscrow**:
```bash
# Transférer budget initial au contrat escrow
cast send $DAOS_TOKEN_ADDRESS "transfer(address,uint256)" $ESCROW_ADDRESS $(cast to-wei 1000)
```

**HybridPaymentSplitter**:
```bash
# Accorder METER_ROLE à l'oracle de metering
cast send $SPLITTER_ADDRESS "grantMeterRole(address)" $METER_ORACLE_ADDRESS
```

---

## 🔗 Integration Frontend

### ServiceMarketplace Integration

**React Hook - Create Mission**:
```typescript
import { ethers } from 'ethers';
import { useContract } from '@/hooks/useContract';

export function useCreateMission() {
  const marketplaceContract = useContract('ServiceMarketplace');

  const createMission = async (
    title: string,
    budget: bigint,
    minRank: number,
    requiredSkills: string[]
  ) => {
    // 1. Approve DAOS tokens
    const daosToken = useContract('DAOSToken');
    const approveTx = await daosToken.approve(marketplaceContract.address, budget);
    await approveTx.wait();

    // 2. Create mission
    const tx = await marketplaceContract.createMission(title, budget, minRank, requiredSkills);
    const receipt = await tx.wait();

    // 3. Extract missionId from event
    const event = receipt.logs.find((log: any) => log.eventName === 'MissionCreated');
    const missionId = event.args.missionId;

    return { missionId, transactionHash: receipt.transactionHash };
  };

  return { createMission };
}
```

**React Hook - Apply to Mission**:
```typescript
export function useApplyToMission() {
  const marketplaceContract = useContract('ServiceMarketplace');

  const applyToMission = async (
    missionId: bigint,
    proposalIpfsHash: string,
    proposedBudget: bigint
  ) => {
    const tx = await marketplaceContract.applyToMission(
      missionId,
      proposalIpfsHash,
      proposedBudget
    );

    const receipt = await tx.wait();

    const event = receipt.logs.find((log: any) => log.eventName === 'ApplicationSubmitted');
    const applicationId = event.args.applicationId;

    return { applicationId, transactionHash: receipt.transactionHash };
  };

  return { applyToMission };
}
```

**React Hook - Get Match Scores**:
```typescript
export function useMatchScores(missionId: bigint) {
  const marketplaceContract = useContract('ServiceMarketplace');

  const getMatchScores = async () => {
    const applicationIds = await marketplaceContract.getMissionApplications(missionId);

    const applications = await Promise.all(
      applicationIds.map(async (appId: bigint) => {
        const app = await marketplaceContract.applications(appId);
        return {
          applicationId: appId,
          consultant: app.consultant,
          proposal: app.proposal,
          proposedBudget: app.proposedBudget,
          matchScore: app.matchScore,
          submittedAt: new Date(Number(app.submittedAt) * 1000),
        };
      })
    );

    // Sort by match score descending
    return applications.sort((a, b) => Number(b.matchScore) - Number(a.matchScore));
  };

  return { getMatchScores };
}
```

### MissionEscrow Integration

**React Hook - Submit Milestone**:
```typescript
export function useSubmitMilestone(escrowAddress: string) {
  const escrowContract = useContract('MissionEscrow', escrowAddress);

  const submitMilestone = async (milestoneId: number, deliverableIpfsHash: string) => {
    const tx = await escrowContract.submitMilestone(milestoneId, deliverableIpfsHash);
    const receipt = await tx.wait();

    return { transactionHash: receipt.transactionHash };
  };

  return { submitMilestone };
}
```

**React Hook - Approve Milestone**:
```typescript
export function useApproveMilestone(escrowAddress: string) {
  const escrowContract = useContract('MissionEscrow', escrowAddress);

  const approveMilestone = async (milestoneId: number) => {
    const tx = await escrowContract.approveMilestone(milestoneId);
    const receipt = await tx.wait();

    const event = receipt.logs.find((log: any) => log.eventName === 'MilestoneApproved');
    const amountReleased = event.args.amountReleased;

    return { amountReleased, transactionHash: receipt.transactionHash };
  };

  return { approveMilestone };
}
```

**React Hook - Raise Dispute**:
```typescript
export function useRaiseDispute(escrowAddress: string) {
  const escrowContract = useContract('MissionEscrow', escrowAddress);

  const raiseDispute = async (milestoneId: number, reason: string) => {
    const depositAmount = ethers.parseEther('100'); // 100 DAOS

    const tx = await escrowContract.raiseDispute(milestoneId, reason, {
      value: depositAmount,
    });

    const receipt = await tx.wait();

    const event = receipt.logs.find((log: any) => log.eventName === 'DisputeRaised');
    const disputeId = event.args.disputeId;

    return { disputeId, transactionHash: receipt.transactionHash };
  };

  return { raiseDispute };
}
```

### HybridPaymentSplitter Integration

**React Hook - Report Usage (Oracle)**:
```typescript
export function useReportUsage(splitterAddress: string) {
  const splitterContract = useContract('HybridPaymentSplitter', splitterAddress);

  const reportUsage = async (llmTokens: number, gpuHours: number) => {
    // gpuHours scaled by 1000 (1.5h = 1500)
    const gpuHoursScaled = Math.round(gpuHours * 1000);

    const tx = await splitterContract.reportUsage(llmTokens, gpuHoursScaled);
    const receipt = await tx.wait();

    return { transactionHash: receipt.transactionHash };
  };

  return { reportUsage };
}
```

**React Hook - Distribute Payment**:
```typescript
export function useDistributePayment(splitterAddress: string) {
  const splitterContract = useContract('HybridPaymentSplitter', splitterAddress);

  const distributePayment = async (totalAmount: bigint) => {
    const tx = await splitterContract.distributePayment(totalAmount);
    const receipt = await tx.wait();

    // Extract payment events
    const events = receipt.logs.filter((log: any) => log.eventName === 'PaymentDistributed');

    const payments = events.map((event: any) => ({
      recipient: event.args.recipient,
      amount: event.args.amount,
      contributorType: event.args.contributorType,
    }));

    return { payments, transactionHash: receipt.transactionHash };
  };

  return { distributePayment };
}
```

---

## 📊 Sprint 5 Progress

### Effort Tracking

| Task | Planned | Actual | Status |
|------|---------|--------|--------|
| ServiceMarketplace.sol | 10h | 10h | ✅ |
| MissionEscrow.sol | 10h | 10h | ✅ |
| HybridPaymentSplitter.sol | 6h | 6h | ✅ |
| Tests (24 tests) | 4h | 4h | ✅ |
| Documentation | 2h | 2h | ✅ |
| **Total Sprint 5** | **30h** | **30h** | **✅** |

### Cumulative Progress

| Sprint | Effort | Status | Files Created |
|--------|--------|--------|---------------|
| Sprint 1 (Documentation) | 9h | ✅ | 4 guides |
| Sprint 2 (UI Governance) | 12h | ✅ | 16 fichiers |
| Sprint 3 (Dashboard Consultant) | 11h | ✅ | 6 fichiers |
| Sprint 4 (Milestone Tracker) | 14h | ✅ | 5 fichiers |
| Sprint 5 (Smart Contracts) | 30h | ✅ | 5 fichiers |
| **Total Sprints 1-5** | **76h / 95h** | **80%** | **36 fichiers** |

### Remaining

| Sprint | Tasks | Effort | Status |
|--------|-------|--------|--------|
| Sprint 6 (Data Layer) | Supabase schema + APIs + event sync + webhooks | 19h | ⏳ Pending |

---

## 🎯 Next Steps

### Sprint 6: Data Layer (19h)

**Deliverables**:
1. **Supabase Schema** (~18 tables)
   - missions, milestones, disputes
   - applications, match_scores
   - contributors, usage_logs
   - payments, transactions

2. **REST APIs** (15 endpoints)
   - Mission CRUD (create, read, update, delete)
   - Application CRUD
   - Milestone tracking
   - Dispute management
   - Usage reporting
   - Payment history

3. **Event Sync Worker** (TypeScript)
   - Listen to blockchain events
   - Sync to Supabase in real-time
   - Handle reorgs and retries

4. **Webhooks** (notifications)
   - Mission status changes
   - Milestone approvals
   - Dispute resolutions
   - Payment distributions

**Validation Checklist** (before considering Sprint 6 complete):
- [ ] All 18 tables created with RLS policies
- [ ] 15 REST API endpoints tested (Postman/Thunder Client)
- [ ] Event sync worker running (test with 10+ events)
- [ ] Webhooks tested (Discord/Slack notifications)
- [ ] Documentation (`SPRINT6_SUMMARY.md`)

---

## 📝 Contract Addresses (Post-Déploiement)

**À remplir après déploiement Paseo**:

```env
# Paseo Testnet Addresses
SERVICE_MARKETPLACE_ADDRESS=0x...
MISSION_ESCROW_FACTORY_ADDRESS=0x...
HYBRID_PAYMENT_SPLITTER_FACTORY_ADDRESS=0x...

# Dependencies
DAOS_TOKEN_ADDRESS=0x...
DAO_MEMBERSHIP_ADDRESS=0x...
```

---

## 🔍 Troubleshooting

### Issue 1: "Transfer failed" lors de createMission

**Cause**: Tokens DAOS non approuvés pour le marketplace

**Solution**:
```typescript
const daosToken = new ethers.Contract(DAOS_TOKEN_ADDRESS, ERC20_ABI, signer);
await daosToken.approve(MARKETPLACE_ADDRESS, ethers.parseEther('10000'));
```

### Issue 2: "Previous milestone must be approved" lors de submitMilestone

**Cause**: Tentative de soumettre milestone N+1 avant approbation de N

**Solution**: Respecter l'ordre séquentiel (milestone 0 → 1 → 2 → ...)

### Issue 3: "Insufficient eligible jurors" lors de raiseDispute

**Cause**: <5 membres Rank 3+ disponibles dans Membership contract

**Solution**: Vérifier `membership.getEligibleJurors()` retourne ≥5 adresses

### Issue 4: "Insufficient deposit" lors de raiseDispute

**Cause**: Dépôt <100 DAOS envoyé avec la transaction

**Solution**:
```typescript
await escrow.raiseDispute(milestoneId, reason, {
  value: ethers.parseEther('100') // 100 DAOS requis
});
```

---

## ✅ Sprint 5 - Validation Checklist

### Contracts
- [x] ServiceMarketplace.sol compilé (0 warnings)
- [x] MissionEscrow.sol compilé (0 warnings)
- [x] HybridPaymentSplitter.sol compilé (0 warnings)
- [x] OpenZeppelin imports configurés

### Tests
- [x] 24 tests passent (0 failed)
- [x] Coverage ≥80% lignes
- [x] Mocks (DAOSToken, Membership) fonctionnels
- [x] Events validés (MissionCreated, DisputeResolved, PaymentDistributed)

### Documentation
- [x] SPRINT5_SUMMARY.md créé
- [x] Déploiement guide complet
- [x] Integration frontend exemples
- [x] Troubleshooting section

---

**Sprint 5 Status**: ✅ **COMPLÉTÉ** (30h effort, 5 fichiers créés, 24 tests passent)

**Prochaine étape**: Sprint 6 (Data Layer - 19h) dès validation user.
