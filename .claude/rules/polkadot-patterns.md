# Polkadot Patterns

**Date** : 2026-02-10
**Version** : 1.0.0
**Purpose** : High-level patterns et décisions stratégiques pour développement Polkadot

---

## High-Level Patterns

### Substrate Runtime > ink! Smart Contracts

**Principe** : Prefer native Substrate pallets over ink! smart contracts for production applications.

**Rationale** :
- **Maintenance** : Parity supports Substrate runtime actively, ink! maintenance paused (Jan 2026)
- **Performance** : Native bytecode execution (0% overhead) vs WASM interpreter (10-20% overhead)
- **Flexibility** : Unlimited storage + runtime logic vs contract boundaries
- **Upgradability** : Runtime upgrades on-chain (native) vs proxy patterns (complex)

**Decision DAO** :
- ✅ **Short-term (0-3 mois)** : Ship Solidity MVP (EVM-compatible, fast deployment)
- ⚠️ **Medium-term (3-6 mois)** : Substrate POC (validate ROI)
- ✅ **Long-term (6-12 mois)** : Substrate runtime (if performance gain >2× and cost <50%)

**Reference** : `_docs/guides/ink-vs-substrate-decision.md`

---

### Agile Coretime for MVP Phase

**Principe** : Use Agile Coretime (on-demand blockspace) for MVP, migrate to parachain only if >1000 missions/day.

**Rationale** :
- **Cost-efficient** : Pay-per-use vs 2M DOT parachain slot
- **Flexible** : Rent cores during peak usage (voting periods, mission matching)
- **Breakeven** : 1000+ transactions/day = parachain rentable

**Pattern** :
```rust
// Rent core for 3-day voting period
fn rent_core_for_voting(proposal_id: u32) {
    let duration = 3 * 24; // hours
    broker_pallet::purchase_core(duration, max_price);
    schedule_core_release(proposal_id, duration);
}
```

**Decision Gate** :
- MVP (0-12 months) : Agile Coretime
- Scale (12+ months) : Parachain if >100 missions/day constant

**Reference** : `_docs/guides/polkadot-2.0-architecture.md` §Agile Coretime

---

### Test on Paseo Before Mainnet

**Principe** : Always deploy to Paseo testnet for 2+ weeks before mainnet deployment.

**Workflow** :
1. Deploy to Paseo testnet
2. Stress testing (1000+ transactions)
3. Gas optimization (<50k gas per operation)
4. Community testing (rewards program)
5. Security audit (Trail of Bits, Oak Security)
6. Mainnet deployment

**Faucet** : https://faucet.polkadot.io/

**Reference** : `_docs/guides/polkadot-deployment-guide.md` §Testnets Polkadot

---

## Security Patterns

### Always Audit Before Mainnet

**Principe** : Professional security audit is MANDATORY before mainnet deployment.

**Recommended Auditors** :
- **Trail of Bits** : $50-80k, 4-6 weeks (best reputation)
- **Oak Security** : $30-60k, 3-5 weeks (Polkadot expert)
- **OpenZeppelin** : $30-50k, 3-4 weeks (Solidity focus)

**Audit Scope** :
- Smart contracts (Solidity/ink!) : ~1200 lines
- Substrate runtime : ~800+ lines per pallet

**Timeline** :
- Week 1-2 : Initial review
- Week 3 : Penetration testing
- Week 4 : Final report + re-audit

**Budget** : $35k (Solidity MVP) to $60k (Substrate runtime)

**Reference** : `_docs/guides/polkadot-project-management.md` §Security Audit Requirements

---

### OpenZeppelin Battle-Tested Libraries

**Principe** : Use OpenZeppelin libraries for Solidity contracts (governance, access control, security).

**Libraries** :
- `AccessControl.sol` : Role-based access control
- `ReentrancyGuard.sol` : Reentrancy protection
- `Pausable.sol` : Emergency pause mechanism
- `Governor.sol` : OpenGov-compatible governance

