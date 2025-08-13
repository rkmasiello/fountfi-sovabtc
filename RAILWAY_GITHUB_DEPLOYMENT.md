# Railway GitHub Deployment Guide

Now that GitHub is connected, follow these steps to deploy both backend services:

## Service 1: Ponder Indexer

### 1. Create Ponder Indexer Service

1. Go to Railway Dashboard: https://railway.app/project/b5aaa9af-52dd-4dda-9126-befa6ff56509
2. Click **"+ New"** → **"GitHub Repo"**
3. Select **`rkmasiello/fountfi-sovabtc`**
4. Choose branch: **`sovabtc-2`**

### 2. Configure Ponder Indexer Settings

Click on the deployed service, then go to **Settings** tab:

#### General Settings:
- **Service Name**: `ponder-indexer`
- **Root Directory**: `/frontend/indexer` (IMPORTANT: Set this!)
- **Watch Paths**: `/frontend/indexer/**`

#### Build & Deploy:
- **Builder**: Dockerfile
- **Dockerfile Path**: `../Dockerfile.indexer` (relative to root directory)
- **Start Command**: `npm start`

#### Networking:
- **Port**: `42069`
- **Health Check Path**: `/health`
- **Health Check Timeout**: `30`

### 3. Set Ponder Indexer Environment Variables

Go to **Variables** tab and add:

```env
# Database
DATABASE_URL=postgresql://[YOUR_NEON_DATABASE_URL]
PONDER_DATABASE_URL=postgresql://[YOUR_NEON_DATABASE_URL]

# Network Configuration
NETWORK=baseSepolia
BASE_SEPOLIA_RPC_URL=https://base-sepolia.g.alchemy.com/v2/[YOUR_ALCHEMY_KEY]

# Contract Addresses
BASE_VAULT_TOKEN_ADDRESS=0xfF09B2B0AfEe51E29941091C4dd6B635780BC34a
BASE_VAULT_STRATEGY_ADDRESS=0x0A039085Ca2AD68a3FC77A9C5191C22B309126F8
BASE_START_BLOCK=19500000

# Service Config
NODE_ENV=production
PORT=42069
```

---

## Service 2: Scheduler

### 1. Create Scheduler Service

1. In Railway Dashboard, click **"+ New"** → **"GitHub Repo"** 
2. Select **`rkmasiello/fountfi-sovabtc`** again
3. Choose branch: **`sovabtc-2`**

### 2. Configure Scheduler Settings

Click on the service, go to **Settings** tab:

#### General Settings:
- **Service Name**: `scheduler`  
- **Root Directory**: `/frontend` (IMPORTANT: Set this!)
- **Watch Paths**: `/frontend/services/scheduler/**`

#### Build & Deploy:
- **Builder**: Dockerfile
- **Dockerfile Path**: `Dockerfile.scheduler` (relative to root directory)
- **Start Command**: `node services/scheduler/dist/index.js`

#### Networking:
- **Port**: `3001`
- **Health Check Path**: `/health`
- **Health Check Timeout**: `10`

### 3. Set Scheduler Environment Variables

Go to **Variables** tab and add:

```env
# Database
DATABASE_URL=postgresql://[YOUR_NEON_DATABASE_URL]
DIRECT_DATABASE_URL=postgresql://[YOUR_NEON_DATABASE_URL]

# Network Configuration  
BASE_SEPOLIA_RPC_URL=https://base-sepolia.g.alchemy.com/v2/[YOUR_ALCHEMY_KEY]

# Contract Addresses
NEXT_PUBLIC_VAULT_ADDRESS=0xfF09B2B0AfEe51E29941091C4dd6B635780BC34a
NEXT_PUBLIC_STRATEGY_ADDRESS=0x0A039085Ca2AD68a3FC77A9C5191C22B309126F8

# Service Config
NODE_ENV=production
PORT=3001
CRON_ENABLED=true
SCHEDULER_PORT=3001

# Internal Service URL (after indexer is deployed)
INDEXER_URL=https://ponder-indexer.up.railway.app
INDEXER_INTERNAL_URL=http://ponder-indexer.railway.internal:42069
```

---

## Important Configuration Notes

### Root Directory Settings:
- **Ponder Indexer**: `/frontend/indexer`
- **Scheduler**: `/frontend`

This is crucial because our Dockerfiles expect to be run from these directories.

