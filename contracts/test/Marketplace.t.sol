// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/ServiceMarketplace.sol";
import "../src/MissionEscrow.sol";
import "../src/HybridPaymentSplitter.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

// Mock DAOS token
contract MockDAOS is ERC20 {
    constructor() ERC20("DAOS Token", "DAOS") {
        _mint(msg.sender, 1_000_000 ether);
    }

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}

// Mock Membership contract
contract MockMembership {
    mapping(address => uint8) public ranks;
    mapping(address => string[]) public skills;
    mapping(address => uint256) public completedMissions;
    mapping(address => uint256) public averageRatings;

    function setRank(address user, uint8 rank) external {
        ranks[user] = rank;
    }

    function setSkills(address user, string[] memory userSkills) external {
        skills[user] = userSkills;
    }

    function setTrackRecord(address user, uint256 missions, uint256 rating) external {
        completedMissions[user] = missions;
        averageRatings[user] = rating;
    }

    function getRank(address user) external view returns (uint8) {
        return ranks[user];
    }

    function getSkills(address user) external view returns (string[] memory) {
        return skills[user];
    }

    function getTrackRecord(address user) external view returns (uint256, uint256) {
        return (completedMissions[user], averageRatings[user]);
    }

    function getEligibleJurors(address, address) external pure returns (address[] memory) {
        address[] memory jurors = new address[](10);
        jurors[0] = address(0x1001);
        jurors[1] = address(0x1002);
        jurors[2] = address(0x1003);
        jurors[3] = address(0x1004);
        jurors[4] = address(0x1005);
        jurors[5] = address(0x1006);
        jurors[6] = address(0x1007);
        jurors[7] = address(0x1008);
        jurors[8] = address(0x1009);
        jurors[9] = address(0x100A);
        return jurors;
    }
}

