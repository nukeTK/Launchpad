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
import "./libraries/BancorBondingCurve.sol";
import "./interfaces/ILaunchpad.sol";
import "./interfaces/IUniswapV2Router02.sol";
import "forge-std/console2.sol";

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

    // Constants (all properly decimal-adjusted)
    uint256 public constant override INITIAL_SUPPLY = 1_000_000_000 * 1e18; // 1B tokens (18 decimals)
    uint256 public constant override TARGET_TOKENS_SOLD = 500_000_000 * 1e18; // 500M tokens (18 decimals)
    uint256 public constant override CREATOR_TOKENS = 200_000_000 * 1e18; // 200M tokens (18 decimals)
    uint256 public constant override LIQUIDITY_TOKENS = 250_000_000 * 1e18; // 250M tokens (18 decimals)
    uint256 public constant override PLATFORM_FEE_TOKENS = 50_000_000 * 1e18; // 50M tokens (18 decimals)

    // Target funding limits (6 decimals for USDC)
    uint256 public constant MIN_TARGET_FUNDING = 100_000 * 1e6; // 100,000 USDC
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

    /**
     * @notice Pauses all contract operations
     * @dev Only callable by the contract owner
     * @dev When paused, all state-changing functions will revert
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @notice Unpauses the contract operations
     * @dev Only callable by the contract owner
     * @dev Restores normal contract functionality
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * @notice Authorizes contract upgrades
     * @dev Only callable by the contract owner
     * @param newImplementation Address of the new implementation contract
     */
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner { }

    // =============================================
    // ============ EXTERNAL FUNCTIONS =============
    // =============================================

    /**
     * @notice Creates a new fundraising campaign
     * @dev Creates a new token and sets up the fundraising parameters
     * @param _targetFunding Target amount of USDC to raise (6 decimals)
     * @param _tokenName Name of the token to be created
     * @param _tokenSymbol Symbol of the token to be created
     */
    function createFundraise(
        uint256 _targetFunding, // 6 decimals
        string memory _tokenName,
        string memory _tokenSymbol
    )
        external
        override
        whenNotPaused
    {
        require(_targetFunding >= MIN_TARGET_FUNDING, "Target funding too low");
        require(_targetFunding <= MAX_TARGET_FUNDING, "Target funding too high");
        require(_targetFunding % 1e6 == 0, "Target funding must be in whole USDC");

        LaunchpadToken token = new LaunchpadToken(_tokenName, _tokenSymbol);

        fundraiserIds++;

        fundraisers[fundraiserIds] = Fundraise({
            creator: msg.sender,
            targetFunding: _targetFunding, // 6 decimals
            currentFunding: 0, // 6 decimals
            tokensSold: 0, // 18 decimals
            isCompleted: false,
            tokenAddress: address(token),
            startTime: block.timestamp,
            endTime: 0
        });

        activeFundraisers[fundraiserIds] = true;

        emit FundraiseCreated(fundraiserIds, msg.sender, _targetFunding);
    }

    /**
     * @notice Allows users to purchase tokens in a fundraising campaign
     * @dev Uses Bancor bonding curve to determine token price
     * @param fundraiserId ID of the fundraising campaign
     * @param usdcAmount Amount of USDC to spend (6 decimals)
     */
    function purchaseTokens(
        uint256 fundraiserId,
        uint256 usdcAmount // usdcAmount in 6 decimals
    )
        external
        override
        nonReentrant
        whenNotPaused
    {
        require(activeFundraisers[fundraiserId], "Fundraise not active");
        Fundraise storage fundraiser = fundraisers[fundraiserId];
        require(!fundraiser.isCompleted, "Fundraise completed");

        IERC20 usdc = IERC20(usdcAddress);

        uint256 tokensToReceive = BancorBondingCurve.calculateTokensForUSDC(
            INITIAL_SUPPLY, // 18 decimals
            fundraiser.currentFunding, // 6 decimals
            usdcAmount, // 6 decimals
            fundraiser.targetFunding // 6 decimals
        );

        console2.log("tokensToReceive", tokensToReceive);
        require(tokensToReceive > 0, "Amount too small");

        require(fundraiser.tokensSold + tokensToReceive <= TARGET_TOKENS_SOLD, "Exceeds target tokens");

        // Transfer USDC from buyer (6 decimals)
        usdc.safeTransferFrom(msg.sender, address(this), usdcAmount);

        // Update state
        fundraiser.currentFunding += usdcAmount; // 6 decimals
        fundraiser.tokensSold += tokensToReceive; // 18 decimals
        userPurchases[fundraiserId][msg.sender] += tokensToReceive; // 18 decimals

        emit TokensPurchased(fundraiserId, msg.sender, tokensToReceive, usdcAmount);

        // Check if funding target is reached
        if (fundraiser.currentFunding >= fundraiser.targetFunding || fundraiser.tokensSold >= TARGET_TOKENS_SOLD) {
            completeFundraise(fundraiserId);
        }
    }

    /**
     * @notice Allows users to claim their purchased tokens after fundraising completion
     * @param fundraiserId ID of the fundraising campaign
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
     * @notice Returns detailed information about a fundraising campaign
     * @param fundraiserId ID of the fundraising campaign
     * @return creator Address of the campaign creator
     * @return targetFunding Target funding amount in USDC (6 decimals)
     * @return currentFunding Current funding amount in USDC (6 decimals)
     * @return tokensSold Number of tokens sold (18 decimals)
     * @return isCompleted Whether the campaign is completed
     * @return tokenAddress Address of the campaign's token
     * @return startTime Timestamp when the campaign started
     * @return endTime Timestamp when the campaign ended (0 if not ended)
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

    // =============================================
    // ============ INTERNAL FUNCTIONS =============
    // =============================================

    /**
     * @notice Completes a fundraising campaign
     * @dev Distributes tokens and USDC according to the predefined rules
     * @dev Creates Uniswap liquidity pool
     * @param fundraiserId ID of the fundraising campaign
     */
    function completeFundraise(uint256 fundraiserId) internal {
        Fundraise storage fundraiser = fundraisers[fundraiserId];
        require(!fundraiser.isCompleted, "Already completed");

        LaunchpadToken token = LaunchpadToken(fundraiser.tokenAddress);
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
        token.transfer(fundraiser.creator, CREATOR_TOKENS); // 18 decimals
        usdc.safeTransfer(fundraiser.creator, creatorUsdcAmount); // 6 decimals

        // Transfer platform fee
        token.transfer(owner(), PLATFORM_FEE_TOKENS); // 18 decimals

        // Create Uniswap pool
        token.approve(uniswapRouter, LIQUIDITY_TOKENS); // 18 decimals
        usdc.safeTransfer(uniswapRouter, liquidityUsdcAmount); // 6 decimals

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
