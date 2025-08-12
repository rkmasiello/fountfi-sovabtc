# Session 18: Refactor to Specification-Compliant Architecture

## Context
The multi-collateral BTC vault implementation has become overly complex and deviates from both the original FountFi patterns and the specification PDF. We need to refactor to a simpler, specification-compliant architecture that:
1. Uses existing FountFi patterns in `/strategy` and `/token`
2. Eliminates the `/vaults` directory
3. Reduces contract count from 4 to 2
4. Resolves forge coverage stack depth issues

## Branch
Continue on branch: `sovabtc-2`

## Specification Reference
Per "FountFi Multi-Collateral BTC Vault Specification.pdf" pages 3-4:
- **BtcVaultStrategy**: Extends ReportedStrategy, holds collateral
- **VaultShareToken**: Extends tRWA (ERC4626), handles deposits/withdrawals
- **ConversionLib**: Simple registry for supported assets (can be inline)

## Phase 1: Create New Architecture (Priority 1)

### Task 1: Create BtcVaultShareToken
Create `/src/token/BtcVaultShareToken.sol` that:
1. Extends `tRWA.sol` (which already has ERC4626)
2. Implements multi-collateral deposit functionality
3. Routes to strategy for asset management
4. Handles share minting/burning

**Key Implementation Points:**
```solidity
contract BtcVaultShareToken is tRWA {
    // Constructor similar to tRWA but for BTC assets
    // Override deposit to handle multiple collateral types
    // Override withdraw/redeem to return sovaBTC only
    // Reference the strategy for actual asset management
}
```

### Task 2: Create BtcVaultStrategy
Create `/src/strategy/BtcVaultStrategy.sol` that:
1. Extends `ReportedStrategy.sol`
2. Holds all BTC collateral tokens
3. Manages sovaBTC liquidity for redemptions
4. Includes inline asset registry (no separate contract)

**Key Implementation Points:**
```solidity
contract BtcVaultStrategy is ReportedStrategy {
    // Inline supported assets mapping
    mapping(address => bool) public supportedAssets;
    mapping(address => uint8) public assetDecimals;
    
    // Hold collateral and manage liquidity
    // Simple withdrawal to provide sovaBTC
    // Admin functions for asset management
}
```

## Phase 2: Migrate Functionality (Priority 2)

### Task 3: Port Core Logic
1. **Deposit Flow**: 
   - Move from `MultiBTCVault.depositCollateral()` to `BtcVaultShareToken.deposit()`
   - Simplify validation - remove helper functions
   - Direct transfer to strategy

2. **Redemption Flow**:
   - Remove queue complexity
   - Simple liquidity check in strategy
   - Direct sovaBTC transfer if available

3. **Asset Registry**:
   - Move from separate `MultiCollateralRegistry` to inline mappings
   - Simple 1:1 conversion (all BTC variants = 1 sovaBTC)
   - Admin can add/remove supported assets

### Task 4: Remove Unnecessary Contracts
Delete or deprecate:
- `/src/vaults/MultiBTCVault.sol`
- `/src/strategy/ManagedRedemptionQueue.sol`
- `/src/strategy/MultiCollateralStrategy.sol` 
- `/src/registry/MultiCollateralRegistry.sol`

## Phase 3: Simplify Implementation (Priority 3)

### Task 5: Code Optimization
1. **Remove Overengineering**:
   - No structs unless absolutely necessary
   - No helper functions for simple operations
   - Direct state access instead of getters

2. **Flatten Logic**:
   ```solidity
   // BEFORE (current)
   function depositCollateral(...) {
       DepositParams memory params = ...
       _validateDeposit(params);
       _executeDepositTransfer(params);
   }
   
   // AFTER (simplified)
   function deposit(...) {
       require(supportedAssets[token], "Unsupported");
       require(amount >= MIN_DEPOSIT, "Too small");
       token.safeTransferFrom(msg.sender, strategy, amount);
       _mint(receiver, shares);
   }
   ```

3. **Reduce Stack Usage**:
   - Inline simple calculations
   - Use storage pointers
   - Avoid local variable declarations

## Phase 4: Update Tests (Priority 4)

### Task 6: Adapt Test Suite
1. Update test imports to new contracts
2. Adjust test logic for simplified architecture
3. Ensure all 509 tests still pass
4. Add new tests for refactored functionality

### Task 7: Verify Coverage
1. Run `forge test` - all should pass
2. Run `forge coverage` - should work without `--ir-minimum`
3. Document any remaining issues

## Implementation Guidelines

### DO:
- ✅ Extend existing FountFi contracts (tRWA, ReportedStrategy)
- ✅ Use proven patterns from original codebase
- ✅ Keep logic simple and direct
- ✅ Follow specification naming (BtcVaultStrategy, VaultShareToken)
- ✅ Reuse existing utilities (Conduit, PriceOracleReporter)

### DON'T:
- ❌ Create new architectural patterns
- ❌ Add unnecessary abstraction layers
- ❌ Over-optimize prematurely
- ❌ Deviate from specification
- ❌ Add features not in spec

## File Structure Goal
```
src/
├── strategy/
│   ├── BtcVaultStrategy.sol         # NEW: Main strategy
│   ├── ReportedStrategy.sol         # EXISTING: Base class
│   └── [other existing strategies]
├── token/
│   ├── BtcVaultShareToken.sol       # NEW: Share token
│   ├── tRWA.sol                     # EXISTING: Base class
│   └── [other existing tokens]
└── interfaces/
    ├── IBtcVaultStrategy.sol         # NEW: Simple interface
    └── IBtcVaultShareToken.sol       # NEW: Simple interface
```

## Success Criteria
1. ✅ Only 2 new contracts (strategy + token)
2. ✅ Extends existing FountFi base contracts
3. ✅ `forge coverage` works without special flags
4. ✅ All tests pass
5. ✅ Matches specification exactly
6. ✅ No `/vaults` directory
7. ✅ Simpler than current implementation

## Commands to Run
```bash
# After creating new contracts
forge build

# Test compilation
forge test --match-contract BtcVaultShareToken
forge test --match-contract BtcVaultStrategy

# Once working, test all
forge test

# Finally, verify coverage works
forge coverage
```

## Important Notes

1. **Start Fresh**: Create new contracts rather than trying to modify existing BTC vault contracts
2. **Follow Patterns**: Look at how tRWA and ReportedStrategy work, follow same patterns
3. **Keep Simple**: If something seems complex, it probably is - simplify it
4. **Test Early**: Write basic tests as you go to ensure functionality
5. **Document Changes**: Keep notes on what was moved/changed for reference

## Expected Outcome

By end of session:
- Two new contracts that fully implement the multi-collateral BTC vault
- Passing test suite (adapted from existing tests)
- Working forge coverage without stack issues
- Cleaner, simpler, specification-compliant architecture
- Ready for audit and production deployment

Remember: The goal is SIMPLIFICATION. The current implementation works but is too complex. We're not adding features, we're removing complexity while maintaining functionality.