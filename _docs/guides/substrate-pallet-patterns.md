# Substrate Pallet Development Patterns

**Date** : 2026-02-10
**Projet** : DAO Services IA/Humains
**Version** : 1.0.0

---

## Vue d'ensemble

Les **pallets** sont les modules fondamentaux d'un Substrate runtime. Ce guide présente les patterns essentiels pour développer les pallets DAO Services.

---

## 1. Substrate Runtime Architecture

### Principe

Un Substrate runtime est une **State Transition Function (STF)** :

```
STF(State_N, Block_N) → State_N+1
```

**Composants** :
- **Runtime** : Logique métier on-chain (comparable à smart contracts)
- **Pallets** : Modules runtime (comparable à contracts individuels)
- **Node** : Client P2P + consensus (off-chain logic)

### Advantages vs Smart Contracts

| Feature | Smart Contracts (ink!/Solidity) | Runtime Pallets (Substrate) |
|---------|--------------------------------|---------------------------|
| **Execution** | WASM interpreter (overhead 10-20%) | Native bytecode (0% overhead) |
| **Storage** | Limité (contract bounds) | Illimité (runtime storage) |
| **Upgradability** | Proxy patterns (complexe) | Runtime upgrades (natif) |
| **Cross-chain** | Bridges (trust assumptions) | XCM natif (trustless) |
| **Fees** | Gas-based (variable) | Weight-based (déterministe) |

**Conclusion** : Pallets = performance supérieure + flexibilité totale.

---

## 2. Pallets DAO Nécessaires

### Architecture

```
┌──────────────────────────────────────────┐
│         DAO Runtime                      │
├──────────────────────────────────────────┤
│  Marketplace Pallet (custom)             │
│  - create_mission()                      │
│  - match_mission()                       │
│  - submit_deliverable()                  │
│  - release_payment()                     │
├──────────────────────────────────────────┤
│  Treasury Pallet (built-in)              │
│  - pallet_treasury::spend()              │
│  - Milestone releases                    │
├──────────────────────────────────────────┤
│  Governance Pallet (built-in)            │
│  - pallet_referenda (OpenGov)            │
│  - pallet_conviction_voting              │
│  - pallet_preimage                       │
├──────────────────────────────────────────┤
│  Membership Pallet (custom)              │
│  - register_member()                     │
│  - assign_role()                         │
│  - reputation_score()                    │
└──────────────────────────────────────────┘
```

---

### 2.1 Marketplace Pallet

**Emplacement** : `runtime/pallets/marketplace/src/lib.rs`

**Structure complète** :

