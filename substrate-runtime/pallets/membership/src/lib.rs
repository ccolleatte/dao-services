#![cfg_attr(not(feature = "std"), no_std)]

//! # Membership Pallet
//!
//! Rank-based membership system for DAO governance
//!
//! ## Overview
//!
//! This pallet implements a rank-based membership system with 5 tiers (0-4):
//! - Rank 0: Junior (<2 years experience) - Vote weight: 0
//! - Rank 1: Consultant (3-5 years) - Vote weight: 1
//! - Rank 2: Senior (6-10 years) - Vote weight: 3
//! - Rank 3: Manager (10-15 years) - Vote weight: 6
//! - Rank 4: Partner (15+ years) - Vote weight: 10
//!
//! ## Features
//!
//! - **Triangular vote weights**: `weight = rank × (rank + 1) / 2`
//! - **Minimum rank durations**: Enforced before promotion
//! - **Active/inactive status**: Members can be temporarily suspended
//! - **Integration with governance**: Vote weight calculation for proposals
//!
//! ## Extrinsics
//!
//! - `add_member`: Add new member with initial rank (Admin only)
//! - `promote_member`: Promote to next rank if minimum duration met
//! - `demote_member`: Demote to lower rank (Admin only)
//! - `remove_member`: Remove member from DAO (Admin only)
//! - `set_member_active`: Activate/deactivate member

// pub use pallet::*;

// #[cfg(test)]
// mod tests;

#[frame_support::pallet]
pub mod pallet {
    use frame_support::pallet_prelude::*;
    use frame_system::pallet_prelude::*;
    use sp_runtime::traits::{Saturating, Zero};
    use sp_std::vec::Vec;

    #[pallet::pallet]
    pub struct Pallet<T>(_);

    #[pallet::config]
    pub trait Config: frame_system::Config {
        /// The overarching event type.
        type RuntimeEvent: From<Event<Self>> + IsType<<Self as frame_system::Config>::RuntimeEvent>;

        /// The origin which may add/remove/promote members (typically Root or Governance).
        type AdminOrigin: EnsureOrigin<Self::RuntimeOrigin>;

        /// The origin which may activate/deactivate members.
        type ManagerOrigin: EnsureOrigin<Self::RuntimeOrigin>;
    }

    /// Member rank (0-4)
    #[derive(Clone, Encode, Decode, Eq, PartialEq, RuntimeDebug, TypeInfo, MaxEncodedLen)]
    pub enum Rank {
        Junior = 0,     // 0 vote weight
        Consultant = 1, // 1 vote weight
        Senior = 2,     // 3 vote weight
        Manager = 3,    // 6 vote weight
        Partner = 4,    // 10 vote weight
    }

    impl Rank {
        /// Calculate triangular vote weight: rank × (rank + 1) / 2
        pub fn vote_weight(&self) -> u32 {
            let r = self.clone() as u32;
            r * (r + 1) / 2
        }

        /// Get next rank (if exists)
        pub fn next(&self) -> Option<Self> {
            match self {
                Rank::Junior => Some(Rank::Consultant),
                Rank::Consultant => Some(Rank::Senior),
                Rank::Senior => Some(Rank::Manager),
                Rank::Manager => Some(Rank::Partner),
                Rank::Partner => None,
            }
        }

        /// Get previous rank (if exists)
        pub fn previous(&self) -> Option<Self> {
            match self {
                Rank::Junior => None,
                Rank::Consultant => Some(Rank::Junior),
                Rank::Senior => Some(Rank::Consultant),
                Rank::Manager => Some(Rank::Senior),
                Rank::Partner => Some(Rank::Manager),
            }
        }

        /// Minimum duration at rank before promotion (in blocks)
        /// Assuming 6s block time: 90 days = 1,296,000 blocks
        pub fn min_duration_blocks(&self) -> u32 {
            match self {
                Rank::Junior => 0,           // No minimum
                Rank::Consultant => 1_296_000, // 90 days
                Rank::Senior => 2_592_000,     // 180 days
                Rank::Manager => 5_184_000,    // 365 days
                Rank::Partner => 7_862_400,    // 547 days
            }
        }
    }

    /// Member information
    #[derive(Clone, Encode, Decode, Eq, PartialEq, RuntimeDebug, TypeInfo, MaxEncodedLen)]
    #[scale_info(skip_type_params(T))]
    pub struct MemberInfo<BlockNumber> {
        /// Current rank (0-4)
        pub rank: Rank,
        /// Block when member joined
        pub joined_at: BlockNumber,
        /// Block of last promotion
        pub last_promoted_at: BlockNumber,
        /// Active status (false = suspended)
        pub active: bool,
    }

    /// Storage: Member information by AccountId
    #[pallet::storage]
    #[pallet::getter(fn members)]
    pub type Members<T: Config> = StorageMap<
        _,
        Blake2_128Concat,
        T::AccountId,
        MemberInfo<BlockNumberFor<T>>,
        OptionQuery,
    >;

