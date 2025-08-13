# Ponder Indexer & Scheduler Services

## Overview

This directory contains two critical services for the SovaBTC vault system:

1. **Ponder Indexer** - Indexes blockchain events in real-time
2. **Scheduler Service** - Runs automated cron jobs for metrics collection

## Architecture

```
frontend/
├── indexer/                 # Ponder blockchain indexer
│   ├── ponder.config.ts    # Network and contract configuration
│   ├── ponder.schema.ts    # Database schema for indexed data
│   └── src/                # Event handlers
│       ├── BtcVaultToken.ts    # ERC4626 events
│       └── BtcVaultStrategy.ts # Strategy-specific events
├── services/
│   └── scheduler/          # Cron job scheduler
│       └── src/
│           ├── index.ts           # Main scheduler with cron jobs
│           └── blockchainService.ts # Blockchain data fetching
├── app/api/cron/          # Vercel cron endpoints (alternative)
│   ├── metrics/           # Metrics collection endpoint
│   ├── collaterals/       # Collateral sync endpoint
│   └── daily-summary/     # Daily summary generation
├── docker-compose.yml     # Local development setup
├── Dockerfile.indexer     # Ponder container
└── Dockerfile.scheduler   # Scheduler container
```

## Services

### 1. Ponder Indexer

Ponder is a blazing-fast blockchain indexer that's ~10x faster than The Graph.

**Features:**
- Real-time event indexing
- Automatic reorg handling
- PostgreSQL storage
- GraphQL API for queries
- Type-safe event handlers

**Events Indexed:**
- `Deposit` - Track user deposits
- `Withdraw` - Track withdrawals
- `Transfer` - Monitor share transfers
- `CollateralDeposited` - Track collateral deposits
- `CollateralAdded/Removed` - Configuration changes
- `LiquidityAdded/Removed` - Liquidity management
- `WithdrawalApproved` - Managed withdrawals

### 2. Scheduler Service

Automated cron jobs for data synchronization and metrics collection.

**Jobs:**
- **Metrics Collection** (every 5 minutes)
  - Fetch TVL, share price, utilization
  - Update network metrics
  - Store historical data
  
- **Collateral Sync** (every hour)
  - Sync supported collaterals from chain
  - Update collateral configuration
  - Mark inactive collaterals

- **Daily Summary** (once daily)
  - Aggregate daily metrics
  - Generate activity reports
  - Store summary for analytics

## Deployment Options

### Option 1: Docker Compose (Local Development)

```bash
# Start all services
docker-compose up -d

# View logs
docker-compose logs -f scheduler
docker-compose logs -f indexer

# Stop services
docker-compose down
```

**URLs:**
- Scheduler Health: http://localhost:3001/health
- Scheduler Status: http://localhost:3001/status
- Ponder GraphQL: http://localhost:42069
- Frontend: http://localhost:3000

### Option 2: Railway (Production)

Railway provides simple Docker deployment with built-in health checks.

```bash
# Install Railway CLI
npm install -g @railway/cli

# Login to Railway
railway login

# Create new project
railway init

# Deploy services
railway up

# View logs
railway logs
```

**Configuration:**
1. Add environment variables in Railway dashboard
2. Services will auto-deploy on git push
3. Health checks ensure high availability

### Option 3: Vercel Cron (Serverless)

For simpler deployments, use Vercel's built-in cron jobs.

**Setup:**
1. Deploy frontend to Vercel
2. Set `CRON_SECRET` environment variable
3. Cron jobs run automatically per `vercel.json`

**Endpoints:**
- `/api/cron/metrics` - Runs every 5 minutes
- `/api/cron/collaterals` - Runs every hour
- `/api/cron/daily-summary` - Runs daily at midnight

## Environment Variables

### Required for All Services

```env
# Database
DATABASE_URL=postgresql://user:pass@host:5432/dbname
DIRECT_DATABASE_URL=postgresql://user:pass@host:5432/dbname

# RPC URLs
BASE_SEPOLIA_RPC_URL=https://sepolia.base.org
BASE_RPC_URL=https://mainnet.base.org
ETHEREUM_RPC_URL=https://eth.llamarpc.com
```

### Ponder Specific

```env
# Network to index
NETWORK=baseSepolia  # or "base" for mainnet

# Optional: Separate database for Ponder
PONDER_DATABASE_URL=postgresql://...

# Contract addresses (for mainnet)
BASE_VAULT_TOKEN_ADDRESS=0x...
BASE_VAULT_STRATEGY_ADDRESS=0x...
BASE_START_BLOCK=123456
```

### Scheduler Specific

