# Next Session Prompt for Multi-Collateral BTC Vault

## Session 6: Testnet Deployment & Verification

You are continuing work on the FountFi Multi-Collateral BTC Vault system. Review ASSESSMENT_REPORT.md for the complete development history.

### ✅ Current Status:
- All core contracts implemented and tested
- Complete deployment infrastructure created
- 509 tests passing (100% success rate)
- Admin operation scripts ready
- System is production-ready

### 🎯 Session 6 Goals: Testnet Deployment & Documentation

**PRIMARY OBJECTIVE: Deploy to Sepolia testnet and create user documentation**

#### 1. Testnet Deployment
- Deploy all contracts to Sepolia testnet
- Verify contracts on Etherscan
- Test all admin operations
- Document deployed addresses

#### 2. Create Comprehensive Documentation

##### A. User Guide (`docs/USER_GUIDE.md`)
- How to deposit WBTC/TBTC
- Understanding mcBTC shares
- How the redemption queue works
- 14-day waiting period explanation
- Minimum investment requirements
- Step-by-step tutorials with examples

##### B. Admin Operations Manual (`docs/ADMIN_MANUAL.md`)
- NAV update procedures
- Processing redemption queues
- Liquidity management strategies
- Emergency procedures
- Monitoring and alerts setup
- Daily/weekly operational checklists

##### C. Integration Guide (`docs/INTEGRATION_GUIDE.md`)
- How to integrate with the vault
- API/Contract interfaces
- Event monitoring
- Example integrations
- Common patterns

##### D. Security Documentation (`docs/SECURITY.md`)
- Security model overview
- Access control matrix
- Emergency procedures
- Known risks and mitigations
- Audit recommendations

#### 3. Create Frontend Integration Examples

##### A. Basic Web3 Integration (`examples/web3-integration.js`)
- Connect wallet
- Deposit collateral
- Queue redemption
- Check balances
- Monitor queue status

##### B. Subgraph Schema (`examples/subgraph.yaml`)
- Define entities for indexing
- Track deposits and redemptions
- Monitor NAV updates
- User position tracking

#### 4. Gas Optimization Analysis
- Run `forge snapshot`
- Identify high-cost operations
- Document gas costs for users
- Suggest optimizations if needed

#### 5. Create Deployment Verification Script
- Script to verify all contracts are properly configured
- Check roles and permissions
- Verify collateral registrations
- Test deposit/redemption flow

### 📋 Deliverables for Session 6:

1. **Sepolia Deployment**
   - [ ] All contracts deployed
   - [ ] Contracts verified on Etherscan
   - [ ] Test transactions completed
   - [ ] Addresses documented

2. **Documentation Suite**
   - [ ] User Guide with tutorials
   - [ ] Admin Operations Manual
   - [ ] Integration Guide for developers
   - [ ] Security documentation

3. **Integration Examples**
   - [ ] Web3.js integration example
   - [ ] Subgraph schema
   - [ ] React component examples (optional)

4. **Verification & Testing**
   - [ ] Post-deployment verification script
   - [ ] Gas optimization report
   - [ ] Testnet integration tests passing

### 🔧 Technical Tasks:

```bash
# Deploy to Sepolia
forge script script/DeployAll.s.sol --rpc-url $SEPOLIA_RPC_URL --broadcast --verify

# Verify contracts
forge verify-contract <ADDRESS> <CONTRACT> --chain sepolia

# Test operations
forge script script/admin/UpdatePriceOracle.s.sol --rpc-url $SEPOLIA_RPC_URL --broadcast
```

### 📝 Documentation Structure:
```
docs/
├── USER_GUIDE.md           # End user documentation
├── ADMIN_MANUAL.md          # Admin operations guide
├── INTEGRATION_GUIDE.md     # Developer integration docs
├── SECURITY.md              # Security documentation
└── DEPLOYMENT_SEPOLIA.md    # Sepolia addresses and config

examples/
├── web3-integration.js      # JavaScript integration
├── subgraph.yaml           # Graph Protocol schema
└── react-components/       # Optional React examples
```

### ⚠️ Important Considerations:

1. **Sepolia Configuration**
   - Need mock BTC tokens on Sepolia
   - May need to deploy mock tokens first
   - Configure appropriate conversion rates

2. **Documentation Quality**
   - Clear, step-by-step instructions
   - Include code examples
   - Add diagrams where helpful
   - Consider non-technical users

3. **Testing on Sepolia**
   - Test full deposit → redemption cycle
   - Verify 14-day queue works correctly
   - Test emergency procedures
   - Monitor gas costs

### Success Criteria:
- [ ] Contracts successfully deployed to Sepolia
- [ ] All contracts verified on Etherscan
- [ ] Complete documentation suite created
- [ ] Integration examples working
- [ ] Admin successfully processed test redemption
- [ ] Gas costs documented and reasonable

This session focuses on making the system accessible and ready for real-world use through deployment, documentation, and examples.