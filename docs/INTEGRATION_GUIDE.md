# BTC Vault Integration Guide

## Overview

The BTC Vault system is a multi-collateral vault that accepts various BTC-pegged tokens (WBTC, tBTC, etc.) and mints shares representing the deposited value. The system follows the ManagedWithdrawRWAStrategy pattern with a clean 2-contract architecture.

## Architecture

### Core Contracts

1. **BtcVaultStrategy** (`src/strategy/BtcVaultStrategy.sol`)
   - Extends ReportedStrategy
   - Manages collateral types and liquidity
   - Handles redemption approvals
   - Auto-deploys BtcVaultToken during initialization

2. **BtcVaultToken** (`src/token/BtcVaultToken.sol`)
   - Extends ManagedWithdrawRWA (ERC4626 compliant)
   - Handles multi-collateral deposits
   - Enforces managed withdrawals only

## Integration Points

### For Frontend Applications

#### 1. Deposit Flow

Users can deposit supported BTC collateral tokens to receive vault shares:

```javascript
// Step 1: Check if token is supported
const isSupported = await btcVaultStrategy.isSupportedAsset(wbtcAddress);

// Step 2: User approves collateral spending
await wbtc.approve(btcVaultTokenAddress, depositAmount);

// Step 3: User deposits collateral
await btcVaultToken.depositCollateral(
    wbtcAddress,     // collateral token
    depositAmount,   // amount to deposit
    userAddress      // receiver of shares
);
```

#### 2. Redemption Flow (Manager-Initiated)

Redemptions must be approved by the strategy manager:

```javascript
// Step 1: User approves strategy to spend their shares
await btcVaultToken.approve(strategyAddress, shareAmount);

// Step 2: Manager processes the redemption
// (This is done by the manager, not the user)
await btcVaultToken.redeem(
    shareAmount,     // shares to redeem
    recipientAddress,// receiver of sovaBTC
    userAddress,     // owner of shares
    minAssets        // minimum assets expected
);
```

#### 3. View Functions

```javascript
// Get user's share balance
const shares = await btcVaultToken.balanceOf(userAddress);

// Convert shares to assets value
const assetValue = await btcVaultToken.convertToAssets(shares);

// Get total assets under management
const totalAssets = await btcVaultToken.totalAssets();

// Check supported collateral
const isSupported = await btcVaultStrategy.isSupportedAsset(tokenAddress);

// Get all supported collateral tokens
const collateralTokens = await btcVaultStrategy.getCollateralTokens();
```

### For Smart Contract Integration

#### Depositing Collateral

```solidity
interface IBtcVaultToken {
    function depositCollateral(
        address token,
        uint256 amount,
        address receiver
    ) external returns (uint256 shares);
}

// Example integration
contract MyProtocol {
    IBtcVaultToken public btcVault;
    IERC20 public wbtc;
    
    function depositToBtcVault(uint256 amount) external {
        // Transfer WBTC from user
        wbtc.transferFrom(msg.sender, address(this), amount);
        
        // Approve vault to spend WBTC
        wbtc.approve(address(btcVault), amount);
        
        // Deposit and receive shares
        uint256 shares = btcVault.depositCollateral(
            address(wbtc),
            amount,
            msg.sender
        );
    }
}
```

## Deployment

### Using Foundry Script

1. Set environment variables:
```bash
export DEPLOYER_ADDRESS=0x...
export SOVABTC_ADDRESS=0x...
export ROLE_MANAGER_ADDRESS=0x...
export REGISTRY_ADDRESS=0x...

# Optional
export WBTC_ADDRESS=0x...
export TBTC_ADDRESS=0x...
export INITIAL_LIQUIDITY=100000000  # 1 BTC in satoshis
```

2. Deploy the vault:
```bash
forge script script/deploy/DeployBtcVault.s.sol \
    --rpc-url $RPC_URL \
    --private-key $PRIVATE_KEY \
    --broadcast
```

### Post-Deployment Configuration

1. **Add Collateral Types**:
```solidity
btcVaultStrategy.addCollateral(wbtcAddress, 8);  // 8 decimals
btcVaultStrategy.addCollateral(tbtcAddress, 8);
```

2. **Add Initial Liquidity**:
```solidity
sovaBTC.approve(strategyAddress, liquidityAmount);
btcVaultStrategy.addLiquidity(liquidityAmount);
```

3. **Set Roles** (if needed):
```solidity
roleManager.grantRole(managerAddress, STRATEGY_ADMIN_ROLE);
```

## Security Considerations

1. **Managed Withdrawals**: All redemptions must be approved by the strategy manager
2. **Role-Based Access**: Administrative functions are protected by role checks
3. **Collateral Validation**: Only pre-approved collateral tokens can be deposited
4. **Decimal Handling**: All BTC tokens must have 8 decimals
5. **Price Reporting**: Strategy uses PriceOracleReporter for share pricing

## Events to Monitor

```solidity
// From BtcVaultStrategy
event CollateralAdded(address indexed token, uint8 decimals);
event CollateralRemoved(address indexed token);
event LiquidityAdded(uint256 amount);
event LiquidityRemoved(uint256 amount);
event CollateralDeposited(address indexed depositor, address indexed token, uint256 amount);

// From BtcVaultToken (ERC4626 events)
event Deposit(address indexed sender, address indexed owner, uint256 assets, uint256 shares);
event Withdraw(address indexed sender, address indexed receiver, address indexed owner, uint256 assets, uint256 shares);
```

## Error Handling

Common errors and their meanings:

- `TokenNotSupported()`: Attempting to deposit an unsupported collateral token
- `AssetNotSupported()`: Token is not in the supported assets list
- `InsufficientLiquidity()`: Not enough sovaBTC liquidity for redemption
- `InvalidAmount()`: Deposit amount is below minimum or invalid
- `Unauthorized()`: Caller doesn't have required role for the operation

## Testing Integration

Run the test suite to verify integration:

```bash
# Run all BTC vault tests
forge test --match-contract BtcVaultRefactorTest -vv

# Run specific test
forge test --match-test test_DepositWBTC -vv
```

## Migration from Old System

If migrating from the deprecated multi-contract system:

1. Deploy new BtcVaultStrategy (auto-deploys token)
2. Configure collateral types to match old system
3. Add liquidity to support redemptions
4. Update frontend to use new contract addresses
5. Migrate user positions if needed (coordinate redemptions and re-deposits)

## Support

For technical questions or issues:
- Review test files in `test/BtcVaultRefactorTest.t.sol`
- Check deployment script in `script/deploy/DeployBtcVault.s.sol`
- Consult the technical specification in `ASSESSMENT_REPORT_REFACTOR.md`