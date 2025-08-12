# Session 19: Cleanup and Integration

## Context
In Session 18, we successfully refactored the multi-collateral BTC vault to follow the ManagedWithdrawRWAStrategy pattern. We now have a clean 2-contract architecture:
- **BtcVaultStrategy.sol** - Extends ReportedStrategy
- **BtcVaultToken.sol** - Extends ManagedWithdrawRWA

The implementation is complete and all tests pass. Now we need to clean up the old contracts from previous implementation attempts and prepare for integration.

## Branch
Continue on branch: `sovabtc-2`

## Phase 1: Cleanup Deprecated Contracts

### Task 1: Create Deprecated Folder Structure
```bash
mkdir -p src/deprecated/vaults
mkdir -p src/deprecated/strategy
mkdir -p src/deprecated/registry
mkdir -p src/deprecated/token
mkdir -p src/deprecated/interfaces
mkdir -p test/deprecated
```

### Task 2: Move Old Contracts
Move the following contracts to `/src/deprecated/`:

**From `/src/vaults/`:**
- `MultiBTCVault.sol` → `/src/deprecated/vaults/`
- All related vault contracts

**From `/src/strategy/`:**
- `MultiCollateralStrategy.sol` → `/src/deprecated/strategy/`
- `ManagedRedemptionQueue.sol` → `/src/deprecated/strategy/`

**From `/src/registry/`:**
- `MultiCollateralRegistry.sol` → `/src/deprecated/registry/`

**From `/src/token/`:**
- `BtcVaultShareToken.sol` → `/src/deprecated/token/` (the old one extending tRWA directly)

**From `/src/interfaces/`:**
- `IMultiBTCVault.sol` → `/src/deprecated/interfaces/`
- `IMultiCollateralRegistry.sol` → `/src/deprecated/interfaces/`
- `IMultiCollateralStrategy.sol` → `/src/deprecated/interfaces/`
- `IManagedRedemptionQueue.sol` → `/src/deprecated/interfaces/`

### Task 3: Move Old Tests
Move tests that reference deprecated contracts:
- `test/vaults/MultiBTCVault.t.sol` → `/test/deprecated/`
- `test/strategy/ManagedRedemptionQueue.t.sol` → `/test/deprecated/`
- `test/BtcVaultTest.t.sol` → `/test/deprecated/` (old version)
- Any other tests referencing the old contracts

### Task 4: Clean Up Deployment Scripts
Review and update deployment scripts:
- Keep `script/deploy/DeployBtcVault.s.sol` (update if needed)
- Move old deployment scripts referencing deprecated contracts to `/script/deprecated/`

## Phase 2: Update Active Codebase

### Task 5: Update Import Paths
Ensure no active contracts import from deprecated contracts:
```bash
# Check for any remaining imports of old contracts
grep -r "MultiBTCVault\|MultiCollateral\|ManagedRedemptionQueue" src/ --exclude-dir=deprecated
grep -r "MultiBTCVault\|MultiCollateral\|ManagedRedemptionQueue" test/ --exclude-dir=deprecated
grep -r "MultiBTCVault\|MultiCollateral\|ManagedRedemptionQueue" script/ --exclude-dir=deprecated
```

### Task 6: Verify Build
After moving deprecated contracts:
```bash
forge clean
forge build
forge test
```

## Phase 3: Integration Preparation

### Task 7: Update Documentation
1. Update README.md to reflect new architecture
2. Create architecture diagram showing:
   - BtcVaultStrategy → BtcVaultToken relationship
   - Multi-collateral deposit flow
   - Managed redemption flow

### Task 8: Frontend Integration Points
Document the key integration points for frontend:

**Deposit Flow:**
```solidity
// User approves collateral token
IERC20(wbtc).approve(vaultToken, amount);
// User deposits collateral for shares
BtcVaultToken(vaultToken).depositCollateral(wbtc, amount, receiver);
```

**Redemption Flow (Manager-Initiated):**
```solidity
// User approves strategy to spend shares
BtcVaultToken(vaultToken).approve(strategy, shares);
// Manager processes redemption
ManagedWithdrawRWA(vaultToken).redeem(shares, to, owner, minAssets);
```

### Task 9: Create Integration Test
Create a comprehensive integration test that simulates real-world usage:
- Multiple users depositing different collateral types
- Manager processing batch redemptions
- Liquidity management scenarios
- Edge cases and error conditions

## Phase 4: Deployment Preparation

### Task 10: Update Deployment Script
Update `script/deploy/DeployBtcVault.s.sol` to:
1. Deploy BtcVaultStrategy with proper initialization
2. Verify the strategy auto-deploys BtcVaultToken
3. Configure initial collateral types (WBTC, tBTC, etc.)
4. Set up initial liquidity if needed

### Task 11: Create Verification Script
Create script to verify deployment:
```solidity
// script/verify/VerifyBtcVault.s.sol
- Check strategy deployment
- Verify token deployment
- Confirm collateral support
- Test deposit/redemption flow
```

## Expected Outcomes

By end of session:
1. ✅ All deprecated contracts moved to `/deprecated` folders
2. ✅ Clean codebase with only active contracts
3. ✅ All tests passing with new structure
4. ✅ Documentation updated
5. ✅ Integration points documented
6. ✅ Deployment scripts ready

## File Structure Goal

```
src/
├── strategy/
│   ├── BtcVaultStrategy.sol         # ACTIVE
│   └── [other active strategies]
├── token/
│   ├── BtcVaultToken.sol           # ACTIVE
│   └── [other active tokens]
├── interfaces/
│   ├── IBtcVaultStrategy.sol       # ACTIVE
│   ├── IBtcVaultShareToken.sol     # ACTIVE (if needed)
│   └── [other active interfaces]
└── deprecated/                      # NEW - All old implementations
    ├── vaults/
    ├── strategy/
    ├── registry/
    ├── token/
    └── interfaces/

test/
├── BtcVaultRefactorTest.t.sol      # ACTIVE - New tests
├── [other active tests]
└── deprecated/                      # NEW - Old tests
    └── [old test files]

script/
├── deploy/
│   ├── DeployBtcVault.s.sol        # ACTIVE - Updated
│   └── [other active scripts]
└── deprecated/                      # NEW - Old scripts
    └── [old deployment scripts]
```

## Important Notes

1. **Don't Delete Yet**: Move to `/deprecated` rather than deleting, in case we need to reference old implementations
2. **Git History**: After moving, commit with clear message about the cleanup
3. **Dependencies**: Check that no active contracts depend on deprecated ones before moving
4. **Test Coverage**: Ensure new tests cover all functionality from old tests
5. **Documentation**: Update all docs to reflect the new simplified architecture

## Commands to Run

```bash
# After cleanup
forge clean
forge build
forge test
forge coverage

# Verify no references to old contracts
grep -r "MultiBTCVault\|MultiCollateral\|ManagedRedemptionQueue" src/ test/ script/ --exclude-dir=deprecated

# Run specific new tests
forge test --match-contract BtcVaultRefactorTest -vv
```

This cleanup will give us a clean, maintainable codebase ready for audit and production deployment.