# Next Session Prompt for Multi-Collateral BTC Vault

## Session 14: Production Deployment & Audit Submission

You are continuing work on the FountFi Multi-Collateral BTC Vault system. Review ASSESSMENT_REPORT.md for the complete development history.

### ✅ Current Status:
- All smart contracts deployed and operational on Base Sepolia
- Complete frontend with admin panel and onboarding wizard
- Security audit documentation package prepared
- CI/CD pipeline configured with GitHub Actions
- Contract verification scripts ready
- Ponder indexer dockerized and ready for Railway
- All infrastructure ready for production deployment

### 🎯 Session 14 Goals: Execute Production Deployments & Begin Audit Process

**PRIMARY OBJECTIVE: Deploy all production infrastructure, verify contracts, and submit for security audit**

### 🔗 Live Infrastructure:
- **Vault**: `0x73E27097221d4d9D5893a83350dC7A967b46fab7` (Base Sepolia)
- **Frontend**: `/frontend` directory (ready for Vercel)
- **Indexer**: `/examples/ponder-indexer` (ready for Railway)
- **Audit Docs**: `/audit-prep` directory (complete)
- **CI/CD**: `.github/workflows` (configured)

### 📋 Task List:

#### 1. Execute Contract Verification on Basescan
**Priority: CRITICAL** - Required for transparency

Execute the verification script:
```bash
cd ~/Documents/GitHub/fountfi-sovabtc
./scripts/verify-contracts.sh
```

Tasks:
- [ ] Run verification script with API key
- [ ] Confirm each contract is verified on Basescan
- [ ] Document verification status
- [ ] Update README with verified badges
- [ ] Create verification report

Expected outcomes:
- All 6 contracts verified and readable on Basescan
- Source code visible to users
- Constructor arguments confirmed

#### 2. Deploy Frontend to Vercel Production
**Priority: CRITICAL** - User interface deployment

Deploy the frontend application:
```bash
cd frontend
npm install
vercel --prod
```

Tasks:
- [ ] Install Vercel CLI if needed: `npm i -g vercel`
- [ ] Login to Vercel: `vercel login`
- [ ] Configure environment variables in Vercel dashboard
- [ ] Deploy to production
- [ ] Test all features on production URL
- [ ] Configure custom domain if available
- [ ] Set up preview deployments for branches
- [ ] Test wallet connections and transactions
- [ ] Verify onboarding wizard works

Environment variables to set in Vercel:
```
NEXT_PUBLIC_NETWORK=base-sepolia
NEXT_PUBLIC_ALCHEMY_KEY=[your-key]
NEXT_PUBLIC_WALLETCONNECT_PROJECT_ID=fbdc02ca1d45b13459b8815d9344ee5a
NEXT_PUBLIC_VAULT_ADDRESS=0x73E27097221d4d9D5893a83350dC7A967b46fab7
# ... (all other addresses from .env.production)
```

#### 3. Deploy Ponder Indexer to Railway
**Priority: HIGH** - Data indexing service

Deploy the indexer:
```bash
cd examples/ponder-indexer
railway login
railway link
railway up
```

Tasks:
- [ ] Create Railway account if needed
- [ ] Install Railway CLI: `npm i -g @railway/cli`
- [ ] Link to Railway project
- [ ] Configure environment variables in Railway:
  - `DATABASE_URL` (Neon database)
  - `PONDER_RPC_URL_84532` (Alchemy Base Sepolia)
- [ ] Deploy using Docker configuration
- [ ] Verify indexer is running
- [ ] Test GraphQL endpoint
- [ ] Monitor initial sync progress
- [ ] Set up health checks
- [ ] Configure auto-scaling

#### 4. Deploy Monitoring System
**Priority: HIGH** - System observability

Deploy the monitoring infrastructure:

Tasks:
- [ ] Choose monitoring platform (Grafana Cloud, Datadog, etc.)
- [ ] Deploy health-monitor container
- [ ] Configure alert webhooks (Discord/Slack)
- [ ] Set up dashboards:
  - TVL tracking
  - Transaction volumes
  - Gas costs
  - Error rates
  - System health
- [ ] Test alert notifications
- [ ] Document monitoring access

#### 5. Submit for Security Audit
**Priority: CRITICAL** - Required before mainnet

Prepare and submit audit package:

Tasks:
- [ ] Package `/audit-prep` directory
- [ ] Research and contact audit firms:
  - OpenZeppelin
  - Trail of Bits
  - Consensys Diligence
  - Certik
  - Quantstamp
- [ ] Request quotes and timelines
- [ ] Submit initial package
- [ ] Schedule kickoff call
- [ ] Prepare team for Q&A
- [ ] Create audit tracking document

