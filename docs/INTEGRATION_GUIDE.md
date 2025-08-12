# Multi-Collateral BTC Vault Integration Guide

## Overview

This guide provides comprehensive instructions for developers looking to integrate with the Multi-Collateral BTC Vault system. It covers smart contract interfaces, event monitoring, common integration patterns, and example implementations.

## Table of Contents

1. [Quick Start](#quick-start)
2. [Contract Interfaces](#contract-interfaces)
3. [Integration Methods](#integration-methods)
4. [Event Monitoring](#event-monitoring)
5. [Common Integration Patterns](#common-integration-patterns)
6. [Error Handling](#error-handling)
7. [Testing Your Integration](#testing-your-integration)
8. [API Reference](#api-reference)
9. [Code Examples](#code-examples)

## Quick Start

### Installation

```bash
# Install dependencies
npm install ethers @openzeppelin/contracts

# Or using yarn
yarn add ethers @openzeppelin/contracts
```

### Basic Integration

```javascript
import { ethers } from 'ethers';
import MultiBTCVaultABI from './abis/MultiBTCVault.json';

// Connect to provider
const provider = new ethers.providers.JsonRpcProvider(RPC_URL);
const signer = provider.getSigner();

// Initialize vault contract
const vaultAddress = '0x...'; // MultiBTCVault address
const vault = new ethers.Contract(vaultAddress, MultiBTCVaultABI, signer);

// Deposit WBTC
async function deposit(amount) {
    // Approve WBTC spending
    const wbtc = new ethers.Contract(WBTC_ADDRESS, ERC20_ABI, signer);
    await wbtc.approve(vaultAddress, amount);
    
    // Deposit and receive mcBTC shares
    const tx = await vault.deposit(amount, signer.address);
    await tx.wait();
    
    return tx.hash;
}
```

## Contract Interfaces

### Core Contracts

#### MultiBTCVault (ERC-4626)

```solidity
interface IMultiBTCVault is IERC4626 {
    // Deposit collateral and receive shares
    function deposit(uint256 assets, address receiver) 
        external returns (uint256 shares);
    
    // Request redemption (enters queue)
    function requestRedeem(uint256 shares, address receiver, address owner) 
        external returns (uint256 requestId);
    
    // View functions
    function totalAssets() external view returns (uint256);
    function convertToShares(uint256 assets) external view returns (uint256);
    function convertToAssets(uint256 shares) external view returns (uint256);
    function maxDeposit(address) external view returns (uint256);
    function maxRedeem(address owner) external view returns (uint256);
}
```

#### ManagedRedemptionQueue

```solidity
interface IManagedRedemptionQueue {
    // Redemption request structure
    struct RedemptionRequest {
        address requester;
        address receiver;
        uint256 shares;
        uint256 requestTimestamp;
        uint256 maturityTimestamp;
    }
    
    // View redemption request
    function redemptionRequests(uint256 requestId) 
        external view returns (RedemptionRequest memory);
    
    // Check if request is mature
    function isRequestMature(uint256 requestId) 
        external view returns (bool);
    
    // Get queue statistics
    function queueLength() external view returns (uint256);
    function totalSharesQueued() external view returns (uint256);
}
```

#### MultiCollateralRegistry

```solidity
interface IMultiCollateralRegistry {
    // Check if collateral is supported
    function isCollateralSupported(address token) 
        external view returns (bool);
    
    // Get collateral configuration
    function getCollateralConfig(address token) 
        external view returns (
            bool isActive,
            uint8 decimals,
            uint256 conversionRate
        );
    
    // List all supported collaterals
    function getSupportedCollaterals() 
        external view returns (address[] memory);
}
```

### Key Functions for Integration

#### Deposits

```javascript
// 1. Check if collateral is supported
const isSupported = await registry.isCollateralSupported(tokenAddress);

// 2. Get deposit preview
const expectedShares = await vault.previewDeposit(depositAmount);

// 3. Check minimum deposit
const minDeposit = ethers.utils.parseUnits("0.001", 8); // For WBTC
require(depositAmount >= minDeposit, "Below minimum");

// 4. Approve and deposit
await token.approve(vaultAddress, depositAmount);
const shares = await vault.deposit(depositAmount, userAddress);
```

#### Redemptions

```javascript
// 1. Check user's share balance
const shareBalance = await vault.balanceOf(userAddress);

// 2. Preview redemption value
const assetsToReceive = await vault.previewRedeem(shareAmount);

// 3. Request redemption (enters 14-day queue)
const requestId = await vault.requestRedeem(
    shareAmount,
    userAddress,  // receiver
    userAddress   // owner
);

// 4. Monitor redemption status
const request = await queue.redemptionRequests(requestId);
const isReady = await queue.isRequestMature(requestId);
```

## Integration Methods

### Method 1: Direct Smart Contract Integration

For dApps building custom smart contracts:

```solidity
pragma solidity ^0.8.25;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IMultiBTCVault} from "./interfaces/IMultiBTCVault.sol";

contract VaultIntegration {
    IMultiBTCVault public immutable vault;
    IERC20 public immutable wbtc;
    
    constructor(address _vault, address _wbtc) {
        vault = IMultiBTCVault(_vault);
        wbtc = IERC20(_wbtc);
    }
    
    function depositForUser(uint256 amount, address user) external {
        // Transfer WBTC from user
        wbtc.transferFrom(msg.sender, address(this), amount);
        
        // Approve vault
        wbtc.approve(address(vault), amount);
        
        // Deposit and send shares to user
        vault.deposit(amount, user);
    }
}
```

### Method 2: Web3 Frontend Integration

For web applications:

```javascript
import { ethers } from 'ethers';
import { useState, useEffect } from 'react';

function VaultInterface() {
    const [vault, setVault] = useState(null);
    const [userShares, setUserShares] = useState('0');
    
    useEffect(() => {
        initializeVault();
    }, []);
    
    async function initializeVault() {
        const provider = new ethers.providers.Web3Provider(window.ethereum);
        const signer = provider.getSigner();
        const vaultContract = new ethers.Contract(
            VAULT_ADDRESS,
            VAULT_ABI,
            signer
        );
        setVault(vaultContract);
        
        // Load user balance
        const address = await signer.getAddress();
        const balance = await vaultContract.balanceOf(address);
        setUserShares(ethers.utils.formatEther(balance));
    }
    
    async function handleDeposit(amount) {
        try {
            const tx = await vault.deposit(
                ethers.utils.parseUnits(amount, 8), // WBTC decimals
                await vault.signer.getAddress()
            );
            await tx.wait();
            console.log('Deposit successful:', tx.hash);
        } catch (error) {
            console.error('Deposit failed:', error);
        }
    }
}
```

### Method 3: Backend Service Integration

For automated services and bots:

```javascript
const { ethers } = require('ethers');
const cron = require('node-cron');

class VaultService {
    constructor(rpcUrl, privateKey) {
        this.provider = new ethers.providers.JsonRpcProvider(rpcUrl);
        this.wallet = new ethers.Wallet(privateKey, this.provider);
        this.vault = new ethers.Contract(VAULT_ADDRESS, VAULT_ABI, this.wallet);
    }
    
    async monitorAndDeposit() {
        // Check wallet balance
        const wbtcBalance = await this.getWBTCBalance();
        
        // Auto-deposit if balance exceeds threshold
        const threshold = ethers.utils.parseUnits("0.1", 8);
        if (wbtcBalance.gt(threshold)) {
            await this.deposit(wbtcBalance);
        }
    }
    
    async deposit(amount) {
        // Approve WBTC
        const wbtc = new ethers.Contract(WBTC_ADDRESS, ERC20_ABI, this.wallet);
        const approveTx = await wbtc.approve(this.vault.address, amount);
        await approveTx.wait();
        
        // Deposit
        const depositTx = await this.vault.deposit(amount, this.wallet.address);
        await depositTx.wait();
        
        console.log(`Deposited ${amount} WBTC at ${depositTx.hash}`);
    }
}

// Schedule automatic deposits
cron.schedule('0 0 * * *', async () => {
    const service = new VaultService(RPC_URL, PRIVATE_KEY);
    await service.monitorAndDeposit();
});
```

## Event Monitoring

### Key Events to Monitor

```solidity
// Deposit event
event Deposit(
    address indexed sender,
    address indexed owner,
    uint256 assets,
    uint256 shares
);

// Redemption request event
event RedemptionRequested(
    uint256 indexed requestId,
    address indexed requester,
    address indexed receiver,
    uint256 shares,
    uint256 maturityTimestamp
);

// Redemption processed event
event RedemptionProcessed(
    uint256 indexed requestId,
    address indexed receiver,
    uint256 shares,
    uint256 assets
);

// NAV update event
event NAVUpdated(
    uint256 oldNAV,
    uint256 newNAV,
    uint256 timestamp
);
```

### Event Listening Implementation

```javascript
// Listen for deposits
vault.on("Deposit", (sender, owner, assets, shares, event) => {
    console.log(`Deposit: ${sender} deposited ${assets} for ${shares} shares`);
    // Update UI or database
});

// Listen for redemption requests
vault.on("RedemptionRequested", (requestId, requester, receiver, shares, maturity) => {
    console.log(`Redemption #${requestId} requested by ${requester}`);
    // Track in database
});

// Listen for NAV updates
oracle.on("NAVUpdated", (oldNAV, newNAV, timestamp) => {
    console.log(`NAV updated from ${oldNAV} to ${newNAV}`);
    // Update calculations
});

// Query historical events
const filter = vault.filters.Deposit(null, userAddress);
const events = await vault.queryFilter(filter, startBlock, endBlock);
```

## Common Integration Patterns

### Pattern 1: Deposit with Slippage Protection

```javascript
async function depositWithSlippageProtection(amount, maxSlippage = 0.01) {
    // Get expected shares
    const expectedShares = await vault.previewDeposit(amount);
    
    // Calculate minimum acceptable shares (1% slippage)
    const minShares = expectedShares.mul(100 - maxSlippage * 100).div(100);
    
    // Check current share calculation
    const actualShares = await vault.previewDeposit(amount);
    
    if (actualShares.lt(minShares)) {
        throw new Error('Slippage too high');
    }
    
    // Proceed with deposit
    return await vault.deposit(amount, signer.address);
}
```

### Pattern 2: Batched Deposits

```javascript
async function batchDeposit(deposits) {
    const multicall = new ethers.Contract(MULTICALL_ADDRESS, MULTICALL_ABI, signer);
    
    const calls = deposits.map(({ token, amount }) => ({
        target: vault.address,
        callData: vault.interface.encodeFunctionData('deposit', [amount, signer.address])
    }));
    
    const tx = await multicall.aggregate(calls);
    return await tx.wait();
}
```

### Pattern 3: Auto-Compound Yields

```javascript
class AutoCompounder {
    async compound() {
        // Get current share value
        const shareValue = await vault.convertToAssets(ethers.utils.parseEther("1"));
        
        // Get user's redeemable value
        const userShares = await vault.balanceOf(this.userAddress);
        const totalValue = await vault.convertToAssets(userShares);
        
        // Calculate yield (if any excess over principal)
        const yield = totalValue.sub(this.principal);
        
        if (yield.gt(0)) {
            // Redeem yield and re-deposit
            await vault.requestRedeem(yield, this.userAddress, this.userAddress);
            // Wait 14 days, then re-deposit
        }
    }
}
```

### Pattern 4: Liquidity Provider Integration

```javascript
class LiquidityProvider {
    async provideLiquidity(amount) {
        // Deposit to vault
        const shares = await vault.deposit(amount, this.address);
        
        // Use shares as collateral elsewhere
        await lendingProtocol.depositCollateral(vault.address, shares);
        
        // Borrow against mcBTC shares
        const borrowAmount = shares.mul(60).div(100); // 60% LTV
        await lendingProtocol.borrow(borrowAmount);
    }
}
```

## Error Handling

### Common Errors and Solutions

```javascript
const ERROR_CODES = {
    'MINIMUM_NOT_MET': 'Deposit amount below 0.001 BTC minimum',
    'PAUSED': 'Vault is temporarily paused',
    'INSUFFICIENT_ALLOWANCE': 'Token approval needed',
    'INSUFFICIENT_BALANCE': 'Insufficient token balance',
    'REDEMPTION_NOT_MATURE': 'Redemption still in 14-day waiting period',
    'INVALID_COLLATERAL': 'Token not supported as collateral'
};

async function handleVaultOperation(operation) {
    try {
        return await operation();
    } catch (error) {
        // Parse revert reason
        const reason = error.reason || error.message;
        
        // Handle specific errors
        if (reason.includes('Minimum deposit not met')) {
            console.error('Deposit must be at least 0.001 BTC');
            return null;
        }
        
        if (reason.includes('Paused')) {
            console.error('Vault is paused for maintenance');
            return null;
        }
        
        // Log unknown errors
        console.error('Vault operation failed:', error);
        throw error;
    }
}
```

### Retry Logic

```javascript
async function retryWithBackoff(fn, maxRetries = 3) {
    for (let i = 0; i < maxRetries; i++) {
        try {
            return await fn();
        } catch (error) {
            if (i === maxRetries - 1) throw error;
            
            // Exponential backoff
            const delay = Math.pow(2, i) * 1000;
            await new Promise(resolve => setTimeout(resolve, delay));
        }
    }
}

// Usage
const result = await retryWithBackoff(() => 
    vault.deposit(amount, userAddress)
);
```

## Testing Your Integration

### Unit Tests

```javascript
const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Vault Integration", function() {
    let vault, wbtc, user;
    
    beforeEach(async function() {
        [user] = await ethers.getSigners();
        // Deploy or connect to contracts
    });
    
    it("Should deposit WBTC and receive mcBTC shares", async function() {
        const depositAmount = ethers.utils.parseUnits("0.1", 8);
        
        // Approve and deposit
        await wbtc.approve(vault.address, depositAmount);
        await vault.deposit(depositAmount, user.address);
        
        // Check shares received
        const shares = await vault.balanceOf(user.address);
        expect(shares).to.be.gt(0);
    });
    
    it("Should handle redemption queue correctly", async function() {
        const shares = await vault.balanceOf(user.address);
        
        // Request redemption
        const tx = await vault.requestRedeem(shares, user.address, user.address);
        const receipt = await tx.wait();
        
        // Check event emitted
        const event = receipt.events.find(e => e.event === 'RedemptionRequested');
        expect(event).to.not.be.undefined;
    });
});
```

### Integration Tests

```javascript
describe("End-to-End Integration", function() {
    it("Complete deposit and redemption cycle", async function() {
        // 1. Deposit WBTC
        const deposit = ethers.utils.parseUnits("1", 8);
        await wbtc.approve(vault.address, deposit);
        await vault.deposit(deposit, user.address);
        
        // 2. Check shares
        const shares = await vault.balanceOf(user.address);
        console.log(`Received ${shares} mcBTC shares`);
        
        // 3. Request redemption
        await vault.requestRedeem(shares, user.address, user.address);
        
        // 4. Wait 14 days (in test, use time manipulation)
        await network.provider.send("evm_increaseTime", [14 * 24 * 3600]);
        await network.provider.send("evm_mine");
        
        // 5. Process redemption (admin action)
        await queue.connect(admin).processRedemptions(1);
        
        // 6. Check sovaBTC received
        const sovaBTCBalance = await sovaBTC.balanceOf(user.address);
        expect(sovaBTCBalance).to.be.gt(0);
    });
});
```

## API Reference

### Read Functions (View/Pure)

| Function | Description | Parameters | Returns |
|----------|-------------|------------|---------|
| `totalAssets()` | Total BTC value in vault | None | `uint256` |
| `totalSupply()` | Total mcBTC shares | None | `uint256` |
| `balanceOf(address)` | User's mcBTC balance | `owner` | `uint256` |
| `convertToShares(uint256)` | Preview shares for assets | `assets` | `uint256` |
| `convertToAssets(uint256)` | Preview assets for shares | `shares` | `uint256` |
| `maxDeposit(address)` | Maximum deposit allowed | `receiver` | `uint256` |
| `maxRedeem(address)` | Maximum redeemable shares | `owner` | `uint256` |
| `previewDeposit(uint256)` | Preview deposit result | `assets` | `uint256` |
| `previewRedeem(uint256)` | Preview redemption result | `shares` | `uint256` |

### Write Functions (State-Changing)

| Function | Description | Parameters | Returns |
|----------|-------------|------------|---------|
| `deposit(uint256,address)` | Deposit collateral | `assets`, `receiver` | `shares` |
| `mint(uint256,address)` | Mint specific shares | `shares`, `receiver` | `assets` |
| `requestRedeem(uint256,address,address)` | Queue redemption | `shares`, `receiver`, `owner` | `requestId` |
| `approve(address,uint256)` | Approve share spending | `spender`, `amount` | `bool` |
| `transfer(address,uint256)` | Transfer shares | `to`, `amount` | `bool` |

### Admin Functions

| Function | Description | Access |
|----------|-------------|--------|
| `pause()` | Pause vault operations | ADMIN_ROLE |
| `unpause()` | Resume operations | ADMIN_ROLE |
| `updateOracle(uint256)` | Update NAV | REPORTER_ROLE |
| `processRedemptions(uint256)` | Process queue | OPERATOR_ROLE |
| `rescueTokens(address,uint256)` | Rescue stuck tokens | ADMIN_ROLE |

## Code Examples

### Complete Integration Example

```javascript
// Full integration example with error handling and events
class VaultIntegration {
    constructor(provider, signer) {
        this.provider = provider;
        this.signer = signer;
        this.vault = new ethers.Contract(VAULT_ADDRESS, VAULT_ABI, signer);
        this.setupEventListeners();
    }
    
    setupEventListeners() {
        this.vault.on("Deposit", this.handleDeposit.bind(this));
        this.vault.on("RedemptionRequested", this.handleRedemption.bind(this));
    }
    
    async deposit(tokenAddress, amount) {
        try {
            // Validate inputs
            if (!await this.isCollateralSupported(tokenAddress)) {
                throw new Error("Unsupported collateral");
            }
            
            // Check minimum
            const minDeposit = ethers.utils.parseUnits("0.001", 8);
            if (amount.lt(minDeposit)) {
                throw new Error("Below minimum deposit");
            }
            
            // Approve token
            const token = new ethers.Contract(tokenAddress, ERC20_ABI, this.signer);
            const allowance = await token.allowance(this.signer.address, this.vault.address);
            if (allowance.lt(amount)) {
                const approveTx = await token.approve(this.vault.address, amount);
                await approveTx.wait();
            }
            
            // Execute deposit
            const depositTx = await this.vault.deposit(amount, this.signer.address);
            const receipt = await depositTx.wait();
            
            // Parse events
            const event = receipt.events.find(e => e.event === 'Deposit');
            const shares = event.args.shares;
            
            return {
                success: true,
                txHash: receipt.transactionHash,
                shares: shares.toString(),
                gasUsed: receipt.gasUsed.toString()
            };
            
        } catch (error) {
            return {
                success: false,
                error: error.message
            };
        }
    }
    
    async requestRedemption(shares) {
        try {
            // Check balance
            const balance = await this.vault.balanceOf(this.signer.address);
            if (balance.lt(shares)) {
                throw new Error("Insufficient shares");
            }
            
            // Request redemption
            const tx = await this.vault.requestRedeem(
                shares,
                this.signer.address,
                this.signer.address
            );
            const receipt = await tx.wait();
            
            // Get request ID from events
            const event = receipt.events.find(e => e.event === 'RedemptionRequested');
            const requestId = event.args.requestId;
            
            return {
                success: true,
                requestId: requestId.toString(),
                maturityDate: new Date(Date.now() + 14 * 24 * 60 * 60 * 1000)
            };
            
        } catch (error) {
            return {
                success: false,
                error: error.message
            };
        }
    }
    
    async getPosition() {
        const address = await this.signer.getAddress();
        const shares = await this.vault.balanceOf(address);
        const assets = await this.vault.convertToAssets(shares);
        
        return {
            shares: ethers.utils.formatEther(shares),
            btcValue: ethers.utils.formatUnits(assets, 8),
            currentNAV: await this.getCurrentNAV()
        };
    }
    
    handleDeposit(sender, owner, assets, shares, event) {
        console.log(`Deposit detected: ${sender} -> ${shares} shares`);
        // Update UI or send notification
    }
    
    handleRedemption(requestId, requester, receiver, shares, maturity, event) {
        console.log(`Redemption #${requestId} requested, matures ${new Date(maturity * 1000)}`);
        // Track redemption
    }
}

// Usage
const integration = new VaultIntegration(provider, signer);
const result = await integration.deposit(WBTC_ADDRESS, depositAmount);
console.log(result);
```

## Additional Resources

- [User Guide](./USER_GUIDE.md) - For end users
- [Admin Manual](./ADMIN_MANUAL.md) - For administrators
- [Security Documentation](./SECURITY.md) - Security considerations
- [GitHub Repository](https://github.com/SovaNetwork/multi-collateral-vault)
- [Smart Contract Documentation](../contracts/README.md)

## Support

For integration support:
- Email: dev-support@sovanetwork.com
- Discord: #dev-support
- GitHub Issues: [Report Issue](https://github.com/SovaNetwork/multi-collateral-vault/issues)

---

*Last Updated: [Current Date]*
*Version: 1.0.0*