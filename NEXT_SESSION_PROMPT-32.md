# Session 32: Enhanced Collateral Management & Blockchain Integration

## Context
We have successfully completed:
- ✅ PostgreSQL database integration with Neon (Session 31)
- ✅ API routes for all CRUD operations
- ✅ Data migration from localStorage to database
- ✅ React Query integration with optimistic updates
- ✅ 6 database tables tracking networks, deployments, collaterals, metrics, and activities
- ✅ Multi-network contract management system with admin UI
- ✅ Professional glassmorphism frontend with 15+ wallet support

## Current Database Schema Issues

### Problem 1: Collateral Token Tracking
Currently, collateral tokens are linked to a deployment, but the same token (e.g., WBTC) has different addresses on different networks:
- **WBTC on Ethereum**: `0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599`
- **WBTC on Base**: `0x03C7054BCB39f7b2e5B2c7AcB37583e32D70Cfa3`
- **WBTC on Arbitrum**: `0x2f2a2543B76A4166549F7aaB2e75Bef0aefC5B0f`

The current schema doesn't properly handle network-specific collateral addresses.

### Problem 2: Backend-Frontend Integration Gap
- Backend smart contracts track collaterals by address
- Frontend has hardcoded collateral templates
- No dynamic synchronization between on-chain and database collateral state

## Session 32 Objectives

### 🎯 Primary Goals

#### 1. Enhanced Database Schema for Collaterals
Update the database schema to properly track network-specific collateral tokens:

```prisma
// Updated schema concept
model SovaBtcCollateral {
  id            String      @id @default(cuid())
  deploymentId  String
  deployment    SovaBtcDeployment  @relation(...)
  
  // Token identification
  symbol        String      // e.g., "WBTC"
  name          String      // e.g., "Wrapped Bitcoin"
  
  // Network-specific address
  chainId       Int         // Network this collateral is on
  address       String      // Network-specific address
  
  // Token metadata
  decimals      Int
  oracleId      String?
  logoUri       String?     // Token logo URL
  coingeckoId   String?     // For price data
  
  // Status
  isActive      Boolean     @default(true)
  isVerified    Boolean     @default(false)
  
  createdAt     DateTime    @default(now())
  updatedAt     DateTime    @updatedAt
  
  @@unique([chainId, address])  // Unique per network
  @@unique([deploymentId, symbol, chainId])  // Unique symbol per deployment per network
  @@map("sovabtc_collaterals")
}

// New table for global token registry
model SovaBtcTokenRegistry {
  id            String      @id @default(cuid())
  
  // Token identification
  symbol        String      // e.g., "WBTC"
  name          String      // e.g., "Wrapped Bitcoin"
  
  // Network addresses (JSON object)
  addresses     Json        // { "1": "0x...", "8453": "0x...", ... }
  
  // Metadata
  decimals      Int         // Usually consistent across networks
  logoUri       String?
  coingeckoId   String?
  category      String?     // "btc", "stablecoin", etc.
  
  createdAt     DateTime    @default(now())
  updatedAt     DateTime    @updatedAt
  
  @@unique([symbol])
  @@map("sovabtc_token_registry")
}
```

#### 2. Blockchain Integration Service

Create a service to fetch real on-chain data:

```typescript
// lib/services/blockchainService.ts
export class BlockchainService {
  async fetchCollateralsFromChain(chainId: number, strategyAddress: string) {
    // Connect to RPC
    // Call strategy.getSupportedCollaterals()
    // Fetch token metadata (name, symbol, decimals)
    // Return collateral list
  }
  
  async syncCollateralsToDatabase(chainId: number) {
    // Fetch on-chain collaterals
    // Update database
    // Log activity
  }
  
  async fetchRealMetrics(chainId: number) {
    // Get TVL, share price, etc. from chain
    // Store in database
  }
}
```

#### 3. API Routes for Enhanced Collateral Management

```typescript
// app/api/collaterals/route.ts
GET /api/collaterals?chainId=8453  // Get collaterals for specific network
POST /api/collaterals/sync          // Sync from blockchain
PUT /api/collaterals/[id]          // Update metadata (logo, etc.)

// app/api/token-registry/route.ts
GET /api/token-registry             // Get all known tokens
POST /api/token-registry            // Add new token to registry
```

#### 4. Frontend Updates

##### A. Update Hooks
```typescript
// hooks/useCollaterals.ts
export function useCollaterals(chainId: number) {
  // Fetch network-specific collaterals from API
  // Cache with React Query
  // Return typed collateral list
}
```

##### B. Update Components
- **DepositForm**: Use dynamic collaterals from database
- **AdminPanel**: Add collateral sync button
- **CollateralManager**: New component for managing network-specific collaterals

#### 5. Ponder Indexer Integration

Review and potentially integrate the Ponder indexer from `/examples/ponder-indexer`:

