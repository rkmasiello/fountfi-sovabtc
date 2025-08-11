# Multi-Collateral BTC Vault - Contract Interfaces Specification

## Overview
This document provides detailed specifications for creating the contract interfaces needed for the Multi-Collateral BTC Vault. These interfaces should be implemented in Solidity 0.8.25 and follow the existing FountFi patterns.

## Required Interfaces

### 1. IMultiCollateralRegistry.sol
**Location**: `src/registry/IMultiCollateralRegistry.sol`

**Purpose**: Interface for managing supported BTC collateral tokens and their conversion rates to sovaBTC.

**Required Functions**:
```solidity
// Add a new supported collateral token
function addCollateral(address token, uint256 conversionRate, uint8 decimals) external;

// Remove a collateral token from supported list
function removeCollateral(address token) external;

// Update the conversion rate for an existing collateral
function updateConversionRate(address token, uint256 newRate) external;

// Check if a token is supported
function isSupportedAsset(address token) external view returns (bool);

// Get collateral information
function getCollateralInfo(address token) external view returns (
    uint256 conversionRate,  // 1e18 scaled rate (1e18 = 1:1 with sovaBTC)
    uint8 decimals,          // Token decimals (should be 8 for BTC tokens)
    bool isActive            // Whether token is currently accepted
);

// Convert token amount to sovaBTC base units
function getValueInUnderlying(address token, uint256 amount) external view returns (uint256);

// Get all supported collateral addresses
function getSupportedCollaterals() external view returns (address[] memory);
```

**Events**:
```solidity
event CollateralAdded(address indexed token, uint256 conversionRate, uint8 decimals);
event CollateralRemoved(address indexed token);
event ConversionRateUpdated(address indexed token, uint256 oldRate, uint256 newRate);
```

**Access Control**: Should integrate with RoleManager - only PROTOCOL_ADMIN can add/remove/update collaterals.

### 2. IMultiBTCVault.sol
**Location**: `src/vaults/IMultiBTCVault.sol`

**Purpose**: Main vault interface extending ERC-4626 with multi-collateral support.

**Inheritance**: Should extend `IERC4626` from forge-std or OpenZeppelin

**Additional Required Functions** (beyond standard ERC-4626):
```solidity
// Multi-asset deposit function
function depositCollateral(
    address token,      // BTC collateral token address
    uint256 amount,     // Amount in token's native decimals
    address receiver    // Who receives the shares
) external returns (uint256 shares);

// Preview functions for multi-asset
function previewDepositCollateral(address token, uint256 amount) external view returns (uint256 shares);

// Get the registry address
function registry() external view returns (address);

// Get the strategy address  
function strategy() external view returns (address);

// Get the price oracle reporter
function priceOracle() external view returns (address);

// Get the conduit address (if used)
function conduit() external view returns (address);

// Admin function to set new strategy
function setStrategy(address newStrategy) external;

// Admin function to set new price oracle
function setPriceOracle(address newOracle) external;

// Emergency pause functionality
function pause() external;
function unpause() external;
function paused() external view returns (bool);
```

**Key Implementation Notes**:
- `asset()` should return sovaBTC address
- `decimals()` should return 18 (share token decimals)
- All redemptions return sovaBTC only (no multi-asset withdrawals)
- Should integrate with Conduit for token transfers

### 3. IMultiCollateralStrategy.sol
**Location**: `src/strategy/IMultiCollateralStrategy.sol`

**Purpose**: Strategy interface for holding and managing multiple BTC collateral types.

**Inheritance**: Should extend or be compatible with `IStrategy` from existing FountFi

**Required Functions**:
```solidity
// Withdraw specific amount of sovaBTC to a recipient
function withdrawTo(address asset, address to, uint256 amount) external returns (bool);

// Get balance of a specific collateral token
function collateralBalance(address token) external view returns (uint256);

// Get total value in sovaBTC terms
function totalAssets() external view returns (uint256);

// Admin function to rebalance collaterals (swap between BTC types)
function rebalanceCollateral(
    address fromToken,
    address toToken,
    uint256 amount
) external;

// Admin function to add liquidity (deposit sovaBTC for redemptions)
function addLiquidity(uint256 amount) external;

// Admin function to remove excess collateral
function removeCollateral(address token, uint256 amount, address to) external;

// Set the associated vault address
function setVault(address vault) external;

// Get the associated vault address
function vault() external view returns (address);

// Emergency withdrawal for admin
function emergencyWithdraw(address token, uint256 amount, address to) external;

// Get list of all held collateral tokens
function getHeldCollaterals() external view returns (address[] memory);
```

