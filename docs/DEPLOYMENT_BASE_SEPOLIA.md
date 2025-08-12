# Base Sepolia Deployment

## Network Information
- **Network**: Base Sepolia
- **Chain ID**: 84532
- **RPC URL**: https://base-sepolia.g.alchemy.com/v2/e7qIcHOK60Sc4-hvyWA68
- **Block Explorer**: https://sepolia.basescan.org/
- **Currency**: ETH (Sepolia ETH)

## Deployment Date
- **Date**: August 12, 2025
- **Deployer**: 0x1804c8AB1F12E6bbf3894d4083f33e07309d1f38

## Core Contracts

### Access Control
- **RoleManager**: `0x15502fC5e872c8B22BA6dD5e01A7A5bd4f9A3d72`
  - Manages all system roles and permissions
  - Admin: 0x1804c8AB1F12E6bbf3894d4083f33e07309d1f38

### Core System
- **MultiCollateralRegistry**: `0x15a9983784617aa8892b2677bbaEc23539482B65`
  - Manages supported collateral tokens
  - Tracks conversion rates and decimals

- **MultiCollateralStrategy**: `0x740907524EbD6A481a81cE76B5115A4cDDb80099`
  - Holds and manages multiple BTC collateral types
  - Connected to vault for withdrawals

- **MultiBTCVault**: `0x73E27097221d4d9D5893a83350dC7A967b46fab7`
  - Main ERC-4626 vault contract
  - Token Name: Multi-Collateral BTC Vault
  - Token Symbol: mcBTC
  - Decimals: 18

- **ManagedRedemptionQueue**: `0x22BC73098CE1Ba2CaE5431fb32051cB4fc0F9C52`
  - Manages 1-day redemption queue (reduced for testing)
  - Holds shares during redemption period

- **PriceOracleReporter**: `0xDB4479A2360E118CCbD99B88e82522813BDE48f5`
  - Manual NAV price oracle
  - Initial NAV: 1.0
  - Max deviation: 5% per hour

## Mock Collateral Tokens

### WBTC (Mock)
- **Address**: `0xe44b2870eFcd6Bb3C9305808012621f438e9636D`
- **Decimals**: 8
- **Conversion Rate**: 1.0

### TBTC (Mock)
- **Address**: `0xE2b47f0dD766834b9DD2612D2d3632B05Ca89802`
- **Decimals**: 18
- **Conversion Rate**: 0.99

### sovaBTC (Mock)
- **Address**: `0x05aB19d77516414f7333a8fd52cC1F49FF8eAFA9`
- **Decimals**: 8
- **Conversion Rate**: 1.0
- **Note**: Primary redemption token

## Configuration Status

### Contract Connections ✅
- [x] Strategy -> Vault: Connected
- [x] Vault -> Strategy: Connected
- [x] Vault -> Queue: Connected
- [x] Vault -> PriceOracle: Connected
- [x] Registry -> Collaterals: Configured

### Roles Assigned ✅
- [x] PROTOCOL_ADMIN: 0x1804c8AB1F12E6bbf3894d4083f33e07309d1f38
- [x] OPERATOR: 0x1804c8AB1F12E6bbf3894d4083f33e07309d1f38
- [x] REPORTER: 0x1804c8AB1F12E6bbf3894d4083f33e07309d1f38

## System Parameters

### Investment Limits
- **Minimum Investment**: 0.001 BTC (100,000 units in 8 decimals)
- **Maximum Investment**: No limit

### Redemption Settings
- **Redemption Period**: 1 day (reduced from 14 days for testing)
- **Redemption Token**: sovaBTC only
- **Queue Processing**: Manual by operator

### Price Oracle Settings
- **Initial NAV**: 1.0
- **Max Deviation**: 5% per hour
- **Update Frequency**: Manual updates by reporter

## Testing Instructions

