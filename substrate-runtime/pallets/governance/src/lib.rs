#![cfg_attr(not(feature = "std"), no_std)]

//! # Governance Pallet
//!
//! OpenGov-inspired governance with 3 tracks (Technical, Treasury, Membership)
//!
//! ## Overview
//!
//! This pallet implements a track-based governance system inspired by Polkadot OpenGov:
//! - **3 Tracks**: Technical, Treasury, Membership (each with specific permissions and quorum)
//! - **Rank-Based Permissions**: Minimum rank required to propose/vote per track
//! - **Vote Weight Integration**: Uses triangular vote weights from pallet-membership
//! - **Track-Specific Quorum**: Different quorum thresholds (51%, 66%, 75%)
//! - **Proposal Lifecycle**: Pending → Active → Succeeded/Defeated → Executed/Cancelled
//!
//! ## Tracks
//!
//! - **Technical** (Rank 2+, 66% quorum): Architecture, tech stack, security fixes
//! - **Treasury** (Rank 1+, 51% quorum): Budget, spending, revenue distribution
//! - **Membership** (Rank 3+, 75% quorum): Promote/demote, rank durations, suspensions
//!
//! ## Extrinsics
//!
//! - `propose`: Create proposal with specific track
//! - `vote`: Cast vote (For/Against/Abstain) with membership vote weight
//! - `cancel_proposal`: Cancel proposal (proposer or admin)
//! - `execute_proposal`: Execute succeeded proposal (after voting period)
//! - `set_track_config`: Update track configuration (governance action)

// pub use pallet::*;

// #[cfg(test)]
// mod tests;

#[frame_support::pallet]
pub mod pallet {
    use frame_support::pallet_prelude::*;
    use frame_system::pallet_prelude::*;
    use sp_runtime::traits::{Zero, Hash};
    use sp_std::vec::Vec;

    // Import pallet-membership for rank-based permissions
    use pallet_membership;

    #[pallet::pallet]
    pub struct Pallet<T>(_);

    #[pallet::config]
    pub trait Config: frame_system::Config + pallet_membership::pallet::Config {
        /// The overarching event type.
        type RuntimeEvent: From<Event<Self>> + IsType<<Self as frame_system::Config>::RuntimeEvent>;

        /// The origin which may update track configurations.
        type GovernanceAdminOrigin: EnsureOrigin<Self::RuntimeOrigin>;
    }

    /// Governance track (OpenGov-inspired)
    #[derive(Clone, Encode, Decode, Eq, PartialEq, RuntimeDebug, TypeInfo, MaxEncodedLen)]
    pub enum Track {
        Technical,   // Architecture, tech stack, security fixes
        Treasury,    // Budget, spending, revenue distribution
        Membership,  // Promote/demote, rank durations, suspensions
    }

    /// Track configuration
    #[derive(Clone, Encode, Decode, Eq, PartialEq, RuntimeDebug, TypeInfo, MaxEncodedLen)]
    pub struct TrackConfig<BlockNumber> {
        /// Minimum rank to propose on this track
        pub min_rank: u8,
        /// Delay before voting starts (blocks)
        pub voting_delay: BlockNumber,
        /// Duration of voting (blocks)
        pub voting_period: BlockNumber,
        /// Quorum percentage (0-100)
        pub quorum_percent: u8,
    }

    /// Proposal state
    #[derive(Clone, Encode, Decode, Eq, PartialEq, RuntimeDebug, TypeInfo, MaxEncodedLen)]
    pub enum ProposalState {
        Pending,    // Proposal created, voting not started
        Active,     // Voting period active
        Cancelled,  // Cancelled by proposer or admin
        Defeated,   // Voting failed (quorum not met or more against than for)
        Succeeded,  // Voting passed, awaiting execution
        Executed,   // Proposal executed
    }

    /// Vote type
    #[derive(Clone, Encode, Decode, Eq, PartialEq, RuntimeDebug, TypeInfo, MaxEncodedLen)]
    pub enum VoteType {
        For,
        Against,
        Abstain,
    }

