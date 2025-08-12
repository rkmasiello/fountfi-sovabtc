# System Invariants

## Core Invariants

### 1. Total Supply Invariant
**Statement**: The total supply of mcBTC must equal the sum of all user balances plus shares held in the redemption queue.

```solidity
invariant totalSupplyConsistency:
    totalSupply() == sumOfUserBalances() + redemptionQueue.totalSharesInCustody()
```

**Verification Points**:
- After every deposit
- After every redemption request
- After processing redemptions
- During emergency operations

### 2. Asset Backing Invariant
**Statement**: The total value of assets in the strategy must be sufficient to back all outstanding shares at the current price per share.

```solidity
invariant assetBacking:
    strategy.totalValue() >= (totalSupply() * pricePerShare) / 1e18
```

**Verification Points**:
- Before and after deposits
- Before processing redemptions
- After price oracle updates
- During rebalancing operations

### 3. Collateral Conservation Invariant
**Statement**: The sum of all collateral in the strategy must equal the sum of all deposits minus all withdrawals.

```solidity
invariant collateralConservation:
    forall token in supportedTokens:
        strategy.balance(token) == totalDeposits(token) - totalWithdrawals(token)
```

**Verification Points**:
- After each deposit
- After each withdrawal
- During strategy rebalancing
- In emergency token rescue

### 4. Redemption Queue Invariant
**Statement**: The total shares in the redemption queue must be backed by equivalent assets marked for redemption.

```solidity
invariant redemptionQueueBacking:
    redemptionQueue.totalShares() <= vault.maxRedeem(redemptionQueue)
```

**Verification Points**:
- When adding redemption requests
- Before processing redemptions
- After emergency cancellations
- During force processing

### 5. Decimal Normalization Invariant
**Statement**: All internal calculations must use 18-decimal precision, with proper conversion at boundaries.

```solidity
invariant decimalConsistency:
    forall amount in internalCalculations:
        decimals(amount) == 18
```

**Verification Points**:
- Token deposit conversions
- Token withdrawal conversions
- Share calculations
- Price calculations

## State Invariants

### 6. Minimum Investment Invariant
**Statement**: No deposit can result in shares being minted for less than the minimum investment amount.

```solidity
invariant minimumInvestment:
    forall deposit:
        if (shares > 0) then normalizedAmount >= minInvestmentAmount
```

**Enforcement**:
- Checked in `depositCollateral` function
- Reverts on violation
- Applies to all collateral types

### 7. Share Price Monotonicity Invariant
**Statement**: The price per share should never decrease except through legitimate yield/loss events.

```solidity
invariant priceMonotonicity:
    newPricePerShare >= oldPricePerShare || legitimateLossEvent
```

**Verification Points**:
- After oracle price updates
- After fee assessments
- During NAV recalculations

### 8. Redemption Timing Invariant
**Statement**: No redemption can be processed before its designated waiting period expires.

```solidity
invariant redemptionTiming:
    forall redemption in processedRedemptions:
        block.timestamp >= redemption.timestamp + REDEMPTION_DELAY
```

**Exceptions**:
- Admin force processing (emergency only)
- Requires explicit admin action
- Logged for audit trail

### 9. Role Hierarchy Invariant
**Statement**: Higher privilege roles must be subsets of lower privilege roles in terms of personnel.

```solidity
invariant roleHierarchy:
    hasRole(ADMIN) implies hasRole(OPERATOR)
    hasRole(OPERATOR) implies hasRole(REPORTER)
```

**Enforcement**:
- Checked in role assignment
- Prevents privilege escalation
- Maintains security model

### 10. Token Approval Invariant
**Statement**: The strategy must never hold token approvals beyond immediate operational needs.

```solidity
invariant noExcessApprovals:
    forall token in supportedTokens:
        token.allowance(strategy, anyAddress) == 0 after transaction
```

**Verification**:
- After each token transfer
- No standing approvals
- Prevents approval exploits

## Economic Invariants

### 11. No Negative Shares Invariant
**Statement**: Share calculations must never result in negative values or underflows.

```solidity
invariant noNegativeShares:
    forall shareCalculation:
        result >= 0 && result <= type(uint256).max
```

**Protection**:
- Solidity 0.8.25 overflow protection
- Explicit checks in critical paths
- Safe math operations

### 12. Fee Extraction Limit Invariant
**Statement**: No single operation can extract more than the defined maximum fee percentage.

```solidity
invariant feeLimit:
    extractedFee <= (transactionAmount * maxFeePercentage) / 10000
```

**Current Status**:
- No fees implemented
- Invariant ready for future use
- Would require governance to modify

### 13. Liquidity Availability Invariant
**Statement**: The strategy must maintain sufficient liquidity for processing pending redemptions.

```solidity
invariant liquidityAvailability:
    strategy.availableLiquidity(sovaBTC) >= redemptionQueue.pendingRedemptionAmount()
```

**Monitoring**:
- Checked before processing
- Admin alerts on low liquidity
- Emergency pause available

