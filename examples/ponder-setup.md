# Ponder Indexer Setup for Multi-Collateral BTC Vault

## Overview

This guide explains how to set up Ponder for indexing the Multi-Collateral BTC Vault events into a Neon PostgreSQL database.

## Why Ponder over The Graph?

- **Performance**: ~10x faster indexing than Graph Node
- **Developer Experience**: TypeScript-native with hot-reloading
- **Direct Database Access**: Query directly with SQL, not just GraphQL
- **Cost Effective**: Uses 35x less disk space and 35% fewer RPC credits
- **Flexibility**: Multiple query interfaces (GraphQL, SQL over HTTP, direct Postgres)

## Setup Instructions

### 1. Create Ponder Project

```bash
cd examples
npm create ponder@latest vault-indexer
cd vault-indexer
```

### 2. Configure Environment

Create `.env.local` file:

```env
# Neon Database Connection
DATABASE_URL=postgresql://neondb_owner:npg_nV3muZf7eUwd@ep-curly-lab-a5wkugy4-pooler.us-east-2.aws.neon.tech/neondb?sslmode=require

# RPC URL
PONDER_RPC_URL_BASE_SEPOLIA=https://base-sepolia.g.alchemy.com/v2/e7qIcHOK60Sc4-hvyWA68
```

### 3. Install Dependencies

```bash
npm install @ponder/core viem
```

### 4. Configure Contracts

Create `ponder.config.ts`:

```typescript
import { createConfig } from "@ponder/core";
import { http } from "viem";

// Import ABIs
import MultiBTCVaultABI from "./abis/MultiBTCVault.json";
import ManagedRedemptionQueueABI from "./abis/ManagedRedemptionQueue.json";

export default createConfig({
  networks: {
    baseSepolia: {
      chainId: 84532,
      transport: http(process.env.PONDER_RPC_URL_BASE_SEPOLIA),
    },
  },
  contracts: {
    MultiBTCVault: {
      network: "baseSepolia",
      abi: MultiBTCVaultABI,
      address: "0x73E27097221d4d9D5893a83350dC7A967b46fab7",
      startBlock: 19000000, // Adjust to actual deployment block
    },
    ManagedRedemptionQueue: {
      network: "baseSepolia",
      abi: ManagedRedemptionQueueABI,
      address: "0x22BC73098CE1Ba2CaE5431fb32051cB4fc0F9C52",
      startBlock: 19000000,
    },
  },
  database: {
    kind: "postgres",
    connectionString: process.env.DATABASE_URL,
    poolConfig: {
      max: 10,
    },
  },
});
```

### 5. Define Database Schema

Create `ponder.schema.ts`:

