'use client';

import { useState, useEffect } from 'react';
import { useAccount, useReadContract, useWriteContract, useWaitForTransactionReceipt } from 'wagmi';
import { formatUnits, parseUnits, encodeFunctionData } from 'viem';
import { CONTRACTS } from '@/lib/contracts';

// Admin Panel ABIs
const ROLE_MANAGER_ABI = [
  {
    inputs: [],
    name: 'PROTOCOL_ADMIN',
    outputs: [{ internalType: 'uint256', name: '', type: 'uint256' }],
    stateMutability: 'view',
    type: 'function'
  },
  {
    inputs: [
      { internalType: 'address', name: 'user', type: 'address' },
      { internalType: 'uint256', name: 'roles', type: 'uint256' }
    ],
    name: 'hasAllRoles',
    outputs: [{ internalType: 'bool', name: '', type: 'bool' }],
    stateMutability: 'view',
    type: 'function'
  }
] as const;

const QUEUE_ABI = [
  {
    inputs: [{ internalType: 'uint256[]', name: 'requestIds', type: 'uint256[]' }],
    name: 'processRedemptions',
    outputs: [],
    stateMutability: 'nonpayable',
    type: 'function'
  },
  {
    inputs: [{ internalType: 'uint256', name: 'requestId', type: 'uint256' }],
    name: 'forceProcessRedemption',
    outputs: [],
    stateMutability: 'nonpayable',
    type: 'function'
  },
  {
    inputs: [],
    name: 'pause',
    outputs: [],
    stateMutability: 'nonpayable',
    type: 'function'
  },
  {
    inputs: [],
    name: 'unpause',
    outputs: [],
    stateMutability: 'nonpayable',
    type: 'function'
  },
  {
    inputs: [
      { internalType: 'address', name: 'token', type: 'address' },
      { internalType: 'address', name: 'to', type: 'address' },
      { internalType: 'uint256', name: 'amount', type: 'uint256' }
    ],
    name: 'rescueTokens',
    outputs: [],
    stateMutability: 'nonpayable',
    type: 'function'
  },
  {
    inputs: [],
    name: 'paused',
    outputs: [{ internalType: 'bool', name: '', type: 'bool' }],
    stateMutability: 'view',
    type: 'function'
  },
  {
    inputs: [],
    name: 'totalRequests',
    outputs: [{ internalType: 'uint256', name: '', type: 'uint256' }],
    stateMutability: 'view',
    type: 'function'
  },
  {
    inputs: [],
    name: 'totalPendingShares',
    outputs: [{ internalType: 'uint256', name: '', type: 'uint256' }],
    stateMutability: 'view',
    type: 'function'
  }
] as const;

const PRICE_ORACLE_ABI = [
  {
    inputs: [
      { internalType: 'uint256', name: 'newTargetPricePerShare', type: 'uint256' },
      { internalType: 'string', name: 'source_', type: 'string' }
    ],
    name: 'update',
    outputs: [],
    stateMutability: 'nonpayable',
    type: 'function'
  },
  {
    inputs: [],
    name: 'currentPrice',
    outputs: [{ internalType: 'uint256', name: '', type: 'uint256' }],
    stateMutability: 'view',
    type: 'function'
  },
  {
    inputs: [],
    name: 'targetPrice',
    outputs: [{ internalType: 'uint256', name: '', type: 'uint256' }],
    stateMutability: 'view',
    type: 'function'
  },
  {
    inputs: [],
    name: 'lastUpdate',
    outputs: [{ internalType: 'uint256', name: '', type: 'uint256' }],
    stateMutability: 'view',
    type: 'function'
  }
] as const;

