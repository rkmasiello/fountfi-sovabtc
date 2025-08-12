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

contract TestMultiUser is Script {
    address constant VAULT = 0x73E27097221d4d9D5893a83350dC7A967b46fab7;
    address constant QUEUE = 0x22BC73098CE1Ba2CaE5431fb32051cB4fc0F9C52;
    address constant REGISTRY = 0x15a9983784617aa8892b2677bbaEc23539482B65;
    
    address constant WBTC = 0xe44b2870eFcd6Bb3C9305808012621f438e9636D;
    address constant TBTC = 0xE2b47f0dD766834b9DD2612D2d3632B05Ca89802;
    address constant SOVABTC = 0x05aB19d77516414f7333a8fd52cC1F49FF8eAFA9;
    
    address constant ADMIN = 0xc96E00ea87C0C23e4de12fBb086ba45A76F87cEd;
    
    uint256 constant NUM_USERS = 10;
    uint256 constant MIN_DEPOSIT = 0.001e8; // 0.001 BTC in 8 decimals
    uint256 constant MAX_DEPOSIT = 0.1e8;   // 0.1 BTC in 8 decimals
    
    struct TestUser {
        address addr;
        uint256 privateKey;
        address collateralToken;
        uint256 depositAmount;
        uint256 shares;
        uint256 redemptionRequestId;
    }
    
    TestUser[] public testUsers;
    
    function run() external {
        console2.log("Starting Multi-User Testing Scenarios");
        console2.log("======================================");
        
        // Generate test users
        generateTestUsers();
        
        // Test 1: Multiple concurrent deposits
        testConcurrentDeposits();
        
        // Test 2: Multiple redemption requests
        testConcurrentRedemptions();
        
        // Test 3: Admin processes redemptions
        testAdminProcessing();
        
        // Test 4: Users claim redemptions
        testClaimRedemptions();
        
        // Test 5: New deposits during redemption processing
        testDepositsDuringRedemptions();
        
        // Test 6: Edge cases
        testEdgeCases();
        
        console2.log("\n======================================");
        console2.log("Multi-User Testing Complete!");
        printFinalStats();
    }
    
    function generateTestUsers() internal {
        console2.log("\n1. Generating Test Users");
        console2.log("------------------------");
        
        address[3] memory tokens = [WBTC, TBTC, SOVABTC];
        
        for (uint256 i = 0; i < NUM_USERS; i++) {
            uint256 privateKey = uint256(keccak256(abi.encodePacked("test_user", i, block.timestamp)));
            address userAddr = vm.addr(privateKey);
            
            TestUser memory user = TestUser({
                addr: userAddr,
                privateKey: privateKey,
                collateralToken: tokens[i % 3],
                depositAmount: MIN_DEPOSIT + (i * (MAX_DEPOSIT - MIN_DEPOSIT) / NUM_USERS),
                shares: 0,
                redemptionRequestId: 0
            });
            
            testUsers.push(user);
            
            // Fund user with ETH for gas
            vm.deal(userAddr, 0.1 ether);
            
            console2.log("User", i, ":", userAddr);
            console2.log("  Token:", getTokenSymbol(user.collateralToken));
            console2.log("  Amount:", user.depositAmount / 1e8, "BTC");
        }
    }
    
    function testConcurrentDeposits() internal {
        console2.log("\n2. Testing Concurrent Deposits");
        console2.log("-------------------------------");
        
        uint256 totalDeposited = 0;
        
        for (uint256 i = 0; i < testUsers.length; i++) {
            TestUser storage user = testUsers[i];
            
            vm.startBroadcast(user.privateKey);
            
            // Mint tokens for user
            IMockToken(user.collateralToken).mint(user.depositAmount);
            
            // Approve vault
            IERC20(user.collateralToken).approve(VAULT, user.depositAmount);
            
            // Deposit
            uint256 sharesBefore = IERC20(VAULT).balanceOf(user.addr);
            IMultiBTCVault(VAULT).deposit(user.collateralToken, user.depositAmount, user.addr);
            uint256 sharesAfter = IERC20(VAULT).balanceOf(user.addr);
            
            user.shares = sharesAfter - sharesBefore;
            totalDeposited += user.depositAmount;
            
            console2.log("User", i, "deposited", user.depositAmount / 1e8, "BTC, received", user.shares / 1e18, "mcBTC");
            
            vm.stopBroadcast();
        }
        
        console2.log("Total deposited:", totalDeposited / 1e8, "BTC");
    }
    
    function testConcurrentRedemptions() internal {
        console2.log("\n3. Testing Concurrent Redemption Requests");
        console2.log("------------------------------------------");
        
        // Half of users request redemptions
        uint256 redemptionCount = NUM_USERS / 2;
        uint256 totalRedemptionShares = 0;
        
        for (uint256 i = 0; i < redemptionCount; i++) {
            TestUser storage user = testUsers[i];
            
            vm.startBroadcast(user.privateKey);
            
            // Request redemption for half of their shares
            uint256 redeemShares = user.shares / 2;
            uint256 requestId = IMultiBTCVault(VAULT).requestRedemption(redeemShares);
            user.redemptionRequestId = requestId;
            
            totalRedemptionShares += redeemShares;
            
            console2.log("User", i, "requested redemption of", redeemShares / 1e18, "mcBTC (Request ID:", requestId, ")");
            
            vm.stopBroadcast();
        }
        
        console2.log("Total redemption requests:", totalRedemptionShares / 1e18, "mcBTC");
    }
    
    function testAdminProcessing() internal {
        console2.log("\n4. Testing Admin Processing");
        console2.log("----------------------------");
        
        // Get all pending requests
        uint256[] memory requestIds = new uint256[](NUM_USERS / 2);
        uint256 count = 0;
        
        for (uint256 i = 0; i < testUsers.length; i++) {
            if (testUsers[i].redemptionRequestId > 0) {
                requestIds[count] = testUsers[i].redemptionRequestId;
                count++;
            }
        }
        
        // Process first batch (3 requests)
        uint256 batchSize = 3;
        if (count >= batchSize) {
            uint256[] memory batch = new uint256[](batchSize);
            for (uint256 i = 0; i < batchSize; i++) {
                batch[i] = requestIds[i];
            }
            
            vm.startBroadcast(vm.envUint("PRIVATE_KEY"));
            IManagedRedemptionQueue(QUEUE).processRedemptions(batch);
            vm.stopBroadcast();
            
            console2.log("Admin processed", batchSize, "redemption requests");
        }
    }
    
    function testClaimRedemptions() internal {
        console2.log("\n5. Testing Claim Redemptions");
        console2.log("-----------------------------");
        
        uint256 claimCount = 0;
        
        for (uint256 i = 0; i < testUsers.length; i++) {
            TestUser storage user = testUsers[i];
            
            if (user.redemptionRequestId > 0) {
                vm.startBroadcast(user.privateKey);
                
                IManagedRedemptionQueue.RedemptionRequest memory request = 
                    IManagedRedemptionQueue(QUEUE).getRedemptionRequest(user.redemptionRequestId);
                
                if (request.processed && !request.claimed) {
                    IManagedRedemptionQueue(QUEUE).claimRedemption(user.redemptionRequestId);
                    console2.log("User", i, "claimed redemption (Amount:", request.redeemableAmount / 1e8, "sovaBTC)");
                    claimCount++;
                }
                
                vm.stopBroadcast();
            }
        }
        
        console2.log("Total claims processed:", claimCount);
    }
    
    function testDepositsDuringRedemptions() internal {
        console2.log("\n6. Testing New Deposits During Redemptions");
        console2.log("-------------------------------------------");
        
        // Users who didn't request redemptions make new deposits
        uint256 newDepositCount = 0;
        
        for (uint256 i = NUM_USERS / 2; i < testUsers.length; i++) {
            TestUser storage user = testUsers[i];
            
            vm.startBroadcast(user.privateKey);
            
            uint256 newAmount = MIN_DEPOSIT;
            IMockToken(user.collateralToken).mint(newAmount);
            IERC20(user.collateralToken).approve(VAULT, newAmount);
            
            uint256 sharesBefore = IERC20(VAULT).balanceOf(user.addr);
            IMultiBTCVault(VAULT).deposit(user.collateralToken, newAmount, user.addr);
            uint256 sharesAfter = IERC20(VAULT).balanceOf(user.addr);
            
            uint256 newShares = sharesAfter - sharesBefore;
            user.shares += newShares;
            
            console2.log("User", i, "made additional deposit of", newAmount / 1e8, "BTC");
            newDepositCount++;
            
            vm.stopBroadcast();
        }
        
        console2.log("New deposits made:", newDepositCount);
    }
    
    function testEdgeCases() internal {
        console2.log("\n7. Testing Edge Cases");
        console2.log("----------------------");
        
        // Test minimum deposit
        testMinimumDeposit();
        
        // Test queue capacity
        testQueueCapacity();
        
        // Test share price consistency
        testSharePriceConsistency();
    }
    
    function testMinimumDeposit() internal {
        console2.log("\nTesting minimum deposit (0.001 BTC)...");
        
        uint256 testKey = uint256(keccak256("edge_case_user"));
        address testUser = vm.addr(testKey);
        vm.deal(testUser, 0.1 ether);
        
        vm.startBroadcast(testKey);
        
        IMockToken(WBTC).mint(MIN_DEPOSIT);
        IERC20(WBTC).approve(VAULT, MIN_DEPOSIT);
        
        try IMultiBTCVault(VAULT).deposit(WBTC, MIN_DEPOSIT, testUser) returns (uint256 shares) {
            console2.log("Minimum deposit successful, received", shares / 1e18, "mcBTC");
        } catch {
            console2.log("Minimum deposit failed (as expected if below threshold)");
        }
        
        vm.stopBroadcast();
    }
    
    function testQueueCapacity() internal {
        console2.log("\nTesting queue with multiple pending requests...");
        
        uint256 pendingShares = IManagedRedemptionQueue(QUEUE).getTotalPendingShares();
        console2.log("Total pending shares in queue:", pendingShares / 1e18, "mcBTC");
    }
    
    function testSharePriceConsistency() internal {
        console2.log("\nTesting share price consistency...");
        
        uint256 sharePrice = IMultiBTCVault(VAULT).sharePrice();
        uint256 totalAssets = IMultiBTCVault(VAULT).totalAssets();
        uint256 totalSupply = IERC20(VAULT).totalSupply();
        
        console2.log("Share price:", sharePrice / 1e18);
        console2.log("Total assets:", totalAssets / 1e8, "BTC");
        console2.log("Total supply:", totalSupply / 1e18, "mcBTC");
        
        if (totalSupply > 0) {
            uint256 calculatedPrice = (totalAssets * 1e18) / totalSupply;
            console2.log("Calculated price:", calculatedPrice / 1e18);
            
            uint256 priceDiff = sharePrice > calculatedPrice 
                ? sharePrice - calculatedPrice 
                : calculatedPrice - sharePrice;
                
            if (priceDiff < 1e14) { // 0.0001 tolerance
                console2.log("Share price is consistent ✓");
            } else {
                console2.log("Share price inconsistency detected!");
            }
        }
    }
    
    function printFinalStats() internal view {
        console2.log("\nFinal Statistics");
        console2.log("----------------");
        
        uint256 totalUserShares = 0;
        uint256 totalUserValue = 0;
        
        for (uint256 i = 0; i < testUsers.length; i++) {
            uint256 balance = IERC20(VAULT).balanceOf(testUsers[i].addr);
            totalUserShares += balance;
        }
        
        uint256 vaultTVL = IMultiBTCVault(VAULT).totalAssets();
        uint256 sharePrice = IMultiBTCVault(VAULT).sharePrice();
        
        console2.log("Vault TVL:", vaultTVL / 1e8, "BTC");
        console2.log("Total user shares:", totalUserShares / 1e18, "mcBTC");
        console2.log("Current share price:", sharePrice / 1e18, "BTC/mcBTC");
        console2.log("Number of test users:", testUsers.length);
    }
    
    function getTokenSymbol(address token) internal pure returns (string memory) {
        if (token == WBTC) return "WBTC";
        if (token == TBTC) return "TBTC";
        if (token == SOVABTC) return "sovaBTC";
        return "UNKNOWN";
    }
}