# Session 30: Multi-Network Contract Management & Dynamic Deployment UI

## Context
We have successfully completed:
- ✅ Clean 2-contract BTC vault architecture deployed on Base Sepolia
- ✅ Professional glassmorphism UI with complete frontend (see `REPORT_FE.md`)
- ✅ Multi-network support with NetworkSwitcher (Session 27)
- ✅ Enhanced wallet connectivity supporting 15+ wallets (Session 28)
- ✅ Professional color theme system with Sova branding (Session 29)
- ✅ Multi-network deployment framework in smart contracts (Session 25)
- ✅ All core functionality working and tested

## Current Challenge
While we have excellent multi-network infrastructure on both frontend and smart contract sides, we lack the crucial connection between them - the ability to:
- **Dynamically manage** contract addresses across networks
- **Easily add** new network deployments without code changes
- **Track deployment status** across all chains
- **Auto-detect** contracts based on selected network
- **Visualize** deployment health and metrics

## Session 30 Objectives

### 🎯 Primary Goals
1. **Dynamic Contract Registry** - Database of deployments across networks
2. **Deployment Management UI** - Admin interface for managing deployments
3. **Network Status Dashboard** - Real-time deployment status visualization
4. **Auto-Detection System** - Seamless contract loading per network
5. **Configuration Import/Export** - Share deployments between environments

## Implementation Plan

### 1. Contract Registry System

#### A. Create Deployment Database Structure
```typescript
// lib/deployments/registry.ts
export interface DeploymentInfo {
  network: {
    chainId: number;
    name: string;
    rpcUrl: string;
    blockExplorer: string;
    nativeCurrency: {
      name: string;
      symbol: string;
      decimals: number;
    };
  };
  contracts: {
    btcVaultStrategy: string;
    btcVaultToken: string;
    priceOracle: string;
  };
  collaterals: {
    [symbol: string]: {
      address: string;
      decimals: number;
      name: string;
      oracleId?: string;
    };
  };
  deployment: {
    timestamp: string;
    blockNumber: number;
    deployer: string;
    verified: boolean;
  };
  status: 'active' | 'pending' | 'deprecated' | 'not-deployed';
  metrics?: {
    tvl: string;
    users: number;
    transactions: number;
    lastUpdated: string;
  };
}

export class DeploymentRegistry {
  private deployments: Map<number, DeploymentInfo>;
  
  constructor() {
    this.loadDeployments();
  }
  
  // Methods to add, update, remove, query deployments
  addDeployment(chainId: number, info: DeploymentInfo): void;
  updateDeployment(chainId: number, updates: Partial<DeploymentInfo>): void;
  getDeployment(chainId: number): DeploymentInfo | null;
  getAllDeployments(): DeploymentInfo[];
  exportConfig(): string;
  importConfig(json: string): void;
}
```

#### B. Pre-configured Network Templates
```typescript
// lib/deployments/networks.ts
export const NETWORK_TEMPLATES = {
  // Mainnets
  ethereum: { chainId: 1, name: 'Ethereum', ... },
  base: { chainId: 8453, name: 'Base', ... },
  arbitrum: { chainId: 42161, name: 'Arbitrum One', ... },
  optimism: { chainId: 10, name: 'Optimism', ... },
  polygon: { chainId: 137, name: 'Polygon', ... },
  avalanche: { chainId: 43114, name: 'Avalanche', ... },
  
  // Testnets
  sepolia: { chainId: 11155111, name: 'Sepolia', ... },
  baseSepolia: { chainId: 84532, name: 'Base Sepolia', ... },
  // ... more networks
};

// Common collateral tokens per network
export const COLLATERAL_TEMPLATES = {
  ethereum: {
    WBTC: { address: '0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599', decimals: 8 },
    tBTC: { address: '0x18084fbA666a33d37592fA2633fD49a74DD93a88', decimals: 18 },
    // ...
  },
  // ... per network
};
```

### 2. Admin Deployment Interface

#### A. Deployment Management Page
```typescript
// app/admin/deployments/page.tsx
- Network grid view showing all configured networks
- Status indicators (deployed, pending, not-started)
- Quick actions (deploy, verify, update, deprecate)
- Metrics display (TVL, users, transactions)
```

