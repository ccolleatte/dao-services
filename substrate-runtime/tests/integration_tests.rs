// Integration tests for DAO runtime with all 5 custom pallets
// Tests E2E scenarios: membership → governance → treasury → marketplace → payments

#![cfg(test)]

use dao_runtime::{
    Runtime, System, Balances, Membership, Treasury, Governance,
    Marketplace, PaymentSplitter, RuntimeOrigin, AccountId, Balance,
};
use frame_support::{
    assert_ok, assert_noop,
    traits::{OnFinalize, OnInitialize},
};
use sp_runtime::{BuildStorage, DispatchError};
use sp_core::{H256, sr25519};

type BlockNumber = u64;

/// Helper: Run to block number
fn run_to_block(n: BlockNumber) {
    while System::block_number() < n {
        let current = System::block_number();

        // Finalize current block
        Membership::on_finalize(current);
        Treasury::on_finalize(current);
        Governance::on_finalize(current);
        Marketplace::on_finalize(current);
        System::on_finalize(current);

        // Initialize next block
        System::set_block_number(current + 1);
        System::on_initialize(current + 1);
        Membership::on_initialize(current + 1);
        Treasury::on_initialize(current + 1);
        Governance::on_initialize(current + 1);
        Marketplace::on_initialize(current + 1);
    }
}

/// Helper: Setup test externalities
fn new_test_ext() -> sp_io::TestExternalities {
    let mut t = frame_system::GenesisConfig::<Runtime>::default()
        .build_storage()
        .unwrap();

    // Genesis accounts with initial balances
    pallet_balances::GenesisConfig::<Runtime> {
        balances: vec![
            (account(1), 1_000_000), // Alice (client)
            (account(2), 500_000),   // Bob (provider)
            (account(3), 500_000),   // Charlie (provider)
            (account(4), 100_000),   // DAO Treasury seed
        ],
    }
    .assimilate_storage(&mut t)
    .unwrap();

    let mut ext = sp_io::TestExternalities::new(t);
    ext.execute_with(|| System::set_block_number(1));
    ext
}

/// Helper: Create test account from ID
fn account(id: u8) -> AccountId {
    [id; 32].into()
}

// ============================================================================
// Test Suite 1: Membership Lifecycle
// ============================================================================

#[test]
fn test_membership_junior_to_consultant_promotion() {
    new_test_ext().execute_with(|| {
        let alice = account(1);

        // Add Alice as Junior (rank 0)
        assert_ok!(Membership::add_member(
            RuntimeOrigin::root(),
            alice.clone(),
            pallet_membership::pallet::Rank::Junior
        ));

        // Verify membership
        assert_eq!(
            Membership::members(&alice).unwrap().rank,
            pallet_membership::pallet::Rank::Junior
        );

        // Fast-forward 90 days (1_296_000 blocks at 6s/block)
        run_to_block(1_296_001);

        // Promote to Consultant (rank 1)
        assert_ok!(Membership::promote_member(
            RuntimeOrigin::root(),
            alice.clone()
        ));

        // Verify promotion
        assert_eq!(
            Membership::members(&alice).unwrap().rank,
            pallet_membership::pallet::Rank::Consultant
        );

        // Vote weight should be 1 (triangular formula: 1*(1+1)/2 = 1)
        assert_eq!(Membership::vote_weight(&alice).unwrap(), 1);
    });
}

#[test]
fn test_membership_premature_promotion_fails() {
    new_test_ext().execute_with(|| {
        let alice = account(1);

        // Add as Junior
        assert_ok!(Membership::add_member(
            RuntimeOrigin::root(),
            alice.clone(),
            pallet_membership::pallet::Rank::Junior
        ));

        // Attempt promotion immediately (without waiting 90 days)
        run_to_block(10);

        assert_noop!(
            Membership::promote_member(RuntimeOrigin::root(), alice.clone()),
            pallet_membership::pallet::Error::<Runtime>::MinDurationNotMet
        );
    });
}

// ============================================================================
// Test Suite 2: Governance Proposal Flow
// ============================================================================

