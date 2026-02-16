// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/ServiceMarketplace.sol";
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

contract ServiceMarketplaceTest is Test {
    ServiceMarketplace public marketplace;
    DAOMembership public membership;
    MockDAOSToken public daosToken;

    address public admin = address(0x1);
    address public client = address(0x2);
    address public consultant1 = address(0x3);
    address public consultant2 = address(0x4);

    function setUp() public {
        vm.startPrank(admin);

        // Deploy contracts
        daosToken = new MockDAOSToken();
        membership = new DAOMembership();
        marketplace = new ServiceMarketplace(address(daosToken), address(membership), admin);

        // Setup members
        membership.addMember(client, 2, "client-github");
        membership.addMember(consultant1, 3, "consultant1-github");
        membership.addMember(consultant2, 2, "consultant2-github");

        // Set skills for consultants
        string[] memory skills1 = new string[](3);
        skills1[0] = "Solidity";
        skills1[1] = "React";
        skills1[2] = "Node.js";
        membership.setSkills(consultant1, skills1);

        string[] memory skills2 = new string[](2);
        skills2[0] = "Solidity";
        skills2[1] = "Python";
        membership.setSkills(consultant2, skills2);

        // Mint tokens and approve
        daosToken.mint(client, 10000 ether);
        daosToken.mint(consultant1, 1000 ether);
        daosToken.mint(consultant2, 1000 ether);

        vm.stopPrank();

        // Client approves marketplace
        vm.prank(client);
        daosToken.approve(address(marketplace), type(uint256).max);
    }

    // ===== Test Mission Creation =====

    function test_CreateMission() public {
        vm.prank(client);

        string[] memory requiredSkills = new string[](2);
        requiredSkills[0] = "Solidity";
        requiredSkills[1] = "React";

        uint256 missionId = marketplace.createMission(
            "Smart Contract Audit",
            "Comprehensive audit of DAO governance contracts",
            1000 ether,
            2,
            requiredSkills
        );

        (
            uint256 id,
            address missionClient,
            string memory title,
            string memory description,
            uint256 budget,
            uint8 minRank,
            ServiceMarketplace.MissionStatus status,
            ,
            uint256 createdAt,

        ) = marketplace.missions(missionId);

        assertEq(id, 0);
        assertEq(missionClient, client);
        assertEq(title, "Smart Contract Audit");
        assertEq(description, "Comprehensive audit of DAO governance contracts");
        assertEq(budget, 1000 ether);
        assertEq(minRank, 2);
        assertTrue(uint8(status) == uint8(ServiceMarketplace.MissionStatus.Draft));
        assertEq(createdAt, block.timestamp);
    }

    function test_CreateMissionRevertsIfNotMember() public {
        vm.prank(address(0x999)); // Non-member

        string[] memory requiredSkills = new string[](0);

        vm.expectRevert(ServiceMarketplace.NotActiveMember.selector);
        marketplace.createMission(
            "Test Mission",
            "Test description",
            1000 ether,
            0,
            requiredSkills
        );
    }

    function test_CreateMissionRevertsIfInvalidBudget() public {
        vm.prank(client);

        string[] memory requiredSkills = new string[](0);

        vm.expectRevert(ServiceMarketplace.InvalidBudget.selector);
        marketplace.createMission(
            "Test Mission",
            "Test description",
            0, // Invalid budget
            0,
            requiredSkills
        );
    }

    function test_CreateMissionRevertsIfTitleTooLong() public {
        vm.prank(client);

        string[] memory requiredSkills = new string[](0);
        string memory longTitle = new string(201);

        vm.expectRevert(ServiceMarketplace.InvalidTitle.selector);
        marketplace.createMission(
            longTitle,
            "Test description",
            1000 ether,
            0,
            requiredSkills
        );
    }

    function test_CreateMissionRevertsIfTooManySkills() public {
        vm.prank(client);

        string[] memory requiredSkills = new string[](11); // Max 10

        vm.expectRevert(ServiceMarketplace.TooManySkills.selector);
        marketplace.createMission(
            "Test Mission",
            "Test description",
            1000 ether,
            0,
            requiredSkills
        );
    }

    // ===== Test Post Mission =====

    function test_PostMission() public {
        vm.startPrank(client);

        string[] memory requiredSkills = new string[](0);
        uint256 missionId = marketplace.createMission(
            "Test Mission",
            "Test description",
            1000 ether,
            0,
            requiredSkills
        );

        uint256 balanceBefore = daosToken.balanceOf(client);

        marketplace.postMission(missionId);

        uint256 balanceAfter = daosToken.balanceOf(client);

        (,,,,,,ServiceMarketplace.MissionStatus status,,,) = marketplace.missions(missionId);

        assertTrue(uint8(status) == uint8(ServiceMarketplace.MissionStatus.Active));
        assertEq(balanceBefore - balanceAfter, 1000 ether);
        assertEq(daosToken.balanceOf(address(marketplace)), 1000 ether);

        vm.stopPrank();
    }

    function test_PostMissionRevertsIfNotClient() public {
        vm.prank(client);

        string[] memory requiredSkills = new string[](0);
        uint256 missionId = marketplace.createMission(
            "Test Mission",
            "Test description",
            1000 ether,
            0,
            requiredSkills
        );

        vm.prank(consultant1); // Not client

        vm.expectRevert(ServiceMarketplace.UnauthorizedClient.selector);
        marketplace.postMission(missionId);
    }

    function test_PostMissionRevertsIfNotDraft() public {
        vm.startPrank(client);

        string[] memory requiredSkills = new string[](0);
        uint256 missionId = marketplace.createMission(
            "Test Mission",
            "Test description",
            1000 ether,
            0,
            requiredSkills
        );

        marketplace.postMission(missionId);

        vm.expectRevert(ServiceMarketplace.MissionNotDraft.selector);
        marketplace.postMission(missionId); // Already Active

        vm.stopPrank();
    }

    // ===== Test Apply to Mission =====

    function test_ApplyToMission() public {
        vm.startPrank(client);

        string[] memory requiredSkills = new string[](2);
        requiredSkills[0] = "Solidity";
        requiredSkills[1] = "React";

        uint256 missionId = marketplace.createMission(
            "Smart Contract Audit",
            "Comprehensive audit",
            1000 ether,
            2,
            requiredSkills
        );

        marketplace.postMission(missionId);

        vm.stopPrank();

        vm.prank(consultant1);

        marketplace.applyToMission(
            missionId,
            "QmYwAPJzv5CZsnA625s3Xf2nemtYgPpHdWEz79ojWnPbdG", // IPFS hash (46 chars)
            800 ether
        );

        ServiceMarketplace.Application memory app = marketplace.getApplication(missionId, consultant1);

        assertEq(app.consultant, consultant1);
        assertEq(app.proposedBudget, 800 ether);
        assertTrue(app.matchScore > 0);
    }

    function test_ApplyToMissionRevertsIfNotActive() public {
        vm.prank(client);

        string[] memory requiredSkills = new string[](0);
        uint256 missionId = marketplace.createMission(
            "Test Mission",
            "Test description",
            1000 ether,
            0,
            requiredSkills
        );

        // Mission still in Draft status

        vm.prank(consultant1);

        vm.expectRevert(ServiceMarketplace.MissionNotActive.selector);
        marketplace.applyToMission(
            missionId,
            "QmYwAPJzv5CZsnA625s3Xf2nemtYgPpHdWEz79ojWnPbdG",
            800 ether
        );
    }

    function test_ApplyToMissionRevertsIfAlreadyApplied() public {
        vm.startPrank(client);

        string[] memory requiredSkills = new string[](0);
        uint256 missionId = marketplace.createMission(
            "Test Mission",
            "Test description",
            1000 ether,
            0,
            requiredSkills
        );

        marketplace.postMission(missionId);

        vm.stopPrank();

        vm.startPrank(consultant1);

        marketplace.applyToMission(
            missionId,
            "QmYwAPJzv5CZsnA625s3Xf2nemtYgPpHdWEz79ojWnPbdG",
            800 ether
        );

        vm.expectRevert(ServiceMarketplace.AlreadyApplied.selector);
        marketplace.applyToMission(
            missionId,
            "QmYwAPJzv5CZsnA625s3Xf2nemtYgPpHdWEz79ojWnPbdG",
            800 ether
        );

        vm.stopPrank();
    }

    function test_ApplyToMissionRevertsIfBudgetTooHigh() public {
        vm.startPrank(client);

        string[] memory requiredSkills = new string[](0);
        uint256 missionId = marketplace.createMission(
            "Test Mission",
            "Test description",
            1000 ether,
            0,
            requiredSkills
        );

        marketplace.postMission(missionId);

        vm.stopPrank();

        vm.prank(consultant1);

        vm.expectRevert(ServiceMarketplace.ProposedBudgetTooHigh.selector);
        marketplace.applyToMission(
            missionId,
            "QmYwAPJzv5CZsnA625s3Xf2nemtYgPpHdWEz79ojWnPbdG",
            1001 ether // Budget too high
        );
    }

    function test_ApplyToMissionRevertsIfInsufficientRank() public {
        vm.startPrank(client);

        string[] memory requiredSkills = new string[](0);
        uint256 missionId = marketplace.createMission(
            "Test Mission",
            "Test description",
            1000 ether,
            4, // Requires rank 4
            requiredSkills
        );

        marketplace.postMission(missionId);

        vm.stopPrank();

        vm.prank(consultant1); // Rank 3 < 4

        vm.expectRevert(ServiceMarketplace.InsufficientRank.selector);
        marketplace.applyToMission(
            missionId,
            "QmYwAPJzv5CZsnA625s3Xf2nemtYgPpHdWEz79ojWnPbdG",
            800 ether
        );
    }

    // ===== Test Select Consultant =====

    function test_SelectConsultant() public {
        vm.startPrank(client);

        string[] memory requiredSkills = new string[](0);
        uint256 missionId = marketplace.createMission(
            "Test Mission",
            "Test description",
            1000 ether,
            0,
            requiredSkills
        );

        marketplace.postMission(missionId);

        vm.stopPrank();

        vm.prank(consultant1);
        marketplace.applyToMission(
            missionId,
            "QmYwAPJzv5CZsnA625s3Xf2nemtYgPpHdWEz79ojWnPbdG",
            800 ether
        );

        vm.prank(client);
        marketplace.selectConsultant(missionId, consultant1);

        (,,,,,,ServiceMarketplace.MissionStatus status, address selected,,) = marketplace.missions(missionId);

        assertTrue(uint8(status) == uint8(ServiceMarketplace.MissionStatus.OnHold));
        assertEq(selected, consultant1);
    }

    function test_SelectConsultantRevertsIfNotClient() public {
        vm.startPrank(client);

        string[] memory requiredSkills = new string[](0);
        uint256 missionId = marketplace.createMission(
            "Test Mission",
            "Test description",
            1000 ether,
            0,
            requiredSkills
        );

        marketplace.postMission(missionId);

        vm.stopPrank();

        vm.prank(consultant1);
        marketplace.applyToMission(
            missionId,
            "QmYwAPJzv5CZsnA625s3Xf2nemtYgPpHdWEz79ojWnPbdG",
            800 ether
        );

        vm.prank(consultant2); // Not client

        vm.expectRevert(ServiceMarketplace.UnauthorizedClient.selector);
        marketplace.selectConsultant(missionId, consultant1);
    }

    // ===== Test Cancel Mission =====

    function test_CancelMission() public {
        vm.startPrank(client);

        string[] memory requiredSkills = new string[](0);
        uint256 missionId = marketplace.createMission(
            "Test Mission",
            "Test description",
            1000 ether,
            0,
            requiredSkills
        );

        marketplace.postMission(missionId);

        uint256 balanceBefore = daosToken.balanceOf(client);

        marketplace.cancelMission(missionId);

        uint256 balanceAfter = daosToken.balanceOf(client);

        (,,,,,,ServiceMarketplace.MissionStatus status,,,) = marketplace.missions(missionId);

        assertTrue(uint8(status) == uint8(ServiceMarketplace.MissionStatus.Cancelled));
        assertEq(balanceAfter - balanceBefore, 1000 ether); // Refunded

        vm.stopPrank();
    }

    function test_CancelMissionRevertsIfNotClient() public {
        vm.startPrank(client);

        string[] memory requiredSkills = new string[](0);
        uint256 missionId = marketplace.createMission(
            "Test Mission",
            "Test description",
            1000 ether,
            0,
            requiredSkills
        );

        marketplace.postMission(missionId);

        vm.stopPrank();

        vm.prank(consultant1); // Not client

        vm.expectRevert(ServiceMarketplace.UnauthorizedClient.selector);
        marketplace.cancelMission(missionId);
    }

    // ===== Test Match Score Calculation =====

    function test_CalculateMatchScore() public {
        vm.startPrank(client);

        string[] memory requiredSkills = new string[](2);
        requiredSkills[0] = "Solidity";
        requiredSkills[1] = "React";

        uint256 missionId = marketplace.createMission(
            "Smart Contract Audit",
            "Comprehensive audit",
            1000 ether,
            2,
            requiredSkills
        );

        marketplace.postMission(missionId);

        vm.stopPrank();

        // Consultant1: Rank 3, Skills [Solidity, React, Node.js], 2/2 match
        uint256 matchScore = marketplace.calculateMatchScore(missionId, consultant1, 800 ether);

        // Expected breakdown:
        // 1. Rank: (3 * 25) / 4 = 18.75 = 18 points
        // 2. Skills: (2/2) * 25 = 25 points
        // 3. Budget: 20 - ((800/1000) * 20) = 20 - 16 = 4 points
        // 4. Track Record: 0 (no missions completed)
        // 5. Responsiveness: ~15 points (applied immediately)
        // Total: ~62 points

        assertTrue(matchScore >= 60 && matchScore <= 65); // Approximate range
    }
}
