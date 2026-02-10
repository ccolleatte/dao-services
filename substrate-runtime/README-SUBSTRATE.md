# DAO Services - Substrate Runtime

**Stack** : Substrate 1.14.0 (Polkadot 2.0 compatible)
**Runtime** : Custom pallets pour DAO marketplace IA/Humains

---

## Architecture

```
substrate-runtime/
├── node/              # Collator binary (block production)
├── runtime/           # Runtime logic (STF - State Transition Function)
├── pallets/          # Custom pallets (business logic)
│   ├── membership/    # Rôles et permissions (Initiate→Member→Core→Advisor)
│   ├── treasury/      # Paiements milestone-based
│   ├── governance/    # OpenGov 3 tracks (Technical/Treasury/Membership)
│   ├── marketplace/   # Mission lifecycle + escrow
│   └── payment-splitter/  # Splitting hybride AI/humains
└── Cargo.toml        # Workspace configuration
```

---

## Quick Start

### Prerequisites

```powershell
# Install Rust
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

# Add wasm32 target
rustup target add wasm32-unknown-unknown

# Install Substrate dependencies (Ubuntu/Debian)
sudo apt update
sudo apt install -y build-essential git clang curl libssl-dev llvm libudev-dev protobuf-compiler
```

### Build Runtime

```powershell
# Build release binary (optimized WASM)
cargo build --release

# Build development binary (faster compile)
cargo build
```

### Run Local Development Node

```powershell
# Start local node (development chain)
./target/release/dao-node --dev --tmp

# Alternative: Specify base path
./target/release/dao-node --dev --base-path=./chain-data
```

### Run Tests

```powershell
# Run all tests (unit + integration)
cargo test --workspace

# Run tests with benchmarks
cargo test --workspace --features runtime-benchmarks

# Run specific pallet tests
cargo test -p pallet-membership
cargo test -p pallet-governance
```

### Generate Chain Spec

```powershell
# Generate development chain spec
./target/release/dao-node build-spec --chain local > chain-spec-dev.json

# Convert to raw format (for deployment)
./target/release/dao-node build-spec --chain chain-spec-dev.json --raw > chain-spec-dev-raw.json
```

---

## Pallets Overview

### 1. pallet-membership (Foundation)

**Purpose** : Rôles et permissions rank-based

**Features** :
- 4 ranks : Initiate(1), Member(2), Core(3), Advisor(4)
- Voting weights : Linear par rank (1→1, 2→2, 3→3, 4→4)
- Suspension : 30-day cooldown
- Promote/demote : Rank-gated (Core+ only)

**Key extrinsics** :
```rust
pub fn add_member(origin, who: AccountId, rank: Rank)
pub fn promote(origin, who: AccountId)
pub fn suspend(origin, who: AccountId, reason: Vec<u8>)
pub fn reinstate(origin, who: AccountId)
```

**Storage** :
- `Members<T>`: AccountId → MemberInfo { rank, joinedAt, suspended }
- `TotalVotingWeight<T>`: Cached total for quorum

---

### 2. pallet-treasury (Milestone Payments)

**Purpose** : Paiements progressifs milestone-based

**Features** :
- Spending proposals avec milestones (approve individuellement)
- Emergency pause (governance-controlled)
- Treasury balance tracking
- Beneficiary validation

**Key extrinsics** :
```rust
pub fn propose_spending(origin, beneficiary: AccountId, amount: Balance, milestones: Vec<Milestone>)
pub fn approve_milestone(origin, proposal_id: u32, milestone_index: u8)
pub fn emergency_pause(origin)
```

**Storage** :
- `Proposals<T>`: ProposalId → TreasuryProposal
- `Milestones<T>`: MilestoneId → MilestoneInfo
- `TreasuryBalance<T>`: Cached balance

---

### 3. pallet-governance (OpenGov 3 Tracks)

**Purpose** : Gouvernance décentralisée OpenGov-inspired

**Features** :
- 3 tracks : Technical, Treasury, Membership
- Track-specific configs : minRank, votingDelay, votingPeriod, quorumPercent
- Rank-weighted voting (intégration pallet-membership)
- Proposal lifecycle : Proposed → Active → Succeeded/Defeated → Queued → Executed

**Key extrinsics** :
```rust
pub fn propose(origin, track: Track, calls: Vec<Call>, description_hash: Hash)
pub fn vote(origin, proposal_id: u32, support: bool)
pub fn execute(origin, proposal_id: u32)
```

**Storage** :
- `Proposals<T>`: ProposalId → GovernanceProposal
- `TrackConfigs<T>`: Track → TrackConfig
- `Votes<T>`: (ProposalId, AccountId) → VoteInfo

---

### 4. pallet-marketplace (Mission Lifecycle)

**Purpose** : Marketplace missions avec escrow

**Features** :
- Mission lifecycle : Created → Matched → InProgress → Completed → Paid
- Escrow automatique : Lock budget on creation, release on completion
- Multi-role : Client, Provider (AI/Human/Compute)
- Dispute resolution : Arbitration par Core+ members
- Service categories : Enum (Development, Design, Research, AI, Compute)

**Key extrinsics** :
```rust
pub fn create_mission(origin, description_hash: Hash, budget: Balance, category: ServiceCategory)
pub fn match_mission(origin, mission_id: u32, provider: AccountId)
pub fn complete_mission(origin, mission_id: u32)
pub fn release_payment(origin, mission_id: u32)
pub fn dispute_mission(origin, mission_id: u32, reason: Vec<u8>)
```

**Storage** :
- `Missions<T>`: MissionId → MissionInfo
- `Escrows<T>`: MissionId → EscrowInfo
- `ServiceProviders<T>`: AccountId → ProviderProfile

---