```typescript
import { onchainTable, index, relations } from "@ponder/core";

// User accounts
export const accounts = onchainTable("accounts", (t) => ({
  address: t.hex().primaryKey(),
  firstSeenBlock: t.bigint().notNull(),
  firstSeenTimestamp: t.bigint().notNull(),
  totalDeposited: t.bigint().notNull().default(0n),
  totalRedeemed: t.bigint().notNull().default(0n),
  currentShares: t.bigint().notNull().default(0n),
}));

// Deposit events
export const deposits = onchainTable("deposits", (t) => ({
  id: t.text().primaryKey(), // txHash-logIndex
  userAddress: t.hex().notNull(),
  asset: t.hex().notNull(),
  assetSymbol: t.text().notNull(),
  amount: t.bigint().notNull(),
  shares: t.bigint().notNull(),
  sharePrice: t.bigint().notNull(),
  timestamp: t.bigint().notNull(),
  blockNumber: t.bigint().notNull(),
  txHash: t.hex().notNull(),
}), (table) => ({
  userIdx: index().on(table.userAddress),
  timestampIdx: index().on(table.timestamp),
}));

// Redemption requests
export const redemptionRequests = onchainTable("redemption_requests", (t) => ({
  id: t.text().primaryKey(), // requestId
  requestId: t.bigint().notNull().unique(),
  userAddress: t.hex().notNull(),
  shares: t.bigint().notNull(),
  requestedAt: t.bigint().notNull(),
  processed: t.boolean().notNull().default(false),
  processedAt: t.bigint(),
  claimed: t.boolean().notNull().default(false),
  claimedAt: t.bigint(),
  redeemableAmount: t.bigint(),
  status: t.text().notNull(), // 'pending', 'processed', 'claimed'
  txHash: t.hex().notNull(),
}), (table) => ({
  userIdx: index().on(table.userAddress),
  statusIdx: index().on(table.status),
  requestedAtIdx: index().on(table.requestedAt),
}));

// Vault metrics (snapshot every hour)
export const vaultSnapshots = onchainTable("vault_snapshots", (t) => ({
  id: t.text().primaryKey(), // blockNumber-timestamp
  totalAssets: t.bigint().notNull(),
  totalSupply: t.bigint().notNull(),
  sharePrice: t.bigint().notNull(),
  totalUsers: t.integer().notNull(),
  pendingRedemptions: t.bigint().notNull(),
  timestamp: t.bigint().notNull(),
  blockNumber: t.bigint().notNull(),
}), (table) => ({
  timestampIdx: index().on(table.timestamp),
}));

// Daily aggregates for analytics
export const dailyStats = onchainTable("daily_stats", (t) => ({
  date: t.text().primaryKey(), // YYYY-MM-DD
  depositsCount: t.integer().notNull().default(0),
  depositsVolume: t.bigint().notNull().default(0n),
  redemptionsCount: t.integer().notNull().default(0),
  redemptionsVolume: t.bigint().notNull().default(0n),
  uniqueUsers: t.integer().notNull().default(0),
  avgSharePrice: t.bigint().notNull().default(0n),
  closingTVL: t.bigint().notNull().default(0n),
}));
```

### 6. Create Indexing Functions

Create `src/index.ts`:

```typescript
import { ponder } from "@/generated";
import { accounts, deposits, redemptionRequests, vaultSnapshots } from "../ponder.schema";

// Track deposits
ponder.on("MultiBTCVault:Deposit", async ({ event, context }) => {
  const { db } = context;
  const { caller, owner, assets, shares } = event.args;
  
  // Update or create account
  await db
    .insert(accounts)
    .values({
      address: owner,
      firstSeenBlock: event.block.number,
      firstSeenTimestamp: event.block.timestamp,
      totalDeposited: assets,
      currentShares: shares,
    })
    .onConflictDoUpdate({
      totalDeposited: (current) => current.totalDeposited + assets,
      currentShares: (current) => current.currentShares + shares,
    });
  
  // Record deposit
  await db.insert(deposits).values({
    id: `${event.transaction.hash}-${event.log.logIndex}`,
    userAddress: owner,
    asset: caller, // The token address
    assetSymbol: getTokenSymbol(caller),
    amount: assets,
    shares: shares,
    sharePrice: await getSharePrice(context),
    timestamp: event.block.timestamp,
    blockNumber: event.block.number,
    txHash: event.transaction.hash,
  });
  
  // Update vault snapshot if needed
  await updateVaultSnapshot(context, event.block);
});

// Track redemption requests
ponder.on("MultiBTCVault:RedemptionRequested", async ({ event, context }) => {
  const { db } = context;
  const { requestId, user, shares } = event.args;
  
  await db.insert(redemptionRequests).values({
    id: requestId.toString(),
    requestId: requestId,
    userAddress: user,
    shares: shares,
    requestedAt: event.block.timestamp,
    processed: false,
    claimed: false,
    status: "pending",
    txHash: event.transaction.hash,
  });
  
  // Update account shares
  await db
    .update(accounts)
    .set({
      currentShares: (current) => current.currentShares - shares,
    })
    .where({ address: user });
});

// Track redemption processing
ponder.on("ManagedRedemptionQueue:RedemptionsProcessed", async ({ event, context }) => {
  const { db } = context;
  const { requestIds } = event.args;
  
  for (const requestId of requestIds) {
    await db
      .update(redemptionRequests)
      .set({
        processed: true,
        processedAt: event.block.timestamp,
        status: "processed",
      })
      .where({ requestId: requestId });
  }
});

// Track redemption claims
ponder.on("ManagedRedemptionQueue:RedemptionClaimed", async ({ event, context }) => {
  const { db } = context;
  const { requestId, user, amount } = event.args;
  
  await db
    .update(redemptionRequests)
    .set({
      claimed: true,
      claimedAt: event.block.timestamp,
      redeemableAmount: amount,
      status: "claimed",
    })
    .where({ requestId: requestId });
  
  // Update account totals
  await db
    .update(accounts)
    .set({
      totalRedeemed: (current) => current.totalRedeemed + amount,
    })
    .where({ address: user });
});

// Helper functions
function getTokenSymbol(address: string): string {
  const symbols: Record<string, string> = {
    "0xe44b2870eFcd6Bb3C9305808012621f438e9636D": "WBTC",
    "0xE2b47f0dD766834b9DD2612D2d3632B05Ca89802": "TBTC",
    "0x05aB19d77516414f7333a8fd52cC1F49FF8eAFA9": "sovaBTC",
  };
  return symbols[address] || "UNKNOWN";
}

async function getSharePrice(context: any): Promise<bigint> {
  // Implement share price calculation
  return 1000000000000000000n; // 1e18 as placeholder
}

async function updateVaultSnapshot(context: any, block: any): Promise<void> {
  // Implement periodic snapshot logic
  // Only update once per hour to avoid too many records
}
```

