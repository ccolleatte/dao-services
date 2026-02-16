#![cfg_attr(not(feature = "std"), no_std)]

pub use pallet::*;

use codec::{Decode, Encode, MaxEncodedLen};
use frame_support::pallet_prelude::*;
use frame_system::pallet_prelude::*;
use scale_info::TypeInfo;
use sp_runtime::RuntimeDebug;

/// Mission status
#[derive(Clone, Encode, Decode, Eq, PartialEq, RuntimeDebug, TypeInfo, MaxEncodedLen)]
pub enum MissionStatus {
    Active,
    Completed,
    Cancelled,
    Disputed,
}

/// Milestone (Phase 2 implementation)
#[derive(Clone, Encode, Decode, Eq, PartialEq, RuntimeDebug, TypeInfo, MaxEncodedLen)]
#[scale_info(skip_type_params(T))]
pub struct Milestone<T: Config> {
    pub mission_id: u64,
    pub index: u32,
    pub deliverable_hash: [u8; 32],
    pub amount: u128,
    pub approved: bool,
    pub approver: Option<T::AccountId>,
}

#[frame_support::pallet]
pub mod pallet {
    use super::*;

    #[pallet::pallet]
    pub struct Pallet<T>(_);

    #[pallet::config]
    pub trait Config: frame_system::Config + pallet_dao_membership::Config {
        type RuntimeEvent: From<Event<Self>> + IsType<<Self as frame_system::Config>::RuntimeEvent>;
    }

    /// Storage: Milestones (double map for mission_id => milestone_index)
    #[pallet::storage]
    pub type Milestones<T: Config> = StorageDoubleMap<
        _,
        Blake2_128Concat, u64,  // mission_id
        Blake2_128Concat, u32,  // milestone_index
        Milestone<T>,
    >;

    /// Events
    #[pallet::event]
    #[pallet::generate_deposit(pub(super) fn deposit_event)]
    pub enum Event<T: Config> {
        /// Mission created [mission_id]
        MissionCreated { mission_id: u64 },
        /// Milestone submitted [mission_id, milestone_index]
        MilestoneSubmitted { mission_id: u64, milestone_index: u32 },
        /// Milestone approved [mission_id, milestone_index]
        MilestoneApproved { mission_id: u64, milestone_index: u32 },
    }

    /// Errors
    #[pallet::error]
    pub enum Error<T> {
        /// Not implemented yet (Phase 2)
        NotImplementedYet,
    }

    #[pallet::call]
    impl<T: Config> Pallet<T> {
        /// Create mission (Phase 2 implementation)
        #[pallet::call_index(0)]
        #[pallet::weight(10_000)]
        pub fn create_mission(
            origin: OriginFor<T>,
            _mission_id: u64,
        ) -> DispatchResult {
            let _who = ensure_signed(origin)?;

            // Phase 2: Implement full mission creation logic
            Err(Error::<T>::NotImplementedYet.into())
        }

        /// Submit milestone (Phase 2 implementation)
        #[pallet::call_index(1)]
        #[pallet::weight(10_000)]
        pub fn submit_milestone(
            origin: OriginFor<T>,
            _mission_id: u64,
            _milestone_index: u32,
        ) -> DispatchResult {
            let _who = ensure_signed(origin)?;

            // Phase 2: Implement milestone submission
            Err(Error::<T>::NotImplementedYet.into())
        }

        /// Approve milestone (Phase 2 implementation)
        #[pallet::call_index(2)]
        #[pallet::weight(10_000)]
        pub fn approve_milestone(
            origin: OriginFor<T>,
            _mission_id: u64,
            _milestone_index: u32,
        ) -> DispatchResult {
            let _who = ensure_signed(origin)?;

            // Phase 2: Implement approval logic with triangular vote weights
            Err(Error::<T>::NotImplementedYet.into())
        }
    }
}
