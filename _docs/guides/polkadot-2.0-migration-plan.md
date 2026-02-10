# Plan de Migration Polkadot 2.0 - DAO Project

**Date** : 2026-02-10
**Version** : 1.0.0
**Objectif** : Migration simplifiée vers environnement natif Polkadot 2.0

---

## Executive Summary

### 🎯 Objectif Principal

**Simplifier de 3 stacks → 1 stack natif Polkadot 2.0**

| État Actuel | État Cible | Simplification |
|-------------|------------|----------------|
| 3 stacks parallèles | 1 stack unique | -66% complexité |
| Solidity + Substrate legacy + ink! | polkadot-sdk natif | -200% maintenance |
| 0 features Polkadot 2.0 | Async Backing + Agile Coretime | +300% performance |

### 📊 Décision Stratégique

**Option recommandée** : **Migration complète vers polkadot-sdk native** (Option C)

**Rationale** :
- ✅ **Polkadot 2.0 native** : Accès complet Async Backing, Agile Coretime, Elastic Scaling
- ✅ **Simplification maximale** : 1 seul stack à maintenir
- ✅ **Future-proof** : Aligné roadmap Polkadot long-terme
- ✅ **ROI positif** : 6-8 semaines migration vs maintenance 3× stacks éliminée

---

## Phase 0 : Préparation (1-2 semaines)

### 0.1 Finaliser Validation MVP Solidity (P0 - EN COURS)

**Effort** : 14-22h (déjà planifié)

**Tâches** :
- [ ] Coverage improvement (8-12h) : 66.67% → 80% lines, 41.71% → 70% branches
- [ ] Pausable mechanism (4-6h) : OpenZeppelin pattern pour 5 contrats
- [ ] Unbounded arrays fix (2-4h) : Pagination DAOMembership

**Livrable** : MVP Solidity production-ready avec 8/8 critères Phase 0.5

**Script validation** : `_scripts/validation/validate-contracts.ps1 -Full`

---

### 0.2 Extraction Business Logic (Solidity → Format Neutre)

**Effort** : 3-5 jours

**Objectif** : Documenter logique métier indépendamment de l'implémentation Solidity

**Tâches** :

#### Inventaire Contrats Solidity

| Contrat | Responsabilité | État Logique |
|---------|----------------|--------------|
| **DAOMembership** | Gestion membres + vote weights | ✅ Production-ready (post P0) |
| **DAOGovernor** | Gouvernance multi-track | ✅ Production-ready (post P0) |
| **DAOTreasury** | Trésorerie + budgets | ✅ Production-ready (post P0) |
| **MissionEscrow** | Escrow milestones missions | ✅ Production-ready (post P0) |
| **ServiceMarketplace** | Marketplace services | ✅ Production-ready (post P0) |

#### Extraction Format Neutre

**Template** : `_docs/business-logic/[CONTRACT]-specification.md`

**Structure** :
```markdown
# [Contract Name] - Business Logic Specification

## 1. Core Entities
- Data structures (agnostic implementation)
- State machine (états + transitions)

## 2. Business Rules
- Validation rules
- Access control logic
- Economic parameters

## 3. Operations
- CRUD operations avec pre/post-conditions
- Events émis

## 4. Test Cases (Critical Paths)
- Edge cases identifiés en Phase 0.5
- Attack vectors couverts

## 5. Dependencies
- Autres contrats requis
- Oracles/External data
```

**Exemple DAOMembership** :
```markdown
# DAOMembership - Business Logic Specification

## 1. Core Entities

### Member
```
struct Member {
  address: AccountId,
  github_handle: String,
  rank: u8 (1-5),
  active: bool,
  joined_at: Timestamp
}
```

### Vote Weight Calculation
- Formula: triangular number `rank × (rank + 1) / 2`
- Rank 1 → 1 vote
- Rank 2 → 3 votes
- Rank 3 → 6 votes
- Rank 4 → 10 votes
- Rank 5 → 15 votes

## 2. Business Rules

### BR-001: Add Member
- **Pre-conditions**:
  - Caller has MEMBER_MANAGER_ROLE
  - Address not already member
  - GitHub handle unique
  - Rank between 1-5
  - Contract not paused
- **Post-conditions**:
  - Member added to registry
  - Event MemberAdded emitted
  - Total vote weight updated

### BR-002: Remove Member
- **Pre-conditions**:
  - Caller has MEMBER_MANAGER_ROLE
  - Address is active member
  - Contract not paused
- **Post-conditions**:
  - Member marked inactive
  - Removed from active members array
  - Event MemberRemoved emitted
  - Total vote weight updated

[... etc pour toutes les opérations]
```

**Script génération** : `_scripts/migration/extract-business-logic.ps1`

