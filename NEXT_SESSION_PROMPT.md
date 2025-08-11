# Next Session Prompt for Multi-Collateral BTC Vault Development

## Session 5: Deployment Scripts & Production Launch Preparation

You are continuing work on the FountFi Multi-Collateral BTC Vault system. Review ASSESSMENT_REPORT.md for the complete development history.

### ✅ Sessions 1-4 Completed:
- Core contracts implemented (Registry, Strategy, Vault, Queue)
- Vault-Queue integration with proper separation of concerns
- Emergency controls and production safety features
- Comprehensive integration test suite
- All 509 tests passing (100%)

### 🎯 Session 5 Priority: Create Complete Deployment System

**CRITICAL TASK: Production Deployment Scripts**

Create a professional deployment system in the `script/` directory with the following structure:

#### 1. Base Deployment Scripts (`script/deploy/`)
```
script/deploy/
├── 01_DeployCore.s.sol        # Deploy RoleManager and Registry
├── 02_DeployStrategy.s.sol    # Deploy MultiCollateralStrategy
├── 03_DeployVault.s.sol       # Deploy MultiBTCVault
├── 04_DeployQueue.s.sol       # Deploy ManagedRedemptionQueue (separate)
├── 05_DeployReporter.s.sol    # Deploy PriceOracleReporter
└── 06_Configure.s.sol         # Wire everything together
```

#### 2. Helper Scripts (`script/helpers/`)
```
script/helpers/
├── DeploymentConfig.sol       # Centralized configuration
├── DeploymentAddresses.sol    # Track deployed addresses
└── NetworkConfig.sol          # Network-specific settings
```

#### 3. Admin Scripts (`script/admin/`)
```
script/admin/
├── UpdatePriceOracle.s.sol    # Update NAV
├── ProcessRedemptions.s.sol   # Process queued redemptions
├── EmergencyPause.s.sol       # Emergency controls
└── ManageLiquidity.s.sol      # Add/remove sovaBTC liquidity
```

### 📋 Deployment Requirements:

1. **Network Support**:
   - Mainnet configuration
   - Sepolia testnet configuration
   - Local fork configuration
   - Proper RPC URLs and chain IDs

2. **Address Management**:
   - Save deployed addresses to JSON
   - Verify contracts on Etherscan
   - Generate deployment report

3. **Configuration**:
   - Initial collateral tokens (WBTC, TBTC, sovaBTC)
   - Conversion rates (WBTC: 1.0, TBTC: 0.99, sovaBTC: 1.0)
   - 14-day redemption period
   - 0.001 BTC minimum investment

4. **Security**:
   - Multi-step deployment with verification
   - Role assignments verification
   - Post-deployment tests

### 🔧 Technical Requirements:

1. **Use Foundry best practices**:
   ```solidity
   // Example structure
   contract DeployCore is Script {
       function run() external returns (address roleManager, address registry) {
           uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
           vm.startBroadcast(deployerPrivateKey);
           
           // Deploy contracts
           roleManager = address(new RoleManager());
           registry = address(new MultiCollateralRegistry(roleManager));
           
           // Save addresses
           _saveAddresses(roleManager, registry);
           
           vm.stopBroadcast();
       }
   }
   ```

2. **Environment Variables**:
   ```
   PRIVATE_KEY=
   ETHERSCAN_API_KEY=
   RPC_URL_MAINNET=
   RPC_URL_SEPOLIA=
   PROTOCOL_ADMIN_ADDRESS=
   ```

3. **Deployment Order**:
   ```
   1. RoleManager
   2. MultiCollateralRegistry
   3. MultiCollateralStrategy
   4. MultiBTCVault
   5. ManagedRedemptionQueue
   6. PriceOracleReporter
   7. Configuration & Wiring
   ```

### 🎯 Additional Tasks (If Time Permits):

1. **Create README for deployment**:
   - Step-by-step deployment guide
   - Environment setup instructions
   - Verification commands
   - Post-deployment checklist

2. **Create simple UI interaction examples**:
   - Example: How to deposit WBTC
   - Example: How to queue redemption
   - Example: Admin processing redemptions

3. **Gas optimization analysis**:
   - Run forge snapshot
   - Identify expensive operations
   - Suggest optimizations

### ⚠️ Important Notes:

1. **Queue remains separate**: ManagedRedemptionQueue is a separate contract
2. **Test on fork first**: Always test deployment on a mainnet fork
3. **Verify everything**: Each contract should be verified on Etherscan
4. **Document addresses**: Keep a clear record of all deployed addresses

### 📁 Key Files to Reference:
- `src/vaults/MultiBTCVault.sol` - Main vault contract
- `src/strategy/ManagedRedemptionQueue.sol` - Separate queue contract
- `src/strategy/MultiCollateralStrategy.sol` - Strategy contract
- `src/registry/MultiCollateralRegistry.sol` - Registry contract
- `test/integration/FullSystemTest.t.sol` - For deployment flow reference

### Success Criteria:
- [ ] All deployment scripts created and tested
- [ ] Successful deployment on testnet
- [ ] Contracts verified on Etherscan
- [ ] Admin can update price oracle
- [ ] Admin can process redemptions
- [ ] Users can deposit and queue redemptions
- [ ] Emergency controls tested
- [ ] Deployment documentation complete

### Testing the Deployment:
```bash
# Test deployment on local fork
forge script script/deploy/01_DeployCore.s.sol --fork-url $RPC_URL_MAINNET

# Deploy to testnet
forge script script/deploy/01_DeployCore.s.sol --rpc-url $RPC_URL_SEPOLIA --broadcast --verify

# Run post-deployment tests
forge test --match-contract DeploymentTest --fork-url $RPC_URL_SEPOLIA
```

Remember to follow the code style guidelines in CLAUDE.md. The system is fully functional with all tests passing - now it needs to be deployable!