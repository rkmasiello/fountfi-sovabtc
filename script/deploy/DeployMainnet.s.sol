// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {Script} from "forge-std/Script.sol";
import {console2} from "forge-std/console2.sol";
import {RoleManager} from "../../src/access/RoleManager.sol";
import {MultiCollateralRegistry} from "../../src/strategy/MultiCollateralRegistry.sol";
import {MultiCollateralStrategy} from "../../src/strategy/MultiCollateralStrategy.sol";
import {MultiBTCVault} from "../../src/vaults/MultiBTCVault.sol";
import {ManagedRedemptionQueue} from "../../src/strategy/ManagedRedemptionQueue.sol";
import {PriceOracleReporter} from "../../src/oracles/PriceOracleReporter.sol";

contract DeployMainnet is Script {
    // Network-specific configurations
    struct NetworkConfig {
        address wbtc;
        address tbtc;
        address sovaBTC;
        address multisig;
        uint256 redemptionDelay;
        uint256 minDeposit;
        string vaultName;
        string vaultSymbol;
    }

    mapping(uint256 => NetworkConfig) public networkConfigs;
    
    // Deployed contract addresses
    RoleManager public roleManager;
    MultiCollateralRegistry public registry;
    MultiCollateralStrategy public strategy;
    MultiBTCVault public vault;
    ManagedRedemptionQueue public queue;
    PriceOracleReporter public priceOracle;

    function setUp() public {
        // Base Mainnet (Chain ID: 8453)
        networkConfigs[8453] = NetworkConfig({
            wbtc: address(0), // TODO: Add actual Base WBTC address
            tbtc: address(0), // TODO: Add actual Base tBTC address
            sovaBTC: address(0), // TODO: Add actual Base sovaBTC address
            multisig: address(0), // TODO: Add team multisig address
            redemptionDelay: 14 days,
            minDeposit: 0.001e8, // 0.001 BTC
            vaultName: "Multi-Collateral Bitcoin",
            vaultSymbol: "mcBTC"
        });

        // Ethereum Mainnet (Chain ID: 1)
        networkConfigs[1] = NetworkConfig({
            wbtc: 0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599,
            tbtc: 0x18084fbA666a33d37592fA2633fD49a74DD93a88,
            sovaBTC: address(0), // TODO: Add sovaBTC on Ethereum
            multisig: address(0), // TODO: Add team multisig address
            redemptionDelay: 14 days,
            minDeposit: 0.001e8,
            vaultName: "Multi-Collateral Bitcoin",
            vaultSymbol: "mcBTC"
        });

        // Arbitrum Mainnet (Chain ID: 42161)
        networkConfigs[42161] = NetworkConfig({
            wbtc: 0x2f2a2543B76A4166549F7aaB2e75Bef0aefC5B0f,
            tbtc: 0x6c84a8f1c29108F47a79964b5Fe888D4f4D0dE40,
            sovaBTC: address(0), // TODO: Add sovaBTC on Arbitrum
            multisig: address(0), // TODO: Add team multisig address
            redemptionDelay: 14 days,
            minDeposit: 0.001e8,
            vaultName: "Multi-Collateral Bitcoin",
            vaultSymbol: "mcBTC"
        });

        // Optimism Mainnet (Chain ID: 10)
        networkConfigs[10] = NetworkConfig({
            wbtc: 0x68f180fcCe6836688e9084f035309E29Bf0A2095,
            tbtc: 0x6c84a8f1c29108F47a79964b5Fe888D4f4D0dE40,
            sovaBTC: address(0), // TODO: Add sovaBTC on Optimism
            multisig: address(0), // TODO: Add team multisig address
            redemptionDelay: 14 days,
            minDeposit: 0.001e8,
            vaultName: "Multi-Collateral Bitcoin",
            vaultSymbol: "mcBTC"
        });
    }

    function run() external {
        uint256 chainId = block.chainid;
        NetworkConfig memory config = networkConfigs[chainId];
        
        // Validate configuration
        require(config.wbtc != address(0), "WBTC address not configured for this network");
        require(config.multisig != address(0), "Multisig address not configured");
        
        console2.log("Deploying to network with chain ID:", chainId);
        console2.log("Using configuration:");
        console2.log("  WBTC:", config.wbtc);
        console2.log("  tBTC:", config.tbtc);
        console2.log("  sovaBTC:", config.sovaBTC);
        console2.log("  Multisig:", config.multisig);
        
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        
        console2.log("Deployer address:", deployer);
        
        vm.startBroadcast(deployerPrivateKey);
        
        // 1. Deploy RoleManager
        console2.log("\n1. Deploying RoleManager...");
        roleManager = new RoleManager(deployer);
        console2.log("  RoleManager deployed at:", address(roleManager));
        
        // 2. Deploy Registry
        console2.log("\n2. Deploying MultiCollateralRegistry...");
        registry = new MultiCollateralRegistry(address(roleManager));
        console2.log("  Registry deployed at:", address(registry));
        
        // 3. Deploy Strategy
        console2.log("\n3. Deploying MultiCollateralStrategy...");
        strategy = new MultiCollateralStrategy(
            address(roleManager),
            address(registry)
        );
        console2.log("  Strategy deployed at:", address(strategy));
        
        // 4. Deploy Price Oracle
        console2.log("\n4. Deploying PriceOracleReporter...");
        priceOracle = new PriceOracleReporter(
            address(roleManager),
            1e18, // Initial price: 1 BTC = 1 mcBTC
            86400 // 24 hour transition period
        );
        console2.log("  PriceOracle deployed at:", address(priceOracle));
        
        // 5. Deploy Vault
        console2.log("\n5. Deploying MultiBTCVault...");
        vault = new MultiBTCVault(
            address(roleManager),
            address(registry),
            address(strategy),
            address(priceOracle),
            config.minDeposit,
            config.vaultName,
            config.vaultSymbol
        );
        console2.log("  Vault deployed at:", address(vault));
        
        // 6. Deploy Redemption Queue
        console2.log("\n6. Deploying ManagedRedemptionQueue...");
        queue = new ManagedRedemptionQueue(
            address(roleManager),
            address(vault),
            config.sovaBTC != address(0) ? config.sovaBTC : config.wbtc, // Use WBTC as fallback
            config.redemptionDelay
        );
        console2.log("  Queue deployed at:", address(queue));
        
        // 7. Configure contracts
        console2.log("\n7. Configuring contracts...");
        
        // Set vault on strategy
        strategy.setVault(address(vault));
        console2.log("  Strategy vault set");
        
        // Set redemption queue on vault
        vault.setRedemptionQueue(address(queue));
        console2.log("  Vault redemption queue set");
        
        // Register collateral tokens
        if (config.wbtc != address(0)) {
            registry.addCollateral(config.wbtc, 8);
            console2.log("  WBTC registered");
        }
        
        if (config.tbtc != address(0)) {
            registry.addCollateral(config.tbtc, 18);
            console2.log("  tBTC registered");
        }
        
        if (config.sovaBTC != address(0)) {
            registry.addCollateral(config.sovaBTC, 8);
            console2.log("  sovaBTC registered");
        }
        
        // 8. Transfer ownership to multisig
        console2.log("\n8. Transferring ownership to multisig...");
        
        // Grant admin role to multisig
        roleManager.grantRole(roleManager.ADMIN_ROLE(), config.multisig);
        console2.log("  Admin role granted to multisig");
        
        // Revoke admin role from deployer (after multisig confirms)
        // roleManager.revokeRole(roleManager.ADMIN_ROLE(), deployer);
        console2.log("  Note: Deployer still has admin role. Multisig should revoke after verification");
        
        vm.stopBroadcast();
        
        // Save deployment addresses
        saveDeploymentAddresses(chainId);
        
        console2.log("\n========== Deployment Complete ==========");
        console2.log("Please verify all contracts on the block explorer");
        console2.log("Multisig should:");
        console2.log("  1. Verify all contract deployments");
        console2.log("  2. Test basic operations");
        console2.log("  3. Revoke deployer admin role");
        console2.log("  4. Set up monitoring");
    }
    
    function saveDeploymentAddresses(uint256 chainId) internal {
        string memory chainName = getChainName(chainId);
        string memory json = "deployment";
        
        vm.serializeAddress(json, "roleManager", address(roleManager));
        vm.serializeAddress(json, "registry", address(registry));
        vm.serializeAddress(json, "strategy", address(strategy));
        vm.serializeAddress(json, "vault", address(vault));
        vm.serializeAddress(json, "queue", address(queue));
        string memory finalJson = vm.serializeAddress(json, "priceOracle", address(priceOracle));
        
        string memory filename = string.concat("deployments/", chainName, "-mainnet.json");
        vm.writeJson(finalJson, filename);
        
        console2.log("\nDeployment addresses saved to:", filename);
    }
    
    function getChainName(uint256 chainId) internal pure returns (string memory) {
        if (chainId == 1) return "ethereum";
        if (chainId == 8453) return "base";
        if (chainId == 42161) return "arbitrum";
        if (chainId == 10) return "optimism";
        return "unknown";
    }
}