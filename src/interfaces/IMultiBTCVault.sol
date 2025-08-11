// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.25;

/**
 * @title IMultiBTCVault
 * @notice Multi-collateral BTC vault interface for ERC-4626 vault
 * @dev Accepts multiple BTC-pegged tokens as deposits and always redeems in sovaBTC
 */
interface IMultiBTCVault {
    /*//////////////////////////////////////////////////////////////
                                ERRORS
    //////////////////////////////////////////////////////////////*/

    error TokenNotSupported(address token);
    error InvalidAmount(uint256 amount);
    error InvalidAddress();
    error DepositFailed();
    error WithdrawFailed();
    error Paused();
    error NotPaused();
    error Unauthorized(address caller);
    error ZeroShares();
    error ZeroAssets();
    error QueueNotSet();

    /*//////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Emitted when collateral is deposited
     * @param depositor The address that deposited
     * @param token The collateral token deposited
     * @param amount The amount deposited in token's native decimals
     * @param shares The shares minted to the receiver
     * @param receiver The address that received the shares
     */
    event CollateralDeposited(
        address indexed depositor, address indexed token, uint256 amount, uint256 shares, address indexed receiver
    );

    /**
     * @notice Emitted when the strategy is updated
     * @param oldStrategy The previous strategy address
     * @param newStrategy The new strategy address
     */
    event StrategyUpdated(address indexed oldStrategy, address indexed newStrategy);

    /**
     * @notice Emitted when the price oracle is updated
     * @param oldOracle The previous oracle address
     * @param newOracle The new oracle address
     */
    event PriceOracleUpdated(address indexed oldOracle, address indexed newOracle);

    /**
     * @notice Emitted when the vault is paused
     * @param account The account that triggered the pause
     */
    event VaultPaused(address account);

    /**
     * @notice Emitted when the vault is unpaused
     * @param account The account that triggered the unpause
     */
    event VaultUnpaused(address account);

    /**
     * @notice Emitted when the redemption queue is updated
     * @param oldQueue The previous queue address
     * @param newQueue The new queue address
     */
    event RedemptionQueueUpdated(address indexed oldQueue, address indexed newQueue);

    /**
     * @notice Emitted when a redemption is queued
     * @param user The user who queued the redemption
     * @param receiver The receiver of the redemption
     * @param shares The shares queued for redemption
     * @param requestId The ID of the redemption request
     */
    event RedemptionQueued(address indexed user, address indexed receiver, uint256 shares, uint256 requestId);

    /*//////////////////////////////////////////////////////////////
                        MULTI-COLLATERAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Deposit a specific BTC collateral token to receive vault shares
     * @dev Collateral must be supported by the registry
     * @param token The BTC collateral token address (WBTC, tBTC, etc.)
     * @param amount The amount to deposit in the token's native decimals (typically 8)
     * @param receiver The address to receive the vault shares
     * @return shares The amount of shares minted (18 decimals)
     */
    function depositCollateral(address token, uint256 amount, address receiver) external returns (uint256 shares);

    /**
     * @notice Preview shares that would be minted for a collateral deposit
     * @dev Does not account for slippage or fees
     * @param token The BTC collateral token address
     * @param amount The amount to deposit in the token's native decimals
     * @return shares The amount of shares that would be minted (18 decimals)
     */
    function previewDepositCollateral(address token, uint256 amount) external view returns (uint256 shares);

    /**
     * @notice Queue a redemption request through the redemption queue
     * @dev Transfers shares to queue for custody during the 14-day waiting period
     * @param shares The amount of shares to redeem (18 decimals)
     * @param receiver The address to receive sovaBTC after redemption
     * @return requestId The ID of the redemption request
     */
    function queueRedemption(uint256 shares, address receiver) external returns (uint256 requestId);

    /**
     * @notice Burn shares held by the redemption queue
     * @dev Only callable by the redemption queue contract
     * @param shares The amount of shares to burn
     * @return assets The amount of sovaBTC assets the shares represent
     */
    function burnSharesForRedemption(uint256 shares) external returns (uint256 assets);

    /*//////////////////////////////////////////////////////////////
                            ADMIN FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Set a new strategy contract
     * @dev Only callable by PROTOCOL_ADMIN
     * @param newStrategy The address of the new strategy contract
     */
    function setStrategy(address newStrategy) external;

    /**
     * @notice Set a new price oracle reporter
     * @dev Only callable by PROTOCOL_ADMIN
     * @param newOracle The address of the new price oracle
     */
    function setPriceOracle(address newOracle) external;

    /**
     * @notice Pause all vault operations
     * @dev Only callable by PROTOCOL_ADMIN
     */
    function pause() external;

    /**
     * @notice Unpause vault operations
     * @dev Only callable by PROTOCOL_ADMIN
     */
    function unpause() external;

    /**
     * @notice Set the redemption queue contract
     * @dev Only callable by PROTOCOL_ADMIN
     * @param newQueue The address of the redemption queue contract
     */
    function setRedemptionQueue(address newQueue) external;

    /*//////////////////////////////////////////////////////////////
                            VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/


    /**
     * @notice Get the strategy contract address
     * @return The address of the strategy managing collateral
     */
    function strategy() external view returns (address);

    /**
     * @notice Get the price oracle reporter address
     * @return The address of the price oracle
     */
    function priceOracle() external view returns (address);

    /**
     * @notice Get the conduit address if used for token transfers
     * @return The address of the conduit contract (may be address(0) if not used)
     */
    function conduit() external view returns (address);

    /**
     * @notice Check if the vault is paused
     * @return True if paused, false otherwise
     */
    function paused() external view returns (bool);

    /**
     * @notice Get the redemption queue address
     * @return The address of the redemption queue contract
     */
    function redemptionQueue() external view returns (address);

    /*//////////////////////////////////////////////////////////////
                        ERC-4626 OVERRIDES NOTES
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Notes on ERC-4626 implementation for this multi-collateral vault:
     *
     * asset() - Returns sovaBTC address (the redemption asset)
     *
     * decimals() - Returns 18 (share token decimals)
     *
     * totalAssets() - Returns total value of all collateral in sovaBTC terms (8 decimals)
     *
     * deposit()/mint() - Should revert with TokenNotSupported error
     *                    Users must use depositCollateral() instead
     *
     * withdraw()/redeem() - Always returns sovaBTC, never other collateral types
     *                      Amount/shares use appropriate decimal scaling
     *
     * All preview functions account for conversion rates from registry
     */
}
