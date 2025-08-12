# Mainnet Deployment Checklist

## Pre-Deployment Phase (T-7 Days)

### Security & Audit
- [ ] Final security audit report received and reviewed
- [ ] All critical and high-severity findings addressed
- [ ] Medium and low-severity findings documented with mitigation plans
- [ ] Audit response document prepared
- [ ] Contract code frozen (commit hash: ____________)

### Legal & Compliance
- [ ] Legal review completed
- [ ] Terms of service updated
- [ ] Privacy policy updated
- [ ] Regulatory compliance checklist completed
- [ ] Risk disclosure documents prepared

### Technical Preparation
- [ ] Mainnet fork testing completed successfully
- [ ] Load testing results reviewed and acceptable
- [ ] Gas optimization analysis completed
- [ ] All test suites passing (100% line coverage maintained)
- [ ] Deployment scripts tested on mainnet fork
- [ ] Rollback procedures tested and documented

### Infrastructure
- [ ] Mainnet RPC endpoints configured and tested
- [ ] Backup RPC endpoints configured
- [ ] Multi-sig wallet deployed and configured
- [ ] Multi-sig signers confirmed and tested signing
- [ ] Hardware wallets prepared for deployment
- [ ] Monitoring infrastructure deployed (Tenderly/Datadog)

### Team Preparation
- [ ] Deployment team identified and available
- [ ] Communication channels established
- [ ] Emergency contact list updated
- [ ] War room scheduled for deployment day
- [ ] Deployment runbook reviewed by all team members

## Pre-Deployment Phase (T-1 Day)

### Final Checks
- [ ] Latest code review completed
- [ ] No pending PRs or issues for deployment
- [ ] Deployment configuration file reviewed
- [ ] Environment variables verified
- [ ] Gas prices checked and limits set
- [ ] Mainnet balance sufficient for deployment

### Communication
- [ ] Stakeholders notified of deployment schedule
- [ ] Marketing team prepared announcement
- [ ] Support team briefed on new features
- [ ] Documentation website updated (staged)
- [ ] Social media posts prepared (draft)

## Deployment Day (T-0)

### Pre-Deployment (1 Hour Before)
- [ ] Team assembled in war room / communication channel
- [ ] All signers available and ready
- [ ] Mainnet gas prices checked
- [ ] No ongoing network issues on Base
- [ ] Final go/no-go decision made

### Deployment Phase 1: Core Contracts

#### Deploy Oracle Reporter
- [ ] Deploy PriceOracleReporter contract
- [ ] Verify constructor parameters
- [ ] Contract deployed successfully (Address: ____________)
- [ ] Transaction confirmed (TX: ____________)
- [ ] Contract verified on Basescan

#### Deploy BTC Vault Strategy
- [ ] Deploy BtcVaultStrategy contract
- [ ] Verify constructor parameters:
  - [ ] Role Manager address correct
  - [ ] sovaBTC address correct
  - [ ] Oracle reporter address correct
- [ ] Contract deployed successfully (Address: ____________)
- [ ] Transaction confirmed (TX: ____________)
- [ ] Contract verified on Basescan

#### Deploy BTC Vault Token
- [ ] Deploy BtcVaultToken contract
- [ ] Verify constructor parameters:
  - [ ] Strategy address correct
  - [ ] Name and symbol correct
- [ ] Contract deployed successfully (Address: ____________)
- [ ] Transaction confirmed (TX: ____________)
- [ ] Contract verified on Basescan

### Deployment Phase 2: Configuration

#### Setup Roles
- [ ] Grant ADMIN role to multi-sig
- [ ] Grant MANAGER roles to designated addresses
- [ ] Grant OPERATOR roles to designated addresses
- [ ] Grant REPORTER role to oracle
- [ ] All role transactions confirmed
- [ ] Roles verified via read functions

#### Configure Collaterals
- [ ] Add wBTC as supported collateral
- [ ] Add tBTC as supported collateral
- [ ] Add cbBTC as supported collateral
- [ ] Verify decimals for each collateral
- [ ] Test deposit with small amount for each

#### Add Initial Liquidity
- [ ] Transfer sovaBTC to liquidity provider address
- [ ] Approve strategy contract
- [ ] Add initial liquidity (Amount: ____________)
- [ ] Verify liquidity added successfully
- [ ] Check availableLiquidity() returns correct amount

