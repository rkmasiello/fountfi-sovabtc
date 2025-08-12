# Decimal Handling Documentation

## Overview

The Multi-Collateral BTC Vault system handles tokens with different decimal precisions. This document details how decimal conversions are managed throughout the system to ensure precision and prevent rounding errors.

## Token Decimal Configuration

| Token | Native Decimals | Usage | Notes |
|-------|-----------------|-------|-------|
| WBTC | 8 | Collateral | Bitcoin standard |
| tBTC | 18 | Collateral | Ethereum standard |
| sovaBTC | 18 | Collateral & Redemption | System native |
| mcBTC | 18 | Vault Shares | ERC-4626 standard |

## Normalization Strategy

### Core Principle
All internal calculations use 18-decimal precision. Conversions happen at system boundaries:
- **Input**: When tokens enter the system (deposits)
- **Output**: When tokens leave the system (redemptions)
- **Display**: When showing values to users

### Normalization Functions

```solidity
// MultiCollateralRegistry.sol
function normalizeAmount(address token, uint256 amount) 
    external view returns (uint256) {
    CollateralInfo memory info = collateralInfo[token];
    require(info.enabled, "Token not supported");
    
    if (info.decimals == 18) {
        return amount;
    } else if (info.decimals < 18) {
        return amount * 10**(18 - info.decimals);
    } else {
        return amount / 10**(info.decimals - 18);
    }
}

function denormalizeAmount(address token, uint256 amount) 
    external view returns (uint256) {
    CollateralInfo memory info = collateralInfo[token];
    require(info.enabled, "Token not supported");
    
    if (info.decimals == 18) {
        return amount;
    } else if (info.decimals < 18) {
        return amount / 10**(18 - info.decimals);
    } else {
        return amount * 10**(info.decimals - 18);
    }
}
```

## Critical Calculation Points

### 1. Deposit Flow

```solidity
// User deposits 1 WBTC (8 decimals)
userInput = 100000000 (1e8)

// Step 1: Normalize to 18 decimals
normalizedAmount = 100000000 * 10^10 = 1000000000000000000 (1e18)

// Step 2: Calculate shares (assuming 1:1 initial ratio)
shares = (normalizedAmount * totalSupply) / totalAssets
shares = (1e18 * totalSupply) / totalAssets

// Step 3: Mint shares (already in 18 decimals)
_mint(receiver, shares)
```

### 2. Redemption Flow

```solidity
// User redeems shares for sovaBTC
shares = 1000000000000000000 (1e18)

// Step 1: Calculate assets (18 decimals)
assets = (shares * totalAssets) / totalSupply

// Step 2: sovaBTC is already 18 decimals, no conversion needed
sovaBTCAmount = assets

// Step 3: Transfer sovaBTC
IERC20(sovaBTC).transfer(user, sovaBTCAmount)
```

### 3. Multi-Collateral Value Calculation

```solidity
// Calculate total value across different decimals
totalValue = 0

// WBTC: 0.5 BTC (8 decimals)
wbtcBalance = 50000000 (5e7)
wbtcNormalized = 50000000 * 10^10 = 500000000000000000 (5e17)
totalValue += wbtcNormalized

// tBTC: 0.3 BTC (18 decimals)  
tbtcBalance = 300000000000000000 (3e17)
totalValue += tbtcBalance

// sovaBTC: 0.2 BTC (18 decimals)
sovaBtcBalance = 200000000000000000 (2e17)
totalValue += sovaBtcBalance

// Total: 1 BTC in 18 decimals
totalValue = 1000000000000000000 (1e18)
```

## Rounding Behavior

### Rounding Rules
1. **Favor the Vault**: Round down on deposits, round up on withdrawals
2. **Minimum Amounts**: Enforce minimums after conversion
3. **Dust Prevention**: Reject amounts that would result in 0 shares

### Example Calculations

```solidity
// Deposit with potential rounding
// User deposits 0.00000001 WBTC (1 satoshi)
amount = 1 (in 8 decimals)
normalized = 1 * 10^10 = 10000000000 (1e10 in 18 decimals)

// This is less than minimum (0.001 BTC = 1e15 in 18 decimals)
require(normalized >= minInvestmentAmount, "Below minimum")
// Transaction reverts
```

## Edge Cases and Handling

### 1. Dust Amounts
**Issue**: Very small amounts could result in 0 shares due to rounding
**Solution**: Minimum investment amount of 0.001 BTC prevents dust

### 2. Precision Loss
**Issue**: Converting from higher to lower decimals loses precision
**Solution**: All internal math in 18 decimals, only convert at boundaries

