# Escrow + Dispute Resolution - Specifications Phase 2 Extension

## Contexte

Extension de Phase 2 pour ajouter mécanismes de quality assurance :
- Escrow avec milestones
- Dispute resolution par arbitrage DAO
- Reputation tracking basique

## Objectifs

**Fonctionnels** :
- Client peut définir milestones avec critères d'acceptation
- Consultant soumet deliverables pour validation
- Client valide/rejette livraisons
- Système de dispute avec arbitrage par DAO members
- Reputation score impacte matching

**Non-fonctionnels** :
- Gas-efficient (batch operations)
- GDPR-compliant (hash-only storage)
- Backward compatible avec missions existantes

---

## Architecture

### 1. MilestoneEscrow.sol

**Responsabilités** :
- Lock funds en escrow lors création mission
- Gestion milestones par mission
- Release funds progressif à validation milestones
- Refund client si mission cancelled

**Structures** :

```solidity
struct Milestone {
    string description;              // "Phase 1: Design mockups"
    bytes32 acceptanceCriteriaHash;  // IPFS hash critères détaillés
    uint256 amount;                  // Budget alloué (wei)
    MilestoneStatus status;
    bytes32 deliverableHash;         // IPFS hash livrable soumis
    uint256 submittedAt;
    uint256 validatedAt;
    address validator;               // Client qui a validé
}

enum MilestoneStatus {
    Pending,      // Pas encore soumis
    Submitted,    // Consultant a soumis livrable
    Accepted,     // Client a validé
    Rejected,     // Client a rejeté
    Disputed      // En cours d'arbitrage
}

struct EscrowBalance {
    uint256 totalLocked;     // Total en escrow
    uint256 released;        // Déjà payé au consultant
    uint256 refunded;        // Remboursé au client
    bool finalized;          // Escrow finalisé (all milestones resolved)
}

mapping(uint256 => Milestone[]) public missionMilestones;
mapping(uint256 => EscrowBalance) public escrowBalances;
```

**Fonctions publiques** :

```solidity
// Client définit milestones lors création mission
function setupMilestones(
    uint256 missionId,
    Milestone[] memory milestones
) external onlyClient(missionId);

// Consultant soumet livrable
function submitDeliverable(
    uint256 missionId,
    uint256 milestoneIndex,
    bytes32 deliverableHash
) external onlySelectedConsultant(missionId);

// Client accepte livrable → release funds
function acceptDeliverable(
    uint256 missionId,
    uint256 milestoneIndex
) external onlyClient(missionId);

// Client rejette livrable
function rejectDeliverable(
    uint256 missionId,
    uint256 milestoneIndex,
    string calldata reason
) external onlyClient(missionId);

// Emergency: Client cancel mission avant sélection consultant
function cancelMissionAndRefund(
    uint256 missionId
) external onlyClient(missionId);
```

---

### 2. DisputeResolution.sol

**Responsabilités** :
- Création disputes suite rejection deliverable
- Sélection arbitres aléatoires parmi DAO members éligibles
- Vote arbitres (Accept/Reject deliverable)
- Resolution dispute à majorité qualifiée (2/3)
- Distribution rewards arbitres

**Structures** :

```solidity
struct Dispute {
    uint256 missionId;
    uint256 milestoneIndex;
    address initiator;           // Consultant (suite reject)
    string reason;               // Raison du litige
    DisputeStatus status;
    address[3] arbiters;         // 3 arbitres sélectionnés
    uint256 votesAccept;         // Count votes "Accept deliverable"
    uint256 votesReject;         // Count votes "Reject deliverable"
    uint256 createdAt;
    uint256 resolvedAt;
}

enum DisputeStatus {
    Open,          // Dispute ouverte, votes en cours
    Resolved,      // Décision prise
    Cancelled      // Annulée (ex: consultant retire dispute)
}

mapping(uint256 => Dispute) public disputes; // disputeId => Dispute
mapping(uint256 => mapping(address => bool)) public hasVoted;
```

**Fonctions publiques** :

