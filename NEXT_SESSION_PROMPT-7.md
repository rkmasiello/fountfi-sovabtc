# Next Session Prompt for Multi-Collateral BTC Vault

## Session 7: Base Sepolia Deployment & Live Testing

You are continuing work on the FountFi Multi-Collateral BTC Vault system. Review ASSESSMENT_REPORT.md for the complete development history.

### ✅ Current Status:
- All core contracts implemented and tested (509 tests passing)
- Complete deployment infrastructure created
- Comprehensive documentation suite completed
- Web3 integration examples and subgraph schema ready
- Gas optimization analyzed (217k deposit, 337k redemption)
- System is fully documented and production-ready

### 🎯 Session 7 Goals: Deploy to Base Sepolia & Conduct Live Testing

**PRIMARY OBJECTIVE: Deploy the complete system to Base Sepolia testnet and conduct end-to-end testing**

### 🔗 Network Configuration:
- **Network**: Base Sepolia
- **Chain ID**: 84532
- **RPC URL**: https://base-sepolia.g.alchemy.com/v2/e7qIcHOK60Sc4-hvyWA68
- **Block Explorer**: https://sepolia.basescan.org/
- **Currency**: ETH (Sepolia ETH)

#### 1. Base Sepolia Testnet Deployment

##### A. Pre-Deployment Setup
- [ ] Configure Base Sepolia RPC endpoint (Alchemy)
- [ ] Fund deployment wallet with Base Sepolia ETH
- [ ] Configure environment variables
- [ ] Deploy mock BTC tokens if needed (WBTC, TBTC, sovaBTC)

```bash
# Set environment variables
export BASE_SEPOLIA_RPC_URL="https://base-sepolia.g.alchemy.com/v2/e7qIcHOK60Sc4-hvyWA68"
export CHAIN_ID=84532
export ETHERSCAN_API_KEY="your_basescan_api_key"
```

##### B. Execute Deployment
```bash
# Deploy all contracts
forge script script/DeployAll.s.sol \
  --rpc-url $BASE_SEPOLIA_RPC_URL \
  --broadcast \
  --verify \
  --verifier-url https://api-sepolia.basescan.org/api \
  --etherscan-api-key $ETHERSCAN_API_KEY \
  --chain-id 84532

# Run verification script
forge script script/VerifyDeployment.s.sol \
  --rpc-url $BASE_SEPOLIA_RPC_URL \
  --chain-id 84532
```

##### C. Contract Verification
- [ ] Verify all contracts on Base Sepolia Basescan
- [ ] Ensure source code is readable
- [ ] Confirm all constructor arguments

#### 2. Document Deployed Addresses

Create `docs/DEPLOYMENT_BASE_SEPOLIA.md` with:
```markdown
# Base Sepolia Deployment

## Core Contracts
- RoleManager: 0x...
- MultiCollateralRegistry: 0x...
- MultiCollateralStrategy: 0x...
- MultiBTCVault: 0x...
- ManagedRedemptionQueue: 0x...
- PriceOracleReporter: 0x...

## Collateral Tokens
- WBTC (Mock): 0x...
- TBTC (Mock): 0x...
- sovaBTC (Mock): 0x...

## Admin Addresses
- Admin: 0x...
- Operator: 0x...
- Reporter: 0x...

## Deployment Info
- Network: Base Sepolia
- Chain ID: 84532
- Block Number: ...
- Transaction Hash: ...
- Deployer: 0x...
- Date: ...
```

#### 3. Live Testing on Base Sepolia

##### A. Basic Functionality Tests
- [ ] Deposit WBTC and receive mcBTC shares
- [ ] Deposit TBTC and receive mcBTC shares
- [ ] Transfer mcBTC shares between accounts
- [ ] Request redemption (enter queue)
- [ ] Check redemption queue status

##### B. Admin Operations Testing
- [ ] Update NAV via price oracle
- [ ] Process mature redemptions (after time advance)
- [ ] Test emergency pause/unpause
- [ ] Verify role-based access control

##### C. Integration Testing
- [ ] Test Web3.js integration example against live contracts
- [ ] Verify event emissions
- [ ] Test gas consumption matches estimates
- [ ] Confirm decimal handling across collaterals

#### 4. Create Testing Scripts

##### A. User Testing Script (`script/test/TestUserFlow.s.sol`)
```solidity
// Script to test complete user flow
// 1. Mint mock tokens
// 2. Approve vault
// 3. Deposit collateral
// 4. Check shares received
// 5. Request redemption
// 6. Check queue status
```

##### B. Admin Testing Script (`script/test/TestAdminFlow.s.sol`)
```solidity
// Script to test admin operations
// 1. Update NAV
// 2. Process redemptions
// 3. Emergency procedures
// 4. Liquidity management
```

#### 5. Performance Benchmarking

##### A. Load Testing
- Test with multiple concurrent users
- Measure transaction throughput
- Monitor gas consumption patterns
- Document performance metrics

