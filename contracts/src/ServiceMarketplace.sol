// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./DAOMembership.sol";
import "./ComplianceRegistry.sol";

/**
 * @title ServiceMarketplace
 * @notice Phase 3 MVP — Matching on-chain transparent, paiement via PSP (Mangopay/Stripe Connect)
 * @dev Implements mission lifecycle (Draft → Active → OnHold → Completed/Cancelled)
 *      5-criteria match score: Rank (25%), Skills (25%), Budget (20%), Track Record (15%), Responsiveness (15%)
 *      Pas de token DAOS on-chain — les paiements sont gérés par le PSP (ADR 2026-02-18)
 */
contract ServiceMarketplace is AccessControl, ReentrancyGuard {
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    // ===== Enums =====

    enum MissionStatus {
        Draft,      // Créée, pas encore publiée
        Active,     // Publiée, candidatures ouvertes
        OnHold,     // Consultant sélectionné, contrat PSP en attente
        Completed,  // Tous les jalons validés
        Cancelled   // Annulée par le client ou le système
    }

    // ===== Structs =====

    struct Mission {
        uint256 id;
        address client;
        string title;                    // Max 200 chars
        string description;              // Max 2000 chars
        uint256 budget;                  // Budget en EUR centimes (géré par PSP)
        uint8 minRank;                   // 0-4 (rang DAO requis)
        string[] requiredSkills;         // Max 10 compétences
        MissionStatus status;
        address selectedConsultant;
        uint256 createdAt;
        uint256 updatedAt;
    }

    struct Application {
        uint256 missionId;
        address consultant;
        string proposal;                 // Hash IPFS du document de candidature (46 chars)
        uint256 proposedBudget;
        uint256 submittedAt;
        uint256 matchScore;              // 0-100 calculé on-chain
    }

    // ===== State Variables =====

    uint256 public nextMissionId;
    mapping(uint256 => Mission) public missions;

    // Applications: clé composite keccak256(abi.encodePacked(missionId, consultant))
    mapping(bytes32 => Application) public applications;

    // Index des candidatures par mission
    mapping(uint256 => address[]) public missionApplicants;

    DAOMembership public immutable membership;
    ComplianceRegistry public immutable complianceRegistry;

    // ===== Events =====

    event MissionCreated(
        uint256 indexed missionId,
        address indexed client,
        uint256 budget,
        uint8 minRank
    );

    event MissionPosted(
        uint256 indexed missionId
    );

    event ApplicationSubmitted(
        uint256 indexed missionId,
        address indexed consultant,
        uint256 matchScore
    );

    event ConsultantSelected(
        uint256 indexed missionId,
        address indexed consultant,
        uint256 matchScore
    );

    event MissionCancelled(
        uint256 indexed missionId,
        address indexed client
    );

    // ===== Errors =====

    error InvalidBudget();
    error InvalidTitle();
    error InvalidDescription();
    error InvalidMinRank();
    error TooManySkills();
    error MissionNotDraft();
    error MissionNotActive();
    error AlreadyApplied();
    error InsufficientRank();
    error UnauthorizedClient();
    error InvalidMissionStatus();
    error ProposedBudgetTooHigh();
    error InvalidProposal();
    error NotActiveMember();
    error ApplicationNotFound();
    error ConsultantNotActive();
    error ComplianceCheckFailed();

    // ===== Constructor =====

    constructor(
        address _membership,
        address _complianceRegistry,
        address _admin
    ) {
        membership = DAOMembership(_membership);
        complianceRegistry = ComplianceRegistry(_complianceRegistry);
        _grantRole(DEFAULT_ADMIN_ROLE, _admin);
        _grantRole(ADMIN_ROLE, _admin);
    }

    // ===== Core Functions =====

    /**
     * @notice Créer une nouvelle mission (statut Draft)
     * @param title Titre de la mission (max 200 chars)
     * @param description Description détaillée (max 2000 chars)
     * @param budget Budget en EUR centimes (le paiement est géré par le PSP)
     * @param minRank Rang DAO minimum requis (0-4)
     * @param requiredSkills Compétences requises (max 10)
     */
    function createMission(
        string memory title,
        string memory description,
        uint256 budget,
        uint8 minRank,
        string[] memory requiredSkills
    ) external returns (uint256) {
        // Vérifier que l'appelant est un membre actif de la DAO
        if (!membership.isMember(msg.sender)) revert NotActiveMember();
        (,,,, bool active,,) = membership.members(msg.sender);
        if (!active) revert NotActiveMember();

        // Validation des entrées
        if (budget == 0) revert InvalidBudget();
        if (bytes(title).length == 0 || bytes(title).length > 200) revert InvalidTitle();
        if (bytes(description).length == 0 || bytes(description).length > 2000) revert InvalidDescription();
        if (minRank > 4) revert InvalidMinRank();
        if (requiredSkills.length > 10) revert TooManySkills();

        uint256 missionId = nextMissionId++;

        missions[missionId] = Mission({
            id: missionId,
            client: msg.sender,
            title: title,
            description: description,
            budget: budget,
            minRank: minRank,
            requiredSkills: requiredSkills,
            status: MissionStatus.Draft,
            selectedConsultant: address(0),
            createdAt: block.timestamp,
            updatedAt: block.timestamp
        });

        emit MissionCreated(missionId, msg.sender, budget, minRank);

        return missionId;
    }

    /**
     * @notice Publier la mission (Draft → Active)
     * @param missionId ID de la mission à publier
     * @dev Le budget est géré par le PSP — pas de verrouillage on-chain
     */
    function postMission(uint256 missionId) external {
        Mission storage mission = missions[missionId];

        if (msg.sender != mission.client) revert UnauthorizedClient();
        if (mission.status != MissionStatus.Draft) revert MissionNotDraft();

        mission.status = MissionStatus.Active;
        mission.updatedAt = block.timestamp;

        emit MissionPosted(missionId);
    }

    /**
     * @notice Soumettre une candidature à une mission
     * @param missionId Mission à rejoindre
     * @param proposal Hash IPFS du document de candidature (46 chars)
     * @param proposedBudget Budget proposé par le consultant (EUR centimes)
     */
    function applyToMission(
        uint256 missionId,
        string memory proposal,
        uint256 proposedBudget
    ) external nonReentrant {
        Mission storage mission = missions[missionId];

        if (mission.status != MissionStatus.Active) revert MissionNotActive();
        if (proposedBudget == 0 || proposedBudget > mission.budget) revert ProposedBudgetTooHigh();
        if (bytes(proposal).length != 46) revert InvalidProposal();

        bytes32 applicationKey = keccak256(abi.encodePacked(missionId, msg.sender));
        if (applications[applicationKey].consultant != address(0)) revert AlreadyApplied();

        (uint8 consultantRank,,,, bool active,,) = membership.members(msg.sender);
        if (!active) revert NotActiveMember();
        if (consultantRank < mission.minRank) revert InsufficientRank();

        // Score calculé on-chain — garantie de transparence algorithmique (Q1)
        uint256 matchScore = calculateMatchScore(missionId, msg.sender, proposedBudget);

        applications[applicationKey] = Application({
            missionId: missionId,
            consultant: msg.sender,
            proposal: proposal,
            proposedBudget: proposedBudget,
            submittedAt: block.timestamp,
            matchScore: matchScore
        });

        missionApplicants[missionId].push(msg.sender);

        emit ApplicationSubmitted(missionId, msg.sender, matchScore);
    }

    /**
     * @notice Sélectionner un consultant pour la mission (client uniquement)
     * @param missionId ID de la mission
     * @param consultant Adresse du consultant sélectionné
     * @dev Passe la mission en OnHold — le contrat PSP est créé par le backend
     */
    function selectConsultant(
        uint256 missionId,
        address consultant
    ) external nonReentrant {
        Mission storage mission = missions[missionId];

        if (msg.sender != mission.client) revert UnauthorizedClient();
        if (mission.status != MissionStatus.Active) revert InvalidMissionStatus();

        bytes32 applicationKey = keccak256(abi.encodePacked(missionId, consultant));
        Application memory selectedApp = applications[applicationKey];
        if (selectedApp.consultant == address(0)) revert ApplicationNotFound();

        // Vérifier attestation conformité KBIS du consultant (ADR 2026-02-18)
        if (!complianceRegistry.hasValidAttestation(consultant, ComplianceRegistry.AttestationType.KBIS)) {
            revert ComplianceCheckFailed();
        }

        mission.selectedConsultant = consultant;
        mission.status = MissionStatus.OnHold; // Consultant sélectionné, contrat PSP en attente
        mission.updatedAt = block.timestamp;

        emit ConsultantSelected(missionId, consultant, selectedApp.matchScore);
    }

    /**
     * @notice Annuler une mission
     * @param missionId Mission à annuler
     * @dev Le remboursement PSP est géré par le backend (pas de token on-chain)
     */
    function cancelMission(uint256 missionId) external nonReentrant {
        Mission storage mission = missions[missionId];

        if (msg.sender != mission.client) revert UnauthorizedClient();

        // Annulation possible uniquement si Active ou OnHold (avant complétion des jalons)
        if (mission.status != MissionStatus.Active && mission.status != MissionStatus.OnHold) {
            revert InvalidMissionStatus();
        }

        // Remboursement géré par le backend PSP — pas de transfert on-chain
        mission.status = MissionStatus.Cancelled;
        mission.updatedAt = block.timestamp;

        emit MissionCancelled(missionId, mission.client);
    }

    /**
     * @notice Calculer le score de matching pour un consultant (0-100)
     * @dev 5 critères : Rang (25%), Compétences (25%), Budget (20%), Track Record (15%), Réactivité (15%)
     *      Algorithme public, vérifiable on-chain — garantie structurelle contre la manipulation
     * @param missionId ID de la mission
     * @param consultant Adresse du consultant
     * @param proposedBudget Budget proposé par le consultant
     */
    function calculateMatchScore(
        uint256 missionId,
        address consultant,
        uint256 proposedBudget
    ) public view returns (uint256) {
        Mission memory mission = missions[missionId];
        (uint8 consultantRank,,,, bool active,,) = membership.members(consultant);
        if (!active) revert ConsultantNotActive();

        uint256 score = 0;

        // 1. Rang (25 points max) : échelle linéaire Rang 0-4 → 0-25 points
        score += (uint256(consultantRank) * 25) / 4;

        // 2. Overlap compétences (25 points max)
        {
            string[] memory consultantSkills = membership.getSkills(consultant);
            uint256 matchingSkills = countMatchingSkills(mission.requiredSkills, consultantSkills);
            score += mission.requiredSkills.length > 0
                ? (matchingSkills * 25) / mission.requiredSkills.length
                : 0;
        }

        // 3. Compétitivité du budget (20 points max) : budget plus bas = score plus élevé
        {
            uint256 budgetRatio = (proposedBudget * 100) / mission.budget;
            score += budgetRatio <= 100 ? 20 - ((budgetRatio * 20) / 100) : 0;
        }

        // 4. Track record (15 points max) : missions complétées (max 10) + rating moyen (max 5)
        {
            (uint256 completedMissions, uint256 averageRating) = membership.getTrackRecord(consultant);
            uint256 missionsScore = completedMissions > 10 ? 10 : completedMissions;
            score += missionsScore + ((averageRating * 5) / 100);
        }

        // 5. Réactivité (15 points max) : candidature rapide = score plus élevé (décroissance linéaire sur 7 jours)
        {
            uint256 timeElapsed = block.timestamp - mission.createdAt;
            score += timeElapsed < 7 days ? 15 - ((timeElapsed * 15) / 7 days) : 0;
        }

        return score > 100 ? 100 : score;
    }

    /**
     * @notice Compter les compétences communes entre les exigences et le profil consultant
     */
    function countMatchingSkills(
        string[] memory required,
        string[] memory consultantSkills
    ) internal pure returns (uint256) {
        uint256 count = 0;

        for (uint256 i = 0; i < required.length; i++) {
            for (uint256 j = 0; j < consultantSkills.length; j++) {
                if (keccak256(bytes(required[i])) == keccak256(bytes(consultantSkills[j]))) {
                    count++;
                    break;
                }
            }
        }

        return count;
    }

    // ===== View Functions =====

    /**
     * @notice Obtenir les candidats d'une mission
     */
    function getMissionApplicants(uint256 missionId) external view returns (address[] memory) {
        return missionApplicants[missionId];
    }

    /**
     * @notice Obtenir la candidature d'un consultant pour une mission
     */
    function getApplication(uint256 missionId, address consultant) external view returns (Application memory) {
        bytes32 applicationKey = keccak256(abi.encodePacked(missionId, consultant));
        return applications[applicationKey];
    }
}
