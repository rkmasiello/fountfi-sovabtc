# Frontend Testing Checklist

## Test Environment
- **Frontend URL**: http://localhost:3003
- **Network**: Base Sepolia (Chain ID: 84532)
- **Test Wallet**: 0x1f53aA5d3b5743BD0D41884124bC07f4d7682Fc1

## Deployed Contracts
- **BtcVaultStrategy**: 0x0A039085Ca2AD68a3FC77A9C5191C22B309126F8
- **BtcVaultToken**: 0xfF09B2B0AfEe51E29941091C4dd6B635780BC34a
- **sovaBTC**: 0x05aB19d77516414f7333a8fd52cC1F49FF8eAFA9
- **WBTC**: 0xe44b2870eFcd6Bb3C9305808012621f438e9636D
- **TBTC**: 0xE2b47f0dD766834b9DD2612D2d3632B05Ca89802

## Test Token Balances
- **sovaBTC**: 0.09 BTC (9,900,000 units)
- **WBTC**: 1.0001 BTC (100,010,100 units)
- **TBTC**: 0.1 BTC (10,000,000 units)

## Available Liquidity
- **Strategy Liquidity**: 0.001 BTC (100,000 units of sovaBTC)

## Test Cases

### 1. Deposit Flow Testing ✅
- [ ] Connect wallet to Base Sepolia
- [ ] Verify vault stats display correctly
- [ ] Test WBTC deposit:
  - [ ] Select WBTC as collateral
  - [ ] Enter amount (e.g., 0.0001 BTC)
  - [ ] Preview shares to receive
  - [ ] Approve token if needed
  - [ ] Execute deposit
  - [ ] Verify share balance updated
- [ ] Test TBTC deposit:
  - [ ] Select TBTC as collateral
  - [ ] Enter amount (e.g., 0.0001 BTC)
  - [ ] Preview and execute
- [ ] Test sovaBTC deposit:
  - [ ] Select sovaBTC as collateral
  - [ ] Enter amount (e.g., 0.0001 BTC)
  - [ ] Preview and execute

### 2. Redemption Flow Testing
- [ ] Request redemption:
  - [ ] Enter share amount to redeem
  - [ ] Preview BTC amount to receive
  - [ ] Submit redemption request
  - [ ] Verify request appears in queue
- [ ] Check redemption status:
  - [ ] View pending redemptions
  - [ ] Check approval status

### 3. Admin Panel Testing
- [ ] Access admin panel (requires manager role)
- [ ] Collateral Management:
  - [ ] View supported collaterals
  - [ ] Add new collateral (test address)
  - [ ] Remove collateral
  - [ ] Set collateral ratios
- [ ] Liquidity Management:
  - [ ] View current liquidity
  - [ ] Add liquidity
  - [ ] Remove liquidity
- [ ] Withdrawal Management:
  - [ ] View pending withdrawals
  - [ ] Approve withdrawals
  - [ ] Reject withdrawals

### 4. Edge Cases
- [ ] Try depositing unsupported collateral
- [ ] Try depositing 0 amount
- [ ] Try depositing more than balance
- [ ] Try redeeming more shares than owned
- [ ] Test with disconnected wallet

## Known Issues
- None yet

## Frontend Performance
- [ ] Page load time: < 2s
- [ ] Transaction response time: reasonable
- [ ] No console errors
- [ ] Responsive design works

## Test Results Summary
- **Status**: Testing in progress
- **Date**: 2025-08-12
- **Tester**: System