    /// Storage: Total voting weight (cached for performance)
    #[pallet::storage]
    #[pallet::getter(fn total_voting_weight)]
    pub type TotalVotingWeight<T: Config> = StorageValue<_, u32, ValueQuery>;

    /// Storage: Member count
    #[pallet::storage]
    #[pallet::getter(fn member_count)]
    pub type MemberCount<T: Config> = StorageValue<_, u32, ValueQuery>;

    #[pallet::event]
    #[pallet::generate_deposit(pub(super) fn deposit_event)]
    pub enum Event<T: Config> {
        /// Member added [who, rank]
        MemberAdded { who: T::AccountId, rank: Rank },
        /// Member promoted [who, old_rank, new_rank]
        MemberPromoted {
            who: T::AccountId,
            old_rank: Rank,
            new_rank: Rank,
        },
        /// Member demoted [who, old_rank, new_rank]
        MemberDemoted {
            who: T::AccountId,
            old_rank: Rank,
            new_rank: Rank,
        },
        /// Member removed [who]
        MemberRemoved { who: T::AccountId },
        /// Member activated [who]
        MemberActivated { who: T::AccountId },
        /// Member deactivated [who]
        MemberDeactivated { who: T::AccountId },
    }

    #[pallet::error]
    pub enum Error<T> {
        /// Member already exists
        AlreadyMember,
        /// Not a member
        NotAMember,
        /// Member is inactive
        MemberInactive,
        /// Already at maximum rank
        AlreadyMaxRank,
        /// Already at minimum rank
        AlreadyMinRank,
        /// Minimum duration at current rank not met
        MinDurationNotMet,
        /// Invalid rank value
        InvalidRank,
    }

    #[pallet::call]
    impl<T: Config> Pallet<T> {
        /// Add a new member to the DAO
        ///
        /// # Arguments
        ///
        /// * `who` - Account to add as member
        /// * `rank` - Initial rank (0-4)
        ///
        /// # Weight
        ///
        /// - Reads: 1 (Members check)
        /// - Writes: 3 (Members, MemberCount, TotalVotingWeight)
        #[pallet::call_index(0)]
        #[pallet::weight(Weight::from_parts(10_000, 0).saturating_add(T::DbWeight::get().reads_writes(1, 3)))]
        pub fn add_member(
            origin: OriginFor<T>,
            who: T::AccountId,
            rank: Rank,
        ) -> DispatchResult {
            T::AdminOrigin::ensure_origin(origin)?;

            ensure!(!Members::<T>::contains_key(&who), Error::<T>::AlreadyMember);

            let current_block = frame_system::Pallet::<T>::block_number();

            let member_info = MemberInfo {
                rank: rank.clone(),
                joined_at: current_block,
                last_promoted_at: current_block,
                active: true,
            };

            Members::<T>::insert(&who, member_info);
            MemberCount::<T>::mutate(|count| *count += 1);

            // Update total voting weight
            let vote_weight = rank.vote_weight();
            TotalVotingWeight::<T>::mutate(|total| *total += vote_weight);

            Self::deposit_event(Event::MemberAdded { who, rank });

            Ok(())
        }

        /// Promote member to next rank (if minimum duration met)
        ///
        /// # Arguments
        ///
        /// * `who` - Member to promote
        ///
        /// # Errors
        ///
        /// - `NotAMember`: Account is not a member
        /// - `AlreadyMaxRank`: Already at Partner rank (4)
        /// - `MinDurationNotMet`: Minimum duration at current rank not satisfied
        #[pallet::call_index(1)]
        #[pallet::weight(Weight::from_parts(10_000, 0).saturating_add(T::DbWeight::get().reads_writes(1, 2)))]
        pub fn promote_member(origin: OriginFor<T>, who: T::AccountId) -> DispatchResult {
            T::ManagerOrigin::ensure_origin(origin)?;

            Members::<T>::try_mutate(&who, |maybe_member| -> DispatchResult {
                let member = maybe_member.as_mut().ok_or(Error::<T>::NotAMember)?;

                let next_rank = member.rank.next().ok_or(Error::<T>::AlreadyMaxRank)?;

                // Check minimum duration at current rank
                let current_block = frame_system::Pallet::<T>::block_number();
                let time_at_rank = current_block.saturating_sub(member.last_promoted_at);
                let min_duration: BlockNumberFor<T> = next_rank.min_duration_blocks().into();

                ensure!(time_at_rank >= min_duration, Error::<T>::MinDurationNotMet);

                // Update member
                let old_rank = member.rank.clone();
                let old_weight = old_rank.vote_weight();
                let new_weight = next_rank.vote_weight();

                member.rank = next_rank.clone();
                member.last_promoted_at = current_block;

                // Update total voting weight
                TotalVotingWeight::<T>::mutate(|total| {
                    *total = total.saturating_sub(old_weight).saturating_add(new_weight);
                });

                Self::deposit_event(Event::MemberPromoted {
                    who: who.clone(),
                    old_rank,
                    new_rank: next_rank,
                });

                Ok(())
            })
        }

