// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title ServiceMarketplace
 * @notice Core marketplace for mission publication, consultant application, and matching
 * @dev Implements on-chain scoring algorithm for transparent consultant selection
 */
contract ServiceMarketplace is AccessControl, ReentrancyGuard {
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    // Mission status enum
    enum MissionStatus { Draft, Active, OnHold, Disputed, Completed, Cancelled }

    // Mission struct
    struct Mission {
        uint256 id;
        address client;
        string title;
        uint256 budget;
        uint8 minRank; // 0-4 (DAO rank requirement)
        MissionStatus status;
        address selectedConsultant;
        string[] requiredSkills;
        uint256 createdAt;
        uint256 updatedAt;
    }

    // Application struct
    struct Application {
        uint256 missionId;
        address consultant;
        string proposal; // IPFS hash
        uint256 proposedBudget;
        uint256 submittedAt;
        uint256 matchScore; // 0-100 calculated on-chain
    }

    // State variables
    uint256 public missionCounter;
    mapping(uint256 => Mission) public missions;
    mapping(uint256 => Application) public applications;
    mapping(uint256 => uint256[]) public missionApplications; // missionId => applicationIds
    mapping(address => uint256[]) public consultantApplications; // consultant => applicationIds

    IERC20 public immutable daosToken;
    address public membershipContract;
    address public escrowFactory;

    // Events
    event MissionCreated(uint256 indexed missionId, address indexed client, uint256 budget);
    event ApplicationSubmitted(uint256 indexed applicationId, uint256 indexed missionId, address indexed consultant);
    event ConsultantSelected(uint256 indexed missionId, address indexed consultant, uint256 matchScore);
    event MissionStatusUpdated(uint256 indexed missionId, MissionStatus newStatus);

    // Errors
    error InsufficientBudget();
    error MissionNotActive();
    error AlreadyApplied();
    error InsufficientRank();
    error UnauthorizedClient();
    error InvalidMissionStatus();

    constructor(
        address _daosToken,
        address _membershipContract,
        address _admin
    ) {
        daosToken = IERC20(_daosToken);
        membershipContract = _membershipContract;
        _grantRole(DEFAULT_ADMIN_ROLE, _admin);
        _grantRole(ADMIN_ROLE, _admin);
    }

    /**
     * @notice Create a new mission
     * @param title Mission title
     * @param budget Total budget in DAOS tokens
     * @param minRank Minimum DAO rank required (0-4)
     * @param requiredSkills Array of required skill identifiers
     */
    function createMission(
        string memory title,
        uint256 budget,
        uint8 minRank,
        string[] memory requiredSkills
    ) external nonReentrant returns (uint256) {
        if (budget == 0) revert InsufficientBudget();

        // Lock budget in contract (client must approve first)
        bool success = daosToken.transferFrom(msg.sender, address(this), budget);
        require(success, "Budget transfer failed");

        uint256 missionId = ++missionCounter;

        missions[missionId] = Mission({
            id: missionId,
            client: msg.sender,
            title: title,
            budget: budget,
            minRank: minRank,
            status: MissionStatus.Active,
            selectedConsultant: address(0),
            requiredSkills: requiredSkills,
            createdAt: block.timestamp,
            updatedAt: block.timestamp
        });

        emit MissionCreated(missionId, msg.sender, budget);

        return missionId;
    }

    /**
     * @notice Apply to a mission as consultant
     * @param missionId Mission to apply to
     * @param proposal IPFS hash of proposal document
     * @param proposedBudget Consultant's proposed budget
     */
    function applyToMission(
        uint256 missionId,
        string memory proposal,
        uint256 proposedBudget
    ) external nonReentrant returns (uint256) {
        Mission storage mission = missions[missionId];

        if (mission.status != MissionStatus.Active) revert MissionNotActive();
        if (proposedBudget > mission.budget) revert InsufficientBudget();

        // Check if already applied
        uint256[] memory existingApps = missionApplications[missionId];
        for (uint256 i = 0; i < existingApps.length; i++) {
            if (applications[existingApps[i]].consultant == msg.sender) {
                revert AlreadyApplied();
            }
        }

        // Get consultant rank from membership contract
        (bool success, bytes memory data) = membershipContract.staticcall(
            abi.encodeWithSignature("getRank(address)", msg.sender)
        );
        require(success, "Rank check failed");
        uint8 consultantRank = abi.decode(data, (uint8));

        if (consultantRank < mission.minRank) revert InsufficientRank();

        uint256 applicationId = missionApplications[missionId].length;

        // Calculate match score on-chain
        uint256 matchScore = calculateMatchScore(missionId, msg.sender, proposedBudget, consultantRank);

        applications[applicationId] = Application({
            missionId: missionId,
            consultant: msg.sender,
            proposal: proposal,
            proposedBudget: proposedBudget,
            submittedAt: block.timestamp,
            matchScore: matchScore
        });

        missionApplications[missionId].push(applicationId);
        consultantApplications[msg.sender].push(applicationId);

        emit ApplicationSubmitted(applicationId, missionId, msg.sender);

        return applicationId;
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

        if (msg.sender != mission.client) revert UnauthorizedClient();
        if (mission.status != MissionStatus.Active) revert InvalidMissionStatus();

        // Find application
        uint256[] memory apps = missionApplications[missionId];
        Application memory selectedApp;
        bool found = false;

        for (uint256 i = 0; i < apps.length; i++) {
            if (applications[apps[i]].consultant == consultant) {
                selectedApp = applications[apps[i]];
                found = true;
                break;
            }
        }

        require(found, "Application not found");

        // Update mission
        mission.selectedConsultant = consultant;
        mission.status = MissionStatus.OnHold; // Wait for escrow creation
        mission.updatedAt = block.timestamp;

        // Transfer locked budget to escrow contract (to be created by factory)
        // Note: In production, this would trigger escrow factory

        emit ConsultantSelected(missionId, consultant, selectedApp.matchScore);
    }

    /**
     * @notice Calculate match score for consultant application (0-100)
     * @dev 5 criteria with weights: Rank (25%), Skills (25%), Budget (20%), Track Record (15%), Responsiveness (15%)
     * @param missionId Mission ID
     * @param consultant Consultant address
     * @param proposedBudget Consultant's proposed budget
     * @param consultantRank Consultant's DAO rank (0-4)
     */
    function calculateMatchScore(
        uint256 missionId,
        address consultant,
        uint256 proposedBudget,
        uint8 consultantRank
    ) public view returns (uint256) {
        Mission memory mission = missions[missionId];

        uint256 totalScore = 0;

        // 1. Rank match (25 points max)
        // Linear scaling: Rank 0 = 0 points, Rank 4 = 25 points
        uint256 rankScore = (uint256(consultantRank) * 25) / 4;
        totalScore += rankScore;

        // 2. Skills overlap (25 points max)
        // Get consultant skills from membership contract
        (bool success, bytes memory data) = membershipContract.staticcall(
            abi.encodeWithSignature("getSkills(address)", consultant)
        );

        if (success) {
            string[] memory consultantSkills = abi.decode(data, (string[]));
            uint256 matchingSkills = countMatchingSkills(mission.requiredSkills, consultantSkills);
            uint256 skillsScore = mission.requiredSkills.length > 0
                ? (matchingSkills * 25) / mission.requiredSkills.length
                : 0;
            totalScore += skillsScore;
        }

        // 3. Budget competitiveness (20 points max)
        // Lower proposed budget = higher score (inverse relationship)
        // If proposed == mission.budget → 0 points
        // If proposed == 0 → 20 points (unrealistic, but for demo)
        uint256 budgetScore = mission.budget > 0
            ? 20 - ((proposedBudget * 20) / mission.budget)
            : 0;
        totalScore += budgetScore;

        // 4. Track record (15 points max)
        // Get completed missions + average rating from membership contract
        (bool trackSuccess, bytes memory trackData) = membershipContract.staticcall(
            abi.encodeWithSignature("getTrackRecord(address)", consultant)
        );

        if (trackSuccess) {
            (uint256 completedMissions, uint256 averageRating) = abi.decode(trackData, (uint256, uint256));
            uint256 missionsScore = completedMissions > 10 ? 10 : completedMissions; // Max 10 points
            uint256 ratingScore = (averageRating * 5) / 100; // Max 5 points (rating 0-100 → 0-5 points)
            totalScore += missionsScore + ratingScore;
        }

        // 5. Responsiveness (15 points max)
        // Early application = higher score
        // Assumes mission created recently, decay over 7 days
        uint256 timeElapsed = block.timestamp - mission.createdAt;
        uint256 totalTime = 7 days;
        uint256 responsivenessScore = timeElapsed < totalTime
            ? 15 - ((timeElapsed * 15) / totalTime)
            : 0;
        totalScore += responsivenessScore;

        return totalScore > 100 ? 100 : totalScore;
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

    /**
     * @notice Update mission status (admin only)
     * @param missionId Mission ID
     * @param newStatus New status
     */
    function updateMissionStatus(
        uint256 missionId,
        MissionStatus newStatus
    ) external onlyRole(ADMIN_ROLE) {
        Mission storage mission = missions[missionId];
        mission.status = newStatus;
        mission.updatedAt = block.timestamp;

        emit MissionStatusUpdated(missionId, newStatus);
    }

    /**
     * @notice Get applications for a mission
     * @param missionId Mission ID
     */
    function getMissionApplications(uint256 missionId) external view returns (uint256[] memory) {
        return missionApplications[missionId];
    }

    /**
     * @notice Get consultant's applications
     * @param consultant Consultant address
     */
    function getConsultantApplications(address consultant) external view returns (uint256[] memory) {
        return consultantApplications[consultant];
    }

    /**
     * @notice Set membership contract address (admin only)
     * @param _membershipContract New membership contract address
     */
    function setMembershipContract(address _membershipContract) external onlyRole(ADMIN_ROLE) {
        membershipContract = _membershipContract;
    }

    /**
     * @notice Set escrow factory address (admin only)
     * @param _escrowFactory New escrow factory address
     */
    function setEscrowFactory(address _escrowFactory) external onlyRole(ADMIN_ROLE) {
        escrowFactory = _escrowFactory;
    }
}
