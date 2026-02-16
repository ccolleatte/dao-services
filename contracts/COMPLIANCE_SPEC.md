# ComplianceRegistry — Spécifications Formelles

**Version** : 1.0.0
**Date** : 2026-02-16
**Issue** : #2 (Phase 1 KYC/Compliance)

## Objectif

Registre on-chain d'attestations de conformité pour consultants. Les entreprises peuvent exiger des attestations valides avant d'assigner une mission.

## Principe Fondamental (GDPR)

**JAMAIS stocker de données personnelles on-chain**. Uniquement :
- Hash IPFS du document (attestation)
- Metadata (verifier, dates, type)
- Pas de nom, adresse, SSN, ou autre PII

## Attestation Types

```solidity
enum AttestationType {
    KBIS,                    // Extrait KBIS <3 mois (France)
    URSSAF,                  // Attestation URSSAF <6 mois (France)
    WORK_AUTHORIZATION,      // Autorisation de travail (non-UE)
    PROFESSIONAL_INSURANCE,  // RC Pro (assurance responsabilité civile)
    TAX_CLEARANCE           // Attestation fiscale <1 an
}
```

## Attestation Struct

```solidity
struct Attestation {
    bytes32 documentHash;    // IPFS hash du document (GDPR-compliant)
    address verifier;        // Expert-comptable, CAC, etc. (trusted third party)
    uint256 issuedAt;        // Timestamp émission
    uint256 expiryDate;      // Timestamp expiration
    AttestationType attestationType;
    bool revoked;            // Révocation possible (right to erasure)
}
```

## Rôles (AccessControl)

- **DEFAULT_ADMIN_ROLE** : DAO admin (grant/revoke roles)
- **VERIFIER_ROLE** : Experts-comptables, CAC, etc. (can issue attestations)

## Fonctions Principales

### 1. issueAttestation (VERIFIER_ROLE)

**Given** : Un verifier avec VERIFIER_ROLE
**When** : Il émet une attestation pour un consultant
**Then** : L'attestation est stockée on-chain avec expiration

```solidity
function issueAttestation(
    address consultant,
    AttestationType attestationType,
    bytes32 documentHash,
    uint256 validityDays
) external onlyRole(VERIFIER_ROLE)
```

