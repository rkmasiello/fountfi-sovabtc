# Next Session Prompt for Multi-Collateral BTC Vault

## Session 12: Dockerize Ponder & Mainnet Preparation

You are continuing work on the FountFi Multi-Collateral BTC Vault system. Review ASSESSMENT_REPORT.md for the complete development history.

### ✅ Current Status:
- All smart contracts deployed and operational on Base Sepolia
- Frontend application built with Next.js, includes admin panel
- Ponder indexer configured with Neon database
- Load testing completed for 50-100+ concurrent users
- TypeScript SDK and integration examples completed
- System fully functional with all features implemented

### 🎯 Session 12 Goals: Production Deployment & Mainnet Preparation

**PRIMARY OBJECTIVE: Dockerize Ponder indexer for Railway deployment and prepare the entire system for mainnet deployment with configurable network support**

### 🔗 Live Infrastructure:
- **Vault**: `0x73E27097221d4d9D5893a83350dC7A967b46fab7` (Base Sepolia)
- **Queue**: `0x22BC73098CE1Ba2CaE5431fb32051cB4fc0F9C52` (Base Sepolia)
- **Frontend**: `/frontend` directory (Next.js app)
- **Indexer**: `/examples/ponder-indexer` (Ponder + Neon DB)
- **SDK**: `/sdk/VaultSDK.ts`

### 📋 Task List:

#### 1. Dockerize Ponder Indexer
**Priority: CRITICAL** - Required for production deployment

Create a production-ready Docker configuration for the Ponder indexer:

```dockerfile
# examples/ponder-indexer/Dockerfile
FROM node:20-alpine
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production
COPY . .
RUN npm run build
EXPOSE 42069
CMD ["npm", "start"]
```

Additional requirements:
- [ ] Create `.dockerignore` file
- [ ] Add health check endpoint
- [ ] Configure environment variables for:
  - `DATABASE_URL` (Neon connection string)
  - `RPC_URL` (Alchemy/Infura endpoint)
  - `CHAIN_ID` (network identifier)
  - `CONTRACT_ADDRESSES` (JSON string or individual vars)
- [ ] Create `docker-compose.yml` for local testing
- [ ] Add Railway deployment configuration (`railway.json`)
- [ ] Test Docker build and run locally

#### 2. Multi-Network Configuration System
**Priority: HIGH** - Essential for mainnet deployment

Create a flexible configuration system that supports multiple networks:

```typescript
// examples/ponder-indexer/src/config.ts
export interface NetworkConfig {
  chainId: number;
  rpcUrl: string;
  startBlock: number;
  contracts: {
    vault: string;
    queue: string;
    registry: string;
    strategy: string;
    priceOracle: string;
  };
}

export const NETWORK_CONFIGS: Record<string, NetworkConfig> = {
  'base-sepolia': {
    chainId: 84532,
    rpcUrl: process.env.BASE_SEPOLIA_RPC || '',
    startBlock: 12345678,
    contracts: {
      vault: '0x73E27097221d4d9D5893a83350dC7A967b46fab7',
      // ... other contracts
    }
  },
  'base': {
    chainId: 8453,
    rpcUrl: process.env.BASE_MAINNET_RPC || '',
    startBlock: 0, // To be determined
    contracts: {
      vault: '', // To be deployed
      // ... other contracts
    }
  },
  'ethereum': {
    chainId: 1,
    rpcUrl: process.env.ETH_MAINNET_RPC || '',
    startBlock: 0,
    contracts: {
      vault: '', // To be deployed
      // ... other contracts
    }
  }
};

export function getNetworkConfig(): NetworkConfig {
  const network = process.env.NETWORK || 'base-sepolia';
  const config = NETWORK_CONFIGS[network];
  
  if (!config) {
    throw new Error(`Unknown network: ${network}`);
  }
  
  // Allow override from environment variables
  if (process.env.VAULT_ADDRESS) {
    config.contracts.vault = process.env.VAULT_ADDRESS;
  }
  // ... handle other overrides
  
  return config;
}
```

Update Ponder configuration to use dynamic network config:
- [ ] Modify `ponder.config.ts` to use `getNetworkConfig()`
- [ ] Update event handlers to be network-agnostic
- [ ] Add network validation on startup
- [ ] Create migration scripts for database schema updates

#### 3. Railway Deployment Configuration
**Priority: HIGH** - Production deployment platform

Create Railway-specific configuration files:

```json
// examples/ponder-indexer/railway.json
{
  "build": {
    "builder": "DOCKERFILE",
    "dockerfilePath": "Dockerfile"
  },
  "deploy": {
    "healthcheckPath": "/health",
    "healthcheckTimeout": 30,
    "restartPolicyType": "ON_FAILURE",
    "restartPolicyMaxRetries": 3
  }
}
```

Railway deployment steps:
- [ ] Create `railway.toml` with service configuration
- [ ] Set up environment variables in Railway dashboard
- [ ] Configure Neon database connection pooling
- [ ] Set up custom domain (if available)
- [ ] Configure auto-scaling rules
- [ ] Set up monitoring and alerts
- [ ] Create deployment script/GitHub Action

