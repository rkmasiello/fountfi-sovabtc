# Session 35: Fix Docker Builds and Test Locally Before Railway Deployment

## Context
Session 34 attempted to deploy both backend services (Ponder indexer and Scheduler) to Railway, but both failed with build errors. We need to step back and ensure everything works locally before attempting cloud deployment again.

## Current Situation

### What We Have:
1. **Ponder Indexer** (`frontend/indexer/`)
   - Complete event handlers for BTC vault
   - GraphQL API configuration
   - `Dockerfile.indexer` created but untested

2. **Scheduler Service** (`frontend/services/scheduler/`)
   - Cron jobs for metrics and collateral sync
   - TypeScript build configuration
   - `Dockerfile.scheduler` with multi-stage build

3. **Railway Configuration**:
   - GitHub connected to Railway
   - railway.toml files in place
   - Environment variables configured
   - **Problem**: Services fail to build/start

### Build Failures on Railway:
- Docker builds are failing
- Likely issues:
  - File paths incorrect
  - Dependencies not properly copied
  - Build context problems
  - Node modules issues
  - TypeScript compilation errors

## Session 35 Objectives

### 🎯 Goal 1: Test and Fix Docker Builds Locally

#### Step 1: Test Ponder Indexer Docker Build
```bash
cd frontend
# Test the indexer Dockerfile
docker build -f Dockerfile.indexer -t ponder-indexer:local .

# If it fails, debug:
# - Check file paths
# - Verify package.json exists
# - Ensure all dependencies are included
```

#### Step 2: Test Scheduler Docker Build
```bash
cd frontend
# Test the scheduler Dockerfile
docker build -f Dockerfile.scheduler -t scheduler:local .

# Common issues to fix:
# - TypeScript compilation errors
# - Missing dependencies
# - Prisma generation issues
# - Path resolution problems
```

#### Step 3: Run Services Locally
```bash
# Create a test docker-compose.yml
# Run both services together
docker-compose up

# Verify:
# - Services start without crashing
# - Health endpoints respond
# - No missing environment variables
# - Database connections work
```

### 🎯 Goal 2: Create Working docker-compose.yml

Create a complete docker-compose setup that:
1. Builds both services
2. Sets up networking between them
3. Includes health checks
4. Uses .env file for configuration
5. Can be used for local development

```yaml
version: '3.8'
services:
  ponder-indexer:
    build:
      context: .
      dockerfile: Dockerfile.indexer
    ports:
      - "42069:42069"
    environment:
      - DATABASE_URL=${DATABASE_URL}
      # ... other vars
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:42069/health"]
      
  scheduler:
    build:
      context: .
      dockerfile: Dockerfile.scheduler
    ports:
      - "3001:3001"
    environment:
      - DATABASE_URL=${DATABASE_URL}
      # ... other vars
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:3001/health"]
```

### 🎯 Goal 3: Fix Common Docker Issues

#### Expected Problems and Solutions:

1. **Ponder Indexer Issues**:
   ```dockerfile
   # Problem: package.json not found
   # Solution: Fix COPY paths
   COPY indexer/package*.json ./
   
   # Problem: Dependencies fail to install
   # Solution: Clear npm cache
   RUN npm ci --cache /tmp/empty-cache
   
   # Problem: Ponder won't start
   # Solution: Ensure correct working directory
   WORKDIR /app
   ```

2. **Scheduler Issues**:
   ```dockerfile
   # Problem: TypeScript won't compile
   # Solution: Install dev dependencies for build
   RUN npm ci # not npm ci --omit=dev
   
   # Problem: Prisma client not generated
   # Solution: Generate after install
   RUN npx prisma generate
   
   # Problem: Build files not found
   # Solution: Verify build output location
   RUN npm run build && ls -la dist/
   ```

3. **General Issues**:
   - Use `node:20-alpine` consistently
   - Set proper working directories
   - Copy files in correct order
   - Handle node_modules properly
   - Set correct permissions