**Example** :
```solidity
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract DAOMarketplace is AccessControl, ReentrancyGuard, Pausable {
    // Battle-tested security patterns
}
```

**Reference** : `_docs/guides/polkadot-best-practices.md` §Smart Contract Security

---

### Emergency Pause Mechanisms

**Principe** : Implement emergency pause mechanisms for all critical operations (mission creation, payments, governance).

**Solidity** :
```solidity
function createMission(...) external whenNotPaused {
    // Normal operation
}

function emergencyPause() external onlyRole(EMERGENCY_ROLE) {
    _pause();
}
```

**Substrate** :
```rust
#[pallet::storage]
pub type EmergencyPaused<T> = StorageValue<_, bool, ValueQuery>;

pub fn create_mission(...) -> DispatchResult {
    ensure!(!EmergencyPaused::<T>::get(), Error::<T>::Paused);
    // Normal logic
}
```

**Reference** : `_docs/guides/polkadot-best-practices.md` §Emergency Pause Mechanisms

---

### Weight Limits Enforcement (Substrate)

**Principe** : Always benchmark extrinsics and enforce weight limits to prevent DoS attacks.

**Pattern** :
```rust
#[pallet::weight(
    T::WeightInfo::create_mission()
        .saturating_add(T::DbWeight::get().reads(2))
        .saturating_add(T::DbWeight::get().writes(3))
)]
pub fn create_mission(...) -> DispatchResult {
    // Implementation
}
```

**Benchmark** :
```bash
cargo build --release --features runtime-benchmarks
./target/release/dao-node benchmark pallet \
    --pallet pallet_marketplace \
    --extrinsic "*" \
    --output pallets/marketplace/src/weights.rs
```

**Reference** : `_docs/guides/substrate-pallet-patterns.md` §Weight Calculation Pattern

---

## Performance Patterns

### Batch Small Transactions

**Principe** : Maximize async backing throughput by batching small transactions (10 missions in 1 block instead of 10 blocks).

**Impact** :
- **Before** : 1 mission/6s = 10 missions/min
- **After** : 10 missions/6s = 100 missions/min (10× improvement)

**Pattern** :
```solidity
function batchCreateMissions(
    string[] calldata descriptions,
    uint256[] calldata budgets
) external {
    for (uint256 i = 0; i < descriptions.length; i++) {
        _createMission(descriptions[i], budgets[i]);
    }
}
```

**Reference** : `_docs/guides/polkadot-2.0-architecture.md` §Async Backing

---

### Off-Chain Workers for Heavy Computations

**Principe** : Use off-chain workers for CPU-intensive tasks (mission rankings, reputation scoring) to avoid blocking block production.

**Pattern** :
```rust
impl<T: Config> Pallet<T> {
    fn offchain_worker(block_number: T::BlockNumber) {
        // Heavy computation off-chain
        let result = Self::compute_mission_rankings();

        // Submit result on-chain
        let call = Call::submit_rankings { result };
        SubmitTransaction::<T, Call<T>>::submit_unsigned_transaction(call.into());
    }
}
```

**Reference** : `_docs/guides/polkadot-best-practices.md` §Off-Chain Workers

---

### Storage Optimization (Bounded Types)

**Principe** : Use bounded types (`BoundedVec`) to prevent storage bloat and DoS attacks.

**Pattern** :
```rust
// ❌ WRONG: Unbounded vector
pub struct Mission {
    pub tags: Vec<u8>,
}

// ✅ CORRECT: Bounded vector
pub struct Mission {
    pub tags: BoundedVec<u8, ConstU32<100>>,
}
```

**Reference** : `_docs/guides/polkadot-best-practices.md` §Storage Bounds

---

### Event Emission (Minimal Data)

**Principe** : Emit minimal data on-chain (hashes, IDs), store full data off-chain (IPFS).

