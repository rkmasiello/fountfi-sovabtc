# Multi-Network Deployment Guide

## Overview

The BTC Vault system now supports deployment across multiple EVM-compatible networks with a unified deployment framework. This guide covers the multi-network deployment process, configuration, and management.

## Supported Networks

### Production Networks
- **Ethereum Mainnet** (Chain ID: 1)
  - Collaterals: WBTC, tBTC, cbBTC
  - Oracle: Chainlink BTC/USD
  
- **Arbitrum One** (Chain ID: 42161)
  - Collaterals: WBTC, tBTC
  - Low gas costs, fast confirmations
  
- **Optimism** (Chain ID: 10)
  - Collaterals: WBTC, tBTC
  - L2 scalability benefits
  
- **Base** (Chain ID: 8453)
  - Collaterals: cbBTC
  - Coinbase ecosystem integration
  
- **Polygon** (Chain ID: 137)
  - Collaterals: WBTC
  - High throughput, low cost
  
- **Avalanche C-Chain** (Chain ID: 43114)
  - Collaterals: WBTC, BTC.b
  - Sub-second finality

### Test Networks
- **Base Sepolia** (Chain ID: 84532)
  - Current deployment location
  - All test collaterals available
  
- **Sepolia** (Chain ID: 11155111)
  - Ethereum testnet
  - For testing mainnet deployments

## Architecture Components

### 1. NetworkConfig Library
Located at `src/lib/NetworkConfig.sol`

Provides network-specific configurations:
- Chain IDs and network names
- Oracle addresses
- Gas settings
- Collateral token configurations
- Deployment defaults

### 2. DeploymentRegistry Contract
Located at `src/DeploymentRegistry.sol`

Tracks deployments across all networks:
- Deployment history
- Version management
- Active/inactive status
- Network-specific queries

### 3. Universal Deployment Script
Located at `script/deploy/DeployMultiNetwork.s.sol`

Features:
- Automatic network detection
- Dynamic configuration loading
- Collateral auto-configuration
- Deployment registration

## Deployment Process

### Prerequisites

1. **Environment Setup**
```bash
# Set RPC URLs for target networks
export ETHEREUM_RPC_URL="https://eth-mainnet.g.alchemy.com/v2/e7qIcHOK60Sc4-hvyWA68"
export ARBITRUM_RPC_URL="https://arb-mainnet.g.alchemy.com/v2/e7qIcHOK60Sc4-hvyWA68"
export OPTIMISM_RPC_URL="https://opt-mainnet.g.alchemy.com/v2/e7qIcHOK60Sc4-hvyWA68"
export BASE_RPC_URL="https://base-mainnet.g.alchemy.com/v2/e7qIcHOK60Sc4-hvyWA68"
export POLYGON_RPC_URL="https://polygon-mainnet.g.alchemy.com/v2/e7qIcHOK60Sc4-hvyWA68"
export AVALANCHE_RPC_URL="https://avax-mainnet.g.alchemy.com/v2/e7qIcHOK60Sc4-hvyWA68"

# Set verification API keys
export ETHERSCAN_API_KEY="KI5PMY8D813UGVZS7MEFMW7BW4AU8A14DV"
export ARBISCAN_API_KEY="KI5PMY8D813UGVZS7MEFMW7BW4AU8A14DV"
export OPTIMISM_API_KEY="KI5PMY8D813UGVZS7MEFMW7BW4AU8A14DV"
export BASESCAN_API_KEY="KI5PMY8D813UGVZS7MEFMW7BW4AU8A14DV"
export POLYGONSCAN_API_KEY="KI5PMY8D813UGVZS7MEFMW7BW4AU8A14DV"
export SNOWTRACE_API_KEY="KI5PMY8D813UGVZS7MEFMW7BW4AU8A14DV"

# Set deployment private key
export PRIVATE_KEY="0x..."
```

2. **Update Configuration**
Edit `deployment.multinetwork.config.json` with:
- Admin addresses
- Manager addresses
- Deployment limits
- Network-specific settings

### Single Network Deployment

Deploy to a specific network:

```bash
# Deploy to Ethereum Mainnet
forge script script/deploy/DeployMultiNetwork.s.sol \
  --rpc-url $ETHEREUM_RPC_URL \
  --private-key $PRIVATE_KEY \
  --broadcast \
  --verify

# Deploy to Arbitrum
forge script script/deploy/DeployMultiNetwork.s.sol \
  --rpc-url $ARBITRUM_RPC_URL \
  --private-key $PRIVATE_KEY \
  --broadcast \
  --verify
```

