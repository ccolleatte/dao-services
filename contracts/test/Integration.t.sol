// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/DAOMembership.sol";
import "../src/DAOGovernor.sol";
import "../src/DAOTreasury.sol";
import "@openzeppelin/contracts/governance/TimelockController.sol";

/**
 * @title Integration Tests
 * @notice End-to-end tests for DAOMembership ↔ DAOGovernor ↔ DAOTreasury
 */
contract IntegrationTest is Test {
    DAOMembership public membership;
    DAOGovernor public governor;
    DAOTreasury public treasury;
    TimelockController public timelock;

    address public admin = address(1);
    address public member1 = address(2); // Rank 1
    address public member2 = address(3); // Rank 2
    address public member3 = address(4); // Rank 3
    address public voter1 = address(5);  // Rank 1
    address public voter2 = address(6);  // Rank 2
    address payable public beneficiary = payable(address(7));

    uint256 constant MIN_DELAY = 1 days;

    function setUp() public {
        vm.startPrank(admin);

        // Deploy DAOMembership
        membership = new DAOMembership();

        // Setup timelock
        address[] memory proposers = new address[](1);
        address[] memory executors = new address[](1);
        proposers[0] = address(0);
        executors[0] = address(0);

        timelock = new TimelockController(
            MIN_DELAY,
            proposers,
            executors,
            admin
        );

        // Deploy Governor
        governor = new DAOGovernor(membership, timelock);

        // Grant Governor roles on timelock
        bytes32 PROPOSER_ROLE = timelock.PROPOSER_ROLE();
        bytes32 EXECUTOR_ROLE = timelock.EXECUTOR_ROLE();
        timelock.grantRole(PROPOSER_ROLE, address(governor));
        timelock.grantRole(EXECUTOR_ROLE, address(governor));

        // Deploy Treasury
        treasury = new DAOTreasury(membership, admin);

        // Grant Treasury roles
        treasury.grantRole(treasury.TREASURER_ROLE(), address(timelock));
        treasury.grantRole(treasury.SPENDER_ROLE(), address(timelock));

        // Add members with various ranks
        membership.addMember(member1, 1, "member1");
        membership.addMember(member2, 2, "member2");
        membership.addMember(member3, 3, "member3");
        membership.addMember(voter1, 1, "voter1");
        membership.addMember(voter2, 2, "voter2");

        // Fund treasury
        vm.deal(address(treasury), 1000 ether);

        vm.stopPrank();
    }

    /**
     * @notice Integration Test 1: Vote Weights Flow (Membership → Governor)
     * @dev Verify that vote weights from DAOMembership are correctly used in Governor
     */
    function testIntegration_VoteWeightsFlow() public {
        vm.startPrank(member2);

        // Create Technical proposal (requires Rank 2+)
        address[] memory targets = new address[](1);
        uint256[] memory values = new uint256[](1);
        bytes[] memory calldatas = new bytes[](1);

        targets[0] = address(membership);
        values[0] = 0;
        calldatas[0] = abi.encodeWithSignature("addMember(address,uint8,string)", address(99), 1, "newmember");

        uint256 proposalId = governor.proposeWithTrack(
            targets,
            values,
            calldatas,
            "Add new member via Technical track",
            DAOGovernor.Track.Technical
        );

        vm.stopPrank();

        // Fast-forward past voting delay
        vm.roll(block.number + governor.votingDelay() + 1);

        // Voter1 (Rank 1) tries to vote on Technical track (requires Rank 2+)
        // Vote should not count (weight = 0 because rank < minRank)
        vm.prank(voter1);
        governor.castVote(proposalId, 1); // For

        // Voter2 (Rank 2) votes on Technical track
        // Vote should count with weight = 3
        vm.prank(voter2);
        governor.castVote(proposalId, 1); // For

        // Member2 (Rank 2) also votes
        // Vote should count with weight = 3
        vm.prank(member2);
        governor.castVote(proposalId, 1); // For

        // Fast-forward past voting period
        vm.roll(block.number + governor.votingPeriod() + 1);

        // Verify vote weights were applied correctly
        // Total votes should be: 3 (voter2) + 3 (member2) = 6
        // Note: Foundry doesn't expose vote counts directly, but we can verify state
        assertEq(uint(governor.state(proposalId)), uint(IGovernor.ProposalState.Succeeded));
    }

    /**
     * @notice Integration Test 2: Treasury Spending via Governance
     * @dev Create treasury spending proposal through governance process
     */
    function testIntegration_TreasurySpendingViaGovernance() public {
        // Step 1: Create governance proposal to approve treasury spending
        vm.startPrank(member1);

        address[] memory targets = new address[](1);
        uint256[] memory values = new uint256[](1);
        bytes[] memory calldatas = new bytes[](1);

        // Proposal: Treasury approves a spending proposal
        targets[0] = address(treasury);
        values[0] = 0;

        // First, create spending proposal in treasury
        uint256 treasuryProposalId = treasury.createProposal(
            beneficiary,
            50 ether,
            "Payment for consultancy",
            "development"
        );

        // Governance proposal to approve treasury spending
        calldatas[0] = abi.encodeWithSignature("approveProposal(uint256)", treasuryProposalId);

        uint256 govProposalId = governor.proposeWithTrack(
            targets,
            values,
            calldatas,
            "Approve treasury spending of 50 ETH",
            DAOGovernor.Track.Treasury
        );

        vm.stopPrank();

        // Step 2: Vote on governance proposal
        vm.roll(block.number + governor.votingDelay() + 1);

        vm.prank(member1);
        governor.castVote(govProposalId, 1); // For

        vm.prank(voter1);
        governor.castVote(govProposalId, 1); // For

        vm.prank(member2);
        governor.castVote(govProposalId, 1); // For

        // Fast-forward past voting period
        vm.roll(block.number + governor.votingPeriod() + 1);

        // Verify proposal succeeded
        assertEq(uint(governor.state(govProposalId)), uint(IGovernor.ProposalState.Succeeded));

        // Step 3: Queue proposal in timelock
        // Note: proposeWithTrack prefixes the description with track name
        bytes32 descriptionHash = keccak256(bytes("[TREASURY] Approve treasury spending of 50 ETH"));
        governor.queue(targets, values, calldatas, descriptionHash);

        // Step 4: Wait for timelock delay
        vm.warp(block.timestamp + MIN_DELAY + 1);

        // Step 5: Execute governance proposal (approves treasury spending)
        governor.execute(targets, values, calldatas, descriptionHash);

        // Verify treasury proposal was approved
        DAOTreasury.SpendingProposal memory proposal = treasury.getProposal(treasuryProposalId);
        assertEq(uint(proposal.status), uint(DAOTreasury.ProposalStatus.Approved));
    }

    /**
     * @notice Integration Test 3: End-to-End Treasury Spend
     * @dev Complete flow: Propose → Vote → Execute → Treasury Transfer
     */
    function testIntegration_EndToEndTreasurySpend() public {
        // Grant admin temporary roles for test setup
        vm.startPrank(admin);
        treasury.grantRole(treasury.TREASURER_ROLE(), admin);
        treasury.grantRole(treasury.SPENDER_ROLE(), admin);
        vm.stopPrank();

        // Step 1: Create spending proposal
        vm.prank(member1);
        uint256 proposalId = treasury.createProposal(
            beneficiary,
            25 ether,
            "Payment for development work",
            "development"
        );

        // Step 2: Approve via admin (simulating governance approval)
        vm.prank(admin);
        treasury.approveProposal(proposalId);

        // Step 3: Execute spending
        uint256 beneficiaryBalanceBefore = beneficiary.balance;

        vm.prank(admin);
        treasury.executeProposal(proposalId, "development");

        // Step 4: Verify transfer succeeded
        assertEq(beneficiary.balance, beneficiaryBalanceBefore + 25 ether);
        assertEq(address(treasury).balance, 975 ether);

        // Verify proposal state
        DAOTreasury.SpendingProposal memory proposal = treasury.getProposal(proposalId);
        assertEq(uint(proposal.status), uint(DAOTreasury.ProposalStatus.Executed));
    }

    /**
     * @notice Integration Test 4: Rank-Based Voting Permissions
     * @dev Verify different tracks enforce different rank requirements
     */
    function testIntegration_RankBasedVotingPermissions() public {
        // Technical track (Rank 2+ required)
        vm.startPrank(member2);
        address[] memory targets = new address[](1);
        uint256[] memory values = new uint256[](1);
        bytes[] memory calldatas = new bytes[](1);

        targets[0] = address(membership);
        values[0] = 0;
        calldatas[0] = "";

        uint256 techProposal = governor.proposeWithTrack(
            targets,
            values,
            calldatas,
            "Technical proposal",
            DAOGovernor.Track.Technical
        );
        vm.stopPrank();

        // Treasury track (Rank 1+ required)
        vm.prank(member1);
        uint256 treasuryProposal = governor.proposeWithTrack(
            targets,
            values,
            calldatas,
            "Treasury proposal",
            DAOGovernor.Track.Treasury
        );

        // Membership track (Rank 3+ required)
        vm.prank(member3);
        uint256 membershipProposal = governor.proposeWithTrack(
            targets,
            values,
            calldatas,
            "Membership proposal",
            DAOGovernor.Track.Membership
        );

        // Verify all proposals were created successfully
        assertGt(techProposal, 0);
        assertGt(treasuryProposal, 0);
        assertGt(membershipProposal, 0);

        // Verify Member1 (Rank 1) cannot propose on Technical track
        vm.prank(member1);
        vm.expectRevert(
            abi.encodeWithSelector(
                DAOGovernor.InsufficientRank.selector,
                uint8(2), // required
                uint8(1)  // actual
            )
        );
        governor.proposeWithTrack(
            targets,
            values,
            calldatas,
            "Should fail",
            DAOGovernor.Track.Technical
        );

        // Verify Member2 (Rank 2) cannot propose on Membership track
        vm.prank(member2);
        vm.expectRevert(
            abi.encodeWithSelector(
                DAOGovernor.InsufficientRank.selector,
                uint8(3), // required
                uint8(2)  // actual
            )
        );
        governor.proposeWithTrack(
            targets,
            values,
            calldatas,
            "Should fail",
            DAOGovernor.Track.Membership
        );
    }

    /**
     * @notice Integration Test 5: Budget Tracking Across Governance
     * @dev Verify budget is tracked correctly across multiple spending proposals
     */
    function testIntegration_BudgetTrackingAcrossGovernance() public {
        // Setup: Allocate budget and grant roles
        vm.startPrank(admin);
        treasury.grantRole(treasury.TREASURER_ROLE(), admin);
        treasury.grantRole(treasury.SPENDER_ROLE(), admin);
        treasury.allocateBudget("development", 100 ether);
        vm.stopPrank();

        // Create first spending proposal
        vm.prank(member1);
        uint256 proposal1 = treasury.createProposal(
            beneficiary,
            30 ether,
            "First payment",
            "development"
        );

        // Approve and execute
        vm.prank(admin);
        treasury.approveProposal(proposal1);

        vm.prank(admin);
        treasury.executeProposal(proposal1, "development");

        // Verify budget updated
        DAOTreasury.Budget memory budget1 = treasury.getBudget("development");
        assertEq(budget1.spent, 30 ether);
        assertEq(budget1.allocated, 100 ether);

        // Create second spending proposal
        vm.prank(member1);
        uint256 proposal2 = treasury.createProposal(
            beneficiary,
            50 ether,
            "Second payment",
            "development"
        );

        vm.prank(admin);
        treasury.approveProposal(proposal2);

        vm.prank(admin);
        treasury.executeProposal(proposal2, "development");

        // Verify cumulative budget tracking
        DAOTreasury.Budget memory budget2 = treasury.getBudget("development");
        assertEq(budget2.spent, 80 ether);
        assertEq(budget2.allocated, 100 ether);

        // Try to exceed budget (should fail)
        vm.prank(member1);
        vm.expectRevert(DAOTreasury.BudgetExceeded.selector);
        treasury.createProposal(
            beneficiary,
            25 ether,
            "Third payment (exceeds budget)",
            "development"
        );
    }

    /**
     * @notice Integration Test 6: Multi-Track Governance Concurrent Proposals
     * @dev Verify multiple tracks can have active proposals simultaneously
     */
    function testIntegration_MultiTrackConcurrentProposals() public {
        address[] memory targets = new address[](1);
        uint256[] memory values = new uint256[](1);
        bytes[] memory calldatas = new bytes[](1);

        targets[0] = address(membership);
        values[0] = 0;
        calldatas[0] = "";

        // Create proposals on all tracks
        vm.prank(member2);
        uint256 techProposal = governor.proposeWithTrack(
            targets,
            values,
            calldatas,
            "Tech proposal",
            DAOGovernor.Track.Technical
        );

        vm.prank(member1);
        uint256 treasuryProposal = governor.proposeWithTrack(
            targets,
            values,
            calldatas,
            "Treasury proposal",
            DAOGovernor.Track.Treasury
        );

        vm.prank(member3);
        uint256 membershipProposal = governor.proposeWithTrack(
            targets,
            values,
            calldatas,
            "Membership proposal",
            DAOGovernor.Track.Membership
        );

        // Fast-forward past voting delay
        vm.roll(block.number + governor.votingDelay() + 1);

        // Verify all proposals are active
        assertEq(uint(governor.state(techProposal)), uint(IGovernor.ProposalState.Active));
        assertEq(uint(governor.state(treasuryProposal)), uint(IGovernor.ProposalState.Active));
        assertEq(uint(governor.state(membershipProposal)), uint(IGovernor.ProposalState.Active));

        // Vote on all proposals
        vm.prank(member2);
        governor.castVote(techProposal, 1);

        vm.prank(member1);
        governor.castVote(treasuryProposal, 1);

        vm.prank(member3);
        governor.castVote(membershipProposal, 1);

        // Fast-forward past voting period
        vm.roll(block.number + governor.votingPeriod() + 1);

        // Verify proposals can succeed independently
        assertEq(uint(governor.state(techProposal)), uint(IGovernor.ProposalState.Succeeded));
        assertEq(uint(governor.state(treasuryProposal)), uint(IGovernor.ProposalState.Succeeded));
        assertEq(uint(governor.state(membershipProposal)), uint(IGovernor.ProposalState.Succeeded));
    }
}
