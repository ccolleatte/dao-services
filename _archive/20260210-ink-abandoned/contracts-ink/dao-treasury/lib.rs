#![cfg_attr(not(feature = "std"), no_std, no_main)]

/// # DAOTreasury - Polkadot 2.0 Native
///
/// Manages DAO funds with governance-controlled spending:
/// - Spending proposals workflow (create → approve → execute)
/// - Budget allocation per category
/// - Spending limits (max single: 100 tokens, daily: 500 tokens)
/// - Role-based access (Treasurer, Spender)

#[ink::contract]
mod dao_treasury {
    use ink::prelude::string::String;
    use ink::storage::Mapping;

    /// Spending proposal status
    #[derive(Debug, Clone, Copy, PartialEq, Eq, scale::Encode, scale::Decode)]
    #[cfg_attr(feature = "std", derive(scale_info::TypeInfo, ink::storage::traits::StorageLayout))]
    pub enum ProposalStatus {
        Pending,
        Approved,
        Executed,
        Cancelled,
    }

    /// Spending proposal
    #[derive(Debug, Clone, PartialEq, scale::Encode, scale::Decode)]
    #[cfg_attr(feature = "std", derive(scale_info::TypeInfo, ink::storage::traits::StorageLayout))]
    pub struct SpendingProposal {
        pub id: u128,
        pub beneficiary: AccountId,
        pub amount: Balance,
        pub description: String,
        pub proposer: AccountId,
        pub status: ProposalStatus,
        pub created_at: Timestamp,
        pub approved_at: Timestamp,
        pub executed_at: Timestamp,
    }

    /// Budget category
    #[derive(Debug, Clone, scale::Encode, scale::Decode)]
    #[cfg_attr(feature = "std", derive(scale_info::TypeInfo, ink::storage::traits::StorageLayout))]
    pub struct Budget {
        pub allocated: Balance,
        pub spent: Balance,
        pub active: bool,
    }

    /// Contract storage
    #[ink(storage)]
    pub struct DAOTreasury {
        /// Admin account
        admin: AccountId,
        /// Treasurer account
        treasurer: AccountId,
        /// Spender account
        spender: AccountId,
        /// Reference to DAOMembership
        membership: AccountId,
        /// Proposal counter
        proposal_counter: u128,
        /// Proposals mapping
        proposals: Mapping<u128, SpendingProposal>,
        /// Budgets mapping (category hash -> Budget)
        budgets: Mapping<[u8; 32], Budget>,
        /// Spending limits
        max_single_spend: Balance,
        daily_spend_limit: Balance,
        daily_spent: Balance,
        last_spend_day: u64,
    }

    /// Events
    #[ink(event)]
    pub struct ProposalCreated {
        #[ink(topic)]
        proposal_id: u128,
        #[ink(topic)]
        beneficiary: AccountId,
        amount: Balance,
        proposer: AccountId,
    }

    #[ink(event)]
    pub struct ProposalApproved {
        #[ink(topic)]
        proposal_id: u128,
        approver: AccountId,
    }

    #[ink(event)]
    pub struct ProposalExecuted {
        #[ink(topic)]
        proposal_id: u128,
        amount: Balance,
    }

    #[ink(event)]
    pub struct ProposalCancelled {
        #[ink(topic)]
        proposal_id: u128,
    }

    #[ink(event)]
    pub struct BudgetAllocated {
        category_hash: [u8; 32],
        amount: Balance,
    }

    #[ink(event)]
    pub struct BudgetSpent {
        category_hash: [u8; 32],
        amount: Balance,
    }

    #[ink(event)]
    pub struct FundsReceived {
        from: AccountId,
        amount: Balance,
    }

    #[ink(event)]
    pub struct LimitsUpdated {
        max_single_spend: Balance,
        daily_spend_limit: Balance,
    }

