// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./DAOMembership.sol";

/**
 * @title DAOTreasury
 * @notice Manages DAO funds with governance-controlled spending
 * @dev Milestone-based spending with multi-sig approval patterns
 */
contract DAOTreasury is AccessControl, ReentrancyGuard {
    /// @notice Role for treasury operations
    bytes32 public constant TREASURER_ROLE = keccak256("TREASURER_ROLE");
    bytes32 public constant SPENDER_ROLE = keccak256("SPENDER_ROLE");

    /// @notice Reference to DAOMembership
    DAOMembership public immutable membership;

    /// @notice Spending proposal status
    enum ProposalStatus {
        Pending,
        Approved,
        Executed,
        Cancelled
    }

    /// @notice Spending proposal
    struct SpendingProposal {
        uint256 id;
        address payable beneficiary;
        uint256 amount;
        string description;
        address proposer;
        ProposalStatus status;
        uint256 createdAt;
        uint256 approvedAt;
        uint256 executedAt;
    }

    /// @notice Budget category
    struct Budget {
        uint256 allocated;
        uint256 spent;
        bool active;
    }

    /// @notice State variables
    uint256 public proposalCounter;
    mapping(uint256 => SpendingProposal) public proposals;
    mapping(bytes32 => Budget) public budgets; // categoryHash => Budget

    /// @notice Spending limits (governance-configurable)
    uint256 public maxSingleSpend = 100 ether; // Max without special approval
    uint256 public dailySpendLimit = 500 ether;
    uint256 public dailySpent;
    uint256 public lastSpendDay;

    /// @notice Events
    event ProposalCreated(
        uint256 indexed proposalId,
        address indexed beneficiary,
        uint256 amount,
        address proposer
    );
    event ProposalApproved(uint256 indexed proposalId, address approver);
    event ProposalExecuted(uint256 indexed proposalId, uint256 amount);
    event ProposalCancelled(uint256 indexed proposalId);
    event BudgetAllocated(bytes32 indexed category, uint256 amount);
    event BudgetSpent(bytes32 indexed category, uint256 amount);
    event FundsReceived(address indexed from, uint256 amount);
    event LimitsUpdated(uint256 maxSingleSpend, uint256 dailySpendLimit);

    /// @notice Errors
    error InsufficientFunds();
    error ProposalNotPending();
    error ProposalNotApproved();
    error ExceedsMaxSpend();
    error ExceedsDailyLimit();
    error BudgetExceeded();
    error InvalidProposal();
    error Unauthorized();
    error TransferFailed();

    /**
     * @notice Constructor
     * @param _membership DAOMembership contract
     * @param _admin Initial admin address
     */
    constructor(DAOMembership _membership, address _admin) {
        membership = _membership;

        _grantRole(DEFAULT_ADMIN_ROLE, _admin);
        _grantRole(TREASURER_ROLE, _admin);
    }

    /**
     * @notice Receive ETH
     */
    receive() external payable {
        emit FundsReceived(msg.sender, msg.value);
    }

    /**
     * @notice Create spending proposal
     * @param beneficiary Payment recipient
     * @param amount Amount to spend
     * @param description Spending justification
     * @param category Budget category (e.g., "marketing", "development")
     */
    function createProposal(
        address payable beneficiary,
        uint256 amount,
        string memory description,
        string memory category
    ) external returns (uint256) {
        // Verify proposer is active DAO member with rank > 0
        (uint8 rank,,,, bool active,,) = membership.members(msg.sender);
        if (!active || rank == 0) {
            revert Unauthorized();
        }

        if (amount == 0 || beneficiary == address(0)) {
            revert InvalidProposal();
        }

        uint256 proposalId = proposalCounter++;

        proposals[proposalId] = SpendingProposal({
            id: proposalId,
            beneficiary: beneficiary,
            amount: amount,
            description: description,
            proposer: msg.sender,
            status: ProposalStatus.Pending,
            createdAt: block.timestamp,
            approvedAt: 0,
            executedAt: 0
        });

        // Check budget if category provided
        if (bytes(category).length > 0) {
            bytes32 categoryHash = keccak256(bytes(category));
            Budget storage budget = budgets[categoryHash];

            if (budget.active) {
                if (budget.spent + amount > budget.allocated) {
                    revert BudgetExceeded();
                }
            }
        }

        emit ProposalCreated(proposalId, beneficiary, amount, msg.sender);

        return proposalId;
    }

    /**
     * @notice Approve spending proposal
     * @param proposalId Proposal to approve
     * @dev Only TREASURER_ROLE can approve
     */
    function approveProposal(uint256 proposalId) external onlyRole(TREASURER_ROLE) {
        SpendingProposal storage proposal = proposals[proposalId];

        if (proposal.status != ProposalStatus.Pending) {
            revert ProposalNotPending();
        }

        // Check spending limits
        if (proposal.amount > maxSingleSpend) {
            revert ExceedsMaxSpend();
        }

        proposal.status = ProposalStatus.Approved;
        proposal.approvedAt = block.timestamp;

        emit ProposalApproved(proposalId, msg.sender);
    }

    /**
     * @notice Execute approved spending proposal
     * @param proposalId Proposal to execute
     * @param category Budget category to deduct from (optional)
     */
    function executeProposal(
        uint256 proposalId,
        string memory category
    ) external nonReentrant onlyRole(SPENDER_ROLE) {
        SpendingProposal storage proposal = proposals[proposalId];

        if (proposal.status != ProposalStatus.Approved) {
            revert ProposalNotApproved();
        }

        // Check treasury balance
        if (address(this).balance < proposal.amount) {
            revert InsufficientFunds();
        }

        // Check daily spend limit
        if (block.timestamp / 1 days > lastSpendDay) {
            // Reset daily counter
            dailySpent = 0;
            lastSpendDay = block.timestamp / 1 days;
        }

        if (dailySpent + proposal.amount > dailySpendLimit) {
            revert ExceedsDailyLimit();
        }

        // Update budget if category provided
        if (bytes(category).length > 0) {
            bytes32 categoryHash = keccak256(bytes(category));
            Budget storage budget = budgets[categoryHash];

            if (budget.active) {
                budget.spent += proposal.amount;
                emit BudgetSpent(categoryHash, proposal.amount);
            }
        }

        // Update state
        proposal.status = ProposalStatus.Executed;
        proposal.executedAt = block.timestamp;
        dailySpent += proposal.amount;

        // Transfer funds
        (bool success, ) = proposal.beneficiary.call{value: proposal.amount}("");
        if (!success) revert TransferFailed();

        emit ProposalExecuted(proposalId, proposal.amount);
    }

    /**
     * @notice Cancel pending proposal
     * @param proposalId Proposal to cancel
     */
    function cancelProposal(uint256 proposalId) external {
        SpendingProposal storage proposal = proposals[proposalId];

        // Only proposer or treasurer can cancel
        if (msg.sender != proposal.proposer && !hasRole(TREASURER_ROLE, msg.sender)) {
            revert Unauthorized();
        }

        if (proposal.status != ProposalStatus.Pending) {
            revert ProposalNotPending();
        }

        proposal.status = ProposalStatus.Cancelled;

        emit ProposalCancelled(proposalId);
    }

    /**
     * @notice Allocate budget for category
     * @param category Budget category
     * @param amount Budget amount
     */
    function allocateBudget(
        string memory category,
        uint256 amount
    ) external onlyRole(TREASURER_ROLE) {
        bytes32 categoryHash = keccak256(bytes(category));

        budgets[categoryHash] = Budget({
            allocated: amount,
            spent: 0,
            active: true
        });

        emit BudgetAllocated(categoryHash, amount);
    }

    /**
     * @notice Update spending limits
     * @param _maxSingleSpend New max single spend
     * @param _dailySpendLimit New daily limit
     */
    function updateLimits(
        uint256 _maxSingleSpend,
        uint256 _dailySpendLimit
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        maxSingleSpend = _maxSingleSpend;
        dailySpendLimit = _dailySpendLimit;

        emit LimitsUpdated(_maxSingleSpend, _dailySpendLimit);
    }

    /**
     * @notice Get proposal details
     */
    function getProposal(uint256 proposalId)
        external
        view
        returns (SpendingProposal memory)
    {
        return proposals[proposalId];
    }

    /**
     * @notice Get budget status
     */
    function getBudget(string memory category)
        external
        view
        returns (Budget memory)
    {
        bytes32 categoryHash = keccak256(bytes(category));
        return budgets[categoryHash];
    }

    /**
     * @notice Get treasury balance
     */
    function balance() external view returns (uint256) {
        return address(this).balance;
    }

    /**
     * @notice Get daily spend remaining
     */
    function dailySpendRemaining() external view returns (uint256) {
        // Reset if new day
        if (block.timestamp / 1 days > lastSpendDay) {
            return dailySpendLimit;
        }

        return dailySpendLimit > dailySpent ? dailySpendLimit - dailySpent : 0;
    }
}
