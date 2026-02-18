// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/AccessControl.sol";

interface IDAOMembership {
    function updateTrackRecord(address _member, uint256 _missionRating) external;
    function isMember(address _account) external view returns (bool);
}

/**
 * @title Reputation
 * @notice Système de réputation portable pour les consultants de la DAO
 * @dev Remplace ReputationTracker.sol (dépendait de DisputeResolution archivé)
 *
 * Design :
 * - addBadge() appelé par le PSP webhook handler (MEMBER_MANAGER_ROLE)
 *   après validation d'un jalon → déclenche DAOMembership.updateTrackRecord()
 * - addCrossRating() : notes croisées consultant ↔ client
 * - Pas de PII on-chain (RGPD) : uniquement missionId + ipfsHash + rating
 */
contract Reputation is AccessControl {
    // ===== Roles =====
    bytes32 public constant MEMBER_MANAGER_ROLE = keccak256("MEMBER_MANAGER_ROLE");

    // ===== Structs =====
    struct Badge {
        uint256 missionId;    // ID de la mission (clé ServiceMarketplace)
        bytes32 ipfsHash;     // Hash IPFS du document (rapport, attestation)
        uint8 rating;         // Note 0-100
        uint256 timestamp;    // Timestamp de création
    }

    struct CrossRating {
        address rater;        // Auteur de la note
        address rated;        // Destinataire
        uint256 missionId;    // Mission concernée
        uint8 rating;         // Note 0-100
        bool isClientRating;  // true = client note consultant, false = consultant note client
        uint256 timestamp;
    }

    // ===== Constants =====
    uint8 public constant MAX_RATING = 100;

    // ===== State Variables =====
    IDAOMembership public immutable membership;

    // consultant → badges
    mapping(address => Badge[]) private _badges;

    // missionId → rater → hasRated (anti double-vote)
    mapping(uint256 => mapping(address => bool)) private _hasRated;

    // consultant → cross-ratings reçus
    mapping(address => CrossRating[]) private _crossRatings;

    // ===== Custom Errors =====
    error InvalidRating(uint8 rating, uint8 max);
    error InvalidAddress();
    error AlreadyRatedForMission(address rater, uint256 missionId);
    error UnauthorizedRater();

    // ===== Events =====
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

    // ===== Constructor =====
    constructor(address _membership) {
        if (_membership == address(0)) revert InvalidAddress();
        membership = IDAOMembership(_membership);
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MEMBER_MANAGER_ROLE, msg.sender);
    }

    // ===== Core Functions =====

    /**
     * @notice Ajouter un badge après complétion d'une mission
     * @param consultant Adresse du consultant
     * @param missionId ID de la mission (lien ServiceMarketplace)
     * @param ipfsHash Hash IPFS du document de validation (pas de PII on-chain)
     * @param rating Note attribuée (0-100)
     * @dev Appelé par le PSP webhook handler (rôle MEMBER_MANAGER_ROLE)
     *      Déclenche DAOMembership.updateTrackRecord() pour mettre à jour le track record
     */
    function addBadge(
        address consultant,
        uint256 missionId,
        bytes32 ipfsHash,
        uint8 rating
    ) external onlyRole(MEMBER_MANAGER_ROLE) {
        if (consultant == address(0)) revert InvalidAddress();
        if (rating > MAX_RATING) revert InvalidRating(rating, MAX_RATING);

        Badge memory badge = Badge({
            missionId: missionId,
            ipfsHash: ipfsHash,
            rating: rating,
            timestamp: block.timestamp
        });

        _badges[consultant].push(badge);

        // Intégration DAOMembership — spécification comportementale T1
        membership.updateTrackRecord(consultant, rating);

        emit BadgeAdded(consultant, missionId, ipfsHash, rating, block.timestamp);
    }

    /**
     * @notice Ajouter une note croisée consultant ↔ client
     * @param rater Auteur de la note
     * @param rated Destinataire de la note
     * @param missionId Mission concernée
     * @param rating Note (0-100)
     * @param isClientRating true = client note consultant, false = consultant note client
     * @dev Anti double-vote : un rater ne peut noter qu'une fois par mission
     */
    function addCrossRating(
        address rater,
        address rated,
        uint256 missionId,
        uint8 rating,
        bool isClientRating
    ) external onlyRole(MEMBER_MANAGER_ROLE) {
        if (rater == address(0) || rated == address(0)) revert InvalidAddress();
        if (rating > MAX_RATING) revert InvalidRating(rating, MAX_RATING);
        if (_hasRated[missionId][rater]) revert AlreadyRatedForMission(rater, missionId);

        _hasRated[missionId][rater] = true;

        CrossRating memory cr = CrossRating({
            rater: rater,
            rated: rated,
            missionId: missionId,
            rating: rating,
            isClientRating: isClientRating,
            timestamp: block.timestamp
        });

        _crossRatings[rated].push(cr);

        emit CrossRatingAdded(rater, rated, missionId, rating, isClientRating);
    }

    // ===== View Functions =====

    /**
     * @notice Obtenir les badges d'un consultant (ordre chronologique)
     * @param consultant Adresse du consultant
     * @return Tableau de badges
     */
    function getConsultantBadges(address consultant) external view returns (Badge[] memory) {
        return _badges[consultant];
    }

    /**
     * @notice Calculer le rating moyen d'un consultant (0-100)
     * @param consultant Adresse du consultant
     * @return Rating moyen, 0 si aucun badge
     */
    function getRating(address consultant) external view returns (uint256) {
        Badge[] storage badges = _badges[consultant];
        uint256 count = badges.length;
        if (count == 0) return 0;

        uint256 total = 0;
        for (uint256 i = 0; i < count; i++) {
            total += badges[i].rating;
        }
        return total / count;
    }

    /**
     * @notice Nombre de badges d'un consultant
     * @param consultant Adresse du consultant
     * @return Nombre de badges
     */
    function getBadgeCount(address consultant) external view returns (uint256) {
        return _badges[consultant].length;
    }

    /**
     * @notice Obtenir les notes croisées reçues par un utilisateur
     * @param user Adresse de l'utilisateur
     * @return Tableau de CrossRating
     */
    function getCrossRatings(address user) external view returns (CrossRating[] memory) {
        return _crossRatings[user];
    }

    /**
     * @notice Vérifier si un rater a déjà noté pour une mission
     * @param missionId ID de la mission
     * @param rater Adresse du rater
     * @return true si déjà noté
     */
    function hasRatedForMission(uint256 missionId, address rater) external view returns (bool) {
        return _hasRated[missionId][rater];
    }
}
