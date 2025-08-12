// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {Script} from "forge-std/Script.sol";
import {console2} from "forge-std/console2.sol";
import {IMultiBTCVault} from "../../src/interfaces/IMultiBTCVault.sol";
import {IManagedRedemptionQueue} from "../../src/interfaces/IManagedRedemptionQueue.sol";
import {IMultiCollateralRegistry} from "../../src/interfaces/IMultiCollateralRegistry.sol";
import {IERC20} from "forge-std/interfaces/IERC20.sol";

interface IMockToken is IERC20 {
    function mint(uint256 amount) external;
}

/**
 * @title LoadTest
 * @notice Comprehensive load testing script for Multi-Collateral BTC Vault
 * @dev Tests system with 50-100 concurrent users performing various operations
 */
contract LoadTest is Script {
    // Contract addresses
    address constant VAULT = 0x73E27097221d4d9D5893a83350dC7A967b46fab7;
    address constant QUEUE = 0x22BC73098CE1Ba2CaE5431fb32051cB4fc0F9C52;
    address constant REGISTRY = 0x15a9983784617aa8892b2677bbaEc23539482B65;
    
    // Token addresses
    address constant WBTC = 0xe44b2870eFcd6Bb3C9305808012621f438e9636D;
    address constant TBTC = 0xE2b47f0dD766834b9DD2612D2d3632B05Ca89802;
    address constant SOVABTC = 0x05aB19d77516414f7333a8fd52cC1F49FF8eAFA9;
    
    address constant ADMIN = 0xc96E00Ea87C0C23E4De12FBb086bA45a76F87ced;
    
    // Test parameters - configurable for different load levels
    uint256 public NUM_USERS = 100; // Default to 100 users
    uint256 constant MIN_DEPOSIT = 0.001e8; // 0.001 BTC in 8 decimals
    uint256 constant MAX_DEPOSIT = 0.1e8;   // 0.1 BTC in 8 decimals
    uint256 constant BATCH_SIZE = 10; // Process users in batches to avoid RPC limits
    
    // Performance metrics
    struct Metrics {
        uint256 totalDeposits;
        uint256 successfulDeposits;
        uint256 failedDeposits;
        uint256 totalRedemptions;
        uint256 successfulRedemptions;
        uint256 failedRedemptions;
        uint256 totalGasUsed;
        uint256 avgGasPerDeposit;
        uint256 avgGasPerRedemption;
        uint256 maxGasUsed;
        uint256 minGasUsed;
        uint256 startTime;
        uint256 endTime;
    }
    
    Metrics public metrics;
    
    struct TestUser {
        address addr;
        uint256 privateKey;
        address collateralToken;
        uint256 depositAmount;
        uint256 shares;
        uint256 redemptionRequestId;
        bool depositSuccess;
        bool redemptionSuccess;
        uint256 gasUsed;
    }
    
    TestUser[] public testUsers;
    
    function run() external {
        // Parse command line arguments for user count
        string memory userCountStr = vm.envOr("LOAD_TEST_USERS", string("100"));
        NUM_USERS = vm.parseUint(userCountStr);
        
        console2.log("========================================");
        console2.log("COMPREHENSIVE LOAD TESTING");
        console2.log("Testing with", NUM_USERS, "concurrent users");
        console2.log("========================================");
        
        metrics.startTime = block.timestamp;
        
        // Phase 1: Setup and user generation
        console2.log("\nPhase 1: User Generation");
        console2.log("------------------------");
        generateTestUsers();
        
        // Phase 2: Concurrent deposits
        console2.log("\nPhase 2: Concurrent Deposits");
        console2.log("-----------------------------");
        testConcurrentDeposits();
        
        // Phase 3: Mixed operations
        console2.log("\nPhase 3: Mixed Operations");
        console2.log("-------------------------");
        testMixedOperations();
        
        // Phase 4: Concurrent redemptions
        console2.log("\nPhase 4: Concurrent Redemptions");
        console2.log("--------------------------------");
        testConcurrentRedemptions();
        
        // Phase 5: Edge cases and stress tests
        console2.log("\nPhase 5: Edge Cases & Stress Tests");
        console2.log("-----------------------------------");
        testEdgeCases();
        
        // Phase 6: Admin operations under load
        console2.log("\nPhase 6: Admin Operations Under Load");
        console2.log("-------------------------------------");
        testAdminOperationsUnderLoad();
        
        metrics.endTime = block.timestamp;
        
        // Generate comprehensive report
        generateReport();
    }
    
    function generateTestUsers() internal {
        address[3] memory tokens = [WBTC, TBTC, SOVABTC];
        
        for (uint256 i = 0; i < NUM_USERS; i++) {
            uint256 privateKey = uint256(keccak256(abi.encodePacked("load_test_user", i, block.timestamp)));
            address userAddr = vm.addr(privateKey);
            
            TestUser memory user = TestUser({
                addr: userAddr,
                privateKey: privateKey,
                collateralToken: tokens[i % 3],
                depositAmount: MIN_DEPOSIT + (uint256(keccak256(abi.encodePacked(i))) % (MAX_DEPOSIT - MIN_DEPOSIT)),
                shares: 0,
                redemptionRequestId: 0,
                depositSuccess: false,
                redemptionSuccess: false,
                gasUsed: 0
            });
            
            testUsers.push(user);
            
            // Fund user with ETH for gas
            vm.deal(userAddr, 0.5 ether);
            
            if (i % 10 == 0) {
                console2.log("Generated", i + 1, "users...");
            }
        }
        
        console2.log("Total users generated:", NUM_USERS);
    }
    
    function testConcurrentDeposits() internal {
        console2.log("Starting concurrent deposits...");
        
        uint256 batchCount = (NUM_USERS + BATCH_SIZE - 1) / BATCH_SIZE;
        
        for (uint256 batch = 0; batch < batchCount; batch++) {
            uint256 startIdx = batch * BATCH_SIZE;
            uint256 endIdx = startIdx + BATCH_SIZE;
            if (endIdx > NUM_USERS) endIdx = NUM_USERS;
            
            console2.log("Processing batch", batch + 1, "of", batchCount);
            console2.log("  Users:", startIdx, "-", endIdx - 1);
            
            for (uint256 i = startIdx; i < endIdx; i++) {
                TestUser storage user = testUsers[i];
                
                vm.startBroadcast(user.privateKey);
                
                try this.executeDeposit(user.addr, user.collateralToken, user.depositAmount) returns (uint256 shares, uint256 gasUsed) {
                    user.shares = shares;
                    user.depositSuccess = true;
                    user.gasUsed = gasUsed;
                    metrics.successfulDeposits++;
                    metrics.totalGasUsed += gasUsed;
                    
                    if (gasUsed > metrics.maxGasUsed) metrics.maxGasUsed = gasUsed;
                    if (metrics.minGasUsed == 0 || gasUsed < metrics.minGasUsed) metrics.minGasUsed = gasUsed;
                } catch {
                    metrics.failedDeposits++;
                    console2.log("  Deposit failed for user", i);
                }
                
                vm.stopBroadcast();
                
                metrics.totalDeposits++;
            }
            
            // Small delay between batches to avoid RPC rate limits
            vm.warp(block.timestamp + 1);
        }
        
        console2.log("Deposits complete:");
        console2.log("  Successful:", metrics.successfulDeposits);
        console2.log("  Failed:", metrics.failedDeposits);
        
        if (metrics.successfulDeposits > 0) {
            metrics.avgGasPerDeposit = metrics.totalGasUsed / metrics.successfulDeposits;
            console2.log("  Avg gas per deposit:", metrics.avgGasPerDeposit);
        }
    }
    
    function testMixedOperations() internal {
        console2.log("Starting mixed operations (deposits + redemptions)...");
        
        // Half users deposit, half redeem
        for (uint256 i = 0; i < NUM_USERS / 2; i++) {
            // New deposits
            if (i < NUM_USERS / 4) {
                TestUser storage user = testUsers[i];
                if (!user.depositSuccess) {
                    vm.startBroadcast(user.privateKey);
                    
                    try this.executeDeposit(user.addr, user.collateralToken, user.depositAmount) returns (uint256 shares, uint256) {
                        user.shares = shares;
                        user.depositSuccess = true;
                        metrics.successfulDeposits++;
                    } catch {
                        console2.log("  Mixed deposit failed for user", i);
                    }
                    
                    vm.stopBroadcast();
                }
            }
            
            // Redemptions from users who deposited
            if (i >= NUM_USERS / 4 && i < NUM_USERS / 2) {
                TestUser storage user = testUsers[i];
                if (user.depositSuccess && user.shares > 0) {
                    vm.startBroadcast(user.privateKey);
                    
                    try this.executeRedemption(user.addr, user.shares / 2) returns (uint256 requestId, uint256 gasUsed) {
                        user.redemptionRequestId = requestId;
                        user.redemptionSuccess = true;
                        metrics.successfulRedemptions++;
                        metrics.totalGasUsed += gasUsed;
                    } catch {
                        console2.log("  Mixed redemption failed for user", i);
                    }
                    
                    vm.stopBroadcast();
                    metrics.totalRedemptions++;
                }
            }
        }
        
        console2.log("Mixed operations complete");
    }
    
    function testConcurrentRedemptions() internal {
        console2.log("Starting concurrent redemptions...");
        
        uint256 redemptionCount = 0;
        uint256 redemptionGas = 0;
        
        for (uint256 i = 0; i < NUM_USERS; i++) {
            TestUser storage user = testUsers[i];
            
            if (user.depositSuccess && user.shares > 0 && !user.redemptionSuccess) {
                vm.startBroadcast(user.privateKey);
                
                try this.executeRedemption(user.addr, user.shares) returns (uint256 requestId, uint256 gasUsed) {
                    user.redemptionRequestId = requestId;
                    user.redemptionSuccess = true;
                    metrics.successfulRedemptions++;
                    redemptionGas += gasUsed;
                    redemptionCount++;
                } catch {
                    metrics.failedRedemptions++;
                    console2.log("  Redemption failed for user", i);
                }
                
                vm.stopBroadcast();
                metrics.totalRedemptions++;
                
                if (redemptionCount % 10 == 0) {
                    console2.log("  Processed", redemptionCount, "redemptions...");
                }
            }
        }
        
        if (redemptionCount > 0) {
            metrics.avgGasPerRedemption = redemptionGas / redemptionCount;
            console2.log("Redemptions complete:");
            console2.log("  Total:", redemptionCount);
            console2.log("  Avg gas per redemption:", metrics.avgGasPerRedemption);
        }
    }
    
    function testEdgeCases() internal {
        console2.log("Testing edge cases...");
        
        // Test 1: Minimum deposit amount
        vm.startBroadcast(testUsers[0].privateKey);
        try this.executeDeposit(testUsers[0].addr, WBTC, MIN_DEPOSIT) {
            console2.log("  [OK] Minimum deposit successful");
        } catch {
            console2.log("  [FAIL] Minimum deposit failed");
        }
        vm.stopBroadcast();
        
        // Test 2: Below minimum deposit (should fail)
        vm.startBroadcast(testUsers[1].privateKey);
        try this.executeDeposit(testUsers[1].addr, WBTC, MIN_DEPOSIT - 1) {
            console2.log("  [FAIL] Below minimum deposit unexpectedly succeeded");
        } catch {
            console2.log("  [OK] Below minimum deposit correctly rejected");
        }
        vm.stopBroadcast();
        
        // Test 3: Zero amount redemption (should fail)
        if (testUsers[2].depositSuccess) {
            vm.startBroadcast(testUsers[2].privateKey);
            try this.executeRedemption(testUsers[2].addr, 0) {
                console2.log("  [FAIL] Zero redemption unexpectedly succeeded");
            } catch {
                console2.log("  [OK] Zero redemption correctly rejected");
            }
            vm.stopBroadcast();
        }
        
        // Test 4: Maximum gas scenario
        console2.log("  Testing maximum gas usage scenario...");
        uint256 maxGasTest = 0;
        for (uint256 i = 3; i < 8 && i < NUM_USERS; i++) {
            if (testUsers[i].depositSuccess) {
                vm.startBroadcast(testUsers[i].privateKey);
                uint256 gasStart = gasleft();
                try this.executeRedemption(testUsers[i].addr, testUsers[i].shares) {
                    uint256 gasUsed = gasStart - gasleft();
                    if (gasUsed > maxGasTest) maxGasTest = gasUsed;
                } catch {}
                vm.stopBroadcast();
            }
        }
        console2.log("  Max gas in edge case:", maxGasTest);
    }
    
    function testAdminOperationsUnderLoad() internal {
        console2.log("Testing admin operations under load...");
        
        // Collect redemption request IDs
        uint256[] memory requestIds = new uint256[](10);
        uint256 count = 0;
        
        for (uint256 i = 0; i < NUM_USERS && count < 10; i++) {
            if (testUsers[i].redemptionSuccess && testUsers[i].redemptionRequestId > 0) {
                requestIds[count] = testUsers[i].redemptionRequestId;
                count++;
            }
        }
        
        if (count > 0) {
            // Process redemptions as admin
            vm.startBroadcast(vm.envUint("PRIVATE_KEY"));
            
            uint256 gasStart = gasleft();
            try IManagedRedemptionQueue(QUEUE).processRedemptions(requestIds) {
                uint256 gasUsed = gasStart - gasleft();
                console2.log("  [OK] Admin processed", count, "redemptions");
                console2.log("  Gas used for batch processing:", gasUsed);
                console2.log("  Gas per redemption:", gasUsed / count);
            } catch {
                console2.log("  [FAIL] Admin redemption processing failed");
            }
            
            vm.stopBroadcast();
        }
        
        // Test pause/unpause during load
        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));
        
        try IMultiBTCVault(VAULT).pause() {
            console2.log("  [OK] System paused successfully");
            
            // Try operation while paused (should fail)
            vm.stopBroadcast();
            vm.startBroadcast(testUsers[0].privateKey);
            try this.executeDeposit(testUsers[0].addr, WBTC, MIN_DEPOSIT) {
                console2.log("  [FAIL] Deposit succeeded while paused (unexpected)");
            } catch {
                console2.log("  [OK] Deposit correctly blocked while paused");
            }
            vm.stopBroadcast();
            
            // Unpause
            vm.startBroadcast(vm.envUint("PRIVATE_KEY"));
            try IMultiBTCVault(VAULT).unpause() {
                console2.log("  [OK] System unpaused successfully");
            } catch {
                console2.log("  [FAIL] Failed to unpause system");
            }
        } catch {
            console2.log("  [FAIL] Failed to pause system");
        }
        
        vm.stopBroadcast();
    }
    
    function generateReport() internal {
        console2.log("\n========================================");
        console2.log("LOAD TESTING REPORT");
        console2.log("========================================");
        
        console2.log("\n== Test Configuration ==");
        console2.log("  Total Users:", NUM_USERS);
        console2.log("  Batch Size:", BATCH_SIZE);
        console2.log("  Deposit Range: 0.001 - 0.1 BTC");
        
        console2.log("\n== Performance Metrics ==");
        console2.log("  Total Operations:", metrics.totalDeposits + metrics.totalRedemptions);
        console2.log("  Duration:", metrics.endTime - metrics.startTime, "seconds");
        
        console2.log("\n== Deposits ==");
        console2.log("  Total Attempts:", metrics.totalDeposits);
        console2.log("  Successful:", metrics.successfulDeposits);
        console2.log("  Failed:", metrics.failedDeposits);
        console2.log("  Success Rate:", (metrics.successfulDeposits * 100) / metrics.totalDeposits, "%");
        console2.log("  Avg Gas:", metrics.avgGasPerDeposit);
        
        console2.log("\n== Redemptions ==");
        console2.log("  Total Attempts:", metrics.totalRedemptions);
        console2.log("  Successful:", metrics.successfulRedemptions);
        console2.log("  Failed:", metrics.failedRedemptions);
        if (metrics.totalRedemptions > 0) {
            console2.log("  Success Rate:", (metrics.successfulRedemptions * 100) / metrics.totalRedemptions, "%");
        }
        console2.log("  Avg Gas:", metrics.avgGasPerRedemption);
        
        console2.log("\n== Gas Analysis ==");
        console2.log("  Total Gas Used:", metrics.totalGasUsed);
        console2.log("  Max Gas (single tx):", metrics.maxGasUsed);
        console2.log("  Min Gas (single tx):", metrics.minGasUsed);
        
        // Calculate estimated costs (Base Sepolia gas price ~0.001 gwei)
        uint256 gasPrice = 0.001 gwei;
        uint256 totalCostWei = metrics.totalGasUsed * gasPrice;
        console2.log("  Est. Total Cost:", totalCostWei / 1e18, "ETH");
        
        console2.log("\n== System Health ==");
        uint256 successRate = ((metrics.successfulDeposits + metrics.successfulRedemptions) * 100) / 
                             (metrics.totalDeposits + metrics.totalRedemptions);
        
        if (successRate >= 95) {
            console2.log("  Status: EXCELLENT (", successRate, "% success rate)");
        } else if (successRate >= 90) {
            console2.log("  Status: GOOD (", successRate, "% success rate)");
        } else if (successRate >= 80) {
            console2.log("  Status: FAIR (", successRate, "% success rate)");
        } else {
            console2.log("  Status: NEEDS ATTENTION (", successRate, "% success rate)");
        }
        
        console2.log("\n== Recommendations ==");
        if (metrics.failedDeposits > metrics.totalDeposits / 10) {
            console2.log("  [WARNING] High deposit failure rate - check collateral token approvals");
        }
        if (metrics.failedRedemptions > metrics.totalRedemptions / 10) {
            console2.log("  [WARNING] High redemption failure rate - check queue capacity");
        }
        if (metrics.maxGasUsed > 500000) {
            console2.log("  [WARNING] High gas usage detected - consider optimization");
        }
        if (successRate >= 95) {
            console2.log("  [OK] System performing well under load");
        }
        
        console2.log("\n========================================");
        console2.log("Load testing complete!");
        console2.log("========================================");
    }
    
    // External helper functions for try-catch
    function executeDeposit(address user, address token, uint256 amount) external returns (uint256 shares, uint256 gasUsed) {
        // Mint tokens
        IMockToken(token).mint(amount);
        
        // Approve vault
        IERC20(token).approve(VAULT, amount);
        
        // Execute deposit
        uint256 gasStart = gasleft();
        shares = IMultiBTCVault(VAULT).depositCollateral(token, amount, user);
        gasUsed = gasStart - gasleft();
        
        return (shares, gasUsed);
    }
    
    function executeRedemption(address user, uint256 shares) external returns (uint256 requestId, uint256 gasUsed) {
        uint256 gasStart = gasleft();
        requestId = IMultiBTCVault(VAULT).queueRedemption(shares, user);
        gasUsed = gasStart - gasleft();
        
        return (requestId, gasUsed);
    }
    
    // Helper function
    function getTokenSymbol(address token) internal pure returns (string memory) {
        if (token == WBTC) return "WBTC";
        if (token == TBTC) return "TBTC";
        if (token == SOVABTC) return "sovaBTC";
        return "UNKNOWN";
    }
}