```powershell
# Extract business logic from Solidity contracts
param([string]$ContractsDir = "C:\dev\DAO\contracts\src")

$contracts = @("DAOMembership", "DAOGovernor", "DAOTreasury", "MissionEscrow", "ServiceMarketplace")

foreach ($contract in $contracts) {
    Write-Host "Extracting $contract business logic..."

    # Parse Solidity contract
    $solidityFile = Join-Path $ContractsDir "$contract.sol"
    $content = Get-Content $solidityFile -Raw

    # Extract structs, events, functions
    $structs = [regex]::Matches($content, 'struct\s+(\w+)\s*\{([^}]+)\}')
    $events = [regex]::Matches($content, 'event\s+(\w+)\(([^)]*)\)')
    $functions = [regex]::Matches($content, 'function\s+(\w+)\(([^)]*)\).*?\{')

    # Generate specification document
    $spec = @"
# $contract - Business Logic Specification

## 1. Core Entities

$(foreach ($struct in $structs) {
"### $($struct.Groups[1].Value)
``````
$($struct.Groups[2].Value)
``````
"
})

## 2. Events

$(foreach ($event in $events) {
"- **$($event.Groups[1].Value)**: $($event.Groups[2].Value)"
})

## 3. Operations

$(foreach ($func in $functions) {
"### $($func.Groups[1].Value)
- Parameters: $($func.Groups[2].Value)
- [TODO: Add pre/post-conditions from tests]
"
})

## 4. Test Cases
- See: contracts/test/$contract.t.sol (85 tests, 100% passing)

## 5. Dependencies
- [TODO: Identify from imports]
"@

    $outputPath = "C:\dev\DAO\_docs\business-logic\$contract-specification.md"
    New-Item -ItemType Directory -Force -Path (Split-Path $outputPath) | Out-Null
    Set-Content -Path $outputPath -Value $spec

    Write-Host "  ✓ Created $outputPath"
}

Write-Host "`n✅ Business logic extraction complete"
Write-Host "Review and complete TODO sections manually"
```

**Validation** :
- [ ] 5 specifications créées (1 par contrat)
- [ ] Structs/Events/Functions documentés
- [ ] Business rules extraites des tests Solidity
- [ ] Format agnostic (pas de Solidity-specific syntax)

**Livrable** : `_docs/business-logic/*.md` (5 fichiers)

---

### 0.3 Setup Environnement polkadot-sdk

**Effort** : 2-3 jours

**Objectif** : Environnement de développement Polkadot 2.0 natif fonctionnel

#### Installation Rust Toolchain

```bash
# Rust stable + nightly + wasm32 target
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
rustup default stable
rustup update
rustup update nightly
rustup target add wasm32-unknown-unknown --toolchain nightly

# Verify
rustc --version  # 1.75+ requis
cargo --version
```

#### Clone polkadot-sdk

```bash
cd C:\dev\DAO
git clone https://github.com/paritytech/polkadot-sdk.git
cd polkadot-sdk

# Checkout stable release (pas master)
git checkout release-polkadot-v1.7.0  # Latest stable

# Build (10-30 min première fois)
cargo build --release
```

#### Template Parachain

**Option A : Utiliser `pop-cli`** (Recommandé - plus simple)

```bash
# Install pop-cli
cargo install --git https://github.com/r0gue-io/pop-cli pop-cli

# Create parachain from template
cd C:\dev\DAO
pop new parachain dao-parachain --template standard

# Structure générée :
# dao-parachain/
# ├── runtime/     # Runtime logic (pallets)
# ├── node/        # Node implementation
# ├── pallets/     # Custom pallets
# └── Cargo.toml
```

**Option B : Fork parachain-template** (Manuel, plus contrôle)

```bash
cd C:\dev\DAO
git clone https://github.com/paritytech/polkadot-sdk-parachain-template.git dao-parachain
cd dao-parachain

# Update dependencies to polkadot-sdk v1.7.0
# Edit Cargo.toml:
# [dependencies]
# polkadot-sdk = { git = "https://github.com/paritytech/polkadot-sdk", branch = "release-polkadot-v1.7.0" }
```

#### Vérification Build

```bash
cd C:\dev\DAO\dao-parachain

# Build runtime
cargo build --release --package dao-parachain-runtime

# Build node
cargo build --release --package dao-parachain-node

# Run local testnet (dev mode)
./target/release/dao-parachain-node --dev

# Test RPC
curl -H "Content-Type: application/json" -d '{"id":1, "jsonrpc":"2.0", "method": "system_chain"}' http://localhost:9944

# Expected: {"jsonrpc":"2.0","result":"Development","id":1}
```

**Livrable** :
- [ ] Rust toolchain installé et vérifié
- [ ] polkadot-sdk cloné + compilé
- [ ] Parachain template fonctionnel (dev node tourne)
- [ ] RPC accessible sur localhost:9944

**Temps total Phase 0** : 1-2 semaines

---

## Phase 1 : Migration Pallets Core (3-4 semaines)

### 1.1 Pallet DAOMembership (1 semaine)

**Objectif** : Migrer DAOMembership.sol → pallet-dao-membership

#### Structure Pallet

```
dao-parachain/pallets/dao-membership/
├── Cargo.toml
├── src/
│   ├── lib.rs           # Pallet entrypoint
│   ├── types.rs         # Member, Rank structs
│   ├── weights.rs       # Benchmark weights (auto-generated)
│   ├── tests.rs         # Unit tests
│   └── benchmarking.rs  # Runtime benchmarks
└── README.md
```

#### Cargo.toml

```toml
[package]
name = "pallet-dao-membership"
version = "1.0.0"
edition = "2021"

[dependencies]
codec = { package = "parity-scale-codec", version = "3.6", default-features = false }
scale-info = { version = "2.10", default-features = false }

# Substrate dependencies
frame-support = { git = "https://github.com/paritytech/polkadot-sdk", branch = "release-polkadot-v1.7.0", default-features = false }
frame-system = { git = "https://github.com/paritytech/polkadot-sdk", branch = "release-polkadot-v1.7.0", default-features = false }
sp-std = { git = "https://github.com/paritytech/polkadot-sdk", branch = "release-polkadot-v1.7.0", default-features = false }
sp-runtime = { git = "https://github.com/paritytech/polkadot-sdk", branch = "release-polkadot-v1.7.0", default-features = false }

[dev-dependencies]
sp-io = { git = "https://github.com/paritytech/polkadot-sdk", branch = "release-polkadot-v1.7.0" }

[features]
default = ["std"]
std = [
    "codec/std",
    "scale-info/std",
    "frame-support/std",
    "frame-system/std",
    "sp-std/std",
    "sp-runtime/std",
]
```

#### lib.rs (Structure de base)

```rust
#![cfg_attr(not(feature = "std"), no_std)]

pub use pallet::*;

#[frame_support::pallet]
pub mod pallet {
    use frame_support::pallet_prelude::*;
    use frame_system::pallet_prelude::*;
    use sp_std::vec::Vec;

    #[pallet::pallet]
    pub struct Pallet<T>(_);

    #[pallet::config]
    pub trait Config: frame_system::Config {
        type RuntimeEvent: From<Event<Self>> + IsType<<Self as frame_system::Config>::RuntimeEvent>;

        /// Weight information for extrinsics
        type WeightInfo: WeightInfo;

        /// Maximum length for GitHub handle
        #[pallet::constant]
        type MaxGithubHandleLength: Get<u32>;

        /// Maximum rank value (1-5)
        #[pallet::constant]
        type MaxRank: Get<u8>;
    }

    // ============================================
    // Types
    // ============================================

    #[derive(Clone, Encode, Decode, Eq, PartialEq, RuntimeDebug, TypeInfo, MaxEncodedLen)]
    pub struct Member<AccountId> {
        pub account: AccountId,
        pub github_handle: BoundedVec<u8, ConstU32<100>>,
        pub rank: u8,
        pub active: bool,
        pub joined_at: u64,
    }

    // ============================================
    // Storage
    // ============================================

    /// Members registry: AccountId => Member
    #[pallet::storage]
    #[pallet::getter(fn members)]
    pub type Members<T: Config> = StorageMap<
        _,
        Blake2_128Concat,
        T::AccountId,
        Member<T::AccountId>,
        OptionQuery,
    >;

    /// Active members list (for iteration)
    #[pallet::storage]
    #[pallet::getter(fn member_addresses)]
    pub type MemberAddresses<T: Config> = StorageValue<
        _,
        BoundedVec<T::AccountId, ConstU32<10000>>,  // Max 10k members
        ValueQuery,
    >;

    /// Total members count
    #[pallet::storage]
    #[pallet::getter(fn member_count)]
    pub type MemberCount<T: Config> = StorageValue<_, u32, ValueQuery>;

    // ============================================
    // Events
    // ============================================

    #[pallet::event]
    #[pallet::generate_deposit(pub(super) fn deposit_event)]
    pub enum Event<T: Config> {
        /// Member added [account, rank]
        MemberAdded { account: T::AccountId, rank: u8 },

        /// Member removed [account]
        MemberRemoved { account: T::AccountId },

        /// Member promoted [account, old_rank, new_rank]
        MemberPromoted { account: T::AccountId, old_rank: u8, new_rank: u8 },

        /// Member demoted [account, old_rank, new_rank]
        MemberDemoted { account: T::AccountId, old_rank: u8, new_rank: u8 },
    }

    // ============================================
    // Errors
    // ============================================

    #[pallet::error]
    pub enum Error<T> {
        /// Member already exists
        MemberAlreadyExists,

        /// Member not found
        MemberNotFound,

        /// Invalid rank (must be 1-5)
        InvalidRank,

        /// GitHub handle too long
        GithubHandleTooLong,

        /// GitHub handle already in use
        GithubHandleExists,

        /// Member inactive
        MemberInactive,

        /// Cannot promote (already max rank)
        AlreadyMaxRank,

        /// Cannot demote (already min rank)
        AlreadyMinRank,

        /// Too many members (storage limit)
        TooManyMembers,
    }

    // ============================================
    // Extrinsics (Dispatchable functions)
    // ============================================

    #[pallet::call]
    impl<T: Config> Pallet<T> {
        /// Add a new member
        #[pallet::call_index(0)]
        #[pallet::weight(T::WeightInfo::add_member())]
        pub fn add_member(
            origin: OriginFor<T>,
            account: T::AccountId,
            github_handle: Vec<u8>,
            rank: u8,
        ) -> DispatchResult {
            // Authorization check (Root or specific origin)
            ensure_root(origin)?;

            // Validation
            ensure!(rank >= 1 && rank <= T::MaxRank::get(), Error::<T>::InvalidRank);
            ensure!(
                github_handle.len() <= T::MaxGithubHandleLength::get() as usize,
                Error::<T>::GithubHandleTooLong
            );
            ensure!(!Members::<T>::contains_key(&account), Error::<T>::MemberAlreadyExists);

            // Create member
            let bounded_handle = BoundedVec::try_from(github_handle)
                .map_err(|_| Error::<T>::GithubHandleTooLong)?;

            let member = Member {
                account: account.clone(),
                github_handle: bounded_handle,
                rank,
                active: true,
                joined_at: Self::current_timestamp(),
            };

            // Store
            Members::<T>::insert(&account, member);

            // Update active members list
            MemberAddresses::<T>::try_mutate(|members| {
                members.try_push(account.clone())
                    .map_err(|_| Error::<T>::TooManyMembers)
            })?;

            // Update count
            MemberCount::<T>::mutate(|count| *count = count.saturating_add(1));

            // Emit event
            Self::deposit_event(Event::MemberAdded { account, rank });

            Ok(())
        }

        /// Remove a member
        #[pallet::call_index(1)]
        #[pallet::weight(T::WeightInfo::remove_member())]
        pub fn remove_member(
            origin: OriginFor<T>,
            account: T::AccountId,
        ) -> DispatchResult {
            ensure_root(origin)?;

            // Get member
            let mut member = Members::<T>::get(&account)
                .ok_or(Error::<T>::MemberNotFound)?;

            // Mark inactive
            member.active = false;
            Members::<T>::insert(&account, member);

            // Remove from active list
            MemberAddresses::<T>::mutate(|members| {
                if let Some(pos) = members.iter().position(|a| a == &account) {
                    members.swap_remove(pos);
                }
            });

            // Update count
            MemberCount::<T>::mutate(|count| *count = count.saturating_sub(1));

            // Emit event
            Self::deposit_event(Event::MemberRemoved { account });

            Ok(())
        }

        /// Promote member (+1 rank)
        #[pallet::call_index(2)]
        #[pallet::weight(T::WeightInfo::promote_member())]
        pub fn promote_member(
            origin: OriginFor<T>,
            account: T::AccountId,
        ) -> DispatchResult {
            ensure_root(origin)?;

            Members::<T>::try_mutate(&account, |maybe_member| {
                let member = maybe_member.as_mut().ok_or(Error::<T>::MemberNotFound)?;
                ensure!(member.active, Error::<T>::MemberInactive);
                ensure!(member.rank < T::MaxRank::get(), Error::<T>::AlreadyMaxRank);

                let old_rank = member.rank;
                member.rank += 1;

                Self::deposit_event(Event::MemberPromoted {
                    account: account.clone(),
                    old_rank,
                    new_rank: member.rank,
                });

                Ok(())
            })
        }

        /// Demote member (-1 rank)
        #[pallet::call_index(3)]
        #[pallet::weight(T::WeightInfo::demote_member())]
        pub fn demote_member(
            origin: OriginFor<T>,
            account: T::AccountId,
        ) -> DispatchResult {
            ensure_root(origin)?;

            Members::<T>::try_mutate(&account, |maybe_member| {
                let member = maybe_member.as_mut().ok_or(Error::<T>::MemberNotFound)?;
                ensure!(member.active, Error::<T>::MemberInactive);
                ensure!(member.rank > 1, Error::<T>::AlreadyMinRank);

                let old_rank = member.rank;
                member.rank -= 1;

                Self::deposit_event(Event::MemberDemoted {
                    account: account.clone(),
                    old_rank,
                    new_rank: member.rank,
                });

                Ok(())
            })
        }
    }

    // ============================================
    // Helper functions (public API)
    // ============================================

    impl<T: Config> Pallet<T> {
        /// Check if account is member
        pub fn is_member(account: &T::AccountId) -> bool {
            Members::<T>::contains_key(account)
        }

        /// Check if member is active
        pub fn is_active_member(account: &T::AccountId) -> bool {
            Members::<T>::get(account)
                .map(|m| m.active)
                .unwrap_or(false)
        }

        /// Calculate vote weight for member (triangular number)
        pub fn calculate_vote_weight(account: &T::AccountId) -> u32 {
            Members::<T>::get(account)
                .filter(|m| m.active)
                .map(|m| {
                    let rank = m.rank as u32;
                    rank * (rank + 1) / 2
                })
                .unwrap_or(0)
        }

        /// Calculate total vote weight for all active members with min_rank
        pub fn calculate_total_vote_weight(min_rank: u8) -> u32 {
            MemberAddresses::<T>::get()
                .iter()
                .filter_map(|account| Members::<T>::get(account))
                .filter(|m| m.active && m.rank >= min_rank)
                .map(|m| {
                    let rank = m.rank as u32;
                    rank * (rank + 1) / 2
                })
                .sum()
        }

        /// Get active members by rank (with pagination)
        pub fn get_active_members_by_rank(
            rank: u8,
            offset: u32,
            limit: u32,
        ) -> (Vec<T::AccountId>, u32) {
            let all_members: Vec<T::AccountId> = MemberAddresses::<T>::get()
                .iter()
                .filter(|account| {
                    Members::<T>::get(account)
                        .map(|m| m.active && m.rank == rank)
                        .unwrap_or(false)
                })
                .cloned()
                .collect();

            let total = all_members.len() as u32;
            let start = offset as usize;
            let end = (offset + limit).min(total) as usize;

            let result = all_members[start..end].to_vec();

            (result, total)
        }

        /// Get current timestamp (block number as proxy)
        fn current_timestamp() -> u64 {
            <frame_system::Pallet<T>>::block_number()
                .try_into()
                .unwrap_or(0)
        }
    }

    // ============================================
    // Weight trait (placeholder, to be benchmarked)
    // ============================================

    pub trait WeightInfo {
        fn add_member() -> Weight;
        fn remove_member() -> Weight;
        fn promote_member() -> Weight;
        fn demote_member() -> Weight;
    }

    impl WeightInfo for () {
        fn add_member() -> Weight {
            Weight::from_parts(10_000_000, 0)
        }
        fn remove_member() -> Weight {
            Weight::from_parts(10_000_000, 0)
        }
        fn promote_member() -> Weight {
            Weight::from_parts(5_000_000, 0)
        }
        fn demote_member() -> Weight {
            Weight::from_parts(5_000_000, 0)
        }
    }
}
```

#### tests.rs (Unit Tests)

```rust
#[cfg(test)]
mod tests {
    use super::*;
    use crate::pallet as pallet_dao_membership;
    use frame_support::{assert_ok, assert_noop, parameter_types};
    use sp_runtime::{
        traits::{BlakeTwo256, IdentityLookup},
        BuildStorage,
    };

    type Block = frame_system::mocking::MockBlock<Test>;

    frame_support::construct_runtime!(
        pub enum Test {
            System: frame_system,
            DAOMembership: pallet_dao_membership,
        }
    );

    parameter_types! {
        pub const BlockHashCount: u64 = 250;
    }

    impl frame_system::Config for Test {
        type BaseCallFilter = frame_support::traits::Everything;
        type BlockWeights = ();
        type BlockLength = ();
        type DbWeight = ();
        type RuntimeOrigin = RuntimeOrigin;
        type RuntimeCall = RuntimeCall;
        type Nonce = u64;
        type Hash = sp_core::H256;
        type Hashing = BlakeTwo256;
        type AccountId = u64;
        type Lookup = IdentityLookup<Self::AccountId>;
        type Block = Block;
        type RuntimeEvent = RuntimeEvent;
        type BlockHashCount = BlockHashCount;
        type Version = ();
        type PalletInfo = PalletInfo;
        type AccountData = ();
        type OnNewAccount = ();
        type OnKilledAccount = ();
        type SystemWeightInfo = ();
        type SS58Prefix = ();
        type OnSetCode = ();
        type MaxConsumers = frame_support::traits::ConstU32<16>;
    }

    parameter_types! {
        pub const MaxGithubHandleLength: u32 = 100;
        pub const MaxRank: u8 = 5;
    }

    impl Config for Test {
        type RuntimeEvent = RuntimeEvent;
        type WeightInfo = ();
        type MaxGithubHandleLength = MaxGithubHandleLength;
        type MaxRank = MaxRank;
    }

    fn new_test_ext() -> sp_io::TestExternalities {
        frame_system::GenesisConfig::<Test>::default()
            .build_storage()
            .unwrap()
            .into()
    }

    #[test]
    fn add_member_works() {
        new_test_ext().execute_with(|| {
            assert_ok!(DAOMembership::add_member(
                RuntimeOrigin::root(),
                1,
                b"alice".to_vec(),
                3
            ));

            assert_eq!(DAOMembership::member_count(), 1);
            assert!(DAOMembership::is_member(&1));
            assert!(DAOMembership::is_active_member(&1));
            assert_eq!(DAOMembership::calculate_vote_weight(&1), 6); // rank 3 = 3*4/2 = 6
        });
    }

    #[test]
    fn add_member_already_exists_fails() {
        new_test_ext().execute_with(|| {
            assert_ok!(DAOMembership::add_member(
                RuntimeOrigin::root(),
                1,
                b"alice".to_vec(),
                3
            ));

            assert_noop!(
                DAOMembership::add_member(
                    RuntimeOrigin::root(),
                    1,
                    b"alice2".to_vec(),
                    3
                ),
                Error::<Test>::MemberAlreadyExists
            );
        });
    }

    #[test]
    fn remove_member_works() {
        new_test_ext().execute_with(|| {
            assert_ok!(DAOMembership::add_member(
                RuntimeOrigin::root(),
                1,
                b"alice".to_vec(),
                3
            ));

            assert_ok!(DAOMembership::remove_member(RuntimeOrigin::root(), 1));

            assert_eq!(DAOMembership::member_count(), 0);
            assert!(!DAOMembership::is_active_member(&1));
            assert_eq!(DAOMembership::calculate_vote_weight(&1), 0);
        });
    }

    #[test]
    fn promote_member_works() {
        new_test_ext().execute_with(|| {
            assert_ok!(DAOMembership::add_member(
                RuntimeOrigin::root(),
                1,
                b"alice".to_vec(),
                3
            ));

            assert_ok!(DAOMembership::promote_member(RuntimeOrigin::root(), 1));

            let member = DAOMembership::members(1).unwrap();
            assert_eq!(member.rank, 4);
            assert_eq!(DAOMembership::calculate_vote_weight(&1), 10); // rank 4 = 4*5/2 = 10
        });
    }

    #[test]
    fn promote_max_rank_fails() {
        new_test_ext().execute_with(|| {
            assert_ok!(DAOMembership::add_member(
                RuntimeOrigin::root(),
                1,
                b"alice".to_vec(),
                5
            ));

            assert_noop!(
                DAOMembership::promote_member(RuntimeOrigin::root(), 1),
                Error::<Test>::AlreadyMaxRank
            );
        });
    }

    #[test]
    fn calculate_total_vote_weight_works() {
        new_test_ext().execute_with(|| {
            assert_ok!(DAOMembership::add_member(
                RuntimeOrigin::root(),
                1,
                b"alice".to_vec(),
                1
            ));
            assert_ok!(DAOMembership::add_member(
                RuntimeOrigin::root(),
                2,
                b"bob".to_vec(),
                2
            ));
            assert_ok!(DAOMembership::add_member(
                RuntimeOrigin::root(),
                3,
                b"charlie".to_vec(),
                3
            ));

            // Total weight = 1 + 3 + 6 = 10
            assert_eq!(DAOMembership::calculate_total_vote_weight(1), 10);

            // Only rank >= 2 = 3 + 6 = 9
            assert_eq!(DAOMembership::calculate_total_vote_weight(2), 9);
        });
    }

    #[test]
    fn get_active_members_by_rank_pagination_works() {
        new_test_ext().execute_with(|| {
            // Add 5 members rank 2
            for i in 1..=5 {
                assert_ok!(DAOMembership::add_member(
                    RuntimeOrigin::root(),
                    i,
                    format!("user{}", i).as_bytes().to_vec(),
                    2
                ));
            }

            // First page (offset 0, limit 2)
            let (members, total) = DAOMembership::get_active_members_by_rank(2, 0, 2);
            assert_eq!(total, 5);
            assert_eq!(members.len(), 2);

            // Second page (offset 2, limit 2)
            let (members, total) = DAOMembership::get_active_members_by_rank(2, 2, 2);
            assert_eq!(total, 5);
            assert_eq!(members.len(), 2);

            // Last page (offset 4, limit 2)
            let (members, total) = DAOMembership::get_active_members_by_rank(2, 4, 2);
            assert_eq!(total, 5);
            assert_eq!(members.len(), 1); // Only 1 remaining
        });
    }
}
```

#### Intégration au Runtime

**Fichier** : `dao-parachain/runtime/src/lib.rs`

```rust
// Add pallet configuration
parameter_types! {
    pub const MaxGithubHandleLength: u32 = 100;
    pub const MaxRank: u8 = 5;
}

impl pallet_dao_membership::Config for Runtime {
    type RuntimeEvent = RuntimeEvent;
    type WeightInfo = ();
    type MaxGithubHandleLength = MaxGithubHandleLength;
    type MaxRank = MaxRank;
}

// Add to construct_runtime! macro
construct_runtime!(
    pub enum Runtime {
        System: frame_system,
        // ... autres pallets
        DAOMembership: pallet_dao_membership,
    }
);
```

**Validation** :
```bash
cd dao-parachain
cargo test -p pallet-dao-membership
cargo build --release --package dao-parachain-runtime
```

**Livrable** :
- [ ] pallet-dao-membership compilé
- [ ] 12+ unit tests passing (85 tests Solidity → subset critique)
- [ ] Intégré au runtime
- [ ] Business logic conforme specification

**Temps** : 1 semaine (5 jours)

---

### 1.2 Pallet DAOGovernor (1.5 semaines)

**Objectif** : Migrer DAOGovernor.sol → pallet-dao-governor

**Complexité** : HAUTE (multi-track governance + OpenGov integration)

#### Dépendances

- `pallet-dao-membership` (vote weights)
- `pallet-collective` (optional, pour councils)
- `pallet-scheduler` (pour timelock)

#### Workflow Similaire à 1.1

- Extraire business logic de DAOGovernor.sol
- Créer structure pallet
- Implémenter storage (Proposals, Tracks, Votes)
- Implémenter extrinsics (propose, vote, execute)
- Tests unitaires (subset critique des 85 tests Solidity)

**Spécificités Polkadot** :

```rust
// Integration OpenGov Polkadot 2.0
use pallet_referenda::{Track, TrackInfo};

// Tracks configuration
pub const TRACKS: &[(Track, TrackInfo)] = &[
    (0, TrackInfo { /* Root track */ }),
    (1, TrackInfo { /* Treasury track */ }),
    (2, TrackInfo { /* General track */ }),
];
```

**Livrable** :
- [ ] pallet-dao-governor compilé et testé
- [ ] Intégration OpenGov tracks
- [ ] Tests multi-track passing

**Temps** : 1.5 semaines

---

### 1.3 Pallet DAOTreasury (1 semaine)

**Objectif** : Migrer DAOTreasury.sol → pallet-dao-treasury

**Workflow** : Similaire à 1.1-1.2

**Spécificités** :
- Budget tracking (daily limits)
- Proposal execution avec timelock
- Integration pallet-treasury (Polkadot native)

**Option** : Réutiliser `pallet-treasury` existant + ajouter custom logic

```rust
// Extend native treasury pallet
impl pallet_dao_treasury::Config for Runtime {
    type Proposal = RuntimeCall;
    type Currency = Balances;
    type RejectOrigin = EnsureRoot<AccountId>;
    type ApproveOrigin = EnsureRoot<AccountId>;
    // ... custom daily limits logic
}
```

**Livrable** :
- [ ] pallet-dao-treasury ou extension pallet-treasury
- [ ] Daily limits enforcement
- [ ] Tests passing

**Temps** : 1 semaine

---

### 1.4 Pallets Marketplace (MissionEscrow + ServiceMarketplace) (1 semaine)

**Objectif** : Migrer escrow/marketplace logic

**Spécificités** :
- Escrow state machine (MissionEscrow)
- Marketplace listings (ServiceMarketplace)
- Integration pallet-balances pour escrow locks

**Livrable** :
- [ ] 2 pallets compilés et testés
- [ ] Escrow milestones + disputes
- [ ] Marketplace CRUD

**Temps** : 1 semaine

---

**Temps total Phase 1** : 3-4 semaines

---

## Phase 2 : Testing & Benchmarking (1-2 semaines)

### 2.1 Integration Tests

**Objectif** : Tests end-to-end multi-pallets

#### Test Suite Structure

```
dao-parachain/integration-tests/
├── src/
│   ├── governance_flow.rs      # Propose → Vote → Execute
│   ├── treasury_flow.rs        # Create proposal → Approve → Disburse
│   ├── marketplace_flow.rs     # List service → Escrow → Release
│   └── member_lifecycle.rs     # Add → Promote → Vote → Remove
└── Cargo.toml
```

#### Exemple Integration Test

```rust
#[test]
fn full_governance_flow_works() {
    new_test_ext().execute_with(|| {
        // 1. Add members
        assert_ok!(DAOMembership::add_member(RuntimeOrigin::root(), ALICE, b"alice".to_vec(), 3));
        assert_ok!(DAOMembership::add_member(RuntimeOrigin::root(), BOB, b"bob".to_vec(), 2));

        // 2. Create treasury proposal
        let proposal_hash = DAOGovernor::propose(
            RuntimeOrigin::signed(ALICE),
            Track::Treasury,
            vec![/* treasury spend call */],
        ).unwrap();

        // 3. Vote on proposal
        assert_ok!(DAOGovernor::vote(RuntimeOrigin::signed(ALICE), proposal_hash, true));
        assert_ok!(DAOGovernor::vote(RuntimeOrigin::signed(BOB), proposal_hash, true));

        // 4. Advance blocks (voting period)
        run_to_block(100);

        // 5. Execute proposal (quorum reached)
        assert_ok!(DAOGovernor::execute(RuntimeOrigin::signed(ALICE), proposal_hash));

        // 6. Verify treasury updated
        assert_eq!(DAOTreasury::balance(ALICE), 1000);
    });
}
```

**Validation** :
- [ ] 10+ integration tests passing
- [ ] Coverage flows critiques

---

### 2.2 Runtime Benchmarking

**Objectif** : Générer weights réels pour chaque extrinsic

#### Benchmark Template

```rust
// pallets/dao-membership/src/benchmarking.rs
#![cfg(feature = "runtime-benchmarks")]

