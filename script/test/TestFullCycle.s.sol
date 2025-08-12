// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {Script} from "forge-std/Script.sol";
import {console2} from "forge-std/console2.sol";
import {IERC20} from "forge-std/interfaces/IERC20.sol";

interface IMultiBTCVault {
    function depositCollateral(address token, uint256 amount, address receiver) external returns (uint256 shares);
    function balanceOf(address account) external view returns (uint256);
    function totalAssets() external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function convertToAssets(uint256 shares) external view returns (uint256);
    function queueRedemption(uint256 shares, address receiver) external returns (uint256 requestId);
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
}

interface IMockToken {
    function mint(address to, uint256 amount) external;
    function decimals() external view returns (uint8);
}

contract TestFullCycle is Script {
    // Contract addresses
    address constant VAULT = 0x73E27097221d4d9D5893a83350dC7A967b46fab7;
    address constant QUEUE = 0x22BC73098CE1Ba2CaE5431fb32051cB4fc0F9C52;
    address constant WBTC = 0xe44b2870eFcd6Bb3C9305808012621f438e9636D;
    address constant SOVABTC = 0x05aB19d77516414f7333a8fd52cC1F49FF8eAFA9;
    
    uint256 constant DEPOSIT_AMOUNT = 1 * 1e8; // 1 WBTC (8 decimals)
    
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address user = vm.addr(deployerPrivateKey);
        
        console2.log("Testing Full Redemption Cycle");
        console2.log("==============================");
        console2.log("User:", user);
        console2.log("");
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Step 1: Mint and approve WBTC
        console2.log("Step 1: Preparing WBTC for deposit");
        IMockToken(WBTC).mint(user, DEPOSIT_AMOUNT);
        IERC20(WBTC).approve(VAULT, DEPOSIT_AMOUNT);
        uint256 wbtcBalance = IERC20(WBTC).balanceOf(user);
        console2.log("  WBTC balance:", wbtcBalance);
        console2.log("");
        
        // Step 2: Deposit to vault
        console2.log("Step 2: Depositing WBTC to vault");
        uint256 sharesBefore = IMultiBTCVault(VAULT).balanceOf(user);
        uint256 sharesReceived = IMultiBTCVault(VAULT).depositCollateral(WBTC, DEPOSIT_AMOUNT, user);
        uint256 sharesAfter = IMultiBTCVault(VAULT).balanceOf(user);
        console2.log("  Shares before deposit:", sharesBefore);
        console2.log("  Shares received:", sharesReceived);
        console2.log("  Shares after deposit:", sharesAfter);
        console2.log("  Total vault assets:", IMultiBTCVault(VAULT).totalAssets());
        console2.log("");
        
        // Step 3: Request redemption through vault (no approval needed - vault burns shares)
        console2.log("Step 3: Requesting redemption through vault");
        uint256 requestId = IMultiBTCVault(VAULT).queueRedemption(sharesReceived, user);
        console2.log("  Request ID:", requestId);
        
        vm.stopBroadcast();
        
        // Check request status (outside broadcast to avoid stack issues)
        _checkRequestStatus(requestId);
        
        // Step 4: Check redemption status
        console2.log("Step 4: Checking redemption status");
        console2.log("");
        
        // Check user balances (outside broadcast to avoid stack issues)
        console2.log("Final balances:");
        console2.log("  User mcBTC shares:", IMultiBTCVault(VAULT).balanceOf(user));
        console2.log("  User WBTC:", IERC20(WBTC).balanceOf(user));
        console2.log("  User sovaBTC:", IERC20(SOVABTC).balanceOf(user));
        
        console2.log("");
        console2.log("=== Redemption Request Successful ===");
        console2.log("Request ID", requestId, "created");
        console2.log("Waiting period: 1 day (Base Sepolia)");
        console2.log("");
        console2.log("Next steps:");
        console2.log("1. Wait for redemption period to pass");
        console2.log("2. Admin processes redemptions");
        console2.log("3. User claims sovaBTC");
    }
    
    function _checkRequestStatus(uint256 requestId) internal view {
        (
            address owner,
            uint256 shares,
            uint256 sovaBTCAmount,
            address receiver,
            uint256 queuedAt,
            bool processed
        ) = IManagedRedemptionQueue(QUEUE).getRedemptionRequest(requestId);
        
        console2.log("  Request details:");
        console2.log("    Owner:", owner);
        console2.log("    Shares:", shares);
        console2.log("    sovaBTC Amount:", sovaBTCAmount);
        console2.log("    Receiver:", receiver);
        console2.log("    Queued at:", queuedAt);
        console2.log("    Processed:", processed);
        console2.log("");
    }
}