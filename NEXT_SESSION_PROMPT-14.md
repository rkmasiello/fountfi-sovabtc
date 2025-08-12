# Next Session Prompt for Multi-Collateral BTC Vault

## Session 14: Frontend Debugging & Component Fixes

You are continuing work on the FountFi Multi-Collateral BTC Vault system. Review ASSESSMENT_REPORT.md for the complete development history.

### ⚠️ Current Status:
- Smart contracts are fully deployed and operational on Base Sepolia
- Frontend application has been built but contains bugs that need fixing
- Components may have import/export issues, rendering problems, or transaction errors
- All backend infrastructure is ready but frontend must be debugged before production deployment

### 🎯 Session 14 Goals: Systematically Debug and Fix Frontend Issues

**PRIMARY OBJECTIVE: Identify and fix all frontend bugs to make the application production-ready**

### 🔗 Frontend Structure:
- **Location**: `/frontend` directory
- **Framework**: Next.js 14 with App Router
- **Components**: Located in `/frontend/components`
- **Wallet**: RainbowKit for wallet connection
- **Contract Interaction**: wagmi v2 and viem
- **Styling**: Tailwind CSS

### 📋 Systematic Debugging Tasks:

#### 1. Initial Assessment & Setup
**Priority: CRITICAL** - Understand current state

First, assess the current state of the frontend:

```bash
cd frontend
npm install
npm run dev
```

Tasks:
- [ ] Start development server and note any build errors
- [ ] Open browser console and check for runtime errors
- [ ] Document all error messages and warnings
- [ ] Check package.json for dependency issues
- [ ] Verify all environment variables are set correctly
- [ ] Test in multiple browsers (Chrome, Firefox, Safari)

Common issues to look for:
- Missing dependencies
- Import/export mismatches
- TypeScript errors
- Environment variable issues
- CORS problems

#### 2. Component Import/Export Fixes
**Priority: HIGH** - Components must be properly exported

Review and fix all component exports:

```typescript
// Check each component file for proper exports
// components/WalletConnect.tsx
export default function WalletConnect() { ... }
// OR
export { WalletConnect }

// Ensure imports match exports
import WalletConnect from '@/components/WalletConnect'
// OR
import { WalletConnect } from '@/components/WalletConnect'
```

Components to verify:
- [ ] WalletConnect.tsx
- [ ] VaultStats.tsx
- [ ] DepositForm.tsx
- [ ] RedemptionQueue.tsx
- [ ] AdminPanel.tsx
- [ ] OnboardingWizard.tsx

For each component:
- [ ] Check export statement (default vs named)
- [ ] Verify import statements match
- [ ] Ensure TypeScript types are exported if needed
- [ ] Fix any circular dependencies

#### 3. Wallet Connection Issues
**Priority: CRITICAL** - Users must be able to connect

Debug wallet connection flow:

Tasks:
- [ ] Verify RainbowKit is properly configured
- [ ] Check WalletConnect project ID is valid
- [ ] Test wallet connection with MetaMask
- [ ] Test with other wallets (WalletConnect, Coinbase)
- [ ] Verify chain switching works (to Base Sepolia)
- [ ] Check account/address state management
- [ ] Fix any hydration mismatches

Common fixes:
```typescript
// Ensure providers are wrapped correctly
'use client';

// Check wagmi config
const config = createConfig({
  chains: [baseSepolia],
  transports: {
    [baseSepolia.id]: http(),
  },
});

// Verify RainbowKit provider setup
<WagmiProvider config={config}>
  <QueryClientProvider client={queryClient}>
    <RainbowKitProvider>
      {children}
    </RainbowKitProvider>
  </QueryClientProvider>
</WagmiProvider>
```

#### 4. Contract Interaction Debugging
**Priority: HIGH** - Core functionality must work

Fix contract read/write operations:

Tasks:
- [ ] Verify contract ABIs are correct and complete
- [ ] Check contract addresses in environment variables
- [ ] Test reading vault stats (totalSupply, totalAssets)
- [ ] Test deposit function with mock tokens
- [ ] Test redemption queue operations
- [ ] Fix any gas estimation errors
- [ ] Handle transaction rejection properly

Debug pattern:
```typescript
// Add extensive error handling
try {
  const { hash } = await writeContract({
    address: VAULT_ADDRESS,
    abi: vaultABI,
    functionName: 'depositCollateral',
    args: [tokenAddress, amount, userAddress],
  });
  
  // Wait for transaction
  const receipt = await waitForTransactionReceipt({ hash });
  console.log('Transaction successful:', receipt);
} catch (error) {
  console.error('Transaction failed:', error);
  // Show user-friendly error message
}
```

#### 5. State Management & Data Flow
**Priority: MEDIUM** - Ensure data updates properly

Fix state synchronization issues:

Tasks:
- [ ] Verify data fetching with useContractRead hooks
- [ ] Fix any stale data issues
- [ ] Ensure balance updates after transactions
- [ ] Fix loading states and skeletons
- [ ] Handle error states gracefully
- [ ] Test data refresh/polling