```env
# Port for health checks
SCHEDULER_PORT=3001

# Node environment
NODE_ENV=production
```

### Vercel Cron Specific

```env
# Secret for authenticating cron requests
CRON_SECRET=your-secret-here
```

## Local Development

### Install Dependencies

```bash
# Install indexer dependencies
cd frontend/indexer
npm install

# Install scheduler dependencies
cd ../services/scheduler
npm install
```

### Run Services Locally

```bash
# Terminal 1: Run Ponder indexer
cd frontend/indexer
npm run dev

# Terminal 2: Run scheduler
cd frontend/services/scheduler
npm run dev

# Terminal 3: Run frontend
cd frontend
npm run dev
```

### Manual Testing

**Trigger scheduler jobs manually (dev mode only):**

```bash
# Trigger metrics collection
curl -X POST http://localhost:3001/trigger/metrics

# Trigger collateral sync
curl -X POST http://localhost:3001/trigger/collaterals

# Check scheduler status
curl http://localhost:3001/status
```

**Query Ponder GraphQL:**

```graphql
# Example query
query {
  deposits(limit: 10, orderBy: "timestamp", orderDirection: "desc") {
    id
    sender
    owner
    assets
    shares
    timestamp
    txHash
  }
}
```

## Monitoring

### Health Checks

All services expose health endpoints:
- Scheduler: `GET /health`
- Ponder: `GET /health`
- Frontend: `GET /api/health`

### Metrics

Monitor these key metrics:
- Job success/failure rates
- Indexing lag (blocks behind)
- Database query performance
- Memory usage
- API response times

### Logging

All services use structured logging:
```
[Service] [Level] Message {metadata}
```

Example:
```
[Metrics] Starting metrics collection...
[Metrics] Found 2 active deployments
[Metrics] Collecting metrics for Base Sepolia
[Metrics] Metrics collection completed successfully
```

## Troubleshooting

### Ponder Issues

**Problem: Indexer falling behind**
- Solution: Increase `maxBlockRange` in config
- Check RPC rate limits

**Problem: Database connection errors**
- Solution: Check `DATABASE_URL` format
- Ensure PostgreSQL is running
- Check connection pool settings

### Scheduler Issues

**Problem: Cron jobs not running**
- Solution: Check cron syntax
- Verify timezone settings
- Check process health

**Problem: Metrics collection failing**
- Solution: Verify RPC URLs
- Check contract addresses
- Ensure sufficient RPC credits

### Docker Issues

**Problem: Containers won't start**
- Solution: Check port conflicts
- Verify environment variables
- Review container logs

## Database Schema

### Ponder Tables (Indexed Events)
- `btc_users` - User balances and activity
- `btc_deposits` - Deposit transactions
- `btc_withdrawals` - Withdrawal transactions
- `btc_collateral_deposits` - Collateral-specific deposits
- `btc_managed_withdrawals` - Approval tracking
- `btc_collateral_changes` - Configuration changes
- `btc_liquidity_events` - Liquidity management
- `btc_vault_snapshots` - Periodic state snapshots
- `btc_daily_metrics` - Aggregated daily data

### Application Tables (Managed by Prisma)
- `sovabtc_deployments` - Contract deployments
- `sovabtc_collaterals` - Collateral configurations
- `sovabtc_deployment_metrics` - TVL and APY metrics
- `sovabtc_network_metrics` - Network health
- `sovabtc_activities` - Activity logs

## Performance Optimization

### Ponder
- Use appropriate `maxBlockRange` for network
- Enable database connection pooling
- Consider separate read replicas for queries

### Scheduler
- Stagger cron job execution times
- Implement retry logic with exponential backoff
- Use batch operations where possible

### Database
- Add indexes on frequently queried columns
- Use materialized views for complex aggregations
- Regular VACUUM and ANALYZE operations

## Security Considerations

1. **Environment Variables**: Never commit secrets to git
2. **RPC URLs**: Use private endpoints with authentication
3. **Database**: Use SSL connections in production
4. **API Authentication**: Verify cron job requests
5. **Rate Limiting**: Implement on all public endpoints
6. **Input Validation**: Sanitize all user inputs
7. **Error Handling**: Don't expose sensitive errors

## Support

For issues or questions:
1. Check logs for error messages
2. Review environment variables
3. Verify network connectivity
4. Consult documentation links below

## References

- [Ponder Documentation](https://ponder.sh/docs)
- [Railway Documentation](https://docs.railway.app)
- [Vercel Cron Jobs](https://vercel.com/docs/cron-jobs)
- [Docker Documentation](https://docs.docker.com)
- [Prisma Documentation](https://www.prisma.io/docs)