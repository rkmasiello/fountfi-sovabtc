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

contract DeployBaseSepolia is Script {
    // Already deployed addresses
    address constant ROLE_MANAGER = 0x15502fC5e872c8B22BA6dD5e01A7A5bd4f9A3d72;
    address constant REGISTRY = 0x15a9983784617aa8892b2677bbaEc23539482B65;
    
    // Mock tokens
    address constant WBTC = 0xe44b2870eFcd6Bb3C9305808012621f438e9636D;
    address constant TBTC = 0xE2b47f0dD766834b9DD2612D2d3632B05Ca89802;
    address constant SOVABTC = 0x05aB19d77516414f7333a8fd52cC1F49FF8eAFA9;
    
    // Admin addresses
    address constant ADMIN = 0x1804c8AB1F12E6bbf3894d4083f33e07309d1f38;
    
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        vm.startBroadcast(deployerPrivateKey);
        
        console.log("\n========================================");
        console.log("   Deploying Remaining Contracts");
        console.log("========================================\n");
        
        // Deploy Strategy
        console.log("\nDeploying Strategy...");
        MultiCollateralStrategy strategy = new MultiCollateralStrategy(
            ROLE_MANAGER,
            REGISTRY,
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
            REGISTRY,
            ROLE_MANAGER,
            address(0) // no conduit for now
        );
        console.log("Vault deployed at:", address(vault));
        
        // Deploy Queue
        console.log("\nDeploying ManagedRedemptionQueue...");
        ManagedRedemptionQueue queue = new ManagedRedemptionQueue(
            address(vault),
            address(strategy),
            ROLE_MANAGER,
            SOVABTC
        );
        console.log("Queue deployed at:", address(queue));
        
        // Configure contracts
        console.log("\n========================================");
        console.log("   Configuring Contracts");
        console.log("========================================\n");
        
        // Configuration will be done after deployment in a separate transaction
        // For now, let's just add collaterals to registry
        
        // Configure registry with collaterals
        console.log("Configuring collaterals in registry...");
        MultiCollateralRegistry registry = MultiCollateralRegistry(REGISTRY);
        
        // Add WBTC (8 decimals)
        registry.addCollateral(WBTC, 1e18, 8);
        console.log("Added WBTC to registry");
        
        // Add TBTC (18 decimals)
        registry.addCollateral(TBTC, 99e16, 18);
        console.log("Added TBTC to registry");
        
        // Add sovaBTC (8 decimals)
        registry.addCollateral(SOVABTC, 1e18, 8);
        console.log("Added sovaBTC to registry");
        
        // Grant roles
        RoleManager roleManager = RoleManager(ROLE_MANAGER);
        
        // Grant OPERATOR role to admin for testing (role value = 4)
        roleManager.grantRole(ADMIN, 4);
        console.log("Granted OPERATOR role to admin");
        
        // Grant REPORTER role to admin for testing (role value = 16)
        roleManager.grantRole(ADMIN, 16);
        console.log("Granted REPORTER role to admin");
        
        vm.stopBroadcast();
        
        console.log("\n========================================");
        console.log("   Deployment Complete!");
        console.log("========================================\n");
        
        console.log("Deployed Addresses:");
        console.log("-------------------");
        console.log("RoleManager:", ROLE_MANAGER);
        console.log("Registry:", REGISTRY);
        console.log("Strategy:", address(strategy));
        console.log("Vault:", address(vault));
        console.log("Queue:", address(queue));
        console.log("Reporter:", address(reporter));
        console.log("\nMock Tokens:");
        console.log("------------");
        console.log("WBTC:", WBTC);
        console.log("TBTC:", TBTC);
        console.log("sovaBTC:", SOVABTC);
    }
}