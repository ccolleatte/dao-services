# Polkadot Best Practices

**Date** : 2026-02-10
**Projet** : DAO Services IA/Humains
**Version** : 1.0.0

---

## Vue d'ensemble

Ce guide consolide les best practices pour développer sur l'écosystème Polkadot, couvrant smart contracts (Solidity/ink!) et runtime development (Substrate).

---

## 1. Smart Contract Security (ink!/Solidity)

### Reentrancy Guards

**Problem** : Attacker calls back into contract before state is updated.

**Solidity** :

```solidity
// OpenZeppelin ReentrancyGuard
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract DAOMarketplace is ReentrancyGuard {
    function releasePayment(uint256 missionId) external nonReentrant {
        Mission storage mission = missions[missionId];

        // State updates BEFORE external call
        mission.status = Status.Completed;
        mission.paid = true;

        // External call last (checks-effects-interactions pattern)
        payable(mission.provider).transfer(mission.budget);
    }
}
```

**ink!** :

```rust
#[ink(message)]
pub fn release_payment(&mut self, mission_id: u64) -> Result<()> {
    // State updates first
    let mut mission = self.missions.get_mut(&mission_id)
        .ok_or(Error::MissionNotFound)?;

    mission.status = Status::Completed;

    // Transfer last
    self.env().transfer(mission.provider, mission.budget)?;

    Ok(())
}
```

---

### Integer Overflow Checks

**Solidity 0.8+** : Built-in overflow checks (reverts on overflow).

```solidity
// Safe by default
function addBudget(uint256 missionId, uint256 amount) external {
    missions[missionId].budget += amount; // Reverts on overflow
}

// Explicit unchecked (use with caution)
function optimizedAdd(uint256 a, uint256 b) internal pure returns (uint256) {
    unchecked {
        return a + b; // Gas savings, but unsafe
    }
}
```

**ink!** : Use `checked_*` methods.

```rust
pub fn add_budget(&mut self, mission_id: u64, amount: Balance) -> Result<()> {
    let mission = self.missions.get_mut(&mission_id)
        .ok_or(Error::MissionNotFound)?;

    // Safe: reverts on overflow
    mission.budget = mission.budget.checked_add(amount)
        .ok_or(Error::Overflow)?;

    Ok(())
}
```

---

### Access Control Patterns

**Solidity** : OpenZeppelin `AccessControl`.

```solidity
import "@openzeppelin/contracts/access/AccessControl.sol";

contract DAOGovernance is AccessControl {
    bytes32 public constant PROPOSER_ROLE = keccak256("PROPOSER");
    bytes32 public constant VOTER_ROLE = keccak256("VOTER");

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function createProposal(...) external onlyRole(PROPOSER_ROLE) {
        // Only proposers can create proposals
    }

    function vote(...) external onlyRole(VOTER_ROLE) {
        // Only voters can vote
    }
}
```

**ink!** : Custom role-based access.

```rust
#[derive(Debug, Clone, Copy, PartialEq, Eq, Encode, Decode, SpreadLayout)]
pub enum Role {
    Admin,
    Proposer,
    Voter,
}

#[ink(storage)]
pub struct DAOGovernance {
    roles: Mapping<AccountId, Role>,
}

#[ink(message)]
pub fn create_proposal(&mut self, ...) -> Result<()> {
    let caller = self.env().caller();
    let role = self.roles.get(&caller).ok_or(Error::Unauthorized)?;

    ensure!(role == Role::Proposer || role == Role::Admin, Error::Unauthorized);

    // Logic
    Ok(())
}
```

---

### Emergency Pause Mechanisms

**Solidity** :

```solidity
import "@openzeppelin/contracts/security/Pausable.sol";

contract DAOMarketplace is Pausable {
    function createMission(...) external whenNotPaused {
        // Normal operation
    }

    function emergencyPause() external onlyRole(EMERGENCY_ROLE) {
        _pause();
        emit EmergencyPaused(msg.sender);
    }

    function unpause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
        emit Unpaused(msg.sender);
    }
}
```