### Batch Deployment

Deploy to all configured networks:

```bash
forge script script/deploy/DeployMultiNetwork.s.sol:DeployMultiNetwork \
  --sig "deployToAllNetworks()" \
  --private-key $PRIVATE_KEY \
  --broadcast
```

### Network Validation

Before deployment, validate network configuration:

```bash
# Validate current network
forge script script/helpers/ValidateNetwork.s.sol \
  --rpc-url $ETHEREUM_RPC_URL

# Check collateral tokens, oracle feeds, and settings
```

## Post-Deployment

### 1. Verify Contracts

Contracts are automatically verified during deployment if API keys are set. Manual verification:

```bash
forge verify-contract <CONTRACT_ADDRESS> <CONTRACT_NAME> \
  --chain <CHAIN_ID> \
  --etherscan-api-key $API_KEY
```

### 2. Save Deployment Info

```bash
forge script script/helpers/SaveDeployment.s.sol \
  --sig "run(address,address,address)" \
  <STRATEGY> <TOKEN> <ORACLE> \
  --rpc-url $RPC_URL
```

### 3. Register with Registry

If using a deployment registry:

```bash
cast send <REGISTRY_ADDRESS> "registerDeployment(uint256,address,address,address,string,string)" \
  <CHAIN_ID> <STRATEGY> <TOKEN> <ORACLE> "1.0.0" "Network Name" \
  --private-key $PRIVATE_KEY \
  --rpc-url $RPC_URL
```

### 4. Query Deployments

```bash
# Query all deployments
forge script script/helpers/QueryDeployments.s.sol \
  --rpc-url $RPC_URL

# Query specific network
forge script script/helpers/QueryDeployments.s.sol \
  --sig "queryByNetwork(address,uint256)" \
  <REGISTRY_ADDRESS> <CHAIN_ID> \
  --rpc-url $RPC_URL
```

## Testing

### Fork Testing

Test deployment on network forks before mainnet:

```bash
# Test on Ethereum fork
forge test --match-contract MultiNetworkForkTest \
  --fork-url $ETHEREUM_RPC_URL \
  -vvv

# Test on Arbitrum fork
forge test --match-contract MultiNetworkForkTest \
  --fork-url $ARBITRUM_RPC_URL \
  -vvv
```

### Network-Specific Tests

```bash
# Run network-specific test suites
forge test --match-contract NetworkSpecificTests \
  --fork-url $RPC_URL \
  -vvv
```

## Configuration Management

### Network Configuration Structure

```json
{
  "networks": {
    "ethereum": {
      "chainId": 1,
      "tokens": {
        "WBTC": "0x...",
        "tBTC": "0x..."
      },
      "oracles": {
        "BTC_USD": "0x..."
      },
      "gasSettings": {
        "maxFeePerGas": "50000000000",
        "maxPriorityFeePerGas": "2000000000"
      }
    }
  }
}
```

### Adding New Networks

1. Update `NetworkConfig.sol`:
```solidity
// Add to getNetworkConfig()
else if (chainId == NEW_CHAIN_ID) {
    return Network({
        chainId: NEW_CHAIN_ID,
        name: "New Network",
        btcOracle: 0x...,
        confirmations: 2,
        maxFeePerGas: 50 gwei,
        maxPriorityFeePerGas: 2 gwei
    });
}
```

2. Add collateral configuration:
```solidity
// Add to getCollaterals()
else if (chainId == NEW_CHAIN_ID) {
    CollateralConfig[] memory collaterals = new CollateralConfig[](1);
    collaterals[0] = CollateralConfig({
        tokenAddress: 0x...,
        symbol: "WBTC",
        decimals: 8,
        isActive: true
    });
    return collaterals;
}
```

3. Update configuration file:
```json
"new-network": {
  "chainId": NEW_CHAIN_ID,
  "name": "New Network",
  ...
}
```

## Gas Optimization

### Network-Specific Gas Settings

Each network has different gas dynamics:

| Network | Max Fee (Gwei) | Priority Fee (Gwei) | Notes |
|---------|----------------|---------------------|--------|
| Ethereum | 50 | 2 | Higher during congestion |
| Arbitrum | 1 | 0 | L2 efficiency |
| Optimism | 1 | 0.001 | Stable fees |
| Base | 1 | 0.001 | Low cost |
| Polygon | 50 | 30 | Can spike |
| Avalanche | 50 | 2 | C-Chain pricing |