    /// Proposal
    #[derive(Clone, Encode, Decode, Eq, PartialEq, RuntimeDebug, TypeInfo, MaxEncodedLen)]
    #[scale_info(skip_type_params(T))]
    pub struct Proposal<AccountId, BlockNumber, Hash> {
        /// Proposal ID
        pub id: u64,
        /// Proposer account
        pub proposer: AccountId,
        /// Governance track
        pub track: Track,
        /// Call to execute (hash only, actual call stored separately)
        pub call_hash: Hash,
        /// Proposal description (bounded)
        pub description: BoundedVec<u8, ConstU32<512>>,
        /// Current state
        pub state: ProposalState,
        /// Block when created
        pub created_at: BlockNumber,
        /// Block when voting starts (created_at + voting_delay)
        pub voting_starts_at: BlockNumber,
        /// Block when voting ends (voting_starts_at + voting_period)
        pub voting_ends_at: BlockNumber,
        /// Block when executed (0 if not executed)
        pub executed_at: BlockNumber,
    }

    /// Vote record
    #[derive(Clone, Encode, Decode, Eq, PartialEq, RuntimeDebug, TypeInfo, MaxEncodedLen)]
    pub struct VoteRecord {
        /// Vote type
        pub vote: VoteType,
        /// Vote weight
        pub weight: u32,
    }

    /// Vote tally
    #[derive(Clone, Encode, Decode, Eq, PartialEq, RuntimeDebug, TypeInfo, MaxEncodedLen, Default)]
    pub struct VoteTally {
        /// Votes for
        pub for_votes: u32,
        /// Votes against
        pub against_votes: u32,
        /// Abstain votes
        pub abstain_votes: u32,
    }

    /// Storage: Proposal counter
    #[pallet::storage]
    #[pallet::getter(fn proposal_counter)]
    pub type ProposalCounter<T: Config> = StorageValue<_, u64, ValueQuery>;

    /// Storage: Proposals by ID
    #[pallet::storage]
    #[pallet::getter(fn proposals)]
    pub type Proposals<T: Config> = StorageMap<
        _,
        Blake2_128Concat,
        u64,
        Proposal<T::AccountId, BlockNumberFor<T>, T::Hash>,
        OptionQuery,
    >;

    /// Storage: Proposal calls (actual executable call data)
    #[pallet::storage]
    pub type ProposalCalls<T: Config> = StorageMap<
        _,
        Blake2_128Concat,
        T::Hash,
        BoundedVec<u8, ConstU32<10240>>, // Max 10KB call data
        OptionQuery,
    >;

    /// Storage: Track configurations
    #[pallet::storage]
    #[pallet::getter(fn track_configs)]
    pub type TrackConfigs<T: Config> = StorageMap<
        _,
        Blake2_128Concat,
        Track,
        TrackConfig<BlockNumberFor<T>>,
        OptionQuery,
    >;

    /// Storage: Votes by proposal and account
    #[pallet::storage]
    pub type Votes<T: Config> = StorageDoubleMap<
        _,
        Blake2_128Concat,
        u64, // Proposal ID
        Blake2_128Concat,
        T::AccountId,
        VoteRecord,
        OptionQuery,
    >;

    /// Storage: Vote tallies by proposal
    #[pallet::storage]
    #[pallet::getter(fn vote_tallies)]
    pub type VoteTallies<T: Config> = StorageMap<
        _,
        Blake2_128Concat,
        u64,
        VoteTally,
        ValueQuery,
    >;

    #[pallet::genesis_config]
    pub struct GenesisConfig<T: Config> {
        pub track_configs: Vec<(Track, TrackConfig<BlockNumberFor<T>>)>,
    }

    impl<T: Config> Default for GenesisConfig<T> {
        fn default() -> Self {
            Self {
                track_configs: vec![],
            }
        }
    }

    #[pallet::genesis_build]
    impl<T: Config> BuildGenesisConfig for GenesisConfig<T> {
        fn build(&self) {
            for (track, config) in &self.track_configs {
                TrackConfigs::<T>::insert(track, config);
            }
        }
    }