### Deployment Phase 3: Verification

#### Smoke Tests
- [ ] Perform test deposit with wBTC
- [ ] Perform test deposit with tBTC
- [ ] Perform test deposit with cbBTC
- [ ] Request test withdrawal
- [ ] Approve test withdrawal (as manager)
- [ ] Complete test withdrawal
- [ ] Verify sovaBTC received

#### Contract State Verification
- [ ] Total supply is as expected
- [ ] NAV is correctly initialized
- [ ] All collaterals showing as supported
- [ ] Available liquidity matches added amount
- [ ] Share price is 1:1 initially

### Post-Deployment Phase 1: Immediate (First Hour)

#### Monitoring Setup
- [ ] Contracts added to Tenderly
- [ ] Alerts configured and tested
- [ ] Datadog dashboard live
- [ ] First metrics appearing
- [ ] No unexpected errors in logs

#### Access Control
- [ ] Deployer privileges revoked/transferred
- [ ] Multi-sig is contract owner
- [ ] Admin functions only callable by multi-sig
- [ ] Manager functions tested
- [ ] Operator functions tested

### Post-Deployment Phase 2: First Day

#### Frontend Updates
- [ ] Frontend configuration updated with mainnet addresses
- [ ] Frontend deployed to production
- [ ] DNS records updated
- [ ] SSL certificates valid
- [ ] Frontend connecting to mainnet successfully

#### Documentation
- [ ] Documentation updated with mainnet addresses
- [ ] API documentation updated
- [ ] Integration guide updated
- [ ] GitHub README updated
- [ ] Deployment report created

#### Communication
- [ ] Deployment success announced internally
- [ ] Public announcement published
- [ ] Social media posts live
- [ ] Community channels notified
- [ ] Partner notifications sent

### Post-Deployment Phase 3: First Week

#### Monitoring & Performance
- [ ] Daily monitoring reports reviewed
- [ ] No critical alerts triggered
- [ ] Gas costs within expected range
- [ ] Transaction success rate > 99%
- [ ] User deposits/withdrawals processing smoothly

#### Security
- [ ] No security incidents reported
- [ ] Audit firm notified of successful deployment
- [ ] Bug bounty program updated
- [ ] Security monitoring active
- [ ] Incident response team on standby

#### Business Operations
- [ ] First user onboarding successful
- [ ] Support tickets being handled
- [ ] TVL tracking initiated
- [ ] Analytics dashboard operational
- [ ] Daily operations checklist established

## Emergency Procedures

### Pause Procedures
If critical issue detected:
1. [ ] Identify issue severity
2. [ ] Notify emergency contacts
3. [ ] Execute pause transaction via multi-sig
4. [ ] Communicate pause to users
5. [ ] Begin investigation

### Rollback Procedures
If rollback required:
1. [ ] Snapshot current state
2. [ ] Deploy previous version contracts
3. [ ] Migrate user balances
4. [ ] Update all integrations
5. [ ] Verify rollback success
6. [ ] Communicate to users

### Communication Templates

#### Success Announcement
```
BTC Vault is now LIVE on Base Mainnet! 

✅ Multi-collateral deposits (wBTC, tBTC, cbBTC)
✅ Managed redemptions in sovaBTC
✅ Audited and secure
✅ Gas-optimized for Base

Start earning: [URL]
Docs: [URL]
```

#### Issue Communication
```
We are currently investigating an issue with the BTC Vault. 
Funds are safe. 
Deposits and withdrawals are temporarily paused.
Updates: [URL]
```

## Sign-off Requirements

### Technical Team
- [ ] Lead Developer: ____________ Date: ______
- [ ] Security Lead: ____________ Date: ______
- [ ] DevOps Lead: ____________ Date: ______

### Business Team
- [ ] Product Owner: ____________ Date: ______
- [ ] Risk Manager: ____________ Date: ______
- [ ] Legal Counsel: ____________ Date: ______

### Final Approval
- [ ] CEO/CTO: ____________ Date: ______

## Notes Section

_Use this space to document any deviations from the checklist, issues encountered, or additional steps taken:_

---

**Deployment Date:** ____________
**Deployment Team:** ____________
**Final Status:** ____________