**Pattern** :
```rust
// ❌ WRONG: Emit full description
#[pallet::event]
pub enum Event<T: Config> {
    MissionCreated {
        id: u64,
        description: Vec<u8>, // Can be large!
    },
}

// ✅ CORRECT: Emit hash only
#[pallet::event]
pub enum Event<T: Config> {
    MissionCreated {
        id: u64,
        description_hash: [u8; 32], // Fixed size
    },
}
```

**Reference** : `_docs/guides/polkadot-best-practices.md` §Event Emission

---

## Decision Gates

### Gate 0 (Month 0 - NOW)

**Decision** : Abandon ink! migration, focus Solidity MVP completion.

**Rationale** :
- ink! maintenance paused (security risk)
- 67% migration restante = 2-3 mois wasted effort
- Substrate runtime = superior long-term choice

**Action** : Complete Phase 3 Solidity MVP (30% restant = 3-4 weeks).

**Reference** : `_docs/guides/ink-vs-substrate-decision.md` §Recommandation Stratégique

---

### Gate 1 (Month 3)

**Criteria** :
- Solidity MVP revenue > $10k/month ?
- Marketplace usage > 10 missions/jour ?

**Decision** :
- ✅ YES → Continue Solidity + Start Substrate POC (parallel)
- ❌ NO → Pivot strategy

**Reference** : `_docs/guides/ink-vs-substrate-decision.md` §Decision Gates

---

### Gate 2 (Month 6)

**Criteria** :
- Substrate POC performance gain > 2× Solidity ?
- Substrate POC cost reduction > 50% Solidity ?
- Security audit Substrate < $80k ?

**Decision** :
- ✅ YES (3/3 criteria) → Migrate to Substrate
- ❌ NO (<3/3 criteria) → Stay on Solidity

**Reference** : `_docs/guides/ink-vs-substrate-decision.md` §Success Criteria POC

---

### Gate 3 (Month 12)

**Criteria** :
- User base > 1000 active users ?
- Throughput > 100 missions/jour constant ?
- Treasury > 500k DOT ?

**Decision** :
- ✅ YES → Evaluate parachain (crowdloan preparation)
- ❌ NO → Stay Agile Coretime

**Reference** : `_docs/guides/polkadot-deployment-guide.md` §Parachain Path

---

## Anti-Patterns (Avoid)

### ❌ Direct ink! Migration

**Why Avoid** : ink! maintenance abandoned (Jan 2026), security risk long-term.

**Alternative** : Substrate runtime (Parity-supported, production-grade).

---

### ❌ Custom Bridges

**Why Avoid** : Security risk (trust assumptions, implementation bugs).

**Alternative** : Use Snowbridge (trustless, light client verification) or Hyperbridge (ZK proofs).

**Reference** : `_docs/guides/xcm-integration-patterns.md` §Bridge DAO Token Ethereum ↔ Polkadot

---

### ❌ Unbounded Storage

**Why Avoid** : Storage bloat, DoS attacks.

**Alternative** : Use `BoundedVec` with explicit limits.

---

### ❌ No Emergency Pause

**Why Avoid** : Cannot stop contract in case of exploit.

**Alternative** : Implement `Pausable` pattern (OpenZeppelin).

---

## Related Guides

| Guide | Purpose | Priorité |
|-------|---------|----------|
| `polkadot-2.0-architecture.md` | Async Backing, Agile Coretime, Elastic Scaling, XCM | CRITIQUE |
| `ink-vs-substrate-decision.md` | Décision stratégique ink! vs Substrate | CRITIQUE |
| `substrate-pallet-patterns.md` | Pallet development, weight calculation, testing | HAUTE |
| `xcm-integration-patterns.md` | Cross-chain asset transfer, bridges, XCM security | HAUTE |
| `polkadot-deployment-guide.md` | Testnets, mainnet deployment, parachain path | HAUTE |
| `polkadot-project-management.md` | Treasury proposals, audits, community engagement | HAUTE |
| `polkadot-best-practices.md` | Security, performance, governance, testing | HAUTE |

---

**Version** : 1.0.0
**Dernière mise à jour** : 2026-02-10
