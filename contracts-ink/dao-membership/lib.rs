#![cfg_attr(not(feature = "std"), no_std, no_main)]

/// # DAOMembership - Polkadot 2.0 Native
///
/// Gestion des membres du DAO avec système de rangs hiérarchiques
/// inspiré du Technical Fellowship de Polkadot (rangs 0-4)
///
/// ## Rangs
/// - Rang 0 : Junior (<2 ans expérience)
/// - Rang 1 : Consultant (3-5 ans)
/// - Rang 2 : Senior (6-10 ans)
/// - Rang 3 : Manager (10-15 ans)
/// - Rang 4 : Partner (15+ ans)
///
/// ## Vote Weight
/// Standard triangular numbers:
/// weight(r) = r × (r + 1) / 2
/// - Rank 0: 0, Rank 1: 1, Rank 2: 3, Rank 3: 6, Rank 4: 10

#[ink::contract]
mod dao_membership {
    use ink::prelude::string::String;
    use ink::prelude::vec::Vec;
    use ink::storage::Mapping;

    /// Member structure
    #[derive(Debug, Clone, PartialEq, scale::Encode, scale::Decode)]
    #[cfg_attr(feature = "std", derive(scale_info::TypeInfo, ink::storage::traits::StorageLayout))]
    pub struct Member {
        /// Rang actuel (0-4)
        pub rank: u8,
        /// Timestamp d'adhésion (block timestamp)
        pub joined_at: Timestamp,
        /// Timestamp dernière promotion
        pub last_promoted_at: Timestamp,
        /// Identifiant GitHub (optionnel)
        pub github_handle: String,
        /// Statut actif/inactif
        pub active: bool,
    }

    /// Contract storage
    #[ink(storage)]
    pub struct DAOMembership {
        /// Admin account (deployer)
        admin: AccountId,
        /// Member manager account
        member_manager: AccountId,
        /// Mapping members address -> Member struct
        members: Mapping<AccountId, Member>,
        /// List of all member addresses
        member_addresses: Vec<AccountId>,
        /// Minimum rank duration in seconds (5 values for ranks 0-4)
        /// [0, 90 days, 180 days, 365 days, 547 days]
        min_rank_duration: [Timestamp; 5],
    }

    /// Events
    #[ink(event)]
    pub struct MemberAdded {
        #[ink(topic)]
        member: AccountId,
        rank: u8,
        github_handle: String,
    }

    #[ink(event)]
    pub struct MemberPromoted {
        #[ink(topic)]
        member: AccountId,
        old_rank: u8,
        new_rank: u8,
    }

    #[ink(event)]
    pub struct MemberDemoted {
        #[ink(topic)]
        member: AccountId,
        old_rank: u8,
        new_rank: u8,
    }

    #[ink(event)]
    pub struct MemberRemoved {
        #[ink(topic)]
        member: AccountId,
    }

    #[ink(event)]
    pub struct MemberActivated {
        #[ink(topic)]
        member: AccountId,
    }

    #[ink(event)]
    pub struct MemberDeactivated {
        #[ink(topic)]
        member: AccountId,
    }

    /// Errors
    #[derive(Debug, PartialEq, Eq, scale::Encode, scale::Decode)]
    #[cfg_attr(feature = "std", derive(scale_info::TypeInfo))]
    pub enum Error {
        /// Caller is not authorized
        Unauthorized,
        /// Invalid address (zero address)
        InvalidAddress,
        /// Invalid rank (max 4)
        InvalidRank,
        /// Address is already a member
        AlreadyMember,
        /// Address is not a member
        NotMember,
        /// Member is inactive
        MemberInactive,
        /// Already at maximum rank (4)
        AlreadyMaxRank,
        /// Already at minimum rank (0)
        AlreadyMinRank,
        /// Minimum duration at current rank not met
        MinDurationNotMet,
        /// Rank too low for this operation
        RankTooLow,
    }

    impl DAOMembership {
        /// Constructor
        #[ink(constructor)]
        pub fn new() -> Self {
            let caller = Self::env().caller();

            Self {
                admin: caller,
                member_manager: caller,
                members: Mapping::default(),
                member_addresses: Vec::new(),
                // Durations in seconds: [0, 90 days, 180 days, 365 days, 547 days]
                min_rank_duration: [
                    0,
                    7_776_000,    // 90 days
                    15_552_000,   // 180 days
                    31_536_000,   // 365 days
                    47_260_800,   // 547 days
                ],
            }
        }

