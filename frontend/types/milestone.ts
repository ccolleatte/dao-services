/**
 * Milestone Type Definitions
 * Defines mission tracking, milestones, change requests, and disputes
 */

import { ethers } from 'ethers';

// Mission status lifecycle
export enum MissionStatus {
  Draft = 0,
  Active = 1,
  OnHold = 2,
  Disputed = 3,
  Completed = 4,
  Cancelled = 5,
}

// Milestone status
export enum MilestoneStatus {
  Pending = 0,
  InProgress = 1,
  UnderReview = 2,
  Approved = 3,
  Rejected = 4,
}

// Change request status
export enum ChangeRequestStatus {
  Pending = 0,
  Accepted = 1,
  Rejected = 2,
  Negotiating = 3,
}

// Dispute status
export enum DisputeStatus {
  Open = 0,
  UnderReview = 1,
  JurySelected = 2,
  Deliberating = 3,
  Resolved = 4,
  Closed = 5,
}

// Dispute resolution outcome
export enum DisputeOutcome {
  None = 0,
  FavorConsultant = 1,
  FavorClient = 2,
  Compromise = 3,
}

// Mission interface
export interface Mission {
  id: string;
  title: string;
  description: string;
  consultant: string;
  client: string;
  totalBudget: bigint;
  currency: 'DAOS' | 'USDC' | 'ETH';
  startDate: Date;
  endDate: Date;
  status: MissionStatus;
  escrowAddress: string;
  milestones: Milestone[];
  changeRequests: ChangeRequest[];
  disputes: Dispute[];
  createdAt: Date;
  updatedAt: Date;
}

// Milestone interface
export interface Milestone {
  id: string;
  missionId: string;
  title: string;
  description: string;
  deliverables: string[];
  amount: bigint;
  dueDate: Date;
  status: MilestoneStatus;
  completionDate?: Date;
  reviewDate?: Date;
  evidenceUrls: string[]; // IPFS hashes
  reviewNotes?: string;
  order: number; // Sequential order (1, 2, 3...)
}

// Change request interface
export interface ChangeRequest {
  id: string;
  missionId: string;
  proposedBy: string; // consultant or client address
  title: string;
  description: string;
  impact: {
    scope?: string;
    timeline?: number; // Days adjustment
    budget?: bigint; // Budget adjustment
  };
  justification: string;
  status: ChangeRequestStatus;
  createdAt: Date;
  respondedAt?: Date;
  responseNotes?: string;
}

// Dispute interface
export interface Dispute {
  id: string;
  missionId: string;
  initiatedBy: string; // consultant or client address
  subject: string;
  description: string;
  evidenceUrls: string[]; // IPFS hashes
  status: DisputeStatus;
  outcome?: DisputeOutcome;
  juryMembers: string[]; // 5 members Rank 3+
  juryVotes: JuryVote[];
  deposit: bigint; // 100 DAOS
  createdAt: Date;
  resolvedAt?: Date;
  resolutionNotes?: string;
}

// Jury vote interface
export interface JuryVote {
  juryMember: string;
  vote: DisputeOutcome;
  reasoning: string;
  timestamp: Date;
}

// MissionEscrow smart contract interface
export interface MissionEscrowContract {
  // Mission lifecycle
  createMission(
    consultant: string,
    milestones: {
      title: string;
      amount: bigint;
      dueDate: number;
    }[],
    totalBudget: bigint
  ): Promise<ethers.ContractTransaction>;

  // Milestone management
  submitMilestone(
    missionId: string,
    milestoneIndex: number,
    evidenceUrls: string[]
  ): Promise<ethers.ContractTransaction>;

  approveMilestone(
    missionId: string,
    milestoneIndex: number
  ): Promise<ethers.ContractTransaction>;

  rejectMilestone(
    missionId: string,
    milestoneIndex: number,
    reason: string
  ): Promise<ethers.ContractTransaction>;

  // Change requests
  proposeChange(
    missionId: string,
    description: string,
    budgetAdjustment: bigint
  ): Promise<ethers.ContractTransaction>;

  respondToChange(
    missionId: string,
    changeRequestId: string,
    accept: boolean,
    notes: string
  ): Promise<ethers.ContractTransaction>;

  // Disputes
  openDispute(
    missionId: string,
    subject: string,
    evidenceUrls: string[]
  ): Promise<ethers.ContractTransaction>;

  voteDispute(
    disputeId: string,
    outcome: DisputeOutcome,
    reasoning: string
  ): Promise<ethers.ContractTransaction>;

  resolveDispute(
    disputeId: string
  ): Promise<ethers.ContractTransaction>;

