// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/DAOGovernor.sol";
import "../src/DAOMembership.sol";
import "@openzeppelin/contracts/governance/TimelockController.sol";

contract DAOGovernorTest is Test {
    DAOMembership public membership;
    DAOGovernor public governor;
    TimelockController public timelock;

    address public admin = address(1);
    address public proposer1 = address(2); // Rank 1
    address public proposer2 = address(3); // Rank 2
    address public proposer3 = address(4); // Rank 3
    address public voter1 = address(5);    // Rank 1
    address public voter2 = address(6);    // Rank 2

    uint256 constant MIN_DELAY = 1 days;

    function setUp() public {
        vm.startPrank(admin);

        // Deploy DAOMembership
        membership = new DAOMembership();

        // Setup timelock
        address[] memory proposers = new address[](1);
        address[] memory executors = new address[](1);
        proposers[0] = address(0); // Anyone can propose (Governor controls this)
        executors[0] = address(0); // Anyone can execute (after timelock)

        timelock = new TimelockController(
            MIN_DELAY,
            proposers,
            executors,
            admin
        );

        // Deploy Governor
        governor = new DAOGovernor(membership, timelock);

        // Grant Governor proposer role on timelock
        bytes32 PROPOSER_ROLE = timelock.PROPOSER_ROLE();
        bytes32 EXECUTOR_ROLE = timelock.EXECUTOR_ROLE();
        timelock.grantRole(PROPOSER_ROLE, address(governor));
        timelock.grantRole(EXECUTOR_ROLE, address(governor));

        // Add members with various ranks
        membership.addMember(proposer1, 1, "proposer1"); // Active Contributor
        membership.addMember(proposer2, 2, "proposer2"); // Mid-Level Contributor
        membership.addMember(proposer3, 3, "proposer3"); // Core Team
        membership.addMember(voter1, 1, "voter1");
        membership.addMember(voter2, 2, "voter2");

        vm.stopPrank();
    }

    function testConstructor() public view {
        assertEq(address(governor.membership()), address(membership));

        // Check default track configs
        (uint8 minRank, uint256 votingDelay, uint256 votingPeriod, uint256 quorum) =
            governor.trackConfigs(DAOGovernor.Track.Technical);
        assertEq(minRank, 2);
        assertEq(votingDelay, 1 days);
        assertEq(votingPeriod, 7 days);
        assertEq(quorum, 66);

        (minRank, votingDelay, votingPeriod, quorum) =
            governor.trackConfigs(DAOGovernor.Track.Treasury);
        assertEq(minRank, 1);
        assertEq(votingPeriod, 14 days);
        assertEq(quorum, 51);

        (minRank, votingDelay, votingPeriod, quorum) =
            governor.trackConfigs(DAOGovernor.Track.Membership);
        assertEq(minRank, 3);
        assertEq(quorum, 75);
    }

    function testProposeWithTrack_Technical() public {
        vm.startPrank(proposer2); // Rank 2

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

        assertGt(proposalId, 0);
        assertEq(uint(governor.proposalTrack(proposalId)), uint(DAOGovernor.Track.Technical));

        vm.stopPrank();
    }

    function testProposeWithTrack_InsufficientRank() public {
        vm.startPrank(proposer1); // Rank 1 (insufficient for Technical track)

        address[] memory targets = new address[](1);
        uint256[] memory values = new uint256[](1);
        bytes[] memory calldatas = new bytes[](1);

        targets[0] = address(membership);
        values[0] = 0;
        calldatas[0] = abi.encodeWithSignature("addMember(address,uint8,string)", address(99), 1, "newmember");

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

        vm.stopPrank();
    }

    function testProposeWithTrack_Treasury() public {
        vm.startPrank(proposer1); // Rank 1 (sufficient for Treasury)

        address[] memory targets = new address[](1);
        uint256[] memory values = new uint256[](1);
        bytes[] memory calldatas = new bytes[](1);

        targets[0] = address(membership);
        values[0] = 0;
        calldatas[0] = "";

        uint256 proposalId = governor.proposeWithTrack(
            targets,
            values,
            calldatas,
            "Treasury spending proposal",
            DAOGovernor.Track.Treasury
        );

        assertGt(proposalId, 0);
        assertEq(uint(governor.proposalTrack(proposalId)), uint(DAOGovernor.Track.Treasury));

        vm.stopPrank();
    }

    function testProposeWithTrack_Membership() public {
        vm.startPrank(proposer3); // Rank 3 (required for Membership)

        address[] memory targets = new address[](1);
        uint256[] memory values = new uint256[](1);
        bytes[] memory calldatas = new bytes[](1);

        targets[0] = address(membership);
        values[0] = 0;
        calldatas[0] = abi.encodeWithSignature("promoteMember(address)", proposer1);

        uint256 proposalId = governor.proposeWithTrack(
            targets,
            values,
            calldatas,
            "Promote member to Rank 2",
            DAOGovernor.Track.Membership
        );

        assertGt(proposalId, 0);
        assertEq(uint(governor.proposalTrack(proposalId)), uint(DAOGovernor.Track.Membership));

        vm.stopPrank();
    }

    function testProposeWithTrack_MembershipInsufficientRank() public {
        vm.startPrank(proposer2); // Rank 2 (insufficient for Membership track)

        address[] memory targets = new address[](1);
        uint256[] memory values = new uint256[](1);
        bytes[] memory calldatas = new bytes[](1);

        targets[0] = address(membership);

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

        vm.stopPrank();
    }

    function testGetVotes_RankBasedFiltering() public {
        vm.startPrank(proposer2);

        address[] memory targets = new address[](1);
        uint256[] memory values = new uint256[](1);
        bytes[] memory calldatas = new bytes[](1);

        targets[0] = address(membership);

        uint256 proposalId = governor.proposeWithTrack(
            targets,
            values,
            calldatas,
            "Technical proposal",
            DAOGovernor.Track.Technical
        );

        vm.stopPrank();

        // Vote weights should reflect DAOMembership triangular numbers
        // Rank 1: weight = 1, Rank 2: weight = 3, Rank 3: weight = 6

        // Voter with Rank 2 should have weight 3 (Technical track requires Rank 2+)
        uint256 voter2Weight = membership.calculateVoteWeight(voter2, 2);
        assertEq(voter2Weight, 3);

        // Voter with Rank 1 should have weight 0 (below minRank for Technical)
        // (Technical track requires Rank 2+)
    }

    function testSetTrackConfig_OnlyGovernance() public {
        vm.startPrank(proposer1);

        DAOGovernor.TrackConfig memory newConfig = DAOGovernor.TrackConfig({
            minRank: 1,
            votingDelay: 2 days,
            votingPeriod: 10 days,
            quorumPercent: 60
        });

        // Should fail - only governance can update
        vm.expectRevert();
        governor.setTrackConfig(DAOGovernor.Track.Technical, newConfig);

        vm.stopPrank();
    }

    function testProposalStateFlow() public {
        vm.startPrank(proposer2);

        address[] memory targets = new address[](1);
        uint256[] memory values = new uint256[](1);
        bytes[] memory calldatas = new bytes[](1);

        targets[0] = address(membership);

        uint256 proposalId = governor.proposeWithTrack(
            targets,
            values,
            calldatas,
            "Test proposal lifecycle",
            DAOGovernor.Track.Technical
        );

        // Initial state: Pending
        assertEq(uint(governor.state(proposalId)), uint(IGovernor.ProposalState.Pending));

        // Advance past voting delay
        vm.roll(block.number + governor.votingDelay() + 1);

        // State: Active
        assertEq(uint(governor.state(proposalId)), uint(IGovernor.ProposalState.Active));

        vm.stopPrank();
    }

    function testMultipleTrackProposals() public {
        // Technical proposal (Rank 2)
        vm.prank(proposer2);
        address[] memory targets = new address[](1);
        uint256[] memory values = new uint256[](1);
        bytes[] memory calldatas = new bytes[](1);

        uint256 techProposal = governor.proposeWithTrack(
            targets,
            values,
            calldatas,
            "Technical change",
            DAOGovernor.Track.Technical
        );

        // Treasury proposal (Rank 1)
        vm.prank(proposer1);
        uint256 treasuryProposal = governor.proposeWithTrack(
            targets,
            values,
            calldatas,
            "Treasury spending",
            DAOGovernor.Track.Treasury
        );

        // Membership proposal (Rank 3)
        vm.prank(proposer3);
        uint256 membershipProposal = governor.proposeWithTrack(
            targets,
            values,
            calldatas,
            "Member promotion",
            DAOGovernor.Track.Membership
        );

        // Verify tracks are correctly assigned
        assertEq(uint(governor.proposalTrack(techProposal)), uint(DAOGovernor.Track.Technical));
        assertEq(uint(governor.proposalTrack(treasuryProposal)), uint(DAOGovernor.Track.Treasury));
        assertEq(uint(governor.proposalTrack(membershipProposal)), uint(DAOGovernor.Track.Membership));
    }

    // ===== Coverage gaps — T10 (branches non couverts) =====

    function test_ProposeWithTrack_RevertsIfMemberNotActive() public {
        vm.prank(admin);
        membership.setMemberActive(proposer2, false);

        vm.prank(proposer2);
        address[] memory targets = new address[](1);
        uint256[] memory values = new uint256[](1);
        bytes[] memory calldatas = new bytes[](1);
        targets[0] = address(membership);

        vm.expectRevert(DAOGovernor.MemberNotActive.selector);
        governor.proposeWithTrack(targets, values, calldatas, "Should fail", DAOGovernor.Track.Technical);
    }

    function test_CastVote_ForVote() public {
        vm.prank(proposer2);
        address[] memory targets = new address[](1);
        uint256[] memory values = new uint256[](1);
        bytes[] memory calldatas = new bytes[](1);
        targets[0] = address(membership);
        uint256 proposalId = governor.proposeWithTrack(
            targets, values, calldatas, "Vote test", DAOGovernor.Track.Technical
        );

        vm.roll(block.number + governor.votingDelay() + 1);

        vm.prank(voter2); // Rank 2, eligible for Technical
        governor.castVote(proposalId, 1); // For

        (uint256 againstVotes, uint256 forVotes, uint256 abstainVotes) = governor.proposalVotes(proposalId);
        assertGt(forVotes, 0);
        assertEq(againstVotes, 0);
        assertEq(abstainVotes, 0);
    }

    function test_CastVote_AbstainVote() public {
        vm.prank(proposer2);
        address[] memory targets = new address[](1);
        uint256[] memory values = new uint256[](1);
        bytes[] memory calldatas = new bytes[](1);
        targets[0] = address(membership);
        uint256 proposalId = governor.proposeWithTrack(
            targets, values, calldatas, "Abstain test", DAOGovernor.Track.Technical
        );

        vm.roll(block.number + governor.votingDelay() + 1);

        vm.prank(voter2);
        governor.castVote(proposalId, 2); // Abstain

        (uint256 againstVotes, uint256 forVotes, uint256 abstainVotes) = governor.proposalVotes(proposalId);
        assertGt(abstainVotes, 0);
        assertEq(forVotes, 0);
        assertEq(againstVotes, 0);
    }

    /// @dev Couvre la branche `!active → return 0` dans _getVotes
    function test_CastVote_InactiveVoterHasZeroWeight() public {
        vm.prank(proposer2);
        address[] memory targets = new address[](1);
        uint256[] memory values = new uint256[](1);
        bytes[] memory calldatas = new bytes[](1);
        targets[0] = address(membership);
        uint256 proposalId = governor.proposeWithTrack(
            targets, values, calldatas, "Inactive voter", DAOGovernor.Track.Technical
        );

        // Désactiver voter2 après création (DAOGovernor lit l'état courant dans _getVotes)
        vm.prank(admin);
        membership.setMemberActive(voter2, false);

        vm.roll(block.number + governor.votingDelay() + 1);

        vm.prank(voter2);
        governor.castVote(proposalId, 1); // For, mais poids = 0

        (, uint256 forVotes,) = governor.proposalVotes(proposalId);
        assertEq(forVotes, 0); // Membre inactif → poids nul
    }

    /// @dev Couvre proposalQuorum : petite population, quorumNeeded > 5 → /5
    function test_ProposalQuorum_SmallPopulation_DivFive() public {
        vm.prank(proposer2);
        address[] memory targets = new address[](1);
        uint256[] memory values = new uint256[](1);
        bytes[] memory calldatas = new bytes[](1);
        targets[0] = address(membership);
        uint256 proposalId = governor.proposeWithTrack(
            targets, values, calldatas, "Quorum small test", DAOGovernor.Track.Technical
        );

        // Membres éligibles (rank ≥ 2): proposer2(w=3) + proposer3(w=6) + voter2(w=3) = 12 < 20
        // quorumNeeded = (12*66)/100 = 7 → 7 > 5 → 7/5 = 1
        uint256 q = governor.proposalQuorum(proposalId);
        assertEq(q, 1);
    }

    /// @dev Couvre proposalQuorum : très petite population, quorumNeeded ≤ 5 → retourne 1 (minimum)
    function test_ProposalQuorum_SmallPopulation_MinimumOne() public {
        vm.prank(proposer3); // Rank 3 — seul éligible pour Membership
        address[] memory targets = new address[](1);
        uint256[] memory values = new uint256[](1);
        bytes[] memory calldatas = new bytes[](1);
        targets[0] = address(membership);
        uint256 proposalId = governor.proposeWithTrack(
            targets, values, calldatas, "Membership quorum", DAOGovernor.Track.Membership
        );

        // Seul proposer3 éligible (rank ≥ 3): total weight = 6 < 20
        // quorumNeeded = (6*75)/100 = 4 ≤ 5 → retourne 1 (minimum)
        uint256 q = governor.proposalQuorum(proposalId);
        assertEq(q, 1);
    }

    /// @dev Couvre proposalQuorum : grande population (≥ 20) → pas d'ajustement
    function test_ProposalQuorum_LargePopulation() public {
        vm.startPrank(admin);
        membership.addMember(address(10), 3, "member10"); // Rank 3, w=6
        membership.addMember(address(11), 3, "member11"); // Rank 3, w=6
        membership.addMember(address(12), 3, "member12"); // Rank 3, w=6
        vm.stopPrank();

        vm.prank(proposer2);
        address[] memory targets = new address[](1);
        uint256[] memory values = new uint256[](1);
        bytes[] memory calldatas = new bytes[](1);
        targets[0] = address(membership);
        uint256 proposalId = governor.proposeWithTrack(
            targets, values, calldatas, "Quorum large test", DAOGovernor.Track.Technical
        );

        // Total weight: 3+6+3+6+6+6 = 30 ≥ 20 → pas d'ajustement
        // quorumNeeded = (30*66)/100 = 19
        uint256 q = governor.proposalQuorum(proposalId);
        assertEq(q, 19);
    }

    /// @dev Couvre _quorumReached + _voteSucceeded (forVotes > againstVotes) → Succeeded
    function test_ProposalLifecycle_Succeeded() public {
        vm.prank(proposer2);
        address[] memory targets = new address[](1);
        uint256[] memory values = new uint256[](1);
        bytes[] memory calldatas = new bytes[](1);
        targets[0] = address(membership);
        uint256 proposalId = governor.proposeWithTrack(
            targets, values, calldatas, "Lifecycle test", DAOGovernor.Track.Technical
        );

        vm.roll(block.number + governor.votingDelay() + 1);
        assertEq(uint(governor.state(proposalId)), uint(IGovernor.ProposalState.Active));

        // quorum = 1 (petite pop), voter2 poids = 3 ≥ 1
        vm.prank(voter2);
        governor.castVote(proposalId, 1); // For

        vm.roll(block.number + governor.votingPeriod() + 1);
        assertEq(uint(governor.state(proposalId)), uint(IGovernor.ProposalState.Succeeded));
    }

    /// @dev Couvre _quorumReached + _voteSucceeded (forVotes ≤ againstVotes) → Defeated
    function test_ProposalLifecycle_Defeated() public {
        vm.prank(proposer2);
        address[] memory targets = new address[](1);
        uint256[] memory values = new uint256[](1);
        bytes[] memory calldatas = new bytes[](1);
        targets[0] = address(membership);
        uint256 proposalId = governor.proposeWithTrack(
            targets, values, calldatas, "Defeat test", DAOGovernor.Track.Technical
        );

        vm.roll(block.number + governor.votingDelay() + 1);

        // Against vote — quorum atteint (3 ≥ 1), but for(0) ≤ against(3) → Defeated
        vm.prank(voter2);
        governor.castVote(proposalId, 0); // Against

        vm.roll(block.number + governor.votingPeriod() + 1);
        assertEq(uint(governor.state(proposalId)), uint(IGovernor.ProposalState.Defeated));
    }
}
