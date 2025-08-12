'use client';

import { useState } from 'react';
import { useAccount, useWriteContract, useReadContract, useWaitForTransactionReceipt } from 'wagmi';
import { parseUnits, formatUnits } from 'viem';
import { CONTRACTS } from '@/lib/contracts';
import { VAULT_ABI, QUEUE_ABI } from '@/lib/abis';

export function RedemptionQueue() {
  const { address } = useAccount();
  const [redeemAmount, setRedeemAmount] = useState('');

  const { writeContract: requestRedemption, data: requestHash } = useWriteContract();
  const { writeContract: claimRedemption, data: claimHash } = useWriteContract();

  const { isLoading: isRequestPending } = useWaitForTransactionReceipt({
    hash: requestHash,
  });

  const { isLoading: isClaimPending } = useWaitForTransactionReceipt({
    hash: claimHash,
  });

  const { data: userBalance } = useReadContract({
    address: CONTRACTS.vault as `0x${string}`,
    abi: VAULT_ABI,
    functionName: 'balanceOf',
    args: address ? [address] : undefined,
  });

  const { data: userRequests } = useReadContract({
    address: CONTRACTS.queue as `0x${string}`,
    abi: QUEUE_ABI,
    functionName: 'getUserRequests',
    args: address ? [address] : undefined,
  });

  const { data: totalPending } = useReadContract({
    address: CONTRACTS.queue as `0x${string}`,
    abi: QUEUE_ABI,
    functionName: 'getTotalPendingShares',
  });

  const handleRequestRedemption = async () => {
    if (!redeemAmount || !address) return;
    
    const amountInWei = parseUnits(redeemAmount, 18);
    
    await requestRedemption({
      address: CONTRACTS.vault as `0x${string}`,
      abi: VAULT_ABI,
      functionName: 'requestRedemption',
      args: [amountInWei],
    });
    
    setRedeemAmount('');
  };

  const handleClaim = async (requestId: bigint) => {
    if (!address) return;
    
    await claimRedemption({
      address: CONTRACTS.queue as `0x${string}`,
      abi: QUEUE_ABI,
      functionName: 'claimRedemption',
      args: [requestId],
    });
  };

  const balance = userBalance ? Number(formatUnits(userBalance, 18)) : 0;
  const pendingShares = totalPending ? Number(formatUnits(totalPending, 18)) : 0;

  return (
    <div className="bg-white rounded-lg shadow p-6">
      <h2 className="text-xl font-bold mb-4">Redemption Queue</h2>
      
      <div className="space-y-4">
        <div className="border-b pb-4">
          <p className="text-sm text-gray-600 mb-2">
            Queue Status: {pendingShares.toFixed(2)} mcBTC pending
          </p>
          <p className="text-sm text-gray-600">
            Processing Time: 1 day (testnet) / 14 days (mainnet)
          </p>
        </div>

        <div>
          <label className="block text-sm font-medium text-gray-700 mb-2">
            Request Redemption (mcBTC)
          </label>
          <div className="flex space-x-2">
            <input
              type="number"
              step="0.01"
              className="flex-1 px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
              value={redeemAmount}
              onChange={(e) => setRedeemAmount(e.target.value)}
              placeholder="0.00"
              max={balance.toString()}
            />
            <button
              onClick={handleRequestRedemption}
              disabled={!redeemAmount || Number(redeemAmount) > balance || isRequestPending}
              className="bg-red-600 text-white py-2 px-4 rounded-md hover:bg-red-700 disabled:bg-gray-400 transition-colors"
            >
              {isRequestPending ? 'Requesting...' : 'Request'}
            </button>
          </div>
          <p className="text-sm text-gray-500 mt-1">
            Available: {balance.toFixed(4)} mcBTC
          </p>
        </div>

        {userRequests && userRequests.length > 0 && (
          <div>
            <h3 className="font-semibold mb-2">Your Redemption Requests</h3>
            <div className="space-y-2">
              {userRequests.map((requestId, index) => (
                <RedemptionRequestItem 
                  key={index} 
                  requestId={requestId} 
                  onClaim={handleClaim}
                  isClaimPending={isClaimPending}
                />
              ))}
            </div>
          </div>
        )}
      </div>
    </div>
  );
}

function RedemptionRequestItem({ 
  requestId, 
  onClaim,
  isClaimPending 
}: { 
  requestId: bigint;
  onClaim: (id: bigint) => void;
  isClaimPending: boolean;
}) {
  const { data: request } = useReadContract({
    address: CONTRACTS.queue as `0x${string}`,
    abi: QUEUE_ABI,
    functionName: 'getRedemptionRequest',
    args: [requestId],
  });

  if (!request) return null;

  const shares = Number(formatUnits(request.shares, 18));
  const requestDate = new Date(Number(request.requestedAt) * 1000);
  const canClaim = request.processed && !request.claimed;

  return (
    <div className="border rounded p-3">
      <div className="flex justify-between items-center">
        <div>
          <p className="font-medium">Request #{requestId.toString()}</p>
          <p className="text-sm text-gray-600">
            {shares.toFixed(4)} mcBTC
          </p>
          <p className="text-xs text-gray-500">
            {requestDate.toLocaleDateString()}
          </p>
        </div>
        <div>
          {request.claimed && (
            <span className="text-green-600 text-sm">Claimed</span>
          )}
          {request.processed && !request.claimed && (
            <button
              onClick={() => onClaim(requestId)}
              disabled={isClaimPending}
              className="bg-green-600 text-white py-1 px-3 rounded text-sm hover:bg-green-700 disabled:bg-gray-400"
            >
              {isClaimPending ? 'Claiming...' : 'Claim'}
            </button>
          )}
          {!request.processed && (
            <span className="text-yellow-600 text-sm">Processing</span>
          )}
        </div>
      </div>
    </div>
  );
}