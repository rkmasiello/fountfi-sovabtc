# Multi-Collateral BTC Vault Security Documentation

## Overview

This document outlines the security model, access controls, risk assessments, and emergency procedures for the Multi-Collateral BTC Vault system. It serves as a comprehensive security reference for developers, auditors, and administrators.

## Table of Contents

1. [Security Model](#security-model)
2. [Access Control Matrix](#access-control-matrix)
3. [Smart Contract Security](#smart-contract-security)
4. [Risk Assessment](#risk-assessment)
5. [Attack Vectors and Mitigations](#attack-vectors-and-mitigations)
6. [Emergency Procedures](#emergency-procedures)
7. [Audit Recommendations](#audit-recommendations)
8. [Security Best Practices](#security-best-practices)
9. [Incident Response Plan](#incident-response-plan)
10. [Security Monitoring](#security-monitoring)

## Security Model

### Architecture Overview

```
┌─────────────────────────────────────────────┐
│                   Users                      │
└──────────────────┬──────────────────────────┘
                   │
        ┌──────────▼──────────┐
        │   MultiBTCVault     │ ◄─── Admin Controls
        │    (ERC-4626)       │
        └──────────┬──────────┘
                   │
     ┌─────────────┼─────────────┐
     │             │             │
┌────▼────┐  ┌────▼────┐  ┌────▼────┐
│Registry │  │Strategy │  │  Queue  │
└─────────┘  └─────────┘  └─────────┘
     │             │             │
     └─────────────┼─────────────┘
                   │
            ┌──────▼──────┐
            │   Oracle    │
            └─────────────┘
```

### Trust Assumptions

1. **Admin Trust**: Admins are trusted to act in good faith
2. **Oracle Trust**: Price reporter provides accurate NAV
3. **Time Trust**: Block timestamps are reasonably accurate
4. **Collateral Trust**: Underlying BTC tokens are legitimate

### Security Principles

1. **Least Privilege**: Each role has minimum necessary permissions
2. **Defense in Depth**: Multiple layers of security controls
3. **Fail Safe**: System fails to a secure state when errors occur
4. **Separation of Duties**: Critical operations require multiple roles
5. **Transparency**: All actions are logged and auditable

## Access Control Matrix

### Role Definitions

| Role | Contracts | Critical Permissions | Risk Level |
|------|-----------|---------------------|------------|
| **DEFAULT_ADMIN_ROLE** | All | Grant/revoke roles, upgrade contracts | CRITICAL |
| **PAUSER_ROLE** | Vault, Queue | Pause/unpause operations | HIGH |
| **ADMIN_ROLE** | Vault | Set parameters, rescue tokens | HIGH |
| **OPERATOR_ROLE** | Queue | Process redemptions | MEDIUM |
| **REPORTER_ROLE** | Oracle | Update NAV | HIGH |
| **MANAGER_ROLE** | Strategy | Rebalance collateral | MEDIUM |

### Permission Matrix

```
Contract: MultiBTCVault
├── pause()              -> PAUSER_ROLE
├── unpause()            -> PAUSER_ROLE
├── setMinDeposit()      -> ADMIN_ROLE
├── setStrategy()        -> ADMIN_ROLE
├── rescueTokens()       -> ADMIN_ROLE
└── emergencyWithdraw()  -> ADMIN_ROLE

Contract: ManagedRedemptionQueue
├── pause()              -> PAUSER_ROLE
├── unpause()            -> PAUSER_ROLE
├── processRedemptions() -> OPERATOR_ROLE
├── forceProcess()       -> ADMIN_ROLE
└── rescueTokens()       -> ADMIN_ROLE

Contract: PriceOracleReporter
├── updatePrice()        -> REPORTER_ROLE
├── setPriceBounds()     -> ADMIN_ROLE
└── pause()              -> PAUSER_ROLE

Contract: MultiCollateralStrategy
├── rebalance()          -> MANAGER_ROLE
├── withdrawForRedemption() -> Vault Only
└── emergencyWithdraw()  -> ADMIN_ROLE
```

### Multi-Signature Requirements

Critical operations should require multi-sig approval:

```solidity
// Recommended multi-sig setup
Gnosis Safe with 3/5 threshold:
- 2 technical team members
- 2 business team members  
- 1 external security advisor
```

## Smart Contract Security

### Reentrancy Protection

All state-changing functions use OpenZeppelin's ReentrancyGuard:

```solidity
function deposit(uint256 assets, address receiver) 
    external 
    nonReentrant 
    whenNotPaused 
    returns (uint256 shares) 
{
    // Implementation
}
```

### Integer Overflow Protection

- Solidity 0.8.x automatic overflow protection
- Explicit checks for critical calculations
- Safe math for share/asset conversions

### Access Control

Using OpenZeppelin's AccessControl for role management:

```solidity
modifier onlyAdmin() {
    require(hasRole(ADMIN_ROLE, msg.sender), "Not admin");
    _;
}
```

### Pausability

Emergency pause mechanism for all critical functions:

```solidity
modifier whenNotPaused() {
    require(!paused(), "Contract paused");
    _;
}
```

### Input Validation

All inputs validated before processing:

```solidity
function deposit(uint256 assets, address receiver) external {
    require(assets >= minDeposit, "Below minimum");
    require(receiver != address(0), "Invalid receiver");
    require(isCollateralSupported(msg.sender), "Invalid collateral");
    // Process deposit
}
```

## Risk Assessment

### Risk Categories

#### High Risk 🔴

| Risk | Description | Mitigation |
|------|-------------|------------|
| **Oracle Manipulation** | Malicious NAV updates | Price bounds, gradual changes, multi-sig |
| **Admin Key Compromise** | Unauthorized admin actions | Multi-sig, time-locks, monitoring |
| **Smart Contract Bug** | Code vulnerability | Audits, testing, bug bounty |
| **Liquidity Crisis** | Cannot fulfill redemptions | 14-day queue, liquidity monitoring |

#### Medium Risk 🟡

| Risk | Description | Mitigation |
|------|-------------|------------|
| **Decimal Handling** | Conversion errors | Extensive testing, standardization |
| **Gas Price Spike** | Operations become expensive | Batch processing, gas optimization |
| **Collateral Depeg** | WBTC/TBTC loses peg | Diversification, monitoring |
| **Frontrunning** | MEV attacks on deposits | Commit-reveal, flashloan protection |

#### Low Risk 🟢

| Risk | Description | Mitigation |
|------|-------------|------------|
| **Dust Attacks** | Small deposit spam | Minimum deposit requirement |
| **Griefing** | Malicious queue flooding | Gas costs deter attackers |
| **Timestamp Manipulation** | Minor time adjustments | 14-day buffer absorbs variance |

## Attack Vectors and Mitigations

### 1. Sandwich Attack

**Vector**: Attacker frontruns large deposits/redemptions
```
1. See pending large deposit
2. Deposit first (frontrun)
3. Original deposit executes (increases NAV)
4. Attacker withdraws at profit
```

**Mitigation**:
- Gradual NAV updates (max 10% daily)
- Minimum holding period consideration
- MEV protection via private mempool

### 2. Oracle Manipulation

**Vector**: Compromised reporter updates false NAV
```
1. Gain reporter role access
2. Set artificially high/low NAV
3. Arbitrage the mispricing
```

**Mitigation**:
- Multi-sig for reporter role
- Price bounds (max 10% change)
- Time-delayed price updates
- Multiple price sources

### 3. Reentrancy Attack

**Vector**: Recursive calls to drain funds
```
1. Deposit triggers callback
2. Callback calls deposit again
3. State not updated, double credit
```

**Mitigation**:
- ReentrancyGuard on all external functions
- Checks-Effects-Interactions pattern
- State updates before external calls

### 4. Griefing Attack

**Vector**: Spam redemption queue
```
1. Create many small redemptions
2. Clog processing queue
3. Legitimate users delayed
```

**Mitigation**:
- Gas costs make spam expensive
- Batch processing capability
- Admin force-process function

### 5. Flash Loan Attack

**Vector**: Manipulate vault with borrowed funds
```
1. Flash loan large amount
2. Deposit to manipulate shares
3. Exploit price differential
4. Repay loan in same tx
```

**Mitigation**:
- No same-block redemptions
- 14-day redemption queue
- NAV smoothing over time

## Emergency Procedures

### Level 1: Suspicious Activity

**Indicators**:
- Unusual deposit/withdrawal patterns
- Multiple failed transactions
- Unexpected contract calls

**Response**:
1. Increase monitoring frequency
2. Alert security team
3. Prepare for escalation

### Level 2: Confirmed Threat

**Indicators**:
- Confirmed exploit attempt
- Abnormal NAV changes
- Unauthorized access attempts

**Response**:
1. **Pause affected contracts**:
```bash
cast send $VAULT "pause()" --private-key $PAUSER_KEY
cast send $QUEUE "pause()" --private-key $PAUSER_KEY
```

2. **Investigate the issue**:
```bash
# Check recent transactions
cast logs --address $VAULT --from-block -100

# Verify contract state
cast call $VAULT "totalAssets()"
cast call $QUEUE "queueLength()"
```

3. **Communicate**:
- Notify users via official channels
- Post security update
- Coordinate with team

### Level 3: Active Exploit

**Indicators**:
- Funds being drained
- Contract state corrupted
- System compromise confirmed

**Response**:
1. **Emergency pause all contracts**
2. **Initiate incident response plan**
3. **Preserve evidence**:
```bash
# Snapshot current state
forge script script/emergency/SnapshotState.s.sol --rpc-url $RPC

# Archive logs
cast logs --address $VAULT --from-block $INCIDENT_BLOCK > incident_logs.json
```

4. **Execute recovery**:
- Deploy patched contracts
- Migrate user funds
- Process insurance claims

### Emergency Contacts

```
Security Team Lead: +1-XXX-XXX-XXXX
DevOps On-Call: +1-XXX-XXX-XXXX
Legal Team: legal@sovanetwork.com
Insurance Provider: claims@protocol-insurance.com
```

## Audit Recommendations

### Pre-Audit Checklist

- [ ] All tests passing (100% success rate)
- [ ] Test coverage > 90%
- [ ] Slither analysis clean
- [ ] Mythril scan complete
- [ ] Documentation updated
- [ ] Access controls reviewed
- [ ] Emergency procedures tested

### Focus Areas for Auditors

1. **Decimal Conversions**
   - WBTC (8 decimals) ↔ mcBTC (18 decimals)
   - Rounding errors in share calculations

2. **Redemption Queue**
   - 14-day maturity enforcement
   - Queue ordering and fairness
   - Edge cases in processing

3. **Oracle Integration**
   - Price manipulation resistance
   - Update frequency and bounds
   - Fallback mechanisms

4. **Access Control**
   - Role separation adequacy
   - Privilege escalation paths
   - Emergency control safety

### Recommended Audit Firms

1. **Trail of Bits** - Smart contract specialists
2. **OpenZeppelin** - Security framework experts
3. **Quantstamp** - Automated + manual audit
4. **ConsenSys Diligence** - Ethereum specialists
5. **Halborn** - DeFi security experts

## Security Best Practices

### For Developers

1. **Code Review Process**
   - All code peer-reviewed
   - Security-focused review pass
   - Automated testing required

2. **Testing Requirements**
   - Unit tests for all functions
   - Integration tests for workflows
   - Fuzz testing for edge cases
   - Formal verification for critical paths

3. **Deployment Security**
   - Use deterministic deployment
   - Verify all contracts on Etherscan
   - Document deployment parameters
   - Test on testnet first

### For Administrators

1. **Operational Security**
   - Use hardware wallets for admin keys
   - Multi-sig for all critical operations
   - Regular key rotation
   - Audit trail for all actions

2. **Monitoring Requirements**
   - 24/7 system monitoring
   - Automated alerts for anomalies
   - Regular security reviews
   - Incident response drills

3. **Communication Security**
   - Secure channels for team communication
   - Verified announcement channels
   - Clear escalation procedures
   - Regular security updates

### For Users

1. **Wallet Security**
   - Use hardware wallets for large amounts
   - Verify contract addresses
   - Check transaction details
   - Monitor account activity

2. **Transaction Security**
   - Start with small test amounts
   - Verify gas prices
   - Use secure RPC endpoints
   - Keep transaction records

## Incident Response Plan

### Phase 1: Detection (0-15 minutes)

1. **Identify the incident**
2. **Assess severity (Level 1-3)**
3. **Activate response team**
4. **Begin evidence collection**

### Phase 2: Containment (15-60 minutes)

1. **Pause affected systems**
2. **Prevent further damage**
3. **Isolate compromised components**
4. **Maintain system stability**

### Phase 3: Investigation (1-4 hours)

1. **Determine root cause**
2. **Assess full impact**
3. **Identify affected users**
4. **Document findings**

### Phase 4: Recovery (4-24 hours)

1. **Develop fix/patch**
2. **Test solution thoroughly**
3. **Deploy updates**
4. **Restore normal operations**

### Phase 5: Post-Incident (24-72 hours)

1. **Full incident report**
2. **User compensation plan**
3. **Security improvements**
4. **Lessons learned session**

## Security Monitoring

### Real-Time Monitoring

```javascript
// Monitor critical events
const criticalEvents = [
    'RoleGranted',
    'RoleRevoked',
    'Paused',
    'Unpaused',
    'EmergencyWithdraw'
];

// Alert on large transactions
const LARGE_DEPOSIT = ethers.utils.parseUnits("10", 8); // 10 BTC
vault.on("Deposit", (sender, owner, assets, shares) => {
    if (assets.gt(LARGE_DEPOSIT)) {
        sendAlert(`Large deposit: ${assets} from ${sender}`);
    }
});
```

### Security Metrics Dashboard

Key metrics to track:
- Active admin addresses
- Unusual transaction patterns
- Contract pause status
- TVL changes
- Gas price anomalies
- Failed transaction rate
- Queue processing delays

### Automated Security Checks

```bash
# Daily security scan
0 0 * * * /scripts/security_scan.sh

# Hourly monitoring
0 * * * * /scripts/monitor_contracts.sh

# Real-time alerts
*/5 * * * * /scripts/check_alerts.sh
```

## Bug Bounty Program

### Reward Structure

| Severity | Description | Reward |
|----------|-------------|--------|
| **Critical** | Fund loss, system compromise | $50,000 - $100,000 |
| **High** | Temporary fund lock, DoS | $10,000 - $50,000 |
| **Medium** | Gas griefing, minor issues | $1,000 - $10,000 |
| **Low** | UI bugs, typos | $100 - $1,000 |

### Submission Guidelines

1. Report via: security@sovanetwork.com
2. Include proof of concept
3. Allow 48 hours for response
4. Responsible disclosure required
5. No public disclosure before fix

### Out of Scope

- Already known issues
- Social engineering
- Physical attacks
- Issues in dependencies
- Gas optimization suggestions

## Appendix: Security Tools

### Static Analysis

```bash
# Slither analysis
slither contracts/ --print human-summary

# Mythril scan
myth analyze contracts/MultiBTCVault.sol

# Echidna fuzzing
echidna-test contracts/ --contract MultiBTCVault
```

### Dynamic Analysis

```bash
# Tenderly monitoring
tenderly monitor --network mainnet --address $VAULT

# Forta detection bots
forta-agent --config security-config.json
```

### Manual Review Tools

- **Surya**: Visualization and analysis
- **Manticore**: Symbolic execution
- **Securify**: Security patterns
- **MythX**: Cloud-based analysis

---

*Last Updated: [Current Date]*
*Version: 1.0.0*
*Classification: PUBLIC*
*Review Schedule: Monthly*