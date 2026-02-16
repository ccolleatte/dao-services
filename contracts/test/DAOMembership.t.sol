// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/DAOMembership.sol";

contract DAOMembershipTest is Test {
    DAOMembership public membership;

    address public admin = address(0x1);
    address public alice = address(0x2);
    address public bob = address(0x3);
    address public charlie = address(0x4);

    function setUp() public {
        // Déployer le contrat
        vm.prank(admin);
        membership = new DAOMembership();
    }

    // ===== Test Constructor =====

    function test_ConstructorSetsRoles() public {
        assertTrue(membership.hasRole(membership.DEFAULT_ADMIN_ROLE(), admin));
        assertTrue(membership.hasRole(membership.ADMIN_ROLE(), admin));
        assertTrue(membership.hasRole(membership.MEMBER_MANAGER_ROLE(), admin));
    }

    // ===== Test Add Member =====

    function test_AddMember() public {
        vm.prank(admin);
        membership.addMember(alice, 0, "alice-github");

        assertTrue(membership.isMember(alice));

        DAOMembership.Member memory member = membership.getMemberInfo(alice);
        assertEq(member.rank, 0);
        assertEq(member.githubHandle, "alice-github");
        assertTrue(member.active);
    }

    function test_AddMemberRevertsIfUnauthorized() public {
        vm.prank(alice); // Non-admin essaie d'ajouter
        vm.expectRevert();
        membership.addMember(bob, 0, "bob-github");
    }

    function test_AddMemberRevertsIfAlreadyMember() public {
        vm.startPrank(admin);
        membership.addMember(alice, 0, "alice-github");

        vm.expectRevert(abi.encodeWithSelector(DAOMembership.AlreadyMember.selector, alice));
        membership.addMember(alice, 1, "alice-github-2");
        vm.stopPrank();
    }

    function test_AddMemberRevertsIfInvalidRank() public {
        vm.prank(admin);
        vm.expectRevert(abi.encodeWithSelector(DAOMembership.InvalidRank.selector, 5));
        membership.addMember(alice, 5, "alice-github");
    }

    // ===== Test Promote Member =====

    function test_PromoteMember() public {
        vm.startPrank(admin);
        membership.addMember(alice, 0, "alice-github");

        // Avancer le temps de 91 jours (> 90 jours requis)
        skip(91 days);

        membership.promoteMember(alice);

        DAOMembership.Member memory member = membership.getMemberInfo(alice);
        assertEq(member.rank, 1);
        vm.stopPrank();
    }

    function test_PromoteMemberRevertsIfDurationNotMet() public {
        vm.startPrank(admin);
        membership.addMember(alice, 0, "alice-github");

        // Essayer de promouvoir immédiatement (< 90 jours)
        vm.expectRevert(abi.encodeWithSelector(DAOMembership.InsufficientTimeSincePromotion.selector, 0, 90 days));
        membership.promoteMember(alice);
        vm.stopPrank();
    }

    function test_PromoteMemberRevertsIfMaxRank() public {
        vm.startPrank(admin);
        membership.addMember(alice, 4, "alice-github");

        vm.expectRevert(abi.encodeWithSelector(DAOMembership.AlreadyAtMaxRank.selector, alice));
        membership.promoteMember(alice);
        vm.stopPrank();
    }

    // ===== Test Demote Member =====

    function test_DemoteMember() public {
        vm.startPrank(admin);
        membership.addMember(alice, 2, "alice-github");

        membership.demoteMember(alice);

        DAOMembership.Member memory member = membership.getMemberInfo(alice);
        assertEq(member.rank, 1);
        vm.stopPrank();
    }

    function test_DemoteMemberRevertsIfMinRank() public {
        vm.startPrank(admin);
        membership.addMember(alice, 0, "alice-github");

        vm.expectRevert(abi.encodeWithSelector(DAOMembership.AlreadyAtMinRank.selector, alice));
        membership.demoteMember(alice);
        vm.stopPrank();
    }

    // ===== Test Remove Member =====

    function test_RemoveMember() public {
        vm.startPrank(admin);
        membership.addMember(alice, 0, "alice-github");

        assertTrue(membership.isMember(alice));

        membership.removeMember(alice);

        assertFalse(membership.isMember(alice));
        vm.stopPrank();
    }

    // ===== Test Vote Weight Calculation =====

    function test_CalculateVoteWeight_Rank0() public {
        vm.prank(admin);
        membership.addMember(alice, 0, "alice-github");

        // Rank 0 → weight = 0 (standard triangular)
        uint256 weight = membership.calculateVoteWeight(alice, 0);
        assertEq(weight, 0);
    }

    function test_CalculateVoteWeight_Rank1() public {
        vm.prank(admin);
        membership.addMember(bob, 1, "bob-github");

        // Rank 1 → weight = 1 (standard triangular)
        uint256 weight = membership.calculateVoteWeight(bob, 0);
        assertEq(weight, 1);
    }

    function test_CalculateVoteWeight_Rank2() public {
        vm.prank(admin);
        membership.addMember(charlie, 2, "charlie-github");

        // Rank 2 → weight = 3 (standard triangular)
        uint256 weight = membership.calculateVoteWeight(charlie, 0);
        assertEq(weight, 3);
    }

    function test_CalculateVoteWeight_WithMinRank() public {
        vm.prank(admin);
        membership.addMember(charlie, 2, "charlie-github");

        // minRank = 1 → charlie's rank 2 >= minRank → weight = triangular(2) = 3
        uint256 weight = membership.calculateVoteWeight(charlie, 1);
        assertEq(weight, 3);
    }

    function test_CalculateVoteWeightRevertsIfRankTooLow() public {
        vm.prank(admin);
        membership.addMember(alice, 0, "alice-github");

        vm.expectRevert(abi.encodeWithSelector(DAOMembership.RankTooLow.selector, 0, 2));
        membership.calculateVoteWeight(alice, 2);
    }

    // ===== Test Total Vote Weight =====

    function test_CalculateTotalVoteWeight() public {
        vm.startPrank(admin);
        membership.addMember(alice, 0, "alice-github");     // weight = 0
        membership.addMember(bob, 1, "bob-github");         // weight = 1
        membership.addMember(charlie, 2, "charlie-github"); // weight = 3

        uint256 totalWeight = membership.calculateTotalVoteWeight(0);
        assertEq(totalWeight, 4); // 0 + 1 + 3 = 4
        vm.stopPrank();
    }

    function test_CalculateTotalVoteWeightWithMinRank() public {
        vm.startPrank(admin);
        membership.addMember(alice, 0, "alice-github");
        membership.addMember(bob, 1, "bob-github");
        membership.addMember(charlie, 2, "charlie-github");

        // minRank = 1 → only bob and charlie count (alice filtered out)
        uint256 totalWeight = membership.calculateTotalVoteWeight(1);
        // bob: rank=1, weight=1*2/2=1
        // charlie: rank=2, weight=2*3/2=3
        // Total = 1 + 3 = 4 (standard triangular, no minRank adjustment)
        assertEq(totalWeight, 4);
        vm.stopPrank();
    }

    // ===== Test Active/Inactive Members =====

    function test_SetMemberInactive() public {
        vm.startPrank(admin);
        membership.addMember(alice, 0, "alice-github");

        membership.setMemberActive(alice, false);

        DAOMembership.Member memory member = membership.getMemberInfo(alice);
        assertFalse(member.active);
        vm.stopPrank();
    }

    function test_CalculateVoteWeightRevertsIfInactive() public {
        vm.startPrank(admin);
        membership.addMember(alice, 0, "alice-github");
        membership.setMemberActive(alice, false);
        vm.stopPrank();

        vm.expectRevert(abi.encodeWithSelector(DAOMembership.MemberInactive.selector, alice));
        membership.calculateVoteWeight(alice, 0);
    }

    // ===== Test Get Members By Rank =====

    function test_GetActiveMembersByRank() public {
        vm.startPrank(admin);
        membership.addMember(alice, 0, "alice-github");
        membership.addMember(bob, 1, "bob-github");
        membership.addMember(charlie, 0, "charlie-github");

        address[] memory rank0Members = membership.getActiveMembersByRank(0);
        assertEq(rank0Members.length, 2);

        address[] memory rank1Members = membership.getActiveMembersByRank(1);
        assertEq(rank1Members.length, 1);
        assertEq(rank1Members[0], bob);
        vm.stopPrank();
    }

    // ===== Test Member Count =====

    function test_GetMemberCount() public {
        vm.startPrank(admin);
        membership.addMember(alice, 0, "alice-github");
        membership.addMember(bob, 1, "bob-github");

        assertEq(membership.getMemberCount(), 2);
        vm.stopPrank();
    }

    // ===== Test Skills Management =====

    function test_SetSkills() public {
        vm.startPrank(admin);
        membership.addMember(alice, 2, "alice-github");

        string[] memory skills = new string[](3);
        skills[0] = "Solidity";
        skills[1] = "React";
        skills[2] = "Node.js";

        membership.setSkills(alice, skills);

        string[] memory retrievedSkills = membership.getSkills(alice);
        assertEq(retrievedSkills.length, 3);
        assertEq(retrievedSkills[0], "Solidity");
        assertEq(retrievedSkills[1], "React");
        assertEq(retrievedSkills[2], "Node.js");
        vm.stopPrank();
    }

    function test_SetSkillsRevertsIfTooMany() public {
        vm.startPrank(admin);
        membership.addMember(alice, 2, "alice-github");

        // Créer 21 skills (> MAX_SKILLS = 20)
        string[] memory skills = new string[](21);
        for (uint256 i = 0; i < 21; i++) {
            skills[i] = "Skill";
        }

        vm.expectRevert("Too many skills (max 20)");
        membership.setSkills(alice, skills);
        vm.stopPrank();
    }

    function test_SetSkillsReplacesOldSkills() public {
        vm.startPrank(admin);
        membership.addMember(alice, 2, "alice-github");

        // Set initial skills
        string[] memory skills1 = new string[](2);
        skills1[0] = "Solidity";
        skills1[1] = "React";
        membership.setSkills(alice, skills1);

        // Replace with new skills
        string[] memory skills2 = new string[](3);
        skills2[0] = "Rust";
        skills2[1] = "Python";
        skills2[2] = "Go";
        membership.setSkills(alice, skills2);

        string[] memory retrievedSkills = membership.getSkills(alice);
        assertEq(retrievedSkills.length, 3);
        assertEq(retrievedSkills[0], "Rust");
        assertEq(retrievedSkills[1], "Python");
        assertEq(retrievedSkills[2], "Go");
        vm.stopPrank();
    }

    function test_GetSkillsRevertsIfNotMember() public {
        vm.expectRevert("Not a member");
        membership.getSkills(bob);
    }

    // ===== Test Track Record Management =====

    function test_UpdateTrackRecord() public {
        vm.startPrank(admin);
        membership.addMember(alice, 2, "alice-github");

        // Première mission : rating 85
        membership.updateTrackRecord(alice, 85);

        (uint256 completedMissions, uint256 averageRating) = membership.getTrackRecord(alice);
        assertEq(completedMissions, 1);
        assertEq(averageRating, 85);
        vm.stopPrank();
    }

    function test_UpdateTrackRecordCalculatesAverage() public {
        vm.startPrank(admin);
        membership.addMember(alice, 2, "alice-github");

        // Mission 1 : rating 80
        membership.updateTrackRecord(alice, 80);
        // Mission 2 : rating 90
        membership.updateTrackRecord(alice, 90);
        // Mission 3 : rating 85
        membership.updateTrackRecord(alice, 85);

        (uint256 completedMissions, uint256 averageRating) = membership.getTrackRecord(alice);
        assertEq(completedMissions, 3);
        // Average : (80 + 90 + 85) / 3 = 85
        assertEq(averageRating, 85);
        vm.stopPrank();
    }

    function test_UpdateTrackRecordRevertsIfInvalidRating() public {
        vm.startPrank(admin);
        membership.addMember(alice, 2, "alice-github");

        // Rating > MAX_RATING (100)
        vm.expectRevert("Invalid rating (max 100)");
        membership.updateTrackRecord(alice, 101);
        vm.stopPrank();
    }

    function test_GetTrackRecordRevertsIfNotMember() public {
        vm.expectRevert("Not a member");
        membership.getTrackRecord(bob);
    }

    function test_TrackRecordInitiallyZero() public {
        vm.prank(admin);
        membership.addMember(alice, 2, "alice-github");

        (uint256 completedMissions, uint256 averageRating) = membership.getTrackRecord(alice);
        assertEq(completedMissions, 0);
        assertEq(averageRating, 0);
    }
}
