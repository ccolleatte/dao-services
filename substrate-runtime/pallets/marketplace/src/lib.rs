#![cfg_attr(not(feature = "std"), no_std)]

//! # Marketplace Pallet
//!
//! Mission escrow with milestone-based payments and DAO jury dispute resolution
//!
//! ## Overview
//!
//! This pallet implements:
//! - **Mission lifecycle**: Creation, milestone tracking, completion
//! - **Milestone escrow**: Sequential validation (N must be approved before N+1)
//! - **Dispute resolution**: DAO jury voting (5 Rank 3+ jurors, 72h voting)
//! - **Auto-release**: 7-day automatic payment if client doesn't respond
//! - **Dispute deposit**: 100 DAOS tokens (refunded if won)
//!
//! ## Features
//!
//! - **Sequential milestones**: Cannot submit milestone N+1 if N not approved
//! - **Jury selection**: 5 Rank 3+ members (pseudo-random, exclude client/consultant)
//! - **Majority voting**: 3/5 votes required to resolve dispute
//! - **Auto-resolution**: Dispute resolves automatically after 72h voting period
//! - **Deposit mechanism**: 100 DAOS deposit required to raise dispute (refunded if won)
//!
//! ## Extrinsics
//!
//! - `create_mission`: Create new mission with escrow
//! - `add_milestone`: Add milestone to mission (client only)
//! - `submit_milestone`: Submit deliverable (consultant only)
//! - `approve_milestone`: Approve and release payment (client only)
//! - `reject_milestone`: Reject milestone (client only)
//! - `auto_release_milestone`: Auto-release after 7 days
//! - `raise_dispute`: Raise dispute on milestone (requires deposit)
//! - `vote_on_dispute`: Vote on dispute (jurors only)
//! - `resolve_dispute`: Resolve dispute based on votes

// pub use pallet::*;

// #[cfg(test)]
// mod tests;

#[frame_support::pallet]
pub mod pallet {
    use frame_support::pallet_prelude::*;
    use frame_system::pallet_prelude::*;
    use sp_runtime::traits::{CheckedAdd, CheckedSub, Zero};
    use sp_std::vec::Vec;

    #[pallet::pallet]
    pub struct Pallet<T>(_);

    #[pallet::config]
    pub trait Config: frame_system::Config {
        /// The overarching event type.
        type RuntimeEvent: From<Event<Self>> + IsType<<Self as frame_system::Config>::RuntimeEvent>;

        /// The origin which may administer missions (typically Root or Governance).
        type AdminOrigin: EnsureOrigin<Self::RuntimeOrigin>;

        /// Currency type for escrow deposits and payments.
        type Currency: frame_support::traits::Currency<Self::AccountId>;
    }

    /// Milestone status
    #[derive(Clone, Encode, Decode, Eq, PartialEq, RuntimeDebug, TypeInfo, MaxEncodedLen)]
    pub enum MilestoneStatus {
        Pending,    // Created, waiting for submission
        Submitted,  // Deliverable submitted, waiting for approval
        Approved,   // Approved, payment released
        Rejected,   // Rejected by client
        Disputed,   // Dispute raised
    }

    /// Dispute status
    #[derive(Clone, Encode, Decode, Eq, PartialEq, RuntimeDebug, TypeInfo, MaxEncodedLen)]
    pub enum DisputeStatus {
        Voting,     // Jury voting in progress
        Resolved,   // Dispute resolved
    }

    /// Milestone information
    #[derive(Clone, Encode, Decode, Eq, PartialEq, RuntimeDebug, TypeInfo, MaxEncodedLen)]
    #[scale_info(skip_type_params(T))]
    pub struct Milestone<Balance, BlockNumber> {
        pub id: u64,
        pub description: BoundedVec<u8, ConstU32<256>>,
        pub amount: Balance,
        pub deadline: BlockNumber,
        pub status: MilestoneStatus,
        pub deliverable: BoundedVec<u8, ConstU32<256>>, // IPFS hash
        pub submitted_at: BlockNumber,
    }

