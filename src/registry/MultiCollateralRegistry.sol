// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.25;

import {IMultiCollateralRegistry} from "../interfaces/IMultiCollateralRegistry.sol";
import {RoleManaged} from "../auth/RoleManaged.sol";

/**
 * @title MultiCollateralRegistry
 * @notice Registry for managing supported BTC collateral tokens and their conversion rates to sovaBTC
 * @dev Manages multiple BTC-pegged tokens with conversion rates and decimal configurations
 */
contract MultiCollateralRegistry is IMultiCollateralRegistry, RoleManaged {
    /*//////////////////////////////////////////////////////////////
                                STRUCTS
    //////////////////////////////////////////////////////////////*/

    struct CollateralInfo {
        uint256 conversionRate; // 1e18 scaled rate (1e18 = 1:1 with sovaBTC)
        uint8 decimals; // Token decimals (typically 8 for BTC tokens)
        bool isActive; // Whether token is currently accepted
    }

    /*//////////////////////////////////////////////////////////////
                                STATE
    //////////////////////////////////////////////////////////////*/

    /// @notice Mapping from token address to collateral information
    mapping(address => CollateralInfo) private _collateralInfo;

    /// @notice Array of all supported collateral addresses
    address[] private _supportedCollaterals;

    /// @notice Mapping to track if an address is in the array
    mapping(address => bool) private _isInArray;

    /*//////////////////////////////////////////////////////////////
                            CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Constructor
     * @param _roleManager Address of the role manager contract
     */
    constructor(address _roleManager) RoleManaged(_roleManager) {}

    /*//////////////////////////////////////////////////////////////
                            ADMIN FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @inheritdoc IMultiCollateralRegistry
     */
    function addCollateral(address token, uint256 conversionRate, uint8 decimals)
        external
        override
        onlyRoles(roleManager.PROTOCOL_ADMIN())
    {
        if (token == address(0)) revert ZeroAddress();
        if (conversionRate == 0) revert InvalidConversionRate(conversionRate);
        if (decimals == 0 || decimals > 18) revert InvalidDecimals(decimals);
        if (_collateralInfo[token].isActive) revert TokenAlreadyAdded(token);

        _collateralInfo[token] = CollateralInfo({conversionRate: conversionRate, decimals: decimals, isActive: true});

        // Add to array if not already present
        if (!_isInArray[token]) {
            _supportedCollaterals.push(token);
            _isInArray[token] = true;
        }

        emit CollateralAdded(token, conversionRate, decimals);
    }

    /**
     * @inheritdoc IMultiCollateralRegistry
     */
    function removeCollateral(address token) external override onlyRoles(roleManager.PROTOCOL_ADMIN()) {
        if (!_collateralInfo[token].isActive) revert TokenNotSupported(token);

        _collateralInfo[token].isActive = false;

        // Remove from array
        if (_isInArray[token]) {
            _removeFromArray(token);
            _isInArray[token] = false;
        }

        emit CollateralRemoved(token);
    }

    /**
     * @inheritdoc IMultiCollateralRegistry
     */
    function updateConversionRate(address token, uint256 newRate)
        external
        override
        onlyRoles(roleManager.PROTOCOL_ADMIN())
    {
        if (!_collateralInfo[token].isActive) revert TokenNotSupported(token);
        if (newRate == 0) revert InvalidConversionRate(newRate);

        uint256 oldRate = _collateralInfo[token].conversionRate;
        _collateralInfo[token].conversionRate = newRate;

        emit ConversionRateUpdated(token, oldRate, newRate);
    }

    /*//////////////////////////////////////////////////////////////
                            VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @inheritdoc IMultiCollateralRegistry
     */
    function isSupportedAsset(address token) external view override returns (bool) {
        return _collateralInfo[token].isActive;
    }

    /**
     * @inheritdoc IMultiCollateralRegistry
     */
    function getCollateralInfo(address token)
        external
        view
        override
        returns (uint256 conversionRate, uint8 decimals, bool isActive)
    {
        CollateralInfo memory info = _collateralInfo[token];
        return (info.conversionRate, info.decimals, info.isActive);
    }

    /**
     * @inheritdoc IMultiCollateralRegistry
     */
    function getValueInUnderlying(address token, uint256 amount) external view override returns (uint256) {
        CollateralInfo memory info = _collateralInfo[token];
        if (!info.isActive) revert TokenNotSupported(token);

        // Apply conversion rate: amount * conversionRate / 1e18
        // Both input and output are in the same decimals (typically 8 for BTC tokens)
        // so no decimal conversion needed, just apply the rate
        return (amount * info.conversionRate) / 1e18;
    }

    /**
     * @inheritdoc IMultiCollateralRegistry
     */
    function getSupportedCollaterals() external view override returns (address[] memory) {
        // Return only active collaterals
        uint256 activeCount = 0;
        for (uint256 i = 0; i < _supportedCollaterals.length; i++) {
            if (_collateralInfo[_supportedCollaterals[i]].isActive) {
                activeCount++;
            }
        }

        address[] memory activeCollaterals = new address[](activeCount);
        uint256 index = 0;
        for (uint256 i = 0; i < _supportedCollaterals.length; i++) {
            if (_collateralInfo[_supportedCollaterals[i]].isActive) {
                activeCollaterals[index] = _supportedCollaterals[i];
                index++;
            }
        }

        return activeCollaterals;
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Remove an address from the supported collaterals array
     * @param token The token to remove
     */
    function _removeFromArray(address token) private {
        uint256 length = _supportedCollaterals.length;
        for (uint256 i = 0; i < length; i++) {
            if (_supportedCollaterals[i] == token) {
                // Move the last element to this position and pop
                _supportedCollaterals[i] = _supportedCollaterals[length - 1];
                _supportedCollaterals.pop();
                break;
            }
        }
    }
}
