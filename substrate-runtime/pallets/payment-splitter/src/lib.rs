#![cfg_attr(not(feature = "std"), no_std)]

//! # Payment Splitter Pallet
//!
//! Hybrid payment distribution for Human/AI/Compute contributors
//!
//! ## Overview
//!
//! This pallet implements:
//! - **Hybrid revenue sharing**: Human (fixed %), AI (usage + fixed %), Compute (usage + fixed %)
//! - **Usage metering**: LLM tokens + GPU hours tracked by oracle
//! - **Dynamic pricing**: Configurable prices for LLM tokens and GPU compute
//! - **Automated distribution**: Calculate shares based on contributor type and usage
//! - **Role-based access**: Admin (configuration) and Meter (usage reporting)
//!
//! ## Features
//!
//! - **Three contributor types**:
//!   - Human: Fixed percentage of total amount
//!   - AI: Usage cost (LLM tokens) + fixed percentage
//!   - Compute: Usage cost (GPU hours) + fixed percentage
//! - **Usage tracking**: LLM tokens and GPU-hours with metering oracle
//! - **Pricing model**: Price per 1M LLM tokens, price per GPU-hour
//! - **Automatic calculation**: Share calculation based on usage and fixed percentages
//!
//! ## Extrinsics
//!
//! - `create_split_config`: Create payment split configuration
//! - `add_contributor`: Add Human/AI/Compute contributor
//! - `report_usage`: Report usage metrics (Meter role only)
//! - `distribute_payment`: Distribute payment to contributors
//! - `update_pricing`: Update LLM token and GPU hour pricing
//! - `reset_usage_metrics`: Reset usage after payment distribution

// pub use pallet::*;

// #[cfg(test)]
// mod tests;

#[frame_support::pallet]
pub mod pallet {
    use frame_support::pallet_prelude::*;
    use frame_system::pallet_prelude::*;
    use sp_runtime::traits::{CheckedAdd, CheckedDiv, CheckedMul, Zero, SaturatedConversion};
    use sp_std::vec::Vec;

    #[pallet::pallet]
    pub struct Pallet<T>(_);

    #[pallet::config]
    pub trait Config: frame_system::Config {
        /// The overarching event type.
        type RuntimeEvent: From<Event<Self>> + IsType<<Self as frame_system::Config>::RuntimeEvent>;

        /// The origin which may administer split configs (typically Root or Governance).
        type AdminOrigin: EnsureOrigin<Self::RuntimeOrigin>;

        /// The origin which may report usage metrics (meter oracle).
        type MeterOrigin: EnsureOrigin<Self::RuntimeOrigin>;

        /// Currency type for payments.
        type Currency: frame_support::traits::Currency<Self::AccountId>;
    }

    /// Contributor type
    #[derive(Clone, Encode, Decode, Eq, PartialEq, RuntimeDebug, TypeInfo, MaxEncodedLen)]
    pub enum ContributorType {
        Human,   // Fixed percentage
        AI,      // Usage-based (LLM tokens) + fixed percentage
        Compute, // Usage-based (GPU hours) + fixed percentage
    }

    /// Contributor information
    #[derive(Clone, Encode, Decode, Eq, PartialEq, RuntimeDebug, TypeInfo, MaxEncodedLen)]
    #[scale_info(skip_type_params(T))]
    pub struct Contributor<AccountId, Balance> {
        pub account: AccountId,
        pub contributor_type: ContributorType,
        pub percentage_bps: u32, // Basis points (10000 = 100%)
        pub total_earned: Balance,
    }

    /// Usage metrics
    #[derive(Clone, Encode, Decode, Eq, PartialEq, RuntimeDebug, TypeInfo, MaxEncodedLen)]
    pub struct UsageMetrics<BlockNumber> {
        pub llm_tokens_used: u64,  // LLM tokens (prompt + completion)
        pub gpu_hours_used: u64,   // GPU-hours (scaled by 1000: 1.5h = 1500)
        pub last_updated: BlockNumber,
    }

    /// Pricing configuration
    #[derive(Clone, Encode, Decode, Eq, PartialEq, RuntimeDebug, TypeInfo, MaxEncodedLen)]
    #[scale_info(skip_type_params(T))]
    pub struct Pricing<Balance> {
        pub price_per_m_token_llm: Balance, // Price per 1M LLM tokens
        pub price_per_gpu_hour: Balance,    // Price per GPU-hour
    }

