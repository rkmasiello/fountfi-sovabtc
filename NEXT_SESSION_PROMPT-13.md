# Next Session Prompt for Multi-Collateral BTC Vault

## Session 13: Frontend Deployment & Security Audit Preparation

You are continuing work on the FountFi Multi-Collateral BTC Vault system. Review ASSESSMENT_REPORT.md for the complete development history.

### ✅ Current Status:
- All smart contracts deployed and operational on Base Sepolia
- Frontend application built with Next.js, includes admin panel
- Ponder indexer dockerized with multi-network configuration
- Automated monitoring system created with health checks
- Mainnet deployment scripts ready for multiple networks
- Load testing completed for 50-100+ concurrent users
- System fully functional with all features implemented

### 🎯 Session 13 Goals: Production Deployment & Security Preparation

**PRIMARY OBJECTIVE: Deploy frontend to Vercel, prepare comprehensive security audit package, and create CI/CD pipelines for automated deployments**

### 🔗 Live Infrastructure:
- **Vault**: `0x73E27097221d4d9D5893a83350dC7A967b46fab7` (Base Sepolia)
- **Queue**: `0x22BC73098CE1Ba2CaE5431fb32051cB4fc0F9C52` (Base Sepolia)
- **Frontend**: `/frontend` directory (Next.js app)
- **Indexer**: `/examples/ponder-indexer` (Dockerized)
- **Monitoring**: `/scripts/monitoring` (TypeScript)
- **SDK**: `/sdk/VaultSDK.ts`

### 📋 Task List:

#### 1. Frontend Production Deployment to Vercel
**Priority: CRITICAL** - User-facing application

Configure and deploy the Next.js frontend to Vercel:

- [ ] Create `vercel.json` configuration file
- [ ] Set up environment variables for production:
  ```
  NEXT_PUBLIC_NETWORK=base-sepolia
  NEXT_PUBLIC_ALCHEMY_KEY=<key>
  NEXT_PUBLIC_WALLETCONNECT_PROJECT_ID=fbdc02ca1d45b13459b8815d9344ee5a
  NEXT_PUBLIC_INDEXER_URL=https://indexer.yourdomain.com
  NEXT_PUBLIC_VAULT_ADDRESS=0x73E27097221d4d9D5893a83350dC7A967b46fab7
  ```
- [ ] Configure custom domain (if available)
- [ ] Set up preview deployments for PR branches
- [ ] Add build optimization and caching
- [ ] Configure security headers
- [ ] Set up error monitoring (Sentry)
- [ ] Add analytics (Plausible/Google Analytics)
- [ ] Create staging environment
- [ ] Test all functionality post-deployment

#### 2. Security Audit Preparation Package
**Priority: CRITICAL** - Required before mainnet

Create comprehensive documentation for auditors in `/audit-prep/`:

```
audit-prep/
├── README.md                    # System overview and architecture
├── CONTRACTS.md                # Contract descriptions and interactions
├── INVARIANTS.md               # System invariants that must hold
├── ATTACK_VECTORS.md           # Known risks and mitigations
├── TEST_COVERAGE.md            # Test results and coverage reports
├── DEPENDENCIES.md             # External dependencies audit
├── ACCESS_CONTROL.md           # Role-based permissions matrix
├── DECIMAL_HANDLING.md         # Precision and rounding documentation
├── EMERGENCY_PROCEDURES.md     # Incident response plan
├── DEPLOYMENT_GUIDE.md         # Step-by-step deployment instructions
├── SLITHER_REPORT.md           # Automated security analysis
└── KNOWN_ISSUES.md             # Acknowledged limitations and future improvements
```

Key documentation to include:
- [ ] System architecture diagrams
- [ ] Contract interaction flow charts
- [ ] Mathematical proofs for share calculations
- [ ] Decimal conversion edge cases
- [ ] Emergency pause scenarios
- [ ] Redemption queue attack vectors
- [ ] Oracle manipulation risks
- [ ] Multi-collateral risks
- [ ] Reentrancy analysis
- [ ] Gas optimization opportunities

#### 3. CI/CD Pipeline Configuration
**Priority: HIGH** - Automated deployments

Set up GitHub Actions for continuous integration and deployment:

`.github/workflows/ci.yml`:
```yaml
name: CI/CD Pipeline
on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Install Foundry
      - name: Run tests
      - name: Generate coverage report
      
  deploy-frontend:
    needs: test
    if: github.ref == 'refs/heads/main'
    steps:
      - name: Deploy to Vercel
      
  deploy-indexer:
    needs: test
    if: github.ref == 'refs/heads/main'
    steps:
      - name: Deploy to Railway
```

Tasks:
- [ ] Create test workflow for smart contracts
- [ ] Add coverage reporting with Codecov
- [ ] Set up Slither security analysis
- [ ] Configure frontend deployment workflow
- [ ] Add indexer deployment workflow
- [ ] Create release automation
- [ ] Set up dependency updates (Dependabot)
- [ ] Add license checking
- [ ] Configure branch protection rules

#### 4. Contract Verification on Basescan
**Priority: HIGH** - Transparency and trust

Verify all deployed contracts on Base Sepolia:

