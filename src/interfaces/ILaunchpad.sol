// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface ILaunchpad {
    struct Fundraise {
        address creator;
        uint256 targetFunding;
        uint256 currentFunding;
        uint256 tokensSold;
        bool isCompleted;
        address tokenAddress;
        uint256 startTime;
        uint256 endTime;
    }

    // Constants
    function INITIAL_SUPPLY() external view returns (uint256);
    function TARGET_TOKENS_SOLD() external view returns (uint256);
    function CREATOR_TOKENS() external view returns (uint256);
    function LIQUIDITY_TOKENS() external view returns (uint256);
    function PLATFORM_FEE_TOKENS() external view returns (uint256);

    // Events
    event FundraiseCreated(uint256 indexed fundraiserId, address indexed creator, uint256 targetFunding);
    event TokensPurchased(uint256 indexed fundraiserId, address indexed buyer, uint256 amount, uint256 usdcAmount);
    event FundraiseCompleted(uint256 indexed fundraiserId, uint256 totalFunding, uint256 tokensSold);
    event TokensClaimed(uint256 indexed fundraiserId, address indexed claimer, uint256 amount);

    // Fundraiser Management
    function createFundraise(
        uint256 _targetFunding,
        uint256 _startTime,
        string memory _tokenName,
        string memory _tokenSymbol
    )
        external;

    function purchaseTokens(uint256 fundraiserId, uint256 usdcAmount) external;

    // View Functions
    function getFundraiser(uint256 fundraiserId)
        external
        view
        returns (
            address creator,
            uint256 targetFunding,
            uint256 currentFunding,
            uint256 tokensSold,
            bool isCompleted,
            address tokenAddress,
            uint256 startTime,
            uint256 endTime
        );
}
