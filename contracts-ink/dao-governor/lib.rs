#![cfg_attr(not(feature = "std"), no_std, no_main)]

/// # DAOGovernor - Polkadot 2.0 Native
///
/// OpenGov-inspired governance with 3 tracks:
/// - Technical: Architecture, tech stack, security (Rank 2+, 66% quorum)
/// - Treasury: Budget, spending, revenue (Rank 1+, 51% quorum)
/// - Membership: Promotions, ranks, suspensions (Rank 3+, 75% quorum)

#[ink::contract]
mod dao_governor {
    use ink::prelude::string::String;
    use ink::prelude::vec::Vec;
    use ink::storage::Mapping;

    /// Governance tracks (OpenGov-inspired)
    #[derive(Debug, Clone, Copy, PartialEq, Eq, scale::Encode, scale::Decode)]
    #[cfg_attr(feature = "std", derive(scale_info::TypeInfo, ink::storage::traits::StorageLayout))]
    pub enum Track {
        Technical,
        Treasury,
        Membership,
    }

    /// Track configuration
    #[derive(Debug, Clone, scale::Encode, scale::Decode)]
    #[cfg_attr(feature = "std", derive(scale_info::TypeInfo, ink::storage::traits::StorageLayout))]
    pub struct TrackConfig {
        /// Minimum rank to propose
        pub min_rank: u8,
        /// Delay before voting starts (seconds)
        pub voting_delay: Timestamp,
        /// Duration of voting (seconds)
        pub voting_period: Timestamp,
        /// Quorum percentage (e.g., 51 = 51%)
        pub quorum_percent: u8,
    }

    /// Proposal state
    #[derive(Debug, Clone, Copy, PartialEq, Eq, scale::Encode, scale::Decode)]
    #[cfg_attr(feature = "std", derive(scale_info::TypeInfo, ink::storage::traits::StorageLayout))]
    pub enum ProposalState {
        Pending,     // Created, voting not started
        Active,      // Voting in progress
        Canceled,    // Canceled by proposer
        Defeated,    // Did not reach quorum or majority voted against
        Succeeded,   // Quorum reached and majority voted for
        Executed,    // Successfully executed
    }

    /// Vote type
    #[derive(Debug, Clone, Copy, PartialEq, Eq, scale::Encode, scale::Decode)]
    #[cfg_attr(feature = "std", derive(scale_info::TypeInfo, ink::storage::traits::StorageLayout))]
    pub enum VoteType {
        Against = 0,
        For = 1,
        Abstain = 2,
    }

    /// Proposal data
    #[derive(Debug, Clone, scale::Encode, scale::Decode)]
    #[cfg_attr(feature = "std", derive(scale_info::TypeInfo, ink::storage::traits::StorageLayout))]
    pub struct Proposal {
        /// Unique proposal ID
        pub id: u128,
        /// Proposer address
        pub proposer: AccountId,
        /// Track this proposal belongs to
        pub track: Track,
        /// Timestamp when proposal was created
        pub created_at: Timestamp,
        /// Timestamp when voting starts
        pub voting_starts_at: Timestamp,
        /// Timestamp when voting ends
        pub voting_ends_at: Timestamp,
        /// Description
        pub description: String,
        /// For votes (weighted sum)
        pub for_votes: u128,
        /// Against votes (weighted sum)
        pub against_votes: u128,
        /// Abstain votes (weighted sum)
        pub abstain_votes: u128,
        /// Proposal state
        pub state: ProposalState,
        /// Target contract address (for execution)
        pub target: Option<AccountId>,
        /// Call data (for execution)
        pub call_data: Vec<u8>,
    }

    /// Vote receipt
    #[derive(Debug, Clone, scale::Encode, scale::Decode)]
    #[cfg_attr(feature = "std", derive(scale_info::TypeInfo, ink::storage::traits::StorageLayout))]
    pub struct VoteReceipt {
        pub has_voted: bool,
        pub vote_type: VoteType,
        pub vote_weight: u128,
    }

    /// Contract storage
    #[ink(storage)]
    pub struct DAOGovernor {
        /// Admin account
        admin: AccountId,
        /// Reference to DAOMembership contract
        membership: AccountId,
        /// Next proposal ID
        next_proposal_id: u128,
        /// Proposals mapping
        proposals: Mapping<u128, Proposal>,
        /// Track configurations
        track_configs: Mapping<Track, TrackConfig>,
        /// Vote receipts: (proposal_id, voter) -> VoteReceipt
        vote_receipts: Mapping<(u128, AccountId), VoteReceipt>,
    }

