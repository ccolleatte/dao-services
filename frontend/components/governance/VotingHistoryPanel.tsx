/**
 * Voting History Panel Component
 * Displays user's past voting activity
 */

'use client';

import { useState, useEffect } from 'react';
import { ethers } from 'ethers';
import {
  Proposal,
  VoteType,
  VoteReceipt,
  formatProposalStatus,
  formatVoteType,
} from '../../types/governance.js';
import { GovernanceService } from '../../services/governanceService.js';
import { formatDistanceToNow } from 'date-fns';

interface VotingHistoryPanelProps {
  userAddress?: string;
  governanceService: GovernanceService | null;
}

interface VoteHistory {
  proposal: Proposal;
  vote: VoteReceipt;
  timestamp: number;
}

export function VotingHistoryPanel({
  userAddress,
  governanceService,
}: VotingHistoryPanelProps) {
  const [history, setHistory] = useState<VoteHistory[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    if (!governanceService || !userAddress) {
      setLoading(false);
      return;
    }

    const fetchHistory = async () => {
      setLoading(true);
      try {
        // In production, fetch from events or subgraph
        // For now, mock data
        setHistory([]);
      } catch (error) {
        console.error('Error fetching voting history:', error);
      } finally {
        setLoading(false);
      }
    };

    fetchHistory();
  }, [governanceService, userAddress]);

  if (!userAddress) {
    return (
      <div className="bg-white dark:bg-gray-800 rounded-lg border border-gray-200 dark:border-gray-700 p-6">
        <p className="text-sm text-gray-600 dark:text-gray-400">
          Connect your wallet to view voting history
        </p>
      </div>
    );
  }

  if (loading) {
    return (
      <div className="bg-white dark:bg-gray-800 rounded-lg border border-gray-200 dark:border-gray-700 p-6">
        <div className="animate-pulse space-y-4">
          <div className="h-4 bg-gray-200 dark:bg-gray-700 rounded w-3/4"></div>
          <div className="h-4 bg-gray-200 dark:bg-gray-700 rounded w-1/2"></div>
        </div>
      </div>
    );
  }

  return (
    <div className="bg-white dark:bg-gray-800 rounded-lg border border-gray-200 dark:border-gray-700">
      {/* Header */}
      <div className="p-6 border-b border-gray-200 dark:border-gray-700">
        <h2 className="text-lg font-semibold text-gray-900 dark:text-white">
          My Voting History
        </h2>
        <p className="text-sm text-gray-600 dark:text-gray-400 mt-1">
          Last 20 votes
        </p>
      </div>

      {/* History List */}
      <div className="divide-y divide-gray-200 dark:divide-gray-700">
        {history.length === 0 ? (
          <div className="p-6 text-center">
            <svg
              className="mx-auto h-12 w-12 text-gray-400"
              fill="none"
              viewBox="0 0 24 24"
              stroke="currentColor"
            >
              <path
                strokeLinecap="round"
                strokeLinejoin="round"
                strokeWidth={2}
                d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2"
              />
            </svg>
            <p className="mt-2 text-sm text-gray-600 dark:text-gray-400">
              No voting history yet
            </p>
          </div>
        ) : (
          history.map((item, index) => (
            <div key={index} className="p-4">
              <div className="flex items-start justify-between">
                <div className="flex-1">
                  <p className="text-sm font-medium text-gray-900 dark:text-white">
                    {item.proposal.title}
                  </p>
                  <div className="mt-1 flex items-center space-x-2 text-xs text-gray-500 dark:text-gray-400">
                    <span
                      className={`px-2 py-1 rounded ${
                        item.vote.support === VoteType.For
                          ? 'bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-300'
                          : item.vote.support === VoteType.Against
                          ? 'bg-red-100 text-red-800 dark:bg-red-900 dark:text-red-300'
                          : 'bg-gray-100 text-gray-800 dark:bg-gray-700 dark:text-gray-300'
                      }`}
                    >
                      {formatVoteType(item.vote.support)}
                    </span>
                    <span>•</span>
                    <span>{ethers.formatEther(item.vote.votes)} votes</span>
                  </div>
                </div>

                <div className="ml-4 flex-shrink-0">
                  <span className="text-xs text-gray-500 dark:text-gray-400">
                    {formatDistanceToNow(new Date(item.timestamp * 1000), { addSuffix: true })}
                  </span>
                </div>
              </div>

              {/* Proposal Status */}
              <div className="mt-2">
                <span className="text-xs text-gray-600 dark:text-gray-400">
                  Result: {formatProposalStatus(item.proposal.status)}
                </span>
              </div>
            </div>
          ))
        )}
      </div>

      {/* Stats */}
      <div className="p-6 bg-gray-50 dark:bg-gray-900/50 border-t border-gray-200 dark:border-gray-700">
        <div className="grid grid-cols-3 gap-4 text-center">
          <div>
            <p className="text-2xl font-bold text-gray-900 dark:text-white">
              {history.length}
            </p>
            <p className="text-xs text-gray-600 dark:text-gray-400">Total Votes</p>
          </div>
          <div>
            <p className="text-2xl font-bold text-green-600 dark:text-green-400">
              {history.filter((h) => h.vote.support === VoteType.For).length}
            </p>
            <p className="text-xs text-gray-600 dark:text-gray-400">For</p>
          </div>
          <div>
            <p className="text-2xl font-bold text-red-600 dark:text-red-400">
              {history.filter((h) => h.vote.support === VoteType.Against).length}
            </p>
            <p className="text-xs text-gray-600 dark:text-gray-400">Against</p>
          </div>
        </div>
      </div>
    </div>
  );
}
