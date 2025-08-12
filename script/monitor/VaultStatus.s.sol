// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {Script} from "forge-std/Script.sol";
import {console2} from "forge-std/console2.sol";
import {IERC20} from "forge-std/interfaces/IERC20.sol";

interface IMultiBTCVault {
    function totalAssets() external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function collateralRegistry() external view returns (address);
    function strategy() external view returns (address);
    function priceOracle() external view returns (address);
    function redemptionQueue() external view returns (address);
    function paused() external view returns (bool);
}

interface IMultiCollateralStrategy {
    function totalValue() external view returns (uint256);
    function vault() external view returns (address);
}

interface IPriceOracleReporter {
    function report() external view returns (uint256);
}

interface IManagedRedemptionQueue {
    function totalRequests() external view returns (uint256);
}

interface IMultiCollateralRegistry {
    function getSupportedCollaterals() external view returns (address[] memory);
    function getCollateralInfo(address token) external view returns (uint256 conversionRate, uint8 decimals, bool isActive);
}

contract VaultStatus is Script {
    // Contract addresses
    address constant VAULT = 0x73E27097221d4d9D5893a83350dC7A967b46fab7;
    address constant STRATEGY = 0x740907524EbD6A481a81cE76B5115A4cDDb80099;
    address constant QUEUE = 0x22BC73098CE1Ba2CaE5431fb32051cB4fc0F9C52;
    address constant PRICE_ORACLE = 0xDB4479A2360E118CCbD99B88e82522813BDE48f5;
    address constant REGISTRY = 0x15a9983784617aa8892b2677bbaEc23539482B65;
    
    // Mock tokens
    address constant WBTC = 0xe44b2870eFcd6Bb3C9305808012621f438e9636D;
    address constant TBTC = 0xE2b47f0dD766834b9DD2612D2d3632B05Ca89802;
    address constant SOVABTC = 0x05aB19d77516414f7333a8fd52cC1F49FF8eAFA9;
    
    function run() external view {
        console2.log("========================================");
        console2.log("   MULTI-COLLATERAL BTC VAULT STATUS");
        console2.log("========================================");
        console2.log("");
        
        // Vault Overview
        console2.log("VAULT OVERVIEW");
        console2.log("--------------");
        console2.log("Address:", VAULT);
        console2.log("Name: Multi-Collateral BTC Vault");
        console2.log("Symbol: mcBTC");
        
        uint256 totalAssets = IMultiBTCVault(VAULT).totalAssets();
        uint256 totalSupply = IMultiBTCVault(VAULT).totalSupply();
        bool isPaused = IMultiBTCVault(VAULT).paused();
        
        console2.log("Total Assets (8 decimals):", totalAssets);
        console2.log("Total Supply (18 decimals):", totalSupply);
        console2.log("Status:", isPaused ? "PAUSED" : "ACTIVE");
        
        if (totalSupply > 0) {
            uint256 sharePrice = (totalAssets * 1e18) / totalSupply;
            console2.log("Share Price (1e18):", sharePrice);
        } else {
            console2.log("Share Price: N/A (no shares)");
        }
        console2.log("");
        
        // Strategy Status
        console2.log("STRATEGY STATUS");
        console2.log("---------------");
        console2.log("Address:", STRATEGY);
        
        // Check collateral balances
        uint256 wbtcBalance = IERC20(WBTC).balanceOf(STRATEGY);
        uint256 tbtcBalance = IERC20(TBTC).balanceOf(STRATEGY);
        uint256 sovabtcBalance = IERC20(SOVABTC).balanceOf(STRATEGY);
        
        console2.log("Collateral Balances:");
        console2.log("  WBTC (8 decimals):", wbtcBalance);
        console2.log("  TBTC (18 decimals):", tbtcBalance);
        console2.log("  sovaBTC (8 decimals):", sovabtcBalance);
        console2.log("");
        
        // Price Oracle Status
        console2.log("PRICE ORACLE STATUS");
        console2.log("-------------------");
        console2.log("Address:", PRICE_ORACLE);
        
        uint256 currentNAV = IPriceOracleReporter(PRICE_ORACLE).report();
        console2.log("Current NAV (1e18):", currentNAV);
        console2.log("");
        
        // Redemption Queue Status
        console2.log("REDEMPTION QUEUE STATUS");
        console2.log("-----------------------");
        console2.log("Address:", QUEUE);
        
        uint256 totalRequests = IManagedRedemptionQueue(QUEUE).totalRequests();
        
        console2.log("Total Redemption Requests:", totalRequests);
        console2.log("Redemption Delay: 24 hours (Base Sepolia)");
        console2.log("");
        
        // Registry Status
        console2.log("COLLATERAL REGISTRY STATUS");
        console2.log("--------------------------");
        console2.log("Address:", REGISTRY);
        
        address[] memory supportedTokens = IMultiCollateralRegistry(REGISTRY).getSupportedCollaterals();
        console2.log("Supported Collaterals:", supportedTokens.length);
        
        for (uint256 i = 0; i < supportedTokens.length; i++) {
            (uint256 conversionRate, uint8 decimals, bool isActive) = 
                IMultiCollateralRegistry(REGISTRY).getCollateralInfo(supportedTokens[i]);
            
            string memory tokenName = "Unknown";
            if (supportedTokens[i] == WBTC) tokenName = "WBTC";
            else if (supportedTokens[i] == TBTC) tokenName = "TBTC";
            else if (supportedTokens[i] == SOVABTC) tokenName = "sovaBTC";
            
            console2.log("");
            console2.log("  Token", i + 1, ":", tokenName);
            console2.log("    Address:", supportedTokens[i]);
            console2.log("    Active:", isActive);
            console2.log("    Decimals:", decimals);
            console2.log("    Conversion Rate:", conversionRate);
        }
        console2.log("");
        
        // System Health Check
        console2.log("SYSTEM HEALTH CHECK");
        console2.log("-------------------");
        
        // Check connections
        address vaultStrategy = IMultiBTCVault(VAULT).strategy();
        address vaultQueue = IMultiBTCVault(VAULT).redemptionQueue();
        address vaultOracle = IMultiBTCVault(VAULT).priceOracle();
        address vaultRegistry = IMultiBTCVault(VAULT).collateralRegistry();
        
        console2.log("Vault -> Strategy:", vaultStrategy == STRATEGY ? "OK" : "MISMATCH");
        console2.log("Vault -> Queue:", vaultQueue == QUEUE ? "OK" : "MISMATCH");
        console2.log("Vault -> Oracle:", vaultOracle == PRICE_ORACLE ? "OK" : "MISMATCH");
        console2.log("Vault -> Registry:", vaultRegistry == REGISTRY ? "OK" : "MISMATCH");
        
        // Check strategy connection back to vault
        address strategyVault = IMultiCollateralStrategy(STRATEGY).vault();
        console2.log("Strategy -> Vault:", strategyVault == VAULT ? "OK" : "MISMATCH");
        console2.log("");
        
        // Summary
        _printSummary();
    }
    
    function _printSummary() internal view {
        console2.log("========================================");
        console2.log("              SUMMARY");
        console2.log("========================================");
        console2.log("System is monitoring Base Sepolia");
        console2.log("Last checked block:", block.number);
    }
}