// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title HybridPaymentSplitter
 * @notice Distribution des revenus entre contributeurs Human/AI/Compute
 * @dev Usage-based payment calculation with metering integration
 */
contract HybridPaymentSplitter is AccessControl, ReentrancyGuard {
    bytes32 public constant METER_ROLE = keccak256("METER_ROLE");
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    // Contributor type enum
    enum ContributorType { Human, AI, Compute }

    // Contributor struct
    struct Contributor {
        address payable account;
        ContributorType contributorType;
        uint256 percentageBps; // Basis points (10000 = 100%)
        uint256 totalEarned;
    }

    // Usage metrics struct
    struct UsageMetrics {
        uint256 llmTokensUsed; // OpenAI tokens (prompt + completion)
        uint256 gpuHoursUsed; // GPU-hours (scaled by 1000: 1.5h = 1500)
        uint256 lastUpdated;
    }

    // Pricing struct
    struct Pricing {
        uint256 pricePerMTokenLLM; // Price per 1M tokens (wei)
        uint256 pricePerGPUHour; // Price per GPU-hour (wei)
    }

    // State variables
    uint256 public missionId;
    Contributor[] public contributors;
    UsageMetrics public usageMetrics;
    Pricing public pricing;

    IERC20 public immutable daosToken;

    // Events
    event ContributorAdded(address indexed account, ContributorType contributorType, uint256 percentageBps);
    event UsageReported(uint256 llmTokens, uint256 gpuHours);
    event PaymentDistributed(address indexed recipient, uint256 amount, ContributorType contributorType);
    event PricingUpdated(uint256 pricePerMTokenLLM, uint256 pricePerGPUHour);

    // Errors
    error InvalidPercentage();
    error UnauthorizedMeter();
    error InsufficientFunds();
    error ContributorNotFound();
    error TransferFailed();
    error InvalidIndex(uint256 index, uint256 max);
    error NoFundsToWithdraw();
    error WithdrawalFailed();

    constructor(
        uint256 _missionId,
        address _daosToken,
        address _admin
    ) {
        missionId = _missionId;
        daosToken = IERC20(_daosToken);

        _grantRole(DEFAULT_ADMIN_ROLE, _admin);
        _grantRole(ADMIN_ROLE, _admin);

        // Default pricing (can be updated)
        // Example: $0.002 per 1K tokens = $2 per 1M tokens
        // If DAOS = $0.10, then 20 DAOS per 1M tokens
        pricing = Pricing({
            pricePerMTokenLLM: 20 ether, // 20 DAOS per 1M tokens
            pricePerGPUHour: 10 ether // 10 DAOS per GPU-hour
        });
    }

    /**
     * @notice Add a contributor
     * @param account Contributor address
     * @param contributorType Human/AI/Compute
     * @param percentageBps Percentage in basis points (10000 = 100%)
     */
    function addContributor(
        address payable account,
        ContributorType contributorType,
        uint256 percentageBps
    ) external onlyRole(ADMIN_ROLE) {
        if (percentageBps > 10000) revert InvalidPercentage();

        contributors.push(Contributor({
            account: account,
            contributorType: contributorType,
            percentageBps: percentageBps,
            totalEarned: 0
        }));

        emit ContributorAdded(account, contributorType, percentageBps);
    }

    /**
     * @notice Report usage metrics (Oracle with METER_ROLE)
     * @param llmTokens LLM tokens used (prompt + completion)
     * @param gpuHours GPU-hours used (scaled by 1000)
     */
    function reportUsage(
        uint256 llmTokens,
        uint256 gpuHours
    ) external onlyRole(METER_ROLE) {
        usageMetrics.llmTokensUsed += llmTokens;
        usageMetrics.gpuHoursUsed += gpuHours;
        usageMetrics.lastUpdated = block.timestamp;

        emit UsageReported(llmTokens, gpuHours);
    }

    /**
     * @notice Distribute payment to contributors
     * @param totalAmount Total amount to distribute (wei)
     */
    function distributePayment(uint256 totalAmount) external nonReentrant onlyRole(ADMIN_ROLE) {
        uint256 balance = daosToken.balanceOf(address(this));
        if (balance < totalAmount) revert InsufficientFunds();

        uint256 remainingAmount = totalAmount;

        // Calculate usage-based costs first (AI + Compute)
        uint256 aiUsageCost = calculateAIUsageCost();
        uint256 computeUsageCost = calculateComputeUsageCost();

        // Distribute to each contributor
        for (uint256 i = 0; i < contributors.length; i++) {
            Contributor storage contributor = contributors[i];
            uint256 share = calculateShare(contributor, totalAmount, aiUsageCost, computeUsageCost);

            if (share > 0 && share <= remainingAmount) {
                bool success = daosToken.transfer(contributor.account, share);
                if (!success) revert TransferFailed();

                contributor.totalEarned += share;
                remainingAmount -= share;

                emit PaymentDistributed(contributor.account, share, contributor.contributorType);
            }
        }

        // Transfer any remaining dust to admin (rounding errors)
        if (remainingAmount > 0) {
            bool success = daosToken.transfer(msg.sender, remainingAmount);
            if (!success) revert TransferFailed();
        }
    }

    /**
     * @notice Calculate share for a contributor
     * @param contributor Contributor struct
     * @param totalAmount Total amount to distribute
     * @param aiUsageCost Calculated AI usage cost
     * @param computeUsageCost Calculated compute usage cost
     */
    function calculateShare(
        Contributor storage contributor,
        uint256 totalAmount,
        uint256 aiUsageCost,
        uint256 computeUsageCost
    ) internal view returns (uint256) {
        if (contributor.contributorType == ContributorType.Human) {
            // Fixed percentage
            return (totalAmount * contributor.percentageBps) / 10000;

        } else if (contributor.contributorType == ContributorType.AI) {
            // Usage-based: usage cost + fixed percentage of remaining
            uint256 fixedShare = (totalAmount * contributor.percentageBps) / 10000;
            return aiUsageCost + fixedShare;

        } else if (contributor.contributorType == ContributorType.Compute) {
            // Usage-based: usage cost + fixed percentage of remaining
            uint256 fixedShare = (totalAmount * contributor.percentageBps) / 10000;
            return computeUsageCost + fixedShare;

        } else {
            return 0;
        }
    }

    /**
     * @notice Calculate AI usage cost based on LLM tokens
     */
    function calculateAIUsageCost() public view returns (uint256) {
        // Cost = (tokens / 1M) * pricePerMTokenLLM
        return (usageMetrics.llmTokensUsed * pricing.pricePerMTokenLLM) / 1_000_000;
    }

    /**
     * @notice Calculate compute usage cost based on GPU-hours
     */
    function calculateComputeUsageCost() public view returns (uint256) {
        // Cost = (gpu-hours / 1000) * pricePerGPUHour
        // (usageMetrics scaled by 1000: 1.5h = 1500)
        return (usageMetrics.gpuHoursUsed * pricing.pricePerGPUHour) / 1000;
    }

    /**
     * @notice Update pricing (admin only)
     * @param pricePerMTokenLLM New price per 1M LLM tokens (wei)
     * @param pricePerGPUHour New price per GPU-hour (wei)
     */
    function updatePricing(
        uint256 pricePerMTokenLLM,
        uint256 pricePerGPUHour
    ) external onlyRole(ADMIN_ROLE) {
        pricing.pricePerMTokenLLM = pricePerMTokenLLM;
        pricing.pricePerGPUHour = pricePerGPUHour;

        emit PricingUpdated(pricePerMTokenLLM, pricePerGPUHour);
    }

    /**
     * @notice Get contributor count
     */
    function getContributorCount() external view returns (uint256) {
        return contributors.length;
    }

    /**
     * @notice Get contributor details
     * @param index Contributor index
     */
    function getContributor(uint256 index) external view returns (
        address account,
        ContributorType contributorType,
        uint256 percentageBps,
        uint256 totalEarned
    ) {
        if (index >= contributors.length) {
            revert InvalidIndex(index, contributors.length);
        }

        Contributor storage contributor = contributors[index];

        return (
            contributor.account,
            contributor.contributorType,
            contributor.percentageBps,
            contributor.totalEarned
        );
    }

    /**
     * @notice Get current usage metrics
     */
    function getUsageMetrics() external view returns (
        uint256 llmTokensUsed,
        uint256 gpuHoursUsed,
        uint256 lastUpdated
    ) {
        return (
            usageMetrics.llmTokensUsed,
            usageMetrics.gpuHoursUsed,
            usageMetrics.lastUpdated
        );
    }

    /**
     * @notice Get current pricing
     */
    function getPricing() external view returns (
        uint256 pricePerMTokenLLM,
        uint256 pricePerGPUHour
    ) {
        return (
            pricing.pricePerMTokenLLM,
            pricing.pricePerGPUHour
        );
    }

    /**
     * @notice Grant meter role (admin only)
     * @param meter Meter oracle address
     */
    function grantMeterRole(address meter) external onlyRole(ADMIN_ROLE) {
        _grantRole(METER_ROLE, meter);
    }

    /**
     * @notice Revoke meter role (admin only)
     * @param meter Meter oracle address
     */
    function revokeMeterRole(address meter) external onlyRole(ADMIN_ROLE) {
        _revokeRole(METER_ROLE, meter);
    }

    /**
     * @notice Withdraw remaining funds (admin only, emergency)
     */
    function emergencyWithdraw() external onlyRole(ADMIN_ROLE) nonReentrant {
        uint256 balance = daosToken.balanceOf(address(this));
        if (balance == 0) revert NoFundsToWithdraw();

        bool success = daosToken.transfer(msg.sender, balance);
        if (!success) revert WithdrawalFailed();
    }

    /**
     * @notice Reset usage metrics (admin only, after payment distribution)
     */
    function resetUsageMetrics() external onlyRole(ADMIN_ROLE) {
        usageMetrics.llmTokensUsed = 0;
        usageMetrics.gpuHoursUsed = 0;
        usageMetrics.lastUpdated = block.timestamp;
    }
}