        // ===== MEMBER MANAGEMENT =====

        /// Add a new member to the DAO
        #[ink(message)]
        pub fn add_member(
            &mut self,
            member: AccountId,
            rank: u8,
            github_handle: String,
        ) -> Result<(), Error> {
            // Only member_manager can add members
            if self.env().caller() != self.member_manager {
                return Err(Error::Unauthorized);
            }

            // Validate inputs
            if member == AccountId::from([0u8; 32]) {
                return Err(Error::InvalidAddress);
            }
            if rank > 4 {
                return Err(Error::InvalidRank);
            }
            if self.is_member(member) {
                return Err(Error::AlreadyMember);
            }

            // Create member
            let now = self.env().block_timestamp();
            let new_member = Member {
                rank,
                joined_at: now,
                last_promoted_at: now,
                github_handle: github_handle.clone(),
                active: true,
            };

            self.members.insert(member, &new_member);
            self.member_addresses.push(member);

            Self::env().emit_event(MemberAdded {
                member,
                rank,
                github_handle,
            });

            Ok(())
        }

        /// Promote member to next rank
        #[ink(message)]
        pub fn promote_member(&mut self, member: AccountId) -> Result<(), Error> {
            // Only member_manager can promote
            if self.env().caller() != self.member_manager {
                return Err(Error::Unauthorized);
            }

            if !self.is_member(member) {
                return Err(Error::NotMember);
            }

            let mut member_data = self.members.get(member).unwrap();

            if member_data.rank >= 4 {
                return Err(Error::AlreadyMaxRank);
            }

            // Check minimum duration at current rank
            let now = self.env().block_timestamp();
            let time_at_rank = now - member_data.last_promoted_at;
            let next_rank = (member_data.rank + 1) as usize;

            if time_at_rank < self.min_rank_duration[next_rank] {
                return Err(Error::MinDurationNotMet);
            }

            let old_rank = member_data.rank;
            member_data.rank += 1;
            member_data.last_promoted_at = now;

            self.members.insert(member, &member_data);

            Self::env().emit_event(MemberPromoted {
                member,
                old_rank,
                new_rank: member_data.rank,
            });

            Ok(())
        }

        /// Demote member to previous rank
        #[ink(message)]
        pub fn demote_member(&mut self, member: AccountId) -> Result<(), Error> {
            // Only admin can demote
            if self.env().caller() != self.admin {
                return Err(Error::Unauthorized);
            }

            if !self.is_member(member) {
                return Err(Error::NotMember);
            }

            let mut member_data = self.members.get(member).unwrap();

            if member_data.rank == 0 {
                return Err(Error::AlreadyMinRank);
            }

            let old_rank = member_data.rank;
            member_data.rank -= 1;

            self.members.insert(member, &member_data);

            Self::env().emit_event(MemberDemoted {
                member,
                old_rank,
                new_rank: member_data.rank,
            });

            Ok(())
        }

        /// Remove member from DAO
        #[ink(message)]
        pub fn remove_member(&mut self, member: AccountId) -> Result<(), Error> {
            // Only admin can remove
            if self.env().caller() != self.admin {
                return Err(Error::Unauthorized);
            }

            if !self.is_member(member) {
                return Err(Error::NotMember);
            }

            self.members.remove(member);

            // Remove from member_addresses
            if let Some(pos) = self.member_addresses.iter().position(|&x| x == member) {
                self.member_addresses.swap_remove(pos);
            }

            Self::env().emit_event(MemberRemoved { member });

            Ok(())
        }

        /// Set member active/inactive status
        #[ink(message)]
        pub fn set_member_active(&mut self, member: AccountId, active: bool) -> Result<(), Error> {
            // Only member_manager can change status
            if self.env().caller() != self.member_manager {
                return Err(Error::Unauthorized);
            }

            if !self.is_member(member) {
                return Err(Error::NotMember);
            }

            let mut member_data = self.members.get(member).unwrap();
            member_data.active = active;
            self.members.insert(member, &member_data);

            if active {
                Self::env().emit_event(MemberActivated { member });
            } else {
                Self::env().emit_event(MemberDeactivated { member });
            }

            Ok(())
        }

        // ===== VOTE WEIGHT CALCULATION =====