    /// Errors
    #[derive(Debug, PartialEq, Eq, scale::Encode, scale::Decode)]
    #[cfg_attr(feature = "std", derive(scale_info::TypeInfo))]
    pub enum Error {
        Unauthorized,
        InsufficientFunds,
        ProposalNotPending,
        ProposalNotApproved,
        ExceedsMaxSpend,
        ExceedsDailyLimit,
        BudgetExceeded,
        InvalidProposal,
        InvalidProposalId,
        TransferFailed,
    }

    impl DAOTreasury {
        /// Constructor
        #[ink(constructor)]
        pub fn new(membership: AccountId) -> Self {
            let caller = Self::env().caller();

            // Convert 100 ETH to native token (assuming 18 decimals)
            let max_single = 100_000_000_000_000_000_000; // 100 tokens
            let daily_limit = 500_000_000_000_000_000_000; // 500 tokens

            Self {
                admin: caller,
                treasurer: caller,
                spender: caller,
                membership,
                proposal_counter: 1,
                proposals: Mapping::default(),
                budgets: Mapping::default(),
                max_single_spend: max_single,
                daily_spend_limit: daily_limit,
                daily_spent: 0,
                last_spend_day: 0,
            }
        }

        /// Receive funds
        #[ink(message, payable)]
        pub fn deposit(&mut self) {
            let caller = self.env().caller();
            let amount = self.env().transferred_value();

            Self::env().emit_event(FundsReceived {
                from: caller,
                amount,
            });
        }

        // ===== PROPOSAL MANAGEMENT =====

        /// Create spending proposal
        #[ink(message)]
        pub fn create_proposal(
            &mut self,
            beneficiary: AccountId,
            amount: Balance,
            description: String,
            category: Option<String>,
        ) -> Result<u128, Error> {
            let proposer = self.env().caller();

            // Verify proposer is active member (cross-contract call needed)
            // TODO: Call DAOMembership to verify
            // For now, accept all callers

            if amount == 0 || beneficiary == AccountId::from([0u8; 32]) {
                return Err(Error::InvalidProposal);
            }

            let proposal_id = self.proposal_counter;
            let now = self.env().block_timestamp();

            // Check budget if category provided
            if let Some(cat) = category {
                let category_hash = self.hash_category(&cat);
                if let Some(budget) = self.budgets.get(category_hash) {
                    if budget.active && budget.spent + amount > budget.allocated {
                        return Err(Error::BudgetExceeded);
                    }
                }
            }

            let proposal = SpendingProposal {
                id: proposal_id,
                beneficiary,
                amount,
                description: description.clone(),
                proposer,
                status: ProposalStatus::Pending,
                created_at: now,
                approved_at: 0,
                executed_at: 0,
            };

            self.proposals.insert(proposal_id, &proposal);
            self.proposal_counter += 1;

            Self::env().emit_event(ProposalCreated {
                proposal_id,
                beneficiary,
                amount,
                proposer,
            });

            Ok(proposal_id)
        }

        /// Approve spending proposal
        #[ink(message)]
        pub fn approve_proposal(&mut self, proposal_id: u128) -> Result<(), Error> {
            // Only treasurer can approve
            if self.env().caller() != self.treasurer {
                return Err(Error::Unauthorized);
            }

            let mut proposal = self.proposals.get(proposal_id)
                .ok_or(Error::InvalidProposalId)?;

            if proposal.status != ProposalStatus::Pending {
                return Err(Error::ProposalNotPending);
            }

            // Check spending limits
            if proposal.amount > self.max_single_spend {
                return Err(Error::ExceedsMaxSpend);
            }

            let now = self.env().block_timestamp();
            proposal.status = ProposalStatus::Approved;
            proposal.approved_at = now;

            self.proposals.insert(proposal_id, &proposal);

            Self::env().emit_event(ProposalApproved {
                proposal_id,
                approver: self.env().caller(),
            });

            Ok(())
        }

