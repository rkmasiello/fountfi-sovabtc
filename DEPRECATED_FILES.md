# Deprecated Files Notice

## Overview

As part of Session 19 cleanup, all deprecated contracts, tests, and scripts have been removed from the main project to ensure clean compilation and testing.

## Deprecated Contracts Removed

The following contracts and related files were part of the old multi-contract architecture and have been removed:

### Contracts (`src/`)
- `MultiBTCVault.sol` - Old vault implementation
- `MultiCollateralStrategy.sol` - Overly complex strategy
- `ManagedRedemptionQueue.sol` - Unnecessary queue system
- `MultiCollateralRegistry.sol` - Replaced by inline mappings
- `BtcVaultShareToken.sol` - Old version extending tRWA directly

### Interfaces (`src/interfaces/`)
- `IMultiBTCVault.sol`
- `IMultiCollateralRegistry.sol`
- `IMultiCollateralStrategy.sol`
- `IManagedRedemptionQueue.sol`

### Tests (`test/`)
- `MultiBTCVault.t.sol`
- `ManagedRedemptionQueue.t.sol`
- `MultiCollateralStrategy.t.sol`
- `MultiCollateralRegistry.t.sol`
- `BtcVaultTest.t.sol` (old version)
- `FullSystemTest.t.sol`
- `DeploymentTest.t.sol`
- `InterfaceCompilation.t.sol`

### Scripts (`script/`)
- Various deployment and configuration scripts that referenced deprecated contracts
- Old deployment scripts from the multi-contract architecture

## New Architecture

The system has been refactored to a clean 2-contract architecture:

1. **BtcVaultStrategy** (`src/strategy/BtcVaultStrategy.sol`)
   - Extends ReportedStrategy
   - Manages collateral and liquidity
   - Auto-deploys BtcVaultToken

2. **BtcVaultToken** (`src/token/BtcVaultToken.sol`)
   - Extends ManagedWithdrawRWA
   - Handles multi-collateral deposits
   - ERC4626 compliant

## Migration Guide

If you need to reference the old implementation:
1. Check git history for the deprecated files
2. The old contracts followed a 4+ contract pattern with separate registry and queue
3. The new implementation consolidates functionality into 2 contracts

## Testing

All tests pass with the new architecture:
- Run `forge test` to verify all tests pass
- The main test file for the new architecture is `test/BtcVaultRefactorTest.t.sol`

## Deployment

Use the updated deployment script:
- `script/deploy/DeployBtcVault.s.sol` - Deploys the new 2-contract system

## Notes

- The deprecated files were removed to prevent compilation conflicts
- The `foundry.toml` has been configured to skip deprecated folders
- All functionality from the old system has been preserved in the new architecture
- The new system is simpler, more maintainable, and follows FountFi patterns