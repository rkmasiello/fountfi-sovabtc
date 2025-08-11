// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {RoleManager} from "../../src/auth/RoleManager.sol";
import {MultiCollateralRegistry} from "../../src/registry/MultiCollateralRegistry.sol";
import {DeploymentConfig} from "../helpers/DeploymentConfig.sol";
import {DeploymentAddresses} from "../helpers/DeploymentAddresses.sol";

contract DeployCore is Script {
    DeploymentConfig public config;
    DeploymentAddresses public addresses;

    function run() external returns (address roleManager, address registry) {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        uint256 chainId = block.chainid;

        config = new DeploymentConfig();
        addresses = new DeploymentAddresses();

        DeploymentConfig.NetworkConfig memory networkConfig = config.getNetworkConfig(chainId);

        vm.startBroadcast(deployerPrivateKey);

        console.log("Deploying Core contracts to chain:", chainId);
        console.log("Protocol Admin:", networkConfig.protocolAdmin);

        // Deploy RoleManager
        roleManager = address(new RoleManager());
        console.log("RoleManager deployed at:", roleManager);

        // Setup initial admin
        RoleManager(roleManager).grantRole(networkConfig.protocolAdmin, RoleManager(roleManager).PROTOCOL_ADMIN());
        console.log("Granted admin role to:", networkConfig.protocolAdmin);

        // Deploy MultiCollateralRegistry
        registry = address(new MultiCollateralRegistry(roleManager));
        console.log("MultiCollateralRegistry deployed at:", registry);

        vm.stopBroadcast();

        // Save deployment addresses
        DeploymentAddresses.Addresses memory deployedAddresses;
        deployedAddresses.roleManager = roleManager;
        deployedAddresses.registry = registry;

        vm.broadcast(deployerPrivateKey);
        addresses.saveDeployment(chainId, deployedAddresses);

        console.log("\n=== Core Deployment Complete ===");
        console.log("RoleManager:", roleManager);
        console.log("Registry:", registry);

        return (roleManager, registry);
    }
}
