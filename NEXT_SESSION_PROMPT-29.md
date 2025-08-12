# Session 29: Multi-Network Contract Management & Deployment UI

## Context
We have successfully completed:
- ✅ Clean 2-contract BTC vault architecture deployed on Base Sepolia
- ✅ Professional glassmorphism UI with complete frontend
- ✅ Multi-network support with NetworkSwitcher (Session 27)
- ✅ Enhanced wallet connectivity supporting 15+ wallets (Session 28)
- ✅ Multi-network deployment framework in smart contracts (Session 25)
- ✅ All core functionality working and tested

## Current Challenge
While we have:
1. **Smart contract side**: Multi-network deployment framework (`DeployMultiNetwork.s.sol`, `NetworkConfig.sol`)
2. **Frontend side**: Basic network switching (`NetworkSwitcher.tsx`)

We're missing the connection between them - the ability to:
- Easily add new network deployments to the frontend
- Dynamically load contract addresses based on selected network
- Manage different deployments across networks from the UI
- Show deployment status across all networks

## Session 29 Objectives

### 🎯 Primary Goals
1. **Dynamic Contract Configuration** - Network-specific contract addresses
2. **Deployment Management UI** - Admin interface for managing deployments
3. **Network Status Dashboard** - View deployment status across all chains
4. **Easy Network Addition** - Simple process to add new network deployments
5. **Automatic Contract Detection** - Load correct contracts for selected network

## Task Breakdown

### 1. Contract Configuration System

#### A. Create Centralized Contract Registry
```typescript
// lib/deployments.ts
export const DEPLOYMENTS = {
  // Base Sepolia (current)
  84532: {
    name: 'Base Sepolia',
    contracts: {
      btcVaultStrategy: '0x0A039085Ca2AD68a3FC77A9C5191C22B309126F8',
      btcVaultToken: '0xfF09B2B0AfEe51E29941091C4dd6B635780BC34a',
      priceOracle: '0x698FBBde2c9FF3aF64C0ec48f174d5e8231FAacF',
    },
    collaterals: {
      WBTC: '0xe44b2870eFcd6Bb3C9305808012621f438e9636D',
      tBTC: '0x517E7047a3f21794c1fD4E3821EE2132cF69aBFe',
      sovaBTC: '0x8Cc03Df6CD3868B4bc5E85eF717C8adb2A2a04F8',
    },
    blockExplorer: 'https://sepolia.basescan.org',
    status: 'deployed',
    deployedAt: '2024-01-15',
  },
  
  // Base Mainnet (ready for deployment)
  8453: {
    name: 'Base',
    contracts: {
      btcVaultStrategy: '',
      btcVaultToken: '',
      priceOracle: '',
    },
    collaterals: {
      WBTC: '0x...',
      cbBTC: '0x...',
    },
    status: 'pending',
  },
  
  // More networks...
};
```

#### B. Dynamic Contract Hook
```typescript
// hooks/useContractAddresses.ts
export function useContractAddresses() {
  const { chain } = useNetwork();
  const deployment = DEPLOYMENTS[chain?.id];
  
  return {
    contracts: deployment?.contracts || {},
    collaterals: deployment?.collaterals || {},
    isDeployed: deployment?.status === 'deployed',
    explorerUrl: deployment?.blockExplorer,
  };
}
```

### 2. Deployment Management Interface

#### A. Admin Deployment Panel
Create a new admin section for managing deployments:
- View all networks and their deployment status
- Add/update contract addresses
- Verify deployments
- Export deployment configuration

#### B. Network Status Grid
```typescript
// components/admin/NetworkDeployments.tsx
- Grid showing all configured networks
- Status indicators (deployed, pending, not started)
- Quick actions (deploy, verify, update)
- Contract address management
```

### 3. Network Configuration UI

#### A. Add Network Modal
```typescript
// components/admin/AddNetworkModal.tsx
- Form to add new network configuration
- Input fields for:
  - Network name and chain ID
  - RPC URL
  - Contract addresses (if already deployed)
  - Collateral token addresses
  - Block explorer URL
```

#### B. Edit Deployment Modal
```typescript
// components/admin/EditDeploymentModal.tsx
- Update existing deployment details
- Add/remove collateral tokens
- Update oracle addresses
- Set deployment status
```

### 4. Deployment Status Dashboard

#### A. Multi-Network Overview
```typescript
// components/admin/DeploymentDashboard.tsx
interface DeploymentStatus {
  network: string;
  chainId: number;
  status: 'deployed' | 'pending' | 'not-started';
  contracts: {
    strategy: string;
    token: string;
    oracle: string;
  };
  tvl?: string;
  users?: number;
  lastUpdated: Date;
}
```

#### B. Visual Status Indicators
- Color-coded status badges
- Progress bars for pending deployments
- TVL and usage metrics (where deployed)
- Quick links to block explorers

### 5. Contract Auto-Detection

#### A. Network Change Handler
```typescript
// Automatically update contracts when network changes
useEffect(() => {
  if (chain?.id && DEPLOYMENTS[chain.id]) {
    updateContractAddresses(DEPLOYMENTS[chain.id].contracts);
  }
}, [chain?.id]);
```