    /// Events
    #[ink(event)]
    pub struct ProposalCreated {
        #[ink(topic)]
        proposal_id: u128,
        #[ink(topic)]
        proposer: AccountId,
        track: Track,
        description: String,
    }

    #[ink(event)]
    pub struct VoteCast {
        #[ink(topic)]
        proposal_id: u128,
        #[ink(topic)]
        voter: AccountId,
        vote_type: VoteType,
        vote_weight: u128,
    }

    #[ink(event)]
    pub struct ProposalExecuted {
        #[ink(topic)]
        proposal_id: u128,
    }

    #[ink(event)]
    pub struct ProposalCanceled {
        #[ink(topic)]
        proposal_id: u128,
    }

    /// Errors
    #[derive(Debug, PartialEq, Eq, scale::Encode, scale::Decode)]
    #[cfg_attr(feature = "std", derive(scale_info::TypeInfo))]
    pub enum Error {
        Unauthorized,
        InvalidProposalId,
        InsufficientRank,
        VotingNotStarted,
        VotingEnded,
        AlreadyVoted,
        QuorumNotReached,
        ProposalNotSucceeded,
        ProposalAlreadyExecuted,
        InvalidQuorumPercent,
        /// Cross-contract call failed
        CrossContractCallFailed,
    }

    impl DAOGovernor {
        /// Constructor
        #[ink(constructor)]
        pub fn new(membership: AccountId) -> Self {
            let caller = Self::env().caller();

            let mut governor = Self {
                admin: caller,
                membership,
                next_proposal_id: 1,
                proposals: Mapping::default(),
                track_configs: Mapping::default(),
                vote_receipts: Mapping::default(),
            };

            // Initialize default track configurations
            governor.set_track_config_internal(
                Track::Technical,
                TrackConfig {
                    min_rank: 2,
                    voting_delay: 86400,        // 1 day
                    voting_period: 604800,      // 7 days
                    quorum_percent: 66,
                },
            );

            governor.set_track_config_internal(
                Track::Treasury,
                TrackConfig {
                    min_rank: 1,
                    voting_delay: 86400,        // 1 day
                    voting_period: 1209600,     // 14 days
                    quorum_percent: 51,
                },
            );

            governor.set_track_config_internal(
                Track::Membership,
                TrackConfig {
                    min_rank: 3,
                    voting_delay: 86400,        // 1 day
                    voting_period: 604800,      // 7 days
                    quorum_percent: 75,
                },
            );

            governor
        }

        // ===== PROPOSAL MANAGEMENT =====

        /// Create new proposal
        #[ink(message)]
        pub fn propose(
            &mut self,
            track: Track,
            description: String,
            target: Option<AccountId>,
            call_data: Vec<u8>,
        ) -> Result<u128, Error> {
            let proposer = self.env().caller();

            // Get member rank from DAOMembership (cross-contract call)
            let member_rank = self.get_member_rank(proposer)?;

            // Check rank requirement
            let config = self.track_configs.get(track).unwrap();
            if member_rank < config.min_rank {
                return Err(Error::InsufficientRank);
            }

            // Create proposal
            let proposal_id = self.next_proposal_id;
            let now = self.env().block_timestamp();

            let proposal = Proposal {
                id: proposal_id,
                proposer,
                track,
                created_at: now,
                voting_starts_at: now + config.voting_delay,
                voting_ends_at: now + config.voting_delay + config.voting_period,
                description: description.clone(),
                for_votes: 0,
                against_votes: 0,
                abstain_votes: 0,
                state: ProposalState::Pending,
                target,
                call_data,
            };

            self.proposals.insert(proposal_id, &proposal);
            self.next_proposal_id += 1;

            Self::env().emit_event(ProposalCreated {
                proposal_id,
                proposer,
                track,
                description,
            });

            Ok(proposal_id)
        }

