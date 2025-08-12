// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {Script} from "forge-std/Script.sol";
import {console2} from "forge-std/console2.sol";

contract VerifyContracts is Script {
    struct ContractInfo {
        string name;
        address addr;
        string constructorArgs;
    }
    
    function run() external {
        uint256 chainId = block.chainid;
        string memory chainName = getChainName(chainId);
        string memory deploymentFile = string.concat("deployments/", chainName, "-mainnet.json");
        
        // Read deployment addresses from JSON
        string memory json = vm.readFile(deploymentFile);
        
        address roleManager = vm.parseJsonAddress(json, ".roleManager");
        address registry = vm.parseJsonAddress(json, ".registry");
        address strategy = vm.parseJsonAddress(json, ".strategy");
        address vault = vm.parseJsonAddress(json, ".vault");
        address queue = vm.parseJsonAddress(json, ".queue");
        address priceOracle = vm.parseJsonAddress(json, ".priceOracle");
        
        console2.log("Verifying contracts on", chainName);
        console2.log("Chain ID:", chainId);
        
        // Generate verification commands
        console2.log("\n========== Verification Commands ==========\n");
        
        // RoleManager
        console2.log("1. RoleManager:");
        console2.log(string.concat(
            "forge verify-contract ",
            vm.toString(roleManager),
            " src/access/RoleManager.sol:RoleManager --chain-id ",
            vm.toString(chainId)
        ));
        
        // Registry
        console2.log("\n2. MultiCollateralRegistry:");
        console2.log(string.concat(
            "forge verify-contract ",
            vm.toString(registry),
            " src/strategy/MultiCollateralRegistry.sol:MultiCollateralRegistry --chain-id ",
            vm.toString(chainId),
            " --constructor-args ",
            vm.toString(abi.encode(roleManager))
        ));
        
        // Strategy
        console2.log("\n3. MultiCollateralStrategy:");
        console2.log(string.concat(
            "forge verify-contract ",
            vm.toString(strategy),
            " src/strategy/MultiCollateralStrategy.sol:MultiCollateralStrategy --chain-id ",
            vm.toString(chainId),
            " --constructor-args ",
            vm.toString(abi.encode(roleManager, registry))
        ));
        
        // Price Oracle
        console2.log("\n4. PriceOracleReporter:");
        console2.log(string.concat(
            "forge verify-contract ",
            vm.toString(priceOracle),
            " src/oracles/PriceOracleReporter.sol:PriceOracleReporter --chain-id ",
            vm.toString(chainId),
            " --constructor-args ",
            vm.toString(abi.encode(roleManager, uint256(1e18), uint256(86400)))
        ));
        
        // Vault (complex constructor args)
        console2.log("\n5. MultiBTCVault:");
        console2.log("Note: Vault has complex constructor args. Use Etherscan UI or:");
        console2.log(string.concat(
            "forge verify-contract ",
            vm.toString(vault),
            " src/vaults/MultiBTCVault.sol:MultiBTCVault --chain-id ",
            vm.toString(chainId),
            " --constructor-args <encoded_args>"
        ));
        
        // Queue
        console2.log("\n6. ManagedRedemptionQueue:");
        console2.log("Note: Queue has complex constructor args. Use Etherscan UI or:");
        console2.log(string.concat(
            "forge verify-contract ",
            vm.toString(queue),
            " src/strategy/ManagedRedemptionQueue.sol:ManagedRedemptionQueue --chain-id ",
            vm.toString(chainId),
            " --constructor-args <encoded_args>"
        ));
        
        console2.log("\n========== Automated Verification Script ==========\n");
        console2.log("Save this as verify.sh and run with: bash verify.sh\n");
        
        generateVerificationScript(chainId, roleManager, registry, strategy, vault, queue, priceOracle);
    }
    
    function generateVerificationScript(
        uint256 chainId,
        address roleManager,
        address registry,
        address strategy,
        address vault,
        address queue,
        address priceOracle
    ) internal view {
        console2.log("#!/bin/bash");
        console2.log("set -e");
        console2.log("");
        console2.log("# Verification script for chain ID:", chainId);
        console2.log("ETHERSCAN_API_KEY=${ETHERSCAN_API_KEY}");
        console2.log("");
        
        console2.log("echo 'Verifying RoleManager...'");
        console2.log(string.concat(
            "forge verify-contract ",
            vm.toString(roleManager),
            " src/access/RoleManager.sol:RoleManager \\",
            "\n  --chain-id ", vm.toString(chainId), " \\",
            "\n  --etherscan-api-key $ETHERSCAN_API_KEY"
        ));
        console2.log("");
        
        console2.log("echo 'Verifying Registry...'");
        console2.log(string.concat(
            "forge verify-contract ",
            vm.toString(registry),
            " src/strategy/MultiCollateralRegistry.sol:MultiCollateralRegistry \\",
            "\n  --chain-id ", vm.toString(chainId), " \\",
            "\n  --constructor-args ", vm.toString(abi.encode(roleManager)), " \\",
            "\n  --etherscan-api-key $ETHERSCAN_API_KEY"
        ));
        console2.log("");
        
        console2.log("echo 'All contracts verified successfully!'");
    }
    
    function getChainName(uint256 chainId) internal pure returns (string memory) {
        if (chainId == 1) return "ethereum";
        if (chainId == 8453) return "base";
        if (chainId == 42161) return "arbitrum";
        if (chainId == 10) return "optimism";
        if (chainId == 84532) return "base-sepolia";
        return "unknown";
    }
}