// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./DAOMembership.sol";

/**
 * @title ServiceMarketplace
 * @notice Phase 3.1 - Transparent on-chain matching with public scoring algorithm
 * @dev Implements mission lifecycle (Draft → Active → OnHold → Completed/Cancelled)
 *      5-criteria match score: Rank (25%), Skills (25%), Budget (20%), Track Record (15%), Responsiveness (15%)
 */
contract ServiceMarketplace is AccessControl, ReentrancyGuard {
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    // ===== Enums =====

    enum MissionStatus {
        Draft,      // Created but not posted (budget not locked)
        Active,     // Posted, accepting applications (budget locked)
        OnHold,     // Consultant selected, awaiting escrow creation
        Disputed,   // Active dispute in escrow system
        Completed,  // All milestones completed
        Cancelled   // Cancelled by client or system
    }

    // ===== Structs =====

    struct Mission {
        uint256 id;
        address client;
        string title;                    // Max 200 chars
        string description;              // Max 2000 chars (Phase 3.1 requirement)
        uint256 budget;
        uint8 minRank;                   // 0-4 (DAO rank requirement)
        string[] requiredSkills;         // Max 10 skills
        MissionStatus status;
        address selectedConsultant;
        uint256 createdAt;
        uint256 updatedAt;
    }

    struct Application {
        uint256 missionId;
        address consultant;
        string proposal;                 // IPFS hash (46 chars)
        uint256 proposedBudget;
        uint256 submittedAt;
        uint256 matchScore;              // 0-100 calculated on-chain
    }

    // ===== State Variables =====

    uint256 public nextMissionId;
    mapping(uint256 => Mission) public missions;

    // Applications: composite key keccak256(abi.encodePacked(missionId, consultant))
    mapping(bytes32 => Application) public applications;

    // Index for querying applications by mission
    mapping(uint256 => address[]) public missionApplicants;

    IERC20 public immutable daosToken;
    DAOMembership public immutable membership;

    // ===== Events =====

    event MissionCreated(
        uint256 indexed missionId,
        address indexed client,
        uint256 budget,
        uint8 minRank
    );

    event MissionPosted(
        uint256 indexed missionId,
        uint256 budgetLocked
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

    // ===== Constructor =====

    constructor(
        address _daosToken,
        address _membership,
        address _admin
    ) {
        daosToken = IERC20(_daosToken);
        membership = DAOMembership(_membership);
        _grantRole(DEFAULT_ADMIN_ROLE, _admin);
        _grantRole(ADMIN_ROLE, _admin);
    }

    // ===== Core Functions =====

    /**
     * @notice Create a new mission (Draft status, budget not locked)
     * @param title Mission title (max 200 chars)
     * @param description Detailed description (max 2000 chars)
     * @param budget Total budget in DAOS tokens (wei)
     * @param minRank Minimum consultant rank required (0-4)
     * @param requiredSkills Required skills (max 10)
     */
    function createMission(
        string memory title,
        string memory description,
        uint256 budget,
        uint8 minRank,
        string[] memory requiredSkills
    ) external returns (uint256) {
        // Verify caller is active DAO member
        if (!membership.isMember(msg.sender)) revert NotActiveMember();
        (,,,, bool active,,) = membership.members(msg.sender);
        if (!active) revert NotActiveMember();

        // Validate inputs
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
            status: MissionStatus.Draft,  // Phase 3.1: Draft status, budget NOT locked
            selectedConsultant: address(0),
            createdAt: block.timestamp,
            updatedAt: block.timestamp
        });

        emit MissionCreated(missionId, msg.sender, budget, minRank);

        return missionId;
    }

    /**
     * @notice Post mission (activate + lock budget)
     * @param missionId Mission to activate
     */
    function postMission(uint256 missionId) external nonReentrant {
        Mission storage mission = missions[missionId];

        // Verify caller is mission client
        if (msg.sender != mission.client) revert UnauthorizedClient();

        // Verify mission is in Draft status
        if (mission.status != MissionStatus.Draft) revert MissionNotDraft();

        // Lock budget in contract (client must approve first)
        bool success = daosToken.transferFrom(msg.sender, address(this), mission.budget);
        require(success, "Budget transfer failed");

        // Update status to Active
        mission.status = MissionStatus.Active;
        mission.updatedAt = block.timestamp;

        emit MissionPosted(missionId, mission.budget);
    }

    /**
     * @notice Apply to a mission as consultant
     * @param missionId Mission to apply to
     * @param proposal IPFS hash of proposal document (46 chars)
     * @param proposedBudget Consultant's proposed budget
     */
    function applyToMission(
        uint256 missionId,
        string memory proposal,
        uint256 proposedBudget
    ) external nonReentrant {
        Mission storage mission = missions[missionId];

        // Verify mission is active
        if (mission.status != MissionStatus.Active) revert MissionNotActive();

        // Verify proposed budget
        if (proposedBudget == 0 || proposedBudget > mission.budget) revert ProposedBudgetTooHigh();

        // Verify proposal is IPFS hash (46 chars)
        if (bytes(proposal).length != 46) revert InvalidProposal();

        // Check if already applied
        bytes32 applicationKey = keccak256(abi.encodePacked(missionId, msg.sender));
        if (applications[applicationKey].consultant != address(0)) revert AlreadyApplied();

        // Get consultant rank and verify eligibility
        (uint8 consultantRank,,,, bool active,,) = membership.members(msg.sender);
        if (!active) revert NotActiveMember();
        if (consultantRank < mission.minRank) revert InsufficientRank();

        // Calculate match score on-chain
        uint256 matchScore = calculateMatchScore(missionId, msg.sender, proposedBudget);

        // Store application
        applications[applicationKey] = Application({
            missionId: missionId,
            consultant: msg.sender,
            proposal: proposal,
            proposedBudget: proposedBudget,
            submittedAt: block.timestamp,
            matchScore: matchScore
        });

        // Add to applicants index
        missionApplicants[missionId].push(msg.sender);

        emit ApplicationSubmitted(missionId, msg.sender, matchScore);
    }

    /**
     * @notice Select consultant for mission (client only)
     * @param missionId Mission ID
     * @param consultant Selected consultant address
     */
    function selectConsultant(
        uint256 missionId,
        address consultant
    ) external nonReentrant {
        Mission storage mission = missions[missionId];

        // Verify caller is mission client
        if (msg.sender != mission.client) revert UnauthorizedClient();

        // Verify mission is active
        if (mission.status != MissionStatus.Active) revert InvalidMissionStatus();

        // Verify application exists
        bytes32 applicationKey = keccak256(abi.encodePacked(missionId, consultant));
        Application memory selectedApp = applications[applicationKey];
        if (selectedApp.consultant == address(0)) revert ApplicationNotFound();

        // Update mission
        mission.selectedConsultant = consultant;
        mission.status = MissionStatus.OnHold; // Await escrow creation
        mission.updatedAt = block.timestamp;

        emit ConsultantSelected(missionId, consultant, selectedApp.matchScore);
    }

    /**
     * @notice Cancel mission and refund budget
     * @param missionId Mission to cancel
     */
    function cancelMission(uint256 missionId) external nonReentrant {
        Mission storage mission = missions[missionId];

        // Verify caller is mission client
        if (msg.sender != mission.client) revert UnauthorizedClient();

        // Verify mission is Active or OnHold (before escrow creation)
        if (mission.status != MissionStatus.Active && mission.status != MissionStatus.OnHold) {
            revert InvalidMissionStatus();
        }

        // Refund locked budget to client (only if Active, OnHold means escrow not created yet)
        if (mission.status == MissionStatus.Active || mission.status == MissionStatus.OnHold) {
            bool success = daosToken.transfer(mission.client, mission.budget);
            require(success, "Refund transfer failed");
        }

        // Update status to Cancelled
        mission.status = MissionStatus.Cancelled;
        mission.updatedAt = block.timestamp;

        emit MissionCancelled(missionId, mission.client);
    }

    /**
     * @notice Calculate match score for consultant application (0-100)
     * @dev 5 criteria with weights: Rank (25%), Skills (25%), Budget (20%), Track Record (15%), Responsiveness (15%)
     * @param missionId Mission ID
     * @param consultant Consultant address
     * @param proposedBudget Consultant's proposed budget
     */
    function calculateMatchScore(
        uint256 missionId,
        address consultant,
        uint256 proposedBudget
    ) public view returns (uint256) {
        Mission memory mission = missions[missionId];
        (uint8 consultantRank,,,, bool active,,) = membership.members(consultant);
        require(active, "Consultant not active");

        // Calculate scores inline to avoid stack too deep
        uint256 score = 0;

        // 1. Rank match (25 points max): Linear scaling Rank 0-4 → 0-25 points
        score += (uint256(consultantRank) * 25) / 4;

        // 2. Skills overlap (25 points max)
        {
            string[] memory consultantSkills = membership.getSkills(consultant);
            uint256 matchingSkills = countMatchingSkills(mission.requiredSkills, consultantSkills);
            score += mission.requiredSkills.length > 0
                ? (matchingSkills * 25) / mission.requiredSkills.length
                : 0;
        }

        // 3. Budget competitiveness (20 points max): Lower budget = higher score
        {
            uint256 budgetRatio = (proposedBudget * 100) / mission.budget;
            score += budgetRatio <= 100 ? 20 - ((budgetRatio * 20) / 100) : 0;
        }

        // 4. Track record (15 points max): Missions (max 10) + Rating (max 5)
        {
            (uint256 completedMissions, uint256 averageRating) = membership.getTrackRecord(consultant);
            uint256 missionsScore = completedMissions > 10 ? 10 : completedMissions;
            score += missionsScore + ((averageRating * 5) / 100);
        }

        // 5. Responsiveness (15 points max): Early application = higher score, linear decay over 7 days
        {
            uint256 timeElapsed = block.timestamp - mission.createdAt;
            score += timeElapsed < 7 days ? 15 - ((timeElapsed * 15) / 7 days) : 0;
        }

        return score > 100 ? 100 : score;
    }

    /**
     * @notice Count matching skills between required and consultant skills
     * @param required Required skills array
     * @param consultantSkills Consultant's skills array
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
     * @notice Get applicants for a mission
     * @param missionId Mission ID
     */
    function getMissionApplicants(uint256 missionId) external view returns (address[] memory) {
        return missionApplicants[missionId];
    }

    /**
     * @notice Get application for consultant on mission
     * @param missionId Mission ID
     * @param consultant Consultant address
     */
    function getApplication(uint256 missionId, address consultant) external view returns (Application memory) {
        bytes32 applicationKey = keccak256(abi.encodePacked(missionId, consultant));
        return applications[applicationKey];
    }
}