        /// Execute approved proposal
        #[ink(message)]
        pub fn execute_proposal(
            &mut self,
            proposal_id: u128,
            category: Option<String>,
        ) -> Result<(), Error> {
            // Only spender can execute
            if self.env().caller() != self.spender {
                return Err(Error::Unauthorized);
            }

            let mut proposal = self.proposals.get(proposal_id)
                .ok_or(Error::InvalidProposalId)?;

            if proposal.status != ProposalStatus::Approved {
                return Err(Error::ProposalNotApproved);
            }

            // Check treasury balance
            if self.env().balance() < proposal.amount {
                return Err(Error::InsufficientFunds);
            }

            // Check daily spend limit
            let now = self.env().block_timestamp();
            let current_day = now / 86400; // Days since epoch

            if current_day > self.last_spend_day {
                // Reset daily counter
                self.daily_spent = 0;
                self.last_spend_day = current_day;
            }

            if self.daily_spent + proposal.amount > self.daily_spend_limit {
                return Err(Error::ExceedsDailyLimit);
            }

            // Update budget if category provided
            if let Some(cat) = category {
                let category_hash = self.hash_category(&cat);
                if let Some(mut budget) = self.budgets.get(category_hash) {
                    if budget.active {
                        budget.spent += proposal.amount;
                        self.budgets.insert(category_hash, &budget);

                        Self::env().emit_event(BudgetSpent {
                            category_hash,
                            amount: proposal.amount,
                        });
                    }
                }
            }

            // Update state
            proposal.status = ProposalStatus::Executed;
            proposal.executed_at = now;
            self.daily_spent += proposal.amount;

            self.proposals.insert(proposal_id, &proposal);

            // Transfer funds
            if self.env().transfer(proposal.beneficiary, proposal.amount).is_err() {
                return Err(Error::TransferFailed);
            }

            Self::env().emit_event(ProposalExecuted {
                proposal_id,
                amount: proposal.amount,
            });

            Ok(())
        }

        /// Cancel pending proposal
        #[ink(message)]
        pub fn cancel_proposal(&mut self, proposal_id: u128) -> Result<(), Error> {
            let caller = self.env().caller();

            let mut proposal = self.proposals.get(proposal_id)
                .ok_or(Error::InvalidProposalId)?;

            // Only proposer or treasurer can cancel
            if caller != proposal.proposer && caller != self.treasurer {
                return Err(Error::Unauthorized);
            }

            if proposal.status != ProposalStatus::Pending {
                return Err(Error::ProposalNotPending);
            }

            proposal.status = ProposalStatus::Cancelled;
            self.proposals.insert(proposal_id, &proposal);

            Self::env().emit_event(ProposalCancelled { proposal_id });

            Ok(())
        }

        // ===== BUDGET MANAGEMENT =====

        /// Allocate budget for category
        #[ink(message)]
        pub fn allocate_budget(&mut self, category: String, amount: Balance) -> Result<(), Error> {
            // Only treasurer can allocate
            if self.env().caller() != self.treasurer {
                return Err(Error::Unauthorized);
            }

            let category_hash = self.hash_category(&category);

            let budget = Budget {
                allocated: amount,
                spent: 0,
                active: true,
            };

            self.budgets.insert(category_hash, &budget);

            Self::env().emit_event(BudgetAllocated {
                category_hash,
                amount,
            });

            Ok(())
        }

        /// Update spending limits
        #[ink(message)]
        pub fn update_limits(
            &mut self,
            max_single_spend: Balance,
            daily_spend_limit: Balance,
        ) -> Result<(), Error> {
            // Only admin can update
            if self.env().caller() != self.admin {
                return Err(Error::Unauthorized);
            }

            self.max_single_spend = max_single_spend;
            self.daily_spend_limit = daily_spend_limit;

            Self::env().emit_event(LimitsUpdated {
                max_single_spend,
                daily_spend_limit,
            });

            Ok(())
        }

        // ===== VIEW FUNCTIONS =====

        /// Get proposal details
        #[ink(message)]
        pub fn get_proposal(&self, proposal_id: u128) -> Result<SpendingProposal, Error> {
            self.proposals.get(proposal_id).ok_or(Error::InvalidProposalId)
        }

