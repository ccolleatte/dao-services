// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/DisputeResolution.sol";
import "../src/MilestoneEscrow.sol";

/**
 * @title DisputeResolutionTest
 * @notice TDD RED phase - Tests written BEFORE implementation
 * @dev Phase 2 Extension: Dispute arbitration system
 */
contract DisputeResolutionTest is Test {
    DisputeResolution public disputeResolution;
    MockMilestoneEscrow public escrow;
    MockMembershipContract public membership;

    address consultant = makeAddr("consultant");
    address client = makeAddr("client");
    address arbiter1 = makeAddr("arbiter1");
    address arbiter2 = makeAddr("arbiter2");
    address arbiter3 = makeAddr("arbiter3");
    address nonArbiter = makeAddr("nonArbiter");

    uint256 missionId = 1;
    uint256 milestoneIndex = 0;
    uint256 milestoneAmount = 300 ether;

    // Events
    event DisputeInitiated(
        uint256 indexed disputeId,
        uint256 indexed missionId,
        uint256 milestoneIndex,
        address indexed initiator
    );
    event VoteCast(uint256 indexed disputeId, address indexed arbiter, bool acceptDeliverable);
    event DisputeResolved(
        uint256 indexed disputeId,
        bool consultantWon,
        uint256 votesAccept,
        uint256 votesReject
    );
    event DisputeCancelled(uint256 indexed disputeId);

    function setUp() public {
        // Deploy mock contracts
        membership = new MockMembershipContract();
        escrow = new MockMilestoneEscrow();

        // Deploy DisputeResolution
        disputeResolution = new DisputeResolution(
            address(escrow),
            address(membership)
        );

        // Setup mock membership ranks (arbiter eligibility = rank ≥3)
        membership.setRank(arbiter1, 3);
        membership.setRank(arbiter2, 4);
        membership.setRank(arbiter3, 3);
        membership.setRank(nonArbiter, 2); // Not eligible
        membership.setRank(consultant, 3);

        // Setup mock mission
        escrow.setMissionClient(missionId, client);
        escrow.setMissionConsultant(missionId, consultant);
        escrow.setMilestoneStatus(missionId, milestoneIndex, MilestoneEscrow.MilestoneStatus.Rejected);
        escrow.setMilestoneAmount(missionId, milestoneIndex, milestoneAmount);

        // Register eligible arbiters
        address[] memory arbiters = new address[](3);
        arbiters[0] = arbiter1;
        arbiters[1] = arbiter2;
        arbiters[2] = arbiter3;
        disputeResolution.registerEligibleArbiters(arbiters);
    }

    /*//////////////////////////////////////////////////////////////
                        INITIATE DISPUTE TESTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Test: Consultant can initiate dispute after milestone rejected
    function test_InitiateDispute_Success() public {
        string memory reason = "I met all acceptance criteria";

        // Expect event
        vm.expectEmit(true, true, true, true);
        emit DisputeInitiated(0, missionId, milestoneIndex, consultant);

        // Consultant initiate dispute
        vm.prank(consultant);
        uint256 disputeId = disputeResolution.initiateDispute(missionId, milestoneIndex, reason);

        // Verify dispute created
        DisputeResolution.Dispute memory dispute = disputeResolution.getDispute(disputeId);
        assertEq(dispute.missionId, missionId);
        assertEq(dispute.milestoneIndex, milestoneIndex);
        assertEq(dispute.initiator, consultant);
        assertEq(dispute.reason, reason);
        assertEq(uint(dispute.status), uint(DisputeResolution.DisputeStatus.Open));
        assertEq(dispute.createdAt, block.timestamp);

        // Verify 3 arbiters selected (non-zero addresses)
        assertTrue(dispute.arbiters[0] != address(0));
        assertTrue(dispute.arbiters[1] != address(0));
        assertTrue(dispute.arbiters[2] != address(0));
    }

    /// @notice Test: Non-consultant cannot initiate dispute
    function test_InitiateDispute_RevertIfNotConsultant() public {
        vm.expectRevert(DisputeResolution.NotSelectedConsultant.selector);
        vm.prank(client);
        disputeResolution.initiateDispute(missionId, milestoneIndex, "reason");
    }

    /// @notice Test: Cannot initiate dispute if milestone not rejected
    function test_InitiateDispute_RevertIfNotRejected() public {
        escrow.setMilestoneStatus(missionId, milestoneIndex, MilestoneEscrow.MilestoneStatus.Pending);

        vm.expectRevert(DisputeResolution.MilestoneNotRejected.selector);
        vm.prank(consultant);
        disputeResolution.initiateDispute(missionId, milestoneIndex, "reason");
    }

    /*//////////////////////////////////////////////////////////////
                        VOTE ON DISPUTE TESTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Test: Eligible arbiter can vote on dispute
    function test_ArbiterVote_Success() public {
        // Create dispute
        vm.prank(consultant);
        uint256 disputeId = disputeResolution.initiateDispute(missionId, milestoneIndex, "reason");

        // Get arbiters
        DisputeResolution.Dispute memory dispute = disputeResolution.getDispute(disputeId);
        address arbiter = dispute.arbiters[0];

        // Expect event
        vm.expectEmit(true, true, true, true);
        emit VoteCast(disputeId, arbiter, true);

        // Arbiter vote
        vm.prank(arbiter);
        disputeResolution.voteOnDispute(disputeId, true);

        // Verify vote recorded
        dispute = disputeResolution.getDispute(disputeId);
        assertEq(dispute.votesAccept, 1);
        assertEq(dispute.votesReject, 0);
        assertTrue(disputeResolution.hasVoted(disputeId, arbiter));
    }

    /// @notice Test: Cannot vote twice
    function test_ArbiterVote_RevertIfAlreadyVoted() public {
        vm.prank(consultant);
        uint256 disputeId = disputeResolution.initiateDispute(missionId, milestoneIndex, "reason");

        DisputeResolution.Dispute memory dispute = disputeResolution.getDispute(disputeId);
        address arbiter = dispute.arbiters[0];

        // First vote
        vm.prank(arbiter);
        disputeResolution.voteOnDispute(disputeId, true);

        // Second vote should revert
        vm.expectRevert(DisputeResolution.AlreadyVoted.selector);
        vm.prank(arbiter);
        disputeResolution.voteOnDispute(disputeId, false);
    }

    /// @notice Test: Non-eligible arbiter cannot vote (rank <3)
    function test_ArbiterVote_RevertIfNotEligible() public {
        vm.prank(consultant);
        uint256 disputeId = disputeResolution.initiateDispute(missionId, milestoneIndex, "reason");

        vm.expectRevert(DisputeResolution.NotEligibleArbiter.selector);
        vm.prank(nonArbiter);
        disputeResolution.voteOnDispute(disputeId, true);
    }

    /*//////////////////////////////////////////////////////////////
                        RESOLVE DISPUTE TESTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Test: Resolve dispute - Consultant wins (2 votes Accept)
    function test_ResolveDispute_ConsultantWins() public {
        vm.prank(consultant);
        uint256 disputeId = disputeResolution.initiateDispute(missionId, milestoneIndex, "reason");

        DisputeResolution.Dispute memory dispute = disputeResolution.getDispute(disputeId);

        // 2 arbiters vote Accept, 1 vote Reject
        vm.prank(dispute.arbiters[0]);
        disputeResolution.voteOnDispute(disputeId, true);

        vm.prank(dispute.arbiters[1]);
        disputeResolution.voteOnDispute(disputeId, true);

        vm.prank(dispute.arbiters[2]);
        disputeResolution.voteOnDispute(disputeId, false);

        // Expect event
        vm.expectEmit(true, true, true, true);
        emit DisputeResolved(disputeId, true, 2, 1);

        // Resolve dispute
        disputeResolution.resolveDispute(disputeId);

        // Verify dispute resolved
        dispute = disputeResolution.getDispute(disputeId);
        assertEq(uint(dispute.status), uint(DisputeResolution.DisputeStatus.Resolved));
        assertEq(dispute.resolvedAt, block.timestamp);

        // Verify milestone status updated to Accepted
        assertTrue(escrow.milestoneAccepted(missionId, milestoneIndex));
    }

    /// @notice Test: Resolve dispute - Client wins (2 votes Reject)
    function test_ResolveDispute_ClientWins() public {
        vm.prank(consultant);
        uint256 disputeId = disputeResolution.initiateDispute(missionId, milestoneIndex, "reason");

        DisputeResolution.Dispute memory dispute = disputeResolution.getDispute(disputeId);

        // 1 arbiter vote Accept, 2 vote Reject
        vm.prank(dispute.arbiters[0]);
        disputeResolution.voteOnDispute(disputeId, true);

        vm.prank(dispute.arbiters[1]);
        disputeResolution.voteOnDispute(disputeId, false);

        vm.prank(dispute.arbiters[2]);
        disputeResolution.voteOnDispute(disputeId, false);

        // Expect event
        vm.expectEmit(true, true, true, true);
        emit DisputeResolved(disputeId, false, 1, 2);

        // Resolve dispute
        disputeResolution.resolveDispute(disputeId);

        // Verify dispute resolved
        dispute = disputeResolution.getDispute(disputeId);
        assertEq(uint(dispute.status), uint(DisputeResolution.DisputeStatus.Resolved));

        // Verify milestone status stays Rejected
        assertFalse(escrow.milestoneAccepted(missionId, milestoneIndex));
    }

    /// @notice Test: Resolve dispute - Tie defaults to client wins
    function test_ResolveDispute_Tie_ClientWins() public {
        vm.prank(consultant);
        uint256 disputeId = disputeResolution.initiateDispute(missionId, milestoneIndex, "reason");

        // Only 2 arbiters vote (1 Accept, 1 Reject) - tie
        DisputeResolution.Dispute memory dispute = disputeResolution.getDispute(disputeId);

        vm.prank(dispute.arbiters[0]);
        disputeResolution.voteOnDispute(disputeId, true);

        vm.prank(dispute.arbiters[1]);
        disputeResolution.voteOnDispute(disputeId, false);

        // Fast-forward past vote period (7 days)
        vm.warp(block.timestamp + 8 days);

        // Resolve dispute (tie = client wins)
        disputeResolution.resolveDispute(disputeId);

        dispute = disputeResolution.getDispute(disputeId);
        assertEq(uint(dispute.status), uint(DisputeResolution.DisputeStatus.Resolved));

        // Milestone stays Rejected
        assertFalse(escrow.milestoneAccepted(missionId, milestoneIndex));
    }

    /*//////////////////////////////////////////////////////////////
                        CANCEL DISPUTE TESTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Test: Consultant can cancel dispute before votes
    function test_CancelDispute_Success() public {
        vm.prank(consultant);
        uint256 disputeId = disputeResolution.initiateDispute(missionId, milestoneIndex, "reason");

        // Expect event
        vm.expectEmit(true, true, true, true);
        emit DisputeCancelled(disputeId);

        // Consultant cancel
        vm.prank(consultant);
        disputeResolution.cancelDispute(disputeId);

        // Verify status
        DisputeResolution.Dispute memory dispute = disputeResolution.getDispute(disputeId);
        assertEq(uint(dispute.status), uint(DisputeResolution.DisputeStatus.Cancelled));
    }

    /// @notice Test: Cannot cancel if not initiator
    function test_CancelDispute_RevertIfNotInitiator() public {
        vm.prank(consultant);
        uint256 disputeId = disputeResolution.initiateDispute(missionId, milestoneIndex, "reason");

        vm.expectRevert(DisputeResolution.NotDisputeInitiator.selector);
        vm.prank(client);
        disputeResolution.cancelDispute(disputeId);
    }
}