#### B. Add Network Modal
```typescript
// components/admin/AddNetworkModal.tsx
interface AddNetworkModalProps {
  onAdd: (deployment: DeploymentInfo) => void;
}

Features:
- Network selection from templates or custom
- Contract address inputs with validation
- Collateral token configuration
- Auto-fill from known deployments
- Test connection before saving
```

#### C. Deployment Details Panel
```typescript
// components/admin/DeploymentDetails.tsx
interface DeploymentDetailsProps {
  deployment: DeploymentInfo;
  onUpdate: (updates: Partial<DeploymentInfo>) => void;
}

Features:
- Edit contract addresses
- Add/remove collateral tokens
- Update RPC endpoints
- Verify deployment on-chain
- View transaction history
- Export single deployment config
```

### 3. Network Status Dashboard

#### A. Multi-Network Overview
```typescript
// components/admin/NetworkDashboard.tsx
interface NetworkMetrics {
  chainId: number;
  name: string;
  status: 'online' | 'offline' | 'degraded';
  blockHeight: number;
  gasPrice: string;
  tvl: string;
  activeUsers: number;
  last24hTransactions: number;
  healthScore: number; // 0-100
}

Features:
- Real-time network status monitoring
- TVL aggregation across networks
- User activity heatmap
- Transaction volume charts
- Gas price tracking
- Alert system for issues
```

#### B. Visual Status Grid
```typescript
// components/admin/NetworkGrid.tsx
- Card-based layout for each network
- Color-coded status (green/yellow/red)
- Sparkline charts for activity
- Quick stats display
- Drill-down to details
```

### 4. Auto-Detection & Loading System

#### A. Network-Aware Hooks
```typescript
// hooks/useDeploymentConfig.ts
export function useDeploymentConfig() {
  const { chain } = useNetwork();
  const registry = useDeploymentRegistry();
  
  const deployment = useMemo(() => {
    return registry.getDeployment(chain?.id);
  }, [chain?.id, registry]);
  
  return {
    deployment,
    contracts: deployment?.contracts,
    collaterals: deployment?.collaterals,
    isDeployed: deployment?.status === 'active',
    switchToNetwork: (chainId: number) => {...},
  };
}
```

#### B. Dynamic Contract Loading
```typescript
// hooks/useVaultContract.ts
export function useVaultContract() {
  const { deployment } = useDeploymentConfig();
  
  const strategyContract = useContract({
    address: deployment?.contracts.btcVaultStrategy,
    abi: BTC_VAULT_STRATEGY_ABI,
    enabled: !!deployment,
  });
  
  const tokenContract = useContract({
    address: deployment?.contracts.btcVaultToken,
    abi: BTC_VAULT_TOKEN_ABI,
    enabled: !!deployment,
  });
  
  return { strategyContract, tokenContract };
}
```

### 5. Configuration Management

#### A. Import/Export UI
```typescript
// components/admin/ConfigManager.tsx
Features:
- Export all deployments as JSON
- Import deployments from JSON
- Validate imported configs
- Merge with existing configs
- Backup/restore functionality
- Share via URL/QR code
```

#### B. Storage Strategy
```typescript
// lib/storage/deploymentStorage.ts
Options:
1. Local Storage (development)
2. Backend API (production)
3. IPFS (decentralized)
4. Contract-based (on-chain)

export class DeploymentStorage {
  async save(deployments: DeploymentInfo[]): Promise<void>;
  async load(): Promise<DeploymentInfo[]>;
  async sync(): Promise<void>;
}
```

### 6. User-Facing Integration

#### A. Network Selector Enhancement
```typescript
// components/NetworkSwitcher.tsx (update)
- Show deployment status per network
- Gray out non-deployed networks
- Display network metrics (TVL, gas)
- "Request Deployment" option
```

#### B. Deployment Status Banner
```typescript
// components/DeploymentStatus.tsx
- Show current network deployment status
- Alert if network not supported
- Link to supported networks
- Admin: link to deployment page
```

### 7. Testing & Validation

#### A. Deployment Verification
```typescript
// utils/verifyDeployment.ts
export async function verifyDeployment(
  chainId: number,
  deployment: DeploymentInfo
): Promise<ValidationResult> {
  // Check contract bytecode
  // Verify contract ownership
  // Test basic operations
  // Check collateral support
  // Validate oracle feeds
}
```

#### B. Network Health Checks
```typescript
// utils/networkHealth.ts
export async function checkNetworkHealth(
  chainId: number
): Promise<HealthStatus> {
  // RPC connectivity
  // Block production rate
  // Gas price stability
  // Contract responsiveness
}
```

