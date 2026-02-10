#![cfg_attr(not(feature = "std"), no_std)]

//! # Treasury Pallet
//!
//! Manages DAO funds with governance-controlled spending
//!
//! ## Overview
//!
//! This pallet implements a treasury system with milestone-based spending:
//! - **Spending Proposals**: 4-state lifecycle (Pending → Approved → Executed, or Cancelled)
//! - **Budget System**: Per-category budgets with allocated/spent tracking
//! - **Spending Limits**: Maximum single spend and daily spend limits
//! - **Role-Based Access**: TreasuryAdminOrigin (limits), TreasurerOrigin (approve), SpenderOrigin (execute)
//! - **Membership Integration**: Only active members with rank > 0 can create proposals
//!
//! ## Features
//!
//! - **Budget Categories**: Allocate budgets per category (e.g., "marketing", "development")
//! - **Daily Spend Limits**: Reset at midnight (block-based)
//! - **Spending Controls**: Max single spend, daily limit, budget enforcement
//! - **Audit Trail**: Full proposal lifecycle tracking with timestamps
//!
//! ## Extrinsics
//!
//! - `create_proposal`: Create spending proposal (requires active membership, rank > 0)
//! - `approve_proposal`: Approve proposal (TreasurerOrigin)
//! - `execute_proposal`: Execute approved proposal, transfer funds (SpenderOrigin)
//! - `cancel_proposal`: Cancel pending proposal (proposer or treasurer)
//! - `allocate_budget`: Allocate budget for category (TreasurerOrigin)
//! - `update_limits`: Update spending limits (TreasuryAdminOrigin)

// pub use pallet::*;

// #[cfg(test)]
// mod tests;

#[frame_support::pallet]
pub mod pallet {
    use frame_support::pallet_prelude::*;
    use frame_support::traits::{Currency, ExistenceRequirement};
    use frame_system::pallet_prelude::*;
    use sp_runtime::traits::{Zero, Saturating};
    use sp_std::vec::Vec;
    use sp_core;

    // Import pallet-membership for rank checks
    use pallet_membership;

    type BalanceOf<T> = <<T as Config>::Currency as Currency<<T as frame_system::Config>::AccountId>>::Balance;

    #[pallet::pallet]
    pub struct Pallet<T>(_);

    #[pallet::config]
    pub trait Config: frame_system::Config + pallet_membership::pallet::Config {
        /// The overarching event type.
        type RuntimeEvent: From<Event<Self>> + IsType<<Self as frame_system::Config>::RuntimeEvent>;

        /// The currency mechanism.
        type Currency: Currency<Self::AccountId>;

        /// The origin which may approve proposals (typically Root or Governance).
        type TreasurerOrigin: EnsureOrigin<Self::RuntimeOrigin, Success = Self::AccountId>;

        /// The origin which may execute proposals.
        type SpenderOrigin: EnsureOrigin<Self::RuntimeOrigin>;

        /// The origin which may update spending limits.
        type TreasuryAdminOrigin: EnsureOrigin<Self::RuntimeOrigin>;
    }

    /// Proposal status
    #[derive(Clone, Encode, Decode, Eq, PartialEq, RuntimeDebug, TypeInfo, MaxEncodedLen)]
    pub enum ProposalStatus {
        Pending,
        Approved,
        Executed,
        Cancelled,
    }

    /// Spending proposal
    #[derive(Clone, Encode, Decode, Eq, PartialEq, RuntimeDebug, TypeInfo, MaxEncodedLen)]
    #[scale_info(skip_type_params(T))]
    pub struct SpendingProposal<AccountId, Balance, BlockNumber> {
        /// Proposal ID
        pub id: u64,
        /// Payment recipient
        pub beneficiary: AccountId,
        /// Amount to spend
        pub amount: Balance,
        /// Spending justification (bounded string via BoundedVec)
        pub description: BoundedVec<u8, ConstU32<256>>,
        /// Who proposed
        pub proposer: AccountId,
        /// Current status
        pub status: ProposalStatus,
        /// Block when created
        pub created_at: BlockNumber,
        /// Block when approved (0 if not approved)
        pub approved_at: BlockNumber,
        /// Block when executed (0 if not executed)
        pub executed_at: BlockNumber,
    }

    /// Budget category
    #[derive(Clone, Encode, Decode, Eq, PartialEq, RuntimeDebug, TypeInfo, MaxEncodedLen)]
    pub struct Budget<Balance> {
        /// Total allocated budget
        pub allocated: Balance,
        /// Amount spent so far
        pub spent: Balance,
        /// Whether budget is active
        pub active: bool,
    }

