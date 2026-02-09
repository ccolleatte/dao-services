/**
 * Proposal Detail View Component
 * Full proposal details with voting interface
 */

'use client';

import { useState, useEffect } from 'react';
import { ethers } from 'ethers';
import {
  Proposal,
  VoteType,
  VoteReceipt,
  formatProposalStatus,
  getQuorumProgress,
  getVoteBreakdown,
  ProposalStatus,
} from '../../types/governance.js';
import { GovernanceService } from '../../services/governanceService.js';
import { formatDistanceToNow } from 'date-fns';

interface ProposalDetailViewProps {
  proposal: Proposal;
  userAddress?: string;
  governanceService: GovernanceService | null;
  onVote: (proposalId: string, support: VoteType, reason?: string) => Promise<void>;
}

export function ProposalDetailView({
  proposal,
  userAddress,
  governanceService,
  onVote,
}: ProposalDetailViewProps) {
  const [userVote, setUserVote] = useState<VoteReceipt | null>(null);
  const [voting, setVoting] = useState(false);
  const [reason, setReason] = useState('');
  const [showImpact, setShowImpact] = useState(false);

  const quorumProgress = getQuorumProgress(proposal);
  const { forPercentage, againstPercentage, abstainPercentage } = getVoteBreakdown(proposal);

  // Fetch user's vote
  useEffect(() => {
    if (!governanceService || !userAddress) return;

    const fetchUserVote = async () => {
      const receipt = await governanceService.getUserVote(proposal.id, userAddress);
      setUserVote(receipt);
    };

    fetchUserVote();
  }, [governanceService, proposal.id, userAddress]);

  const handleVote = async (support: VoteType) => {
    if (!userAddress) {
      alert('Please connect your wallet to vote');
      return;
    }

    setVoting(true);
    try {
      await onVote(proposal.id, support, reason || undefined);
      setReason('');
    } finally {
      setVoting(false);
    }
  };

  const canVote =
    userAddress && proposal.status === ProposalStatus.Active && !userVote?.hasVoted;

  const timeRemaining = proposal.voteEnd
    ? formatDistanceToNow(new Date(proposal.voteEnd * 1000), { addSuffix: true })
    : null;

  return (
    <div className="bg-white dark:bg-gray-800 rounded-lg border border-gray-200 dark:border-gray-700 overflow-hidden">
      {/* Header */}
      <div className="p-6 border-b border-gray-200 dark:border-gray-700">
        <h2 className="text-xl font-bold text-gray-900 dark:text-white mb-2">
          {proposal.title}
        </h2>
        <div className="flex items-center space-x-4 text-sm text-gray-600 dark:text-gray-400">
          <span className="font-medium">{formatProposalStatus(proposal.status)}</span>
          {timeRemaining && <span>•</span>}
          {timeRemaining && <span>Ends {timeRemaining}</span>}
        </div>
      </div>

      {/* Description */}
      <div className="p-6 border-b border-gray-200 dark:border-gray-700">
        <p className="text-sm text-gray-700 dark:text-gray-300 whitespace-pre-wrap">
          {proposal.description}
        </p>
      </div>

      {/* Impact Preview */}
      {showImpact && (
        <div className="p-6 border-b border-gray-200 dark:border-gray-700 bg-blue-50 dark:bg-blue-900/20">
          <h3 className="text-sm font-semibold text-gray-900 dark:text-white mb-3">
            Impact Preview
          </h3>
          <div className="space-y-3">
            <div className="bg-white dark:bg-gray-800 rounded-md p-3">
              <div className="flex items-start space-x-3">
                <div className="flex-shrink-0">
                  <span className="text-green-500">✓</span>
                </div>
                <div className="flex-1 text-sm">
                  <p className="font-medium text-gray-900 dark:text-white">
                    If YES (Proposal Passes)
                  </p>
                  <p className="text-gray-600 dark:text-gray-400 mt-1">
                    The proposed changes will be queued for execution after a 1-day timelock
                    period. This may include parameter updates, contract upgrades, or treasury
                    operations.
                  </p>
                </div>
              </div>
            </div>

            <div className="bg-white dark:bg-gray-800 rounded-md p-3">
              <div className="flex items-start space-x-3">
                <div className="flex-shrink-0">
                  <span className="text-red-500">✗</span>
                </div>
                <div className="flex-1 text-sm">
                  <p className="font-medium text-gray-900 dark:text-white">
                    If NO (Proposal Fails)
                  </p>
                  <p className="text-gray-600 dark:text-gray-400 mt-1">
                    The proposal will be marked as defeated and no changes will be made. The
                    current system parameters will remain in effect.
                  </p>
                </div>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* Vote Breakdown */}
      <div className="p-6 border-b border-gray-200 dark:border-gray-700">
        <h3 className="text-sm font-semibold text-gray-900 dark:text-white mb-4">
          Current Results
        </h3>

        <div className="space-y-3">
          {/* For */}
          <div>
            <div className="flex justify-between text-sm mb-1">
              <span className="text-gray-700 dark:text-gray-300">For</span>
              <span className="font-medium text-green-600 dark:text-green-400">
                {forPercentage.toFixed(1)}% ({ethers.formatEther(proposal.forVotes)})
              </span>
            </div>
            <div className="w-full bg-gray-200 dark:bg-gray-700 rounded-full h-2">
              <div
                className="bg-green-500 h-2 rounded-full transition-all"
                style={{ width: `${forPercentage}%` }}
              />
            </div>
          </div>

          {/* Against */}
          <div>
            <div className="flex justify-between text-sm mb-1">
              <span className="text-gray-700 dark:text-gray-300">Against</span>
              <span className="font-medium text-red-600 dark:text-red-400">
                {againstPercentage.toFixed(1)}% ({ethers.formatEther(proposal.againstVotes)})
              </span>
            </div>
            <div className="w-full bg-gray-200 dark:bg-gray-700 rounded-full h-2">
              <div
                className="bg-red-500 h-2 rounded-full transition-all"
                style={{ width: `${againstPercentage}%` }}
              />
            </div>
          </div>

          {/* Abstain */}
          <div>
            <div className="flex justify-between text-sm mb-1">
              <span className="text-gray-700 dark:text-gray-300">Abstain</span>
              <span className="font-medium text-gray-600 dark:text-gray-400">
                {abstainPercentage.toFixed(1)}% ({ethers.formatEther(proposal.abstainVotes)})
              </span>
            </div>
            <div className="w-full bg-gray-200 dark:bg-gray-700 rounded-full h-2">
              <div
                className="bg-gray-400 h-2 rounded-full transition-all"
                style={{ width: `${abstainPercentage}%` }}
              />
            </div>
          </div>
        </div>

        {/* Quorum */}
        <div className="mt-4 pt-4 border-t border-gray-200 dark:border-gray-700">
          <div className="flex justify-between text-sm mb-2">
            <span className="text-gray-700 dark:text-gray-300">Quorum Progress</span>
            <span
              className={`font-medium ${
                quorumProgress >= 100 ? 'text-green-600 dark:text-green-400' : 'text-blue-600 dark:text-blue-400'
              }`}
            >
              {Math.min(quorumProgress, 100).toFixed(1)}%
            </span>
          </div>
          <div className="w-full bg-gray-200 dark:bg-gray-700 rounded-full h-2">
            <div
              className={`h-2 rounded-full transition-all ${
                quorumProgress >= 100 ? 'bg-green-500' : 'bg-blue-500'
              }`}
              style={{ width: `${Math.min(quorumProgress, 100)}%` }}
            />
          </div>
          <p className="text-xs text-gray-500 dark:text-gray-400 mt-1">
            {ethers.formatEther(proposal.quorum)} votes required
          </p>
        </div>
      </div>

      {/* Voting Interface */}
      {canVote ? (
        <div className="p-6">
          <h3 className="text-sm font-semibold text-gray-900 dark:text-white mb-4">
            Cast Your Vote
          </h3>

          {/* Reason (optional) */}
          <div className="mb-4">
            <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
              Reason (optional)
            </label>
            <textarea
              value={reason}
              onChange={(e) => setReason(e.target.value)}
              placeholder="Explain your vote..."
              rows={3}
              className="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-md shadow-sm focus:outline-none focus:ring-blue-500 focus:border-blue-500 dark:bg-gray-700 dark:text-white text-sm"
            />
          </div>

          {/* Vote Buttons */}
          <div className="grid grid-cols-3 gap-3">
            <button
              onClick={() => handleVote(VoteType.For)}
              disabled={voting}
              className="px-4 py-2 bg-green-600 text-white rounded-md hover:bg-green-700 disabled:opacity-50 disabled:cursor-not-allowed font-medium text-sm transition-colors"
            >
              {voting ? 'Voting...' : 'For'}
            </button>
            <button
              onClick={() => handleVote(VoteType.Against)}
              disabled={voting}
              className="px-4 py-2 bg-red-600 text-white rounded-md hover:bg-red-700 disabled:opacity-50 disabled:cursor-not-allowed font-medium text-sm transition-colors"
            >
              {voting ? 'Voting...' : 'Against'}
            </button>
            <button
              onClick={() => handleVote(VoteType.Abstain)}
              disabled={voting}
              className="px-4 py-2 bg-gray-600 text-white rounded-md hover:bg-gray-700 disabled:opacity-50 disabled:cursor-not-allowed font-medium text-sm transition-colors"
            >
              {voting ? 'Voting...' : 'Abstain'}
            </button>
          </div>

          <button
            onClick={() => setShowImpact(!showImpact)}
            className="w-full mt-3 text-sm text-blue-600 dark:text-blue-400 hover:underline"
          >
            {showImpact ? 'Hide' : 'Show'} Impact Preview
          </button>
        </div>
      ) : userVote?.hasVoted ? (
        <div className="p-6 bg-gray-50 dark:bg-gray-900/50">
          <div className="flex items-center space-x-2 text-sm text-gray-700 dark:text-gray-300">
            <svg
              className="w-5 h-5 text-green-500"
              fill="currentColor"
              viewBox="0 0 20 20"
            >
              <path
                fillRule="evenodd"
                d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z"
                clipRule="evenodd"
              />
            </svg>
            <span className="font-medium">
              You voted: {userVote.support === VoteType.For ? 'For' : userVote.support === VoteType.Against ? 'Against' : 'Abstain'}
            </span>
          </div>
          <p className="text-xs text-gray-500 dark:text-gray-400 mt-1">
            Vote weight: {ethers.formatEther(userVote.votes)}
          </p>
        </div>
      ) : (
        <div className="p-6 bg-gray-50 dark:bg-gray-900/50">
          <p className="text-sm text-gray-600 dark:text-gray-400">
            {!userAddress
              ? 'Connect your wallet to vote'
              : 'Voting is closed for this proposal'}
          </p>
        </div>
      )}
    </div>
  );
}
