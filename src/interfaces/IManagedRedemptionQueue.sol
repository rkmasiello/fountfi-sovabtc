// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.25;

/**
 * @title IManagedRedemptionQueue
 * @notice Interface for managed withdrawal queue system
 * @dev Optional component for queued redemptions instead of direct withdrawals
 */
interface IManagedRedemptionQueue {
    /*//////////////////////////////////////////////////////////////
                                ERRORS
    //////////////////////////////////////////////////////////////*/

    error InvalidRequestId(uint256 requestId);
    error RequestAlreadyProcessed(uint256 requestId);
    error RequestAlreadyCancelled(uint256 requestId);
    error NotRequestOwner(address caller, uint256 requestId);
    error InvalidAmount(uint256 amount);
    error ZeroShares();
    error ZeroAddress();
    error Unauthorized(address caller);
    error InsufficientLiquidity(uint256 requested, uint256 available);

    /*//////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Emitted when a redemption is queued
     * @param requestId The unique identifier for the redemption request
     * @param owner The owner of the shares being redeemed
     * @param receiver The address that will receive the sovaBTC
     * @param shares The amount of shares to redeem (18 decimals)
     * @param sovaBTCAmount The expected sovaBTC amount (8 decimals)
     * @param timestamp The timestamp when the request was created
     */
    event RedemptionQueued(
        uint256 indexed requestId,
        address indexed owner,
        address indexed receiver,
        uint256 shares,
        uint256 sovaBTCAmount,
        uint256 timestamp
    );

    /**
     * @notice Emitted when redemptions are processed
     * @param requestIds Array of processed request IDs
     * @param processor The address that processed the redemptions
     */
    event RedemptionsProcessed(uint256[] requestIds, address indexed processor);

    /**
     * @notice Emitted when a single redemption is processed
     * @param requestId The processed request ID
     * @param receiver The receiver of the sovaBTC
     * @param amount The amount of sovaBTC sent
     */
    event RedemptionProcessed(uint256 indexed requestId, address indexed receiver, uint256 amount);

    /**
     * @notice Emitted when a redemption is cancelled
     * @param requestId The cancelled request ID
     * @param owner The owner who cancelled the request
     */
    event RedemptionCancelled(uint256 indexed requestId, address indexed owner);

    /*//////////////////////////////////////////////////////////////
                                STRUCTS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Redemption request information
     * @param owner The owner of the shares
     * @param receiver The recipient of the sovaBTC
     * @param shares The amount of shares to redeem (18 decimals)
     * @param sovaBTCAmount The amount of sovaBTC to receive (8 decimals)
     * @param timestamp When the request was created
     * @param processed Whether the request has been processed
     * @param cancelled Whether the request has been cancelled
     */
    struct RedemptionRequest {
        address owner;
        address receiver;
        uint256 shares;
        uint256 sovaBTCAmount;
        uint256 timestamp;
        bool processed;
        bool cancelled;
    }

    /*//////////////////////////////////////////////////////////////
                            USER FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Queue a redemption request
     * @dev Called by the vault when a user initiates a redemption
     * @param owner The owner of the shares to redeem
     * @param shares The amount of shares to redeem (18 decimals)
     * @param receiver The address to receive the sovaBTC
     * @return requestId The unique identifier for this redemption request
     */
    function queueRedemption(address owner, uint256 shares, address receiver) external returns (uint256 requestId);

    /**
     * @notice Cancel a pending redemption request
     * @dev Only the request owner can cancel
     * @param requestId The ID of the request to cancel
     */
    function cancelRedemption(uint256 requestId) external;

    /*//////////////////////////////////////////////////////////////
                            ADMIN FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Process multiple queued redemption requests
     * @dev Only callable by PROTOCOL_ADMIN
     * @param requestIds Array of request IDs to process
     */
    function processRedemptions(uint256[] calldata requestIds) external;

    /*//////////////////////////////////////////////////////////////
                            VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Get detailed information about a redemption request
     * @param requestId The ID of the redemption request
     * @return owner The owner of the shares
     * @return receiver The recipient address for sovaBTC
     * @return shares The amount of shares to redeem (18 decimals)
     * @return sovaBTCAmount The amount of sovaBTC to receive (8 decimals)
     * @return timestamp When the request was created
     * @return processed Whether the request has been processed
     * @return cancelled Whether the request has been cancelled
     */
    function getRedemptionRequest(uint256 requestId)
        external
        view
        returns (
            address owner,
            address receiver,
            uint256 shares,
            uint256 sovaBTCAmount,
            uint256 timestamp,
            bool processed,
            bool cancelled
        );

    /**
     * @notice Get all pending redemption request IDs for an address
     * @param owner The address to query
     * @return An array of pending request IDs
     */
    function getPendingRedemptions(address owner) external view returns (uint256[] memory);

    /**
     * @notice Get the total number of redemption requests
     * @return The total count of all redemption requests
     */
    function totalRequests() external view returns (uint256);

    /**
     * @notice Get the total shares pending redemption
     * @return The sum of shares from all pending requests (18 decimals)
     */
    function totalPendingShares() external view returns (uint256);

    /**
     * @notice Get the total sovaBTC amount pending redemption
     * @return The sum of sovaBTC from all pending requests (8 decimals)
     */
    function totalPendingSovaBTC() external view returns (uint256);
}