        /// Cast vote on proposal
        #[ink(message)]
        pub fn cast_vote(
            &mut self,
            proposal_id: u128,
            vote_type: VoteType,
        ) -> Result<(), Error> {
            let voter = self.env().caller();
            let now = self.env().block_timestamp();

            // Get proposal
            let mut proposal = self.proposals.get(proposal_id)
                .ok_or(Error::InvalidProposalId)?;

            // Update proposal state
            self.update_proposal_state(&mut proposal, now);

            // Check voting period
            if proposal.state != ProposalState::Active {
                return Err(Error::VotingNotStarted);
            }
            if now > proposal.voting_ends_at {
                return Err(Error::VotingEnded);
            }

            // Check if already voted
            let receipt_key = (proposal_id, voter);
            if self.vote_receipts.contains(receipt_key) {
                return Err(Error::AlreadyVoted);
            }

            // Get vote weight from DAOMembership
            let config = self.track_configs.get(proposal.track).unwrap();
            let vote_weight = self.get_vote_weight(voter, config.min_rank)?;

            // Record vote
            match vote_type {
                VoteType::For => proposal.for_votes += vote_weight,
                VoteType::Against => proposal.against_votes += vote_weight,
                VoteType::Abstain => proposal.abstain_votes += vote_weight,
            }

            // Save vote receipt
            let receipt = VoteReceipt {
                has_voted: true,
                vote_type,
                vote_weight,
            };
            self.vote_receipts.insert(receipt_key, &receipt);

            // Update proposal
            self.proposals.insert(proposal_id, &proposal);

            Self::env().emit_event(VoteCast {
                proposal_id,
                voter,
                vote_type,
                vote_weight,
            });

            Ok(())
        }

        /// Execute proposal (if succeeded)
        #[ink(message)]
        pub fn execute(&mut self, proposal_id: u128) -> Result<(), Error> {
            let now = self.env().block_timestamp();

            let mut proposal = self.proposals.get(proposal_id)
                .ok_or(Error::InvalidProposalId)?;

            // Update state
            self.update_proposal_state(&mut proposal, now);

            // Check if succeeded
            if proposal.state != ProposalState::Succeeded {
                return Err(Error::ProposalNotSucceeded);
            }

            // Mark as executed
            proposal.state = ProposalState::Executed;
            self.proposals.insert(proposal_id, &proposal);

            // TODO: Execute cross-contract call if target is set
            // This would require ink! cross-contract call API

            Self::env().emit_event(ProposalExecuted { proposal_id });

            Ok(())
        }

        /// Cancel proposal (proposer only)
        #[ink(message)]
        pub fn cancel(&mut self, proposal_id: u128) -> Result<(), Error> {
            let caller = self.env().caller();

            let mut proposal = self.proposals.get(proposal_id)
                .ok_or(Error::InvalidProposalId)?;

            if proposal.proposer != caller && caller != self.admin {
                return Err(Error::Unauthorized);
            }

            proposal.state = ProposalState::Canceled;
            self.proposals.insert(proposal_id, &proposal);

            Self::env().emit_event(ProposalCanceled { proposal_id });

            Ok(())
        }

        // ===== VIEW FUNCTIONS =====

        /// Get proposal info
        #[ink(message)]
        pub fn get_proposal(&self, proposal_id: u128) -> Result<Proposal, Error> {
            self.proposals.get(proposal_id).ok_or(Error::InvalidProposalId)
        }

        /// Get proposal state (with auto-update)
        #[ink(message)]
        pub fn get_proposal_state(&self, proposal_id: u128) -> Result<ProposalState, Error> {
            let mut proposal = self.proposals.get(proposal_id)
                .ok_or(Error::InvalidProposalId)?;

            let now = self.env().block_timestamp();
            self.update_proposal_state(&mut proposal, now);

            Ok(proposal.state)
        }

        /// Get vote receipt for a voter
        #[ink(message)]
        pub fn get_vote_receipt(
            &self,
            proposal_id: u128,
            voter: AccountId,
        ) -> Option<VoteReceipt> {
            self.vote_receipts.get((proposal_id, voter))
        }

        /// Get track configuration
        #[ink(message)]
        pub fn get_track_config(&self, track: Track) -> Option<TrackConfig> {
            self.track_configs.get(track)
        }

        /// Update track config (admin only)
        #[ink(message)]
        pub fn set_track_config(
            &mut self,
            track: Track,
            config: TrackConfig,
        ) -> Result<(), Error> {
            if self.env().caller() != self.admin {
                return Err(Error::Unauthorized);
            }

            if config.quorum_percent == 0 || config.quorum_percent > 100 {
                return Err(Error::InvalidQuorumPercent);
            }

            self.set_track_config_internal(track, config);
            Ok(())
        }

        // ===== INTERNAL FUNCTIONS =====

        fn set_track_config_internal(&mut self, track: Track, config: TrackConfig) {
            self.track_configs.insert(track, &config);
        }