### 1. Get Test Tokens
First, mint yourself some test tokens:
```bash
# Get WBTC
cast send 0xe44b2870eFcd6Bb3C9305808012621f438e9636D "mint(address,uint256)" YOUR_ADDRESS 1000000000 --private-key YOUR_KEY --rpc-url https://base-sepolia.g.alchemy.com/v2/e7qIcHOK60Sc4-hvyWA68

# Get TBTC
cast send 0xE2b47f0dD766834b9DD2612D2d3632B05Ca89802 "mint(address,uint256)" YOUR_ADDRESS 1000000000000000000000 --private-key YOUR_KEY --rpc-url https://base-sepolia.g.alchemy.com/v2/e7qIcHOK60Sc4-hvyWA68
```

### 2. Approve and Deposit
```bash
# Approve WBTC
cast send 0xe44b2870eFcd6Bb3C9305808012621f438e9636D "approve(address,uint256)" 0x73E27097221d4d9D5893a83350dC7A967b46fab7 1000000000 --private-key YOUR_KEY --rpc-url https://base-sepolia.g.alchemy.com/v2/e7qIcHOK60Sc4-hvyWA68

# Deposit WBTC
cast send 0x73E27097221d4d9D5893a83350dC7A967b46fab7 "deposit(address,uint256,address)" 0xe44b2870eFcd6Bb3C9305808012621f438e9636D 100000000 YOUR_ADDRESS --private-key YOUR_KEY --rpc-url https://base-sepolia.g.alchemy.com/v2/e7qIcHOK60Sc4-hvyWA68
```

### 3. Request Redemption
```bash
# Request redemption
cast send 0x73E27097221d4d9D5893a83350dC7A967b46fab7 "requestRedeem(uint256,address,address)" 1000000000000000000 YOUR_ADDRESS YOUR_ADDRESS --private-key YOUR_KEY --rpc-url https://base-sepolia.g.alchemy.com/v2/e7qIcHOK60Sc4-hvyWA68
```

### 4. Process Redemption (Admin)
```bash
# After 1 day, process redemptions
cast send 0x22BC73098CE1Ba2CaE5431fb32051cB4fc0F9C52 "processRedemptions(uint256)" 10 --private-key ADMIN_KEY --rpc-url https://base-sepolia.g.alchemy.com/v2/e7qIcHOK60Sc4-hvyWA68
```

## Admin Operations

### Update NAV
```bash
cast send 0xDB4479A2360E118CCbD99B88e82522813BDE48f5 "updatePrice(uint256)" 1050000000000000000 --private-key ADMIN_KEY --rpc-url https://base-sepolia.g.alchemy.com/v2/e7qIcHOK60Sc4-hvyWA68
```

### Emergency Pause
```bash
cast send 0x73E27097221d4d9D5893a83350dC7A967b46fab7 "pause()" --private-key ADMIN_KEY --rpc-url https://base-sepolia.g.alchemy.com/v2/e7qIcHOK60Sc4-hvyWA68
```

## Verification Links
- RoleManager: https://sepolia.basescan.org/address/0x15502fC5e872c8B22BA6dD5e01A7A5bd4f9A3d72
- Registry: https://sepolia.basescan.org/address/0x15a9983784617aa8892b2677bbaEc23539482B65
- Strategy: https://sepolia.basescan.org/address/0x740907524EbD6A481a81cE76B5115A4cDDb80099
- Vault: https://sepolia.basescan.org/address/0x73E27097221d4d9D5893a83350dC7A967b46fab7
- Queue: https://sepolia.basescan.org/address/0x22BC73098CE1Ba2CaE5431fb32051cB4fc0F9C52
- PriceOracle: https://sepolia.basescan.org/address/0xDB4479A2360E118CCbD99B88e82522813BDE48f5

## Gas Costs (Estimated)
- Deposit: ~217,000 gas
- Request Redemption: ~150,000 gas
- Process Redemption: ~337,000 gas
- Update NAV: ~50,000 gas

## Notes
1. This is a testnet deployment with reduced redemption period (1 day instead of 14)
2. All admin roles are assigned to the deployer for testing
3. Mock tokens have mint functions for easy testing
4. Initial NAV is set to 1.0
5. System is fully configured and ready for testing

## Support
For issues or questions about this deployment, please refer to the main documentation or create an issue in the repository.