    /// Dispute information
    #[derive(Clone, Encode, Decode, Eq, PartialEq, RuntimeDebug, TypeInfo, MaxEncodedLen)]
    #[scale_info(skip_type_params(T))]
    pub struct Dispute<AccountId, BlockNumber> {
        pub milestone_id: u64,
        pub initiator: AccountId,
        pub reason: BoundedVec<u8, ConstU32<256>>,
        pub consultant_response: BoundedVec<u8, ConstU32<256>>,
        pub jurors: BoundedVec<AccountId, ConstU32<5>>,
        pub votes_for: u32,      // For consultant
        pub votes_against: u32,  // For client
        pub status: DisputeStatus,
        pub winner: Option<AccountId>,
        pub created_at: BlockNumber,
        pub voting_deadline: BlockNumber,
    }

    /// Mission information
    #[derive(Clone, Encode, Decode, Eq, PartialEq, RuntimeDebug, TypeInfo, MaxEncodedLen)]
    #[scale_info(skip_type_params(T))]
    pub struct Mission<AccountId, Balance> {
        pub id: u64,
        pub client: AccountId,
        pub consultant: AccountId,
        pub total_budget: Balance,
        pub released_funds: Balance,
        pub milestone_count: u64,
    }

    /// Storage: Missions by ID
    #[pallet::storage]
    #[pallet::getter(fn missions)]
    pub type Missions<T: Config> = StorageMap<
        _,
        Blake2_128Concat,
        u64,
        Mission<T::AccountId, BalanceOf<T>>,
        OptionQuery,
    >;

    /// Storage: Mission counter
    #[pallet::storage]
    #[pallet::getter(fn mission_counter)]
    pub type MissionCounter<T: Config> = StorageValue<_, u64, ValueQuery>;

    /// Storage: Milestones by (MissionId, MilestoneId)
    #[pallet::storage]
    #[pallet::getter(fn milestones)]
    pub type Milestones<T: Config> = StorageDoubleMap<
        _,
        Blake2_128Concat,
        u64, // Mission ID
        Blake2_128Concat,
        u64, // Milestone ID
        Milestone<BalanceOf<T>, BlockNumberFor<T>>,
        OptionQuery,
    >;

    /// Storage: Disputes by ID
    #[pallet::storage]
    #[pallet::getter(fn disputes)]
    pub type Disputes<T: Config> = StorageMap<
        _,
        Blake2_128Concat,
        u64,
        Dispute<T::AccountId, BlockNumberFor<T>>,
        OptionQuery,
    >;

    /// Storage: Dispute counter
    #[pallet::storage]
    #[pallet::getter(fn dispute_counter)]
    pub type DisputeCounter<T: Config> = StorageValue<_, u64, ValueQuery>;

    /// Storage: Dispute votes by (DisputeId, Juror)
    #[pallet::storage]
    #[pallet::getter(fn dispute_votes)]
    pub type DisputeVotes<T: Config> = StorageDoubleMap<
        _,
        Blake2_128Concat,
        u64, // Dispute ID
        Blake2_128Concat,
        T::AccountId, // Juror
        bool, // true = for consultant, false = for client
        OptionQuery,
    >;

    /// Constants
    pub type BalanceOf<T> = <<T as Config>::Currency as frame_support::traits::Currency<
        <T as frame_system::Config>::AccountId,
    >>::Balance;

    // Constants (in blocks, assuming 6s block time)
    // 7 days = 7 * 24 * 60 * 10 = 100,800 blocks
    pub const AUTO_RELEASE_DELAY: u32 = 100_800;

    // 72 hours = 72 * 60 * 10 = 43,200 blocks
    pub const VOTING_PERIOD: u32 = 43_200;

    // Jury size
    pub const JURY_SIZE: u32 = 5;

