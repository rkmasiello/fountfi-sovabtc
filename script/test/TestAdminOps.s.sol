// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {Script} from "forge-std/Script.sol";
import {console2} from "forge-std/console2.sol";

interface IPriceOracleReporter {
    function report() external view returns (uint256);
    function updatePrice(uint256 newPrice) external;
}

interface IManagedRedemptionQueue {
    function processRedemptions(uint256[] calldata requestIds) external;
    function getRedemptionRequest(uint256 requestId) external view returns (
        address owner,
        uint256 shares,
        uint256 sovaBTCAmount,
        address receiver,
        uint256 queuedAt,
        bool processed
    );
    function forceProcessRedemption(uint256 requestId) external;
}

interface IMultiBTCVault {
    function pause() external;
    function unpause() external;
    function paused() external view returns (bool);
}

interface IMultiCollateralRegistry {
    function addCollateral(address token, uint256 conversionRate, uint8 decimals) external;
    function removeCollateral(address token) external;
    function updateConversionRate(address token, uint256 newRate) external;
    function isSupportedAsset(address token) external view returns (bool);
}

contract TestAdminOps is Script {
    // Contract addresses
    address constant VAULT = 0x73E27097221d4d9D5893a83350dC7A967b46fab7;
    address constant QUEUE = 0x22BC73098CE1Ba2CaE5431fb32051cB4fc0F9C52;
    address constant PRICE_ORACLE = 0xDB4479A2360E118CCbD99B88e82522813BDE48f5;
    address constant REGISTRY = 0x15a9983784617aa8892b2677bbaEc23539482B65;
    
    // Test token for collateral management
    address constant TEST_TOKEN = 0x1234567890123456789012345678901234567890;
    
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        console2.log("Testing Admin Operations");
        console2.log("========================");
        console2.log("");
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Test 1: NAV Price Update
        console2.log("Test 1: NAV Price Update");
        console2.log("------------------------");
        
        uint256 currentPrice = IPriceOracleReporter(PRICE_ORACLE).report();
        console2.log("  Current NAV:", currentPrice);
        
        uint256 newPrice = 1.05e18; // 5% increase
        console2.log("  Updating NAV to:", newPrice);
        
        try IPriceOracleReporter(PRICE_ORACLE).updatePrice(newPrice) {
            console2.log("  [SUCCESS] NAV update successful");
            uint256 updatedPrice = IPriceOracleReporter(PRICE_ORACLE).report();
            console2.log("  New NAV:", updatedPrice);
        } catch {
            console2.log("  [FAILED] NAV update failed (may need REPORTER role)");
        }
        console2.log("");
        
        // Test 2: Process Redemption Queue
        console2.log("Test 2: Process Redemption Queue");
        console2.log("---------------------------------");
        
        // Check if request ID 1 exists and can be processed
        try IManagedRedemptionQueue(QUEUE).getRedemptionRequest(1) returns (
            address owner,
            uint256 shares,
            uint256 sovaBTCAmount,
            address receiver,
            uint256 queuedAt,
            bool processed
        ) {
            console2.log("  Request ID 1 found:");
            console2.log("    Owner:", owner);
            console2.log("    Processed:", processed);
            
            if (!processed) {
                console2.log("  Attempting to process request...");
                
                uint256[] memory requestIds = new uint256[](1);
                requestIds[0] = 1;
                
                try IManagedRedemptionQueue(QUEUE).processRedemptions(requestIds) {
                    console2.log("  [SUCCESS] Redemption processed successfully");
                } catch {
                    console2.log("  [FAILED] Cannot process yet (may need to wait redemption period)");
                    
                    // Try force process as admin
                    console2.log("  Attempting force process as admin...");
                    try IManagedRedemptionQueue(QUEUE).forceProcessRedemption(1) {
                        console2.log("  [SUCCESS] Force process successful");
                    } catch {
                        console2.log("  [FAILED] Force process failed (may need PROTOCOL_ADMIN role)");
                    }
                }
            } else {
                console2.log("  Request already processed");
            }
        } catch {
            console2.log("  No redemption request with ID 1 found");
        }
        console2.log("");
        
        // Test 3: Emergency Pause/Unpause
        console2.log("Test 3: Emergency Pause/Unpause");
        console2.log("--------------------------------");
        
        bool isPaused = IMultiBTCVault(VAULT).paused();
        console2.log("  Current pause state:", isPaused);
        
        if (!isPaused) {
            console2.log("  Testing pause...");
            try IMultiBTCVault(VAULT).pause() {
                console2.log("  [SUCCESS] Vault paused successfully");
                
                // Now unpause
                console2.log("  Testing unpause...");
                try IMultiBTCVault(VAULT).unpause() {
                    console2.log("  [SUCCESS] Vault unpaused successfully");
                } catch {
                    console2.log("  [FAILED] Unpause failed");
                }
            } catch {
                console2.log("  [FAILED] Pause failed (may need PROTOCOL_ADMIN role)");
            }
        }
        console2.log("");
        
        // Test 4: Collateral Management
        console2.log("Test 4: Collateral Management");
        console2.log("------------------------------");
        
        console2.log("  Testing add new collateral...");
        try IMultiCollateralRegistry(REGISTRY).addCollateral(TEST_TOKEN, 1e18, 8) {
            console2.log("  [SUCCESS] New collateral added");
            
            // Update conversion rate
            console2.log("  Testing conversion rate update...");
            try IMultiCollateralRegistry(REGISTRY).updateConversionRate(TEST_TOKEN, 95e16) {
                console2.log("  [SUCCESS] Conversion rate updated to 0.95");
            } catch {
                console2.log("  [FAILED] Conversion rate update failed");
            }
            
            // Remove collateral
            console2.log("  Testing collateral removal...");
            try IMultiCollateralRegistry(REGISTRY).removeCollateral(TEST_TOKEN) {
                console2.log("  [SUCCESS] Collateral removed");
            } catch {
                console2.log("  [FAILED] Collateral removal failed");
            }
        } catch {
            console2.log("  [FAILED] Add collateral failed (may need PROTOCOL_ADMIN role)");
        }
        
        vm.stopBroadcast();
        
        console2.log("");
        console2.log("=== Admin Operations Test Complete ===");
        console2.log("");
        console2.log("Note: Some operations may fail if:");
        console2.log("- Admin roles not granted");
        console2.log("- Redemption period not expired");
        console2.log("- Contracts in unexpected state");
    }
}