#### 4. Create Automated Monitoring System
**Priority: HIGH** - Essential for production operations

Build a comprehensive monitoring service:

```typescript
// scripts/monitoring/health-monitor.ts
import { VaultSDK } from '../../sdk/VaultSDK';
import axios from 'axios';

class HealthMonitor {
  private checks: HealthCheck[] = [];
  private alertWebhook: string;
  
  constructor(config: MonitorConfig) {
    this.setupChecks();
    this.alertWebhook = config.alertWebhook;
  }
  
  async runHealthChecks() {
    const results = await Promise.all(
      this.checks.map(check => this.runCheck(check))
    );
    
    const failures = results.filter(r => !r.success);
    if (failures.length > 0) {
      await this.sendAlert(failures);
    }
    
    return results;
  }
  
  private setupChecks() {
    this.checks = [
      {
        name: 'Vault Not Paused',
        check: async () => {
          const sdk = new VaultSDK();
          return !await sdk.isPaused();
        }
      },
      {
        name: 'Price Oracle Fresh',
        check: async () => {
          const sdk = new VaultSDK();
          const lastUpdate = await sdk.getLastPriceUpdate();
          return (Date.now() - lastUpdate) < 24 * 60 * 60 * 1000;
        }
      },
      {
        name: 'Ponder Indexer Synced',
        check: async () => {
          const response = await axios.get('http://indexer.example.com/health');
          return response.data.synced && response.data.blocksBehind < 10;
        }
      },
      {
        name: 'Redemption Queue Processing',
        check: async () => {
          const sdk = new VaultSDK();
          const pending = await sdk.getPendingRedemptions();
          const oldestRequest = pending[0];
          if (!oldestRequest) return true;
          
          const daysSinceRequest = (Date.now() - oldestRequest.timestamp) / (24 * 60 * 60 * 1000);
          return daysSinceRequest < 15; // Alert if older than 15 days
        }
      },
      {
        name: 'Strategy Liquidity Sufficient',
        check: async () => {
          const sdk = new VaultSDK();
          const liquidity = await sdk.getStrategyLiquidity();
          const pendingRedemptions = await sdk.getTotalPendingRedemptions();
          return liquidity >= pendingRedemptions * 1.1; // 10% buffer
        }
      }
    ];
  }
  
  private async sendAlert(failures: any[]) {
    // Send to Discord/Slack/Telegram
    await axios.post(this.alertWebhook, {
      content: `⚠️ Health Check Failures:\n${failures.map(f => `- ${f.name}: ${f.error}`).join('\n')}`
    });
  }
}

// Run every 5 minutes
setInterval(async () => {
  const monitor = new HealthMonitor({
    alertWebhook: process.env.ALERT_WEBHOOK
  });
  await monitor.runHealthChecks();
}, 5 * 60 * 1000);
```

Monitoring setup:
- [ ] Create health check endpoints for all services
- [ ] Set up Uptime Robot or similar for endpoint monitoring
- [ ] Configure Discord/Telegram bot for alerts
- [ ] Create Grafana dashboard for metrics
- [ ] Set up log aggregation (Logtail/Datadog)
- [ ] Create incident response runbook

#### 5. Mainnet Deployment Scripts
**Priority: HIGH** - Required for production launch

Create deployment scripts that support multiple networks:

```solidity
// script/deploy/DeployMainnet.s.sol
contract DeployMainnet is Script {
    struct NetworkAddresses {
        address wbtc;
        address tbtc;
        address sovaBTC;
        address multisig;
    }
    
    mapping(uint256 => NetworkAddresses) public networkAddresses;
    
    function setUp() public {
        // Base Mainnet
        networkAddresses[8453] = NetworkAddresses({
            wbtc: 0x..., // Real WBTC on Base
            tbtc: 0x..., // Real tBTC on Base
            sovaBTC: 0x..., // Real sovaBTC on Base
            multisig: 0x... // Team multisig
        });
        
        // Ethereum Mainnet
        networkAddresses[1] = NetworkAddresses({
            wbtc: 0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599,
            tbtc: 0x18084fbA666a33d37592fA2633fD49a74DD93a88,
            sovaBTC: 0x..., // sovaBTC on Ethereum
            multisig: 0x... // Team multisig
        });
    }
    
    function run() external {
        uint256 chainId = block.chainid;
        NetworkAddresses memory addrs = networkAddresses[chainId];
        
        require(addrs.wbtc != address(0), "Network not configured");
        
        vm.startBroadcast();
        
        // Deploy contracts with network-specific configuration
        // ...
        
        vm.stopBroadcast();
    }
}
```

Deployment preparation:
- [ ] Create network-specific deployment scripts
- [ ] Set up Gnosis Safe multisig for each network
- [ ] Configure Defender or similar for transaction management
- [ ] Create deployment checklist and verification steps
- [ ] Set up contract verification automation
- [ ] Prepare initial liquidity amounts

#### 6. Frontend Production Deployment
**Priority: HIGH** - User-facing application