contract ServiceMarketplaceTest is Test {
    ServiceMarketplace public marketplace;
    MockDAOS public daosToken;
    MockMembership public membership;

    address public admin = address(0x1);
    address public client = address(0x2);
    address public consultant1 = address(0x3);
    address public consultant2 = address(0x4);

    function setUp() public {
        daosToken = new MockDAOS();
        membership = new MockMembership();

        marketplace = new ServiceMarketplace(
            address(daosToken),
            address(membership),
            admin
        );

        // Mint tokens to client
        daosToken.mint(client, 10_000 ether);

        // Setup consultant ranks
        membership.setRank(consultant1, 3);
        membership.setRank(consultant2, 4);

        // Setup consultant skills
        string[] memory skills1 = new string[](2);
        skills1[0] = "solidity";
        skills1[1] = "security";
        membership.setSkills(consultant1, skills1);

        string[] memory skills2 = new string[](3);
        skills2[0] = "solidity";
        skills2[1] = "frontend";
        skills2[2] = "security";
        membership.setSkills(consultant2, skills2);

        // Setup track records
        membership.setTrackRecord(consultant1, 5, 85); // 5 missions, 85% rating
        membership.setTrackRecord(consultant2, 10, 92); // 10 missions, 92% rating
    }

    // Test 1: Create mission
    function testCreateMission() public {
        string[] memory requiredSkills = new string[](2);
        requiredSkills[0] = "solidity";
        requiredSkills[1] = "security";

        vm.startPrank(client);
        daosToken.approve(address(marketplace), 1000 ether);

        uint256 missionId = marketplace.createMission(
            "Smart Contract Audit",
            1000 ether,
            2,
            requiredSkills
        );

        assertEq(missionId, 1);

        (
            uint256 id,
            address missionClient,
            string memory title,
            uint256 budget,
            uint8 minRank,
            ServiceMarketplace.MissionStatus status,
            ,
            ,
        ) = marketplace.missions(missionId);

        assertEq(id, 1);
        assertEq(missionClient, client);
        assertEq(title, "Smart Contract Audit");
        assertEq(budget, 1000 ether);
        assertEq(minRank, 2);
        assertEq(uint256(status), uint256(ServiceMarketplace.MissionStatus.Active));

        vm.stopPrank();
    }

    // Test 2: Apply to mission
    function testApplyToMission() public {
        // Create mission first
        string[] memory requiredSkills = new string[](2);
        requiredSkills[0] = "solidity";
        requiredSkills[1] = "security";

        vm.startPrank(client);
        daosToken.approve(address(marketplace), 1000 ether);
        uint256 missionId = marketplace.createMission(
            "Smart Contract Audit",
            1000 ether,
            2,
            requiredSkills
        );
        vm.stopPrank();

        // Consultant applies
        vm.prank(consultant1);
        uint256 appId = marketplace.applyToMission(
            missionId,
            "Qm...", // IPFS hash
            800 ether
        );

        assertEq(appId, 0);

        (
            uint256 appMissionId,
            address appConsultant,
            string memory proposal,
            uint256 proposedBudget,
            ,
            uint256 matchScore
        ) = marketplace.applications(appId);

        assertEq(appMissionId, missionId);
        assertEq(appConsultant, consultant1);
        assertEq(proposal, "Qm...");
        assertEq(proposedBudget, 800 ether);
        assertGt(matchScore, 0);
    }

    // Test 3: Calculate match score
    function testCalculateMatchScore() public {
        string[] memory requiredSkills = new string[](2);
        requiredSkills[0] = "solidity";
        requiredSkills[1] = "security";

        vm.startPrank(client);
        daosToken.approve(address(marketplace), 1000 ether);
        uint256 missionId = marketplace.createMission(
            "Smart Contract Audit",
            1000 ether,
            2,
            requiredSkills
        );
        vm.stopPrank();

        // Test consultant 1 (rank 3, 2/2 skills match, 5 missions)
        uint256 score1 = marketplace.calculateMatchScore(missionId, consultant1, 800 ether, 3);

        // Test consultant 2 (rank 4, 2/2 skills match, 10 missions)
        uint256 score2 = marketplace.calculateMatchScore(missionId, consultant2, 900 ether, 4);

        // Consultant 2 should have higher score (higher rank + more missions)
        assertGt(score2, score1);
        assertLe(score1, 100);
        assertLe(score2, 100);
    }

    // Test 4: Select consultant
    function testSelectConsultant() public {
        string[] memory requiredSkills = new string[](2);
        requiredSkills[0] = "solidity";
        requiredSkills[1] = "security";

        vm.startPrank(client);
        daosToken.approve(address(marketplace), 1000 ether);
        uint256 missionId = marketplace.createMission(
            "Smart Contract Audit",
            1000 ether,
            2,
            requiredSkills
        );
        vm.stopPrank();

        vm.prank(consultant1);
        marketplace.applyToMission(missionId, "Qm...", 800 ether);

        vm.prank(client);
        marketplace.selectConsultant(missionId, consultant1);

        (
            ,
            ,
            ,
            ,
            ,
            ServiceMarketplace.MissionStatus status,
            address selectedConsultant,
            ,
        ) = marketplace.missions(missionId);

        assertEq(uint256(status), uint256(ServiceMarketplace.MissionStatus.OnHold));
        assertEq(selectedConsultant, consultant1);
    }

    // Test 5: Revert if insufficient rank
    function testRevertInsufficientRank() public {
        string[] memory requiredSkills = new string[](2);
        requiredSkills[0] = "solidity";
        requiredSkills[1] = "security";

        vm.startPrank(client);
        daosToken.approve(address(marketplace), 1000 ether);
        uint256 missionId = marketplace.createMission(
            "Smart Contract Audit",
            1000 ether,
            4, // Require rank 4
            requiredSkills
        );
        vm.stopPrank();

        // Consultant1 has rank 3, should fail
        vm.expectRevert(ServiceMarketplace.InsufficientRank.selector);
        vm.prank(consultant1);
        marketplace.applyToMission(missionId, "Qm...", 800 ether);
    }

    // Test 6: Revert if already applied
    function testRevertAlreadyApplied() public {
        string[] memory requiredSkills = new string[](2);
        requiredSkills[0] = "solidity";
        requiredSkills[1] = "security";

        vm.startPrank(client);
        daosToken.approve(address(marketplace), 1000 ether);
        uint256 missionId = marketplace.createMission(
            "Smart Contract Audit",
            1000 ether,
            2,
            requiredSkills
        );
        vm.stopPrank();

        vm.startPrank(consultant1);
        marketplace.applyToMission(missionId, "Qm...", 800 ether);

        // Try to apply again
        vm.expectRevert(ServiceMarketplace.AlreadyApplied.selector);
        marketplace.applyToMission(missionId, "Qm...", 800 ether);
        vm.stopPrank();
    }
}