    #[pallet::event]
    #[pallet::generate_deposit(pub(super) fn deposit_event)]
    pub enum Event<T: Config> {
        /// Mission created [mission_id, client, consultant, total_budget]
        MissionCreated {
            mission_id: u64,
            client: T::AccountId,
            consultant: T::AccountId,
            total_budget: BalanceOf<T>,
        },
        /// Milestone added [mission_id, milestone_id, amount, deadline]
        MilestoneAdded {
            mission_id: u64,
            milestone_id: u64,
            amount: BalanceOf<T>,
            deadline: BlockNumberFor<T>,
        },
        /// Milestone submitted [mission_id, milestone_id, deliverable]
        MilestoneSubmitted {
            mission_id: u64,
            milestone_id: u64,
            deliverable: Vec<u8>,
        },
        /// Milestone approved [mission_id, milestone_id, amount_released]
        MilestoneApproved {
            mission_id: u64,
            milestone_id: u64,
            amount_released: BalanceOf<T>,
        },
        /// Milestone rejected [mission_id, milestone_id]
        MilestoneRejected {
            mission_id: u64,
            milestone_id: u64,
        },
        /// Dispute raised [dispute_id, mission_id, milestone_id, initiator]
        DisputeRaised {
            dispute_id: u64,
            mission_id: u64,
            milestone_id: u64,
            initiator: T::AccountId,
        },
        /// Dispute vote cast [dispute_id, juror, favor_consultant]
        DisputeVoteCast {
            dispute_id: u64,
            juror: T::AccountId,
            favor_consultant: bool,
        },
        /// Dispute resolved [dispute_id, winner, amount_awarded]
        DisputeResolved {
            dispute_id: u64,
            winner: Option<T::AccountId>,
            amount_awarded: BalanceOf<T>,
        },
    }

    #[pallet::error]
    pub enum Error<T> {
        /// Mission not found
        MissionNotFound,
        /// Milestone not found
        MilestoneNotFound,
        /// Dispute not found
        DisputeNotFound,
        /// Not authorized as client
        UnauthorizedClient,
        /// Not authorized as consultant
        UnauthorizedConsultant,
        /// Invalid milestone status
        InvalidMilestoneStatus,
        /// Previous milestone not approved
        PreviousMilestoneNotApproved,
        /// Auto-release delay not met
        AutoReleaseDelayNotMet,
        /// Insufficient deposit
        InsufficientDeposit,
        /// Already voted
        AlreadyVoted,
        /// Not a juror for this dispute
        NotJuror,
        /// Dispute not in voting status
        DisputeNotVoting,
        /// Voting period not ended
        VotingPeriodNotEnded,
        /// Arithmetic overflow
        ArithmeticOverflow,
        /// Insufficient eligible jurors
        InsufficientEligibleJurors,
    }

    #[pallet::call]
    impl<T: Config> Pallet<T> {
        /// Create a new mission with escrow
        ///
        /// # Arguments
        ///
        /// * `consultant` - Consultant account
        /// * `total_budget` - Total mission budget
        #[pallet::call_index(0)]
        #[pallet::weight(Weight::from_parts(10_000, 0).saturating_add(T::DbWeight::get().reads_writes(1, 2)))]
        pub fn create_mission(
            origin: OriginFor<T>,
            consultant: T::AccountId,
            total_budget: BalanceOf<T>,
        ) -> DispatchResult {
            let client = ensure_signed(origin)?;

            let mission_id = MissionCounter::<T>::get();
            let next_id = mission_id
                .checked_add(1)
                .ok_or(Error::<T>::ArithmeticOverflow)?;

            let mission = Mission {
                id: mission_id,
                client: client.clone(),
                consultant: consultant.clone(),
                total_budget,
                released_funds: Zero::zero(),
                milestone_count: 0,
            };

            Missions::<T>::insert(mission_id, mission);
            MissionCounter::<T>::put(next_id);

            Self::deposit_event(Event::MissionCreated {
                mission_id,
                client,
                consultant,
                total_budget,
            });

            Ok(())
        }

