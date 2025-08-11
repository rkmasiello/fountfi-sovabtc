// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.25;

import {Test} from "forge-std/Test.sol";
import {console2} from "forge-std/console2.sol";
import {MultiCollateralStrategy} from "../../src/strategy/MultiCollateralStrategy.sol";
import {MultiCollateralRegistry} from "../../src/registry/MultiCollateralRegistry.sol";
import {IMultiCollateralStrategy} from "../../src/interfaces/IMultiCollateralStrategy.sol";
import {IMultiCollateralRegistry} from "../../src/interfaces/IMultiCollateralRegistry.sol";
import {RoleManager} from "../../src/auth/RoleManager.sol";

contract ERC20Mock is Test {
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;

    constructor(string memory _name, string memory _symbol, uint8 _decimals) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
    }

    function mint(address to, uint256 amount) external {
        balanceOf[to] += amount;
        totalSupply += amount;
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        allowance[msg.sender][spender] = amount;
        return true;
    }

    function transfer(address to, uint256 amount) external returns (bool) {
        require(balanceOf[msg.sender] >= amount, "Insufficient balance");
        balanceOf[msg.sender] -= amount;
        balanceOf[to] += amount;
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) external returns (bool) {
        require(balanceOf[from] >= amount, "Insufficient balance");
        require(allowance[from][msg.sender] >= amount, "Insufficient allowance");

        balanceOf[from] -= amount;
        balanceOf[to] += amount;
        allowance[from][msg.sender] -= amount;

        return true;
    }
}

contract MockVault {
    address public redemptionQueue;

    function setRedemptionQueue(address _queue) external {
        redemptionQueue = _queue;
    }
}