/*//////////////////////////////////////////////////////////////
                        MOCK CONTRACTS
//////////////////////////////////////////////////////////////*/

contract MockMilestoneEscrow {
    mapping(uint256 => address) public missionClients;
    mapping(uint256 => address) public missionConsultants;
    mapping(uint256 => mapping(uint256 => MilestoneEscrow.MilestoneStatus)) public milestoneStatuses;
    mapping(uint256 => mapping(uint256 => uint256)) public milestoneAmounts;
    mapping(uint256 => mapping(uint256 => bool)) public milestonesAccepted;

    function setMissionClient(uint256 missionId, address client) external {
        missionClients[missionId] = client;
    }

    function setMissionConsultant(uint256 missionId, address consultant) external {
        missionConsultants[missionId] = consultant;
    }

    function setMilestoneStatus(
        uint256 missionId,
        uint256 milestoneIndex,
        MilestoneEscrow.MilestoneStatus status
    ) external {
        milestoneStatuses[missionId][milestoneIndex] = status;
    }

    function setMilestoneAmount(uint256 missionId, uint256 milestoneIndex, uint256 amount) external {
        milestoneAmounts[missionId][milestoneIndex] = amount;
    }

    function getMissionClient(uint256 missionId) external view returns (address) {
        return missionClients[missionId];
    }

    function getMissionConsultant(uint256 missionId) external view returns (address) {
        return missionConsultants[missionId];
    }

    function getMilestoneStatus(
        uint256 missionId,
        uint256 milestoneIndex
    ) external view returns (MilestoneEscrow.MilestoneStatus) {
        return milestoneStatuses[missionId][milestoneIndex];
    }

    function acceptMilestoneFromDispute(uint256 missionId, uint256 milestoneIndex) external {
        milestonesAccepted[missionId][milestoneIndex] = true;
    }

    function milestoneAccepted(uint256 missionId, uint256 milestoneIndex) external view returns (bool) {
        return milestonesAccepted[missionId][milestoneIndex];
    }
}

contract MockMembershipContract {
    mapping(address => uint8) public ranks;

    function setRank(address user, uint8 rank) external {
        ranks[user] = rank;
    }

    function getRank(address user) external view returns (uint8) {
        return ranks[user];
    }
}