Common patterns to implement:
```typescript
// Auto-refresh data
const { data, isError, isLoading, refetch } = useContractRead({
  address: VAULT_ADDRESS,
  abi: vaultABI,
  functionName: 'totalAssets',
  watch: true, // Auto-refresh
});

// Refetch after transaction
useEffect(() => {
  if (isSuccess) {
    refetch();
  }
}, [isSuccess, refetch]);
```

#### 6. UI/UX Issues
**Priority: MEDIUM** - Polish user experience

Fix visual and interaction issues:

Tasks:
- [ ] Fix responsive design breakpoints
- [ ] Ensure buttons are clickable and show proper states
- [ ] Fix form validation and error messages
- [ ] Correct number formatting (especially for BTC amounts)
- [ ] Fix modal/dialog behavior
- [ ] Ensure loading spinners work
- [ ] Test dark mode if implemented

#### 7. Testing All User Flows
**Priority: CRITICAL** - Ensure everything works end-to-end

Test complete user journeys:

**New User Flow:**
- [ ] Land on homepage
- [ ] See onboarding wizard
- [ ] Connect wallet successfully
- [ ] Switch to Base Sepolia
- [ ] Get test tokens from faucet
- [ ] Complete first deposit
- [ ] View updated balances

**Deposit Flow:**
- [ ] Select collateral type (WBTC/tBTC/sovaBTC)
- [ ] Enter amount (with validation)
- [ ] Approve token spending
- [ ] Execute deposit
- [ ] See confirmation
- [ ] View updated mcBTC balance

**Redemption Flow:**
- [ ] Enter redemption amount
- [ ] Submit redemption request
- [ ] View in queue
- [ ] See countdown timer
- [ ] Process redemption (admin)
- [ ] Receive sovaBTC

**Admin Flow:**
- [ ] Access admin panel (role check)
- [ ] Process redemptions
- [ ] Update price oracle
- [ ] Pause/unpause vault
- [ ] View system metrics

#### 8. Build & Deployment Preparation
**Priority: HIGH** - Must build successfully

Ensure production build works:

```bash
npm run build
npm run start  # Test production build locally
```

Tasks:
- [ ] Fix any build errors
- [ ] Resolve TypeScript issues
- [ ] Optimize bundle size
- [ ] Test production build locally
- [ ] Verify environment variables for production
- [ ] Update .env.production file

#### 9. Cross-Browser & Device Testing
**Priority: MEDIUM** - Ensure compatibility

Test on multiple platforms:

- [ ] Chrome (latest)
- [ ] Firefox (latest)
- [ ] Safari (if available)
- [ ] Mobile browsers
- [ ] Different screen sizes
- [ ] Slow network conditions

### 🐛 Common Frontend Issues & Solutions:

#### Issue: "Module not found" errors
```typescript
// Solution: Check import paths and ensure files exist
import { ComponentName } from '@/components/ComponentName'
// Verify tsconfig.json paths are correct
```

#### Issue: Hydration mismatches
```typescript
// Solution: Ensure client-only code is wrapped
'use client';
// Or use dynamic imports with ssr: false
const Component = dynamic(() => import('./Component'), { ssr: false });
```

#### Issue: BigInt serialization errors
```typescript
// Solution: Format BigInt values before rendering
const formatted = formatUnits(bigIntValue, decimals);
```

#### Issue: Wallet not connecting
```typescript
// Solution: Check provider setup and chain config
// Ensure WalletConnect project ID is valid
// Verify RPC URLs are correct
```

### 📊 Testing Checklist:

Before marking frontend as ready:

- [ ] All components render without errors
- [ ] Wallet connection works reliably
- [ ] All contract interactions succeed
- [ ] Forms validate and submit correctly
- [ ] Error messages are user-friendly
- [ ] Loading states work properly
- [ ] Data refreshes after transactions
- [ ] Responsive design works on all devices
- [ ] No console errors or warnings
- [ ] Production build succeeds

### 🔧 Debugging Tools:

```bash
# Check for TypeScript errors
npm run type-check

# Run linter
npm run lint

# Check bundle size
npm run analyze

# Test production build
npm run build && npm run start

# Clear cache if needed
rm -rf .next node_modules
npm install
```

### Success Criteria:
- [ ] Development server runs without errors
- [ ] All user flows work end-to-end
- [ ] No console errors in browser
- [ ] Production build succeeds
- [ ] All tests pass (if any exist)
- [ ] Components are properly typed
- [ ] Wallet connection is reliable
- [ ] Transactions execute successfully
- [ ] UI is responsive and polished

### After Session 14:
Once all frontend bugs are fixed:
1. **Deploy to Vercel staging** for final testing
2. **Get team/community feedback** on UX
3. **Deploy to production** (Session 16)
4. **Begin security audit** process
5. **Start marketing** preparations

This session focuses on systematically debugging and fixing all frontend issues. Take time to properly test each component and user flow. A working frontend is critical before the production deployment.