/**
 * EarningsChart Component
 * Visualizes consultant earnings over time using Recharts
 */

import { useMemo } from 'react';
import {
  LineChart,
  Line,
  BarChart,
  Bar,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  Legend,
  ResponsiveContainer,
  TooltipProps,
} from 'recharts';
import { Transaction } from './ConsultantDashboard.js';
import { format } from 'date-fns';
import { fr } from 'date-fns/locale';

export interface EarningsChartProps {
  transactions: Transaction[];
  period: 30 | 90;
  currentRate: number;
}

interface ChartDataPoint {
  date: string;
  daos: number;
  eur: number;
  cumulativeEur: number;
  rate: number;
}

export function EarningsChart({ transactions, period, currentRate }: EarningsChartProps) {
  // Process transactions into chart data points
  const chartData = useMemo(() => {
    // Sort transactions by date
    const sorted = [...transactions].sort(
      (a, b) => a.date.getTime() - b.date.getTime()
    );

    // Group by day
    const dailyMap = new Map<string, { daos: number; eur: number; rate: number }>();

    sorted.forEach((tx) => {
      const dateKey = format(tx.date, 'yyyy-MM-dd');
      const existing = dailyMap.get(dateKey) || { daos: 0, eur: 0, rate: 0 };

      dailyMap.set(dateKey, {
        daos: existing.daos + Number(tx.daosAmount) / 1e18,
        eur: existing.eur + tx.eurValue,
        rate: tx.daosToEurRate, // Use latest rate for the day
      });
    });

    // Convert to array and calculate cumulative
    let cumulative = 0;
    const data: ChartDataPoint[] = Array.from(dailyMap.entries())
      .map(([date, values]) => {
        cumulative += values.eur;
        return {
          date: format(new Date(date), 'd MMM', { locale: fr }),
          daos: Math.round(values.daos),
          eur: Math.round(values.eur),
          cumulativeEur: Math.round(cumulative),
          rate: values.rate,
        };
      })
      .slice(-period); // Last N days

    return data;
  }, [transactions, period]);

  // Custom tooltip
  const CustomTooltip = ({ active, payload }: TooltipProps<number, string>) => {
    if (!active || !payload || !payload.length) {
      return null;
    }

    const data = payload[0].payload as ChartDataPoint;

    return (
      <div className="bg-white dark:bg-gray-800 border border-gray-200 dark:border-gray-700 rounded-lg p-3 shadow-lg">
        <p className="text-sm font-medium text-gray-900 dark:text-white mb-2">
          {data.date}
        </p>
        <div className="space-y-1 text-sm">
          <p className="text-gray-600 dark:text-gray-400">
            DAOS:{' '}
            <span className="font-medium text-blue-600 dark:text-blue-400">
              {data.daos.toLocaleString('fr-FR')}
            </span>
          </p>
          <p className="text-gray-600 dark:text-gray-400">
            EUR:{' '}
            <span className="font-medium text-green-600 dark:text-green-400">
              {data.eur.toLocaleString('fr-FR', {
                style: 'currency',
                currency: 'EUR',
                maximumFractionDigits: 0,
              })}
            </span>
          </p>
          <p className="text-gray-600 dark:text-gray-400">
            Taux:{' '}
            <span className="font-medium text-gray-900 dark:text-white">
              {data.rate.toFixed(4)}
            </span>
          </p>
          <p className="text-gray-600 dark:text-gray-400 border-t border-gray-200 dark:border-gray-700 pt-1 mt-1">
            Cumulé:{' '}
            <span className="font-medium text-green-600 dark:text-green-400">
              {data.cumulativeEur.toLocaleString('fr-FR', {
                style: 'currency',
                currency: 'EUR',
                maximumFractionDigits: 0,
              })}
            </span>
          </p>
        </div>
      </div>
    );
  };

  if (chartData.length === 0) {
    return (
      <div className="bg-white dark:bg-gray-800 rounded-lg border border-gray-200 dark:border-gray-700 p-6">
        <h2 className="text-lg font-semibold text-gray-900 dark:text-white mb-4">
          Évolution des revenus
        </h2>
        <div className="flex flex-col items-center justify-center h-64 text-gray-500 dark:text-gray-400">
          <svg
            className="w-16 h-16 mb-4"
            fill="none"
            viewBox="0 0 24 24"
            stroke="currentColor"
          >
            <path
              strokeLinecap="round"
              strokeLinejoin="round"
              strokeWidth={2}
              d="M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z"
            />
          </svg>
          <p className="text-sm">Aucune transaction pour cette période</p>
        </div>
      </div>
    );
  }

  return (
    <div className="bg-white dark:bg-gray-800 rounded-lg border border-gray-200 dark:border-gray-700 p-6">
      <h2 className="text-lg font-semibold text-gray-900 dark:text-white mb-4">
        Évolution des revenus ({period} jours)
      </h2>

      {/* Cumulative EUR Line Chart */}
      <div className="mb-8">
        <h3 className="text-sm font-medium text-gray-700 dark:text-gray-300 mb-3">
          Revenus cumulés (EUR)
        </h3>
        <ResponsiveContainer width="100%" height={250}>
          <LineChart data={chartData}>
            <CartesianGrid
              strokeDasharray="3 3"
              stroke="currentColor"
              className="text-gray-200 dark:text-gray-700"
            />
            <XAxis
              dataKey="date"
              stroke="currentColor"
              className="text-gray-600 dark:text-gray-400"
              style={{ fontSize: '12px' }}
            />
            <YAxis
              stroke="currentColor"
              className="text-gray-600 dark:text-gray-400"
              style={{ fontSize: '12px' }}
              tickFormatter={(value) =>
                `${(value / 1000).toFixed(0)}k€`
              }
            />
            <Tooltip content={<CustomTooltip />} />
            <Legend
              wrapperStyle={{ fontSize: '14px' }}
              iconType="line"
            />
            <Line
              type="monotone"
              dataKey="cumulativeEur"
              stroke="#10b981"
              strokeWidth={2}
              name="Cumulé EUR"
              dot={{ fill: '#10b981', r: 4 }}
              activeDot={{ r: 6 }}
            />
          </LineChart>
        </ResponsiveContainer>
      </div>

      {/* Daily DAOS + EUR Bar Chart */}
      <div>
        <h3 className="text-sm font-medium text-gray-700 dark:text-gray-300 mb-3">
          Revenus quotidiens (DAOS + EUR)
        </h3>
        <ResponsiveContainer width="100%" height={250}>
          <BarChart data={chartData}>
            <CartesianGrid
              strokeDasharray="3 3"
              stroke="currentColor"
              className="text-gray-200 dark:text-gray-700"
            />
            <XAxis
              dataKey="date"
              stroke="currentColor"
              className="text-gray-600 dark:text-gray-400"
              style={{ fontSize: '12px' }}
            />
            <YAxis
              yAxisId="left"
              stroke="currentColor"
              className="text-gray-600 dark:text-gray-400"
              style={{ fontSize: '12px' }}
              label={{
                value: 'DAOS',
                angle: -90,
                position: 'insideLeft',
                style: { fontSize: '12px' },
              }}
            />
            <YAxis
              yAxisId="right"
              orientation="right"
              stroke="currentColor"
              className="text-gray-600 dark:text-gray-400"
              style={{ fontSize: '12px' }}
              label={{
                value: 'EUR',
                angle: 90,
                position: 'insideRight',
                style: { fontSize: '12px' },
              }}
              tickFormatter={(value) => `${value}€`}
            />
            <Tooltip content={<CustomTooltip />} />
            <Legend
              wrapperStyle={{ fontSize: '14px' }}
              iconType="rect"
            />
            <Bar
              yAxisId="left"
              dataKey="daos"
              fill="#3b82f6"
              name="DAOS"
              radius={[4, 4, 0, 0]}
            />
            <Bar
              yAxisId="right"
              dataKey="eur"
              fill="#10b981"
              name="EUR"
              radius={[4, 4, 0, 0]}
            />
          </BarChart>
        </ResponsiveContainer>
      </div>

      {/* Trend Indicators */}
      <div className="mt-6 pt-6 border-t border-gray-200 dark:border-gray-700">
        <h3 className="text-sm font-medium text-gray-700 dark:text-gray-300 mb-3">
          Tendances
        </h3>
        <div className="grid grid-cols-3 gap-4">
          <div className="bg-blue-50 dark:bg-blue-900/20 rounded-lg p-3">
            <div className="text-xs text-blue-600 dark:text-blue-400 font-medium mb-1">
              Meilleure journée
            </div>
            <div className="text-lg font-bold text-blue-900 dark:text-blue-300">
              {chartData.reduce((max, d) => (d.eur > max.eur ? d : max), chartData[0])?.eur.toLocaleString('fr-FR', {
                style: 'currency',
                currency: 'EUR',
                maximumFractionDigits: 0,
              })}
            </div>
            <div className="text-xs text-blue-600 dark:text-blue-400 mt-1">
              {chartData.reduce((max, d) => (d.eur > max.eur ? d : max), chartData[0])?.date}
            </div>
          </div>

          <div className="bg-green-50 dark:bg-green-900/20 rounded-lg p-3">
            <div className="text-xs text-green-600 dark:text-green-400 font-medium mb-1">
              Moyenne journalière
            </div>
            <div className="text-lg font-bold text-green-900 dark:text-green-300">
              {(
                chartData.reduce((sum, d) => sum + d.eur, 0) / chartData.length
              ).toLocaleString('fr-FR', {
                style: 'currency',
                currency: 'EUR',
                maximumFractionDigits: 0,
              })}
            </div>
            <div className="text-xs text-green-600 dark:text-green-400 mt-1">
              sur {chartData.length} jours
            </div>
          </div>

          <div className="bg-purple-50 dark:bg-purple-900/20 rounded-lg p-3">
            <div className="text-xs text-purple-600 dark:text-purple-400 font-medium mb-1">
              Taux actuel
            </div>
            <div className="text-lg font-bold text-purple-900 dark:text-purple-300">
              {currentRate.toFixed(4)}
            </div>
            <div className="text-xs text-purple-600 dark:text-purple-400 mt-1">
              EUR/DAOS
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
