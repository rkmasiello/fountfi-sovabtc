import { createConfig } from "ponder";
import MultiBTCVaultAbi from "./abis/MultiBTCVault.json";
import ManagedRedemptionQueueAbi from "./abis/ManagedRedemptionQueue.json";

export default createConfig({
  chains: {
    baseSepolia: {
      id: 84532,
      rpc: process.env.PONDER_RPC_URL_1!,
    },
  },
  contracts: {
    MultiBTCVault: {
      chain: "baseSepolia",
      abi: MultiBTCVaultAbi,
      address: "0x73E27097221d4d9D5893a83350dC7A967b46fab7",
      startBlock: 0,
    },
    ManagedRedemptionQueue: {
      chain: "baseSepolia",
      abi: ManagedRedemptionQueueAbi,
      address: "0x22BC73098CE1Ba2CaE5431fb32051cB4fc0F9C52",
      startBlock: 0,
    },
  },
  database: {
    kind: "postgres",
    connectionString: process.env.DATABASE_URL,
  },
});