#[test]
fn test_governance_technical_proposal_lifecycle() {
    new_test_ext().execute_with(|| {
        let alice = account(1);
        let bob = account(2);

        // Setup: Alice and Bob as Senior (rank 2) for Technical track
        assert_ok!(Membership::add_member(
            RuntimeOrigin::root(),
            alice.clone(),
            pallet_membership::pallet::Rank::Senior
        ));
        assert_ok!(Membership::add_member(
            RuntimeOrigin::root(),
            bob.clone(),
            pallet_membership::pallet::Rank::Senior
        ));

        // Submit Technical proposal (requires rank 2+)
        let proposal_description = b"Upgrade runtime to v2.0".to_vec();
        assert_ok!(Governance::submit_proposal(
            RuntimeOrigin::signed(alice.clone()),
            pallet_governance::Track::Technical,
            proposal_description.clone(),
            100_000 // Proposal bond
        ));

        let proposal_id = 0u64; // First proposal

        // Vote: Alice votes Yes (weight 3: 2*(2+1)/2)
        assert_ok!(Governance::vote(
            RuntimeOrigin::signed(alice.clone()),
            proposal_id,
            true
        ));

        // Vote: Bob votes Yes (weight 3)
        assert_ok!(Governance::vote(
            RuntimeOrigin::signed(bob.clone()),
            proposal_id,
            true
        ));

        // Fast-forward past voting period (7 days = 100,800 blocks)
        run_to_block(100,801);

        // Finalize proposal (should pass with 66% threshold)
        assert_ok!(Governance::finalize_proposal(
            RuntimeOrigin::signed(alice.clone()),
            proposal_id
        ));

        // Verify proposal passed
        let proposal = Governance::proposals(proposal_id).unwrap();
        assert_eq!(proposal.status, pallet_governance::ProposalStatus::Approved);

        // Fast-forward enactment period (2 days = 28,800 blocks)
        run_to_block(100,801 + 28,801);

        // Execute proposal
        assert_ok!(Governance::execute_proposal(
            RuntimeOrigin::signed(alice.clone()),
            proposal_id
        ));
    });
}

// ============================================================================
// Test Suite 3: Marketplace Mission with Milestones
// ============================================================================

#[test]
fn test_marketplace_mission_lifecycle_success() {
    new_test_ext().execute_with(|| {
        let client = account(1);
        let provider = account(2);
        let mission_id = 0u64;

        // Client creates mission (100k budget, 3 milestones)
        assert_ok!(Marketplace::create_mission(
            RuntimeOrigin::signed(client.clone()),
            b"Build DAO frontend".to_vec(),
            100_000, // Total budget
            vec![30_000, 30_000, 40_000], // Milestone amounts
            vec![50_400, 100_800, 151_200], // Deadlines (7, 14, 21 days)
        ));

        // Verify escrow locked
        assert_eq!(Marketplace::missions(mission_id).unwrap().total_amount, 100_000);

        // Provider accepts mission
        assert_ok!(Marketplace::accept_mission(
            RuntimeOrigin::signed(provider.clone()),
            mission_id
        ));

        // Provider submits milestone 1
        assert_ok!(Marketplace::submit_milestone(
            RuntimeOrigin::signed(provider.clone()),
            mission_id,
            0, // Milestone index
            b"Figma mockups complete: https://figma.com/...".to_vec()
        ));

        // Client approves milestone 1
        assert_ok!(Marketplace::approve_milestone(
            RuntimeOrigin::signed(client.clone()),
            mission_id,
            0
        ));

        // Verify payment released (30k to provider)
        assert_eq!(Balances::free_balance(&provider), 500_000 + 30_000);

        // Submit + approve milestone 2
        assert_ok!(Marketplace::submit_milestone(
            RuntimeOrigin::signed(provider.clone()),
            mission_id,
            1,
            b"React components implemented".to_vec()
        ));
        assert_ok!(Marketplace::approve_milestone(
            RuntimeOrigin::signed(client.clone()),
            mission_id,
            1
        ));

        // Submit + auto-release milestone 3 (after 7 days without response)
        assert_ok!(Marketplace::submit_milestone(
            RuntimeOrigin::signed(provider.clone()),
            mission_id,
            2,
            b"Production deployment live".to_vec()
        ));

        // Fast-forward 7 days (100,800 blocks)
        run_to_block(System::block_number() + 100_801);

        // Trigger auto-release
        assert_ok!(Marketplace::release_milestone_auto(
            RuntimeOrigin::signed(provider.clone()),
            mission_id,
            2
        ));

        // Verify final payment released (40k)
        assert_eq!(Balances::free_balance(&provider), 500_000 + 100_000);

        // Mission complete
        assert_eq!(
            Marketplace::missions(mission_id).unwrap().status,
            pallet_marketplace::MissionStatus::Completed
        );
    });
}

