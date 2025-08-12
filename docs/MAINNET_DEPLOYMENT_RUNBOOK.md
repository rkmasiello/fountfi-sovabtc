# Mainnet Deployment Runbook

## Environment Setup

### 1. Configure Environment Variables
```bash
# Create .env.mainnet file
cp .env.example .env.mainnet

# Edit .env.mainnet with production values
export BASE_MAINNET_RPC_URL="https://mainnet.base.org"
export MAINNET_DEPLOYER_PRIVATE_KEY="0x..."
export BASESCAN_API_KEY="..."
export MAINNET_SAFE_ADDRESS="0x..."
```

### 2. Verify Environment
```bash
# Source environment variables
source .env.mainnet

# Verify connection to Base mainnet
cast chain-id --rpc-url $BASE_MAINNET_RPC_URL
# Expected output: 8453

# Check deployer balance
cast balance $MAINNET_DEPLOYER_ADDRESS --rpc-url $BASE_MAINNET_RPC_URL
# Ensure sufficient ETH for deployment (minimum 0.1 ETH recommended)
```

## Deployment Steps

### Step 1: Deploy Price Oracle Reporter
```bash
# Deploy the oracle contract
forge script script/deploy/DeployBtcVault.s.sol:DeployBtcVault \
  --rpc-url $BASE_MAINNET_RPC_URL \
  --private-key $MAINNET_DEPLOYER_PRIVATE_KEY \
  --broadcast \
  --verify \
  --etherscan-api-key $BASESCAN_API_KEY \
  --slow \
  -vvvv

# Save the deployed address
export ORACLE_ADDRESS="0x..."

# Verify deployment
cast call $ORACLE_ADDRESS "admin()" --rpc-url $BASE_MAINNET_RPC_URL
```

### Step 2: Deploy BTC Vault Strategy
```bash
# Deploy strategy contract
forge create src/strategy/BtcVaultStrategy.sol:BtcVaultStrategy \
  --constructor-args $MAINNET_ROLE_MANAGER $MAINNET_SOVABTC_ADDRESS $ORACLE_ADDRESS \
  --rpc-url $BASE_MAINNET_RPC_URL \
  --private-key $MAINNET_DEPLOYER_PRIVATE_KEY \
  --verify \
  --etherscan-api-key $BASESCAN_API_KEY

# Save the deployed address
export STRATEGY_ADDRESS="0x..."

# Verify deployment
cast call $STRATEGY_ADDRESS "sovaBTC()" --rpc-url $BASE_MAINNET_RPC_URL
```

### Step 3: Deploy BTC Vault Token
```bash
# Deploy token contract
forge create src/token/BtcVaultToken.sol:BtcVaultToken \
  --constructor-args $STRATEGY_ADDRESS \
  --rpc-url $BASE_MAINNET_RPC_URL \
  --private-key $MAINNET_DEPLOYER_PRIVATE_KEY \
  --verify \
  --etherscan-api-key $BASESCAN_API_KEY

# Save the deployed address
export TOKEN_ADDRESS="0x..."

# Verify deployment
cast call $TOKEN_ADDRESS "asset()" --rpc-url $BASE_MAINNET_RPC_URL
```

### Step 4: Configure Strategy
```bash
# Set the share token in strategy
cast send $STRATEGY_ADDRESS "setSToken(address)" $TOKEN_ADDRESS \
  --private-key $MAINNET_DEPLOYER_PRIVATE_KEY \
  --rpc-url $BASE_MAINNET_RPC_URL

# Verify configuration
cast call $STRATEGY_ADDRESS "sToken()" --rpc-url $BASE_MAINNET_RPC_URL
# Should return TOKEN_ADDRESS
```

## Configuration Steps

### Step 5: Setup Roles
```bash
# Grant ADMIN role to multi-sig
cast send $MAINNET_ROLE_MANAGER "grantRole(bytes32,address)" \
  $(cast keccak "ADMIN_ROLE") $MAINNET_SAFE_ADDRESS \
  --private-key $MAINNET_DEPLOYER_PRIVATE_KEY \
  --rpc-url $BASE_MAINNET_RPC_URL

# Grant MANAGER roles
cast send $MAINNET_ROLE_MANAGER "grantRole(bytes32,address)" \
  $(cast keccak "MANAGER_ROLE") $MAINNET_MANAGER_1 \
  --private-key $MAINNET_DEPLOYER_PRIVATE_KEY \
  --rpc-url $BASE_MAINNET_RPC_URL

cast send $MAINNET_ROLE_MANAGER "grantRole(bytes32,address)" \
  $(cast keccak "MANAGER_ROLE") $MAINNET_MANAGER_2 \
  --private-key $MAINNET_DEPLOYER_PRIVATE_KEY \
  --rpc-url $BASE_MAINNET_RPC_URL

# Grant OPERATOR roles
for operator in $MAINNET_OPERATOR_1 $MAINNET_OPERATOR_2 $MAINNET_OPERATOR_3; do
  cast send $MAINNET_ROLE_MANAGER "grantRole(bytes32,address)" \
    $(cast keccak "OPERATOR_ROLE") $operator \
    --private-key $MAINNET_DEPLOYER_PRIVATE_KEY \
    --rpc-url $BASE_MAINNET_RPC_URL
done

# Grant REPORTER role
cast send $MAINNET_ROLE_MANAGER "grantRole(bytes32,address)" \
  $(cast keccak "REPORTER_ROLE") $ORACLE_ADDRESS \
  --private-key $MAINNET_DEPLOYER_PRIVATE_KEY \
  --rpc-url $BASE_MAINNET_RPC_URL
```

