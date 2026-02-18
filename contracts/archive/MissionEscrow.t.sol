// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/MissionEscrow.sol";
import "../src/DAOMembership.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

// Mock DAOS token for testing
contract MockDAOSToken is ERC20 {
    constructor() ERC20("DAOS Token", "DAOS") {
        _mint(msg.sender, 1000000 ether);
    }

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}

contract MissionEscrowTest is Test {
    MissionEscrow public escrow;
    DAOMembership public membership;
    MockDAOSToken public daosToken;

    address public client = address(0x1);
    address public consultant = address(0x2);
    address public juror1 = address(0x3);
    address public juror2 = address(0x4);
    address public juror3 = address(0x5);
    address public juror4 = address(0x6);
    address public juror5 = address(0x7);

    uint256 public constant MISSION_ID = 1;
    uint256 public constant TOTAL_BUDGET = 10000 ether;

    function setUp() public {
        vm.startPrank(client);

        // Deploy contracts
        daosToken = new MockDAOSToken();
        membership = new DAOMembership();

        // Setup members
        membership.addMember(client, 2, "client-github");
        membership.addMember(consultant, 3, "consultant-github");

        // Setup jurors (Rank 3+)
        membership.addMember(juror1, 3, "juror1-github");
        membership.addMember(juror2, 3, "juror2-github");
        membership.addMember(juror3, 4, "juror3-github");
        membership.addMember(juror4, 3, "juror4-github");
        membership.addMember(juror5, 4, "juror5-github");

        // Deploy escrow
        escrow = new MissionEscrow(
            MISSION_ID,
            client,
            consultant,
            TOTAL_BUDGET,
            address(daosToken),
            address(membership)
        );

        // Fund escrow with total budget
        daosToken.mint(address(escrow), TOTAL_BUDGET);

        // Fund client and consultant for dispute deposits
        daosToken.mint(client, 1000 ether);
        daosToken.mint(consultant, 1000 ether);

        // Give client and consultant ETH for dispute deposits
        vm.deal(client, 1000 ether);
        vm.deal(consultant, 1000 ether);

        vm.stopPrank();
    }

    // ===== Test Constructor =====

    function test_Constructor() public {
        assertEq(escrow.missionId(), MISSION_ID);
        assertEq(escrow.client(), client);
        assertEq(escrow.consultant(), consultant);
        assertEq(escrow.totalBudget(), TOTAL_BUDGET);
        assertEq(escrow.releasedFunds(), 0);
        assertEq(address(escrow.daosToken()), address(daosToken));
        assertEq(escrow.membershipContract(), address(membership));
    }

    // ===== Test Add Milestone =====

    function test_AddMilestone() public {
        vm.prank(client);

        escrow.addMilestone("Milestone 1", 2000 ether, block.timestamp + 30 days);

        assertEq(escrow.getMilestoneCount(), 1);

        MissionEscrow.Milestone memory milestone = escrow.getMilestone(0);
        assertEq(milestone.id, 0);
        assertEq(milestone.description, "Milestone 1");
        assertEq(milestone.amount, 2000 ether);
        assertEq(milestone.deadline, block.timestamp + 30 days);
        assertTrue(uint8(milestone.status) == uint8(MissionEscrow.MilestoneStatus.Pending));
        assertEq(milestone.deliverable, "");
        assertEq(milestone.submittedAt, 0);
    }

    function test_AddMilestoneRevertsIfNotClient() public {
        vm.prank(consultant);

        vm.expectRevert(MissionEscrow.UnauthorizedClient.selector);
        escrow.addMilestone("Milestone 1", 2000 ether, block.timestamp + 30 days);
    }

    function test_AddMultipleMilestones() public {
        vm.startPrank(client);

        escrow.addMilestone("Milestone 1", 3000 ether, block.timestamp + 30 days);
        escrow.addMilestone("Milestone 2", 4000 ether, block.timestamp + 60 days);
        escrow.addMilestone("Milestone 3", 3000 ether, block.timestamp + 90 days);

        assertEq(escrow.getMilestoneCount(), 3);

        vm.stopPrank();
    }

    // ===== Test Submit Milestone =====

    function test_SubmitMilestone() public {
        vm.prank(client);
        escrow.addMilestone("Milestone 1", 2000 ether, block.timestamp + 30 days);

        vm.prank(consultant);
        escrow.submitMilestone(0, "QmYwAPJzv5CZsnA625s3Xf2nemtYgPpHdWEz79ojWnPbdG");

        MissionEscrow.Milestone memory milestone = escrow.getMilestone(0);
        assertTrue(uint8(milestone.status) == uint8(MissionEscrow.MilestoneStatus.Submitted));
        assertEq(milestone.deliverable, "QmYwAPJzv5CZsnA625s3Xf2nemtYgPpHdWEz79ojWnPbdG");
        assertEq(milestone.submittedAt, block.timestamp);
    }

    function test_SubmitMilestoneRevertsIfNotConsultant() public {
        vm.prank(client);
        escrow.addMilestone("Milestone 1", 2000 ether, block.timestamp + 30 days);

        vm.prank(client); // Not consultant

        vm.expectRevert(MissionEscrow.UnauthorizedConsultant.selector);
        escrow.submitMilestone(0, "QmYwAPJzv5CZsnA625s3Xf2nemtYgPpHdWEz79ojWnPbdG");
    }

    function test_SubmitMilestoneRevertsIfInvalidMilestoneId() public {
        vm.prank(consultant);

        vm.expectRevert(MissionEscrow.InvalidMilestone.selector);
        escrow.submitMilestone(99, "QmYwAPJzv5CZsnA625s3Xf2nemtYgPpHdWEz79ojWnPbdG");
    }

    function test_SubmitMilestoneRevertsIfNotPending() public {
        vm.prank(client);
        escrow.addMilestone("Milestone 1", 2000 ether, block.timestamp + 30 days);

        vm.prank(consultant);
        escrow.submitMilestone(0, "QmYwAPJzv5CZsnA625s3Xf2nemtYgPpHdWEz79ojWnPbdG");

        // Try to submit again
        vm.prank(consultant);
        vm.expectRevert(MissionEscrow.InvalidMilestone.selector);
        escrow.submitMilestone(0, "QmYwAPJzv5CZsnA625s3Xf2nemtYgPpHdWEz79ojWnPbdG");
    }

    function test_SubmitMilestoneRevertsIfPreviousNotApproved() public {
        vm.startPrank(client);
        escrow.addMilestone("Milestone 1", 2000 ether, block.timestamp + 30 days);
        escrow.addMilestone("Milestone 2", 3000 ether, block.timestamp + 60 days);
        vm.stopPrank();

        // Submit milestone 1
        vm.prank(consultant);
        escrow.submitMilestone(0, "QmYwAPJzv5CZsnA625s3Xf2nemtYgPpHdWEz79ojWnPbdG");

        // Try to submit milestone 2 (milestone 1 not approved yet)
        vm.prank(consultant);
        vm.expectRevert(MissionEscrow.PreviousMilestoneNotApproved.selector);
        escrow.submitMilestone(1, "QmYwAPJzv5CZsnA625s3Xf2nemtYgPpHdWEz79ojWnPbdG");
    }

    function test_SubmitMilestoneSequentialFlow() public {
        vm.startPrank(client);
        escrow.addMilestone("Milestone 1", 2000 ether, block.timestamp + 30 days);
        escrow.addMilestone("Milestone 2", 3000 ether, block.timestamp + 60 days);
        vm.stopPrank();

        // Submit milestone 1
        vm.prank(consultant);
        escrow.submitMilestone(0, "QmYwAPJzv5CZsnA625s3Xf2nemtYgPpHdWEz79ojWnPbdG");

        // Approve milestone 1
        vm.prank(client);
        escrow.approveMilestone(0);

        // Now milestone 2 can be submitted
        vm.prank(consultant);
        escrow.submitMilestone(1, "QmYwAPJzv5CZsnA625s3Xf2nemtYgPpHdWEz79ojWnPbdH");

        MissionEscrow.Milestone memory milestone2 = escrow.getMilestone(1);
        assertTrue(uint8(milestone2.status) == uint8(MissionEscrow.MilestoneStatus.Submitted));
    }

    // ===== Test Approve Milestone =====

    function test_ApproveMilestone() public {
        vm.prank(client);
        escrow.addMilestone("Milestone 1", 2000 ether, block.timestamp + 30 days);

        vm.prank(consultant);
        escrow.submitMilestone(0, "QmYwAPJzv5CZsnA625s3Xf2nemtYgPpHdWEz79ojWnPbdG");

        uint256 balanceBefore = daosToken.balanceOf(consultant);

        vm.prank(client);
        escrow.approveMilestone(0);

        uint256 balanceAfter = daosToken.balanceOf(consultant);

        MissionEscrow.Milestone memory milestone = escrow.getMilestone(0);
        assertTrue(uint8(milestone.status) == uint8(MissionEscrow.MilestoneStatus.Approved));
        assertEq(balanceAfter - balanceBefore, 2000 ether);
        assertEq(escrow.releasedFunds(), 2000 ether);
    }

    function test_ApproveMilestoneRevertsIfNotClient() public {
        vm.prank(client);
        escrow.addMilestone("Milestone 1", 2000 ether, block.timestamp + 30 days);

        vm.prank(consultant);
        escrow.submitMilestone(0, "QmYwAPJzv5CZsnA625s3Xf2nemtYgPpHdWEz79ojWnPbdG");

        vm.prank(consultant); // Not client

        vm.expectRevert(MissionEscrow.UnauthorizedClient.selector);
        escrow.approveMilestone(0);
    }

    function test_ApproveMilestoneRevertsIfNotSubmitted() public {
        vm.prank(client);
        escrow.addMilestone("Milestone 1", 2000 ether, block.timestamp + 30 days);

        vm.prank(client);

        vm.expectRevert(MissionEscrow.MilestoneNotSubmitted.selector);
        escrow.approveMilestone(0);
    }

    // ===== Test Reject Milestone =====

    function test_RejectMilestone() public {
        vm.prank(client);
        escrow.addMilestone("Milestone 1", 2000 ether, block.timestamp + 30 days);

        vm.prank(consultant);
        escrow.submitMilestone(0, "QmYwAPJzv5CZsnA625s3Xf2nemtYgPpHdWEz79ojWnPbdG");

        vm.prank(client);
        escrow.rejectMilestone(0, "Not acceptable quality");

        MissionEscrow.Milestone memory milestone = escrow.getMilestone(0);
        assertTrue(uint8(milestone.status) == uint8(MissionEscrow.MilestoneStatus.Rejected));
    }

    function test_RejectMilestoneRevertsIfNotClient() public {
        vm.prank(client);
        escrow.addMilestone("Milestone 1", 2000 ether, block.timestamp + 30 days);

        vm.prank(consultant);
        escrow.submitMilestone(0, "QmYwAPJzv5CZsnA625s3Xf2nemtYgPpHdWEz79ojWnPbdG");

        vm.prank(consultant); // Not client

        vm.expectRevert(MissionEscrow.UnauthorizedClient.selector);
        escrow.rejectMilestone(0, "Reason");
    }

    function test_RejectMilestoneRevertsIfNotSubmitted() public {
        vm.prank(client);
        escrow.addMilestone("Milestone 1", 2000 ether, block.timestamp + 30 days);

        vm.prank(client);

        vm.expectRevert(MissionEscrow.MilestoneNotSubmitted.selector);
        escrow.rejectMilestone(0, "Reason");
    }

    // ===== Test Auto-Release Milestone =====

    function test_AutoReleaseMilestone() public {
        vm.prank(client);
        escrow.addMilestone("Milestone 1", 2000 ether, block.timestamp + 30 days);

        vm.prank(consultant);
        escrow.submitMilestone(0, "QmYwAPJzv5CZsnA625s3Xf2nemtYgPpHdWEz79ojWnPbdG");

        // Fast forward 7 days
        skip(7 days);

        uint256 balanceBefore = daosToken.balanceOf(consultant);

        // Anyone can trigger auto-release
        escrow.autoReleaseMilestone(0);

        uint256 balanceAfter = daosToken.balanceOf(consultant);

        MissionEscrow.Milestone memory milestone = escrow.getMilestone(0);
        assertTrue(uint8(milestone.status) == uint8(MissionEscrow.MilestoneStatus.Approved));
        assertEq(balanceAfter - balanceBefore, 2000 ether);
    }

    function test_AutoReleaseMilestoneRevertsIfDelayNotMet() public {
        vm.prank(client);
        escrow.addMilestone("Milestone 1", 2000 ether, block.timestamp + 30 days);

        vm.prank(consultant);
        escrow.submitMilestone(0, "QmYwAPJzv5CZsnA625s3Xf2nemtYgPpHdWEz79ojWnPbdG");

        // Try to auto-release immediately (before 7 days)
        vm.expectRevert();
        escrow.autoReleaseMilestone(0);
    }

    function test_AutoReleaseMilestoneRevertsIfNotSubmitted() public {
        vm.prank(client);
        escrow.addMilestone("Milestone 1", 2000 ether, block.timestamp + 30 days);

        skip(7 days);

        vm.expectRevert(MissionEscrow.MilestoneNotSubmitted.selector);
        escrow.autoReleaseMilestone(0);
    }

    // ===== Test Withdraw Remaining Funds =====

    function test_WithdrawRemainingFunds() public {
        vm.prank(client);
        escrow.addMilestone("Milestone 1", 3000 ether, block.timestamp + 30 days);

        vm.prank(consultant);
        escrow.submitMilestone(0, "QmYwAPJzv5CZsnA625s3Xf2nemtYgPpHdWEz79ojWnPbdG");

        vm.prank(client);
        escrow.approveMilestone(0);

        // Withdraw remaining (10000 - 3000 = 7000)
        uint256 balanceBefore = daosToken.balanceOf(client);

        vm.prank(client);
        escrow.withdrawRemainingFunds();

        uint256 balanceAfter = daosToken.balanceOf(client);

        assertEq(balanceAfter - balanceBefore, 7000 ether);
    }

    function test_WithdrawRemainingFundsRevertsIfNotClient() public {
        vm.prank(consultant);

        vm.expectRevert(MissionEscrow.UnauthorizedClient.selector);
        escrow.withdrawRemainingFunds();
    }

    function test_WithdrawRemainingFundsRevertsIfNoFunds() public {
        // Approve all milestones to release all funds
        vm.startPrank(client);
        escrow.addMilestone("Milestone 1", 10000 ether, block.timestamp + 30 days);
        vm.stopPrank();

        vm.prank(consultant);
        escrow.submitMilestone(0, "QmYwAPJzv5CZsnA625s3Xf2nemtYgPpHdWEz79ojWnPbdG");

        vm.prank(client);
        escrow.approveMilestone(0);

        // No remaining funds
        vm.prank(client);
        vm.expectRevert(MissionEscrow.NoFundsToWithdraw.selector);
        escrow.withdrawRemainingFunds();
    }

    // ===== Test Get Milestone =====

    function test_GetMilestone() public {
        vm.prank(client);
        escrow.addMilestone("Milestone 1", 2000 ether, block.timestamp + 30 days);

        MissionEscrow.Milestone memory milestone = escrow.getMilestone(0);

        assertEq(milestone.id, 0);
        assertEq(milestone.description, "Milestone 1");
        assertEq(milestone.amount, 2000 ether);
    }

    function test_GetMilestoneRevertsIfInvalidId() public {
        vm.expectRevert();
        escrow.getMilestone(99);
    }

    // ===== Test Milestone Count =====

    function test_GetMilestoneCount() public {
        assertEq(escrow.getMilestoneCount(), 0);

        vm.startPrank(client);
        escrow.addMilestone("Milestone 1", 2000 ether, block.timestamp + 30 days);
        escrow.addMilestone("Milestone 2", 3000 ether, block.timestamp + 60 days);
        vm.stopPrank();

        assertEq(escrow.getMilestoneCount(), 2);
    }

    // ===== Test Constants =====

    function test_Constants() public {
        assertEq(escrow.AUTO_RELEASE_DELAY(), 7 days);
        assertEq(escrow.DISPUTE_DEPOSIT(), 100 ether);
        assertEq(escrow.JURY_SIZE(), 5);
        assertEq(escrow.VOTING_PERIOD(), 72 hours);
    }

    // ===== Integration Test: Full Milestone Workflow =====

    function test_FullMilestoneWorkflow() public {
        // Setup 3 milestones
        vm.startPrank(client);
        escrow.addMilestone("Milestone 1", 3000 ether, block.timestamp + 30 days);
        escrow.addMilestone("Milestone 2", 4000 ether, block.timestamp + 60 days);
        escrow.addMilestone("Milestone 3", 3000 ether, block.timestamp + 90 days);
        vm.stopPrank();

        assertEq(escrow.getMilestoneCount(), 3);

        // Milestone 1: Submit -> Approve
        vm.prank(consultant);
        escrow.submitMilestone(0, "QmHash1");

        vm.prank(client);
        escrow.approveMilestone(0);

        assertEq(escrow.releasedFunds(), 3000 ether);

        // Milestone 2: Submit -> Approve
        vm.prank(consultant);
        escrow.submitMilestone(1, "QmHash2");

        vm.prank(client);
        escrow.approveMilestone(1);

        assertEq(escrow.releasedFunds(), 7000 ether);

        // Milestone 3: Submit -> Reject -> Resubmit (would require dispute in real scenario)
        vm.prank(consultant);
        escrow.submitMilestone(2, "QmHash3");

        vm.prank(client);
        escrow.rejectMilestone(2, "Quality issues");

        MissionEscrow.Milestone memory milestone3 = escrow.getMilestone(2);
        assertTrue(uint8(milestone3.status) == uint8(MissionEscrow.MilestoneStatus.Rejected));

        // Withdraw remaining funds
        uint256 clientBalanceBefore = daosToken.balanceOf(client);

        vm.prank(client);
        escrow.withdrawRemainingFunds();

        uint256 clientBalanceAfter = daosToken.balanceOf(client);

        assertEq(clientBalanceAfter - clientBalanceBefore, 3000 ether); // Remaining funds withdrawn
    }
}