    /// Split configuration
    #[derive(Clone, Encode, Decode, Eq, PartialEq, RuntimeDebug, TypeInfo, MaxEncodedLen)]
    pub struct SplitConfig {
        pub mission_id: u64,
        pub contributor_count: u32,
    }

    /// Storage: Split configurations by ID
    #[pallet::storage]
    #[pallet::getter(fn split_configs)]
    pub type SplitConfigs<T: Config> = StorageMap<
        _,
        Blake2_128Concat,
        u64,
        SplitConfig,
        OptionQuery,
    >;

    /// Storage: Split config counter
    #[pallet::storage]
    #[pallet::getter(fn split_config_counter)]
    pub type SplitConfigCounter<T: Config> = StorageValue<_, u64, ValueQuery>;

    /// Storage: Contributors by (SplitConfigId, ContributorIndex)
    #[pallet::storage]
    #[pallet::getter(fn contributors)]
    pub type Contributors<T: Config> = StorageDoubleMap<
        _,
        Blake2_128Concat,
        u64, // Split config ID
        Blake2_128Concat,
        u32, // Contributor index
        Contributor<T::AccountId, BalanceOf<T>>,
        OptionQuery,
    >;

    /// Storage: Usage metrics by split config ID
    #[pallet::storage]
    #[pallet::getter(fn usage_metrics)]
    pub type UsageMetricsStorage<T: Config> = StorageMap<
        _,
        Blake2_128Concat,
        u64,
        UsageMetrics<BlockNumberFor<T>>,
        OptionQuery,
    >;

    /// Storage: Pricing by split config ID
    #[pallet::storage]
    #[pallet::getter(fn pricing)]
    pub type PricingStorage<T: Config> = StorageMap<
        _,
        Blake2_128Concat,
        u64,
        Pricing<BalanceOf<T>>,
        OptionQuery,
    >;

    /// Constants
    pub type BalanceOf<T> = <<T as Config>::Currency as frame_support::traits::Currency<
        <T as frame_system::Config>::AccountId,
    >>::Balance;

    #[pallet::event]
    #[pallet::generate_deposit(pub(super) fn deposit_event)]
    pub enum Event<T: Config> {
        /// Split config created [split_config_id, mission_id]
        SplitConfigCreated {
            split_config_id: u64,
            mission_id: u64,
        },
        /// Contributor added [split_config_id, contributor_index, account, contributor_type, percentage_bps]
        ContributorAdded {
            split_config_id: u64,
            contributor_index: u32,
            account: T::AccountId,
            contributor_type: ContributorType,
            percentage_bps: u32,
        },
        /// Usage reported [split_config_id, llm_tokens, gpu_hours]
        UsageReported {
            split_config_id: u64,
            llm_tokens: u64,
            gpu_hours: u64,
        },
        /// Payment distributed [split_config_id, recipient, amount, contributor_type]
        PaymentDistributed {
            split_config_id: u64,
            recipient: T::AccountId,
            amount: BalanceOf<T>,
            contributor_type: ContributorType,
        },
        /// Pricing updated [split_config_id, price_per_m_token_llm, price_per_gpu_hour]
        PricingUpdated {
            split_config_id: u64,
            price_per_m_token_llm: BalanceOf<T>,
            price_per_gpu_hour: BalanceOf<T>,
        },
        /// Usage metrics reset [split_config_id]
        UsageMetricsReset {
            split_config_id: u64,
        },
    }

    #[pallet::error]
    pub enum Error<T> {
        /// Split config not found
        SplitConfigNotFound,
        /// Contributor not found
        ContributorNotFound,
        /// Invalid percentage (must be <= 10000 bps)
        InvalidPercentage,
        /// Arithmetic overflow
        ArithmeticOverflow,
        /// Insufficient funds
        InsufficientFunds,
        /// Invalid contributor index
        InvalidContributorIndex,
    }

