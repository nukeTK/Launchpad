// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "./LaunchpadToken.sol";
import "./libraries/BondingCurveLib.sol";
import "./interfaces/ILaunchpad.sol";
import "./interfaces/IUniswapV2Router02.sol";
import "./interfaces/IUniswapFactory.sol";

contract Launchpad is
    Initializable,
    UUPSUpgradeable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable,
    PausableUpgradeable,
    ILaunchpad
{
    using SafeERC20 for IERC20;

    // Storage
    uint256 public fundraiserIds;
    mapping(uint256 => Fundraise) public fundraisers;
    mapping(uint256 => bool) public activeFundraisers;
    mapping(uint256 => mapping(address => uint256)) public userPurchases;

    address public usdcAddress;
    address public uniswapRouter;

    // Constants
    uint256 public constant MIN_PURCHASE = 1 * 1e6; // 1 USDC (6 decimals)
    uint256 public constant MAX_PURCHASE = 10_000 * 1e6; // 10K USDC (6 decimals)

    // Token distribution constants (all 18 decimals)
    uint256 public constant override INITIAL_SUPPLY = 1_000_000_000 * 1e18; // 1B tokens
    uint256 public constant override TARGET_TOKENS_SOLD = 500_000_000 * 1e18; // 500M tokens
    uint256 public constant override CREATOR_TOKENS = 200_000_000 * 1e18; // 200M tokens
    uint256 public constant override LIQUIDITY_TOKENS = 250_000_000 * 1e18; // 250M tokens
    uint256 public constant override PLATFORM_FEE_TOKENS = 50_000_000 * 1e18; // 50M tokens

    // Target funding limits (6 decimals for USDC)
    uint256 public constant MIN_TARGET_FUNDING = 500_000 * 1e6; // 500K USDC
    uint256 public constant MAX_TARGET_FUNDING = 1_000_000_000 * 1e6; // 1B USDC

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address _usdcAddress, address _uniswapRouter) public initializer {
        require(_usdcAddress != address(0), "Invalid USDC address");
        require(_uniswapRouter != address(0), "Invalid Uniswap router address");

        __Ownable_init(msg.sender);
        __UUPSUpgradeable_init();
        __ReentrancyGuard_init();
        __Pausable_init();

        usdcAddress = _usdcAddress;
        uniswapRouter = _uniswapRouter;
    }

    // =============================================
    // ============= OWNER FUNCTIONS ===============
    // =============================================

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner { }

    // =============================================
    // ============ EXTERNAL FUNCTIONS =============
    // =============================================

    /**
     * @notice Creates a new fundraising campaign
     * @param _targetFunding The target funding amount in USDC (6 decimals)
     * @param _startTime The timestamp when the fundraise will start
     * @param _tokenName The name of the token to be created
     * @param _tokenSymbol The symbol of the token to be created
     */
    function createFundraise(
        uint256 _targetFunding,
        uint256 _startTime,
        string memory _tokenName,
        string memory _tokenSymbol
    )
        external
        override
        whenNotPaused
    {
        require(_startTime > block.timestamp, "Start time must be in the future");
        require(_targetFunding >= MIN_TARGET_FUNDING, "Target funding too low");
        require(_targetFunding <= MAX_TARGET_FUNDING, "Target funding too high");

        LaunchpadToken token = new LaunchpadToken(_tokenName, _tokenSymbol);
        fundraiserIds++;

        fundraisers[fundraiserIds] = Fundraise({
            creator: msg.sender,
            targetFunding: _targetFunding, // 6 decimals
            currentFunding: 0, // 6 decimals
            tokensSold: 0, // 18 decimals
            isCompleted: false,
            tokenAddress: address(token),
            startTime: _startTime,
            endTime: 0
        });

        activeFundraisers[fundraiserIds] = true;

        emit FundraiseCreated(fundraiserIds, msg.sender, _targetFunding);
    }

    /**
     * @notice Allows users to purchase tokens from a fundraise using USDC
     * @param fundraiserId The ID of the fundraise to purchase from
     * @param usdcAmount The amount of USDC to spend (6 decimals)
     */
    function purchaseTokens(uint256 fundraiserId, uint256 usdcAmount) external override nonReentrant whenNotPaused {
        require(activeFundraisers[fundraiserId], "Fundraise not active");
        Fundraise storage fundraiser = fundraisers[fundraiserId];

        require(block.timestamp >= fundraiser.startTime, "Fundraise not started");
        require(!fundraiser.isCompleted, "Fundraise completed");
        require(usdcAmount >= MIN_PURCHASE, "USDC amount too low");
        require(usdcAmount <= MAX_PURCHASE, "USDC amount too high");

        // Calculate slope using reserveTarget and maxSupply
        uint256 slope = BondingCurveLib.calculateSlope(fundraiser.targetFunding, TARGET_TOKENS_SOLD);
        // Calculate tokens to mint using bonding curve
        (uint256 tokenAmount, uint256 usdcNeeded) =
            BondingCurveLib.calculateTokensToMint(usdcAmount, fundraiser.tokensSold, slope, TARGET_TOKENS_SOLD);

        require(tokenAmount > 0, "Token amount too low");

        // If we need less USDC than provided, adjust the amount
        if (usdcNeeded > 0 && usdcNeeded < usdcAmount) {
            usdcAmount = usdcNeeded;
        }

        // Check if this transaction would bring us within 1% of target
        uint256 totalAfterTransaction = fundraiser.tokensSold + tokenAmount;
        uint256 remainingToTarget = TARGET_TOKENS_SOLD - totalAfterTransaction;
        if (remainingToTarget <= TARGET_TOKENS_SOLD / 100) {
            // Add remaining tokens to this transaction
            tokenAmount += remainingToTarget;
        }

        // Transfer USDC from user to contract
        IERC20(usdcAddress).safeTransferFrom(msg.sender, address(this), usdcAmount);

        // Update fundraiser state
        fundraiser.tokensSold += tokenAmount;
        fundraiser.currentFunding += usdcAmount;
        userPurchases[fundraiserId][msg.sender] += tokenAmount;

        emit TokensPurchased(fundraiserId, msg.sender, tokenAmount, usdcAmount);

        // Check for completion
        if (fundraiser.tokensSold == TARGET_TOKENS_SOLD && fundraiser.currentFunding == fundraiser.targetFunding) {
            completeFundraise(fundraiserId);
        }
    }

    /**
     * @notice Allows users to claim their purchased tokens
     * @param fundraiserId The ID of the fundraiser to claim tokens from
     */
    function claimTokens(uint256 fundraiserId) external nonReentrant {
        require(!activeFundraisers[fundraiserId], "Fundraise still active");
        Fundraise storage fundraiser = fundraisers[fundraiserId];
        require(fundraiser.isCompleted, "Fundraise not completed");

        uint256 tokensToClaim = userPurchases[fundraiserId][msg.sender]; // 18 decimals
        require(tokensToClaim > 0, "No tokens to claim");

        userPurchases[fundraiserId][msg.sender] = 0;
        LaunchpadToken(fundraiser.tokenAddress).transfer(msg.sender, tokensToClaim);

        emit TokensClaimed(fundraiserId, msg.sender, tokensToClaim);
    }

    // =============================================
    // ============== VIEW FUNCTIONS ===============
    // =============================================

    /**
     * @notice Returns information about a specific fundraiser
     * @param fundraiserId The ID of the fundraiser to retrieve information for
     * @return creator The address of the fundraiser creator
     * @return targetFunding The target funding amount in USDC (6 decimals)
     * @return currentFunding The current funding amount in USDC (6 decimals)
     * @return tokensSold The total number of tokens sold
     * @return isCompleted Whether the fundraiser is completed
     * @return tokenAddress The address of the token created
     * @return startTime The start time of the fundraiser
     * @return endTime The end time of the fundraiser
     */
    function getFundraiser(uint256 fundraiserId)
        external
        view
        override
        returns (
            address creator,
            uint256 targetFunding,
            uint256 currentFunding,
            uint256 tokensSold,
            bool isCompleted,
            address tokenAddress,
            uint256 startTime,
            uint256 endTime
        )
    {
        Fundraise memory fundraiser = fundraisers[fundraiserId];
        return (
            fundraiser.creator,
            fundraiser.targetFunding,
            fundraiser.currentFunding,
            fundraiser.tokensSold,
            fundraiser.isCompleted,
            fundraiser.tokenAddress,
            fundraiser.startTime,
            fundraiser.endTime
        );
    }

    /**
     * @notice Returns the price of tokens in USDC for a specific fundraiser
     * @param fundraiserId The ID of the fundraiser
     * @return The price of tokens in USDC
     */
    function returnPrice(uint256 fundraiserId) public view returns (uint256) {
        Fundraise memory fundraiser = fundraisers[fundraiserId];
        uint256 slope = BondingCurveLib.calculateSlope(fundraiser.targetFunding, TARGET_TOKENS_SOLD);
        return BondingCurveLib.calculatePrice(fundraiser.tokensSold, slope);
    }

    /**
     * @notice Returns the total amount of tokens purchased by a user for a specific fundraiser
     * @param fundraiserId The ID of the fundraiser
     * @param user The address of the user
     * @return The amount of tokens purchased by the user
     */
    function getUserPurchases(uint256 fundraiserId, address user) public view returns (uint256) {
        return userPurchases[fundraiserId][user];
    }

    /**
     * @notice Returns the remaining tokens available for purchase in a fundraiser
     * @param fundraiserId The ID of the fundraiser
     * @return The amount of tokens remaining for purchase
     */
    function getRemainingTokens(uint256 fundraiserId) public view returns (uint256) {
        Fundraise memory fundraiser = fundraisers[fundraiserId];
        return TARGET_TOKENS_SOLD - fundraiser.tokensSold;
    }

    /**
     * @notice Returns the fundraising progress as a percentage (0-100)
     * @param fundraiserId The ID of the fundraiser
     * @return The percentage of funding completed
     */
    function getFundraisingProgress(uint256 fundraiserId) public view returns (uint256) {
        Fundraise memory fundraiser = fundraisers[fundraiserId];
        return (fundraiser.currentFunding * 100) / fundraiser.targetFunding;
    }

    // =============================================
    // ============ INTERNAL FUNCTIONS =============
    // =============================================

    function completeFundraise(uint256 fundraiserId) internal {
        Fundraise storage fundraiser = fundraisers[fundraiserId];
        require(!fundraiser.isCompleted, "Already completed");

        LaunchpadToken token = LaunchpadToken(fundraiser.tokenAddress);
        IERC20 tokenContract = IERC20(token);
        IERC20 usdc = IERC20(usdcAddress);

        // Calculate amounts for distribution (all in 6 decimals)
        uint256 creatorUsdcAmount = fundraiser.currentFunding * 50 / 100; // 50%
        uint256 liquidityUsdcAmount = fundraiser.currentFunding - creatorUsdcAmount;
        // Verify total token distribution matches INITIAL_SUPPLY
        require(
            CREATOR_TOKENS + LIQUIDITY_TOKENS + PLATFORM_FEE_TOKENS + fundraiser.tokensSold == INITIAL_SUPPLY,
            "Token distribution mismatch"
        );

        // Transfer creator's share
        tokenContract.transfer(fundraiser.creator, CREATOR_TOKENS); // 18 decimals
        usdc.safeTransfer(fundraiser.creator, creatorUsdcAmount); // 6 decimals

        // Transfer platform fee
        tokenContract.transfer(owner(), PLATFORM_FEE_TOKENS); // 18 decimals

        // Create Uniswap pool
        tokenContract.approve(uniswapRouter, LIQUIDITY_TOKENS); // 18 decimals
        usdc.approve(uniswapRouter, liquidityUsdcAmount); // 6 decimals
        
        IUniswapV2Router02 router = IUniswapV2Router02(uniswapRouter);
        router.addLiquidity(
            address(token),
            usdcAddress,
            LIQUIDITY_TOKENS, // 18 decimals
            liquidityUsdcAmount, // 6 decimals
            LIQUIDITY_TOKENS * 95 / 100, // 5% slippage tolerance
            liquidityUsdcAmount * 95 / 100,
            address(this),
            block.timestamp + 1 hours
        );

        // Update state
        fundraiser.isCompleted = true;
        fundraiser.endTime = block.timestamp;
        activeFundraisers[fundraiserId] = false;

        emit FundraiseCompleted(fundraiserId, fundraiser.currentFunding, fundraiser.tokensSold);
    }
}