**Access Control**: 
- `withdrawTo` - only callable by associated vault
- Admin functions - only callable by PROTOCOL_ADMIN
- Should integrate with RoleManager

### 4. IManagedRedemptionQueue.sol (Optional)
**Location**: `src/strategy/IManagedRedemptionQueue.sol`

**Purpose**: Interface for managed withdrawal queue system (if using queued redemptions instead of direct).

**Required Functions**:
```solidity
// Queue a redemption request
function queueRedemption(
    address owner,
    uint256 shares,
    address receiver
) external returns (uint256 requestId);

// Process queued redemptions (admin function)
function processRedemptions(uint256[] calldata requestIds) external;

// Cancel a redemption request
function cancelRedemption(uint256 requestId) external;

// Get redemption request details
function getRedemptionRequest(uint256 requestId) external view returns (
    address owner,
    address receiver,
    uint256 shares,
    uint256 sovaBTCAmount,
    uint256 timestamp,
    bool processed,
    bool cancelled
);

// Get pending redemption requests for an address
function getPendingRedemptions(address owner) external view returns (uint256[] memory);
```

## Integration Points

### With Existing FountFi Interfaces

1. **IReporter** (already exists)
   - No modifications needed
   - Use as-is for price reporting

2. **IConduit** (needs minor updates)
   - Add validation for multiple collateral types
   - Ensure it checks against registry for allowed tokens

3. **IRoleManager** (already exists)
   - Use as-is, but simplified role set:
   - Only need PROTOCOL_ADMIN (not STRATEGY_ADMIN, RULES_ADMIN, etc.)

4. **IRegistry** (optional use)
   - Can use for factory deployment if multiple vaults planned
   - Otherwise, direct deployment is fine

## Implementation Guidelines for Claude Code

### File Structure
```
src/
├── interfaces/
│   ├── IMultiCollateralRegistry.sol
│   ├── IMultiBTCVault.sol
│   ├── IMultiCollateralStrategy.sol
│   └── IManagedRedemptionQueue.sol (optional)
```

### Development Order
1. Start with `IMultiCollateralRegistry` (simplest, most independent)
2. Then `IMultiCollateralStrategy` (builds on registry)
3. Then `IMultiBTCVault` (depends on both above)
4. Finally `IManagedRedemptionQueue` if implementing queued redemptions

### Key Design Patterns to Follow

1. **Error Definitions**: Use custom errors (not require strings)
```solidity
error UnsupportedAsset(address token);
error InsufficientLiquidity(uint256 requested, uint256 available);
error Unauthorized(address caller);
```

2. **Event Patterns**: Follow FountFi's indexed parameter approach
```solidity
event CollateralDeposited(
    address indexed depositor,
    address indexed token,
    uint256 amount,
    uint256 shares
);
```

3. **Access Control Pattern**: Use RoleManaged modifiers
```solidity
modifier onlyAdmin() {
    if (!roleManager.hasRole(msg.sender, PROTOCOL_ADMIN)) {
        revert Unauthorized(msg.sender);
    }
    _;
}
```

4. **Decimal Handling**: Always document decimal assumptions
```solidity
// @param amount Amount in token's native decimals (8 for BTC tokens)
// @return sovaBTCAmount Amount in sovaBTC base units (8 decimals)
```

### Testing Considerations

When implementing these interfaces, ensure:
1. All functions that deal with amounts specify decimal expectations in comments
2. View functions are marked as `view` or `pure` appropriately  
3. State-changing functions return success indicators or revert
4. Events are emitted for all significant state changes
5. Functions that might be called by other contracts return standardized types

### Security Notes

1. All external functions should validate inputs
2. Use `nonReentrant` modifier on state-changing functions that transfer tokens
3. Implement pause mechanism for emergency situations
4. Ensure proper access control on all admin functions
5. Validate token addresses against registry before accepting deposits

## Example Implementation Start

Here's how to begin implementing the first interface:

```solidity
// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

interface IMultiCollateralRegistry {
    // Custom errors
    error TokenNotSupported(address token);
    error InvalidDecimals(uint8 decimals);
    error InvalidConversionRate(uint256 rate);
    error TokenAlreadyAdded(address token);
    
    // Events
    event CollateralAdded(address indexed token, uint256 conversionRate, uint8 decimals);
    event CollateralRemoved(address indexed token);
    event ConversionRateUpdated(address indexed token, uint256 oldRate, uint256 newRate);
    
    // ... rest of interface
}
```

This specification provides everything needed for Claude Code to create clean, well-documented interfaces that integrate properly with the existing FountFi codebase.