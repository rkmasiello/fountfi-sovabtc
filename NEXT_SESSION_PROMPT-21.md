# Session 21: Frontend Components Update and Testnet Deployment

## Context
In Sessions 18-20, we successfully:
- Refactored to clean 2-contract architecture (BtcVaultStrategy + BtcVaultToken)
- Removed all deprecated contracts and tests
- Updated SDK to `BtcVaultSDK` with new methods
- Updated frontend ABIs with new contract interfaces
- Created deployment configuration and verification scripts
- All 425 tests passing

The smart contracts are complete and the SDK/ABIs are updated. Now we need to update the frontend components and deploy to testnet.

## Branch
Continue on branch: `sovabtc-2`

## Phase 1: Frontend Component Updates

### Task 1: Update VaultStats Component
File: `frontend/components/VaultStats.tsx`
- Update to use `BTC_VAULT_TOKEN_ABI` and `BTC_VAULT_STRATEGY_ABI`
- Replace old contract addresses with new ones after deployment
- Update method calls:
  - Use `totalAssets()` and `totalSupply()` from token
  - Use `availableLiquidity()` from strategy
  - Calculate share price from totalAssets/totalSupply

### Task 2: Update RedemptionQueue Component
File: `frontend/components/RedemptionQueue.tsx`
- Remove queue-based logic (no longer exists)
- Implement managed withdrawal display:
  - Show pending withdrawal requests
  - Display approval status
  - Remove claim functionality (handled by manager)
- Update to show liquidity availability from strategy

### Task 3: Update DepositForm Component
File: `frontend/components/DepositForm.tsx`
- Update to use `depositCollateral()` method
- Use `previewDepositCollateral()` for share preview
- Update approval to approve the vault token contract
- Show supported collaterals from strategy

### Task 4: Update AdminPanel Component
File: `frontend/components/AdminPanel.tsx`
- Add collateral management:
  - Add/remove collateral tokens
  - View collateral balances
- Add liquidity management:
  - Add/remove sovaBTC liquidity
  - View available liquidity
- Update withdrawal processing for managed pattern

### Task 5: Update Contract Addresses
File: `frontend/lib/contracts.ts`
- Remove old contract addresses
- Add placeholder for new deployment addresses
- Update contract initialization with new ABIs

## Phase 2: Testnet Deployment

### Task 6: Deploy to Base Sepolia
```bash
# Set environment variables
export PRIVATE_KEY=0x95a18be97b616ea6a2c79e1a82090f66686f15548b6cbb621a6a6417677759d4
export ETHERSCAN_API_KEY=KI5PMY8D813UGVZS7MEFMW7BW4AU8A14DV
export NETWORK=baseSepolia

# Deploy contracts
forge script script/deploy/DeployBtcVault.s.sol \
  --rpc-url base-sepolia \
  --private-key $PRIVATE_KEY \
  --broadcast \
  --verify

# Run verification
forge script script/verify/VerifyBtcVault.s.sol \
  --rpc-url base-sepolia \
  --private-key $PRIVATE_KEY
```

### Task 7: Update Configuration with Deployed Addresses
After deployment:
1. Update `deployment.config.json` with deployed addresses
2. Update `frontend/lib/contracts.ts` with deployed addresses
3. Update `sdk/VaultSDK.ts` BASE_SEPOLIA_ADDRESSES
4. Commit deployment artifacts to git

## Phase 3: Integration Testing

### Task 8: Test Frontend Integration
1. Start frontend locally:
   ```bash
   cd frontend
   npm install
   npm run dev
   ```
2. Connect wallet to Base Sepolia
3. Test core flows:
   - View vault stats
   - Deposit collateral
   - Request withdrawal
   - Admin functions (if role assigned)

### Task 9: End-to-End Testing Script
Create `test/integration/E2ETest.s.sol`:
- Deploy contracts
- Add collateral support
- Perform deposits
- Process withdrawals
- Verify all state changes

## Phase 4: Documentation

### Task 10: Update README
Update main `README.md`:
- New architecture overview
- Updated deployment instructions
- Frontend setup guide
- Contract addresses for Base Sepolia

### Task 11: Create Migration Guide
Create `docs/MIGRATION_GUIDE.md`:
- Breaking changes from old architecture
- New method names and signatures
- Frontend component changes
- SDK migration examples

### Task 12: Update Integration Guide
Update `docs/INTEGRATION_GUIDE.md`:
- Add deployed contract addresses
- Update example code with real addresses
- Add frontend integration examples

## Expected Outcomes

By end of session:
1. ✅ All frontend components updated for new architecture
2. ✅ Contracts deployed and verified on Base Sepolia
3. ✅ Frontend connected to deployed contracts
4. ✅ Core user flows tested end-to-end
5. ✅ Documentation fully updated
6. ✅ Migration guide created

## Important Notes

1. **Contract Addresses**: After deployment, update all references in:
   - `frontend/lib/contracts.ts`
   - `sdk/VaultSDK.ts`
   - `deployment.config.json`
   - Documentation files

2. **Testing Order**:
   - Deploy contracts first
   - Verify deployment
   - Update frontend with addresses
   - Test integration

3. **Liquidity Setup**: After deployment, add initial sovaBTC liquidity for testing withdrawals

4. **Role Management**: Ensure deployer has necessary roles for admin functions

## Success Criteria

- [ ] Frontend displays correct vault stats
- [ ] Users can deposit collateral and receive shares
- [ ] Withdrawal requests are properly handled
- [ ] Admin can manage collateral and liquidity
- [ ] All documentation is current and accurate
- [ ] Testnet deployment is verified and functional

## Helpful Commands

```bash
# Check deployment
cast call <STRATEGY_ADDRESS> "totalAssets()" --rpc-url base-sepolia

# Add collateral support (as admin)
cast send <STRATEGY_ADDRESS> "addCollateral(address,uint8)" <TOKEN> 8 \
  --private-key $PRIVATE_KEY --rpc-url base-sepolia

# Verify contract on Etherscan
forge verify-contract <ADDRESS> <CONTRACT_NAME> \
  --etherscan-api-key $ETHERSCAN_API_KEY --chain base-sepolia

# Frontend development
cd frontend && npm run dev

# Run integration tests
forge test --match-contract E2ETest -vvv
```

This session will complete the frontend integration and establish a working deployment on Base Sepolia testnet.