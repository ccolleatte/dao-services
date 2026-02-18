// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/ServiceMarketplace.sol";
import "../src/DAOMembership.sol";
import "../src/ComplianceRegistry.sol";

/**
 * @title ServiceMarketplaceTest
 * @notice Tests ServiceMarketplace.sol après refactoring T3 (ADR 2026-02-18)
 *         - Suppression dépendance DAOS token
 *         - Matching on-chain conservé (Q1)
 *         - Paiements gérés par PSP (pas de token transfer on-chain)
 */
contract ServiceMarketplaceTest is Test {
    ServiceMarketplace public marketplace;
    DAOMembership public membership;
    ComplianceRegistry public complianceRegistry;

    address public admin = address(0x1);
    address public client = address(0x2);
    address public consultant1 = address(0x3);
    address public consultant2 = address(0x4);

    function setUp() public {
        vm.startPrank(admin);

        membership = new DAOMembership();
        complianceRegistry = new ComplianceRegistry();
        complianceRegistry.grantRole(complianceRegistry.VERIFIER_ROLE(), admin);
        marketplace = new ServiceMarketplace(address(membership), address(complianceRegistry), admin);

        // Attestation KBIS pour consultant1 (valide 365 jours)
        complianceRegistry.issueAttestation(
            consultant1,
            ComplianceRegistry.AttestationType.KBIS,
            keccak256("consultant1-kbis-2026"),
            365
        );

        // Membres DAO
        membership.addMember(client, 2, "client-github");
        membership.addMember(consultant1, 3, "consultant1-github");
        membership.addMember(consultant2, 2, "consultant2-github");

        // Compétences
        string[] memory skills1 = new string[](3);
        skills1[0] = "Solidity";
        skills1[1] = "React";
        skills1[2] = "Node.js";
        membership.setSkills(consultant1, skills1);

        string[] memory skills2 = new string[](2);
        skills2[0] = "Solidity";
        skills2[1] = "Python";
        membership.setSkills(consultant2, skills2);

        vm.stopPrank();
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
        vm.prank(address(0x999));

        string[] memory requiredSkills = new string[](0);

        vm.expectRevert(ServiceMarketplace.NotActiveMember.selector);
        marketplace.createMission("Test Mission", "Test description", 1000 ether, 0, requiredSkills);
    }

    function test_CreateMissionRevertsIfInvalidBudget() public {
        vm.prank(client);

        string[] memory requiredSkills = new string[](0);

        vm.expectRevert(ServiceMarketplace.InvalidBudget.selector);
        marketplace.createMission("Test Mission", "Test description", 0, 0, requiredSkills);
    }

    function test_CreateMissionRevertsIfTitleTooLong() public {
        vm.prank(client);

        string[] memory requiredSkills = new string[](0);
        string memory longTitle = new string(201);

        vm.expectRevert(ServiceMarketplace.InvalidTitle.selector);
        marketplace.createMission(longTitle, "Test description", 1000 ether, 0, requiredSkills);
    }

    function test_CreateMissionRevertsIfTooManySkills() public {
        vm.prank(client);

        string[] memory requiredSkills = new string[](11);

        vm.expectRevert(ServiceMarketplace.TooManySkills.selector);
        marketplace.createMission("Test Mission", "Test description", 1000 ether, 0, requiredSkills);
    }

    // ===== Test Post Mission (sans token locking — ADR T3) =====

    function test_PostMission() public {
        vm.startPrank(client);

        string[] memory requiredSkills = new string[](0);
        uint256 missionId = marketplace.createMission(
            "Test Mission", "Test description", 1000 ether, 0, requiredSkills
        );

        marketplace.postMission(missionId);

        (,,,,,,ServiceMarketplace.MissionStatus status,,,) = marketplace.missions(missionId);

        // Statut passé à Active — pas de token locking (géré par PSP)
        assertTrue(uint8(status) == uint8(ServiceMarketplace.MissionStatus.Active));

        vm.stopPrank();
    }

    function test_PostMissionRevertsIfNotClient() public {
        vm.prank(client);

        string[] memory requiredSkills = new string[](0);
        uint256 missionId = marketplace.createMission(
            "Test Mission", "Test description", 1000 ether, 0, requiredSkills
        );

        vm.prank(consultant1);

        vm.expectRevert(ServiceMarketplace.UnauthorizedClient.selector);
        marketplace.postMission(missionId);
    }

    function test_PostMissionRevertsIfNotDraft() public {
        vm.startPrank(client);

        string[] memory requiredSkills = new string[](0);
        uint256 missionId = marketplace.createMission(
            "Test Mission", "Test description", 1000 ether, 0, requiredSkills
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
            "Smart Contract Audit", "Comprehensive audit", 1000 ether, 2, requiredSkills
        );

        marketplace.postMission(missionId);
        vm.stopPrank();

        vm.prank(consultant1);
        marketplace.applyToMission(
            missionId,
            "QmYwAPJzv5CZsnA625s3Xf2nemtYgPpHdWEz79ojWnPbdG",
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
            "Test Mission", "Test description", 1000 ether, 0, requiredSkills
        );

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
            "Test Mission", "Test description", 1000 ether, 0, requiredSkills
        );
        marketplace.postMission(missionId);
        vm.stopPrank();

        vm.startPrank(consultant1);
        marketplace.applyToMission(
            missionId, "QmYwAPJzv5CZsnA625s3Xf2nemtYgPpHdWEz79ojWnPbdG", 800 ether
        );

        vm.expectRevert(ServiceMarketplace.AlreadyApplied.selector);
        marketplace.applyToMission(
            missionId, "QmYwAPJzv5CZsnA625s3Xf2nemtYgPpHdWEz79ojWnPbdG", 800 ether
        );
        vm.stopPrank();
    }

    function test_ApplyToMissionRevertsIfBudgetTooHigh() public {
        vm.startPrank(client);

        string[] memory requiredSkills = new string[](0);
        uint256 missionId = marketplace.createMission(
            "Test Mission", "Test description", 1000 ether, 0, requiredSkills
        );
        marketplace.postMission(missionId);
        vm.stopPrank();

        vm.prank(consultant1);
        vm.expectRevert(ServiceMarketplace.ProposedBudgetTooHigh.selector);
        marketplace.applyToMission(
            missionId, "QmYwAPJzv5CZsnA625s3Xf2nemtYgPpHdWEz79ojWnPbdG", 1001 ether
        );
    }

    function test_ApplyToMissionRevertsIfInsufficientRank() public {
        vm.startPrank(client);

        string[] memory requiredSkills = new string[](0);
        uint256 missionId = marketplace.createMission(
            "Test Mission", "Test description", 1000 ether, 4, requiredSkills
        );
        marketplace.postMission(missionId);
        vm.stopPrank();

        vm.prank(consultant1); // Rang 3 < 4

        vm.expectRevert(ServiceMarketplace.InsufficientRank.selector);
        marketplace.applyToMission(
            missionId, "QmYwAPJzv5CZsnA625s3Xf2nemtYgPpHdWEz79ojWnPbdG", 800 ether
        );
    }

    // ===== Test Select Consultant =====

    function test_SelectConsultant() public {
        vm.startPrank(client);

        string[] memory requiredSkills = new string[](0);
        uint256 missionId = marketplace.createMission(
            "Test Mission", "Test description", 1000 ether, 0, requiredSkills
        );
        marketplace.postMission(missionId);
        vm.stopPrank();

        vm.prank(consultant1);
        marketplace.applyToMission(
            missionId, "QmYwAPJzv5CZsnA625s3Xf2nemtYgPpHdWEz79ojWnPbdG", 800 ether
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
            "Test Mission", "Test description", 1000 ether, 0, requiredSkills
        );
        marketplace.postMission(missionId);
        vm.stopPrank();

        vm.prank(consultant1);
        marketplace.applyToMission(
            missionId, "QmYwAPJzv5CZsnA625s3Xf2nemtYgPpHdWEz79ojWnPbdG", 800 ether
        );

        vm.prank(consultant2); // Pas le client
        vm.expectRevert(ServiceMarketplace.UnauthorizedClient.selector);
        marketplace.selectConsultant(missionId, consultant1);
    }

    // ===== Test Cancel Mission (sans remboursement token — ADR T3) =====

    function test_CancelMission() public {
        vm.startPrank(client);

        string[] memory requiredSkills = new string[](0);
        uint256 missionId = marketplace.createMission(
            "Test Mission", "Test description", 1000 ether, 0, requiredSkills
        );
        marketplace.postMission(missionId);
        marketplace.cancelMission(missionId);

        (,,,,,,ServiceMarketplace.MissionStatus status,,,) = marketplace.missions(missionId);

        // Statut Cancelled — remboursement géré par PSP backend (pas on-chain)
        assertTrue(uint8(status) == uint8(ServiceMarketplace.MissionStatus.Cancelled));

        vm.stopPrank();
    }

    function test_CancelMissionRevertsIfNotClient() public {
        vm.startPrank(client);

        string[] memory requiredSkills = new string[](0);
        uint256 missionId = marketplace.createMission(
            "Test Mission", "Test description", 1000 ether, 0, requiredSkills
        );
        marketplace.postMission(missionId);
        vm.stopPrank();

        vm.prank(consultant1);
        vm.expectRevert(ServiceMarketplace.UnauthorizedClient.selector);
        marketplace.cancelMission(missionId);
    }

    // ===== Test Match Score — algorithme on-chain conservé (Q1) =====

    function test_CalculateMatchScore() public {
        vm.startPrank(client);

        string[] memory requiredSkills = new string[](2);
        requiredSkills[0] = "Solidity";
        requiredSkills[1] = "React";

        uint256 missionId = marketplace.createMission(
            "Smart Contract Audit", "Comprehensive audit", 1000 ether, 2, requiredSkills
        );
        marketplace.postMission(missionId);
        vm.stopPrank();

        // Consultant1 : Rang 3, Skills [Solidity, React, Node.js], 2/2 match
        uint256 matchScore = marketplace.calculateMatchScore(missionId, consultant1, 800 ether);

        // Décomposition attendue :
        // 1. Rang : (3 * 25) / 4 = 18 pts
        // 2. Compétences : (2/2) * 25 = 25 pts
        // 3. Budget : 20 - ((800/1000) * 20) = 4 pts
        // 4. Track record : 0 pt (aucune mission)
        // 5. Réactivité : ~15 pts (candidature immédiate)
        // Total : ~62 pts

        assertTrue(matchScore >= 60 && matchScore <= 65);
    }

    // ===== Coverage gaps — T9 (branches non couverts) =====

    function test_CreateMissionRevertsIfDescriptionTooLong() public {
        vm.prank(client);
        string[] memory requiredSkills = new string[](0);
        string memory longDesc = new string(2001);
        vm.expectRevert(ServiceMarketplace.InvalidDescription.selector);
        marketplace.createMission("Test Mission", longDesc, 1000 ether, 0, requiredSkills);
    }

    function test_CreateMissionRevertsIfInvalidMinRank() public {
        vm.prank(client);
        string[] memory requiredSkills = new string[](0);
        vm.expectRevert(ServiceMarketplace.InvalidMinRank.selector);
        marketplace.createMission("Test Mission", "Test description", 1000 ether, 5, requiredSkills);
    }

    function test_CreateMissionRevertsIfInactiveMember() public {
        // Désactiver le client
        vm.prank(admin);
        membership.setMemberActive(client, false);

        vm.prank(client);
        string[] memory requiredSkills = new string[](0);
        vm.expectRevert(ServiceMarketplace.NotActiveMember.selector);
        marketplace.createMission("Test Mission", "Test description", 1000 ether, 0, requiredSkills);
    }

    function test_ApplyToMissionRevertsIfInvalidProposal() public {
        vm.startPrank(client);
        string[] memory requiredSkills = new string[](0);
        uint256 missionId = marketplace.createMission(
            "Test Mission", "Test description", 1000 ether, 0, requiredSkills
        );
        marketplace.postMission(missionId);
        vm.stopPrank();

        vm.prank(consultant1);
        vm.expectRevert(ServiceMarketplace.InvalidProposal.selector);
        marketplace.applyToMission(missionId, "too-short", 800 ether);
    }

    function test_ApplyToMissionRevertsIfInactiveMember() public {
        vm.startPrank(client);
        string[] memory requiredSkills = new string[](0);
        uint256 missionId = marketplace.createMission(
            "Test Mission", "Test description", 1000 ether, 0, requiredSkills
        );
        marketplace.postMission(missionId);
        vm.stopPrank();

        vm.prank(admin);
        membership.setMemberActive(consultant1, false);

        vm.prank(consultant1);
        vm.expectRevert(ServiceMarketplace.NotActiveMember.selector);
        marketplace.applyToMission(
            missionId, "QmYwAPJzv5CZsnA625s3Xf2nemtYgPpHdWEz79ojWnPbdG", 800 ether
        );
    }

    function test_SelectConsultantRevertsIfMissionNotActive() public {
        vm.startPrank(client);
        string[] memory requiredSkills = new string[](0);
        uint256 missionId = marketplace.createMission(
            "Test Mission", "Test description", 1000 ether, 0, requiredSkills
        );
        // Mission en statut Draft (non publiée)

        vm.expectRevert(ServiceMarketplace.InvalidMissionStatus.selector);
        marketplace.selectConsultant(missionId, consultant1);
        vm.stopPrank();
    }

    function test_SelectConsultantRevertsIfApplicationNotFound() public {
        vm.startPrank(client);
        string[] memory requiredSkills = new string[](0);
        uint256 missionId = marketplace.createMission(
            "Test Mission", "Test description", 1000 ether, 0, requiredSkills
        );
        marketplace.postMission(missionId);

        // consultant1 n'a pas candidaté
        vm.expectRevert(ServiceMarketplace.ApplicationNotFound.selector);
        marketplace.selectConsultant(missionId, consultant1);
        vm.stopPrank();
    }

    function test_CancelMissionRevertsIfInvalidStatus() public {
        vm.startPrank(client);
        string[] memory requiredSkills = new string[](0);
        uint256 missionId = marketplace.createMission(
            "Test Mission", "Test description", 1000 ether, 0, requiredSkills
        );
        // Mission en statut Draft — ni Active ni OnHold → InvalidMissionStatus

        vm.expectRevert(ServiceMarketplace.InvalidMissionStatus.selector);
        marketplace.cancelMission(missionId);
        vm.stopPrank();
    }

    function test_CancelMission_WhenOnHold() public {
        vm.startPrank(client);
        string[] memory requiredSkills = new string[](0);
        uint256 missionId = marketplace.createMission(
            "Test Mission", "Test description", 1000 ether, 0, requiredSkills
        );
        marketplace.postMission(missionId);
        vm.stopPrank();

        vm.prank(consultant1);
        marketplace.applyToMission(
            missionId, "QmYwAPJzv5CZsnA625s3Xf2nemtYgPpHdWEz79ojWnPbdG", 800 ether
        );

        vm.startPrank(client);
        marketplace.selectConsultant(missionId, consultant1);

        // Mission est maintenant OnHold — l'annulation doit réussir
        marketplace.cancelMission(missionId);
        vm.stopPrank();

        (,,,,,,ServiceMarketplace.MissionStatus status,,,) = marketplace.missions(missionId);
        assertTrue(uint8(status) == uint8(ServiceMarketplace.MissionStatus.Cancelled));
    }

    function test_GetMissionApplicants() public {
        vm.startPrank(client);
        string[] memory requiredSkills = new string[](0);
        uint256 missionId = marketplace.createMission(
            "Test Mission", "Test description", 1000 ether, 0, requiredSkills
        );
        marketplace.postMission(missionId);
        vm.stopPrank();

        vm.prank(consultant1);
        marketplace.applyToMission(
            missionId, "QmYwAPJzv5CZsnA625s3Xf2nemtYgPpHdWEz79ojWnPbdG", 800 ether
        );

        vm.prank(consultant2);
        marketplace.applyToMission(
            missionId, "QmYwAPJzv5CZsnA625s3Xf2nemtYgPpHdWEz79ojWnPbdG", 700 ether
        );

        address[] memory applicants = marketplace.getMissionApplicants(missionId);
        assertEq(applicants.length, 2);
    }

    function test_CalculateMatchScore_NoRequiredSkills() public {
        vm.startPrank(client);
        string[] memory requiredSkills = new string[](0); // Aucune compétence requise
        uint256 missionId = marketplace.createMission(
            "No Skills Mission", "Test description", 1000 ether, 0, requiredSkills
        );
        marketplace.postMission(missionId);
        vm.stopPrank();

        // Score compétences = 0 (requiredSkills.length == 0 → branche 0/0)
        uint256 score = marketplace.calculateMatchScore(missionId, consultant1, 500 ether);
        // Rang 3: (3 * 25) / 4 = 18 pts
        // Compétences: 0 (aucune requise → branche else : 0 pts)
        // Budget: ratio = 50 → 20 - (50 * 20) / 100 = 10 pts
        // Track record: 0 pts
        // Réactivité: ~15 pts (immédiat)
        // Total attendu: ~43 pts
        assertTrue(score >= 40 && score <= 50);
    }

    // ===== Coverage gaps — T11 (ComplianceRegistry integration) =====

    /// @dev Consultant sans attestation KBIS → ComplianceCheckFailed
    function test_SelectConsultantRevertsIfNoAttestation() public {
        vm.startPrank(client);
        string[] memory requiredSkills = new string[](0);
        uint256 missionId = marketplace.createMission(
            "Test Mission", "Test description", 1000 ether, 0, requiredSkills
        );
        marketplace.postMission(missionId);
        vm.stopPrank();

        // consultant2 n'a PAS d'attestation KBIS — doit revenir avec ComplianceCheckFailed
        vm.prank(consultant2);
        marketplace.applyToMission(
            missionId, "QmYwAPJzv5CZsnA625s3Xf2nemtYgPpHdWEz79ojWnPbdG", 800 ether
        );

        vm.prank(client);
        vm.expectRevert(ServiceMarketplace.ComplianceCheckFailed.selector);
        marketplace.selectConsultant(missionId, consultant2);
    }

    /// @dev Consultant avec attestation KBIS valide → sélection réussie
    function test_SelectConsultantSucceedsWithValidAttestation() public {
        vm.startPrank(client);
        string[] memory requiredSkills = new string[](0);
        uint256 missionId = marketplace.createMission(
            "Test Mission", "Test description", 1000 ether, 0, requiredSkills
        );
        marketplace.postMission(missionId);
        vm.stopPrank();

        // consultant1 a une attestation KBIS valide (émise dans setUp)
        vm.prank(consultant1);
        marketplace.applyToMission(
            missionId, "QmYwAPJzv5CZsnA625s3Xf2nemtYgPpHdWEz79ojWnPbdG", 800 ether
        );

        vm.prank(client);
        marketplace.selectConsultant(missionId, consultant1);

        (,,,,,,ServiceMarketplace.MissionStatus status, address selected,,) = marketplace.missions(missionId);
        assertTrue(uint8(status) == uint8(ServiceMarketplace.MissionStatus.OnHold));
        assertEq(selected, consultant1);
    }

    /// @dev Attestation révoquée → ComplianceCheckFailed (attestation revoked)
    function test_SelectConsultantRevertsIfAttestationRevoked() public {
        // Révoquer l'attestation KBIS de consultant1 (index 0 = seule attestation émise)
        vm.startPrank(admin);
        complianceRegistry.revokeAttestation(consultant1, 0, "Revoked for test");
        vm.stopPrank();

        vm.startPrank(client);
        string[] memory requiredSkills = new string[](0);
        uint256 missionId = marketplace.createMission(
            "Test Mission", "Test description", 1000 ether, 0, requiredSkills
        );
        marketplace.postMission(missionId);
        vm.stopPrank();

        vm.prank(consultant1);
        marketplace.applyToMission(
            missionId, "QmYwAPJzv5CZsnA625s3Xf2nemtYgPpHdWEz79ojWnPbdG", 800 ether
        );

        vm.prank(client);
        vm.expectRevert(ServiceMarketplace.ComplianceCheckFailed.selector);
        marketplace.selectConsultant(missionId, consultant1);
    }
}
