# Session 33: Ponder Indexer Integration & Scheduled Jobs

## Context
We have successfully completed:
- ✅ Enhanced collateral management with network-specific tracking (Session 32)
- ✅ Blockchain service for on-chain data fetching
- ✅ Token registry with multi-network support
- ✅ Dynamic collateral loading in frontend
- ✅ Admin sync functionality for collaterals
- ✅ PostgreSQL database with 8 tables
- ✅ Complete API routes for all operations

## Current Architecture Status

### What We Have:
1. **Database**: PostgreSQL with Prisma ORM, fully configured
2. **Blockchain Service**: Can fetch data from chain when called
3. **API Routes**: All CRUD operations working
4. **Frontend**: Dynamic collateral management, admin controls
5. **Deployment**: Base Sepolia contracts live and verified

### What's Missing:
1. **Event Indexing**: No historical event tracking
2. **Automation**: Manual triggers only, no scheduled jobs
3. **Real-time Updates**: Polling-based, no WebSocket/SSE

## Session 33 Objectives

### 🎯 Part 1: Ponder Indexer Integration

[Ponder](https://ponder.sh) is a blazing-fast blockchain indexer that's ~10x faster than The Graph. We likely have an existing Ponder setup in the repository that needs to be configured for our BTC vault.

#### Tasks:
1. **Locate and Review Existing Ponder Setup**
   ```bash
   # Check for existing Ponder configuration
   find . -name "ponder*" -o -name "*indexer*"
   # Look in /examples or /indexer directories
   ```

2. **Update Ponder Configuration**
   ```typescript
   // ponder.config.ts
   export const config = {
     networks: [
       {
         name: "base-sepolia",
         chainId: 84532,
         rpcUrl: process.env.PONDER_RPC_URL_84532,
       },
     ],
     contracts: [
       {
         name: "BtcVaultToken",
         network: "base-sepolia",
         address: "0xfF09B2B0AfEe51E29941091C4dd6B635780BC34a",
         abi: "./abis/BtcVaultToken.json",
         startBlock: 123456, // Deployment block
       },
       {
         name: "BtcVaultStrategy",
         network: "base-sepolia",
         address: "0x0A039085Ca2AD68a3FC77A9C5191C22B309126F8",
         abi: "./abis/BtcVaultStrategy.json",
         startBlock: 123456,
       },
     ],
   };
   ```

3. **Create Event Handlers**
   ```typescript
   // src/BtcVaultToken.ts
   import { ponder } from "@/generated";
   
   ponder.on("BtcVaultToken:Deposit", async ({ event, context }) => {
     const { account, db } = context;
     
     await db.Deposit.create({
       id: event.log.id,
       data: {
         sender: event.params.sender,
         owner: event.params.owner,
         assets: event.params.assets,
         shares: event.params.shares,
         timestamp: event.block.timestamp,
         blockNumber: event.block.number,
         transactionHash: event.transaction.hash,
       },
     });
     
     // Update user balance
     await db.UserBalance.upsert({
       id: event.params.owner,
       create: {
         address: event.params.owner,
         shares: event.params.shares,
       },
       update: ({ current }) => ({
         shares: current.shares + event.params.shares,
       }),
     });
   });
   ```

4. **Database Schema for Ponder**
   ```typescript
   // ponder.schema.ts
   export const schema = {
     Deposit: {
       id: { type: "string", primaryKey: true },
       sender: { type: "string", index: true },
       owner: { type: "string", index: true },
       assets: { type: "bigint" },
       shares: { type: "bigint" },
       timestamp: { type: "bigint" },
       blockNumber: { type: "int" },
       transactionHash: { type: "string" },
     },
     Withdrawal: {
       // Similar structure
     },
     UserBalance: {
       id: { type: "string", primaryKey: true }, // user address
       address: { type: "string" },
       shares: { type: "bigint" },
       lastActivity: { type: "bigint" },
     },
     CollateralChange: {
       id: { type: "string", primaryKey: true },
       collateral: { type: "string" },
       action: { type: "string" }, // "added" or "removed"
       timestamp: { type: "bigint" },
     },
   };
   ```

5. **Connect Ponder to Our Database**
   - Configure Ponder to use same PostgreSQL as our app
   - Or set up sync mechanism between Ponder DB and app DB
   - Create API routes to query Ponder data

### 🎯 Part 2: Scheduled Jobs with Docker & Railway

#### Tasks:

1. **Create Scheduler Service**
   ```typescript
   // services/scheduler/index.ts
   import { CronJob } from 'cron';
   import { BlockchainService } from './blockchainService';
   import { PrismaClient } from '@prisma/client';
   
   const prisma = new PrismaClient();
   const blockchain = new BlockchainService(prisma);
   
   // Every 5 minutes - collect metrics
   new CronJob('*/5 * * * *', async () => {
     console.log('Collecting metrics...');
     try {
       const deployments = await prisma.sovaBtcDeployment.findMany({
         where: { status: 'ACTIVE' },
       });
       
       for (const deployment of deployments) {
         await blockchain.fetchRealMetrics(deployment.chainId, deployment.id);
       }
     } catch (error) {
       console.error('Metrics collection failed:', error);
     }
   }, null, true);
   
   // Every hour - sync collaterals
   new CronJob('0 * * * *', async () => {
     console.log('Syncing collaterals...');
     try {
       const deployments = await prisma.sovaBtcDeployment.findMany({
         where: { status: 'ACTIVE' },
       });
       
       for (const deployment of deployments) {
         await blockchain.syncCollateralsToDatabase(
           deployment.chainId, 
           deployment.id
         );
       }
     } catch (error) {
       console.error('Collateral sync failed:', error);
     }
   }, null, true);
   
   // Health check endpoint
   import express from 'express';
   const app = express();
   
   app.get('/health', (req, res) => {
     res.json({ status: 'healthy', timestamp: new Date() });
   });
   
   app.listen(3001, () => {
     console.log('Scheduler service running on port 3001');
   });
   ```

2. **Dockerize the Scheduler**
   ```dockerfile
   # Dockerfile.scheduler
   FROM node:20-alpine
   
   WORKDIR /app
   
   # Copy package files
   COPY package*.json ./
   COPY prisma ./prisma/
   
   # Install dependencies
   RUN npm ci --only=production
   RUN npx prisma generate
   
   # Copy source code
   COPY services/scheduler ./services/scheduler
   COPY lib/services ./lib/services
   
   # Set environment variables
   ENV NODE_ENV=production
   
   EXPOSE 3001
   
   CMD ["node", "services/scheduler/index.js"]
   ```

3. **Docker Compose for Local Development**
   ```yaml
   # docker-compose.yml
   version: '3.8'
   
   services:
     scheduler:
       build:
         context: ./frontend
         dockerfile: Dockerfile.scheduler
       environment:
         DATABASE_URL: ${DATABASE_URL}
         DIRECT_DATABASE_URL: ${DIRECT_DATABASE_URL}
         BASE_SEPOLIA_RPC_URL: ${BASE_SEPOLIA_RPC_URL}
       ports:
         - "3001:3001"
       restart: unless-stopped
       healthcheck:
         test: ["CMD", "curl", "-f", "http://localhost:3001/health"]
         interval: 30s
         timeout: 10s
         retries: 3
   
     ponder:
       build:
         context: ./indexer
         dockerfile: Dockerfile.ponder
       environment:
         DATABASE_URL: ${PONDER_DATABASE_URL}
         PONDER_RPC_URL_84532: ${BASE_SEPOLIA_RPC_URL}
       ports:
         - "42069:42069"
       restart: unless-stopped
   ```

4. **Railway Deployment Configuration**
   ```json
   // railway.json
   {
     "$schema": "https://railway.app/railway.schema.json",
     "build": {
       "builder": "DOCKERFILE",
       "dockerfilePath": "./frontend/Dockerfile.scheduler"
     },
     "deploy": {
       "numReplicas": 1,
       "healthcheckPath": "/health",
       "restartPolicyType": "ON_FAILURE",
       "restartPolicyMaxRetries": 3
     },
     "services": [
       {
         "name": "scheduler",
         "source": {
           "repo": "github.com/your-repo/fountfi-sovabtc"
         }
       }
     ]
   }
   ```

5. **Alternative: Vercel Cron Functions**
   ```typescript
   // app/api/cron/metrics/route.ts
   import { NextRequest } from 'next/server';
   import { headers } from 'next/headers';
   
   export async function GET(request: NextRequest) {
     // Verify the request is from Vercel Cron
     const authHeader = headers().get('authorization');
     if (authHeader !== `Bearer ${process.env.CRON_SECRET}`) {
       return new Response('Unauthorized', { status: 401 });
     }
     
     // Run metrics collection
     // ...
     
     return Response.json({ success: true });
   }
   ```
   
   ```json
   // vercel.json
   {
     "crons": [
       {
         "path": "/api/cron/metrics",
         "schedule": "*/5 * * * *"
       },
       {
         "path": "/api/cron/collaterals",
         "schedule": "0 * * * *"
       }
     ]
   }
   ```

## Implementation Plan

### Phase 1: Ponder Setup (Day 1 Morning)
1. Locate existing Ponder configuration
2. Update contracts and network settings
3. Create event handlers for deposits/withdrawals
4. Test indexing with historical data
5. Set up API to query indexed data

### Phase 2: Scheduler Development (Day 1 Afternoon)
1. Create scheduler service with cron jobs
2. Implement metrics collection job
3. Implement collateral sync job
4. Add error handling and retries
5. Create health check endpoint

### Phase 3: Containerization (Day 2 Morning)
1. Create Dockerfile for scheduler
2. Set up docker-compose for local testing
3. Test container builds and networking
4. Configure environment variables
5. Add logging and monitoring

### Phase 4: Deployment (Day 2 Afternoon)
1. Set up Railway project (or alternative)
2. Configure environment variables
3. Deploy scheduler service
4. Deploy Ponder indexer
5. Verify jobs are running
6. Monitor logs and metrics

## Success Criteria

1. ✅ Ponder indexer running and indexing events
2. ✅ Historical data backfilled from deployment block
3. ✅ Scheduler running with cron jobs
4. ✅ Metrics collected every 5 minutes automatically
5. ✅ Collaterals synced every hour automatically
6. ✅ Deployed to Railway/Vercel and running in production
7. ✅ Health checks passing
8. ✅ Logs accessible for debugging

## Testing Plan

1. **Ponder Testing**:
   - Verify events are indexed correctly
   - Check database for indexed data
   - Test API queries return correct data
   - Verify real-time indexing works

2. **Scheduler Testing**:
   - Test cron job triggers
   - Verify metrics are collected
   - Check error handling
   - Test health endpoint

3. **Integration Testing**:
   - Verify frontend can query indexed data
   - Check metrics update in UI
   - Test collateral sync updates admin panel
   - Monitor for memory leaks

## Environment Variables Needed

```env
# Ponder
PONDER_DATABASE_URL=postgresql://...
PONDER_RPC_URL_84532=https://base-sepolia.g.alchemy.com/v2/xxx

# Scheduler
DATABASE_URL=postgresql://...
DIRECT_DATABASE_URL=postgresql://...
BASE_SEPOLIA_RPC_URL=https://base-sepolia.g.alchemy.com/v2/xxx
ETHEREUM_RPC_URL=https://eth-mainnet.g.alchemy.com/v2/xxx

# Deployment
RAILWAY_TOKEN=xxx
CRON_SECRET=xxx
```

## References

- [Ponder Documentation](https://ponder.sh/docs)
- [Railway Documentation](https://docs.railway.app)
- [Vercel Cron Jobs](https://vercel.com/docs/cron-jobs)
- [Docker Best Practices](https://docs.docker.com/develop/dev-best-practices/)
- [Node.js Cron](https://github.com/node-cron/node-cron)

## Notes

### Why Ponder?
- 10x faster than The Graph
- Direct PostgreSQL integration
- TypeScript native with full type safety
- Real-time indexing with reorg handling
- No subgraph deployment needed

### Why Railway?
- Simple Docker deployment
- Built-in health checks
- Easy environment management
- Automatic SSL certificates
- Good pricing for cron jobs

### Alternative Options:
- **Render**: Similar to Railway with cron jobs
- **Fly.io**: More control, global deployment
- **AWS ECS**: Enterprise solution
- **Google Cloud Run**: Serverless containers

---

**Session Goal**: Set up automated blockchain data indexing with Ponder and scheduled metrics collection, transforming our system from manual triggers to fully automated data synchronization.