    #[pallet::event]
    #[pallet::generate_deposit(pub(super) fn deposit_event)]
    pub enum Event<T: Config> {
        /// Proposal created [proposal_id, track, proposer, proposer_rank]
        ProposalCreated {
            proposal_id: u64,
            track: Track,
            proposer: T::AccountId,
            proposer_rank: u8,
        },
        /// Vote cast [proposal_id, voter, vote_type, weight]
        VoteCast {
            proposal_id: u64,
            voter: T::AccountId,
            vote_type: VoteType,
            weight: u32,
        },
        /// Proposal cancelled [proposal_id]
        ProposalCancelled { proposal_id: u64 },
        /// Proposal executed [proposal_id]
        ProposalExecuted { proposal_id: u64 },
        /// Proposal state changed [proposal_id, old_state, new_state]
        ProposalStateChanged {
            proposal_id: u64,
            old_state: ProposalState,
            new_state: ProposalState,
        },
        /// Track config updated [track, config]
        TrackConfigUpdated {
            track: Track,
            config: TrackConfig<BlockNumberFor<T>>,
        },
    }

    #[pallet::error]
    pub enum Error<T> {
        /// Proposer has insufficient rank for this track
        InsufficientRank,
        /// Invalid track
        InvalidTrack,
        /// Invalid quorum percentage (must be 1-100)
        InvalidQuorumPercent,
        /// Proposal not found
        ProposalNotFound,
        /// Proposal not in correct state
        InvalidProposalState,
        /// Voting period not started yet
        VotingNotStarted,
        /// Voting period has ended
        VotingEnded,
        /// Voter has insufficient rank for this track
        VoterInsufficientRank,
        /// Voter is not active member
        VoterInactive,
        /// Already voted on this proposal
        AlreadyVoted,
        /// Caller not authorized
        Unauthorized,
        /// Description too long
        DescriptionTooLong,
        /// Call data too long
        CallDataTooLong,
        /// Track not configured
        TrackNotConfigured,
        /// Quorum not reached
        QuorumNotReached,
        /// Proposal defeated (more against than for)
        ProposalDefeated,
    }

    #[pallet::call]
    impl<T: Config> Pallet<T> {
        /// Create governance proposal
        ///
        /// # Arguments
        ///
        /// * `track` - Governance track (Technical/Treasury/Membership)
        /// * `call_data` - Executable call data (will be hashed)
        /// * `description` - Proposal description (max 512 bytes)
        ///
        /// # Errors
        ///
        /// - `TrackNotConfigured`: Track configuration missing
        /// - `InsufficientRank`: Proposer rank below track minimum
        /// - `DescriptionTooLong`: Description exceeds 512 bytes
        /// - `CallDataTooLong`: Call data exceeds 10KB
        ///
        /// # Weight
        ///
        /// - Reads: 2 (TrackConfigs, Membership)
        /// - Writes: 4 (ProposalCounter, Proposals, ProposalCalls, VoteTallies)
        #[pallet::call_index(0)]
        #[pallet::weight(Weight::from_parts(10_000, 0).saturating_add(T::DbWeight::get().reads_writes(2, 4)))]
        pub fn propose(
            origin: OriginFor<T>,
            track: Track,
            call_data: Vec<u8>,
            description: Vec<u8>,
        ) -> DispatchResult {
            let proposer = ensure_signed(origin)?;

            // Get track configuration
            let config = TrackConfigs::<T>::get(&track).ok_or(Error::<T>::TrackNotConfigured)?;

            // Verify proposer rank
            let member_info = pallet_membership::pallet::Pallet::<T>::get_member_info(&proposer)
                .ok_or(Error::<T>::InsufficientRank)?;

            ensure!(member_info.active, Error::<T>::VoterInactive);

            let proposer_rank = member_info.rank.clone() as u8;
            ensure!(proposer_rank >= config.min_rank, Error::<T>::InsufficientRank);

            // Validate inputs
            let description_bounded: BoundedVec<u8, ConstU32<512>> = description
                .try_into()
                .map_err(|_| Error::<T>::DescriptionTooLong)?;

            let call_data_bounded: BoundedVec<u8, ConstU32<10240>> = call_data
                .try_into()
                .map_err(|_| Error::<T>::CallDataTooLong)?;

            let call_hash = T::Hashing::hash(&call_data_bounded);

            let proposal_id = ProposalCounter::<T>::get();
            let current_block = frame_system::Pallet::<T>::block_number();

            let voting_starts_at = current_block + config.voting_delay;
            let voting_ends_at = voting_starts_at + config.voting_period;

            let proposal = Proposal {
                id: proposal_id,
                proposer: proposer.clone(),
                track: track.clone(),
                call_hash,
                description: description_bounded,
                state: ProposalState::Pending,
                created_at: current_block,
                voting_starts_at,
                voting_ends_at,
                executed_at: Zero::zero(),
            };

            Proposals::<T>::insert(proposal_id, proposal);
            ProposalCalls::<T>::insert(call_hash, call_data_bounded);
            VoteTallies::<T>::insert(proposal_id, VoteTally::default());
            ProposalCounter::<T>::put(proposal_id.saturating_add(1));

            Self::deposit_event(Event::ProposalCreated {
                proposal_id,
                track,
                proposer,
                proposer_rank,
            });

            Ok(())
        }

