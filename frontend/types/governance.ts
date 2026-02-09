/**
 * Governance Types
 * Types for DAO governance voting system
 */

export enum ProposalTrack {
  Technical = 0,
  Treasury = 1,
  Membership = 2,
}

export enum ProposalStatus {
  Pending = 0,
  Active = 1,
  Canceled = 2,
  Defeated = 3,
  Succeeded = 4,
  Queued = 5,
  Expired = 6,
  Executed = 7,
}

export enum VoteType {
  Against = 0,
  For = 1,
  Abstain = 2,
}

export interface Proposal {
  id: string;
  track: ProposalTrack;
  status: ProposalStatus;
  proposer: string;
  title: string;
  description: string;
  forVotes: bigint;
  againstVotes: bigint;
  abstainVotes: bigint;
  quorum: bigint;
  voteStart: number; // block number
  voteEnd: number;
  snapshot: number; // block number for voting power
  executionDelay: number; // timelock delay in seconds
  targets?: string[];
  values?: bigint[];
  calldatas?: string[];
  createdAt: number; // timestamp
}

export interface VoteReceipt {
  hasVoted: boolean;
  support: VoteType;
  votes: bigint;
  reason?: string;
}

export interface VotingPower {
  rank: number; // 0-4
  tokensHeld: bigint;
  voteWeight: number; // triangular formula result
  percentage: number; // % of total voting power
}

export interface ProposalImpact {
  category: 'governance' | 'technical' | 'treasury' | 'membership';
  changes: {
    parameter: string;
    currentValue: string;
    proposedValue: string;
    impact: 'low' | 'medium' | 'high' | 'critical';
  }[];
  summary: string;
}

export interface JuryMember {
  address: string;
  rank: number;
  reputation: number;
  hasVoted: boolean;
  vote?: VoteType;
  justification?: string;
}

export interface Dispute {
  id: string;
  missionId: string;
  milestoneId: string;
  plaintiff: string; // client or consultant
  defendant: string;
  reason: string;
  evidence: string; // IPFS hash
  amountContested: bigint;
  status: 'open' | 'jury_selected' | 'voting' | 'resolved';
  jury: JuryMember[];
  createdAt: number;
  votingDeadline: number;
  resolution?: {
    verdict: 'favor_plaintiff' | 'favor_defendant' | 'compromise';
    refundAmount: bigint;
    resolvedAt: number;
  };
}

// Voting power calculation (triangular formula)
export const RANK_WEIGHTS: Record<number, number> = {
  0: 0,
  1: 1,
  2: 3,
  3: 6,
  4: 10,
};

export function calculateVotingPower(rank: number, tokensHeld: bigint): VotingPower {
  const baseWeight = RANK_WEIGHTS[rank] || 0;
  const tokenMultiplier = Number(tokensHeld) / 1e18; // Convert wei to tokens
  const voteWeight = baseWeight * (1 + Math.log10(1 + tokenMultiplier));

  return {
    rank,
    tokensHeld,
    voteWeight,
    percentage: 0, // Calculate in context of total voting power
  };
}

export function formatProposalStatus(status: ProposalStatus): string {
  switch (status) {
    case ProposalStatus.Pending:
      return 'Pending';
    case ProposalStatus.Active:
      return 'Active';
    case ProposalStatus.Canceled:
      return 'Canceled';
    case ProposalStatus.Defeated:
      return 'Defeated';
    case ProposalStatus.Succeeded:
      return 'Succeeded';
    case ProposalStatus.Queued:
      return 'Queued';
    case ProposalStatus.Expired:
      return 'Expired';
    case ProposalStatus.Executed:
      return 'Executed';
    default:
      return 'Unknown';
  }
}

export function formatVoteType(vote: VoteType): string {
  switch (vote) {
    case VoteType.Against:
      return 'Against';
    case VoteType.For:
      return 'For';
    case VoteType.Abstain:
      return 'Abstain';
    default:
      return 'Unknown';
  }
}

export function getProposalStatusColor(status: ProposalStatus): string {
  switch (status) {
    case ProposalStatus.Pending:
      return 'gray';
    case ProposalStatus.Active:
      return 'blue';
    case ProposalStatus.Succeeded:
      return 'green';
    case ProposalStatus.Defeated:
      return 'red';
    case ProposalStatus.Executed:
      return 'purple';
    default:
      return 'gray';
  }
}

export function getQuorumProgress(proposal: Proposal): number {
  const totalVotes = proposal.forVotes + proposal.againstVotes + proposal.abstainVotes;
  return Number((totalVotes * 100n) / proposal.quorum);
}

export function getVoteBreakdown(proposal: Proposal): {
  forPercentage: number;
  againstPercentage: number;
  abstainPercentage: number;
} {
  const total = proposal.forVotes + proposal.againstVotes + proposal.abstainVotes;

  if (total === 0n) {
    return { forPercentage: 0, againstPercentage: 0, abstainPercentage: 0 };
  }

  return {
    forPercentage: Number((proposal.forVotes * 100n) / total),
    againstPercentage: Number((proposal.againstVotes * 100n) / total),
    abstainPercentage: Number((proposal.abstainVotes * 100n) / total),
  };
}