### 14. Oracle Price Bound Invariant
**Statement**: Oracle price updates must not exceed maximum allowed deviation per update.

```solidity
invariant priceBounds:
    abs(newPrice - oldPrice) <= (oldPrice * MAX_PRICE_DEVIATION) / 10000
```

**Parameters**:
- MAX_PRICE_DEVIATION: 1000 (10%)
- Gradual transition over 1 hour
- Prevents manipulation

### 15. Collateral Uniqueness Invariant
**Statement**: Each collateral token can only be registered once in the registry.

```solidity
invariant collateralUniqueness:
    forall token1, token2 in supportedTokens:
        if token1 != token2 then address(token1) != address(token2)
```

**Enforcement**:
- Checked on registration
- Prevents duplicate entries
- Maintains registry integrity

## Security Invariants

### 16. Reentrancy Protection Invariant
**Statement**: No external call can re-enter protected functions during execution.

```solidity
invariant noReentrancy:
    forall protectedFunction:
        reentrancyGuard.status == ENTERED during execution
```

**Implementation**:
- OpenZeppelin ReentrancyGuard
- Applied to all external functions
- Checked before state changes

### 17. Pause Effectiveness Invariant
**Statement**: When paused, no state-changing operations can execute except emergency functions.

```solidity
invariant pauseEffectiveness:
    if (paused) then only emergencyFunctions can execute
```

**Emergency Functions**:
- `unpause()`
- `rescueTokens()`
- `forceProcessRedemption()`

### 18. Access Control Invariant
**Statement**: All restricted functions must verify caller has required role before execution.

```solidity
invariant accessControl:
    forall restrictedFunction:
        hasRole(requiredRole, msg.sender) before execution
```

**Verification**:
- OpenZeppelin AccessControl
- Reverts on unauthorized access
- Role checks in modifiers

### 19. Token Conservation Invariant
**Statement**: The sum of all token movements must equal zero (no token creation/destruction except mcBTC).

```solidity
invariant tokenConservation:
    forall token != mcBTC:
        sum(inflows) == sum(outflows)
```

**Tracking**:
- Event emissions for all transfers
- Balance checks after operations
- No token minting except mcBTC

### 20. Emergency Recovery Invariant
**Statement**: Emergency functions must be able to recover system to safe state without data loss.

```solidity
invariant emergencyRecovery:
    after emergencyOperation:
        system.isSafe() && no_permanent_data_loss
```

**Recovery Functions**:
- Pause/unpause
- Token rescue
- Force redemption processing
- Admin overrides

## Testing Invariants

### Test Coverage Requirements
- Every invariant must have at least 3 test cases
- Fuzz testing for numeric invariants
- Edge case testing for boundary conditions
- Integration tests for system-wide invariants

### Formal Verification Targets
Priority invariants for formal verification:
1. Total Supply Invariant
2. Asset Backing Invariant
3. Decimal Normalization Invariant
4. Redemption Timing Invariant
5. Token Conservation Invariant

### Monitoring Requirements
Invariants that require runtime monitoring:
- Asset Backing Invariant (continuous)
- Liquidity Availability Invariant (hourly)
- Oracle Price Bound Invariant (per update)
- Collateral Conservation Invariant (daily)

## Invariant Violation Response

### Severity Levels

#### Critical (Immediate Action)
- Total Supply Invariant violation
- Asset Backing Invariant violation
- Token Conservation Invariant violation
**Response**: Immediate pause, admin notification, investigation

#### High (Within 1 Hour)
- Redemption Timing Invariant violation
- Access Control Invariant violation
- Reentrancy Protection Invariant violation
**Response**: Investigate, prepare fix, consider pause

#### Medium (Within 24 Hours)
- Oracle Price Bound Invariant violation
- Liquidity Availability Invariant violation
**Response**: Monitor, adjust parameters, inform users

#### Low (Next Maintenance)
- Fee Extraction Limit Invariant violation
- Role Hierarchy Invariant violation
**Response**: Log, include in next update

## Invariant Dependencies

### Dependency Graph
```
Total Supply Invariant
    └── Asset Backing Invariant
        └── Collateral Conservation Invariant
            └── Decimal Normalization Invariant

Redemption Queue Invariant
    └── Redemption Timing Invariant
        └── Liquidity Availability Invariant

Access Control Invariant
    └── Role Hierarchy Invariant
        └── Pause Effectiveness Invariant
```

### Critical Paths
1. **Deposit Path**: Decimal → Collateral → Asset → Supply
2. **Redemption Path**: Timing → Queue → Liquidity → Supply
3. **Price Path**: Oracle Bounds → Asset Backing → Share Price

## Future Invariants

### Planned Additions
1. **Cross-chain Consistency**: When deployed on multiple chains
2. **Upgrade Safety**: If upgrade mechanism added
3. **Governance Bounds**: If governance added
4. **Yield Distribution**: When yield strategies implemented
5. **Slashing Protection**: For staked collateral types