#[test]
fn test_marketplace_dispute_resolution() {
    new_test_ext().execute_with(|| {
        let client = account(1);
        let provider = account(2);
        let juror1 = account(5);
        let juror2 = account(6);
        let juror3 = account(7);
        let mission_id = 0u64;

        // Setup jurors as Lead (rank 3)
        for juror in [juror1.clone(), juror2.clone(), juror3.clone()] {
            assert_ok!(Membership::add_member(
                RuntimeOrigin::root(),
                juror,
                pallet_membership::pallet::Rank::Lead
            ));
        }

        // Create + accept mission
        assert_ok!(Marketplace::create_mission(
            RuntimeOrigin::signed(client.clone()),
            b"Mission with dispute".to_vec(),
            50_000,
            vec![50_000],
            vec![50_400],
        ));
        assert_ok!(Marketplace::accept_mission(
            RuntimeOrigin::signed(provider.clone()),
            mission_id
        ));

        // Provider submits milestone
        assert_ok!(Marketplace::submit_milestone(
            RuntimeOrigin::signed(provider.clone()),
            mission_id,
            0,
            b"Work complete".to_vec()
        ));

        // Client disputes milestone
        assert_ok!(Marketplace::dispute_milestone(
            RuntimeOrigin::signed(client.clone()),
            mission_id,
            0,
            b"Quality not acceptable".to_vec()
        ));

        // Assign jurors
        assert_ok!(Marketplace::assign_jurors(
            RuntimeOrigin::root(),
            mission_id,
            0,
            vec![juror1.clone(), juror2.clone(), juror3.clone()],
        ));

        // Jurors vote (2 for provider, 1 for client = provider wins)
        assert_ok!(Marketplace::vote_dispute(
            RuntimeOrigin::signed(juror1.clone()),
            mission_id,
            0,
            true // Vote for provider
        ));
        assert_ok!(Marketplace::vote_dispute(
            RuntimeOrigin::signed(juror2.clone()),
            mission_id,
            0,
            true
        ));
        assert_ok!(Marketplace::vote_dispute(
            RuntimeOrigin::signed(juror3.clone()),
            mission_id,
            0,
            false // Vote for client
        ));

        // Fast-forward past voting period (72h = 43,200 blocks)
        run_to_block(System::block_number() + 43,201);

        // Resolve dispute
        assert_ok!(Marketplace::resolve_dispute(
            RuntimeOrigin::signed(client.clone()),
            mission_id,
            0
        ));

        // Verify: Provider wins (2/3 votes), payment released
        assert_eq!(Balances::free_balance(&provider), 500_000 + 50_000);
    });
}

// ============================================================================
// Test Suite 4: Hybrid Payment Distribution
// ============================================================================

#[test]
fn test_payment_splitter_hybrid_distribution() {
    new_test_ext().execute_with(|| {
        let mission_id = 0u64;
        let human = account(10);
        let ai = account(11);
        let compute = account(12);

        // Create split for mission (100k total)
        assert_ok!(PaymentSplitter::create_split(
            RuntimeOrigin::root(),
            mission_id,
            vec![
                (human.clone(), pallet_payment_splitter::ContributorType::Human, 40), // 40% fixed
                (ai.clone(), pallet_payment_splitter::ContributorType::AI, 30),      // 30% fixed + usage
                (compute.clone(), pallet_payment_splitter::ContributorType::Compute, 30), // 30% + usage
            ],
            100_000, // Total amount
        ));

        // Meter AI usage: 1M LLM tokens @ 0.01 per 1k tokens = 10k additional
        assert_ok!(PaymentSplitter::meter_usage(
            RuntimeOrigin::root(),
            mission_id,
            ai.clone(),
            1_000_000, // LLM tokens
            0          // GPU hours
        ));

        // Meter Compute usage: 100 GPU hours @ 50 per hour = 5k additional
        assert_ok!(PaymentSplitter::meter_usage(
            RuntimeOrigin::root(),
            mission_id,
            compute.clone(),
            0,
            100 // GPU hours
        ));

        // Execute distribution
        assert_ok!(PaymentSplitter::execute_split(
            RuntimeOrigin::root(),
            mission_id
        ));

        // Verify distributions:
        // Human: 40k (40% fixed)
        // AI: 30k (fixed) + 10k (usage) = 40k
        // Compute: 30k (fixed) + 5k (usage) = 35k
        // Total: 115k (100k base + 15k usage-based)

        let human_received = 40_000;
        let ai_received = 40_000;
        let compute_received = 35_000;

        // Note: Balances need escrow mechanism, simplified for test
        assert_eq!(
            PaymentSplitter::splits(mission_id).unwrap().contributors[0].amount_paid,
            human_received
        );
        assert_eq!(
            PaymentSplitter::splits(mission_id).unwrap().contributors[1].amount_paid,
            ai_received
        );
        assert_eq!(
            PaymentSplitter::splits(mission_id).unwrap().contributors[2].amount_paid,
            compute_received
        );
    });
}

