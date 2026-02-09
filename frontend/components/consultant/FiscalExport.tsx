/**
 * FiscalExport Component
 * CSV export for fiscal declaration (FR, BE, CH, LUX)
 */

import { useState } from 'react';
import { Transaction } from './ConsultantDashboard.js';
import { format } from 'date-fns';
import { fr } from 'date-fns/locale';

export interface FiscalExportProps {
  transactions: Transaction[];
  userAddress: string;
  onClose: () => void;
}

type Country = 'FR' | 'BE' | 'CH' | 'LUX';
type FiscalYear = number;

// CSV Headers by country
const CSV_HEADERS: Record<Country, string> = {
  FR: 'Date,Mission,Montant DAOS,Taux EUR/DAOS,Montant EUR,Type,Remarques',
  BE: 'Datum,Missie,Bedrag DAOS,Wisselkoers EUR/DAOS,Bedrag EUR,Type,Opmerkingen',
  CH: 'Datum,Mission,Betrag DAOS,Wechselkurs EUR/DAOS,Betrag EUR,Typ,Bemerkungen',
  LUX: 'Date,Mission,Montant DAOS,Taux EUR/DAOS,Montant EUR,Type,Remarques',
};

// Fiscal year notes by country
const FISCAL_NOTES: Record<Country, string> = {
  FR: 'Déclaration BNC (Bénéfices Non Commerciaux) - Formulaire 2042-C-PRO. Revenus de prestations intellectuelles. Régime micro-BNC si <77 700€ (abattement 34%). Sinon régime réel.',
  BE: 'Déclaration revenus indépendant complémentaire - Code 1200 (revenus professions libérales). Cotisations sociales si >1 769,57€/trimestre. TVA si >25 000€.',
  CH: 'Déclaration AVS/AI obligatoire. Revenus de travail indépendant à déclarer dans la déclaration fiscale annuelle. Cotisations AVS/AI/APG à payer (env. 10%).',
  LUX: 'Déclaration auto-entrepreneur - Formulaire 100. Régime forfaitaire si <100 000€. TVA si >35 000€. Cotisations sociales sur base des revenus nets.',
};