### 3. Overflow Risk
**Issue**: Multiplying large numbers could overflow
**Solution**: Solidity 0.8.25 built-in overflow protection

### 4. Different Decimal Tokens
**Issue**: Future tokens might have unusual decimals (e.g., 6, 9)
**Solution**: Generic normalization function handles any decimal count

## Testing Matrix

### Decimal Conversion Tests

| Test Case | Input | Expected Output | Status |
|-----------|-------|-----------------|--------|
| WBTC normalization | 1e8 (1 BTC) | 1e18 | ✅ Tested |
| WBTC denormalization | 1e18 | 1e8 (1 BTC) | ✅ Tested |
| tBTC normalization | 1e18 (1 BTC) | 1e18 | ✅ Tested |
| Mixed collateral sum | Various | Correct total | ✅ Tested |
| Minimum amount check | 1e5 (0.001 WBTC) | 1e15 normalized | ✅ Tested |
| Dust rejection | 1 wei WBTC | Revert | ✅ Tested |

### Fuzz Testing Parameters

```solidity
// Fuzz test configuration
function testFuzz_decimalConversion(
    uint8 decimals,      // 0-18
    uint256 amount       // 0-type(uint256).max
) public {
    // Ensure decimals are reasonable
    decimals = bound(decimals, 0, 18);
    
    // Ensure amount won't overflow
    if (decimals < 18) {
        amount = bound(amount, 0, type(uint256).max / 10**(18-decimals));
    }
    
    // Test normalization and denormalization
    uint256 normalized = normalize(amount, decimals);
    uint256 denormalized = denormalize(normalized, decimals);
    
    // Allow for 1 wei rounding error
    assertApproxEqAbs(amount, denormalized, 1);
}
```

## Implementation Guidelines

### For Developers

1. **Always Normalize First**: Convert to 18 decimals before any calculation
2. **Store Normalized**: Keep internal state in 18 decimals
3. **Convert at Boundaries**: Only denormalize for external transfers
4. **Check Minimums**: Validate amounts after normalization
5. **Test Thoroughly**: Include all decimal combinations in tests

### For Auditors

1. **Check Conversion Points**: Verify all entry/exit points handle decimals
2. **Review Rounding**: Ensure rounding favors protocol security
3. **Test Edge Cases**: Focus on minimum amounts and dust
4. **Verify Overflow Protection**: Confirm Solidity version or SafeMath usage
5. **Cross-check Calculations**: Manually verify sample calculations

## Common Pitfalls

### 1. Forgetting to Normalize
```solidity
// WRONG
uint256 shares = (amount * totalSupply) / totalAssets;

// CORRECT
uint256 normalized = registry.normalizeAmount(token, amount);
uint256 shares = (normalized * totalSupply) / totalAssets;
```

### 2. Double Conversion
```solidity
// WRONG - Converting twice
uint256 normalized = registry.normalizeAmount(token, amount);
uint256 doubleNormalized = normalized * 10**(18 - decimals); // BUG!

// CORRECT - Convert once
uint256 normalized = registry.normalizeAmount(token, amount);
```

### 3. Incorrect Decimal Assumption
```solidity
// WRONG - Assuming all tokens are 18 decimals
uint256 value = balance; // Could be 8 decimals!

// CORRECT - Always normalize
uint256 value = registry.normalizeAmount(token, balance);
```

## Monitoring and Alerts

### Runtime Checks
1. Monitor for unexpected decimal values in events
2. Alert on failed normalizations
3. Track rounding losses over time
4. Verify share calculations match expected values

### Invariants to Monitor
```solidity
// After every deposit
assert(sharesIssued > 0 || amount < minimum);

// After every withdrawal  
assert(assetsRedeemed <= sharesRedeemed * pricePerShare);

// Periodic check
assert(sumOfAllShares == totalSupply);
```

## Future Considerations

### Supporting New Decimals
When adding new collateral types:
1. Test normalization with new decimal count
2. Verify no overflow in conversion math
3. Update minimum amounts if needed
4. Add to testing matrix
5. Document in collateral registry

### Precision Improvements
Potential future enhancements:
1. Use fixed-point math libraries for better precision
2. Implement decimal-aware rounding modes
3. Add precision loss tracking
4. Consider decimal migration strategies

## Conclusion

Decimal handling is critical for the vault's security and correctness. The normalization strategy ensures consistent calculations while preserving precision. All conversions happen at system boundaries, with internal calculations using 18-decimal precision throughout.