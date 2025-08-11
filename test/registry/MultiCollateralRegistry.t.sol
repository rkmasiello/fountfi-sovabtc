// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.25;

import {Test} from "forge-std/Test.sol";
import {console2} from "forge-std/console2.sol";
import {MultiCollateralRegistry} from "../../src/registry/MultiCollateralRegistry.sol";
import {IMultiCollateralRegistry} from "../../src/interfaces/IMultiCollateralRegistry.sol";
import {RoleManager} from "../../src/auth/RoleManager.sol";

contract MultiCollateralRegistryTest is Test {
    MultiCollateralRegistry registry;
    RoleManager roleManager;
    
    address admin = address(0x1);
    address user = address(0x2);
    address wbtc = address(0x3);
    address tbtc = address(0x4);
    address sovabtc = address(0x5);
    
    uint256 constant ONE_TO_ONE = 1e18;
    uint8 constant BTC_DECIMALS = 8;
    
    event CollateralAdded(address indexed token, uint256 conversionRate, uint8 decimals);
    event CollateralRemoved(address indexed token);
    event ConversionRateUpdated(address indexed token, uint256 oldRate, uint256 newRate);

    function setUp() public {
        // Deploy RoleManager and grant admin role
        roleManager = new RoleManager();
        roleManager.grantRole(admin, roleManager.PROTOCOL_ADMIN());
        
        // Deploy registry
        registry = new MultiCollateralRegistry(address(roleManager));
    }

    /*//////////////////////////////////////////////////////////////
                        ADD COLLATERAL TESTS
    //////////////////////////////////////////////////////////////*/

    function test_AddCollateral_Success() public {
        vm.prank(admin);
        
        vm.expectEmit(true, false, false, true);
        emit CollateralAdded(wbtc, ONE_TO_ONE, BTC_DECIMALS);
        
        registry.addCollateral(wbtc, ONE_TO_ONE, BTC_DECIMALS);
        
        // Verify collateral was added
        assertTrue(registry.isSupportedAsset(wbtc));
        
        (uint256 rate, uint8 decimals, bool isActive) = registry.getCollateralInfo(wbtc);
        assertEq(rate, ONE_TO_ONE);
        assertEq(decimals, BTC_DECIMALS);
        assertTrue(isActive);
        
        // Check supported collaterals list
        address[] memory collaterals = registry.getSupportedCollaterals();
        assertEq(collaterals.length, 1);
        assertEq(collaterals[0], wbtc);
    }

    function test_AddCollateral_RevertZeroAddress() public {
        vm.prank(admin);
        vm.expectRevert(IMultiCollateralRegistry.ZeroAddress.selector);
        registry.addCollateral(address(0), ONE_TO_ONE, BTC_DECIMALS);
    }

    function test_AddCollateral_RevertInvalidConversionRate() public {
        vm.prank(admin);
        vm.expectRevert(abi.encodeWithSelector(IMultiCollateralRegistry.InvalidConversionRate.selector, 0));
        registry.addCollateral(wbtc, 0, BTC_DECIMALS);
    }

    function test_AddCollateral_RevertInvalidDecimals() public {
        vm.prank(admin);
        vm.expectRevert(abi.encodeWithSelector(IMultiCollateralRegistry.InvalidDecimals.selector, 0));
        registry.addCollateral(wbtc, ONE_TO_ONE, 0);
        
        vm.expectRevert(abi.encodeWithSelector(IMultiCollateralRegistry.InvalidDecimals.selector, 19));
        registry.addCollateral(wbtc, ONE_TO_ONE, 19);
    }

    function test_AddCollateral_RevertTokenAlreadyAdded() public {
        vm.startPrank(admin);
        registry.addCollateral(wbtc, ONE_TO_ONE, BTC_DECIMALS);
        
        vm.expectRevert(abi.encodeWithSelector(IMultiCollateralRegistry.TokenAlreadyAdded.selector, wbtc));
        registry.addCollateral(wbtc, ONE_TO_ONE, BTC_DECIMALS);
    }

    function test_AddCollateral_RevertUnauthorized() public {
        vm.prank(user);
        vm.expectRevert();
        registry.addCollateral(wbtc, ONE_TO_ONE, BTC_DECIMALS);
    }

    /*//////////////////////////////////////////////////////////////
                        REMOVE COLLATERAL TESTS
    //////////////////////////////////////////////////////////////*/

    function test_RemoveCollateral_Success() public {
        vm.startPrank(admin);
        registry.addCollateral(wbtc, ONE_TO_ONE, BTC_DECIMALS);
        
        vm.expectEmit(true, false, false, false);
        emit CollateralRemoved(wbtc);
        
        registry.removeCollateral(wbtc);
        
        // Verify collateral was removed
        assertFalse(registry.isSupportedAsset(wbtc));
        
        (,, bool isActive) = registry.getCollateralInfo(wbtc);
        assertFalse(isActive);
        
        // Check supported collaterals list
        address[] memory collaterals = registry.getSupportedCollaterals();
        assertEq(collaterals.length, 0);
    }

    function test_RemoveCollateral_RevertTokenNotSupported() public {
        vm.prank(admin);
        vm.expectRevert(abi.encodeWithSelector(IMultiCollateralRegistry.TokenNotSupported.selector, wbtc));
        registry.removeCollateral(wbtc);
    }

    function test_RemoveCollateral_RevertUnauthorized() public {
        vm.prank(admin);
        registry.addCollateral(wbtc, ONE_TO_ONE, BTC_DECIMALS);
        
        vm.prank(user);
        vm.expectRevert();
        registry.removeCollateral(wbtc);
    }

    /*//////////////////////////////////////////////////////////////
                    UPDATE CONVERSION RATE TESTS
    //////////////////////////////////////////////////////////////*/

    function test_UpdateConversionRate_Success() public {
        vm.startPrank(admin);
        registry.addCollateral(wbtc, ONE_TO_ONE, BTC_DECIMALS);
        
        uint256 newRate = 1.05e18; // 5% premium
        
        vm.expectEmit(true, false, false, true);
        emit ConversionRateUpdated(wbtc, ONE_TO_ONE, newRate);
        
        registry.updateConversionRate(wbtc, newRate);
        
        (uint256 rate,,) = registry.getCollateralInfo(wbtc);
        assertEq(rate, newRate);
    }

    function test_UpdateConversionRate_RevertTokenNotSupported() public {
        vm.prank(admin);
        vm.expectRevert(abi.encodeWithSelector(IMultiCollateralRegistry.TokenNotSupported.selector, wbtc));
        registry.updateConversionRate(wbtc, ONE_TO_ONE);
    }

    function test_UpdateConversionRate_RevertInvalidRate() public {
        vm.startPrank(admin);
        registry.addCollateral(wbtc, ONE_TO_ONE, BTC_DECIMALS);
        
        vm.expectRevert(abi.encodeWithSelector(IMultiCollateralRegistry.InvalidConversionRate.selector, 0));
        registry.updateConversionRate(wbtc, 0);
    }

    function test_UpdateConversionRate_RevertUnauthorized() public {
        vm.prank(admin);
        registry.addCollateral(wbtc, ONE_TO_ONE, BTC_DECIMALS);
        
        vm.prank(user);
        vm.expectRevert();
        registry.updateConversionRate(wbtc, 1.05e18);
    }

    /*//////////////////////////////////////////////////////////////
                        VIEW FUNCTIONS TESTS
    //////////////////////////////////////////////////////////////*/

    function test_GetValueInUnderlying_Success() public {
        vm.prank(admin);
        registry.addCollateral(wbtc, ONE_TO_ONE, BTC_DECIMALS);
        
        uint256 amount = 1e8; // 1 BTC
        uint256 value = registry.getValueInUnderlying(wbtc, amount);
        assertEq(value, amount); // 1:1 conversion
        
        // Test with different conversion rate
        vm.prank(admin);
        registry.updateConversionRate(wbtc, 0.95e18); // 5% discount
        
        value = registry.getValueInUnderlying(wbtc, amount);
        assertEq(value, 0.95e8); // 0.95 BTC worth
    }

    function test_GetValueInUnderlying_RevertTokenNotSupported() public {
        uint256 amount = 1e8;
        vm.expectRevert(abi.encodeWithSelector(IMultiCollateralRegistry.TokenNotSupported.selector, wbtc));
        registry.getValueInUnderlying(wbtc, amount);
    }

    function test_GetSupportedCollaterals_MultipleTokens() public {
        vm.startPrank(admin);
        registry.addCollateral(wbtc, ONE_TO_ONE, BTC_DECIMALS);
        registry.addCollateral(tbtc, 0.99e18, BTC_DECIMALS); // 1% discount
        registry.addCollateral(sovabtc, ONE_TO_ONE, BTC_DECIMALS);
        
        address[] memory collaterals = registry.getSupportedCollaterals();
        assertEq(collaterals.length, 3);
        
        // Remove one and check again
        registry.removeCollateral(tbtc);
        collaterals = registry.getSupportedCollaterals();
        assertEq(collaterals.length, 2);
    }

    /*//////////////////////////////////////////////////////////////
                            FUZZ TESTS
    //////////////////////////////////////////////////////////////*/

    function testFuzz_AddCollateral_ValidInputs(
        address token,
        uint256 rate,
        uint8 decimals
    ) public {
        // Bound inputs to valid ranges
        vm.assume(token != address(0));
        rate = bound(rate, 1, 1000e18); // Between 0.000001 and 1000x
        decimals = uint8(bound(decimals, 1, 18));
        
        vm.prank(admin);
        registry.addCollateral(token, rate, decimals);
        
        assertTrue(registry.isSupportedAsset(token));
        (uint256 storedRate, uint8 storedDecimals, bool isActive) = registry.getCollateralInfo(token);
        assertEq(storedRate, rate);
        assertEq(storedDecimals, decimals);
        assertTrue(isActive);
    }

    function testFuzz_GetValueInUnderlying_Calculation(
        uint256 amount,
        uint256 rate
    ) public {
        // Bound inputs to reasonable ranges
        amount = bound(amount, 1, 21_000_000e8); // Max 21M BTC
        rate = bound(rate, 0.01e18, 100e18); // Between 0.01x and 100x
        
        vm.startPrank(admin);
        registry.addCollateral(wbtc, rate, BTC_DECIMALS);
        
        uint256 value = registry.getValueInUnderlying(wbtc, amount);
        assertEq(value, (amount * rate) / 1e18);
    }
}