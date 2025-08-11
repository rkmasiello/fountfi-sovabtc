// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";

// Import contracts to deploy
import {RoleManager} from "../../src/auth/RoleManager.sol";
import {MultiCollateralRegistry} from "../../src/registry/MultiCollateralRegistry.sol";
import {MultiCollateralStrategy} from "../../src/strategy/MultiCollateralStrategy.sol";
import {MultiBTCVault} from "../../src/vaults/MultiBTCVault.sol";
import {ManagedRedemptionQueue} from "../../src/strategy/ManagedRedemptionQueue.sol";
import {PriceOracleReporter} from "../../src/reporter/PriceOracleReporter.sol";
import {MockERC20} from "../../src/mocks/MockERC20.sol";

contract DeploymentTest is Test {
    address constant ADMIN = address(0x1234);
    address constant PRICE_UPDATER = address(0x5678);
    
    address roleManager;
    address registry;
    address strategy;
    address vault;
    address queue;
    address reporter;
    
    address wbtc;
    address tbtc;
    address sovabtc;

    function setUp() public {
        // Deploy mock tokens first
        wbtc = address(new MockERC20("Wrapped BTC", "WBTC", 8));
        tbtc = address(new MockERC20("tBTC", "TBTC", 18));
        sovabtc = address(new MockERC20("Sova BTC", "sovaBTC", 8));
        
        // Mint some tokens for testing
        MockERC20(wbtc).mint(address(this), 10 * 10**8);
        MockERC20(tbtc).mint(address(this), 10 * 10**18);
        MockERC20(sovabtc).mint(address(this), 10 * 10**8);
    }

    function test_FullDeployment() public {
        console.log("Testing full deployment sequence...");
        
        // Step 1: Deploy Core
        console.log("\n[Step 1] Deploying core contracts...");
        roleManager = address(new RoleManager());
        registry = address(new MultiCollateralRegistry(roleManager));
        
        // Grant admin role
        RoleManager(roleManager).grantRole(ADMIN, RoleManager(roleManager).PROTOCOL_ADMIN());
        
        assertNotEq(roleManager, address(0), "RoleManager should be deployed");
        assertNotEq(registry, address(0), "Registry should be deployed");
        
        // Step 2: Deploy Strategy
        console.log("\n[Step 2] Deploying strategy...");
        strategy = address(new MultiCollateralStrategy(
            roleManager,
            registry,
            sovabtc
        ));
        
        assertNotEq(strategy, address(0), "Strategy should be deployed");
        
        // Step 3: Deploy Vault
        console.log("\n[Step 3] Deploying vault...");
        vault = address(new MultiBTCVault(
            "Multi-Collateral BTC Vault",
            "mcBTC",
            sovabtc,
            registry,
            roleManager,
            address(0) // No conduit
        ));
        
        assertNotEq(vault, address(0), "Vault should be deployed");
        
        // Step 4: Deploy Queue
        console.log("\n[Step 4] Deploying queue...");
        queue = address(new ManagedRedemptionQueue(
            vault,
            strategy,
            roleManager,
            sovabtc
        ));
        
        assertNotEq(queue, address(0), "Queue should be deployed");
        
        // Step 5: Deploy Reporter
        console.log("\n[Step 5] Deploying reporter...");
        reporter = address(new PriceOracleReporter(
            1e18, // Initial price
            PRICE_UPDATER,
            100, // 1% max deviation
            300  // 5 minutes
        ));
        
        assertNotEq(reporter, address(0), "Reporter should be deployed");
        
        // Step 6: Configure System
        console.log("\n[Step 6] Configuring system...");
        
        // Prank as admin for configuration
        vm.startPrank(ADMIN);
        
        // Configure registry with collaterals
        MultiCollateralRegistry(registry).addCollateral(wbtc, 1e18, 8);
        MultiCollateralRegistry(registry).addCollateral(tbtc, 99e16, 18);
        MultiCollateralRegistry(registry).addCollateral(sovabtc, 1e18, 8);
        
        // Configure vault
        MultiBTCVault(vault).setStrategy(strategy);
        MultiBTCVault(vault).setPriceOracle(reporter);
        MultiBTCVault(vault).setRedemptionQueue(queue);
        
        // Configure strategy
        MultiCollateralStrategy(strategy).setVault(vault);
        
        // Grant necessary roles
        RoleManager(roleManager).grantRole(vault, RoleManager(roleManager).STRATEGY_OPERATOR());
        RoleManager(roleManager).grantRole(queue, RoleManager(roleManager).STRATEGY_OPERATOR());
        
        vm.stopPrank();
        
        // Verify configuration
        _verifyConfiguration();
        
        console.log("\nDeployment test passed!");
    }

    function _verifyConfiguration() private view {
        console.log("\nVerifying configuration...");
        
        // Verify vault setup
        MultiBTCVault vaultContract = MultiBTCVault(vault);
        assertEq(vaultContract.strategy(), strategy, "Strategy should be set");
        assertEq(vaultContract.priceOracle(), reporter, "Price oracle should be set");
        assertEq(vaultContract.redemptionQueue(), queue, "Redemption queue should be set");
        
        // Verify registry has collaterals
        MultiCollateralRegistry registryContract = MultiCollateralRegistry(registry);
        address[] memory collaterals = registryContract.getSupportedCollaterals();
        assertEq(collaterals.length, 3, "Should have 3 registered collaterals");
        
        // Verify strategy setup
        MultiCollateralStrategy strategyContract = MultiCollateralStrategy(strategy);
        assertEq(strategyContract.vault(), vault, "Vault should be set in strategy");
        
        // Verify reporter setup
        PriceOracleReporter reporterContract = PriceOracleReporter(reporter);
        assertGt(reporterContract.getCurrentPrice(), 0, "Price should be initialized");
        
        console.log("All configuration checks passed");
    }
}