contract MultiCollateralStrategyTest is Test {
    MultiCollateralStrategy strategy;
    MultiCollateralRegistry registry;
    RoleManager roleManager;
    MockVault mockVault;

    ERC20Mock wbtc;
    ERC20Mock tbtc;
    ERC20Mock sovaBTC;

    address admin = address(0x1);
    address vault;
    address user = address(0x3);
    address recipient = address(0x4);

    uint256 constant ONE_TO_ONE = 1e18;
    uint8 constant BTC_DECIMALS = 8;

    event WithdrawTo(address indexed asset, address indexed to, uint256 amount);
    event CollateralRebalanced(address indexed fromToken, address indexed toToken, uint256 amount);
    event LiquidityAdded(uint256 amount);
    event CollateralRemoved(address indexed token, uint256 amount, address indexed to);
    event VaultSet(address indexed oldVault, address indexed newVault);
    event EmergencyWithdrawal(address indexed token, uint256 amount, address indexed to);

    function setUp() public {
        // Deploy RoleManager and grant admin role
        roleManager = new RoleManager();
        roleManager.grantRole(admin, roleManager.PROTOCOL_ADMIN());

        // Deploy registry
        registry = new MultiCollateralRegistry(address(roleManager));

        // Deploy mock tokens
        wbtc = new ERC20Mock("Wrapped Bitcoin", "WBTC", BTC_DECIMALS);
        tbtc = new ERC20Mock("tBTC", "TBTC", BTC_DECIMALS);
        sovaBTC = new ERC20Mock("sovaBTC", "sovaBTC", BTC_DECIMALS);

        // Deploy mock vault
        mockVault = new MockVault();
        vault = address(mockVault);

        // Deploy strategy
        strategy = new MultiCollateralStrategy(address(roleManager), address(registry), address(sovaBTC));

        // Set vault
        vm.prank(admin);
        strategy.setVault(vault);

        // Add collaterals to registry
        vm.startPrank(admin);
        registry.addCollateral(address(wbtc), ONE_TO_ONE, BTC_DECIMALS);
        registry.addCollateral(address(tbtc), 0.99e18, BTC_DECIMALS); // 1% discount
        registry.addCollateral(address(sovaBTC), ONE_TO_ONE, BTC_DECIMALS);
        vm.stopPrank();
    }

    /*//////////////////////////////////////////////////////////////
                        WITHDRAWTO TESTS
    //////////////////////////////////////////////////////////////*/

    function test_WithdrawTo_Success() public {
        // Fund strategy with sovaBTC
        uint256 amount = 1e8; // 1 BTC
        sovaBTC.mint(address(strategy), amount);

        vm.prank(vault);
        vm.expectEmit(true, true, false, true);
        emit WithdrawTo(address(sovaBTC), recipient, amount);

        bool success = strategy.withdrawTo(address(sovaBTC), recipient, amount);

        assertTrue(success);
        assertEq(sovaBTC.balanceOf(recipient), amount);
        assertEq(sovaBTC.balanceOf(address(strategy)), 0);
    }

    function test_WithdrawTo_RevertNotVault() public {
        vm.prank(user);
        vm.expectRevert(abi.encodeWithSelector(IMultiCollateralStrategy.Unauthorized.selector, user));
        strategy.withdrawTo(address(sovaBTC), recipient, 1e8);
    }

    function test_WithdrawTo_RevertInvalidAddress() public {
        vm.prank(vault);
        vm.expectRevert(IMultiCollateralStrategy.InvalidAddress.selector);
        strategy.withdrawTo(address(sovaBTC), address(0), 1e8);
    }

    function test_WithdrawTo_RevertInvalidAmount() public {
        vm.prank(vault);
        vm.expectRevert(abi.encodeWithSelector(IMultiCollateralStrategy.InvalidAmount.selector, 0));
        strategy.withdrawTo(address(sovaBTC), recipient, 0);
    }

    function test_WithdrawTo_RevertTokenNotSupported() public {
        vm.prank(vault);
        vm.expectRevert(abi.encodeWithSelector(IMultiCollateralStrategy.TokenNotSupported.selector, address(wbtc)));
        strategy.withdrawTo(address(wbtc), recipient, 1e8);
    }

    function test_WithdrawTo_RevertInsufficientBalance() public {
        uint256 amount = 1e8;
        sovaBTC.mint(address(strategy), amount / 2);

        vm.prank(vault);
        vm.expectRevert(
            abi.encodeWithSelector(IMultiCollateralStrategy.InsufficientBalance.selector, amount, amount / 2)
        );
        strategy.withdrawTo(address(sovaBTC), recipient, amount);
    }

    /*//////////////////////////////////////////////////////////////
                        ADD LIQUIDITY TESTS
    //////////////////////////////////////////////////////////////*/

    function test_AddLiquidity_Success() public {
        uint256 amount = 10e8; // 10 BTC
        sovaBTC.mint(admin, amount);

        vm.startPrank(admin);
        sovaBTC.approve(address(strategy), amount);

        vm.expectEmit(false, false, false, true);
        emit LiquidityAdded(amount);

        strategy.addLiquidity(amount);
        vm.stopPrank();

        assertEq(sovaBTC.balanceOf(address(strategy)), amount);
        assertEq(sovaBTC.balanceOf(admin), 0);
    }

    function test_AddLiquidity_RevertUnauthorized() public {
        vm.prank(user);
        vm.expectRevert();
        strategy.addLiquidity(1e8);
    }

    function test_AddLiquidity_RevertInvalidAmount() public {
        vm.prank(admin);
        vm.expectRevert(abi.encodeWithSelector(IMultiCollateralStrategy.InvalidAmount.selector, 0));
        strategy.addLiquidity(0);
    }

    /*//////////////////////////////////////////////////////////////
                    REMOVE COLLATERAL TESTS
    //////////////////////////////////////////////////////////////*/

    function test_RemoveCollateral_Success() public {
        uint256 amount = 5e8;
        wbtc.mint(address(strategy), amount);

        vm.prank(admin);
        vm.expectEmit(true, false, true, true);
        emit CollateralRemoved(address(wbtc), amount, recipient);

        strategy.removeCollateral(address(wbtc), amount, recipient);

        assertEq(wbtc.balanceOf(recipient), amount);
        assertEq(wbtc.balanceOf(address(strategy)), 0);
    }

    function test_RemoveCollateral_RevertUnauthorized() public {
        vm.prank(user);
        vm.expectRevert();
        strategy.removeCollateral(address(wbtc), 1e8, recipient);
    }

    function test_RemoveCollateral_RevertInvalidAddress() public {
        vm.prank(admin);
        vm.expectRevert(IMultiCollateralStrategy.InvalidAddress.selector);
        strategy.removeCollateral(address(wbtc), 1e8, address(0));
    }

    function test_RemoveCollateral_RevertInsufficientBalance() public {
        uint256 amount = 1e8;
        wbtc.mint(address(strategy), amount / 2);

        vm.prank(admin);
        vm.expectRevert(
            abi.encodeWithSelector(IMultiCollateralStrategy.InsufficientBalance.selector, amount, amount / 2)
        );
        strategy.removeCollateral(address(wbtc), amount, recipient);
    }

    /*//////////////////////////////////////////////////////////////
                        SET VAULT TESTS
    //////////////////////////////////////////////////////////////*/

    function test_SetVault_Success() public {
        address newVault = address(0x5);

        vm.prank(admin);
        vm.expectEmit(true, true, false, false);
        emit VaultSet(vault, newVault);

        strategy.setVault(newVault);

        assertEq(strategy.vault(), newVault);
    }

    function test_SetVault_RevertUnauthorized() public {
        vm.prank(user);
        vm.expectRevert();
        strategy.setVault(address(0x5));
    }

    function test_SetVault_RevertInvalidAddress() public {
        vm.prank(admin);
        vm.expectRevert(IMultiCollateralStrategy.InvalidAddress.selector);
        strategy.setVault(address(0));
    }

    /*//////////////////////////////////////////////////////////////
                    EMERGENCY WITHDRAW TESTS
    //////////////////////////////////////////////////////////////*/

    function test_EmergencyWithdraw_Success() public {
        uint256 amount = 3e8;
        wbtc.mint(address(strategy), amount);

        vm.prank(admin);
        vm.expectEmit(true, false, true, true);
        emit EmergencyWithdrawal(address(wbtc), amount, recipient);

        strategy.emergencyWithdraw(address(wbtc), amount, recipient);

        assertEq(wbtc.balanceOf(recipient), amount);
        assertEq(wbtc.balanceOf(address(strategy)), 0);
    }

    /*//////////////////////////////////////////////////////////////
                        VIEW FUNCTIONS TESTS
    //////////////////////////////////////////////////////////////*/

    function test_CollateralBalance() public {
        uint256 amount = 2e8;
        wbtc.mint(address(strategy), amount);

        assertEq(strategy.collateralBalance(address(wbtc)), amount);
        assertEq(strategy.collateralBalance(address(tbtc)), 0);
    }

    function test_TotalAssets() public {
        // Mint various collaterals
        uint256 wbtcAmount = 2e8; // 2 BTC
        uint256 tbtcAmount = 3e8; // 3 BTC (worth 2.97 sovaBTC due to 0.99 rate)
        uint256 sovaBTCAmount = 1e8; // 1 sovaBTC

        wbtc.mint(address(strategy), wbtcAmount);
        tbtc.mint(address(strategy), tbtcAmount);
        sovaBTC.mint(address(strategy), sovaBTCAmount);

        uint256 totalAssets = strategy.totalAssets();

        // Expected: sovaBTC is counted only once (fix for double-counting bug)
        // Direct sovaBTC: 1 BTC
        // Other collaterals: 2 BTC (wbtc) + 2.97 BTC (tbtc) = 4.97 BTC
        // Total: 1 BTC + 4.97 BTC = 5.97 BTC
        uint256 expected = sovaBTCAmount + wbtcAmount + (tbtcAmount * 99 / 100);
        assertEq(totalAssets, expected);
    }

    function test_GetHeldCollaterals() public {
        // Initially empty
        address[] memory held = strategy.getHeldCollaterals();
        assertEq(held.length, 0);

        // The held collaterals array would be updated when actual transfers happen
        // For now just verify the getter works
    }

    /*//////////////////////////////////////////////////////////////
                        REBALANCE TESTS
    //////////////////////////////////////////////////////////////*/

    function test_RebalanceCollateral_EmitsEvent() public {
        uint256 amount = 1e8;
        wbtc.mint(address(strategy), amount);

        vm.prank(admin);
        vm.expectEmit(true, true, false, true);
        emit CollateralRebalanced(address(wbtc), address(tbtc), amount);

        strategy.rebalanceCollateral(address(wbtc), address(tbtc), amount);
    }

    function test_RebalanceCollateral_RevertTokenNotSupported() public {
        address unsupported = address(0x999);

        vm.prank(admin);
        vm.expectRevert(abi.encodeWithSelector(IMultiCollateralStrategy.TokenNotSupported.selector, unsupported));
        strategy.rebalanceCollateral(unsupported, address(tbtc), 1e8);
    }

    function test_RebalanceCollateral_RevertInsufficientBalance() public {
        uint256 amount = 1e8;
        wbtc.mint(address(strategy), amount / 2);

        vm.prank(admin);
        vm.expectRevert(
            abi.encodeWithSelector(IMultiCollateralStrategy.InsufficientBalance.selector, amount, amount / 2)
        );
        strategy.rebalanceCollateral(address(wbtc), address(tbtc), amount);
    }
}