        /// Get budget status
        #[ink(message)]
        pub fn get_budget(&self, category: String) -> Option<Budget> {
            let category_hash = self.hash_category(&category);
            self.budgets.get(category_hash)
        }

        /// Get treasury balance
        #[ink(message)]
        pub fn balance(&self) -> Balance {
            self.env().balance()
        }

        /// Get daily spend remaining
        #[ink(message)]
        pub fn daily_spend_remaining(&self) -> Balance {
            let now = self.env().block_timestamp();
            let current_day = now / 86400;

            if current_day > self.last_spend_day {
                return self.daily_spend_limit;
            }

            if self.daily_spend_limit > self.daily_spent {
                self.daily_spend_limit - self.daily_spent
            } else {
                0
            }
        }

        /// Get admin address
        #[ink(message)]
        pub fn get_admin(&self) -> AccountId {
            self.admin
        }

        /// Get treasurer address
        #[ink(message)]
        pub fn get_treasurer(&self) -> AccountId {
            self.treasurer
        }

        /// Set new treasurer
        #[ink(message)]
        pub fn set_treasurer(&mut self, new_treasurer: AccountId) -> Result<(), Error> {
            if self.env().caller() != self.admin {
                return Err(Error::Unauthorized);
            }

            self.treasurer = new_treasurer;
            Ok(())
        }

        // ===== INTERNAL FUNCTIONS =====

        fn hash_category(&self, category: &str) -> [u8; 32] {
            use ink::env::hash::{Blake2x256, HashOutput};

            let mut output = <Blake2x256 as HashOutput>::Type::default();
            ink::env::hash_bytes::<Blake2x256>(category.as_bytes(), &mut output);
            output
        }
    }

    /// Unit tests
    #[cfg(test)]
    mod tests {
        use super::*;

        #[ink::test]
        fn test_constructor() {
            let accounts = ink::env::test::default_accounts::<ink::env::DefaultEnvironment>();
            let treasury = DAOTreasury::new(accounts.bob);

            // Test environment gives contracts default endowment of 1_000_000
            assert_eq!(treasury.balance(), 1_000_000);
            assert_eq!(treasury.proposal_counter, 1);
        }

        #[ink::test]
        fn test_create_proposal() {
            let accounts = ink::env::test::default_accounts::<ink::env::DefaultEnvironment>();
            let mut treasury = DAOTreasury::new(accounts.bob);

            let result = treasury.create_proposal(
                accounts.charlie,
                1000,
                String::from("Test payment"),
                None,
            );

            assert!(result.is_ok());
            assert_eq!(result.unwrap(), 1);

            let proposal = treasury.get_proposal(1).unwrap();
            assert_eq!(proposal.amount, 1000);
            assert_eq!(proposal.status, ProposalStatus::Pending);
        }

        #[ink::test]
        fn test_approve_proposal() {
            let accounts = ink::env::test::default_accounts::<ink::env::DefaultEnvironment>();
            let mut treasury = DAOTreasury::new(accounts.bob);

            // Create proposal
            let proposal_id = treasury.create_proposal(
                accounts.charlie,
                1000,
                String::from("Test"),
                None,
            ).unwrap();

            // Approve (caller is treasurer by default)
            let result = treasury.approve_proposal(proposal_id);
            assert!(result.is_ok());

            let proposal = treasury.get_proposal(proposal_id).unwrap();
            assert_eq!(proposal.status, ProposalStatus::Approved);
        }

        #[ink::test]
        fn test_unauthorized_approve() {
            let accounts = ink::env::test::default_accounts::<ink::env::DefaultEnvironment>();
            let mut treasury = DAOTreasury::new(accounts.bob);

            let proposal_id = treasury.create_proposal(
                accounts.charlie,
                1000,
                String::from("Test"),
                None,
            ).unwrap();

            // Change to non-treasurer
            ink::env::test::set_caller::<ink::env::DefaultEnvironment>(accounts.charlie);

            let result = treasury.approve_proposal(proposal_id);
            assert_eq!(result, Err(Error::Unauthorized));
        }