##### Benefits of Ponder:
- Real-time blockchain event indexing
- ~10x faster than The Graph
- Direct PostgreSQL integration
- TypeScript-native with full type safety

##### Integration Tasks:
1. Review existing Ponder configuration
2. Update contract addresses and ABIs
3. Map Ponder schema to our database schema
4. Set up event handlers for:
   - Deposits
   - Withdrawals
   - Collateral additions/removals
   - Price updates
5. Create sync mechanism between Ponder and main database

#### 6. Scheduled Jobs Implementation

```typescript
// lib/services/scheduler.ts
export class MetricsScheduler {
  // Run every 5 minutes
  async collectMetrics() {
    const deployments = await getActiveDeployments();
    for (const deployment of deployments) {
      await blockchainService.fetchRealMetrics(deployment.chainId);
    }
  }
  
  // Run every hour
  async syncCollaterals() {
    const deployments = await getActiveDeployments();
    for (const deployment of deployments) {
      await blockchainService.syncCollateralsToDatabase(deployment.chainId);
    }
  }
}
```

## Implementation Plan

### Phase 1: Database Schema Update (Morning)
1. Update Prisma schema with enhanced collateral tracking
2. Create token registry table
3. Run migrations
4. Update seed data

### Phase 2: Blockchain Service (Afternoon)
1. Implement BlockchainService class
2. Add methods for fetching on-chain data
3. Create sync mechanisms
4. Test with Base Sepolia

### Phase 3: API Routes (Day 2 Morning)
1. Update collateral CRUD operations
2. Add token registry endpoints
3. Implement sync endpoints
4. Add validation and error handling

### Phase 4: Frontend Integration (Day 2 Afternoon)
1. Update hooks for network-specific collaterals
2. Modify DepositForm to use dynamic data
3. Add sync UI to AdminPanel
4. Test end-to-end flow

### Phase 5: Ponder Integration (Day 3)
1. Review and update Ponder configuration
2. Map events to database operations
3. Set up development environment
4. Test indexing with real transactions

## Success Criteria

1. ✅ Collaterals properly tracked per network with unique addresses
2. ✅ Real blockchain data replacing mock metrics
3. ✅ Frontend dynamically loads network-specific collaterals
4. ✅ Admin can sync collaterals from blockchain
5. ✅ Scheduled jobs collecting metrics automatically
6. ✅ Ponder indexer processing events (optional but recommended)

## Testing Requirements

1. **Database Tests**:
   - Verify unique constraints work correctly
   - Test collateral CRUD operations
   - Validate token registry

2. **Blockchain Integration Tests**:
   - Mock RPC calls for unit tests
   - Integration tests with real Base Sepolia
   - Verify data accuracy

3. **Frontend Tests**:
   - Test dynamic collateral loading
   - Verify network switching updates collaterals
   - Test sync UI functionality

## Environment Variables Needed

```env
# RPC URLs for each network
ETHEREUM_RPC_URL=https://eth-mainnet.g.alchemy.com/v2/xxx
BASE_RPC_URL=https://base-mainnet.g.alchemy.com/v2/xxx
ARBITRUM_RPC_URL=https://arb-mainnet.g.alchemy.com/v2/xxx
BASE_SEPOLIA_RPC_URL=https://base-sepolia.g.alchemy.com/v2/xxx

# Ponder Configuration (if using)
PONDER_RPC_URL_1=https://base-sepolia.g.alchemy.com/v2/xxx

# Cron Secret (for Vercel Cron or similar)
CRON_SECRET=xxx
```

## Notes

### Why This Matters:
1. **Multi-chain Ready**: Proper network-specific tracking enables true multi-chain deployment
2. **Data Accuracy**: Real blockchain data instead of mocks
3. **User Experience**: Dynamic collaterals improve flexibility
4. **Maintainability**: Centralized token registry reduces duplication

### Considerations:
1. **RPC Rate Limits**: Implement caching and rate limiting
2. **Gas Costs**: Batch operations where possible
3. **Data Consistency**: Handle chain reorgs gracefully
4. **Performance**: Optimize database queries with proper indexes

### Optional Enhancements:
1. **Token Price Integration**: Fetch prices from CoinGecko/CMC
2. **WebSocket Support**: Real-time updates instead of polling
3. **IPFS Integration**: Store token logos on IPFS
4. **Analytics Dashboard**: Visualize metrics over time

## References

- [Ponder Documentation](https://ponder.sh)
- [Prisma Schema Reference](https://www.prisma.io/docs/reference/api-reference/prisma-schema-reference)
- [Ethers.js v6 Docs](https://docs.ethers.org/v6/)
- [Vercel Cron Jobs](https://vercel.com/docs/cron-jobs)

---

**Session Goal**: Transform the collateral management system from a static, deployment-centric model to a dynamic, network-aware system with real blockchain data integration and optional event indexing via Ponder.