export function FiscalExport({ transactions, userAddress, onClose }: FiscalExportProps) {
  const currentYear = new Date().getFullYear();
  const [country, setCountry] = useState<Country>('FR');
  const [fiscalYear, setFiscalYear] = useState<FiscalYear>(currentYear);

  // Available fiscal years (last 5 years + current)
  const availableYears = Array.from({ length: 6 }, (_, i) => currentYear - i);

  // Filter transactions by fiscal year
  const filteredTransactions = transactions.filter((tx) => {
    const year = tx.date.getFullYear();
    return year === fiscalYear;
  });

  // Calculate totals
  const totalDaos = filteredTransactions.reduce(
    (sum, tx) => sum + Number(tx.daosAmount),
    0
  ) / 1e18;
  const totalEur = filteredTransactions.reduce((sum, tx) => sum + tx.eurValue, 0);

  // Generate CSV
  const generateCSV = () => {
    const header = CSV_HEADERS[country];
    const rows = filteredTransactions.map((tx) => {
      const dateFormatted = format(tx.date, 'dd/MM/yyyy');
      const daosFormatted = (Number(tx.daosAmount) / 1e18).toFixed(2);
      const rateFormatted = tx.daosToEurRate.toFixed(4);
      const eurFormatted = tx.eurValue.toFixed(2);
      const typeLabel = tx.type === 'mission_payment' ? 'Mission' : tx.type === 'bonus' ? 'Bonus' : 'Remboursement';
      const remarks = tx.missionTitle;

      return `"${dateFormatted}","${remarks}","${daosFormatted}","${rateFormatted}","${eurFormatted}","${typeLabel}",""`;
    });

    // Add summary row
    rows.push('');
    rows.push(`"TOTAL"," ","${totalDaos.toFixed(2)}"," ","${totalEur.toFixed(2)}"," "," "`);

    // Add metadata
    rows.push('');
    rows.push(`"Adresse wallet","${userAddress}"," "," "," "," "," "`);
    rows.push(`"Année fiscale","${fiscalYear}"," "," "," "," "," "`);
    rows.push(`"Pays","${country}"," "," "," "," "," "`);
    rows.push(`"Date export","${format(new Date(), 'dd/MM/yyyy HH:mm')}"," "," "," "," "," "`);

    return [header, ...rows].join('\n');
  };

  // Download CSV
  const handleExport = () => {
    const csv = generateCSV();
    const blob = new Blob(['\ufeff' + csv], { type: 'text/csv;charset=utf-8;' }); // BOM for Excel
    const link = document.createElement('a');
    const url = URL.createObjectURL(blob);

    link.setAttribute('href', url);
    link.setAttribute('download', `fiscal-export-${country}-${fiscalYear}.csv`);
    link.style.visibility = 'hidden';

    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
  };

  return (
    <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4">
      <div className="bg-white dark:bg-gray-800 rounded-lg border border-gray-200 dark:border-gray-700 max-w-4xl w-full max-h-[90vh] overflow-auto">
        {/* Header */}
        <div className="flex items-center justify-between p-6 border-b border-gray-200 dark:border-gray-700">
          <div>
            <h2 className="text-xl font-semibold text-gray-900 dark:text-white">
              Export Fiscal
            </h2>
            <p className="text-sm text-gray-600 dark:text-gray-400 mt-1">
              Générer un fichier CSV pour votre déclaration fiscale
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

        {/* Content */}
        <div className="p-6 space-y-6">
          {/* Selection Controls */}
          <div className="grid grid-cols-2 gap-4">
            {/* Country Selector */}
            <div>
              <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                Pays de déclaration
              </label>
              <select
                value={country}
                onChange={(e) => setCountry(e.target.value as Country)}
                className="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-md shadow-sm focus:outline-none focus:ring-blue-500 focus:border-blue-500 dark:bg-gray-700 dark:text-white"
              >
                <option value="FR">🇫🇷 France (BNC)</option>
                <option value="BE">🇧🇪 Belgique (Indépendant)</option>
                <option value="CH">🇨🇭 Suisse (AVS)</option>
                <option value="LUX">🇱🇺 Luxembourg (Auto-entrepreneur)</option>
              </select>
            </div>

            {/* Year Selector */}
            <div>
              <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                Année fiscale
              </label>
              <select
                value={fiscalYear}
                onChange={(e) => setFiscalYear(Number(e.target.value))}
                className="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-md shadow-sm focus:outline-none focus:ring-blue-500 focus:border-blue-500 dark:bg-gray-700 dark:text-white"
              >
                {availableYears.map((year) => (
                  <option key={year} value={year}>
                    {year}
                    {year === currentYear && ' (année courante)'}
                  </option>
                ))}
              </select>
            </div>
          </div>

          {/* Summary */}
          <div className="bg-blue-50 dark:bg-blue-900/20 rounded-lg p-4">
            <h3 className="text-sm font-medium text-blue-900 dark:text-blue-300 mb-3">
              Résumé {fiscalYear}
            </h3>
            <div className="grid grid-cols-3 gap-4">
              <div>
                <div className="text-xs text-blue-600 dark:text-blue-400 mb-1">
                  Transactions
                </div>
                <div className="text-2xl font-bold text-blue-900 dark:text-blue-300">
                  {filteredTransactions.length}
                </div>
              </div>
              <div>
                <div className="text-xs text-blue-600 dark:text-blue-400 mb-1">
                  Total DAOS
                </div>
                <div className="text-2xl font-bold text-blue-900 dark:text-blue-300">
                  {totalDaos.toLocaleString('fr-FR', { maximumFractionDigits: 0 })}
                </div>
              </div>
              <div>
                <div className="text-xs text-blue-600 dark:text-blue-400 mb-1">
                  Total EUR
                </div>
                <div className="text-2xl font-bold text-green-600 dark:text-green-400">
                  {totalEur.toLocaleString('fr-FR', {
                    style: 'currency',
                    currency: 'EUR',
                    maximumFractionDigits: 0,
                  })}
                </div>
              </div>
            </div>
          </div>

          {/* Fiscal Notes */}
          <div className="bg-yellow-50 dark:bg-yellow-900/20 rounded-lg p-4">
            <h3 className="text-sm font-medium text-yellow-900 dark:text-yellow-300 mb-2 flex items-center">
              <svg
                className="w-5 h-5 mr-2"
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
              Notes fiscales - {country}
            </h3>
            <p className="text-xs text-yellow-800 dark:text-yellow-200 leading-relaxed">
              {FISCAL_NOTES[country]}
            </p>
            <div className="mt-3 pt-3 border-t border-yellow-200 dark:border-yellow-800">
              <p className="text-xs text-yellow-700 dark:text-yellow-300 font-medium">
                ⚠️ Recommandation : Consultez un expert-comptable certifié crypto pour validation
              </p>
            </div>
          </div>

          {/* Preview (first 5 transactions) */}
          {filteredTransactions.length > 0 ? (
            <div>
              <h3 className="text-sm font-medium text-gray-700 dark:text-gray-300 mb-3">
                Aperçu (5 premières transactions)
              </h3>
              <div className="overflow-x-auto">
                <table className="min-w-full divide-y divide-gray-200 dark:divide-gray-700">
                  <thead className="bg-gray-50 dark:bg-gray-700">
                    <tr>
                      <th className="px-3 py-2 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase">
                        Date
                      </th>
                      <th className="px-3 py-2 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase">
                        Mission
                      </th>
                      <th className="px-3 py-2 text-right text-xs font-medium text-gray-500 dark:text-gray-400 uppercase">
                        DAOS
                      </th>
                      <th className="px-3 py-2 text-right text-xs font-medium text-gray-500 dark:text-gray-400 uppercase">
                        Taux
                      </th>
                      <th className="px-3 py-2 text-right text-xs font-medium text-gray-500 dark:text-gray-400 uppercase">
                        EUR
                      </th>
                    </tr>
                  </thead>
                  <tbody className="bg-white dark:bg-gray-800 divide-y divide-gray-200 dark:divide-gray-700">
                    {filteredTransactions.slice(0, 5).map((tx) => (
                      <tr key={tx.id}>
                        <td className="px-3 py-2 text-sm text-gray-900 dark:text-white">
                          {format(tx.date, 'dd/MM/yyyy')}
                        </td>
                        <td className="px-3 py-2 text-sm text-gray-900 dark:text-white">
                          {tx.missionTitle}
                        </td>
                        <td className="px-3 py-2 text-sm text-right text-gray-900 dark:text-white">
                          {(Number(tx.daosAmount) / 1e18).toFixed(2)}
                        </td>
                        <td className="px-3 py-2 text-sm text-right text-gray-600 dark:text-gray-400">
                          {tx.daosToEurRate.toFixed(4)}
                        </td>
                        <td className="px-3 py-2 text-sm text-right font-medium text-green-600 dark:text-green-400">
                          {tx.eurValue.toLocaleString('fr-FR', {
                            style: 'currency',
                            currency: 'EUR',
                          })}
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
              {filteredTransactions.length > 5 && (
                <p className="text-xs text-gray-500 dark:text-gray-400 mt-2">
                  ... et {filteredTransactions.length - 5} autres transactions
                </p>
              )}
            </div>
          ) : (
            <div className="text-center py-8 text-gray-500 dark:text-gray-400">
              <svg
                className="w-12 h-12 mx-auto mb-3"
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
              <p className="text-sm">Aucune transaction pour {fiscalYear}</p>
            </div>
          )}
        </div>

        {/* Footer Actions */}
        <div className="flex items-center justify-between p-6 border-t border-gray-200 dark:border-gray-700">
          <button
            onClick={onClose}
            className="px-4 py-2 text-gray-700 dark:text-gray-300 hover:bg-gray-100 dark:hover:bg-gray-700 rounded-md font-medium transition-colors"
          >
            Annuler
          </button>
          <button
            onClick={handleExport}
            disabled={filteredTransactions.length === 0}
            className="px-6 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700 disabled:opacity-50 disabled:cursor-not-allowed font-medium transition-colors flex items-center space-x-2"
          >
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
                d="M12 10v6m0 0l-3-3m3 3l3-3m2 8H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"
              />
            </svg>
            <span>Exporter CSV</span>
          </button>
        </div>
      </div>
    </div>
  );
}