##### B. Create Performance Report
```markdown
# Base Sepolia Performance Report
- Average deposit time: X seconds
- Average redemption processing: X seconds
- Gas costs at X gwei
- Concurrent user capacity
- Queue processing efficiency
```

#### 6. Update Integration Examples

##### A. Update Web3 Integration
- Replace placeholder addresses with actual Base Sepolia addresses
- Test all functions against live contracts
- Create working demo page
- Update chain ID to 84532

##### B. Deploy Subgraph (Optional)
- Deploy subgraph to The Graph's hosted service
- Index Base Sepolia contracts
- Test queries
- Update network configuration in subgraph.yaml

#### 7. Security Checks

##### A. Access Control Verification
- [ ] Confirm only admin can pause
- [ ] Verify only operator can process redemptions
- [ ] Test unauthorized access attempts
- [ ] Validate role inheritance

##### B. Edge Case Testing
- [ ] Test with minimum deposits (0.001 BTC)
- [ ] Test with maximum uint256 values
- [ ] Test rapid deposit/withdraw cycles
- [ ] Test queue overflow scenarios

#### 8. Create Demo Materials

##### A. Video Demo Script
- Show deposit flow
- Demonstrate redemption queue
- Display admin operations
- Highlight security features

##### B. Test dApp Interface (Optional)
- Simple React interface
- Connect wallet functionality
- Deposit/Redeem UI
- Admin panel

### 📋 Deliverables for Session 7:

1. **Base Sepolia Deployment**
   - [ ] All contracts deployed and verified
   - [ ] Deployment addresses documented
   - [ ] Verification script passed
   - [ ] Basescan verification complete

2. **Testing Results**
   - [ ] User flow tested end-to-end
   - [ ] Admin operations verified
   - [ ] Performance benchmarks recorded
   - [ ] Security checks passed

3. **Documentation Updates**
   - [ ] Base Sepolia deployment guide
   - [ ] Testing report
   - [ ] Performance metrics
   - [ ] Updated integration examples with live addresses

4. **Demo Materials**
   - [ ] Working testnet demo
   - [ ] Test scripts for users and admins
   - [ ] Optional: Basic UI for testing

### 🔧 Technical Commands:

```bash
# Deploy to Base Sepolia
forge script script/DeployAll.s.sol \
  --rpc-url https://base-sepolia.g.alchemy.com/v2/e7qIcHOK60Sc4-hvyWA68 \
  --broadcast \
  --verify \
  --chain-id 84532

# Verify specific contract
forge verify-contract <ADDRESS> <CONTRACT_NAME> \
  --chain-id 84532 \
  --verifier-url https://api-sepolia.basescan.org/api \
  --watch

# Test user flow
forge script script/test/TestUserFlow.s.sol \
  --rpc-url https://base-sepolia.g.alchemy.com/v2/e7qIcHOK60Sc4-hvyWA68 \
  --broadcast

# Test admin operations
forge script script/test/TestAdminFlow.s.sol \
  --rpc-url https://base-sepolia.g.alchemy.com/v2/e7qIcHOK60Sc4-hvyWA68 \
  --broadcast

# Check deployment
cast call <VAULT_ADDRESS> "totalAssets()" \
  --rpc-url https://base-sepolia.g.alchemy.com/v2/e7qIcHOK60Sc4-hvyWA68
```

### ⚠️ Important Considerations:

1. **Base Sepolia ETH**
   - Ensure sufficient Base Sepolia ETH for deployment and testing
   - Base Sepolia Faucets:
     - https://faucet.quicknode.com/base/sepolia
     - https://www.alchemy.com/faucets/base-sepolia
     - Bridge from Sepolia: https://bridge.base.org/

2. **Mock Tokens**
   - Deploy mock BTC tokens with faucet functionality
   - Ensure proper decimals (WBTC: 8, TBTC/sovaBTC: 18)

3. **Time Manipulation**
   - Base Sepolia doesn't support time manipulation
   - May need to wait actual time for redemption testing
   - Consider shorter delay for testnet (1 day instead of 14)

4. **Base-Specific Considerations**
   - Lower gas costs compared to Ethereum mainnet
   - Faster block times (~2 seconds)
   - Alchemy RPC endpoint provided for reliability

4. **Monitoring**
   - Set up event monitoring
   - Track gas consumption
   - Monitor for failures

### Success Criteria:
- [ ] All contracts successfully deployed to Base Sepolia
- [ ] Contracts verified on Basescan
- [ ] Complete user journey tested (deposit → redemption)
- [ ] Admin operations functional
- [ ] Gas costs match estimates (±20%)
- [ ] No critical issues found
- [ ] Documentation updated with live addresses

### Next Steps After Session 7:
1. **Mainnet Preparation** - Prepare for mainnet deployment
2. **Security Audit** - Submit for external audit
3. **UI Development** - Build production frontend
4. **Liquidity Setup** - Prepare initial liquidity
5. **Launch Planning** - Marketing and go-to-market strategy

This session focuses on making the system live on testnet and ensuring everything works as expected in a real blockchain environment.