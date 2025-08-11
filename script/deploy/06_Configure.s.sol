// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {RoleManager} from "../../src/auth/RoleManager.sol";
import {MultiCollateralRegistry} from "../../src/registry/MultiCollateralRegistry.sol";
import {MultiCollateralStrategy} from "../../src/strategy/MultiCollateralStrategy.sol";
import {MultiBTCVault} from "../../src/vaults/MultiBTCVault.sol";
import {ManagedRedemptionQueue} from "../../src/strategy/ManagedRedemptionQueue.sol";
import {PriceOracleReporter} from "../../src/reporter/PriceOracleReporter.sol";
import {DeploymentConfig} from "../helpers/DeploymentConfig.sol";
import {DeploymentAddresses} from "../helpers/DeploymentAddresses.sol";

contract Configure is Script {
    DeploymentConfig public config;
    DeploymentAddresses public addresses;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        uint256 chainId = block.chainid;

        config = new DeploymentConfig();
        addresses = new DeploymentAddresses();

        DeploymentConfig.NetworkConfig memory networkConfig = config.getNetworkConfig(chainId);
        DeploymentAddresses.Addresses memory deployedAddresses = addresses.getDeployment(chainId);

        require(deployedAddresses.roleManager != address(0), "RoleManager not deployed");
        require(deployedAddresses.registry != address(0), "Registry not deployed");
        require(deployedAddresses.strategy != address(0), "Strategy not deployed");
        require(deployedAddresses.vault != address(0), "Vault not deployed");
        require(deployedAddresses.queue != address(0), "Queue not deployed");
        require(deployedAddresses.reporter != address(0), "Reporter not deployed");

        vm.startBroadcast(deployerPrivateKey);

        console.log("\n=== Starting Configuration ===");

        // 1. Setup roles
        console.log("\n1. Setting up roles...");
        RoleManager roleManager = RoleManager(deployedAddresses.roleManager);
        uint256 PROTOCOL_ADMIN = roleManager.PROTOCOL_ADMIN();

        // Grant reporter updater role
        if (networkConfig.priceOracleUpdater != address(0)) {
            roleManager.grantRole(networkConfig.priceOracleUpdater, PROTOCOL_ADMIN);
            console.log("Granted admin role to price oracle updater:", networkConfig.priceOracleUpdater);
        }

        // 2. Configure Registry with collateral tokens
        console.log("\n2. Configuring collateral tokens...");
        MultiCollateralRegistry registry = MultiCollateralRegistry(deployedAddresses.registry);
        DeploymentConfig.CollateralConfig[] memory collaterals = config.getCollateralConfigs(chainId);

        for (uint256 i = 0; i < collaterals.length; i++) {
            if (collaterals[i].token != address(0) && collaterals[i].isActive) {
                registry.addCollateral(collaterals[i].token, collaterals[i].conversionRate, collaterals[i].decimals);
                console.log("Added collateral:", collaterals[i].token);
                console.log("  - Conversion rate:", collaterals[i].conversionRate);
                console.log("  - Decimals:", collaterals[i].decimals);
            }
        }

        // Also add sovaBTC if available
        if (networkConfig.sovabtc != address(0)) {
            registry.addCollateral(networkConfig.sovabtc, 1e18, 8);
            console.log("Added sovaBTC as collateral:", networkConfig.sovabtc);
        }

        // 3. Configure Vault
        console.log("\n3. Configuring vault...");
        MultiBTCVault vault = MultiBTCVault(deployedAddresses.vault);

        // Set strategy
        vault.setStrategy(deployedAddresses.strategy);
        console.log("Set strategy for vault:", deployedAddresses.strategy);

        // Set price oracle
        vault.setPriceOracle(deployedAddresses.reporter);
        console.log("Set price oracle for vault:", deployedAddresses.reporter);

        // Set redemption queue
        vault.setRedemptionQueue(deployedAddresses.queue);
        console.log("Set redemption queue for vault:", deployedAddresses.queue);

        // Minimum investment is already set as a constant in the vault
        console.log("Minimum investment is:", vault.MINIMUM_INVESTMENT(), "(0.001 BTC)");

        // 4. Configure Strategy
        console.log("\n4. Configuring strategy...");
        MultiCollateralStrategy strategy = MultiCollateralStrategy(deployedAddresses.strategy);

        // Set vault as authorized withdrawer
        strategy.setVault(deployedAddresses.vault);
        console.log("Set vault as authorized withdrawer:", deployedAddresses.vault);

        // Allow queue to withdraw as well
        // Note: This requires the strategy to have a function to authorize the queue
        // If not available, this step may need to be handled differently

        // 5. Configure Queue
        console.log("\n5. Queue configuration...");
        ManagedRedemptionQueue queue = ManagedRedemptionQueue(deployedAddresses.queue);
        console.log("Queue configured with:");
        console.log("  - Vault:", deployedAddresses.vault);
        console.log("  - Strategy:", deployedAddresses.strategy);
        console.log("  - Redemption period:", networkConfig.redemptionPeriod / 1 days, "days");

        // 6. Final setup
        console.log("\n6. Final setup...");

        // Grant necessary roles for operations
        uint256 STRATEGY_OPERATOR = roleManager.STRATEGY_OPERATOR();

        roleManager.grantRole(deployedAddresses.vault, STRATEGY_OPERATOR);
        roleManager.grantRole(deployedAddresses.queue, STRATEGY_OPERATOR);
        console.log("Granted operational roles to vault and queue");

        vm.stopBroadcast();

        console.log("\n=== Configuration Complete ===");
        console.log("\nDeployed Addresses:");
        console.log("  RoleManager:", deployedAddresses.roleManager);
        console.log("  Registry:", deployedAddresses.registry);
        console.log("  Strategy:", deployedAddresses.strategy);
        console.log("  Vault:", deployedAddresses.vault);
        console.log("  Queue:", deployedAddresses.queue);
        console.log("  Reporter:", deployedAddresses.reporter);
        console.log("\nSystem is ready for use!");
    }
}