### 7. Run the Indexer

```bash
# Development (with hot-reload)
npm run dev

# Production
npm run start

# Generate TypeScript types from schema
npm run codegen
```

## Querying the Data

Once indexed, you can query the data in multiple ways:

### 1. GraphQL API

```graphql
query {
  deposits(orderBy: "timestamp", orderDirection: "desc", limit: 10) {
    items {
      userAddress
      amount
      shares
      timestamp
    }
  }
}
```

### 2. Direct SQL

```sql
-- Get total deposits by user
SELECT 
  user_address,
  COUNT(*) as deposit_count,
  SUM(amount) as total_deposited
FROM deposits
GROUP BY user_address
ORDER BY total_deposited DESC;

-- Get pending redemptions
SELECT * FROM redemption_requests
WHERE status = 'pending'
ORDER BY requested_at;

-- Get vault metrics over time
SELECT 
  DATE(to_timestamp(timestamp)) as date,
  AVG(share_price) as avg_price,
  MAX(total_assets) as peak_tvl
FROM vault_snapshots
GROUP BY date
ORDER BY date DESC;
```

### 3. TypeScript SDK Integration

```typescript
import { createPublicClient, http } from "viem";
import { baseSepolia } from "viem/chains";

// Query indexed data via Ponder's API
const response = await fetch("http://localhost:42069/graphql", {
  method: "POST",
  headers: { "Content-Type": "application/json" },
  body: JSON.stringify({
    query: `
      query GetUserDeposits($address: String!) {
        deposits(where: { userAddress: $address }) {
          items {
            amount
            shares
            timestamp
          }
        }
      }
    `,
    variables: { address: userAddress },
  }),
});
```

## Production Deployment

For production:

1. Use a dedicated Neon database branch
2. Set up proper connection pooling
3. Configure rate limiting for RPC calls
4. Implement monitoring and alerting
5. Set up database backups

## Monitoring

Monitor indexer health:

```bash
# Check indexing progress
curl http://localhost:42069/metrics

# View logs
npm run dev -- --log-level debug
```

## Benefits for the Multi-Collateral BTC Vault

1. **Real-time Analytics**: Track TVL, user activity, and redemption queues
2. **Historical Data**: Analyze trends and user behavior over time
3. **Performance**: Fast queries directly from PostgreSQL
4. **Flexibility**: Use SQL for complex analytics queries
5. **Integration**: Easy to integrate with existing backend services

## Resources

- [Ponder Documentation](https://ponder.sh/docs)
- [Neon Database](https://neon.tech/docs)
- [Base Sepolia Explorer](https://sepolia.basescan.org)