```rust
#![cfg_attr(not(feature = "std"), no_std)]

pub use pallet::*;

#[frame_support::pallet]
pub mod pallet {
    use frame_support::{
        pallet_prelude::*,
        traits::{Currency, ReservableCurrency},
    };
    use frame_system::pallet_prelude::*;
    use sp_runtime::traits::StaticLookup;

    type BalanceOf<T> = <<T as Config>::Currency as Currency<<T as frame_system::Config>::AccountId>>::Balance;

    #[pallet::pallet]
    pub struct Pallet<T>(_);

    #[pallet::config]
    pub trait Config: frame_system::Config {
        /// Runtime event type
        type RuntimeEvent: From<Event<Self>> + IsType<<Self as frame_system::Config>::RuntimeEvent>;

        /// Currency for payments
        type Currency: Currency<Self::AccountId> + ReservableCurrency<Self::AccountId>;

        /// Max description length (prevent spam)
        #[pallet::constant]
        type MaxDescriptionLen: Get<u32>;

        /// Minimum mission budget (anti-spam)
        #[pallet::constant]
        type MinimumBudget: Get<BalanceOf<Self>>;

        /// Platform fee percentage (e.g., 5% = 5)
        #[pallet::constant]
        type PlatformFeePercent: Get<u8>;
    }

    /// Mission structure
    #[derive(Clone, Encode, Decode, Eq, PartialEq, RuntimeDebug, TypeInfo, MaxEncodedLen)]
    pub struct Mission<AccountId, Balance> {
        pub client: AccountId,
        pub description_hash: [u8; 32], // IPFS hash
        pub budget: Balance,
        pub escrow: Balance,
        pub provider: Option<AccountId>,
        pub status: MissionStatus,
        pub created_at: u32, // Block number
    }

    #[derive(Clone, Encode, Decode, Eq, PartialEq, RuntimeDebug, TypeInfo, MaxEncodedLen)]
    pub enum MissionStatus {
        Open,
        Matched,
        InProgress,
        UnderReview,
        Completed,
        Disputed,
        Cancelled,
    }

    /// Storage: Missions by ID
    #[pallet::storage]
    #[pallet::getter(fn missions)]
    pub type Missions<T: Config> = StorageMap<
        _,
        Blake2_128Concat,
        u64, // Mission ID
        Mission<T::AccountId, BalanceOf<T>>,
        OptionQuery,
    >;

    /// Storage: Next mission ID (counter)
    #[pallet::storage]
    #[pallet::getter(fn next_mission_id)]
    pub type NextMissionId<T> = StorageValue<_, u64, ValueQuery>;

    /// Storage: Missions by provider
    #[pallet::storage]
    pub type MissionsByProvider<T: Config> = StorageMap<
        _,
        Blake2_128Concat,
        T::AccountId,
        BoundedVec<u64, ConstU32<100>>, // Max 100 missions per provider
        ValueQuery,
    >;

    /// Events
    #[pallet::event]
    #[pallet::generate_deposit(pub(super) fn deposit_event)]
    pub enum Event<T: Config> {
        MissionCreated {
            id: u64,
            client: T::AccountId,
            budget: BalanceOf<T>,
        },
        MissionMatched {
            id: u64,
            provider: T::AccountId,
        },
        DeliverableSubmitted {
            id: u64,
            deliverable_hash: [u8; 32],
        },
        PaymentReleased {
            id: u64,
            provider: T::AccountId,
            amount: BalanceOf<T>,
        },
        MissionCancelled {
            id: u64,
            reason: BoundedVec<u8, ConstU32<100>>,
        },
    }

    /// Errors
    #[pallet::error]
    pub enum Error<T> {
        MissionNotFound,
        NotMissionClient,
        NotMissionProvider,
        InvalidStatus,
        BudgetTooLow,
        DescriptionTooLong,
        InsufficientBalance,
        AlreadyMatched,
        NotMatched,
    }

    /// Extrinsics (callable functions)
    #[pallet::call]
    impl<T: Config> Pallet<T> {
        /// Create new mission
        #[pallet::weight(10_000 + T::DbWeight::get().writes(3))]
        pub fn create_mission(
            origin: OriginFor<T>,
            description_hash: [u8; 32],
            budget: BalanceOf<T>,
        ) -> DispatchResult {
            let client = ensure_signed(origin)?;

            // Validate budget
            ensure!(
                budget >= T::MinimumBudget::get(),
                Error::<T>::BudgetTooLow
            );

            // Reserve funds (escrow)
            T::Currency::reserve(&client, budget)?;

            // Get next mission ID
            let mission_id = NextMissionId::<T>::get();
            NextMissionId::<T>::put(mission_id + 1);

            // Create mission
            let mission = Mission {
                client: client.clone(),
                description_hash,
                budget,
                escrow: budget,
                provider: None,
                status: MissionStatus::Open,
                created_at: <frame_system::Pallet<T>>::block_number() as u32,
            };

            Missions::<T>::insert(mission_id, mission);

            Self::deposit_event(Event::MissionCreated {
                id: mission_id,
                client,
                budget,
            });

            Ok(())
        }

        /// Match mission with provider
        #[pallet::weight(10_000 + T::DbWeight::get().writes(2))]
        pub fn match_mission(
            origin: OriginFor<T>,
            mission_id: u64,
        ) -> DispatchResult {
            let provider = ensure_signed(origin)?;

            Missions::<T>::try_mutate(mission_id, |maybe_mission| -> DispatchResult {
                let mission = maybe_mission.as_mut().ok_or(Error::<T>::MissionNotFound)?;

                // Validate status
                ensure!(
                    mission.status == MissionStatus::Open,
                    Error::<T>::InvalidStatus
                );

                // Assign provider
                mission.provider = Some(provider.clone());
                mission.status = MissionStatus::Matched;

                // Add to provider's missions
                MissionsByProvider::<T>::try_mutate(&provider, |missions| -> DispatchResult {
                    missions.try_push(mission_id).map_err(|_| Error::<T>::AlreadyMatched)?;
                    Ok(())
                })?;

                Self::deposit_event(Event::MissionMatched {
                    id: mission_id,
                    provider,
                });

                Ok(())
            })
        }

        /// Submit deliverable
        #[pallet::weight(10_000 + T::DbWeight::get().writes(1))]
        pub fn submit_deliverable(
            origin: OriginFor<T>,
            mission_id: u64,
            deliverable_hash: [u8; 32],
        ) -> DispatchResult {
            let provider = ensure_signed(origin)?;

            Missions::<T>::try_mutate(mission_id, |maybe_mission| -> DispatchResult {
                let mission = maybe_mission.as_mut().ok_or(Error::<T>::MissionNotFound)?;

                // Validate provider
                ensure!(
                    mission.provider == Some(provider.clone()),
                    Error::<T>::NotMissionProvider
                );

                // Validate status
                ensure!(
                    mission.status == MissionStatus::Matched || mission.status == MissionStatus::InProgress,
                    Error::<T>::InvalidStatus
                );

                mission.status = MissionStatus::UnderReview;

                Self::deposit_event(Event::DeliverableSubmitted {
                    id: mission_id,
                    deliverable_hash,
                });

                Ok(())
            })
        }

        /// Release payment (client approves)
        #[pallet::weight(10_000 + T::DbWeight::get().writes(2))]
        pub fn release_payment(
            origin: OriginFor<T>,
            mission_id: u64,
        ) -> DispatchResult {
            let client = ensure_signed(origin)?;

            Missions::<T>::try_mutate(mission_id, |maybe_mission| -> DispatchResult {
                let mission = maybe_mission.as_mut().ok_or(Error::<T>::MissionNotFound)?;

                // Validate client
                ensure!(
                    mission.client == client,
                    Error::<T>::NotMissionClient
                );

                // Validate status
                ensure!(
                    mission.status == MissionStatus::UnderReview,
                    Error::<T>::InvalidStatus
                );

                let provider = mission.provider.as_ref().ok_or(Error::<T>::NotMatched)?;

                // Calculate platform fee
                let platform_fee = mission.budget * T::PlatformFeePercent::get().into() / 100u32.into();
                let provider_payment = mission.budget - platform_fee;

                // Unreserve and transfer
                T::Currency::unreserve(&client, mission.budget);
                T::Currency::transfer(&client, provider, provider_payment, frame_support::traits::ExistenceRequirement::KeepAlive)?;

                // Platform fee goes to Treasury
                // (handled by pallet_treasury integration)

                mission.status = MissionStatus::Completed;

                Self::deposit_event(Event::PaymentReleased {
                    id: mission_id,
                    provider: provider.clone(),
                    amount: provider_payment,
                });

                Ok(())
            })
        }
    }
}
```