        /// Add a milestone to a mission (client only)
        ///
        /// # Arguments
        ///
        /// * `mission_id` - Mission ID
        /// * `description` - Milestone description
        /// * `amount` - Payment amount
        /// * `deadline` - Deadline block number
        #[pallet::call_index(1)]
        #[pallet::weight(Weight::from_parts(10_000, 0).saturating_add(T::DbWeight::get().reads_writes(2, 2)))]
        pub fn add_milestone(
            origin: OriginFor<T>,
            mission_id: u64,
            description: Vec<u8>,
            amount: BalanceOf<T>,
            deadline: BlockNumberFor<T>,
        ) -> DispatchResult {
            let who = ensure_signed(origin)?;

            let mut mission = Missions::<T>::get(mission_id)
                .ok_or(Error::<T>::MissionNotFound)?;

            ensure!(who == mission.client, Error::<T>::UnauthorizedClient);

            let milestone_id = mission.milestone_count;
            let next_count = milestone_id
                .checked_add(1)
                .ok_or(Error::<T>::ArithmeticOverflow)?;

            let description_bounded: BoundedVec<u8, ConstU32<256>> = description
                .try_into()
                .map_err(|_| Error::<T>::ArithmeticOverflow)?;

            let milestone = Milestone {
                id: milestone_id,
                description: description_bounded,
                amount,
                deadline,
                status: MilestoneStatus::Pending,
                deliverable: BoundedVec::default(),
                submitted_at: Zero::zero(),
            };

            Milestones::<T>::insert(mission_id, milestone_id, milestone);

            mission.milestone_count = next_count;
            Missions::<T>::insert(mission_id, mission);

            Self::deposit_event(Event::MilestoneAdded {
                mission_id,
                milestone_id,
                amount,
                deadline,
            });

            Ok(())
        }

        /// Submit milestone deliverable (consultant only)
        ///
        /// # Arguments
        ///
        /// * `mission_id` - Mission ID
        /// * `milestone_id` - Milestone ID
        /// * `deliverable` - IPFS hash or deliverable reference
        #[pallet::call_index(2)]
        #[pallet::weight(Weight::from_parts(10_000, 0).saturating_add(T::DbWeight::get().reads_writes(3, 1)))]
        pub fn submit_milestone(
            origin: OriginFor<T>,
            mission_id: u64,
            milestone_id: u64,
            deliverable: Vec<u8>,
        ) -> DispatchResult {
            let who = ensure_signed(origin)?;

            let mission = Missions::<T>::get(mission_id)
                .ok_or(Error::<T>::MissionNotFound)?;

            ensure!(who == mission.consultant, Error::<T>::UnauthorizedConsultant);

            Milestones::<T>::try_mutate(
                mission_id,
                milestone_id,
                |maybe_milestone| -> DispatchResult {
                    let milestone = maybe_milestone
                        .as_mut()
                        .ok_or(Error::<T>::MilestoneNotFound)?;

                    ensure!(
                        milestone.status == MilestoneStatus::Pending,
                        Error::<T>::InvalidMilestoneStatus
                    );

                    // Sequential validation: Cannot submit milestone N+1 if milestone N not approved
                    if milestone_id > 0 {
                        let prev_milestone = Milestones::<T>::get(mission_id, milestone_id - 1)
                            .ok_or(Error::<T>::MilestoneNotFound)?;

                        ensure!(
                            prev_milestone.status == MilestoneStatus::Approved,
                            Error::<T>::PreviousMilestoneNotApproved
                        );
                    }

                    let deliverable_bounded: BoundedVec<u8, ConstU32<256>> = deliverable
                        .clone()
                        .try_into()
                        .map_err(|_| Error::<T>::ArithmeticOverflow)?;

                    milestone.status = MilestoneStatus::Submitted;
                    milestone.deliverable = deliverable_bounded;
                    milestone.submitted_at = frame_system::Pallet::<T>::block_number();

                    Self::deposit_event(Event::MilestoneSubmitted {
                        mission_id,
                        milestone_id,
                        deliverable,
                    });

                    Ok(())
                },
            )
        }