### Deployment Cost Estimates

Approximate deployment costs per network:

| Network | Gas Used | Est. Cost (USD) |
|---------|----------|-----------------|
| Ethereum | ~5M | $200-500 |
| Arbitrum | ~5M | $5-10 |
| Optimism | ~5M | $5-10 |
| Base | ~5M | $5-10 |
| Polygon | ~5M | $10-20 |
| Avalanche | ~5M | $20-40 |

## Monitoring

### Cross-Chain Monitoring

Monitor deployments across all networks:

```javascript
// monitoring/multiNetworkMonitor.js
const networks = [
  { name: 'Ethereum', rpc: process.env.ETHEREUM_RPC_URL },
  { name: 'Arbitrum', rpc: process.env.ARBITRUM_RPC_URL },
  // ... other networks
];

for (const network of networks) {
  const provider = new ethers.JsonRpcProvider(network.rpc);
  const strategy = new ethers.Contract(strategyAddress, abi, provider);
  
  const tvl = await strategy.totalAssets();
  console.log(`${network.name} TVL: ${tvl}`);
}
```

### Registry Queries

Use the deployment registry to track all deployments:

```javascript
const registry = new ethers.Contract(registryAddress, registryAbi, provider);
const deployments = await registry.getAllActiveDeployments();

for (const deployment of deployments) {
  console.log(`Chain ${deployment.chainId}: ${deployment.strategyAddress}`);
}
```

## Troubleshooting

### Common Issues

1. **Network Not Supported Error**
   - Ensure chain ID is added to NetworkConfig.sol
   - Verify RPC URL is correct

2. **Collateral Configuration Failed**
   - Check token addresses are correct for network
   - Verify token contracts exist on network

3. **Gas Estimation Failed**
   - Adjust gas settings in configuration
   - Check account has sufficient balance

4. **Verification Failed**
   - Ensure correct API key for network
   - Wait for more confirmations
   - Try manual verification

### Debug Commands

```bash
# Check network configuration
cast call <NETWORK_CONFIG_ADDRESS> "getNetworkName(uint256)" <CHAIN_ID>

# Verify collateral support
cast call <STRATEGY_ADDRESS> "isSupportedCollateral(address)" <TOKEN_ADDRESS>

# Check deployment registry
cast call <REGISTRY_ADDRESS> "getActiveDeployment(uint256)" <CHAIN_ID>
```

## Security Considerations

1. **Network Validation**
   - Always validate network before deployment
   - Verify collateral addresses
   - Check oracle feeds are active

2. **Multi-Sig Setup**
   - Use different admin addresses per network
   - Configure time delays for critical operations
   - Implement emergency pause mechanisms

3. **Cross-Chain Risks**
   - Bridge security varies by network
   - Oracle reliability differs
   - Consider network-specific attack vectors

## Best Practices

1. **Deployment Order**
   - Deploy to testnets first
   - Start with lower-value networks
   - Gradually increase deployment scope

2. **Configuration Management**
   - Keep network configs in version control
   - Document all address changes
   - Maintain deployment history

3. **Monitoring Setup**
   - Deploy monitoring before mainnet
   - Set up alerts for each network
   - Track cross-chain metrics

4. **Upgrade Planning**
   - Plan upgrades per network
   - Consider network-specific timelines
   - Coordinate cross-chain updates

## Advanced Features

### Custom Network Handlers

Create network-specific deployment logic:

```solidity
contract CustomNetworkDeploy is DeployMultiNetwork {
    function deployToCustomNetwork() external {
        if (chainId == CUSTOM_CHAIN_ID) {
            // Custom deployment logic
            _deployCustomContracts();
            _configureCustomSettings();
        }
    }
}
```

### Cross-Chain Communication

For future cross-chain features:

```solidity
interface ICrossChainRegistry {
    function syncDeployment(
        uint256 sourceChain,
        uint256 targetChain,
        address deployment
    ) external;
}
```

## Conclusion

The multi-network deployment framework provides a robust, scalable solution for deploying the BTC Vault system across multiple EVM chains. By following this guide and using the provided tools, you can efficiently manage deployments, monitor performance, and maintain consistency across all supported networks.