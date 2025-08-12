'use client';

import { WalletConnect } from '@/components/WalletConnect';
import { VaultStats } from '@/components/VaultStats';
import { DepositForm } from '@/components/DepositForm';
import { RedemptionQueue } from '@/components/RedemptionQueue';
import { AdminPanel } from '@/components/AdminPanel';
import OnboardingWizard from '@/components/OnboardingWizard';
import { useAccount } from 'wagmi';
import { useState, useEffect } from 'react';

export default function Home() {
  const { isConnected, address } = useAccount();
  const [showAdmin, setShowAdmin] = useState(false);
  const [showOnboarding, setShowOnboarding] = useState(false);

  useEffect(() => {
    if (isConnected && address) {
      const hasCompleted = localStorage.getItem(`onboarding_completed_${address}`);
      if (!hasCompleted) {
        setShowOnboarding(true);
      }
    }
  }, [isConnected, address]);

  return (
    <div className="min-h-screen bg-gray-50">
      {/* Onboarding Wizard */}
      {showOnboarding && (
        <OnboardingWizard 
          onComplete={() => setShowOnboarding(false)}
          onSkip={() => setShowOnboarding(false)}
        />
      )}
      
      <header className="bg-white shadow-sm border-b">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-4">
          <div className="flex justify-between items-center">
            <div>
              <h1 className="text-2xl font-bold text-gray-900">Multi-Collateral BTC Vault</h1>
              <p className="text-sm text-gray-600">Deposit BTC collateral • Earn yield • Redeem in sovaBTC</p>
            </div>
            <WalletConnect />
          </div>
        </div>
      </header>

      <main className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        {!isConnected ? (
          <div className="bg-white rounded-lg shadow p-12 text-center">
            <h2 className="text-2xl font-semibold text-gray-900 mb-4">
              Welcome to the Multi-Collateral BTC Vault
            </h2>
            <p className="text-gray-600 mb-8">
              Connect your wallet to start depositing BTC collateral and earning yield
            </p>
            <div className="inline-block">
              <WalletConnect />
            </div>
          </div>
        ) : (
          <>
            <VaultStats />
            
            {/* Admin Panel Toggle */}
            <div className="mb-4 flex justify-end">
              <button
                onClick={() => setShowAdmin(!showAdmin)}
                className="px-4 py-2 bg-purple-600 text-white rounded-md hover:bg-purple-700 text-sm"
              >
                {showAdmin ? 'Hide Admin Panel' : 'Show Admin Panel'}
              </button>
            </div>

            {/* Admin Panel */}
            {showAdmin && (
              <div className="mb-8">
                <AdminPanel />
              </div>
            )}
            
            <div className="grid grid-cols-1 lg:grid-cols-2 gap-8">
              <DepositForm />
              <RedemptionQueue />
            </div>

            <div className="mt-8 bg-blue-50 border border-blue-200 rounded-lg p-4">
              <h3 className="text-sm font-semibold text-blue-900 mb-2">Testnet Information</h3>
              <p className="text-sm text-blue-800">
                This is deployed on Base Sepolia testnet. Use the "Mint Test Tokens" button to get test BTC tokens.
                Redemption period is set to 1 day for testing (14 days on mainnet).
              </p>
            </div>
          </>
        )}
      </main>

      <footer className="bg-white border-t mt-12">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-6">
          <div className="flex justify-between items-center text-sm text-gray-600">
            <div>
              <p>Multi-Collateral BTC Vault • Base Sepolia</p>
              <p className="text-xs mt-1">
                Vault: {`0x73E2...fab7`} • 
                <a 
                  href="https://sepolia.basescan.org/address/0x73E27097221d4d9D5893a83350dC7A967b46fab7" 
                  target="_blank" 
                  rel="noopener noreferrer"
                  className="ml-1 text-blue-600 hover:underline"
                >
                  View on BaseScan
                </a>
              </p>
            </div>
            <div className="text-right">
              <p>Built with FountFi Protocol</p>
              <p className="text-xs mt-1">
                <a 
                  href="https://github.com/fountfi/sovabtc" 
                  target="_blank" 
                  rel="noopener noreferrer"
                  className="text-blue-600 hover:underline"
                >
                  Documentation
                </a>
              </p>
            </div>
          </div>
        </div>
      </footer>
    </div>
  );
}