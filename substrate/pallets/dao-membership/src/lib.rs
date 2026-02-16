#![cfg_attr(not(feature = "std"), no_std)]

pub use pallet::*;

use codec::{Decode, Encode, MaxEncodedLen};
use frame_support::{
    pallet_prelude::*,
    traits::Get,
    BoundedVec,
};
use frame_system::pallet_prelude::*;
use scale_info::TypeInfo;
use sp_runtime::RuntimeDebug;
use sp_std::vec::Vec;

/// Rank levels (0-4 for triangular vote weights)
pub type RankLevel = u8;

/// Member information
#[derive(Clone, Encode, Decode, Eq, PartialEq, RuntimeDebug, TypeInfo, MaxEncodedLen)]
#[scale_info(skip_type_params(T))]
pub struct Member<T: Config> {
    pub rank: RankLevel,
    pub joined_at: BlockNumberFor<T>,
    pub last_promoted_at: BlockNumberFor<T>,
    pub github_handle: BoundedVec<u8, ConstU32<50>>,
    pub active: bool,
}

#[frame_support::pallet]
pub mod pallet {
    use super::*;

    #[pallet::pallet]
    pub struct Pallet<T>(_);

    #[pallet::config]
    pub trait Config: frame_system::Config {
        type RuntimeEvent: From<Event<Self>> + IsType<<Self as frame_system::Config>::RuntimeEvent>;

        /// Maximum number of members
        #[pallet::constant]
        type MaxMembers: Get<u32>;
    }

    /// Storage: Members indexed by account ID
    #[pallet::storage]
    #[pallet::getter(fn members)]
    pub type Members<T: Config> = StorageMap<
        _,
        Blake2_128Concat,
        T::AccountId,
        Member<T>,
    >;

    /// Storage: Member count
    #[pallet::storage]
    #[pallet::getter(fn member_count)]
    pub type MemberCount<T> = StorageValue<_, u32, ValueQuery>;

    /// Events
    #[pallet::event]
    #[pallet::generate_deposit(pub(super) fn deposit_event)]
    pub enum Event<T: Config> {
        /// New member registered [account, rank]
        MemberRegistered { account: T::AccountId, rank: RankLevel },
        /// Member promoted [account, new_rank]
        MemberPromoted { account: T::AccountId, new_rank: RankLevel },
        /// Member suspended [account]
        MemberSuspended { account: T::AccountId },
        /// Member reactivated [account]
        MemberReactivated { account: T::AccountId },
    }

    /// Errors
    #[pallet::error]
    pub enum Error<T> {
        /// Member already registered
        MemberAlreadyExists,
        /// Member not found
        MemberNotFound,
        /// Maximum members reached
        MaxMembersReached,
        /// Invalid rank (must be 0-4)
        InvalidRank,
        /// Member already active
        MemberAlreadyActive,
        /// Member not active
        MemberNotActive,
    }

    #[pallet::call]
    impl<T: Config> Pallet<T> {
        /// Register a new member
        #[pallet::call_index(0)]
        #[pallet::weight(10_000)]
        pub fn register_member(
            origin: OriginFor<T>,
            account: T::AccountId,
            github_handle: Vec<u8>,
        ) -> DispatchResult {
            ensure_root(origin)?;

            // Check if member already exists
            ensure!(!Members::<T>::contains_key(&account), Error::<T>::MemberAlreadyExists);

            // Check max members
            let count = MemberCount::<T>::get();
            ensure!(count < T::MaxMembers::get(), Error::<T>::MaxMembersReached);

            // Create bounded github handle
            let bounded_handle: BoundedVec<u8, ConstU32<50>> = github_handle
                .try_into()
                .map_err(|_| Error::<T>::InvalidRank)?; // Reuse error for simplicity

            // Create member with rank 0
            let member = Member {
                rank: 0,
                joined_at: <frame_system::Pallet<T>>::block_number(),
                last_promoted_at: <frame_system::Pallet<T>>::block_number(),
                github_handle: bounded_handle,
                active: true,
            };

            // Store member
            Members::<T>::insert(&account, member);
            MemberCount::<T>::put(count + 1);

            // Emit event
            Self::deposit_event(Event::MemberRegistered { account, rank: 0 });

            Ok(())
        }

