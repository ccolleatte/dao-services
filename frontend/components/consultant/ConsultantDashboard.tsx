/**
 * ConsultantDashboard Component
 * Main dashboard for consultant earnings, conversion EUR, and fiscal export
 */

import { useState, useEffect } from 'react';
import { ethers } from 'ethers';
import { useQuery } from '@tanstack/react-query';
import { EarningsChart } from './EarningsChart.js';
import { FiscalExport } from './FiscalExport.js';
import { VolatilityAlerts } from './VolatilityAlerts.js';

// Chainlink Price Feed ABI (minimal)
const PRICE_FEED_ABI = [
  'function latestRoundData() external view returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound)',
  'function decimals() external view returns (uint8)',
];

export interface Transaction {
  id: string;
  date: Date;
  missionTitle: string;
  daosAmount: bigint;
  daosToEurRate: number;
  eurValue: number;
  type: 'mission_payment' | 'bonus' | 'refund';
}

export interface ConsultantDashboardProps {
  userAddress: string;
  provider: ethers.Provider;
  priceFeedAddress: string; // Chainlink DAOS/EUR Price Feed
  transactions: Transaction[];
}

export function ConsultantDashboard({
  userAddress,
  provider,
  priceFeedAddress,
  transactions,
}: ConsultantDashboardProps) {
  const [period, setPeriod] = useState<30 | 90>(30);
  const [showExport, setShowExport] = useState(false);
  const [balance, setBalance] = useState<bigint>(0n);

  // Fetch current DAOS/EUR rate from Chainlink (refresh every 30s)
  const { data: currentRate, isLoading: rateLoading } = useQuery({
    queryKey: ['daosEurRate', priceFeedAddress],
    queryFn: async () => {
      const priceFeed = new ethers.Contract(priceFeedAddress, PRICE_FEED_ABI, provider);
      const [, answer] = await priceFeed.latestRoundData();
      const decimals = await priceFeed.decimals();

      // Convert to EUR rate (answer is scaled by decimals)
      const rate = Number(answer) / Math.pow(10, Number(decimals));
      return rate;
    },
    refetchInterval: 30_000, // Refresh every 30 seconds
    staleTime: 25_000,
  });

  // Fetch user DAOS balance
  useEffect(() => {
    async function fetchBalance() {
      // Assuming DAOS is an ERC20 token
      // In production, use token contract address
      const balance = await provider.getBalance(userAddress);
      setBalance(balance);
    }
    fetchBalance();
  }, [userAddress, provider]);

  // Filter transactions by period
  const filteredTransactions = transactions.filter((tx) => {
    const daysAgo = (Date.now() - tx.date.getTime()) / (1000 * 60 * 60 * 24);
    return daysAgo <= period;
  });

  // Calculate total earnings in EUR for period
  const totalEarningsEur = filteredTransactions.reduce(
    (sum, tx) => sum + tx.eurValue,
    0
  );

  // Calculate projected monthly earnings (based on period average)
  const daysInPeriod = Math.min(period, Math.floor((Date.now() - new Date(Math.min(...filteredTransactions.map(tx => tx.date.getTime()))).getTime()) / (1000 * 60 * 60 * 24)));
  const avgDailyEarnings = daysInPeriod > 0 ? totalEarningsEur / daysInPeriod : 0;
  const projectedMonthlyEur = avgDailyEarnings * 30;

  // Current portfolio value in EUR
  const portfolioValueEur = currentRate
    ? (Number(balance) / 1e18) * currentRate
    : 0;

  return (
    <div className="max-w-7xl mx-auto p-6 space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-gray-900 dark:text-white">
            Tableau de bord Consultant
          </h1>
          <p className="text-sm text-gray-600 dark:text-gray-400 mt-1">
            {userAddress.slice(0, 6)}...{userAddress.slice(-4)}
          </p>
        </div>

        <button
          onClick={() => setShowExport(!showExport)}
          className="px-4 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700 font-medium transition-colors"
        >
          {showExport ? 'Masquer Export' : 'Export Fiscal'}
        </button>
      </div>

      {/* Volatility Alerts */}
      <VolatilityAlerts
        currentRate={currentRate || 0}
        transactions={transactions}
        portfolioValueEur={portfolioValueEur}
      />

      {/* Balance & Conversion Card */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
        {/* DAOS Balance */}
        <div className="bg-white dark:bg-gray-800 rounded-lg border border-gray-200 dark:border-gray-700 p-6">
          <div className="text-sm text-gray-600 dark:text-gray-400 mb-1">
            Solde DAOS
          </div>
          <div className="text-3xl font-bold text-gray-900 dark:text-white">
            {(Number(balance) / 1e18).toLocaleString('fr-FR', {
              minimumFractionDigits: 2,
              maximumFractionDigits: 2,
            })}
          </div>
          <div className="text-sm text-gray-600 dark:text-gray-400 mt-1">
            DAOS tokens
          </div>
        </div>

        {/* EUR Conversion */}
        <div className="bg-white dark:bg-gray-800 rounded-lg border border-gray-200 dark:border-gray-700 p-6">
          <div className="text-sm text-gray-600 dark:text-gray-400 mb-1">
            Valeur Portfolio EUR
          </div>
          {rateLoading ? (
            <div className="flex items-center space-x-2">
              <div className="animate-spin rounded-full h-6 w-6 border-b-2 border-blue-600"></div>
              <span className="text-sm text-gray-600 dark:text-gray-400">
                Chargement taux...
              </span>
            </div>
          ) : (
            <>
              <div className="text-3xl font-bold text-green-600 dark:text-green-400">
                {portfolioValueEur.toLocaleString('fr-FR', {
                  style: 'currency',
                  currency: 'EUR',
                })}
              </div>
              <div className="text-sm text-gray-600 dark:text-gray-400 mt-1">
                Taux: {currentRate?.toFixed(4)} EUR/DAOS
              </div>
            </>
          )}
        </div>

        {/* Projected Monthly */}
        <div className="bg-white dark:bg-gray-800 rounded-lg border border-gray-200 dark:border-gray-700 p-6">
          <div className="text-sm text-gray-600 dark:text-gray-400 mb-1">
            Projection Mensuelle
          </div>
          <div className="text-3xl font-bold text-blue-600 dark:text-blue-400">
            {projectedMonthlyEur.toLocaleString('fr-FR', {
              style: 'currency',
              currency: 'EUR',
            })}
          </div>
          <div className="text-sm text-gray-600 dark:text-gray-400 mt-1">
            Basé sur {period} derniers jours
          </div>
        </div>
      </div>

      {/* Period Selector */}
      <div className="flex items-center justify-between bg-white dark:bg-gray-800 rounded-lg border border-gray-200 dark:border-gray-700 p-4">
        <div className="text-sm font-medium text-gray-900 dark:text-white">
          Période d'analyse
        </div>
        <div className="flex space-x-2">
          <button
            onClick={() => setPeriod(30)}
            className={`px-4 py-2 rounded-md font-medium transition-colors ${
              period === 30
                ? 'bg-blue-600 text-white'
                : 'bg-gray-100 dark:bg-gray-700 text-gray-700 dark:text-gray-300 hover:bg-gray-200 dark:hover:bg-gray-600'
            }`}
          >
            30 jours
          </button>
          <button
            onClick={() => setPeriod(90)}
            className={`px-4 py-2 rounded-md font-medium transition-colors ${
              period === 90
                ? 'bg-blue-600 text-white'
                : 'bg-gray-100 dark:bg-gray-700 text-gray-700 dark:text-gray-300 hover:bg-gray-200 dark:hover:bg-gray-600'
            }`}
          >
            90 jours
          </button>
        </div>
      </div>

      {/* Earnings Chart */}
      <EarningsChart
        transactions={filteredTransactions}
        period={period}
        currentRate={currentRate || 0}
      />

      {/* Fiscal Export */}
      {showExport && (
        <FiscalExport
          transactions={transactions}
          userAddress={userAddress}
          onClose={() => setShowExport(false)}
        />
      )}

      {/* Summary Stats */}
      <div className="bg-white dark:bg-gray-800 rounded-lg border border-gray-200 dark:border-gray-700 p-6">
        <h2 className="text-lg font-semibold text-gray-900 dark:text-white mb-4">
          Statistiques {period} jours
        </h2>
        <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
          <div>
            <div className="text-sm text-gray-600 dark:text-gray-400">
              Missions complétées
            </div>
            <div className="text-2xl font-bold text-gray-900 dark:text-white mt-1">
              {filteredTransactions.filter((tx) => tx.type === 'mission_payment').length}
            </div>
          </div>
          <div>
            <div className="text-sm text-gray-600 dark:text-gray-400">
              Total DAOS reçus
            </div>
            <div className="text-2xl font-bold text-gray-900 dark:text-white mt-1">
              {(
                filteredTransactions.reduce(
                  (sum, tx) => sum + Number(tx.daosAmount),
                  0
                ) / 1e18
              ).toLocaleString('fr-FR', { maximumFractionDigits: 0 })}
            </div>
          </div>
          <div>
            <div className="text-sm text-gray-600 dark:text-gray-400">
              Total EUR
            </div>
            <div className="text-2xl font-bold text-green-600 dark:text-green-400 mt-1">
              {totalEarningsEur.toLocaleString('fr-FR', {
                style: 'currency',
                currency: 'EUR',
                maximumFractionDigits: 0,
              })}
            </div>
          </div>
          <div>
            <div className="text-sm text-gray-600 dark:text-gray-400">
              Taux moyen
            </div>
            <div className="text-2xl font-bold text-gray-900 dark:text-white mt-1">
              {filteredTransactions.length > 0
                ? (
                    filteredTransactions.reduce(
                      (sum, tx) => sum + tx.daosToEurRate,
                      0
                    ) / filteredTransactions.length
                  ).toFixed(4)
                : '0.0000'}
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
