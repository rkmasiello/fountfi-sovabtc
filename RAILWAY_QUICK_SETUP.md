# Railway Quick Setup Guide 🚀

## Step-by-Step Configuration

### 📦 Service 1: Ponder Indexer

1. **Create Service**: New → GitHub Repo → `rkmasiello/fountfi-sovabtc` → branch `sovabtc-2`

2. **Settings Tab**:
   ```
   Service Name: ponder-indexer
   Root Directory: /frontend/indexer
   Dockerfile Path: ../Dockerfile.indexer
   Port: 42069
   Health Check Path: /health
   ```

3. **Variables Tab** (paste this block and update DATABASE_URL and RPC_URL):
   ```env
   DATABASE_URL=postgresql://[YOUR_NEON_URL]
   PONDER_DATABASE_URL=postgresql://[YOUR_NEON_URL]
   NETWORK=baseSepolia
   BASE_SEPOLIA_RPC_URL=https://base-sepolia.g.alchemy.com/v2/[YOUR_KEY]
   BASE_VAULT_TOKEN_ADDRESS=0xfF09B2B0AfEe51E29941091C4dd6B635780BC34a
   BASE_VAULT_STRATEGY_ADDRESS=0x0A039085Ca2AD68a3FC77A9C5191C22B309126F8
   BASE_START_BLOCK=19500000
   NODE_ENV=production
   PORT=42069
   ```

### 📦 Service 2: Scheduler

1. **Create Service**: New → GitHub Repo → `rkmasiello/fountfi-sovabtc` → branch `sovabtc-2`

2. **Settings Tab**:
   ```
   Service Name: scheduler
   Root Directory: /frontend
   Dockerfile Path: Dockerfile.scheduler
   Port: 3001
   Health Check Path: /health
   ```

3. **Variables Tab** (paste this block and update DATABASE_URL and RPC_URL):
   ```env
   DATABASE_URL=postgresql://[YOUR_NEON_URL]
   DIRECT_DATABASE_URL=postgresql://[YOUR_NEON_URL]
   BASE_SEPOLIA_RPC_URL=https://base-sepolia.g.alchemy.com/v2/[YOUR_KEY]
   NEXT_PUBLIC_VAULT_ADDRESS=0xfF09B2B0AfEe51E29941091C4dd6B635780BC34a
   NEXT_PUBLIC_STRATEGY_ADDRESS=0x0A039085Ca2AD68a3FC77A9C5191C22B309126F8
   NODE_ENV=production
   PORT=3001
   CRON_ENABLED=true
   SCHEDULER_PORT=3001
   ```

## ⚠️ Critical Settings

| Service | Root Directory | Dockerfile Path | Port |
|---------|---------------|-----------------|------|
| ponder-indexer | `/frontend/indexer` | `../Dockerfile.indexer` | 42069 |
| scheduler | `/frontend` | `Dockerfile.scheduler` | 3001 |

## ✅ Verification

After both services are deployed:

```bash
# Get your URLs from Railway dashboard, then test:

# Indexer health
curl https://[indexer-url].up.railway.app/health

# Scheduler health  
curl https://[scheduler-url].up.railway.app/health

# GraphQL playground
open https://[indexer-url].up.railway.app/graphql
```

## 🔄 Auto-Deploy

Both services will automatically redeploy when you:
- Push to `sovabtc-2` branch
- Merge PRs to `sovabtc-2`

## 📝 Notes

- Services communicate internally via: `http://[service-name].railway.internal:[port]`
- Public URLs will be shown in Settings → Networking
- Check build logs if deployment fails
- Both services share the same PostgreSQL database