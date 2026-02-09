// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title MissionEscrow
 * @notice Milestone-based escrow with change requests and dispute arbitrage
 * @dev Sequential milestone validation with DAO jury dispute resolution
 */
contract MissionEscrow is AccessControl, ReentrancyGuard {
    bytes32 public constant JUROR_ROLE = keccak256("JUROR_ROLE");

    // Milestone status enum
    enum MilestoneStatus { Pending, Submitted, Approved, Rejected, Disputed }

    // Dispute status enum
    enum DisputeStatus { Open, Voting, Resolved }

    // Milestone struct
    struct Milestone {
        uint256 id;
        string description;
        uint256 amount; // Payment amount (wei)
        uint256 deadline;
        MilestoneStatus status;
        string deliverable; // IPFS hash
        uint256 submittedAt;
    }

    // Dispute struct
    struct Dispute {
        uint256 milestoneId;
        address initiator;
        string reason;
        string consultantResponse;
        address[] jurors; // 5 Rank 3+ members
        mapping(address => bool) hasVoted;
        uint256 votesFor; // For consultant
        uint256 votesAgainst; // For client
        DisputeStatus status;
        address winner;
        uint256 createdAt;
        uint256 votingDeadline; // 72 hours from creation
    }

    // State variables
    uint256 public missionId;
    address public client;
    address public consultant;
    uint256 public totalBudget;
    uint256 public releasedFunds;

    Milestone[] public milestones;
    mapping(uint256 => Dispute) public disputes;
    uint256 public disputeCounter;

    IERC20 public immutable daosToken;
    address public membershipContract;

    // Constants
    uint256 public constant AUTO_RELEASE_DELAY = 7 days;
    uint256 public constant DISPUTE_DEPOSIT = 100 ether; // 100 DAOS
    uint256 public constant JURY_SIZE = 5;
    uint256 public constant VOTING_PERIOD = 72 hours;

    // Events
    event MilestoneAdded(uint256 indexed milestoneId, string description, uint256 amount, uint256 deadline);
    event MilestoneSubmitted(uint256 indexed milestoneId, string deliverable);
    event MilestoneApproved(uint256 indexed milestoneId, uint256 amountReleased);
    event MilestoneRejected(uint256 indexed milestoneId, string reason);
    event DisputeRaised(uint256 indexed disputeId, uint256 indexed milestoneId, address initiator);
    event DisputeVoteCast(uint256 indexed disputeId, address indexed juror, bool favorConsultant);
    event DisputeResolved(uint256 indexed disputeId, address winner, uint256 amountAwarded);

    // Errors
    error UnauthorizedClient();
    error UnauthorizedConsultant();
    error InvalidMilestone();
    error MilestoneNotSubmitted();
    error InsufficientDeposit();
    error AlreadyVoted();
    error NotJuror();
    error DisputeNotVoting();
    error VotingPeriodNotEnded();

    constructor(
        uint256 _missionId,
        address _client,
        address _consultant,
        uint256 _totalBudget,
        address _daosToken,
        address _membershipContract
    ) {
        missionId = _missionId;
        client = _client;
        consultant = _consultant;
        totalBudget = _totalBudget;
        daosToken = IERC20(_daosToken);
        membershipContract = _membershipContract;

        _grantRole(DEFAULT_ADMIN_ROLE, _client);
    }

    /**
     * @notice Add a milestone (client only, during setup phase)
     * @param description Milestone description
     * @param amount Payment amount for this milestone
     * @param deadline Deadline timestamp
     */
    function addMilestone(
        string memory description,
        uint256 amount,
        uint256 deadline
    ) external {
        if (msg.sender != client) revert UnauthorizedClient();

        uint256 milestoneId = milestones.length;

        milestones.push(Milestone({
            id: milestoneId,
            description: description,
            amount: amount,
            deadline: deadline,
            status: MilestoneStatus.Pending,
            deliverable: "",
            submittedAt: 0
        }));

        emit MilestoneAdded(milestoneId, description, amount, deadline);
    }

    /**
     * @notice Submit milestone deliverable (consultant only)
     * @param milestoneId Milestone index
     * @param deliverable IPFS hash of deliverable
     */
    function submitMilestone(
        uint256 milestoneId,
        string memory deliverable
    ) external nonReentrant {
        if (msg.sender != consultant) revert UnauthorizedConsultant();
        if (milestoneId >= milestones.length) revert InvalidMilestone();

        Milestone storage milestone = milestones[milestoneId];

        if (milestone.status != MilestoneStatus.Pending) revert InvalidMilestone();

        // Sequential validation: Cannot submit milestone N+1 if milestone N not approved
        if (milestoneId > 0) {
            Milestone storage prevMilestone = milestones[milestoneId - 1];
            require(
                prevMilestone.status == MilestoneStatus.Approved,
                "Previous milestone must be approved"
            );
        }

        milestone.status = MilestoneStatus.Submitted;
        milestone.deliverable = deliverable;
        milestone.submittedAt = block.timestamp;

        emit MilestoneSubmitted(milestoneId, deliverable);
    }

    /**
     * @notice Approve milestone and release payment (client only)
     * @param milestoneId Milestone index
     */
    function approveMilestone(uint256 milestoneId) external nonReentrant {
        if (msg.sender != client) revert UnauthorizedClient();
        if (milestoneId >= milestones.length) revert InvalidMilestone();

        Milestone storage milestone = milestones[milestoneId];

        if (milestone.status != MilestoneStatus.Submitted) revert MilestoneNotSubmitted();

        milestone.status = MilestoneStatus.Approved;

        // Release payment to consultant
        bool success = daosToken.transfer(consultant, milestone.amount);
        require(success, "Payment transfer failed");

        releasedFunds += milestone.amount;

        emit MilestoneApproved(milestoneId, milestone.amount);
    }

    /**
     * @notice Reject milestone (client only)
     * @param milestoneId Milestone index
     * @param reason Rejection reason
     */
    function rejectMilestone(
        uint256 milestoneId,
        string memory reason
    ) external {
        if (msg.sender != client) revert UnauthorizedClient();
        if (milestoneId >= milestones.length) revert InvalidMilestone();

        Milestone storage milestone = milestones[milestoneId];

        if (milestone.status != MilestoneStatus.Submitted) revert MilestoneNotSubmitted();

        milestone.status = MilestoneStatus.Rejected;

        emit MilestoneRejected(milestoneId, reason);
    }

    /**
     * @notice Auto-release milestone if client doesn't approve/reject within 7 days
     * @param milestoneId Milestone index
     */
    function autoReleaseMilestone(uint256 milestoneId) external nonReentrant {
        if (milestoneId >= milestones.length) revert InvalidMilestone();

        Milestone storage milestone = milestones[milestoneId];

        require(
            milestone.status == MilestoneStatus.Submitted,
            "Milestone not submitted"
        );

        require(
            block.timestamp >= milestone.submittedAt + AUTO_RELEASE_DELAY,
            "Auto-release delay not met"
        );

        milestone.status = MilestoneStatus.Approved;

        // Release payment to consultant
        bool success = daosToken.transfer(consultant, milestone.amount);
        require(success, "Payment transfer failed");

        releasedFunds += milestone.amount;

        emit MilestoneApproved(milestoneId, milestone.amount);
    }

    /**
     * @notice Raise a dispute (client or consultant)
     * @param milestoneId Milestone index
     * @param reason Dispute reason
     */
    function raiseDispute(
        uint256 milestoneId,
        string memory reason
    ) external payable nonReentrant returns (uint256) {
        if (msg.sender != client && msg.sender != consultant) {
            revert UnauthorizedClient();
        }

        if (milestoneId >= milestones.length) revert InvalidMilestone();

        // Require 100 DAOS deposit (refunded if won)
        require(msg.value >= DISPUTE_DEPOSIT, "Insufficient deposit");

        Milestone storage milestone = milestones[milestoneId];
        milestone.status = MilestoneStatus.Disputed;

        uint256 disputeId = disputeCounter++;

        // Select jury (5 Rank 3+ members, pseudo-random, exclude client/consultant)
        address[] memory jurors = selectJury();

        Dispute storage dispute = disputes[disputeId];
        dispute.milestoneId = milestoneId;
        dispute.initiator = msg.sender;
        dispute.reason = reason;
        dispute.jurors = jurors;
        dispute.status = DisputeStatus.Voting;
        dispute.createdAt = block.timestamp;
        dispute.votingDeadline = block.timestamp + VOTING_PERIOD;

        // Grant juror role
        for (uint256 i = 0; i < jurors.length; i++) {
            _grantRole(JUROR_ROLE, jurors[i]);
        }

        emit DisputeRaised(disputeId, milestoneId, msg.sender);

        return disputeId;
    }

    /**
     * @notice Vote on dispute (jurors only)
     * @param disputeId Dispute ID
     * @param favorConsultant True if voting for consultant, false for client
     */
    function voteOnDispute(
        uint256 disputeId,
        bool favorConsultant
    ) external {
        Dispute storage dispute = disputes[disputeId];

        if (!hasRole(JUROR_ROLE, msg.sender)) revert NotJuror();
        if (dispute.status != DisputeStatus.Voting) revert DisputeNotVoting();
        if (dispute.hasVoted[msg.sender]) revert AlreadyVoted();

        // Check if msg.sender is in jurors array
        bool isJuror = false;
        for (uint256 i = 0; i < dispute.jurors.length; i++) {
            if (dispute.jurors[i] == msg.sender) {
                isJuror = true;
                break;
            }
        }

        require(isJuror, "Not a juror for this dispute");

        dispute.hasVoted[msg.sender] = true;

        if (favorConsultant) {
            dispute.votesFor++;
        } else {
            dispute.votesAgainst++;
        }

        emit DisputeVoteCast(disputeId, msg.sender, favorConsultant);

        // Check if majority reached (3/5 votes)
        if (dispute.votesFor >= 3 || dispute.votesAgainst >= 3) {
            resolveDispute(disputeId);
        }
    }

    /**
     * @notice Resolve dispute based on votes or after voting period
     * @param disputeId Dispute ID
     */
    function resolveDispute(uint256 disputeId) public nonReentrant {
        Dispute storage dispute = disputes[disputeId];

        require(
            dispute.status == DisputeStatus.Voting,
            "Dispute not in voting status"
        );

        require(
            dispute.votesFor >= 3 || dispute.votesAgainst >= 3 || block.timestamp >= dispute.votingDeadline,
            "Voting not concluded"
        );

        dispute.status = DisputeStatus.Resolved;

        Milestone storage milestone = milestones[dispute.milestoneId];

        // Determine winner
        address winner;
        uint256 amountAwarded;

        if (dispute.votesFor > dispute.votesAgainst) {
            // Consultant wins
            winner = consultant;
            amountAwarded = milestone.amount;
            milestone.status = MilestoneStatus.Approved;

            // Release payment to consultant
            bool success = daosToken.transfer(consultant, milestone.amount);
            require(success, "Payment transfer failed");

            releasedFunds += milestone.amount;

            // Refund deposit to initiator if consultant
            if (dispute.initiator == consultant) {
                payable(consultant).transfer(DISPUTE_DEPOSIT);
            }
        } else if (dispute.votesAgainst > dispute.votesFor) {
            // Client wins
            winner = client;
            amountAwarded = milestone.amount;
            milestone.status = MilestoneStatus.Rejected;

            // Refund deposit to initiator if client
            if (dispute.initiator == client) {
                payable(client).transfer(DISPUTE_DEPOSIT);
            }
        } else {
            // Tie (rare) - split 50/50
            winner = address(0);
            amountAwarded = milestone.amount / 2;

            bool success1 = daosToken.transfer(consultant, milestone.amount / 2);
            bool success2 = daosToken.transfer(client, milestone.amount / 2);
            require(success1 && success2, "Payment transfer failed");

            releasedFunds += milestone.amount / 2;

            // Refund half deposit to both
            payable(consultant).transfer(DISPUTE_DEPOSIT / 2);
            payable(client).transfer(DISPUTE_DEPOSIT / 2);
        }

        dispute.winner = winner;

        // Revoke juror role
        for (uint256 i = 0; i < dispute.jurors.length; i++) {
            _revokeRole(JUROR_ROLE, dispute.jurors[i]);
        }

        emit DisputeResolved(disputeId, winner, amountAwarded);
    }

    /**
     * @notice Select jury (pseudo-random, 5 Rank 3+ members, exclude client/consultant)
     * @dev In production, use Chainlink VRF for true randomness
     */
    function selectJury() internal view returns (address[] memory) {
        // Mock implementation: Get eligible members from membership contract
        (bool success, bytes memory data) = membershipContract.staticcall(
            abi.encodeWithSignature("getEligibleJurors(address,address)", client, consultant)
        );

        require(success, "Failed to get jurors");

        address[] memory eligibleJurors = abi.decode(data, (address[]));

        require(eligibleJurors.length >= JURY_SIZE, "Insufficient eligible jurors");

        address[] memory selectedJurors = new address[](JURY_SIZE);

        // Pseudo-random selection using blockhash (INSECURE, demo only)
        uint256 seed = uint256(keccak256(abi.encodePacked(block.timestamp, blockhash(block.number - 1))));

        for (uint256 i = 0; i < JURY_SIZE; i++) {
            uint256 randomIndex = (seed + i) % eligibleJurors.length;
            selectedJurors[i] = eligibleJurors[randomIndex];
        }

        return selectedJurors;
    }

    /**
     * @notice Get milestone details
     * @param milestoneId Milestone index
     */
    function getMilestone(uint256 milestoneId) external view returns (Milestone memory) {
        require(milestoneId < milestones.length, "Invalid milestone ID");
        return milestones[milestoneId];
    }

    /**
     * @notice Get total number of milestones
     */
    function getMilestoneCount() external view returns (uint256) {
        return milestones.length;
    }

    /**
     * @notice Get dispute jurors
     * @param disputeId Dispute ID
     */
    function getDisputeJurors(uint256 disputeId) external view returns (address[] memory) {
        return disputes[disputeId].jurors;
    }

    /**
     * @notice Withdraw remaining funds (client only, after all milestones approved/rejected)
     */
    function withdrawRemainingFunds() external nonReentrant {
        if (msg.sender != client) revert UnauthorizedClient();

        uint256 remaining = totalBudget - releasedFunds;

        require(remaining > 0, "No funds to withdraw");

        bool success = daosToken.transfer(client, remaining);
        require(success, "Withdrawal failed");
    }
}