---

### 2.2 Treasury Pallet Integration

**Utiliser `pallet_treasury` built-in** (pas de custom pallet needed).

**Configuration** (`runtime/src/lib.rs`) :

```rust
impl pallet_treasury::Config for Runtime {
    type PalletId = TreasuryPalletId;
    type Currency = Balances;
    type ApproveOrigin = frame_system::EnsureRoot<AccountId>; // Or governance
    type RejectOrigin = frame_system::EnsureRoot<AccountId>;
    type RuntimeEvent = RuntimeEvent;
    type OnSlash = Treasury;
    type ProposalBond = ProposalBond;
    type ProposalBondMinimum = ProposalBondMinimum;
    type ProposalBondMaximum = ProposalBondMaximum;
    type SpendPeriod = SpendPeriod;
    type Burn = Burn;
    type BurnDestination = ();
    type SpendFunds = ();
    type WeightInfo = pallet_treasury::weights::SubstrateWeight<Runtime>;
    type MaxApprovals = MaxApprovals;
    type SpendOrigin = frame_support::traits::NeverEnsureOrigin<Balance>; // Use governance
}
```

**Usage** (milestone releases) :

```rust
// In marketplace pallet
impl<T: Config> Pallet<T> {
    fn release_payment_with_milestone(
        client: T::AccountId,
        provider: T::AccountId,
        mission_id: u64,
        milestone_percent: u8,
    ) -> DispatchResult {
        let mission = Missions::<T>::get(mission_id).ok_or(Error::<T>::MissionNotFound)?;

        let milestone_amount = mission.budget * milestone_percent.into() / 100u32.into();

        // Transfer from treasury
        <pallet_treasury::Pallet<T>>::spend(
            frame_system::RawOrigin::Root.into(), // Governance approval needed
            milestone_amount,
            provider.clone(),
        )?;

        Ok(())
    }
}
```

