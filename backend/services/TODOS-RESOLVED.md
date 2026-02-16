# TODOs Resolved → GitHub Issues

**Date**: 2026-02-16
**Context**: Phase 1 Remédiation - Task #2 (Event-sync hardening)

## TODOs Removed from event-sync-worker.ts

### TODO-EVENT-SYNC-01: Listen to MissionEscrow and HybridPaymentSplitter events
**Original Line**: 487
**Original Text**:
```typescript
// TODO: Listen to MissionEscrow and HybridPaymentSplitter events
// Requires tracking contract addresses dynamically (via factory events)
```

**Resolution**:
- Deferred to Phase 2 (tracking dynamic contract addresses requires factory event listeners)
- Created GitHub issue (to be created): #TODO-EVENT-SYNC-01
- Priority: MEDIUM (not blocking MVP - these events are for milestone payments)
- Estimated effort: 2-3 days (requires factory pattern implementation)

**GitHub Issue Template**:
```
Title: Listen to MissionEscrow and HybridPaymentSplitter events

Labels: tech-debt, enhancement, phase-2

Description:
Currently event-sync-worker only listens to ServiceMarketplace events.
Add listeners for:
- MissionEscrow events (MilestoneAdded, MilestoneSubmitted, etc.)
- HybridPaymentSplitter events (ContributorAdded, PaymentDistributed, etc.)

Challenge: These contracts are created dynamically via factory patterns, so we need to:
1. Listen to factory CreateEscrow/CreateSplitter events
2. Track new contract addresses
3. Dynamically attach event listeners to new instances

Acceptance Criteria:
- [ ] Factory event listeners implemented
- [ ] Dynamic contract instance tracking
- [ ] Event handlers for all MissionEscrow events
- [ ] Event handlers for all HybridPaymentSplitter events
- [ ] Tests: 10+ test cases covering dynamic listener attachment
```

---

### TODO-EVENT-SYNC-02: Fetch dispute reason from contract
**Original Line**: 347
**Original Text**:
```typescript
reason: 'Dispute raised on-chain', // TODO: Fetch from contract
```

**Resolution**:
- GitHub issue created (to be created): #TODO-EVENT-SYNC-02
- Priority: HIGH (user-facing - affects dispute UI)
- Estimated effort: 1 day (requires contract ABI update + RPC call)

**GitHub Issue Template**:
```
Title: Fetch dispute reason from DisputeResolution contract

Labels: tech-debt, bug, UX

Description:
Currently hardcoded to 'Dispute raised on-chain'. Should fetch actual reason from contract.

Implementation:
1. Add `getDisputeDetails(disputeId)` to DisputeResolution ABI
2. Call contract method in handleDisputeRaised
3. Store real reason in transaction log

Acceptance Criteria:
- [ ] Contract method added to ABI
- [ ] RPC call with retry logic
- [ ] Real dispute reason stored in database
- [ ] Tests: 3 test cases (valid reason, invalid disputeId, RPC error)
```

---

### TODO-EVENT-SYNC-03: Resolve mission from splitter contract
**Original Lines**: 390, 394
**Original Text**:
```typescript
// TODO: Find mission associated with this splitter contract
...
mission_id: null, // TODO: Resolve from splitter contract
```

**Resolution**:
- GitHub issue created (to be created): #TODO-EVENT-SYNC-03
- Priority: MEDIUM (affects payment distribution tracking)
- Estimated effort: 1.5 days (requires contract storage read)

**GitHub Issue Template**:
```
Title: Resolve mission from HybridPaymentSplitter contract

Labels: tech-debt, enhancement

Description:
Currently mission_id is null for payment splitter events. Should resolve from contract storage.

Implementation:
1. Add `getMissionId()` to HybridPaymentSplitter ABI
2. Call contract method in handlePaymentDistributed
3. Link payment events to missions

Acceptance Criteria:
- [ ] Contract method added to ABI
- [ ] RPC call with retry logic
- [ ] mission_id populated in transaction logs
- [ ] Tests: 3 test cases (valid mission, no mission, RPC error)
```

---

## Summary

| TODO ID | Priority | Effort | Phase | Status |
|---------|----------|--------|-------|--------|
| EVENT-SYNC-01 | MEDIUM | 2-3d | Phase 2 | GitHub issue (to create) |
| EVENT-SYNC-02 | HIGH | 1d | This sprint | GitHub issue (to create) |
| EVENT-SYNC-03 | MEDIUM | 1.5d | Phase 2 | GitHub issue (to create) |

**Total deferred effort**: 4.5-5.5 days (acceptable for MVP)

**Action items**:
1. Create 3 GitHub issues with templates above
2. Label with tech-debt + priority
3. Assign to Phase 2 (except EVENT-SYNC-02 which is HIGH priority)
