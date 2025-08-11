// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {MultiBTCVault} from "../../src/vaults/MultiBTCVault.sol";
import {DeploymentConfig} from "../helpers/DeploymentConfig.sol";
import {DeploymentAddresses} from "../helpers/DeploymentAddresses.sol";

contract DeployVault is Script {
    DeploymentConfig public config;
    DeploymentAddresses public addresses;

    function run() external returns (address vault) {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        uint256 chainId = block.chainid;

        config = new DeploymentConfig();
        addresses = new DeploymentAddresses();

        DeploymentConfig.NetworkConfig memory networkConfig = config.getNetworkConfig(chainId);
        DeploymentAddresses.Addresses memory deployedAddresses = addresses.getDeployment(chainId);

        require(deployedAddresses.roleManager != address(0), "RoleManager not deployed");
        require(deployedAddresses.registry != address(0), "Registry not deployed");
        require(deployedAddresses.strategy != address(0), "Strategy not deployed");

        vm.startBroadcast(deployerPrivateKey);

        console.log("Deploying Vault to chain:", chainId);
        console.log("Using RoleManager:", deployedAddresses.roleManager);
        console.log("Using Registry:", deployedAddresses.registry);
        console.log("Using Strategy:", deployedAddresses.strategy);

        // Deploy MultiBTCVault
        vault = address(
            new MultiBTCVault(
                "Multi-Collateral BTC Vault",
                "mcBTC",
                networkConfig.sovabtc, // sovaBTC address
                deployedAddresses.registry,
                deployedAddresses.roleManager,
                address(0) // Conduit (optional)
            )
        );
        console.log("MultiBTCVault deployed at:", vault);

        vm.stopBroadcast();

        // Update deployment addresses
        deployedAddresses.vault = vault;

        vm.broadcast(deployerPrivateKey);
        addresses.saveDeployment(chainId, deployedAddresses);

        console.log("\n=== Vault Deployment Complete ===");
        console.log("MultiBTCVault:", vault);

        return vault;
    }
}
