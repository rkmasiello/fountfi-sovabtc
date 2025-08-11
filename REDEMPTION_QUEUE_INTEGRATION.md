# ManagedRedemptionQueue Integration Design

## Overview
This document outlines the integration approach for keeping ManagedRedemptionQueue as a **separate contract** while properly integrating it with the MultiBTCVault.

## Architecture Decision
The ManagedRedemptionQueue will remain a separate contract to provide:
- Better modularity and separation of concerns
- Easier upgradeability of redemption logic
- Clear separation between vault operations and queue management
- Flexibility to replace/upgrade the queue implementation

## Integration Flow

### User Flow
```
1. User calls: Vault.queueRedemption(shares, receiver)
   ↓
2. Vault transfers shares to Queue (for custody)
   ↓  
3. Vault calls: Queue.queueRedemption(user, shares, receiver)
   ↓
4. Queue holds shares in custody for 14 days
   ↓
5. After 14 days, Admin calls: Queue.processRedemptions([requestIds])
   ↓
6. Queue burns shares via Vault
   ↓
7. Queue triggers: Strategy.withdrawTo(sovaBTC, receiver, amount)
   ↓
8. User receives sovaBTC
```

## Required Changes

### 1. MultiBTCVault Enhancements

#### Add Queue Address Storage
```solidity
// State variable
address public redemptionQueue;

// Setter function (admin only)
function setRedemptionQueue(address queue) external onlyAdmin {
    redemptionQueue = queue;
    emit RedemptionQueueUpdated(queue);
}
```

#### Add queueRedemption Function
```solidity
function queueRedemption(uint256 shares, address receiver) 
    external 
    nonReentrant 
    whenNotPaused 
    returns (uint256 requestId) 
{
    // Validate inputs
    require(shares > 0, "Zero shares");
    require(receiver != address(0), "Invalid receiver");
    require(redemptionQueue != address(0), "Queue not set");
    
    // Transfer shares from user to queue for custody
    _transfer(msg.sender, redemptionQueue, shares);
    
    // Call queue to record the redemption request
    requestId = IManagedRedemptionQueue(redemptionQueue)
        .queueRedemption(msg.sender, shares, receiver);
    
    emit RedemptionQueued(msg.sender, receiver, shares, requestId);
}
```

#### Add burnSharesForRedemption Function
```solidity
function burnSharesForRedemption(uint256 shares) 
    external 
    returns (uint256 assets) 
{
    // Only queue can call this
    require(msg.sender == redemptionQueue, "Only queue");
    
    // Calculate assets
    assets = previewRedeem(shares);
    
    // Burn shares held by queue
    _burn(redemptionQueue, shares);
    
    return assets;
}
```

### 2. ManagedRedemptionQueue Enhancements

#### Update Constructor
```solidity
constructor(
    address _vault,
    address _strategy, 
    address _roleManager,
    address _sovaBTC
) {
    // ... existing validation ...
    vault = IMultiBTCVault(_vault);
    strategy = IMultiCollateralStrategy(_strategy);
    // ... rest ...
}
```

#### Update queueRedemption Function
```solidity
function queueRedemption(address owner, uint256 shares, address receiver)
    external
    returns (uint256 requestId)
{
    // Only vault can queue redemptions
    require(msg.sender == address(vault), "Only vault");
    
    // Shares are already transferred to this contract by vault
    // Just record the redemption request
    
    // Calculate sovaBTC amount based on current conversion
    uint256 sovaBTCAmount = vault.previewRedeem(shares);
    
    // Create and store redemption request
    requestId = nextRequestId++;
    redemptionRequests[requestId] = RedemptionRequest({
        owner: owner,
        receiver: receiver,
        shares: shares,
        sovaBTCAmount: sovaBTCAmount,
        timestamp: block.timestamp,
        processed: false,
        cancelled: false
    });
    
    // Track request
    userRequests[owner].push(requestId);
    totalPendingShares += shares;
    totalPendingSovaBTC += sovaBTCAmount;
    
    emit RedemptionQueued(requestId, owner, receiver, shares, sovaBTCAmount);
}
```

#### Update cancelRedemption Function
```solidity
function cancelRedemption(uint256 requestId) external {
    RedemptionRequest storage request = redemptionRequests[requestId];
    
    // Validate
    require(request.owner == msg.sender, "Not owner");
    require(!request.processed, "Already processed");
    require(!request.cancelled, "Already cancelled");
    
    // Mark as cancelled
    request.cancelled = true;
    
    // Return shares to user from queue's custody
    IERC20(address(vault)).transfer(request.owner, request.shares);
    
    // Update totals
    totalPendingShares -= request.shares;
    totalPendingSovaBTC -= request.sovaBTCAmount;
    
    emit RedemptionCancelled(requestId, msg.sender);
}
```

