# Session 31: Database Integration - Replace Mock Data with Neon PostgreSQL

## Context
We have successfully completed:
- ✅ Multi-network contract management system with admin UI (Session 30)
- ✅ DeploymentRegistry with localStorage persistence
- ✅ Network templates for 13+ chains
- ✅ Complete admin interface at `/admin/deployments`
- ✅ Import/export functionality
- ✅ Dashboard with metrics visualization

## Current Problem
The deployment configurations and metrics are currently stored in **localStorage** (browser storage) which means:
- Data is lost when browser cache is cleared
- No persistence across different devices
- Mock/placeholder metrics data
- No real blockchain data integration
- No multi-user support

## Session 31 Objectives

### 🎯 Primary Goal
Replace the mock localStorage implementation with a real **Neon PostgreSQL database** to persist deployment configurations and collect real blockchain metrics.

### Database Connection
```
postgresql://neondb_owner:npg_nV3muZf7eUwd@ep-curly-lab-a5wkugy4-pooler.us-east-2.aws.neon.tech/neondb?sslmode=require&channel_binding=require
```

## Implementation Plan

### 1. Database Setup & Schema Design

#### A. Install Required Dependencies
```bash
npm install @prisma/client prisma
npm install @vercel/postgres # Alternative lightweight option
npm install ethers # For blockchain data fetching
```

#### B. Initialize Prisma
```bash
npx prisma init
```

#### C. Database Schema
```prisma
// prisma/schema.prisma
datasource db {
  provider  = "postgresql"
  url       = env("DATABASE_URL")
  directUrl = env("DIRECT_DATABASE_URL")
}

generator client {
  provider = "prisma-client-js"
}

model Network {
  id            String       @id @default(cuid())
  chainId       Int          @unique
  name          String
  rpcUrl        String
  blockExplorer String
  nativeCurrency Json        // {name, symbol, decimals}
  isTestnet     Boolean      @default(false)
  createdAt     DateTime     @default(now())
  updatedAt     DateTime     @updatedAt
  
  deployments   Deployment[]
  metrics       NetworkMetrics[]
}

model Deployment {
  id                String      @id @default(cuid())
  chainId           Int
  network           Network     @relation(fields: [chainId], references: [chainId])
  
  // Contract addresses
  vaultStrategy     String
  vaultToken        String
  priceOracle       String?
  
  // Deployment info
  status            DeploymentStatus @default(NOT_DEPLOYED)
  deployer          String?
  blockNumber       Int?
  transactionHash   String?
  verified          Boolean     @default(false)
  
  createdAt         DateTime    @default(now())
  updatedAt         DateTime    @updatedAt
  
  collaterals       Collateral[]
  metrics           DeploymentMetrics[]
  activities        Activity[]
}

enum DeploymentStatus {
  NOT_DEPLOYED
  PENDING
  ACTIVE
  DEPRECATED
}

model Collateral {
  id            String      @id @default(cuid())
  deploymentId  String
  deployment    Deployment  @relation(fields: [deploymentId], references: [id], onDelete: Cascade)
  
  symbol        String
  name          String
  address       String
  decimals      Int
  oracleId      String?
  
  createdAt     DateTime    @default(now())
  updatedAt     DateTime    @updatedAt
  
  @@unique([deploymentId, symbol])
}

model DeploymentMetrics {
  id            String      @id @default(cuid())
  deploymentId  String
  deployment    Deployment  @relation(fields: [deploymentId], references: [id], onDelete: Cascade)
  
  tvl           Decimal     @db.Decimal(30, 10)
  totalSupply   Decimal     @db.Decimal(30, 10)
  totalAssets   Decimal     @db.Decimal(30, 10)
  sharePrice    Decimal     @db.Decimal(30, 10)
  apy           Decimal?    @db.Decimal(10, 4)
  users         Int         @default(0)
  transactions  Int         @default(0)
  
  timestamp     DateTime    @default(now())
  
  @@index([deploymentId, timestamp])
}

model NetworkMetrics {
  id            String      @id @default(cuid())
  chainId       Int
  network       Network     @relation(fields: [chainId], references: [chainId])
  
  blockHeight   BigInt
  gasPrice      BigInt
  isOnline      Boolean     @default(true)
  latency       Int?        // milliseconds
  
  timestamp     DateTime    @default(now())
  
  @@index([chainId, timestamp])
}

model Activity {
  id            String      @id @default(cuid())
  deploymentId  String
  deployment    Deployment  @relation(fields: [deploymentId], references: [id], onDelete: Cascade)
  
  type          ActivityType
  description   String
  metadata      Json?       // Additional data
  txHash        String?
  
  createdAt     DateTime    @default(now())
  
  @@index([deploymentId, createdAt])
}

enum ActivityType {
  DEPLOYMENT_CREATED
  DEPLOYMENT_UPDATED
  COLLATERAL_ADDED
  COLLATERAL_REMOVED
  STATUS_CHANGED
  METRICS_UPDATED
  USER_DEPOSIT
  USER_WITHDRAWAL
}
```