    #[pallet::call]
    impl<T: Config> Pallet<T> {
        /// Create a new payment split configuration
        ///
        /// # Arguments
        ///
        /// * `mission_id` - Associated mission ID
        /// * `price_per_m_token_llm` - Price per 1M LLM tokens
        /// * `price_per_gpu_hour` - Price per GPU-hour
        #[pallet::call_index(0)]
        #[pallet::weight(Weight::from_parts(10_000, 0).saturating_add(T::DbWeight::get().reads_writes(1, 3)))]
        pub fn create_split_config(
            origin: OriginFor<T>,
            mission_id: u64,
            price_per_m_token_llm: BalanceOf<T>,
            price_per_gpu_hour: BalanceOf<T>,
        ) -> DispatchResult {
            T::AdminOrigin::ensure_origin(origin)?;

            let split_config_id = SplitConfigCounter::<T>::get();
            let next_id = split_config_id
                .checked_add(1)
                .ok_or(Error::<T>::ArithmeticOverflow)?;

            let config = SplitConfig {
                mission_id,
                contributor_count: 0,
            };

            let pricing = Pricing {
                price_per_m_token_llm,
                price_per_gpu_hour,
            };

            let usage = UsageMetrics {
                llm_tokens_used: 0,
                gpu_hours_used: 0,
                last_updated: frame_system::Pallet::<T>::block_number(),
            };

            SplitConfigs::<T>::insert(split_config_id, config);
            PricingStorage::<T>::insert(split_config_id, pricing);
            UsageMetricsStorage::<T>::insert(split_config_id, usage);
            SplitConfigCounter::<T>::put(next_id);

            Self::deposit_event(Event::SplitConfigCreated {
                split_config_id,
                mission_id,
            });

            Ok(())
        }

        /// Add a contributor to a split configuration
        ///
        /// # Arguments
        ///
        /// * `split_config_id` - Split configuration ID
        /// * `account` - Contributor account
        /// * `contributor_type` - Human/AI/Compute
        /// * `percentage_bps` - Fixed percentage in basis points (10000 = 100%)
        #[pallet::call_index(1)]
        #[pallet::weight(Weight::from_parts(10_000, 0).saturating_add(T::DbWeight::get().reads_writes(2, 2)))]
        pub fn add_contributor(
            origin: OriginFor<T>,
            split_config_id: u64,
            account: T::AccountId,
            contributor_type: ContributorType,
            percentage_bps: u32,
        ) -> DispatchResult {
            T::AdminOrigin::ensure_origin(origin)?;

            ensure!(percentage_bps <= 10000, Error::<T>::InvalidPercentage);

            let mut config = SplitConfigs::<T>::get(split_config_id)
                .ok_or(Error::<T>::SplitConfigNotFound)?;

            let contributor_index = config.contributor_count;
            let next_count = contributor_index
                .checked_add(1)
                .ok_or(Error::<T>::ArithmeticOverflow)?;

            let contributor = Contributor {
                account: account.clone(),
                contributor_type: contributor_type.clone(),
                percentage_bps,
                total_earned: Zero::zero(),
            };

            Contributors::<T>::insert(split_config_id, contributor_index, contributor);

            config.contributor_count = next_count;
            SplitConfigs::<T>::insert(split_config_id, config);

            Self::deposit_event(Event::ContributorAdded {
                split_config_id,
                contributor_index,
                account,
                contributor_type,
                percentage_bps,
            });

            Ok(())
        }

        /// Report usage metrics (Meter role only)
        ///
        /// # Arguments
        ///
        /// * `split_config_id` - Split configuration ID
        /// * `llm_tokens` - LLM tokens used (prompt + completion)
        /// * `gpu_hours` - GPU-hours used (scaled by 1000: 1.5h = 1500)
        #[pallet::call_index(2)]
        #[pallet::weight(Weight::from_parts(10_000, 0).saturating_add(T::DbWeight::get().reads_writes(1, 1)))]
        pub fn report_usage(
            origin: OriginFor<T>,
            split_config_id: u64,
            llm_tokens: u64,
            gpu_hours: u64,
        ) -> DispatchResult {
            T::MeterOrigin::ensure_origin(origin)?;

            UsageMetricsStorage::<T>::try_mutate(
                split_config_id,
                |maybe_usage| -> DispatchResult {
                    let usage = maybe_usage
                        .as_mut()
                        .ok_or(Error::<T>::SplitConfigNotFound)?;

                    usage.llm_tokens_used = usage
                        .llm_tokens_used
                        .checked_add(llm_tokens)
                        .ok_or(Error::<T>::ArithmeticOverflow)?;

                    usage.gpu_hours_used = usage
                        .gpu_hours_used
                        .checked_add(gpu_hours)
                        .ok_or(Error::<T>::ArithmeticOverflow)?;

                    usage.last_updated = frame_system::Pallet::<T>::block_number();

                    Self::deposit_event(Event::UsageReported {
                        split_config_id,
                        llm_tokens,
                        gpu_hours,
                    });

                    Ok(())
                },
            )
        }

