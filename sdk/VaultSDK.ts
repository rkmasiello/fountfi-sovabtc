import { ethers, Contract, Signer, Provider, ContractTransaction, BigNumberish } from 'ethers';

export interface VaultStats {
  tvl: string;
  totalShares: string;
  sharePrice: string;
}

export interface UserPosition {
  shares: string;
  value: string;
  address: string;
}

export interface RedemptionRequest {
  id?: string;
  user: string;
  shares: string;
  requestedAt: Date;
  processed: boolean;
  claimed: boolean;
  redeemableAmount: string;
}

export interface TokenBalances {
  wbtc: string;
  tbtc: string;
  sovaBTC: string;
}

export enum CollateralToken {
  WBTC = 'wbtc',
  TBTC = 'tbtc',
  SOVABTC = 'sovaBTC'
}

export interface ContractAddresses {
  vault: string;
  queue: string;
  registry: string;
  strategy: string;
  priceOracle: string;
  roleManager: string;
  wbtc: string;
  tbtc: string;
  sovaBTC: string;
}

// Base Sepolia addresses
export const BASE_SEPOLIA_ADDRESSES: ContractAddresses = {
  vault: "0x73E27097221d4d9D5893a83350dC7A967b46fab7",
  queue: "0x22BC73098CE1Ba2CaE5431fb32051cB4fc0F9C52",
  registry: "0x15a9983784617aa8892b2677bbaEc23539482B65",
  strategy: "0x740907524EbD6A481a81cE76B5115A4cDDb80099",
  priceOracle: "0xDB4479A2360E118CCbD99B88e82522813BDE48f5",
  roleManager: "0x15502fC5e872c8B22BA6dD5e01A7A5bd4f9A3d72",
  wbtc: "0xe44b2870eFcd6Bb3C9305808012621f438e9636D",
  tbtc: "0xE2b47f0dD766834b9DD2612D2d3632B05Ca89802",
  sovaBTC: "0x05aB19d77516414f7333a8fd52cC1F49FF8eAFA9"
};

// Simplified ABIs
const VAULT_ABI = [
  "function deposit(address asset, uint256 assets, address receiver) returns (uint256 shares)",
  "function requestRedemption(uint256 shares) returns (uint256 requestId)",
  "function totalAssets() view returns (uint256)",
  "function totalSupply() view returns (uint256)",
  "function balanceOf(address account) view returns (uint256)",
  "function sharePrice() view returns (uint256)",
  "event RedemptionRequested(uint256 indexed requestId, address indexed user, uint256 shares)"
];

const QUEUE_ABI = [
  "function claimRedemption(uint256 requestId)",
  "function getRedemptionRequest(uint256 requestId) view returns (tuple(address user, uint256 shares, uint256 requestedAt, bool processed, bool claimed, uint256 redeemableAmount))",
  "function getUserRequests(address user) view returns (uint256[])",
  "function getTotalPendingShares() view returns (uint256)",
  "function processRedemptions(uint256[] calldata requestIds)"
];

const ERC20_ABI = [
  "function balanceOf(address account) view returns (uint256)",
  "function approve(address spender, uint256 amount) returns (bool)",
  "function allowance(address owner, address spender) view returns (uint256)",
  "function mint(uint256 amount)",
  "function decimals() view returns (uint8)",
  "function symbol() view returns (string)"
];

export class MultiBTCVaultSDK {
  private provider: Provider;
  private signer?: Signer;
  private vault: Contract;
  private queue: Contract;
  private tokens: Record<CollateralToken, Contract>;
  private addresses: ContractAddresses;

  constructor(
    provider: Provider,
    signer?: Signer,
    addresses: ContractAddresses = BASE_SEPOLIA_ADDRESSES
  ) {
    this.provider = provider;
    this.signer = signer;
    this.addresses = addresses;
    
    const signerOrProvider = signer || provider;
    
    // Initialize contracts
    this.vault = new Contract(addresses.vault, VAULT_ABI, signerOrProvider);
    this.queue = new Contract(addresses.queue, QUEUE_ABI, signerOrProvider);
    
    // Initialize token contracts
    this.tokens = {
      [CollateralToken.WBTC]: new Contract(addresses.wbtc, ERC20_ABI, signerOrProvider),
      [CollateralToken.TBTC]: new Contract(addresses.tbtc, ERC20_ABI, signerOrProvider),
      [CollateralToken.SOVABTC]: new Contract(addresses.sovaBTC, ERC20_ABI, signerOrProvider)
    };
  }

  // Static factory methods
  static async connectWallet(
    addresses: ContractAddresses = BASE_SEPOLIA_ADDRESSES
  ): Promise<MultiBTCVaultSDK> {
    if (typeof window === 'undefined' || !window.ethereum) {
      throw new Error('No wallet detected. Please install MetaMask.');
    }
    
    await window.ethereum.request({ method: 'eth_requestAccounts' });
    const provider = new ethers.BrowserProvider(window.ethereum);
    const signer = await provider.getSigner();
    
    return new MultiBTCVaultSDK(provider, signer, addresses);
  }

  static connectWithPrivateKey(
    privateKey: string,
    rpcUrl: string,
    addresses: ContractAddresses = BASE_SEPOLIA_ADDRESSES
  ): MultiBTCVaultSDK {
    const provider = new ethers.JsonRpcProvider(rpcUrl);
    const signer = new ethers.Wallet(privateKey, provider);
    
    return new MultiBTCVaultSDK(provider, signer, addresses);
  }

  static readOnly(
    rpcUrl: string,
    addresses: ContractAddresses = BASE_SEPOLIA_ADDRESSES
  ): MultiBTCVaultSDK {
    const provider = new ethers.JsonRpcProvider(rpcUrl);
    return new MultiBTCVaultSDK(provider, undefined, addresses);
  }