### 🎯 Goal 4: Create Simplified Dockerfiles

If current Dockerfiles are too complex, create simplified versions:

#### Simple Ponder Indexer Dockerfile:
```dockerfile
FROM node:20-alpine
WORKDIR /app
COPY indexer/package*.json ./
RUN npm ci
COPY indexer/ ./
EXPOSE 42069
CMD ["npm", "start"]
```

#### Simple Scheduler Dockerfile:
```dockerfile
FROM node:20-alpine
WORKDIR /app
COPY package*.json ./
COPY prisma ./prisma/
RUN npm ci && npx prisma generate
COPY services/scheduler ./services/scheduler
COPY lib ./lib
RUN cd services/scheduler && npm run build
EXPOSE 3001
CMD ["node", "services/scheduler/dist/index.js"]
```

### 🎯 Goal 5: Test Everything Locally

#### Testing Checklist:
- [ ] Ponder indexer builds without errors
- [ ] Scheduler builds without errors
- [ ] Both services start with docker-compose
- [ ] Health endpoints return 200 OK
- [ ] GraphQL playground loads at :42069/graphql
- [ ] Scheduler status endpoint works at :3001/status
- [ ] No crashes after 5 minutes of running
- [ ] Logs show expected output
- [ ] Database connections successful
- [ ] Cron jobs execute (check scheduler logs)

### 🎯 Goal 6: Prepare for Railway Re-deployment

Once everything works locally:

1. **Update Dockerfiles** with working versions
2. **Update railway.toml** files if needed
3. **Document the fixes** made
4. **Create deployment script** for consistency
5. **Test with production environment variables**

## Success Criteria

✅ **Local Development Working**:
- Both Docker images build successfully
- Services run without crashing
- Health checks pass
- GraphQL endpoint accessible
- Scheduler cron jobs execute

✅ **Ready for Railway**:
- Dockerfiles tested and working
- docker-compose.yml documented
- Environment variables documented
- Deployment instructions updated

## Debugging Commands

```bash
# Build with verbose output
docker build --progress=plain -f Dockerfile.indexer .

# Run with shell to debug
docker run -it --entrypoint sh ponder-indexer:local

# Check logs
docker logs [container-id] -f

# Inspect running container
docker exec -it [container-id] sh

# Test health endpoint
curl http://localhost:42069/health
curl http://localhost:3001/health

# Check file structure in container
docker run --rm ponder-indexer:local ls -la

# Test with minimal environment
docker run --rm -e NODE_ENV=development ponder-indexer:local
```

## File Structure to Verify

```
frontend/
├── indexer/
│   ├── package.json          # Must exist
│   ├── ponder.config.ts      # Required for Ponder
│   ├── ponder.schema.ts      # Required for Ponder
│   └── src/                  # Event handlers
├── services/
│   └── scheduler/
│       ├── package.json      # Must exist
│       ├── tsconfig.json     # For TypeScript build
│       └── src/
│           └── index.ts      # Main file
├── lib/                      # Shared code
├── prisma/
│   └── schema.prisma        # For scheduler
├── Dockerfile.indexer        # Fix this
├── Dockerfile.scheduler      # Fix this
└── docker-compose.yml        # Create this
```

## Priority Order

1. **First**: Get Ponder indexer Docker working
2. **Second**: Get Scheduler Docker working
3. **Third**: Test both with docker-compose
4. **Fourth**: Run for 10+ minutes to ensure stability
5. **Finally**: Push fixes and redeploy to Railway

## Notes

- Don't try to deploy to Railway until local tests pass
- Keep Dockerfiles simple initially, optimize later
- Document every fix made for future reference
- Test with real environment variables, not just defaults
- Consider creating a Makefile for common commands

---

**Session Goal**: Get both backend services running successfully in Docker locally, fixing all build and runtime issues, before attempting Railway deployment again. This ensures we have working, tested containers that will deploy successfully.