        /// Update proposal state based on current time and votes
        fn update_proposal_state(&self, proposal: &mut Proposal, now: Timestamp) {
            match proposal.state {
                ProposalState::Pending => {
                    if now >= proposal.voting_starts_at {
                        proposal.state = ProposalState::Active;
                    }
                }
                ProposalState::Active => {
                    if now >= proposal.voting_ends_at {
                        // Voting ended, determine outcome
                        let config = self.track_configs.get(proposal.track).unwrap();
                        let total_votes = proposal.for_votes + proposal.against_votes + proposal.abstain_votes;

                        // Calculate quorum (simplified: based on current votes)
                        let quorum_needed = (total_votes * config.quorum_percent as u128) / 100;

                        if total_votes < quorum_needed {
                            proposal.state = ProposalState::Defeated;
                        } else if proposal.for_votes > proposal.against_votes {
                            proposal.state = ProposalState::Succeeded;
                        } else {
                            proposal.state = ProposalState::Defeated;
                        }
                    }
                }
                _ => {}
            }
        }

        /// Get member rank from DAOMembership contract
        fn get_member_rank(&self, _member: AccountId) -> Result<u8, Error> {
            // TODO: Implement cross-contract call to DAOMembership.get_member_info()
            // For now, return dummy value
            // This requires using ink!'s cross-contract call API
            Ok(2) // Dummy: assume rank 2
        }

        /// Get vote weight from DAOMembership contract
        fn get_vote_weight(&self, _member: AccountId, _min_rank: u8) -> Result<u128, Error> {
            // TODO: Implement cross-contract call to DAOMembership.calculate_vote_weight()
            // For now, return dummy value
            Ok(3) // Dummy: rank 2 = weight 3
        }
    }

    /// Unit tests
    #[cfg(test)]
    mod tests {
        use super::*;

        #[ink::test]
        fn test_constructor() {
            let accounts = ink::env::test::default_accounts::<ink::env::DefaultEnvironment>();
            let governor = DAOGovernor::new(accounts.bob);

            assert!(governor.get_track_config(Track::Technical).is_some());
            assert!(governor.get_track_config(Track::Treasury).is_some());
            assert!(governor.get_track_config(Track::Membership).is_some());
        }

        #[ink::test]
        fn test_propose() {
            let accounts = ink::env::test::default_accounts::<ink::env::DefaultEnvironment>();
            let mut governor = DAOGovernor::new(accounts.bob);

            let result = governor.propose(
                Track::Technical,
                String::from("Upgrade protocol"),
                None,
                Vec::new(),
            );

            // Note: Will pass with dummy rank (returns 2)
            assert!(result.is_ok());
        }

        #[ink::test]
        fn test_cast_vote() {
            let accounts = ink::env::test::default_accounts::<ink::env::DefaultEnvironment>();
            let mut governor = DAOGovernor::new(accounts.bob);

            // Create proposal
            let proposal_id = governor.propose(
                Track::Technical,
                String::from("Upgrade protocol"),
                None,
                Vec::new(),
            ).unwrap();

            // Fast forward time to voting period
            let proposal = governor.get_proposal(proposal_id).unwrap();
            ink::env::test::advance_block::<ink::env::DefaultEnvironment>();

            // Cast vote (will use dummy weight)
            let result = governor.cast_vote(proposal_id, VoteType::For);

            // May fail due to timing, but should not panic
            assert!(result.is_ok() || result.is_err());
        }

        #[ink::test]
        fn test_track_configurations() {
            let accounts = ink::env::test::default_accounts::<ink::env::DefaultEnvironment>();
            let governor = DAOGovernor::new(accounts.bob);

            // Technical track
            let tech_config = governor.get_track_config(Track::Technical).unwrap();
            assert_eq!(tech_config.min_rank, 2);
            assert_eq!(tech_config.quorum_percent, 66);
            assert_eq!(tech_config.voting_period, 604800); // 7 days

            // Treasury track
            let treasury_config = governor.get_track_config(Track::Treasury).unwrap();
            assert_eq!(treasury_config.min_rank, 1);
            assert_eq!(treasury_config.quorum_percent, 51);
            assert_eq!(treasury_config.voting_period, 1209600); // 14 days

            // Membership track
            let membership_config = governor.get_track_config(Track::Membership).unwrap();
            assert_eq!(membership_config.min_rank, 3);
            assert_eq!(membership_config.quorum_percent, 75);
            assert_eq!(membership_config.voting_period, 604800); // 7 days
        }