    /// Storage: Proposal counter
    #[pallet::storage]
    #[pallet::getter(fn proposal_counter)]
    pub type ProposalCounter<T: Config> = StorageValue<_, u64, ValueQuery>;

    /// Storage: Spending proposals by ID
    #[pallet::storage]
    #[pallet::getter(fn proposals)]
    pub type Proposals<T: Config> = StorageMap<
        _,
        Blake2_128Concat,
        u64,
        SpendingProposal<T::AccountId, BalanceOf<T>, BlockNumberFor<T>>,
        OptionQuery,
    >;

    /// Storage: Budgets by category hash
    #[pallet::storage]
    #[pallet::getter(fn budgets)]
    pub type Budgets<T: Config> = StorageMap<
        _,
        Blake2_128Concat,
        [u8; 32], // Blake2_256 hash of category string
        Budget<BalanceOf<T>>,
        OptionQuery,
    >;

    /// Storage: Maximum single spend (governance-configurable)
    #[pallet::storage]
    #[pallet::getter(fn max_single_spend)]
    pub type MaxSingleSpend<T: Config> = StorageValue<_, BalanceOf<T>, ValueQuery>;

    /// Storage: Daily spend limit
    #[pallet::storage]
    #[pallet::getter(fn daily_spend_limit)]
    pub type DailySpendLimit<T: Config> = StorageValue<_, BalanceOf<T>, ValueQuery>;

    /// Storage: Daily spent amount (resets at day boundary)
    #[pallet::storage]
    #[pallet::getter(fn daily_spent)]
    pub type DailySpent<T: Config> = StorageValue<_, BalanceOf<T>, ValueQuery>;

    /// Storage: Last spend day (block number / blocks_per_day)
    #[pallet::storage]
    #[pallet::getter(fn last_spend_day)]
    pub type LastSpendDay<T: Config> = StorageValue<_, BlockNumberFor<T>, ValueQuery>;

    /// Storage: Treasury account ID
    #[pallet::storage]
    #[pallet::getter(fn treasury_account)]
    pub type TreasuryAccount<T: Config> = StorageValue<_, T::AccountId, OptionQuery>;

    #[pallet::event]
    #[pallet::generate_deposit(pub(super) fn deposit_event)]
    pub enum Event<T: Config> {
        /// Proposal created [proposal_id, beneficiary, amount, proposer]
        ProposalCreated {
            proposal_id: u64,
            beneficiary: T::AccountId,
            amount: BalanceOf<T>,
            proposer: T::AccountId,
        },
        /// Proposal approved [proposal_id, approver]
        ProposalApproved {
            proposal_id: u64,
            approver: T::AccountId,
        },
        /// Proposal executed [proposal_id, amount]
        ProposalExecuted {
            proposal_id: u64,
            amount: BalanceOf<T>,
        },
        /// Proposal cancelled [proposal_id]
        ProposalCancelled { proposal_id: u64 },
        /// Budget allocated [category_hash, amount]
        BudgetAllocated {
            category_hash: [u8; 32],
            amount: BalanceOf<T>,
        },
        /// Budget spent [category_hash, amount]
        BudgetSpent {
            category_hash: [u8; 32],
            amount: BalanceOf<T>,
        },
        /// Funds received [from, amount]
        FundsReceived {
            from: T::AccountId,
            amount: BalanceOf<T>,
        },
        /// Spending limits updated [max_single_spend, daily_spend_limit]
        LimitsUpdated {
            max_single_spend: BalanceOf<T>,
            daily_spend_limit: BalanceOf<T>,
        },
    }

    #[pallet::error]
    pub enum Error<T> {
        /// Insufficient treasury funds
        InsufficientFunds,
        /// Proposal not in pending status
        ProposalNotPending,
        /// Proposal not in approved status
        ProposalNotApproved,
        /// Amount exceeds max single spend
        ExceedsMaxSpend,
        /// Amount exceeds daily spend limit
        ExceedsDailyLimit,
        /// Budget exceeded for category
        BudgetExceeded,
        /// Invalid proposal parameters
        InvalidProposal,
        /// Caller not authorized
        Unauthorized,
        /// Proposal not found
        ProposalNotFound,
        /// Description too long
        DescriptionTooLong,
        /// Category string too long
        CategoryTooLong,
    }

