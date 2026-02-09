/**
 * Governance Voting UI
 * Main component for DAO governance voting interface
 */

'use client';

import { useState, useEffect } from 'react';
import { useAccount } from 'wagmi';
import { ethers } from 'ethers';
import {
  Proposal,
  ProposalTrack,
  ProposalStatus,
  VoteType,
  VoteReceipt,
  formatProposalStatus,
  getProposalStatusColor,
  getQuorumProgress,
  getVoteBreakdown,
} from '../../types/governance.js';
import { GovernanceService } from '../../services/governanceService.js';
import { ProposalCard } from './ProposalCard.js';
import { ProposalDetailView } from './ProposalDetailView.js';
import { VotingHistoryPanel } from './VotingHistoryPanel.js';

interface GovernanceVotingUIProps {
  contractAddress: string;
  provider: ethers.Provider;
  signer?: ethers.Signer;
}

export function GovernanceVotingUI({
  contractAddress,
  provider,
  signer,
}: GovernanceVotingUIProps) {
  const { address: userAddress } = useAccount();
  const [activeTrack, setActiveTrack] = useState<ProposalTrack>(ProposalTrack.Technical);
  const [proposals, setProposals] = useState<Proposal[]>([]);
  const [selectedProposal, setSelectedProposal] = useState<Proposal | null>(null);
  const [loading, setLoading] = useState(true);
  const [showHistory, setShowHistory] = useState(false);
  const [governanceService, setGovernanceService] = useState<GovernanceService | null>(null);

  // Initialize governance service
  useEffect(() => {
    const service = new GovernanceService(contractAddress, provider, signer);
    setGovernanceService(service);

    return () => {
      service.removeAllListeners();
    };
  }, [contractAddress, provider, signer]);

  // Fetch proposals for active track
  useEffect(() => {
    if (!governanceService) return;

    const fetchProposals = async () => {
      setLoading(true);
      try {
        const trackProposals = await governanceService.fetchProposalsByTrack(activeTrack);
        setProposals(trackProposals);
      } catch (error) {
        console.error('Error fetching proposals:', error);
      } finally {
        setLoading(false);
      }
    };

    fetchProposals();
  }, [activeTrack, governanceService]);

  // Subscribe to vote events
  useEffect(() => {
    if (!governanceService) return;

    governanceService.onVoteCast((voter, proposalId, support, weight) => {
      console.log('Vote cast:', { voter, proposalId, support, weight });
      // Refresh proposals to update vote counts
      setProposals((prev) =>
        prev.map((p) => {
          if (p.id === proposalId) {
            // Update vote counts (simplified)
            return { ...p };
          }
          return p;
        })
      );
    });
  }, [governanceService]);

  const handleVote = async (proposalId: string, support: VoteType, reason?: string) => {
    if (!governanceService || !signer) {
      alert('Please connect your wallet to vote');
      return;
    }

    try {
      const tx = await governanceService.castVote(proposalId, support, reason);
      await tx.wait();
      alert('Vote cast successfully!');

      // Refresh proposal
      const updated = await governanceService.fetchProposalById(proposalId);
      if (updated) {
        setProposals((prev) => prev.map((p) => (p.id === proposalId ? updated : p)));
        setSelectedProposal(updated);
      }
    } catch (error: any) {
      console.error('Error casting vote:', error);
      alert(`Failed to cast vote: ${error.message}`);
    }
  };

  const activeProposals = proposals.filter((p) => p.status === ProposalStatus.Active);
  const pendingProposals = proposals.filter((p) => p.status === ProposalStatus.Pending);
  const completedProposals = proposals.filter(
    (p) =>
      p.status === ProposalStatus.Succeeded ||
      p.status === ProposalStatus.Defeated ||
      p.status === ProposalStatus.Executed
  );

  return (
    <div className="governance-voting-ui min-h-screen bg-gray-50 dark:bg-gray-900">
      {/* Header */}
      <header className="bg-white dark:bg-gray-800 border-b border-gray-200 dark:border-gray-700">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-6">
          <h1 className="text-3xl font-bold text-gray-900 dark:text-white">
            DAO Governance
          </h1>
          <p className="mt-2 text-sm text-gray-600 dark:text-gray-400">
            Vote on proposals and shape the future of the DAO
          </p>

          {/* Track Tabs */}
          <div className="mt-6 flex space-x-4 border-b border-gray-200 dark:border-gray-700">
            {[
              { track: ProposalTrack.Technical, label: 'Technical' },
              { track: ProposalTrack.Treasury, label: 'Treasury' },
              { track: ProposalTrack.Membership, label: 'Membership' },
            ].map(({ track, label }) => (
              <button
                key={track}
                onClick={() => {
                  setActiveTrack(track);
                  setSelectedProposal(null);
                }}
                className={`px-4 py-2 text-sm font-medium border-b-2 transition-colors ${
                  activeTrack === track
                    ? 'border-blue-500 text-blue-600 dark:text-blue-400'
                    : 'border-transparent text-gray-500 hover:text-gray-700 dark:text-gray-400 dark:hover:text-gray-300'
                }`}
              >
                {label}
              </button>
            ))}

            <div className="flex-1" />

            <button
              onClick={() => setShowHistory(!showHistory)}
              className="px-4 py-2 text-sm font-medium text-gray-700 dark:text-gray-300 hover:bg-gray-100 dark:hover:bg-gray-700 rounded-md"
            >
              {showHistory ? 'Hide History' : 'My Voting History'}
            </button>
          </div>
        </div>
      </header>

      {/* Main Content */}
      <main className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
          {/* Proposals List */}
          <div className="lg:col-span-2">
            {loading ? (
              <div className="text-center py-12">
                <div className="inline-block animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600"></div>
                <p className="mt-4 text-sm text-gray-600 dark:text-gray-400">
                  Loading proposals...
                </p>
              </div>
            ) : (
              <>
                {/* Active Proposals */}
                {activeProposals.length > 0 && (
                  <section className="mb-8">
                    <h2 className="text-xl font-semibold text-gray-900 dark:text-white mb-4">
                      Active Proposals ({activeProposals.length})
                    </h2>
                    <div className="space-y-4">
                      {activeProposals.map((proposal) => (
                        <ProposalCard
                          key={proposal.id}
                          proposal={proposal}
                          onClick={() => setSelectedProposal(proposal)}
                          isSelected={selectedProposal?.id === proposal.id}
                        />
                      ))}
                    </div>
                  </section>
                )}

                {/* Pending Proposals */}
                {pendingProposals.length > 0 && (
                  <section className="mb-8">
                    <h2 className="text-xl font-semibold text-gray-900 dark:text-white mb-4">
                      Pending Proposals ({pendingProposals.length})
                    </h2>
                    <div className="space-y-4">
                      {pendingProposals.map((proposal) => (
                        <ProposalCard
                          key={proposal.id}
                          proposal={proposal}
                          onClick={() => setSelectedProposal(proposal)}
                          isSelected={selectedProposal?.id === proposal.id}
                        />
                      ))}
                    </div>
                  </section>
                )}

                {/* Completed Proposals */}
                {completedProposals.length > 0 && (
                  <section>
                    <h2 className="text-xl font-semibold text-gray-900 dark:text-white mb-4">
                      Completed Proposals ({completedProposals.length})
                    </h2>
                    <div className="space-y-4">
                      {completedProposals.map((proposal) => (
                        <ProposalCard
                          key={proposal.id}
                          proposal={proposal}
                          onClick={() => setSelectedProposal(proposal)}
                          isSelected={selectedProposal?.id === proposal.id}
                        />
                      ))}
                    </div>
                  </section>
                )}

                {/* Empty State */}
                {proposals.length === 0 && (
                  <div className="text-center py-12 bg-white dark:bg-gray-800 rounded-lg border border-gray-200 dark:border-gray-700">
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
                        d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"
                      />
                    </svg>
                    <h3 className="mt-2 text-sm font-medium text-gray-900 dark:text-white">
                      No proposals
                    </h3>
                    <p className="mt-1 text-sm text-gray-500 dark:text-gray-400">
                      No proposals found for this track.
                    </p>
                  </div>
                )}
              </>
            )}
          </div>

          {/* Sidebar */}
          <div className="lg:col-span-1">
            {showHistory ? (
              <VotingHistoryPanel
                userAddress={userAddress}
                governanceService={governanceService}
              />
            ) : selectedProposal ? (
              <ProposalDetailView
                proposal={selectedProposal}
                userAddress={userAddress}
                governanceService={governanceService}
                onVote={handleVote}
              />
            ) : (
              <div className="bg-white dark:bg-gray-800 rounded-lg border border-gray-200 dark:border-gray-700 p-6">
                <p className="text-sm text-gray-600 dark:text-gray-400">
                  Select a proposal to view details and vote
                </p>
              </div>
            )}
          </div>
        </div>
      </main>
    </div>
  );
}
