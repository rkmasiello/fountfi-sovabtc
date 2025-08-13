# Session 34: Deploy Backend Services to Railway Production

## Context
We have successfully completed:
- ✅ Ponder indexer configuration for BTC vault contracts (Session 33)
- ✅ Event handlers for all vault operations
- ✅ Scheduler service with automated cron jobs
- ✅ Docker containerization for both services
- ✅ Comprehensive documentation and README

## Deployment Strategy
- **Railway**: All backend services (Ponder indexer, Scheduler, Database if needed)
- **Vercel**: Frontend deployment (future session)
- **Focus**: Backend services only for this session

## Current Status

### What's Ready:
1. **Ponder Indexer** (`frontend/indexer/`)
   - Configured for BtcVaultToken and BtcVaultStrategy
   - Event handlers for deposits, withdrawals, collaterals
   - Database schema with 10 tables
   - Docker container ready

2. **Scheduler Service** (`frontend/services/scheduler/`)
   - Cron jobs for metrics and collateral sync
   - Health monitoring endpoints
   - Docker container ready

3. **Deployment Files**:
   - `Dockerfile.indexer` and `Dockerfile.scheduler`
   - `docker-compose.yml` for local testing
   - `railway.json` configuration

## Railway Project Setup
- **Project ID**: `b5aaa9af-52dd-4dda-9126-befa6ff56509`
- **Access**: `railway link -p b5aaa9af-52dd-4dda-9126-befa6ff56509`
- **Status**: Blank project ready for deployment

## Session 34 Objectives

### 🎯 Goal 1: Deploy Both Backend Services to Railway

We will deploy both the Ponder indexer and Scheduler service to Railway as separate services within the same project. This keeps all backend infrastructure in one place.

#### Step 1: Prepare Railway Deployment
```bash
# Link to Railway project
railway link -p b5aaa9af-52dd-4dda-9126-befa6ff56509

# Check current status
railway status
railway variables
```

#### Step 2: Configure Environment Variables
Set up the following in Railway dashboard or CLI:

```env
# Database Configuration
DATABASE_URL=postgresql://... # Your Neon PostgreSQL URL
PONDER_DATABASE_URL=postgresql://... # Can be same as DATABASE_URL

# Network Configuration
NETWORK=baseSepolia
BASE_SEPOLIA_RPC_URL=https://base-sepolia.g.alchemy.com/v2/YOUR_KEY

# Contract Addresses (Base Sepolia)
BASE_VAULT_TOKEN_ADDRESS=0xfF09B2B0AfEe51E29941091C4dd6B635780BC34a
BASE_VAULT_STRATEGY_ADDRESS=0x0A039085Ca2AD68a3FC77A9C5191C22B309126F8
BASE_START_BLOCK=19500000

# Service Configuration
NODE_ENV=production
PORT=42069
```

#### Step 3: Deploy Services to Railway

##### Service 1: Ponder Indexer
```bash
# Create and deploy indexer service
railway service create ponder-indexer
railway up -d -s ponder-indexer -f frontend/Dockerfile.indexer

# Or deploy from directory
cd frontend/indexer
railway up -d -s ponder-indexer
```

##### Service 2: Scheduler
```bash
# Create and deploy scheduler service
railway service create scheduler
railway up -d -s scheduler -f frontend/Dockerfile.scheduler

# Set scheduler-specific variables
railway variables set SCHEDULER_PORT=3001 -s scheduler
railway variables set CRON_ENABLED=true -s scheduler
```

#### Step 4: Verify Deployments

##### Check Ponder Indexer:
```bash
# View logs
railway logs -s ponder-indexer

# Test health endpoint
curl https://ponder-indexer.railway.app/health

# Query indexed data
curl -X POST https://ponder-indexer.railway.app/graphql \
  -H "Content-Type: application/json" \
  -d '{"query": "{ btc_deposits(limit: 5) { id sender assets timestamp } }"}'
```

##### Check Scheduler:
```bash
# View logs
railway logs -s scheduler

# Test health endpoint
curl https://scheduler.railway.app/health

# Check status
curl https://scheduler.railway.app/status
```

### 🎯 Goal 2: Configure Inter-Service Communication

Since both services will be in Railway, they need to communicate:

#### Database Sharing
Both services should use the same PostgreSQL database:
```bash
# Set shared database URL for both services
railway variables set DATABASE_URL="$DATABASE_URL" -s ponder-indexer
railway variables set DATABASE_URL="$DATABASE_URL" -s scheduler
```