    #[pallet::call]
    impl<T: Config> Pallet<T> {
        /// Create spending proposal
        ///
        /// # Arguments
        ///
        /// * `beneficiary` - Payment recipient
        /// * `amount` - Amount to spend
        /// * `description` - Spending justification (max 256 bytes)
        /// * `category` - Budget category (optional, max 64 bytes)
        ///
        /// # Errors
        ///
        /// - `Unauthorized`: Caller not active member with rank > 0
        /// - `InvalidProposal`: Amount is zero or beneficiary invalid
        /// - `BudgetExceeded`: Spending would exceed category budget
        /// - `DescriptionTooLong`: Description exceeds 256 bytes
        /// - `CategoryTooLong`: Category exceeds 64 bytes
        ///
        /// # Weight
        ///
        /// - Reads: 2 (Membership check, Budget check if category provided)
        /// - Writes: 2 (ProposalCounter, Proposals)
        #[pallet::call_index(0)]
        #[pallet::weight(Weight::from_parts(10_000, 0).saturating_add(T::DbWeight::get().reads_writes(2, 2)))]
        pub fn create_proposal(
            origin: OriginFor<T>,
            beneficiary: T::AccountId,
            amount: BalanceOf<T>,
            description: Vec<u8>,
            category: Option<Vec<u8>>,
        ) -> DispatchResult {
            let proposer = ensure_signed(origin)?;

            // Verify proposer is active DAO member with rank > 0
            let member_info = pallet_membership::pallet::Pallet::<T>::get_member_info(&proposer)
                .ok_or(Error::<T>::Unauthorized)?;

            if !member_info.active || member_info.rank == pallet_membership::pallet::Rank::Junior {
                return Err(Error::<T>::Unauthorized.into());
            }

            // Validate proposal
            ensure!(!amount.is_zero(), Error::<T>::InvalidProposal);

            // Convert description to BoundedVec
            let description_bounded: BoundedVec<u8, ConstU32<256>> = description
                .try_into()
                .map_err(|_| Error::<T>::DescriptionTooLong)?;

            let proposal_id = ProposalCounter::<T>::get();
            let current_block = frame_system::Pallet::<T>::block_number();

            // Check budget if category provided
            if let Some(cat) = category {
                ensure!(cat.len() <= 64, Error::<T>::CategoryTooLong);
                let category_hash = sp_core::hashing::blake2_256(&cat);

                if let Some(budget) = Budgets::<T>::get(category_hash) {
                    if budget.active {
                        let new_spent = budget.spent.saturating_add(amount);
                        ensure!(new_spent <= budget.allocated, Error::<T>::BudgetExceeded);
                    }
                }
            }

            let proposal = SpendingProposal {
                id: proposal_id,
                beneficiary: beneficiary.clone(),
                amount,
                description: description_bounded,
                proposer: proposer.clone(),
                status: ProposalStatus::Pending,
                created_at: current_block,
                approved_at: Zero::zero(),
                executed_at: Zero::zero(),
            };

            Proposals::<T>::insert(proposal_id, proposal);
            ProposalCounter::<T>::put(proposal_id.saturating_add(1));

            Self::deposit_event(Event::ProposalCreated {
                proposal_id,
                beneficiary,
                amount,
                proposer,
            });

            Ok(())
        }

        /// Approve spending proposal
        ///
        /// # Arguments
        ///
        /// * `proposal_id` - Proposal to approve
        ///
        /// # Errors
        ///
        /// - `ProposalNotFound`: Proposal doesn't exist
        /// - `ProposalNotPending`: Proposal not in pending status
        /// - `ExceedsMaxSpend`: Amount exceeds max single spend limit
        ///
        /// # Weight
        ///
        /// - Reads: 2 (Proposals, MaxSingleSpend)
        /// - Writes: 1 (Proposals)
        #[pallet::call_index(1)]
        #[pallet::weight(Weight::from_parts(10_000, 0).saturating_add(T::DbWeight::get().reads_writes(2, 1)))]
        pub fn approve_proposal(origin: OriginFor<T>, proposal_id: u64) -> DispatchResult {
            let approver = T::TreasurerOrigin::ensure_origin(origin)?;

            Proposals::<T>::try_mutate(proposal_id, |maybe_proposal| -> DispatchResult {
                let proposal = maybe_proposal.as_mut().ok_or(Error::<T>::ProposalNotFound)?;

                ensure!(
                    proposal.status == ProposalStatus::Pending,
                    Error::<T>::ProposalNotPending
                );

                // Check spending limit
                let max_spend = MaxSingleSpend::<T>::get();
                ensure!(proposal.amount <= max_spend, Error::<T>::ExceedsMaxSpend);

                proposal.status = ProposalStatus::Approved;
                proposal.approved_at = frame_system::Pallet::<T>::block_number();

                Self::deposit_event(Event::ProposalApproved {
                    proposal_id,
                    approver: approver.clone(),
                });

                Ok(())
            })
        }

