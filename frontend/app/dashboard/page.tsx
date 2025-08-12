'use client';

import { useAccount, useReadContract } from 'wagmi';
import { formatUnits } from 'viem';
import { useNetworkContracts } from '@/hooks/useNetworkContracts';
import { BTC_VAULT_TOKEN_ABI, BTC_VAULT_STRATEGY_ABI } from '@/lib/abis';
import { GlassCard } from '@/components/GlassCard';
import { 
  TrendingUp, 
  Users, 
  Coins, 
  Activity,
  ArrowUp,
  ArrowDown,
  DollarSign,
  BarChart3,
  PieChart,
  Clock
} from 'lucide-react';
import { cn } from '@/lib/utils';

// Mock data for charts (in production, this would come from a real API)
const mockTVLData = [
  { date: '1 Jan', value: 100 },
  { date: '8 Jan', value: 120 },
  { date: '15 Jan', value: 115 },
  { date: '22 Jan', value: 140 },
  { date: '29 Jan', value: 135 },
  { date: '5 Feb', value: 160 },
  { date: '12 Feb', value: 175 },
];

const mockCollateralDistribution = [
  { name: 'sovaBTC', value: 45, color: 'bg-orange-500' },
  { name: 'WBTC', value: 30, color: 'bg-blue-500' },
  { name: 'tBTC', value: 25, color: 'bg-purple-500' },
];

const mockRecentTransactions = [
  { type: 'deposit', user: '0x1234...5678', amount: '0.5 BTC', time: '2 min ago' },
  { type: 'withdrawal', user: '0x8765...4321', amount: '0.2 BTC', time: '15 min ago' },
  { type: 'deposit', user: '0x2468...1357', amount: '1.0 BTC', time: '1 hour ago' },
  { type: 'deposit', user: '0x9876...5432', amount: '0.3 BTC', time: '2 hours ago' },
  { type: 'withdrawal', user: '0x3456...7890', amount: '0.1 BTC', time: '3 hours ago' },
];

