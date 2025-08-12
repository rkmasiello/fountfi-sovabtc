// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {RoleManager} from "../src/auth/RoleManager.sol";
import {MultiCollateralRegistry} from "../src/registry/MultiCollateralRegistry.sol";
import {MultiCollateralStrategy} from "../src/strategy/MultiCollateralStrategy.sol";
import {MultiBTCVault} from "../src/vaults/MultiBTCVault.sol";
import {ManagedRedemptionQueue} from "../src/strategy/ManagedRedemptionQueue.sol";
import {PriceOracleReporter} from "../src/reporter/PriceOracleReporter.sol";

contract DeployFreshBaseSepolia is Script {
    // Mock tokens (already deployed)
    address constant WBTC = 0xe44b2870eFcd6Bb3C9305808012621f438e9636D;
    address constant TBTC = 0xE2b47f0dD766834b9DD2612D2d3632B05Ca89802;
    address constant SOVABTC = 0x05aB19d77516414f7333a8fd52cC1F49FF8eAFA9;
    
    // Admin address
    address constant ADMIN = 0x1804c8AB1F12E6bbf3894d4083f33e07309d1f38;
    
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        vm.startBroadcast(deployerPrivateKey);
        
        console.log("\n========================================");
        console.log("   Base Sepolia Fresh Deployment");
        console.log("========================================\n");
        
        // Deploy RoleManager
        console.log("Deploying RoleManager...");
        RoleManager roleManager = new RoleManager();
        console.log("RoleManager deployed at:", address(roleManager));
        
        // Grant admin role
        roleManager.grantRole(ADMIN, 2); // PROTOCOL_ADMIN
        console.log("Granted PROTOCOL_ADMIN role to:", ADMIN);
        
        // Deploy Registry
        console.log("\nDeploying MultiCollateralRegistry...");
        MultiCollateralRegistry registry = new MultiCollateralRegistry(address(roleManager));
        console.log("Registry deployed at:", address(registry));
        
        // Deploy Strategy
        console.log("\nDeploying MultiCollateralStrategy...");
        MultiCollateralStrategy strategy = new MultiCollateralStrategy(
            address(roleManager),
            address(registry),
            SOVABTC
        );
        console.log("Strategy deployed at:", address(strategy));
        
        // Deploy PriceOracleReporter
        console.log("\nDeploying PriceOracleReporter...");
        PriceOracleReporter reporter = new PriceOracleReporter(
            1e18, // initial NAV
            ADMIN, // updater
            500, // max deviation 5% (in basis points)
            3600  // deviation time period (1 hour)
        );
        console.log("Reporter deployed at:", address(reporter));
        
        // Deploy Vault
        console.log("\nDeploying MultiBTCVault...");
        MultiBTCVault vault = new MultiBTCVault(
            "Multi-Collateral BTC Vault",
            "mcBTC",
            SOVABTC,
            address(registry),
            address(roleManager),
            address(0) // no conduit
        );
        console.log("Vault deployed at:", address(vault));
        
        // Deploy Queue
        console.log("\nDeploying ManagedRedemptionQueue...");
        ManagedRedemptionQueue queue = new ManagedRedemptionQueue(
            address(vault),
            address(strategy),
            address(roleManager),
            SOVABTC
        );
        console.log("Queue deployed at:", address(queue));
        
        // Configure registry with collaterals
        console.log("\nConfiguring collaterals in registry...");
        
        // Add WBTC (8 decimals)
        registry.addCollateral(WBTC, 1e18, 8);
        console.log("Added WBTC to registry");
        
        // Add TBTC (18 decimals)
        registry.addCollateral(TBTC, 99e16, 18);
        console.log("Added TBTC to registry");
        
        // Add sovaBTC (8 decimals)
        registry.addCollateral(SOVABTC, 1e18, 8);
        console.log("Added sovaBTC to registry");
        
        // Grant additional roles
        roleManager.grantRole(ADMIN, 4); // OPERATOR
        console.log("Granted OPERATOR role to admin");
        
        roleManager.grantRole(ADMIN, 16); // REPORTER
        console.log("Granted REPORTER role to admin");
        
        vm.stopBroadcast();
        
        console.log("\n========================================");
        console.log("   Deployment Complete!");
        console.log("========================================\n");
        
        console.log("Deployed Addresses:");
        console.log("-------------------");
        console.log("RoleManager:", address(roleManager));
        console.log("Registry:", address(registry));
        console.log("Strategy:", address(strategy));
        console.log("Vault:", address(vault));
        console.log("Queue:", address(queue));
        console.log("Reporter:", address(reporter));
        console.log("\nMock Tokens:");
        console.log("------------");
        console.log("WBTC:", WBTC);
        console.log("TBTC:", TBTC);
        console.log("sovaBTC:", SOVABTC);
        
        console.log("\nIMPORTANT: Run the configuration script next to connect the contracts!");
    }
}