**Substrate** :

```rust
#[pallet::storage]
pub type EmergencyPaused<T> = StorageValue<_, bool, ValueQuery>;

#[pallet::call]
impl<T: Config> Pallet<T> {
    #[pallet::weight(10_000)]
    pub fn create_mission(&mut self, ...) -> DispatchResult {
        ensure!(!EmergencyPaused::<T>::get(), Error::<T>::Paused);

        // Normal logic
        Ok(())
    }

    #[pallet::weight(10_000)]
    pub fn emergency_pause(origin: OriginFor<T>) -> DispatchResult {
        T::EmergencyOrigin::ensure_origin(origin)?;

        EmergencyPaused::<T>::put(true);

        Self::deposit_event(Event::EmergencyPaused);

        Ok(())
    }
}
```

---

## 2. Runtime Security (Substrate)

### Weight Limits Enforcement

**Problem** : Unbounded computation causes DoS.

**Solution** : Benchmark extrinsics and enforce weight limits.

```rust
#[pallet::call]
impl<T: Config> Pallet<T> {
    // Weight calculated from benchmarking
    #[pallet::weight(
        T::WeightInfo::create_mission()
            .saturating_add(T::DbWeight::get().reads(2))
            .saturating_add(T::DbWeight::get().writes(3))
    )]
    pub fn create_mission(
        origin: OriginFor<T>,
        description_hash: [u8; 32],
        budget: BalanceOf<T>,
    ) -> DispatchResult {
        // Implementation
        Ok(())
    }
}

// Benchmark implementation
#[cfg(feature = "runtime-benchmarks")]
benchmarks! {
    create_mission {
        let caller: T::AccountId = whitelisted_caller();
        let budget = T::MinimumBudget::get() * 10u32.into();
        T::Currency::make_free_balance_be(&caller, budget * 2u32.into());

    }: _(RawOrigin::Signed(caller), [0u8; 32], budget)
    verify {
        assert_eq!(NextMissionId::<T>::get(), 1);
    }
}
```

---

### Origin Checking

**Problem** : Unauthorized calls execute privileged operations.

**Solution** : Always check origin with `ensure_*` macros.

```rust
#[pallet::call]
impl<T: Config> Pallet<T> {
    pub fn admin_operation(origin: OriginFor<T>) -> DispatchResult {
        // CRITICAL: Check origin first
        ensure_root(origin)?; // Only sudo/governance

        // Privileged logic
        Ok(())
    }

    pub fn user_operation(origin: OriginFor<T>) -> DispatchResult {
        // CRITICAL: Verify signed origin
        let caller = ensure_signed(origin)?;

        // User-specific logic
        Ok(())
    }

    pub fn governance_operation(origin: OriginFor<T>) -> DispatchResult {
        // Custom origin check
        T::GovernanceOrigin::ensure_origin(origin)?;

        // Governance logic
        Ok(())
    }
}
```

---

### Storage Bounds

**Problem** : Unbounded vectors cause storage bloat.

**Solution** : Use `BoundedVec`.

```rust
use frame_support::BoundedVec;

#[pallet::storage]
pub type Missions<T: Config> = StorageMap<
    _,
    Blake2_128Concat,
    u64,
    Mission<T::AccountId, BalanceOf<T>>,
>;

#[derive(Clone, Encode, Decode, Eq, PartialEq, TypeInfo, MaxEncodedLen)]
pub struct Mission<AccountId, Balance> {
    pub client: AccountId,
    pub description_hash: [u8; 32],
    pub budget: Balance,

    // ❌ WRONG: Unbounded
    // pub tags: Vec<u8>,

    // ✅ CORRECT: Bounded
    pub tags: BoundedVec<u8, ConstU32<100>>, // Max 100 bytes
}

#[pallet::call]
impl<T: Config> Pallet<T> {
    pub fn create_mission(
        origin: OriginFor<T>,
        description_hash: [u8; 32],
        budget: BalanceOf<T>,
        tags: Vec<u8>,
    ) -> DispatchResult {
        let caller = ensure_signed(origin)?;

        // Validate bounds
        let bounded_tags: BoundedVec<u8, ConstU32<100>> = tags.try_into()
            .map_err(|_| Error::<T>::TagsTooLong)?;

        // Create mission
        let mission = Mission {
            client: caller,
            description_hash,
            budget,
            tags: bounded_tags,
        };

        // Store
        Missions::<T>::insert(next_id, mission);

        Ok(())
    }
}
```