**Specifications négatives** :
- ❌ NEVER store full document on-chain
- ❌ NEVER allow self-attestations (consultant can't issue to themselves)
- ❌ NEVER bypass VERIFIER_ROLE check

**Validation** :
- `consultant != address(0)`
- `documentHash != bytes32(0)`
- `validityDays > 0 && validityDays <= 730` (max 2 years)

**Events** :
```solidity
event AttestationIssued(
    address indexed consultant,
    AttestationType attestationType,
    address indexed verifier,
    uint256 expiryDate
);
```

---

### 2. hasValidAttestation (public view)

**Given** : Un consultant avec ou sans attestation
**When** : On vérifie la validité d'une attestation spécifique
**Then** : Retourne `true` seulement si attestation valide (non-expired, non-revoked)

```solidity
function hasValidAttestation(
    address consultant,
    AttestationType attestationType
) public view returns (bool)
```

**Logique** :
```
FOR EACH attestation de consultant:
  IF (
    attestationType == requested_type AND
    expiryDate > block.timestamp AND
    revoked == false
  ) THEN return true

RETURN false (aucune attestation valide trouvée)
```

---

### 3. revokeAttestation (VERIFIER_ROLE)

**Given** : Un verifier avec VERIFIER_ROLE
**When** : Il révoque une attestation existante
**Then** : L'attestation est marquée `revoked = true` (right to erasure - GDPR)

```solidity
function revokeAttestation(
    address consultant,
    uint256 attestationIndex,
    string calldata reason
) external onlyRole(VERIFIER_ROLE)
```

**Validation** :
- `attestationIndex < consultantAttestations[consultant].length`
- Attestation pas déjà révoquée

**Events** :
```solidity
event AttestationRevoked(
    address indexed consultant,
    uint256 attestationIndex,
    address indexed verifier,
    string reason
);
```

---

### 4. getConsultantAttestations (public view)

**Given** : Un consultant
**When** : On récupère toutes ses attestations
**Then** : Retourne array d'attestations (pour export - GDPR data portability)

```solidity
function getConsultantAttestations(
    address consultant
) public view returns (Attestation[] memory)
```

---

## Intégration ServiceMarketplace

### Modification `createMission`

**Before** :
```solidity
function createMission(
    string memory title,
    uint256 budget,
    uint8 minRank,
    string[] memory requiredSkills
)
```

**After** (with compliance) :
```solidity
function createMission(
    string memory title,
    uint256 budget,
    uint8 minRank,
    string[] memory requiredSkills,
    AttestationType[] memory requiredAttestations  // NOUVEAU
)
```

**Storage** :
```solidity
mapping(uint256 => AttestationType[]) public missionRequirements;
```

**Logic** :
```solidity
missionRequirements[missionId] = requiredAttestations;
```

---

### Modification `selectConsultant`

**Before** : Aucune vérification compliance

**After** (with compliance) :
```solidity
function selectConsultant(
    uint256 missionId,
    address consultant
) external nonReentrant {
    Mission storage mission = missions[missionId];

    // NOUVEAU : Vérification compliance
    AttestationType[] memory required = missionRequirements[missionId];
    for (uint256 i = 0; i < required.length; i++) {
        require(
            complianceRegistry.hasValidAttestation(consultant, required[i]),
            "Missing required attestation"
        );
    }

    // ... reste logique existante
}
```

**Dependency injection** :
```solidity
ComplianceRegistry public complianceRegistry;

function setComplianceRegistry(address _complianceRegistry)
    external onlyRole(ADMIN_ROLE)
{
    complianceRegistry = ComplianceRegistry(_complianceRegistry);
}
```

---

## Tests (TDD)

### Test Suite 1 : ComplianceRegistry.t.sol

**Setup** :
```solidity
contract ComplianceRegistryTest is Test {
    ComplianceRegistry public registry;
    address admin = makeAddr("admin");
    address verifier = makeAddr("verifier");
    address consultant = makeAddr("consultant");
}
```

**Tests** :
1. ✅ `test_IssueAttestation_Success`
   - Verifier peut émettre attestation KBIS
   - Event `AttestationIssued` émis
   - Attestation stockée correctement

2. ✅ `test_IssueAttestation_RevertIfNotVerifier`
   - Non-verifier ne peut pas émettre attestation
   - Revert avec `AccessControlUnauthorizedAccount`

3. ✅ `test_HasValidAttestation_True`
   - Consultant avec KBIS valide → `hasValidAttestation` retourne `true`

4. ✅ `test_HasValidAttestation_False_Expired`
   - Attestation expirée → `hasValidAttestation` retourne `false`

5. ✅ `test_HasValidAttestation_False_Revoked`
   - Attestation révoquée → `hasValidAttestation` retourne `false`

6. ✅ `test_RevokeAttestation_Success`
   - Verifier peut révoquer attestation
   - Event `AttestationRevoked` émis
   - `revoked = true` après révocation

7. ✅ `test_GetConsultantAttestations_ExportData`
   - Data portability (GDPR)
   - Retourne array d'attestations

---

### Test Suite 2 : ServiceMarketplace.t.sol (Integration)

**Tests** :
1. ✅ `test_CreateMission_WithComplianceRequirements`
   - Mission créée avec 2 attestations requises (KBIS + URSSAF)
   - `missionRequirements` stocké correctement

2. ✅ `test_SelectConsultant_RevertIfMissingAttestation`
   - Consultant sans KBIS
   - `selectConsultant` revert avec `"Missing required attestation"`

3. ✅ `test_SelectConsultant_SuccessWithValidAttestations`
   - Consultant avec KBIS + URSSAF valides
   - `selectConsultant` réussit

---

## Coverage Target

- **Lines** : ≥80%
- **Branches** : ≥70%
- **Functions** : 100%

---

## Sécurité (Checklist)

- [x] OpenZeppelin AccessControl (role-based)
- [x] No reentrancy risk (view functions only)
- [x] No personal data on-chain (hash-only)
- [x] Event logs pour audit trail
- [x] Input validation (address(0), bounds)
- [x] Right to erasure (revocation mechanism)

---

## Déploiement (Paseo Testnet)

**Script** : `script/DeployCompliance.s.sol`

**Steps** :
1. Deploy `ComplianceRegistry`
2. Grant `VERIFIER_ROLE` to 3-5 verifiers
3. Deploy or upgrade `ServiceMarketplace` with compliance integration
4. Test flow E2E (create mission → issue attestation → select consultant)

---

**Dernière mise à jour** : 2026-02-16
**Auteur** : Claude Sonnet 4.5
**Review** : Pending