contract MissionEscrowTest is Test {
    MissionEscrow public escrow;
    MockDAOS public daosToken;
    MockMembership public membership;

    address public client = address(0x2);
    address public consultant = address(0x3);

    function setUp() public {
        daosToken = new MockDAOS();
        membership = new MockMembership();

        // Create escrow with 1000 DAOS budget
        escrow = new MissionEscrow(
            1,
            client,
            consultant,
            1000 ether,
            address(daosToken),
            address(membership)
        );

        // Transfer budget to escrow
        daosToken.transfer(address(escrow), 1000 ether);

        // Fund client with ETH for dispute stakes
        vm.deal(client, 200 ether);
    }

    // Test 7: Add milestone
    function testAddMilestone() public {
        vm.prank(client);
        escrow.addMilestone(
            "Setup smart contract structure",
            200 ether,
            block.timestamp + 7 days
        );

        MissionEscrow.Milestone memory milestone = escrow.getMilestone(0);

        assertEq(milestone.id, 0);
        assertEq(milestone.description, "Setup smart contract structure");
        assertEq(milestone.amount, 200 ether);
        assertEq(uint256(milestone.status), uint256(MissionEscrow.MilestoneStatus.Pending));
    }

    // Test 8: Submit milestone
    function testSubmitMilestone() public {
        vm.prank(client);
        escrow.addMilestone("Milestone 1", 200 ether, block.timestamp + 7 days);

        vm.prank(consultant);
        escrow.submitMilestone(0, "QmDeliverableHash...");

        MissionEscrow.Milestone memory milestone = escrow.getMilestone(0);

        assertEq(uint256(milestone.status), uint256(MissionEscrow.MilestoneStatus.Submitted));
        assertEq(milestone.deliverable, "QmDeliverableHash...");
    }

    // Test 9: Approve milestone
    function testApproveMilestone() public {
        vm.prank(client);
        escrow.addMilestone("Milestone 1", 200 ether, block.timestamp + 7 days);

        vm.prank(consultant);
        escrow.submitMilestone(0, "QmDeliverableHash...");

        uint256 balanceBefore = daosToken.balanceOf(consultant);

        vm.prank(client);
        escrow.approveMilestone(0);

        uint256 balanceAfter = daosToken.balanceOf(consultant);

        MissionEscrow.Milestone memory milestone = escrow.getMilestone(0);

        assertEq(uint256(milestone.status), uint256(MissionEscrow.MilestoneStatus.Approved));
        assertEq(balanceAfter - balanceBefore, 200 ether);
        assertEq(escrow.releasedFunds(), 200 ether);
    }

    // Test 10: Reject milestone
    function testRejectMilestone() public {
        vm.prank(client);
        escrow.addMilestone("Milestone 1", 200 ether, block.timestamp + 7 days);

        vm.prank(consultant);
        escrow.submitMilestone(0, "QmDeliverableHash...");

        vm.prank(client);
        escrow.rejectMilestone(0, "Does not meet requirements");

        MissionEscrow.Milestone memory milestone = escrow.getMilestone(0);

        assertEq(uint256(milestone.status), uint256(MissionEscrow.MilestoneStatus.Rejected));
    }

    // Test 11: Sequential milestone validation
    function testSequentialMilestones() public {
        // Add 2 milestones
        vm.startPrank(client);
        escrow.addMilestone("Milestone 1", 200 ether, block.timestamp + 7 days);
        escrow.addMilestone("Milestone 2", 300 ether, block.timestamp + 14 days);
        vm.stopPrank();

        // Try to submit milestone 2 before milestone 1 is approved
        vm.expectRevert("Previous milestone must be approved");
        vm.prank(consultant);
        escrow.submitMilestone(1, "QmDeliverableHash2...");

        // Submit and approve milestone 1
        vm.prank(consultant);
        escrow.submitMilestone(0, "QmDeliverableHash1...");

        vm.prank(client);
        escrow.approveMilestone(0);

        // Now milestone 2 can be submitted
        vm.prank(consultant);
        escrow.submitMilestone(1, "QmDeliverableHash2...");

        MissionEscrow.Milestone memory milestone = escrow.getMilestone(1);

        assertEq(uint256(milestone.status), uint256(MissionEscrow.MilestoneStatus.Submitted));
    }

    // Test 12: Auto-release milestone
    function testAutoReleaseMilestone() public {
        vm.prank(client);
        escrow.addMilestone("Milestone 1", 200 ether, block.timestamp + 7 days);

        vm.prank(consultant);
        escrow.submitMilestone(0, "QmDeliverableHash...");

        // Fast forward 7 days
        vm.warp(block.timestamp + 7 days + 1);

        uint256 balanceBefore = daosToken.balanceOf(consultant);

        escrow.autoReleaseMilestone(0);

        uint256 balanceAfter = daosToken.balanceOf(consultant);

        assertEq(balanceAfter - balanceBefore, 200 ether);
    }

    // Test 13: Raise dispute
    function testRaiseDispute() public {
        vm.prank(client);
        escrow.addMilestone("Milestone 1", 200 ether, block.timestamp + 7 days);

        vm.prank(consultant);
        escrow.submitMilestone(0, "QmDeliverableHash...");

        // Client raises dispute
        vm.prank(client);
        uint256 disputeId = escrow.raiseDispute{value: 100 ether}(
            0,
            "Deliverable does not match requirements"
        );

        assertEq(disputeId, 0);

        MissionEscrow.Milestone memory milestone = escrow.getMilestone(0);

        assertEq(uint256(milestone.status), uint256(MissionEscrow.MilestoneStatus.Disputed));
    }

    // Test 14: Vote on dispute
    function testVoteOnDispute() public {
        vm.prank(client);
        escrow.addMilestone("Milestone 1", 200 ether, block.timestamp + 7 days);

        vm.prank(consultant);
        escrow.submitMilestone(0, "QmDeliverableHash...");

        vm.prank(client);
        uint256 disputeId = escrow.raiseDispute{value: 100 ether}(0, "Issue");

        // Get jurors
        address[] memory jurors = escrow.getDisputeJurors(disputeId);

        // 3 jurors vote for consultant
        vm.prank(jurors[0]);
        escrow.voteOnDispute(disputeId, true);

        vm.prank(jurors[1]);
        escrow.voteOnDispute(disputeId, true);

        // This vote should trigger resolution (3/5 majority)
        vm.prank(jurors[2]);
        escrow.voteOnDispute(disputeId, true);

        // Check milestone approved
        MissionEscrow.Milestone memory milestone = escrow.getMilestone(0);

        assertEq(uint256(milestone.status), uint256(MissionEscrow.MilestoneStatus.Approved));
    }
}

