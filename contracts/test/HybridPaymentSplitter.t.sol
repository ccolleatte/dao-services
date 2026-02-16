// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/HybridPaymentSplitter.sol";
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

contract HybridPaymentSplitterTest is Test {
    HybridPaymentSplitter public splitter;
    MockDAOSToken public daosToken;

    // Actors
    address public admin = address(0x1);
    address payable public humanContributor = payable(address(0x2));
    address payable public aiContributor = payable(address(0x3));
    address payable public computeContributor = payable(address(0x4));
    address public meterOracle = address(0x5);
    address public unauthorized = address(0x99);

    // Constants
    uint256 public constant MISSION_ID = 123;
    uint256 public constant TOTAL_BUDGET = 10000 ether;

    function setUp() public {
        // Deploy contracts
        daosToken = new MockDAOSToken();

        vm.prank(admin);
        splitter = new HybridPaymentSplitter(MISSION_ID, address(daosToken), admin);

        // Fund splitter contract
        daosToken.mint(address(splitter), TOTAL_BUDGET);

        // Grant METER_ROLE to oracle
        vm.prank(admin);
        splitter.grantMeterRole(meterOracle);
    }

    // ===== Constructor & Initial State =====

    function test_ConstructorSetsRoles() public {
        assertTrue(splitter.hasRole(splitter.DEFAULT_ADMIN_ROLE(), admin));
        assertTrue(splitter.hasRole(splitter.ADMIN_ROLE(), admin));
    }

    function test_ConstructorSetsDefaultPricing() public {
        (uint256 pricePerMTokenLLM, uint256 pricePerGPUHour) = splitter.getPricing();
        assertEq(pricePerMTokenLLM, 20 ether); // 20 DAOS per 1M tokens
        assertEq(pricePerGPUHour, 10 ether); // 10 DAOS per GPU-hour
    }

    function test_ConstructorSetsMissionId() public {
        assertEq(splitter.missionId(), MISSION_ID);
    }

    // ===== Add Contributor =====

    function test_AddContributor() public {
        vm.prank(admin);
        splitter.addContributor(humanContributor, HybridPaymentSplitter.ContributorType.Human, 5000); // 50%

        assertEq(splitter.getContributorCount(), 1);

        (address account, HybridPaymentSplitter.ContributorType contributorType, uint256 percentageBps, uint256 totalEarned) =
            splitter.getContributor(0);

        assertEq(account, humanContributor);
        assertEq(uint256(contributorType), uint256(HybridPaymentSplitter.ContributorType.Human));
        assertEq(percentageBps, 5000);
        assertEq(totalEarned, 0);
    }

    function test_AddContributorRevertsIfUnauthorized() public {
        vm.prank(unauthorized);
        vm.expectRevert();
        splitter.addContributor(humanContributor, HybridPaymentSplitter.ContributorType.Human, 5000);
    }

    function test_AddContributorRevertsIfInvalidPercentage() public {
        vm.prank(admin);
        vm.expectRevert(HybridPaymentSplitter.InvalidPercentage.selector);
        splitter.addContributor(humanContributor, HybridPaymentSplitter.ContributorType.Human, 10001); // >100%
    }

    // ===== Usage Reporting =====

    function test_ReportUsage() public {
        vm.prank(meterOracle);
        splitter.reportUsage(1000000, 1500); // 1M tokens, 1.5 GPU-hours (1500/1000)

        (uint256 llmTokensUsed, uint256 gpuHoursUsed, uint256 lastUpdated) = splitter.getUsageMetrics();

        assertEq(llmTokensUsed, 1000000);
        assertEq(gpuHoursUsed, 1500);
        assertEq(lastUpdated, block.timestamp);
    }

    function test_ReportUsageRevertsIfUnauthorized() public {
        vm.prank(unauthorized);
        vm.expectRevert();
        splitter.reportUsage(1000000, 1500);
    }

    function test_ReportUsageAccumulates() public {
        vm.prank(meterOracle);
        splitter.reportUsage(500000, 1000); // First report

        vm.prank(meterOracle);
        splitter.reportUsage(300000, 500); // Second report

        (uint256 llmTokensUsed, uint256 gpuHoursUsed,) = splitter.getUsageMetrics();

        assertEq(llmTokensUsed, 800000); // 500k + 300k
        assertEq(gpuHoursUsed, 1500); // 1000 + 500
    }

    // ===== Payment Distribution - Human Contributor =====

    function test_DistributePaymentHumanContributor() public {
        // Add human contributor (50%)
        vm.prank(admin);
        splitter.addContributor(humanContributor, HybridPaymentSplitter.ContributorType.Human, 5000);

        uint256 balanceBefore = daosToken.balanceOf(humanContributor);

        // Distribute 1000 DAOS
        vm.prank(admin);
        splitter.distributePayment(1000 ether);

        uint256 balanceAfter = daosToken.balanceOf(humanContributor);

        // Human gets fixed 50% = 500 DAOS
        assertEq(balanceAfter - balanceBefore, 500 ether);
    }

    // ===== Payment Distribution - AI Contributor =====

    function test_DistributePaymentAIContributor() public {
        // Add AI contributor (10% fixed)
        vm.prank(admin);
        splitter.addContributor(aiContributor, HybridPaymentSplitter.ContributorType.AI, 1000);

        // Report LLM usage: 2M tokens
        vm.prank(meterOracle);
        splitter.reportUsage(2000000, 0);

        uint256 balanceBefore = daosToken.balanceOf(aiContributor);

        // Distribute 1000 DAOS
        vm.prank(admin);
        splitter.distributePayment(1000 ether);

        uint256 balanceAfter = daosToken.balanceOf(aiContributor);

        // AI gets: usage cost + fixed %
        // Usage cost = (2M / 1M) * 20 DAOS = 40 DAOS
        // Fixed % = 1000 DAOS * 10% = 100 DAOS
        // Total = 140 DAOS
        assertEq(balanceAfter - balanceBefore, 140 ether);
    }

    // ===== Payment Distribution - Compute Contributor =====

    function test_DistributePaymentComputeContributor() public {
        // Add compute contributor (5% fixed)
        vm.prank(admin);
        splitter.addContributor(computeContributor, HybridPaymentSplitter.ContributorType.Compute, 500);

        // Report GPU usage: 3.5 GPU-hours (3500 / 1000)
        vm.prank(meterOracle);
        splitter.reportUsage(0, 3500);

        uint256 balanceBefore = daosToken.balanceOf(computeContributor);

        // Distribute 1000 DAOS
        vm.prank(admin);
        splitter.distributePayment(1000 ether);

        uint256 balanceAfter = daosToken.balanceOf(computeContributor);

        // Compute gets: usage cost + fixed %
        // Usage cost = (3500 / 1000) * 10 DAOS = 35 DAOS
        // Fixed % = 1000 DAOS * 5% = 50 DAOS
        // Total = 85 DAOS
        assertEq(balanceAfter - balanceBefore, 85 ether);
    }

    // ===== Payment Distribution - Multiple Contributors =====

    function test_DistributePaymentMultipleContributors() public {
        // Add all 3 contributor types
        vm.startPrank(admin);
        splitter.addContributor(humanContributor, HybridPaymentSplitter.ContributorType.Human, 5000); // 50%
        splitter.addContributor(aiContributor, HybridPaymentSplitter.ContributorType.AI, 1000); // 10%
        splitter.addContributor(computeContributor, HybridPaymentSplitter.ContributorType.Compute, 500); // 5%
        vm.stopPrank();

        // Report usage
        vm.prank(meterOracle);
        splitter.reportUsage(1000000, 2000); // 1M tokens, 2 GPU-hours

        uint256 humanBalanceBefore = daosToken.balanceOf(humanContributor);
        uint256 aiBalanceBefore = daosToken.balanceOf(aiContributor);
        uint256 computeBalanceBefore = daosToken.balanceOf(computeContributor);

        // Distribute 1000 DAOS
        vm.prank(admin);
        splitter.distributePayment(1000 ether);

        // Human: 50% of 1000 = 500 DAOS
        assertEq(daosToken.balanceOf(humanContributor) - humanBalanceBefore, 500 ether);

        // AI: (1M/1M)*20 + 10% of 1000 = 20 + 100 = 120 DAOS
        assertEq(daosToken.balanceOf(aiContributor) - aiBalanceBefore, 120 ether);

        // Compute: (2000/1000)*10 + 5% of 1000 = 20 + 50 = 70 DAOS
        assertEq(daosToken.balanceOf(computeContributor) - computeBalanceBefore, 70 ether);
    }

    // ===== Payment Distribution - Insufficient Funds =====

    function test_DistributePaymentRevertsIfInsufficientFunds() public {
        vm.prank(admin);
        splitter.addContributor(humanContributor, HybridPaymentSplitter.ContributorType.Human, 5000);

        vm.prank(admin);
        vm.expectRevert(HybridPaymentSplitter.InsufficientFunds.selector);
        splitter.distributePayment(TOTAL_BUDGET + 1 ether); // More than available
    }

    function test_DistributePaymentRevertsIfUnauthorized() public {
        vm.prank(unauthorized);
        vm.expectRevert();
        splitter.distributePayment(100 ether);
    }

    // ===== Payment Distribution - Dust Handling =====

    function test_DistributePaymentHandlesDust() public {
        // Add contributor with percentage that creates rounding
        vm.prank(admin);
        splitter.addContributor(humanContributor, HybridPaymentSplitter.ContributorType.Human, 3333); // 33.33%

        uint256 adminBalanceBefore = daosToken.balanceOf(admin);

        // Distribute amount that creates dust
        vm.prank(admin);
        splitter.distributePayment(100 ether);

        // Contributor gets 33.33 DAOS (rounded down)
        // Dust (remaining) goes to admin
        uint256 contributorReceived = (100 ether * 3333) / 10000;
        uint256 expectedDust = 100 ether - contributorReceived;

        assertEq(daosToken.balanceOf(admin) - adminBalanceBefore, expectedDust);
    }

    // ===== Usage Cost Calculations =====

    function test_CalculateAIUsageCost() public {
        // Report 5M LLM tokens
        vm.prank(meterOracle);
        splitter.reportUsage(5000000, 0);

        // Cost = (5M / 1M) * 20 DAOS = 100 DAOS
        uint256 cost = splitter.calculateAIUsageCost();
        assertEq(cost, 100 ether);
    }

    function test_CalculateComputeUsageCost() public {
        // Report 4.5 GPU-hours (4500 / 1000)
        vm.prank(meterOracle);
        splitter.reportUsage(0, 4500);

        // Cost = (4500 / 1000) * 10 DAOS = 45 DAOS
        uint256 cost = splitter.calculateComputeUsageCost();
        assertEq(cost, 45 ether);
    }

    function test_CalculateAIUsageCostZero() public {
        // No usage reported
        uint256 cost = splitter.calculateAIUsageCost();
        assertEq(cost, 0);
    }

    function test_CalculateComputeUsageCostZero() public {
        // No usage reported
        uint256 cost = splitter.calculateComputeUsageCost();
        assertEq(cost, 0);
    }

    // ===== Pricing Updates =====

    function test_UpdatePricing() public {
        vm.prank(admin);
        splitter.updatePricing(50 ether, 25 ether);

        (uint256 pricePerMTokenLLM, uint256 pricePerGPUHour) = splitter.getPricing();

        assertEq(pricePerMTokenLLM, 50 ether);
        assertEq(pricePerGPUHour, 25 ether);
    }

    function test_UpdatePricingRevertsIfUnauthorized() public {
        vm.prank(unauthorized);
        vm.expectRevert();
        splitter.updatePricing(50 ether, 25 ether);
    }

    function test_UpdatePricingAffectsDistribution() public {
        // Add AI contributor
        vm.prank(admin);
        splitter.addContributor(aiContributor, HybridPaymentSplitter.ContributorType.AI, 0); // 0% fixed

        // Report 1M tokens
        vm.prank(meterOracle);
        splitter.reportUsage(1000000, 0);

        // Update pricing to 100 DAOS per 1M tokens
        vm.prank(admin);
        splitter.updatePricing(100 ether, 10 ether);

        uint256 balanceBefore = daosToken.balanceOf(aiContributor);

        // Distribute
        vm.prank(admin);
        splitter.distributePayment(1000 ether);

        uint256 balanceAfter = daosToken.balanceOf(aiContributor);

        // AI gets: (1M/1M) * 100 DAOS + 0% fixed = 100 DAOS
        assertEq(balanceAfter - balanceBefore, 100 ether);
    }

    // ===== Role Management =====

    function test_GrantMeterRole() public {
        address newOracle = address(0x10);

        vm.prank(admin);
        splitter.grantMeterRole(newOracle);

        assertTrue(splitter.hasRole(splitter.METER_ROLE(), newOracle));
    }

    function test_RevokeMeterRole() public {
        vm.prank(admin);
        splitter.revokeMeterRole(meterOracle);

        assertFalse(splitter.hasRole(splitter.METER_ROLE(), meterOracle));
    }

    function test_GrantMeterRoleRevertsIfUnauthorized() public {
        vm.prank(unauthorized);
        vm.expectRevert();
        splitter.grantMeterRole(address(0x10));
    }

    function test_RevokeMeterRoleRevertsIfUnauthorized() public {
        vm.prank(unauthorized);
        vm.expectRevert();
        splitter.revokeMeterRole(meterOracle);
    }

    // ===== Emergency Withdraw =====

    function test_EmergencyWithdraw() public {
        uint256 balanceBefore = daosToken.balanceOf(admin);

        vm.prank(admin);
        splitter.emergencyWithdraw();

        uint256 balanceAfter = daosToken.balanceOf(admin);

        assertEq(balanceAfter - balanceBefore, TOTAL_BUDGET);
        assertEq(daosToken.balanceOf(address(splitter)), 0);
    }

    function test_EmergencyWithdrawRevertsIfNoFunds() public {
        // Withdraw all funds first
        vm.prank(admin);
        splitter.emergencyWithdraw();

        // Try to withdraw again
        vm.prank(admin);
        vm.expectRevert(HybridPaymentSplitter.NoFundsToWithdraw.selector);
        splitter.emergencyWithdraw();
    }

    function test_EmergencyWithdrawRevertsIfUnauthorized() public {
        vm.prank(unauthorized);
        vm.expectRevert();
        splitter.emergencyWithdraw();
    }

    // ===== Usage Metrics Reset =====

    function test_ResetUsageMetrics() public {
        // Report usage
        vm.prank(meterOracle);
        splitter.reportUsage(1000000, 2000);

        // Reset
        vm.prank(admin);
        splitter.resetUsageMetrics();

        (uint256 llmTokensUsed, uint256 gpuHoursUsed, uint256 lastUpdated) = splitter.getUsageMetrics();

        assertEq(llmTokensUsed, 0);
        assertEq(gpuHoursUsed, 0);
        assertEq(lastUpdated, block.timestamp);
    }

    function test_ResetUsageMetricsRevertsIfUnauthorized() public {
        vm.prank(unauthorized);
        vm.expectRevert();
        splitter.resetUsageMetrics();
    }

    // ===== View Functions =====

    function test_GetContributorCount() public {
        assertEq(splitter.getContributorCount(), 0);

        vm.prank(admin);
        splitter.addContributor(humanContributor, HybridPaymentSplitter.ContributorType.Human, 5000);

        assertEq(splitter.getContributorCount(), 1);
    }

    function test_GetContributorRevertsIfInvalidIndex() public {
        vm.expectRevert();
        splitter.getContributor(0); // No contributors yet
    }

    function test_GetUsageMetrics() public {
        (uint256 llmTokensUsed, uint256 gpuHoursUsed, uint256 lastUpdated) = splitter.getUsageMetrics();

        assertEq(llmTokensUsed, 0);
        assertEq(gpuHoursUsed, 0);
        assertEq(lastUpdated, 0); // Not set yet
    }

    function test_GetPricing() public {
        (uint256 pricePerMTokenLLM, uint256 pricePerGPUHour) = splitter.getPricing();

        assertEq(pricePerMTokenLLM, 20 ether);
        assertEq(pricePerGPUHour, 10 ether);
    }

    // ===== Integration Test =====

    function test_FullWorkflow() public {
        // 1. Add all contributors
        vm.startPrank(admin);
        splitter.addContributor(humanContributor, HybridPaymentSplitter.ContributorType.Human, 4000); // 40%
        splitter.addContributor(aiContributor, HybridPaymentSplitter.ContributorType.AI, 1500); // 15%
        splitter.addContributor(computeContributor, HybridPaymentSplitter.ContributorType.Compute, 1000); // 10%
        vm.stopPrank();

        // 2. Report usage
        vm.prank(meterOracle);
        splitter.reportUsage(3000000, 5000); // 3M tokens, 5 GPU-hours

        // 3. Distribute payment (1000 DAOS)
        vm.prank(admin);
        splitter.distributePayment(1000 ether);

        // 4. Verify distributions
        // Human: 40% of 1000 = 400 DAOS
        (,,, uint256 humanEarned) = splitter.getContributor(0);
        assertEq(humanEarned, 400 ether);

        // AI: (3M/1M)*20 + 15% of 1000 = 60 + 150 = 210 DAOS
        (,,, uint256 aiEarned) = splitter.getContributor(1);
        assertEq(aiEarned, 210 ether);

        // Compute: (5000/1000)*10 + 10% of 1000 = 50 + 100 = 150 DAOS
        (,,, uint256 computeEarned) = splitter.getContributor(2);
        assertEq(computeEarned, 150 ether);

        // 5. Reset usage for next period
        vm.prank(admin);
        splitter.resetUsageMetrics();

        (uint256 llmTokensUsed, uint256 gpuHoursUsed,) = splitter.getUsageMetrics();
        assertEq(llmTokensUsed, 0);
        assertEq(gpuHoursUsed, 0);

        // 6. Distribute again (should only use fixed percentages now)
        vm.prank(admin);
        splitter.distributePayment(500 ether);

        // Human: 40% of 500 = 200 DAOS (total: 600)
        (,,, humanEarned) = splitter.getContributor(0);
        assertEq(humanEarned, 600 ether);

        // AI: 0 usage + 15% of 500 = 75 DAOS (total: 285)
        (,,, aiEarned) = splitter.getContributor(1);
        assertEq(aiEarned, 285 ether);

        // Compute: 0 usage + 10% of 500 = 50 DAOS (total: 200)
        (,,, computeEarned) = splitter.getContributor(2);
        assertEq(computeEarned, 200 ether);
    }
}