        /// Execute approved spending proposal
        ///
        /// # Arguments
        ///
        /// * `proposal_id` - Proposal to execute
        /// * `category` - Budget category to deduct from (optional)
        ///
        /// # Errors
        ///
        /// - `ProposalNotFound`: Proposal doesn't exist
        /// - `ProposalNotApproved`: Proposal not in approved status
        /// - `InsufficientFunds`: Treasury balance insufficient
        /// - `ExceedsDailyLimit`: Would exceed daily spend limit
        ///
        /// # Weight
        ///
        /// - Reads: 5 (Proposals, TreasuryAccount, Balance, DailySpent, LastSpendDay)
        /// - Writes: 4 (Proposals, DailySpent, LastSpendDay, Transfer)
        #[pallet::call_index(2)]
        #[pallet::weight(Weight::from_parts(10_000, 0).saturating_add(T::DbWeight::get().reads_writes(5, 4)))]
        pub fn execute_proposal(
            origin: OriginFor<T>,
            proposal_id: u64,
            category: Option<Vec<u8>>,
        ) -> DispatchResult {
            T::SpenderOrigin::ensure_origin(origin)?;

            Proposals::<T>::try_mutate(proposal_id, |maybe_proposal| -> DispatchResult {
                let proposal = maybe_proposal.as_mut().ok_or(Error::<T>::ProposalNotFound)?;

                ensure!(
                    proposal.status == ProposalStatus::Approved,
                    Error::<T>::ProposalNotApproved
                );

                // Get treasury account
                let treasury = TreasuryAccount::<T>::get().ok_or(Error::<T>::InvalidProposal)?;

                // Check treasury balance
                let balance = T::Currency::free_balance(&treasury);
                ensure!(balance >= proposal.amount, Error::<T>::InsufficientFunds);

                // Check and update daily spend limit
                let current_block = frame_system::Pallet::<T>::block_number();
                let blocks_per_day = 14_400u32.into(); // 6s blocks = 14,400 blocks/day
                let current_day = current_block / blocks_per_day;
                let last_day = LastSpendDay::<T>::get();

                let mut daily_spent = if current_day > last_day {
                    // Reset daily counter for new day
                    LastSpendDay::<T>::put(current_day);
                    Zero::zero()
                } else {
                    DailySpent::<T>::get()
                };

                let daily_limit = DailySpendLimit::<T>::get();
                let new_daily_spent = daily_spent.saturating_add(proposal.amount);
                ensure!(new_daily_spent <= daily_limit, Error::<T>::ExceedsDailyLimit);

                // Update budget if category provided
                if let Some(cat) = category {
                    let category_hash = sp_core::hashing::blake2_256(&cat);

                    Budgets::<T>::try_mutate(category_hash, |maybe_budget| -> DispatchResult {
                        if let Some(budget) = maybe_budget {
                            if budget.active {
                                budget.spent = budget.spent.saturating_add(proposal.amount);
                                Self::deposit_event(Event::BudgetSpent {
                                    category_hash,
                                    amount: proposal.amount,
                                });
                            }
                        }
                        Ok(())
                    })?;
                }

                // Update state
                proposal.status = ProposalStatus::Executed;
                proposal.executed_at = current_block;
                DailySpent::<T>::put(new_daily_spent);

                // Transfer funds
                T::Currency::transfer(
                    &treasury,
                    &proposal.beneficiary,
                    proposal.amount,
                    ExistenceRequirement::KeepAlive,
                )?;

                Self::deposit_event(Event::ProposalExecuted {
                    proposal_id,
                    amount: proposal.amount,
                });

                Ok(())
            })
        }

        /// Cancel pending proposal
        ///
        /// # Arguments
        ///
        /// * `proposal_id` - Proposal to cancel
        ///
        /// # Errors
        ///
        /// - `ProposalNotFound`: Proposal doesn't exist
        /// - `Unauthorized`: Caller not proposer or treasurer
        /// - `ProposalNotPending`: Proposal not in pending status
        ///
        /// # Weight
        ///
        /// - Reads: 1 (Proposals)
        /// - Writes: 1 (Proposals)
        #[pallet::call_index(3)]
        #[pallet::weight(Weight::from_parts(10_000, 0).saturating_add(T::DbWeight::get().reads_writes(1, 1)))]
        pub fn cancel_proposal(origin: OriginFor<T>, proposal_id: u64) -> DispatchResult {
            let caller = ensure_signed(origin.clone())?;

            Proposals::<T>::try_mutate(proposal_id, |maybe_proposal| -> DispatchResult {
                let proposal = maybe_proposal.as_mut().ok_or(Error::<T>::ProposalNotFound)?;

                // Only proposer or treasurer can cancel
                let is_treasurer = T::TreasurerOrigin::ensure_origin(origin.clone()).is_ok();
                ensure!(
                    caller == proposal.proposer || is_treasurer,
                    Error::<T>::Unauthorized
                );

                ensure!(
                    proposal.status == ProposalStatus::Pending,
                    Error::<T>::ProposalNotPending
                );

                proposal.status = ProposalStatus::Cancelled;

                Self::deposit_event(Event::ProposalCancelled { proposal_id });

                Ok(())
            })
        }

