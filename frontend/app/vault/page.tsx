'use client';

import { useState, useEffect } from 'react';
import { useAccount, useReadContract, useWriteContract, useWaitForTransactionReceipt } from 'wagmi';
import { parseUnits, formatUnits } from 'viem';
import { ArrowDown, Wallet, TrendingUp, Lock, ChevronDown, Check, X } from 'lucide-react';
import toast, { Toaster } from 'react-hot-toast';
import { GlassCard, GlassCardHeader, GlassCardContent, GlassCardFooter } from '../../components/GlassCard';
import { BTC_VAULT_TOKEN_ADDRESS, BTC_VAULT_STRATEGY_ADDRESS } from '../../lib/contracts';
import { BTC_VAULT_TOKEN_ABI, BTC_VAULT_STRATEGY_ABI } from '../../lib/abis';
import { formatAddress, formatAmount } from '../../lib/utils';

// Supported collateral types
const COLLATERAL_TYPES = [
  {
    symbol: 'WBTC',
    name: 'Wrapped Bitcoin',
    address: '0xe44b2870eFcd6Bb3C9305808012621f438e9636D',
    decimals: 8,
    icon: '🟠'
  },
  {
    symbol: 'tBTC',
    name: 'tBTC v2',
    address: '0x236aa50979D5f3De3Bd1Eeb40E81137F22ab794b',
    decimals: 18,
    icon: '🟢'
  },
  {
    symbol: 'cbBTC',
    name: 'Coinbase Wrapped BTC',
    address: '0x46248B5c1196E073714Cc4B02d4D45d973172c40',
    decimals: 8,
    icon: '🔵'
  }
];

// Simple ERC20 ABI for balance and approve
const ERC20_ABI = [
  {
    "inputs": [{"name": "account", "type": "address"}],
    "name": "balanceOf",
    "outputs": [{"name": "", "type": "uint256"}],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [
      {"name": "spender", "type": "address"},
      {"name": "amount", "type": "uint256"}
    ],
    "name": "approve",
    "outputs": [{"name": "", "type": "bool"}],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [
      {"name": "owner", "type": "address"},
      {"name": "spender", "type": "address"}
    ],
    "name": "allowance",
    "outputs": [{"name": "", "type": "uint256"}],
    "stateMutability": "view",
    "type": "function"
  }
] as const;

