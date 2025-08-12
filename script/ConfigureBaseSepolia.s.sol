// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {MultiCollateralStrategy} from "../src/strategy/MultiCollateralStrategy.sol";
import {MultiBTCVault} from "../src/vaults/MultiBTCVault.sol";

contract ConfigureBaseSepolia is Script {
    // Deployed contract addresses
    address constant ROLE_MANAGER = 0x15502fC5e872c8B22BA6dD5e01A7A5bd4f9A3d72;
    address constant REGISTRY = 0x15a9983784617aa8892b2677bbaEc23539482B65;
    address constant STRATEGY = 0x740907524EbD6A481a81cE76B5115A4cDDb80099;
    address constant VAULT = 0x73E27097221d4d9D5893a83350dC7A967b46fab7;
    address constant QUEUE = 0x22BC73098CE1Ba2CaE5431fb32051cB4fc0F9C52;
    address constant REPORTER = 0xDB4479A2360E118CCbD99B88e82522813BDE48f5;
    
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        vm.startBroadcast(deployerPrivateKey);
        
        console.log("\n========================================");
        console.log("   Configuring Base Sepolia Contracts");
        console.log("========================================\n");
        
        // Connect Strategy to Vault
        console.log("Setting vault on strategy...");
        MultiCollateralStrategy strategy = MultiCollateralStrategy(STRATEGY);
        strategy.setVault(VAULT);
        console.log("Strategy connected to Vault");
        
        // Connect Vault to Queue
        console.log("\nSetting redemption queue on vault...");
        MultiBTCVault vault = MultiBTCVault(VAULT);
        vault.setRedemptionQueue(QUEUE);
        console.log("Vault connected to Queue");
        
        // Set Strategy on Vault
        console.log("\nSetting strategy on vault...");
        vault.setStrategy(STRATEGY);
        console.log("Vault connected to Strategy");
        
        // Set Price Oracle on Vault
        console.log("\nSetting price oracle on vault...");
        vault.setPriceOracle(REPORTER);
        console.log("Vault connected to Price Oracle");
        
        vm.stopBroadcast();
        
        console.log("\n========================================");
        console.log("   Configuration Complete!");
        console.log("========================================\n");
        
        console.log("System is now fully configured and ready for use!");
        console.log("\nContract Connections:");
        console.log("- Strategy -> Vault: Connected");
        console.log("- Vault -> Strategy: Connected");
        console.log("- Vault -> Queue: Connected");
        console.log("- Vault -> PriceOracle: Connected");
    }
}