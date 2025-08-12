# Contract Specifications

## MultiBTCVault

### Purpose
Main vault contract implementing ERC-4626 standard for multi-collateral BTC deposits.

### Key Functions

#### Deposit Flow
```solidity
function depositCollateral(address token, uint256 amount, address receiver)
    external
    nonReentrant
    whenNotPaused
    returns (uint256 shares)
```
- Accepts approved BTC collateral
- Normalizes amounts to 18 decimals
- Calculates shares based on current NAV
- Enforces 0.001 BTC minimum
- Transfers collateral to strategy

#### Redemption Flow
```solidity
function redeem(uint256 shares, address receiver, address owner)
    public
    override
    nonReentrant
    whenNotPaused
    returns (uint256 assets)
```
- Transfers shares to redemption queue
- Creates redemption request
- Returns request ID to user
- 14-day waiting period begins

### State Variables
- `strategy`: MultiCollateralStrategy address
- `redemptionQueue`: ManagedRedemptionQueue address
- `registry`: MultiCollateralRegistry address
- `priceOracle`: PriceOracleReporter address
- `minInvestmentAmount`: 0.001 BTC (in 18 decimals)

### Security Features
- ReentrancyGuard on all external functions
- Pausable for emergency situations
- Role-based access control
- Input validation on all parameters

## MultiCollateralStrategy

### Purpose
Manages multiple BTC collateral types, handles deposits/withdrawals, and maintains collateral accounting.

### Key Functions

#### Deposit Handling
```solidity
function deposit(address token, uint256 amount) external onlyVault
```
- Receives collateral from vault
- Updates internal accounting
- Maintains token balances

#### Withdrawal Processing
```solidity
function withdraw(address token, uint256 amount, address to) external onlyVault
```
- Processes redemption withdrawals
- Ensures sufficient liquidity
- Transfers tokens to recipients

#### Total Value Calculation
```solidity
function totalValue() public view returns (uint256)
```
- Calculates total BTC value across all collaterals
- Uses registry for conversion rates
- Returns 18-decimal normalized value

### State Management
- `balances`: Mapping of token to amount held
- `supportedTokens`: Array of collateral addresses
- `vault`: Authorized vault address
- `registry`: Collateral registry reference

### Security Considerations
- Only vault can call state-changing functions
- No direct user interaction
- Protected token transfers
- Accurate balance tracking

## ManagedRedemptionQueue

### Purpose
Manages redemption requests with 14-day waiting period and batch processing.

### Key Functions

#### Queue Management
```solidity
function addRedemption(
    address user,
    uint256 shares,
    uint256 assets
) external onlyVault returns (uint256 requestId)
```
- Creates redemption request
- Holds shares in custody
- Assigns unique request ID
- Sets processing timestamp

#### Processing
```solidity
function processRedemptions(uint256[] calldata requestIds) external onlyOperator
```
- Processes mature redemptions (>14 days)
- Transfers sovaBTC to users
- Burns redeemed shares
- Updates queue state

#### Emergency Controls
```solidity
function forceProcessRedemption(uint256 requestId) external onlyAdmin
```
- Immediate processing (emergency only)
- Bypasses waiting period
- Requires admin role

### Queue Structure
```solidity
struct RedemptionRequest {
    address user;
    uint256 shares;
    uint256 assets;
    uint256 timestamp;
    bool processed;
}
```

### Security Features
- Shares held in custody during wait
- Batch processing for gas efficiency
- Emergency override capability
- Request cancellation protection

## MultiCollateralRegistry

### Purpose
Maintains registry of supported BTC collateral types with decimal normalization.

### Key Functions

#### Collateral Management
```solidity
function addCollateral(
    address token,
    uint8 decimals,
    bool enabled
) external onlyManager
```
- Registers new collateral type
- Stores decimal information
- Sets enabled status

#### Conversion Utilities
```solidity
function normalizeAmount(address token, uint256 amount) 
    external view returns (uint256)
```
- Converts token amount to 18 decimals
- Handles decimal differences
- Used for all calculations

```solidity
function denormalizeAmount(address token, uint256 amount)
    external view returns (uint256)
```
- Converts 18-decimal amount to token decimals
- Used for withdrawals
- Ensures precision

### Registry Data
```solidity
struct CollateralInfo {
    uint8 decimals;
    bool enabled;
    uint256 totalDeposited;
}
```

### Validation
- Checks collateral is registered
- Verifies enabled status
- Validates decimal configuration
- Prevents duplicate registrations

## PriceOracleReporter

### Purpose
Manual price oracle for NAV updates with gradual transitions and manipulation protection.

### Key Functions

#### Price Updates
```solidity
function updatePrice(uint256 newPrice) external onlyReporter
```
- Accepts new price from authorized reporter
- Implements gradual transition
- Stores price history
- Emits update event

#### Price Retrieval
```solidity
function getCurrentPrice() external view returns (uint256)
```
- Returns current interpolated price
- Handles transition period
- 18-decimal precision

### Price Transition
- Maximum 10% immediate change
- Linear interpolation over 1 hour
- Prevents flash loan attacks
- Smooth NAV updates

### Security Model
- Reporter role required for updates
- Gradual price changes
- Historical price tracking
- Manipulation resistance

## Contract Interactions

### Deposit Flow
1. User approves collateral to vault
2. User calls `depositCollateral` on vault
3. Vault validates collateral via registry
4. Vault transfers tokens to strategy
5. Strategy updates balances
6. Vault mints mcBTC shares to user

### Redemption Flow
1. User calls `redeem` on vault
2. Vault transfers shares to queue
3. Queue creates redemption request
4. After 14 days, operator processes
5. Strategy withdraws sovaBTC
6. Queue transfers sovaBTC to user
7. Queue burns mcBTC shares

### Price Update Flow
1. Reporter calls `updatePrice` on oracle
2. Oracle begins price transition
3. Vault uses interpolated price for NAV
4. Share calculations use current NAV

## Gas Optimization

### Strategies Employed
- Batch redemption processing
- Minimal storage updates
- Efficient decimal conversion
- Cached calculations
- Optimized loops

### Measured Gas Costs
- Deposit: ~217,000 gas
- Redemption request: ~150,000 gas
- Process redemption: ~180,000 gas
- Price update: ~45,000 gas

## Upgrade Considerations

### Current Status
- Contracts are immutable (no proxy pattern)
- No upgrade mechanism implemented
- Ensures predictability for users

### Future Considerations
- May implement UUPS pattern for v2
- Would require migration strategy
- User consent mechanisms needed
- Backwards compatibility important