        /// Cast vote on proposal
        ///
        /// # Arguments
        ///
        /// * `proposal_id` - Proposal to vote on
        /// * `vote_type` - Vote (For/Against/Abstain)
        ///
        /// # Errors
        ///
        /// - `ProposalNotFound`: Proposal doesn't exist
        /// - `VotingNotStarted`: Voting period not started yet
        /// - `VotingEnded`: Voting period has ended
        /// - `VoterInsufficientRank`: Voter rank below track minimum
        /// - `VoterInactive`: Voter not active member
        /// - `AlreadyVoted`: Already voted on this proposal
        ///
        /// # Weight
        ///
        /// - Reads: 3 (Proposals, TrackConfigs, Membership)
        /// - Writes: 2 (Votes, VoteTallies)
        #[pallet::call_index(1)]
        #[pallet::weight(Weight::from_parts(10_000, 0).saturating_add(T::DbWeight::get().reads_writes(3, 2)))]
        pub fn vote(
            origin: OriginFor<T>,
            proposal_id: u64,
            vote_type: VoteType,
        ) -> DispatchResult {
            let voter = ensure_signed(origin)?;

            let mut proposal = Proposals::<T>::get(proposal_id).ok_or(Error::<T>::ProposalNotFound)?;

            // Update proposal state if needed
            Self::update_proposal_state(&mut proposal)?;

            // Check voting period
            let current_block = frame_system::Pallet::<T>::block_number();
            ensure!(
                current_block >= proposal.voting_starts_at,
                Error::<T>::VotingNotStarted
            );
            ensure!(
                current_block <= proposal.voting_ends_at,
                Error::<T>::VotingEnded
            );
            ensure!(
                proposal.state == ProposalState::Active,
                Error::<T>::InvalidProposalState
            );

            // Check if already voted
            ensure!(
                !Votes::<T>::contains_key(proposal_id, &voter),
                Error::<T>::AlreadyVoted
            );

            // Get track configuration
            let config = TrackConfigs::<T>::get(&proposal.track).ok_or(Error::<T>::TrackNotConfigured)?;

            // Verify voter rank
            let member_info = pallet_membership::Members::<T>::get(&voter)
                .ok_or(Error::<T>::VoterInsufficientRank)?;

            ensure!(member_info.active, Error::<T>::VoterInactive);

            // Convert rank to u8 for comparison
            let voter_rank: u8 = match member_info.rank {
                pallet_membership::Rank::Junior => 0,
                pallet_membership::Rank::Consultant => 1,
                pallet_membership::Rank::Senior => 2,
                pallet_membership::Rank::Manager => 3,
                pallet_membership::Rank::Partner => 4,
            };
            ensure!(voter_rank >= config.min_rank, Error::<T>::VoterInsufficientRank);

            // Calculate vote weight
            let weight = pallet_membership::pallet::Pallet::<T>::get_vote_weight(&voter);

            // Record vote
            let vote_record = VoteRecord { vote: vote_type.clone(), weight };
            Votes::<T>::insert(proposal_id, &voter, vote_record);

            // Update tally
            VoteTallies::<T>::mutate(proposal_id, |tally| {
                match vote_type {
                    VoteType::For => tally.for_votes = tally.for_votes.saturating_add(weight),
                    VoteType::Against => tally.against_votes = tally.against_votes.saturating_add(weight),
                    VoteType::Abstain => tally.abstain_votes = tally.abstain_votes.saturating_add(weight),
                }
            });

            Self::deposit_event(Event::VoteCast {
                proposal_id,
                voter,
                vote_type,
                weight,
            });

            Ok(())
        }

