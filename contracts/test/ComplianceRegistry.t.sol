// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/ComplianceRegistry.sol";

/**
 * @title ComplianceRegistryTest
 * @notice Test suite for ComplianceRegistry contract (Phase 1 KYC/Compliance)
 * @dev TDD approach: Tests written BEFORE implementation
 */
contract ComplianceRegistryTest is Test {
    ComplianceRegistry public registry;

    address admin = makeAddr("admin");
    address verifier1 = makeAddr("verifier1");
    address verifier2 = makeAddr("verifier2");
    address consultant = makeAddr("consultant");
    address nonVerifier = makeAddr("nonVerifier");

    // Events (for testing)
    event AttestationIssued(
        address indexed consultant,
        ComplianceRegistry.AttestationType attestationType,
        address indexed verifier,
        uint256 expiryDate
    );

    event AttestationRevoked(
        address indexed consultant,
        uint256 attestationIndex,
        address indexed verifier,
        string reason
    );

    function setUp() public {
        // Deploy contract (msg.sender = this test contract)
        registry = new ComplianceRegistry();

        // Grant VERIFIER_ROLE to verifier1
        registry.grantRole(registry.VERIFIER_ROLE(), verifier1);

        // Grant VERIFIER_ROLE to verifier2
        registry.grantRole(registry.VERIFIER_ROLE(), verifier2);
    }

    /*//////////////////////////////////////////////////////////////
                        POSITIVE TEST CASES
    //////////////////////////////////////////////////////////////*/

    /// @notice Test: Verifier can issue KBIS attestation
    function test_IssueAttestation_KBIS_Success() public {
        bytes32 documentHash = keccak256("KBIS_IPFS_HASH_123");
        uint256 validityDays = 90; // 3 months

        // Expect event emission
        vm.expectEmit(true, true, true, true);
        emit AttestationIssued(
            consultant,
            ComplianceRegistry.AttestationType.KBIS,
            verifier1,
            block.timestamp + (validityDays * 1 days)
        );

        // Issue attestation
        vm.prank(verifier1);
        registry.issueAttestation(
            consultant,
            ComplianceRegistry.AttestationType.KBIS,
            documentHash,
            validityDays
        );

        // Verify attestation is valid
        assertTrue(
            registry.hasValidAttestation(
                consultant,
                ComplianceRegistry.AttestationType.KBIS
            )
        );
    }

    /// @notice Test: Verifier can issue URSSAF attestation
    function test_IssueAttestation_URSSAF_Success() public {
        bytes32 documentHash = keccak256("URSSAF_IPFS_HASH_456");
        uint256 validityDays = 180; // 6 months

        vm.prank(verifier1);
        registry.issueAttestation(
            consultant,
            ComplianceRegistry.AttestationType.URSSAF,
            documentHash,
            validityDays
        );

        assertTrue(
            registry.hasValidAttestation(
                consultant,
                ComplianceRegistry.AttestationType.URSSAF
            )
        );
    }

    /// @notice Test: Verifier can issue multiple attestations for same consultant
    function test_IssueAttestation_MultipleTypes_Success() public {
        bytes32 kbisHash = keccak256("KBIS_123");
        bytes32 urssafHash = keccak256("URSSAF_456");
        bytes32 insuranceHash = keccak256("INSURANCE_789");

        // Issue KBIS
        vm.prank(verifier1);
        registry.issueAttestation(
            consultant,
            ComplianceRegistry.AttestationType.KBIS,
            kbisHash,
            90
        );

        // Issue URSSAF
        vm.prank(verifier1);
        registry.issueAttestation(
            consultant,
            ComplianceRegistry.AttestationType.URSSAF,
            urssafHash,
            180
        );

        // Issue Professional Insurance
        vm.prank(verifier2);
        registry.issueAttestation(
            consultant,
            ComplianceRegistry.AttestationType.PROFESSIONAL_INSURANCE,
            insuranceHash,
            365
        );

        // Verify all 3 attestations are valid
        assertTrue(registry.hasValidAttestation(consultant, ComplianceRegistry.AttestationType.KBIS));
        assertTrue(registry.hasValidAttestation(consultant, ComplianceRegistry.AttestationType.URSSAF));
        assertTrue(registry.hasValidAttestation(consultant, ComplianceRegistry.AttestationType.PROFESSIONAL_INSURANCE));
    }

    /// @notice Test: Get consultant attestations (data portability - GDPR)
    function test_GetConsultantAttestations_DataPortability() public {
        bytes32 kbisHash = keccak256("KBIS_123");
        bytes32 urssafHash = keccak256("URSSAF_456");

        vm.prank(verifier1);
        registry.issueAttestation(
            consultant,
            ComplianceRegistry.AttestationType.KBIS,
            kbisHash,
            90
        );

        vm.prank(verifier1);
        registry.issueAttestation(
            consultant,
            ComplianceRegistry.AttestationType.URSSAF,
            urssafHash,
            180
        );

        // Get all attestations
        ComplianceRegistry.Attestation[] memory attestations = registry.getConsultantAttestations(consultant);

        // Verify 2 attestations returned
        assertEq(attestations.length, 2);
        assertEq(attestations[0].documentHash, kbisHash);
        assertEq(attestations[1].documentHash, urssafHash);
        assertEq(attestations[0].verifier, verifier1);
    }

    /// @notice Test: Revoke attestation (right to erasure - GDPR)
    function test_RevokeAttestation_Success() public {
        bytes32 documentHash = keccak256("KBIS_123");

        // Issue attestation
        vm.prank(verifier1);
        registry.issueAttestation(
            consultant,
            ComplianceRegistry.AttestationType.KBIS,
            documentHash,
            90
        );

        // Verify valid before revocation
        assertTrue(registry.hasValidAttestation(consultant, ComplianceRegistry.AttestationType.KBIS));

        // Expect revocation event
        vm.expectEmit(true, true, true, true);
        emit AttestationRevoked(consultant, 0, verifier1, "Consultant requested erasure");

        // Revoke attestation
        vm.prank(verifier1);
        registry.revokeAttestation(consultant, 0, "Consultant requested erasure");

        // Verify invalid after revocation
        assertFalse(registry.hasValidAttestation(consultant, ComplianceRegistry.AttestationType.KBIS));
    }

    /*//////////////////////////////////////////////////////////////
                        EXPIRY TEST CASES
    //////////////////////////////////////////////////////////////*/

    /// @notice Test: Expired attestation returns false
    function test_HasValidAttestation_False_Expired() public {
        bytes32 documentHash = keccak256("KBIS_123");
        uint256 validityDays = 1; // 1 day

        vm.prank(verifier1);
        registry.issueAttestation(
            consultant,
            ComplianceRegistry.AttestationType.KBIS,
            documentHash,
            validityDays
        );

        // Verify valid immediately
        assertTrue(registry.hasValidAttestation(consultant, ComplianceRegistry.AttestationType.KBIS));

        // Fast-forward 2 days (past expiry)
        vm.warp(block.timestamp + 2 days);

        // Verify invalid after expiry
        assertFalse(registry.hasValidAttestation(consultant, ComplianceRegistry.AttestationType.KBIS));
    }

    /// @notice Test: Attestation valid exactly at expiry timestamp
    function test_HasValidAttestation_EdgeCase_ExactExpiry() public {
        bytes32 documentHash = keccak256("KBIS_123");
        uint256 validityDays = 90;

        vm.prank(verifier1);
        registry.issueAttestation(
            consultant,
            ComplianceRegistry.AttestationType.KBIS,
            documentHash,
            validityDays
        );

        // Fast-forward to EXACTLY expiry time
        uint256 expiryTimestamp = block.timestamp + (validityDays * 1 days);
        vm.warp(expiryTimestamp);

        // Should be invalid at exact expiry time (expiryDate > block.timestamp)
        assertFalse(registry.hasValidAttestation(consultant, ComplianceRegistry.AttestationType.KBIS));
    }

    /*//////////////////////////////////////////////////////////////
                        NEGATIVE TEST CASES
    //////////////////////////////////////////////////////////////*/

    /// @notice Test: Non-verifier cannot issue attestation (AccessControl)
    function test_IssueAttestation_RevertIfNotVerifier() public {
        bytes32 documentHash = keccak256("KBIS_123");

        vm.expectRevert(); // AccessControl revert
        vm.prank(nonVerifier);
        registry.issueAttestation(
            consultant,
            ComplianceRegistry.AttestationType.KBIS,
            documentHash,
            90
        );
    }

    /// @notice Test: Cannot issue attestation to address(0)
    function test_IssueAttestation_RevertIfZeroAddress() public {
        bytes32 documentHash = keccak256("KBIS_123");

        vm.expectRevert(ComplianceRegistry.InvalidConsultant.selector);
        vm.prank(verifier1);
        registry.issueAttestation(
            address(0),
            ComplianceRegistry.AttestationType.KBIS,
            documentHash,
            90
        );
    }

    /// @notice Test: Cannot issue attestation with zero document hash
    function test_IssueAttestation_RevertIfZeroHash() public {
        vm.expectRevert(ComplianceRegistry.InvalidDocumentHash.selector);
        vm.prank(verifier1);
        registry.issueAttestation(
            consultant,
            ComplianceRegistry.AttestationType.KBIS,
            bytes32(0),
            90
        );
    }

    /// @notice Test: Cannot issue attestation with zero validity days
    function test_IssueAttestation_RevertIfZeroValidity() public {
        bytes32 documentHash = keccak256("KBIS_123");

        vm.expectRevert(ComplianceRegistry.InvalidValidityPeriod.selector);
        vm.prank(verifier1);
        registry.issueAttestation(
            consultant,
            ComplianceRegistry.AttestationType.KBIS,
            documentHash,
            0
        );
    }

    /// @notice Test: Cannot issue attestation with validity >2 years (730 days)
    function test_IssueAttestation_RevertIfExcessiveValidity() public {
        bytes32 documentHash = keccak256("KBIS_123");

        vm.expectRevert(ComplianceRegistry.InvalidValidityPeriod.selector);
        vm.prank(verifier1);
        registry.issueAttestation(
            consultant,
            ComplianceRegistry.AttestationType.KBIS,
            documentHash,
            731 // >730 days
        );
    }

    /// @notice Test: Cannot revoke attestation if index out of bounds
    function test_RevokeAttestation_RevertIfInvalidIndex() public {
        vm.expectRevert(ComplianceRegistry.InvalidAttestationIndex.selector);
        vm.prank(verifier1);
        registry.revokeAttestation(consultant, 0, "Test");
    }

    /// @notice Test: hasValidAttestation returns false if no attestation exists
    function test_HasValidAttestation_False_NoAttestation() public {
        assertFalse(registry.hasValidAttestation(consultant, ComplianceRegistry.AttestationType.KBIS));
    }

    /// @notice Test: hasValidAttestation returns false if revoked
    function test_HasValidAttestation_False_Revoked() public {
        bytes32 documentHash = keccak256("KBIS_123");

        vm.prank(verifier1);
        registry.issueAttestation(
            consultant,
            ComplianceRegistry.AttestationType.KBIS,
            documentHash,
            90
        );

        // Revoke
        vm.prank(verifier1);
        registry.revokeAttestation(consultant, 0, "Test revocation");

        // Verify invalid after revocation
        assertFalse(registry.hasValidAttestation(consultant, ComplianceRegistry.AttestationType.KBIS));
    }

    /*//////////////////////////////////////////////////////////////
                        EDGE CASES
    //////////////////////////////////////////////////////////////*/

    /// @notice Test: Multiple attestations of same type (newest should be valid)
    function test_MultipleAttestations_SameType_NewestValid() public {
        bytes32 oldHash = keccak256("KBIS_OLD");
        bytes32 newHash = keccak256("KBIS_NEW");

        // Issue old KBIS (expires in 1 day)
        vm.prank(verifier1);
        registry.issueAttestation(
            consultant,
            ComplianceRegistry.AttestationType.KBIS,
            oldHash,
            1
        );

        // Issue new KBIS (expires in 90 days)
        vm.prank(verifier1);
        registry.issueAttestation(
            consultant,
            ComplianceRegistry.AttestationType.KBIS,
            newHash,
            90
        );

        // Fast-forward 2 days (old expired, new still valid)
        vm.warp(block.timestamp + 2 days);

        // Should still be valid (new attestation)
        assertTrue(registry.hasValidAttestation(consultant, ComplianceRegistry.AttestationType.KBIS));

        // Verify 2 attestations stored
        ComplianceRegistry.Attestation[] memory attestations = registry.getConsultantAttestations(consultant);
        assertEq(attestations.length, 2);
    }

    /// @notice Test: Different verifiers can issue attestations
    function test_MultipleVerifiers_CanIssue() public {
        bytes32 hash1 = keccak256("VERIFIER1");
        bytes32 hash2 = keccak256("VERIFIER2");

        vm.prank(verifier1);
        registry.issueAttestation(
            consultant,
            ComplianceRegistry.AttestationType.KBIS,
            hash1,
            90
        );

        vm.prank(verifier2);
        registry.issueAttestation(
            consultant,
            ComplianceRegistry.AttestationType.URSSAF,
            hash2,
            180
        );

        assertTrue(registry.hasValidAttestation(consultant, ComplianceRegistry.AttestationType.KBIS));
        assertTrue(registry.hasValidAttestation(consultant, ComplianceRegistry.AttestationType.URSSAF));
    }

    /*//////////////////////////////////////////////////////////////
                        ADMIN FUNCTIONS TESTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Test: Admin can grant VERIFIER_ROLE
    function test_GrantVerifierRole_Success() public {
        address newVerifier = makeAddr("newVerifier");

        // Grant role (test contract is admin)
        registry.grantVerifierRole(newVerifier);

        // Verify new verifier can issue attestations
        vm.prank(newVerifier);
        registry.issueAttestation(
            consultant,
            ComplianceRegistry.AttestationType.TAX_CLEARANCE,
            keccak256("TAX_123"),
            365
        );

        assertTrue(registry.hasValidAttestation(consultant, ComplianceRegistry.AttestationType.TAX_CLEARANCE));
    }

    /// @notice Test: Admin can revoke VERIFIER_ROLE
    function test_RevokeVerifierRole_Success() public {
        // Revoke verifier1's role
        registry.revokeVerifierRole(verifier1);

        // Verify verifier1 can no longer issue attestations
        vm.expectRevert(); // AccessControl revert
        vm.prank(verifier1);
        registry.issueAttestation(
            consultant,
            ComplianceRegistry.AttestationType.KBIS,
            keccak256("KBIS_123"),
            90
        );
    }

    /*//////////////////////////////////////////////////////////////
                    P1 FIX - DOS PREVENTION TESTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Test: P1 Fix - Revert if max attestations reached (50 limit)
    function test_RevertIf_MaxAttestationsReached() public {
        // Issue 50 attestations (max limit)
        for (uint256 i = 0; i < 50; i++) {
            vm.prank(verifier1);
            registry.issueAttestation(
                consultant,
                ComplianceRegistry.AttestationType.KBIS,
                keccak256(abi.encodePacked("KBIS", i)),
                90
            );
        }

        // Verify 50 attestations exist
        ComplianceRegistry.Attestation[] memory attestations = registry.getConsultantAttestations(consultant);
        assertEq(attestations.length, 50);

        // Attempt to issue 51st attestation (should revert)
        vm.expectRevert(ComplianceRegistry.MaxAttestationsReached.selector);
        vm.prank(verifier1);
        registry.issueAttestation(
            consultant,
            ComplianceRegistry.AttestationType.KBIS,
            keccak256("KBIS_51"),
            90
        );
    }

    /// @notice Test: P1 Fix - Accept exactly 50 attestations (boundary)
    function test_Accept_ExactlyFiftyAttestations() public {
        // Issue exactly 50 attestations (max limit)
        for (uint256 i = 0; i < 50; i++) {
            vm.prank(verifier1);
            registry.issueAttestation(
                consultant,
                ComplianceRegistry.AttestationType.KBIS,
                keccak256(abi.encodePacked("KBIS", i)),
                90
            );
        }

        // Verify 50 attestations exist
        ComplianceRegistry.Attestation[] memory attestations = registry.getConsultantAttestations(consultant);
        assertEq(attestations.length, 50);

        // Verify last attestation is valid
        assertEq(attestations[49].documentHash, keccak256(abi.encodePacked("KBIS", uint256(49))));
        assertEq(attestations[49].verifier, verifier1);
    }

    /// @notice Test: P1 Fix - Revoked attestations still count toward limit
    function test_RevokedAttestationsCountTowardLimit() public {
        // Issue 50 attestations
        for (uint256 i = 0; i < 50; i++) {
            vm.prank(verifier1);
            registry.issueAttestation(
                consultant,
                ComplianceRegistry.AttestationType.KBIS,
                keccak256(abi.encodePacked("KBIS", i)),
                90
            );
        }

        // Revoke first attestation
        vm.prank(verifier1);
        registry.revokeAttestation(consultant, 0, "Test revocation");

        // Verify attestation is revoked
        ComplianceRegistry.Attestation[] memory attestations = registry.getConsultantAttestations(consultant);
        assertTrue(attestations[0].revoked);

        // Attempt to issue new attestation (should still revert - revoked count toward limit)
        vm.expectRevert(ComplianceRegistry.MaxAttestationsReached.selector);
        vm.prank(verifier1);
        registry.issueAttestation(
            consultant,
            ComplianceRegistry.AttestationType.KBIS,
            keccak256("KBIS_NEW"),
            90
        );
    }
}
