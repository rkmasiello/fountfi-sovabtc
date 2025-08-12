'use client';

import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { WagmiProvider } from 'wagmi';
import { RainbowKitProvider, darkTheme, Theme } from '@rainbow-me/rainbowkit';
import { config } from '@/lib/wagmi';
import '@rainbow-me/rainbowkit/styles.css';
import merge from 'lodash.merge';

const queryClient = new QueryClient();

// Custom glassmorphism theme for RainbowKit
const customTheme = merge(darkTheme(), {
  colors: {
    accentColor: 'linear-gradient(135deg, #F97316 0%, #FCD34D 100%)', // Orange to yellow gradient
    accentColorForeground: '#FFFFFF',
    actionButtonBorder: 'rgba(255, 255, 255, 0.1)',
    actionButtonBorderMobile: 'rgba(255, 255, 255, 0.1)',
    actionButtonSecondaryBackground: 'rgba(255, 255, 255, 0.08)',
    closeButton: 'rgba(255, 255, 255, 0.7)',
    closeButtonBackground: 'rgba(255, 255, 255, 0.08)',
    connectButtonBackground: '#1E293B',
    connectButtonBackgroundError: '#EF4444',
    connectButtonInnerBackground: 'linear-gradient(135deg, #3B82F6 0%, #8B5CF6 100%)',
    connectButtonText: '#FFFFFF',
    connectButtonTextError: '#FFFFFF',
    connectionIndicator: '#10B981',
    error: '#EF4444',
    generalBorder: 'rgba(255, 255, 255, 0.1)',
    generalBorderDim: 'rgba(255, 255, 255, 0.05)',
    menuItemBackground: 'rgba(255, 255, 255, 0.08)',
    modalBackdrop: 'rgba(0, 0, 0, 0.5)',
    modalBackground: 'rgba(30, 41, 59, 0.95)',
    modalBorder: 'rgba(255, 255, 255, 0.1)',
    modalText: 'rgba(255, 255, 255, 0.87)',
    modalTextDim: 'rgba(255, 255, 255, 0.6)',
    modalTextSecondary: 'rgba(255, 255, 255, 0.6)',
    profileAction: 'rgba(255, 255, 255, 0.08)',
    profileActionHover: 'rgba(255, 255, 255, 0.12)',
    profileForeground: 'rgba(30, 41, 59, 0.95)',
    selectedOptionBorder: 'rgba(59, 130, 246, 0.5)',
    standby: '#FCD34D',
  },
  fonts: {
    body: 'Inter, sans-serif',
  },
  radii: {
    actionButton: '12px',
    connectButton: '12px',
    menuButton: '12px',
    modal: '16px',
    modalMobile: '16px',
  },
  shadows: {
    connectButton: '0 8px 25px 0 rgba(59, 130, 246, 0.4)',
    dialog: '0 8px 32px 0 rgba(31, 38, 135, 0.37)',
    profileDetailsAction: '0 4px 15px 0 rgba(31, 38, 135, 0.2)',
    selectedOption: '0 4px 15px 0 rgba(59, 130, 246, 0.4)',
    selectedWallet: '0 4px 15px 0 rgba(59, 130, 246, 0.4)',
    walletLogo: '0 4px 15px 0 rgba(31, 38, 135, 0.2)',
  },
  blurs: {
    modalOverlay: 'blur(8px)',
  },
} as Theme);

export function Providers({ children }: { children: React.ReactNode }) {
  return (
    <WagmiProvider config={config}>
      <QueryClientProvider client={queryClient}>
        <RainbowKitProvider 
          theme={customTheme}
          modalSize="wide"
          showRecentTransactions={true}
        >
          {children}
        </RainbowKitProvider>
      </QueryClientProvider>
    </WagmiProvider>
  );
}