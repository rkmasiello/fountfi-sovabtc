'use client';

import { useContractRead, useContractWrite, useWaitForTransactionReceipt } from 'wagmi';
import { BTC_VAULT_STRATEGY_ABI, BTC_VAULT_TOKEN_ABI } from '@/lib/abis';
import { useDeploymentConfig } from './useDeploymentConfig';
import { parseUnits, formatUnits } from 'viem';

export function useVaultContract() {
  const { contracts, isDeployed, collaterals } = useDeploymentConfig();

  // Strategy contract reads
  const { data: totalAssets } = useContractRead({
    address: contracts?.btcVaultStrategy as `0x${string}`,
    abi: BTC_VAULT_STRATEGY_ABI,
    functionName: 'totalAssets',
    enabled: isDeployed,
  });

  const { data: availableLiquidity } = useContractRead({
    address: contracts?.btcVaultStrategy as `0x${string}`,
    abi: BTC_VAULT_STRATEGY_ABI,
    functionName: 'availableLiquidity',
    enabled: isDeployed,
  });

  // Token contract reads
  const { data: totalSupply } = useContractRead({
    address: contracts?.btcVaultToken as `0x${string}`,
    abi: BTC_VAULT_TOKEN_ABI,
    functionName: 'totalSupply',
    enabled: isDeployed,
  });

  const { data: sharePrice } = useContractRead({
    address: contracts?.btcVaultToken as `0x${string}`,
    abi: BTC_VAULT_TOKEN_ABI,
    functionName: 'convertToAssets',
    args: [parseUnits('1', 8)],
    enabled: isDeployed,
  });

  // Deposit function
  const depositCollateral = (collateralAddress: string, amount: bigint) => {
    if (!contracts?.btcVaultStrategy) {
      throw new Error('Vault strategy not configured');
    }

    return {
      address: contracts.btcVaultStrategy as `0x${string}`,
      abi: BTC_VAULT_STRATEGY_ABI,
      functionName: 'depositCollateral',
      args: [collateralAddress, amount],
    };
  };

  // Check if collateral is supported
  const isSupportedCollateral = (address: string) => {
    return Object.values(collaterals || {}).some(
      c => c.address.toLowerCase() === address.toLowerCase()
    );
  };

  // Format values for display
  const formatAssets = (value: bigint | undefined) => {
    if (!value) return '0';
    return formatUnits(value, 8); // BTC decimals
  };

  return {
    // Contract addresses
    strategyAddress: contracts?.btcVaultStrategy,
    tokenAddress: contracts?.btcVaultToken,
    
    // Read values
    totalAssets,
    availableLiquidity,
    totalSupply,
    sharePrice,
    
    // Functions
    depositCollateral,
    isSupportedCollateral,
    
    // Helpers
    formatAssets,
    isDeployed,
  };
}