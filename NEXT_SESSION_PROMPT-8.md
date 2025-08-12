# Next Session Prompt for Multi-Collateral BTC Vault

## Session 8: Complete Testnet Testing & Integration

You are continuing work on the FountFi Multi-Collateral BTC Vault system. Review ASSESSMENT_REPORT.md for the complete development history.

### ✅ Current Status:
- All contracts deployed to Base Sepolia testnet
- Mock tokens deployed with mint functions
- Deposits working successfully (mcBTC shares issued)
- System fully configured and connected
- Documentation complete
- Redemptions need sovaBTC liquidity to work

### 🎯 Session 8 Goals: Complete Testing & Verification

**PRIMARY OBJECTIVE: Add liquidity, verify contracts, complete full testing cycle, and update integrations**

### 🔗 Deployment Information:
- **Network**: Base Sepolia (Chain ID: 84532)
- **Vault**: `0x73E27097221d4d9D5893a83350dC7A967b46fab7`
- **Strategy**: `0x740907524EbD6A481a81cE76B5115A4cDDb80099`
- **Queue**: `0x22BC73098CE1Ba2CaE5431fb32051cB4fc0F9C52`
- **sovaBTC**: `0x05aB19d77516414f7333a8fd52cC1F49FF8eAFA9`

### 📋 Task List:

#### 1. Add sovaBTC Liquidity to Strategy
**Priority: HIGH** - Required for redemptions to work

```solidity
// Create script: script/admin/AddLiquidity.s.sol
// 1. Mint sovaBTC to admin
// 2. Transfer sovaBTC to strategy
// 3. Verify strategy balance
```

Expected outcome:
- Strategy has sufficient sovaBTC for redemptions
- Test redemption flow works end-to-end

#### 2. Verify Contracts on Basescan
**Priority: HIGH** - Important for transparency

```bash
# Verify each contract
forge verify-contract 0x73E27097221d4d9D5893a83350dC7A967b46fab7 MultiBTCVault \
  --chain-id 84532 \
  --verifier-url https://api-sepolia.basescan.org/api \
  --etherscan-api-key KI5PMY8D813UGVZS7MEFMW7BW4AU8A14DV \
  --constructor-args $(cast abi-encode "constructor(string,string,address,address,address,address)" "Multi-Collateral BTC Vault" "mcBTC" 0x05aB19d77516414f7333a8fd52cC1F49FF8eAFA9 0x15a9983784617aa8892b2677bbaEc23539482B65 0x15502fC5e872c8B22BA6dD5e01A7A5bd4f9A3d72 0x0000000000000000000000000000000000000000)
```

Tasks:
- [ ] Verify RoleManager
- [ ] Verify Registry
- [ ] Verify Strategy
- [ ] Verify Vault
- [ ] Verify Queue
- [ ] Verify PriceOracle

#### 3. Complete Full Testing Cycle

##### A. Test Complete Redemption Flow
```solidity
// script/test/TestFullCycle.s.sol
// 1. Deposit collateral
// 2. Request redemption
// 3. Wait for redemption period (or use time manipulation)
// 4. Process redemptions (admin)
// 5. Claim redeemed sovaBTC
```

##### B. Test Admin Operations
```solidity
// script/test/TestAdminOps.s.sol
// 1. Update NAV price
// 2. Process redemption queue
// 3. Emergency pause/unpause
// 4. Add/remove collateral types
```

##### C. Test Multi-User Scenarios
```solidity
// script/test/TestMultiUser.s.sol
// 1. Multiple users deposit different collaterals
// 2. Multiple redemption requests
// 3. Partial queue processing
// 4. Edge cases (minimum amounts, maximum amounts)
```

#### 4. Update Integration Examples

##### A. Update Web3 Integration with Live Addresses
```javascript
// examples/web3-integration-live.js
const CONTRACTS = {
  vault: "0x73E27097221d4d9D5893a83350dC7A967b46fab7",
  queue: "0x22BC73098CE1Ba2CaE5431fb32051cB4fc0F9C52",
  wbtc: "0xe44b2870eFcd6Bb3C9305808012621f438e9636D",
  // ... etc
};
```

##### B. Create Working Demo Script
```javascript
// examples/demo.js
// 1. Connect to Base Sepolia
// 2. Show current vault stats
// 3. Demonstrate deposit flow
// 4. Show redemption queue status
```

