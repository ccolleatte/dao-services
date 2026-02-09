/**
 * VolatilityAlerts Component
 * Monitors portfolio volatility and suggests auto-conversion to stablecoins
 */

import { useEffect, useState } from 'react';
import { create } from 'zustand';
import { persist } from 'zustand/middleware';
import { Transaction } from './ConsultantDashboard.js';

export interface VolatilityAlertsProps {
  currentRate: number;
  transactions: Transaction[];
  portfolioValueEur: number;
}

// Alert types
interface Alert {
  id: string;
  type: 'volatility' | 'drop' | 'surge' | 'info';
  severity: 'low' | 'medium' | 'high';
  message: string;
  timestamp: Date;
  dismissed: boolean;
}

// Volatility threshold settings
interface VolatilitySettings {
  dropThreshold: number; // Percentage drop to trigger alert (default: 10%)
  timeWindow: number; // Hours to check (default: 24)
  autoConvertEnabled: boolean;
  autoConvertThreshold: number; // Percentage drop to auto-convert (default: 15%)
  dismissedAlerts: string[];
}

// Zustand store for volatility settings and alerts
interface VolatilityStore {
  settings: VolatilitySettings;
  alerts: Alert[];
  updateSettings: (settings: Partial<VolatilitySettings>) => void;
  addAlert: (alert: Omit<Alert, 'id' | 'timestamp' | 'dismissed'>) => void;
  dismissAlert: (id: string) => void;
  clearAlerts: () => void;
}

const useVolatilityStore = create<VolatilityStore>()(
  persist(
    (set) => ({
      settings: {
        dropThreshold: 10,
        timeWindow: 24,
        autoConvertEnabled: false,
        autoConvertThreshold: 15,
        dismissedAlerts: [],
      },
      alerts: [],
      updateSettings: (newSettings) =>
        set((state) => ({
          settings: { ...state.settings, ...newSettings },
        })),
      addAlert: (alert) =>
        set((state) => ({
          alerts: [
            ...state.alerts,
            {
              ...alert,
              id: `alert-${Date.now()}-${Math.random().toString(36).substr(2, 9)}`,
              timestamp: new Date(),
              dismissed: false,
            },
          ],
        })),
      dismissAlert: (id) =>
        set((state) => ({
          alerts: state.alerts.map((alert) =>
            alert.id === id ? { ...alert, dismissed: true } : alert
          ),
        })),
      clearAlerts: () => set({ alerts: [] }),
    }),
    {
      name: 'volatility-settings',
    }
  )
);