---

### 2.3 Governance Pallet Integration

**Utiliser OpenGov pallets built-in** :
- `pallet_referenda` : Referendum proposals
- `pallet_conviction_voting` : Vote with conviction multipliers
- `pallet_preimage` : Store proposal call data

**Configuration** (`runtime/src/lib.rs`) :

```rust
parameter_types! {
    pub const VotingPeriod: BlockNumber = 7 * DAYS;
    pub const EnactmentPeriod: BlockNumber = 3 * DAYS;
}

impl pallet_referenda::Config for Runtime {
    type RuntimeEvent = RuntimeEvent;
    type Currency = Balances;
    type SubmitOrigin = frame_system::EnsureSigned<AccountId>;
    type CancelOrigin = frame_system::EnsureRoot<AccountId>;
    type KillOrigin = frame_system::EnsureRoot<AccountId>;
    type Slash = Treasury;
    type Votes = pallet_conviction_voting::VotesOf<Runtime>;
    type Tally = pallet_conviction_voting::TallyOf<Runtime>;
    type SubmissionDeposit = SubmissionDeposit;
    type MaxQueued = MaxQueued;
    type UndecidingTimeout = UndecidingTimeout;
    type AlarmInterval = AlarmInterval;
    type Tracks = TracksInfo; // Custom tracks (Technical, Treasury, Membership)
    type Preimages = Preimage;
}

impl pallet_conviction_voting::Config for Runtime {
    type RuntimeEvent = RuntimeEvent;
    type Currency = Balances;
    type VoteLockingPeriod = VoteLockingPeriod;
    type MaxVotes = MaxVotes;
    type MaxTurnout = MaxTurnout;
    type Polls = Referenda;
    type WeightInfo = pallet_conviction_voting::weights::SubstrateWeight<Runtime>;
}
```

**Custom Tracks** (Technical, Treasury, Membership) :