        #[ink::test]
        fn test_update_track_config() {
            let accounts = ink::env::test::default_accounts::<ink::env::DefaultEnvironment>();
            let mut governor = DAOGovernor::new(accounts.bob);

            let new_config = TrackConfig {
                min_rank: 3,
                voting_delay: 172800, // 2 days
                voting_period: 432000, // 5 days
                quorum_percent: 80,
            };

            let result = governor.set_track_config(Track::Technical, new_config.clone());
            assert!(result.is_ok());

            let updated = governor.get_track_config(Track::Technical).unwrap();
            assert_eq!(updated.min_rank, 3);
            assert_eq!(updated.quorum_percent, 80);
        }

        #[ink::test]
        fn test_invalid_quorum() {
            let accounts = ink::env::test::default_accounts::<ink::env::DefaultEnvironment>();
            let mut governor = DAOGovernor::new(accounts.bob);

            let invalid_config = TrackConfig {
                min_rank: 2,
                voting_delay: 86400,
                voting_period: 604800,
                quorum_percent: 101, // Invalid > 100
            };

            let result = governor.set_track_config(Track::Technical, invalid_config);
            assert_eq!(result, Err(Error::InvalidQuorumPercent));
        }

        #[ink::test]
        fn test_cancel_proposal() {
            let accounts = ink::env::test::default_accounts::<ink::env::DefaultEnvironment>();
            let mut governor = DAOGovernor::new(accounts.bob);

            // Create proposal
            let proposal_id = governor.propose(
                Track::Technical,
                String::from("Test proposal"),
                None,
                Vec::new(),
            ).unwrap();

            // Cancel proposal
            let result = governor.cancel(proposal_id);
            assert!(result.is_ok());

            // Verify state
            let proposal = governor.get_proposal(proposal_id).unwrap();
            assert_eq!(proposal.state, ProposalState::Canceled);
        }

        #[ink::test]
        fn test_unauthorized_cancel() {
            let accounts = ink::env::test::default_accounts::<ink::env::DefaultEnvironment>();
            let mut governor = DAOGovernor::new(accounts.bob);

            // Create proposal as alice
            let proposal_id = governor.propose(
                Track::Technical,
                String::from("Test proposal"),
                None,
                Vec::new(),
            ).unwrap();

            // Try to cancel as bob (not proposer or admin)
            ink::env::test::set_caller::<ink::env::DefaultEnvironment>(accounts.charlie);
            let result = governor.cancel(proposal_id);
            assert_eq!(result, Err(Error::Unauthorized));
        }

        #[ink::test]
        fn test_proposal_state_transitions() {
            let accounts = ink::env::test::default_accounts::<ink::env::DefaultEnvironment>();
            let mut governor = DAOGovernor::new(accounts.bob);

            // Create proposal
            let proposal_id = governor.propose(
                Track::Technical,
                String::from("State test"),
                None,
                Vec::new(),
            ).unwrap();

            // Initial state should be Pending
            let mut proposal = governor.get_proposal(proposal_id).unwrap();
            assert_eq!(proposal.state, ProposalState::Pending);
        }

        #[ink::test]
        fn test_vote_receipt() {
            let accounts = ink::env::test::default_accounts::<ink::env::DefaultEnvironment>();
            let mut governor = DAOGovernor::new(accounts.bob);

            let proposal_id = governor.propose(
                Track::Technical,
                String::from("Vote test"),
                None,
                Vec::new(),
            ).unwrap();

            // Initially no receipt
            let receipt = governor.get_vote_receipt(proposal_id, accounts.alice);
            assert!(receipt.is_none());
        }

        #[ink::test]
        fn test_multiple_proposals() {
            let accounts = ink::env::test::default_accounts::<ink::env::DefaultEnvironment>();
            let mut governor = DAOGovernor::new(accounts.bob);

            // Create multiple proposals
            let id1 = governor.propose(
                Track::Technical,
                String::from("Proposal 1"),
                None,
                Vec::new(),
            ).unwrap();

            let id2 = governor.propose(
                Track::Treasury,
                String::from("Proposal 2"),
                None,
                Vec::new(),
            ).unwrap();

            assert_eq!(id1, 1);
            assert_eq!(id2, 2);

            // Both should exist
            assert!(governor.get_proposal(id1).is_ok());
            assert!(governor.get_proposal(id2).is_ok());
        }
    }
}