#### 5. Performance and Gas Analysis

##### A. Measure Gas Costs on Live Network
- [ ] Deposit gas cost (actual)
- [ ] Redemption request gas cost
- [ ] Queue processing gas cost
- [ ] NAV update gas cost

##### B. Create Performance Report
```markdown
# Base Sepolia Performance Report
- Network latency
- Transaction confirmation times
- Gas costs at current prices
- Throughput limitations
```

#### 6. Create Monitoring Dashboard Script

```javascript
// script/monitor/VaultStatus.s.sol
// Display:
// - Total assets locked
// - Number of unique depositors
// - Pending redemptions
// - Current NAV
// - Collateral balances
```

#### 7. Bug Fixes and Improvements

Based on testing, address any issues found:
- [ ] Fix any failing transactions
- [ ] Optimize gas usage where possible
- [ ] Improve error messages
- [ ] Add missing events

#### 8. Documentation Updates

##### A. Update README with Testnet Info
```markdown
## Live on Base Sepolia!
- Vault: 0x73E27097221d4d9D5893a83350dC7A967b46fab7
- Explorer: https://sepolia.basescan.org/address/0x73E27097221d4d9D5893a83350dC7A967b46fab7
```

##### B. Create Testing Guide
```markdown
# docs/TESTNET_GUIDE.md
- How to get test tokens
- How to interact with contracts
- Common issues and solutions
```

### 📊 Deliverables for Session 8:

1. **Liquidity & Redemptions**
   - [ ] sovaBTC liquidity added to strategy
   - [ ] Full redemption cycle tested successfully
   - [ ] Queue processing verified

2. **Contract Verification**
   - [ ] All contracts verified on Basescan
   - [ ] Source code readable on explorer
   - [ ] Constructor args confirmed

3. **Testing Complete**
   - [ ] Multi-user scenarios tested
   - [ ] Admin operations verified
   - [ ] Edge cases handled

4. **Integration Updates**
   - [ ] Web3 examples use live addresses
   - [ ] Demo script working
   - [ ] Monitoring tools created

5. **Documentation**
   - [ ] Performance report created
   - [ ] Testing guide written
   - [ ] README updated

### 🔧 Useful Commands:

```bash
# Check strategy sovaBTC balance
cast call 0x05aB19d77516414f7333a8fd52cC1F49FF8eAFA9 "balanceOf(address)" 0x740907524EbD6A481a81cE76B5115A4cDDb80099 --rpc-url https://base-sepolia.g.alchemy.com/v2/e7qIcHOK60Sc4-hvyWA68

# Check vault total assets
cast call 0x73E27097221d4d9D5893a83350dC7A967b46fab7 "totalAssets()" --rpc-url https://base-sepolia.g.alchemy.com/v2/e7qIcHOK60Sc4-hvyWA68

# Process redemptions (admin only)
cast send 0x22BC73098CE1Ba2CaE5431fb32051cB4fc0F9C52 "processRedemptions(uint256)" 10 --private-key $ADMIN_KEY --rpc-url https://base-sepolia.g.alchemy.com/v2/e7qIcHOK60Sc4-hvyWA68
```

### ⚠️ Important Notes:

1. **Private Keys**: 
   - User/Admin: `0x95a18be97b616ea6a2c79e1a82090f66686f15548b6cbb621a6a6417677759d4`
   - Etherscan API: `KI5PMY8D813UGVZS7MEFMW7BW4AU8A14DV`

2. **Testing Considerations**:
   - Base Sepolia has 2-second block times
   - Redemption period is set to 1 day for testing
   - Mock tokens have unlimited minting

3. **Focus Areas**:
   - Ensure redemptions work properly
   - Verify all user flows
   - Document any issues found

### Success Criteria:
- [ ] Users can deposit, request redemption, and receive sovaBTC
- [ ] All contracts verified on Basescan
- [ ] Integration examples working with live contracts
- [ ] No critical bugs found
- [ ] Performance metrics documented
- [ ] System ready for broader testing

### Next Steps After Session 8:
1. **Frontend Development** - Create basic UI for testing
2. **Subgraph Deployment** - Deploy indexing to The Graph
3. **Community Testing** - Open for public testnet testing
4. **Audit Preparation** - Prepare for security audit
5. **Mainnet Planning** - Plan production deployment

This session focuses on completing the testnet deployment with full functionality and preparing for the next phases of development.