```rust
// runtime/src/governance/tracks.rs
use pallet_referenda::Curve;

pub struct TracksInfo;
impl pallet_referenda::TracksInfo<Balance, BlockNumber> for TracksInfo {
    type Id = u16;
    type RuntimeOrigin = RuntimeOrigin;

    fn tracks() -> &'static [(Self::Id, TrackInfo<Balance, BlockNumber>)] {
        static DATA: [(u16, TrackInfo<Balance, BlockNumber>); 3] = [
            // Track 0: Technical
            (
                0,
                TrackInfo {
                    name: "technical",
                    max_deciding: 10,
                    decision_deposit: 100 * UNITS,
                    prepare_period: 1 * DAYS,
                    decision_period: 7 * DAYS,
                    confirm_period: 3 * DAYS,
                    min_enactment_period: 1 * DAYS,
                    min_approval: Curve::LinearDecreasing {
                        length: Perbill::from_percent(100),
                        floor: Perbill::from_percent(50),
                        ceil: Perbill::from_percent(100),
                    },
                    min_support: Curve::LinearDecreasing {
                        length: Perbill::from_percent(100),
                        floor: Perbill::from_percent(10),
                        ceil: Perbill::from_percent(50),
                    },
                },
            ),
            // Track 1: Treasury
            (
                1,
                TrackInfo {
                    name: "treasury",
                    max_deciding: 5,
                    decision_deposit: 1000 * UNITS,
                    prepare_period: 2 * DAYS,
                    decision_period: 14 * DAYS,
                    confirm_period: 7 * DAYS,
                    min_enactment_period: 3 * DAYS,
                    min_approval: Curve::LinearDecreasing {
                        length: Perbill::from_percent(100),
                        floor: Perbill::from_percent(60),
                        ceil: Perbill::from_percent(100),
                    },
                    min_support: Curve::LinearDecreasing {
                        length: Perbill::from_percent(100),
                        floor: Perbill::from_percent(20),
                        ceil: Perbill::from_percent(60),
                    },
                },
            ),
            // Track 2: Membership
            (
                2,
                TrackInfo {
                    name: "membership",
                    max_deciding: 10,
                    decision_deposit: 50 * UNITS,
                    prepare_period: 1 * DAYS,
                    decision_period: 7 * DAYS,
                    confirm_period: 2 * DAYS,
                    min_enactment_period: 1 * DAYS,
                    min_approval: Curve::LinearDecreasing {
                        length: Perbill::from_percent(100),
                        floor: Perbill::from_percent(50),
                        ceil: Perbill::from_percent(100),
                    },
                    min_support: Curve::LinearDecreasing {
                        length: Perbill::from_percent(100),
                        floor: Perbill::from_percent(10),
                        ceil: Perbill::from_percent(40),
                    },
                },
            ),
        ];
        &DATA
    }

    fn track_for(id: &Self::RuntimeOrigin) -> Result<Self::Id, ()> {
        // Map origin to track ID
        match id {
            RuntimeOrigin::Technical => Ok(0),
            RuntimeOrigin::Treasury => Ok(1),
            RuntimeOrigin::Membership => Ok(2),
            _ => Err(()),
        }
    }
}
```

---

## 3. Weight Calculation Pattern

### Principe

**Weights** = Estimated computational cost (deterministic, unlike gas).

**Formula** :
```
Weight = ref_time (CPU cycles) + proof_size (storage reads/writes)
```

### Benchmarking

**Setup** (`pallets/marketplace/Cargo.toml`) :

```toml
[features]
runtime-benchmarks = [
    "frame-benchmarking/runtime-benchmarks",
    "frame-support/runtime-benchmarks",
]
```

**Benchmark code** (`pallets/marketplace/src/benchmarking.rs`) :

```rust
#![cfg(feature = "runtime-benchmarks")]

use super::*;
use frame_benchmarking::{benchmarks, whitelisted_caller};
use frame_system::RawOrigin;

benchmarks! {
    create_mission {
        let caller: T::AccountId = whitelisted_caller();
        let description_hash = [0u8; 32];
        let budget = T::MinimumBudget::get() * 10u32.into();

        // Fund caller
        T::Currency::make_free_balance_be(&caller, budget * 2u32.into());

    }: _(RawOrigin::Signed(caller), description_hash, budget)
    verify {
        assert_eq!(NextMissionId::<T>::get(), 1);
    }

    match_mission {
        let client: T::AccountId = whitelisted_caller();
        let provider: T::AccountId = account("provider", 0, 0);

        // Setup: create mission first
        let description_hash = [0u8; 32];
        let budget = T::MinimumBudget::get() * 10u32.into();
        T::Currency::make_free_balance_be(&client, budget * 2u32.into());
        Pallet::<T>::create_mission(RawOrigin::Signed(client).into(), description_hash, budget)?;

    }: _(RawOrigin::Signed(provider), 0)
    verify {
        assert!(Missions::<T>::get(0).unwrap().provider.is_some());
    }

    impl_benchmark_test_suite!(Pallet, crate::mock::new_test_ext(), crate::mock::Test);
}
```

