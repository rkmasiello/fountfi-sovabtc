// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {ManagedRedemptionQueue} from "../../src/strategy/ManagedRedemptionQueue.sol";
import {DeploymentConfig} from "../helpers/DeploymentConfig.sol";
import {DeploymentAddresses} from "../helpers/DeploymentAddresses.sol";

contract DeployQueue is Script {
    DeploymentConfig public config;
    DeploymentAddresses public addresses;

    function run() external returns (address queue) {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        uint256 chainId = block.chainid;

        config = new DeploymentConfig();
        addresses = new DeploymentAddresses();

        DeploymentConfig.NetworkConfig memory networkConfig = config.getNetworkConfig(chainId);
        DeploymentAddresses.Addresses memory deployedAddresses = addresses.getDeployment(chainId);

        require(deployedAddresses.roleManager != address(0), "RoleManager not deployed");
        require(deployedAddresses.vault != address(0), "Vault not deployed");
        require(deployedAddresses.strategy != address(0), "Strategy not deployed");

        vm.startBroadcast(deployerPrivateKey);

        console.log("Deploying ManagedRedemptionQueue to chain:", chainId);
        console.log("Using RoleManager:", deployedAddresses.roleManager);
        console.log("Using Vault:", deployedAddresses.vault);
        console.log("Using Strategy:", deployedAddresses.strategy);
        console.log("Redemption Period:", networkConfig.redemptionPeriod);

        // Deploy ManagedRedemptionQueue
        queue = address(
            new ManagedRedemptionQueue(
                deployedAddresses.vault,
                deployedAddresses.strategy,
                deployedAddresses.roleManager,
                networkConfig.sovabtc
            )
        );
        console.log("ManagedRedemptionQueue deployed at:", queue);

        vm.stopBroadcast();

        // Update deployment addresses
        deployedAddresses.queue = queue;

        vm.broadcast(deployerPrivateKey);
        addresses.saveDeployment(chainId, deployedAddresses);

        console.log("\n=== Queue Deployment Complete ===");
        console.log("ManagedRedemptionQueue:", queue);
        console.log("Redemption Period:", networkConfig.redemptionPeriod / 1 days, "days");

        return queue;
    }
}
