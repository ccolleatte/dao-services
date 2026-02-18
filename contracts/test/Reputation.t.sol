// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/Reputation.sol";
import "../src/DAOMembership.sol";

/**
 * @title ReputationTest
 * @notice Tests Reputation.sol — couverture ≥20 tests (plan T1)
 *
 * Catégories :
 * - Constructor (2)
 * - addBadge : accès, validation, intégration DAOMembership (6)
 * - getRating : 0 badge, 1 badge, N badges, moyenne (4)
 * - addCrossRating : sens, anti double-vote, validation (6)
 * - View functions : getBadgeCount, getCrossRatings, hasRatedForMission (4)
 * Total : 22 tests
 */
contract ReputationTest is Test {
    Reputation public reputation;
    DAOMembership public membership;

    address public admin = address(0x1);
    address public consultant = address(0x2);
    address public client = address(0x3);
    address public unauthorized = address(0x4);

    uint256 public missionId1 = 1;
    uint256 public missionId2 = 2;
    bytes32 public ipfsHash1 = keccak256("report-mission-1");
    bytes32 public ipfsHash2 = keccak256("report-mission-2");

    // Events
    event BadgeAdded(
        address indexed consultant,
        uint256 indexed missionId,
        bytes32 ipfsHash,
        uint8 rating,
        uint256 timestamp
    );

    event CrossRatingAdded(
        address indexed rater,
        address indexed rated,
        uint256 indexed missionId,
        uint8 rating,
        bool isClientRating
    );

    function setUp() public {
        vm.startPrank(admin);
        membership = new DAOMembership();
        reputation = new Reputation(address(membership));

        // Donner à reputation le rôle MEMBER_MANAGER_ROLE sur DAOMembership
        membership.grantRole(membership.MEMBER_MANAGER_ROLE(), address(reputation));

        // Enregistrer le consultant et le client comme membres DAO
        membership.addMember(consultant, 1, "consultant-github");
        membership.addMember(client, 0, "client-github");
        vm.stopPrank();
    }

    // ===== Constructor =====

    function test_ConstructorSetsRoles() public view {
        assertTrue(reputation.hasRole(reputation.DEFAULT_ADMIN_ROLE(), admin));
        assertTrue(reputation.hasRole(reputation.MEMBER_MANAGER_ROLE(), admin));
    }

    function test_ConstructorRevertsOnZeroAddress() public {
        vm.prank(admin);
        vm.expectRevert(Reputation.InvalidAddress.selector);
        new Reputation(address(0));
    }

    // ===== addBadge : accès =====

    function test_AddBadge_SuccessByMemberManager() public {
        vm.prank(admin);
        reputation.addBadge(consultant, missionId1, ipfsHash1, 80);

        assertEq(reputation.getBadgeCount(consultant), 1);
    }

    function test_AddBadge_RevertsIfUnauthorized() public {
        vm.prank(unauthorized);
        vm.expectRevert();
        reputation.addBadge(consultant, missionId1, ipfsHash1, 80);
    }

    function test_AddBadge_RevertsIfRatingOver100() public {
        vm.prank(admin);
        vm.expectRevert(abi.encodeWithSelector(Reputation.InvalidRating.selector, 101, 100));
        reputation.addBadge(consultant, missionId1, ipfsHash1, 101);
    }

    function test_AddBadge_RevertsIfZeroAddress() public {
        vm.prank(admin);
        vm.expectRevert(Reputation.InvalidAddress.selector);
        reputation.addBadge(address(0), missionId1, ipfsHash1, 80);
    }

    function test_AddBadge_EmitsEvent() public {
        vm.prank(admin);
        vm.expectEmit(true, true, false, false);
        emit BadgeAdded(consultant, missionId1, ipfsHash1, 80, block.timestamp);
        reputation.addBadge(consultant, missionId1, ipfsHash1, 80);
    }

    // ===== addBadge : intégration DAOMembership =====

    function test_AddBadge_UpdatesDAOMembershipTrackRecord() public {
        vm.prank(admin);
        reputation.addBadge(consultant, missionId1, ipfsHash1, 90);

        // Vérifier que DAOMembership.updateTrackRecord() a été appelé
        (uint256 completedMissions, uint256 averageRating) = membership.getTrackRecord(consultant);
        assertEq(completedMissions, 1);
        assertEq(averageRating, 90);
    }

    // ===== getRating =====

    function test_GetRating_ZeroBadges_ReturnsZero() public view {
        assertEq(reputation.getRating(consultant), 0);
    }

    function test_GetRating_OneBadge_ReturnsRating() public {
        vm.prank(admin);
        reputation.addBadge(consultant, missionId1, ipfsHash1, 75);

        assertEq(reputation.getRating(consultant), 75);
    }

    function test_GetRating_MultipleBadges_ReturnsMoyenne() public {
        vm.startPrank(admin);
        reputation.addBadge(consultant, missionId1, ipfsHash1, 60);
        reputation.addBadge(consultant, missionId2, ipfsHash2, 80);
        vm.stopPrank();

        // Moyenne : (60 + 80) / 2 = 70
        assertEq(reputation.getRating(consultant), 70);
    }

    function test_GetRating_MaxRating() public {
        vm.prank(admin);
        reputation.addBadge(consultant, missionId1, ipfsHash1, 100);

        assertEq(reputation.getRating(consultant), 100);
    }

    // ===== addCrossRating =====

    function test_AddCrossRating_ClientNotesConsultant() public {
        vm.prank(admin);
        reputation.addCrossRating(client, consultant, missionId1, 85, true);

        Reputation.CrossRating[] memory ratings = reputation.getCrossRatings(consultant);
        assertEq(ratings.length, 1);
        assertEq(ratings[0].rating, 85);
        assertTrue(ratings[0].isClientRating);
        assertEq(ratings[0].rater, client);
    }

    function test_AddCrossRating_ConsultantNotesClient() public {
        vm.prank(admin);
        reputation.addCrossRating(consultant, client, missionId1, 70, false);

        Reputation.CrossRating[] memory ratings = reputation.getCrossRatings(client);
        assertEq(ratings.length, 1);
        assertFalse(ratings[0].isClientRating);
    }

    function test_AddCrossRating_RevertsOnDoubleVoteMameMission() public {
        vm.startPrank(admin);
        reputation.addCrossRating(client, consultant, missionId1, 85, true);

        vm.expectRevert(
            abi.encodeWithSelector(Reputation.AlreadyRatedForMission.selector, client, missionId1)
        );
        reputation.addCrossRating(client, consultant, missionId1, 90, true);
        vm.stopPrank();
    }

    function test_AddCrossRating_AllowsDifferentMissions() public {
        vm.startPrank(admin);
        reputation.addCrossRating(client, consultant, missionId1, 85, true);
        reputation.addCrossRating(client, consultant, missionId2, 70, true); // OK : autre mission
        vm.stopPrank();

        Reputation.CrossRating[] memory ratings = reputation.getCrossRatings(consultant);
        assertEq(ratings.length, 2);
    }

    function test_AddCrossRating_RevertsIfRatingOver100() public {
        vm.prank(admin);
        vm.expectRevert(abi.encodeWithSelector(Reputation.InvalidRating.selector, 101, 100));
        reputation.addCrossRating(client, consultant, missionId1, 101, true);
    }

    function test_AddCrossRating_EmitsEvent() public {
        vm.prank(admin);
        vm.expectEmit(true, true, true, false);
        emit CrossRatingAdded(client, consultant, missionId1, 85, true);
        reputation.addCrossRating(client, consultant, missionId1, 85, true);
    }

    // ===== View functions =====

    function test_GetConsultantBadges_ChronologicalOrder() public {
        vm.startPrank(admin);
        reputation.addBadge(consultant, missionId1, ipfsHash1, 60);
        reputation.addBadge(consultant, missionId2, ipfsHash2, 80);
        vm.stopPrank();

        Reputation.Badge[] memory badges = reputation.getConsultantBadges(consultant);
        assertEq(badges.length, 2);
        // Ordre chronologique : premier badge ajouté = index 0
        assertEq(badges[0].missionId, missionId1);
        assertEq(badges[1].missionId, missionId2);
    }

    function test_GetBadgeCount_ReturnsCorrectCount() public {
        vm.startPrank(admin);
        reputation.addBadge(consultant, missionId1, ipfsHash1, 60);
        reputation.addBadge(consultant, missionId2, ipfsHash2, 80);
        vm.stopPrank();

        assertEq(reputation.getBadgeCount(consultant), 2);
    }

    function test_GetBadgeCount_EmptyReturnsZero() public view {
        assertEq(reputation.getBadgeCount(consultant), 0);
    }

    function test_HasRatedForMission_ReturnsTrueAfterRating() public {
        vm.prank(admin);
        reputation.addCrossRating(client, consultant, missionId1, 85, true);

        assertTrue(reputation.hasRatedForMission(missionId1, client));
    }
}