Prepare frontend for production deployment:

```javascript
// frontend/next.config.js
module.exports = {
  env: {
    NEXT_PUBLIC_NETWORK: process.env.NEXT_PUBLIC_NETWORK || 'base-sepolia',
    NEXT_PUBLIC_ALCHEMY_KEY: process.env.NEXT_PUBLIC_ALCHEMY_KEY,
    NEXT_PUBLIC_WALLETCONNECT_PROJECT_ID: process.env.NEXT_PUBLIC_WALLETCONNECT_PROJECT_ID,
    NEXT_PUBLIC_INDEXER_URL: process.env.NEXT_PUBLIC_INDEXER_URL || 'http://localhost:42069',
  },
  // ... other config
}
```

Frontend deployment tasks:
- [ ] Create environment-specific configurations
- [ ] Set up Vercel/Netlify deployment
- [ ] Configure custom domain and SSL
- [ ] Add Google Analytics/Plausible
- [ ] Implement error tracking (Sentry)
- [ ] Set up A/B testing framework
- [ ] Create staging environment
- [ ] Add feature flags system

#### 7. Security Audit Preparation Package
**Priority: MEDIUM** - Required before mainnet

Prepare comprehensive documentation for auditors:

```markdown
# audit-prep/
├── README.md                    # System overview and architecture
├── CONTRACTS.md                # Contract descriptions and interactions
├── INVARIANTS.md               # System invariants that must hold
├── ATTACK_VECTORS.md           # Known risks and mitigations
├── TEST_COVERAGE.md            # Test results and coverage reports
├── DEPENDENCIES.md             # External dependencies audit
├── ACCESS_CONTROL.md           # Role-based permissions matrix
├── DECIMAL_HANDLING.md         # Precision and rounding documentation
├── EMERGENCY_PROCEDURES.md     # Incident response plan
└── DEPLOYMENT_GUIDE.md         # Step-by-step deployment instructions
```

Audit preparation tasks:
- [ ] Generate test coverage reports
- [ ] Document all external calls
- [ ] Create attack vector analysis
- [ ] List all privileged functions
- [ ] Document decimal conversion logic
- [ ] Create state machine diagrams
- [ ] Prepare Slither/Mythril reports
- [ ] Document upgrade procedures

### 📊 Deliverables for Session 12:

1. **Dockerized Ponder Indexer**
   - [ ] Dockerfile and docker-compose.yml
   - [ ] Railway deployment configuration
   - [ ] Multi-network support
   - [ ] Environment-based configuration

2. **Production Monitoring**
   - [ ] Automated health checks
   - [ ] Alert system configured
   - [ ] Monitoring dashboard
   - [ ] Incident response procedures

3. **Mainnet Deployment Package**
   - [ ] Network-specific deployment scripts
   - [ ] Configuration management system
   - [ ] Multisig setup documentation
   - [ ] Initial liquidity plan

4. **Security Audit Package**
   - [ ] Complete documentation set
   - [ ] Test coverage reports
   - [ ] Risk assessment matrix
   - [ ] Remediation tracking system

### 🔧 Useful Commands:

```bash
# Docker commands
cd examples/ponder-indexer
docker build -t vault-indexer .
docker run -p 42069:42069 --env-file .env vault-indexer

# Railway deployment
railway login
railway link
railway up

# Monitoring
node scripts/monitoring/health-monitor.js

# Mainnet deployment simulation
forge script script/deploy/DeployMainnet.s.sol --rpc-url $MAINNET_RPC --dry-run

# Frontend deployment
cd frontend
vercel --prod

# Generate audit reports
forge coverage
slither . --print human-summary
```

### ⚠️ Important Considerations:

1. **Network Configuration**
   - Ensure all contract addresses are properly configured
   - Test on testnets that mirror mainnet conditions
   - Validate RPC endpoint reliability and rate limits
   - Plan for multi-chain deployment order

2. **Security First**
   - Complete internal review before audit
   - Set up bug bounty program
   - Prepare incident response team
   - Create pause mechanisms for each network

3. **Monitoring & Operations**
   - 24/7 monitoring essential for mainnet
   - Clear escalation procedures
   - Automated and manual response capabilities
   - Regular security drills

### Success Criteria:
- [ ] Ponder indexer running on Railway with 99.9% uptime
- [ ] Multi-network configuration tested and validated
- [ ] Monitoring alerts configured and tested
- [ ] Frontend deployed to production with staging environment
- [ ] Mainnet deployment scripts tested on fork
- [ ] Security audit package reviewed and complete
- [ ] Load testing shows system can handle 1000+ users
- [ ] Documentation complete for operators and users

### After Session 12:
The vault will be ready for:
1. **Security audit submission**
2. **Mainnet deployment execution**
3. **Public launch and marketing**
4. **Integration partnerships**
5. **Liquidity bootstrapping**

This session focuses on production-readiness, ensuring the system can be deployed to mainnet with confidence, proper monitoring, and multi-network support. The Dockerized Ponder indexer will provide reliable data indexing across all deployments.