#### Internal Networking
Railway provides internal networking between services:
```bash
# Scheduler can access indexer via internal URL
INDEXER_INTERNAL_URL=http://ponder-indexer.railway.internal:42069
```

### 🎯 Goal 3: Testing & Monitoring

#### 1. Test Indexer Functionality
- Verify event indexing is working
- Check database for indexed events
- Test GraphQL queries
- Monitor for missed blocks

#### 2. Test Scheduler Jobs
- Verify metrics collection runs
- Check collateral sync works
- Confirm daily summaries generate
- Monitor health endpoints

#### 3. Set Up Railway Monitoring
- Configure health checks in Railway dashboard
- Set up alerts for failures
- Monitor resource usage graphs
- Track deployment metrics

## Troubleshooting Guide

### Common Issues & Solutions

#### Issue: Railway deployment fails
```bash
# Check build logs
railway logs --build

# Verify Dockerfile syntax
docker build -f frontend/Dockerfile.indexer .

# Test locally first
docker-compose up indexer
```

#### Issue: Database connection errors
```bash
# Test connection from Railway
railway run node -e "console.log(process.env.DATABASE_URL)"

# Verify PostgreSQL SSL settings
# Add ?sslmode=require to connection string
```

#### Issue: RPC rate limiting
```bash
# Reduce indexing speed
# Update ponder.config.ts:
maxBlockRange: 100  # Reduce from 1000
pollingInterval: 30000  # Increase from 12000
```

#### Issue: Memory/CPU limits
```bash
# Scale up Railway resources
railway scale --min-instances 1 --max-instances 3
```

## Success Criteria

✅ **Both Services Deployed on Railway**:
- Ponder indexer service running
- Scheduler service running
- Both services healthy in Railway dashboard
- Internal networking configured

✅ **Indexer Working**:
- GraphQL endpoint accessible
- Events being indexed in real-time
- Historical data backfilled
- No missed blocks

✅ **Scheduler Working**:
- Cron jobs executing on schedule
- Metrics collected every 5 minutes
- Collaterals syncing every hour
- Health checks passing

✅ **Monitoring Active**:
- Railway dashboard shows both services
- Logs accessible for debugging
- Resource usage within limits
- Alerts configured for failures

## Testing Checklist

### Pre-Deployment
- [ ] Test Docker build locally
- [ ] Verify environment variables
- [ ] Check database connection
- [ ] Test RPC endpoint access

### Post-Deployment
- [ ] Indexer health check passes
- [ ] GraphQL queries return data
- [ ] New events are indexed
- [ ] Scheduler jobs trigger
- [ ] Metrics are collected
- [ ] No errors in logs

### Production Validation
- [ ] Monitor for 24 hours
- [ ] Check data consistency
- [ ] Verify no memory leaks
- [ ] Confirm reorg handling works

## Railway-Specific Configuration

### Service Architecture in Railway
```
Railway Project (b5aaa9af-52dd-4dda-9126-befa6ff56509)
├── ponder-indexer (Service 1)
│   ├── Port: 42069
│   ├── GraphQL endpoint
│   └── Event processing
├── scheduler (Service 2)
│   ├── Port: 3001
│   ├── Cron jobs
│   └── Health monitoring
└── Shared PostgreSQL Database
    └── Used by both services
```

### Railway CLI Commands Reference
```bash
# Service management
railway service list
railway service create <name>
railway service delete <name>

# Deployment
railway up -s <service-name>
railway deploy -s <service-name>

# Variables
railway variables -s <service-name>
railway variables set KEY=value -s <service-name>

# Logs and monitoring
railway logs -s <service-name>
railway status
```

## Documentation to Update

After successful deployment:
1. Update README with production URLs
2. Add monitoring dashboard links
3. Document any configuration changes
4. Create runbook for operations

## Next Steps After Deployment

Once both backend services are running on Railway:
1. Monitor services for 24-48 hours for stability
2. Optimize resource allocation based on usage
3. Set up Railway alerts and notifications
4. Document production URLs and endpoints
5. Prepare for frontend deployment to Vercel (future session)

### Future Frontend Integration (Not this session)
- Frontend will be deployed to Vercel
- Frontend will connect to Railway backend services via public URLs
- Environment variables will point to Railway service endpoints

---

**Session Goal**: Deploy both backend services (Ponder indexer and Scheduler) to Railway production, establishing a robust backend infrastructure for automated blockchain data indexing and metrics collection. Frontend deployment to Vercel will be handled in a future session.