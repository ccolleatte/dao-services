// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/DAOTreasury.sol";
import "../src/DAOMembership.sol";

contract DAOTreasuryTest is Test {
    DAOMembership public membership;
    DAOTreasury public treasury;

    address public admin = address(1);
    address public treasurer = address(2);
    address public member1 = address(3);
    address public member2 = address(4);
    address payable public beneficiary = payable(address(5));
    address public nonMember = address(6);

    function setUp() public {
        vm.startPrank(admin);

        // Deploy contracts
        membership = new DAOMembership();
        treasury = new DAOTreasury(membership, admin);

        // Setup roles
        treasury.grantRole(treasury.TREASURER_ROLE(), treasurer);
        treasury.grantRole(treasury.SPENDER_ROLE(), treasurer);

        // Add members
        membership.addMember(member1, 1, "member1");
        membership.addMember(member2, 2, "member2");

        // Fund treasury
        vm.deal(address(treasury), 1000 ether);

        vm.stopPrank();
    }

    function testConstructor() public view {
        assertEq(address(treasury.membership()), address(membership));
        assertTrue(treasury.hasRole(treasury.DEFAULT_ADMIN_ROLE(), admin));
        assertTrue(treasury.hasRole(treasury.TREASURER_ROLE(), admin));
        assertEq(treasury.balance(), 1000 ether);
    }

    function testReceiveETH() public {
        uint256 initialBalance = address(treasury).balance;

        vm.deal(address(this), 100 ether);
        (bool success, ) = address(treasury).call{value: 100 ether}("");
        assertTrue(success);

        assertEq(address(treasury).balance, initialBalance + 100 ether);
    }

    function testCreateProposal_Success() public {
        vm.startPrank(member1);

        uint256 proposalId = treasury.createProposal(
            beneficiary,
            10 ether,
            "Payment for services",
            "development"
        );

        assertEq(proposalId, 0);

        DAOTreasury.SpendingProposal memory proposal = treasury.getProposal(proposalId);
        assertEq(proposal.beneficiary, beneficiary);
        assertEq(proposal.amount, 10 ether);
        assertEq(proposal.proposer, member1);
        assertEq(uint(proposal.status), uint(DAOTreasury.ProposalStatus.Pending));

        vm.stopPrank();
    }

    function testCreateProposal_NonMember() public {
        vm.startPrank(nonMember);

        vm.expectRevert(DAOTreasury.Unauthorized.selector);

        treasury.createProposal(
            beneficiary,
            10 ether,
            "Should fail",
            ""
        );

        vm.stopPrank();
    }

    function testCreateProposal_ZeroAmount() public {
        vm.startPrank(member1);

        vm.expectRevert(DAOTreasury.InvalidProposal.selector);

        treasury.createProposal(
            beneficiary,
            0,
            "Invalid amount",
            ""
        );

        vm.stopPrank();
    }

    function testCreateProposal_ZeroAddress() public {
        vm.startPrank(member1);

        vm.expectRevert(DAOTreasury.InvalidProposal.selector);

        treasury.createProposal(
            payable(address(0)),
            10 ether,
            "Invalid beneficiary",
            ""
        );

        vm.stopPrank();
    }

    function testApproveProposal_Success() public {
        // Create proposal
        vm.prank(member1);
        uint256 proposalId = treasury.createProposal(
            beneficiary,
            10 ether,
            "Payment",
            ""
        );

        // Approve
        vm.prank(treasurer);
        treasury.approveProposal(proposalId);

        DAOTreasury.SpendingProposal memory proposal = treasury.getProposal(proposalId);
        assertEq(uint(proposal.status), uint(DAOTreasury.ProposalStatus.Approved));
        assertGt(proposal.approvedAt, 0);
    }

    function testApproveProposal_OnlyTreasurer() public {
        vm.prank(member1);
        uint256 proposalId = treasury.createProposal(
            beneficiary,
            10 ether,
            "Payment",
            ""
        );

        // Non-treasurer tries to approve
        vm.prank(member2);
        vm.expectRevert();
        treasury.approveProposal(proposalId);
    }

    function testApproveProposal_ExceedsMaxSpend() public {
        vm.prank(member1);
        uint256 proposalId = treasury.createProposal(
            beneficiary,
            150 ether, // Exceeds maxSingleSpend (100 ether)
            "Large payment",
            ""
        );

        vm.prank(treasurer);
        vm.expectRevert(DAOTreasury.ExceedsMaxSpend.selector);
        treasury.approveProposal(proposalId);
    }

    function testExecuteProposal_Success() public {
        // Create and approve
        vm.prank(member1);
        uint256 proposalId = treasury.createProposal(
            beneficiary,
            10 ether,
            "Payment",
            ""
        );

        vm.prank(treasurer);
        treasury.approveProposal(proposalId);

        // Execute
        uint256 beneficiaryBalanceBefore = beneficiary.balance;

        vm.prank(treasurer);
        treasury.executeProposal(proposalId, "");

        DAOTreasury.SpendingProposal memory proposal = treasury.getProposal(proposalId);
        assertEq(uint(proposal.status), uint(DAOTreasury.ProposalStatus.Executed));
        assertGt(proposal.executedAt, 0);
        assertEq(beneficiary.balance, beneficiaryBalanceBefore + 10 ether);
    }

    function testExecuteProposal_NotApproved() public {
        vm.prank(member1);
        uint256 proposalId = treasury.createProposal(
            beneficiary,
            10 ether,
            "Payment",
            ""
        );

        vm.prank(treasurer);
        vm.expectRevert(DAOTreasury.ProposalNotApproved.selector);
        treasury.executeProposal(proposalId, "");
    }

    function testExecuteProposal_InsufficientFunds() public {
        // Create proposal exceeding treasury balance
        vm.prank(member1);
        uint256 proposalId = treasury.createProposal(
            beneficiary,
            50 ether,
            "Large payment",
            ""
        );

        vm.prank(treasurer);
        treasury.approveProposal(proposalId);

        // Drain treasury
        vm.deal(address(treasury), 10 ether);

        vm.prank(treasurer);
        vm.expectRevert(DAOTreasury.InsufficientFunds.selector);
        treasury.executeProposal(proposalId, "");
    }

    function testExecuteProposal_DailyLimit() public {
        // Create and execute first proposal
        vm.prank(member1);
        uint256 proposal1 = treasury.createProposal(
            beneficiary,
            400 ether,
            "Payment 1",
            ""
        );

        vm.prank(treasurer);
        treasury.approveProposal(proposal1);

        vm.prank(treasurer);
        treasury.executeProposal(proposal1, "");

        // Create second proposal (would exceed daily limit)
        vm.prank(member1);
        uint256 proposal2 = treasury.createProposal(
            beneficiary,
            150 ether,
            "Payment 2",
            ""
        );

        vm.prank(treasurer);
        treasury.approveProposal(proposal2);

        vm.prank(treasurer);
        vm.expectRevert(DAOTreasury.ExceedsDailyLimit.selector);
        treasury.executeProposal(proposal2, "");
    }

    function testCancelProposal_Proposer() public {
        vm.prank(member1);
        uint256 proposalId = treasury.createProposal(
            beneficiary,
            10 ether,
            "Payment",
            ""
        );

        vm.prank(member1);
        treasury.cancelProposal(proposalId);

        DAOTreasury.SpendingProposal memory proposal = treasury.getProposal(proposalId);
        assertEq(uint(proposal.status), uint(DAOTreasury.ProposalStatus.Cancelled));
    }

    function testCancelProposal_Treasurer() public {
        vm.prank(member1);
        uint256 proposalId = treasury.createProposal(
            beneficiary,
            10 ether,
            "Payment",
            ""
        );

        vm.prank(treasurer);
        treasury.cancelProposal(proposalId);

        DAOTreasury.SpendingProposal memory proposal = treasury.getProposal(proposalId);
        assertEq(uint(proposal.status), uint(DAOTreasury.ProposalStatus.Cancelled));
    }

    function testCancelProposal_Unauthorized() public {
        vm.prank(member1);
        uint256 proposalId = treasury.createProposal(
            beneficiary,
            10 ether,
            "Payment",
            ""
        );

        vm.prank(member2);
        vm.expectRevert(DAOTreasury.Unauthorized.selector);
        treasury.cancelProposal(proposalId);
    }

    function testAllocateBudget() public {
        vm.prank(treasurer);
        treasury.allocateBudget("marketing", 100 ether);

        DAOTreasury.Budget memory budget = treasury.getBudget("marketing");
        assertEq(budget.allocated, 100 ether);
        assertEq(budget.spent, 0);
        assertTrue(budget.active);
    }

    function testBudgetExceeded() public {
        // Allocate budget
        vm.prank(treasurer);
        treasury.allocateBudget("marketing", 50 ether);

        // Try to create proposal exceeding budget
        vm.prank(member1);
        vm.expectRevert(DAOTreasury.BudgetExceeded.selector);
        treasury.createProposal(
            beneficiary,
            60 ether,
            "Exceeds budget",
            "marketing"
        );
    }

    function testBudgetTracking() public {
        // Allocate budget
        vm.prank(treasurer);
        treasury.allocateBudget("development", 100 ether);

        // Create and execute proposal
        vm.prank(member1);
        uint256 proposalId = treasury.createProposal(
            beneficiary,
            30 ether,
            "Dev payment",
            "development"
        );

        vm.prank(treasurer);
        treasury.approveProposal(proposalId);

        vm.prank(treasurer);
        treasury.executeProposal(proposalId, "development");

        // Verify budget updated
        DAOTreasury.Budget memory budget = treasury.getBudget("development");
        assertEq(budget.spent, 30 ether);
        assertEq(budget.allocated, 100 ether);
    }

    function testUpdateLimits() public {
        vm.prank(admin);
        treasury.updateLimits(200 ether, 1000 ether);

        assertEq(treasury.maxSingleSpend(), 200 ether);
        assertEq(treasury.dailySpendLimit(), 1000 ether);
    }

    function testUpdateLimits_OnlyAdmin() public {
        vm.prank(treasurer);
        vm.expectRevert();
        treasury.updateLimits(200 ether, 1000 ether);
    }

    function testDailySpendRemaining() public {
        // Initially full limit
        assertEq(treasury.dailySpendRemaining(), 500 ether);

        // Execute proposal
        vm.prank(member1);
        uint256 proposalId = treasury.createProposal(
            beneficiary,
            100 ether,
            "Payment",
            ""
        );

        vm.prank(treasurer);
        treasury.approveProposal(proposalId);

        vm.prank(treasurer);
        treasury.executeProposal(proposalId, "");

        // Remaining reduced
        assertEq(treasury.dailySpendRemaining(), 400 ether);
    }

    function testDailyLimitReset() public {
        // Execute proposal
        vm.prank(member1);
        uint256 proposal1 = treasury.createProposal(
            beneficiary,
            400 ether,
            "Payment 1",
            ""
        );

        vm.prank(treasurer);
        treasury.approveProposal(proposal1);

        vm.prank(treasurer);
        treasury.executeProposal(proposal1, "");

        assertEq(treasury.dailySpendRemaining(), 100 ether);

        // Advance 1 day
        vm.warp(block.timestamp + 1 days + 1);

        // Daily limit should reset
        assertEq(treasury.dailySpendRemaining(), 500 ether);
    }
}
