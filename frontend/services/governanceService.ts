/**
 * Governance Service
 * Handles all interactions with DAOGovernor smart contract
 */

import { ethers } from 'ethers';
import {
  Proposal,
  ProposalTrack,
  ProposalStatus,
  VoteType,
  VoteReceipt,
} from '../types/governance.js';

// DAOGovernor ABI (minimal interface for voting)
const DAO_GOVERNOR_ABI = [
  'function propose(address[] targets, uint256[] values, bytes[] calldatas, string description) returns (uint256)',
  'function castVote(uint256 proposalId, uint8 support) returns (uint256)',
  'function castVoteWithReason(uint256 proposalId, uint8 support, string reason) returns (uint256)',
  'function getReceipt(uint256 proposalId, address voter) view returns (bool hasVoted, uint8 support, uint256 votes)',
  'function state(uint256 proposalId) view returns (uint8)',
  'function proposalVotes(uint256 proposalId) view returns (uint256 againstVotes, uint256 forVotes, uint256 abstainVotes)',
  'function proposalSnapshot(uint256 proposalId) view returns (uint256)',
  'function proposalDeadline(uint256 proposalId) view returns (uint256)',
  'function quorum(uint256 blockNumber) view returns (uint256)',
  'function getVotingPower(address account, uint256 blockNumber) view returns (uint256)',
  'event ProposalCreated(uint256 proposalId, address proposer, address[] targets, uint256[] values, string[] signatures, bytes[] calldatas, uint256 voteStart, uint256 voteEnd, string description)',
  'event VoteCast(address indexed voter, uint256 proposalId, uint8 support, uint256 weight, string reason)',
];

export class GovernanceService {
  private contract: ethers.Contract;
  private provider: ethers.Provider;
  private signer?: ethers.Signer;

  constructor(contractAddress: string, provider: ethers.Provider, signer?: ethers.Signer) {
    this.provider = provider;
    this.signer = signer;
    this.contract = new ethers.Contract(
      contractAddress,
      DAO_GOVERNOR_ABI,
      signer || provider
    );
  }

  /**
   * Fetch all proposals for a specific track
   */
  async fetchProposalsByTrack(track: ProposalTrack): Promise<Proposal[]> {
    // This would require a subgraph or events indexing
    // For now, we'll return mock data structure
    // In production, use The Graph or event logs

    const filter = this.contract.filters.ProposalCreated();
    const events = await this.contract.queryFilter(filter);

    const proposals: Proposal[] = [];

    for (const event of events) {
      const proposalId = event.args?.proposalId.toString();
      if (!proposalId) continue;

      const proposal = await this.fetchProposalById(proposalId);
      if (proposal && proposal.track === track) {
        proposals.push(proposal);
      }
    }

    return proposals;
  }

  /**
   * Fetch a single proposal by ID
   */
  async fetchProposalById(proposalId: string): Promise<Proposal | null> {
    try {
      const [state, votes, snapshot, deadline] = await Promise.all([
        this.contract.state(proposalId),
        this.contract.proposalVotes(proposalId),
        this.contract.proposalSnapshot(proposalId),
        this.contract.proposalDeadline(proposalId),
      ]);

      const quorum = await this.contract.quorum(snapshot);
      const currentBlock = await this.provider.getBlockNumber();

      // Extract track from proposal description (convention: [Track] Title)
      // In production, store track in proposal metadata
      const track = ProposalTrack.Technical; // Default

      return {
        id: proposalId,
        track,
        status: state as ProposalStatus,
        proposer: '0x0000000000000000000000000000000000000000', // Extract from event
        title: 'Proposal Title', // Extract from description
        description: 'Full proposal description', // Extract from event
        forVotes: votes.forVotes,
        againstVotes: votes.againstVotes,
        abstainVotes: votes.abstainVotes,
        quorum,
        voteStart: Number(snapshot),
        voteEnd: Number(deadline),
        snapshot: Number(snapshot),
        executionDelay: 86400, // 1 day default
        createdAt: Date.now() / 1000,
      };
    } catch (error) {
      console.error('Error fetching proposal:', error);
      return null;
    }
  }

  /**
   * Cast a vote on a proposal
   */
  async castVote(
    proposalId: string,
    support: VoteType,
    reason?: string
  ): Promise<ethers.TransactionResponse> {
    if (!this.signer) {
      throw new Error('Signer required to cast vote');
    }

    if (reason) {
      return this.contract.castVoteWithReason(proposalId, support, reason);
    }

    return this.contract.castVote(proposalId, support);
  }

  /**
   * Get user's vote receipt for a proposal
   */
  async getUserVote(proposalId: string, userAddress: string): Promise<VoteReceipt> {
    const receipt = await this.contract.getReceipt(proposalId, userAddress);

    return {
      hasVoted: receipt.hasVoted,
      support: receipt.support as VoteType,
      votes: receipt.votes,
    };
  }

  /**
   * Get user's voting power at a specific block
   */
  async getVotingPower(userAddress: string, blockNumber: number): Promise<bigint> {
    return this.contract.getVotingPower(userAddress, blockNumber);
  }

  /**
   * Subscribe to vote events
   */
  onVoteCast(
    callback: (voter: string, proposalId: string, support: VoteType, weight: bigint) => void
  ): void {
    this.contract.on('VoteCast', (voter, proposalId, support, weight) => {
      callback(voter, proposalId.toString(), support as VoteType, weight);
    });
  }

  /**
   * Unsubscribe from events
   */
  removeAllListeners(): void {
    this.contract.removeAllListeners();
  }
}

/**
 * Create governance service instance
 */
export function createGovernanceService(
  contractAddress: string,
  provider: ethers.Provider,
  signer?: ethers.Signer
): GovernanceService {
  return new GovernanceService(contractAddress, provider, signer);
}