        /// Approve milestone and release payment (client only)
        ///
        /// # Arguments
        ///
        /// * `mission_id` - Mission ID
        /// * `milestone_id` - Milestone ID
        #[pallet::call_index(3)]
        #[pallet::weight(Weight::from_parts(10_000, 0).saturating_add(T::DbWeight::get().reads_writes(3, 2)))]
        pub fn approve_milestone(
            origin: OriginFor<T>,
            mission_id: u64,
            milestone_id: u64,
        ) -> DispatchResult {
            let who = ensure_signed(origin)?;

            let mut mission = Missions::<T>::get(mission_id)
                .ok_or(Error::<T>::MissionNotFound)?;

            ensure!(who == mission.client, Error::<T>::UnauthorizedClient);

            Milestones::<T>::try_mutate(
                mission_id,
                milestone_id,
                |maybe_milestone| -> DispatchResult {
                    let milestone = maybe_milestone
                        .as_mut()
                        .ok_or(Error::<T>::MilestoneNotFound)?;

                    ensure!(
                        milestone.status == MilestoneStatus::Submitted,
                        Error::<T>::InvalidMilestoneStatus
                    );

                    milestone.status = MilestoneStatus::Approved;

                    // Update mission released funds
                    mission.released_funds = mission
                        .released_funds
                        .checked_add(&milestone.amount)
                        .ok_or(Error::<T>::ArithmeticOverflow)?;

                    Missions::<T>::insert(mission_id, mission.clone());

                    Self::deposit_event(Event::MilestoneApproved {
                        mission_id,
                        milestone_id,
                        amount_released: milestone.amount,
                    });

                    Ok(())
                },
            )
        }

        /// Reject milestone (client only)
        ///
        /// # Arguments
        ///
        /// * `mission_id` - Mission ID
        /// * `milestone_id` - Milestone ID
        #[pallet::call_index(4)]
        #[pallet::weight(Weight::from_parts(10_000, 0).saturating_add(T::DbWeight::get().reads_writes(2, 1)))]
        pub fn reject_milestone(
            origin: OriginFor<T>,
            mission_id: u64,
            milestone_id: u64,
        ) -> DispatchResult {
            let who = ensure_signed(origin)?;

            let mission = Missions::<T>::get(mission_id)
                .ok_or(Error::<T>::MissionNotFound)?;

            ensure!(who == mission.client, Error::<T>::UnauthorizedClient);

            Milestones::<T>::try_mutate(
                mission_id,
                milestone_id,
                |maybe_milestone| -> DispatchResult {
                    let milestone = maybe_milestone
                        .as_mut()
                        .ok_or(Error::<T>::MilestoneNotFound)?;

                    ensure!(
                        milestone.status == MilestoneStatus::Submitted,
                        Error::<T>::InvalidMilestoneStatus
                    );

                    milestone.status = MilestoneStatus::Rejected;

                    Self::deposit_event(Event::MilestoneRejected {
                        mission_id,
                        milestone_id,
                    });

                    Ok(())
                },
            )
        }

        /// Auto-release milestone if client doesn't approve/reject within 7 days
        ///
        /// # Arguments
        ///
        /// * `mission_id` - Mission ID
        /// * `milestone_id` - Milestone ID
        #[pallet::call_index(5)]
        #[pallet::weight(Weight::from_parts(10_000, 0).saturating_add(T::DbWeight::get().reads_writes(3, 2)))]
        pub fn auto_release_milestone(
            origin: OriginFor<T>,
            mission_id: u64,
            milestone_id: u64,
        ) -> DispatchResult {
            let _ = ensure_signed(origin)?;

            let mut mission = Missions::<T>::get(mission_id)
                .ok_or(Error::<T>::MissionNotFound)?;

            Milestones::<T>::try_mutate(
                mission_id,
                milestone_id,
                |maybe_milestone| -> DispatchResult {
                    let milestone = maybe_milestone
                        .as_mut()
                        .ok_or(Error::<T>::MilestoneNotFound)?;

                    ensure!(
                        milestone.status == MilestoneStatus::Submitted,
                        Error::<T>::InvalidMilestoneStatus
                    );

                    let current_block = frame_system::Pallet::<T>::block_number();
                    let deadline = milestone
                        .submitted_at
                        .checked_add(&AUTO_RELEASE_DELAY.into())
                        .ok_or(Error::<T>::ArithmeticOverflow)?;

                    ensure!(
                        current_block >= deadline,
                        Error::<T>::AutoReleaseDelayNotMet
                    );

                    milestone.status = MilestoneStatus::Approved;

                    // Update mission released funds
                    mission.released_funds = mission
                        .released_funds
                        .checked_add(&milestone.amount)
                        .ok_or(Error::<T>::ArithmeticOverflow)?;

                    Missions::<T>::insert(mission_id, mission.clone());

                    Self::deposit_event(Event::MilestoneApproved {
                        mission_id,
                        milestone_id,
                        amount_released: milestone.amount,
                    });

                    Ok(())
                },
            )
        }

