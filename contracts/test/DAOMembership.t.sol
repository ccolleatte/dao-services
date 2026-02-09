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

        vm.expectRevert("Already a member");
        membership.addMember(alice, 1, "alice-github-2");
        vm.stopPrank();
    }

    function test_AddMemberRevertsIfInvalidRank() public {
        vm.prank(admin);
        vm.expectRevert("Invalid rank (max 4)");
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
        vm.expectRevert("Minimum duration not met");
        membership.promoteMember(alice);
        vm.stopPrank();
    }

    function test_PromoteMemberRevertsIfMaxRank() public {
        vm.startPrank(admin);
        membership.addMember(alice, 4, "alice-github");

        vm.expectRevert("Already at max rank");
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

        vm.expectRevert("Already at min rank");
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

        // minRank = 0 → weight = 1
        uint256 weight = membership.calculateVoteWeight(alice, 0);
        assertEq(weight, 1);
    }

    function test_CalculateVoteWeight_Rank1() public {
        vm.prank(admin);
        membership.addMember(bob, 1, "bob-github");

        // minRank = 0 → weight = 3
        uint256 weight = membership.calculateVoteWeight(bob, 0);
        assertEq(weight, 3);
    }

    function test_CalculateVoteWeight_Rank2() public {
        vm.prank(admin);
        membership.addMember(charlie, 2, "charlie-github");

        // minRank = 0 → weight = 6
        uint256 weight = membership.calculateVoteWeight(charlie, 0);
        assertEq(weight, 6);
    }

    function test_CalculateVoteWeight_WithMinRank() public {
        vm.prank(admin);
        membership.addMember(charlie, 2, "charlie-github");

        // minRank = 1 → r = 2-1+1 = 2 → weight = 3
        uint256 weight = membership.calculateVoteWeight(charlie, 1);
        assertEq(weight, 3);
    }

    function test_CalculateVoteWeightRevertsIfRankTooLow() public {
        vm.prank(admin);
        membership.addMember(alice, 0, "alice-github");

        vm.expectRevert("Rank too low for this proposal");
        membership.calculateVoteWeight(alice, 2);
    }

    // ===== Test Total Vote Weight =====

    function test_CalculateTotalVoteWeight() public {
        vm.startPrank(admin);
        membership.addMember(alice, 0, "alice-github");     // weight = 1
        membership.addMember(bob, 1, "bob-github");         // weight = 3
        membership.addMember(charlie, 2, "charlie-github"); // weight = 6

        uint256 totalWeight = membership.calculateTotalVoteWeight(0);
        assertEq(totalWeight, 10); // 1 + 3 + 6 = 10
        vm.stopPrank();
    }

    function test_CalculateTotalVoteWeightWithMinRank() public {
        vm.startPrank(admin);
        membership.addMember(alice, 0, "alice-github");
        membership.addMember(bob, 1, "bob-github");
        membership.addMember(charlie, 2, "charlie-github");

        // minRank = 1 → seuls bob et charlie comptent
        uint256 totalWeight = membership.calculateTotalVoteWeight(1);
        // bob: r=1→1, weight=1; charlie: r=2-1=1, weight=1
        assertEq(totalWeight, 2); // 1 + 1 = 2
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

        vm.expectRevert("Member inactive");
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
}
