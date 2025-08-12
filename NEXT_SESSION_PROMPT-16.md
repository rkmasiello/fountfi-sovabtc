# Session 17: Refactor BTC Vault Contracts for Coverage Compatibility

## Context
The Multi-Collateral BTC Vault is fully functional with all 509 tests passing. However, `forge coverage` cannot run due to stack depth limitations when coverage instrumentation is added to our BTC vault contracts. We need to refactor these contracts to reduce local variable usage and improve code quality.

## Current Branch
Working on branch: `sovabtc-2`

## Problem Analysis
The following BTC vault contracts cause stack depth issues during coverage:
1. **MultiBTCVault.sol** - 21 functions with complex state management
2. **ManagedRedemptionQueue.sol** - 12 functions with queue operations  
3. **MultiCollateralStrategy.sol** - Multiple collateral handling
4. **MultiCollateralRegistry.sol** - Conversion calculations

**Note**: Original FountFi contracts (tRWA, GatedMintRWA, RulesEngine, etc.) do NOT need refactoring.

## Refactoring Strategy

### Phase 1: Analyze Stack Usage
- Identify functions with most local variables
- Find deeply nested operations
- Locate complex calculations that can be extracted

### Phase 2: Refactor MultiBTCVault.sol
Focus on the most complex functions:

#### 2.1 `depositCollateral()` function
**Current Issues**:
- Multiple local variables for validation
- Complex calculation flow
- Multiple external calls

**Refactoring Approach**:
```solidity
// Create a struct for deposit parameters
struct DepositParams {
    address token;
    uint256 amount;
    address receiver;
    uint256 shares;
}

// Extract validation into a separate function
function _validateDeposit(DepositParams memory params) private view

// Extract transfer logic
function _executeDepositTransfer(DepositParams memory params) private
```

#### 2.2 `totalAssets()` function
**Current Issues**:
- Complex NAV calculation with multiple variables
- Conditional logic with price oracle

**Refactoring Approach**:
```solidity
// Extract price calculation
function _calculateNAVPrice() private view returns (uint256)

// Simplify decimal conversion
function _convertToAssetDecimals(uint256 value) private pure returns (uint256)
```

#### 2.3 `withdraw()` and `redeem()` functions
**Current Issues**:
- Duplicate logic
- Multiple validation steps
- Complex allowance handling

**Refactoring Approach**:
```solidity
// Create shared withdraw logic
function _processWithdrawal(
    uint256 shares,
    uint256 assets,
    address receiver,
    address owner
) private
```

### Phase 3: Refactor ManagedRedemptionQueue.sol
Focus on queue management functions:

#### 3.1 `processRedemptions()` function
**Current Issues**:
- Loop with multiple local variables
- Complex state updates
- Multiple external calls

**Refactoring Approach**:
```solidity
// Extract single redemption processing
function _processSingleRedemption(uint256 requestId) private

// Use storage pointers instead of memory copies
RedemptionRequest storage request = redemptionRequests[requestId];
```

#### 3.2 `queueRedemption()` function
**Current Issues**:
- Multiple validation checks
- Complex request creation

**Refactoring Approach**:
```solidity
// Create request struct more efficiently
function _createRedemptionRequest(
    address owner,
    uint256 shares,
    address receiver
) private returns (uint256)
```

### Phase 4: Refactor MultiCollateralStrategy.sol

#### 4.1 `withdrawTo()` function
**Current Issues**:
- Multiple balance checks
- Complex collateral selection

**Refactoring Approach**:
```solidity
// Extract balance validation
function _validateWithdrawal(address token, uint256 amount) private view

// Simplify transfer execution
function _executeTransfer(address token, address to, uint256 amount) private
```

### Phase 5: Refactor MultiCollateralRegistry.sol

#### 5.1 `getValueInUnderlying()` function
**Current Issues**:
- Complex decimal conversion math
- Multiple intermediate calculations

**Refactoring Approach**:
```solidity
// Pre-calculate decimal adjustments
function _getDecimalAdjustment(address token) private view returns (uint256)

// Simplify conversion logic
function _applyConversionRate(uint256 amount, uint256 rate) private pure
```

## Implementation Guidelines

### Best Practices to Follow:
1. **Use Storage Pointers**: Replace memory copies with storage pointers where possible
2. **Extract Pure Functions**: Move calculations to pure functions that can be optimized
3. **Combine State Updates**: Group multiple state changes together
4. **Reduce Return Values**: Use structs for multiple return values
5. **Eliminate Intermediate Variables**: Direct assignments where readable

### Example Refactoring Pattern:
```solidity
// BEFORE: Too many local variables
function complexFunction() public {
    uint256 var1 = someCalculation();
    uint256 var2 = anotherCalculation();
    uint256 var3 = var1 + var2;
    address var4 = getAddress();
    bool var5 = checkCondition();
    // ... more logic
}

// AFTER: Extracted and simplified
function complexFunction() public {
    ComplexResult memory result = _performCalculations();
    _executeAction(result);
}

function _performCalculations() private view returns (ComplexResult memory) {
    return ComplexResult({
        total: someCalculation() + anotherCalculation(),
        target: getAddress(),
        isValid: checkCondition()
    });
}
```

## Testing Strategy

### After Each Refactoring:
1. Run `forge test` to ensure all tests still pass
2. Run `forge build` to verify compilation
3. Attempt `forge coverage` to check if stack issues are resolved
4. Compare gas usage before/after to ensure no regression

### Validation Checklist:
- [ ] All existing tests pass
- [ ] No change in external function signatures
- [ ] Gas costs remain similar or improve
- [ ] Code is more readable and maintainable
- [ ] forge coverage runs successfully

## Success Criteria
1. ✅ `forge coverage` runs without `--ir-minimum` flag
2. ✅ All 509 tests continue to pass
3. ✅ No regression in gas costs
4. ✅ Improved code readability and maintainability
5. ✅ Coverage report generated successfully

## Important Notes
- Work on branch `sovabtc-2`
- Do NOT modify any original FountFi contracts (tRWA, GatedMintRWA, etc.)
- Focus ONLY on BTC vault related contracts
- Prioritize code quality over minimal changes
- Document any significant architectural changes

## Commands to Run
```bash
# Switch to the refactoring branch
git checkout sovabtc-2

# Run tests after each change
forge test

# Check compilation
forge build

# Attempt coverage (goal is for this to work)
forge coverage

# Compare gas reports
forge test --gas-report
```

## Files to Modify
1. `src/vaults/MultiBTCVault.sol` (Priority 1)
2. `src/strategy/ManagedRedemptionQueue.sol` (Priority 2)
3. `src/strategy/MultiCollateralStrategy.sol` (Priority 3)
4. `src/registry/MultiCollateralRegistry.sol` (Priority 4)

## Files to NOT Modify
- Any contracts in `src/token/` (tRWA.sol, GatedMintRWA.sol, etc.)
- Any contracts in `src/hooks/` (RulesEngine.sol, KycRulesHook.sol, etc.)
- Any original FountFi contracts