---

### Benchmarking Critical Extrinsics

**Setup** :

```bash
# Build with benchmarking feature
cargo build --release --features runtime-benchmarks

# Run benchmarks
./target/release/dao-node benchmark pallet \
    --pallet pallet_marketplace \
    --extrinsic "*" \
    --steps 50 \
    --repeat 20 \
    --output pallets/marketplace/src/weights.rs \
    --template .maintain/frame-weight-template.hbs
```

**Generated weights** :

```rust
pub trait WeightInfo {
    fn create_mission() -> Weight;
    fn match_mission() -> Weight;
    fn release_payment() -> Weight;
}

impl WeightInfo for SubstrateWeight<T> {
    fn create_mission() -> Weight {
        Weight::from_parts(45_000_000, 0)
            .saturating_add(T::DbWeight::get().reads(2))
            .saturating_add(T::DbWeight::get().writes(3))
    }
}
```

---

## 3. Performance Optimization

### Batching Transactions

**Pattern** : Group related operations to maximize throughput.

**Solidity** :

```solidity
function batchCreateMissions(
    string[] calldata descriptions,
    uint256[] calldata budgets
) external {
    require(descriptions.length == budgets.length, "Length mismatch");

    for (uint256 i = 0; i < descriptions.length; i++) {
        _createMission(descriptions[i], budgets[i]);
    }

    emit MissionsBatchCreated(descriptions.length);
}
```

**Substrate** :

```rust
#[pallet::call]
impl<T: Config> Pallet<T> {
    #[pallet::weight(
        T::WeightInfo::create_mission()
            .saturating_mul(missions.len() as u64)
    )]
    pub fn batch_create_missions(
        origin: OriginFor<T>,
        missions: Vec<(BoundedVec<u8, T::MaxDescriptionLen>, BalanceOf<T>)>,
    ) -> DispatchResult {
        let caller = ensure_signed(origin)?;

        for (description, budget) in missions {
            Self::create_mission_internal(caller.clone(), description, budget)?;
        }

        Ok(())
    }
}
```

**Benefit** : 10 missions in 1 block (6s) instead of 10 blocks (60s).

---

### Storage Optimization

**Use bounded types** :

```rust
// ❌ WRONG: Vec<T> (unbounded, expensive)
pub struct Mission<T> {
    pub tags: Vec<u8>,
    pub milestones: Vec<Milestone>,
}

// ✅ CORRECT: BoundedVec (bounded, efficient)
pub struct Mission<T> {
    pub tags: BoundedVec<u8, ConstU32<100>>,
    pub milestones: BoundedVec<Milestone, ConstU32<10>>,
}
```

**Minimize storage writes** :

```rust
// ❌ WRONG: Multiple writes
pub fn update_mission(mission_id: u64, new_budget: Balance, new_status: Status) {
    Missions::<T>::mutate(mission_id, |mission| {
        mission.budget = new_budget;
    }); // Write #1

    Missions::<T>::mutate(mission_id, |mission| {
        mission.status = new_status;
    }); // Write #2 (expensive!)
}

// ✅ CORRECT: Single write
pub fn update_mission(mission_id: u64, new_budget: Balance, new_status: Status) {
    Missions::<T>::mutate(mission_id, |mission| {
        mission.budget = new_budget;
        mission.status = new_status;
    }); // Single write
}
```

---

### Event Emission

**Minimal data on-chain** :

