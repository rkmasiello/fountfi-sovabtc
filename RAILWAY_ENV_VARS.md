# Railway Environment Variables Configuration

## Service ID
Your deployed service ID: `f0747ec5-3ae4-49d2-b98c-8420850fe7a9`

## How to Set Environment Variables

1. Go to Railway Dashboard: https://railway.app/project/b5aaa9af-52dd-4dda-9126-befa6ff56509/service/f0747ec5-3ae4-49d2-b98c-8420850fe7a9

2. Click on the **Variables** tab

3. Add the following environment variables:

## Required Environment Variables

### Database Configuration
```
DATABASE_URL=postgresql://[your-neon-db-url]
DIRECT_DATABASE_URL=postgresql://[your-neon-db-url]
```

### Network Configuration  
```
BASE_SEPOLIA_RPC_URL=https://base-sepolia.g.alchemy.com/v2/[YOUR_ALCHEMY_KEY]
NETWORK=baseSepolia
```

### Contract Addresses (Base Sepolia)
```
BASE_VAULT_TOKEN_ADDRESS=0xfF09B2B0AfEe51E29941091C4dd6B635780BC34a
BASE_VAULT_STRATEGY_ADDRESS=0x0A039085Ca2AD68a3FC77A9C5191C22B309126F8
NEXT_PUBLIC_VAULT_ADDRESS=0xfF09B2B0AfEe51E29941091C4dd6B635780BC34a
NEXT_PUBLIC_STRATEGY_ADDRESS=0x0A039085Ca2AD68a3FC77A9C5191C22B309126F8
```

### Service Configuration
```
NODE_ENV=production
PORT=3000
```

### For Ponder Indexer (if deploying indexer)
```
PONDER_DATABASE_URL=[same as DATABASE_URL]
BASE_START_BLOCK=19500000
INDEXER_PORT=42069
```

### For Scheduler (if deploying scheduler)
```
CRON_ENABLED=true
SCHEDULER_PORT=3001
```

## Quick Copy-Paste Template

Copy this block and update the placeholders:

```
DATABASE_URL=postgresql://neondb_owner:YOUR_PASSWORD@ep-YOUR-ENDPOINT.us-east-2.aws.neon.tech/neondb?sslmode=require
DIRECT_DATABASE_URL=postgresql://neondb_owner:YOUR_PASSWORD@ep-YOUR-ENDPOINT.us-east-2.aws.neon.tech/neondb?sslmode=require
BASE_SEPOLIA_RPC_URL=https://base-sepolia.g.alchemy.com/v2/YOUR_ALCHEMY_KEY
NETWORK=baseSepolia
BASE_VAULT_TOKEN_ADDRESS=0xfF09B2B0AfEe51E29941091C4dd6B635780BC34a
BASE_VAULT_STRATEGY_ADDRESS=0x0A039085Ca2AD68a3FC77A9C5191C22B309126F8
NEXT_PUBLIC_VAULT_ADDRESS=0xfF09B2B0AfEe51E29941091C4dd6B635780BC34a
NEXT_PUBLIC_STRATEGY_ADDRESS=0x0A039085Ca2AD68a3FC77A9C5191C22B309126F8
NODE_ENV=production
PORT=3000
PONDER_DATABASE_URL=postgresql://neondb_owner:YOUR_PASSWORD@ep-YOUR-ENDPOINT.us-east-2.aws.neon.tech/neondb?sslmode=require
BASE_START_BLOCK=19500000
CRON_ENABLED=true
SCHEDULER_PORT=3001
```

## After Setting Variables

1. The deployment should restart automatically
2. Check the build logs in the Railway dashboard
3. Once deployed, check the service URL in the Settings tab
4. Test the health endpoint: `https://[your-service].up.railway.app/health`

## Deployment URLs
Once deployed, your services will be available at:
- Service URL will be shown in Railway dashboard under Settings → Domains
- Add a custom domain if needed