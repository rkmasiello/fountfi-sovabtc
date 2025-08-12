import { getDefaultConfig } from '@rainbow-me/rainbowkit';
import { baseSepolia } from 'wagmi/chains';

export const config = getDefaultConfig({
  appName: 'Multi-Collateral BTC Vault',
  projectId: process.env.NEXT_PUBLIC_WALLETCONNECT_PROJECT_ID || 'fbdc02ca1d45b13459b8815d9344ee5a',
  chains: [baseSepolia],
  ssr: true,
});