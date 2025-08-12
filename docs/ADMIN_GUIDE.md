# Administrator Guide - Multi-Collateral BTC Vault

This guide provides comprehensive instructions for administrators managing the BTC Vault system on Base Sepolia and future mainnet deployments.

## Table of Contents
- [Overview](#overview)
- [Admin Roles and Permissions](#admin-roles-and-permissions)
- [Daily Operations](#daily-operations)
- [Collateral Management](#collateral-management)
- [Liquidity Management](#liquidity-management)
- [Withdrawal Processing](#withdrawal-processing)
- [Emergency Procedures](#emergency-procedures)
- [Monitoring and Maintenance](#monitoring-and-maintenance)
- [Script Reference](#script-reference)

## Overview

As an administrator of the BTC Vault system, you are responsible for:
- Managing supported collateral types
- Maintaining sovaBTC liquidity for withdrawals
- Processing withdrawal requests
- Monitoring system health
- Responding to emergencies

### Current Deployment (Base Sepolia)

| Component | Address | Role Required |
|-----------|---------|---------------|
| BtcVaultStrategy | `0x0A039085Ca2AD68a3FC77A9C5191C22B309126F8` | STRATEGY_OPERATOR |
| BtcVaultToken | `0xfF09B2B0AfEe51E29941091C4dd6B635780BC34a` | STRATEGY_ADMIN |
| RoleManager | `0x15502fC5e872c8B22BA6dD5e01A7A5bd4f9A3d72` | PROTOCOL_ADMIN |

## Admin Roles and Permissions

### Role Hierarchy

```
PROTOCOL_ADMIN (1)
├── STRATEGY_ADMIN (2)
│   └── STRATEGY_OPERATOR (8)
├── RULES_ADMIN (4)
│   └── KYC_OPERATOR (16)
└── PRICE_UPDATER (32)
```

### Key Permissions

| Role | Permissions | Contract |
|------|------------|----------|
| **PROTOCOL_ADMIN** | Grant/revoke roles, system configuration | RoleManager |
| **STRATEGY_ADMIN** | Strategy parameters, pause/unpause | BtcVaultStrategy |
| **STRATEGY_OPERATOR** | Daily operations, withdrawals, liquidity | BtcVaultStrategy |

### Checking Roles

```bash
# Check if address has role
cast call 0x15502fC5e872c8B22BA6dD5e01A7A5bd4f9A3d72 "hasRole(address,uint256)" ADDRESS ROLE_NUMBER --rpc-url base-sepolia

# Example: Check if address has STRATEGY_OPERATOR role (8)
cast call 0x15502fC5e872c8B22BA6dD5e01A7A5bd4f9A3d72 "hasRole(address,uint256)" 0x1f53aA5d3b5743BD0D41884124bC07f4d7682Fc1 8 --rpc-url base-sepolia
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

2. **Review Overnight Activity**
   - Check for new deposits
   - Review withdrawal requests
   - Monitor for unusual activity

3. **Process Withdrawals** (if any pending)
   - Review pending withdrawal requests
   - Ensure sufficient liquidity
   - Approve or reject requests

## Collateral Management

### Adding New Collateral

```bash
# Add new collateral type (requires STRATEGY_OPERATOR role)
cast send 0x0A039085Ca2AD68a3FC77A9C5191C22B309126F8 \
  "addSupportedCollateral(address,uint256)" \
  COLLATERAL_ADDRESS RATIO \
  --private-key $PRIVATE_KEY \
  --rpc-url base-sepolia

# Example: Add new BTC token with 1:1 ratio
cast send 0x0A039085Ca2AD68a3FC77A9C5191C22B309126F8 \
  "addSupportedCollateral(address,uint256)" \
  0xNEW_TOKEN_ADDRESS 1000000000000000000 \
  --private-key $PRIVATE_KEY \
  --rpc-url base-sepolia
```

### Removing Collateral

```bash
# Remove collateral support
cast send 0x0A039085Ca2AD68a3FC77A9C5191C22B309126F8 \
  "removeSupportedCollateral(address)" \
  COLLATERAL_ADDRESS \
  --private-key $PRIVATE_KEY \
  --rpc-url base-sepolia
```

### Viewing Supported Collaterals

```bash
# Get list of supported collaterals
cast call 0x0A039085Ca2AD68a3FC77A9C5191C22B309126F8 \
  "getSupportedCollaterals()" \
  --rpc-url base-sepolia

# Check if specific token is supported
cast call 0x0A039085Ca2AD68a3FC77A9C5191C22B309126F8 \
  "isSupportedCollateral(address)" \
  TOKEN_ADDRESS \
  --rpc-url base-sepolia
```

## Liquidity Management

### Adding Liquidity

The strategy needs sovaBTC liquidity to process withdrawals.

```bash
# First, approve sovaBTC spending
cast send 0x05aB19d77516414f7333a8fd52cC1F49FF8eAFA9 \
  "approve(address,uint256)" \
  0x0A039085Ca2AD68a3FC77A9C5191C22B309126F8 \
  AMOUNT \
  --private-key $PRIVATE_KEY \
  --rpc-url base-sepolia

# Then add liquidity
cast send 0x0A039085Ca2AD68a3FC77A9C5191C22B309126F8 \
  "addLiquidity(uint256)" \
  AMOUNT \
  --private-key $PRIVATE_KEY \
  --rpc-url base-sepolia
```

### Using the AddLiquidity Script

```bash
# Run the liquidity script (easier method)
PRIVATE_KEY=$PRIVATE_KEY forge script script/AddLiquidity.s.sol:AddLiquidityScript \
  --rpc-url base-sepolia \
  --broadcast
```

### Removing Excess Liquidity

```bash
# Remove liquidity if too much is idle
cast send 0x0A039085Ca2AD68a3FC77A9C5191C22B309126F8 \
  "removeLiquidity(uint256)" \
  AMOUNT \
  --private-key $PRIVATE_KEY \
  --rpc-url base-sepolia
```

### Monitoring Liquidity Levels

```bash
# Check current available liquidity
cast call 0x0A039085Ca2AD68a3FC77A9C5191C22B309126F8 \
  "availableLiquidity()" \
  --rpc-url base-sepolia

# Check total pending withdrawals
cast call 0xfF09B2B0AfEe51E29941091C4dd6B635780BC34a \
  "totalPendingWithdrawals()" \
  --rpc-url base-sepolia
```

## Withdrawal Processing

### Viewing Pending Withdrawals

```bash
# Get pending withdrawal requests
cast call 0xfF09B2B0AfEe51E29941091C4dd6B635780BC34a \
  "getPendingWithdrawals()" \
  --rpc-url base-sepolia

# Check specific withdrawal request
cast call 0xfF09B2B0AfEe51E29941091C4dd6B635780BC34a \
  "withdrawalRequests(uint256)" \
  REQUEST_ID \
  --rpc-url base-sepolia
```

### Approving Withdrawals

```bash
# Approve a single withdrawal
cast send 0xfF09B2B0AfEe51E29941091C4dd6B635780BC34a \
  "approveWithdrawal(uint256)" \
  REQUEST_ID \
  --private-key $PRIVATE_KEY \
  --rpc-url base-sepolia

# Batch approve multiple withdrawals
cast send 0xfF09B2B0AfEe51E29941091C4dd6B635780BC34a \
  "batchApproveWithdrawals(uint256[])" \
  "[1,2,3,4,5]" \
  --private-key $PRIVATE_KEY \
  --rpc-url base-sepolia
```

### Rejecting Withdrawals

```bash
# Reject a withdrawal request
cast send 0xfF09B2B0AfEe51E29941091C4dd6B635780BC34a \
  "rejectWithdrawal(uint256)" \
  REQUEST_ID \
  --private-key $PRIVATE_KEY \
  --rpc-url base-sepolia
```

### Processing Flow

1. **Review Request**: Check the withdrawal details
2. **Verify Liquidity**: Ensure sufficient sovaBTC available
3. **Approve/Reject**: Process based on criteria
4. **Monitor**: Verify successful transfer to user

## Emergency Procedures

### 1. Pausing the System

In case of emergency, pause all operations:

```bash
# Pause the vault token (stops deposits/withdrawals)
cast send 0xfF09B2B0AfEe51E29941091C4dd6B635780BC34a \
  "pause()" \
  --private-key $PRIVATE_KEY \
  --rpc-url base-sepolia

# Unpause when safe
cast send 0xfF09B2B0AfEe51E29941091C4dd6B635780BC34a \
  "unpause()" \
  --private-key $PRIVATE_KEY \
  --rpc-url base-sepolia
```

### 2. Emergency Token Recovery

If tokens get stuck in contracts:

```bash
# Recover stuck tokens from strategy
cast send 0x0A039085Ca2AD68a3FC77A9C5191C22B309126F8 \
  "sendToken(address,address,uint256)" \
  TOKEN_ADDRESS RECIPIENT AMOUNT \
  --private-key $PRIVATE_KEY \
  --rpc-url base-sepolia
```

### 3. Forcing Withdrawal Processing

In urgent cases, force process withdrawals:

```bash
# Force process specific withdrawal
cast send 0xfF09B2B0AfEe51E29941091C4dd6B635780BC34a \
  "forceProcessWithdrawal(uint256)" \
  REQUEST_ID \
  --private-key $PRIVATE_KEY \
  --rpc-url base-sepolia
```

### 4. Emergency Contacts

- **Technical Issues**: Open GitHub issue
- **Security Concerns**: Contact security team immediately
- **User Issues**: Direct to support channels

## Monitoring and Maintenance

### Key Metrics to Monitor

1. **Total Value Locked (TVL)**
```bash
cast call 0xfF09B2B0AfEe51E29941091C4dd6B635780BC34a "totalAssets()" --rpc-url base-sepolia
```

2. **Share Price**
```bash
# Get price of 1 share (1e18)
cast call 0xfF09B2B0AfEe51E29941091C4dd6B635780BC34a "convertToAssets(uint256)" 1000000000000000000 --rpc-url base-sepolia
```

3. **Available Liquidity**
```bash
cast call 0x0A039085Ca2AD68a3FC77A9C5191C22B309126F8 "availableLiquidity()" --rpc-url base-sepolia
```

4. **Pending Withdrawals**
```bash
cast call 0xfF09B2B0AfEe51E29941091C4dd6B635780BC34a "pendingWithdrawals()" --rpc-url base-sepolia
```

### Setting Up Monitoring

#### Using Tenderly

1. Import contracts to Tenderly
2. Set up alerts for:
   - Large deposits/withdrawals
   - Liquidity below threshold
   - Failed transactions
   - Unusual activity patterns

#### Custom Monitoring Script

```javascript
// monitoring.js
const checkVaultHealth = async () => {
  const tvl = await vaultToken.totalAssets();
  const liquidity = await strategy.availableLiquidity();
  const pending = await vaultToken.pendingWithdrawals();
  
  // Alert if liquidity < pending withdrawals
  if (liquidity < pending) {
    sendAlert("Insufficient liquidity for pending withdrawals!");
  }
  
  // Alert if TVL drops > 20%
  if (tvl < previousTVL * 0.8) {
    sendAlert("TVL dropped significantly!");
  }
};

// Run every 5 minutes
setInterval(checkVaultHealth, 5 * 60 * 1000);
```

### Regular Maintenance Tasks

#### Daily
- Check system health
- Process pending withdrawals
- Monitor liquidity levels
- Review transaction logs

#### Weekly
- Review collateral ratios
- Analyze user activity patterns
- Update liquidity forecasts
- Generate performance reports

#### Monthly
- Full system audit
- Review and update documentation
- Optimize gas usage
- Plan for upcoming changes

## Script Reference

### Available Admin Scripts

```bash
# Liquidity Management
script/AddLiquidity.s.sol              # Add sovaBTC liquidity
script/MintTestTokens.s.sol            # Mint test tokens (testnet only)

# Deployment
script/deploy/DeployBtcVault.s.sol    # Deploy new vault instance
script/verify/VerifyBtcVault.s.sol    # Verify deployment

# Testing
test/BtcVaultRefactorTest.t.sol       # Run integration tests
```

### Running Scripts

```bash
# General format
forge script script/SCRIPT_NAME.s.sol:CONTRACT_NAME \
  --rpc-url base-sepolia \
  --private-key $PRIVATE_KEY \
  --broadcast \
  -vvv

# Example: Add liquidity
forge script script/AddLiquidity.s.sol:AddLiquidityScript \
  --rpc-url base-sepolia \
  --private-key $PRIVATE_KEY \
  --broadcast
```

## Best Practices

### Security

1. **Use Hardware Wallets**: For mainnet admin operations
2. **Multi-sig Wallets**: Require multiple signatures for critical operations
3. **Regular Audits**: Review permissions and access regularly
4. **Monitor Always**: Set up 24/7 monitoring with alerts
5. **Test First**: Always test on testnet before mainnet

### Operations

1. **Document Everything**: Keep logs of all admin actions
2. **Regular Backups**: Backup configuration and state
3. **Gradual Changes**: Make incremental changes, not drastic ones
4. **Communication**: Keep users informed of maintenance
5. **Redundancy**: Have backup admins trained and ready

### Performance

1. **Gas Optimization**: Batch operations when possible
2. **Timing**: Execute during low-traffic periods
3. **Monitoring**: Track gas costs and optimize
4. **Efficiency**: Use scripts for repetitive tasks

## Troubleshooting

### Common Issues

#### "Insufficient Liquidity" Error
```bash
# Check available liquidity
cast call 0x0A039085Ca2AD68a3FC77A9C5191C22B309126F8 "availableLiquidity()" --rpc-url base-sepolia

# Add more if needed
forge script script/AddLiquidity.s.sol --rpc-url base-sepolia --broadcast
```

#### Transaction Failing
- Check gas price and limits
- Verify role permissions
- Ensure contract not paused
- Check token approvals

#### Cannot Process Withdrawal
- Verify admin role
- Check liquidity availability
- Ensure withdrawal request exists
- Verify not already processed

## Appendix

### Contract ABIs

ABIs are available in:
- `frontend/lib/abis.ts` - Frontend ABIs
- `out/` directory after building - Full contract ABIs

### Environment Variables

```bash
# .env file structure
PRIVATE_KEY=0x...
ETHERSCAN_API_KEY=...
BASE_SEPOLIA_RPC=https://sepolia.base.org
```

### Useful Commands

```bash
# Get contract bytecode size
forge inspect BtcVaultStrategy bytecode | wc -c

# Run specific test
forge test --match-test test_depositCollateral -vvv

# Generate gas report
forge test --gas-report

# Verify contract on Etherscan
forge verify-contract ADDRESS CONTRACT_NAME --chain-id 84532
```

---

*Last Updated: 2025-08-12*
*Version: 1.0.0*
*Network: Base Sepolia*