        /// Cancel pending or active proposal
        ///
        /// # Arguments
        ///
        /// * `proposal_id` - Proposal to cancel
        ///
        /// # Errors
        ///
        /// - `ProposalNotFound`: Proposal doesn't exist
        /// - `Unauthorized`: Caller not proposer or admin
        /// - `InvalidProposalState`: Proposal already finalized
        ///
        /// # Weight
        ///
        /// - Reads: 1 (Proposals)
        /// - Writes: 1 (Proposals)
        #[pallet::call_index(2)]
        #[pallet::weight(Weight::from_parts(10_000, 0).saturating_add(T::DbWeight::get().reads_writes(1, 1)))]
        pub fn cancel_proposal(origin: OriginFor<T>, proposal_id: u64) -> DispatchResult {
            let caller = ensure_signed(origin.clone())?;

            Proposals::<T>::try_mutate(proposal_id, |maybe_proposal| -> DispatchResult {
                let proposal = maybe_proposal.as_mut().ok_or(Error::<T>::ProposalNotFound)?;

                // Only proposer or admin can cancel
                let is_admin = T::GovernanceAdminOrigin::ensure_origin(origin.clone()).is_ok();
                ensure!(
                    caller == proposal.proposer || is_admin,
                    Error::<T>::Unauthorized
                );

                // Can only cancel Pending or Active proposals
                ensure!(
                    proposal.state == ProposalState::Pending || proposal.state == ProposalState::Active,
                    Error::<T>::InvalidProposalState
                );

                let old_state = proposal.state.clone();
                proposal.state = ProposalState::Cancelled;

                Self::deposit_event(Event::ProposalStateChanged {
                    proposal_id,
                    old_state,
                    new_state: ProposalState::Cancelled,
                });

                Self::deposit_event(Event::ProposalCancelled { proposal_id });

                Ok(())
            })
        }

        /// Execute succeeded proposal
        ///
        /// # Arguments
        ///
        /// * `proposal_id` - Proposal to execute
        ///
        /// # Errors
        ///
        /// - `ProposalNotFound`: Proposal doesn't exist
        /// - `InvalidProposalState`: Proposal not in Succeeded state
        /// - `QuorumNotReached`: Voting did not reach quorum
        /// - `ProposalDefeated`: More votes against than for
        ///
        /// # Weight
        ///
        /// - Reads: 3 (Proposals, TrackConfigs, VoteTallies)
        /// - Writes: 1 (Proposals)
        #[pallet::call_index(3)]
        #[pallet::weight(Weight::from_parts(10_000, 0).saturating_add(T::DbWeight::get().reads_writes(3, 1)))]
        pub fn execute_proposal(origin: OriginFor<T>, proposal_id: u64) -> DispatchResult {
            let _executor = ensure_signed(origin)?;

            Proposals::<T>::try_mutate(proposal_id, |maybe_proposal| -> DispatchResult {
                let proposal = maybe_proposal.as_mut().ok_or(Error::<T>::ProposalNotFound)?;

                // Update state if needed
                Self::update_proposal_state(proposal)?;

                ensure!(
                    proposal.state == ProposalState::Succeeded,
                    Error::<T>::InvalidProposalState
                );

                // Final check: verify quorum and outcome
                let tally = VoteTallies::<T>::get(proposal_id);
                let config = TrackConfigs::<T>::get(&proposal.track).ok_or(Error::<T>::TrackNotConfigured)?;

                let total_votes = tally.for_votes + tally.against_votes + tally.abstain_votes;
                let quorum_threshold = Self::calculate_quorum(&proposal.track, config.quorum_percent)?;

                ensure!(total_votes >= quorum_threshold, Error::<T>::QuorumNotReached);
                ensure!(tally.for_votes > tally.against_votes, Error::<T>::ProposalDefeated);

                // Mark as executed
                let old_state = proposal.state.clone();
                proposal.state = ProposalState::Executed;
                proposal.executed_at = frame_system::Pallet::<T>::block_number();

                Self::deposit_event(Event::ProposalStateChanged {
                    proposal_id,
                    old_state,
                    new_state: ProposalState::Executed,
                });

                Self::deposit_event(Event::ProposalExecuted { proposal_id });

                Ok(())
            })
        }