        /// Distribute payment to contributors
        ///
        /// # Arguments
        ///
        /// * `split_config_id` - Split configuration ID
        /// * `total_amount` - Total amount to distribute
        #[pallet::call_index(3)]
        #[pallet::weight(Weight::from_parts(10_000, 0).saturating_add(T::DbWeight::get().reads_writes(10, 10)))]
        pub fn distribute_payment(
            origin: OriginFor<T>,
            split_config_id: u64,
            total_amount: BalanceOf<T>,
        ) -> DispatchResult {
            T::AdminOrigin::ensure_origin(origin)?;

            let config = SplitConfigs::<T>::get(split_config_id)
                .ok_or(Error::<T>::SplitConfigNotFound)?;

            let usage = UsageMetricsStorage::<T>::get(split_config_id)
                .ok_or(Error::<T>::SplitConfigNotFound)?;

            let pricing = PricingStorage::<T>::get(split_config_id)
                .ok_or(Error::<T>::SplitConfigNotFound)?;

            // Calculate usage costs
            let ai_usage_cost = Self::calculate_ai_usage_cost(&usage, &pricing)?;
            let compute_usage_cost = Self::calculate_compute_usage_cost(&usage, &pricing)?;

            // Distribute to each contributor
            for i in 0..config.contributor_count {
                if let Some(mut contributor) = Contributors::<T>::get(split_config_id, i) {
                    let share = Self::calculate_share(
                        &contributor,
                        total_amount,
                        ai_usage_cost,
                        compute_usage_cost,
                    )?;

                    if !share.is_zero() {
                        contributor.total_earned = contributor
                            .total_earned
                            .checked_add(&share)
                            .ok_or(Error::<T>::ArithmeticOverflow)?;

                        Contributors::<T>::insert(split_config_id, i, contributor.clone());

                        Self::deposit_event(Event::PaymentDistributed {
                            split_config_id,
                            recipient: contributor.account,
                            amount: share,
                            contributor_type: contributor.contributor_type,
                        });
                    }
                }
            }

            Ok(())
        }

        /// Update pricing (Admin only)
        ///
        /// # Arguments
        ///
        /// * `split_config_id` - Split configuration ID
        /// * `price_per_m_token_llm` - New price per 1M LLM tokens
        /// * `price_per_gpu_hour` - New price per GPU-hour
        #[pallet::call_index(4)]
        #[pallet::weight(Weight::from_parts(10_000, 0).saturating_add(T::DbWeight::get().reads_writes(1, 1)))]
        pub fn update_pricing(
            origin: OriginFor<T>,
            split_config_id: u64,
            price_per_m_token_llm: BalanceOf<T>,
            price_per_gpu_hour: BalanceOf<T>,
        ) -> DispatchResult {
            T::AdminOrigin::ensure_origin(origin)?;

            PricingStorage::<T>::try_mutate(
                split_config_id,
                |maybe_pricing| -> DispatchResult {
                    let pricing = maybe_pricing
                        .as_mut()
                        .ok_or(Error::<T>::SplitConfigNotFound)?;

                    pricing.price_per_m_token_llm = price_per_m_token_llm;
                    pricing.price_per_gpu_hour = price_per_gpu_hour;

                    Self::deposit_event(Event::PricingUpdated {
                        split_config_id,
                        price_per_m_token_llm,
                        price_per_gpu_hour,
                    });

                    Ok(())
                },
            )
        }