### Step 6: Add Supported Collaterals
```bash
# Add wBTC (8 decimals)
cast send $STRATEGY_ADDRESS "addSupportedCollateral(address,uint8)" \
  0x1ceA84203673764244E05693e42E6Ace62bE9BA5 8 \
  --private-key $MAINNET_DEPLOYER_PRIVATE_KEY \
  --rpc-url $BASE_MAINNET_RPC_URL

# Add tBTC (18 decimals)
cast send $STRATEGY_ADDRESS "addSupportedCollateral(address,uint8)" \
  0x236aa50979D5f3De3Bd1Eeb40E81137F22ab794b 18 \
  --private-key $MAINNET_DEPLOYER_PRIVATE_KEY \
  --rpc-url $BASE_MAINNET_RPC_URL

# Add cbBTC (8 decimals)
cast send $STRATEGY_ADDRESS "addSupportedCollateral(address,uint8)" \
  0xcbB7C0000aB88B473b1f5aFd9ef808440eed33Bf 8 \
  --private-key $MAINNET_DEPLOYER_PRIVATE_KEY \
  --rpc-url $BASE_MAINNET_RPC_URL

# Verify collaterals
cast call $STRATEGY_ADDRESS "isSupportedCollateral(address)" \
  0x1ceA84203673764244E05693e42E6Ace62bE9BA5 \
  --rpc-url $BASE_MAINNET_RPC_URL
# Should return true
```

### Step 7: Add Initial Liquidity
```bash
# First, approve the strategy to spend sovaBTC
cast send $MAINNET_SOVABTC_ADDRESS "approve(address,uint256)" \
  $STRATEGY_ADDRESS 10000000000 \
  --private-key $MAINNET_DEPLOYER_PRIVATE_KEY \
  --rpc-url $BASE_MAINNET_RPC_URL

# Add liquidity (10 BTC worth)
cast send $STRATEGY_ADDRESS "addLiquidity(uint256)" \
  10000000000 \
  --private-key $MAINNET_DEPLOYER_PRIVATE_KEY \
  --rpc-url $BASE_MAINNET_RPC_URL

# Verify liquidity
cast call $STRATEGY_ADDRESS "availableLiquidity()" \
  --rpc-url $BASE_MAINNET_RPC_URL
# Should return 10000000000
```

### Step 8: Initialize NAV
```bash
# Set initial NAV (assuming 1:1 ratio)
cast send $STRATEGY_ADDRESS "report(uint256,uint256)" \
  10000000000 0 \
  --private-key $MAINNET_DEPLOYER_PRIVATE_KEY \
  --rpc-url $BASE_MAINNET_RPC_URL

# Verify NAV
cast call $STRATEGY_ADDRESS "nav()" --rpc-url $BASE_MAINNET_RPC_URL
```

## Verification Steps

### Step 9: Run Smoke Tests
```bash
# Run verification script
forge script script/verify/VerifyBtcVault.s.sol \
  --rpc-url $BASE_MAINNET_RPC_URL \
  --private-key $MAINNET_DEPLOYER_PRIVATE_KEY \
  -vvvv

# Manual test deposit (requires test tokens)
# 1. Approve wBTC
cast send 0x1ceA84203673764244E05693e42E6Ace62bE9BA5 \
  "approve(address,uint256)" $STRATEGY_ADDRESS 1000000 \
  --private-key $TEST_USER_PRIVATE_KEY \
  --rpc-url $BASE_MAINNET_RPC_URL

# 2. Deposit wBTC
cast send $STRATEGY_ADDRESS \
  "depositCollateral(address,uint256,address)" \
  0x1ceA84203673764244E05693e42E6Ace62bE9BA5 1000000 $TEST_USER_ADDRESS \
  --private-key $TEST_USER_PRIVATE_KEY \
  --rpc-url $BASE_MAINNET_RPC_URL

# 3. Check balance
cast call $TOKEN_ADDRESS "balanceOf(address)" $TEST_USER_ADDRESS \
  --rpc-url $BASE_MAINNET_RPC_URL
```