        /// Allocate budget for category
        ///
        /// # Arguments
        ///
        /// * `category` - Budget category (max 64 bytes)
        /// * `amount` - Budget amount
        ///
        /// # Weight
        ///
        /// - Reads: 0
        /// - Writes: 1 (Budgets)
        #[pallet::call_index(4)]
        #[pallet::weight(Weight::from_parts(10_000, 0).saturating_add(T::DbWeight::get().writes(1)))]
        pub fn allocate_budget(
            origin: OriginFor<T>,
            category: Vec<u8>,
            amount: BalanceOf<T>,
        ) -> DispatchResult {
            T::TreasurerOrigin::ensure_origin(origin)?;

            ensure!(category.len() <= 64, Error::<T>::CategoryTooLong);

            let category_hash = sp_core::hashing::blake2_256(&category);

            let budget = Budget {
                allocated: amount,
                spent: Zero::zero(),
                active: true,
            };

            Budgets::<T>::insert(category_hash, budget);

            Self::deposit_event(Event::BudgetAllocated {
                category_hash,
                amount,
            });

            Ok(())
        }

        /// Update spending limits
        ///
        /// # Arguments
        ///
        /// * `max_single_spend` - New max single spend
        /// * `daily_spend_limit` - New daily limit
        ///
        /// # Weight
        ///
        /// - Reads: 0
        /// - Writes: 2 (MaxSingleSpend, DailySpendLimit)
        #[pallet::call_index(5)]
        #[pallet::weight(Weight::from_parts(10_000, 0).saturating_add(T::DbWeight::get().writes(2)))]
        pub fn update_limits(
            origin: OriginFor<T>,
            max_single_spend: BalanceOf<T>,
            daily_spend_limit: BalanceOf<T>,
        ) -> DispatchResult {
            T::TreasuryAdminOrigin::ensure_origin(origin)?;

            MaxSingleSpend::<T>::put(max_single_spend);
            DailySpendLimit::<T>::put(daily_spend_limit);

            Self::deposit_event(Event::LimitsUpdated {
                max_single_spend,
                daily_spend_limit,
            });

            Ok(())
        }

        /// Set treasury account
        ///
        /// # Arguments
        ///
        /// * `account` - Treasury account ID
        ///
        /// # Weight
        ///
        /// - Reads: 0
        /// - Writes: 1 (TreasuryAccount)
        #[pallet::call_index(6)]
        #[pallet::weight(Weight::from_parts(10_000, 0).saturating_add(T::DbWeight::get().writes(1)))]
        pub fn set_treasury_account(
            origin: OriginFor<T>,
            account: T::AccountId,
        ) -> DispatchResult {
            T::TreasuryAdminOrigin::ensure_origin(origin)?;

            TreasuryAccount::<T>::put(account);

            Ok(())
        }
    }

    impl<T: Config> Pallet<T> {
        /// Get treasury balance
        pub fn get_balance() -> BalanceOf<T> {
            if let Some(treasury) = TreasuryAccount::<T>::get() {
                T::Currency::free_balance(&treasury)
            } else {
                Zero::zero()
            }
        }

        /// Get daily spend remaining
        pub fn daily_spend_remaining() -> BalanceOf<T> {
            let current_block = frame_system::Pallet::<T>::block_number();
            let blocks_per_day = 14_400u32.into();
            let current_day = current_block / blocks_per_day;
            let last_day = LastSpendDay::<T>::get();

            let daily_limit = DailySpendLimit::<T>::get();

            if current_day > last_day {
                // New day, full limit available
                daily_limit
            } else {
                let daily_spent = DailySpent::<T>::get();
                daily_limit.saturating_sub(daily_spent)
            }
        }

        /// Check if proposal exists
        pub fn proposal_exists(proposal_id: u64) -> bool {
            Proposals::<T>::contains_key(proposal_id)
        }
    }
}
