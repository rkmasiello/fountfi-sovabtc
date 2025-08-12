# Mainnet Deployment Guide

## Overview

This guide provides step-by-step instructions for deploying the Multi-Collateral BTC Vault to mainnet across multiple chains.

## Supported Networks

- **Base** (Chain ID: 8453) - Primary deployment
- **Ethereum** (Chain ID: 1) - Secondary deployment
- **Arbitrum** (Chain ID: 42161) - L2 deployment
- **Optimism** (Chain ID: 10) - L2 deployment

## Pre-Deployment Checklist

### 1. Security Audit
- [ ] Smart contracts audited by reputable firm
- [ ] Audit findings addressed
- [ ] Final audit report published

### 2. Configuration
- [ ] Multisig wallet deployed on target network
- [ ] Team member addresses collected
- [ ] BTC token addresses verified for each network
- [ ] Initial parameters decided (min deposit, redemption delay, etc.)

### 3. Infrastructure
- [ ] RPC endpoints configured (Alchemy/Infura)
- [ ] Block explorer API keys obtained
- [ ] Monitoring system deployed
- [ ] Indexer infrastructure ready

### 4. Testing
- [ ] All tests passing (`forge test`)
- [ ] Deployment tested on fork
- [ ] Integration tests completed
- [ ] Load testing performed

## Deployment Process

### Step 1: Environment Setup

```bash
# Copy environment template
cp .env.example .env

# Edit .env with your configuration
# Required variables:
# - PRIVATE_KEY (deployer wallet)
# - RPC_URL_BASE
# - RPC_URL_ETHEREUM
# - RPC_URL_ARBITRUM
# - RPC_URL_OPTIMISM
# - ETHERSCAN_API_KEY
# - BASESCAN_API_KEY
# - ARBISCAN_API_KEY
# - OPSCAN_API_KEY
```

### Step 2: Update Network Configuration

Edit `script/deploy/DeployMainnet.s.sol` and update:

```solidity
// Base Mainnet
networkConfigs[8453] = NetworkConfig({
    wbtc: 0x...,      // Actual WBTC address on Base
    tbtc: 0x...,      // Actual tBTC address on Base
    sovaBTC: 0x...,   // Actual sovaBTC address on Base
    multisig: 0x...,  // Your multisig address
    redemptionDelay: 14 days,
    minDeposit: 0.001e8,
    vaultName: "Multi-Collateral Bitcoin",
    vaultSymbol: "mcBTC"
});
```

### Step 3: Deploy Contracts

#### Base Deployment

```bash
# Dry run first
forge script script/deploy/DeployMainnet.s.sol \
    --rpc-url $RPC_URL_BASE \
    --chain-id 8453 \
    --dry-run

# Actual deployment
forge script script/deploy/DeployMainnet.s.sol \
    --rpc-url $RPC_URL_BASE \
    --chain-id 8453 \
    --broadcast \
    --verify \
    --etherscan-api-key $BASESCAN_API_KEY
```

#### Ethereum Deployment

```bash
forge script script/deploy/DeployMainnet.s.sol \
    --rpc-url $RPC_URL_ETHEREUM \
    --chain-id 1 \
    --broadcast \
    --verify \
    --etherscan-api-key $ETHERSCAN_API_KEY
```

### Step 4: Verify Contracts

```bash
# Run verification script
forge script script/deploy/VerifyContracts.s.sol \
    --rpc-url $RPC_URL_BASE \
    --chain-id 8453

# Follow the generated commands to verify each contract
```

### Step 5: Post-Deployment Checks

```bash
# Run automated checks
forge script script/deploy/PostDeploymentChecks.s.sol \
    --rpc-url $RPC_URL_BASE \
    --chain-id 8453
```

### Step 6: Initial Configuration

#### 1. Transfer Ownership to Multisig

```bash
# Grant admin role to multisig
cast send $ROLE_MANAGER \
    "grantRole(bytes32,address)" \
    $(cast keccak "ADMIN_ROLE") \
    $MULTISIG_ADDRESS \
    --rpc-url $RPC_URL_BASE \
    --private-key $PRIVATE_KEY

# Revoke deployer admin role (after multisig confirms)
cast send $ROLE_MANAGER \
    "revokeRole(bytes32,address)" \
    $(cast keccak "ADMIN_ROLE") \
    $DEPLOYER_ADDRESS \
    --rpc-url $RPC_URL_BASE \
    --private-key $PRIVATE_KEY
```

#### 2. Add Initial Liquidity