```solidity
// Consultant initie dispute suite reject
function initiateDispute(
    uint256 missionId,
    uint256 milestoneIndex,
    string calldata reason
) external onlySelectedConsultant(missionId) returns (uint256 disputeId);

// Arbitre vote (require rank ≥3)
function voteOnDispute(
    uint256 disputeId,
    bool acceptDeliverable
) external onlyEligibleArbiter;

// Resolve dispute après votes (automatic ou manual trigger)
function resolveDispute(
    uint256 disputeId
) external;

// Consultant peut cancel dispute avant votes (ex: accord amiable)
function cancelDispute(
    uint256 disputeId
) external onlyDisputeInitiator(disputeId);
```

**Mécanisme arbitrage** :
- Sélection 3 arbitres random parmi members avec `rank ≥3`
- Vote period : 7 jours
- Décision : Majorité 2/3 (2 votes minimum pour gagner)
- Reward arbitres : 2% du milestone amount (distribué équitablement)

---

### 3. ReputationTracker.sol (MVP simple)

**Responsabilités** :
- Track missions completed/disputed par consultant et client
- Calculate reputation score basique

**Structures** :

```solidity
struct ReputationScore {
    uint256 missionsCompleted;
    uint256 disputesInitiated;
    uint256 disputesWon;        // Arbitrage en faveur
    uint256 disputesLost;       // Arbitrage défavorable
}

mapping(address => ReputationScore) public consultantReputation;
mapping(address => ReputationScore) public clientReputation;
```

**Fonctions publiques** :

```solidity
// Update reputation après resolution dispute (internal call)
function updateReputation(
    uint256 missionId,
    address consultant,
    address client,
    bool consultantWon
) external onlyDisputeContract;

// Get reputation score (public view)
function getReputationScore(address user) external view returns (ReputationScore memory);

// Calculate match penalty based on reputation (for ServiceMarketplace scoring)
function getReputationPenalty(address user) external view returns (uint256);
```

---

## Intégration ServiceMarketplace

**Modifications** :

1. Constructor : Ajouter addresses escrow + dispute contracts
2. createMission : Lock funds dans escrow
3. selectConsultant : Transférer escrow ownership au consultant
4. Nouveau status : `MissionStatus.UnderDelivery` (milestones en cours)

---

## Workflow complet

### Happy Path (no dispute)

```
1. Client crée mission → funds locked en escrow
2. Client définit 3 milestones (30%, 40%, 30% budget)
3. Consultant sélectionné → mission status: UnderDelivery
4. Consultant soumet deliverable milestone 1
5. Client accepte → 30% released au consultant
6. Repeat pour milestones 2-3
7. Mission status: Completed
```

### Dispute Path

```
1-4. [Same as happy path]
5. Client rejette deliverable milestone 1 (reason: "Pas conforme specs")
6. Consultant initie dispute
7. 3 arbitres sélectionnés (rank ≥3)
8. Arbitres votent pendant 7 jours
9. Résolution : 2 votes "Accept" → Deliverable accepted
10. 30% released au consultant
11. Reputation updated (consultant +1 disputeWon, client +1 disputeLost)
```

---

## Spécifications comportementales (TDD)

### MilestoneEscrow.sol

**Given/When/Then** :

1. **Setup milestones**
   - Given: Client a créé mission avec budget 1000 DAOS
   - When: Client setup 3 milestones (300, 400, 300 DAOS)
   - Then: Total milestones amount = 1000 DAOS, escrow locked

2. **Submit deliverable**
   - Given: Mission avec milestones, consultant sélectionné
   - When: Consultant soumet deliverable IPFS hash
   - Then: Milestone status = Submitted, deliverableHash stored

3. **Accept deliverable**
   - Given: Milestone status Submitted
   - When: Client accepte deliverable
   - Then: Status = Accepted, funds released au consultant, escrow balance updated

4. **Reject deliverable**
   - Given: Milestone status Submitted
   - When: Client rejette deliverable
   - Then: Status = Rejected, funds NOT released

5. **Cancel mission before consultant selected**
   - Given: Mission Active, no consultant selected
   - When: Client cancel mission
   - Then: Escrow refunded to client, mission status Cancelled

### DisputeResolution.sol

**Given/When/Then** :

1. **Initiate dispute**
   - Given: Milestone rejected par client
   - When: Consultant initie dispute
   - Then: Dispute created, 3 arbitres sélectionnés, status Open

