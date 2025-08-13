# Railway Deployment Guide for SovaBTC Backend Services

## Overview
This guide provides step-by-step instructions for deploying the Ponder indexer and Scheduler services to Railway.

## Project URL
https://railway.app/project/b5aaa9af-52dd-4dda-9126-befa6ff56509

## Step 1: Deploy Services via Railway Dashboard

Since Railway CLI has limitations in non-interactive mode, use the Railway dashboard to create and deploy services.

### 1.1 Create Ponder Indexer Service

1. Go to the Railway project dashboard
2. Click "New Service" → "GitHub Repo"
3. Select the repository: `fountfi-sovabtc`
4. Configure the service:
   - **Service Name**: `ponder-indexer`
   - **Root Directory**: `/frontend`
   - **Build Command**: Override with Docker
   - **Dockerfile Path**: `Dockerfile.indexer`
   - **Port**: `42069`

### 1.2 Create Scheduler Service

1. Click "New Service" → "GitHub Repo"
2. Select the repository: `fountfi-sovabtc`
3. Configure the service:
   - **Service Name**: `scheduler`
   - **Root Directory**: `/frontend`
   - **Build Command**: Override with Docker
   - **Dockerfile Path**: `Dockerfile.scheduler`
   - **Port**: `3001`

## Step 2: Configure Environment Variables

### For Ponder Indexer Service

```env
# Database
DATABASE_URL=postgresql://user:pass@host/db
PONDER_DATABASE_URL=postgresql://user:pass@host/db

# Network Configuration
NETWORK=baseSepolia
BASE_SEPOLIA_RPC_URL=https://base-sepolia.g.alchemy.com/v2/YOUR_KEY

# Contract Addresses
BASE_VAULT_TOKEN_ADDRESS=0xfF09B2B0AfEe51E29941091C4dd6B635780BC34a
BASE_VAULT_STRATEGY_ADDRESS=0x0A039085Ca2AD68a3FC77A9C5191C22B309126F8
BASE_START_BLOCK=19500000

# Service
NODE_ENV=production
PORT=42069
```

### For Scheduler Service

```env
# Database
DATABASE_URL=postgresql://user:pass@host/db
DIRECT_DATABASE_URL=postgresql://user:pass@host/db

# Network Configuration  
BASE_SEPOLIA_RPC_URL=https://base-sepolia.g.alchemy.com/v2/YOUR_KEY

# Contract Addresses
NEXT_PUBLIC_VAULT_ADDRESS=0xfF09B2B0AfEe51E29941091C4dd6B635780BC34a
NEXT_PUBLIC_STRATEGY_ADDRESS=0x0A039085Ca2AD68a3FC77A9C5191C22B309126F8

# Service Configuration
NODE_ENV=production
PORT=3001
CRON_ENABLED=true
SCHEDULER_PORT=3001

# Internal Service URLs (Railway provides these)
INDEXER_URL=https://ponder-indexer.up.railway.app
```

## Step 3: Database Configuration

Both services should use the same PostgreSQL database. You can either:

1. **Use Neon** (Recommended):
   - Get your database URL from Neon dashboard
   - Use the same URL for both services

2. **Use Railway PostgreSQL**:
   - Add PostgreSQL service in Railway
   - Reference it using Railway's internal variables

## Step 4: Deploy via GitHub Integration

1. Ensure your repository is connected to Railway
2. Push to the main branch to trigger deployments
3. Or manually trigger deployments from Railway dashboard

## Step 5: Verify Deployments

### Check Ponder Indexer
```bash
# Health check
curl https://ponder-indexer.up.railway.app/health

# GraphQL endpoint
curl https://ponder-indexer.up.railway.app/graphql

# Query example
curl -X POST https://ponder-indexer.up.railway.app/graphql \
  -H "Content-Type: application/json" \
  -d '{"query": "{ btc_deposits(limit: 5) { id sender assets timestamp } }"}'
```

### Check Scheduler
```bash
# Health check
curl https://scheduler.up.railway.app/health

# Status
curl https://scheduler.up.railway.app/status

# Manual trigger (development only)
curl -X POST https://scheduler.up.railway.app/manual/metrics
```

## Step 6: Monitor Services

1. **Railway Dashboard**:
   - View logs for each service
   - Monitor resource usage
   - Check deployment status

2. **Service Logs**:
   - Ponder Indexer: Check for indexing progress
   - Scheduler: Verify cron jobs are running

## Troubleshooting

### Build Failures
- Check Dockerfile paths are correct
- Verify all dependencies are included
- Review build logs in Railway dashboard

### Runtime Errors
- Check environment variables are set correctly
- Verify database connection strings
- Ensure RPC endpoints are accessible

### Health Check Failures
- Services may take 30-60 seconds to start
- Check logs for startup errors
- Verify ports are correctly configured

## Service URLs (After Deployment)

Update these after successful deployment:

- **Ponder Indexer**: `https://[service-name].up.railway.app`
- **Scheduler**: `https://[service-name].up.railway.app`
- **GraphQL Playground**: `https://[indexer-url]/graphql`

## Next Steps

1. Monitor services for 24-48 hours
2. Set up Railway alerts
3. Configure custom domains if needed
4. Document production endpoints
5. Prepare frontend for connection to these services