## File Structure

```
frontend/
├── app/
│   └── admin/
│       └── deployments/
│           ├── page.tsx                # Main deployment management page
│           └── [chainId]/
│               └── page.tsx            # Network-specific details
├── components/
│   └── admin/
│       ├── NetworkDashboard.tsx       # Overview dashboard
│       ├── NetworkGrid.tsx            # Network cards grid
│       ├── DeploymentDetails.tsx      # Deployment detail panel
│       ├── AddNetworkModal.tsx        # Add network form
│       ├── EditDeploymentModal.tsx    # Edit deployment form
│       ├── ConfigManager.tsx          # Import/export UI
│       └── NetworkMetrics.tsx         # Metrics display
├── hooks/
│   ├── useDeploymentConfig.ts        # Current deployment config
│   ├── useDeploymentRegistry.ts      # Registry access
│   ├── useNetworkMetrics.ts          # Network metrics
│   └── useVaultContract.ts           # Dynamic contract loading
├── lib/
│   └── deployments/
│       ├── registry.ts                # DeploymentRegistry class
│       ├── networks.ts                # Network templates
│       ├── collaterals.ts            # Collateral templates
│       ├── storage.ts                 # Storage abstraction
│       └── validator.ts              # Config validation
└── utils/
    ├── verifyDeployment.ts           # Deployment verification
    ├── networkHealth.ts              # Health checks
    └── metricsCollector.ts           # Metrics gathering
```

## Success Criteria

1. **Easy Network Addition**: < 2 minutes to add a new deployed network
2. **Automatic Detection**: Contracts load correctly when switching networks
3. **Visual Clarity**: Clear deployment status across all networks
4. **Data Persistence**: Configurations persist across sessions
5. **Error Prevention**: Validation prevents invalid configurations
6. **Performance**: No noticeable lag when switching networks

## UI/UX Requirements

### Admin Interface
- Clean, data-dense layout for deployment overview
- Intuitive forms with validation feedback
- Confirmation dialogs for critical actions
- Export/import with clear instructions
- Responsive design for mobile management

### User Experience
- Seamless network switching
- Clear indicators of deployment status
- Helpful messages for unsupported networks
- No breaking changes to existing UI

## Implementation Priority

### Phase 1: Core Infrastructure (Day 1)
1. DeploymentRegistry implementation
2. Network and collateral templates
3. Basic storage (localStorage)
4. Deployment verification utility

### Phase 2: Admin UI (Day 1-2)
1. Deployment management page
2. Add/Edit network modals
3. Network grid view
4. Basic metrics display

### Phase 3: Integration (Day 2)
1. Hook implementations
2. Update existing components
3. Dynamic contract loading
4. Testing and validation

### Phase 4: Enhancement (Day 2-3)
1. Network dashboard
2. Advanced metrics
3. Import/export functionality
4. Health monitoring

## Testing Plan

1. **Unit Tests**
   - Registry operations
   - Validation functions
   - Hook behavior

2. **Integration Tests**
   - Network switching
   - Contract loading
   - Config persistence

3. **E2E Tests**
   - Add new network flow
   - Edit deployment flow
   - Import/export flow

4. **Manual Testing**
   - Cross-browser compatibility
   - Mobile responsiveness
   - Error scenarios

## Alternative Approaches Considered

### Backend API
- Pros: Centralized, real-time sync, audit trail
- Cons: Additional infrastructure, latency

### On-Chain Registry
- Pros: Decentralized, transparent, immutable
- Cons: Gas costs, slower updates

### Hybrid Solution (Recommended)
- Local storage for development
- Optional backend for production
- On-chain registry for critical networks

## Notes & Considerations

- Start with Base Sepolia deployment as reference
- Ensure backward compatibility with hardcoded addresses
- Plan for gradual migration from static to dynamic
- Consider rate limiting for RPC calls
- Implement caching for network metrics
- Add analytics for deployment usage

## Dependencies

No new dependencies required - uses existing:
- wagmi/viem for blockchain interaction
- React hooks for state management
- Local storage for persistence

---

**Session Goal**: Build a comprehensive multi-network contract management system that enables easy deployment tracking, dynamic contract loading, and visual deployment status across all supported networks, making the vault truly multi-chain ready.