use super::*;
use frame_benchmarking::{benchmarks, whitelisted_caller};
use frame_system::RawOrigin;

benchmarks! {
    add_member {
        let caller: T::AccountId = whitelisted_caller();
        let github_handle = vec![0u8; 50];
    }: _(RawOrigin::Root, caller.clone(), github_handle, 3)
    verify {
        assert!(Members::<T>::contains_key(&caller));
    }

    remove_member {
        let caller: T::AccountId = whitelisted_caller();
        DAOMembership::<T>::add_member(
            RawOrigin::Root.into(),
            caller.clone(),
            vec![0u8; 50],
            3
        ).unwrap();
    }: _(RawOrigin::Root, caller.clone())
    verify {
        assert!(!Members::<T>::get(&caller).unwrap().active);
    }

    // ... autres benchmarks
}
```

#### Exécution Benchmarks

```bash
cd dao-parachain

# Build avec benchmarking feature
cargo build --release --features runtime-benchmarks

# Run benchmarks
./target/release/dao-parachain-node benchmark pallet \
    --chain dev \
    --pallet pallet_dao_membership \
    --extrinsic "*" \
    --steps 50 \
    --repeat 20 \
    --output pallets/dao-membership/src/weights.rs
```

**Livrable** :
- [ ] Weights générés pour tous les pallets
- [ ] `weights.rs` intégré au runtime
- [ ] Profiling performance (gas vs weights comparison)

---

**Temps total Phase 2** : 1-2 semaines

---

## Phase 3 : Features Polkadot 2.0 (2-3 semaines)

### 3.1 Async Backing Integration

**Objectif** : Activer Async Backing pour 6s block time (vs 12s actuel)

#### Configuration Runtime

```rust
// runtime/src/lib.rs
parameter_types! {
    pub const BlockHashCount: BlockNumber = 250;
    pub const Version: RuntimeVersion = VERSION;
    pub BlockWeights: frame_system::limits::BlockWeights = BlockWeights::default();
    pub BlockLength: frame_system::limits::BlockLength = BlockLength::max_with_normal_ratio(5 * 1024 * 1024, NORMAL_DISPATCH_RATIO);

    // Async Backing parameters
    pub const ExpectedBlockTime: Moment = MILLISECS_PER_BLOCK;
    pub const AllowMultipleBlocksPerSlot: bool = true;  // Enable async backing
}

