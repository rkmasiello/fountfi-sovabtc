'use client';

import { useState } from 'react';
import { useAccount, useWriteContract, useReadContract, useWaitForTransactionReceipt } from 'wagmi';
import { parseUnits, formatUnits } from 'viem';
import { CONTRACTS } from '@/lib/contracts';
import { VAULT_ABI, ERC20_ABI } from '@/lib/abis';

const COLLATERAL_TOKENS = [
  { symbol: 'WBTC', address: CONTRACTS.wbtc, decimals: 8 },
  { symbol: 'TBTC', address: CONTRACTS.tbtc, decimals: 8 },
  { symbol: 'sovaBTC', address: CONTRACTS.sovaBTC, decimals: 8 },
];

export function DepositForm() {
  const { address } = useAccount();
  const [selectedToken, setSelectedToken] = useState(COLLATERAL_TOKENS[0]);
  const [amount, setAmount] = useState('');
  const [isApproving, setIsApproving] = useState(false);

  const { writeContract: approve, data: approveHash } = useWriteContract();
  const { writeContract: deposit, data: depositHash } = useWriteContract();

  const { isLoading: isApprovalPending } = useWaitForTransactionReceipt({
    hash: approveHash,
  });

  const { isLoading: isDepositPending } = useWaitForTransactionReceipt({
    hash: depositHash,
  });

  const { data: tokenBalance } = useReadContract({
    address: selectedToken.address as `0x${string}`,
    abi: ERC20_ABI,
    functionName: 'balanceOf',
    args: address ? [address] : undefined,
  });

  const { data: allowance } = useReadContract({
    address: selectedToken.address as `0x${string}`,
    abi: ERC20_ABI,
    functionName: 'allowance',
    args: address ? [address, CONTRACTS.vault as `0x${string}`] : undefined,
  });

  const handleMint = async () => {
    if (!address) return;
    
    const mintAmount = parseUnits('1', selectedToken.decimals);
    await approve({
      address: selectedToken.address as `0x${string}`,
      abi: ERC20_ABI,
      functionName: 'mint',
      args: [mintAmount],
    });
  };

  const handleApprove = async () => {
    if (!amount || !address) return;
    
    setIsApproving(true);
    const amountInWei = parseUnits(amount, selectedToken.decimals);
    
    await approve({
      address: selectedToken.address as `0x${string}`,
      abi: ERC20_ABI,
      functionName: 'approve',
      args: [CONTRACTS.vault as `0x${string}`, amountInWei],
    });
  };

  const handleDeposit = async () => {
    if (!amount || !address) return;
    
    const amountInWei = parseUnits(amount, selectedToken.decimals);
    
    await deposit({
      address: CONTRACTS.vault as `0x${string}`,
      abi: VAULT_ABI,
      functionName: 'deposit',
      args: [selectedToken.address as `0x${string}`, amountInWei, address],
    });
    
    setAmount('');
    setIsApproving(false);
  };

  const balance = tokenBalance ? Number(formatUnits(tokenBalance, selectedToken.decimals)) : 0;
  const approved = allowance ? Number(formatUnits(allowance, selectedToken.decimals)) : 0;
  const needsApproval = Number(amount) > approved;

  return (
    <div className="bg-white rounded-lg shadow p-6">
      <h2 className="text-xl font-bold mb-4">Deposit Collateral</h2>
      
      <div className="space-y-4">
        <div>
          <label className="block text-sm font-medium text-gray-700 mb-2">
            Select Collateral Token
          </label>
          <select
            className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
            value={selectedToken.address}
            onChange={(e) => {
              const token = COLLATERAL_TOKENS.find(t => t.address === e.target.value);
              if (token) setSelectedToken(token);
            }}
          >
            {COLLATERAL_TOKENS.map((token) => (
              <option key={token.address} value={token.address}>
                {token.symbol}
              </option>
            ))}
          </select>
          <p className="text-sm text-gray-500 mt-1">
            Balance: {balance.toFixed(6)} {selectedToken.symbol}
          </p>
        </div>

        <div>
          <label className="block text-sm font-medium text-gray-700 mb-2">
            Amount (min 0.001 BTC)
          </label>
          <input
            type="number"
            step="0.0001"
            min="0.001"
            className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
            value={amount}
            onChange={(e) => setAmount(e.target.value)}
            placeholder="0.001"
          />
        </div>

        <div className="space-y-2">
          {balance === 0 && (
            <button
              onClick={handleMint}
              className="w-full bg-green-600 text-white py-2 px-4 rounded-md hover:bg-green-700 transition-colors"
            >
              Mint Test Tokens
            </button>
          )}
          
          {needsApproval && amount && (
            <button
              onClick={handleApprove}
              disabled={isApprovalPending}
              className="w-full bg-blue-600 text-white py-2 px-4 rounded-md hover:bg-blue-700 disabled:bg-gray-400 transition-colors"
            >
              {isApprovalPending ? 'Approving...' : 'Approve Tokens'}
            </button>
          )}
          
          <button
            onClick={handleDeposit}
            disabled={!amount || needsApproval || isDepositPending || Number(amount) < 0.001}
            className="w-full bg-indigo-600 text-white py-2 px-4 rounded-md hover:bg-indigo-700 disabled:bg-gray-400 transition-colors"
          >
            {isDepositPending ? 'Depositing...' : 'Deposit'}
          </button>
        </div>
      </div>
    </div>
  );
}