Audit package should include:
- All contracts source code
- Test suite
- Documentation package
- Deployment addresses
- Known issues list

#### 6. Set Up Multisig Wallets
**Priority: HIGH** - Security requirement

Configure Gnosis Safe multisigs:

Tasks:
- [ ] Deploy Gnosis Safe on Base Sepolia
- [ ] Configure signers (minimum 3)
- [ ] Set threshold (2 of 3 or similar)
- [ ] Transfer admin roles to multisig:
  - DEFAULT_ADMIN_ROLE
  - OPERATOR_ROLE
  - PAUSER_ROLE
- [ ] Test multisig operations
- [ ] Document signing procedures
- [ ] Create operational playbooks

#### 7. Prepare Mainnet Token Research
**Priority: MEDIUM** - Future requirement

Research actual BTC tokens on target networks:

Tasks:
- [ ] Document WBTC addresses on:
  - Base mainnet
  - Ethereum mainnet
  - Arbitrum
  - Optimism
- [ ] Document tBTC addresses
- [ ] Research sovaBTC deployment plans
- [ ] Identify liquidity sources
- [ ] Plan initial liquidity provision
- [ ] Create token integration checklist

#### 8. Create Marketing Materials
**Priority: LOW** - Can be done in parallel

Prepare for public launch:

Tasks:
- [ ] Create landing page design
- [ ] Write vault explainer content
- [ ] Design infographics
- [ ] Prepare launch announcement
- [ ] Create social media accounts
- [ ] Draft documentation site
- [ ] Plan community channels (Discord/Telegram)

### 📊 Deliverables for Session 14:

1. **Verified Contracts**
   - [ ] All contracts verified on Basescan
   - [ ] Verification report created
   - [ ] Public source code accessible

2. **Live Frontend**
   - [ ] Deployed to Vercel production
   - [ ] Custom domain configured (if available)
   - [ ] All features tested and working
   - [ ] Preview deployments active

3. **Running Indexer**
   - [ ] Deployed to Railway
   - [ ] GraphQL endpoint accessible
   - [ ] Data syncing correctly
   - [ ] Monitoring configured

4. **Active Monitoring**
   - [ ] Dashboards created
   - [ ] Alerts configured
   - [ ] Health checks running
   - [ ] Documentation complete

5. **Audit Process Started**
   - [ ] Audit firm selected
   - [ ] Package submitted
   - [ ] Timeline agreed
   - [ ] Kickoff scheduled

6. **Multisig Security**
   - [ ] Safe deployed
   - [ ] Signers configured
   - [ ] Roles transferred
   - [ ] Procedures documented

### 🔧 Useful Commands:

```bash
# Verify contracts
./scripts/verify-contracts.sh

# Deploy frontend
cd frontend && vercel --prod

# Deploy indexer
cd examples/ponder-indexer && railway up

# Check deployment status
forge script script/helpers/CheckDeployment.s.sol --rpc-url base-sepolia

# Monitor transactions
cast logs --address 0x73E27097221d4d9D5893a83350dC7A967b46fab7 --rpc-url base-sepolia

# Test production frontend
curl https://your-app.vercel.app/api/health
```

### ⚠️ Important Considerations:

1. **Verification Order**
   - Verify contracts before announcing publicly
   - Ensure all constructor args are correct
   - Keep API keys secure

2. **Production Deployment**
   - Test everything on staging first
   - Have rollback plan ready
   - Monitor closely after deployment
   - Keep private keys secure

3. **Audit Preparation**
   - Be responsive to auditor questions
   - Prepare to fix issues quickly
   - Plan for audit remediation sprint
   - Budget for multiple rounds

4. **Security Best Practices**
   - Never share private keys
   - Use hardware wallets for mainnet
   - Enable 2FA on all services
   - Rotate API keys regularly

### Success Criteria:
- [ ] All contracts verified and public
- [ ] Frontend live and accessible to users
- [ ] Indexer syncing blockchain data
- [ ] Monitoring showing healthy metrics
- [ ] Audit process initiated
- [ ] Multisig controlling admin functions
- [ ] Team prepared for mainnet deployment
- [ ] Documentation complete and current

### After Session 14:
The system will be:
1. **Fully deployed to production infrastructure**
2. **Under professional security review**
3. **Ready for public beta testing**
4. **Prepared for mainnet deployment post-audit**
5. **Secured with multisig governance**

This session focuses on executing all the production deployments that have been prepared, getting contracts verified for transparency, and initiating the critical security audit process. After this session, the project will be live and ready for users while undergoing security review.