### 2. API Routes Implementation

#### A. Deployment CRUD Operations
```typescript
// app/api/deployments/route.ts
export async function GET() {
  // Fetch all deployments with relations
}

export async function POST(request: Request) {
  // Create new deployment
}

// app/api/deployments/[chainId]/route.ts
export async function GET({ params }) {
  // Get specific deployment
}

export async function PUT(request: Request, { params }) {
  // Update deployment
}

export async function DELETE({ params }) {
  // Remove deployment
}
```

#### B. Metrics Collection
```typescript
// app/api/metrics/collect/route.ts
export async function POST(request: Request) {
  // Collect metrics from blockchain
  // Store in database
  // Return updated metrics
}

// app/api/metrics/[chainId]/route.ts
export async function GET({ params }) {
  // Get historical metrics for a deployment
}
```

#### C. Activity Logging
```typescript
// app/api/activity/route.ts
export async function GET(request: Request) {
  // Get recent activities with pagination
}

export async function POST(request: Request) {
  // Log new activity
}
```

### 3. Blockchain Data Collection Service

#### A. Metrics Collector
```typescript
// lib/services/metricsCollector.ts
import { ethers } from 'ethers';
import { prisma } from '@/lib/prisma';

export class MetricsCollector {
  private providers: Map<number, ethers.Provider>;
  
  async collectDeploymentMetrics(deploymentId: string) {
    // 1. Connect to RPC
    // 2. Fetch contract data (TVL, supply, etc.)
    // 3. Store in database
    // 4. Log activity
  }
  
  async collectNetworkMetrics(chainId: number) {
    // 1. Check RPC connectivity
    // 2. Get gas price
    // 3. Get block height
    // 4. Measure latency
    // 5. Store metrics
  }
  
  async collectAllMetrics() {
    // Run for all active deployments
  }
}
```

#### B. Scheduled Jobs
```typescript
// lib/services/scheduler.ts
// Using Vercel Cron or similar
export async function scheduledMetricsCollection() {
  // Run every 5 minutes
  const collector = new MetricsCollector();
  await collector.collectAllMetrics();
}
```

### 4. Update Frontend Components

#### A. Update DeploymentRegistry
```typescript
// lib/deployments/registry.ts
export class DeploymentRegistry {
  // Remove localStorage methods
  // Add API call methods
  
  async loadDeployments(): Promise<void> {
    const response = await fetch('/api/deployments');
    const data = await response.json();
    // Process data
  }
  
  async saveDeployment(deployment: DeploymentInfo): Promise<void> {
    await fetch('/api/deployments', {
      method: 'POST',
      body: JSON.stringify(deployment),
    });
  }
}
```

#### B. Update Hooks
```typescript
// hooks/useDeploymentRegistry.ts
import { useQuery, useMutation } from '@tanstack/react-query';

export function useDeploymentRegistry() {
  const { data: deployments, refetch } = useQuery({
    queryKey: ['deployments'],
    queryFn: () => fetch('/api/deployments').then(r => r.json()),
  });
  
  const addDeployment = useMutation({
    mutationFn: (deployment) => 
      fetch('/api/deployments', { 
        method: 'POST',
        body: JSON.stringify(deployment)
      }),
    onSuccess: () => refetch(),
  });
  
  // Return API-backed methods
}
```

### 5. Real-time Updates

#### A. WebSocket or Server-Sent Events
```typescript
// app/api/metrics/stream/route.ts
export async function GET() {
  // Stream real-time metrics updates
  const stream = new ReadableStream({
    async start(controller) {
      // Send updates every 10 seconds
    }
  });
  
  return new Response(stream, {
    headers: {
      'Content-Type': 'text/event-stream',
    },
  });
}
```

#### B. Frontend Integration
```typescript
// hooks/useRealtimeMetrics.ts
export function useRealtimeMetrics(chainId: number) {
  const [metrics, setMetrics] = useState(null);
  
  useEffect(() => {
    const eventSource = new EventSource(`/api/metrics/stream?chainId=${chainId}`);
    eventSource.onmessage = (event) => {
      setMetrics(JSON.parse(event.data));
    };
    return () => eventSource.close();
  }, [chainId]);
  
  return metrics;
}
```