- [ ] Prepare constructor arguments for each contract
- [ ] Use Foundry's verification command:
  ```bash
  forge verify-contract <address> <contract> --chain-id 84532
  ```
- [ ] Verify via Basescan UI as backup
- [ ] Document verification status
- [ ] Add verified badges to documentation

#### 5. User Onboarding Flow Component
**Priority: MEDIUM** - User experience

Create an interactive onboarding wizard in the frontend:

```typescript
// frontend/components/OnboardingWizard.tsx
interface OnboardingStep {
  title: string;
  description: string;
  action?: () => void;
  completed: boolean;
}

const steps: OnboardingStep[] = [
  { title: "Connect Wallet", description: "Connect your Web3 wallet" },
  { title: "Get Test Tokens", description: "Claim test BTC tokens" },
  { title: "Approve Tokens", description: "Approve vault to use tokens" },
  { title: "Make First Deposit", description: "Deposit BTC to earn mcBTC" },
  { title: "Explore Features", description: "Learn about redemptions" }
];
```

Features to implement:
- [ ] Step-by-step guided tour
- [ ] Interactive tooltips
- [ ] Progress tracking
- [ ] Skip option for experienced users
- [ ] Educational content at each step
- [ ] Test token faucet integration
- [ ] Success celebrations
- [ ] Help/support links

#### 6. Production Monitoring Dashboard
**Priority: MEDIUM** - Operational visibility

Create a comprehensive monitoring dashboard:

- [ ] Deploy Grafana instance
- [ ] Configure Prometheus metrics
- [ ] Set up alert rules
- [ ] Create dashboards for:
  - Vault TVL over time
  - Deposit/redemption volumes
  - Gas costs tracking
  - User growth metrics
  - System health status
  - Error rates
  - Performance metrics
- [ ] Integrate with monitoring script
- [ ] Add public status page

#### 7. Integration Testing with Real Tokens
**Priority: LOW** - Future mainnet preparation

Prepare for mainnet by testing with real token interfaces:

- [ ] Document actual WBTC addresses on each network
- [ ] Document actual tBTC addresses on each network
- [ ] Research sovaBTC deployment plans
- [ ] Test with token interfaces on fork
- [ ] Verify decimal handling matches
- [ ] Check for any token-specific quirks
- [ ] Update deployment scripts with real addresses

### 📊 Deliverables for Session 13:

1. **Frontend Production Deployment**
   - [ ] Live on Vercel with custom domain
   - [ ] Environment variables configured
   - [ ] Preview deployments working
   - [ ] Analytics and monitoring active

2. **Security Audit Package**
   - [ ] Complete documentation set in `/audit-prep/`
   - [ ] Slither reports generated
   - [ ] Coverage reports included
   - [ ] Architecture diagrams created

3. **CI/CD Pipeline**
   - [ ] GitHub Actions workflows configured
   - [ ] Automated testing on every PR
   - [ ] Automated deployments to production
   - [ ] Security scanning integrated

4. **Contract Verification**
   - [ ] All contracts verified on Basescan
   - [ ] Verification documented
   - [ ] Source code readable on explorer

5. **User Onboarding**
   - [ ] Interactive wizard component
   - [ ] Help documentation integrated
   - [ ] Test token faucet connected
   - [ ] Progress tracking implemented

### 🔧 Useful Commands:

```bash
# Frontend deployment
cd frontend
vercel --prod
vercel env pull .env.local

# Contract verification
forge verify-contract 0x73E27097221d4d9D5893a83350dC7A967b46fab7 \
  MultiBTCVault --chain-id 84532 \
  --etherscan-api-key $BASESCAN_KEY

# Security analysis
slither . --print human-summary
mythril analyze contracts/MultiBTCVault.sol

# Coverage report
forge coverage --report lcov
genhtml lcov.info -o coverage-report

# Deploy monitoring
cd scripts/monitoring
docker build -t vault-monitor .
docker run -d --env-file .env.production vault-monitor

# Test with mainnet fork
forge test --fork-url https://eth-mainnet.alchemyapi.io/v2/YOUR_KEY
```

### ⚠️ Important Considerations:

1. **Frontend Security**
   - Never expose private keys in frontend
   - Use environment variables properly
   - Implement CSP headers
   - Add rate limiting for API calls
   - Validate all user inputs

2. **Audit Preparation**
   - Be thorough in documentation
   - Acknowledge all known issues
   - Provide clear remediation plans
   - Include all test results
   - Document all assumptions

3. **Production Readiness**
   - Test everything on staging first
   - Have rollback procedures ready
   - Monitor closely after deployment
   - Prepare incident response plan
   - Train team on operations

### Success Criteria:
- [ ] Frontend live and accessible to users
- [ ] All user flows working correctly
- [ ] Security audit package complete and professional
- [ ] CI/CD pipeline running smoothly
- [ ] Monitoring showing healthy metrics
- [ ] Team able to manage operations
- [ ] Documentation comprehensive and current
- [ ] System ready for security audit

### After Session 13:
The vault will be ready for:
1. **Professional security audit**
2. **Public beta testing**
3. **Marketing and user acquisition**
4. **Mainnet deployment planning**
5. **Partnership integrations**

This session focuses on making the system production-ready from a user perspective, ensuring proper security documentation for auditors, and establishing automated processes for ongoing development and deployment.