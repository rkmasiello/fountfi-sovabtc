// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {IERC20} from "forge-std/interfaces/IERC20.sol";
import {MultiCollateralStrategy} from "../../src/strategy/MultiCollateralStrategy.sol";
import {DeploymentAddresses} from "../helpers/DeploymentAddresses.sol";
import {DeploymentConfig} from "../helpers/DeploymentConfig.sol";

contract ManageLiquidity is Script {
    DeploymentAddresses public addresses;
    DeploymentConfig public config;

    function run() external {
        uint256 adminPrivateKey = vm.envUint("ADMIN_PRIVATE_KEY");
        uint256 chainId = block.chainid;
        uint256 amount = vm.envUint("AMOUNT"); // Amount in 8 decimals for BTC
        bool isDeposit = vm.envBool("DEPOSIT"); // true to add liquidity, false to remove

        addresses = new DeploymentAddresses();
        config = new DeploymentConfig();

        DeploymentAddresses.Addresses memory deployedAddresses = addresses.getDeployment(chainId);
        DeploymentConfig.NetworkConfig memory networkConfig = config.getNetworkConfig(chainId);

        require(deployedAddresses.strategy != address(0), "Strategy not deployed");
        require(networkConfig.sovabtc != address(0), "sovaBTC not configured");

        vm.startBroadcast(adminPrivateKey);

        console.log("Managing liquidity on chain:", chainId);
        console.log("Strategy address:", deployedAddresses.strategy);
        console.log("sovaBTC address:", networkConfig.sovabtc);
        console.log("Action:", isDeposit ? "ADD LIQUIDITY" : "REMOVE LIQUIDITY");
        console.log("Amount:", amount);

        MultiCollateralStrategy strategy = MultiCollateralStrategy(deployedAddresses.strategy);
        IERC20 sovabtc = IERC20(networkConfig.sovabtc);

        if (isDeposit) {
            // Add liquidity
            uint256 currentBalance = sovabtc.balanceOf(address(strategy));
            console.log("Current strategy sovaBTC balance:", currentBalance);

            // Transfer sovaBTC to strategy
            require(sovabtc.balanceOf(msg.sender) >= amount, "Insufficient sovaBTC balance");
            sovabtc.approve(address(strategy), amount);
            sovabtc.transfer(address(strategy), amount);

            uint256 newBalance = sovabtc.balanceOf(address(strategy));
            console.log("New strategy sovaBTC balance:", newBalance);
            console.log("[OK] Added", amount, "sovaBTC liquidity");
        } else {
            // Remove liquidity (emergency withdrawal)
            uint256 currentBalance = sovabtc.balanceOf(address(strategy));
            console.log("Current strategy sovaBTC balance:", currentBalance);

            require(amount <= currentBalance, "Insufficient strategy balance");

            // Emergency withdraw sovaBTC
            strategy.emergencyWithdraw(networkConfig.sovabtc, amount, msg.sender);

            uint256 newBalance = sovabtc.balanceOf(address(strategy));
            console.log("New strategy sovaBTC balance:", newBalance);
            console.log("[OK] Removed", amount, "sovaBTC liquidity");
        }

        vm.stopBroadcast();

        console.log("\n=== Liquidity Management Complete ===");
        console.log("Final strategy sovaBTC balance:", sovabtc.balanceOf(address(strategy)));
    }
}