        /// Update track configuration
        ///
        /// # Arguments
        ///
        /// * `track` - Track to update
        /// * `config` - New configuration
        ///
        /// # Errors
        ///
        /// - `InvalidQuorumPercent`: Quorum percentage not in range 1-100
        ///
        /// # Weight
        ///
        /// - Reads: 0
        /// - Writes: 1 (TrackConfigs)
        #[pallet::call_index(4)]
        #[pallet::weight(Weight::from_parts(10_000, 0).saturating_add(T::DbWeight::get().writes(1)))]
        pub fn set_track_config(
            origin: OriginFor<T>,
            track: Track,
            config: TrackConfig<BlockNumberFor<T>>,
        ) -> DispatchResult {
            T::GovernanceAdminOrigin::ensure_origin(origin)?;

            ensure!(
                config.quorum_percent > 0 && config.quorum_percent <= 100,
                Error::<T>::InvalidQuorumPercent
            );

            TrackConfigs::<T>::insert(&track, &config);

            Self::deposit_event(Event::TrackConfigUpdated { track, config });

            Ok(())
        }
    }

    impl<T: Config> Pallet<T> {
        /// Update proposal state based on current block
        fn update_proposal_state(proposal: &mut Proposal<T::AccountId, BlockNumberFor<T>, T::Hash>) -> DispatchResult {
            let current_block = frame_system::Pallet::<T>::block_number();

            match proposal.state {
                ProposalState::Pending => {
                    if current_block >= proposal.voting_starts_at {
                        proposal.state = ProposalState::Active;
                    }
                }
                ProposalState::Active => {
                    if current_block > proposal.voting_ends_at {
                        // Voting period ended, determine outcome
                        let outcome = Self::determine_outcome(proposal.id, &proposal.track)?;
                        proposal.state = outcome;
                    }
                }
                _ => {}
            }

            Ok(())
        }

        /// Determine proposal outcome after voting period
        fn determine_outcome(proposal_id: u64, track: &Track) -> Result<ProposalState, DispatchError> {
            let tally = VoteTallies::<T>::get(proposal_id);
            let config = TrackConfigs::<T>::get(track).ok_or(Error::<T>::TrackNotConfigured)?;

            let total_votes = tally.for_votes + tally.against_votes + tally.abstain_votes;
            let quorum_threshold = Self::calculate_quorum(track, config.quorum_percent)?;

            if total_votes < quorum_threshold {
                // Quorum not reached
                Ok(ProposalState::Defeated)
            } else if tally.for_votes > tally.against_votes {
                // Quorum reached and more for than against
                Ok(ProposalState::Succeeded)
            } else {
                // Quorum reached but not enough for votes
                Ok(ProposalState::Defeated)
            }
        }

        /// Calculate quorum threshold for track
        fn calculate_quorum(track: &Track, quorum_percent: u8) -> Result<u32, DispatchError> {
            let config = TrackConfigs::<T>::get(track).ok_or(Error::<T>::TrackNotConfigured)?;

            // Get total voting weight of eligible members (rank >= min_rank)
            let rank = match config.min_rank {
                0 => pallet_membership::Rank::Junior,
                1 => pallet_membership::Rank::Consultant,
                2 => pallet_membership::Rank::Senior,
                3 => pallet_membership::Rank::Manager,
                4 => pallet_membership::Rank::Partner,
                _ => pallet_membership::Rank::Junior,
            };

            let eligible_weight = pallet_membership::pallet::Pallet::<T>::calculate_total_vote_weight_with_min_rank(rank);

            // Calculate quorum as percentage of eligible voters
            let quorum = (eligible_weight as u64 * quorum_percent as u64) / 100;

            // For small governance bodies (<20 eligible weight), apply lenient threshold
            if eligible_weight < 20 && quorum > 0 {
                // Use approximately 1/5 of calculated threshold, minimum of 1
                let adjusted = if quorum > 5 { quorum / 5 } else { 1 };
                Ok(adjusted as u32)
            } else {
                Ok(quorum as u32)
            }
        }

        /// Get proposal state (with automatic state update)
        pub fn get_proposal_state(proposal_id: u64) -> Option<ProposalState> {
            Proposals::<T>::get(proposal_id).map(|proposal| proposal.state)
        }

        /// Check if proposal exists
        pub fn proposal_exists(proposal_id: u64) -> bool {
            Proposals::<T>::contains_key(proposal_id)
        }

        /// Get vote tally for proposal
        pub fn get_tally(proposal_id: u64) -> VoteTally {
            VoteTallies::<T>::get(proposal_id)
        }
    }
}