export default function DashboardPage() {
  const { address } = useAccount();
  const { btcVaultStrategy, btcVaultToken, isSupported } = useNetworkContracts();

  // Read vault data
  const { data: totalAssets } = useReadContract({
    address: btcVaultToken as `0x${string}`,
    abi: BTC_VAULT_TOKEN_ABI,
    functionName: 'totalAssets',
    enabled: isSupported,
  });

  const { data: totalSupply } = useReadContract({
    address: btcVaultToken as `0x${string}`,
    abi: BTC_VAULT_TOKEN_ABI,
    functionName: 'totalSupply',
    enabled: isSupported,
  });

  const { data: availableLiquidity } = useReadContract({
    address: btcVaultStrategy as `0x${string}`,
    abi: BTC_VAULT_STRATEGY_ABI,
    functionName: 'availableLiquidity',
    enabled: isSupported,
  });

  // User data
  const { data: userBalance } = useReadContract({
    address: btcVaultToken as `0x${string}`,
    abi: BTC_VAULT_TOKEN_ABI,
    functionName: 'balanceOf',
    args: address ? [address] : undefined,
    enabled: isSupported && !!address,
  });

  const tvl = totalAssets ? Number(formatUnits(totalAssets, 8)) : 0;
  const shares = totalSupply ? Number(formatUnits(totalSupply, 18)) : 0;
  const liquidity = availableLiquidity ? Number(formatUnits(availableLiquidity, 8)) : 0;
  const sharePrice = shares > 0 ? tvl / shares : 1;
  const userShares = userBalance ? Number(formatUnits(userBalance, 18)) : 0;
  const userValue = userShares * sharePrice;

  // Calculate mock APY (in production, this would be calculated from historical data)
  const apy = 12.5;
  const dailyYield = apy / 365;

  return (
    <main className="container mx-auto px-6 py-12">
      <div className="mb-8">
        <h1 className="text-4xl font-bold text-white mb-2">Dashboard</h1>
        <p className="text-white/60">Monitor vault performance and your positions</p>
      </div>

      {/* Key Metrics */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-8">
        <GlassCard>
          <div className="flex items-center justify-between">
            <div>
              <p className="text-white/60 text-sm">Total Value Locked</p>
              <p className="text-2xl font-bold text-white">{tvl.toFixed(4)}</p>
              <div className="flex items-center gap-1 mt-1">
                <ArrowUp className="w-3 h-3 text-green-400" />
                <p className="text-green-400 text-xs">+15.2% this week</p>
              </div>
            </div>
            <TrendingUp className="w-8 h-8 text-green-400" />
          </div>
        </GlassCard>

        <GlassCard>
          <div className="flex items-center justify-between">
            <div>
              <p className="text-white/60 text-sm">Current APY</p>
              <p className="text-2xl font-bold text-white">{apy.toFixed(2)}%</p>
              <p className="text-white/40 text-xs">{dailyYield.toFixed(3)}% daily</p>
            </div>
            <DollarSign className="w-8 h-8 text-yellow-400" />
          </div>
        </GlassCard>

        <GlassCard>
          <div className="flex items-center justify-between">
            <div>
              <p className="text-white/60 text-sm">Total Depositors</p>
              <p className="text-2xl font-bold text-white">1,234</p>
              <div className="flex items-center gap-1 mt-1">
                <ArrowUp className="w-3 h-3 text-green-400" />
                <p className="text-green-400 text-xs">+42 today</p>
              </div>
            </div>
            <Users className="w-8 h-8 text-blue-400" />
          </div>
        </GlassCard>

        <GlassCard>
          <div className="flex items-center justify-between">
            <div>
              <p className="text-white/60 text-sm">Share Price</p>
              <p className="text-2xl font-bold text-white">{sharePrice.toFixed(6)}</p>
              <p className="text-white/40 text-xs">BTC per share</p>
            </div>
            <Coins className="w-8 h-8 text-purple-400" />
          </div>
        </GlassCard>
      </div>

      {/* User Position */}
      {address && userShares > 0 && (
        <GlassCard className="mb-8">
          <h3 className="text-lg font-semibold text-white mb-4">Your Position</h3>
          <div className="grid grid-cols-1 md:grid-cols-4 gap-6">
            <div>
              <p className="text-white/60 text-sm">Your Shares</p>
              <p className="text-xl font-bold text-white">{userShares.toFixed(4)}</p>
              <p className="text-white/40 text-xs">btcVault</p>
            </div>
            <div>
              <p className="text-white/60 text-sm">Current Value</p>
              <p className="text-xl font-bold text-white">{userValue.toFixed(6)}</p>
              <p className="text-white/40 text-xs">BTC</p>
            </div>
            <div>
              <p className="text-white/60 text-sm">Daily Earnings</p>
              <p className="text-xl font-bold text-green-400">
                +{(userValue * dailyYield / 100).toFixed(8)}
              </p>
              <p className="text-white/40 text-xs">BTC per day</p>
            </div>
            <div>
              <p className="text-white/60 text-sm">Yearly Projection</p>
              <p className="text-xl font-bold text-green-400">
                +{(userValue * apy / 100).toFixed(6)}
              </p>
              <p className="text-white/40 text-xs">BTC per year</p>
            </div>
          </div>
        </GlassCard>
      )}

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-8 mb-8">
        {/* TVL Chart */}
        <GlassCard>
          <div className="flex items-center justify-between mb-4">
            <h3 className="text-lg font-semibold text-white">Total Value Locked</h3>
            <BarChart3 className="w-5 h-5 text-white/40" />
          </div>
          <div className="h-64 flex items-end justify-between gap-2">
            {mockTVLData.map((item, index) => (
              <div key={index} className="flex-1 flex flex-col items-center gap-2">
                <div 
                  className="w-full bg-gradient-to-t from-blue-500 to-purple-500 rounded-t-lg hover:opacity-80 transition-opacity relative group"
                  style={{ height: `${(item.value / 175) * 100}%` }}
                >
                  <div className="absolute -top-8 left-1/2 -translate-x-1/2 bg-slate-800 px-2 py-1 rounded text-xs text-white opacity-0 group-hover:opacity-100 transition-opacity whitespace-nowrap">
                    {item.value} BTC
                  </div>
                </div>
                <span className="text-xs text-white/40">{item.date}</span>
              </div>
            ))}
          </div>
        </GlassCard>

        {/* Collateral Distribution */}
        <GlassCard>
          <div className="flex items-center justify-between mb-4">
            <h3 className="text-lg font-semibold text-white">Collateral Distribution</h3>
            <PieChart className="w-5 h-5 text-white/40" />
          </div>
          <div className="flex items-center justify-center h-48">
            <div className="relative w-48 h-48">
              {/* Pie chart visualization */}
              <svg className="w-full h-full transform -rotate-90">
                {mockCollateralDistribution.reduce((acc, item, index) => {
                  const startAngle = acc;
                  const angle = (item.value / 100) * 360;
                  const largeArcFlag = angle > 180 ? 1 : 0;
                  const x1 = 96 + 80 * Math.cos((startAngle * Math.PI) / 180);
                  const y1 = 96 + 80 * Math.sin((startAngle * Math.PI) / 180);
                  const x2 = 96 + 80 * Math.cos(((startAngle + angle) * Math.PI) / 180);
                  const y2 = 96 + 80 * Math.sin(((startAngle + angle) * Math.PI) / 180);
                  
                  return acc + angle;
                }, 0) && mockCollateralDistribution.map((item, index) => {
                  const startAngle = mockCollateralDistribution
                    .slice(0, index)
                    .reduce((sum, i) => sum + (i.value / 100) * 360, 0);
                  const angle = (item.value / 100) * 360;
                  
                  return (
                    <circle
                      key={index}
                      cx="96"
                      cy="96"
                      r="80"
                      fill="none"
                      stroke={
                        item.color === 'bg-orange-500' ? '#f97316' :
                        item.color === 'bg-blue-500' ? '#3b82f6' :
                        '#a855f7'
                      }
                      strokeWidth="40"
                      strokeDasharray={`${(angle / 360) * 502.65} 502.65`}
                      strokeDashoffset={-startAngle / 360 * 502.65}
                      className="transition-all duration-300 hover:opacity-80"
                    />
                  );
                })}
              </svg>
              <div className="absolute inset-0 flex items-center justify-center">
                <div className="text-center">
                  <p className="text-2xl font-bold text-white">{tvl.toFixed(2)}</p>
                  <p className="text-xs text-white/60">Total BTC</p>
                </div>
              </div>
            </div>
          </div>
          <div className="mt-4 space-y-2">
            {mockCollateralDistribution.map((item) => (
              <div key={item.name} className="flex items-center justify-between">
                <div className="flex items-center gap-2">
                  <div className={cn('w-3 h-3 rounded-full', item.color)} />
                  <span className="text-sm text-white/80">{item.name}</span>
                </div>
                <span className="text-sm text-white/60">{item.value}%</span>
              </div>
            ))}
          </div>
        </GlassCard>
      </div>

      {/* Recent Transactions */}
      <GlassCard>
        <div className="flex items-center justify-between mb-4">
          <h3 className="text-lg font-semibold text-white">Recent Transactions</h3>
          <Activity className="w-5 h-5 text-white/40" />
        </div>
        <div className="space-y-3">
          {mockRecentTransactions.map((tx, index) => (
            <div key={index} className="flex items-center justify-between p-3 bg-white/5 rounded-lg">
              <div className="flex items-center gap-3">
                {tx.type === 'deposit' ? (
                  <div className="w-8 h-8 bg-green-500/20 rounded-full flex items-center justify-center">
                    <ArrowDown className="w-4 h-4 text-green-400" />
                  </div>
                ) : (
                  <div className="w-8 h-8 bg-red-500/20 rounded-full flex items-center justify-center">
                    <ArrowUp className="w-4 h-4 text-red-400" />
                  </div>
                )}
                <div>
                  <p className="text-white font-medium capitalize">{tx.type}</p>
                  <p className="text-white/40 text-xs">{tx.user}</p>
                </div>
              </div>
              <div className="text-right">
                <p className="text-white font-medium">{tx.amount}</p>
                <div className="flex items-center gap-1 text-white/40">
                  <Clock className="w-3 h-3" />
                  <span className="text-xs">{tx.time}</span>
                </div>
              </div>
            </div>
          ))}
        </div>
      </GlassCard>
    </main>
  );
}