### 6. Migration Strategy

#### A. Data Migration Script
```typescript
// scripts/migrate-localStorage.ts
// 1. Read existing localStorage data
// 2. Transform to database schema
// 3. Insert into PostgreSQL
// 4. Verify migration
```

#### B. Backward Compatibility
- Keep localStorage as fallback during transition
- Sync between localStorage and database
- Gradual migration approach

### 7. Environment Configuration

#### A. Environment Variables
```env
# .env.local
DATABASE_URL="postgresql://neondb_owner:npg_nV3muZf7eUwd@ep-curly-lab-a5wkugy4-pooler.us-east-2.aws.neon.tech/neondb?sslmode=require&channel_binding=require&pgbouncer=true"
DIRECT_DATABASE_URL="postgresql://neondb_owner:npg_nV3muZf7eUwd@ep-curly-lab-a5wkugy4.us-east-2.aws.neon.tech/neondb?sslmode=require"

# RPC URLs for metrics collection
ETHEREUM_RPC_URL=
BASE_RPC_URL=
ARBITRUM_RPC_URL=
# ... etc
```

## File Structure

```
frontend/
├── prisma/
│   ├── schema.prisma          # Database schema
│   └── migrations/            # Migration files
├── app/
│   └── api/
│       ├── deployments/       # Deployment CRUD
│       ├── metrics/           # Metrics endpoints
│       ├── activity/          # Activity logging
│       └── health/            # Health check
├── lib/
│   ├── prisma.ts             # Prisma client singleton
│   ├── services/
│   │   ├── metricsCollector.ts
│   │   ├── scheduler.ts
│   │   └── activityLogger.ts
│   └── deployments/
│       └── registry.ts       # Updated for API
└── scripts/
    └── migrate-localStorage.ts
```

## Testing Plan

1. **Database Connection**: Verify Neon PostgreSQL connection
2. **Schema Migration**: Run Prisma migrations successfully
3. **CRUD Operations**: Test all deployment operations
4. **Metrics Collection**: Verify real blockchain data
5. **Performance**: Ensure queries are optimized
6. **Error Handling**: Test connection failures gracefully

## Success Criteria

1. ✅ All deployment data persisted in PostgreSQL
2. ✅ Real blockchain metrics collected every 5 minutes
3. ✅ Activity history tracked and queryable
4. ✅ Multi-user support with same data
5. ✅ No more localStorage dependency
6. ✅ Historical metrics charts working
7. ✅ < 100ms API response times

## Security Considerations

1. **Database Credentials**: Use environment variables only
2. **SQL Injection**: Prisma prevents by default
3. **Rate Limiting**: Implement for public endpoints
4. **Access Control**: Admin routes require authentication
5. **Data Validation**: Validate all inputs server-side

## Alternative Approaches

### Option 1: Vercel KV (Redis)
- Pros: Fast, built-in caching
- Cons: Not relational, limited querying

### Option 2: Supabase
- Pros: Real-time subscriptions, auth built-in
- Cons: Another service to manage

### Option 3: Direct SQL with @vercel/postgres
- Pros: Lightweight, simple
- Cons: No ORM benefits, manual queries

**Recommendation**: Prisma with Neon PostgreSQL for best DX and features

## Implementation Priority

### Phase 1: Database Setup (Day 1 Morning)
1. Configure Prisma with Neon
2. Create and run migrations
3. Test connection

### Phase 2: API Routes (Day 1 Afternoon)
1. Implement deployment CRUD
2. Add metrics endpoints
3. Create activity logging

### Phase 3: Frontend Integration (Day 2 Morning)
1. Update DeploymentRegistry
2. Modify hooks for API calls
3. Test end-to-end flow

### Phase 4: Metrics Collection (Day 2 Afternoon)
1. Implement blockchain data fetching
2. Set up scheduled jobs
3. Add real-time updates

### Phase 5: Migration & Testing (Day 3)
1. Migrate existing data
2. Comprehensive testing
3. Performance optimization

## Notes

- Start with read operations first
- Keep localStorage as temporary cache
- Implement proper error boundaries
- Add loading states for all API calls
- Consider implementing optimistic updates
- Monitor database connection pool

---

**Session Goal**: Transform the multi-network contract management system from a mock localStorage implementation to a production-ready system with real PostgreSQL database persistence and actual blockchain metrics collection.