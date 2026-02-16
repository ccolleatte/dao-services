// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/ReputationTracker.sol";

/**
 * @title ReputationTrackerTest
 * @notice TDD RED phase - Tests written BEFORE implementation
 * @dev Phase 2 Extension: Basic reputation tracking
 */
contract ReputationTrackerTest is Test {
    ReputationTracker public tracker;
    MockDisputeResolution public disputeContract;

    address consultant = makeAddr("consultant");
    address client = makeAddr("client");

    uint256 missionId = 1;

    // Events
    event ReputationUpdated(
        address indexed user,
        bool isConsultant,
        uint256 missionsCompleted,
        uint256 disputesWon,
        uint256 disputesLost
    );

    function setUp() public {
        disputeContract = new MockDisputeResolution();
        tracker = new ReputationTracker(address(disputeContract));
    }

    /*//////////////////////////////////////////////////////////////
                        UPDATE REPUTATION TESTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Test: Update reputation after consultant wins dispute
    function test_UpdateReputation_ConsultantWon() public {
        // Expect event
        vm.expectEmit(true, true, true, true);
        emit ReputationUpdated(consultant, true, 0, 1, 0);

        // Update reputation (consultant won)
        vm.prank(address(disputeContract));
        tracker.updateReputation(missionId, consultant, client, true);

        // Verify consultant reputation
        ReputationTracker.ReputationScore memory score = tracker.getReputationScore(consultant);
        assertEq(score.disputesInitiated, 1);
        assertEq(score.disputesWon, 1);
        assertEq(score.disputesLost, 0);

        // Verify client reputation
        ReputationTracker.ReputationScore memory clientScore = tracker.getClientReputation(client);
        assertEq(clientScore.disputesLost, 1);
    }

    /// @notice Test: Update reputation after client wins dispute
    function test_UpdateReputation_ClientWon() public {
        // Update reputation (consultant lost)
        vm.prank(address(disputeContract));
        tracker.updateReputation(missionId, consultant, client, false);

        // Verify consultant reputation
        ReputationTracker.ReputationScore memory score = tracker.getConsultantReputation(consultant);
        assertEq(score.disputesInitiated, 1);
        assertEq(score.disputesWon, 0);
        assertEq(score.disputesLost, 1);

        // Verify client reputation (client won = no disputesLost)
        ReputationTracker.ReputationScore memory clientScore = tracker.getClientReputation(client);
        assertEq(clientScore.disputesLost, 0);
    }

    /// @notice Test: Cannot update if not dispute contract
    function test_UpdateReputation_RevertIfNotDisputeContract() public {
        vm.expectRevert(ReputationTracker.NotDisputeContract.selector);
        vm.prank(consultant);
        tracker.updateReputation(missionId, consultant, client, true);
    }

    /*//////////////////////////////////////////////////////////////
                        REPUTATION PENALTY TESTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Test: Calculate penalty for high dispute loss rate (30%)
    function test_GetReputationPenalty_HighLossRate() public {
        // Simulate 3 disputes lost, 7 disputes won (total 10)
        for (uint256 i = 0; i < 7; i++) {
            vm.prank(address(disputeContract));
            tracker.updateReputation(i, consultant, client, true); // Won
        }

        for (uint256 i = 7; i < 10; i++) {
            vm.prank(address(disputeContract));
            tracker.updateReputation(i, consultant, client, false); // Lost
        }

        // 3 lost / 10 total = 30% loss rate → 30 penalty
        uint256 penalty = tracker.getReputationPenalty(consultant);
        assertEq(penalty, 30);
    }

    /// @notice Test: Calculate penalty for low dispute loss rate (5%)
    function test_GetReputationPenalty_LowLossRate() public {
        // Simulate 1 dispute lost, 19 disputes won (total 20)
        for (uint256 i = 0; i < 19; i++) {
            vm.prank(address(disputeContract));
            tracker.updateReputation(i, consultant, client, true); // Won
        }

        vm.prank(address(disputeContract));
        tracker.updateReputation(19, consultant, client, false); // Lost

        // 1 lost / 20 total = 5% loss rate → 5 penalty
        uint256 penalty = tracker.getReputationPenalty(consultant);
        assertEq(penalty, 5);
    }

    /// @notice Test: No penalty if no disputes
    function test_GetReputationPenalty_NoDisputes() public {
        uint256 penalty = tracker.getReputationPenalty(consultant);
        assertEq(penalty, 0);
    }

    /*//////////////////////////////////////////////////////////////
                        MISSION COMPLETION TESTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Test: Track mission completion
    function test_RecordMissionCompleted() public {
        vm.prank(address(disputeContract));
        tracker.recordMissionCompleted(consultant);

        ReputationTracker.ReputationScore memory score = tracker.getReputationScore(consultant);
        assertEq(score.missionsCompleted, 1);
    }

    /// @notice Test: Multiple missions completed
    function test_RecordMissionCompleted_Multiple() public {
        for (uint256 i = 0; i < 5; i++) {
            vm.prank(address(disputeContract));
            tracker.recordMissionCompleted(consultant);
        }

        ReputationTracker.ReputationScore memory score = tracker.getReputationScore(consultant);
        assertEq(score.missionsCompleted, 5);
    }

    /*//////////////////////////////////////////////////////////////
                        VIEW FUNCTIONS TESTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Test: Get reputation score returns correct data
    function test_GetReputationScore_CompleteData() public {
        // Record 2 missions completed
        vm.prank(address(disputeContract));
        tracker.recordMissionCompleted(consultant);
        vm.prank(address(disputeContract));
        tracker.recordMissionCompleted(consultant);

        // Record 1 dispute won, 1 dispute lost
        vm.prank(address(disputeContract));
        tracker.updateReputation(1, consultant, client, true);
        vm.prank(address(disputeContract));
        tracker.updateReputation(2, consultant, client, false);

        ReputationTracker.ReputationScore memory score = tracker.getReputationScore(consultant);
        assertEq(score.missionsCompleted, 2);
        assertEq(score.disputesInitiated, 2);
        assertEq(score.disputesWon, 1);
        assertEq(score.disputesLost, 1);
    }
}

/*//////////////////////////////////////////////////////////////
                        MOCK CONTRACTS
//////////////////////////////////////////////////////////////*/

contract MockDisputeResolution {
    // Mock dispute contract for testing
}
