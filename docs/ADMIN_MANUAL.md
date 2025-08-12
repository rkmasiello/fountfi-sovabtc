# Multi-Collateral BTC Vault Admin Operations Manual

## Overview

This manual provides comprehensive instructions for administrators managing the Multi-Collateral BTC Vault system. It covers daily operations, emergency procedures, and best practices for maintaining vault health and security.

## Table of Contents

1. [Admin Roles and Permissions](#admin-roles-and-permissions)
2. [Daily Operations](#daily-operations)
3. [Weekly Operations](#weekly-operations)
4. [NAV Management](#nav-management)
5. [Redemption Queue Processing](#redemption-queue-processing)
6. [Liquidity Management](#liquidity-management)
7. [Emergency Procedures](#emergency-procedures)
8. [Monitoring and Alerts](#monitoring-and-alerts)
9. [Operational Checklists](#operational-checklists)
10. [Troubleshooting Guide](#troubleshooting-guide)

## Admin Roles and Permissions

### Role Structure

| Role | Contract | Permissions |
|------|----------|------------|
| **OWNER** | All | Full control, role management |
| **ADMIN** | Vault | Pause, unpause, set parameters |
| **OPERATOR** | Queue | Process redemptions, force process |
| **REPORTER** | PriceOracle | Update NAV, set price bounds |
| **MANAGER** | Strategy | Rebalance, withdraw for redemptions |

### Key Admin Addresses

```solidity
// Role identifiers
bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");
bytes32 public constant REPORTER_ROLE = keccak256("REPORTER");
```

### Setting Up Roles

```bash
# Grant admin role
cast send $VAULT "grantRole(bytes32,address)" $ADMIN_ROLE $ADMIN_ADDRESS

# Grant operator role
cast send $QUEUE "grantRole(bytes32,address)" $OPERATOR_ROLE $OPERATOR_ADDRESS
```

## Daily Operations

### 1. Morning Checks (9:00 AM UTC)

#### System Health Check
```bash
# Check vault status
forge script script/admin/CheckVaultStatus.s.sol --rpc-url $RPC_URL

# Verify all contracts responsive
cast call $VAULT "totalAssets()" --rpc-url $RPC_URL
cast call $QUEUE "queueLength()" --rpc-url $RPC_URL
```

#### Monitor Key Metrics
- Total Value Locked (TVL)
- Number of pending redemptions
- Available liquidity in strategy
- Current NAV vs previous day

### 2. NAV Update (10:00 AM UTC)

#### Calculate New NAV
```javascript
// Factors to consider:
// 1. Market price of BTC
// 2. Yield generated
// 3. Strategy performance
// 4. Any losses/gains

newNAV = (totalBTCValue + yieldGenerated) / totalShares
```

#### Update Price Oracle
```bash
# Update NAV using admin script
forge script script/admin/UpdatePriceOracle.s.sol \
  --sig "run(uint256)" $NEW_NAV \
  --rpc-url $RPC_URL \
  --broadcast
```

### 3. Process Mature Redemptions (2:00 PM UTC)

```bash
# Check for mature redemptions
forge script script/admin/CheckMatureRedemptions.s.sol --rpc-url $RPC_URL

# Process if any are ready
forge script script/admin/ProcessRedemptions.s.sol \
  --sig "run(uint256)" $MAX_TO_PROCESS \
  --rpc-url $RPC_URL \
  --broadcast
```

### 4. End of Day Report (6:00 PM UTC)

Generate daily report including:
- Total deposits/withdrawals
- NAV changes
- Redemption queue status
- Any incidents or anomalies

## Weekly Operations

### Monday: Liquidity Review

#### Assess Liquidity Needs
```solidity
// Calculate required liquidity for next week
uint256 pendingRedemptions = queue.getTotalPendingRedemptions();
uint256 bufferAmount = pendingRedemptions * 120 / 100; // 20% buffer
```

#### Rebalance Strategy if Needed
```bash
# Rebalance collateral in strategy
forge script script/admin/RebalanceStrategy.s.sol \
  --sig "run(address,uint256)" $TOKEN_ADDRESS $AMOUNT \
  --rpc-url $RPC_URL \
  --broadcast
```

### Wednesday: Security Review

1. Check all admin addresses active
2. Review recent transactions for anomalies
3. Verify no unauthorized role changes
4. Check for any paused states

### Friday: Performance Report

1. Calculate weekly yield
2. Compare to targets
3. Document any deviations
4. Plan for next week

## NAV Management

### Understanding NAV

NAV (Net Asset Value) represents the value per share in the vault:
```
NAV = Total Assets / Total Shares
```

### NAV Update Process

#### Step 1: Gather Market Data
```javascript
// Sources to check:
// - CoinGecko/CoinMarketCap for BTC price
// - DEX prices for wrapped tokens
// - Any yield generated

const btcPrice = await fetchBTCPrice();
const totalBTC = await strategy.totalAssets();
const totalValue = btcPrice * totalBTC;
```

#### Step 2: Calculate New NAV
```javascript
const totalShares = await vault.totalSupply();
const newNAV = totalValue / totalShares;

// Apply gradual change limits (max 10% daily)
const maxChange = currentNAV * 0.1;
const actualNAV = Math.min(newNAV, currentNAV + maxChange);
```

#### Step 3: Update Oracle
```bash
# Update price oracle with new NAV
forge script script/admin/UpdatePriceOracle.s.sol \
  --sig "run(uint256)" $(cast --to-wei $NAV) \
  --rpc-url $RPC_URL \
  --broadcast
```

### NAV Update Best Practices

1. **Consistency**: Update at the same time daily
2. **Verification**: Cross-check calculations
3. **Gradual Changes**: Avoid sudden jumps
4. **Documentation**: Log all updates with reasoning

## Redemption Queue Processing

### Understanding the Queue

The redemption queue holds user redemption requests for 14 days before processing.

### Processing Workflow

#### Step 1: Check Mature Redemptions
```javascript
// Get redemptions ready for processing
const matureRedemptions = await queue.getMatureRedemptions();
console.log(`${matureRedemptions.length} redemptions ready`);
```

#### Step 2: Ensure Liquidity
```javascript
// Calculate total sovaBTC needed
const totalNeeded = await queue.calculateTotalRedemptionValue();

// Check strategy balance
const available = await strategy.getAvailableSovaBTC();

if (available < totalNeeded) {
    // Need to rebalance or wait for more liquidity
    await rebalanceForLiquidity(totalNeeded - available);
}
```

#### Step 3: Process Redemptions
```bash
# Process up to 50 redemptions at once
forge script script/admin/ProcessRedemptions.s.sol \
  --sig "run(uint256)" 50 \
  --rpc-url $RPC_URL \
  --broadcast
```

#### Step 4: Verify Processing
```javascript
// Confirm redemptions processed
const remaining = await queue.queueLength();
console.log(`${remaining} redemptions still pending`);
```

### Queue Management Commands

```bash
# Force process specific redemption (emergency only)
cast send $QUEUE "forceProcessRedemption(uint256)" $REDEMPTION_ID

# Get queue statistics
cast call $QUEUE "getQueueStats()"

# Check specific redemption status
cast call $QUEUE "redemptionRequests(uint256)" $REDEMPTION_ID
```

## Liquidity Management

### Liquidity Planning

#### Weekly Liquidity Forecast
```javascript
function calculateLiquidityNeeds() {
    // Get redemptions maturing in next 7 days
    const upcomingRedemptions = queue.getRedemptionsMaturing(7 * 24 * 3600);
    
    // Add 20% buffer for unexpected redemptions
    const buffer = upcomingRedemptions * 0.2;
    
    // Total needed
    return upcomingRedemptions + buffer;
}
```

### Managing Collateral

#### Rebalancing Strategy
```bash
# Move funds between collateral types
forge script script/admin/RebalanceCollateral.s.sol \
  --sig "run(address,address,uint256)" $FROM_TOKEN $TO_TOKEN $AMOUNT \
  --rpc-url $RPC_URL \
  --broadcast
```

#### Adding Liquidity
```bash
# Add sovaBTC liquidity for redemptions
forge script script/admin/AddLiquidity.s.sol \
  --sig "run(uint256)" $AMOUNT \
  --rpc-url $RPC_URL \
  --broadcast
```

### Liquidity Monitoring

Key metrics to track:
- Available sovaBTC in strategy
- Pending redemption value
- Liquidity coverage ratio (available/pending)
- Days of liquidity remaining

## Emergency Procedures

### 1. Vault Pause (Critical Issues)

#### When to Pause
- Smart contract vulnerability discovered
- Oracle manipulation detected
- Abnormal redemption volume
- External protocol compromise

#### How to Pause
```bash
# Pause vault immediately
cast send $VAULT "pause()" --private-key $ADMIN_KEY

# Pause redemption queue
cast send $QUEUE "pause()" --private-key $ADMIN_KEY
```

### 2. Emergency Redemption Processing

If normal processing fails:
```bash
# Force process specific redemptions
forge script script/admin/EmergencyProcess.s.sol \
  --sig "forceProcess(uint256[])" "[1,2,3,4,5]" \
  --rpc-url $RPC_URL \
  --broadcast
```

### 3. Token Rescue (Stuck Tokens)

If tokens get stuck in contracts:
```bash
# Rescue stuck tokens from vault
cast send $VAULT "rescueTokens(address,uint256)" $TOKEN $AMOUNT

# Rescue from queue
cast send $QUEUE "rescueTokens(address,uint256)" $TOKEN $AMOUNT
```

### 4. Oracle Recovery

If price oracle fails:
```bash
# Reset oracle to safe value
forge script script/admin/ResetOracle.s.sol \
  --sig "run(uint256)" $SAFE_NAV \
  --rpc-url $RPC_URL \
  --broadcast
```

### 5. Emergency Contact Tree

```
Level 1 (Immediate): Technical Lead → DevOps
Level 2 (5 min): Security Team → Operations Manager  
Level 3 (15 min): Executive Team → Legal
```

## Monitoring and Alerts

### Key Metrics to Monitor

#### Real-time Monitoring (1-minute intervals)
- Contract pause status
- TVL changes > 10%
- Failed transactions
- Gas price spikes

#### Hourly Monitoring
- Redemption queue length
- NAV deviation from market
- Collateral balances
- User deposit/withdrawal patterns

#### Daily Monitoring
- Total yield generated
- Gas costs
- User growth
- System performance metrics

### Alert Configuration

```javascript
// Example monitoring setup
const alerts = {
    critical: {
        tvlDrop: 20, // Alert if TVL drops 20%
        queueLength: 100, // Alert if queue > 100
        navDeviation: 5 // Alert if NAV deviates 5% from market
    },
    warning: {
        tvlDrop: 10,
        queueLength: 50,
        navDeviation: 3
    }
};
```

### Monitoring Tools

1. **Tenderly**: Transaction monitoring and alerts
2. **Grafana**: Metrics visualization
3. **PagerDuty**: Alert management
4. **Custom Scripts**: Specific vault monitoring

## Operational Checklists

### Daily Checklist

- [ ] Check system health (9:00 AM)
- [ ] Review overnight activity
- [ ] Update NAV (10:00 AM)
- [ ] Process mature redemptions (2:00 PM)
- [ ] Review liquidity position
- [ ] Generate daily report (6:00 PM)
- [ ] Backup critical data

### Weekly Checklist

- [ ] Monday: Liquidity planning
- [ ] Tuesday: Performance review
- [ ] Wednesday: Security audit
- [ ] Thursday: Strategy rebalancing
- [ ] Friday: Weekly report
- [ ] Friday: System maintenance window

### Monthly Checklist

- [ ] Full system audit
- [ ] Role and permission review
- [ ] Update documentation
- [ ] Review and optimize gas costs
- [ ] Stakeholder reporting
- [ ] Disaster recovery test

## Troubleshooting Guide

### Common Issues and Solutions

#### Issue: NAV Update Fails
```bash
# Check reporter role
cast call $ORACLE "hasRole(bytes32,address)" $REPORTER_ROLE $ADMIN

# Check oracle not paused
cast call $ORACLE "paused()"

# Try with higher gas
forge script script/admin/UpdatePriceOracle.s.sol \
  --gas-price 50gwei \
  --rpc-url $RPC_URL
```

#### Issue: Redemption Processing Stuck
```bash
# Check queue status
cast call $QUEUE "paused()"

# Check liquidity available
cast call $STRATEGY "availableLiquidity()"

# Force process if needed
cast send $QUEUE "forceProcessRedemption(uint256)" $ID
```

#### Issue: High Gas Costs
```bash
# Process in smaller batches
forge script script/admin/ProcessRedemptions.s.sol \
  --sig "run(uint256)" 10 \
  --rpc-url $RPC_URL

# Wait for lower gas prices
# Use gas price oracle for optimal timing
```

#### Issue: Strategy Imbalance
```bash
# Check current allocations
cast call $STRATEGY "getCollateralBalances()"

# Rebalance to target weights
forge script script/admin/RebalanceStrategy.s.sol \
  --rpc-url $RPC_URL
```

## Best Practices

### Security

1. **Multi-sig**: Use multi-sig for all admin operations
2. **Time-locks**: Implement time-locks for critical changes
3. **Monitoring**: 24/7 monitoring with alerts
4. **Backup Plans**: Have rollback procedures ready
5. **Access Control**: Regularly audit role assignments

### Operations

1. **Documentation**: Log all operations with reasoning
2. **Automation**: Automate routine tasks where safe
3. **Testing**: Test all procedures on testnet first
4. **Communication**: Keep stakeholders informed
5. **Training**: Ensure backup operators are trained

### Performance

1. **Gas Optimization**: Batch operations when possible
2. **Timing**: Execute during low-gas periods
3. **Caching**: Cache frequently accessed data
4. **Indexing**: Use events for efficient querying
5. **Monitoring**: Track performance metrics

## Script Reference

### Available Admin Scripts

```bash
# Price Oracle Management
script/admin/UpdatePriceOracle.s.sol       # Update NAV
script/admin/SetPriceBounds.s.sol          # Set min/max NAV change

# Redemption Management  
script/admin/ProcessRedemptions.s.sol      # Process mature redemptions
script/admin/CheckMatureRedemptions.s.sol  # View ready redemptions
script/admin/ForceProcess.s.sol            # Emergency processing

# Liquidity Management
script/admin/RebalanceStrategy.s.sol       # Rebalance collateral
script/admin/AddLiquidity.s.sol            # Add sovaBTC liquidity
script/admin/WithdrawExcess.s.sol          # Remove excess liquidity

# Emergency Controls
script/admin/EmergencyPause.s.sol          # Pause all operations
script/admin/EmergencyUnpause.s.sol        # Resume operations
script/admin/RescueTokens.s.sol            # Rescue stuck tokens

# Monitoring
script/admin/GenerateReport.s.sol          # Generate system report
script/admin/CheckSystemHealth.s.sol       # Health check
script/admin/AuditRoles.s.sol              # Audit permissions
```

## Contact Information

### Technical Support
- Email: tech-support@sovanetwork.com
- Slack: #vault-operations
- On-call: +1-XXX-XXX-XXXX

### Emergency Contacts
- Security Team: security@sovanetwork.com
- DevOps: devops@sovanetwork.com
- Executive: executive@sovanetwork.com

---

*Last Updated: [Current Date]*
*Version: 1.0.0*
*Next Review: [Monthly]*