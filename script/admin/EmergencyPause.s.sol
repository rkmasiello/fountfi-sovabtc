// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {MultiBTCVault} from "../../src/vaults/MultiBTCVault.sol";
import {ManagedRedemptionQueue} from "../../src/strategy/ManagedRedemptionQueue.sol";
import {DeploymentAddresses} from "../helpers/DeploymentAddresses.sol";

contract EmergencyPause is Script {
    DeploymentAddresses public addresses;

    function run() external {
        uint256 adminPrivateKey = vm.envUint("ADMIN_PRIVATE_KEY");
        uint256 chainId = block.chainid;
        bool shouldPause = vm.envBool("PAUSE"); // true to pause, false to unpause

        addresses = new DeploymentAddresses();
        DeploymentAddresses.Addresses memory deployedAddresses = addresses.getDeployment(chainId);

        require(deployedAddresses.vault != address(0), "Vault not deployed");
        require(deployedAddresses.queue != address(0), "Queue not deployed");

        vm.startBroadcast(adminPrivateKey);

        console.log("Emergency pause operation on chain:", chainId);
        console.log("Action:", shouldPause ? "PAUSE" : "UNPAUSE");

        MultiBTCVault vault = MultiBTCVault(deployedAddresses.vault);
        ManagedRedemptionQueue queue = ManagedRedemptionQueue(deployedAddresses.queue);

        // Pause/unpause vault
        if (shouldPause) {
            if (!vault.paused()) {
                vault.pause();
                console.log("[OK] Vault paused");
            } else {
                console.log("Vault already paused");
            }
        } else {
            if (vault.paused()) {
                vault.unpause();
                console.log("[OK] Vault unpaused");
            } else {
                console.log("Vault already unpaused");
            }
        }

        // Pause/unpause queue
        if (shouldPause) {
            if (!queue.paused()) {
                queue.pause();
                console.log("[OK] Queue paused");
            } else {
                console.log("Queue already paused");
            }
        } else {
            if (queue.paused()) {
                queue.unpause();
                console.log("[OK] Queue unpaused");
            } else {
                console.log("Queue already unpaused");
            }
        }

        vm.stopBroadcast();

        console.log("\n=== Emergency Pause Complete ===");
        console.log("Vault paused:", vault.paused());
        console.log("Queue paused:", queue.paused());
    }
}