        #[ink::test]
        fn test_cancel_proposal() {
            let accounts = ink::env::test::default_accounts::<ink::env::DefaultEnvironment>();
            let mut treasury = DAOTreasury::new(accounts.bob);

            let proposal_id = treasury.create_proposal(
                accounts.charlie,
                1000,
                String::from("Test"),
                None,
            ).unwrap();

            // Cancel as proposer
            let result = treasury.cancel_proposal(proposal_id);
            assert!(result.is_ok());

            let proposal = treasury.get_proposal(proposal_id).unwrap();
            assert_eq!(proposal.status, ProposalStatus::Cancelled);
        }

        #[ink::test]
        fn test_exceeds_max_spend() {
            let accounts = ink::env::test::default_accounts::<ink::env::DefaultEnvironment>();
            let mut treasury = DAOTreasury::new(accounts.bob);

            // Create proposal exceeding max single spend (100 tokens)
            let proposal_id = treasury.create_proposal(
                accounts.charlie,
                150_000_000_000_000_000_000, // 150 tokens
                String::from("Big payment"),
                None,
            ).unwrap();

            // Try to approve - should fail
            let result = treasury.approve_proposal(proposal_id);
            assert_eq!(result, Err(Error::ExceedsMaxSpend));
        }

        #[ink::test]
        fn test_allocate_budget() {
            let accounts = ink::env::test::default_accounts::<ink::env::DefaultEnvironment>();
            let mut treasury = DAOTreasury::new(accounts.bob);

            // Allocate budget
            let result = treasury.allocate_budget(
                String::from("development"),
                50_000_000_000_000_000_000, // 50 tokens
            );
            assert!(result.is_ok());

            // Verify budget
            let budget = treasury.get_budget(String::from("development")).unwrap();
            assert_eq!(budget.allocated, 50_000_000_000_000_000_000);
            assert_eq!(budget.spent, 0);
            assert!(budget.active);
        }

        #[ink::test]
        fn test_budget_exceeded() {
            let accounts = ink::env::test::default_accounts::<ink::env::DefaultEnvironment>();
            let mut treasury = DAOTreasury::new(accounts.bob);

            // Allocate budget
            treasury.allocate_budget(
                String::from("development"),
                30_000_000_000_000_000_000, // 30 tokens
            ).unwrap();

            // Try to create proposal exceeding budget
            let result = treasury.create_proposal(
                accounts.charlie,
                40_000_000_000_000_000_000, // 40 tokens
                String::from("Over budget"),
                Some(String::from("development")),
            );

            assert_eq!(result, Err(Error::BudgetExceeded));
        }

        #[ink::test]
        fn test_update_limits() {
            let accounts = ink::env::test::default_accounts::<ink::env::DefaultEnvironment>();
            let mut treasury = DAOTreasury::new(accounts.bob);

            // Update limits
            let result = treasury.update_limits(
                200_000_000_000_000_000_000, // 200 tokens max
                1000_000_000_000_000_000_000, // 1000 tokens daily
            );
            assert!(result.is_ok());
        }

        #[ink::test]
        fn test_unauthorized_update_limits() {
            let accounts = ink::env::test::default_accounts::<ink::env::DefaultEnvironment>();
            let mut treasury = DAOTreasury::new(accounts.bob);

            // Change to non-admin
            ink::env::test::set_caller::<ink::env::DefaultEnvironment>(accounts.charlie);

            let result = treasury.update_limits(
                200_000_000_000_000_000_000,
                1000_000_000_000_000_000_000,
            );

            assert_eq!(result, Err(Error::Unauthorized));
        }

        #[ink::test]
        fn test_daily_spend_remaining() {
            let accounts = ink::env::test::default_accounts::<ink::env::DefaultEnvironment>();
            let treasury = DAOTreasury::new(accounts.bob);

            // Should return full daily limit initially
            let remaining = treasury.daily_spend_remaining();
            assert_eq!(remaining, 500_000_000_000_000_000_000); // 500 tokens
        }