const REGISTRY_ABI = [
  {
    inputs: [
      { internalType: 'address', name: 'token', type: 'address' },
      { internalType: 'uint8', name: 'decimals', type: 'uint8' },
      { internalType: 'uint256', name: 'conversionRate', type: 'uint256' }
    ],
    name: 'addCollateral',
    outputs: [],
    stateMutability: 'nonpayable',
    type: 'function'
  },
  {
    inputs: [{ internalType: 'address', name: 'token', type: 'address' }],
    name: 'removeCollateral',
    outputs: [],
    stateMutability: 'nonpayable',
    type: 'function'
  },
  {
    inputs: [
      { internalType: 'address', name: 'token', type: 'address' },
      { internalType: 'uint256', name: 'newRate', type: 'uint256' }
    ],
    name: 'updateConversionRate',
    outputs: [],
    stateMutability: 'nonpayable',
    type: 'function'
  }
] as const;

interface AdminPanelProps {
  className?: string;
}

export function AdminPanel({ className = '' }: AdminPanelProps) {
  const { address } = useAccount();
  const [activeTab, setActiveTab] = useState<'redemptions' | 'price' | 'emergency' | 'collateral' | 'analytics'>('redemptions');
  const [selectedRequests, setSelectedRequests] = useState<string[]>([]);
  const [newPrice, setNewPrice] = useState('');
  const [priceSource, setPriceSource] = useState('Manual Update');
  const [rescueToken, setRescueToken] = useState('');
  const [rescueTo, setRescueTo] = useState('');
  const [rescueAmount, setRescueAmount] = useState('');
  const [pendingRequests, setPendingRequests] = useState<any[]>([]);

  // Check if user is admin
  const { data: protocolAdminRole } = useReadContract({
    address: CONTRACTS.roleManager as `0x${string}`,
    abi: ROLE_MANAGER_ABI,
    functionName: 'PROTOCOL_ADMIN',
  });

  const { data: isAdmin } = useReadContract({
    address: CONTRACTS.roleManager as `0x${string}`,
    abi: ROLE_MANAGER_ABI,
    functionName: 'hasAllRoles',
    args: address && protocolAdminRole ? [address, protocolAdminRole] : undefined,
  });

  // Read system status
  const { data: isPaused } = useReadContract({
    address: CONTRACTS.queue as `0x${string}`,
    abi: QUEUE_ABI,
    functionName: 'paused',
  });

  const { data: totalRequests } = useReadContract({
    address: CONTRACTS.queue as `0x${string}`,
    abi: QUEUE_ABI,
    functionName: 'totalRequests',
  });

  const { data: totalPendingShares } = useReadContract({
    address: CONTRACTS.queue as `0x${string}`,
    abi: QUEUE_ABI,
    functionName: 'totalPendingShares',
  });

  const { data: currentPrice } = useReadContract({
    address: CONTRACTS.priceOracle as `0x${string}`,
    abi: PRICE_ORACLE_ABI,
    functionName: 'currentPrice',
  });

  const { data: targetPrice } = useReadContract({
    address: CONTRACTS.priceOracle as `0x${string}`,
    abi: PRICE_ORACLE_ABI,
    functionName: 'targetPrice',
  });

  const { data: lastPriceUpdate } = useReadContract({
    address: CONTRACTS.priceOracle as `0x${string}`,
    abi: PRICE_ORACLE_ABI,
    functionName: 'lastUpdate',
  });

  // Write functions
  const { writeContract, data: txHash } = useWriteContract();
  const { isLoading: isConfirming, isSuccess } = useWaitForTransactionReceipt({ hash: txHash });

  // Process redemptions
  const handleProcessRedemptions = async () => {
    if (selectedRequests.length === 0) {
      alert('Please select redemption requests to process');
      return;
    }

    try {
      await writeContract({
        address: CONTRACTS.queue as `0x${string}`,
        abi: QUEUE_ABI,
        functionName: 'processRedemptions',
        args: [selectedRequests.map(id => BigInt(id))],
      });
    } catch (error) {
      console.error('Error processing redemptions:', error);
    }
  };

  // Force process single redemption
  const handleForceProcess = async (requestId: string) => {
    try {
      await writeContract({
        address: CONTRACTS.queue as `0x${string}`,
        abi: QUEUE_ABI,
        functionName: 'forceProcessRedemption',
        args: [BigInt(requestId)],
      });
    } catch (error) {
      console.error('Error force processing redemption:', error);
    }
  };

  // Update price oracle
  const handleUpdatePrice = async () => {
    if (!newPrice) {
      alert('Please enter a new price');
      return;
    }

    try {
      const priceInWei = parseUnits(newPrice, 18);
      await writeContract({
        address: CONTRACTS.priceOracle as `0x${string}`,
        abi: PRICE_ORACLE_ABI,
        functionName: 'update',
        args: [priceInWei, priceSource],
      });
    } catch (error) {
      console.error('Error updating price:', error);
    }
  };

  // Pause/Unpause
  const handlePauseToggle = async () => {
    try {
      await writeContract({
        address: CONTRACTS.queue as `0x${string}`,
        abi: QUEUE_ABI,
        functionName: isPaused ? 'unpause' : 'pause',
      });
    } catch (error) {
      console.error('Error toggling pause:', error);
    }
  };

  // Rescue tokens
  const handleRescueTokens = async () => {
    if (!rescueToken || !rescueTo || !rescueAmount) {
      alert('Please fill all rescue fields');
      return;
    }

    try {
      const amount = parseUnits(rescueAmount, 18); // Adjust decimals as needed
      await writeContract({
        address: CONTRACTS.queue as `0x${string}`,
        abi: QUEUE_ABI,
        functionName: 'rescueTokens',
        args: [rescueToken as `0x${string}`, rescueTo as `0x${string}`, amount],
      });
    } catch (error) {
      console.error('Error rescuing tokens:', error);
    }
  };

  // Format timestamp
  const formatTimestamp = (timestamp: bigint) => {
    const date = new Date(Number(timestamp) * 1000);
    return date.toLocaleString();
  };

  if (!isAdmin) {
    return (
      <div className={`bg-red-50 border border-red-200 rounded-lg p-6 ${className}`}>
        <h2 className="text-xl font-bold text-red-800 mb-2">Access Denied</h2>
        <p className="text-red-600">You do not have admin privileges to access this panel.</p>
        <p className="text-sm text-red-500 mt-2">Connected: {address || 'Not connected'}</p>
      </div>
    );
  }

  return (
    <div className={`bg-white rounded-lg shadow-lg p-6 ${className}`}>
      <div className="mb-6">
        <h2 className="text-2xl font-bold text-gray-900">Admin Panel</h2>
        <p className="text-sm text-gray-500 mt-1">System Status: {isPaused ? '⚠️ PAUSED' : '✅ ACTIVE'}</p>
      </div>

      {/* Tab Navigation */}
      <div className="border-b border-gray-200 mb-6">
        <nav className="-mb-px flex space-x-8">
          {['redemptions', 'price', 'emergency', 'collateral', 'analytics'].map((tab) => (
            <button
              key={tab}
              onClick={() => setActiveTab(tab as any)}
              className={`py-2 px-1 border-b-2 font-medium text-sm ${
                activeTab === tab
                  ? 'border-blue-500 text-blue-600'
                  : 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300'
              }`}
            >
              {tab.charAt(0).toUpperCase() + tab.slice(1)}
            </button>
          ))}
        </nav>
      </div>

      {/* Tab Content */}
      <div className="space-y-6">
        {/* Redemptions Tab */}
        {activeTab === 'redemptions' && (
          <div>
            <h3 className="text-lg font-semibold mb-4">Redemption Processing</h3>
            
            <div className="bg-gray-50 p-4 rounded-lg mb-4">
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <p className="text-sm text-gray-500">Total Requests</p>
                  <p className="text-xl font-bold">{totalRequests?.toString() || '0'}</p>
                </div>
                <div>
                  <p className="text-sm text-gray-500">Pending Shares</p>
                  <p className="text-xl font-bold">
                    {totalPendingShares ? formatUnits(totalPendingShares, 18) : '0'} mcBTC
                  </p>
                </div>
              </div>
            </div>

            <div className="mb-4">
              <label className="block text-sm font-medium text-gray-700 mb-2">
                Request IDs (comma-separated)
              </label>
              <input
                type="text"
                placeholder="1,2,3"
                onChange={(e) => setSelectedRequests(e.target.value.split(',').filter(Boolean))}
                className="w-full px-3 py-2 border border-gray-300 rounded-md"
              />
            </div>

            <div className="flex gap-3">
              <button
                onClick={handleProcessRedemptions}
                disabled={isConfirming}
                className="px-4 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700 disabled:opacity-50"
              >
                {isConfirming ? 'Processing...' : 'Process Selected'}
              </button>
              
              <button
                onClick={() => {
                  const id = prompt('Enter request ID to force process:');
                  if (id) handleForceProcess(id);
                }}
                className="px-4 py-2 bg-orange-600 text-white rounded-md hover:bg-orange-700"
              >
                Force Process Single
              </button>
            </div>
          </div>
        )}

        {/* Price Oracle Tab */}
        {activeTab === 'price' && (
          <div>
            <h3 className="text-lg font-semibold mb-4">Price Oracle Management</h3>
            
            <div className="bg-gray-50 p-4 rounded-lg mb-4">
              <div className="grid grid-cols-3 gap-4">
                <div>
                  <p className="text-sm text-gray-500">Current Price</p>
                  <p className="text-xl font-bold">
                    {currentPrice ? formatUnits(currentPrice, 18) : '0'}
                  </p>
                </div>
                <div>
                  <p className="text-sm text-gray-500">Target Price</p>
                  <p className="text-xl font-bold">
                    {targetPrice ? formatUnits(targetPrice, 18) : '0'}
                  </p>
                </div>
                <div>
                  <p className="text-sm text-gray-500">Last Update</p>
                  <p className="text-sm">
                    {lastPriceUpdate ? formatTimestamp(lastPriceUpdate) : 'Never'}
                  </p>
                </div>
              </div>
            </div>

            <div className="space-y-4">
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  New Target Price
                </label>
                <input
                  type="number"
                  step="0.0001"
                  value={newPrice}
                  onChange={(e) => setNewPrice(e.target.value)}
                  placeholder="1.0000"
                  className="w-full px-3 py-2 border border-gray-300 rounded-md"
                />
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  Source Description
                </label>
                <input
                  type="text"
                  value={priceSource}
                  onChange={(e) => setPriceSource(e.target.value)}
                  placeholder="Manual Update"
                  className="w-full px-3 py-2 border border-gray-300 rounded-md"
                />
              </div>

              <button
                onClick={handleUpdatePrice}
                disabled={isConfirming}
                className="px-4 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700 disabled:opacity-50"
              >
                {isConfirming ? 'Updating...' : 'Update Price'}
              </button>
            </div>
          </div>
        )}

        {/* Emergency Controls Tab */}
        {activeTab === 'emergency' && (
          <div>
            <h3 className="text-lg font-semibold mb-4">Emergency Controls</h3>
            
            <div className="space-y-6">
              {/* Pause/Unpause */}
              <div className="border rounded-lg p-4">
                <h4 className="font-medium mb-2">System Pause</h4>
                <p className="text-sm text-gray-600 mb-3">
                  Current Status: {isPaused ? '⚠️ PAUSED' : '✅ ACTIVE'}
                </p>
                <button
                  onClick={handlePauseToggle}
                  disabled={isConfirming}
                  className={`px-4 py-2 rounded-md text-white ${
                    isPaused 
                      ? 'bg-green-600 hover:bg-green-700' 
                      : 'bg-red-600 hover:bg-red-700'
                  } disabled:opacity-50`}
                >
                  {isConfirming ? 'Processing...' : isPaused ? 'Unpause System' : 'Pause System'}
                </button>
              </div>

              {/* Token Rescue */}
              <div className="border rounded-lg p-4">
                <h4 className="font-medium mb-2">Rescue Tokens</h4>
                <p className="text-sm text-gray-600 mb-3">
                  Recover stuck tokens from the queue contract
                </p>
                
                <div className="space-y-3">
                  <input
                    type="text"
                    value={rescueToken}
                    onChange={(e) => setRescueToken(e.target.value)}
                    placeholder="Token Address"
                    className="w-full px-3 py-2 border border-gray-300 rounded-md"
                  />
                  <input
                    type="text"
                    value={rescueTo}
                    onChange={(e) => setRescueTo(e.target.value)}
                    placeholder="Recipient Address"
                    className="w-full px-3 py-2 border border-gray-300 rounded-md"
                  />
                  <input
                    type="text"
                    value={rescueAmount}
                    onChange={(e) => setRescueAmount(e.target.value)}
                    placeholder="Amount"
                    className="w-full px-3 py-2 border border-gray-300 rounded-md"
                  />
                  <button
                    onClick={handleRescueTokens}
                    disabled={isConfirming}
                    className="px-4 py-2 bg-orange-600 text-white rounded-md hover:bg-orange-700 disabled:opacity-50"
                  >
                    {isConfirming ? 'Rescuing...' : 'Rescue Tokens'}
                  </button>
                </div>
              </div>
            </div>
          </div>
        )}

        {/* Collateral Management Tab */}
        {activeTab === 'collateral' && (
          <div>
            <h3 className="text-lg font-semibold mb-4">Collateral Management</h3>
            <p className="text-gray-600">
              Manage supported collateral tokens in the registry.
            </p>
            
            <div className="mt-4 p-4 bg-yellow-50 border border-yellow-200 rounded-lg">
              <p className="text-sm text-yellow-800">
                Note: Collateral management functions require separate transactions.
                Use the script commands or direct contract interaction for now.
              </p>
            </div>
          </div>
        )}

        {/* Analytics Tab */}
        {activeTab === 'analytics' && (
          <div>
            <h3 className="text-lg font-semibold mb-4">System Analytics</h3>
            
            <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
              <div className="bg-gray-50 p-4 rounded-lg">
                <p className="text-sm text-gray-500">Total Requests</p>
                <p className="text-2xl font-bold">{totalRequests?.toString() || '0'}</p>
              </div>
              
              <div className="bg-gray-50 p-4 rounded-lg">
                <p className="text-sm text-gray-500">Pending Shares</p>
                <p className="text-2xl font-bold">
                  {totalPendingShares ? Number(formatUnits(totalPendingShares, 18)).toFixed(2) : '0'}
                </p>
              </div>
              
              <div className="bg-gray-50 p-4 rounded-lg">
                <p className="text-sm text-gray-500">System Status</p>
                <p className="text-2xl font-bold">{isPaused ? '⚠️' : '✅'}</p>
              </div>
              
              <div className="bg-gray-50 p-4 rounded-lg">
                <p className="text-sm text-gray-500">Price Freshness</p>
                <p className="text-2xl font-bold">
                  {lastPriceUpdate 
                    ? `${Math.floor((Date.now() / 1000 - Number(lastPriceUpdate)) / 3600)}h ago`
                    : 'N/A'}
                </p>
              </div>
            </div>

            <div className="mt-6 p-4 bg-blue-50 border border-blue-200 rounded-lg">
              <h4 className="font-medium text-blue-900 mb-2">System Health</h4>
              <ul className="space-y-1 text-sm text-blue-800">
                <li>✅ Contracts Connected</li>
                <li>{isPaused ? '⚠️ System Paused' : '✅ System Active'}</li>
                <li>
                  {lastPriceUpdate && (Date.now() / 1000 - Number(lastPriceUpdate)) > 86400
                    ? '⚠️ Price Update Needed (>24h)'
                    : '✅ Price Fresh'}
                </li>
                <li>✅ Admin Access Verified</li>
              </ul>
            </div>
          </div>
        )}
      </div>

      {/* Transaction Status */}
      {isSuccess && (
        <div className="mt-4 p-3 bg-green-50 border border-green-200 rounded-lg">
          <p className="text-green-800">✅ Transaction successful!</p>
        </div>
      )}
    </div>
  );
}