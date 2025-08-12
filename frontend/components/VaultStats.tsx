'use client';

import { useReadContract, useAccount } from 'wagmi';
import { formatUnits } from 'viem';
import { CONTRACTS } from '@/lib/contracts';
import { VAULT_ABI } from '@/lib/abis';

export function VaultStats() {
  const { address } = useAccount();

  const { data: totalAssets } = useReadContract({
    address: CONTRACTS.vault as `0x${string}`,
    abi: VAULT_ABI,
    functionName: 'totalAssets',
  });

  const { data: totalSupply } = useReadContract({
    address: CONTRACTS.vault as `0x${string}`,
    abi: VAULT_ABI,
    functionName: 'totalSupply',
  });

  const { data: userBalance } = useReadContract({
    address: CONTRACTS.vault as `0x${string}`,
    abi: VAULT_ABI,
    functionName: 'balanceOf',
    args: address ? [address] : undefined,
  });

  const { data: sharePrice } = useReadContract({
    address: CONTRACTS.vault as `0x${string}`,
    abi: VAULT_ABI,
    functionName: 'sharePrice',
  });

  const tvl = totalAssets ? Number(formatUnits(totalAssets, 8)) : 0;
  const shares = totalSupply ? Number(formatUnits(totalSupply, 18)) : 0;
  const userShares = userBalance ? Number(formatUnits(userBalance, 18)) : 0;
  const price = sharePrice ? Number(formatUnits(sharePrice, 18)) : 1;

  return (
    <div className="grid grid-cols-1 md:grid-cols-4 gap-6 mb-8">
      <div className="bg-white rounded-lg shadow p-6">
        <h3 className="text-sm text-gray-500 mb-1">Total Value Locked</h3>
        <p className="text-2xl font-bold text-gray-900">{tvl.toFixed(4)} BTC</p>
      </div>
      
      <div className="bg-white rounded-lg shadow p-6">
        <h3 className="text-sm text-gray-500 mb-1">Total Shares</h3>
        <p className="text-2xl font-bold text-gray-900">{shares.toFixed(2)} stSOVABTC</p>
      </div>
      
      <div className="bg-white rounded-lg shadow p-6">
        <h3 className="text-sm text-gray-500 mb-1">Share Price</h3>
        <p className="text-2xl font-bold text-gray-900">{price.toFixed(6)} BTC</p>
      </div>
      
      <div className="bg-white rounded-lg shadow p-6">
        <h3 className="text-sm text-gray-500 mb-1">Your Balance</h3>
        <p className="text-2xl font-bold text-gray-900">{userShares.toFixed(4)} stSOVABTC</p>
        <p className="text-sm text-gray-500">{(userShares * price).toFixed(6)} BTC value</p>
      </div>
    </div>
  );
}