impl pallet_async_backing::Config for Runtime {
    type AllowMultipleBlocksPerSlot = AllowMultipleBlocksPerSlot;
}
```

#### Validation Node Configuration

```toml
# node/Cargo.toml
[dependencies]
cumulus-client-consensus-aura = { git = "...", features = ["async-backing"] }
```

**Livrable** :
- [ ] Async backing activé
- [ ] Block time 6s confirmé (vs 12s baseline)
- [ ] Tests collator production

**Temps** : 3-5 jours

---

### 3.2 Agile Coretime Integration

**Objectif** : Passer de slot auction → on-demand coretime

#### Configuration Parachain

```rust
// Coretime API integration
impl cumulus_pallet_parachain_system::Config for Runtime {
    type OnSystemEvent = ();
    type SelfParaId = ParachainId;
    type OutboundXcmpMessageSource = XcmpQueue;
    type DmpQueue = DmpQueue;
    type ReservedDmpWeight = ReservedDmpWeight;
    type XcmpMessageHandler = XcmpQueue;
    type ReservedXcmpWeight = ReservedXcmpWeight;

    // Agile Coretime: on-demand usage
    type CoretimeMode = CoretimeMode::OnDemand;
}
```

**Livrable** :
- [ ] On-demand coretime configuré
- [ ] Tests allocation blocks during peak usage
- [ ] Cost monitoring dashboard

**Temps** : 5-7 jours

---

### 3.3 XCM Integration (Cross-Chain Messaging)

**Objectif** : Communication inter-parachains (Treasury → AssetHub)

#### XCM Configuration

```rust
// runtime/src/xcm_config.rs
use xcm::latest::prelude::*;

