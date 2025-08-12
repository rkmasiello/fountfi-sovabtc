# Multi-Collateral BTC Vault User Guide

## Welcome to mcBTC Vault

The Multi-Collateral BTC Vault (mcBTC) is a decentralized vault system that allows you to deposit various forms of wrapped Bitcoin and earn yield while maintaining exposure to BTC. This guide will walk you through everything you need to know as a user.

## Table of Contents

1. [Overview](#overview)
2. [Supported Collateral](#supported-collateral)
3. [How to Deposit](#how-to-deposit)
4. [Understanding mcBTC Shares](#understanding-mcbtc-shares)
5. [Redemption Process](#redemption-process)
6. [Important Requirements](#important-requirements)
7. [FAQs](#faqs)
8. [Troubleshooting](#troubleshooting)

## Overview

### What is mcBTC Vault?

The mcBTC Vault is an ERC-4626 compliant vault that:
- Accepts multiple types of wrapped Bitcoin as deposits
- Issues mcBTC shares representing your deposit
- Generates yield through strategic BTC management
- Allows redemptions exclusively in sovaBTC after a 14-day waiting period

### Key Features

- **Multi-Collateral Support**: Deposit WBTC, TBTC, or sovaBTC
- **Unified Shares**: Receive mcBTC tokens regardless of deposit type
- **Yield Generation**: Earn returns on your BTC holdings
- **Secure Redemptions**: 14-day queue system ensures liquidity
- **Minimum Investment**: 0.001 BTC (protects against dust attacks)

## Supported Collateral

The vault currently accepts three types of Bitcoin collateral:

| Token | Description | Decimals | Network |
|-------|-------------|----------|---------|
| **WBTC** | Wrapped Bitcoin | 8 | Ethereum |
| **TBTC** | Threshold Bitcoin | 18 | Ethereum |
| **sovaBTC** | Sova Network Bitcoin | 18 | Ethereum |

### Conversion Rates

All collateral types are valued at 1:1 with BTC, adjusted for decimal differences:
- 1 WBTC (8 decimals) = 1 BTC value
- 1 TBTC (18 decimals) = 1 BTC value
- 1 sovaBTC (18 decimals) = 1 BTC value

## How to Deposit

### Step 1: Connect Your Wallet

Connect a Web3 wallet (MetaMask, WalletConnect, etc.) to the dApp interface.

### Step 2: Approve Token Spending

Before depositing, approve the vault contract to spend your BTC tokens:

```javascript
// Example for WBTC
await wbtcContract.approve(vaultAddress, depositAmount);
```

### Step 3: Choose Deposit Amount

- **Minimum**: 0.001 BTC equivalent
- **Maximum**: No upper limit
- Enter the amount you wish to deposit

### Step 4: Execute Deposit

Call the deposit function with your chosen collateral:

```javascript
// Deposit WBTC and receive mcBTC shares
await vaultContract.deposit(depositAmount, yourAddress);
```

### Step 5: Receive mcBTC Shares

After the transaction confirms, you'll receive mcBTC shares representing your deposit. The number of shares depends on:
- Current vault NAV (Net Asset Value)
- Total supply of mcBTC
- Amount deposited

### Example Deposit Flow

```
User deposits 1 WBTC
→ Vault accepts WBTC
→ Calculates shares based on current NAV
→ Issues mcBTC shares to user
→ Strategy holds WBTC for yield generation
```

## Understanding mcBTC Shares

### What are mcBTC Shares?

mcBTC is an ERC-20 token representing your share of the vault's total assets. Key characteristics:

- **18 Decimal Precision**: All shares use 18 decimals for maximum precision
- **Yield-Bearing**: Share value increases as the vault generates returns
- **Transferable**: Can be sent to other addresses
- **Redeemable**: Can be exchanged for sovaBTC through the queue

### Share Calculation

When you deposit, shares are calculated as:

```
shares = (deposit_amount * total_supply) / total_assets
```

When NAV increases (yield generated), your shares become worth more BTC.

### Tracking Your Position

You can check your position anytime:

1. **Share Balance**: `balanceOf(yourAddress)` - Your mcBTC tokens
2. **BTC Value**: `convertToAssets(yourShareBalance)` - Current BTC value
3. **Profit/Loss**: Compare current value to initial deposit

## Redemption Process

### Overview

Redemptions work through a 14-day queue system to ensure liquidity:

1. Request redemption by entering the queue
2. Wait 14 days for processing
3. Admin processes your redemption
4. Receive sovaBTC to your wallet

### Step 1: Queue Your Redemption

```javascript
// Request to redeem 100 mcBTC shares
await vaultContract.requestRedeem(shareAmount, yourAddress, yourAddress);
```

This will:
- Transfer your shares to the redemption queue
- Create a redemption request with current timestamp
- Start the 14-day waiting period

### Step 2: Wait 14 Days

During the waiting period:
- Your shares are held in custody
- You cannot cancel the redemption
- The value continues to track NAV changes
- You can check status anytime

### Step 3: Processing

After 14 days:
- Admin processes mature redemptions
- Strategy withdraws necessary sovaBTC
- Queue distributes sovaBTC to users

### Step 4: Receive sovaBTC

You'll receive sovaBTC directly to your wallet:
- Amount based on NAV at processing time
- No additional action required
- Transaction visible on Etherscan

### Checking Queue Status

```javascript
// Check if your redemption is ready
const request = await queueContract.redemptionRequests(requestId);
const isReady = (Date.now() / 1000) >= request.maturityTimestamp;
```

## Important Requirements

### Minimum Investment

- **Amount**: 0.001 BTC equivalent
- **Reason**: Prevents dust attacks and ensures economical gas costs
- **Applied to**: All deposits regardless of collateral type

### Redemption Rules

1. **Redemption Asset**: Only sovaBTC (no other collateral)
2. **Waiting Period**: Exactly 14 days (1,209,600 seconds)
3. **Processing**: Admin-triggered after maturity
4. **No Cancellation**: Once queued, cannot be cancelled

### Gas Considerations

Typical gas costs for operations:
- **Deposit**: ~150,000 gas
- **Redemption Request**: ~200,000 gas
- **Share Transfer**: ~65,000 gas

## FAQs

### General Questions

**Q: Why can I only redeem in sovaBTC?**
A: The vault is designed to provide liquidity exclusively through sovaBTC, which is the primary BTC representation in the Sova Network ecosystem.

**Q: Can I deposit multiple collateral types?**
A: Yes, you can make multiple deposits with different collateral types. All deposits result in mcBTC shares.

**Q: Are my funds safe during the 14-day waiting period?**
A: Yes, your shares are held securely in the redemption queue contract and continue to track NAV changes.

### Technical Questions

**Q: How is yield generated?**
A: The vault generates yield through strategic BTC management, with returns reflected in increasing NAV.

**Q: What happens if I transfer my mcBTC shares?**
A: mcBTC shares are freely transferable. The recipient gains all rights to the underlying value.

**Q: Can I partially redeem my shares?**
A: Yes, you can redeem any amount of shares you own, subject to minimum requirements.

### Risk Questions

**Q: What are the main risks?**
A: Primary risks include smart contract risk, liquidity risk during high redemption periods, and price oracle manipulation risk.

**Q: Is there slippage on deposits/redemptions?**
A: No slippage on deposits. Redemptions may experience minor variations due to NAV changes during the 14-day period.

**Q: What happens in an emergency?**
A: The vault has pause mechanisms and admin controls for emergency situations. See the Security documentation for details.

## Troubleshooting

### Common Issues and Solutions

#### "Insufficient Allowance" Error
**Solution**: Approve the vault contract to spend your tokens before depositing.

#### "Minimum Not Met" Error
**Solution**: Ensure you're depositing at least 0.001 BTC equivalent.

#### "Redemption Not Mature" Error
**Solution**: Wait for the full 14-day period before expecting processing.

#### Transaction Fails with "Paused" Error
**Solution**: The vault may be temporarily paused for maintenance. Check announcements.

### Getting Help

If you encounter issues not covered here:

1. Check transaction details on Etherscan
2. Verify your wallet is connected to the correct network
3. Ensure you have sufficient gas for transactions
4. Contact support with transaction hash if problems persist

## Best Practices

### For Depositors

1. **Start Small**: Test with minimum amounts first
2. **Check NAV**: Monitor NAV before large deposits
3. **Plan Redemptions**: Account for 14-day waiting period
4. **Keep Records**: Save transaction hashes for reference

### For Yield Optimization

1. **Long-term Holding**: Maximize yield by holding shares longer
2. **NAV Monitoring**: Track NAV changes to understand returns
3. **Gas Optimization**: Batch operations when possible

### Security Tips

1. **Verify Contracts**: Always confirm you're interacting with official contracts
2. **Check Addresses**: Double-check recipient addresses
3. **Use Hardware Wallets**: For large amounts, use hardware wallet
4. **Monitor Positions**: Regularly check your share balance

## Contract Addresses

### Mainnet (Coming Soon)
```
MultiBTCVault: 0x...
ManagedRedemptionQueue: 0x...
MultiCollateralRegistry: 0x...
```

### Sepolia Testnet
```
MultiBTCVault: [To be deployed]
ManagedRedemptionQueue: [To be deployed]
MultiCollateralRegistry: [To be deployed]
```

## Additional Resources

- [Admin Manual](./ADMIN_MANUAL.md) - For vault administrators
- [Integration Guide](./INTEGRATION_GUIDE.md) - For developers
- [Security Documentation](./SECURITY.md) - Security model and procedures
- [GitHub Repository](https://github.com/SovaNetwork/multi-collateral-vault)

---

*Last Updated: [Current Date]*
*Version: 1.0.0*