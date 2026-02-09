/**
 * ChangeRequestForm Component
 * Form for proposing mission scope/budget/timeline changes
 */

import { useState } from 'react';
import { ethers } from 'ethers';
import {
  Mission,
  ChangeRequest,
  ChangeRequestStatus,
} from '@/types/milestone.js';

export interface ChangeRequestFormProps {
  mission: Mission;
  userAddress: string;
  isConsultant: boolean;
  escrowContract: ethers.Contract;
  onClose: () => void;
  onSubmit: (changeRequest: ChangeRequest) => void;
}

export function ChangeRequestForm({
  mission,
  userAddress,
  isConsultant,
  escrowContract,
  onClose,
  onSubmit,
}: ChangeRequestFormProps) {
  const [formData, setFormData] = useState({
    title: '',
    description: '',
    scopeChange: '',
    timelineAdjustment: 0, // Days
    budgetAdjustment: '',
    justification: '',
  });

  const [submitting, setSubmitting] = useState(false);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();

    if (!formData.title || !formData.description || !formData.justification) {
      alert('Veuillez remplir tous les champs obligatoires');
      return;
    }

    setSubmitting(true);

    try {
      // Parse budget adjustment
      const budgetAdjustmentBigInt = formData.budgetAdjustment
        ? ethers.parseEther(formData.budgetAdjustment)
        : 0n;

      // Submit to smart contract
      const tx = await escrowContract.proposeChange(
        mission.id,
        formData.description,
        budgetAdjustmentBigInt
      );

      await tx.wait();

      // Create change request object
      const changeRequest: ChangeRequest = {
        id: `cr-${Date.now()}-${Math.random().toString(36).substr(2, 9)}`,
        missionId: mission.id,
        proposedBy: userAddress,
        title: formData.title,
        description: formData.description,
        impact: {
          scope: formData.scopeChange || undefined,
          timeline: formData.timelineAdjustment !== 0 ? formData.timelineAdjustment : undefined,
          budget: budgetAdjustmentBigInt !== 0n ? budgetAdjustmentBigInt : undefined,
        },
        justification: formData.justification,
        status: ChangeRequestStatus.Pending,
        createdAt: new Date(),
      };

      onSubmit(changeRequest);
    } catch (error) {
      console.error('Error submitting change request:', error);
      alert('Erreur lors de la soumission de la demande');
    } finally {
      setSubmitting(false);
    }
  };

  return (
    <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4">
      <div className="bg-white dark:bg-gray-800 rounded-lg border border-gray-200 dark:border-gray-700 max-w-3xl w-full max-h-[90vh] overflow-auto">
        {/* Header */}
        <div className="flex items-center justify-between p-6 border-b border-gray-200 dark:border-gray-700">
          <div>
            <h2 className="text-xl font-semibold text-gray-900 dark:text-white">
              Demande de changement
            </h2>
            <p className="text-sm text-gray-600 dark:text-gray-400 mt-1">
              Proposer une modification du scope, délai, ou budget
            </p>
          </div>
          <button
            onClick={onClose}
            className="text-gray-400 hover:text-gray-600 dark:hover:text-gray-200 transition-colors"
          >
            <svg className="w-6 h-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path
                strokeLinecap="round"
                strokeLinejoin="round"
                strokeWidth={2}
                d="M6 18L18 6M6 6l12 12"
              />
            </svg>
          </button>
        </div>

        {/* Form */}
        <form onSubmit={handleSubmit} className="p-6 space-y-6">
          {/* Title */}
          <div>
            <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
              Titre <span className="text-red-500">*</span>
            </label>
            <input
              type="text"
              value={formData.title}
              onChange={(e) => setFormData({ ...formData, title: e.target.value })}
              className="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-md shadow-sm focus:outline-none focus:ring-blue-500 focus:border-blue-500 dark:bg-gray-700 dark:text-white"
              placeholder="Ex: Extension du périmètre fonctionnel"
              required
            />
          </div>

          {/* Description */}
          <div>
            <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
              Description détaillée <span className="text-red-500">*</span>
            </label>
            <textarea
              value={formData.description}
              onChange={(e) => setFormData({ ...formData, description: e.target.value })}
              rows={4}
              className="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-md shadow-sm focus:outline-none focus:ring-blue-500 focus:border-blue-500 dark:bg-gray-700 dark:text-white"
              placeholder="Décrivez précisément les changements proposés..."
              required
            />
          </div>

          {/* Impact Section */}
          <div className="bg-blue-50 dark:bg-blue-900/20 rounded-lg p-4 space-y-4">
            <h3 className="text-sm font-medium text-blue-900 dark:text-blue-300">
              Impact des changements
            </h3>

            {/* Scope Change */}
            <div>
              <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                Modification du scope (optionnel)
              </label>
              <textarea
                value={formData.scopeChange}
                onChange={(e) => setFormData({ ...formData, scopeChange: e.target.value })}
                rows={3}
                className="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-md shadow-sm focus:outline-none focus:ring-blue-500 focus:border-blue-500 dark:bg-gray-700 dark:text-white text-sm"
                placeholder="Nouvelles fonctionnalités, suppressions, modifications..."
              />
            </div>

            {/* Timeline Adjustment */}
            <div>
              <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                Ajustement délai (jours)
              </label>
              <div className="flex items-center space-x-4">
                <input
                  type="number"
                  value={formData.timelineAdjustment}
                  onChange={(e) =>
                    setFormData({ ...formData, timelineAdjustment: parseInt(e.target.value) || 0 })
                  }
                  className="w-32 px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-md shadow-sm focus:outline-none focus:ring-blue-500 focus:border-blue-500 dark:bg-gray-700 dark:text-white"
                  placeholder="0"
                />
                <span className="text-sm text-gray-600 dark:text-gray-400">
                  {formData.timelineAdjustment > 0
                    ? `Extension de ${formData.timelineAdjustment} jours`
                    : formData.timelineAdjustment < 0
                    ? `Réduction de ${Math.abs(formData.timelineAdjustment)} jours`
                    : 'Aucun changement'}
                </span>
              </div>
            </div>

            {/* Budget Adjustment */}
            <div>
              <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                Ajustement budget ({mission.currency})
              </label>
              <div className="flex items-center space-x-4">
                <input
                  type="number"
                  step="0.01"
                  value={formData.budgetAdjustment}
                  onChange={(e) =>
                    setFormData({ ...formData, budgetAdjustment: e.target.value })
                  }
                  className="w-32 px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-md shadow-sm focus:outline-none focus:ring-blue-500 focus:border-blue-500 dark:bg-gray-700 dark:text-white"
                  placeholder="0"
                />
                <span className="text-sm text-gray-600 dark:text-gray-400">
                  {formData.budgetAdjustment && parseFloat(formData.budgetAdjustment) !== 0
                    ? parseFloat(formData.budgetAdjustment) > 0
                      ? `+ ${formData.budgetAdjustment} ${mission.currency} (augmentation)`
                      : `${formData.budgetAdjustment} ${mission.currency} (réduction)`
                    : 'Aucun changement'}
                </span>
              </div>
            </div>
          </div>

          {/* Justification */}
          <div>
            <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
              Justification <span className="text-red-500">*</span>
            </label>
            <textarea
              value={formData.justification}
              onChange={(e) => setFormData({ ...formData, justification: e.target.value })}
              rows={4}
              className="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-md shadow-sm focus:outline-none focus:ring-blue-500 focus:border-blue-500 dark:bg-gray-700 dark:text-white"
              placeholder="Expliquez pourquoi ces changements sont nécessaires..."
              required
            />
            <p className="text-xs text-gray-500 dark:text-gray-400 mt-1">
              Justification requise pour approbation par la contrepartie
            </p>
          </div>

          {/* Warning */}
          <div className="bg-yellow-50 dark:bg-yellow-900/20 rounded-lg p-4">
            <div className="flex items-start space-x-3">
              <svg
                className="w-5 h-5 text-yellow-600 dark:text-yellow-400 mt-0.5"
                fill="none"
                viewBox="0 0 24 24"
                stroke="currentColor"
              >
                <path
                  strokeLinecap="round"
                  strokeLinejoin="round"
                  strokeWidth={2}
                  d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"
                />
              </svg>
              <div className="flex-1">
                <h4 className="text-sm font-medium text-yellow-900 dark:text-yellow-300 mb-1">
                  Note importante
                </h4>
                <p className="text-sm text-yellow-800 dark:text-yellow-200">
                  {isConsultant
                    ? 'Cette demande sera envoyée au client pour approbation. Le travail doit être suspendu en attendant la réponse.'
                    : 'Cette demande sera envoyée au consultant pour approbation. La mission peut continuer pendant la négociation.'}
                </p>
              </div>
            </div>
          </div>

          {/* Actions */}
          <div className="flex items-center justify-end space-x-3 pt-4 border-t border-gray-200 dark:border-gray-700">
            <button
              type="button"
              onClick={onClose}
              className="px-4 py-2 text-gray-700 dark:text-gray-300 hover:bg-gray-100 dark:hover:bg-gray-700 rounded-md font-medium transition-colors"
            >
              Annuler
            </button>
            <button
              type="submit"
              disabled={submitting}
              className="px-6 py-2 bg-yellow-600 text-white rounded-md hover:bg-yellow-700 disabled:opacity-50 disabled:cursor-not-allowed font-medium transition-colors flex items-center space-x-2"
            >
              {submitting ? (
                <>
                  <div className="animate-spin rounded-full h-4 w-4 border-b-2 border-white"></div>
                  <span>Soumission...</span>
                </>
              ) : (
                <>
                  <svg
                    className="w-5 h-5"
                    fill="none"
                    viewBox="0 0 24 24"
                    stroke="currentColor"
                  >
                    <path
                      strokeLinecap="round"
                      strokeLinejoin="round"
                      strokeWidth={2}
                      d="M12 19l9 2-9-18-9 18 9-2zm0 0v-8"
                    />
                  </svg>
                  <span>Soumettre demande</span>
                </>
              )}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}