  // Core vault functions
  async getVaultStats(): Promise<VaultStats> {
    const [totalAssets, totalSupply, sharePrice] = await Promise.all([
      this.vault.totalAssets(),
      this.vault.totalSupply(),
      this.vault.sharePrice()
    ]);
    
    return {
      tvl: ethers.formatUnits(totalAssets, 8),
      totalShares: ethers.formatEther(totalSupply),
      sharePrice: ethers.formatEther(sharePrice)
    };
  }

  async getUserPosition(address?: string): Promise<UserPosition> {
    const userAddress = address || await this.requireSigner().getAddress();
    const balance = await this.vault.balanceOf(userAddress);
    const sharePrice = await this.vault.sharePrice();
    
    const shares = ethers.formatEther(balance);
    const value = parseFloat(shares) * parseFloat(ethers.formatEther(sharePrice));
    
    return {
      shares,
      value: value.toFixed(8),
      address: userAddress
    };
  }

  async deposit(
    token: CollateralToken,
    amount: string | number
  ): Promise<ContractTransaction> {
    this.requireSigner();
    
    const tokenContract = this.tokens[token];
    const tokenAddress = await tokenContract.getAddress();
    const decimals = await tokenContract.decimals();
    const amountWei = ethers.parseUnits(amount.toString(), decimals);
    
    // Check and approve if needed
    const userAddress = await this.signer!.getAddress();
    const allowance = await tokenContract.allowance(userAddress, this.addresses.vault);
    
    if (allowance < amountWei) {
      const approveTx = await tokenContract.approve(this.addresses.vault, amountWei);
      await approveTx.wait();
    }
    
    // Deposit
    return await this.vault.deposit(tokenAddress, amountWei, userAddress);
  }

  async requestRedemption(shares: string | number): Promise<{
    tx: ContractTransaction;
    requestId?: bigint;
  }> {
    this.requireSigner();
    
    const sharesWei = ethers.parseEther(shares.toString());
    const tx = await this.vault.requestRedemption(sharesWei);
    
    // Wait for transaction and parse event
    const receipt = await tx.wait();
    const event = receipt?.logs.find((log: any) => {
      try {
        const parsed = this.vault.interface.parseLog(log);
        return parsed?.name === 'RedemptionRequested';
      } catch {
        return false;
      }
    });
    
    const requestId = event ? BigInt(event.topics[1]) : undefined;
    
    return { tx, requestId };
  }

  async getRedemptionStatus(requestId: BigNumberish): Promise<RedemptionRequest> {
    const request = await this.queue.getRedemptionRequest(requestId);
    
    return {
      user: request[0],
      shares: ethers.formatEther(request[1]),
      requestedAt: new Date(Number(request[2]) * 1000),
      processed: request[3],
      claimed: request[4],
      redeemableAmount: ethers.formatUnits(request[5], 8)
    };
  }

  async getUserRequests(address?: string): Promise<RedemptionRequest[]> {
    const userAddress = address || await this.requireSigner().getAddress();
    const requestIds = await this.queue.getUserRequests(userAddress);
    
    const requests: RedemptionRequest[] = [];
    for (const id of requestIds) {
      const status = await this.getRedemptionStatus(id);
      requests.push({ id: id.toString(), ...status });
    }
    
    return requests;
  }

  async claimRedemption(requestId: BigNumberish): Promise<ContractTransaction> {
    this.requireSigner();
    return await this.queue.claimRedemption(requestId);
  }

  // Token functions
  async getTokenBalances(address?: string): Promise<TokenBalances> {
    const userAddress = address || await this.requireSigner().getAddress();
    const balances: TokenBalances = { wbtc: '0', tbtc: '0', sovaBTC: '0' };
    
    for (const [token, contract] of Object.entries(this.tokens)) {
      const balance = await contract.balanceOf(userAddress);
      const decimals = await contract.decimals();
      balances[token as keyof TokenBalances] = ethers.formatUnits(balance, decimals);
    }
    
    return balances;
  }

  async mintTestTokens(
    token: CollateralToken,
    amount: string | number
  ): Promise<ContractTransaction> {
    this.requireSigner();
    
    const tokenContract = this.tokens[token];
    const decimals = await tokenContract.decimals();
    const amountWei = ethers.parseUnits(amount.toString(), decimals);
    
    return await tokenContract.mint(amountWei);
  }

  // Admin functions
  async processRedemptions(requestIds: BigNumberish[]): Promise<ContractTransaction> {
    this.requireSigner();
    return await this.queue.processRedemptions(requestIds);
  }

  async getTotalPendingShares(): Promise<string> {
    const pending = await this.queue.getTotalPendingShares();
    return ethers.formatEther(pending);
  }

  // Helper methods
  private requireSigner(): Signer {
    if (!this.signer) {
      throw new Error('Signer required for this operation. Please connect a wallet.');
    }
    return this.signer;
  }

  getSigner(): Signer | undefined {
    return this.signer;
  }

  getProvider(): Provider {
    return this.provider;
  }

  getAddresses(): ContractAddresses {
    return this.addresses;
  }
}

// Export default RPC URL for Base Sepolia
export const BASE_SEPOLIA_RPC = "https://base-sepolia.g.alchemy.com/v2/e7qIcHOK60Sc4-hvyWA68";

// Convenience function for quick setup
export async function createVaultSDK(
  privateKeyOrConnect: string | 'wallet',
  rpcUrl: string = BASE_SEPOLIA_RPC
): Promise<MultiBTCVaultSDK> {
  if (privateKeyOrConnect === 'wallet') {
    return MultiBTCVaultSDK.connectWallet();
  } else {
    return MultiBTCVaultSDK.connectWithPrivateKey(privateKeyOrConnect, rpcUrl);
  }
}