### Step 10: Transfer Ownership
```bash
# Transfer strategy ownership to multi-sig
cast send $STRATEGY_ADDRESS "transferOwnership(address)" \
  $MAINNET_SAFE_ADDRESS \
  --private-key $MAINNET_DEPLOYER_PRIVATE_KEY \
  --rpc-url $BASE_MAINNET_RPC_URL

# Transfer token ownership to multi-sig
cast send $TOKEN_ADDRESS "transferOwnership(address)" \
  $MAINNET_SAFE_ADDRESS \
  --private-key $MAINNET_DEPLOYER_PRIVATE_KEY \
  --rpc-url $BASE_MAINNET_RPC_URL

# Verify ownership transfer
cast call $STRATEGY_ADDRESS "owner()" --rpc-url $BASE_MAINNET_RPC_URL
# Should return MAINNET_SAFE_ADDRESS
```

## Post-Deployment

### Step 11: Save Deployment Output
```bash
# Create deployment record
cat > deployment-mainnet-$(date +%Y%m%d-%H%M%S).json << EOF
{
  "network": "base-mainnet",
  "chainId": 8453,
  "deploymentDate": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "deployer": "$MAINNET_DEPLOYER_ADDRESS",
  "contracts": {
    "BtcVaultStrategy": "$STRATEGY_ADDRESS",
    "BtcVaultToken": "$TOKEN_ADDRESS",
    "PriceOracleReporter": "$ORACLE_ADDRESS"
  },
  "configuration": {
    "multisig": "$MAINNET_SAFE_ADDRESS",
    "initialLiquidity": "10000000000",
    "collaterals": ["wBTC", "tBTC", "cbBTC"]
  },
  "verification": {
    "strategyVerified": true,
    "tokenVerified": true,
    "oracleVerified": true
  }
}
EOF

# Commit deployment record
git add deployment-mainnet-*.json
git commit -m "Record mainnet deployment $(date +%Y-%m-%d)"
git push origin main
```

### Step 12: Update Frontend Configuration
```bash
# Update frontend contract addresses
cd frontend
npm run update-contracts -- \
  --strategy $STRATEGY_ADDRESS \
  --token $TOKEN_ADDRESS \
  --network mainnet

# Build and deploy frontend
npm run build
npm run deploy:production
```

### Step 13: Setup Monitoring
```bash
# Import contracts to Tenderly
tenderly contract import \
  --network base \
  --address $STRATEGY_ADDRESS \
  --address $TOKEN_ADDRESS \
  --address $ORACLE_ADDRESS

# Configure alerts
tenderly alert create \
  --name "BTC Vault Mainnet Monitoring" \
  --network base \
  --address $STRATEGY_ADDRESS \
  --condition "event.name == 'LowLiquidity'"
```

## Rollback Procedure

If rollback is needed:

### Step 1: Pause Contracts
```bash
# Via multi-sig, pause the strategy
cast send $STRATEGY_ADDRESS "pause()" \
  --private-key $EMERGENCY_PRIVATE_KEY \
  --rpc-url $BASE_MAINNET_RPC_URL
```

### Step 2: Snapshot State
```bash
# Export current state
forge script script/emergency/SnapshotState.s.sol \
  --rpc-url $BASE_MAINNET_RPC_URL \
  --private-key $EMERGENCY_PRIVATE_KEY \
  -vvvv > state-snapshot.json
```

### Step 3: Deploy Previous Version
```bash
# Deploy previous stable version
forge script script/emergency/DeployPreviousVersion.s.sol \
  --rpc-url $BASE_MAINNET_RPC_URL \
  --private-key $EMERGENCY_PRIVATE_KEY \
  --broadcast \
  -vvvv
```

### Step 4: Migrate Balances
```bash
# Run migration script
forge script script/emergency/MigrateBalances.s.sol \
  --rpc-url $BASE_MAINNET_RPC_URL \
  --private-key $EMERGENCY_PRIVATE_KEY \
  --broadcast \
  -vvvv
```

## Emergency Contacts

- **Primary**: [Name] - [Phone] - [Email]
- **Secondary**: [Name] - [Phone] - [Email]
- **War Room**: [Link]
- **Incident Channel**: [Slack/Discord]

## Common Issues & Solutions

### Issue: Transaction Failing with "Insufficient Gas"
```bash
# Increase gas limit
--gas-limit 5000000
```

### Issue: Verification Failing on Basescan
```bash
# Retry with delay
sleep 30
forge verify-contract $CONTRACT_ADDRESS ContractName \
  --chain 8453 \
  --etherscan-api-key $BASESCAN_API_KEY \
  --watch
```

### Issue: Multi-sig Not Executing
```bash
# Check safe transaction queue
cast call $MAINNET_SAFE_ADDRESS "getTransactionCount()" \
  --rpc-url $BASE_MAINNET_RPC_URL
```

## Final Checklist

- [ ] All contracts deployed successfully
- [ ] All contracts verified on Basescan
- [ ] Roles configured correctly
- [ ] Collaterals added and tested
- [ ] Initial liquidity added
- [ ] Ownership transferred to multi-sig
- [ ] Frontend updated and deployed
- [ ] Monitoring active
- [ ] Documentation updated
- [ ] Team notified of success

---

**Last Updated**: Session 24
**Version**: 1.0.0
**Status**: Ready for Mainnet Deployment