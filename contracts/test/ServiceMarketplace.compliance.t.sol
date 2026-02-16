// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/ServiceMarketplace.sol";
import "../src/ComplianceRegistry.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * @title ServiceMarketplaceComplianceTest
 * @notice Integration tests for ServiceMarketplace + ComplianceRegistry (Phase 1 KYC)
 * @dev Tests complete workflow: create mission → issue attestation → select consultant
 */
contract ServiceMarketplaceComplianceTest is Test {
    ServiceMarketplace public marketplace;
    ComplianceRegistry public complianceRegistry;
    MockDAOSToken public daosToken;
    MockMembershipContract public membershipContract;

    address admin = makeAddr("admin");
    address client = makeAddr("client");
    address verifier = makeAddr("verifier");
    address consultant = makeAddr("consultant");
    address consultantNoCompliance = makeAddr("consultantNoCompliance");

    function setUp() public {
        // Deploy mock contracts
        daosToken = new MockDAOSToken();
        membershipContract = new MockMembershipContract();

        // Deploy ComplianceRegistry
        complianceRegistry = new ComplianceRegistry();

        // Deploy ServiceMarketplace
        marketplace = new ServiceMarketplace(
            address(daosToken),
            address(membershipContract),
            address(complianceRegistry),
            admin
        );

        // Grant VERIFIER_ROLE
        complianceRegistry.grantRole(complianceRegistry.VERIFIER_ROLE(), verifier);

        // Fund client with DAOS tokens
        daosToken.mint(client, 10000 ether);

        // Client approves marketplace
        vm.prank(client);
        daosToken.approve(address(marketplace), type(uint256).max);

        // Setup mock membership data
        membershipContract.setRank(consultant, 3);
        membershipContract.setRank(consultantNoCompliance, 3);
    }

    /*//////////////////////////////////////////////////////////////
                        INTEGRATION TESTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Test: Full workflow - Create mission → Issue attestations → Select consultant
    function test_Integration_FullWorkflow_Success() public {
        // Step 1: Verifier issues KBIS + URSSAF attestations to consultant
        vm.startPrank(verifier);
        complianceRegistry.issueAttestation(
            consultant,
            ComplianceRegistry.AttestationType.KBIS,
            keccak256("KBIS_123"),
            90
        );
        complianceRegistry.issueAttestation(
            consultant,
            ComplianceRegistry.AttestationType.URSSAF,
            keccak256("URSSAF_456"),
            180
        );
        vm.stopPrank();

        // Step 2: Client creates mission requiring KBIS + URSSAF
        ComplianceRegistry.AttestationType[] memory requiredAttestations = new ComplianceRegistry.AttestationType[](2);
        requiredAttestations[0] = ComplianceRegistry.AttestationType.KBIS;
        requiredAttestations[1] = ComplianceRegistry.AttestationType.URSSAF;

        string[] memory requiredSkills = new string[](1);
        requiredSkills[0] = "Solidity";

        vm.prank(client);
        uint256 missionId = marketplace.createMission(
            "Smart Contract Development",
            1000 ether,
            2, // minRank
            requiredSkills,
            requiredAttestations
        );

        // Step 3: Consultant applies
        vm.prank(consultant);
        marketplace.applyToMission(missionId, "ipfs://proposal", 950 ether);

        // Step 4: Client selects consultant (compliance check passes)
        vm.prank(client);
        marketplace.selectConsultant(missionId, consultant);

        // Verify consultant selected
        (, , , , , , address selectedConsultant, ,) = marketplace.missions(missionId);
        assertEq(selectedConsultant, consultant);
    }

    /// @notice Test: Cannot select consultant without required attestations
    function test_Integration_RevertIfMissingAttestation() public {
        // Create mission requiring KBIS + URSSAF
        ComplianceRegistry.AttestationType[] memory requiredAttestations = new ComplianceRegistry.AttestationType[](2);
        requiredAttestations[0] = ComplianceRegistry.AttestationType.KBIS;
        requiredAttestations[1] = ComplianceRegistry.AttestationType.URSSAF;

        string[] memory requiredSkills = new string[](0);

        vm.prank(client);
        uint256 missionId = marketplace.createMission(
            "Project",
            1000 ether,
            0,
            requiredSkills,
            requiredAttestations
        );

        // Consultant (without attestations) applies
        vm.prank(consultantNoCompliance);
        marketplace.applyToMission(missionId, "ipfs://proposal", 900 ether);

        // Client tries to select consultant → REVERTS (missing attestations)
        vm.expectRevert("Missing required attestation");
        vm.prank(client);
        marketplace.selectConsultant(missionId, consultantNoCompliance);
    }

    /// @notice Test: Cannot select consultant with expired attestation
    function test_Integration_RevertIfExpiredAttestation() public {
        // Issue attestation with 1 day validity
        vm.prank(verifier);
        complianceRegistry.issueAttestation(
            consultant,
            ComplianceRegistry.AttestationType.KBIS,
            keccak256("KBIS_123"),
            1 // 1 day
        );

        // Create mission requiring KBIS
        ComplianceRegistry.AttestationType[] memory requiredAttestations = new ComplianceRegistry.AttestationType[](1);
        requiredAttestations[0] = ComplianceRegistry.AttestationType.KBIS;

        string[] memory requiredSkills = new string[](0);

        vm.prank(client);
        uint256 missionId = marketplace.createMission(
            "Project",
            1000 ether,
            0,
            requiredSkills,
            requiredAttestations
        );

        vm.prank(consultant);
        marketplace.applyToMission(missionId, "ipfs://proposal", 900 ether);

        // Fast-forward 2 days (attestation expires)
        vm.warp(block.timestamp + 2 days);

        // Client tries to select consultant → REVERTS (expired attestation)
        vm.expectRevert("Missing required attestation");
        vm.prank(client);
        marketplace.selectConsultant(missionId, consultant);
    }

    /// @notice Test: Cannot select consultant with revoked attestation
    function test_Integration_RevertIfRevokedAttestation() public {
        // Issue attestation
        vm.prank(verifier);
        complianceRegistry.issueAttestation(
            consultant,
            ComplianceRegistry.AttestationType.KBIS,
            keccak256("KBIS_123"),
            90
        );

        // Create mission requiring KBIS
        ComplianceRegistry.AttestationType[] memory requiredAttestations = new ComplianceRegistry.AttestationType[](1);
        requiredAttestations[0] = ComplianceRegistry.AttestationType.KBIS;

        string[] memory requiredSkills = new string[](0);

        vm.prank(client);
        uint256 missionId = marketplace.createMission(
            "Project",
            1000 ether,
            0,
            requiredSkills,
            requiredAttestations
        );

        vm.prank(consultant);
        marketplace.applyToMission(missionId, "ipfs://proposal", 900 ether);

        // Verifier revokes attestation
        vm.prank(verifier);
        complianceRegistry.revokeAttestation(consultant, 0, "Compliance lost");

        // Client tries to select consultant → REVERTS (revoked attestation)
        vm.expectRevert("Missing required attestation");
        vm.prank(client);
        marketplace.selectConsultant(missionId, consultant);
    }

    /// @notice Test: Mission with no compliance requirements (backward compatibility)
    function test_Integration_NoComplianceRequirements_BackwardCompatible() public {
        // Create mission with EMPTY compliance requirements
        ComplianceRegistry.AttestationType[] memory requiredAttestations = new ComplianceRegistry.AttestationType[](0);
        string[] memory requiredSkills = new string[](0);

        vm.prank(client);
        uint256 missionId = marketplace.createMission(
            "Project",
            1000 ether,
            0,
            requiredSkills,
            requiredAttestations
        );

        vm.prank(consultant);
        marketplace.applyToMission(missionId, "ipfs://proposal", 900 ether);

        // Client selects consultant → SUCCESS (no compliance check)
        vm.prank(client);
        marketplace.selectConsultant(missionId, consultant);

        (, , , , , , address selectedConsultant, ,) = marketplace.missions(missionId);
        assertEq(selectedConsultant, consultant);
    }
}

/*//////////////////////////////////////////////////////////////
                        MOCK CONTRACTS
//////////////////////////////////////////////////////////////*/

contract MockDAOSToken is ERC20 {
    constructor() ERC20("DAOS Token", "DAOS") {}

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}

contract MockMembershipContract {
    mapping(address => uint8) public ranks;
    mapping(address => string[]) public skills;

    function setRank(address user, uint8 rank) external {
        ranks[user] = rank;
    }

    function getRank(address user) external view returns (uint8) {
        return ranks[user];
    }

    function getSkills(address) external pure returns (string[] memory) {
        string[] memory empty = new string[](0);
        return empty;
    }

    function getTrackRecord(address) external pure returns (uint256, uint256) {
        return (5, 85); // 5 completed missions, 85% rating
    }
}