pub struct XcmConfig;
impl xcm_executor::Config for XcmConfig {
    type RuntimeCall = RuntimeCall;
    type XcmSender = XcmRouter;
    type AssetTransactor = LocalAssetTransactor;
    type OriginConverter = LocalOriginConverter;
    type IsReserve = NativeAsset;
    // ... etc
}

// Example: Send tokens to AssetHub
pub fn transfer_to_assethub(
    amount: Balance,
    recipient: AccountId,
) -> DispatchResult {
    let dest = MultiLocation {
        parents: 1,
        interior: X1(Parachain(1000)), // AssetHub para ID
    };

    let beneficiary = X1(AccountId32 {
        network: Any,
        id: recipient.into(),
    });

    let asset = MultiAsset {
        id: Concrete(Here.into()),
        fun: Fungible(amount),
    };

    <XcmPallet as SendXcm>::send_xcm(
        Here,
        dest,
        Xcm(vec![
            WithdrawAsset(asset.clone().into()),
            BuyExecution { fees: asset.clone(), weight_limit: Unlimited },
            DepositAsset {
                assets: All.into(),
                beneficiary,
            },
        ]),
    )?;

    Ok(())
}
```

**Use Case** : Treasury multi-chain spending (DOT on Polkadot, USDT on AssetHub)

**Livrable** :
- [ ] XCM configuré (v3 ou v4)
- [ ] Tests cross-chain transfer AssetHub
- [ ] Integration pallet-dao-treasury

**Temps** : 5-7 jours

---

**Temps total Phase 3** : 2-3 semaines

---

## Phase 4 : Déploiement Testnet (1-2 semaines)

### 4.1 Paseo Testnet Deployment

**Objectif** : Déployer parachain sur Paseo (Polkadot testnet)

#### Prérequis

- Parachain ID alloué (via faucet Paseo)
- Collator nodes configurés (min 2 pour HA)
- Genesis state + wasm blob générés

#### Génération Genesis

```bash
cd dao-parachain

