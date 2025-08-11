// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.25;

/**
 * @title IMultiCollateralRegistry
 * @notice Interface for managing supported BTC collateral tokens and their conversion rates to sovaBTC
 * @dev Manages multiple BTC-pegged tokens with conversion rates and decimal configurations
 */
interface IMultiCollateralRegistry {
    /*//////////////////////////////////////////////////////////////
                                ERRORS
    //////////////////////////////////////////////////////////////*/

    error TokenNotSupported(address token);
    error TokenAlreadyAdded(address token);
    error InvalidDecimals(uint8 decimals);
    error InvalidConversionRate(uint256 rate);
    error ZeroAddress();
    error Unauthorized(address caller);

    /*//////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Emitted when a new collateral token is added
     * @param token The address of the collateral token
     * @param conversionRate The conversion rate to sovaBTC (1e18 = 1:1)
     * @param decimals The number of decimals for the token
     */
    event CollateralAdded(address indexed token, uint256 conversionRate, uint8 decimals);

    /**
     * @notice Emitted when a collateral token is removed
     * @param token The address of the removed collateral token
     */
    event CollateralRemoved(address indexed token);

    /**
     * @notice Emitted when a conversion rate is updated
     * @param token The address of the collateral token
     * @param oldRate The previous conversion rate
     * @param newRate The new conversion rate
     */
    event ConversionRateUpdated(address indexed token, uint256 oldRate, uint256 newRate);

    /*//////////////////////////////////////////////////////////////
                            ADMIN FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Add a new supported collateral token
     * @dev Only callable by PROTOCOL_ADMIN
     * @param token The address of the BTC collateral token
     * @param conversionRate The conversion rate to sovaBTC (1e18 scaled, where 1e18 = 1:1 with sovaBTC)
     * @param decimals The number of decimals for the token (should be 8 for BTC tokens)
     */
    function addCollateral(address token, uint256 conversionRate, uint8 decimals) external;

    /**
     * @notice Remove a collateral token from the supported list
     * @dev Only callable by PROTOCOL_ADMIN
     * @param token The address of the collateral token to remove
     */
    function removeCollateral(address token) external;

    /**
     * @notice Update the conversion rate for an existing collateral
     * @dev Only callable by PROTOCOL_ADMIN
     * @param token The address of the collateral token
     * @param newRate The new conversion rate (1e18 scaled)
     */
    function updateConversionRate(address token, uint256 newRate) external;

    /*//////////////////////////////////////////////////////////////
                            VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Check if a token is supported as collateral
     * @param token The address of the token to check
     * @return True if the token is a supported collateral, false otherwise
     */
    function isSupportedAsset(address token) external view returns (bool);

    /**
     * @notice Get detailed information about a collateral token
     * @param token The address of the collateral token
     * @return conversionRate The conversion rate to sovaBTC (1e18 scaled)
     * @return decimals The number of decimals for the token
     * @return isActive Whether the token is currently accepted as collateral
     */
    function getCollateralInfo(address token)
        external
        view
        returns (uint256 conversionRate, uint8 decimals, bool isActive);

    /**
     * @notice Convert a token amount to sovaBTC base units
     * @dev Handles decimal conversion and applies the conversion rate
     * @param token The address of the collateral token
     * @param amount The amount in the token's native decimals (typically 8 for BTC tokens)
     * @return The equivalent value in sovaBTC base units (8 decimals)
     */
    function getValueInUnderlying(address token, uint256 amount) external view returns (uint256);

    /**
     * @notice Get all supported collateral token addresses
     * @return An array of addresses for all supported collateral tokens
     */
    function getSupportedCollaterals() external view returns (address[] memory);
}
