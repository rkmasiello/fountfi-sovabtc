// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {Script} from "forge-std/Script.sol";
import {console2} from "forge-std/console2.sol";

contract VerifyContracts is Script {
    function run() external {
        console2.log("Contract verification instructions for Base Sepolia");
        console2.log("====================================================");
        console2.log("");
        console2.log("Run these commands to verify each contract:");
        console2.log("");
        
        // RoleManager
        console2.log("1. RoleManager (0x15502fC5e872c8B22BA6dD5e01A7A5bd4f9A3d72):");
        console2.log("forge verify-contract \\");
        console2.log("  --chain-id 84532 \\");
        console2.log("  --verifier-url https://api-sepolia.basescan.org/api \\");
        console2.log("  --etherscan-api-key KI5PMY8D813UGVZS7MEFMW7BW4AU8A14DV \\");
        console2.log("  --watch \\");
        console2.log("  0x15502fC5e872c8B22BA6dD5e01A7A5bd4f9A3d72 \\");
        console2.log("  src/access/RoleManager.sol:RoleManager");
        console2.log("");
        
        // Registry
        console2.log("2. MultiCollateralRegistry (0x15a9983784617aa8892b2677bbaEc23539482B65):");
        console2.log("forge verify-contract \\");
        console2.log("  --chain-id 84532 \\");
        console2.log("  --verifier-url https://api-sepolia.basescan.org/api \\");
        console2.log("  --etherscan-api-key KI5PMY8D813UGVZS7MEFMW7BW4AU8A14DV \\");
        console2.log("  --watch \\");
        console2.log("  --constructor-args $(cast abi-encode 'constructor(address)' 0x15502fC5e872c8B22BA6dD5e01A7A5bd4f9A3d72) \\");
        console2.log("  0x15a9983784617aa8892b2677bbaEc23539482B65 \\");
        console2.log("  src/registry/MultiCollateralRegistry.sol:MultiCollateralRegistry");
        console2.log("");
        
        // Strategy
        console2.log("3. MultiCollateralStrategy (0x740907524EbD6A481a81cE76B5115A4cDDb80099):");
        console2.log("forge verify-contract \\");
        console2.log("  --chain-id 84532 \\");
        console2.log("  --verifier-url https://api-sepolia.basescan.org/api \\");
        console2.log("  --etherscan-api-key KI5PMY8D813UGVZS7MEFMW7BW4AU8A14DV \\");
        console2.log("  --watch \\");
        console2.log("  --constructor-args $(cast abi-encode 'constructor(address,address,address)' 0x05aB19d77516414f7333a8fd52cC1F49FF8eAFA9 0x15a9983784617aa8892b2677bbaEc23539482B65 0x15502fC5e872c8B22BA6dD5e01A7A5bd4f9A3d72) \\");
        console2.log("  0x740907524EbD6A481a81cE76B5115A4cDDb80099 \\");
        console2.log("  src/strategy/MultiCollateralStrategy.sol:MultiCollateralStrategy");
        console2.log("");
        
        // Vault
        console2.log("4. MultiBTCVault (0x73E27097221d4d9D5893a83350dC7A967b46fab7):");
        console2.log("forge verify-contract \\");
        console2.log("  --chain-id 84532 \\");
        console2.log("  --verifier-url https://api-sepolia.basescan.org/api \\");
        console2.log("  --etherscan-api-key KI5PMY8D813UGVZS7MEFMW7BW4AU8A14DV \\");
        console2.log("  --watch \\");
        console2.log("  --constructor-args $(cast abi-encode 'constructor(string,string,address,address,address,address)' 'Multi-Collateral BTC Vault' 'mcBTC' 0x05aB19d77516414f7333a8fd52cC1F49FF8eAFA9 0x15a9983784617aa8892b2677bbaEc23539482B65 0x15502fC5e872c8B22BA6dD5e01A7A5bd4f9A3d72 0x0000000000000000000000000000000000000000) \\");
        console2.log("  0x73E27097221d4d9D5893a83350dC7A967b46fab7 \\");
        console2.log("  src/vaults/MultiBTCVault.sol:MultiBTCVault");
        console2.log("");
        
        // Queue
        console2.log("5. ManagedRedemptionQueue (0x22BC73098CE1Ba2CaE5431fb32051cB4fc0F9C52):");
        console2.log("forge verify-contract \\");
        console2.log("  --chain-id 84532 \\");
        console2.log("  --verifier-url https://api-sepolia.basescan.org/api \\");
        console2.log("  --etherscan-api-key KI5PMY8D813UGVZS7MEFMW7BW4AU8A14DV \\");
        console2.log("  --watch \\");
        console2.log("  --constructor-args $(cast abi-encode 'constructor(address,address,address,uint256)' 0x73E27097221d4d9D5893a83350dC7A967b46fab7 0x05aB19d77516414f7333a8fd52cC1F49FF8eAFA9 0x15502fC5e872c8B22BA6dD5e01A7A5bd4f9A3d72 86400) \\");
        console2.log("  0x22BC73098CE1Ba2CaE5431fb32051cB4fc0F9C52 \\");
        console2.log("  src/redemption/ManagedRedemptionQueue.sol:ManagedRedemptionQueue");
        console2.log("");
        
        // PriceOracle
        console2.log("6. PriceOracleReporter (0xDB4479A2360E118CCbD99B88e82522813BDE48f5):");
        console2.log("forge verify-contract \\");
        console2.log("  --chain-id 84532 \\");
        console2.log("  --verifier-url https://api-sepolia.basescan.org/api \\");
        console2.log("  --etherscan-api-key KI5PMY8D813UGVZS7MEFMW7BW4AU8A14DV \\");
        console2.log("  --watch \\");
        console2.log("  --constructor-args $(cast abi-encode 'constructor(address)' 0x15502fC5e872c8B22BA6dD5e01A7A5bd4f9A3d72) \\");
        console2.log("  0xDB4479A2360E118CCbD99B88e82522813BDE48f5 \\");
        console2.log("  src/oracles/PriceOracleReporter.sol:PriceOracleReporter");
        console2.log("");
    }
}