        /// Demote member to previous rank
        ///
        /// # Arguments
        ///
        /// * `who` - Member to demote
        ///
        /// # Errors
        ///
        /// - `NotAMember`: Account is not a member
        /// - `AlreadyMinRank`: Already at Junior rank (0)
        #[pallet::call_index(2)]
        #[pallet::weight(Weight::from_parts(10_000, 0).saturating_add(T::DbWeight::get().reads_writes(1, 2)))]
        pub fn demote_member(origin: OriginFor<T>, who: T::AccountId) -> DispatchResult {
            T::AdminOrigin::ensure_origin(origin)?;

            Members::<T>::try_mutate(&who, |maybe_member| -> DispatchResult {
                let member = maybe_member.as_mut().ok_or(Error::<T>::NotAMember)?;

                let prev_rank = member.rank.previous().ok_or(Error::<T>::AlreadyMinRank)?;

                // Update member
                let old_rank = member.rank.clone();
                let old_weight = old_rank.vote_weight();
                let new_weight = prev_rank.vote_weight();

                member.rank = prev_rank.clone();

                // Update total voting weight
                TotalVotingWeight::<T>::mutate(|total| {
                    *total = total.saturating_sub(old_weight).saturating_add(new_weight);
                });

                Self::deposit_event(Event::MemberDemoted {
                    who: who.clone(),
                    old_rank,
                    new_rank: prev_rank,
                });

                Ok(())
            })
        }

        /// Remove member from DAO
        ///
        /// # Arguments
        ///
        /// * `who` - Member to remove
        #[pallet::call_index(3)]
        #[pallet::weight(Weight::from_parts(10_000, 0).saturating_add(T::DbWeight::get().reads_writes(1, 3)))]
        pub fn remove_member(origin: OriginFor<T>, who: T::AccountId) -> DispatchResult {
            T::AdminOrigin::ensure_origin(origin)?;

            let member = Members::<T>::get(&who).ok_or(Error::<T>::NotAMember)?;

            let vote_weight = member.rank.vote_weight();

            Members::<T>::remove(&who);
            MemberCount::<T>::mutate(|count| *count = count.saturating_sub(1));

            // Update total voting weight
            TotalVotingWeight::<T>::mutate(|total| *total = total.saturating_sub(vote_weight));

            Self::deposit_event(Event::MemberRemoved { who });

            Ok(())
        }

        /// Activate or deactivate member (suspend without removing)
        ///
        /// # Arguments
        ///
        /// * `who` - Member to activate/deactivate
        /// * `active` - New active status
        #[pallet::call_index(4)]
        #[pallet::weight(Weight::from_parts(10_000, 0).saturating_add(T::DbWeight::get().reads_writes(1, 2)))]
        pub fn set_member_active(
            origin: OriginFor<T>,
            who: T::AccountId,
            active: bool,
        ) -> DispatchResult {
            T::ManagerOrigin::ensure_origin(origin)?;

            Members::<T>::try_mutate(&who, |maybe_member| -> DispatchResult {
                let member = maybe_member.as_mut().ok_or(Error::<T>::NotAMember)?;

                let vote_weight = member.rank.vote_weight();

                // Update total voting weight based on activation/deactivation
                if member.active && !active {
                    // Deactivating: subtract weight
                    TotalVotingWeight::<T>::mutate(|total| *total = total.saturating_sub(vote_weight));
                    Self::deposit_event(Event::MemberDeactivated { who: who.clone() });
                } else if !member.active && active {
                    // Activating: add weight
                    TotalVotingWeight::<T>::mutate(|total| *total = total.saturating_add(vote_weight));
                    Self::deposit_event(Event::MemberActivated { who: who.clone() });
                }

                member.active = active;

                Ok(())
            })
        }
    }

    impl<T: Config> Pallet<T> {
        /// Check if account is a member
        pub fn is_member(who: &T::AccountId) -> bool {
            Members::<T>::contains_key(who)
        }

        /// Get vote weight for member (0 if not member or inactive)
        pub fn get_vote_weight(who: &T::AccountId) -> u32 {
            Members::<T>::get(who)
                .filter(|m| m.active)
                .map(|m| m.rank.vote_weight())
                .unwrap_or(0)
        }

        /// Get member info for account
        pub fn get_member_info(who: &T::AccountId) -> Option<MemberInfo<BlockNumberFor<T>>> {
            Members::<T>::get(who)
        }

        /// Calculate total vote weight for members with rank >= min_rank
        pub fn calculate_total_vote_weight_with_min_rank(min_rank: Rank) -> u32 {
            Members::<T>::iter()
                .filter(|(_, member)| member.active && member.rank.clone() as u8 >= min_rank.clone() as u8)
                .map(|(_, member)| member.rank.vote_weight())
                .sum()
        }
    }
}
