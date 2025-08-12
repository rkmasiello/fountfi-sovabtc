'use client';

import Link from 'next/link';
import { ConnectButton } from '@rainbow-me/rainbowkit';
import { Wallet, Vault, Settings, BarChart3, Bell, Zap, ArrowLeftRight, Briefcase, Shield } from 'lucide-react';
import { usePathname } from 'next/navigation';
import { NetworkSwitcher } from './NetworkSwitcher';
import { WalletButton } from './WalletButton';
import { useWalletDetection } from '@/hooks/useWalletDetection';

export function Navigation() {
  const pathname = usePathname();
  const { installedCount } = useWalletDetection();

  const navItems = [
    { href: '/dashboard', label: 'Dashboard', icon: BarChart3 },
    { href: '/vault', label: 'Vault', icon: Vault },
    { href: '/portfolio', label: 'Portfolio', icon: Briefcase },
    { href: '/staking', label: 'Staking', icon: Zap },
    { href: '/bridge', label: 'Bridge', icon: ArrowLeftRight },
    { href: '/admin', label: 'Admin', icon: Settings },
  ];

  return (
    <header className="relative z-50 border-b border-white/10 backdrop-blur-xl bg-white/5 shadow-[0_8px_32px_0_rgba(31,38,135,0.37)]">
      <div className="container mx-auto px-6 py-4">
        <div className="flex items-center justify-between">
          {/* Logo with 3D Effect */}
          <div className="flex items-center space-x-3">
            <div className="relative">
              <div className="w-10 h-10 bg-gradient-to-r from-orange-500 to-yellow-500 rounded-xl flex items-center justify-center shadow-[0_8px_25px_0_rgba(251,146,60,0.4)] transform hover:scale-110 transition-all duration-300">
                <span className="text-white font-bold">₿</span>
              </div>
              <div className="absolute inset-0 bg-gradient-to-r from-orange-500 to-yellow-500 rounded-xl blur-lg opacity-30 -z-10"></div>
            </div>
            <div>
              <h1 className="text-xl font-semibold text-white drop-shadow-lg">BTC Vault</h1>
              <p className="text-xs text-white/60">Multi-Collateral Bitcoin Yield</p>
            </div>
          </div>

          {/* Navigation with Glass Effect */}
          <nav className="hidden md:flex items-center space-x-2 bg-white/5 backdrop-blur-md rounded-2xl p-2 border border-white/10">
            {navItems.map((item) => {
              const Icon = item.icon;
              const isActive = pathname === item.href;
              
              return (
                <Link
                  key={item.href}
                  href={item.href}
                  className={`flex items-center space-x-2 px-4 py-2 rounded-xl transition-all duration-300 ${
                    isActive 
                      ? 'bg-white/20 text-white shadow-[0_4px_15px_0_rgba(31,38,135,0.4)] backdrop-blur-lg border border-white/20' 
                      : 'text-white/70 hover:bg-white/10 hover:text-white'
                  }`}
                >
                  <Icon className="w-4 h-4" />
                  <span className="font-medium">{item.label}</span>
                </Link>
              );
            })}
          </nav>

          {/* Right Side with Enhanced Glass Cards */}
          <div className="flex items-center space-x-3">
            {/* Network Switcher */}
            <NetworkSwitcher />

            {/* Glass Icon Buttons */}
            <button className="bg-white/10 backdrop-blur-md border-white/20 text-white hover:bg-white/15 shadow-[0_4px_15px_0_rgba(31,38,135,0.2)] rounded-xl w-10 h-10 p-0 border flex items-center justify-center">
              <Bell className="w-4 h-4" />
            </button>

            <button className="bg-white/10 backdrop-blur-md border-white/20 text-white hover:bg-white/15 shadow-[0_4px_15px_0_rgba(31,38,135,0.2)] rounded-xl w-10 h-10 p-0 border flex items-center justify-center">
              <Settings className="w-4 h-4" />
            </button>

            {/* Wallet Connection with RainbowKit */}
            <ConnectButton.Custom>
              {({
                account,
                chain,
                openAccountModal,
                openChainModal,
                openConnectModal,
                mounted,
              }) => {
                const ready = mounted;
                const connected = ready && account && chain;

                return (
                  <div
                    {...(!ready && {
                      'aria-hidden': true,
                      'style': {
                        opacity: 0,
                        pointerEvents: 'none',
                        userSelect: 'none',
                      },
                    })}
                  >
                    {(() => {
                      if (!connected) {
                        return (
                          <button 
                            onClick={openConnectModal}
                            className="relative bg-gradient-to-r from-blue-600 via-purple-600 to-blue-600 bg-size-200 bg-pos-0 hover:bg-pos-100 transition-all duration-500 text-white shadow-[0_8px_25px_0_rgba(59,130,246,0.4)] hover:shadow-[0_12px_35px_0_rgba(59,130,246,0.6)] transform hover:scale-105 rounded-xl border border-white/20 backdrop-blur-sm px-4 py-2 flex items-center group"
                          >
                            <Wallet className="w-4 h-4 mr-2" />
                            <span className="font-semibold">Connect Wallet</span>
                            {installedCount > 0 && (
                              <div className="absolute -top-2 -right-2">
                                <div className="relative">
                                  <div className="absolute inset-0 bg-green-500 rounded-full blur animate-pulse"></div>
                                  <div className="relative bg-green-500 text-white text-xs font-bold rounded-full w-5 h-5 flex items-center justify-center">
                                    {installedCount}
                                  </div>
                                </div>
                              </div>
                            )}
                            <div className="absolute inset-0 rounded-xl bg-gradient-to-r from-blue-600/20 via-purple-600/20 to-blue-600/20 blur-xl group-hover:blur-2xl transition-all duration-500 -z-10"></div>
                          </button>
                        );
                      }

                      return <WalletButton />;
                    })()}
                  </div>
                );
              }}
            </ConnectButton.Custom>
          </div>
        </div>
      </div>
    </header>
  );
}