#### B. Fallback Handling
- Show "Not Deployed" message for unsupported networks
- Provide deployment instructions
- Link to deployment documentation

### 6. Configuration Management

#### A. Local Storage for Custom Networks
```typescript
// Save custom network configurations locally
const saveCustomNetwork = (config: NetworkConfig) => {
  const custom = JSON.parse(localStorage.getItem('customNetworks') || '{}');
  custom[config.chainId] = config;
  localStorage.setItem('customNetworks', JSON.stringify(custom));
};
```

#### B. Import/Export Configuration
- Export deployment configuration as JSON
- Import configuration from file
- Share configurations between team members

### 7. Implementation Steps

#### Phase 1: Core Infrastructure
1. Create deployment registry structure
2. Build contract address management system
3. Implement network-aware hooks
4. Update existing components to use dynamic addresses

#### Phase 2: Admin Interface
1. Create deployment management UI
2. Build network status dashboard
3. Add network configuration forms
4. Implement edit/update functionality

#### Phase 3: Integration
1. Connect UI to contract registry
2. Test network switching with different deployments
3. Implement auto-detection logic
4. Add error handling for missing deployments

#### Phase 4: Polish & Testing
1. Add loading states and transitions
2. Implement comprehensive error handling
3. Test across all configured networks
4. Document deployment process

## File Structure

```
frontend/
├── lib/
│   ├── deployments.ts          # Centralized deployment registry
│   ├── networks.ts              # Network configurations (update)
│   └── contracts.ts             # Dynamic contract loading (update)
├── hooks/
│   ├── useContractAddresses.ts # Dynamic address hook
│   ├── useDeploymentStatus.ts  # Deployment status hook
│   └── useNetworkConfig.ts     # Network config management
├── components/
│   └── admin/
│       ├── DeploymentDashboard.tsx    # Main dashboard
│       ├── NetworkDeployments.tsx     # Network grid view
│       ├── AddNetworkModal.tsx        # Add network form
│       ├── EditDeploymentModal.tsx    # Edit deployment form
│       ├── DeploymentStatus.tsx       # Status indicators
│       └── ContractVerifier.tsx       # Verify deployments
└── app/
    └── admin/
        └── deployments/
            └── page.tsx         # Deployment management page
```

## Success Metrics

1. **Easy Network Addition**: < 2 minutes to add a new network
2. **Automatic Detection**: 100% accurate contract loading
3. **Status Visibility**: Real-time deployment status across all networks
4. **Configuration Export**: One-click export/import of configurations
5. **User Experience**: Seamless network switching with correct contracts

## UI/UX Requirements

### Visual Design
- Maintain glassmorphism theme throughout
- Use consistent status colors (green=deployed, yellow=pending, gray=not started)
- Clear visual hierarchy for network information
- Responsive grid layout for network cards

### Interactions
- Smooth transitions when switching networks
- Loading states during contract detection
- Clear error messages for missing deployments
- Success confirmations for updates

## Technical Considerations

### Performance
- Cache deployment configurations
- Lazy load network-specific data
- Optimize for frequent network switching

### Security
- Validate contract addresses
- Verify deployment ownership
- Secure storage of configurations

### Compatibility
- Support all EVM networks
- Handle custom RPC endpoints
- Work with all wallet types

## Testing Scenarios

1. **Network Switching**: Verify correct contracts load for each network
2. **New Deployment**: Add a new network and verify it appears
3. **Update Addresses**: Change contract addresses and verify updates
4. **Missing Deployment**: Handle networks without deployments gracefully
5. **Export/Import**: Test configuration sharing between environments

## Example User Flow

### Admin Adding New Network Deployment:
1. Navigate to Admin → Deployments
2. Click "Add Network"
3. Fill in network details and contract addresses
4. Save configuration
5. See new network in deployment grid
6. Switch to new network to verify

### User Switching Networks:
1. Click network switcher
2. Select new network
3. Contracts automatically update
4. UI shows correct deployment status
5. Transactions use new contract addresses

## Alternative Approaches

### Option A: Environment Variables
- Pros: Simple, secure
- Cons: Requires rebuild for changes

### Option B: Backend API
- Pros: Centralized, real-time updates
- Cons: Additional infrastructure needed

### Option C: IPFS/Decentralized Storage
- Pros: Decentralized, permanent
- Cons: More complex, slower updates

### Recommended: Hybrid Approach
- Core networks in code
- Custom networks in local storage
- Optional backend for production

## Notes

- Start with static configuration, add dynamic features incrementally
- Ensure backward compatibility with current Base Sepolia deployment
- Consider gas costs when displaying multiple network stats
- Plan for future cross-chain features

## Dependencies

```json
{
  "dependencies": {
    // Already installed, may need updates
    "wagmi": "^2.x.x",
    "viem": "^2.x.x",
    "@rainbow-me/rainbowkit": "^2.x.x"
  }
}
```

---

**Session Goal**: Create a comprehensive multi-network contract management system that makes it easy to deploy and manage the BTC vault across multiple chains, with a professional admin interface for deployment management and automatic contract detection for users.