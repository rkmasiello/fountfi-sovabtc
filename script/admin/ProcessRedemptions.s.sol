// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {ManagedRedemptionQueue} from "../../src/strategy/ManagedRedemptionQueue.sol";
import {DeploymentAddresses} from "../helpers/DeploymentAddresses.sol";

contract ProcessRedemptions is Script {
    DeploymentAddresses public addresses;

    function run() external {
        uint256 adminPrivateKey = vm.envUint("ADMIN_PRIVATE_KEY");
        uint256 chainId = block.chainid;

        addresses = new DeploymentAddresses();
        DeploymentAddresses.Addresses memory deployedAddresses = addresses.getDeployment(chainId);

        require(deployedAddresses.queue != address(0), "Queue not deployed");

        vm.startBroadcast(adminPrivateKey);

        console.log("Processing redemptions on chain:", chainId);
        console.log("Queue address:", deployedAddresses.queue);

        ManagedRedemptionQueue queue = ManagedRedemptionQueue(deployedAddresses.queue);

        // Get total pending shares
        uint256 totalPending = queue.totalPendingShares();
        console.log("Total pending shares:", totalPending);

        if (totalPending == 0) {
            console.log("No redemptions to process");
            vm.stopBroadcast();
            return;
        }

        // Note: In production, admin would need to track redemption request IDs
        // This is a simplified version for demonstration
        console.log("Processing redemptions...");
        console.log("Note: Admin should track specific request IDs to process");

        // Example: Process a specific redemption by ID (would be provided as parameter)
        uint256 requestId = vm.envOr("REQUEST_ID", uint256(0));
        if (requestId > 0) {
            (
                address owner,
                address receiver,
                uint256 shares,
                uint256 sovaBTCAmount,
                uint256 queuedAt,
                bool processed,
                bool cancelled
            ) = queue.getRedemptionRequest(requestId);

            if (!processed && !cancelled && owner != address(0)) {
                uint256 waitTime = block.timestamp - queuedAt;
                uint256 requiredWaitTime = queue.REDEMPTION_DELAY();

                if (waitTime >= requiredWaitTime) {
                    console.log("Processing redemption ID:", requestId);
                    console.log("  Owner:", owner);
                    console.log("  Receiver:", receiver);
                    console.log("  Shares:", shares);
                    console.log("  sovaBTC:", sovaBTCAmount);

                    uint256[] memory requestIds = new uint256[](1);
                    requestIds[0] = requestId;
                    try queue.processRedemptions(requestIds) {
                        console.log("  [OK] Processed successfully");
                    } catch {
                        console.log("  [FAIL] Failed to process");
                    }
                } else {
                    uint256 remainingTime = requiredWaitTime - waitTime;
                    console.log("Redemption not ready. ID:", requestId);
                    console.log("  Remaining days:", remainingTime / 1 days);
                }
            }
        }

        vm.stopBroadcast();

        console.log("\n=== Redemption Processing Complete ===");
        console.log("Total pending shares:", queue.totalPendingShares());
    }
}
