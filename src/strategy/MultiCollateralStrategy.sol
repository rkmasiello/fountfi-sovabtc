// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.25;

import {IMultiCollateralStrategy} from "../interfaces/IMultiCollateralStrategy.sol";
import {IMultiCollateralRegistry} from "../interfaces/IMultiCollateralRegistry.sol";
import {IMultiBTCVault} from "../interfaces/IMultiBTCVault.sol";
import {RoleManaged} from "../auth/RoleManaged.sol";
import {SafeTransferLib} from "solady/utils/SafeTransferLib.sol";
import {ReentrancyGuard} from "solady/utils/ReentrancyGuard.sol";
import {IERC20} from "forge-std/interfaces/IERC20.sol";

/**
 * @title MultiCollateralStrategy
 * @notice Strategy for holding and managing multiple BTC collateral types
 * @dev Manages multiple BTC-pegged tokens and provides liquidity for sovaBTC redemptions
 */
contract MultiCollateralStrategy is IMultiCollateralStrategy, RoleManaged, ReentrancyGuard {
    using SafeTransferLib for address;

    /*//////////////////////////////////////////////////////////////
                                STATE
    //////////////////////////////////////////////////////////////*/

    /// @notice The associated vault address
    address public vault;

    /// @notice The multi-collateral registry
    IMultiCollateralRegistry public immutable collateralRegistry;

    /// @notice The sovaBTC token address (for redemptions)
    address public immutable sovaBTC;

    /// @notice Array of collateral tokens currently held
    address[] private _heldCollaterals;

    /// @notice Mapping to track if a collateral is in the held array
    mapping(address => bool) private _isHeld;

    /*//////////////////////////////////////////////////////////////
                            CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Constructor
     * @param _roleManager Address of the role manager contract
     * @param _registry Address of the multi-collateral registry
     * @param _sovaBTC Address of the sovaBTC token
     */
    constructor(address _roleManager, address _registry, address _sovaBTC) RoleManaged(_roleManager) {
        if (_registry == address(0)) revert InvalidAddress();
        if (_sovaBTC == address(0)) revert InvalidAddress();

        collateralRegistry = IMultiCollateralRegistry(_registry);
        sovaBTC = _sovaBTC;
    }

    /*//////////////////////////////////////////////////////////////
                            MODIFIERS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Modifier to restrict access to the vault
     */
    modifier onlyVault() {
        if (msg.sender != vault) revert Unauthorized(msg.sender);
        _;
    }

    /**
     * @notice Modifier to restrict access to vault or its redemption queue
     */
    modifier onlyVaultOrQueue() {
        // Allow both vault and its redemption queue to call
        if (msg.sender != vault) {
            // Check if sender is the vault's redemption queue
            address queue = IMultiBTCVault(vault).redemptionQueue();
            if (msg.sender != queue) revert Unauthorized(msg.sender);
        }
        _;
    }

    /*//////////////////////////////////////////////////////////////
                            VAULT FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @inheritdoc IMultiCollateralStrategy
     */
    function withdrawTo(address asset, address to, uint256 amount)
        external
        override
        onlyVaultOrQueue
        nonReentrant
        returns (bool success)
    {
        if (to == address(0)) revert InvalidAddress();
        if (amount == 0) revert InvalidAmount(amount);

        // For now, only support sovaBTC withdrawals for redemptions
        if (asset != sovaBTC) revert TokenNotSupported(asset);

        uint256 balance = IERC20(sovaBTC).balanceOf(address(this));
        if (balance < amount) revert InsufficientBalance(amount, balance);

        sovaBTC.safeTransfer(to, amount);

        emit WithdrawTo(asset, to, amount);
        return true;
    }

    /*//////////////////////////////////////////////////////////////
                            ADMIN FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @inheritdoc IMultiCollateralStrategy
     */
    function rebalanceCollateral(address fromToken, address toToken, uint256 amount)
        external
        override
        onlyRoles(roleManager.PROTOCOL_ADMIN())
        nonReentrant
    {
        if (!collateralRegistry.isSupportedAsset(fromToken)) revert TokenNotSupported(fromToken);
        if (!collateralRegistry.isSupportedAsset(toToken)) revert TokenNotSupported(toToken);
        if (amount == 0) revert InvalidAmount(amount);

        uint256 fromBalance = IERC20(fromToken).balanceOf(address(this));
        if (fromBalance < amount) revert InsufficientBalance(amount, fromBalance);

        // In production, this would integrate with a DEX or swap protocol
        // For now, this is a placeholder that emits the event
        // The admin would need to manually execute the swap externally

        emit CollateralRebalanced(fromToken, toToken, amount);
    }

    /**
     * @inheritdoc IMultiCollateralStrategy
     */
    function addLiquidity(uint256 amount) external override onlyRoles(roleManager.PROTOCOL_ADMIN()) nonReentrant {
        if (amount == 0) revert InvalidAmount(amount);

        // Transfer sovaBTC from admin to strategy for redemptions
        sovaBTC.safeTransferFrom(msg.sender, address(this), amount);

        emit LiquidityAdded(amount);
    }

    /**
     * @inheritdoc IMultiCollateralStrategy
     */
    function removeCollateral(address token, uint256 amount, address to)
        external
        override
        onlyRoles(roleManager.PROTOCOL_ADMIN())
        nonReentrant
    {
        if (to == address(0)) revert InvalidAddress();
        if (amount == 0) revert InvalidAmount(amount);

        uint256 balance = IERC20(token).balanceOf(address(this));
        if (balance < amount) revert InsufficientBalance(amount, balance);

        token.safeTransfer(to, amount);

        // Update held collaterals if balance is now zero
        if (IERC20(token).balanceOf(address(this)) == 0 && _isHeld[token]) {
            _removeFromHeldCollaterals(token);
        }

        emit CollateralRemoved(token, amount, to);
    }

    /**
     * @inheritdoc IMultiCollateralStrategy
     */
    function setVault(address _vault) external override onlyRoles(roleManager.PROTOCOL_ADMIN()) {
        if (_vault == address(0)) revert InvalidAddress();

        address oldVault = vault;
        vault = _vault;

        emit VaultSet(oldVault, _vault);
    }

    /**
     * @inheritdoc IMultiCollateralStrategy
     */
    function emergencyWithdraw(address token, uint256 amount, address to)
        external
        override
        onlyRoles(roleManager.PROTOCOL_ADMIN())
        nonReentrant
    {
        if (to == address(0)) revert InvalidAddress();
        if (amount == 0) revert InvalidAmount(amount);

        uint256 balance = IERC20(token).balanceOf(address(this));
        if (balance < amount) revert InsufficientBalance(amount, balance);

        token.safeTransfer(to, amount);

        // Update held collaterals if balance is now zero
        if (IERC20(token).balanceOf(address(this)) == 0 && _isHeld[token]) {
            _removeFromHeldCollaterals(token);
        }

        emit EmergencyWithdrawal(token, amount, to);
    }

    /*//////////////////////////////////////////////////////////////
                            VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @inheritdoc IMultiCollateralStrategy
     */
    function collateralBalance(address token) external view override returns (uint256) {
        return IERC20(token).balanceOf(address(this));
    }

    /**
     * @inheritdoc IMultiCollateralStrategy
     */
    function totalAssets() external view override returns (uint256) {
        uint256 total = 0;

        // Add sovaBTC balance
        total += IERC20(sovaBTC).balanceOf(address(this));

        // Add value of all supported collaterals (excluding sovaBTC to avoid double-counting)
        address[] memory supportedCollaterals = collateralRegistry.getSupportedCollaterals();
        for (uint256 i = 0; i < supportedCollaterals.length; i++) {
            address token = supportedCollaterals[i];
            // Skip sovaBTC to avoid double-counting (already added above)
            if (token == sovaBTC) {
                continue;
            }
            uint256 balance = IERC20(token).balanceOf(address(this));
            if (balance > 0) {
                // Convert to sovaBTC value using registry conversion rate
                total += collateralRegistry.getValueInUnderlying(token, balance);
            }
        }

        return total;
    }

    /**
     * @inheritdoc IMultiCollateralStrategy
     */
    function getHeldCollaterals() external view override returns (address[] memory) {
        return _heldCollaterals;
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Update the held collaterals array when receiving tokens
     * @param token The token to potentially add to held collaterals
     */
    function _updateHeldCollaterals(address token) internal {
        if (!_isHeld[token] && IERC20(token).balanceOf(address(this)) > 0) {
            _heldCollaterals.push(token);
            _isHeld[token] = true;
        }
    }

    /**
     * @notice Remove a token from the held collaterals array
     * @param token The token to remove
     */
    function _removeFromHeldCollaterals(address token) private {
        uint256 length = _heldCollaterals.length;
        for (uint256 i = 0; i < length; i++) {
            if (_heldCollaterals[i] == token) {
                // Move the last element to this position and pop
                _heldCollaterals[i] = _heldCollaterals[length - 1];
                _heldCollaterals.pop();
                _isHeld[token] = false;
                break;
            }
        }
    }
}
