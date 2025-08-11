// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.25;

import {IManagedRedemptionQueue} from "../interfaces/IManagedRedemptionQueue.sol";
import {IMultiBTCVault} from "../interfaces/IMultiBTCVault.sol";
import {IMultiCollateralStrategy} from "../interfaces/IMultiCollateralStrategy.sol";
import {RoleManager} from "../auth/RoleManager.sol";
import {SafeTransferLib} from "solady/utils/SafeTransferLib.sol";
import {ERC4626} from "solady/tokens/ERC4626.sol";

/**
 * @title ManagedRedemptionQueue
 * @notice Implements a 14-day redemption queue for the Multi-BTC Vault
 * @dev Manages redemption requests with a waiting period before processing
 */
contract ManagedRedemptionQueue is IManagedRedemptionQueue {
    using SafeTransferLib for address;

    /*//////////////////////////////////////////////////////////////
                            CONSTANTS
    //////////////////////////////////////////////////////////////*/

    /// @notice The waiting period before redemptions can be processed (14 days)
    uint256 public constant REDEMPTION_DELAY = 14 days;

    /*//////////////////////////////////////////////////////////////
                            STATE
    //////////////////////////////////////////////////////////////*/

    /// @notice The vault that uses this queue
    IMultiBTCVault public immutable vault;

    /// @notice The strategy for executing withdrawals
    IMultiCollateralStrategy public immutable strategy;

    /// @notice Role manager for access control
    RoleManager public immutable roleManager;

    /// @notice The sovaBTC token address
    address public immutable sovaBTC;

    /// @notice Counter for redemption request IDs
    uint256 public nextRequestId = 1;

    /// @notice Mapping of request ID to redemption details
    mapping(uint256 => RedemptionRequest) public redemptionRequests;

    /// @notice Mapping of user address to their request IDs
    mapping(address => uint256[]) public userRequests;

    /// @notice Total shares pending redemption
    uint256 public totalPendingShares;

    /// @notice Total sovaBTC amount pending redemption
    uint256 public totalPendingSovaBTC;

    /// @notice Whether the queue is paused
    bool public paused;

    /*//////////////////////////////////////////////////////////////
                            MODIFIERS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Modifier to check if the queue is not paused
     */
    modifier whenNotPaused() {
        if (paused) revert Unauthorized(msg.sender);
        _;
    }

    /*//////////////////////////////////////////////////////////////
                            CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Constructor
     * @param _vault The MultiBTCVault address
     * @param _strategy The MultiCollateralStrategy address
     * @param _roleManager The RoleManager address
     * @param _sovaBTC The sovaBTC token address
     */
    constructor(address _vault, address _strategy, address _roleManager, address _sovaBTC) {
        if (_vault == address(0)) revert ZeroAddress();
        if (_strategy == address(0)) revert ZeroAddress();
        if (_roleManager == address(0)) revert ZeroAddress();
        if (_sovaBTC == address(0)) revert ZeroAddress();

        vault = IMultiBTCVault(_vault);
        strategy = IMultiCollateralStrategy(_strategy);
        roleManager = RoleManager(_roleManager);
        sovaBTC = _sovaBTC;
    }

    /*//////////////////////////////////////////////////////////////
                            USER FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @inheritdoc IManagedRedemptionQueue
     */
    function queueRedemption(address owner, uint256 shares, address receiver)
        external
        whenNotPaused
        returns (uint256 requestId)
    {
        // Only vault can queue redemptions
        if (msg.sender != address(vault)) revert Unauthorized(msg.sender);
        if (owner == address(0)) revert ZeroAddress();
        if (receiver == address(0)) revert ZeroAddress();
        if (shares == 0) revert ZeroShares();

        // Shares are already transferred to this contract by vault
        // Calculate sovaBTC amount based on current share value from vault
        // Cast vault to ERC4626 to access previewRedeem
        uint256 sovaBTCAmount = ERC4626(address(vault)).previewRedeem(shares);
        if (sovaBTCAmount == 0) revert InvalidAmount(sovaBTCAmount);

        // Create redemption request
        requestId = nextRequestId++;
        redemptionRequests[requestId] = RedemptionRequest({
            owner: owner,
            receiver: receiver,
            shares: shares,
            sovaBTCAmount: sovaBTCAmount,
            timestamp: block.timestamp,
            processed: false,
            cancelled: false
        });

        // Track user's requests
        userRequests[owner].push(requestId);

        // Update totals
        totalPendingShares += shares;
        totalPendingSovaBTC += sovaBTCAmount;

        emit RedemptionQueued(requestId, owner, receiver, shares, sovaBTCAmount, block.timestamp);
    }

    /**
     * @inheritdoc IManagedRedemptionQueue
     */
    function cancelRedemption(uint256 requestId) external whenNotPaused {
        RedemptionRequest storage request = redemptionRequests[requestId];

        // Validate request
        if (request.owner == address(0)) revert InvalidRequestId(requestId);
        if (request.owner != msg.sender) revert NotRequestOwner(msg.sender, requestId);
        if (request.processed) revert RequestAlreadyProcessed(requestId);
        if (request.cancelled) revert RequestAlreadyCancelled(requestId);

        // Mark as cancelled
        request.cancelled = true;

        // Return shares to user from queue's custody
        address(vault).safeTransfer(request.owner, request.shares);

        // Update totals
        totalPendingShares -= request.shares;
        totalPendingSovaBTC -= request.sovaBTCAmount;

        emit RedemptionCancelled(requestId, msg.sender);
    }

    /*//////////////////////////////////////////////////////////////
                            ADMIN FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @inheritdoc IManagedRedemptionQueue
     */
    function processRedemptions(uint256[] calldata requestIds) external whenNotPaused {
        // Check admin permission
        if (!roleManager.hasAllRoles(msg.sender, roleManager.PROTOCOL_ADMIN())) {
            revert Unauthorized(msg.sender);
        }

        uint256 totalSharesToRedeem = 0;
        uint256 totalSovaBTCNeeded = 0;

        // First pass: validate all requests and calculate totals
        for (uint256 i = 0; i < requestIds.length; i++) {
            uint256 requestId = requestIds[i];
            RedemptionRequest storage request = redemptionRequests[requestId];

            // Validate request
            if (request.owner == address(0)) revert InvalidRequestId(requestId);
            if (request.processed) revert RequestAlreadyProcessed(requestId);
            if (request.cancelled) revert RequestAlreadyCancelled(requestId);

            // Check if waiting period has passed (14 days)
            if (block.timestamp < request.timestamp + REDEMPTION_DELAY) {
                revert Unauthorized(msg.sender); // Request not ready yet
            }

            totalSharesToRedeem += request.shares;
            totalSovaBTCNeeded += request.sovaBTCAmount;
        }

        // Burn all shares at once and get actual sovaBTC amount
        uint256 actualSovaBTC = vault.burnSharesForRedemption(totalSharesToRedeem);

        // Second pass: process all redemptions
        for (uint256 i = 0; i < requestIds.length; i++) {
            uint256 requestId = requestIds[i];
            RedemptionRequest storage request = redemptionRequests[requestId];

            // Mark as processed
            request.processed = true;

            // Calculate proportional amount if needed
            uint256 sovaBTCForUser = request.sovaBTCAmount;
            if (actualSovaBTC < totalSovaBTCNeeded) {
                // Pro-rata distribution if insufficient
                sovaBTCForUser = (actualSovaBTC * request.sovaBTCAmount) / totalSovaBTCNeeded;
            }

            // Withdraw sovaBTC from strategy to user
            bool success = strategy.withdrawTo(sovaBTC, request.receiver, sovaBTCForUser);
            if (!success) revert Unauthorized(msg.sender); // Use existing error for withdrawal failure

            // Update totals
            totalPendingShares -= request.shares;
            totalPendingSovaBTC -= request.sovaBTCAmount;

            emit RedemptionProcessed(requestId, request.receiver, sovaBTCForUser);
        }

        emit RedemptionsProcessed(requestIds, msg.sender);
    }

    /*//////////////////////////////////////////////////////////////
                            VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @inheritdoc IManagedRedemptionQueue
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
        )
    {
        RedemptionRequest memory request = redemptionRequests[requestId];
        return (
            request.owner,
            request.receiver,
            request.shares,
            request.sovaBTCAmount,
            request.timestamp,
            request.processed,
            request.cancelled
        );
    }

    /**
     * @inheritdoc IManagedRedemptionQueue
     */
    function getPendingRedemptions(address owner) external view returns (uint256[] memory) {
        uint256[] memory allRequests = userRequests[owner];
        uint256 pendingCount = 0;

        // Count pending requests
        for (uint256 i = 0; i < allRequests.length; i++) {
            RedemptionRequest memory request = redemptionRequests[allRequests[i]];
            if (!request.processed && !request.cancelled) {
                pendingCount++;
            }
        }

        // Build array of pending requests
        uint256[] memory pendingRequests = new uint256[](pendingCount);
        uint256 index = 0;
        for (uint256 i = 0; i < allRequests.length; i++) {
            RedemptionRequest memory request = redemptionRequests[allRequests[i]];
            if (!request.processed && !request.cancelled) {
                pendingRequests[index++] = allRequests[i];
            }
        }

        return pendingRequests;
    }

    /**
     * @inheritdoc IManagedRedemptionQueue
     */
    function totalRequests() external view returns (uint256) {
        return nextRequestId - 1;
    }

    /*//////////////////////////////////////////////////////////////
                        EMERGENCY FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Pause the queue operations
     * @dev Only callable by PROTOCOL_ADMIN
     */
    function pause() external {
        if (!roleManager.hasAllRoles(msg.sender, roleManager.PROTOCOL_ADMIN())) {
            revert Unauthorized(msg.sender);
        }
        if (paused) revert Unauthorized(msg.sender); // Already paused
        paused = true;
    }

    /**
     * @notice Unpause the queue operations
     * @dev Only callable by PROTOCOL_ADMIN
     */
    function unpause() external {
        if (!roleManager.hasAllRoles(msg.sender, roleManager.PROTOCOL_ADMIN())) {
            revert Unauthorized(msg.sender);
        }
        if (!paused) revert Unauthorized(msg.sender); // Not paused
        paused = false;
    }

    /**
     * @notice Force process a single redemption request
     * @dev Emergency function to process stuck requests, bypasses time check
     * @param requestId The request ID to force process
     */
    function forceProcessRedemption(uint256 requestId) external {
        if (!roleManager.hasAllRoles(msg.sender, roleManager.PROTOCOL_ADMIN())) {
            revert Unauthorized(msg.sender);
        }

        RedemptionRequest storage request = redemptionRequests[requestId];

        // Validate request
        if (request.owner == address(0)) revert InvalidRequestId(requestId);
        if (request.processed) revert RequestAlreadyProcessed(requestId);
        if (request.cancelled) revert RequestAlreadyCancelled(requestId);

        // Mark as processed
        request.processed = true;

        // Burn shares and get sovaBTC
        uint256 actualSovaBTC = vault.burnSharesForRedemption(request.shares);

        // Withdraw to receiver
        bool success = strategy.withdrawTo(sovaBTC, request.receiver, actualSovaBTC);
        if (!success) revert Unauthorized(msg.sender);

        // Update totals
        totalPendingShares -= request.shares;
        totalPendingSovaBTC -= request.sovaBTCAmount;

        emit RedemptionProcessed(requestId, request.receiver, actualSovaBTC);
    }

    /**
     * @notice Rescue stuck tokens
     * @dev Emergency function to recover tokens
     * @param token The token address to rescue
     * @param to The recipient address
     * @param amount The amount to rescue
     */
    function rescueTokens(address token, address to, uint256 amount) external {
        if (!roleManager.hasAllRoles(msg.sender, roleManager.PROTOCOL_ADMIN())) {
            revert Unauthorized(msg.sender);
        }
        if (to == address(0)) revert ZeroAddress();

        token.safeTransfer(to, amount);
    }
}
