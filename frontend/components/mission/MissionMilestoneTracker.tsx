/**
 * MissionMilestoneTracker Component
 * Main mission tracking interface with Gantt chart, milestones, and actions
 */

import { useState, useEffect } from 'react';
import { ethers } from 'ethers';
import {
  Mission,
  Milestone,
  MissionStatus,
  MilestoneStatus,
  getMissionProgress,
  getMissionBudgetSpent,
  getMissionRemainingBudget,
  canSubmitNextMilestone,
  getNextMilestone,
  isMilestoneOverdue,
  getMissionStatusColor,
  getMilestoneStatusColor,
} from '@/types/milestone.js';
import { GanttChart } from './GanttChart.js';
import { ChangeRequestForm } from './ChangeRequestForm.js';
import { DisputeModal } from './DisputeModal.js';

export interface MissionMilestoneTrackerProps {
  mission: Mission;
  userAddress: string;
  isConsultant: boolean;
  escrowContract: ethers.Contract;
  onMissionUpdate: (mission: Mission) => void;
}

export function MissionMilestoneTracker({
  mission,
  userAddress,
  isConsultant,
  escrowContract,
  onMissionUpdate,
}: MissionMilestoneTrackerProps) {
  const [view, setView] = useState<'list' | 'gantt'>('list');
  const [showChangeRequest, setShowChangeRequest] = useState(false);
  const [showDispute, setShowDispute] = useState(false);
  const [selectedMilestone, setSelectedMilestone] = useState<Milestone | null>(null);
  const [submittingEvidence, setSubmittingEvidence] = useState(false);
  const [evidenceUrls, setEvidenceUrls] = useState<string[]>([]);

  // Calculate metrics
  const progress = getMissionProgress(mission);
  const budgetSpent = getMissionBudgetSpent(mission);
  const budgetRemaining = getMissionRemainingBudget(mission);
  const nextMilestone = getNextMilestone(mission);
  const canSubmitNext = canSubmitNextMilestone(mission);

  // Format currency
  const formatAmount = (amount: bigint) => {
    return `${(Number(amount) / 1e18).toLocaleString('fr-FR', {
      minimumFractionDigits: 0,
      maximumFractionDigits: 0,
    })} ${mission.currency}`;
  };

  // Submit milestone evidence
  const handleSubmitMilestone = async (milestone: Milestone) => {
    if (evidenceUrls.length === 0) {
      alert('Veuillez ajouter au moins une preuve (IPFS URL)');
      return;
    }

    setSubmittingEvidence(true);
    try {
      const tx = await escrowContract.submitMilestone(
        mission.id,
        milestone.order - 1, // 0-indexed in contract
        evidenceUrls
      );

      await tx.wait();

      // Update mission locally
      const updatedMilestones = mission.milestones.map((m) =>
        m.id === milestone.id
          ? { ...m, status: MilestoneStatus.UnderReview, evidenceUrls }
          : m
      );

      onMissionUpdate({
        ...mission,
        milestones: updatedMilestones,
        updatedAt: new Date(),
      });

      setEvidenceUrls([]);
      setSelectedMilestone(null);
    } catch (error) {
      console.error('Error submitting milestone:', error);
      alert('Erreur lors de la soumission du jalon');
    } finally {
      setSubmittingEvidence(false);
    }
  };

  // Approve milestone (client only)
  const handleApproveMilestone = async (milestone: Milestone) => {
    if (isConsultant) return;

    try {
      const tx = await escrowContract.approveMilestone(
        mission.id,
        milestone.order - 1
      );

      await tx.wait();

      // Update mission locally
      const updatedMilestones = mission.milestones.map((m) =>
        m.id === milestone.id
          ? {
              ...m,
              status: MilestoneStatus.Approved,
              reviewDate: new Date(),
            }
          : m
      );

      onMissionUpdate({
        ...mission,
        milestones: updatedMilestones,
        updatedAt: new Date(),
      });
    } catch (error) {
      console.error('Error approving milestone:', error);
      alert('Erreur lors de l\'approbation du jalon');
    }
  };

  // Reject milestone (client only)
  const handleRejectMilestone = async (milestone: Milestone, reason: string) => {
    if (isConsultant) return;

    try {
      const tx = await escrowContract.rejectMilestone(
        mission.id,
        milestone.order - 1,
        reason
      );

      await tx.wait();

      // Update mission locally
      const updatedMilestones = mission.milestones.map((m) =>
        m.id === milestone.id
          ? {
              ...m,
              status: MilestoneStatus.Rejected,
              reviewDate: new Date(),
              reviewNotes: reason,
            }
          : m
      );

      onMissionUpdate({
        ...mission,
        milestones: updatedMilestones,
        updatedAt: new Date(),
      });
    } catch (error) {
      console.error('Error rejecting milestone:', error);
      alert('Erreur lors du rejet du jalon');
    }
  };

  return (
    <div className="max-w-7xl mx-auto p-6 space-y-6">
      {/* Header */}
      <div className="flex items-start justify-between">
        <div className="flex-1">
          <div className="flex items-center space-x-3">
            <h1 className="text-2xl font-bold text-gray-900 dark:text-white">
              {mission.title}
            </h1>
            <span
              className={`px-3 py-1 rounded-full text-xs font-medium ${getMissionStatusColor(
                mission.status
              )}`}
            >
              {MissionStatus[mission.status]}
            </span>
          </div>
          <p className="text-sm text-gray-600 dark:text-gray-400 mt-2">
            {mission.description}
          </p>
          <div className="flex items-center space-x-4 mt-3 text-sm text-gray-600 dark:text-gray-400">
            <div>
              👨‍💼 Consultant:{' '}
              <span className="font-medium">
                {mission.consultant.slice(0, 6)}...{mission.consultant.slice(-4)}
              </span>
            </div>
            <div>
              👤 Client:{' '}
              <span className="font-medium">
                {mission.client.slice(0, 6)}...{mission.client.slice(-4)}
              </span>
            </div>
          </div>
        </div>

        {/* Action Buttons */}
        <div className="flex items-center space-x-2">
          <button
            onClick={() => setShowChangeRequest(true)}
            className="px-4 py-2 text-sm bg-yellow-600 text-white rounded-md hover:bg-yellow-700 font-medium transition-colors"
          >
            Demande de changement
          </button>
          <button
            onClick={() => setShowDispute(true)}
            className="px-4 py-2 text-sm bg-red-600 text-white rounded-md hover:bg-red-700 font-medium transition-colors"
          >
            Ouvrir litige
          </button>
        </div>
      </div>

      {/* Progress Overview */}
      <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
        {/* Progress */}
        <div className="bg-white dark:bg-gray-800 rounded-lg border border-gray-200 dark:border-gray-700 p-4">
          <div className="text-sm text-gray-600 dark:text-gray-400 mb-2">
            Progression
          </div>
          <div className="flex items-end space-x-2">
            <div className="text-3xl font-bold text-blue-600 dark:text-blue-400">
              {progress.toFixed(0)}%
            </div>
            <div className="text-sm text-gray-600 dark:text-gray-400 mb-1">
              {mission.milestones.filter((m) => m.status === MilestoneStatus.Approved).length}/
              {mission.milestones.length} jalons
            </div>
          </div>
          <div className="mt-2 w-full bg-gray-200 dark:bg-gray-700 rounded-full h-2">
            <div
              className="bg-blue-600 dark:bg-blue-400 h-2 rounded-full transition-all"
              style={{ width: `${progress}%` }}
            />
          </div>
        </div>

        {/* Budget Spent */}
        <div className="bg-white dark:bg-gray-800 rounded-lg border border-gray-200 dark:border-gray-700 p-4">
          <div className="text-sm text-gray-600 dark:text-gray-400 mb-2">
            Budget dépensé
          </div>
          <div className="text-2xl font-bold text-green-600 dark:text-green-400">
            {formatAmount(budgetSpent)}
          </div>
          <div className="text-xs text-gray-600 dark:text-gray-400 mt-1">
            sur {formatAmount(mission.totalBudget)}
          </div>
        </div>

        {/* Budget Remaining */}
        <div className="bg-white dark:bg-gray-800 rounded-lg border border-gray-200 dark:border-gray-700 p-4">
          <div className="text-sm text-gray-600 dark:text-gray-400 mb-2">
            Budget restant
          </div>
          <div className="text-2xl font-bold text-gray-900 dark:text-white">
            {formatAmount(budgetRemaining)}
          </div>
          <div className="text-xs text-gray-600 dark:text-gray-400 mt-1">
            {((Number(budgetRemaining) / Number(mission.totalBudget)) * 100).toFixed(0)}% du total
          </div>
        </div>

        {/* Timeline */}
        <div className="bg-white dark:bg-gray-800 rounded-lg border border-gray-200 dark:border-gray-700 p-4">
          <div className="text-sm text-gray-600 dark:text-gray-400 mb-2">
            Échéance
          </div>
          <div className="text-lg font-bold text-gray-900 dark:text-white">
            {mission.endDate.toLocaleDateString('fr-FR', {
              day: 'numeric',
              month: 'short',
              year: 'numeric',
            })}
          </div>
          <div className="text-xs text-gray-600 dark:text-gray-400 mt-1">
            {Math.ceil((mission.endDate.getTime() - Date.now()) / (1000 * 60 * 60 * 24))} jours restants
          </div>
        </div>
      </div>

      {/* View Toggle */}
      <div className="flex items-center justify-between bg-white dark:bg-gray-800 rounded-lg border border-gray-200 dark:border-gray-700 p-4">
        <div className="text-sm font-medium text-gray-900 dark:text-white">
          Mode d'affichage
        </div>
        <div className="flex space-x-2">
          <button
            onClick={() => setView('list')}
            className={`px-4 py-2 rounded-md font-medium transition-colors ${
              view === 'list'
                ? 'bg-blue-600 text-white'
                : 'bg-gray-100 dark:bg-gray-700 text-gray-700 dark:text-gray-300 hover:bg-gray-200 dark:hover:bg-gray-600'
            }`}
          >
            Liste
          </button>
          <button
            onClick={() => setView('gantt')}
            className={`px-4 py-2 rounded-md font-medium transition-colors ${
              view === 'gantt'
                ? 'bg-blue-600 text-white'
                : 'bg-gray-100 dark:bg-gray-700 text-gray-700 dark:text-gray-300 hover:bg-gray-200 dark:hover:bg-gray-600'
            }`}
          >
            Gantt
          </button>
        </div>
      </div>

      {/* Gantt View */}
      {view === 'gantt' && (
        <GanttChart
          milestones={mission.milestones}
          startDate={mission.startDate}
          endDate={mission.endDate}
        />
      )}

      {/* List View */}
      {view === 'list' && (
        <div className="space-y-4">
          {mission.milestones
            .sort((a, b) => a.order - b.order)
            .map((milestone) => {
              const isOverdue = isMilestoneOverdue(milestone);
              const isNext = nextMilestone?.id === milestone.id;

              return (
                <div
                  key={milestone.id}
                  className={`bg-white dark:bg-gray-800 rounded-lg border-2 p-6 transition-all ${
                    isNext
                      ? 'border-blue-500 shadow-lg'
                      : 'border-gray-200 dark:border-gray-700'
                  }`}
                >
                  <div className="flex items-start justify-between">
                    {/* Milestone Info */}
                    <div className="flex-1">
                      <div className="flex items-center space-x-3">
                        <span className="text-sm font-medium text-gray-500 dark:text-gray-400">
                          #{milestone.order}
                        </span>
                        <h3 className="text-lg font-semibold text-gray-900 dark:text-white">
                          {milestone.title}
                        </h3>
                        <span
                          className={`px-2 py-1 rounded-full text-xs font-medium ${getMilestoneStatusColor(
                            milestone.status
                          )}`}
                        >
                          {MilestoneStatus[milestone.status]}
                        </span>
                        {isNext && (
                          <span className="px-2 py-1 bg-blue-100 dark:bg-blue-900/30 text-blue-600 dark:text-blue-400 rounded-full text-xs font-medium">
                            Prochain
                          </span>
                        )}
                        {isOverdue && (
                          <span className="px-2 py-1 bg-red-100 dark:bg-red-900/30 text-red-600 dark:text-red-400 rounded-full text-xs font-medium">
                            En retard
                          </span>
                        )}
                      </div>

                      <p className="text-sm text-gray-600 dark:text-gray-400 mt-2">
                        {milestone.description}
                      </p>

                      {/* Deliverables */}
                      <div className="mt-3">
                        <div className="text-xs font-medium text-gray-700 dark:text-gray-300 mb-2">
                          Livrables:
                        </div>
                        <ul className="space-y-1">
                          {milestone.deliverables.map((deliverable, idx) => (
                            <li
                              key={idx}
                              className="text-sm text-gray-600 dark:text-gray-400 flex items-start space-x-2"
                            >
                              <span className="text-blue-600 dark:text-blue-400 mt-0.5">
                                •
                              </span>
                              <span>{deliverable}</span>
                            </li>
                          ))}
                        </ul>
                      </div>

                      {/* Evidence URLs */}
                      {milestone.evidenceUrls && milestone.evidenceUrls.length > 0 && (
                        <div className="mt-3">
                          <div className="text-xs font-medium text-gray-700 dark:text-gray-300 mb-2">
                            Preuves soumises:
                          </div>
                          <div className="flex flex-wrap gap-2">
                            {milestone.evidenceUrls.map((url, idx) => (
                              <a
                                key={idx}
                                href={`https://ipfs.io/ipfs/${url}`}
                                target="_blank"
                                rel="noopener noreferrer"
                                className="px-2 py-1 bg-blue-50 dark:bg-blue-900/20 text-blue-600 dark:text-blue-400 rounded text-xs hover:bg-blue-100 dark:hover:bg-blue-900/30 transition-colors"
                              >
                                📎 {url.slice(0, 8)}...{url.slice(-6)}
                              </a>
                            ))}
                          </div>
                        </div>
                      )}

                      {/* Review Notes */}
                      {milestone.reviewNotes && (
                        <div className="mt-3 p-3 bg-yellow-50 dark:bg-yellow-900/20 rounded-lg">
                          <div className="text-xs font-medium text-yellow-900 dark:text-yellow-300 mb-1">
                            Notes de révision:
                          </div>
                          <p className="text-sm text-yellow-800 dark:text-yellow-200">
                            {milestone.reviewNotes}
                          </p>
                        </div>
                      )}
                    </div>

                    {/* Milestone Meta */}
                    <div className="ml-6 text-right">
                      <div className="text-2xl font-bold text-green-600 dark:text-green-400">
                        {formatAmount(milestone.amount)}
                      </div>
                      <div className="text-xs text-gray-600 dark:text-gray-400 mt-1">
                        Échéance:{' '}
                        {milestone.dueDate.toLocaleDateString('fr-FR', {
                          day: 'numeric',
                          month: 'short',
                        })}
                      </div>

                      {/* Actions */}
                      <div className="mt-4 space-y-2">
                        {/* Consultant: Submit evidence */}
                        {isConsultant &&
                          milestone.status === MilestoneStatus.Pending &&
                          canSubmitNext &&
                          isNext && (
                            <button
                              onClick={() => setSelectedMilestone(milestone)}
                              className="w-full px-3 py-2 bg-blue-600 text-white text-sm rounded-md hover:bg-blue-700 font-medium transition-colors"
                            >
                              Soumettre preuves
                            </button>
                          )}

                        {/* Client: Approve/Reject */}
                        {!isConsultant &&
                          milestone.status === MilestoneStatus.UnderReview && (
                            <>
                              <button
                                onClick={() => handleApproveMilestone(milestone)}
                                className="w-full px-3 py-2 bg-green-600 text-white text-sm rounded-md hover:bg-green-700 font-medium transition-colors"
                              >
                                Approuver
                              </button>
                              <button
                                onClick={() => {
                                  const reason = prompt('Raison du rejet:');
                                  if (reason) {
                                    handleRejectMilestone(milestone, reason);
                                  }
                                }}
                                className="w-full px-3 py-2 bg-red-600 text-white text-sm rounded-md hover:bg-red-700 font-medium transition-colors"
                              >
                                Rejeter
                              </button>
                            </>
                          )}
                      </div>
                    </div>
                  </div>
                </div>
              );
            })}
        </div>
      )}

      {/* Submit Evidence Modal */}
      {selectedMilestone && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4">
          <div className="bg-white dark:bg-gray-800 rounded-lg border border-gray-200 dark:border-gray-700 max-w-2xl w-full p-6">
            <h3 className="text-lg font-semibold text-gray-900 dark:text-white mb-4">
              Soumettre preuves - {selectedMilestone.title}
            </h3>

            <div className="space-y-4">
              <div>
                <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                  URLs IPFS (une par ligne)
                </label>
                <textarea
                  value={evidenceUrls.join('\n')}
                  onChange={(e) =>
                    setEvidenceUrls(e.target.value.split('\n').filter((u) => u.trim()))
                  }
                  rows={5}
                  className="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-md shadow-sm focus:outline-none focus:ring-blue-500 focus:border-blue-500 dark:bg-gray-700 dark:text-white"
                  placeholder="QmX...abc&#10;QmY...def&#10;QmZ...ghi"
                />
                <p className="text-xs text-gray-500 dark:text-gray-400 mt-1">
                  Uploadez vos fichiers sur IPFS puis collez les hashes ici
                </p>
              </div>

              <div className="flex items-center justify-end space-x-3">
                <button
                  onClick={() => {
                    setSelectedMilestone(null);
                    setEvidenceUrls([]);
                  }}
                  className="px-4 py-2 text-gray-700 dark:text-gray-300 hover:bg-gray-100 dark:hover:bg-gray-700 rounded-md font-medium transition-colors"
                >
                  Annuler
                </button>
                <button
                  onClick={() => handleSubmitMilestone(selectedMilestone)}
                  disabled={submittingEvidence || evidenceUrls.length === 0}
                  className="px-6 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700 disabled:opacity-50 disabled:cursor-not-allowed font-medium transition-colors"
                >
                  {submittingEvidence ? 'Soumission...' : 'Soumettre'}
                </button>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* Change Request Modal */}
      {showChangeRequest && (
        <ChangeRequestForm
          mission={mission}
          userAddress={userAddress}
          isConsultant={isConsultant}
          escrowContract={escrowContract}
          onClose={() => setShowChangeRequest(false)}
          onSubmit={(changeRequest) => {
            onMissionUpdate({
              ...mission,
              changeRequests: [...mission.changeRequests, changeRequest],
              updatedAt: new Date(),
            });
            setShowChangeRequest(false);
          }}
        />
      )}

      {/* Dispute Modal */}
      {showDispute && (
        <DisputeModal
          mission={mission}
          userAddress={userAddress}
          isConsultant={isConsultant}
          escrowContract={escrowContract}
          onClose={() => setShowDispute(false)}
          onSubmit={(dispute) => {
            onMissionUpdate({
              ...mission,
              disputes: [...mission.disputes, dispute],
              status: MissionStatus.Disputed,
              updatedAt: new Date(),
            });
            setShowDispute(false);
          }}
        />
      )}
    </div>
  );
}
