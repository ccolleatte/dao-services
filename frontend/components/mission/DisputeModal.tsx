/**
 * DisputeModal Component
 * Modal for opening mission disputes with jury selection
 */

import { useState } from 'react';
import { ethers } from 'ethers';
import {
  Mission,
  Dispute,
  DisputeStatus,
  DisputeOutcome,
} from '@/types/milestone.js';

export interface DisputeModalProps {
  mission: Mission;
  userAddress: string;
  isConsultant: boolean;
  escrowContract: ethers.Contract;
  onClose: () => void;
  onSubmit: (dispute: Dispute) => void;
}

export function DisputeModal({
  mission,
  userAddress,
  isConsultant,
  escrowContract,
  onClose,
  onSubmit,
}: DisputeModalProps) {
  const [formData, setFormData] = useState({
    subject: '',
    description: '',
    evidenceUrls: [] as string[],
  });

  const [submitting, setSubmitting] = useState(false);

  // Dispute deposit (100 DAOS)
  const depositAmount = ethers.parseEther('100');

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();

    if (!formData.subject || !formData.description) {
      alert('Veuillez remplir tous les champs obligatoires');
      return;
    }

    if (formData.evidenceUrls.length === 0) {
      alert('Veuillez fournir au moins une preuve (URL IPFS)');
      return;
    }

    // Confirm deposit
    const confirmed = window.confirm(
      `Cette action nécessite un dépôt de 100 DAOS (remboursé si le litige est résolu en votre faveur).\n\nConfirmez-vous l'ouverture du litige ?`
    );

    if (!confirmed) return;

    setSubmitting(true);

    try {
      // Open dispute on smart contract
      const tx = await escrowContract.openDispute(
        mission.id,
        formData.subject,
        formData.evidenceUrls,
        { value: depositAmount }
      );

      await tx.wait();

      // Create dispute object
      const dispute: Dispute = {
        id: `dispute-${Date.now()}-${Math.random().toString(36).substr(2, 9)}`,
        missionId: mission.id,
        initiatedBy: userAddress,
        subject: formData.subject,
        description: formData.description,
        evidenceUrls: formData.evidenceUrls,
        status: DisputeStatus.Open,
        juryMembers: [], // Will be populated by smart contract
        juryVotes: [],
        deposit: depositAmount,
        createdAt: new Date(),
      };

      onSubmit(dispute);
    } catch (error) {
      console.error('Error opening dispute:', error);
      alert('Erreur lors de l\'ouverture du litige');
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
            <h2 className="text-xl font-semibold text-gray-900 dark:text-white flex items-center space-x-2">
              <svg
                className="w-6 h-6 text-red-600 dark:text-red-400"
                fill="none"
                viewBox="0 0 24 24"
                stroke="currentColor"
              >
                <path
                  strokeLinecap="round"
                  strokeLinejoin="round"
                  strokeWidth={2}
                  d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z"
                />
              </svg>
              <span>Ouvrir un litige</span>
            </h2>
            <p className="text-sm text-gray-600 dark:text-gray-400 mt-1">
              Déclencher une procédure d'arbitrage avec jury DAO
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

        {/* Warning Banner */}
        <div className="m-6 bg-red-50 dark:bg-red-900/20 border-2 border-red-200 dark:border-red-800 rounded-lg p-4">
          <div className="flex items-start space-x-3">
            <svg
              className="w-6 h-6 text-red-600 dark:text-red-400 mt-0.5 flex-shrink-0"
              fill="none"
              viewBox="0 0 24 24"
              stroke="currentColor"
            >
              <path
                strokeLinecap="round"
                strokeLinejoin="round"
                strokeWidth={2}
                d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z"
              />
            </svg>
            <div className="flex-1">
              <h4 className="text-sm font-medium text-red-900 dark:text-red-300 mb-2">
                Procédure formelle d'arbitrage
              </h4>
              <ul className="text-sm text-red-800 dark:text-red-200 space-y-1 list-disc list-inside">
                <li>Dépôt requis : 100 DAOS (remboursé si gagné)</li>
                <li>Jury : 5 membres DAO Rank 3+ (sélection pseudo-aléatoire)</li>
                <li>Délibération : 72h maximum</li>
                <li>Décision finale : Majorité simple (3/5 votes minimum)</li>
                <li>Mission suspendue pendant arbitrage</li>
              </ul>
            </div>
          </div>
        </div>

        {/* Form */}
        <form onSubmit={handleSubmit} className="p-6 space-y-6">
          {/* Subject */}
          <div>
            <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
              Objet du litige <span className="text-red-500">*</span>
            </label>
            <input
              type="text"
              value={formData.subject}
              onChange={(e) => setFormData({ ...formData, subject: e.target.value })}
              className="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-md shadow-sm focus:outline-none focus:ring-red-500 focus:border-red-500 dark:bg-gray-700 dark:text-white"
              placeholder="Ex: Non-respect des délais convenus"
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
              rows={6}
              className="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-md shadow-sm focus:outline-none focus:ring-red-500 focus:border-red-500 dark:bg-gray-700 dark:text-white"
              placeholder="Décrivez précisément les faits, les désaccords, et vos attentes..."
              required
            />
            <p className="text-xs text-gray-500 dark:text-gray-400 mt-1">
              Soyez précis et factuel. Cette description sera lue par le jury.
            </p>
          </div>

          {/* Evidence URLs */}
          <div>
            <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
              Preuves (URLs IPFS) <span className="text-red-500">*</span>
            </label>
            <textarea
              value={formData.evidenceUrls.join('\n')}
              onChange={(e) =>
                setFormData({
                  ...formData,
                  evidenceUrls: e.target.value.split('\n').filter((u) => u.trim()),
                })
              }
              rows={5}
              className="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-md shadow-sm focus:outline-none focus:ring-red-500 focus:border-red-500 dark:bg-gray-700 dark:text-white font-mono text-sm"
              placeholder="QmX...abc&#10;QmY...def&#10;QmZ...ghi"
              required
            />
            <p className="text-xs text-gray-500 dark:text-gray-400 mt-1">
              Uploadez vos preuves (captures d'écran, emails, contrats) sur IPFS puis collez les hashes ici (un par ligne)
            </p>
          </div>

          {/* Evidence Preview */}
          {formData.evidenceUrls.length > 0 && (
            <div className="bg-gray-50 dark:bg-gray-700/50 rounded-lg p-4">
              <div className="text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                Preuves à soumettre ({formData.evidenceUrls.length})
              </div>
              <div className="space-y-2">
                {formData.evidenceUrls.map((url, idx) => (
                  <div
                    key={idx}
                    className="flex items-center justify-between bg-white dark:bg-gray-800 rounded p-2"
                  >
                    <div className="flex items-center space-x-2 flex-1 min-w-0">
                      <svg
                        className="w-4 h-4 text-blue-600 dark:text-blue-400 flex-shrink-0"
                        fill="none"
                        viewBox="0 0 24 24"
                        stroke="currentColor"
                      >
                        <path
                          strokeLinecap="round"
                          strokeLinejoin="round"
                          strokeWidth={2}
                          d="M15.172 7l-6.586 6.586a2 2 0 102.828 2.828l6.414-6.586a4 4 0 00-5.656-5.656l-6.415 6.585a6 6 0 108.486 8.486L20.5 13"
                        />
                      </svg>
                      <span className="text-sm text-gray-600 dark:text-gray-400 truncate font-mono">
                        {url}
                      </span>
                    </div>
                    <a
                      href={`https://ipfs.io/ipfs/${url}`}
                      target="_blank"
                      rel="noopener noreferrer"
                      className="ml-2 text-blue-600 dark:text-blue-400 hover:underline text-xs flex-shrink-0"
                    >
                      Prévisualiser
                    </a>
                  </div>
                ))}
              </div>
            </div>
          )}

          {/* Jury Selection Info */}
          <div className="bg-blue-50 dark:bg-blue-900/20 rounded-lg p-4">
            <h4 className="text-sm font-medium text-blue-900 dark:text-blue-300 mb-2 flex items-center space-x-2">
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
                  d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0zm6 3a2 2 0 11-4 0 2 2 0 014 0zM7 10a2 2 0 11-4 0 2 2 0 014 0z"
                />
              </svg>
              <span>Sélection automatique du jury</span>
            </h4>
            <p className="text-sm text-blue-800 dark:text-blue-200">
              5 membres DAO Rank 3+ seront sélectionnés pseudo-aléatoirement pour arbitrer ce litige.
              Les membres ayant un conflit d'intérêt (participation à la mission, relation avec les parties)
              seront exclus automatiquement.
            </p>
          </div>

          {/* Deposit Info */}
          <div className="bg-yellow-50 dark:bg-yellow-900/20 border-2 border-yellow-200 dark:border-yellow-800 rounded-lg p-4">
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
                  d="M12 8c-1.657 0-3 .895-3 2s1.343 2 3 2 3 .895 3 2-1.343 2-3 2m0-8c1.11 0 2.08.402 2.599 1M12 8V7m0 1v8m0 0v1m0-1c-1.11 0-2.08-.402-2.599-1M21 12a9 9 0 11-18 0 9 9 0 0118 0z"
                />
              </svg>
              <div className="flex-1">
                <h4 className="text-sm font-medium text-yellow-900 dark:text-yellow-300 mb-1">
                  Dépôt requis : 100 DAOS
                </h4>
                <ul className="text-sm text-yellow-800 dark:text-yellow-200 space-y-1 list-disc list-inside">
                  <li>Remboursé si litige résolu en votre faveur</li>
                  <li>Conservé par la DAO si litige rejeté</li>
                  <li>Partagé 50/50 en cas de compromis</li>
                </ul>
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
              className="px-6 py-2 bg-red-600 text-white rounded-md hover:bg-red-700 disabled:opacity-50 disabled:cursor-not-allowed font-medium transition-colors flex items-center space-x-2"
            >
              {submitting ? (
                <>
                  <div className="animate-spin rounded-full h-4 w-4 border-b-2 border-white"></div>
                  <span>Ouverture...</span>
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
                      d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z"
                    />
                  </svg>
                  <span>Ouvrir litige (100 DAOS)</span>
                </>
              )}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}
