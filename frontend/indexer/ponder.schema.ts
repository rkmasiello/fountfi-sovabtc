import { createSchema } from "@ponder/core";

export default createSchema((p) => ({
  // User tracking
  btcUsers: p.createTable({
    id: p.string(), // user address
    firstSeenBlock: p.bigint(),
    firstSeenTimestamp: p.bigint(),
    totalDeposited: p.bigint(),
    totalWithdrawn: p.bigint(),
    currentShares: p.bigint(),
    lastActivityBlock: p.bigint(),
    lastActivityTimestamp: p.bigint(),
  }),

  // Deposit events from BtcVaultToken (ERC4626 Deposit event)
  btcDeposits: p.createTable({
    id: p.string(), // txHash-logIndex
    sender: p.string(),
    owner: p.string(),
    assets: p.bigint(),
    shares: p.bigint(),
    collateralToken: p.string().optional(), // From depositCollateral events
    timestamp: p.bigint(),
    blockNumber: p.bigint(),
    txHash: p.string(),
  }),

  // Withdraw events from BtcVaultToken (ERC4626 Withdraw event)
  btcWithdrawals: p.createTable({
    id: p.string(), // txHash-logIndex
    sender: p.string(),
    receiver: p.string(),
    owner: p.string(),
    assets: p.bigint(),
    shares: p.bigint(),
    timestamp: p.bigint(),
    blockNumber: p.bigint(),
    txHash: p.string(),
  }),

  // Transfer events for tracking shares
  btcTransfers: p.createTable({
    id: p.string(), // txHash-logIndex
    from: p.string(),
    to: p.string(),
    value: p.bigint(),
    timestamp: p.bigint(),
    blockNumber: p.bigint(),
    txHash: p.string(),
  }),

  // Collateral updates from strategy
  collateralUpdates: p.createTable({
    id: p.string(), // txHash-logIndex
    collateralToken: p.string(),
    isSupported: p.boolean(),
    timestamp: p.bigint(),
    blockNumber: p.bigint(),
    txHash: p.string(),
  }),

  // Liquidity events from strategy
  liquidityEvents: p.createTable({
    id: p.string(), // txHash-logIndex
    eventType: p.string(), // 'added' or 'removed'
    amount: p.bigint(),
    totalLiquidity: p.bigint(),
    timestamp: p.bigint(),
    blockNumber: p.bigint(),
    txHash: p.string(),
  }),

  // NAV updates from strategy reports
  navUpdates: p.createTable({
    id: p.string(), // txHash-logIndex
    nav: p.bigint(),
    gain: p.bigint(),
    loss: p.bigint(),
    totalAssets: p.bigint(),
    timestamp: p.bigint(),
    blockNumber: p.bigint(),
    txHash: p.string(),
  }),

  // Strategy report events
  strategyReports: p.createTable({
    id: p.string(), // txHash-logIndex
    nav: p.bigint(),
    gain: p.bigint(),
    loss: p.bigint(),
    totalAssets: p.bigint(),
    timestamp: p.bigint(),
    blockNumber: p.bigint(),
    txHash: p.string(),
  }),

  // Vault metrics (hourly snapshots)
  vaultMetrics: p.createTable({
    id: p.string(), // timestamp-hour
    totalAssets: p.bigint(),
    totalShares: p.bigint(),
    sharePrice: p.bigint(),
    totalUsers: p.int(),
    activeUsers: p.int(), // Active in last 24h
    totalDeposits: p.bigint(),
    totalWithdrawals: p.bigint(),
    timestamp: p.bigint(),
    blockNumber: p.bigint(),
  }),

  // User position tracking
  userPositions: p.createTable({
    id: p.string(), // userAddress-blockNumber
    userAddress: p.string(),
    shares: p.bigint(),
    assets: p.bigint(), // Calculated based on share price
    timestamp: p.bigint(),
    blockNumber: p.bigint(),
  }),

  // Transaction logs for debugging
  transactionLogs: p.createTable({
    id: p.string(), // txHash
    blockNumber: p.bigint(),
    timestamp: p.bigint(),
    from: p.string(),
    to: p.string(),
    value: p.bigint(),
    gasUsed: p.bigint().optional(),
    gasPrice: p.bigint().optional(),
    status: p.int(), // 1 for success, 0 for failure
  }),
}));