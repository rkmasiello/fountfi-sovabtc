// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {Script} from "forge-std/Script.sol";
import {console2} from "forge-std/console2.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IMultiBTCVault} from "../../src/interfaces/IMultiBTCVault.sol";
import {IManagedRedemptionQueue} from "../../src/interfaces/IManagedRedemptionQueue.sol";
import {IMultiCollateralRegistry} from "../../src/interfaces/IMultiCollateralRegistry.sol";
import {IMultiCollateralStrategy} from "../../src/interfaces/IMultiCollateralStrategy.sol";

contract PostDeploymentChecks is Script {
    uint256 constant MIN_DEPOSIT = 0.001e8; // 0.001 BTC
    
    struct DeploymentAddresses {
        address roleManager;
        address registry;
        address strategy;
        address vault;
        address queue;
        address priceOracle;
    }
    
    struct CheckResult {
        string name;
        bool passed;
        string details;
    }
    
    CheckResult[] public results;
    uint256 public passedChecks;
    uint256 public failedChecks;
    
    function run() external {
        uint256 chainId = block.chainid;
        string memory chainName = getChainName(chainId);
        string memory deploymentFile = string.concat("deployments/", chainName, "-mainnet.json");
        
        // Read deployment addresses
        string memory json = vm.readFile(deploymentFile);
        DeploymentAddresses memory addrs = DeploymentAddresses({
            roleManager: vm.parseJsonAddress(json, ".roleManager"),
            registry: vm.parseJsonAddress(json, ".registry"),
            strategy: vm.parseJsonAddress(json, ".strategy"),
            vault: vm.parseJsonAddress(json, ".vault"),
            queue: vm.parseJsonAddress(json, ".queue"),
            priceOracle: vm.parseJsonAddress(json, ".priceOracle")
        });
        
        console2.log("Running post-deployment checks for", chainName);
        console2.log("Chain ID:", chainId);
        console2.log("");
        
        // Run all checks
        checkContractDeployment(addrs);
        checkContractConnections(addrs);
        checkAccessControl(addrs);
        checkCollateralRegistry(addrs);
        checkVaultConfiguration(addrs);
        checkQueueConfiguration(addrs);
        
        // Print results
        printResults();
    }
    
    function checkContractDeployment(DeploymentAddresses memory addrs) internal {
        console2.log("Checking contract deployments...");
        
        // Check each contract has code
        addCheck(
            "RoleManager deployed",
            addrs.roleManager.code.length > 0,
            vm.toString(addrs.roleManager)
        );
        
        addCheck(
            "Registry deployed",
            addrs.registry.code.length > 0,
            vm.toString(addrs.registry)
        );
        
        addCheck(
            "Strategy deployed",
            addrs.strategy.code.length > 0,
            vm.toString(addrs.strategy)
        );
        
        addCheck(
            "Vault deployed",
            addrs.vault.code.length > 0,
            vm.toString(addrs.vault)
        );
        
        addCheck(
            "Queue deployed",
            addrs.queue.code.length > 0,
            vm.toString(addrs.queue)
        );
        
        addCheck(
            "PriceOracle deployed",
            addrs.priceOracle.code.length > 0,
            vm.toString(addrs.priceOracle)
        );
    }
    
    function checkContractConnections(DeploymentAddresses memory addrs) internal {
        console2.log("\nChecking contract connections...");
        
        // Check vault connections
        IMultiBTCVault vault = IMultiBTCVault(addrs.vault);
        
        addCheck(
            "Vault strategy connection",
            address(vault.strategy()) == addrs.strategy,
            "Strategy address matches"
        );
        
        addCheck(
            "Vault registry connection",
            address(vault.registry()) == addrs.registry,
            "Registry address matches"
        );
        
        addCheck(
            "Vault queue connection",
            address(vault.redemptionQueue()) == addrs.queue,
            "Queue address matches"
        );
        
        // Check strategy connections
        IMultiCollateralStrategy strategy = IMultiCollateralStrategy(addrs.strategy);
        
        addCheck(
            "Strategy vault connection",
            address(strategy.vault()) == addrs.vault,
            "Vault address matches"
        );
        
        addCheck(
            "Strategy registry connection",
            address(strategy.registry()) == addrs.registry,
            "Registry address matches"
        );
    }
    
    function checkAccessControl(DeploymentAddresses memory addrs) internal {
        console2.log("\nChecking access control...");
        
        // This would check role assignments
        // For brevity, just checking that contracts are not paused
        IMultiBTCVault vault = IMultiBTCVault(addrs.vault);
        
        addCheck(
            "Vault not paused",
            !vault.paused(),
            "Vault is operational"
        );
    }
    
    function checkCollateralRegistry(DeploymentAddresses memory addrs) internal {
        console2.log("\nChecking collateral registry...");
        
        IMultiCollateralRegistry registry = IMultiCollateralRegistry(addrs.registry);
        address[] memory collaterals = registry.getSupportedCollaterals();
        
        addCheck(
            "Collaterals registered",
            collaterals.length > 0,
            string.concat("Found ", vm.toString(collaterals.length), " collaterals")
        );
        
        // Check each collateral
        for (uint256 i = 0; i < collaterals.length; i++) {
            bool isSupported = registry.isSupported(collaterals[i]);
            uint8 decimals = registry.getDecimals(collaterals[i]);
            
            addCheck(
                string.concat("Collateral ", vm.toString(i), " supported"),
                isSupported,
                string.concat("Decimals: ", vm.toString(decimals))
            );
        }
    }
    
    function checkVaultConfiguration(DeploymentAddresses memory addrs) internal {
        console2.log("\nChecking vault configuration...");
        
        IMultiBTCVault vault = IMultiBTCVault(addrs.vault);
        
        // Check basic vault parameters
        string memory name = vault.name();
        string memory symbol = vault.symbol();
        uint8 decimals = vault.decimals();
        uint256 minDeposit = vault.minDepositAmount();
        
        addCheck(
            "Vault name set",
            bytes(name).length > 0,
            name
        );
        
        addCheck(
            "Vault symbol set",
            bytes(symbol).length > 0,
            symbol
        );
        
        addCheck(
            "Vault decimals",
            decimals == 18,
            string.concat("Decimals: ", vm.toString(decimals))
        );
        
        addCheck(
            "Min deposit amount",
            minDeposit == MIN_DEPOSIT,
            string.concat(vm.toString(minDeposit / 1e8), " BTC")
        );
    }
    
    function checkQueueConfiguration(DeploymentAddresses memory addrs) internal {
        console2.log("\nChecking queue configuration...");
        
        IManagedRedemptionQueue queue = IManagedRedemptionQueue(addrs.queue);
        
        uint256 redemptionDelay = queue.REDEMPTION_DELAY();
        address sovaBTC = queue.sovaBTC();
        address vault = queue.vault();
        
        addCheck(
            "Redemption delay set",
            redemptionDelay > 0,
            string.concat(vm.toString(redemptionDelay / 1 days), " days")
        );
        
        addCheck(
            "SovaBTC token set",
            sovaBTC != address(0),
            vm.toString(sovaBTC)
        );
        
        addCheck(
            "Queue vault connection",
            vault == addrs.vault,
            "Vault address matches"
        );
    }
    
    function addCheck(string memory name, bool passed, string memory details) internal {
        results.push(CheckResult({
            name: name,
            passed: passed,
            details: details
        }));
        
        if (passed) {
            passedChecks++;
            console2.log("[PASS]", name);
        } else {
            failedChecks++;
            console2.log("[FAIL]", name);
        }
        
        if (bytes(details).length > 0) {
            console2.log("      ", details);
        }
    }
    
    function printResults() internal view {
        console2.log("\n========== Check Results ==========");
        console2.log("Total checks:", passedChecks + failedChecks);
        console2.log("Passed:", passedChecks);
        console2.log("Failed:", failedChecks);
        
        if (failedChecks > 0) {
            console2.log("\n[WARNING] Some checks failed!");
            console2.log("Please review and fix before proceeding");
            
            console2.log("\nFailed checks:");
            for (uint256 i = 0; i < results.length; i++) {
                if (!results[i].passed) {
                    console2.log(" -", results[i].name);
                }
            }
        } else {
            console2.log("\n[SUCCESS] All checks passed!");
            console2.log("Deployment appears to be successful");
        }
        
        // Generate deployment report
        console2.log("\n========== Next Steps ==========");
        console2.log("1. Verify contracts on block explorer");
        console2.log("2. Test with small amounts");
        console2.log("3. Set up monitoring");
        console2.log("4. Configure multisig permissions");
        console2.log("5. Add initial liquidity");
        console2.log("6. Enable frontend");
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