export function VolatilityAlerts({
  currentRate,
  transactions,
  portfolioValueEur,
}: VolatilityAlertsProps) {
  const { settings, alerts, updateSettings, addAlert, dismissAlert } =
    useVolatilityStore();

  const [showSettings, setShowSettings] = useState(false);
  const [historicalRates, setHistoricalRates] = useState<Array<{ rate: number; timestamp: Date }>>([]);

  // Track historical rates
  useEffect(() => {
    if (currentRate > 0) {
      setHistoricalRates((prev) => {
        const now = new Date();
        const newRates = [...prev, { rate: currentRate, timestamp: now }];

        // Keep only rates within time window
        const cutoff = new Date(now.getTime() - settings.timeWindow * 60 * 60 * 1000);
        return newRates.filter((r) => r.timestamp > cutoff);
      });
    }
  }, [currentRate, settings.timeWindow]);

  // Check volatility
  useEffect(() => {
    if (historicalRates.length < 2) return;

    const oldest = historicalRates[0];
    const latest = historicalRates[historicalRates.length - 1];

    const percentageChange =
      ((latest.rate - oldest.rate) / oldest.rate) * 100;

    // Drop alert
    if (percentageChange <= -settings.dropThreshold) {
      const existingAlert = alerts.find(
        (a) => a.type === 'drop' && !a.dismissed &&
        new Date().getTime() - a.timestamp.getTime() < 60 * 60 * 1000 // Within 1h
      );

      if (!existingAlert) {
        addAlert({
          type: 'drop',
          severity: Math.abs(percentageChange) >= 15 ? 'high' : 'medium',
          message: `Alerte volatilité : Baisse de ${Math.abs(percentageChange).toFixed(1)}% en ${settings.timeWindow}h. Portfolio: ${portfolioValueEur.toLocaleString('fr-FR', { style: 'currency', currency: 'EUR' })}`,
        });
      }
    }

    // Surge alert
    if (percentageChange >= 10) {
      const existingAlert = alerts.find(
        (a) => a.type === 'surge' && !a.dismissed &&
        new Date().getTime() - a.timestamp.getTime() < 60 * 60 * 1000
      );

      if (!existingAlert) {
        addAlert({
          type: 'surge',
          severity: 'low',
          message: `Opportunité : Hausse de ${percentageChange.toFixed(1)}% en ${settings.timeWindow}h. Envisagez de convertir une partie en EUR pour sécuriser vos gains.`,
        });
      }
    }
  }, [historicalRates, settings, portfolioValueEur]);

  // Active alerts (not dismissed)
  const activeAlerts = alerts.filter((a) => !a.dismissed);

  // Severity colors
  const getSeverityColor = (severity: Alert['severity']) => {
    switch (severity) {
      case 'high':
        return 'border-red-500 bg-red-50 dark:bg-red-900/20';
      case 'medium':
        return 'border-yellow-500 bg-yellow-50 dark:bg-yellow-900/20';
      case 'low':
        return 'border-blue-500 bg-blue-50 dark:bg-blue-900/20';
      default:
        return 'border-gray-300 bg-gray-50 dark:bg-gray-800';
    }
  };

  const getSeverityIcon = (severity: Alert['severity']) => {
    switch (severity) {
      case 'high':
        return (
          <svg className="w-5 h-5 text-red-600 dark:text-red-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z" />
          </svg>
        );
      case 'medium':
        return (
          <svg className="w-5 h-5 text-yellow-600 dark:text-yellow-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
          </svg>
        );
      case 'low':
        return (
          <svg className="w-5 h-5 text-blue-600 dark:text-blue-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
          </svg>
        );
    }
  };

  if (activeAlerts.length === 0 && !showSettings) {
    return null;
  }

  return (
    <div className="space-y-3">
      {/* Active Alerts */}
      {activeAlerts.map((alert) => (
        <div
          key={alert.id}
          className={`rounded-lg border-2 p-4 ${getSeverityColor(alert.severity)}`}
        >
          <div className="flex items-start justify-between">
            <div className="flex items-start space-x-3">
              {getSeverityIcon(alert.severity)}
              <div className="flex-1">
                <p className="text-sm font-medium text-gray-900 dark:text-white">
                  {alert.message}
                </p>
                {alert.type === 'drop' && (
                  <div className="mt-3 flex items-center space-x-2">
                    <button
                      onClick={() => {
                        // In production, this would trigger USDC conversion
                        alert('Conversion USDC : Fonctionnalité à implémenter avec smart contract HybridPaymentSplitter');
                        dismissAlert(alert.id);
                      }}
                      className="px-3 py-1.5 bg-blue-600 text-white text-xs rounded-md hover:bg-blue-700 font-medium transition-colors"
                    >
                      Convertir en USDC
                    </button>
                    <span className="text-xs text-gray-600 dark:text-gray-400">
                      Suggéré : Convertir 30-50% en stablecoin
                    </span>
                  </div>
                )}
                <p className="text-xs text-gray-500 dark:text-gray-400 mt-2">
                  {new Date(alert.timestamp).toLocaleString('fr-FR')}
                </p>
              </div>
            </div>
            <button
              onClick={() => dismissAlert(alert.id)}
              className="text-gray-400 hover:text-gray-600 dark:hover:text-gray-200 transition-colors ml-2"
            >
              <svg className="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
              </svg>
            </button>
          </div>
        </div>
      ))}

      {/* Settings Panel */}
      <div className="bg-white dark:bg-gray-800 rounded-lg border border-gray-200 dark:border-gray-700 p-4">
        <button
          onClick={() => setShowSettings(!showSettings)}
          className="flex items-center justify-between w-full text-sm font-medium text-gray-900 dark:text-white"
        >
          <span>⚙️ Configuration alertes volatilité</span>
          <svg
            className={`w-5 h-5 transition-transform ${showSettings ? 'rotate-180' : ''}`}
            fill="none"
            viewBox="0 0 24 24"
            stroke="currentColor"
          >
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 9l-7 7-7-7" />
          </svg>
        </button>

        {showSettings && (
          <div className="mt-4 space-y-4">
            {/* Drop Threshold */}
            <div>
              <label className="block text-sm text-gray-700 dark:text-gray-300 mb-2">
                Seuil d'alerte baisse : {settings.dropThreshold}%
              </label>
              <input
                type="range"
                min="5"
                max="25"
                step="1"
                value={settings.dropThreshold}
                onChange={(e) =>
                  updateSettings({ dropThreshold: Number(e.target.value) })
                }
                className="w-full"
              />
              <div className="flex justify-between text-xs text-gray-500 dark:text-gray-400 mt-1">
                <span>5%</span>
                <span>25%</span>
              </div>
            </div>

            {/* Time Window */}
            <div>
              <label className="block text-sm text-gray-700 dark:text-gray-300 mb-2">
                Fenêtre temporelle : {settings.timeWindow}h
              </label>
              <select
                value={settings.timeWindow}
                onChange={(e) =>
                  updateSettings({ timeWindow: Number(e.target.value) })
                }
                className="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-md shadow-sm focus:outline-none focus:ring-blue-500 focus:border-blue-500 dark:bg-gray-700 dark:text-white text-sm"
              >
                <option value="6">6 heures</option>
                <option value="12">12 heures</option>
                <option value="24">24 heures</option>
                <option value="48">48 heures</option>
                <option value="72">72 heures</option>
              </select>
            </div>

            {/* Auto-Convert (Future Feature) */}
            <div className="bg-gray-50 dark:bg-gray-700/50 rounded-lg p-3">
              <div className="flex items-center justify-between mb-2">
                <label className="text-sm font-medium text-gray-700 dark:text-gray-300">
                  Auto-conversion USDC (bientôt)
                </label>
                <input
                  type="checkbox"
                  checked={settings.autoConvertEnabled}
                  onChange={(e) =>
                    updateSettings({ autoConvertEnabled: e.target.checked })
                  }
                  disabled
                  className="rounded text-blue-600 focus:ring-blue-500 disabled:opacity-50 disabled:cursor-not-allowed"
                />
              </div>
              <p className="text-xs text-gray-600 dark:text-gray-400">
                Conversion automatique vers USDC si baisse ≥ {settings.autoConvertThreshold}%
              </p>
            </div>

            {/* Stats */}
            <div className="pt-3 border-t border-gray-200 dark:border-gray-700">
              <div className="text-xs text-gray-600 dark:text-gray-400 space-y-1">
                <p>📊 Taux actuels trackés : {historicalRates.length}</p>
                <p>🔔 Alertes actives : {activeAlerts.length}</p>
                <p>✅ Alertes ignorées : {alerts.filter((a) => a.dismissed).length}</p>
              </div>
            </div>
          </div>
        )}
      </div>
    </div>
  );
}