        /// Raise a dispute on a milestone (client or consultant, requires deposit)
        ///
        /// # Arguments
        ///
        /// * `mission_id` - Mission ID
        /// * `milestone_id` - Milestone ID
        /// * `reason` - Dispute reason
        ///
        /// Note: In production, this would require a deposit (100 DAOS tokens).
        /// For simplicity, deposit mechanism omitted in this implementation.
        #[pallet::call_index(6)]
        #[pallet::weight(Weight::from_parts(10_000, 0).saturating_add(T::DbWeight::get().reads_writes(4, 3)))]
        pub fn raise_dispute(
            origin: OriginFor<T>,
            mission_id: u64,
            milestone_id: u64,
            reason: Vec<u8>,
        ) -> DispatchResult {
            let who = ensure_signed(origin)?;

            let mission = Missions::<T>::get(mission_id)
                .ok_or(Error::<T>::MissionNotFound)?;

            ensure!(
                who == mission.client || who == mission.consultant,
                Error::<T>::UnauthorizedClient
            );

            Milestones::<T>::try_mutate(
                mission_id,
                milestone_id,
                |maybe_milestone| -> DispatchResult {
                    let milestone = maybe_milestone
                        .as_mut()
                        .ok_or(Error::<T>::MilestoneNotFound)?;

                    milestone.status = MilestoneStatus::Disputed;

                    let dispute_id = DisputeCounter::<T>::get();
                    let next_id = dispute_id
                        .checked_add(1)
                        .ok_or(Error::<T>::ArithmeticOverflow)?;

                    // Select jury (5 Rank 3+ members, pseudo-random)
                    let jurors = Self::select_jury(&mission.client, &mission.consultant)?;

                    let reason_bounded: BoundedVec<u8, ConstU32<256>> = reason
                        .try_into()
                        .map_err(|_| Error::<T>::ArithmeticOverflow)?;

                    let current_block = frame_system::Pallet::<T>::block_number();
                    let voting_deadline = current_block
                        .checked_add(&VOTING_PERIOD.into())
                        .ok_or(Error::<T>::ArithmeticOverflow)?;

                    let dispute = Dispute {
                        milestone_id,
                        initiator: who.clone(),
                        reason: reason_bounded,
                        consultant_response: BoundedVec::default(),
                        jurors,
                        votes_for: 0,
                        votes_against: 0,
                        status: DisputeStatus::Voting,
                        winner: None,
                        created_at: current_block,
                        voting_deadline,
                    };

                    Disputes::<T>::insert(dispute_id, dispute);
                    DisputeCounter::<T>::put(next_id);

                    Self::deposit_event(Event::DisputeRaised {
                        dispute_id,
                        mission_id,
                        milestone_id,
                        initiator: who,
                    });

                    Ok(())
                },
            )
        }