        /// Reset usage metrics (Admin only, after payment distribution)
        ///
        /// # Arguments
        ///
        /// * `split_config_id` - Split configuration ID
        #[pallet::call_index(5)]
        #[pallet::weight(Weight::from_parts(10_000, 0).saturating_add(T::DbWeight::get().reads_writes(1, 1)))]
        pub fn reset_usage_metrics(
            origin: OriginFor<T>,
            split_config_id: u64,
        ) -> DispatchResult {
            T::AdminOrigin::ensure_origin(origin)?;

            UsageMetricsStorage::<T>::try_mutate(
                split_config_id,
                |maybe_usage| -> DispatchResult {
                    let usage = maybe_usage
                        .as_mut()
                        .ok_or(Error::<T>::SplitConfigNotFound)?;

                    usage.llm_tokens_used = 0;
                    usage.gpu_hours_used = 0;
                    usage.last_updated = frame_system::Pallet::<T>::block_number();

                    Self::deposit_event(Event::UsageMetricsReset {
                        split_config_id,
                    });

                    Ok(())
                },
            )
        }
    }

    impl<T: Config> Pallet<T> {
        /// Calculate AI usage cost based on LLM tokens
        fn calculate_ai_usage_cost(
            usage: &UsageMetrics<BlockNumberFor<T>>,
            pricing: &Pricing<BalanceOf<T>>,
        ) -> Result<BalanceOf<T>, Error<T>> {
            // Cost = (tokens / 1M) * price_per_m_token_llm
            let tokens_in_millions = usage.llm_tokens_used / 1_000_000;

            let cost = pricing
                .price_per_m_token_llm
                .checked_mul(&tokens_in_millions.saturated_into())
                .ok_or(Error::<T>::ArithmeticOverflow)?;

            Ok(cost)
        }

        /// Calculate compute usage cost based on GPU-hours
        fn calculate_compute_usage_cost(
            usage: &UsageMetrics<BlockNumberFor<T>>,
            pricing: &Pricing<BalanceOf<T>>,
        ) -> Result<BalanceOf<T>, Error<T>> {
            // Cost = (gpu_hours / 1000) * price_per_gpu_hour
            // (usage scaled by 1000: 1.5h = 1500)
            let gpu_hours_actual = usage.gpu_hours_used / 1000;

            let cost = pricing
                .price_per_gpu_hour
                .checked_mul(&gpu_hours_actual.saturated_into())
                .ok_or(Error::<T>::ArithmeticOverflow)?;

            Ok(cost)
        }

        /// Calculate share for a contributor
        fn calculate_share(
            contributor: &Contributor<T::AccountId, BalanceOf<T>>,
            total_amount: BalanceOf<T>,
            ai_usage_cost: BalanceOf<T>,
            compute_usage_cost: BalanceOf<T>,
        ) -> Result<BalanceOf<T>, Error<T>> {
            match contributor.contributor_type {
                ContributorType::Human => {
                    // Fixed percentage only
                    let share = total_amount
                        .checked_mul(&contributor.percentage_bps.into())
                        .ok_or(Error::<T>::ArithmeticOverflow)?
                        .checked_div(&10000u32.into())
                        .ok_or(Error::<T>::ArithmeticOverflow)?;

                    Ok(share)
                }
                ContributorType::AI => {
                    // Usage cost + fixed percentage
                    let fixed_share = total_amount
                        .checked_mul(&contributor.percentage_bps.into())
                        .ok_or(Error::<T>::ArithmeticOverflow)?
                        .checked_div(&10000u32.into())
                        .ok_or(Error::<T>::ArithmeticOverflow)?;

                    let total_share = ai_usage_cost
                        .checked_add(&fixed_share)
                        .ok_or(Error::<T>::ArithmeticOverflow)?;

                    Ok(total_share)
                }
                ContributorType::Compute => {
                    // Usage cost + fixed percentage
                    let fixed_share = total_amount
                        .checked_mul(&contributor.percentage_bps.into())
                        .ok_or(Error::<T>::ArithmeticOverflow)?
                        .checked_div(&10000u32.into())
                        .ok_or(Error::<T>::ArithmeticOverflow)?;

                    let total_share = compute_usage_cost
                        .checked_add(&fixed_share)
                        .ok_or(Error::<T>::ArithmeticOverflow)?;

                    Ok(total_share)
                }
            }
        }
    }
}
