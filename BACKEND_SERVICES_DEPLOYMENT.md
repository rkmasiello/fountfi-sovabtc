# Backend Services Deployment Documentation

## Overview
This document provides complete instructions for deploying the SovaBTC backend services (Ponder Indexer and Scheduler) to Railway.

## Railway Project
- **Project Name**: perfect-beauty
- **Project ID**: b5aaa9af-52dd-4dda-9126-befa6ff56509
- **Dashboard URL**: https://railway.app/project/b5aaa9af-52dd-4dda-9126-befa6ff56509

## Services Architecture

```
Railway Project (perfect-beauty)
├── ponder-indexer
│   ├── GraphQL API (port 42069)
│   ├── Event indexing from blockchain
│   └── Database: PostgreSQL (shared)
└── scheduler
    ├── REST API (port 3001)
    ├── Cron jobs for metrics
    └── Database: PostgreSQL (shared)
```

## Deployment Files Created

1. **Dockerfiles** (root-relative paths):
   - `frontend/Dockerfile.indexer.root` - For Ponder indexer
   - `frontend/Dockerfile.scheduler.root` - For Scheduler service

2. **Configuration Files**:
   - `railway.services.json` - Service configuration
   - `frontend/.env.railway.example` - Environment variables template
   - `RAILWAY_DEPLOYMENT_GUIDE.md` - Step-by-step guide

## Manual Deployment Steps (Railway Dashboard)

### Step 1: Create Ponder Indexer Service

1. Go to [Railway Dashboard](https://railway.app/project/b5aaa9af-52dd-4dda-9126-befa6ff56509)
2. Click **"+ New"** → **"GitHub Repo"**
3. Select repository: `fountfi-sovabtc`
4. Configure:
   - **Service Name**: `ponder-indexer`
   - **Branch**: `sovabtc-2` (or your current branch)
   - **Root Directory**: Leave empty (repo root)
   - **Dockerfile Path**: `frontend/Dockerfile.indexer.root`

### Step 2: Create Scheduler Service

1. Click **"+ New"** → **"GitHub Repo"**
2. Select repository: `fountfi-sovabtc`
3. Configure:
   - **Service Name**: `scheduler`
   - **Branch**: `sovabtc-2` (or your current branch)
   - **Root Directory**: Leave empty (repo root)
   - **Dockerfile Path**: `frontend/Dockerfile.scheduler.root`

### Step 3: Configure Environment Variables

#### For Ponder Indexer:
Navigate to the service settings and add these variables:

```env
DATABASE_URL=[Your Neon PostgreSQL URL]
PONDER_DATABASE_URL=[Same as DATABASE_URL]
NETWORK=baseSepolia
BASE_SEPOLIA_RPC_URL=[Your Alchemy/Infura RPC URL]
BASE_VAULT_TOKEN_ADDRESS=0xfF09B2B0AfEe51E29941091C4dd6B635780BC34a
BASE_VAULT_STRATEGY_ADDRESS=0x0A039085Ca2AD68a3FC77A9C5191C22B309126F8
BASE_START_BLOCK=19500000
NODE_ENV=production
PORT=42069
```

#### For Scheduler:
Navigate to the service settings and add these variables:

```env
DATABASE_URL=[Your Neon PostgreSQL URL]
DIRECT_DATABASE_URL=[Same as DATABASE_URL]
BASE_SEPOLIA_RPC_URL=[Your Alchemy/Infura RPC URL]
NEXT_PUBLIC_VAULT_ADDRESS=0xfF09B2B0AfEe51E29941091C4dd6B635780BC34a
NEXT_PUBLIC_STRATEGY_ADDRESS=0x0A039085Ca2AD68a3FC77A9C5191C22B309126F8
NODE_ENV=production
PORT=3001
CRON_ENABLED=true
SCHEDULER_PORT=3001
```

### Step 4: Deploy Services

1. After configuration, Railway will automatically build and deploy
2. Monitor the build logs for any errors
3. Services will be available at:
   - Ponder Indexer: `https://[service-name].up.railway.app`
   - Scheduler: `https://[service-name].up.railway.app`

## Verification Steps

### 1. Check Ponder Indexer
```bash
# Health check
curl https://ponder-indexer-production.up.railway.app/health

# GraphQL playground
open https://ponder-indexer-production.up.railway.app/graphql

# Test query
curl -X POST https://ponder-indexer-production.up.railway.app/graphql \
  -H "Content-Type: application/json" \
  -d '{"query": "{ btc_deposits(limit: 5) { id sender assets timestamp } }"}'
```

### 2. Check Scheduler
```bash
# Health check
curl https://scheduler-production.up.railway.app/health

# Status endpoint
curl https://scheduler-production.up.railway.app/status

# View last metrics collection
curl https://scheduler-production.up.railway.app/metrics/latest
```

## Monitoring

### Railway Dashboard
- View logs: Click on service → "Logs" tab
- Monitor metrics: Click on service → "Metrics" tab
- Check deployments: Click on service → "Deployments" tab

### Service Health
- Both services have health check endpoints at `/health`
- Railway will automatically restart services if health checks fail
- Configure alerts in Railway settings

## Troubleshooting

### Common Issues

1. **Build Failures**
   - Check Dockerfile paths are correct
   - Verify all dependencies in package.json
   - Review build logs for specific errors

2. **Database Connection Errors**
   - Verify DATABASE_URL is correct
   - Add `?sslmode=require` to PostgreSQL URL
   - Check Neon dashboard for connection limits

3. **RPC Rate Limiting**
   - Reduce indexing speed in ponder.config.ts
   - Use a paid RPC plan for production
   - Implement request caching

4. **Memory Issues**
   - Scale up Railway instances
   - Optimize batch sizes in indexer
   - Monitor memory usage in Railway metrics

## Production Checklist

- [ ] Environment variables configured for both services
- [ ] Database connection verified
- [ ] RPC endpoint working with sufficient rate limits
- [ ] Health checks passing
- [ ] Logs showing successful startup
- [ ] GraphQL endpoint accessible
- [ ] Scheduler cron jobs running
- [ ] Monitoring alerts configured
- [ ] Custom domains configured (optional)
- [ ] Backup strategy in place

## Service URLs (Update After Deployment)

Once deployed, update these URLs:

```javascript
// Production Service URLs
export const SERVICES = {
  INDEXER: 'https://ponder-indexer-production.up.railway.app',
  SCHEDULER: 'https://scheduler-production.up.railway.app',
  GRAPHQL: 'https://ponder-indexer-production.up.railway.app/graphql'
};
```

## Next Steps

1. **Monitor for 24-48 hours** to ensure stability
2. **Set up alerts** in Railway for service failures
3. **Configure custom domains** if needed
4. **Update frontend** environment variables to use production URLs
5. **Document any issues** encountered during deployment

## Support

- Railway Documentation: https://docs.railway.app
- Railway Discord: https://discord.gg/railway
- Project Repository: https://github.com/fountfi/fountfi-sovabtc