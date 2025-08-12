// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {IERC20} from "forge-std/interfaces/IERC20.sol";

import {MultiBTCVault} from "../src/vaults/MultiBTCVault.sol";
import {MultiCollateralRegistry} from "../src/registry/MultiCollateralRegistry.sol";
import {MultiCollateralStrategy} from "../src/strategy/MultiCollateralStrategy.sol";
import {ManagedRedemptionQueue} from "../src/strategy/ManagedRedemptionQueue.sol";
import {PriceOracleReporter} from "../src/reporter/PriceOracleReporter.sol";
import {RoleManager} from "../src/auth/RoleManager.sol";

/**
 * @title VerifyDeployment
 * @notice Script to verify all contracts are properly deployed and configured
 * @dev Run after deployment to ensure system is ready for use
 */
contract VerifyDeployment is Script {
    // Expected addresses (update after deployment)
    address public ROLE_MANAGER;
    address public REGISTRY;
    address public STRATEGY;
    address public VAULT;
    address public QUEUE;
    address public REPORTER;
    
    // Collateral tokens
    address public WBTC;
    address public TBTC;
    address public SOVABTC;
    
    // Verification results
    uint256 public passedTests;
    uint256 public failedTests;
    
    function run() external {
        console.log("=== Multi-Collateral BTC Vault Deployment Verification ===\n");
        
        // Load deployed addresses from config
        loadAddresses();
        
        // Run verification tests
        verifyContracts();
        verifyRoles();
        verifyCollaterals();
        verifyIntegration();
        verifyOperations();
        
        // Report results
        reportResults();
    }
    
    function loadAddresses() internal {
        // Load from environment or config file
        ROLE_MANAGER = vm.envAddress("ROLE_MANAGER");
        REGISTRY = vm.envAddress("REGISTRY");
        STRATEGY = vm.envAddress("STRATEGY");
        VAULT = vm.envAddress("VAULT");
        QUEUE = vm.envAddress("QUEUE");
        REPORTER = vm.envAddress("REPORTER");
        
        // Collateral tokens
        WBTC = vm.envAddress("WBTC");
        TBTC = vm.envAddress("TBTC");
        SOVABTC = vm.envAddress("SOVABTC");
        
        console.log("Loaded addresses from environment");
    }
    
    function verifyContracts() internal {
        console.log("\n[1] Verifying Contract Deployment...");
        
        // Check all contracts are deployed
        checkContract("RoleManager", ROLE_MANAGER);
        checkContract("Registry", REGISTRY);
        checkContract("Strategy", STRATEGY);
        checkContract("Vault", VAULT);
        checkContract("Queue", QUEUE);
        checkContract("Reporter", REPORTER);
        
        // Check collateral tokens
        checkContract("WBTC", WBTC);
        checkContract("TBTC", TBTC);
        checkContract("sovaBTC", SOVABTC);
    }
    
    function verifyRoles() internal {
        console.log("\n[2] Verifying Role Configuration...");
        
        RoleManager rm = RoleManager(ROLE_MANAGER);
        
        // Check admin roles are set
        uint256 PROTOCOL_ADMIN = rm.PROTOCOL_ADMIN();
        uint256 STRATEGY_OPERATOR = rm.STRATEGY_OPERATOR();
        
        address admin = vm.envAddress("ADMIN_ADDRESS");
        address operator = vm.envAddress("OPERATOR_ADDRESS");
        
        checkRole("Protocol Admin", rm, PROTOCOL_ADMIN, admin);
        checkRole("Strategy Operator", rm, STRATEGY_OPERATOR, operator);
    }
    
    function verifyCollaterals() internal {
        console.log("\n[3] Verifying Collateral Registration...");
        
        MultiCollateralRegistry registry = MultiCollateralRegistry(REGISTRY);
        
        // Check WBTC registration
        checkCollateral("WBTC", registry, WBTC, 8);
        
        // Check TBTC registration
        checkCollateral("TBTC", registry, TBTC, 18);
        
        // Check sovaBTC registration
        checkCollateral("sovaBTC", registry, SOVABTC, 18);
        
        // Verify supported collaterals list
        address[] memory supported = registry.getSupportedCollaterals();
        if (supported.length == 3) {
            console.log("All 3 collaterals registered");
            passedTests++;
        } else {
            console.log("Expected 3 collaterals, found:", supported.length);
            failedTests++;
        }
    }
    
    function verifyIntegration() internal {
        console.log("\n[4] Verifying Contract Integration...");
        
        MultiBTCVault vault = MultiBTCVault(VAULT);
        MultiCollateralStrategy strategy = MultiCollateralStrategy(STRATEGY);
        ManagedRedemptionQueue queue = ManagedRedemptionQueue(QUEUE);
        PriceOracleReporter oracle = PriceOracleReporter(REPORTER);
        
        // Check vault configuration
        checkAddress("Vault Strategy", address(vault.strategy()), STRATEGY);
        checkAddress("Vault Queue", address(vault.redemptionQueue()), QUEUE);
        checkAddress("Vault Oracle", address(vault.priceOracle()), REPORTER);
        checkAddress("Vault Registry", address(vault.collateralRegistry()), REGISTRY);
        
        // Check strategy configuration
        checkAddress("Strategy Vault", strategy.vault(), VAULT);
        checkAddress("Strategy Registry", address(strategy.collateralRegistry()), REGISTRY);
        
        // Check queue configuration
        checkAddress("Queue Vault", address(queue.vault()), VAULT);
        
        // Check minimum deposit
        uint256 minDeposit = vault.MINIMUM_INVESTMENT();
        if (minDeposit == 1e5) {
            console.log("Minimum deposit set to 0.001 BTC (1e5 satoshis)");
            passedTests++;
        } else {
            console.log("Incorrect minimum deposit:", minDeposit);
            failedTests++;
        }
        
        // Check redemption delay
        uint256 delay = queue.REDEMPTION_DELAY();
        if (delay == 14 days) {
            console.log("Redemption delay set to 14 days");
            passedTests++;
        } else {
            console.log("  Incorrect redemption delay:", delay);
            failedTests++;
        }
    }
    
    function verifyOperations() internal {
        console.log("\n[5] Verifying Basic Operations...");
        
        MultiBTCVault vault = MultiBTCVault(VAULT);
        
        // Check vault is not paused
        if (!vault.paused()) {
            console.log("Vault is not paused");
            passedTests++;
        } else {
            console.log("  Vault is paused");
            failedTests++;
        }
        
        // Check total assets (should be 0 initially)
        uint256 totalAssets = vault.totalAssets();
        console.log("  Total Assets:", totalAssets);
        
        // Check total supply (should be 0 initially)
        uint256 totalSupply = vault.totalSupply();
        console.log("  Total Supply:", totalSupply);
        
        // Check NAV is set
        PriceOracleReporter oracle = PriceOracleReporter(REPORTER);
        uint256 currentPrice = oracle.getCurrentPrice();
        if (currentPrice > 0) {
            console.log("Oracle price set:", currentPrice);
            passedTests++;
        } else {
            console.log("Oracle price not set (may be intentional)");
        }
        
        // Test deposit preview (dry run)
        try vault.previewDeposit(1e8) returns (uint256 shares) {
            console.log("Deposit preview working. Expected shares:", shares);
            passedTests++;
        } catch {
            console.log("  Deposit preview failed");
            failedTests++;
        }
    }
    
    // Helper functions
    
    function checkContract(string memory name, address addr) internal {
        if (addr != address(0) && addr.code.length > 0) {
            console.log(string.concat("", name, " deployed at:"), addr);
            passedTests++;
        } else {
            console.log(string.concat("  ", name, " not deployed"));
            failedTests++;
        }
    }
    
    function checkRole(string memory roleName, RoleManager rm, uint256 role, address account) internal {
        if (rm.hasAllRoles(account, role)) {
            console.log(string.concat("", roleName, " role granted to:"), account);
            passedTests++;
        } else {
            console.log(string.concat("  ", roleName, " role not granted"));
            failedTests++;
        }
    }
    
    function checkCollateral(string memory name, MultiCollateralRegistry registry, address token, uint8 expectedDecimals) internal {
        if (registry.isSupportedAsset(token)) {
            (uint256 conversionRate, uint8 decimals, bool isActive) = registry.getCollateralInfo(token);
            if (isActive && decimals == expectedDecimals) {
                console.log(string.concat("", name, " registered correctly"));
                passedTests++;
            } else {
                console.log(string.concat("  ", name, " config incorrect"));
                failedTests++;
            }
        } else {
            console.log(string.concat("  ", name, " not registered"));
            failedTests++;
        }
    }
    
    function checkAddress(string memory name, address actual, address expected) internal {
        if (actual == expected) {
            console.log(string.concat("", name, " configured correctly"));
            passedTests++;
        } else {
            console.log(string.concat("  ", name, " misconfigured"));
            console.log("    Expected:", expected);
            console.log("    Actual:", actual);
            failedTests++;
        }
    }
    
    function reportResults() internal {
        console.log("\n=== Verification Complete ===");
        console.log("Passed:", passedTests);
        console.log("Failed:", failedTests);
        
        if (failedTests == 0) {
            console.log("\n All verification tests passed! System is ready for use.");
        } else {
            console.log("\n Some tests failed. Please review and fix issues before proceeding.");
            revert("Deployment verification failed");
        }
    }
}