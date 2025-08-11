// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.25;

/**
 * @title IMultiCollateralStrategy
 * @notice Strategy interface for holding and managing multiple BTC collateral types
 * @dev Manages multiple BTC-pegged tokens and provides liquidity for sovaBTC redemptions
 */
interface IMultiCollateralStrategy {
    /*//////////////////////////////////////////////////////////////
                                ERRORS
    //////////////////////////////////////////////////////////////*/

    error InvalidAddress();
    error InsufficientBalance(uint256 requested, uint256 available);
    error TokenNotSupported(address token);
    error Unauthorized(address caller);
    error VaultNotSet();
    error InvalidAmount(uint256 amount);
    error TransferFailed();

    /*//////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Emitted when collateral is withdrawn to a recipient
     * @param asset The address of the asset withdrawn
     * @param to The recipient address
     * @param amount The amount withdrawn
     */
    event WithdrawTo(address indexed asset, address indexed to, uint256 amount);

    /**
     * @notice Emitted when collateral is rebalanced between tokens
     * @param fromToken The token being converted from
     * @param toToken The token being converted to
     * @param amount The amount being rebalanced
     */
    event CollateralRebalanced(address indexed fromToken, address indexed toToken, uint256 amount);

    /**
     * @notice Emitted when sovaBTC liquidity is added
     * @param amount The amount of sovaBTC added
     */
    event LiquidityAdded(uint256 amount);

    /**
     * @notice Emitted when excess collateral is removed
     * @param token The collateral token address
     * @param amount The amount removed
     * @param to The recipient address
     */
    event CollateralRemoved(address indexed token, uint256 amount, address indexed to);

    /**
     * @notice Emitted when the vault address is set
     * @param oldVault The previous vault address
     * @param newVault The new vault address
     */
    event VaultSet(address indexed oldVault, address indexed newVault);

    /**
     * @notice Emitted during emergency withdrawal
     * @param token The token address
     * @param amount The amount withdrawn
     * @param to The recipient address
     */
    event EmergencyWithdrawal(address indexed token, uint256 amount, address indexed to);

    /*//////////////////////////////////////////////////////////////
                            VAULT FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Withdraw specific amount of sovaBTC to a recipient
     * @dev Only callable by the associated vault
     * @param asset The asset to withdraw (should be sovaBTC for redemptions)
     * @param to The recipient address
     * @param amount The amount to withdraw in asset's native decimals (8 for sovaBTC)
     * @return success True if withdrawal was successful
     */
    function withdrawTo(address asset, address to, uint256 amount) external returns (bool success);

    /*//////////////////////////////////////////////////////////////
                            ADMIN FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Rebalance collateral by swapping between BTC token types
     * @dev Only callable by PROTOCOL_ADMIN
     * @param fromToken The token to swap from
     * @param toToken The token to swap to
     * @param amount The amount to rebalance in fromToken's native decimals
     */
    function rebalanceCollateral(address fromToken, address toToken, uint256 amount) external;

    /**
     * @notice Add sovaBTC liquidity for redemptions
     * @dev Only callable by PROTOCOL_ADMIN
     * @param amount The amount of sovaBTC to add (8 decimals)
     */
    function addLiquidity(uint256 amount) external;

    /**
     * @notice Remove excess collateral to a specified address
     * @dev Only callable by PROTOCOL_ADMIN
     * @param token The collateral token to remove
     * @param amount The amount to remove in token's native decimals
     * @param to The recipient address
     */
    function removeCollateral(address token, uint256 amount, address to) external;

    /**
     * @notice Set the associated vault address
     * @dev Only callable by PROTOCOL_ADMIN
     * @param vault The address of the vault contract
     */
    function setVault(address vault) external;

    /**
     * @notice Emergency withdrawal function for critical situations
     * @dev Only callable by PROTOCOL_ADMIN
     * @param token The token to withdraw
     * @param amount The amount to withdraw in token's native decimals
     * @param to The recipient address
     */
    function emergencyWithdraw(address token, uint256 amount, address to) external;

    /*//////////////////////////////////////////////////////////////
                            VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Get the balance of a specific collateral token
     * @param token The collateral token address
     * @return The balance in the token's native decimals (typically 8 for BTC tokens)
     */
    function collateralBalance(address token) external view returns (uint256);

    /**
     * @notice Get the total value of all assets in sovaBTC terms
     * @dev Aggregates all collateral values converted to sovaBTC
     * @return The total value in sovaBTC base units (8 decimals)
     */
    function totalAssets() external view returns (uint256);

    /**
     * @notice Get the associated vault address
     * @return The address of the vault contract
     */
    function vault() external view returns (address);

    /**
     * @notice Get list of all held collateral token addresses
     * @return An array of addresses for all collateral tokens held by the strategy
     */
    function getHeldCollaterals() external view returns (address[] memory);
}
