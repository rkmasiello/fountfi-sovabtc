// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {DeployCore} from "./deploy/01_DeployCore.s.sol";
import {DeployStrategy} from "./deploy/02_DeployStrategy.s.sol";
import {DeployVault} from "./deploy/03_DeployVault.s.sol";
import {DeployQueue} from "./deploy/04_DeployQueue.s.sol";
import {DeployReporter} from "./deploy/05_DeployReporter.s.sol";
import {Configure} from "./deploy/06_Configure.s.sol";

contract DeployAll is Script {
    function run() external {
        console.log("\n========================================");
        console.log("   Multi-Collateral BTC Vault Deployment");
        console.log("========================================\n");

        // Step 1: Deploy Core
        console.log("\n[Step 1/6] Deploying Core Contracts...");
        DeployCore deployCore = new DeployCore();
        deployCore.run();

        // Step 2: Deploy Strategy
        console.log("\n[Step 2/6] Deploying Strategy...");
        DeployStrategy deployStrategy = new DeployStrategy();
        deployStrategy.run();

        // Step 3: Deploy Vault
        console.log("\n[Step 3/6] Deploying Vault...");
        DeployVault deployVault = new DeployVault();
        deployVault.run();

        // Step 4: Deploy Queue
        console.log("\n[Step 4/6] Deploying Queue...");
        DeployQueue deployQueue = new DeployQueue();
        deployQueue.run();

        // Step 5: Deploy Reporter
        console.log("\n[Step 5/6] Deploying Reporter...");
        DeployReporter deployReporter = new DeployReporter();
        deployReporter.run();

        // Step 6: Configure System
        console.log("\n[Step 6/6] Configuring System...");
        Configure configure = new Configure();
        configure.run();

        console.log("\n========================================");
        console.log("   Deployment Complete!");
        console.log("========================================\n");
        console.log("All contracts have been deployed and configured successfully.");
        console.log("Check the deployments/ directory for contract addresses.");
        console.log("\nNext steps:");
        console.log("1. Verify contracts on Etherscan");
        console.log("2. Fund strategy with sovaBTC liquidity");
        console.log("3. Configure initial collateral tokens");
        console.log("4. Test deposit and redemption flows");
    }
}
