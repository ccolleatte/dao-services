// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/AccessControl.sol";

/**
 * @title DAOMembership
 * @notice Gestion des membres du DAO avec système de rangs hiérarchiques
 * @dev Implémente le modèle Technical Fellowship de Polkadot (rangs 0-4)
 *
 * Rangs :
 * - Rang 0 : Junior (<2 ans expérience)
 * - Rang 1 : Consultant (3-5 ans)
 * - Rang 2 : Senior (6-10 ans)
 * - Rang 3 : Manager (10-15 ans)
 * - Rang 4 : Partner (15+ ans)
 *
 * Vote weight : Standard triangular numbers (no adjustment for minRank)
 * weight(r) = r × (r + 1) / 2
 * où r = rang du membre (0-4)
 * Rank 0: 0, Rank 1: 1, Rank 2: 3, Rank 3: 6, Rank 4: 10
 * minRank acts as eligibility filter only (reverts if rank < minRank)
 */
contract DAOMembership is AccessControl {
    // ===== Roles =====
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant MEMBER_MANAGER_ROLE = keccak256("MEMBER_MANAGER_ROLE");

    // ===== Structs =====
    struct Member {
        uint8 rank;              // Rang actuel (0-4)
        uint256 joinedAt;        // Timestamp d'adhésion
        uint256 lastPromotedAt;  // Timestamp dernière promotion
        string githubHandle;     // Identifiant GitHub (optionnel)
        bool active;             // Statut actif/inactif
        string[] skills;         // Compétences du consultant (max 20)
        uint256 completedMissions; // Nombre de missions complétées
        uint256 averageRating;   // Rating moyen (0-100)
    }

    // ===== State Variables =====
    mapping(address => Member) public members;
    address[] public memberAddresses;

    // Durée minimum à chaque rang avant promotion (en secondes)
    uint256[5] public minRankDuration = [
        0,          // Rang 0: pas de minimum
        90 days,    // Rang 0→1: 3 mois
        180 days,   // Rang 1→2: 6 mois
        365 days,   // Rang 2→3: 12 mois
        547 days    // Rang 3→4: 18 mois
    ];

    // Constantes pour validation
    uint256 public constant MAX_SKILLS = 20;
    uint256 public constant MAX_RATING = 100;

    // ===== Custom Errors =====
    error NotAMember(address account);
    error MemberInactive(address account);
    error InvalidAddress();
    error InvalidRank(uint8 rank);
    error AlreadyMember(address account);
    error AlreadyAtMaxRank(address member);
    error AlreadyAtMinRank(address member);
    error InsufficientTimeSincePromotion(uint256 timeElapsed, uint256 required);
    error RankTooLow(uint8 currentRank, uint8 requiredRank);
    error TooManySkills(uint256 provided, uint256 max);
    error InvalidRating(uint256 rating, uint256 max);

    // ===== Events =====
    event MemberAdded(address indexed member, uint8 rank, string githubHandle);
    event MemberPromoted(address indexed member, uint8 oldRank, uint8 newRank);
    event MemberDemoted(address indexed member, uint8 oldRank, uint8 newRank);
    event MemberRemoved(address indexed member);
    event MemberActivated(address indexed member);
    event MemberDeactivated(address indexed member);
    event SkillsUpdated(address indexed member, uint256 skillCount);
    event TrackRecordUpdated(address indexed member, uint256 completedMissions, uint256 averageRating);

    // ===== Constructor =====
    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);
        _grantRole(MEMBER_MANAGER_ROLE, msg.sender);
    }

    // ===== Modifiers =====
    modifier onlyActiveMember() {
        if (!isMember(msg.sender)) revert NotAMember(msg.sender);
        if (!members[msg.sender].active) revert MemberInactive(msg.sender);
        _;
    }

    // ===== Member Management =====

    /**
     * @notice Ajouter un nouveau membre au DAO
     * @param _member Adresse du membre
     * @param _rank Rang initial (0-4)
     * @param _githubHandle Identifiant GitHub (optionnel)
     */
    function addMember(
        address _member,
        uint8 _rank,
        string calldata _githubHandle
    ) external onlyRole(MEMBER_MANAGER_ROLE) {
        if (_member == address(0)) revert InvalidAddress();
        if (_rank > 4) revert InvalidRank(_rank);
        if (isMember(_member)) revert AlreadyMember(_member);

        members[_member] = Member({
            rank: _rank,
            joinedAt: block.timestamp,
            lastPromotedAt: block.timestamp,
            githubHandle: _githubHandle,
            active: true,
            skills: new string[](0),
            completedMissions: 0,
            averageRating: 0
        });

        memberAddresses.push(_member);

        emit MemberAdded(_member, _rank, _githubHandle);
    }

    /**
     * @notice Promouvoir un membre au rang supérieur
     * @param _member Adresse du membre
     */
    function promoteMember(address _member) external onlyRole(MEMBER_MANAGER_ROLE) {
        if (!isMember(_member)) revert NotAMember(_member);
        Member storage member = members[_member];
        if (member.rank >= 4) revert AlreadyAtMaxRank(_member);

        // Vérifier durée minimale au rang actuel
        uint8 currentRank = member.rank;
        uint256 timeAtRank = block.timestamp - member.lastPromotedAt;
        uint256 requiredTime = minRankDuration[currentRank + 1];
        if (timeAtRank < requiredTime) {
            revert InsufficientTimeSincePromotion(timeAtRank, requiredTime);
        }

        uint8 oldRank = member.rank;
        member.rank += 1;
        member.lastPromotedAt = block.timestamp;

        emit MemberPromoted(_member, oldRank, member.rank);
    }

    /**
     * @notice Rétrograder un membre au rang inférieur
     * @param _member Adresse du membre
     */
    function demoteMember(address _member) external onlyRole(ADMIN_ROLE) {
        if (!isMember(_member)) revert NotAMember(_member);
        Member storage member = members[_member];
        if (member.rank == 0) revert AlreadyAtMinRank(_member);

        uint8 oldRank = member.rank;
        member.rank -= 1;

        emit MemberDemoted(_member, oldRank, member.rank);
    }

    /**
     * @notice Retirer un membre du DAO
     * @param _member Adresse du membre
     */
    function removeMember(address _member) external onlyRole(ADMIN_ROLE) {
        if (!isMember(_member)) revert NotAMember(_member);

        delete members[_member];

        // Retirer de la liste des adresses
        for (uint256 i = 0; i < memberAddresses.length; i++) {
            if (memberAddresses[i] == _member) {
                memberAddresses[i] = memberAddresses[memberAddresses.length - 1];
                memberAddresses.pop();
                break;
            }
        }

        emit MemberRemoved(_member);
    }

    /**
     * @notice Activer/désactiver un membre
     * @param _member Adresse du membre
     * @param _active Nouveau statut
     */
    function setMemberActive(address _member, bool _active)
        external
        onlyRole(MEMBER_MANAGER_ROLE)
    {
        if (!isMember(_member)) revert NotAMember(_member);
        members[_member].active = _active;

        if (_active) {
            emit MemberActivated(_member);
        } else {
            emit MemberDeactivated(_member);
        }
    }

    // ===== Vote Weight Calculation =====

    /**
     * @notice Calculer le poids de vote d'un membre pour une proposition
     * @param _member Adresse du membre
     * @param _minRank Rang minimum requis pour voter sur cette proposition
     * @return weight Poids de vote (triangular number)
     *
     * Formule : weight(r) = r × (r + 1) / 2
     * où r = rang du membre (0-4)
     * minRank acts as eligibility filter (reverts if rank < minRank)
     *
     * Examples:
     * - Rang 0: weight = 0
     * - Rang 1: weight = 1
     * - Rang 2: weight = 3
     * - Rang 3: weight = 6
     * - Rang 4: weight = 10
     */
    function calculateVoteWeight(address _member, uint8 _minRank)
        public
        view
        returns (uint256 weight)
    {
        if (!isMember(_member)) revert NotAMember(_member);
        Member memory member = members[_member];
        if (!member.active) revert MemberInactive(_member);

        // If member's rank is below minimum, revert
        if (member.rank < _minRank) revert RankTooLow(member.rank, _minRank);

        // Standard triangular number (absolute rank, no minRank adjustment)
        // weight = rank × (rank + 1) / 2
        uint256 rank = uint256(member.rank);
        weight = rank * (rank + 1) / 2;
    }

    /**
     * @notice Calculer le poids de vote total de tous les membres actifs
     * @param _minRank Rang minimum requis
     * @return totalWeight Somme des poids de vote
     */
    function calculateTotalVoteWeight(uint8 _minRank)
        public
        view
        returns (uint256 totalWeight)
    {
        for (uint256 i = 0; i < memberAddresses.length; i++) {
            address memberAddr = memberAddresses[i];
            Member memory member = members[memberAddr];

            if (member.active && member.rank >= _minRank) {
                // Standard triangular number (absolute rank)
                uint256 rank = uint256(member.rank);
                totalWeight += rank * (rank + 1) / 2;
            }
        }
    }

    // ===== View Functions =====

    /**
     * @notice Vérifier si une adresse est membre du DAO
     * @param _account Adresse à vérifier
     * @return bool True si membre, false sinon
     */
    function isMember(address _account) public view returns (bool) {
        return members[_account].joinedAt > 0;
    }

    /**
     * @notice Obtenir les informations d'un membre
     * @param _member Adresse du membre
     * @return member Struct Member complet
     */
    function getMemberInfo(address _member) external view returns (Member memory) {
        if (!isMember(_member)) revert NotAMember(_member);
        return members[_member];
    }

    /**
     * @notice Obtenir le nombre total de membres
     * @return count Nombre de membres
     */
    function getMemberCount() external view returns (uint256) {
        return memberAddresses.length;
    }

    /**
     * @notice Obtenir tous les membres actifs d'un rang spécifique
     * @param _rank Rang recherché
     * @return activeMembers Liste des adresses
     */
    function getActiveMembersByRank(uint8 _rank)
        external
        view
        returns (address[] memory)
    {
        if (_rank > 4) revert InvalidRank(_rank);

        // Compter d'abord
        uint256 count = 0;
        for (uint256 i = 0; i < memberAddresses.length; i++) {
            Member memory member = members[memberAddresses[i]];
            if (member.active && member.rank == _rank) {
                count++;
            }
        }

        // Créer tableau de la bonne taille
        address[] memory result = new address[](count);
        uint256 index = 0;
        for (uint256 i = 0; i < memberAddresses.length; i++) {
            address memberAddr = memberAddresses[i];
            Member memory member = members[memberAddr];
            if (member.active && member.rank == _rank) {
                result[index] = memberAddr;
                index++;
            }
        }

        return result;
    }

    // ===== OpenZeppelin IVotes Interface =====
    // Required for Governor integration

    /**
     * @notice Returns the current timepoint (block number)
     * @dev Part of IVotes interface for OpenZeppelin Governor
     * @return Current block number as uint48
     */
    function clock() public view returns (uint48) {
        return uint48(block.number);
    }

    /**
     * @notice Returns the clock mode used for voting
     * @dev Part of IVotes interface - indicates we use block.number
     * @return Clock mode string
     */
    function CLOCK_MODE() public pure returns (string memory) {
        return "mode=blocknumber&from=default";
    }

    /**
     * @notice Returns total voting power at a given timepoint
     * @dev Part of IVotes interface
     * @param timepoint Block number (unused in this simplified implementation)
     * @return Total vote weight of all active members with rank >= 0
     *
     * NOTE: This simplified implementation returns CURRENT total supply,
     * not historical. For production, implement checkpoint-based tracking.
     */
    function getPastTotalSupply(uint256 timepoint) public view returns (uint256) {
        // For now, return current total supply (no historical tracking)
        // Governor will call this with a past block number, but we return current
        return calculateTotalVoteWeight(0);
    }

    /**
     * @notice Returns voting power for an account at a given timepoint
     * @dev Part of IVotes interface
     * @param account Member address
     * @param timepoint Block number (unused in this simplified implementation)
     * @return Vote weight for the account with rank >= 0
     *
     * NOTE: This simplified implementation returns CURRENT votes,
     * not historical. For production, implement checkpoint-based tracking.
     */
    function getPastVotes(address account, uint256 timepoint) public view returns (uint256) {
        // For now, return current vote weight (no historical tracking)
        if (!isMember(account)) {
            return 0;
        }

        Member memory member = members[account];
        if (!member.active) {
            return 0;
        }

        // Return vote weight with minRank=0 (all members eligible)
        uint256 rank = uint256(member.rank);
        return rank * (rank + 1) / 2;
    }

    // ===== Skills & Track Record Management =====

    /**
     * @notice Définir les compétences d'un consultant
     * @param _member Adresse du membre
     * @param _skills Liste des compétences (max 20)
     */
    function setSkills(address _member, string[] calldata _skills)
        external
        onlyRole(MEMBER_MANAGER_ROLE)
    {
        if (!isMember(_member)) revert NotAMember(_member);
        if (_skills.length > MAX_SKILLS) revert TooManySkills(_skills.length, MAX_SKILLS);

        // Delete old skills first
        delete members[_member].skills;

        // Copy new skills element by element (nested dynamic array)
        for (uint256 i = 0; i < _skills.length; i++) {
            members[_member].skills.push(_skills[i]);
        }

        emit SkillsUpdated(_member, _skills.length);
    }

    /**
     * @notice Obtenir les compétences d'un consultant
     * @param _member Adresse du membre
     * @return skills Liste des compétences
     */
    function getSkills(address _member)
        external
        view
        returns (string[] memory)
    {
        if (!isMember(_member)) revert NotAMember(_member);
        return members[_member].skills;
    }

    /**
     * @notice Mettre à jour le track record après une mission complétée
     * @param _member Adresse du membre
     * @param _missionRating Rating de la mission (0-100)
     * @dev Appelé par l'intégration PSP après completion de mission (rôle MEMBER_MANAGER_ROLE)
     */
    function updateTrackRecord(address _member, uint256 _missionRating)
        external
        onlyRole(MEMBER_MANAGER_ROLE)
    {
        if (!isMember(_member)) revert NotAMember(_member);
        if (_missionRating > MAX_RATING) revert InvalidRating(_missionRating, MAX_RATING);

        Member storage member = members[_member];

        // Calculer nouveau rating moyen
        uint256 totalMissions = member.completedMissions;
        uint256 currentAverage = member.averageRating;

        // Formule: newAverage = (currentAverage × totalMissions + newRating) / (totalMissions + 1)
        uint256 newAverage = (currentAverage * totalMissions + _missionRating) / (totalMissions + 1);

        member.completedMissions += 1;
        member.averageRating = newAverage;

        emit TrackRecordUpdated(_member, member.completedMissions, member.averageRating);
    }

    /**
     * @notice Obtenir le track record d'un consultant
     * @param _member Adresse du membre
     * @return completedMissions Nombre de missions complétées
     * @return averageRating Rating moyen (0-100)
     */
    function getTrackRecord(address _member)
        external
        view
        returns (uint256 completedMissions, uint256 averageRating)
    {
        if (!isMember(_member)) revert NotAMember(_member);
        Member memory member = members[_member];
        return (member.completedMissions, member.averageRating);
    }
}
