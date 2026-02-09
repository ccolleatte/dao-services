/**
 * Governance Page
 * Main page for DAO governance voting
 */

import { GovernanceVotingUI } from '../components/governance/GovernanceVotingUI.js';
import { VotingPowerCalculator } from '../components/governance/VotingPowerCalculator.js';
import { ethers } from 'ethers';
import { useState, useEffect } from 'react';

export default function GovernancePage() {
  const [provider, setProvider] = useState<ethers.Provider | null>(null);
  const [signer, setSigner] = useState<ethers.Signer | null>(null);
  const [account, setAccount] = useState<string | null>(null);
  const [showCalculator, setShowCalculator] = useState(false);

  // Initialize provider and signer
  useEffect(() => {
    const init = async () => {
      if (typeof window === 'undefined') return;

      // Check if MetaMask is installed
      if (!(window as any).ethereum) {
        console.error('MetaMask not installed');
        return;
      }

      // Create provider
      const web3Provider = new ethers.BrowserProvider((window as any).ethereum);
      setProvider(web3Provider);

      // Request account access
      try {
        const accounts = await (window as any).ethereum.request({
          method: 'eth_requestAccounts',
        });

        if (accounts.length > 0) {
          setAccount(accounts[0]);
          const web3Signer = await web3Provider.getSigner();
          setSigner(web3Signer);
        }
      } catch (error) {
        console.error('Error connecting wallet:', error);
      }
    };

    init();

    // Listen for account changes
    if ((window as any).ethereum) {
      (window as any).ethereum.on('accountsChanged', (accounts: string[]) => {
        if (accounts.length > 0) {
          setAccount(accounts[0]);
          // Re-initialize signer
          init();
        } else {
          setAccount(null);
          setSigner(null);
        }
      });
    }

    return () => {
      if ((window as any).ethereum) {
        (window as any).ethereum.removeAllListeners('accountsChanged');
      }
    };
  }, []);

  const contractAddress = process.env.NEXT_PUBLIC_DAO_GOVERNOR_ADDRESS || '';

  if (!provider) {
    return (
      <div className="min-h-screen bg-gray-50 dark:bg-gray-900 flex items-center justify-center">
        <div className="text-center">
          <h1 className="text-2xl font-bold text-gray-900 dark:text-white mb-4">
            Connecting to Ethereum...
          </h1>
          <div className="inline-block animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600"></div>
        </div>
      </div>
    );
  }

  if (!account) {
    return (
      <div className="min-h-screen bg-gray-50 dark:bg-gray-900 flex items-center justify-center">
        <div className="text-center max-w-md p-8 bg-white dark:bg-gray-800 rounded-lg border border-gray-200 dark:border-gray-700">
          <svg
            className="mx-auto h-12 w-12 text-gray-400 mb-4"
            fill="none"
            viewBox="0 0 24 24"
            stroke="currentColor"
          >
            <path
              strokeLinecap="round"
              strokeLinejoin="round"
              strokeWidth={2}
              d="M12 15v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2zm10-10V7a4 4 0 00-8 0v4h8z"
            />
          </svg>
          <h1 className="text-2xl font-bold text-gray-900 dark:text-white mb-2">
            Connect Your Wallet
          </h1>
          <p className="text-gray-600 dark:text-gray-400 mb-6">
            Please connect your MetaMask wallet to access DAO governance
          </p>
          <button
            onClick={async () => {
              try {
                await (window as any).ethereum.request({
                  method: 'eth_requestAccounts',
                });
              } catch (error) {
                console.error('Error connecting wallet:', error);
              }
            }}
            className="px-6 py-3 bg-blue-600 text-white rounded-md hover:bg-blue-700 font-medium transition-colors"
          >
            Connect Wallet
          </button>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gray-50 dark:bg-gray-900">
      {/* Top Bar */}
      <div className="bg-white dark:bg-gray-800 border-b border-gray-200 dark:border-gray-700">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-4">
          <div className="flex items-center justify-between">
            <div>
              <h1 className="text-xl font-bold text-gray-900 dark:text-white">
                DAO Governance
              </h1>
            </div>

            <div className="flex items-center space-x-4">
              <button
                onClick={() => setShowCalculator(!showCalculator)}
                className="px-4 py-2 text-sm font-medium text-gray-700 dark:text-gray-300 bg-gray-100 dark:bg-gray-700 rounded-md hover:bg-gray-200 dark:hover:bg-gray-600 transition-colors"
              >
                {showCalculator ? 'Hide Calculator' : 'Show Calculator'}
              </button>

              <div className="px-4 py-2 bg-blue-50 dark:bg-blue-900/20 text-blue-700 dark:text-blue-300 rounded-md text-sm font-medium">
                {account.slice(0, 6)}...{account.slice(-4)}
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* Calculator Modal */}
      {showCalculator && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4">
          <div className="max-w-2xl w-full">
            <div className="relative">
              <button
                onClick={() => setShowCalculator(false)}
                className="absolute -top-2 -right-2 bg-white dark:bg-gray-800 rounded-full p-2 shadow-lg hover:bg-gray-100 dark:hover:bg-gray-700 transition-colors z-10"
              >
                <svg
                  className="w-6 h-6 text-gray-600 dark:text-gray-300"
                  fill="none"
                  viewBox="0 0 24 24"
                  stroke="currentColor"
                >
                  <path
                    strokeLinecap="round"
                    strokeLinejoin="round"
                    strokeWidth={2}
                    d="M6 18L18 6M6 6l12 12"
                  />
                </svg>
              </button>
              <VotingPowerCalculator
                currentRank={0}
                currentTokens={ethers.parseEther('100')}
                onCalculate={(power) => console.log('Voting power calculated:', power)}
              />
            </div>
          </div>
        </div>
      )}

      {/* Main Content */}
      <GovernanceVotingUI
        contractAddress={contractAddress}
        provider={provider}
        signer={signer}
      />
    </div>
  );
}
