// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title ReputationTracker
 * @notice Basic reputation tracking for consultants and clients
 * @dev Phase 2 Extension: Track disputes, missions completed, calculate penalties
 */
contract ReputationTracker {
    /*//////////////////////////////////////////////////////////////
                                TYPES
    //////////////////////////////////////////////////////////////*/

    struct ReputationScore {
        uint256 missionsCompleted;
        uint256 disputesInitiated;
        uint256 disputesWon;
        uint256 disputesLost;
    }

    /*//////////////////////////////////////////////////////////////
                            STATE VARIABLES
    //////////////////////////////////////////////////////////////*/

    address public immutable disputeContract;

    mapping(address => ReputationScore) public consultantReputation;
    mapping(address => ReputationScore) public clientReputation;

    /*//////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/

    event ReputationUpdated(
        address indexed user,
        bool isConsultant,
        uint256 missionsCompleted,
        uint256 disputesWon,
        uint256 disputesLost
    );

    /*//////////////////////////////////////////////////////////////
                                ERRORS
    //////////////////////////////////////////////////////////////*/

    error NotDisputeContract();

    /*//////////////////////////////////////////////////////////////
                            CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address _disputeContract) {
        disputeContract = _disputeContract;
    }

    /*//////////////////////////////////////////////////////////////
                            MODIFIERS
    //////////////////////////////////////////////////////////////*/

    modifier onlyDisputeContract() {
        if (msg.sender != disputeContract) revert NotDisputeContract();
        _;
    }

    /*//////////////////////////////////////////////////////////////
                        CORE FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Update reputation after dispute resolution
     * @param missionId Mission ID (unused for MVP)
     * @param consultant Consultant address
     * @param client Client address
     * @param consultantWon True if consultant won dispute
     */
    function updateReputation(
        uint256 missionId,
        address consultant,
        address client,
        bool consultantWon
    ) external onlyDisputeContract {
        // Update consultant reputation
        ReputationScore storage consultantScore = consultantReputation[consultant];
        consultantScore.disputesInitiated++;

        if (consultantWon) {
            consultantScore.disputesWon++;
        } else {
            consultantScore.disputesLost++;
        }

        emit ReputationUpdated(
            consultant,
            true,
            consultantScore.missionsCompleted,
            consultantScore.disputesWon,
            consultantScore.disputesLost
        );

        // Update client reputation
        ReputationScore storage clientScore = clientReputation[client];

        if (!consultantWon) {
            // Client won = consultant lost, no update needed for client
        } else {
            // Consultant won = client lost
            clientScore.disputesLost++;
        }
    }

    /**
     * @notice Record mission completion
     * @param consultant Consultant address
     */
    function recordMissionCompleted(address consultant) external onlyDisputeContract {
        consultantReputation[consultant].missionsCompleted++;
    }

    /**
     * @notice Calculate reputation penalty based on dispute loss rate
     * @param user User address
     * @return penalty Penalty score (0-100)
     */
    function getReputationPenalty(address user) external view returns (uint256 penalty) {
        ReputationScore memory score = consultantReputation[user];

        if (score.disputesInitiated == 0) {
            return 0;
        }

        // Penalty = (disputesLost / disputesInitiated) * 100
        penalty = (score.disputesLost * 100) / score.disputesInitiated;

        return penalty;
    }

    /*//////////////////////////////////////////////////////////////
                        VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function getReputationScore(address user) external view returns (ReputationScore memory) {
        // Check both mappings, return whichever has data
        // In practice, user is either consultant OR client, not both
        ReputationScore memory consultantScore = consultantReputation[user];
        ReputationScore memory clientScore = clientReputation[user];

        // Return whichever has more activity
        if (consultantScore.missionsCompleted > 0 || consultantScore.disputesInitiated > 0) {
            return consultantScore;
        }

        return clientScore;
    }

    function getConsultantReputation(address consultant) external view returns (ReputationScore memory) {
        return consultantReputation[consultant];
    }

    function getClientReputation(address client) external view returns (ReputationScore memory) {
        return clientReputation[client];
    }
}
