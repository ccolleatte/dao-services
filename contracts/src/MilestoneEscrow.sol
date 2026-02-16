// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/**
 * @title MilestoneEscrow
 * @notice Escrow contract for milestone-based payments
 * @dev Phase 2 Extension: Lock funds, validate deliverables, release progressively
 */
contract MilestoneEscrow is ReentrancyGuard {
    /*//////////////////////////////////////////////////////////////
                                TYPES
    //////////////////////////////////////////////////////////////*/

    enum MilestoneStatus {
        Pending,      // Not yet submitted
        Submitted,    // Consultant submitted deliverable
        Accepted,     // Client validated
        Rejected,     // Client rejected
        Disputed      // Under arbitration
    }

    struct Milestone {
        string description;
        bytes32 acceptanceCriteriaHash;
        uint256 amount;
        MilestoneStatus status;
        bytes32 deliverableHash;
        uint256 submittedAt;
        uint256 validatedAt;
        address validator;
    }

    struct MilestoneInput {
        string description;
        bytes32 acceptanceCriteriaHash;
        uint256 amount;
    }

    struct EscrowBalance {
        uint256 totalLocked;
        uint256 released;
        uint256 refunded;
        bool finalized;
    }

    /*//////////////////////////////////////////////////////////////
                            STATE VARIABLES
    //////////////////////////////////////////////////////////////*/

    address public immutable marketplaceContract;
    IERC20 public immutable daosToken;

    mapping(uint256 => Milestone[]) public missionMilestones;
    mapping(uint256 => EscrowBalance) public escrowBalances;

    /*//////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/

    event MilestonesSetup(uint256 indexed missionId, uint256 milestoneCount, uint256 totalAmount);
    event DeliverableSubmitted(uint256 indexed missionId, uint256 milestoneIndex, bytes32 deliverableHash);
    event DeliverableAccepted(uint256 indexed missionId, uint256 milestoneIndex, uint256 amount);
    event DeliverableRejected(uint256 indexed missionId, uint256 milestoneIndex, string reason);
    event FundsReleased(uint256 indexed missionId, address indexed consultant, uint256 amount);
    event MissionCancelled(uint256 indexed missionId, uint256 refundAmount);

    /*//////////////////////////////////////////////////////////////
                                ERRORS
    //////////////////////////////////////////////////////////////*/

    error NotMissionClient();
    error NotSelectedConsultant();
    error MilestonesTotalExceedsBudget();
    error InvalidMilestoneStatus();
    error CannotCancelAfterConsultantSelected();
    error InsufficientFunds();

    /*//////////////////////////////////////////////////////////////
                            CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address _marketplaceContract, address _daosToken) {
        marketplaceContract = _marketplaceContract;
        daosToken = IERC20(_daosToken);
    }

    /*//////////////////////////////////////////////////////////////
                            MODIFIERS
    //////////////////////////////////////////////////////////////*/

    modifier onlyClient(uint256 missionId) {
        address client = IMarketplace(marketplaceContract).getMissionClient(missionId);
        if (msg.sender != client) revert NotMissionClient();
        _;
    }

    modifier onlySelectedConsultant(uint256 missionId) {
        address consultant = IMarketplace(marketplaceContract).getMissionConsultant(missionId);
        if (msg.sender != consultant) revert NotSelectedConsultant();
        _;
    }

    /*//////////////////////////////////////////////////////////////
                        CORE FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Setup milestones for a mission and lock funds in escrow
     * @param missionId Mission ID
     * @param milestones Array of milestone inputs
     */
    function setupMilestones(
        uint256 missionId,
        MilestoneInput[] calldata milestones
    ) external onlyClient(missionId) nonReentrant {
        uint256 totalAmount = 0;

        // Calculate total and create milestones
        for (uint256 i = 0; i < milestones.length; i++) {
            totalAmount += milestones[i].amount;

            missionMilestones[missionId].push(Milestone({
                description: milestones[i].description,
                acceptanceCriteriaHash: milestones[i].acceptanceCriteriaHash,
                amount: milestones[i].amount,
                status: MilestoneStatus.Pending,
                deliverableHash: bytes32(0),
                submittedAt: 0,
                validatedAt: 0,
                validator: address(0)
            }));
        }

        // Verify total does not exceed mission budget
        uint256 missionBudget = IMarketplace(marketplaceContract).getMissionBudget(missionId);
        if (totalAmount > missionBudget) revert MilestonesTotalExceedsBudget();

        // Lock funds in escrow
        bool success = daosToken.transferFrom(msg.sender, address(this), totalAmount);
        require(success, "Escrow transfer failed");

        escrowBalances[missionId] = EscrowBalance({
            totalLocked: totalAmount,
            released: 0,
            refunded: 0,
            finalized: false
        });

        emit MilestonesSetup(missionId, milestones.length, totalAmount);
    }

    /**
     * @notice Consultant submits deliverable for milestone
     * @param missionId Mission ID
     * @param milestoneIndex Index of milestone
     * @param deliverableHash IPFS hash of deliverable
     */
    function submitDeliverable(
        uint256 missionId,
        uint256 milestoneIndex,
        bytes32 deliverableHash
    ) external onlySelectedConsultant(missionId) nonReentrant {
        Milestone storage milestone = missionMilestones[missionId][milestoneIndex];

        milestone.status = MilestoneStatus.Submitted;
        milestone.deliverableHash = deliverableHash;
        milestone.submittedAt = block.timestamp;

        emit DeliverableSubmitted(missionId, milestoneIndex, deliverableHash);
    }

    /**
     * @notice Client accepts deliverable and releases funds
     * @param missionId Mission ID
     * @param milestoneIndex Index of milestone
     */
    function acceptDeliverable(
        uint256 missionId,
        uint256 milestoneIndex
    ) external onlyClient(missionId) nonReentrant {
        Milestone storage milestone = missionMilestones[missionId][milestoneIndex];

        if (milestone.status != MilestoneStatus.Submitted) revert InvalidMilestoneStatus();

        // Update milestone status
        milestone.status = MilestoneStatus.Accepted;
        milestone.validator = msg.sender;
        milestone.validatedAt = block.timestamp;

        // Release funds to consultant
        address consultant = IMarketplace(marketplaceContract).getMissionConsultant(missionId);
        bool success = daosToken.transfer(consultant, milestone.amount);
        require(success, "Fund release failed");

        // Update escrow balance
        escrowBalances[missionId].released += milestone.amount;

        emit DeliverableAccepted(missionId, milestoneIndex, milestone.amount);
        emit FundsReleased(missionId, consultant, milestone.amount);
    }

    /**
     * @notice Client rejects deliverable
     * @param missionId Mission ID
     * @param milestoneIndex Index of milestone
     * @param reason Rejection reason
     */
    function rejectDeliverable(
        uint256 missionId,
        uint256 milestoneIndex,
        string calldata reason
    ) external onlyClient(missionId) nonReentrant {
        Milestone storage milestone = missionMilestones[missionId][milestoneIndex];

        if (milestone.status != MilestoneStatus.Submitted) revert InvalidMilestoneStatus();

        milestone.status = MilestoneStatus.Rejected;

        emit DeliverableRejected(missionId, milestoneIndex, reason);
    }

    /**
     * @notice Client cancels mission and gets refund (only if no consultant selected)
     * @param missionId Mission ID
     */
    function cancelMissionAndRefund(
        uint256 missionId
    ) external onlyClient(missionId) nonReentrant {
        address consultant = IMarketplace(marketplaceContract).getMissionConsultant(missionId);
        if (consultant != address(0)) revert CannotCancelAfterConsultantSelected();

        EscrowBalance storage balance = escrowBalances[missionId];
        uint256 refundAmount = balance.totalLocked - balance.released - balance.refunded;

        if (refundAmount == 0) revert InsufficientFunds();

        // Refund client
        bool success = daosToken.transfer(msg.sender, refundAmount);
        require(success, "Refund failed");

        balance.refunded += refundAmount;
        balance.finalized = true;

        emit MissionCancelled(missionId, refundAmount);
    }

    /**
     * @notice Accept milestone from dispute resolution (called by DisputeResolution contract)
     * @param missionId Mission ID
     * @param milestoneIndex Index of milestone
     */
    function acceptMilestoneFromDispute(
        uint256 missionId,
        uint256 milestoneIndex
    ) external nonReentrant {
        Milestone storage milestone = missionMilestones[missionId][milestoneIndex];

        // Update status
        milestone.status = MilestoneStatus.Accepted;
        milestone.validatedAt = block.timestamp;

        // Release funds
        address consultant = IMarketplace(marketplaceContract).getMissionConsultant(missionId);
        bool success = daosToken.transfer(consultant, milestone.amount);
        require(success, "Fund release failed");

        escrowBalances[missionId].released += milestone.amount;

        emit DeliverableAccepted(missionId, milestoneIndex, milestone.amount);
        emit FundsReleased(missionId, consultant, milestone.amount);
    }

    /*//////////////////////////////////////////////////////////////
                        VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function getMilestone(
        uint256 missionId,
        uint256 milestoneIndex
    ) external view returns (Milestone memory) {
        return missionMilestones[missionId][milestoneIndex];
    }

    function getEscrowBalance(uint256 missionId) external view returns (EscrowBalance memory) {
        return escrowBalances[missionId];
    }

    function getMilestoneStatus(
        uint256 missionId,
        uint256 milestoneIndex
    ) external view returns (MilestoneStatus) {
        return missionMilestones[missionId][milestoneIndex].status;
    }
}

/*//////////////////////////////////////////////////////////////
                        INTERFACES
//////////////////////////////////////////////////////////////*/

interface IMarketplace {
    function getMissionClient(uint256 missionId) external view returns (address);
    function getMissionConsultant(uint256 missionId) external view returns (address);
    function getMissionBudget(uint256 missionId) external view returns (uint256);
}