**Run benchmarks** :

```bash
cargo build --release --features runtime-benchmarks

./target/release/dao-node benchmark pallet \
    --pallet pallet_marketplace \
    --extrinsic "*" \
    --steps 50 \
    --repeat 20 \
    --output pallets/marketplace/src/weights.rs
```

**Generated weights** (`pallets/marketplace/src/weights.rs`) :

```rust
pub trait WeightInfo {
    fn create_mission() -> Weight;
    fn match_mission() -> Weight;
    fn submit_deliverable() -> Weight;
    fn release_payment() -> Weight;
}

impl WeightInfo for SubstrateWeight<T> {
    fn create_mission() -> Weight {
        Weight::from_parts(45_000_000, 0)
            .saturating_add(T::DbWeight::get().reads(2))
            .saturating_add(T::DbWeight::get().writes(3))
    }

    fn match_mission() -> Weight {
        Weight::from_parts(35_000_000, 0)
            .saturating_add(T::DbWeight::get().reads(1))
            .saturating_add(T::DbWeight::get().writes(2))
    }
}
```

---

## 4. Testing Pattern

### Unit Tests

**Setup** (`pallets/marketplace/src/mock.rs`) :

```rust
use frame_support::{
    parameter_types,
    traits::{ConstU32, ConstU64},
};
use sp_runtime::{
    testing::Header,
    traits::{BlakeTwo256, IdentityLookup},
};

type UncheckedExtrinsic = frame_system::mocking::MockUncheckedExtrinsic<Test>;
type Block = frame_system::mocking::MockBlock<Test>;

frame_support::construct_runtime!(
    pub enum Test where
        Block = Block,
        NodeBlock = Block,
        UncheckedExtrinsic = UncheckedExtrinsic,
    {
        System: frame_system,
        Balances: pallet_balances,
        Marketplace: pallet_marketplace,
    }
);

parameter_types! {
    pub const MaxDescriptionLen: u32 = 1000;
    pub const MinimumBudget: u64 = 100;
    pub const PlatformFeePercent: u8 = 5;
}

impl pallet_marketplace::Config for Test {
    type RuntimeEvent = RuntimeEvent;
    type Currency = Balances;
    type MaxDescriptionLen = MaxDescriptionLen;
    type MinimumBudget = MinimumBudget;
    type PlatformFeePercent = PlatformFeePercent;
}

pub fn new_test_ext() -> sp_io::TestExternalities {
    let mut t = frame_system::GenesisConfig::default()
        .build_storage::<Test>()
        .unwrap();

    pallet_balances::GenesisConfig::<Test> {
        balances: vec![(1, 10000), (2, 10000)],
    }
    .assimilate_storage(&mut t)
    .unwrap();

    t.into()
}
```

**Tests** (`pallets/marketplace/src/tests.rs`) :