        /// Calculate vote weight for a member
        /// Formula: weight(r) = r × (r + 1) / 2
        #[ink(message)]
        pub fn calculate_vote_weight(
            &self,
            member: AccountId,
            min_rank: u8,
        ) -> Result<u128, Error> {
            if !self.is_member(member) {
                return Err(Error::NotMember);
            }

            let member_data = self.members.get(member).unwrap();

            if !member_data.active {
                return Err(Error::MemberInactive);
            }

            if member_data.rank < min_rank {
                return Err(Error::RankTooLow);
            }

            // Triangular number formula
            let rank = member_data.rank as u128;
            let weight = rank * (rank + 1) / 2;

            Ok(weight)
        }

        /// Calculate total vote weight of all active members
        #[ink(message)]
        pub fn calculate_total_vote_weight(&self, min_rank: u8) -> u128 {
            let mut total_weight: u128 = 0;

            for member in self.member_addresses.iter() {
                if let Some(member_data) = self.members.get(member) {
                    if member_data.active && member_data.rank >= min_rank {
                        let rank = member_data.rank as u128;
                        total_weight += rank * (rank + 1) / 2;
                    }
                }
            }

            total_weight
        }

        // ===== VIEW FUNCTIONS =====

        /// Check if address is a member
        #[ink(message)]
        pub fn is_member(&self, account: AccountId) -> bool {
            self.members.contains(account)
        }

        /// Get member information
        #[ink(message)]
        pub fn get_member_info(&self, member: AccountId) -> Result<Member, Error> {
            if !self.is_member(member) {
                return Err(Error::NotMember);
            }

            Ok(self.members.get(member).unwrap())
        }

        /// Get total member count
        #[ink(message)]
        pub fn get_member_count(&self) -> u32 {
            self.member_addresses.len() as u32
        }

        /// Get all active members of a specific rank
        #[ink(message)]
        pub fn get_active_members_by_rank(&self, rank: u8) -> Result<Vec<AccountId>, Error> {
            if rank > 4 {
                return Err(Error::InvalidRank);
            }

            let mut result = Vec::new();

            for member in self.member_addresses.iter() {
                if let Some(member_data) = self.members.get(member) {
                    if member_data.active && member_data.rank == rank {
                        result.push(*member);
                    }
                }
            }

            Ok(result)
        }

        /// Get admin address
        #[ink(message)]
        pub fn get_admin(&self) -> AccountId {
            self.admin
        }

        /// Get member manager address
        #[ink(message)]
        pub fn get_member_manager(&self) -> AccountId {
            self.member_manager
        }

        /// Set new member manager (admin only)
        #[ink(message)]
        pub fn set_member_manager(&mut self, new_manager: AccountId) -> Result<(), Error> {
            if self.env().caller() != self.admin {
                return Err(Error::Unauthorized);
            }

            self.member_manager = new_manager;
            Ok(())
        }

        /// Calculate vote weight for a given rank (helper for testing)
        /// Triangular number formula: rank * (rank + 1) / 2
        #[ink(message)]
        pub fn calculate_vote_weight_for_rank(&self, rank: u8) -> u128 {
            if rank > 4 {
                return 0;
            }
            (rank as u128 * (rank as u128 + 1)) / 2
        }

        /// Get all member addresses (helper for testing and enumeration)
        #[ink(message)]
        pub fn get_all_members(&self) -> Vec<AccountId> {
            self.member_addresses.clone()
        }
    }

    /// Unit tests
    #[cfg(test)]
    mod tests {
        use super::*;

        #[ink::test]
        fn test_constructor() {
            let contract = DAOMembership::new();
            assert_eq!(contract.get_member_count(), 0);
        }

        #[ink::test]
        fn test_add_member() {
            let mut contract = DAOMembership::new();
            let accounts = ink::env::test::default_accounts::<ink::env::DefaultEnvironment>();

            let result = contract.add_member(
                accounts.bob,
                1,
                String::from("bob_github"),
            );

            assert!(result.is_ok());
            assert!(contract.is_member(accounts.bob));
            assert_eq!(contract.get_member_count(), 1);
        }

        #[ink::test]
        fn test_calculate_vote_weight() {
            let mut contract = DAOMembership::new();
            let accounts = ink::env::test::default_accounts::<ink::env::DefaultEnvironment>();

            // Add member with rank 2
            contract.add_member(accounts.bob, 2, String::from("bob")).unwrap();

            // Weight for rank 2 should be 3 (triangular number)
            let weight = contract.calculate_vote_weight(accounts.bob, 0).unwrap();
            assert_eq!(weight, 3);
        }

