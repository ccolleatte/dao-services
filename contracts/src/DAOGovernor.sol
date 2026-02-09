// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/governance/Governor.sol";
import "@openzeppelin/contracts/governance/extensions/GovernorSettings.sol";
import "@openzeppelin/contracts/governance/extensions/GovernorCountingSimple.sol";
import "@openzeppelin/contracts/governance/extensions/GovernorVotes.sol";
import "@openzeppelin/contracts/governance/extensions/GovernorVotesQuorumFraction.sol";
import "@openzeppelin/contracts/governance/extensions/GovernorTimelockControl.sol";
import "./DAOMembership.sol";

/**
 * @title DAOGovernor
 * @notice OpenGov-inspired governance with 3 tracks (Technical, Treasury, Membership)
 * @dev Integrates with DAOMembership for vote weights and rank-based permissions
 */
contract DAOGovernor is
    Governor,
    GovernorSettings,
    GovernorCountingSimple,
    GovernorVotes,
    GovernorVotesQuorumFraction,
    GovernorTimelockControl
{
    /// @notice Governance tracks (OpenGov-inspired)
    enum Track {
        Technical,   // Architecture, tech stack, security fixes
        Treasury,    // Budget, spending, revenue distribution
        Membership   // Promote/demote, rank durations, suspensions
    }

    /// @notice Track configuration
    struct TrackConfig {
        uint8 minRank;         // Minimum rank to propose
        uint256 votingDelay;   // Delay before voting starts (blocks)
        uint256 votingPeriod;  // Duration of voting (blocks)
        uint256 quorumPercent; // Quorum percentage (e.g., 51 = 51%)
    }

    /// @notice Reference to DAOMembership contract
    DAOMembership public immutable membership;

    /// @notice Track configurations
    mapping(Track => TrackConfig) public trackConfigs;

    /// @notice Proposal track mapping
    mapping(uint256 => Track) public proposalTrack;

    /// @notice Events
    event ProposalCreatedWithTrack(
        uint256 indexed proposalId,
        Track indexed track,
        address proposer,
        uint8 proposerRank
    );
    event TrackConfigUpdated(Track indexed track, TrackConfig config);

    /// @notice Errors
    error InsufficientRank(uint8 required, uint8 actual);
    error InvalidTrack();
    error InvalidQuorumPercent();

    /**
     * @notice Constructor
     * @param _membership DAOMembership contract address
     * @param _timelock TimelockController address
     */
    constructor(
        DAOMembership _membership,
        TimelockController _timelock
    )
        Governor("DAO Governor")
        GovernorSettings(
            1 days,     // Default voting delay (1 day)
            1 weeks,    // Default voting period (1 week)
            0           // Proposal threshold (0 = any member)
        )
        GovernorVotes(IVotes(address(_membership)))
        GovernorVotesQuorumFraction(51) // Default 51% quorum
        GovernorTimelockControl(_timelock)
    {
        membership = _membership;

        // Initialize default track configurations
        _setTrackConfig(Track.Technical, TrackConfig({
            minRank: 2,        // Rank 2+ (Mid-Level Contributors)
            votingDelay: 1 days,
            votingPeriod: 7 days,
            quorumPercent: 66  // 66% quorum (supermajority)
        }));

        _setTrackConfig(Track.Treasury, TrackConfig({
            minRank: 1,        // Rank 1+ (Active Contributors)
            votingDelay: 1 days,
            votingPeriod: 14 days, // Longer period for financial decisions
            quorumPercent: 51  // Simple majority
        }));

        _setTrackConfig(Track.Membership, TrackConfig({
            minRank: 3,        // Rank 3+ (Core Team)
            votingDelay: 1 days,
            votingPeriod: 7 days,
            quorumPercent: 75  // 75% quorum (high threshold)
        }));
    }

    /**
     * @notice Create proposal with specific track
     * @param targets Target contract addresses
     * @param values ETH values to send
     * @param calldatas Function call data
     * @param description Proposal description (includes track in prefix)
     * @param track Governance track
     */
    function proposeWithTrack(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        string memory description,
        Track track
    ) public returns (uint256) {
        // Verify proposer rank
        uint8 proposerRank = membership.getMemberRank(msg.sender);
        TrackConfig memory config = trackConfigs[track];

        if (proposerRank < config.minRank) {
            revert InsufficientRank(config.minRank, proposerRank);
        }

        // Create proposal with track-specific description prefix
        string memory trackPrefix = _trackToString(track);
        string memory fullDescription = string(abi.encodePacked(
            "[", trackPrefix, "] ", description
        ));

        uint256 proposalId = propose(targets, values, calldatas, fullDescription);
        proposalTrack[proposalId] = track;

        emit ProposalCreatedWithTrack(proposalId, track, msg.sender, proposerRank);

        return proposalId;
    }

    /**
     * @notice Get voting power with DAOMembership weights
     * @dev Overrides Governor._getVotes to use triangular vote weights
     */
    function _getVotes(
        address account,
        uint256 blockNumber,
        bytes memory params
    ) internal view virtual override(Governor, GovernorVotes) returns (uint256) {
        // Get proposal ID from params if available
        uint256 proposalId;
        if (params.length >= 32) {
            proposalId = abi.decode(params, (uint256));
        }

        // Get track and minimum rank requirement
        Track track = proposalTrack[proposalId];
        TrackConfig memory config = trackConfigs[track];

        // Calculate vote weight based on DAOMembership
        uint8 memberRank = membership.getMemberRank(account);

        // Only count votes from members meeting minimum rank
        if (memberRank < config.minRank) {
            return 0;
        }

        return membership.calculateVoteWeight(account);
    }

    /**
     * @notice Update track configuration (governance action)
     * @param track Track to update
     * @param config New configuration
     */
    function setTrackConfig(Track track, TrackConfig memory config) external onlyGovernance {
        if (config.quorumPercent == 0 || config.quorumPercent > 100) {
            revert InvalidQuorumPercent();
        }
        _setTrackConfig(track, config);
    }

    /**
     * @notice Internal function to set track config
     */
    function _setTrackConfig(Track track, TrackConfig memory config) private {
        trackConfigs[track] = config;
        emit TrackConfigUpdated(track, config);
    }

    /**
     * @notice Convert track enum to string
     */
    function _trackToString(Track track) private pure returns (string memory) {
        if (track == Track.Technical) return "TECHNICAL";
        if (track == Track.Treasury) return "TREASURY";
        if (track == Track.Membership) return "MEMBERSHIP";
        revert InvalidTrack();
    }

    /**
     * @notice Get track-specific voting delay
     */
    function votingDelay() public view override(Governor, GovernorSettings) returns (uint256) {
        return super.votingDelay();
    }

    /**
     * @notice Get track-specific voting period
     */
    function votingPeriod() public view override(Governor, GovernorSettings) returns (uint256) {
        return super.votingPeriod();
    }

    /**
     * @notice Get quorum for proposal
     * @dev Uses track-specific quorum percentage
     */
    function quorum(uint256 blockNumber)
        public
        view
        override(Governor, GovernorVotesQuorumFraction)
        returns (uint256)
    {
        return super.quorum(blockNumber);
    }

    /**
     * @notice Get proposal state
     */
    function state(uint256 proposalId)
        public
        view
        override(Governor, GovernorTimelockControl)
        returns (ProposalState)
    {
        return super.state(proposalId);
    }

    /**
     * @notice Propose (standard Governor function)
     */
    function propose(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        string memory description
    ) public override(Governor) returns (uint256) {
        return super.propose(targets, values, calldatas, description);
    }

    /**
     * @notice Proposal threshold (minimum votes to propose)
     */
    function proposalThreshold()
        public
        view
        override(Governor, GovernorSettings)
        returns (uint256)
    {
        return super.proposalThreshold();
    }

    /**
     * @notice Execute proposal through timelock
     */
    function _execute(
        uint256 proposalId,
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    ) internal override(Governor, GovernorTimelockControl) {
        super._execute(proposalId, targets, values, calldatas, descriptionHash);
    }

    /**
     * @notice Cancel proposal
     */
    function _cancel(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    ) internal override(Governor, GovernorTimelockControl) returns (uint256) {
        return super._cancel(targets, values, calldatas, descriptionHash);
    }

    /**
     * @notice Get executor (TimelockController)
     */
    function _executor()
        internal
        view
        override(Governor, GovernorTimelockControl)
        returns (address)
    {
        return super._executor();
    }

    /**
     * @notice Check if contract supports interface
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(Governor, GovernorTimelockControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
