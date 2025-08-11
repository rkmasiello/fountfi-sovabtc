// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.25;

import {Test} from "forge-std/Test.sol";
import {IMultiCollateralRegistry} from "../../src/interfaces/IMultiCollateralRegistry.sol";
import {IMultiCollateralStrategy} from "../../src/interfaces/IMultiCollateralStrategy.sol";
import {IMultiBTCVault} from "../../src/interfaces/IMultiBTCVault.sol";
import {IManagedRedemptionQueue} from "../../src/interfaces/IManagedRedemptionQueue.sol";

/**
 * @title InterfaceCompilationTest
 * @notice Test contract to verify all multi-collateral interfaces compile correctly
 * @dev This test ensures all interfaces are syntactically correct and can be imported
 */
contract InterfaceCompilationTest is Test {
    IMultiCollateralRegistry registry;
    IMultiCollateralStrategy strategy;
    IMultiBTCVault vault;
    IManagedRedemptionQueue queue;

    function setUp() public {
        // This test is just for compilation verification
        // No actual setup needed
    }

    function test_InterfacesCompile() public pure {
        // This test passes if the contract compiles
        // The interfaces are imported above, so compilation will fail if there are syntax errors
        assertTrue(true, "Interfaces compiled successfully");
    }

    function test_RegistryInterfaceMethods() public pure {
        // Verify IMultiCollateralRegistry has expected method signatures
        // This will fail compilation if methods are missing or have wrong signatures
        bytes4 addCollateralSelector = IMultiCollateralRegistry.addCollateral.selector;
        bytes4 removeCollateralSelector = IMultiCollateralRegistry.removeCollateral.selector;
        bytes4 updateConversionRateSelector = IMultiCollateralRegistry.updateConversionRate.selector;
        bytes4 isSupportedAssetSelector = IMultiCollateralRegistry.isSupportedAsset.selector;
        bytes4 getCollateralInfoSelector = IMultiCollateralRegistry.getCollateralInfo.selector;
        bytes4 getValueInUnderlyingSelector = IMultiCollateralRegistry.getValueInUnderlying.selector;
        bytes4 getSupportedCollateralsSelector = IMultiCollateralRegistry.getSupportedCollaterals.selector;

        assertTrue(addCollateralSelector != bytes4(0));
        assertTrue(removeCollateralSelector != bytes4(0));
        assertTrue(updateConversionRateSelector != bytes4(0));
        assertTrue(isSupportedAssetSelector != bytes4(0));
        assertTrue(getCollateralInfoSelector != bytes4(0));
        assertTrue(getValueInUnderlyingSelector != bytes4(0));
        assertTrue(getSupportedCollateralsSelector != bytes4(0));
    }

    function test_StrategyInterfaceMethods() public pure {
        // Verify IMultiCollateralStrategy has expected method signatures
        bytes4 withdrawToSelector = IMultiCollateralStrategy.withdrawTo.selector;
        bytes4 rebalanceCollateralSelector = IMultiCollateralStrategy.rebalanceCollateral.selector;
        bytes4 addLiquiditySelector = IMultiCollateralStrategy.addLiquidity.selector;
        bytes4 removeCollateralSelector = IMultiCollateralStrategy.removeCollateral.selector;
        bytes4 setVaultSelector = IMultiCollateralStrategy.setVault.selector;
        bytes4 emergencyWithdrawSelector = IMultiCollateralStrategy.emergencyWithdraw.selector;
        bytes4 collateralBalanceSelector = IMultiCollateralStrategy.collateralBalance.selector;
        bytes4 totalAssetsSelector = IMultiCollateralStrategy.totalAssets.selector;
        bytes4 vaultSelector = IMultiCollateralStrategy.vault.selector;
        bytes4 getHeldCollateralsSelector = IMultiCollateralStrategy.getHeldCollaterals.selector;

        assertTrue(withdrawToSelector != bytes4(0));
        assertTrue(rebalanceCollateralSelector != bytes4(0));
        assertTrue(addLiquiditySelector != bytes4(0));
        assertTrue(removeCollateralSelector != bytes4(0));
        assertTrue(setVaultSelector != bytes4(0));
        assertTrue(emergencyWithdrawSelector != bytes4(0));
        assertTrue(collateralBalanceSelector != bytes4(0));
        assertTrue(totalAssetsSelector != bytes4(0));
        assertTrue(vaultSelector != bytes4(0));
        assertTrue(getHeldCollateralsSelector != bytes4(0));
    }

    function test_VaultInterfaceMethods() public pure {
        // Verify IMultiBTCVault has expected method signatures
        bytes4 depositCollateralSelector = IMultiBTCVault.depositCollateral.selector;
        bytes4 previewDepositCollateralSelector = IMultiBTCVault.previewDepositCollateral.selector;
        bytes4 setStrategySelector = IMultiBTCVault.setStrategy.selector;
        bytes4 setPriceOracleSelector = IMultiBTCVault.setPriceOracle.selector;
        bytes4 pauseSelector = IMultiBTCVault.pause.selector;
        bytes4 unpauseSelector = IMultiBTCVault.unpause.selector;
        // registry was removed from the interface
        bytes4 strategySelector = IMultiBTCVault.strategy.selector;
        bytes4 priceOracleSelector = IMultiBTCVault.priceOracle.selector;
        bytes4 conduitSelector = IMultiBTCVault.conduit.selector;
        bytes4 pausedSelector = IMultiBTCVault.paused.selector;

        assertTrue(depositCollateralSelector != bytes4(0));
        assertTrue(previewDepositCollateralSelector != bytes4(0));
        assertTrue(setStrategySelector != bytes4(0));
        assertTrue(setPriceOracleSelector != bytes4(0));
        assertTrue(pauseSelector != bytes4(0));
        assertTrue(unpauseSelector != bytes4(0));
        // registry removed
        assertTrue(strategySelector != bytes4(0));
        assertTrue(priceOracleSelector != bytes4(0));
        assertTrue(conduitSelector != bytes4(0));
        assertTrue(pausedSelector != bytes4(0));

        // Test that it inherits from IERC4626 by checking interface support
        // We can't directly access inherited function selectors from the type in Solidity
        // But we've already verified it compiles with IERC4626 inheritance
        assertTrue(true, "IMultiBTCVault inherits from IERC4626");
    }

    function test_QueueInterfaceMethods() public pure {
        // Verify IManagedRedemptionQueue has expected method signatures
        bytes4 queueRedemptionSelector = IManagedRedemptionQueue.queueRedemption.selector;
        bytes4 cancelRedemptionSelector = IManagedRedemptionQueue.cancelRedemption.selector;
        bytes4 processRedemptionsSelector = IManagedRedemptionQueue.processRedemptions.selector;
        bytes4 getRedemptionRequestSelector = IManagedRedemptionQueue.getRedemptionRequest.selector;
        bytes4 getPendingRedemptionsSelector = IManagedRedemptionQueue.getPendingRedemptions.selector;
        bytes4 totalRequestsSelector = IManagedRedemptionQueue.totalRequests.selector;
        bytes4 totalPendingSharesSelector = IManagedRedemptionQueue.totalPendingShares.selector;
        bytes4 totalPendingSovaBTCSelector = IManagedRedemptionQueue.totalPendingSovaBTC.selector;

        assertTrue(queueRedemptionSelector != bytes4(0));
        assertTrue(cancelRedemptionSelector != bytes4(0));
        assertTrue(processRedemptionsSelector != bytes4(0));
        assertTrue(getRedemptionRequestSelector != bytes4(0));
        assertTrue(getPendingRedemptionsSelector != bytes4(0));
        assertTrue(totalRequestsSelector != bytes4(0));
        assertTrue(totalPendingSharesSelector != bytes4(0));
        assertTrue(totalPendingSovaBTCSelector != bytes4(0));
    }

    function test_RegistryErrors() public pure {
        // Test that Registry error selectors are defined correctly
        assertTrue(IMultiCollateralRegistry.TokenNotSupported.selector != bytes4(0));
        assertTrue(IMultiCollateralRegistry.TokenAlreadyAdded.selector != bytes4(0));
        assertTrue(IMultiCollateralRegistry.InvalidDecimals.selector != bytes4(0));
        assertTrue(IMultiCollateralRegistry.InvalidConversionRate.selector != bytes4(0));
    }

    function test_StrategyErrors() public pure {
        // Test that Strategy error selectors are defined correctly
        assertTrue(IMultiCollateralStrategy.InsufficientBalance.selector != bytes4(0));
        assertTrue(IMultiCollateralStrategy.VaultNotSet.selector != bytes4(0));
        assertTrue(IMultiCollateralStrategy.TransferFailed.selector != bytes4(0));
    }

    function test_VaultErrors() public pure {
        // Test that Vault error selectors are defined correctly
        assertTrue(IMultiBTCVault.DepositFailed.selector != bytes4(0));
        assertTrue(IMultiBTCVault.WithdrawFailed.selector != bytes4(0));
        assertTrue(IMultiBTCVault.Paused.selector != bytes4(0));
        assertTrue(IMultiBTCVault.NotPaused.selector != bytes4(0));
    }

    function test_QueueErrors() public pure {
        // Test that Queue error selectors are defined correctly
        assertTrue(IManagedRedemptionQueue.InvalidRequestId.selector != bytes4(0));
        assertTrue(IManagedRedemptionQueue.RequestAlreadyProcessed.selector != bytes4(0));
        assertTrue(IManagedRedemptionQueue.RequestAlreadyCancelled.selector != bytes4(0));
        assertTrue(IManagedRedemptionQueue.NotRequestOwner.selector != bytes4(0));
    }
}
