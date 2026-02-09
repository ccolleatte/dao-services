/**
 * Proposal Card Component
 * Displays proposal summary in list view
 */

'use client';

import {
  Proposal,
  formatProposalStatus,
  getProposalStatusColor,
  getQuorumProgress,
  getVoteBreakdown,
} from '../../types/governance.js';
import { formatDistanceToNow } from 'date-fns';
import { ethers } from 'ethers';

interface ProposalCardProps {
  proposal: Proposal;
  onClick: () => void;
  isSelected: boolean;
}

export function ProposalCard({ proposal, onClick, isSelected }: ProposalCardProps) {
  const statusColor = getProposalStatusColor(proposal.status);
  const quorumProgress = getQuorumProgress(proposal);
  const { forPercentage, againstPercentage } = getVoteBreakdown(proposal);

  const statusColors = {
    gray: 'bg-gray-100 text-gray-800 dark:bg-gray-700 dark:text-gray-300',
    blue: 'bg-blue-100 text-blue-800 dark:bg-blue-900 dark:text-blue-300',
    green: 'bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-300',
    red: 'bg-red-100 text-red-800 dark:bg-red-900 dark:text-red-300',
    purple: 'bg-purple-100 text-purple-800 dark:bg-purple-900 dark:text-purple-300',
  };

  const timeRemaining = proposal.voteEnd
    ? formatDistanceToNow(new Date(proposal.voteEnd * 1000), { addSuffix: true })
    : null;

  return (
    <button
      onClick={onClick}
      className={`w-full text-left bg-white dark:bg-gray-800 rounded-lg border transition-all ${
        isSelected
          ? 'border-blue-500 shadow-lg'
          : 'border-gray-200 dark:border-gray-700 hover:border-gray-300 dark:hover:border-gray-600'
      } p-6`}
    >
      {/* Header */}
      <div className="flex items-start justify-between mb-4">
        <div className="flex-1">
          <h3 className="text-lg font-semibold text-gray-900 dark:text-white mb-2">
            {proposal.title}
          </h3>
          <p className="text-sm text-gray-600 dark:text-gray-400 line-clamp-2">
            {proposal.description}
          </p>
        </div>

        <span
          className={`ml-4 px-3 py-1 text-xs font-medium rounded-full whitespace-nowrap ${
            statusColors[statusColor as keyof typeof statusColors]
          }`}
        >
          {formatProposalStatus(proposal.status)}
        </span>
      </div>

      {/* Vote Breakdown */}
      <div className="mb-4">
        <div className="flex justify-between text-xs text-gray-600 dark:text-gray-400 mb-2">
          <span>
            For: {forPercentage.toFixed(1)}% ({ethers.formatEther(proposal.forVotes)} votes)
          </span>
          <span>
            Against: {againstPercentage.toFixed(1)}% ({ethers.formatEther(proposal.againstVotes)}{' '}
            votes)
          </span>
        </div>

        {/* Progress Bar */}
        <div className="flex h-2 bg-gray-200 dark:bg-gray-700 rounded-full overflow-hidden">
          <div
            className="bg-green-500"
            style={{ width: `${forPercentage}%` }}
            title={`For: ${forPercentage.toFixed(1)}%`}
          />
          <div
            className="bg-red-500"
            style={{ width: `${againstPercentage}%` }}
            title={`Against: ${againstPercentage.toFixed(1)}%`}
          />
        </div>
      </div>

      {/* Quorum Progress */}
      <div className="mb-4">
        <div className="flex justify-between text-xs text-gray-600 dark:text-gray-400 mb-2">
          <span>Quorum Progress</span>
          <span>{Math.min(quorumProgress, 100).toFixed(1)}%</span>
        </div>
        <div className="w-full bg-gray-200 dark:bg-gray-700 rounded-full h-2">
          <div
            className={`h-2 rounded-full transition-all ${
              quorumProgress >= 100 ? 'bg-green-500' : 'bg-blue-500'
            }`}
            style={{ width: `${Math.min(quorumProgress, 100)}%` }}
          />
        </div>
      </div>

      {/* Footer */}
      <div className="flex items-center justify-between text-xs text-gray-500 dark:text-gray-400">
        <span>Proposal #{proposal.id.slice(0, 8)}...</span>
        {timeRemaining && <span>Voting ends {timeRemaining}</span>}
      </div>
    </button>
  );
}
