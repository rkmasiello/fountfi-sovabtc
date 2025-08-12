# User Guide - Multi-Collateral BTC Vault

Welcome to the Multi-Collateral BTC Vault! This guide will help you understand how to use the vault to deposit Bitcoin-pegged assets and manage your holdings.

## Table of Contents
- [Overview](#overview)
- [Getting Started](#getting-started)
- [Depositing Assets](#depositing-assets)
- [Managing Your Position](#managing-your-position)
- [Requesting Withdrawals](#requesting-withdrawals)
- [Understanding Vault Shares](#understanding-vault-shares)
- [FAQ](#faq)
- [Troubleshooting](#troubleshooting)

## Overview

The Multi-Collateral BTC Vault allows you to:
- Deposit various forms of wrapped Bitcoin (WBTC, TBTC, sovaBTC)
- Receive vault shares representing your ownership
- Redeem shares for sovaBTC when you want to withdraw
- Benefit from professional liquidity management

### Key Features
- **1:1 BTC Pegging**: All supported BTC variants are valued equally
- **ERC4626 Standard**: Compatible with DeFi protocols
- **Managed Withdrawals**: Secure redemption process with admin oversight
- **Transparent Pricing**: Real-time share price calculations

## Getting Started

### Prerequisites

1. **Web3 Wallet**: MetaMask, WalletConnect, or similar
2. **Base Sepolia ETH**: For gas fees (get from [faucet](https://www.alchemy.com/faucets/base-sepolia))
3. **BTC Assets**: WBTC, TBTC, or sovaBTC tokens

### Connecting to the Vault

1. Visit the vault interface at http://localhost:3003 (or production URL)
2. Click "Connect Wallet" in the top right
3. Select Base Sepolia network (Chain ID: 84532)
4. Approve the connection request

### Getting Test Tokens (Testnet Only)

For testing on Base Sepolia, test tokens have been deployed:
- **WBTC**: `0xe44b2870eFcd6Bb3C9305808012621f438e9636D`
- **TBTC**: `0xE2b47f0dD766834b9DD2612D2d3632B05Ca89802`
- **sovaBTC**: `0x05aB19d77516414f7333a8fd52cC1F49FF8eAFA9`

## Depositing Assets

### Step-by-Step Deposit Process

1. **Select Collateral Type**
   - Choose from WBTC, TBTC, or sovaBTC
   - All are valued at 1:1 ratio

2. **Enter Amount**
   - Input the amount you wish to deposit
   - Minimum: 0.00001 BTC (1000 satoshis)
   - Maximum: Your wallet balance

3. **Preview Transaction**
   - Review the shares you'll receive
   - Check the current share price
   - Verify gas fees

4. **Approve Token Spending** (First time only)
   - Approve the vault to spend your tokens
   - This is a one-time approval per token type

5. **Confirm Deposit**
   - Click "Deposit"
   - Confirm the transaction in your wallet
   - Wait for confirmation (usually 10-30 seconds)

### Understanding Share Calculation

```
Shares Received = Deposit Amount × (Total Shares / Total Assets)
```

For the first deposit, shares are minted at a 1:1 ratio with 18 decimal precision.

### Using the Smart Contract Directly

```javascript
// 1. Approve collateral spending
await collateralToken.approve(strategyAddress, amount);

// 2. Deposit collateral
await strategy.depositCollateral(collateralAddress, amount, receiverAddress);
```

## Managing Your Position

### Viewing Your Holdings

The vault dashboard displays:
- **Your Share Balance**: Number of vault shares you own
- **Value in BTC**: Current value of your shares
- **Share Price**: Current price per vault share
- **Your Percentage**: Your ownership of the total vault

### Checking On-Chain

```javascript
// Check your share balance
const shares = await vaultToken.balanceOf(yourAddress);

// Convert shares to BTC value
const btcValue = await vaultToken.convertToAssets(shares);
```

## Requesting Withdrawals

### How Withdrawals Work

The vault uses a managed withdrawal system:
1. You request a withdrawal
2. Admin reviews and approves the request
3. You receive sovaBTC upon approval

### Step-by-Step Withdrawal Process

1. **Navigate to Withdrawals**
   - Go to the "Withdraw" or "Redeem" section

2. **Enter Share Amount**
   - Input the number of shares to redeem
   - Or enter the BTC amount you want to withdraw

3. **Submit Request**
   - Click "Request Withdrawal"
   - Confirm the transaction

4. **Wait for Approval**
   - Typical processing: 24-48 hours
   - You'll be notified when approved

5. **Receive sovaBTC**
   - sovaBTC is automatically sent to your wallet
   - No additional action required

### Direct Contract Interaction

```javascript
// Request redemption
await vaultToken.requestRedeem(shareAmount, receiverAddress, ownerAddress);

// Check withdrawal status
const request = await vaultToken.withdrawalRequests(requestId);
```

### Important Notes on Withdrawals

- All withdrawals are paid in sovaBTC only
- Minimum withdrawal: 0.00001 BTC
- Processing times may vary based on liquidity
- Current available liquidity: Check via `strategy.availableLiquidity()`

## Understanding Vault Shares

### What Are Vault Shares?

Vault shares (BTC-VAULT tokens) represent your proportional ownership:
- **Token Address**: `0xfF09B2B0AfEe51E29941091C4dd6B635780BC34a`
- **Symbol**: BTC-VAULT
- **Decimals**: 18
- **Standard**: ERC20/ERC4626

### Share Price Dynamics

The share price changes based on:
- Total assets in the vault
- Total shares outstanding
- Strategy performance

Current share price can be checked:
```javascript
const price = await vaultToken.convertToAssets(1e18); // Price of 1 share
```

### Transferring Shares

Vault shares can be transferred like any ERC20 token:
```javascript
await vaultToken.transfer(recipientAddress, amount);
```

## FAQ

### General Questions

**Q: What is the minimum deposit amount?**
A: 0.00001 BTC (1000 satoshis)

**Q: Can I deposit multiple types of collateral?**
A: Yes, you can deposit WBTC, TBTC, and sovaBTC in any combination

**Q: Are there any fees?**
A: Currently no fees on testnet. Check the interface for mainnet fee structure

**Q: How long do withdrawals take?**
A: Typically 24-48 hours for approval, instant transfer once approved

### Technical Questions

**Q: What are the contract addresses?**
A: 
- Vault Token: `0xfF09B2B0AfEe51E29941091C4dd6B635780BC34a`
- Strategy: `0x0A039085Ca2AD68a3FC77A9C5191C22B309126F8`
- [View on BaseScan](https://sepolia.basescan.org/address/0xfF09B2B0AfEe51E29941091C4dd6B635780BC34a)

**Q: Is the vault audited?**
A: The underlying FountFi protocol is audited by Omniscia

**Q: What blockchain is this on?**
A: Currently deployed on Base Sepolia (testnet)

### Security Questions

**Q: How are my funds secured?**
A: 
- Smart contract security with role-based access
- Managed withdrawal system
- Audited codebase
- Admin multisig (on mainnet)

**Q: What are the risks?**
A: As with any DeFi protocol:
- Smart contract risk
- Admin key risk
- Liquidity risk (for withdrawals)
- Market risk (BTC price fluctuations)

## Troubleshooting

### Common Issues and Solutions

#### Transaction Fails

**Problem**: Deposit transaction reverts

**Solutions**:
- Check token approval is sufficient
- Ensure you have enough balance
- Verify you're on Base Sepolia network
- Increase gas limit if needed

#### Can't See Shares in Wallet

**Problem**: Shares don't appear in MetaMask

**Solution**: Add the vault token to your wallet:
1. Open MetaMask
2. Click "Import tokens"
3. Enter contract address: `0xfF09B2B0AfEe51E29941091C4dd6B635780BC34a`
4. Symbol: BTC-VAULT
5. Decimals: 18

#### Withdrawal Not Processing

**Problem**: Withdrawal request pending for long time

**Solutions**:
- Check if admin approval is pending
- Verify sufficient liquidity exists: `strategy.availableLiquidity()`
- Contact support if delayed >48 hours

#### Wrong Network

**Problem**: Can't connect or see vault

**Solution**: 
1. Open wallet settings
2. Add Base Sepolia network:
   - Name: Base Sepolia
   - RPC: https://sepolia.base.org
   - Chain ID: 84532
   - Currency: ETH
   - Explorer: https://sepolia.basescan.org

### Getting Help

If you need assistance:
1. Check this guide and FAQ
2. Review transaction on [BaseScan](https://sepolia.basescan.org)
3. Check contract state using cast commands
4. Open an issue on GitHub

## Best Practices

### For Optimal Experience

1. **Start Small**: Test with small amounts first
2. **Check Liquidity**: Verify available liquidity before large withdrawals
3. **Monitor Gas**: Execute transactions during low-traffic periods
4. **Keep Records**: Save transaction hashes for reference
5. **Stay Informed**: Follow official announcements

### Security Tips

- Only interact with verified contract addresses
- Never share private keys or seed phrases
- Verify transactions before signing
- Use hardware wallets for large amounts

## Useful Commands

### Using Cast (Foundry)

```bash
# Check your share balance
cast call 0xfF09B2B0AfEe51E29941091C4dd6B635780BC34a "balanceOf(address)" YOUR_ADDRESS --rpc-url base-sepolia

# Check available liquidity
cast call 0x0A039085Ca2AD68a3FC77A9C5191C22B309126F8 "availableLiquidity()" --rpc-url base-sepolia

# Check if collateral is supported
cast call 0x0A039085Ca2AD68a3FC77A9C5191C22B309126F8 "isSupportedCollateral(address)" COLLATERAL_ADDRESS --rpc-url base-sepolia
```

## Contract Addresses

### Base Sepolia (Testnet) - Current Deployment

| Contract | Address | Explorer |
|----------|---------|----------|
| BTC Vault Token | `0xfF09B2B0AfEe51E29941091C4dd6B635780BC34a` | [View](https://sepolia.basescan.org/address/0xfF09B2B0AfEe51E29941091C4dd6B635780BC34a) |
| BTC Vault Strategy | `0x0A039085Ca2AD68a3FC77A9C5191C22B309126F8` | [View](https://sepolia.basescan.org/address/0x0A039085Ca2AD68a3FC77A9C5191C22B309126F8) |
| WBTC | `0xe44b2870eFcd6Bb3C9305808012621f438e9636D` | [View](https://sepolia.basescan.org/address/0xe44b2870eFcd6Bb3C9305808012621f438e9636D) |
| TBTC | `0xE2b47f0dD766834b9DD2612D2d3632B05Ca89802` | [View](https://sepolia.basescan.org/address/0xE2b47f0dD766834b9DD2612D2d3632B05Ca89802) |
| sovaBTC | `0x05aB19d77516414f7333a8fd52cC1F49FF8eAFA9` | [View](https://sepolia.basescan.org/address/0x05aB19d77516414f7333a8fd52cC1F49FF8eAFA9) |

## Updates and Announcements

Stay updated:
- GitHub Repository: [fountfi-sovabtc](https://github.com/yourusername/fountfi-sovabtc)
- Check the vault interface for notices
- Monitor smart contract events

---

*Last Updated: 2025-08-12*
*Version: 1.0.0*
*Network: Base Sepolia Testnet*