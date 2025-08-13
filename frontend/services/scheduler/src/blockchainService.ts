import { PrismaClient } from '@prisma/client';
import { ethers } from 'ethers';

// Import ABIs (we'll use the same ones from the frontend)
import BTC_VAULT_TOKEN_ABI from '../../../lib/abis.js';
import BTC_VAULT_STRATEGY_ABI from '../../../lib/abis.js';

export class BlockchainService {
  private prisma: PrismaClient;
  private providers: Map<number, ethers.JsonRpcProvider> = new Map();
  
  constructor(prisma: PrismaClient) {
    this.prisma = prisma;
  }
  
  private getProvider(chainId: number): ethers.JsonRpcProvider {
    if (!this.providers.has(chainId)) {
      let rpcUrl: string;
      
      switch (chainId) {
        case 84532: // Base Sepolia
          rpcUrl = process.env.BASE_SEPOLIA_RPC_URL || 'https://sepolia.base.org';
          break;
        case 8453: // Base
          rpcUrl = process.env.BASE_RPC_URL || 'https://mainnet.base.org';
          break;
        case 1: // Ethereum
          rpcUrl = process.env.ETHEREUM_RPC_URL || 'https://eth.llamarpc.com';
          break;
        case 42161: // Arbitrum
          rpcUrl = process.env.ARBITRUM_RPC_URL || 'https://arb1.arbitrum.io/rpc';
          break;
        case 10: // Optimism
          rpcUrl = process.env.OPTIMISM_RPC_URL || 'https://mainnet.optimism.io';
          break;
        default:
          throw new Error(`Unsupported chain ID: ${chainId}`);
      }
      
      this.providers.set(chainId, new ethers.JsonRpcProvider(rpcUrl));
    }
    
    return this.providers.get(chainId)!;
  }
  
  async fetchRealMetrics(chainId: number, deploymentId: string) {
    try {
      const deployment = await this.prisma.sovaBtcDeployment.findUnique({
        where: { id: deploymentId },
      });
      
      if (!deployment || !deployment.vaultToken || !deployment.vaultStrategy) {
        throw new Error('Deployment not found or incomplete');
      }
      
      const provider = this.getProvider(chainId);
      
      // Create contract instances
      const vaultToken = new ethers.Contract(
        deployment.vaultToken,
        ['function totalAssets() view returns (uint256)', 'function totalSupply() view returns (uint256)'],
        provider
      );
      
      const vaultStrategy = new ethers.Contract(
        deployment.vaultStrategy,
        ['function sovaBtcBalance() view returns (uint256)'],
        provider
      );
      
      // Fetch on-chain data
      const [totalAssets, totalSupply, sovaBtcBalance, blockNumber] = await Promise.all([
        vaultToken.totalAssets(),
        vaultToken.totalSupply(),
        vaultStrategy.sovaBtcBalance(),
        provider.getBlockNumber(),
      ]);
      
      // Calculate metrics
      const tvl = ethers.formatUnits(totalAssets, 18);
      const sharePrice = totalSupply > 0n ? (totalAssets * 10000n) / totalSupply : 10000n;
      const utilizationRate = totalAssets > 0n 
        ? Number((sovaBtcBalance * 10000n) / totalAssets) / 100 
        : 0;
      
      // Save metrics to database
      await this.prisma.sovaBtcDeploymentMetrics.create({
        data: {
          deploymentId,
          tvl: parseFloat(tvl),
          apy: Math.random() * 10, // TODO: Calculate real APY from historical data
          totalUsers: 0, // TODO: Get from indexer
          totalTransactions: 0, // TODO: Get from indexer
          utilizationRate,
          timestamp: new Date(),
        },
      });
      
      // Update network metrics
      const gasPrice = await provider.getFeeData();
      await this.prisma.sovaBtcNetworkMetrics.create({
        data: {
          networkId: deployment.networkId,
          blockHeight: blockNumber,
          gasPrice: Number(gasPrice.gasPrice || 0n) / 1e9, // Convert to Gwei
          latency: 100, // TODO: Measure actual latency
          timestamp: new Date(),
        },
      });
      
      console.log(`Metrics saved for chain ${chainId}: TVL=${tvl}, SharePrice=${sharePrice.toString()}`);
    } catch (error) {
      console.error(`Error fetching metrics for chain ${chainId}:`, error);
      throw error;
    }
  }
  
  async syncCollateralsToDatabase(chainId: number, deploymentId: string) {
    try {
      const deployment = await this.prisma.sovaBtcDeployment.findUnique({
        where: { id: deploymentId },
      });
      
      if (!deployment || !deployment.vaultStrategy) {
        throw new Error('Deployment not found or strategy address missing');
      }
      
      const provider = this.getProvider(chainId);
      
      // Create strategy contract instance
      const strategy = new ethers.Contract(
        deployment.vaultStrategy,
        [
          'function isSupportedCollateral(address) view returns (bool)',
          'function getCollateralDecimals(address) view returns (uint8)',
        ],
        provider
      );
      
      // Get known collateral addresses from token registry
      const tokenRegistry = await this.prisma.sovaBtcTokenRegistry.findMany({
        where: {
          addresses: {
            path: [chainId.toString()],
            not: 'null',
          },
        },
      });
      
      // Check each token and sync if it's a supported collateral
      for (const token of tokenRegistry) {
        const tokenAddress = (token.addresses as any)[chainId.toString()];
        if (!tokenAddress || tokenAddress === '') continue;
        
        try {
          const isSupported = await strategy.isSupportedCollateral(tokenAddress);
          
          if (isSupported) {
            const decimals = await strategy.getCollateralDecimals(tokenAddress);
            
            // Upsert collateral in database
            await this.prisma.sovaBtcCollateral.upsert({
              where: {
                deploymentId_address: {
                  deploymentId,
                  address: tokenAddress.toLowerCase(),
                },
              },
              create: {
                deploymentId,
                chainId,
                symbol: token.symbol,
                name: token.name,
                address: tokenAddress.toLowerCase(),
                decimals: Number(decimals),
                isActive: true,
                addedAt: new Date(),
              },
              update: {
                isActive: true,
                decimals: Number(decimals),
              },
            });
            
            console.log(`Synced collateral ${token.symbol} on chain ${chainId}`);
          }
        } catch (error) {
          console.error(`Error checking collateral ${token.symbol}:`, error);
        }
      }
      
      // Mark collaterals as inactive if they're no longer supported
      const existingCollaterals = await this.prisma.sovaBtcCollateral.findMany({
        where: { deploymentId },
      });
      
      for (const collateral of existingCollaterals) {
        try {
          const isSupported = await strategy.isSupportedCollateral(collateral.address);
          
          if (!isSupported && collateral.isActive) {
            await this.prisma.sovaBtcCollateral.update({
              where: { id: collateral.id },
              data: { isActive: false },
            });
            
            console.log(`Marked collateral ${collateral.symbol} as inactive on chain ${chainId}`);
          }
        } catch (error) {
          console.error(`Error updating collateral ${collateral.symbol}:`, error);
        }
      }
    } catch (error) {
      console.error(`Error syncing collaterals for chain ${chainId}:`, error);
      throw error;
    }
  }
}