### 5. pallet-payment-splitter (Hybrid Payments)

**Purpose** : Splitting paiements AI/humains/compute

**Features** :
- Split payments entre multiple beneficiaries (configurable on-chain)
- Automatic distribution on mission completion
- Revenue tracking per beneficiary
- Predefined split templates (ex: "70% human, 30% AI")

**Key extrinsics** :
```rust
pub fn configure_split(origin, mission_id: u32, beneficiaries: Vec<(AccountId, Percent)>)
pub fn execute_split(origin, mission_id: u32, total_amount: Balance)
pub fn withdraw_revenue(origin, beneficiary: AccountId)
```

**Storage** :
- `PaymentSplits<T>`: MissionId → Vec<(AccountId, Percent)>
- `BeneficiaryRevenue<T>`: AccountId → TotalEarned
- `SplitConfigs<T>`: ConfigId → SplitTemplate

---

## Benchmarking & Optimization

### Run Benchmarks

```powershell
# Build with benchmarking features
cargo build --release --features runtime-benchmarks

# Run benchmarks for all pallets
./target/release/dao-node benchmark pallet \
    --chain dev \
    --pallet "*" \
    --extrinsic "*" \
    --steps 50 \
    --repeat 20 \
    --output pallets/weights/

# Benchmark specific pallet
./target/release/dao-node benchmark pallet \
    --chain dev \
    --pallet pallet_membership \
    --extrinsic "*" \
    --steps 50 \
    --repeat 20 \
    --output pallets/membership/src/weights.rs
```

### Weight Targets

| Operation | Target Weight | Rationale |
|-----------|---------------|-----------|
| create_mission | <50k | Fast mission creation (user-facing) |
| vote | <30k | High-frequency governance |
| approve_milestone | <40k | Treasury operations |
| execute_split | <60k | Multi-beneficiary computation |

---

## Testing Strategy

### Unit Tests

```rust
#[cfg(test)]
mod tests {
    use super::*;
    use frame_support::{assert_ok, assert_noop};
    use sp_runtime::DispatchError;

    #[test]
    fn create_mission_works() {
        new_test_ext().execute_with(|| {
            assert_ok!(Marketplace::create_mission(
                RuntimeOrigin::signed(ALICE),
                Hash::default(),
                1000,
                ServiceCategory::Development
            ));

            assert_eq!(Missions::<Test>::iter().count(), 1);
        });
    }
}
```

### Integration Tests

```rust
// tests/integration_governance.rs
#[test]
fn governance_e2e_workflow() {
    new_test_ext().execute_with(|| {
        // 1. Create proposal (Technical track)
        assert_ok!(Governance::propose(
            RuntimeOrigin::signed(ALICE),
            Track::Technical,
            vec![...],
            Hash::default()
        ));

        // 2. Vote (rank-weighted)
        assert_ok!(Governance::vote(RuntimeOrigin::signed(BOB), 0, true));

        // 3. Execute (after passing)
        run_to_block(100); // Wait voting period
        assert_ok!(Governance::execute(RuntimeOrigin::signed(ALICE), 0));
    });
}
```

### Coverage Targets

- **Lines** : 80%+
- **Branches** : 70%+
- **Critical paths** : 100%

---

## Deployment

### Paseo Testnet

```powershell
# 1. Build release binary
cargo build --release --features runtime-benchmarks

# 2. Generate Paseo chain spec
./target/release/dao-node build-spec --chain paseo > chain-spec-paseo.json

# 3. Convert to raw
./target/release/dao-node build-spec --chain chain-spec-paseo.json --raw > chain-spec-paseo-raw.json

# 4. Start collator
./target/release/dao-node \
    --collator \
    --chain chain-spec-paseo-raw.json \
    --rpc-cors all \
    --rpc-port 9944 \
    --port 30333

# 5. Get testnet tokens
# Visit: https://faucet.polkadot.io/
```

### Mainnet (Future)

**Prerequisites** :
- Security audit (Oak Security or Trail of Bits)
- Testnet validation (2+ weeks, 1000+ transactions)
- Community testing program
- Treasury allocation (initial liquidity)

**Deployment path** :
1. Paseo testnet (2-4 weeks)
2. Security audit (4-6 weeks)
3. Mainnet deployment via governance proposal
4. Parachain evaluation (if >100 missions/day)

---

## Troubleshooting

### Build Errors

**Error** : `error: linker 'cc' not found`
```powershell
# Install build tools
sudo apt install build-essential
```

**Error** : `could not find native static library 'protobuf'`
```powershell
# Install protobuf
sudo apt install protobuf-compiler
```

### Runtime Errors

**Error** : `Module error: 0`
- Check extrinsic parameters match pallet Config
- Verify origin has required permissions

**Error** : `BadOrigin`
- Extrinsic requires specific rank (e.g., Core+)
- Use sudo for testing: `sudo.sudo(call)`

---

## Resources

**Official Documentation** :
- [Substrate Docs](https://docs.substrate.io/)
- [Polkadot Wiki](https://wiki.polkadot.network/)
- [Rust Book](https://doc.rust-lang.org/book/)

**Development Tools** :
- [Polkadot.js Apps](https://polkadot.js.org/apps/)
- [Subscan](https://www.subscan.io/)
- [Chopsticks](https://github.com/AcalaNetwork/chopsticks) (fork Polkadot locally)

**Community** :
- [Substrate Stack Exchange](https://substrate.stackexchange.com/)
- [Polkadot Forum](https://forum.polkadot.network/)
- [Element](https://matrix.to/#/#substrate-technical:matrix.org)

---

**Version** : 1.0.0
**Last Updated** : 2026-02-10
**Status** : In Development (Phase 1 - Runtime Setup Complete)
