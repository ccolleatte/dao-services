/**
 * Voting Power Calculator Component
 * Interactive calculator for estimating voting power
 */

'use client';

import { useState, useEffect } from 'react';
import { ethers } from 'ethers';
import {
  ProposalTrack,
  VotingPower,
  calculateVotingPower,
  RANK_WEIGHTS,
} from '../../types/governance.js';

interface VotingPowerCalculatorProps {
  currentRank?: number;
  currentTokens?: bigint;
  onCalculate?: (power: VotingPower) => void;
}

export function VotingPowerCalculator({
  currentRank = 0,
  currentTokens = 0n,
  onCalculate,
}: VotingPowerCalculatorProps) {
  const [rank, setRank] = useState(currentRank);
  const [tokensInput, setTokensInput] = useState(
    currentTokens > 0n ? ethers.formatEther(currentTokens) : '100'
  );
  const [selectedTrack, setSelectedTrack] = useState<ProposalTrack>(ProposalTrack.Technical);
  const [votingPower, setVotingPower] = useState<VotingPower | null>(null);
  const [comparison, setComparison] = useState<{
    rank: number;
    power: VotingPower;
  }[]>([]);

  // Calculate voting power
  useEffect(() => {
    try {
      const tokens = ethers.parseEther(tokensInput || '0');
      const power = calculateVotingPower(rank, tokens);

      setVotingPower(power);

      if (onCalculate) {
        onCalculate(power);
      }

      // Generate comparison data (what-if scenarios)
      const comparisonData = [0, 1, 2, 3, 4].map((r) => ({
        rank: r,
        power: calculateVotingPower(r, tokens),
      }));

      setComparison(comparisonData);
    } catch (error) {
      console.error('Error calculating voting power:', error);
      setVotingPower(null);
    }
  }, [rank, tokensInput, onCalculate]);

  const rankLabels: Record<number, string> = {
    0: 'Guest',
    1: 'Member',
    2: 'Senior',
    3: 'Expert',
    4: 'Partner',
  };

  return (
    <div className="bg-white dark:bg-gray-800 rounded-lg border border-gray-200 dark:border-gray-700">
      {/* Header */}
      <div className="p-6 border-b border-gray-200 dark:border-gray-700">
        <h2 className="text-lg font-semibold text-gray-900 dark:text-white">
          Voting Power Calculator
        </h2>
        <p className="text-sm text-gray-600 dark:text-gray-400 mt-1">
          Estimate your influence on proposals
        </p>
      </div>

      {/* Inputs */}
      <div className="p-6 space-y-6">
        {/* Rank Selector */}
        <div>
          <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
            Rank
          </label>
          <div className="grid grid-cols-5 gap-2">
            {[0, 1, 2, 3, 4].map((r) => (
              <button
                key={r}
                onClick={() => setRank(r)}
                className={`px-3 py-2 text-xs font-medium rounded-md transition-colors ${
                  rank === r
                    ? 'bg-blue-600 text-white'
                    : 'bg-gray-100 text-gray-700 hover:bg-gray-200 dark:bg-gray-700 dark:text-gray-300 dark:hover:bg-gray-600'
                }`}
              >
                {r}
              </button>
            ))}
          </div>
          <div className="mt-2 flex items-center justify-between text-xs text-gray-500 dark:text-gray-400">
            <span>{rankLabels[rank]}</span>
            <span>Weight: {RANK_WEIGHTS[rank]}×</span>
          </div>
        </div>

        {/* Tokens Input */}
        <div>
          <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
            DAOS Tokens Held
          </label>
          <div className="relative">
            <input
              type="number"
              value={tokensInput}
              onChange={(e) => setTokensInput(e.target.value)}
              placeholder="100"
              min="0"
              step="10"
              className="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-md shadow-sm focus:outline-none focus:ring-blue-500 focus:border-blue-500 dark:bg-gray-700 dark:text-white text-sm"
            />
            <span className="absolute right-3 top-2 text-sm text-gray-500 dark:text-gray-400">
              DAOS
            </span>
          </div>
        </div>

        {/* Track Selector */}
        <div>
          <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
            Proposal Track
          </label>
          <select
            value={selectedTrack}
            onChange={(e) => setSelectedTrack(Number(e.target.value) as ProposalTrack)}
            className="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-md shadow-sm focus:outline-none focus:ring-blue-500 focus:border-blue-500 dark:bg-gray-700 dark:text-white text-sm"
          >
            <option value={ProposalTrack.Technical}>Technical</option>
            <option value={ProposalTrack.Treasury}>Treasury</option>
            <option value={ProposalTrack.Membership}>Membership</option>
          </select>
        </div>
      </div>

      {/* Results */}
      {votingPower && (
        <>
          <div className="p-6 border-t border-gray-200 dark:border-gray-700 bg-blue-50 dark:bg-blue-900/20">
            <div className="grid grid-cols-2 gap-4">
              <div>
                <p className="text-sm text-gray-600 dark:text-gray-400">Vote Weight</p>
                <p className="text-2xl font-bold text-gray-900 dark:text-white">
                  {votingPower.voteWeight.toFixed(2)}
                </p>
              </div>
              <div>
                <p className="text-sm text-gray-600 dark:text-gray-400">Influence</p>
                <p className="text-2xl font-bold text-blue-600 dark:text-blue-400">
                  {votingPower.percentage.toFixed(3)}%
                </p>
              </div>
            </div>
          </div>

          {/* Projection */}
          <div className="p-6 border-t border-gray-200 dark:border-gray-700">
            <h3 className="text-sm font-semibold text-gray-900 dark:text-white mb-3">
              What-If Scenarios
            </h3>
            <p className="text-xs text-gray-600 dark:text-gray-400 mb-4">
              How your voting power changes with different ranks
            </p>

            <div className="space-y-2">
              {comparison.map((item) => {
                const isCurrentRank = item.rank === rank;
                const increase = item.power.voteWeight - votingPower.voteWeight;
                const increasePercentage = votingPower.voteWeight > 0
                  ? (increase / votingPower.voteWeight) * 100
                  : 0;

                return (
                  <div
                    key={item.rank}
                    className={`p-3 rounded-md ${
                      isCurrentRank
                        ? 'bg-blue-50 dark:bg-blue-900/20 border border-blue-200 dark:border-blue-800'
                        : 'bg-gray-50 dark:bg-gray-900/50'
                    }`}
                  >
                    <div className="flex items-center justify-between">
                      <div>
                        <p className="text-sm font-medium text-gray-900 dark:text-white">
                          Rank {item.rank} ({rankLabels[item.rank]})
                        </p>
                        <p className="text-xs text-gray-600 dark:text-gray-400">
                          Weight: {item.power.voteWeight.toFixed(2)}
                        </p>
                      </div>

                      {!isCurrentRank && increase !== 0 && (
                        <div className="text-right">
                          <span
                            className={`text-sm font-medium ${
                              increase > 0
                                ? 'text-green-600 dark:text-green-400'
                                : 'text-red-600 dark:text-red-400'
                            }`}
                          >
                            {increase > 0 ? '+' : ''}
                            {increasePercentage.toFixed(1)}%
                          </span>
                        </div>
                      )}

                      {isCurrentRank && (
                        <span className="text-xs font-medium text-blue-600 dark:text-blue-400">
                          Current
                        </span>
                      )}
                    </div>
                  </div>
                );
              })}
            </div>
          </div>

          {/* Top Voters Comparison */}
          <div className="p-6 border-t border-gray-200 dark:border-gray-700">
            <h3 className="text-sm font-semibold text-gray-900 dark:text-white mb-3">
              DAO Voting Power Distribution
            </h3>
            <p className="text-xs text-gray-600 dark:text-gray-400 mb-4">
              Estimated distribution across the DAO
            </p>

            <div className="space-y-2">
              {[
                { label: 'Top 10 Voters', percentage: 35, color: 'bg-purple-500' },
                { label: 'Rank 4 (Partners)', percentage: 25, color: 'bg-blue-500' },
                { label: 'Rank 3 (Experts)', percentage: 20, color: 'bg-green-500' },
                { label: 'Rank 2 (Seniors)', percentage: 15, color: 'bg-yellow-500' },
                { label: 'Rank 0-1', percentage: 5, color: 'bg-gray-400' },
              ].map((item) => (
                <div key={item.label}>
                  <div className="flex justify-between text-xs mb-1">
                    <span className="text-gray-700 dark:text-gray-300">{item.label}</span>
                    <span className="font-medium text-gray-900 dark:text-white">
                      ~{item.percentage}%
                    </span>
                  </div>
                  <div className="w-full bg-gray-200 dark:bg-gray-700 rounded-full h-2">
                    <div
                      className={`${item.color} h-2 rounded-full transition-all`}
                      style={{ width: `${item.percentage}%` }}
                    />
                  </div>
                </div>
              ))}
            </div>
          </div>
        </>
      )}
    </div>
  );
}