        #[ink::test]
        fn test_rank_too_low() {
            let mut contract = DAOMembership::new();
            let accounts = ink::env::test::default_accounts::<ink::env::DefaultEnvironment>();

            // Add member with rank 1
            contract.add_member(accounts.bob, 1, String::from("bob")).unwrap();

            // Should fail with min_rank = 2
            let result = contract.calculate_vote_weight(accounts.bob, 2);
            assert_eq!(result, Err(Error::RankTooLow));
        }

        #[ink::test]
        fn test_total_vote_weight() {
            let mut contract = DAOMembership::new();
            let accounts = ink::env::test::default_accounts::<ink::env::DefaultEnvironment>();

            // Add members: rank 1 (weight 1), rank 2 (weight 3)
            contract.add_member(accounts.bob, 1, String::from("bob")).unwrap();
            contract.add_member(accounts.charlie, 2, String::from("charlie")).unwrap();

            // Total weight should be 1 + 3 = 4
            let total = contract.calculate_total_vote_weight(0);
            assert_eq!(total, 4);
        }

        #[ink::test]
        fn test_unauthorized_add_member() {
            let mut contract = DAOMembership::new();
            let accounts = ink::env::test::default_accounts::<ink::env::DefaultEnvironment>();

            // Change caller to non-manager
            ink::env::test::set_caller::<ink::env::DefaultEnvironment>(accounts.bob);

            let result = contract.add_member(
                accounts.charlie,
                1,
                String::from("charlie"),
            );

            assert_eq!(result, Err(Error::Unauthorized));
        }

        #[ink::test]
        fn test_promote_member() {
            let mut contract = DAOMembership::new();
            let accounts = ink::env::test::default_accounts::<ink::env::DefaultEnvironment>();

            // Add member at rank 1
            contract.add_member(accounts.bob, 1, String::from("bob")).unwrap();

            // Advance time by 180 days (15_552_000 seconds) to meet minimum duration for rank 2
            ink::env::test::advance_block::<ink::env::DefaultEnvironment>();
            ink::env::test::set_block_timestamp::<ink::env::DefaultEnvironment>(15_552_000);

            // Promote to rank 2
            let result = contract.promote_member(accounts.bob);
            assert!(result.is_ok());

            let member = contract.get_member_info(accounts.bob).unwrap();
            assert_eq!(member.rank, 2);
        }

        #[ink::test]
        fn test_promote_max_rank() {
            let mut contract = DAOMembership::new();
            let accounts = ink::env::test::default_accounts::<ink::env::DefaultEnvironment>();

            // Add member at max rank
            contract.add_member(accounts.bob, 4, String::from("bob")).unwrap();

            // Try to promote beyond max
            let result = contract.promote_member(accounts.bob);
            assert_eq!(result, Err(Error::AlreadyMaxRank));
        }

        #[ink::test]
        fn test_demote_member() {
            let mut contract = DAOMembership::new();
            let accounts = ink::env::test::default_accounts::<ink::env::DefaultEnvironment>();

            // Add member at rank 2
            contract.add_member(accounts.bob, 2, String::from("bob")).unwrap();

            // Demote to rank 1
            let result = contract.demote_member(accounts.bob);
            assert!(result.is_ok());

            let member = contract.get_member_info(accounts.bob).unwrap();
            assert_eq!(member.rank, 1);
        }

        #[ink::test]
        fn test_demote_min_rank() {
            let mut contract = DAOMembership::new();
            let accounts = ink::env::test::default_accounts::<ink::env::DefaultEnvironment>();

            // Add member at min rank
            contract.add_member(accounts.bob, 0, String::from("bob")).unwrap();

            // Try to demote below min
            let result = contract.demote_member(accounts.bob);
            assert_eq!(result, Err(Error::AlreadyMinRank));
        }

        #[ink::test]
        fn test_remove_member() {
            let mut contract = DAOMembership::new();
            let accounts = ink::env::test::default_accounts::<ink::env::DefaultEnvironment>();

            // Add member
            contract.add_member(accounts.bob, 1, String::from("bob")).unwrap();

            // Remove member
            let result = contract.remove_member(accounts.bob);
            assert!(result.is_ok());

            // Verify member no longer exists
            assert!(contract.get_member_info(accounts.bob).is_err());
            assert_eq!(contract.get_member_count(), 0);
        }

