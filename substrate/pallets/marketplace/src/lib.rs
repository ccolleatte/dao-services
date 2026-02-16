#![cfg_attr(not(feature = "std"), no_std)]

pub use pallet::*;

use codec::{Decode, Encode, MaxEncodedLen};
use frame_support::pallet_prelude::*;
use frame_system::pallet_prelude::*;
use scale_info::TypeInfo;
use sp_runtime::RuntimeDebug;

/// Match score result
#[derive(Clone, Encode, Decode, Eq, PartialEq, RuntimeDebug, TypeInfo, MaxEncodedLen)]
pub struct MatchScore {
    pub profile_id: u64,
    pub total_score: u8,
    pub skills_score: u8,
    pub rating_score: u8,
    pub rate_score: u8,
    pub availability_score: u8,
    pub collaboration_score: u8,
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

    /// Storage: Profiles (Phase 2)
    #[pallet::storage]
    pub type Profiles<T: Config> = StorageMap<
        _,
        Blake2_128Concat,
        u64,  // profile_id
        (),  // Placeholder - full struct in Phase 2
    >;

    /// Events
    #[pallet::event]
    #[pallet::generate_deposit(pub(super) fn deposit_event)]
    pub enum Event<T: Config> {
        /// Profile created [profile_id]
        ProfileCreated { profile_id: u64 },
        /// Need posted [need_id]
        NeedPosted { need_id: u64 },
        /// Match calculated [need_id, profile_id, score]
        MatchCalculated { need_id: u64, profile_id: u64, score: u8 },
    }

    /// Errors
    #[pallet::error]
    pub enum Error<T> {
        /// Not implemented yet (Phase 2)
        NotImplementedYet,
    }

    #[pallet::call]
    impl<T: Config> Pallet<T> {
        /// Create profile (Phase 2 implementation)
        #[pallet::call_index(0)]
        #[pallet::weight(10_000)]
        pub fn create_profile(
            origin: OriginFor<T>,
            _profile_id: u64,
        ) -> DispatchResult {
            let _who = ensure_signed(origin)?;

            // Phase 2: Implement full profile creation
            Err(Error::<T>::NotImplementedYet.into())
        }

        /// Post need (Phase 2 implementation)
        #[pallet::call_index(1)]
        #[pallet::weight(10_000)]
        pub fn post_need(
            origin: OriginFor<T>,
            _need_id: u64,
        ) -> DispatchResult {
            let _who = ensure_signed(origin)?;

            // Phase 2: Implement need posting
            Err(Error::<T>::NotImplementedYet.into())
        }

        /// Calculate match (Phase 2 implementation)
        #[pallet::call_index(2)]
        #[pallet::weight(10_000)]
        pub fn calculate_match(
            origin: OriginFor<T>,
            _need_id: u64,
            _profile_id: u64,
        ) -> DispatchResult {
            let _who = ensure_signed(origin)?;

            // Phase 2: Implement match scoring algorithm
            Err(Error::<T>::NotImplementedYet.into())
        }
    }
}
