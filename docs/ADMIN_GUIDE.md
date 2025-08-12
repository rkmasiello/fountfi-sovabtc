# Administrator Guide - Multi-Collateral BTC Vault

This guide provides comprehensive instructions for administrators managing the Multi-Collateral BTC Vault system deployed on Base Sepolia.

## Table of Contents
- [Overview](#overview)
- [Admin Roles and Permissions](#admin-roles-and-permissions)
- [Daily Operations](#daily-operations)
- [Collateral Management](#collateral-management)
- [Liquidity Management](#liquidity-management)
- [Withdrawal Processing](#withdrawal-processing)
- [Price Oracle Management](#price-oracle-management)
- [Emergency Procedures](#emergency-procedures)
- [Monitoring and Maintenance](#monitoring-and-maintenance)
- [Scripts and Commands](#scripts-and-commands)

## Overview

The BTC Vault system requires active management for:
- Processing withdrawal requests
- Managing sovaBTC liquidity
- Updating price oracles
- Adding/removing collateral types
- Monitoring system health

### Current Deployment

| Contract | Address | Role |
|----------|---------|------|
| BtcVaultStrategy | `0x0A039085Ca2AD68a3FC77A9C5191C22B309126F8` | Manages collateral and liquidity |
| BtcVaultToken | `0xfF09B2B0AfEe51E29941091C4dd6B635780BC34a` | ERC4626 vault token |
| PriceOracleReporter | `0x698FBBde2c9FF3aF64C0ec48f174d5e8231FAacF` | Price feed for NAV |

## Admin Roles and Permissions

### Role Structure

The system uses FountFi's RoleManager for access control:

```solidity
uint256 constant PROTOCOL_ADMIN = 1;    // System-wide admin
uint256 constant STRATEGY_ADMIN = 2;    // Strategy management
uint256 constant STRATEGY_OPERATOR = 8; // Daily operations
uint256 constant PRICE_UPDATER = 32;    // Oracle updates
```

### Current Admin Setup

- **Manager Address**: `0x1f53aA5d3b5743BD0D41884124bC07f4d7682Fc1`
- **Role Manager**: `0x15502fC5e872c8B22BA6dD5e01A7A5bd4f9A3d72`

### Granting Roles

```bash
# Grant STRATEGY_OPERATOR role
cast send 0x15502fC5e872c8B22BA6dD5e01A7A5bd4f9A3d72 \
  "grantRole(address,uint256)" \
  NEW_OPERATOR_ADDRESS 8 \
  --private-key $ADMIN_KEY \
  --rpc-url base-sepolia
```

## Daily Operations

### Morning Checklist (Recommended Daily)

1. **Check System Health**
```bash
# Check vault total assets
cast call 0xfF09B2B0AfEe51E29941091C4dd6B635780BC34a "totalAssets()" --rpc-url base-sepolia

# Check available liquidity
cast call 0x0A039085Ca2AD68a3FC77A9C5191C22B309126F8 "availableLiquidity()" --rpc-url base-sepolia

# Check pending withdrawals
cast call 0xfF09B2B0AfEe51E29941091C4dd6B635780BC34a "pendingWithdrawals()" --rpc-url base-sepolia
```

2. **Process Withdrawals**
```bash
# Check for approved withdrawals ready to process
forge script script/admin/ProcessWithdrawals.s.sol --rpc-url base-sepolia
```

3. **Update Price Oracle (if needed)**
```bash
# Update price with current BTC value
cast send 0x698FBBde2c9FF3aF64C0ec48f174d5e8231FAacF \
  "update(uint256)" \
  NEW_PRICE \
  --private-key $PRICE_UPDATER_KEY \
  --rpc-url base-sepolia
```

## Collateral Management

### Supported Collateral

Current supported tokens:
- WBTC: `0xe44b2870eFcd6Bb3C9305808012621f438e9636D`
- TBTC: `0xE2b47f0dD766834b9DD2612D2d3632B05Ca89802`
- sovaBTC: `0x05aB19d77516414f7333a8fd52cC1F49FF8eAFA9`

### Adding New Collateral

```bash
# Add new collateral type (1:1 ratio = 1e18)
cast send 0x0A039085Ca2AD68a3FC77A9C5191C22B309126F8 \
  "addSupportedCollateral(address,uint256)" \
  NEW_TOKEN_ADDRESS \
  1000000000000000000 \
  --private-key $MANAGER_KEY \
  --rpc-url base-sepolia
```

### Removing Collateral

```bash
# Remove collateral support
cast send 0x0A039085Ca2AD68a3FC77A9C5191C22B309126F8 \
  "removeSupportedCollateral(address)" \
  TOKEN_ADDRESS \
  --private-key $MANAGER_KEY \
  --rpc-url base-sepolia
```

### Checking Collateral Status

```bash
# Check if token is supported
cast call 0x0A039085Ca2AD68a3FC77A9C5191C22B309126F8 \
  "isSupportedCollateral(address)" \
  TOKEN_ADDRESS \
  --rpc-url base-sepolia

# Get all supported collaterals
cast call 0x0A039085Ca2AD68a3FC77A9C5191C22B309126F8 \
  "getSupportedCollaterals()" \
  --rpc-url base-sepolia
```

## Liquidity Management

### Managing sovaBTC Liquidity

The strategy requires sovaBTC liquidity to process withdrawals.

#### Adding Liquidity

```bash
# First approve sovaBTC spending
cast send 0x05aB19d77516414f7333a8fd52cC1F49FF8eAFA9 \
  "approve(address,uint256)" \
  0x0A039085Ca2AD68a3FC77A9C5191C22B309126F8 \
  AMOUNT \
  --private-key $MANAGER_KEY \
  --rpc-url base-sepolia

# Add liquidity to strategy
cast send 0x0A039085Ca2AD68a3FC77A9C5191C22B309126F8 \
  "addLiquidity(uint256)" \
  AMOUNT \
  --private-key $MANAGER_KEY \
  --rpc-url base-sepolia
```

#### Removing Excess Liquidity

```bash
# Remove liquidity from strategy
cast send 0x0A039085Ca2AD68a3FC77A9C5191C22B309126F8 \
  "removeLiquidity(uint256)" \
  AMOUNT \
  --private-key $MANAGER_KEY \
  --rpc-url base-sepolia
```

#### Monitoring Liquidity

```bash
# Check current available liquidity
cast call 0x0A039085Ca2AD68a3FC77A9C5191C22B309126F8 \
  "availableLiquidity()" \
  --rpc-url base-sepolia
```

### Using Helper Scripts

```bash
# Add liquidity using script
forge script script/AddLiquidity.s.sol \
  --rpc-url base-sepolia \
  --broadcast \
  --private-key $MANAGER_KEY

# Mint test tokens (testnet only)
forge script script/MintTestTokens.s.sol \
  --rpc-url base-sepolia \
  --broadcast \
  --private-key $MANAGER_KEY
```

## Withdrawal Processing

### Understanding the Managed Withdrawal System

1. Users request withdrawals through `requestRedeem()`
2. Admin reviews and approves requests
3. Strategy processes approved withdrawals using available liquidity

### Processing Workflow

#### Step 1: Check Pending Withdrawals

```bash
# Get pending withdrawal count
cast call 0xfF09B2B0AfEe51E29941091C4dd6B635780BC34a \
  "pendingWithdrawals()" \
  --rpc-url base-sepolia
```

#### Step 2: Review Withdrawal Requests

```bash
# Get specific withdrawal request details
cast call 0xfF09B2B0AfEe51E29941091C4dd6B635780BC34a \
  "withdrawalRequests(uint256)" \
  REQUEST_ID \
  --rpc-url base-sepolia
```

#### Step 3: Approve Withdrawals

```bash
# Approve a withdrawal request
cast send 0xfF09B2B0AfEe51E29941091C4dd6B635780BC34a \
  "approveWithdrawal(uint256)" \
  REQUEST_ID \
  --private-key $MANAGER_KEY \
  --rpc-url base-sepolia
```

#### Step 4: Process Approved Withdrawals

```bash
# Process all approved withdrawals
cast send 0x0A039085Ca2AD68a3FC77A9C5191C22B309126F8 \
  "processWithdrawals()" \
  --private-key $MANAGER_KEY \
  --rpc-url base-sepolia
```

### Batch Processing

For multiple withdrawals:
```bash
# Approve multiple withdrawals
cast send 0xfF09B2B0AfEe51E29941091C4dd6B635780BC34a \
  "batchApproveWithdrawals(uint256[])" \
  "[1,2,3,4,5]" \
  --private-key $MANAGER_KEY \
  --rpc-url base-sepolia
```

## Price Oracle Management

### Understanding the Price Oracle

The PriceOracleReporter provides the NAV (Net Asset Value) for the vault.

### Updating Price

```bash
# Update price (8 decimals for BTC)
# Example: 1 BTC = 100000000 (1e8)
cast send 0x698FBBde2c9FF3aF64C0ec48f174d5e8231FAacF \
  "update(uint256)" \
  100000000 \
  --private-key $PRICE_UPDATER_KEY \
  --rpc-url base-sepolia
```

### Setting Max Deviation

Protect against price manipulation:
```bash
# Set max deviation to 5% (500 basis points)
cast send 0x698FBBde2c9FF3aF64C0ec48f174d5e8231FAacF \
  "setMaxDeviation(uint16)" \
  500 \
  --private-key $ADMIN_KEY \
  --rpc-url base-sepolia
```

### Checking Oracle Status

```bash
# Get current price
cast call 0x698FBBde2c9FF3aF64C0ec48f174d5e8231FAacF \
  "getLatestPrice()" \
  --rpc-url base-sepolia

# Check last update time
cast call 0x698FBBde2c9FF3aF64C0ec48f174d5e8231FAacF \
  "lastUpdateTime()" \
  --rpc-url base-sepolia
```

## Emergency Procedures

### 1. Pausing Operations

If critical issues arise:
```bash
# Pause vault (if pause functionality exists)
cast send 0xfF09B2B0AfEe51E29941091C4dd6B635780BC34a \
  "pause()" \
  --private-key $ADMIN_KEY \
  --rpc-url base-sepolia
```

### 2. Emergency Withdrawal Processing

Force process specific withdrawals:
```bash
# Emergency withdrawal processing
cast send 0x0A039085Ca2AD68a3FC77A9C5191C22B309126F8 \
  "emergencyWithdraw(address,uint256)" \
  USER_ADDRESS \
  AMOUNT \
  --private-key $ADMIN_KEY \
  --rpc-url base-sepolia
```

### 3. Recovering Stuck Tokens

If tokens get stuck:
```bash
# Recover ERC20 tokens from strategy
cast send 0x0A039085Ca2AD68a3FC77A9C5191C22B309126F8 \
  "sendToken(address,address,uint256)" \
  TOKEN_ADDRESS \
  RECIPIENT \
  AMOUNT \
  --private-key $MANAGER_KEY \
  --rpc-url base-sepolia
```

### 4. Updating Manager

Change strategy manager:
```bash
# Set new manager
cast send 0x0A039085Ca2AD68a3FC77A9C5191C22B309126F8 \
  "setManager(address)" \
  NEW_MANAGER_ADDRESS \
  --private-key $ADMIN_KEY \
  --rpc-url base-sepolia
```

## Monitoring and Maintenance

### Key Metrics to Monitor

1. **Total Value Locked (TVL)**
```bash
cast call 0xfF09B2B0AfEe51E29941091C4dd6B635780BC34a "totalAssets()" --rpc-url base-sepolia
```

2. **Share Price**
```bash
# Get price of 1 share (1e18)
cast call 0xfF09B2B0AfEe51E29941091C4dd6B635780BC34a \
  "convertToAssets(uint256)" \
  1000000000000000000 \
  --rpc-url base-sepolia
```

3. **Total Shares Outstanding**
```bash
cast call 0xfF09B2B0AfEe51E29941091C4dd6B635780BC34a "totalSupply()" --rpc-url base-sepolia
```

4. **Available Liquidity**
```bash
cast call 0x0A039085Ca2AD68a3FC77A9C5191C22B309126F8 "availableLiquidity()" --rpc-url base-sepolia
```

### Regular Maintenance Tasks

#### Daily
- Check and process pending withdrawals
- Monitor liquidity levels
- Review recent transactions
- Update price oracle if needed

#### Weekly
- Review collateral balances
- Analyze deposit/withdrawal patterns
- Check for any failed transactions
- Review gas costs and optimize if needed

#### Monthly
- Full system audit
- Review and update documentation
- Check for contract upgrades
- Performance analysis

### Setting Up Monitoring

Create a monitoring script:
```bash
#!/bin/bash
# monitor.sh

echo "=== BTC Vault Status ==="
echo "TVL: $(cast call 0xfF09B2B0AfEe51E29941091C4dd6B635780BC34a 'totalAssets()' --rpc-url base-sepolia)"
echo "Liquidity: $(cast call 0x0A039085Ca2AD68a3FC77A9C5191C22B309126F8 'availableLiquidity()' --rpc-url base-sepolia)"
echo "Pending: $(cast call 0xfF09B2B0AfEe51E29941091C4dd6B635780BC34a 'pendingWithdrawals()' --rpc-url base-sepolia)"
```

## Scripts and Commands

### Useful Cast Commands

```bash
# Format output as decimal
cast --to-dec $(cast call CONTRACT "METHOD()" --rpc-url base-sepolia)

# Format BTC amount (8 decimals)
cast --to-unit $(cast call CONTRACT "balance()" --rpc-url base-sepolia) 8

# Send transaction with specific gas
cast send CONTRACT "METHOD()" \
  --gas-limit 500000 \
  --gas-price 20gwei \
  --private-key $KEY \
  --rpc-url base-sepolia
```

### Admin Scripts

Location: `script/admin/`

- `AddLiquidity.s.sol` - Add sovaBTC liquidity
- `ProcessWithdrawals.s.sol` - Process pending withdrawals
- `UpdateOracle.s.sol` - Update price oracle
- `RebalanceCollateral.s.sol` - Rebalance strategy holdings

### Running Admin Scripts

```bash
# Generic script execution
forge script script/admin/ScriptName.s.sol:ScriptName \
  --rpc-url base-sepolia \
  --broadcast \
  --private-key $ADMIN_KEY \
  -vvv
```

## Best Practices

### Security

1. **Use Hardware Wallets**: For mainnet admin keys
2. **Multi-sig**: Implement multi-sig for critical operations
3. **Time Delays**: Add time delays for sensitive changes
4. **Monitoring**: Set up 24/7 monitoring with alerts
5. **Backup Keys**: Maintain secure backup of admin keys

### Operations

1. **Document Everything**: Log all admin actions
2. **Test First**: Always test on testnet
3. **Gradual Changes**: Make incremental adjustments
4. **Communication**: Notify users of maintenance
5. **Regular Audits**: Conduct periodic security reviews

### Performance

1. **Batch Operations**: Process multiple items together
2. **Gas Optimization**: Execute during low gas periods
3. **Liquidity Buffer**: Maintain 20% extra liquidity
4. **Regular Rebalancing**: Keep collateral balanced

## Troubleshooting

### Common Issues

#### Issue: Transaction Fails with "Unauthorized"
**Solution**: Check you have the correct role:
```bash
cast call 0x15502fC5e872c8B22BA6dD5e01A7A5bd4f9A3d72 \
  "hasRole(address,uint256)" \
  YOUR_ADDRESS \
  ROLE_ID \
  --rpc-url base-sepolia
```

#### Issue: Insufficient Liquidity for Withdrawals
**Solution**: Add more sovaBTC liquidity or wait for deposits

#### Issue: Oracle Price Stale
**Solution**: Update the oracle with current price

#### Issue: Gas Too High
**Solution**: Wait for lower gas or increase gas price tolerance

## Support and Resources

### Documentation
- [FountFi Protocol Docs](https://docs.fountfi.com)
- [Integration Guide](./INTEGRATION_GUIDE.md)
- [User Guide](./USER_GUIDE.md)

### Contracts on BaseScan
- [BtcVaultToken](https://sepolia.basescan.org/address/0xfF09B2B0AfEe51E29941091C4dd6B635780BC34a)
- [BtcVaultStrategy](https://sepolia.basescan.org/address/0x0A039085Ca2AD68a3FC77A9C5191C22B309126F8)
- [PriceOracleReporter](https://sepolia.basescan.org/address/0x698FBBde2c9FF3aF64C0ec48f174d5e8231FAacF)

### Emergency Contacts
- Technical Issues: Open GitHub issue
- Security Concerns: security@yourproject.com
- General Support: support@yourproject.com

---

*Last Updated: 2025-08-12*
*Version: 1.0.0*
*Network: Base Sepolia Testnet*