export default function VaultPage() {
  const [activeTab, setActiveTab] = useState<'deposit' | 'withdraw'>('deposit');
  const [amount, setAmount] = useState('');
  const [selectedCollateral, setSelectedCollateral] = useState(COLLATERAL_TYPES[0]);
  const [showCollateralDropdown, setShowCollateralDropdown] = useState(false);
  const { address, isConnected } = useAccount();

  // Contract reads - Vault metrics
  const { data: totalAssets } = useReadContract({
    address: BTC_VAULT_TOKEN_ADDRESS,
    abi: BTC_VAULT_TOKEN_ABI,
    functionName: 'totalAssets',
  });

  const { data: totalSupply } = useReadContract({
    address: BTC_VAULT_TOKEN_ADDRESS,
    abi: BTC_VAULT_TOKEN_ABI,
    functionName: 'totalSupply',
  });

  const { data: userShares } = useReadContract({
    address: BTC_VAULT_TOKEN_ADDRESS,
    abi: BTC_VAULT_TOKEN_ABI,
    functionName: 'balanceOf',
    args: address ? [address] : undefined,
  });

  const { data: withdrawalEnabled } = useReadContract({
    address: BTC_VAULT_TOKEN_ADDRESS,
    abi: BTC_VAULT_TOKEN_ABI,
    functionName: 'getWithdrawalEnabled',
  });

  // Check if collateral is supported
  const { data: isSupported } = useReadContract({
    address: BTC_VAULT_STRATEGY_ADDRESS,
    abi: BTC_VAULT_STRATEGY_ABI,
    functionName: 'isSupportedCollateral',
    args: [selectedCollateral.address],
  });

  // Get collateral balance
  const { data: collateralBalance } = useReadContract({
    address: selectedCollateral.address,
    abi: ERC20_ABI,
    functionName: 'balanceOf',
    args: address ? [address] : undefined,
  });

  // Get allowance
  const { data: allowance } = useReadContract({
    address: selectedCollateral.address,
    abi: ERC20_ABI,
    functionName: 'allowance',
    args: address ? [address, BTC_VAULT_STRATEGY_ADDRESS] : undefined,
  });

  // Preview deposit
  const { data: previewShares } = useReadContract({
    address: BTC_VAULT_STRATEGY_ADDRESS,
    abi: BTC_VAULT_STRATEGY_ABI,
    functionName: 'previewDepositCollateral',
    args: amount && selectedCollateral ? 
      [selectedCollateral.address, parseUnits(amount || '0', selectedCollateral.decimals)] : 
      undefined,
  });

  // Contract writes
  const { writeContract: approve, data: approveHash } = useWriteContract();
  const { writeContract: deposit, data: depositHash } = useWriteContract();
  const { writeContract: requestWithdraw, data: withdrawHash } = useWriteContract();

  // Transaction receipts
  const { isLoading: isApproving, isSuccess: approveSuccess } = useWaitForTransactionReceipt({
    hash: approveHash,
  });

  const { isLoading: isDepositing, isSuccess: depositSuccess } = useWaitForTransactionReceipt({
    hash: depositHash,
  });

  const { isLoading: isWithdrawing, isSuccess: withdrawSuccess } = useWaitForTransactionReceipt({
    hash: withdrawHash,
  });

  // Show success messages
  useEffect(() => {
    if (approveSuccess) {
      toast.success('Approval successful!');
    }
  }, [approveSuccess]);

  useEffect(() => {
    if (depositSuccess) {
      toast.success('Deposit successful!');
      setAmount('');
    }
  }, [depositSuccess]);

  useEffect(() => {
    if (withdrawSuccess) {
      toast.success('Withdrawal request submitted!');
      setAmount('');
    }
  }, [withdrawSuccess]);

  const handleDeposit = async () => {
    if (!amount || parseFloat(amount) <= 0) {
      toast.error('Please enter a valid amount');
      return;
    }

    if (!isSupported) {
      toast.error(`${selectedCollateral.symbol} is not supported`);
      return;
    }

    const amountWei = parseUnits(amount, selectedCollateral.decimals);

    // Check if approval is needed
    if (!allowance || allowance < amountWei) {
      toast.loading('Please approve the transaction...', { duration: 2000 });
      approve({
        address: selectedCollateral.address,
        abi: ERC20_ABI,
        functionName: 'approve',
        args: [BTC_VAULT_STRATEGY_ADDRESS, amountWei],
      });
    } else {
      toast.loading('Processing deposit...', { duration: 2000 });
      deposit({
        address: BTC_VAULT_STRATEGY_ADDRESS,
        abi: BTC_VAULT_STRATEGY_ABI,
        functionName: 'depositCollateral',
        args: [selectedCollateral.address, amountWei, address!],
      });
    }
  };

  const handleWithdraw = async () => {
    if (!amount || parseFloat(amount) <= 0) {
      toast.error('Please enter a valid amount');
      return;
    }

    if (!withdrawalEnabled) {
      toast.error('Withdrawals are currently disabled');
      return;
    }

    const amountWei = parseUnits(amount, 18); // Shares are 18 decimals

    toast.loading('Submitting withdrawal request...', { duration: 2000 });
    requestWithdraw({
      address: BTC_VAULT_TOKEN_ADDRESS,
      abi: BTC_VAULT_TOKEN_ABI,
      functionName: 'requestRedeem',
      args: [amountWei, address!, address!],
    });
  };

  const handleMaxDeposit = () => {
    if (collateralBalance) {
      setAmount(formatUnits(collateralBalance, selectedCollateral.decimals));
    }
  };

  const handleMaxWithdraw = () => {
    if (userShares) {
      setAmount(formatUnits(userShares, 18));
    }
  };

  // Calculate values
  const sharePrice = totalSupply && totalAssets && totalSupply > 0n
    ? Number(totalAssets) / Number(totalSupply)
    : 1;

  const userBTCValue = userShares && totalAssets && totalSupply && totalSupply > 0n
    ? (Number(userShares) * Number(totalAssets)) / Number(totalSupply) / 1e18
    : 0;

  return (
    <div className="min-h-screen">
      <Toaster 
        position="bottom-right"
        toastOptions={{
          duration: 4000,
          style: {
            background: 'rgba(15, 23, 42, 0.9)',
            color: '#fff',
            border: '1px solid rgba(255, 255, 255, 0.1)',
            borderRadius: '12px',
            backdropFilter: 'blur(10px)',
            boxShadow: '0 8px 32px 0 rgba(31, 38, 135, 0.37)',
          },
          success: {
            iconTheme: {
              primary: '#10b981',
              secondary: '#fff',
            },
          },
          error: {
            iconTheme: {
              primary: '#ef4444',
              secondary: '#fff',
            },
          },
        }}
      />

      {/* Main Content */}
      <main className="relative z-10 container mx-auto px-6 py-8">
        <div className="max-w-4xl mx-auto space-y-8">

          {/* Vault Overview Card */}
          <div className="relative overflow-hidden bg-white/10 backdrop-blur-xl border-white/20 shadow-[0_8px_32px_0_rgba(31,38,135,0.37)] rounded-2xl border">
            <div className="absolute inset-0 bg-gradient-to-br from-blue-500/10 via-transparent to-purple-500/10"></div>
            
            <div className="relative p-8">
              <h1 className="text-3xl font-bold text-white mb-2">Multi-Collateral Bitcoin Vault</h1>
              <p className="text-white/60 mb-8">Deposit BTC variants to earn sustainable yield from DeFi strategies</p>
              
              <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
                <div className="bg-white/5 backdrop-blur-md rounded-xl p-6 border border-white/10">
                  <p className="text-white/60 text-sm mb-1">Total Value Locked</p>
                  <p className="text-2xl font-bold text-white">
                    {totalAssets ? formatUnits(totalAssets, 18) : '0'} BTC
                  </p>
                  <p className="text-white/60 text-sm">Across all collateral types</p>
                </div>
                <div className="bg-white/5 backdrop-blur-md rounded-xl p-6 border border-white/10">
                  <p className="text-white/60 text-sm mb-1">Share Price</p>
                  <p className="text-2xl font-bold text-green-400">{sharePrice.toFixed(4)}</p>
                  <p className="text-white/60 text-sm">BTC per share</p>
                </div>
                <div className="bg-white/5 backdrop-blur-md rounded-xl p-6 border border-white/10">
                  <p className="text-white/60 text-sm mb-1">Your Position</p>
                  <p className="text-2xl font-bold text-white">{userBTCValue.toFixed(6)} BTC</p>
                  <p className="text-white/60 text-sm">{userShares ? formatUnits(userShares, 18) : '0'} vBTC</p>
                </div>
              </div>
            </div>
          </div>

          {/* Main Vault Interface */}
          <div className="relative overflow-hidden bg-white/10 backdrop-blur-xl border-white/20 shadow-[0_8px_32px_0_rgba(31,38,135,0.37)] rounded-2xl border">
            {/* Tab Navigation */}
            <div className="flex border-b border-white/10">
              <button
                onClick={() => setActiveTab('deposit')}
                className={`flex-1 px-6 py-4 text-center font-semibold transition-all ${
                  activeTab === 'deposit'
                    ? 'tab-active text-white'
                    : 'text-gray-400 hover:text-white hover:bg-white/5'
                }`}
              >
                Deposit
              </button>
              <button
                onClick={() => setActiveTab('withdraw')}
                className={`flex-1 px-6 py-4 text-center font-semibold transition-all ${
                  activeTab === 'withdraw'
                    ? 'tab-active text-white'
                    : 'text-gray-400 hover:text-white hover:bg-white/5'
                }`}
              >
                Withdraw
              </button>
            </div>

            {/* Form Content */}
            <div className="p-8">
              {!isConnected ? (
                <div className="text-center py-12">
                  <Wallet className="w-16 h-16 text-gray-400 mx-auto mb-4" />
                  <h3 className="text-xl font-semibold text-white mb-2">
                    Connect Wallet
                  </h3>
                  <p className="text-gray-400">
                    Please connect your wallet to access the vault
                  </p>
                </div>
              ) : activeTab === 'deposit' ? (
                <div className="space-y-6">
                  {/* Collateral Selector */}
                  <div>
                    <label className="form-label">Select Collateral</label>
                    <div className="relative">
                      <button
                        onClick={() => setShowCollateralDropdown(!showCollateralDropdown)}
                        className="w-full glass-input rounded-lg px-4 py-3 flex items-center justify-between hover:bg-white/10 transition-all"
                      >
                        <div className="flex items-center gap-3">
                          <span className="text-2xl">{selectedCollateral.icon}</span>
                          <div className="text-left">
                            <p className="text-white font-medium">{selectedCollateral.symbol}</p>
                            <p className="text-xs text-gray-400">{selectedCollateral.name}</p>
                          </div>
                        </div>
                        <ChevronDown className={`w-5 h-5 text-gray-400 transition-transform ${
                          showCollateralDropdown ? 'rotate-180' : ''
                        }`} />
                      </button>

                      {/* Dropdown */}
                      {showCollateralDropdown && (
                        <div className="absolute top-full left-0 right-0 mt-2 glass-card rounded-lg overflow-hidden z-20">
                          {COLLATERAL_TYPES.map((collateral) => (
                            <button
                              key={collateral.address}
                              onClick={() => {
                                setSelectedCollateral(collateral);
                                setShowCollateralDropdown(false);
                                setAmount('');
                              }}
                              className="w-full px-4 py-3 flex items-center justify-between hover:bg-white/10 transition-all"
                            >
                              <div className="flex items-center gap-3">
                                <span className="text-2xl">{collateral.icon}</span>
                                <div className="text-left">
                                  <p className="text-white font-medium">{collateral.symbol}</p>
                                  <p className="text-xs text-gray-400">{collateral.name}</p>
                                </div>
                              </div>
                              {selectedCollateral.address === collateral.address && (
                                <Check className="w-5 h-5 text-green-400" />
                              )}
                            </button>
                          ))}
                        </div>
                      )}
                    </div>
                  </div>

                  {/* Amount Input */}
                  <div>
                    <div className="flex justify-between items-center mb-2">
                      <label className="form-label">Amount</label>
                      <div className="text-sm text-gray-400">
                        Balance: {collateralBalance ? formatUnits(collateralBalance, selectedCollateral.decimals) : '0'} {selectedCollateral.symbol}
                      </div>
                    </div>
                    <div className="relative">
                      <input
                        type="number"
                        value={amount}
                        onChange={(e) => setAmount(e.target.value)}
                        placeholder="0.00"
                        className="form-input pr-20"
                      />
                      <button
                        onClick={handleMaxDeposit}
                        className="absolute right-2 top-1/2 -translate-y-1/2 px-3 py-1 text-xs font-medium text-blue-400 hover:text-blue-300 transition-colors"
                      >
                        MAX
                      </button>
                    </div>
                  </div>

                  {/* Preview */}
                  {amount && previewShares && (
                    <div className="glass-card-light rounded-lg p-4">
                      <div className="flex items-center justify-between">
                        <span className="text-gray-400">You will receive</span>
                        <span className="text-white font-medium">
                          {formatUnits(previewShares, 18)} vBTC
                        </span>
                      </div>
                    </div>
                  )}

                  {/* Deposit Button */}
                  <button
                    onClick={handleDeposit}
                    disabled={!amount || isApproving || isDepositing}
                    className="btn-primary w-full disabled:opacity-50 disabled:cursor-not-allowed"
                  >
                    {isApproving ? 'Approving...' : isDepositing ? 'Depositing...' : 
                     allowance && parseUnits(amount || '0', selectedCollateral.decimals) > allowance ? 'Approve & Deposit' : 'Deposit'}
                  </button>

                  {/* Warning for unsupported collateral */}
                  {selectedCollateral && isSupported === false && (
                    <div className="p-4 rounded-lg bg-red-500/20 border border-red-500/50">
                      <p className="text-red-400 text-sm">
                        {selectedCollateral.symbol} is not currently supported. Please select another collateral type.
                      </p>
                    </div>
                  )}
                </div>
              ) : (
                <div className="space-y-6">
                  {/* Withdraw Form */}
                  <div>
                    <div className="flex justify-between items-center mb-2">
                      <label className="form-label">Amount (vBTC shares)</label>
                      <div className="text-sm text-gray-400">
                        Balance: {userShares ? formatUnits(userShares, 18) : '0'} vBTC
                      </div>
                    </div>
                    <div className="relative">
                      <input
                        type="number"
                        value={amount}
                        onChange={(e) => setAmount(e.target.value)}
                        placeholder="0.00"
                        className="form-input pr-20"
                      />
                      <button
                        onClick={handleMaxWithdraw}
                        className="absolute right-2 top-1/2 -translate-y-1/2 px-3 py-1 text-xs font-medium text-orange-400 hover:text-orange-300 transition-colors"
                      >
                        MAX
                      </button>
                    </div>
                  </div>

                  {/* Preview */}
                  {amount && (
                    <div className="glass-card-light rounded-lg p-4">
                      <div className="flex items-center justify-between">
                        <span className="text-gray-400">You will receive (estimated)</span>
                        <span className="text-white font-medium">
                          {(parseFloat(amount) * sharePrice).toFixed(6)} sovaBTC
                        </span>
                      </div>
                    </div>
                  )}

                  {/* Withdraw Button */}
                  <button
                    onClick={handleWithdraw}
                    disabled={!amount || isWithdrawing || !withdrawalEnabled}
                    className="btn-primary w-full disabled:opacity-50 disabled:cursor-not-allowed"
                  >
                    {isWithdrawing ? 'Processing...' : 'Request Withdrawal'}
                  </button>

                  {/* Info Box */}
                  <div className="glass-card-light rounded-lg p-4">
                    <p className="text-sm text-gray-400">
                      Withdrawals are processed through a managed queue. Your request will be reviewed and approved by the vault manager.
                    </p>
                  </div>

                  {/* Disabled Warning */}
                  {withdrawalEnabled === false && (
                    <div className="p-4 rounded-lg bg-yellow-500/20 border border-yellow-500/50">
                      <p className="text-yellow-400 text-sm">
                        Withdrawals are currently disabled. Please try again later.
                      </p>
                    </div>
                  )}
                </div>
              )}
            </div>
          </div>
        </div>
      </main>
    </div>
  );
}