#### Update processRedemptions Function
```solidity
function processRedemptions(uint256[] calldata requestIds) external {
    require(roleManager.hasRole(msg.sender, PROTOCOL_ADMIN), "Not admin");
    
    uint256 totalSharesToBurn = 0;
    uint256 totalSovaBTCNeeded = 0;
    
    // Validate all requests first
    for (uint256 i = 0; i < requestIds.length; i++) {
        RedemptionRequest storage request = redemptionRequests[requestIds[i]];
        
        require(!request.processed && !request.cancelled, "Invalid request");
        require(block.timestamp >= request.timestamp + REDEMPTION_DELAY, "Not ready");
        
        totalSharesToBurn += request.shares;
        totalSovaBTCNeeded += request.sovaBTCAmount;
    }
    
    // Burn all shares at once and get actual sovaBTC amount
    uint256 actualSovaBTC = vault.burnSharesForRedemption(totalSharesToBurn);
    
    // Process each redemption
    for (uint256 i = 0; i < requestIds.length; i++) {
        RedemptionRequest storage request = redemptionRequests[requestIds[i]];
        
        // Mark as processed
        request.processed = true;
        
        // Calculate proportional amount if needed
        uint256 sovaBTCForUser = request.sovaBTCAmount;
        if (actualSovaBTC < totalSovaBTCNeeded) {
            // Pro-rata distribution if insufficient
            sovaBTCForUser = actualSovaBTC * request.sovaBTCAmount / totalSovaBTCNeeded;
        }
        
        // Withdraw sovaBTC from strategy to user
        bool success = strategy.withdrawTo(sovaBTC, request.receiver, sovaBTCForUser);
        require(success, "Withdrawal failed");
        
        // Update totals
        totalPendingShares -= request.shares;
        totalPendingSovaBTC -= request.sovaBTCAmount;
        
        emit RedemptionProcessed(requestIds[i], request.receiver, sovaBTCForUser);
    }
    
    emit RedemptionsProcessed(requestIds, msg.sender);
}
```

### 3. Access Control Updates

#### Vault Permissions
- Queue must be authorized to:
  - Call `burnSharesForRedemption()` on vault
  - Hold vault shares in custody

#### Queue Permissions  
- Queue must be authorized to:
  - Call `withdrawTo()` on strategy
  - Be set as an authorized contract by admin

#### Strategy Permissions
- Queue must be authorized to withdraw funds via `withdrawTo()`

### 4. Emergency Controls

#### In ManagedRedemptionQueue
```solidity
// Emergency pause
bool public paused;

modifier whenNotPaused() {
    require(!paused, "Paused");
    _;
}

function pause() external onlyAdmin {
    paused = true;
    emit QueuePaused();
}

function unpause() external onlyAdmin {
    paused = false;
    emit QueueUnpaused();
}

// Force process stuck redemptions
function forceProcessRedemption(uint256 requestId) external onlyAdmin {
    // Process single redemption regardless of time
}

// Emergency fund rescue
function rescueTokens(address token, uint256 amount) external onlyAdmin {
    // Transfer stuck tokens to admin
}
```

## Testing Requirements

### Unit Tests
1. Test vault's `queueRedemption()` function
2. Test queue's share custody mechanism
3. Test `burnSharesForRedemption()` authorization
4. Test cancellation returns shares correctly
5. Test processing after 14 days

### Integration Tests
1. Full flow: deposit → queue → wait → process → receive
2. Multiple users with concurrent redemptions
3. Cancellation during waiting period
4. NAV changes during redemption period
5. Insufficient liquidity handling
6. Emergency pause/unpause

### Edge Cases
1. User tries to queue more shares than balance
2. Processing before 14 days
3. Double-processing same request
4. Cancelling processed request
5. Queue holding shares correctly

## Benefits of This Approach

1. **Separation of Concerns**
   - Vault handles share operations
   - Queue handles redemption logistics
   - Clear boundaries between contracts

2. **Upgradeability**
   - Queue can be replaced without changing vault
   - New queue implementations can be deployed
   - Smooth migration path for improvements

3. **Security**
   - Shares held in custody by queue
   - Clear authorization boundaries
   - Emergency controls in both contracts

4. **Flexibility**
   - Different queue implementations possible
   - Can add features to queue without touching vault
   - Multiple queues could be supported

## Implementation Order

1. Update MultiBTCVault with new functions
2. Update ManagedRedemptionQueue for proper integration
3. Update access control permissions
4. Add emergency controls
5. Write comprehensive tests
6. Create deployment scripts with proper wiring

## Success Criteria

- [ ] Vault has `queueRedemption()` function
- [ ] Queue properly holds shares in custody
- [ ] Shares can be burned after 14 days
- [ ] Cancellation returns shares to user
- [ ] All existing tests still pass
- [ ] New integration tests pass
- [ ] Emergency controls work
- [ ] Deployment scripts wire everything correctly