2. **Arbiter vote**
   - Given: Dispute Open, user rank ≥3
   - When: Arbiter vote "Accept deliverable"
   - Then: votesAccept incremented, hasVoted[arbiter] = true

3. **Resolve dispute (consultant wins)**
   - Given: Dispute avec 2 votes Accept, 1 vote Reject
   - When: resolveDispute() called
   - Then: Status = Resolved, milestone status = Accepted, funds released, reputation updated

4. **Resolve dispute (client wins)**
   - Given: Dispute avec 1 vote Accept, 2 votes Reject
   - When: resolveDispute() called
   - Then: Status = Resolved, milestone status = Rejected, funds stay in escrow

5. **Cancel dispute**
   - Given: Dispute Open, consultant initiator
   - When: Consultant cancel dispute
   - Then: Status = Cancelled, milestone status reverts to Rejected

### ReputationTracker.sol

**Given/When/Then** :

1. **Update reputation after dispute won**
   - Given: Consultant with 0 disputes
   - When: Dispute resolved, consultant won
   - Then: disputesInitiated +1, disputesWon +1

2. **Update reputation after dispute lost**
   - Given: Client with 0 disputes
   - When: Dispute resolved, client lost
   - Then: disputesLost +1

3. **Calculate reputation penalty**
   - Given: Consultant with disputesLost = 3, disputesInitiated = 10
   - When: getReputationPenalty() called
   - Then: Penalty = 30% (3/10 disputes lost)

---

## Spécifications négatives (ce qui ne doit PAS changer)

1. ❌ Ne PAS modifier ComplianceRegistry.sol (déjà implémenté Phase 1)
2. ❌ Ne PAS casser backward compatibility missions existantes (sans milestones)
3. ❌ Ne PAS stocker PII on-chain (GDPR violation)
4. ❌ Ne PAS permettre double-spending escrow
5. ❌ Ne PAS permettre arbitres voter multiple fois
6. ❌ Ne PAS permettre non-DAO members arbitrer

---

## Tests requis (TDD strict)

### MilestoneEscrow.t.sol
- [ ] test_SetupMilestones_Success
- [ ] test_SetupMilestones_RevertIfNotClient
- [ ] test_SetupMilestones_RevertIfTotalExceedsBudget
- [ ] test_SubmitDeliverable_Success
- [ ] test_SubmitDeliverable_RevertIfNotConsultant
- [ ] test_AcceptDeliverable_Success
- [ ] test_AcceptDeliverable_ReleaseFunds
- [ ] test_RejectDeliverable_Success
- [ ] test_RejectDeliverable_NoFundsReleased
- [ ] test_CancelMission_RefundClient

### DisputeResolution.t.sol
- [ ] test_InitiateDispute_Success
- [ ] test_InitiateDispute_RevertIfNotConsultant
- [ ] test_InitiateDispute_RevertIfNotRejected
- [ ] test_ArbiterVote_Success
- [ ] test_ArbiterVote_RevertIfAlreadyVoted
- [ ] test_ArbiterVote_RevertIfNotEligible (rank <3)
- [ ] test_ResolveDispute_ConsultantWins (2 votes Accept)
- [ ] test_ResolveDispute_ClientWins (2 votes Reject)
- [ ] test_ResolveDispute_Tie (fallback: client wins)
- [ ] test_CancelDispute_Success

### ReputationTracker.t.sol
- [ ] test_UpdateReputation_ConsultantWon
- [ ] test_UpdateReputation_ClientLost
- [ ] test_GetReputationPenalty_HighLossRate (30%)
- [ ] test_GetReputationPenalty_LowLossRate (5%)

### Integration Tests (ServiceMarketplace.escrow.t.sol)
- [ ] test_Integration_FullWorkflow_NoDispute
- [ ] test_Integration_FullWorkflow_WithDispute_ConsultantWins
- [ ] test_Integration_FullWorkflow_WithDispute_ClientWins
- [ ] test_Integration_BackwardCompatibility_NoMilestones

---

## Couverture cible

- Lines: ≥95%
- Statements: ≥95%
- Branches: ≥90%
- Functions: 100%

---

**Version** : 1.0.0
**Date** : 2026-02-16
**Phase** : Phase 2 Extension (Escrow + Dispute Resolution)
