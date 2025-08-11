// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.25;

import {ERC4626} from "solady/tokens/ERC4626.sol";
import {SafeTransferLib} from "solady/utils/SafeTransferLib.sol";
import {FixedPointMathLib} from "solady/utils/FixedPointMathLib.sol";
import {ReentrancyGuard} from "solady/utils/ReentrancyGuard.sol";

import {IMultiBTCVault} from "../interfaces/IMultiBTCVault.sol";
import {IMultiCollateralRegistry} from "../interfaces/IMultiCollateralRegistry.sol";
import {IMultiCollateralStrategy} from "../interfaces/IMultiCollateralStrategy.sol";
import {IManagedRedemptionQueue} from "../interfaces/IManagedRedemptionQueue.sol";
import {IReporter} from "../reporter/IReporter.sol";
import {RoleManaged} from "../auth/RoleManaged.sol";
import {Conduit} from "../conduit/Conduit.sol";
import {IERC20} from "forge-std/interfaces/IERC20.sol";

/**
 * @title MultiBTCVault
 * @notice Multi-collateral BTC vault accepting multiple BTC-pegged tokens and redeeming in sovaBTC
 * @dev Extends ERC4626 with multi-collateral support
 */
contract MultiBTCVault is IMultiBTCVault, ERC4626, RoleManaged, ReentrancyGuard {
    using FixedPointMathLib for uint256;
    using SafeTransferLib for address;

    /*//////////////////////////////////////////////////////////////
                            CONSTANTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Minimum investment amount (0.001 BTC = 1e5 in 8 decimals)
    uint256 public constant MINIMUM_INVESTMENT = 1e5;

    /*//////////////////////////////////////////////////////////////
                            STATE
    //////////////////////////////////////////////////////////////*/

    /// @notice Internal storage for token metadata
    string private _name;
    string private _symbol;
    
    /// @notice The sovaBTC token address (redemption asset)
    address private immutable _asset;
    
    /// @notice The multi-collateral registry
    address public immutable collateralRegistry;
    
    /// @notice The strategy managing collateral
    address public strategy;
    
    /// @notice The price oracle reporter
    address public priceOracle;
    
    /// @notice The conduit for token transfers (if used)
    address public immutable conduit;
    
    /// @notice Whether the vault is paused
    bool private _paused;
    
    /// @notice The redemption queue contract
    address public redemptionQueue;

    /*//////////////////////////////////////////////////////////////
                            CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Constructor
     * @param name_ Vault token name
     * @param symbol_ Vault token symbol
     * @param sovaBTC_ Address of sovaBTC (redemption asset)
     * @param registry_ Address of multi-collateral registry
     * @param roleManager_ Address of role manager
     * @param conduit_ Address of conduit (can be address(0) if not used)
     */
    constructor(
        string memory name_,
        string memory symbol_,
        address sovaBTC_,
        address registry_,
        address roleManager_,
        address conduit_
    ) RoleManaged(roleManager_) {
        if (sovaBTC_ == address(0)) revert InvalidAddress();
        if (registry_ == address(0)) revert InvalidAddress();
        
        _name = name_;
        _symbol = symbol_;
        _asset = sovaBTC_;
        collateralRegistry = registry_;
        conduit = conduit_;
    }

    /*//////////////////////////////////////////////////////////////
                            MODIFIERS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Modifier to check if the vault is not paused
     */
    modifier whenNotPaused() {
        if (_paused) revert Paused();
        _;
    }

    /*//////////////////////////////////////////////////////////////
                        MULTI-COLLATERAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @inheritdoc IMultiBTCVault
     */
    function depositCollateral(address token, uint256 amount, address receiver)
        external
        override
        nonReentrant
        whenNotPaused
        returns (uint256 shares)
    {
        if (receiver == address(0)) revert InvalidAddress();
        if (amount == 0) revert InvalidAmount(amount);
        if (!IMultiCollateralRegistry(collateralRegistry).isSupportedAsset(token)) {
            revert TokenNotSupported(token);
        }
        
        // Check minimum investment amount (0.001 BTC)
        if (amount < MINIMUM_INVESTMENT) {
            revert InvalidAmount(amount);
        }
        
        // Calculate shares based on collateral value
        shares = previewDepositCollateral(token, amount);
        if (shares == 0) revert ZeroShares();
        
        // Transfer collateral from depositor
        if (conduit != address(0)) {
            // Use conduit for transfer
            Conduit(conduit).collectDeposit(token, msg.sender, strategy, amount);
        } else {
            // Direct transfer
            token.safeTransferFrom(msg.sender, strategy, amount);
        }
        
        // Mint shares to receiver
        _mint(receiver, shares);
        
        emit CollateralDeposited(msg.sender, token, amount, shares, receiver);
        
        return shares;
    }

    /**
     * @inheritdoc IMultiBTCVault
     */
    function queueRedemption(uint256 shares, address receiver)
        external
        override
        nonReentrant
        whenNotPaused
        returns (uint256 requestId)
    {
        if (shares == 0) revert ZeroShares();
        if (receiver == address(0)) revert InvalidAddress();
        if (redemptionQueue == address(0)) revert QueueNotSet();
        
        // Check user has enough shares
        if (balanceOf(msg.sender) < shares) revert InvalidAmount(shares);
        
        // Transfer shares from user to queue for custody
        _transfer(msg.sender, redemptionQueue, shares);
        
        // Call queue to record the redemption request
        requestId = IManagedRedemptionQueue(redemptionQueue).queueRedemption(msg.sender, shares, receiver);
        
        emit RedemptionQueued(msg.sender, receiver, shares, requestId);
    }

    /**
     * @inheritdoc IMultiBTCVault
     */
    function burnSharesForRedemption(uint256 shares)
        external
        override
        returns (uint256 assets)
    {
        // Only redemption queue can call this
        if (msg.sender != redemptionQueue) revert Unauthorized(msg.sender);
        if (shares == 0) revert ZeroShares();
        
        // Calculate assets for the shares
        assets = previewRedeem(shares);
        
        // Burn shares held by the queue
        _burn(redemptionQueue, shares);
        
        return assets;
    }

    /**
     * @inheritdoc IMultiBTCVault
     */
    function previewDepositCollateral(address token, uint256 amount)
        public
        view
        override
        returns (uint256 shares)
    {
        if (!IMultiCollateralRegistry(collateralRegistry).isSupportedAsset(token)) {
            return 0;
        }
        
        // Convert collateral amount to sovaBTC value
        uint256 sovaBTCValue = IMultiCollateralRegistry(collateralRegistry).getValueInUnderlying(token, amount);
        
        // Use standard ERC4626 conversion
        return previewDeposit(sovaBTCValue);
    }

    /*//////////////////////////////////////////////////////////////
                            ADMIN FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @inheritdoc IMultiBTCVault
     */
    function setStrategy(address newStrategy)
        external
        override
        onlyRoles(roleManager.PROTOCOL_ADMIN())
    {
        if (newStrategy == address(0)) revert InvalidAddress();
        
        address oldStrategy = strategy;
        strategy = newStrategy;
        
        emit StrategyUpdated(oldStrategy, newStrategy);
    }

    /**
     * @inheritdoc IMultiBTCVault
     */
    function setPriceOracle(address newOracle)
        external
        override
        onlyRoles(roleManager.PROTOCOL_ADMIN())
    {
        if (newOracle == address(0)) revert InvalidAddress();
        
        address oldOracle = priceOracle;
        priceOracle = newOracle;
        
        emit PriceOracleUpdated(oldOracle, newOracle);
    }

    /**
     * @inheritdoc IMultiBTCVault
     */
    function pause() external override onlyRoles(roleManager.PROTOCOL_ADMIN()) {
        if (_paused) revert Paused();
        _paused = true;
        emit VaultPaused(msg.sender);
    }

    /**
     * @inheritdoc IMultiBTCVault
     */
    function unpause() external override onlyRoles(roleManager.PROTOCOL_ADMIN()) {
        if (!_paused) revert NotPaused();
        _paused = false;
        emit VaultUnpaused(msg.sender);
    }

    /**
     * @inheritdoc IMultiBTCVault
     */
    function setRedemptionQueue(address newQueue)
        external
        override
        onlyRoles(roleManager.PROTOCOL_ADMIN())
    {
        if (newQueue == address(0)) revert InvalidAddress();
        
        address oldQueue = redemptionQueue;
        redemptionQueue = newQueue;
        
        emit RedemptionQueueUpdated(oldQueue, newQueue);
    }
    
    /**
     * @inheritdoc IMultiBTCVault
     */
    function paused() public view override returns (bool) {
        return _paused;
    }

    /*//////////////////////////////////////////////////////////////
                        ERC4626 OVERRIDES
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Returns the vault token name
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @notice Returns the vault token symbol
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @notice Returns the address of the underlying asset (sovaBTC)
     */
    function asset() public view virtual override returns (address) {
        return _asset;
    }

    /**
     * @notice Returns the total assets managed by the vault
     * @dev Returns the total value in sovaBTC terms from the strategy
     */
    function totalAssets() public view virtual override returns (uint256) {
        if (strategy == address(0)) return 0;
        
        // If we have a price oracle, use reported NAV
        if (priceOracle != address(0)) {
            uint256 pricePerShare = abi.decode(IReporter(priceOracle).report(), (uint256));
            uint256 totalSupply = totalSupply();
            
            // pricePerShare is in 18 decimals, totalSupply is in 18 decimals
            // Result needs to be in asset decimals (8 for sovaBTC)
            // (pricePerShare * totalSupply) / 10^(18 + 18 - 8) = result in 8 decimals
            return pricePerShare.mulDiv(totalSupply, 10**28);
        }
        
        // Otherwise use strategy's reported total assets
        return IMultiCollateralStrategy(strategy).totalAssets();
    }

    /**
     * @dev Returns the decimals of the underlying asset (sovaBTC = 8)
     */
    function _underlyingDecimals() internal pure virtual override returns (uint8) {
        return 8; // BTC tokens typically have 8 decimals
    }

    /**
     * @dev Returns the offset for share decimals (18 - 8 = 10)
     */
    function _decimalsOffset() internal pure virtual override returns (uint8) {
        return 10; // Makes shares 18 decimals
    }

    /**
     * @notice Standard ERC4626 deposit - reverts as we only accept multi-collateral deposits
     */
    function deposit(uint256, address) public virtual override returns (uint256) {
        revert TokenNotSupported(_asset);
    }

    /**
     * @notice Standard ERC4626 mint - reverts as we only accept multi-collateral deposits
     */
    function mint(uint256, address) public virtual override returns (uint256) {
        revert TokenNotSupported(_asset);
    }

    /**
     * @notice Withdraw sovaBTC by burning shares
     */
    function withdraw(uint256 assets, address receiver, address owner)
        public
        virtual
        override
        nonReentrant
        whenNotPaused
        returns (uint256 shares)
    {
        if (receiver == address(0)) revert InvalidAddress();
        if (assets == 0) revert InvalidAmount(assets);
        
        shares = previewWithdraw(assets);
        if (shares == 0) revert ZeroShares();
        
        // Check allowance if withdrawing for someone else
        if (msg.sender != owner) {
            _spendAllowance(owner, msg.sender, shares);
        }
        
        // Burn shares
        _burn(owner, shares);
        
        // Withdraw sovaBTC from strategy
        bool success = IMultiCollateralStrategy(strategy).withdrawTo(_asset, receiver, assets);
        if (!success) revert WithdrawFailed();
        
        emit Withdraw(msg.sender, receiver, owner, assets, shares);
        
        return shares;
    }

    /**
     * @notice Redeem shares for sovaBTC
     */
    function redeem(uint256 shares, address receiver, address owner)
        public
        virtual
        override
        nonReentrant
        whenNotPaused
        returns (uint256 assets)
    {
        if (receiver == address(0)) revert InvalidAddress();
        if (shares == 0) revert ZeroShares();
        
        assets = previewRedeem(shares);
        if (assets == 0) revert ZeroAssets();
        
        // Check allowance if redeeming for someone else
        if (msg.sender != owner) {
            _spendAllowance(owner, msg.sender, shares);
        }
        
        // Burn shares
        _burn(owner, shares);
        
        // Withdraw sovaBTC from strategy
        bool success = IMultiCollateralStrategy(strategy).withdrawTo(_asset, receiver, assets);
        if (!success) revert WithdrawFailed();
        
        emit Withdraw(msg.sender, receiver, owner, assets, shares);
        
        return assets;
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Spend allowance with proper checks
     */
    function _spendAllowance(address owner, address spender, uint256 amount) internal override {
        uint256 allowed = allowance(owner, spender);
        if (allowed < amount) revert InsufficientAllowance();
        
        if (allowed != type(uint256).max) {
            _approve(owner, spender, allowed - amount);
        }
    }
}