        #[ink::test]
        fn test_set_treasurer() {
            let accounts = ink::env::test::default_accounts::<ink::env::DefaultEnvironment>();
            let mut treasury = DAOTreasury::new(accounts.bob);

            // Set new treasurer
            let result = treasury.set_treasurer(accounts.charlie);
            assert!(result.is_ok());

            assert_eq!(treasury.get_treasurer(), accounts.charlie);
        }

        #[ink::test]
        fn test_invalid_proposal() {
            let accounts = ink::env::test::default_accounts::<ink::env::DefaultEnvironment>();
            let mut treasury = DAOTreasury::new(accounts.bob);

            // Zero amount
            let result = treasury.create_proposal(
                accounts.charlie,
                0,
                String::from("Zero payment"),
                None,
            );
            assert_eq!(result, Err(Error::InvalidProposal));

            // Zero address
            let result = treasury.create_proposal(
                AccountId::from([0u8; 32]),
                1000,
                String::from("Zero address"),
                None,
            );
            assert_eq!(result, Err(Error::InvalidProposal));
        }

        #[ink::test]
        fn test_proposal_not_pending() {
            let accounts = ink::env::test::default_accounts::<ink::env::DefaultEnvironment>();
            let mut treasury = DAOTreasury::new(accounts.bob);

            let proposal_id = treasury.create_proposal(
                accounts.charlie,
                1000,
                String::from("Test"),
                None,
            ).unwrap();

            // Approve first time
            treasury.approve_proposal(proposal_id).unwrap();

            // Try to approve again
            let result = treasury.approve_proposal(proposal_id);
            assert_eq!(result, Err(Error::ProposalNotPending));
        }

        #[ink::test]
        fn test_multiple_proposals() {
            let accounts = ink::env::test::default_accounts::<ink::env::DefaultEnvironment>();
            let mut treasury = DAOTreasury::new(accounts.bob);

            // Create multiple proposals
            let id1 = treasury.create_proposal(
                accounts.charlie,
                1000,
                String::from("Proposal 1"),
                None,
            ).unwrap();

            let id2 = treasury.create_proposal(
                accounts.django,
                2000,
                String::from("Proposal 2"),
                None,
            ).unwrap();

            assert_eq!(id1, 1);
            assert_eq!(id2, 2);

            // Both should exist
            assert!(treasury.get_proposal(id1).is_ok());
            assert!(treasury.get_proposal(id2).is_ok());
        }

        #[ink::test]
        fn test_invalid_proposal_id() {
            let accounts = ink::env::test::default_accounts::<ink::env::DefaultEnvironment>();
            let treasury = DAOTreasury::new(accounts.bob);

            // Try to get non-existent proposal
            let result = treasury.get_proposal(999);
            assert_eq!(result, Err(Error::InvalidProposalId));
        }

        #[ink::test]
        fn test_category_hashing() {
            let accounts = ink::env::test::default_accounts::<ink::env::DefaultEnvironment>();
            let treasury = DAOTreasury::new(accounts.bob);

            // Same category should produce same hash
            let budget1 = treasury.get_budget(String::from("development"));
            let budget2 = treasury.get_budget(String::from("development"));

            // Both should be None initially (or both Some with same data)
            assert_eq!(budget1.is_some(), budget2.is_some());
        }

        #[ink::test]
        fn test_get_admin() {
            let accounts = ink::env::test::default_accounts::<ink::env::DefaultEnvironment>();
            let treasury = DAOTreasury::new(accounts.bob);

            // Admin should be caller (alice by default in tests)
            assert_eq!(treasury.get_admin(), accounts.alice);
        }

        #[ink::test]
        fn test_balance() {
            let accounts = ink::env::test::default_accounts::<ink::env::DefaultEnvironment>();
            let treasury = DAOTreasury::new(accounts.bob);

            // Test environment gives contracts default endowment of 1_000_000
            assert_eq!(treasury.balance(), 1_000_000);
        }
    }
}
