# Session 25: Multi-Network Deployment Framework

## Context
We have successfully completed the BTC vault system with:
- ✅ Clean 2-contract architecture deployed on Base Sepolia
- ✅ 100% line coverage, 94% branch coverage (481 tests passing)
- ✅ Complete documentation suite (user, admin, deployment guides)
- ✅ Load testing and gas analysis completed
- ✅ Monitoring infrastructure deployed
- ✅ Mainnet deployment preparation complete

## Current Limitation
The deployment scripts are currently configured for Base network only. We need to deploy to multiple EVM chains, each with different:
- Collateral token addresses (WBTC, tBTC, etc. vary per chain)
- RPC endpoints
- Verification APIs
- Gas settings
- Oracle configurations

## Session 25 Objectives

### 1. Universal Deployment System
- [ ] Create network-agnostic deployment script
- [ ] Automatic network detection from RPC URL
- [ ] Dynamic configuration loading based on network
- [ ] Unified deployment command for any network
- [ ] Network validation before deployment

### 2. Multi-Network Configuration
Create configurations for:
- [ ] Ethereum Mainnet
- [ ] Arbitrum One
- [ ] Optimism
- [ ] Polygon (Matic)
- [ ] Avalanche C-Chain
- [ ] BNB Chain
- [ ] Base (update existing)

Each configuration should include:
- Network ID and name
- RPC endpoints (primary and fallback)
- Collateral token addresses (WBTC, tBTC, cbBTC, etc.)
- Oracle/price feed addresses
- Block explorer URLs
- Verification API endpoints
- Gas price strategies
- Network-specific settings

### 3. Cross-Chain Infrastructure

#### Deployment Registry
- [ ] Create DeploymentRegistry.sol contract
- [ ] Track deployments across all networks
- [ ] Version management system
- [ ] Upgrade tracking capability
- [ ] Query deployments by network/version

#### Network Abstraction Layer
- [ ] NetworkConfig library for chain-specific settings
- [ ] CollateralRegistry for cross-chain token mappings
- [ ] OracleRegistry for price feed configurations
- [ ] GasManager for network-specific gas strategies

### 4. Enhanced Deployment Scripts

#### Main Deployment Script
```solidity
// DeployMultiNetwork.s.sol
- Detect network from RPC
- Load appropriate configuration
- Deploy contracts
- Configure collaterals
- Set up oracles
- Save deployment info to registry
```

#### Network-Specific Helpers
- [ ] GetNetworkConfig.s.sol - Returns config for current network
- [ ] ValidateNetwork.s.sol - Ensures network is supported
- [ ] SaveDeployment.s.sol - Records deployment to registry
- [ ] QueryDeployments.s.sol - Lists all deployments

### 5. Testing Framework
- [ ] Fork testing script for each network
- [ ] Network-specific test configurations
- [ ] Cross-network deployment verification
- [ ] Gas optimization tests per network
- [ ] Collateral validation tests

### 6. Deployment Automation
- [ ] Single command to deploy to all networks
- [ ] Batch deployment script
- [ ] Deployment status dashboard
- [ ] Automatic verification on all explorers
- [ ] Post-deployment validation

## Technical Implementation

### Network Configuration Structure
```json
{
  "networks": {
    "ethereum": {
      "chainId": 1,
      "name": "Ethereum Mainnet",
      "rpc": {
        "primary": "https://eth-mainnet.g.alchemy.com/v2/KEY",
        "fallback": "https://mainnet.infura.io/v3/KEY"
      },
      "tokens": {
        "WBTC": "0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599",
        "tBTC": "0x18084fbA666a33d37592fA2633fD49a74DD93a88",
        "cbBTC": "0x..."
      },
      "oracles": {
        "BTC/USD": "0xF4030086522a5bEEa4988F8cA5B36dbC97BeE88c"
      },
      "explorer": "https://etherscan.io",
      "verifyApi": "https://api.etherscan.io/api"
    },
    // ... other networks
  }
}
```

### Deployment Commands
```bash
# Deploy to specific network
forge script DeployMultiNetwork --network ethereum

# Deploy to all networks
forge script DeployMultiNetwork --all-networks

# Query deployments
forge script QueryDeployments --network arbitrum

# Verify deployment
forge script VerifyDeployment --network optimism
```

## Success Criteria
- [ ] Can deploy to any supported EVM network with single command
- [ ] Automatic configuration loading based on network
- [ ] All deployments tracked in registry
- [ ] Network-specific tests passing
- [ ] Documentation updated for multi-network deployment

## Deliverables
1. **Multi-network configuration file** with all target chains
2. **Universal deployment script** that works on any network
3. **Deployment registry** for tracking cross-chain deployments
4. **Network abstraction libraries** for configuration management
5. **Testing suite** for each target network
6. **Documentation** for multi-network deployment process

## Networks Priority
1. **Phase 1** (Session 25): Ethereum, Arbitrum, Optimism, Base
2. **Phase 2** (Future): Polygon, Avalanche, BNB Chain
3. **Phase 3** (Future): Additional L2s and emerging chains

## Risk Considerations
- Different gas dynamics per network
- Varying block times affecting timeouts
- Network-specific token decimals
- Oracle availability per chain
- RPC rate limits during batch deployments

## Commands Reference
```bash
# Build project
forge build

# Test with network fork
forge test --fork-url https://eth-mainnet.g.alchemy.com/v2/KEY

# Deploy to specific network
forge script script/deploy/DeployMultiNetwork.s.sol \
  --rpc-url $ETH_RPC_URL \
  --broadcast \
  --verify

# Query all deployments
forge script script/query/ListDeployments.s.sol \
  --rpc-url $ETH_RPC_URL
```

## Notes
- Start with most important networks (Ethereum, Arbitrum)
- Ensure backward compatibility with existing Base deployment
- Consider gas costs on each network for initial setup
- Plan for different block confirmation requirements
- Account for network-specific quirks and limitations

---

**Session Goal**: Create a robust, extensible multi-network deployment framework that allows seamless deployment of the BTC vault system to any EVM-compatible blockchain with minimal configuration changes.