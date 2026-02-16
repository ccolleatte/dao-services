// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/AccessControl.sol";

/**
 * @title ComplianceRegistry
 * @notice On-chain registry of compliance attestations for consultants (KYC/Compliance Phase 1)
 * @dev GDPR-compliant: Only stores hashes on-chain, no personal data (PII)
 *
 * Key Features:
 * - Hash-only storage (IPFS document hashes)
 * - Role-based access control (VERIFIER_ROLE)
 * - Expiration mechanism (time-bound attestations)
 * - Revocation support (right to erasure - GDPR Article 17)
 * - Data portability (export attestations - GDPR Article 20)
 *
 * Integration:
 * - ServiceMarketplace checks attestations before mission assignment
 * - Trusted third parties (verifiers) issue attestations
 *
 * @custom:security-contact security@dao-services.example
 */
contract ComplianceRegistry is AccessControl {
    /*//////////////////////////////////////////////////////////////
                                TYPES
    //////////////////////////////////////////////////////////////*/

    /// @notice Types of compliance attestations supported
    enum AttestationType {
        KBIS,                    // Company registration (France) - Valid 3 months
        URSSAF,                  // Social security compliance (France) - Valid 6 months
        WORK_AUTHORIZATION,      // Work permit for non-EU consultants
        PROFESSIONAL_INSURANCE,  // Professional liability insurance (RC Pro)
        TAX_CLEARANCE           // Tax compliance certificate - Valid 1 year
    }

    /// @notice Attestation structure (GDPR-compliant)
    /// @dev Only stores hash + metadata, NO personal data on-chain
    struct Attestation {
        bytes32 documentHash;         // IPFS hash of attestation document
        address verifier;             // Address of trusted third party who issued attestation
        uint256 issuedAt;             // Timestamp when attestation was issued
        uint256 expiryDate;           // Timestamp when attestation expires
        AttestationType attestationType; // Type of attestation (KBIS, URSSAF, etc.)
        bool revoked;                 // Revocation status (GDPR right to erasure)
    }

    /*//////////////////////////////////////////////////////////////
                            STATE VARIABLES
    //////////////////////////////////////////////////////////////*/

    /// @notice Role for trusted verifiers (experts-comptables, accounting firms, etc.)
    bytes32 public constant VERIFIER_ROLE = keccak256("VERIFIER_ROLE");

    /// @notice Mapping: consultant address => array of attestations
    /// @dev Consultant can have multiple attestations (different types, renewals)
    mapping(address => Attestation[]) public consultantAttestations;

    /*//////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Emitted when a verifier issues an attestation
    /// @param consultant Address of consultant receiving attestation
    /// @param attestationType Type of attestation issued
    /// @param verifier Address of verifier who issued attestation
    /// @param expiryDate Timestamp when attestation expires
    event AttestationIssued(
        address indexed consultant,
        AttestationType attestationType,
        address indexed verifier,
        uint256 expiryDate
    );

    /// @notice Emitted when a verifier revokes an attestation
    /// @param consultant Address of consultant whose attestation was revoked
    /// @param attestationIndex Index of revoked attestation in consultant's attestation array
    /// @param verifier Address of verifier who revoked attestation
    /// @param reason Reason for revocation (GDPR compliance, audit trail)
    event AttestationRevoked(
        address indexed consultant,
        uint256 attestationIndex,
        address indexed verifier,
        string reason
    );

    /*//////////////////////////////////////////////////////////////
                                ERRORS
    //////////////////////////////////////////////////////////////*/

    /// @notice Consultant address cannot be zero
    error InvalidConsultant();

    /// @notice Document hash cannot be zero
    error InvalidDocumentHash();

    /// @notice Validity period must be >0 and <=730 days (2 years max)
    error InvalidValidityPeriod();

    /// @notice Attestation index out of bounds
    error InvalidAttestationIndex();

    /*//////////////////////////////////////////////////////////////
                            CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /// @notice Initialize ComplianceRegistry with admin role
    /// @dev Grants DEFAULT_ADMIN_ROLE to deployer
    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /*//////////////////////////////////////////////////////////////
                        CORE FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Issue a compliance attestation for a consultant
     * @dev Only callable by addresses with VERIFIER_ROLE
     * @param consultant Address of consultant receiving attestation
     * @param attestationType Type of attestation (KBIS, URSSAF, etc.)
     * @param documentHash IPFS hash of attestation document (GDPR-compliant: no PII)
     * @param validityDays Number of days attestation is valid (max 730 = 2 years)
     *
     * Requirements:
     * - Caller must have VERIFIER_ROLE
     * - consultant != address(0)
     * - documentHash != bytes32(0)
     * - validityDays > 0 && validityDays <= 730
     *
     * Emits:
     * - AttestationIssued event
     *
     * @custom:security Role-based access control prevents unauthorized attestation issuance
     */
    function issueAttestation(
        address consultant,
        AttestationType attestationType,
        bytes32 documentHash,
        uint256 validityDays
    ) external onlyRole(VERIFIER_ROLE) {
        // Input validation
        if (consultant == address(0)) revert InvalidConsultant();
        if (documentHash == bytes32(0)) revert InvalidDocumentHash();
        if (validityDays == 0 || validityDays > 730) revert InvalidValidityPeriod();

        // Calculate expiry date
        uint256 expiryDate = block.timestamp + (validityDays * 1 days);

        // Create attestation
        consultantAttestations[consultant].push(Attestation({
            documentHash: documentHash,
            verifier: msg.sender,
            issuedAt: block.timestamp,
            expiryDate: expiryDate,
            attestationType: attestationType,
            revoked: false
        }));

        emit AttestationIssued(consultant, attestationType, msg.sender, expiryDate);
    }

    /**
     * @notice Check if consultant has a valid attestation of specified type
     * @dev Public view function for ServiceMarketplace integration
     * @param consultant Address of consultant to check
     * @param attestationType Type of attestation to verify
     * @return bool True if consultant has valid (non-expired, non-revoked) attestation
     *
     * Logic:
     * - Iterates through consultant's attestations
     * - Returns true if ANY attestation matches type AND is not expired AND is not revoked
     * - Returns false if no valid attestation found
     *
     * @custom:integration Used by ServiceMarketplace.selectConsultant() to verify compliance
     */
    function hasValidAttestation(
        address consultant,
        AttestationType attestationType
    ) public view returns (bool) {
        Attestation[] memory attestations = consultantAttestations[consultant];

        for (uint256 i = 0; i < attestations.length; i++) {
            if (
                attestations[i].attestationType == attestationType &&
                attestations[i].expiryDate > block.timestamp &&
                !attestations[i].revoked
            ) {
                return true;
            }
        }

        return false;
    }

    /**
     * @notice Revoke an attestation (GDPR right to erasure - Article 17)
     * @dev Only callable by addresses with VERIFIER_ROLE
     * @param consultant Address of consultant whose attestation to revoke
     * @param attestationIndex Index of attestation in consultant's attestation array
     * @param reason Reason for revocation (audit trail for GDPR compliance)
     *
     * Requirements:
     * - Caller must have VERIFIER_ROLE
     * - attestationIndex must be valid
     *
     * Emits:
     * - AttestationRevoked event
     *
     * Note:
     * - Attestation is marked as revoked (not deleted) for audit trail
     * - Revoked attestations fail hasValidAttestation() check
     *
     * @custom:gdpr Implements right to erasure while maintaining audit trail
     */
    function revokeAttestation(
        address consultant,
        uint256 attestationIndex,
        string calldata reason
    ) external onlyRole(VERIFIER_ROLE) {
        Attestation[] storage attestations = consultantAttestations[consultant];

        if (attestationIndex >= attestations.length) revert InvalidAttestationIndex();

        attestations[attestationIndex].revoked = true;

        emit AttestationRevoked(consultant, attestationIndex, msg.sender, reason);
    }

    /**
     * @notice Get all attestations for a consultant (GDPR data portability - Article 20)
     * @dev Public view function for data export
     * @param consultant Address of consultant
     * @return Attestation[] Array of all attestations (including expired and revoked)
     *
     * Use cases:
     * - Consultant exports their data (GDPR compliance)
     * - Frontend displays attestation history
     * - Audits and compliance checks
     *
     * @custom:gdpr Implements data portability right
     */
    function getConsultantAttestations(
        address consultant
    ) public view returns (Attestation[] memory) {
        return consultantAttestations[consultant];
    }

    /*//////////////////////////////////////////////////////////////
                        ADMIN FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Grant VERIFIER_ROLE to a trusted third party
     * @dev Only callable by DEFAULT_ADMIN_ROLE
     * @param verifier Address to grant VERIFIER_ROLE
     *
     * Typical verifiers:
     * - Experts-comptables (accounting firms)
     * - Commissaires aux comptes (CAC)
     * - Insurance companies (for RC Pro attestations)
     * - Government agencies (for official documents)
     *
     * @custom:security Carefully vet verifiers before granting role
     */
    function grantVerifierRole(address verifier) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _grantRole(VERIFIER_ROLE, verifier);
    }

    /**
     * @notice Revoke VERIFIER_ROLE from an address
     * @dev Only callable by DEFAULT_ADMIN_ROLE
     * @param verifier Address to revoke VERIFIER_ROLE from
     *
     * Use cases:
     * - Verifier partnership ended
     * - Verifier violated terms of service
     * - Security incident
     */
    function revokeVerifierRole(address verifier) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _revokeRole(VERIFIER_ROLE, verifier);
    }
}