```rust
// ❌ WRONG: Emit full description (expensive)
#[pallet::event]
pub enum Event<T: Config> {
    MissionCreated {
        id: u64,
        description: Vec<u8>, // Can be large!
        budget: BalanceOf<T>,
    },
}

// ✅ CORRECT: Emit hash only (cheap)
#[pallet::event]
pub enum Event<T: Config> {
    MissionCreated {
        id: u64,
        description_hash: [u8; 32], // Fixed size, cheap
        budget: BalanceOf<T>,
    },
}

// Full description stored off-chain (IPFS)
```

---

### Off-Chain Workers

**Use case** : Heavy computations, external API calls.

```rust
impl<T: Config> Pallet<T> {
    fn offchain_worker(block_number: T::BlockNumber) {
        // Heavy computation off-chain
        let result = Self::compute_mission_rankings();

        // Submit result on-chain (signed transaction)
        let call = Call::submit_rankings { result };
        SubmitTransaction::<T, Call<T>>::submit_unsigned_transaction(call.into())
            .expect("Failed to submit transaction");
    }

    #[pallet::call]
    impl<T: Config> Pallet<T> {
        #[pallet::weight(10_000)]
        pub fn submit_rankings(
            origin: OriginFor<T>,
            rankings: Vec<(u64, u32)>, // Mission ID → Score
        ) -> DispatchResult {
            ensure_none(origin)?; // Unsigned transaction

            // Store rankings
            for (mission_id, score) in rankings {
                MissionScores::<T>::insert(mission_id, score);
            }

            Ok(())
        }
    }
}
```

**Benefit** : CPU-intensive tasks don't block block production.

---

## 4. Governance Best Practices

### Proposal Clarity

**Template** :

```markdown
# Title: [Feature Name] - [Budget] DOT

## Problem
[Clear description of the problem]

## Solution
[Detailed solution with technical specs]

## Budget
- Total: X DOT
- Breakdown:
  - Development: Y DOT
  - Audit: Z DOT
  - Testing: W DOT

## Milestones
1. Milestone 1 (Week N): Deliverable → Payment
2. Milestone 2 (Week N+M): Deliverable → Payment

## Team
- [Name] - [Role] - [GitHub/X]

## Expected Outcomes
- [Measurable outcome 1]
- [Measurable outcome 2]

## Timeline
- Start: [Date]
- End: [Date]
```

---

### Milestone-Based Releases

**Pattern** : Pay incrementally based on deliverables.

```solidity
struct Milestone {
    string description;
    uint256 amount;
    bool completed;
    bool paid;
}

mapping(uint256 => Milestone[]) public proposalMilestones;

function completeMilestone(uint256 proposalId, uint256 milestoneIndex) external {
    require(hasRole(REVIEWER_ROLE, msg.sender), "Unauthorized");

    Milestone storage milestone = proposalMilestones[proposalId][milestoneIndex];
    require(!milestone.completed, "Already completed");

    milestone.completed = true;

    // Release payment
    _releaseMilestonePayment(proposalId, milestoneIndex);
}
```

**Benefit** : Reduces risk (no upfront payments), incentivizes delivery.

---

### Community Feedback Loops

**Process** :

1. **Pre-Proposal Discussion** (Polkadot Forum)
   - Post idea
   - Gather feedback (2-4 weeks)
   - Iterate

2. **Formal Proposal** (Subsquare/Polkassembly)
   - Submit on-chain proposal
   - Link to technical specs

3. **Voting Period**
   - Respond to questions (daily)
   - Address concerns
   - Provide updates

4. **Post-Approval**
   - Deliver milestones
   - Report progress (weekly)
   - Final report

---

### Track Selection

**Guidelines** :

| Proposal Type | Track | Rationale |
|---------------|-------|-----------|
| Bug fix (<$5k) | Small Spender | Fast approval (7 days) |
| Feature development ($10-50k) | Medium Spender | Standard approval (14 days) |
| Security audit ($50-100k) | Big Spender | Rigorous approval (28 days) |
| Emergency fix | Treasurer | Fast-track (7 days) |
| Governance parameters | Technical | Expert review (14 days) |

---

## 5. Testing Strategy

