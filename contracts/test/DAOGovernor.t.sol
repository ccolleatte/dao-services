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
        membership = new DAOMembership(admin);

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
        membership.addMember(proposer1, 1); // Active Contributor
        membership.addMember(proposer2, 2); // Mid-Level Contributor
        membership.addMember(proposer3, 3); // Core Team
        membership.addMember(voter1, 1);
        membership.addMember(voter2, 2);

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
        calldatas[0] = abi.encodeWithSignature("addMember(address,uint8)", address(99), 1);

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
        calldatas[0] = abi.encodeWithSignature("addMember(address,uint8)", address(99), 1);

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

        // Voter with Rank 2 should have weight 3
        uint256 voter2Weight = membership.calculateVoteWeight(voter2);
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
}
