// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {Script} from "forge-std/Script.sol";
import {console2} from "forge-std/console2.sol";

contract VerifyBaseSepolia is Script {
    // Contract addresses on Base Sepolia
    address constant ROLE_MANAGER = 0x15502fC5e872c8B22BA6dD5e01A7A5bd4f9A3d72;
    address constant REGISTRY = 0x15a9983784617aa8892b2677bbaEc23539482B65;
    address constant STRATEGY = 0x740907524EbD6A481a81cE76B5115A4cDDb80099;
    address constant VAULT = 0x73E27097221d4d9D5893a83350dC7A967b46fab7;
    address constant QUEUE = 0x22BC73098CE1Ba2CaE5431fb32051cB4fc0F9C52;
    address constant ORACLE = 0xDB4479A2360E118CCbD99B88e82522813BDE48f5;

    function run() external {
        console2.log("====================================");
        console2.log("Base Sepolia Contract Verification");
        console2.log("====================================");
        console2.log("");

        console2.log("Network: Base Sepolia (Chain ID: 84532)");
        console2.log("");

        console2.log("Contract Addresses for Verification:");
        console2.log("=====================================");
        console2.log("");

        // RoleManager
        console2.log("1. RoleManager:");
        console2.log("   Address:", ROLE_MANAGER);
        console2.log("   Verify command:");
        console2.log("   forge verify-contract %s \\", ROLE_MANAGER);
        console2.log("     src/RoleManager.sol:RoleManager \\");
        console2.log("     --chain-id 84532 \\");
        console2.log("     --etherscan-api-key $BASESCAN_KEY \\");
        console2.log("     --constructor-args $(cast abi-encode \"constructor(address)\" %s)", ROLE_MANAGER);
        console2.log("");

        // Registry
        console2.log("2. MultiCollateralRegistry:");
        console2.log("   Address:", REGISTRY);
        console2.log("   Verify command:");
        console2.log("   forge verify-contract %s \\", REGISTRY);
        console2.log("     src/strategies/MultiCollateralRegistry.sol:MultiCollateralRegistry \\");
        console2.log("     --chain-id 84532 \\");
        console2.log("     --etherscan-api-key $BASESCAN_KEY \\");
        console2.log("     --constructor-args $(cast abi-encode \"constructor(address)\" %s)", ROLE_MANAGER);
        console2.log("");

        // Strategy
        console2.log("3. MultiCollateralStrategy:");
        console2.log("   Address:", STRATEGY);
        console2.log("   Verify command:");
        console2.log("   forge verify-contract %s \\", STRATEGY);
        console2.log("     src/strategies/MultiCollateralStrategy.sol:MultiCollateralStrategy \\");
        console2.log("     --chain-id 84532 \\");
        console2.log("     --etherscan-api-key $BASESCAN_KEY \\");
        console2.log("     --constructor-args $(cast abi-encode \"constructor(address,address)\" %s %s)", ROLE_MANAGER, REGISTRY);
        console2.log("");

        // Vault
        console2.log("4. MultiBTCVault:");
        console2.log("   Address:", VAULT);
        console2.log("   Verify command:");
        console2.log("   forge verify-contract %s \\", VAULT);
        console2.log("     src/vaults/MultiBTCVault.sol:MultiBTCVault \\");
        console2.log("     --chain-id 84532 \\");
        console2.log("     --etherscan-api-key $BASESCAN_KEY");
        console2.log("");

        // Queue
        console2.log("5. ManagedRedemptionQueue:");
        console2.log("   Address:", QUEUE);
        console2.log("   Verify command:");
        console2.log("   forge verify-contract %s \\", QUEUE);
        console2.log("     src/vaults/ManagedRedemptionQueue.sol:ManagedRedemptionQueue \\");
        console2.log("     --chain-id 84532 \\");
        console2.log("     --etherscan-api-key $BASESCAN_KEY \\");
        console2.log("     --constructor-args $(cast abi-encode \"constructor(address,address,address)\" %s %s %s)", ROLE_MANAGER, VAULT, "0x05aB19d77516414f7333a8fd52cC1F49FF8eAFA9");
        console2.log("");

        // Oracle
        console2.log("6. PriceOracleReporter:");
        console2.log("   Address:", ORACLE);
        console2.log("   Verify command:");
        console2.log("   forge verify-contract %s \\", ORACLE);
        console2.log("     src/oracles/PriceOracleReporter.sol:PriceOracleReporter \\");
        console2.log("     --chain-id 84532 \\");
        console2.log("     --etherscan-api-key $BASESCAN_KEY \\");
        console2.log("     --constructor-args $(cast abi-encode \"constructor(address)\" %s)", ROLE_MANAGER);
        console2.log("");

        console2.log("====================================");
        console2.log("Basescan Links:");
        console2.log("====================================");
        console2.log("");
        
        console2.log("RoleManager: https://sepolia.basescan.org/address/%s#code", ROLE_MANAGER);
        console2.log("Registry: https://sepolia.basescan.org/address/%s#code", REGISTRY);
        console2.log("Strategy: https://sepolia.basescan.org/address/%s#code", STRATEGY);
        console2.log("Vault: https://sepolia.basescan.org/address/%s#code", VAULT);
        console2.log("Queue: https://sepolia.basescan.org/address/%s#code", QUEUE);
        console2.log("Oracle: https://sepolia.basescan.org/address/%s#code", ORACLE);
        console2.log("");

        console2.log("====================================");
        console2.log("Verification Script:");
        console2.log("====================================");
        console2.log("");
        console2.log("#!/bin/bash");
        console2.log("# Run this script to verify all contracts");
        console2.log("# Make sure to set BASESCAN_KEY environment variable");
        console2.log("");
        console2.log("export BASESCAN_KEY=KI5PMY8D813UGVZS7MEFMW7BW4AU8A14DV");
        console2.log("");
        console2.log("# Verify each contract");
        console2.log("echo 'Verifying contracts on Base Sepolia...'");
        console2.log("");
        
        // Generate bash commands for all contracts
        _generateBashCommand("MultiBTCVault", VAULT, "src/vaults/MultiBTCVault.sol:MultiBTCVault", "");
        _generateBashCommand("ManagedRedemptionQueue", QUEUE, "src/vaults/ManagedRedemptionQueue.sol:ManagedRedemptionQueue", "");
        _generateBashCommand("MultiCollateralStrategy", STRATEGY, "src/strategies/MultiCollateralStrategy.sol:MultiCollateralStrategy", "");
        _generateBashCommand("MultiCollateralRegistry", REGISTRY, "src/strategies/MultiCollateralRegistry.sol:MultiCollateralRegistry", "");
        _generateBashCommand("PriceOracleReporter", ORACLE, "src/oracles/PriceOracleReporter.sol:PriceOracleReporter", "");
        
        console2.log("");
        console2.log("echo 'Verification complete!'");
    }

    function _generateBashCommand(
        string memory name,
        address addr,
        string memory contractPath,
        string memory
    ) internal pure {
        console2.log("echo 'Verifying %s...'", name);
        console2.log("forge verify-contract %s %s \\", addr, contractPath);
        console2.log("  --chain-id 84532 \\");
        console2.log("  --etherscan-api-key $BASESCAN_KEY \\");
        console2.log("  --watch");
        console2.log("");
    }
}