        #[ink::test]
        fn test_set_member_active() {
            let mut contract = DAOMembership::new();
            let accounts = ink::env::test::default_accounts::<ink::env::DefaultEnvironment>();

            // Add member
            contract.add_member(accounts.bob, 1, String::from("bob")).unwrap();

            // Deactivate member
            contract.set_member_active(accounts.bob, false).unwrap();

            let member = contract.get_member_info(accounts.bob).unwrap();
            assert!(!member.active);

            // Reactivate member
            contract.set_member_active(accounts.bob, true).unwrap();

            let member = contract.get_member_info(accounts.bob).unwrap();
            assert!(member.active);
        }

        #[ink::test]
        fn test_vote_weight_calculation() {
            let contract = DAOMembership::new();

            // Test triangular numbers: rank * (rank + 1) / 2
            // Rank 0: 0 * 1 / 2 = 0
            // Rank 1: 1 * 2 / 2 = 1
            // Rank 2: 2 * 3 / 2 = 3
            // Rank 3: 3 * 4 / 2 = 6
            // Rank 4: 4 * 5 / 2 = 10

            assert_eq!(contract.calculate_vote_weight_for_rank(0), 0);
            assert_eq!(contract.calculate_vote_weight_for_rank(1), 1);
            assert_eq!(contract.calculate_vote_weight_for_rank(2), 3);
            assert_eq!(contract.calculate_vote_weight_for_rank(3), 6);
            assert_eq!(contract.calculate_vote_weight_for_rank(4), 10);
        }

        #[ink::test]
        fn test_min_rank_filtering() {
            let mut contract = DAOMembership::new();
            let accounts = ink::env::test::default_accounts::<ink::env::DefaultEnvironment>();

            // Add members with different ranks
            contract.add_member(accounts.bob, 0, String::from("bob")).unwrap();
            contract.add_member(accounts.charlie, 2, String::from("charlie")).unwrap();
            contract.add_member(accounts.django, 3, String::from("django")).unwrap();

            // Calculate total weight with min_rank = 2
            // Only charlie (rank 2, weight 3) and django (rank 3, weight 6) count
            let total = contract.calculate_total_vote_weight(2);
            assert_eq!(total, 9); // 3 + 6
        }

        #[ink::test]
        fn test_get_all_members() {
            let mut contract = DAOMembership::new();
            let accounts = ink::env::test::default_accounts::<ink::env::DefaultEnvironment>();

            // Add multiple members
            contract.add_member(accounts.bob, 1, String::from("bob")).unwrap();
            contract.add_member(accounts.charlie, 2, String::from("charlie")).unwrap();

            let members = contract.get_all_members();
            assert_eq!(members.len(), 2);
            assert!(members.contains(&accounts.bob));
            assert!(members.contains(&accounts.charlie));
        }

        #[ink::test]
        fn test_role_management() {
            let mut contract = DAOMembership::new();
            let accounts = ink::env::test::default_accounts::<ink::env::DefaultEnvironment>();

            // Set new member manager
            contract.set_member_manager(accounts.bob).unwrap();
            assert_eq!(contract.get_member_manager(), accounts.bob);

            // Change caller to new manager
            ink::env::test::set_caller::<ink::env::DefaultEnvironment>(accounts.bob);

            // New manager can add members
            let result = contract.add_member(accounts.charlie, 1, String::from("charlie"));
            assert!(result.is_ok());
        }

        #[ink::test]
        fn test_member_already_exists() {
            let mut contract = DAOMembership::new();
            let accounts = ink::env::test::default_accounts::<ink::env::DefaultEnvironment>();

            // Add member
            contract.add_member(accounts.bob, 1, String::from("bob")).unwrap();

            // Try to add same member again
            let result = contract.add_member(accounts.bob, 2, String::from("bob_duplicate"));
            assert_eq!(result, Err(Error::AlreadyMember));
        }

        #[ink::test]
        fn test_member_not_found() {
            let contract = DAOMembership::new();
            let accounts = ink::env::test::default_accounts::<ink::env::DefaultEnvironment>();

            // Try to get non-existent member
            let result = contract.get_member_info(accounts.bob);
            assert_eq!(result, Err(Error::NotMember));
        }

        #[ink::test]
        fn test_invalid_rank() {
            let mut contract = DAOMembership::new();
            let accounts = ink::env::test::default_accounts::<ink::env::DefaultEnvironment>();

            // Try to add member with rank > 4
            let result = contract.add_member(accounts.bob, 5, String::from("bob"));
            assert_eq!(result, Err(Error::InvalidRank));
        }
    }
}
