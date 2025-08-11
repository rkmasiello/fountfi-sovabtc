// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {MultiCollateralStrategy} from "../../src/strategy/MultiCollateralStrategy.sol";
import {DeploymentConfig} from "../helpers/DeploymentConfig.sol";
import {DeploymentAddresses} from "../helpers/DeploymentAddresses.sol";

contract DeployStrategy is Script {
    DeploymentConfig public config;
    DeploymentAddresses public addresses;

    function run() external returns (address strategy) {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        uint256 chainId = block.chainid;

        config = new DeploymentConfig();
        addresses = new DeploymentAddresses();

        DeploymentConfig.NetworkConfig memory networkConfig = config.getNetworkConfig(chainId);
        DeploymentAddresses.Addresses memory deployedAddresses = addresses.getDeployment(chainId);

        require(deployedAddresses.roleManager != address(0), "RoleManager not deployed");
        require(deployedAddresses.registry != address(0), "Registry not deployed");

        vm.startBroadcast(deployerPrivateKey);

        console.log("Deploying Strategy to chain:", chainId);
        console.log("Using RoleManager:", deployedAddresses.roleManager);
        console.log("Using Registry:", deployedAddresses.registry);

        // Deploy MultiCollateralStrategy
        strategy = address(
            new MultiCollateralStrategy(
                deployedAddresses.roleManager,
                deployedAddresses.registry,
                networkConfig.sovabtc // sovaBTC address (will be set later if not available)
            )
        );
        console.log("MultiCollateralStrategy deployed at:", strategy);

        vm.stopBroadcast();

        // Update deployment addresses
        deployedAddresses.strategy = strategy;

        vm.broadcast(deployerPrivateKey);
        addresses.saveDeployment(chainId, deployedAddresses);

        console.log("\n=== Strategy Deployment Complete ===");
        console.log("MultiCollateralStrategy:", strategy);

        return strategy;
    }
}