  // Getters
  getMission(missionId: string): Promise<Mission>;
  getMilestone(missionId: string, milestoneIndex: number): Promise<Milestone>;
  getDispute(disputeId: string): Promise<Dispute>;
}

// Helper functions
export function getMissionProgress(mission: Mission): number {
  if (mission.milestones.length === 0) return 0;

  const approvedCount = mission.milestones.filter(
    (m) => m.status === MilestoneStatus.Approved
  ).length;

  return (approvedCount / mission.milestones.length) * 100;
}

export function getMissionBudgetSpent(mission: Mission): bigint {
  return mission.milestones
    .filter((m) => m.status === MilestoneStatus.Approved)
    .reduce((sum, m) => sum + m.amount, 0n);
}

export function isMilestoneOverdue(milestone: Milestone): boolean {
  if (milestone.status === MilestoneStatus.Approved) return false;
  return new Date() > milestone.dueDate;
}

export function getMissionRemainingBudget(mission: Mission): bigint {
  const spent = getMissionBudgetSpent(mission);
  return mission.totalBudget - spent;
}

export function canSubmitNextMilestone(mission: Mission): boolean {
  // Milestones must be completed in order
  const milestones = [...mission.milestones].sort((a, b) => a.order - b.order);

  for (let i = 0; i < milestones.length; i++) {
    if (milestones[i].status === MilestoneStatus.Pending) {
      return i === 0; // Can only submit first pending milestone
    }
    if (milestones[i].status === MilestoneStatus.InProgress) {
      return false; // Wait for in-progress to be reviewed
    }
  }

  return false; // All milestones completed or none pending
}

export function getNextMilestone(mission: Mission): Milestone | null {
  const sorted = [...mission.milestones].sort((a, b) => a.order - b.order);
  return sorted.find((m) => m.status === MilestoneStatus.Pending) || null;
}

export function getMissionStatusColor(status: MissionStatus): string {
  switch (status) {
    case MissionStatus.Draft:
      return 'text-gray-600 bg-gray-100 dark:text-gray-400 dark:bg-gray-700';
    case MissionStatus.Active:
      return 'text-blue-600 bg-blue-100 dark:text-blue-400 dark:bg-blue-900/30';
    case MissionStatus.OnHold:
      return 'text-yellow-600 bg-yellow-100 dark:text-yellow-400 dark:bg-yellow-900/30';
    case MissionStatus.Disputed:
      return 'text-red-600 bg-red-100 dark:text-red-400 dark:bg-red-900/30';
    case MissionStatus.Completed:
      return 'text-green-600 bg-green-100 dark:text-green-400 dark:bg-green-900/30';
    case MissionStatus.Cancelled:
      return 'text-gray-600 bg-gray-100 dark:text-gray-400 dark:bg-gray-700';
    default:
      return 'text-gray-600 bg-gray-100';
  }
}

export function getMilestoneStatusColor(status: MilestoneStatus): string {
  switch (status) {
    case MilestoneStatus.Pending:
      return 'text-gray-600 bg-gray-100 dark:text-gray-400 dark:bg-gray-700';
    case MilestoneStatus.InProgress:
      return 'text-blue-600 bg-blue-100 dark:text-blue-400 dark:bg-blue-900/30';
    case MilestoneStatus.UnderReview:
      return 'text-purple-600 bg-purple-100 dark:text-purple-400 dark:bg-purple-900/30';
    case MilestoneStatus.Approved:
      return 'text-green-600 bg-green-100 dark:text-green-400 dark:bg-green-900/30';
    case MilestoneStatus.Rejected:
      return 'text-red-600 bg-red-100 dark:text-red-400 dark:bg-red-900/30';
    default:
      return 'text-gray-600 bg-gray-100';
  }
}

export function getDisputeStatusColor(status: DisputeStatus): string {
  switch (status) {
    case DisputeStatus.Open:
      return 'text-yellow-600 bg-yellow-100 dark:text-yellow-400 dark:bg-yellow-900/30';
    case DisputeStatus.UnderReview:
      return 'text-blue-600 bg-blue-100 dark:text-blue-400 dark:bg-blue-900/30';
    case DisputeStatus.JurySelected:
      return 'text-purple-600 bg-purple-100 dark:text-purple-400 dark:bg-purple-900/30';
    case DisputeStatus.Deliberating:
      return 'text-purple-600 bg-purple-100 dark:text-purple-400 dark:bg-purple-900/30';
    case DisputeStatus.Resolved:
      return 'text-green-600 bg-green-100 dark:text-green-400 dark:bg-green-900/30';
    case DisputeStatus.Closed:
      return 'text-gray-600 bg-gray-100 dark:text-gray-400 dark:bg-gray-700';
    default:
      return 'text-gray-600 bg-gray-100';
  }
}