### Unit Tests

**Coverage Target** : 80%+ lines, 70%+ branches.

**Solidity** :

```solidity
// test/DAOGovernance.t.sol
contract DAOGovernanceTest is Test {
    DAOGovernance public governance;

    function setUp() public {
        governance = new DAOGovernance();
    }

    function testCreateProposal() public {
        uint256 proposalId = governance.createProposal("Test", 100);
        assertEq(proposalId, 0);
    }

    function testVote() public {
        uint256 proposalId = governance.createProposal("Test", 100);
        governance.vote(proposalId, true);
        // Assertions
    }
}
```

**Substrate** :

```rust
#[cfg(test)]
mod tests {
    use super::*;
    use frame_support::{assert_ok, assert_noop};

    #[test]
    fn create_mission_works() {
        new_test_ext().execute_with(|| {
            assert_ok!(Marketplace::create_mission(
                RuntimeOrigin::signed(1),
                [1u8; 32],
                1000
            ));

            assert_eq!(Marketplace::next_mission_id(), 1);
        });
    }
}
```

---

### Integration Tests

**E2E workflows** :

```typescript
// tests/e2e/mission-lifecycle.test.ts
describe('Mission Lifecycle', () => {
  it('completes full mission flow', async () => {
    // 1. Create mission
    const createTx = await marketplace.createMission('Build website', 1000);
    const missionId = await extractMissionId(createTx);

    // 2. Match provider
    await marketplace.matchMission(missionId, { from: provider });

    // 3. Submit deliverable
    await marketplace.submitDeliverable(missionId, ipfsHash, { from: provider });

    // 4. Release payment
    await marketplace.releasePayment(missionId, { from: client });

    // Verify final state
    const mission = await marketplace.missions(missionId);
    expect(mission.status).toBe(Status.Completed);
  });
});
```

---

### Fuzzing

**Property-based testing** (Foundry invariants) :

```solidity
// test/invariants/MarketplaceInvariants.t.sol
contract MarketplaceInvariants is Test {
    Marketplace public marketplace;

    function setUp() public {
        marketplace = new Marketplace();
    }

    // Invariant: Total escrow == Sum of all mission budgets
    function invariant_escrowBalance() public {
        uint256 totalEscrow = address(marketplace).balance;
        uint256 sumBudgets = 0;

        for (uint256 i = 0; i < marketplace.missionCount(); i++) {
            Mission memory mission = marketplace.missions(i);
            if (mission.status != Status.Completed && mission.status != Status.Cancelled) {
                sumBudgets += mission.budget;
            }
        }

        assertEq(totalEscrow, sumBudgets, "Escrow mismatch");
    }
}
```

---

### Testnet Stress Testing

**Target** : 1000+ transactions.

```bash
# Solidity (Foundry)
forge script script/StressTest.s.sol \
    --rpc-url https://paseo-rpc.polkadot.io \
    --broadcast \
    --slow

# Substrate (Chopsticks)
chopsticks stress-test \
    --endpoint ws://localhost:9944 \
    --extrinsic marketplace.createMission \
    --count 1000 \
    --concurrency 10
```

---

## Références

**Substrate Security** :
- [Substrate Runtime Development Best Practices](https://docs.substrate.io/build/runtime-development/)
- [Weight Benchmarking Guide](https://docs.substrate.io/test/benchmark/)

**Solidity Security** :
- [OpenZeppelin Security Patterns](https://docs.openzeppelin.com/contracts/4.x/)
- [Solidity Security Best Practices](https://consensys.github.io/smart-contract-best-practices/)

**Testing** :
- [Foundry Book](https://book.getfoundry.sh/)
- [Substrate Test Utils](https://docs.substrate.io/test/)

**Auditors** :
- [Trail of Bits](https://www.trailofbits.com/)
- [Oak Security](https://www.oaksecurity.io/)
- [OpenZeppelin Defender](https://defender.openzeppelin.com/)

---

**Version** : 1.0.0
**Dernière mise à jour** : 2026-02-10