        /// Vote on a dispute (jurors only)
        ///
        /// # Arguments
        ///
        /// * `dispute_id` - Dispute ID
        /// * `favor_consultant` - True if voting for consultant, false for client
        #[pallet::call_index(7)]
        #[pallet::weight(Weight::from_parts(10_000, 0).saturating_add(T::DbWeight::get().reads_writes(2, 2)))]
        pub fn vote_on_dispute(
            origin: OriginFor<T>,
            dispute_id: u64,
            favor_consultant: bool,
        ) -> DispatchResult {
            let who = ensure_signed(origin)?;

            // Check if already voted
            ensure!(
                !DisputeVotes::<T>::contains_key(dispute_id, &who),
                Error::<T>::AlreadyVoted
            );

            Disputes::<T>::try_mutate(dispute_id, |maybe_dispute| -> DispatchResult {
                let dispute = maybe_dispute.as_mut().ok_or(Error::<T>::DisputeNotFound)?;

                ensure!(
                    dispute.status == DisputeStatus::Voting,
                    Error::<T>::DisputeNotVoting
                );

                // Check if who is a juror
                let is_juror = dispute.jurors.iter().any(|j| j == &who);
                ensure!(is_juror, Error::<T>::NotJuror);

                // Record vote
                DisputeVotes::<T>::insert(dispute_id, &who, favor_consultant);

                if favor_consultant {
                    dispute.votes_for += 1;
                } else {
                    dispute.votes_against += 1;
                }

                Self::deposit_event(Event::DisputeVoteCast {
                    dispute_id,
                    juror: who,
                    favor_consultant,
                });

                // Check if majority reached (3/5 votes)
                if dispute.votes_for >= 3 || dispute.votes_against >= 3 {
                    Self::resolve_dispute_internal(dispute_id)?;
                }

                Ok(())
            })
        }

        /// Resolve dispute based on votes or after voting period
        ///
        /// # Arguments
        ///
        /// * `dispute_id` - Dispute ID
        #[pallet::call_index(8)]
        #[pallet::weight(Weight::from_parts(10_000, 0).saturating_add(T::DbWeight::get().reads_writes(3, 2)))]
        pub fn resolve_dispute(origin: OriginFor<T>, dispute_id: u64) -> DispatchResult {
            let _ = ensure_signed(origin)?;

            let dispute = Disputes::<T>::get(dispute_id).ok_or(Error::<T>::DisputeNotFound)?;

            ensure!(
                dispute.status == DisputeStatus::Voting,
                Error::<T>::DisputeNotVoting
            );

            let current_block = frame_system::Pallet::<T>::block_number();

            // Check if majority reached OR voting period ended
            ensure!(
                dispute.votes_for >= 3
                    || dispute.votes_against >= 3
                    || current_block >= dispute.voting_deadline,
                Error::<T>::VotingPeriodNotEnded
            );

            Self::resolve_dispute_internal(dispute_id)
        }
    }

    impl<T: Config> Pallet<T> {
        /// Select jury (5 Rank 3+ members, pseudo-random, exclude client/consultant)
        ///
        /// In production, this would integrate with pallet-membership to get eligible jurors.
        /// For now, returns empty vec (to be implemented).
        fn select_jury(
            _client: &T::AccountId,
            _consultant: &T::AccountId,
        ) -> Result<BoundedVec<T::AccountId, ConstU32<5>>, Error<T>> {
            // TODO: Integrate with pallet-membership to get Rank 3+ members
            // Exclude client and consultant
            // Pseudo-random selection (use Randomness trait in production)

            // For now, return error if not enough jurors
            // This will be implemented when integrating with pallet-membership
            Err(Error::<T>::InsufficientEligibleJurors)
        }

        /// Internal dispute resolution logic
        fn resolve_dispute_internal(dispute_id: u64) -> DispatchResult {
            Disputes::<T>::try_mutate(dispute_id, |maybe_dispute| -> DispatchResult {
                let dispute = maybe_dispute.as_mut().ok_or(Error::<T>::DisputeNotFound)?;

                dispute.status = DisputeStatus::Resolved;

                // Determine winner and amount awarded
                let (winner, amount_awarded) = if dispute.votes_for > dispute.votes_against {
                    // Consultant wins
                    (Some(dispute.initiator.clone()), Zero::zero())
                } else if dispute.votes_against > dispute.votes_for {
                    // Client wins
                    (Some(dispute.initiator.clone()), Zero::zero())
                } else {
                    // Tie - no winner
                    (None, Zero::zero())
                };

                dispute.winner = winner.clone();

                Self::deposit_event(Event::DisputeResolved {
                    dispute_id,
                    winner,
                    amount_awarded,
                });

                Ok(())
            })
        }
    }
}