# Build release
cargo build --release --package dao-parachain-node

# Generate chain spec
./target/release/dao-parachain-node build-spec \
    --chain paseo \
    --disable-default-bootnode \
    > chain-spec-plain.json

# Edit chain-spec-plain.json:
# - Set para_id: 2xxx (votre ID alloué)
# - Configure genesis balances
# - Set initial collators

# Generate raw spec
./target/release/dao-parachain-node build-spec \
    --chain chain-spec-plain.json \
    --raw \
    --disable-default-bootnode \
    > chain-spec-raw.json

# Export genesis state
./target/release/dao-parachain-node export-genesis-state \
    --chain chain-spec-raw.json \
    > genesis-state

# Export genesis wasm
./target/release/dao-parachain-node export-genesis-wasm \
    --chain chain-spec-raw.json \
    > genesis-wasm
```

#### Enregistrement Parachain

```bash
# Via Paseo UI (polkadot.js.org/apps)
# 1. Developer -> Extrinsics -> registrar.reserve()
# 2. Developer -> Extrinsics -> parasSudoWrapper.sudoScheduleParaInitialize()
#    - id: votre para_id
#    - genesis_head: contenu de genesis-state
#    - validation_code: contenu de genesis-wasm
```

#### Lancement Collators

```bash
# Collator 1
./target/release/dao-parachain-node \
    --collator \
    --chain chain-spec-raw.json \
    --base-path /data/collator1 \
    --port 30333 \
    --rpc-port 9944 \
    --ws-port 9945 \
    --name "DAO-Collator-1" \
    -- \
    --chain paseo \
    --port 30334 \
    --rpc-port 9946

