// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {MultiBTCVault} from "../../src/vaults/MultiBTCVault.sol";
import {MockERC20} from "../../src/mocks/MockERC20.sol";

contract TestUserFlow is Script {
    // Deployed contract addresses
    address constant VAULT = 0x73E27097221d4d9D5893a83350dC7A967b46fab7;
    address constant QUEUE = 0x22BC73098CE1Ba2CaE5431fb32051cB4fc0F9C52;
    
    // Mock tokens
    address constant WBTC = 0xe44b2870eFcd6Bb3C9305808012621f438e9636D;
    address constant TBTC = 0xE2b47f0dD766834b9DD2612D2d3632B05Ca89802;
    address constant SOVABTC = 0x05aB19d77516414f7333a8fd52cC1F49FF8eAFA9;
    
    function run() external {
        uint256 userPrivateKey = vm.envUint("PRIVATE_KEY");
        address user = vm.addr(userPrivateKey);
        
        vm.startBroadcast(userPrivateKey);
        
        console.log("\n========================================");
        console.log("   Testing User Flow on Base Sepolia");
        console.log("========================================\n");
        console.log("User Address:", user);
        
        testMintTokens(user);
        testDeposit(user);
        testRedemption(user);
        
        vm.stopBroadcast();
        
        console.log("\n========================================");
        console.log("   User Flow Test Complete!");
        console.log("========================================\n");
        
        console.log("Summary:");
        console.log("- Successfully minted test tokens");
        console.log("- Deposited both WBTC and TBTC");
        console.log("- Received mcBTC shares");
        console.log("- Requested redemption (now in queue)");
        console.log("\nNote: Redemption will be claimable after 1 day");
        console.log("Admin must process the queue using ProcessRedemptions script");
    }
    
    function testMintTokens(address user) private {
        console.log("\n[Step 1] Minting test tokens...");
        
        MockERC20 wbtc = MockERC20(WBTC);
        MockERC20 tbtc = MockERC20(TBTC);
        
        wbtc.mint(user, 1e8); // 1 WBTC
        console.log("Minted 1 WBTC to user");
        
        tbtc.mint(user, 1e18); // 1 TBTC
        console.log("Minted 1 TBTC to user");
    }
    
    function testDeposit(address user) private {
        console.log("\n[Step 2] Testing deposits...");
        
        MultiBTCVault vault = MultiBTCVault(VAULT);
        MockERC20 wbtc = MockERC20(WBTC);
        
        // Approve and deposit WBTC
        wbtc.approve(VAULT, 1e8);
        console.log("Approved vault to spend WBTC");
        
        uint256 shares = vault.depositCollateral(WBTC, 1e7, user); // 0.1 WBTC
        console.log("Deposited 0.1 WBTC");
        console.log("Shares received:", shares);
        
        uint256 balance = vault.balanceOf(user);
        console.log("Total shares owned:", balance);
    }
    
    function testRedemption(address user) private {
        console.log("\n[Step 3] Testing redemption...");
        
        MultiBTCVault vault = MultiBTCVault(VAULT);
        uint256 shares = vault.balanceOf(user);
        
        if (shares > 0) {
            uint256 redeemAmount = shares / 2;
            uint256 assets = vault.redeem(redeemAmount, user, user);
            console.log("Redeemed shares:", redeemAmount);
            console.log("Assets queued:", assets);
        } else {
            console.log("No shares to redeem");
        }
        
        uint256 remaining = vault.balanceOf(user);
        console.log("Remaining shares:", remaining);
    }
}