### Auto-Deploy Settings:
Both services will automatically redeploy when you push to the `sovabtc-2` branch.

### Internal Networking:
Railway services can communicate internally using:
- Pattern: `http://[service-name].railway.internal:[port]`
- Example: `http://ponder-indexer.railway.internal:42069`

---

## Verification Steps

### 1. Check Build Logs
After configuration, each service will build. Check logs for any errors.

### 2. Get Public URLs
Once deployed, Railway will assign public URLs. Find them in Settings → Networking → Public Domain.

They'll look like:
- `ponder-indexer-production-xxxx.up.railway.app`
- `scheduler-production-xxxx.up.railway.app`

### 3. Test Health Endpoints

```bash
# Test Ponder Indexer
curl https://[indexer-url].up.railway.app/health

# Test GraphQL
curl https://[indexer-url].up.railway.app/graphql

# Test Scheduler
curl https://[scheduler-url].up.railway.app/health

# Check status
curl https://[scheduler-url].up.railway.app/status
```

---

## Troubleshooting

### If build fails:

1. **Check Dockerfile paths** - Make sure they're relative to the root directory
2. **Check logs** - Look for missing dependencies or build errors
3. **Verify root directory** - Must be set correctly for each service

### If service doesn't start:

1. **Check environment variables** - Especially DATABASE_URL and RPC_URL
2. **Check port configuration** - Must match what's in the code
3. **Check health check path** - Should be `/health`

### If services can't communicate:

1. **Use internal URLs** for service-to-service communication
2. **Format**: `http://[service-name].railway.internal:[port]`
3. **Don't use HTTPS** for internal communication

---

## Complete Environment Variables Template

Copy this and update with your actual values:

### For Ponder Indexer:
```env
DATABASE_URL=postgresql://neondb_owner:YOUR_PASSWORD@ep-YOUR-ENDPOINT.us-east-2.aws.neon.tech/neondb?sslmode=require
PONDER_DATABASE_URL=postgresql://neondb_owner:YOUR_PASSWORD@ep-YOUR-ENDPOINT.us-east-2.aws.neon.tech/neondb?sslmode=require
NETWORK=baseSepolia
BASE_SEPOLIA_RPC_URL=https://base-sepolia.g.alchemy.com/v2/YOUR_ALCHEMY_KEY
BASE_VAULT_TOKEN_ADDRESS=0xfF09B2B0AfEe51E29941091C4dd6B635780BC34a
BASE_VAULT_STRATEGY_ADDRESS=0x0A039085Ca2AD68a3FC77A9C5191C22B309126F8
BASE_START_BLOCK=19500000
NODE_ENV=production
PORT=42069
```

### For Scheduler:
```env
DATABASE_URL=postgresql://neondb_owner:YOUR_PASSWORD@ep-YOUR-ENDPOINT.us-east-2.aws.neon.tech/neondb?sslmode=require
DIRECT_DATABASE_URL=postgresql://neondb_owner:YOUR_PASSWORD@ep-YOUR-ENDPOINT.us-east-2.aws.neon.tech/neondb?sslmode=require
BASE_SEPOLIA_RPC_URL=https://base-sepolia.g.alchemy.com/v2/YOUR_ALCHEMY_KEY
NEXT_PUBLIC_VAULT_ADDRESS=0xfF09B2B0AfEe51E29941091C4dd6B635780BC34a
NEXT_PUBLIC_STRATEGY_ADDRESS=0x0A039085Ca2AD68a3FC77A9C5191C22B309126F8
NODE_ENV=production
PORT=3001
CRON_ENABLED=true
SCHEDULER_PORT=3001
INDEXER_URL=https://[your-indexer-url].up.railway.app
INDEXER_INTERNAL_URL=http://ponder-indexer.railway.internal:42069
```

---

## Success Checklist

- [ ] Ponder Indexer service created from GitHub
- [ ] Ponder Indexer root directory set to `/frontend/indexer`
- [ ] Ponder Indexer environment variables configured
- [ ] Ponder Indexer builds successfully
- [ ] Ponder Indexer health check passes
- [ ] Scheduler service created from GitHub  
- [ ] Scheduler root directory set to `/frontend`
- [ ] Scheduler environment variables configured
- [ ] Scheduler builds successfully
- [ ] Scheduler health check passes
- [ ] Both services have public URLs
- [ ] GraphQL endpoint accessible
- [ ] Cron jobs running (check scheduler logs)