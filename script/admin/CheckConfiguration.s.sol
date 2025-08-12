// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {Script} from "forge-std/Script.sol";
import {console2} from "forge-std/console2.sol";

interface IMultiCollateralRegistry {
    function isSupportedAsset(address token) external view returns (bool);
    function getCollateralInfo(address token) external view returns (uint256 conversionRate, uint8 decimals, bool isActive);
}

interface IMultiBTCVault {
    function collateralRegistry() external view returns (address);
    function strategy() external view returns (address);
    function totalAssets() external view returns (uint256);
}

contract CheckConfiguration is Script {
    address constant VAULT = 0x73E27097221d4d9D5893a83350dC7A967b46fab7;
    address constant REGISTRY = 0x15a9983784617aa8892b2677bbaEc23539482B65;
    address constant WBTC = 0xe44b2870eFcd6Bb3C9305808012621f438e9636D;
    address constant TBTC = 0xE2b47f0dD766834b9DD2612D2d3632B05Ca89802;
    address constant SOVABTC = 0x05aB19d77516414f7333a8fd52cC1F49FF8eAFA9;
    
    function run() external view {
        console2.log("Checking Vault Configuration");
        console2.log("=============================");
        console2.log("");
        
        // Check vault connections
        console2.log("Vault connections:");
        address vaultRegistry = IMultiBTCVault(VAULT).collateralRegistry();
        address vaultStrategy = IMultiBTCVault(VAULT).strategy();
        console2.log("  Collateral Registry:", vaultRegistry);
        console2.log("  Strategy:", vaultStrategy);
        console2.log("  Total Assets:", IMultiBTCVault(VAULT).totalAssets());
        console2.log("");
        
        // Check token support
        console2.log("Token Support Status:");
        
        // Check WBTC
        bool wbtcSupported = IMultiCollateralRegistry(REGISTRY).isSupportedAsset(WBTC);
        console2.log("  WBTC:", wbtcSupported ? "SUPPORTED" : "NOT SUPPORTED");
        if (wbtcSupported) {
            (uint256 conversionRate, uint8 decimals, bool isActive) = IMultiCollateralRegistry(REGISTRY).getCollateralInfo(WBTC);
            console2.log("    Decimals:", decimals);
            console2.log("    Conversion Rate:", conversionRate);
        }
        
        // Check TBTC
        bool tbtcSupported = IMultiCollateralRegistry(REGISTRY).isSupportedAsset(TBTC);
        console2.log("  TBTC:", tbtcSupported ? "SUPPORTED" : "NOT SUPPORTED");
        if (tbtcSupported) {
            (uint256 conversionRate, uint8 decimals, bool isActive) = IMultiCollateralRegistry(REGISTRY).getCollateralInfo(TBTC);
            console2.log("    Decimals:", decimals);
            console2.log("    Conversion Rate:", conversionRate);
        }
        
        // Check sovaBTC
        bool sovabtcSupported = IMultiCollateralRegistry(REGISTRY).isSupportedAsset(SOVABTC);
        console2.log("  sovaBTC:", sovabtcSupported ? "SUPPORTED" : "NOT SUPPORTED");
        if (sovabtcSupported) {
            (uint256 conversionRate, uint8 decimals, bool isActive) = IMultiCollateralRegistry(REGISTRY).getCollateralInfo(SOVABTC);
            console2.log("    Decimals:", decimals);
            console2.log("    Conversion Rate:", conversionRate);
        }
        
        console2.log("");
        console2.log("Configuration check complete!");
    }
}