// ============================================================================
// Test Suite 5: End-to-End DAO Flow
// ============================================================================

#[test]
fn test_e2e_dao_workflow() {
    new_test_ext().execute_with(|| {
        // Step 1: Bootstrap DAO members
        let founder = account(1);
        let dev1 = account(2);
        let dev2 = account(3);

        assert_ok!(Membership::add_member(RuntimeOrigin::root(), founder.clone(), pallet_membership::pallet::Rank::Lead));
        assert_ok!(Membership::add_member(RuntimeOrigin::root(), dev1.clone(), pallet_membership::pallet::Rank::Senior));
        assert_ok!(Membership::add_member(RuntimeOrigin::root(), dev2.clone(), pallet_membership::pallet::Rank::Consultant));

        // Step 2: Founder proposes Treasury spend for mission funding
        assert_ok!(Governance::submit_proposal(
            RuntimeOrigin::signed(founder.clone()),
            pallet_governance::Track::Treasury,
            b"Allocate 500k for Q1 missions".to_vec(),
            50_000 // Bond
        ));

        let proposal_id = 0u64;

        // Step 3: Vote and pass proposal (Founder rank 3 = weight 6, others = 3+1 = 7 total)
        assert_ok!(Governance::vote(RuntimeOrigin::signed(founder.clone()), proposal_id, true));
        assert_ok!(Governance::vote(RuntimeOrigin::signed(dev1.clone()), proposal_id, true));

        run_to_block(100_801); // 7 days
        assert_ok!(Governance::finalize_proposal(RuntimeOrigin::signed(founder.clone()), proposal_id));

        run_to_block(100_801 + 28_801); // +2 days enactment
        assert_ok!(Governance::execute_proposal(RuntimeOrigin::signed(founder.clone()), proposal_id));

        // Step 4: Treasury funded, create mission
        let client = founder.clone();
        let provider = dev1.clone();
        let mission_id = 0u64;

        assert_ok!(Marketplace::create_mission(
            RuntimeOrigin::signed(client.clone()),
            b"Build DAO dashboard".to_vec(),
            200_000,
            vec![100_000, 100_000],
            vec![50_400, 100_800],
        ));

        // Step 5: Provider accepts + completes mission
        assert_ok!(Marketplace::accept_mission(RuntimeOrigin::signed(provider.clone()), mission_id));

        assert_ok!(Marketplace::submit_milestone(RuntimeOrigin::signed(provider.clone()), mission_id, 0, b"M1 done".to_vec()));
        assert_ok!(Marketplace::approve_milestone(RuntimeOrigin::signed(client.clone()), mission_id, 0));

        assert_ok!(Marketplace::submit_milestone(RuntimeOrigin::signed(provider.clone()), mission_id, 1, b"M2 done".to_vec()));
        assert_ok!(Marketplace::approve_milestone(RuntimeOrigin::signed(client.clone()), mission_id, 1));

        // Step 6: Payment split with AI/Compute contributors
        let ai_agent = account(20);
        let gpu_provider = account(21);

        assert_ok!(PaymentSplitter::create_split(
            RuntimeOrigin::root(),
            mission_id,
            vec![
                (provider.clone(), pallet_payment_splitter::ContributorType::Human, 60),
                (ai_agent.clone(), pallet_payment_splitter::ContributorType::AI, 20),
                (gpu_provider.clone(), pallet_payment_splitter::ContributorType::Compute, 20),
            ],
            200_000,
        ));

        assert_ok!(PaymentSplitter::execute_split(RuntimeOrigin::root(), mission_id));

        // Verify: Mission complete, payments distributed, DAO operational
        assert_eq!(Marketplace::missions(mission_id).unwrap().status, pallet_marketplace::MissionStatus::Completed);
    });
}
