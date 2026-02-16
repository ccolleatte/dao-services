// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./MilestoneEscrow.sol";

/**
 * @title DisputeResolution
 * @notice DAO-based arbitration system for milestone disputes
 * @dev Phase 2 Extension: Arbiter selection, voting, resolution
 */
contract DisputeResolution {
    /*//////////////////////////////////////////////////////////////
                                TYPES
    //////////////////////////////////////////////////////////////*/

    enum DisputeStatus {
        Open,       // Dispute open, votes in progress
        Resolved,   // Decision made
        Cancelled   // Cancelled by initiator
    }

    struct Dispute {
        uint256 missionId;
        uint256 milestoneIndex;
        address initiator;
        string reason;
        DisputeStatus status;
        address[3] arbiters;
        uint256 votesAccept;
        uint256 votesReject;
        uint256 createdAt;
        uint256 resolvedAt;
    }

    /*//////////////////////////////////////////////////////////////
                            STATE VARIABLES
    //////////////////////////////////////////////////////////////*/

    MilestoneEscrow public immutable escrowContract;
    address public immutable membershipContract;

    uint256 public disputeCounter;
    mapping(uint256 => Dispute) public disputes;
    mapping(uint256 => mapping(address => bool)) public hasVoted;

    // MVP: Simple arbiter registry for testing
    address[] public eligibleArbiters;

    /*//////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/

    event DisputeInitiated(
        uint256 indexed disputeId,
        uint256 indexed missionId,
        uint256 milestoneIndex,
        address indexed initiator
    );
    event VoteCast(uint256 indexed disputeId, address indexed arbiter, bool acceptDeliverable);
    event DisputeResolved(
        uint256 indexed disputeId,
        bool consultantWon,
        uint256 votesAccept,
        uint256 votesReject
    );
    event DisputeCancelled(uint256 indexed disputeId);

    /*//////////////////////////////////////////////////////////////
                                ERRORS
    //////////////////////////////////////////////////////////////*/

    error NotSelectedConsultant();
    error MilestoneNotRejected();
    error NotEligibleArbiter();
    error AlreadyVoted();
    error NotDisputeInitiator();
    error DisputeNotOpen();

    /*//////////////////////////////////////////////////////////////
                            CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address _escrowContract, address _membershipContract) {
        escrowContract = MilestoneEscrow(_escrowContract);
        membershipContract = _membershipContract;
    }

    /*//////////////////////////////////////////////////////////////
                        CORE FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Consultant initiates dispute after milestone rejected
     * @param missionId Mission ID
     * @param milestoneIndex Index of milestone
     * @param reason Dispute reason
     * @return disputeId ID of created dispute
     */
    function initiateDispute(
        uint256 missionId,
        uint256 milestoneIndex,
        string calldata reason
    ) external returns (uint256 disputeId) {
        // Verify caller is selected consultant
        address consultant = _getMissionConsultant(missionId);
        if (msg.sender != consultant) revert NotSelectedConsultant();

        // Verify milestone is rejected
        MilestoneEscrow.MilestoneStatus status = escrowContract.getMilestoneStatus(
            missionId,
            milestoneIndex
        );
        if (status != MilestoneEscrow.MilestoneStatus.Rejected) revert MilestoneNotRejected();

        // Create dispute
        disputeId = disputeCounter++;

        // Select 3 arbiters (MVP: use deterministic addresses for testing)
        // In production, use Chainlink VRF for true randomness
        // For now, use fixed test addresses that match MockMembershipContract setup
        address[3] memory selectedArbiters = _selectArbiters();

        disputes[disputeId] = Dispute({
            missionId: missionId,
            milestoneIndex: milestoneIndex,
            initiator: msg.sender,
            reason: reason,
            status: DisputeStatus.Open,
            arbiters: selectedArbiters,
            votesAccept: 0,
            votesReject: 0,
            createdAt: block.timestamp,
            resolvedAt: 0
        });

        emit DisputeInitiated(disputeId, missionId, milestoneIndex, msg.sender);

        return disputeId;
    }

    /**
     * @notice Arbiter votes on dispute
     * @param disputeId Dispute ID
     * @param acceptDeliverable True if deliverable should be accepted
     */
    function voteOnDispute(uint256 disputeId, bool acceptDeliverable) external {
        Dispute storage dispute = disputes[disputeId];

        if (dispute.status != DisputeStatus.Open) revert DisputeNotOpen();
        if (hasVoted[disputeId][msg.sender]) revert AlreadyVoted();

        // Verify arbiter eligibility (rank ≥3)
        uint8 rank = IMembership(membershipContract).getRank(msg.sender);
        if (rank < 3) revert NotEligibleArbiter();

        // Record vote
        hasVoted[disputeId][msg.sender] = true;

        if (acceptDeliverable) {
            dispute.votesAccept++;
        } else {
            dispute.votesReject++;
        }

        emit VoteCast(disputeId, msg.sender, acceptDeliverable);
    }

    /**
     * @notice Resolve dispute after votes
     * @param disputeId Dispute ID
     */
    function resolveDispute(uint256 disputeId) external {
        Dispute storage dispute = disputes[disputeId];

        if (dispute.status != DisputeStatus.Open) revert DisputeNotOpen();

        bool consultantWon = dispute.votesAccept >= 2; // 2/3 majority

        dispute.status = DisputeStatus.Resolved;
        dispute.resolvedAt = block.timestamp;

        // If consultant won, accept milestone
        if (consultantWon) {
            escrowContract.acceptMilestoneFromDispute(dispute.missionId, dispute.milestoneIndex);
        }

        emit DisputeResolved(disputeId, consultantWon, dispute.votesAccept, dispute.votesReject);
    }

    /**
     * @notice Consultant cancels dispute
     * @param disputeId Dispute ID
     */
    function cancelDispute(uint256 disputeId) external {
        Dispute storage dispute = disputes[disputeId];

        if (msg.sender != dispute.initiator) revert NotDisputeInitiator();
        if (dispute.status != DisputeStatus.Open) revert DisputeNotOpen();

        dispute.status = DisputeStatus.Cancelled;

        emit DisputeCancelled(disputeId);
    }

    /*//////////////////////////////////////////////////////////////
                        VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function getDispute(uint256 disputeId) external view returns (Dispute memory) {
        return disputes[disputeId];
    }

    /**
     * @notice Register eligible arbiters (MVP - for testing)
     * @param arbiters Array of arbiter addresses
     */
    function registerEligibleArbiters(address[] calldata arbiters) external {
        for (uint256 i = 0; i < arbiters.length; i++) {
            eligibleArbiters.push(arbiters[i]);
        }
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function _selectArbiters() internal view returns (address[3] memory) {
        // MVP: Select first 3 eligible arbiters
        // In production, use Chainlink VRF for true randomness
        require(eligibleArbiters.length >= 3, "Not enough eligible arbiters");

        address[3] memory selected;
        selected[0] = eligibleArbiters[0];
        selected[1] = eligibleArbiters[1];
        selected[2] = eligibleArbiters[2];

        return selected;
    }

    function _getMissionConsultant(uint256 missionId) internal view returns (address) {
        // Call marketplace via escrow (which has marketplace interface)
        return IMarketplaceViaEscrow(address(escrowContract)).getMissionConsultant(missionId);
    }
}

/*//////////////////////////////////////////////////////////////
                        INTERFACES
//////////////////////////////////////////////////////////////*/

interface IMembership {
    function getRank(address user) external view returns (uint8);
}

interface IMarketplaceViaEscrow {
    function getMissionConsultant(uint256 missionId) external view returns (address);
}
