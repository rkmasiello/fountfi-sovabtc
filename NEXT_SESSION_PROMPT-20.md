# Session 20: Frontend Integration and Testnet Deployment

## Context
In Sessions 18-19, we successfully:
- Refactored the BTC vault to a clean 2-contract architecture
- Removed all deprecated contracts, tests, and scripts
- Created integration documentation
- Achieved 100% test pass rate (425 tests)

The codebase is now clean and ready for the next phase: frontend integration and testnet deployment.

## Branch
Continue on branch: `sovabtc-2`

## Phase 1: Frontend SDK Update

### Task 1: Update VaultSDK.ts
The SDK at `sdk/VaultSDK.ts` still references the old `MultiBTCVaultSDK` class name and old contract interfaces. Update it to:
1. Rename class to `BtcVaultSDK`
2. Update to use new contract interfaces:
   - `BtcVaultStrategy` 
   - `BtcVaultToken`
3. Update method names to match new architecture:
   - `depositCollateral()` for multi-collateral deposits
   - Remove references to redemption queue
   - Update to managed withdrawal pattern

### Task 2: Update Frontend ABIs
Update `frontend/lib/abis.ts` to:
1. Remove old contract ABIs (MultiBTCVault, etc.)
2. Add new contract ABIs:
   - BtcVaultStrategy ABI
   - BtcVaultToken ABI
3. Update interface names

### Task 3: Update Frontend Components
Review and update frontend components that may reference old contracts:
- `frontend/components/VaultStats.tsx`
- `frontend/components/RedemptionQueue.tsx` (may need refactoring for managed withdrawals)
- `frontend/components/AdminPanel.tsx`
- `frontend/components/OnboardingWizard.tsx`

## Phase 2: Testnet Deployment Preparation

### Task 4: Create Deployment Configuration
Create `deployment.config.json` with:
```json
{
  "baseSepolia": {
    "roleManager": "0x...",
    "sovaBTC": "0x...",
    "wBTC": "0x...",
    "tBTC": "0x...",
    "initialLiquidity": "1000000000"
  }
}
```

### Task 5: Update Deployment Script
Enhance `script/deploy/DeployBtcVault.s.sol` to:
1. Read from deployment config file
2. Add verification step
3. Add post-deployment checks
4. Output deployment addresses to JSON

### Task 6: Create Verification Script
Create `script/verify/VerifyBtcVault.s.sol` to:
1. Verify contract deployment
2. Check role assignments
3. Validate collateral configuration
4. Test basic deposit/withdrawal flow

## Phase 3: Documentation and Testing

### Task 7: Update README
Update main README.md to:
1. Remove references to old architecture
2. Add new architecture overview
3. Update deployment instructions
4. Add integration examples

### Task 8: Create Migration Guide
Create `docs/MIGRATION_GUIDE.md` for users/developers migrating from old system:
1. Contract address changes
2. Method name changes
3. New flow for deposits/withdrawals
4. Breaking changes

### Task 9: Integration Tests
Create end-to-end integration test:
1. Deploy contracts
2. Configure collateral
3. Multiple user deposits
4. Manager-initiated redemptions
5. Verify balances and state

## Phase 4: CI/CD Updates

### Task 10: Update GitHub Actions
Update `.github/workflows/` files:
1. Remove references to deprecated contracts in `verify-contracts.yml`
2. Update test commands
3. Add deployment workflow for testnet

### Task 11: Update Scripts
Update shell scripts:
1. `scripts/verify-contracts.sh` - Remove deprecated contract verification
2. Create `scripts/deploy-testnet.sh` for automated deployment

## Phase 5: Gas Optimization Analysis

### Task 12: Gas Profiling
Run gas profiling on new architecture:
```bash
forge test --gas-report
forge snapshot
```

Compare with baseline and identify optimization opportunities.

### Task 13: Optimization Implementation
If needed, implement gas optimizations:
1. Storage packing
2. Function modifier optimization
3. Loop optimization
4. Event optimization

## Expected Outcomes

By end of session:
1. ✅ Frontend SDK updated for new architecture
2. ✅ Frontend components compatible with new contracts
3. ✅ Testnet deployment ready
4. ✅ Documentation fully updated
5. ✅ CI/CD pipelines updated
6. ✅ Gas usage analyzed and optimized

## Commands to Run

```bash
# Test frontend SDK
npm test --prefix sdk

# Deploy to testnet
forge script script/deploy/DeployBtcVault.s.sol \
  --rpc-url base-sepolia \
  --broadcast \
  --verify

# Run gas analysis
forge test --gas-report > gas-report.txt
forge snapshot

# Verify deployment
forge script script/verify/VerifyBtcVault.s.sol \
  --rpc-url base-sepolia
```

## Important Notes

1. **Backwards Compatibility**: Document all breaking changes
2. **Security**: Ensure all role checks are properly configured
3. **Testing**: Test thoroughly on testnet before mainnet
4. **Documentation**: Keep integration guide updated with any new findings
5. **Version Control**: Tag release after successful testnet deployment

## Files to Focus On

Priority files for updates:
- `sdk/VaultSDK.ts`
- `frontend/lib/abis.ts`
- `frontend/components/VaultStats.tsx`
- `.github/workflows/verify-contracts.yml`
- `README.md`

## Success Criteria

- [ ] SDK works with new contracts
- [ ] Frontend can deposit and request redemptions
- [ ] Successful testnet deployment
- [ ] All tests pass (frontend and contracts)
- [ ] Documentation is complete and accurate
- [ ] Gas usage is reasonable (<500k for deposits)

This session will bridge the gap between the completed smart contract refactor and a fully functional, deployable system ready for production use.