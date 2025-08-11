// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {DeployCore} from "../../script/deploy/01_DeployCore.s.sol";
import {DeployStrategy} from "../../script/deploy/02_DeployStrategy.s.sol";
import {DeployVault} from "../../script/deploy/03_DeployVault.s.sol";
import {DeployQueue} from "../../script/deploy/04_DeployQueue.s.sol";
import {DeployReporter} from "../../script/deploy/05_DeployReporter.s.sol";
import {Configure} from "../../script/deploy/06_Configure.s.sol";
import {DeployMockTokens} from "../../script/helpers/DeployMockTokens.s.sol";

import {RoleManager} from "../../src/auth/RoleManager.sol";
import {MultiCollateralRegistry} from "../../src/registry/MultiCollateralRegistry.sol";
import {MultiCollateralStrategy} from "../../src/strategy/MultiCollateralStrategy.sol";
import {MultiBTCVault} from "../../src/vaults/MultiBTCVault.sol";
import {ManagedRedemptionQueue} from "../../src/strategy/ManagedRedemptionQueue.sol";
import {PriceOracleReporter} from "../../src/reporter/PriceOracleReporter.sol";

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
        // Set environment variables
        vm.setEnv("PRIVATE_KEY", "0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80");
        vm.setEnv("PROTOCOL_ADMIN_ADDRESS", vm.toString(ADMIN));
        vm.setEnv("PRICE_ORACLE_UPDATER", vm.toString(PRICE_UPDATER));
    }

    function test_FullDeployment() public {
        console.log("Testing full deployment sequence...");

        // Step 0: Deploy mock tokens
        console.log("\n[Step 0] Deploying mock tokens...");
        DeployMockTokens deployTokens = new DeployMockTokens();
        (wbtc, tbtc, sovabtc) = deployTokens.run();

        // Update environment with sovaBTC address
        vm.setEnv("SOVABTC_ADDRESS", vm.toString(sovabtc));

        // Step 1: Deploy Core
        console.log("\n[Step 1] Deploying core contracts...");
        DeployCore deployCore = new DeployCore();
        (roleManager, registry) = deployCore.run();

        assertNotEq(roleManager, address(0), "RoleManager should be deployed");
        assertNotEq(registry, address(0), "Registry should be deployed");

        // Step 2: Deploy Strategy
        console.log("\n[Step 2] Deploying strategy...");
        DeployStrategy deployStrategy = new DeployStrategy();
        strategy = deployStrategy.run();

        assertNotEq(strategy, address(0), "Strategy should be deployed");

        // Step 3: Deploy Vault
        console.log("\n[Step 3] Deploying vault...");
        DeployVault deployVault = new DeployVault();
        vault = deployVault.run();

        assertNotEq(vault, address(0), "Vault should be deployed");

        // Step 4: Deploy Queue
        console.log("\n[Step 4] Deploying queue...");
        DeployQueue deployQueue = new DeployQueue();
        queue = deployQueue.run();

        assertNotEq(queue, address(0), "Queue should be deployed");

        // Step 5: Deploy Reporter
        console.log("\n[Step 5] Deploying reporter...");
        DeployReporter deployReporter = new DeployReporter();
        reporter = deployReporter.run();

        assertNotEq(reporter, address(0), "Reporter should be deployed");

        // Step 6: Configure
        console.log("\n[Step 6] Configuring system...");
        Configure configure = new Configure();
        configure.run();

        // Verify configuration
        _verifyConfiguration();

        console.log("\n✅ Deployment test passed!");
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
        assertGt(collaterals.length, 0, "Should have registered collaterals");

        // Verify strategy setup
        MultiCollateralStrategy strategyContract = MultiCollateralStrategy(strategy);
        assertEq(strategyContract.vault(), vault, "Vault should be set in strategy");

        // Verify reporter setup
        PriceOracleReporter reporterContract = PriceOracleReporter(reporter);
        assertGt(reporterContract.getCurrentPrice(), 0, "Price should be initialized");

        console.log("✅ All configuration checks passed");
    }
}