        /// Promote member to next rank
        #[pallet::call_index(1)]
        #[pallet::weight(10_000)]
        pub fn promote_member(
            origin: OriginFor<T>,
            account: T::AccountId,
        ) -> DispatchResult {
            ensure_root(origin)?;

            // Get member
            let mut member = Members::<T>::get(&account).ok_or(Error::<T>::MemberNotFound)?;

            // Check member is active
            ensure!(member.active, Error::<T>::MemberNotActive);

            // Check can promote (max rank is 4)
            ensure!(member.rank < 4, Error::<T>::InvalidRank);

            // Promote
            member.rank += 1;
            member.last_promoted_at = <frame_system::Pallet<T>>::block_number();

            // Update storage
            Members::<T>::insert(&account, member.clone());

            // Emit event
            Self::deposit_event(Event::MemberPromoted {
                account,
                new_rank: member.rank
            });

            Ok(())
        }

        /// Suspend member
        #[pallet::call_index(2)]
        #[pallet::weight(10_000)]
        pub fn suspend_member(
            origin: OriginFor<T>,
            account: T::AccountId,
        ) -> DispatchResult {
            ensure_root(origin)?;

            // Get member
            let mut member = Members::<T>::get(&account).ok_or(Error::<T>::MemberNotFound)?;

            // Check member is active
            ensure!(member.active, Error::<T>::MemberAlreadyActive);

            // Suspend
            member.active = false;

            // Update storage
            Members::<T>::insert(&account, member);

            // Emit event
            Self::deposit_event(Event::MemberSuspended { account });

            Ok(())
        }

        /// Reactivate suspended member
        #[pallet::call_index(3)]
        #[pallet::weight(10_000)]
        pub fn reactivate_member(
            origin: OriginFor<T>,
            account: T::AccountId,
        ) -> DispatchResult {
            ensure_root(origin)?;

            // Get member
            let mut member = Members::<T>::get(&account).ok_or(Error::<T>::MemberNotFound)?;

            // Check member is not active
            ensure!(!member.active, Error::<T>::MemberAlreadyActive);

            // Reactivate
            member.active = true;

            // Update storage
            Members::<T>::insert(&account, member);

            // Emit event
            Self::deposit_event(Event::MemberReactivated { account });

            Ok(())
        }
    }

    impl<T: Config> Pallet<T> {
        /// Calculate triangular vote weight for a rank
        /// Formula: weight(r) = r × (r + 1) / 2
        /// Results: [0, 1, 3, 6, 10] for ranks [0, 1, 2, 3, 4]
        pub fn calculate_vote_weight(rank: RankLevel) -> u64 {
            let r = rank as u64;
            r.saturating_mul(r.saturating_add(1)).saturating_div(2)
        }

        /// Calculate total vote weight for all eligible members (rank >= min_rank)
        pub fn calculate_total_vote_weight(min_rank: RankLevel) -> u64 {
            let mut total: u64 = 0;
            for (_account, member) in Members::<T>::iter() {
                if member.active && member.rank >= min_rank {
                    total = total.saturating_add(Self::calculate_vote_weight(member.rank));
                }
            }
            total
        }

        /// Get eligible voters for a rank threshold
        pub fn get_eligible_voters(min_rank: RankLevel) -> Vec<(T::AccountId, RankLevel, u64)> {
            let mut voters = Vec::new();
            for (account, member) in Members::<T>::iter() {
                if member.active && member.rank >= min_rank {
                    voters.push((
                        account,
                        member.rank,
                        Self::calculate_vote_weight(member.rank)
                    ));
                }
            }
            voters
        }
    }
}