```bash
# Transfer initial sovaBTC to strategy for redemptions
cast send $SOVABTC_TOKEN \
    "transfer(address,uint256)" \
    $STRATEGY_ADDRESS \
    10000000000 \
    --rpc-url $RPC_URL_BASE \
    --private-key $PRIVATE_KEY
```

#### 3. Set Initial Price

```bash
# Set initial NAV (1:1 ratio)
cast send $PRICE_ORACLE \
    "updatePrice(uint256)" \
    1000000000000000000 \
    --rpc-url $RPC_URL_BASE \
    --private-key $PRIVATE_KEY
```

### Step 7: Deploy Supporting Infrastructure

#### 1. Deploy Ponder Indexer

```bash
cd examples/ponder-indexer

# Update configuration for mainnet
cp .env.example .env
# Edit .env with mainnet values

# Deploy to Railway
railway up

# Or deploy with Docker
docker build -t vault-indexer .
docker run -d --env-file .env vault-indexer
```

#### 2. Deploy Monitoring

```bash
cd scripts/monitoring

# Install dependencies
npm install

# Configure for mainnet
cp .env.example .env
# Edit .env with mainnet values

# Start monitoring
npm start
```

#### 3. Deploy Frontend

```bash
cd frontend

# Update environment for mainnet
cp .env.example .env.production
# Edit with mainnet values

# Deploy to Vercel
vercel --prod

# Or deploy to Netlify
netlify deploy --prod
```

## Post-Deployment Tasks

### Immediate (Day 1)

1. **Verify all contracts** on block explorers
2. **Test basic operations** with small amounts
3. **Configure monitoring alerts**
4. **Set up multisig operations**
5. **Document all addresses**

### Short-term (Week 1)

1. **Add initial liquidity** for redemptions
2. **Configure price oracle updates**
3. **Enable frontend for beta users**
4. **Monitor system health**
5. **Prepare marketing materials**

### Medium-term (Month 1)

1. **Gradual rollout** to users
2. **Integrate with partners**
3. **Optimize gas costs**
4. **Expand monitoring**
5. **Gather user feedback**

## Emergency Procedures

### Pause System

```bash
# Pause vault (stops deposits/withdrawals)
cast send $VAULT_ADDRESS \
    "pause()" \
    --rpc-url $RPC_URL_BASE \
    --private-key $MULTISIG_KEY
```

### Force Process Redemptions

```bash
# Process pending redemptions immediately
cast send $QUEUE_ADDRESS \
    "forceProcessRedemptions(uint256[])" \
    "[1,2,3,4,5]" \
    --rpc-url $RPC_URL_BASE \
    --private-key $MULTISIG_KEY
```

### Rescue Tokens

```bash
# Rescue stuck tokens from strategy
cast send $STRATEGY_ADDRESS \
    "rescueToken(address,uint256)" \
    $TOKEN_ADDRESS \
    $AMOUNT \
    --rpc-url $RPC_URL_BASE \
    --private-key $MULTISIG_KEY
```

## Monitoring Endpoints

- **Vault Health**: `https://api.yourdomain.com/health`
- **Indexer Status**: `https://indexer.yourdomain.com/health`
- **Metrics Dashboard**: `https://metrics.yourdomain.com`
- **Admin Panel**: `https://admin.yourdomain.com`

## Support Channels

- **Technical Issues**: tech@yourdomain.com
- **Security Reports**: security@yourdomain.com
- **Discord**: https://discord.gg/yourdomain
- **Telegram**: https://t.me/yourdomain

## Contract Addresses (To be filled after deployment)

### Base Mainnet
- RoleManager: `0x...`
- Registry: `0x...`
- Strategy: `0x...`
- Vault: `0x...`
- Queue: `0x...`
- PriceOracle: `0x...`

### Ethereum Mainnet
- RoleManager: `0x...`
- Registry: `0x...`
- Strategy: `0x...`
- Vault: `0x...`
- Queue: `0x...`
- PriceOracle: `0x...`

## Deployment Checklist Summary

- [ ] Pre-deployment security audit complete
- [ ] Network configurations updated
- [ ] Contracts deployed successfully
- [ ] Contracts verified on block explorers
- [ ] Post-deployment checks passed
- [ ] Ownership transferred to multisig
- [ ] Initial liquidity added
- [ ] Monitoring systems active
- [ ] Indexer deployed and syncing
- [ ] Frontend deployed and tested
- [ ] Documentation updated
- [ ] Team trained on operations
- [ ] Emergency procedures tested
- [ ] Public announcement prepared

## Notes

- Always test on a fork first: `forge script --fork-url $RPC_URL`
- Keep deployment private keys secure and never commit them
- Document all transactions and addresses
- Have at least 2 team members verify each step
- Maintain a deployment log for audit trail