```rust
use super::*;
use crate::mock::*;
use frame_support::{assert_ok, assert_noop};

#[test]
fn create_mission_works() {
    new_test_ext().execute_with(|| {
        let client = 1;
        let description_hash = [1u8; 32];
        let budget = 1000;

        assert_ok!(Marketplace::create_mission(
            RuntimeOrigin::signed(client),
            description_hash,
            budget
        ));

        assert_eq!(Marketplace::next_mission_id(), 1);

        let mission = Marketplace::missions(0).unwrap();
        assert_eq!(mission.client, client);
        assert_eq!(mission.budget, budget);
        assert_eq!(mission.status, MissionStatus::Open);
    });
}

#[test]
fn create_mission_fails_budget_too_low() {
    new_test_ext().execute_with(|| {
        let client = 1;
        let description_hash = [1u8; 32];
        let budget = 50; // Below MinimumBudget (100)

        assert_noop!(
            Marketplace::create_mission(
                RuntimeOrigin::signed(client),
                description_hash,
                budget
            ),
            Error::<Test>::BudgetTooLow
        );
    });
}

#[test]
fn match_mission_works() {
    new_test_ext().execute_with(|| {
        let client = 1;
        let provider = 2;
        let description_hash = [1u8; 32];
        let budget = 1000;

        // Create mission first
        assert_ok!(Marketplace::create_mission(
            RuntimeOrigin::signed(client),
            description_hash,
            budget
        ));

        // Match mission
        assert_ok!(Marketplace::match_mission(
            RuntimeOrigin::signed(provider),
            0
        ));

        let mission = Marketplace::missions(0).unwrap();
        assert_eq!(mission.provider, Some(provider));
        assert_eq!(mission.status, MissionStatus::Matched);
    });
}

#[test]
fn release_payment_works() {
    new_test_ext().execute_with(|| {
        let client = 1;
        let provider = 2;
        let description_hash = [1u8; 32];
        let budget = 1000;

        // Create + match + submit
        assert_ok!(Marketplace::create_mission(
            RuntimeOrigin::signed(client),
            description_hash,
            budget
        ));
        assert_ok!(Marketplace::match_mission(RuntimeOrigin::signed(provider), 0));
        assert_ok!(Marketplace::submit_deliverable(
            RuntimeOrigin::signed(provider),
            0,
            [2u8; 32]
        ));

        // Release payment
        let provider_balance_before = Balances::free_balance(provider);
        assert_ok!(Marketplace::release_payment(RuntimeOrigin::signed(client), 0));

        // Verify payment (budget - 5% fee)
        let expected_payment = budget - (budget * 5 / 100);
        assert_eq!(
            Balances::free_balance(provider),
            provider_balance_before + expected_payment
        );

        let mission = Marketplace::missions(0).unwrap();
        assert_eq!(mission.status, MissionStatus::Completed);
    });
}
```

---

## 5. Migration from Solidity

### Comparison

| Solidity Concept | Substrate Equivalent |
|------------------|---------------------|
| `contract` | `#[pallet::pallet]` |
| `mapping` | `StorageMap` |
| `uint256` | `u64`, `u128`, `Balance` |
| `address` | `AccountId` |
| `modifier` | Origin checks (`ensure_signed`) |
| `event` | `#[pallet::event]` |
| `require()` | `ensure!()` |
| `revert()` | `Err(Error::<T>::...)` |
| Gas cost | Weight |

### Migration Checklist

**Solidity → Substrate** :

1. ✅ Convert contract to pallet structure
2. ✅ Replace `mapping` with `StorageMap`
3. ✅ Replace `uint256` with Substrate types
4. ✅ Add weight calculations (benchmarking)
5. ✅ Convert tests to `new_test_ext()`
6. ✅ Add genesis config (initial state)
7. ✅ Benchmark extrinsics
8. ✅ Generate weights file

---

## Références

**Official Documentation** :
- [Build Custom Pallets](https://docs.substrate.io/build/custom-pallets/)
- [Pallet Macros Reference](https://paritytech.github.io/substrate/master/frame_support/attr.pallet.html)
- [Storage Types](https://docs.substrate.io/build/runtime-storage/)

**Production Examples** :
- [Polkadot Fellowship Runtimes](https://github.com/polkadot-fellows/runtimes)
- [Substrate Node Template](https://github.com/substrate-developer-hub/substrate-node-template)

**Benchmarking** :
- [Weight Benchmarking Guide](https://docs.substrate.io/test/benchmark/)
- [Runtime Benchmarking](https://docs.substrate.io/reference/how-to-guides/weights/add-benchmarks/)

---

**Version** : 1.0.0
**Dernière mise à jour** : 2026-02-10