contract HybridPaymentSplitterTest is Test {
    HybridPaymentSplitter public splitter;
    MockDAOS public daosToken;

    address public admin = address(0x1);
    address public human1 = address(0x2);
    address public ai1 = address(0x3);
    address public compute1 = address(0x4);
    address public meter = address(0x5);

    function setUp() public {
        daosToken = new MockDAOS();

        splitter = new HybridPaymentSplitter(
            1,
            address(daosToken),
            admin
        );

        // Grant meter role
        vm.prank(admin);
        splitter.grantMeterRole(meter);

        // Transfer funds to splitter
        daosToken.transfer(address(splitter), 10_000 ether);
    }

    // Test 15: Add contributors
    function testAddContributors() public {
        vm.startPrank(admin);

        splitter.addContributor(payable(human1), HybridPaymentSplitter.ContributorType.Human, 4000); // 40%
        splitter.addContributor(payable(ai1), HybridPaymentSplitter.ContributorType.AI, 2750); // 27.5%
        splitter.addContributor(payable(compute1), HybridPaymentSplitter.ContributorType.Compute, 1000); // 10%

        vm.stopPrank();

        assertEq(splitter.getContributorCount(), 3);

        (address account, , uint256 percentageBps, ) = splitter.getContributor(0);
        assertEq(account, human1);
        assertEq(percentageBps, 4000);
    }

    // Test 16: Report usage
    function testReportUsage() public {
        vm.prank(meter);
        splitter.reportUsage(500_000, 1500); // 500K tokens, 1.5 GPU-hours

        (uint256 llmTokens, uint256 gpuHours, ) = splitter.getUsageMetrics();

        assertEq(llmTokens, 500_000);
        assertEq(gpuHours, 1500);
    }

    // Test 17: Calculate AI usage cost
    function testCalculateAIUsageCost() public {
        vm.prank(meter);
        splitter.reportUsage(1_000_000, 0); // 1M tokens

        uint256 cost = splitter.calculateAIUsageCost();

        // Default pricing: 20 DAOS per 1M tokens
        assertEq(cost, 20 ether);
    }

    // Test 18: Calculate compute usage cost
    function testCalculateComputeUsageCost() public {
        vm.prank(meter);
        splitter.reportUsage(0, 2000); // 2 GPU-hours (scaled by 1000)

        uint256 cost = splitter.calculateComputeUsageCost();

        // Default pricing: 10 DAOS per GPU-hour
        assertEq(cost, 20 ether); // 2 * 10
    }

    // Test 19: Distribute payment
    function testDistributePayment() public {
        vm.startPrank(admin);
        splitter.addContributor(payable(human1), HybridPaymentSplitter.ContributorType.Human, 4000); // 40%
        splitter.addContributor(payable(ai1), HybridPaymentSplitter.ContributorType.AI, 2750); // 27.5%
        splitter.addContributor(payable(compute1), HybridPaymentSplitter.ContributorType.Compute, 1000); // 10%
        vm.stopPrank();

        vm.prank(meter);
        splitter.reportUsage(500_000, 1500); // 500K tokens, 1.5 GPU-hours

        uint256 human1BalanceBefore = daosToken.balanceOf(human1);
        uint256 ai1BalanceBefore = daosToken.balanceOf(ai1);
        uint256 compute1BalanceBefore = daosToken.balanceOf(compute1);

        vm.prank(admin);
        splitter.distributePayment(1000 ether);

        uint256 human1BalanceAfter = daosToken.balanceOf(human1);
        uint256 ai1BalanceAfter = daosToken.balanceOf(ai1);
        uint256 compute1BalanceAfter = daosToken.balanceOf(compute1);

        // Human should receive 40% fixed
        assertEq(human1BalanceAfter - human1BalanceBefore, 400 ether);

        // AI should receive usage cost + 27.5% fixed
        // 500K tokens * 20 DAOS / 1M = 10 DAOS usage + 275 DAOS fixed = 285 DAOS
        assertEq(ai1BalanceAfter - ai1BalanceBefore, 285 ether);

        // Compute should receive usage cost + 10% fixed
        // 1.5 GPU-hours * 10 DAOS = 15 DAOS usage + 100 DAOS fixed = 115 DAOS
        assertEq(compute1BalanceAfter - compute1BalanceBefore, 115 ether);
    }

    // Test 20: Update pricing
    function testUpdatePricing() public {
        vm.prank(admin);
        splitter.updatePricing(30 ether, 15 ether); // New prices

        (uint256 pricePerMTokenLLM, uint256 pricePerGPUHour) = splitter.getPricing();

        assertEq(pricePerMTokenLLM, 30 ether);
        assertEq(pricePerGPUHour, 15 ether);
    }

    // Test 21: Reset usage metrics
    function testResetUsageMetrics() public {
        vm.prank(meter);
        splitter.reportUsage(500_000, 1500);

        vm.prank(admin);
        splitter.resetUsageMetrics();

        (uint256 llmTokens, uint256 gpuHours, ) = splitter.getUsageMetrics();

        assertEq(llmTokens, 0);
        assertEq(gpuHours, 0);
    }

    // Test 22: Emergency withdraw
    function testEmergencyWithdraw() public {
        uint256 balanceBefore = daosToken.balanceOf(admin);

        vm.prank(admin);
        splitter.emergencyWithdraw();

        uint256 balanceAfter = daosToken.balanceOf(admin);

        assertGt(balanceAfter, balanceBefore);
    }

    // Test 23: Revert if non-meter reports usage
    function testRevertNonMeterReportUsage() public {
        vm.expectRevert();
        vm.prank(human1); // Not a meter
        splitter.reportUsage(100_000, 500);
    }

    // Test 24: Revert if invalid percentage
    function testRevertInvalidPercentage() public {
        vm.expectRevert(HybridPaymentSplitter.InvalidPercentage.selector);
        vm.prank(admin);
        splitter.addContributor(payable(human1), HybridPaymentSplitter.ContributorType.Human, 11000); // >100%
    }
}