# Collator 2 (autre machine)
# ... même commande avec ports différents
```

**Validation** :
- [ ] Parachain enregistrée sur Paseo
- [ ] 2 collators produisant blocks
- [ ] RPC accessible (wss://dao-parachain.example.com)
- [ ] Polkadot.js UI connecté

---

### 4.2 Monitoring & Observability

**Stack recommandée** : Prometheus + Grafana

#### Metrics Export

```toml
# node/Cargo.toml
[dependencies]
substrate-prometheus-endpoint = { git = "..." }
```

```rust
// node/src/service.rs
let prometheus_registry = prometheus::default_registry();
prometheus_exporter::start(
    "0.0.0.0:9615".parse().unwrap(),
    prometheus_registry.clone(),
)?;
```

#### Grafana Dashboards

- **Collator Dashboard** : Block production, finalization lag, peer count
- **Parachain Dashboard** : XCM messages, coretime usage, runtime version
- **Custom Pallets Dashboard** : Proposals count, members count, treasury balance

**Livrable** :
- [ ] Prometheus scraping collators
- [ ] Grafana dashboards configurés
- [ ] Alerting (Slack/Discord) pour block stall

---

### 4.3 Frontend Migration (hors scope migration runtime)

**Note** : Frontend Solidity → Polkadot nécessite migration séparée

**Changements requis** :
- ethers.js → @polkadot/api
- Metamask → Polkadot.js extension / Talisman
- Contract calls → Extrinsic submissions

**Effort estimé** : 2-3 semaines (frontend team)

---

**Temps total Phase 4** : 1-2 semaines

---

## Timeline Consolidé

| Phase | Durée | Livrable Clé |
|-------|-------|--------------|
| **Phase 0 : Préparation** | 1-2 semaines | Business logic extracted, polkadot-sdk setup |
| **Phase 1 : Pallets Core** | 3-4 semaines | 5 pallets migrés et testés |
| **Phase 2 : Testing** | 1-2 semaines | Integration tests + benchmarks |
| **Phase 3 : Features Polkadot 2.0** | 2-3 semaines | Async Backing + Agile Coretime + XCM |
| **Phase 4 : Testnet** | 1-2 semaines | Paseo deployment + monitoring |
| **TOTAL** | **8-13 semaines** | **Parachain production-ready** |

---

## Options Simplification (Trade-offs)

### Option A : MVP Minimal (6-8 semaines)

**Simplifications** :
- ❌ Skip Phase 3 features Polkadot 2.0 (keep standard parachain)
- ❌ Skip XCM integration (single-chain only)
- ✅ Keep: Phases 0, 1, 2, 4

**Trade-off** :
- ✅ -30% effort (8-13 semaines → 6-8 semaines)
- ❌ Pas de features Polkadot 2.0 natives (async backing, coretime)
- ⚠️ Migration features ultérieure possible mais +20% effort

---

### Option B : Réutiliser Pallets Existants (5-7 semaines)

**Simplifications** :
- ❌ Skip DAOGovernor custom → Utiliser `pallet-collective` + `pallet-democracy`
- ❌ Skip DAOTreasury custom → Utiliser `pallet-treasury` natif
- ✅ Keep: DAOMembership, MissionEscrow, ServiceMarketplace (custom logic)

**Trade-off** :
- ✅ -40% effort (8-13 semaines → 5-7 semaines)
- ❌ Moins de flexibilité governance (tracks Polkadot standard vs custom)
- ✅ Meilleure compatibilité écosystème (pallets battle-tested)

**Recommandation** : **Option B pour MVP**, custom governance en Phase 2 si requis

---

### Option C : Hybrid EVM + Native (3-4 semaines migration)

**Architecture** :
- ✅ Keep Solidity contracts sur `pallet-evm` (Frontier)
- ✅ Add pallets natifs uniquement pour features Polkadot 2.0 (XCM, coretime)

**Simplifications** :
- ❌ Skip migration Solidity → Rust (Phase 1)
- ✅ Déployer contracts Solidity existants sur EVM parachain
- ✅ Add wrappers natifs pour interop

**Trade-off** :
- ✅ -70% effort (8-13 semaines → 3-4 semaines)
- ❌ Hybrid stack (EVM + Native) = complexité architecture
- ❌ Features Polkadot 2.0 limitées pour contracts EVM
- ⚠️ Non recommandé long-terme (goal = natif Polkadot)

---

## Décision Matrix

| Option | Effort | Features Polkadot 2.0 | Simplicité | Recommandation |
|--------|--------|----------------------|------------|----------------|
| **A : MVP Minimal** | 6-8 sem | ❌ Limité | ✅✅ Haute | ⚠️ Si contrainte temps critique |
| **B : Pallets Réutilisés** | 5-7 sem | ✅ Complet | ✅✅✅ Maximale | ✅ **RECOMMANDÉ** |
| **C : Hybrid EVM** | 3-4 sem | ⚠️ Partiel | ❌ Complexe | ❌ Non recommandé |
| **Full Native (Plan)** | 8-13 sem | ✅✅ Complet + Custom | ✅ Haute | ✅ Long-terme optimal |

---

## Recommandation Finale

**Phase 1 : MVP avec Option B** (5-7 semaines)
- Réutiliser `pallet-collective`, `pallet-democracy`, `pallet-treasury`
- Créer uniquement DAOMembership, MissionEscrow, ServiceMarketplace custom
- Déployer sur Paseo testnet
- Features Polkadot 2.0 : Async Backing uniquement (quick win)

**Phase 2 : Enrichissement** (si besoin, +3-4 semaines)
- Custom governance tracks
- XCM integration pour multi-chain treasury
- Frontend migration (parallel track)

**ROI** :
- **Avant** : Maintenance 3 stacks = 12-15h/semaine = 600-750h/an
- **Après** : Maintenance 1 stack natif = 4-5h/semaine = 200-250h/an
- **Économie** : 400-500h/an (-66% effort maintenance)
- **Investment** : 5-7 semaines (200-280h) → ROI positif en 6-9 mois

---

## Next Steps

1. **Validation stratégie** : User approuve Option B (MVP Réutilisation Pallets)
2. **Kickoff Phase 0** : Setup polkadot-sdk + business logic extraction (1-2 semaines)
3. **Phase 0.5 completion** : Finaliser P0 fixes Solidity (14-22h) EN PARALLÈLE
4. **Phase 1 execution** : Pallets migration (5 semaines)
5. **Phase 2 testing** : Integration tests + benchmarks (1 semaine)
6. **Phase 4 deployment** : Paseo testnet (1 semaine)

**Total timeline** : **8 semaines** (MVP production-ready sur Paseo)

---

**Créé** : 2026-02-10
**Version** : 1.0.0
**Maintainer** : DAO Development Team
