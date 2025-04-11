// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library CustomBondingCurve {
    uint256 public constant ICO_TOKEN_ALLOCATION = 500_000_000 * 10**18; // 500M tokens (18 decimals)
    uint256 public constant TOKEN_DECIMALS = 18; // Token decimals
    uint256 public constant USDC_DECIMALS = 6; // USDC decimals
    uint256 public constant RESERVE_RATIO = 2_000; // 20% reserve ratio (0.2 * 10,000 for precision)

    function getCurrentPrice(
        uint256 tokensSold,
        uint256 usdcRaised,
        uint256 usdcTarget
    ) internal pure returns (uint256) {
        if (tokensSold >= ICO_TOKEN_ALLOCATION) {
            return (usdcTarget * 10**TOKEN_DECIMALS) / (ICO_TOKEN_ALLOCATION * RESERVE_RATIO / 10**4);
        }

        if (tokensSold == 0) {
            return (usdcTarget * 10**TOKEN_DECIMALS) / (ICO_TOKEN_ALLOCATION * RESERVE_RATIO / 10**4);
        }

        uint256 remainingSupply = ICO_TOKEN_ALLOCATION - tokensSold;
        return (usdcRaised * 10**TOKEN_DECIMALS) / (remainingSupply * RESERVE_RATIO / 10**4);
    }

    function calculateTokensForUSDC(
        uint256 usdcAmount,
        uint256 tokensSold,
        uint256 usdcRaised,
        uint256 usdcTarget
    ) public pure returns (uint256) {
        if (usdcAmount == 0 || tokensSold >= ICO_TOKEN_ALLOCATION) {
            return 0;
        }

        uint256 currentPrice = getCurrentPrice(tokensSold, usdcRaised, usdcTarget);
        require(currentPrice > 0, "Invalid price");

        uint256 tokens = (usdcAmount * 10**TOKEN_DECIMALS) / currentPrice;
        uint256 remainingTokens = ICO_TOKEN_ALLOCATION - tokensSold;
        if (tokens > remainingTokens) {
            tokens = remainingTokens;
        }

        return tokens;
    }

    function calculateUSDCForTokens(
        uint256 tokenAmount,
        uint256 tokensSold,
        uint256 usdcRaised,
        uint256 usdcTarget
    ) internal pure returns (uint256) {
        if (tokenAmount == 0 || tokensSold >= ICO_TOKEN_ALLOCATION) {
            return 0;
        }

        uint256 currentPrice = getCurrentPrice(tokensSold, usdcRaised, usdcTarget);
        require(currentPrice > 0, "Invalid price");

        return (tokenAmount * currentPrice) / 10**TOKEN_DECIMALS;
    }

    function calculateTokensForFinalUSDC(
        uint256 usdcRemaining,
        uint256 tokensRemaining,
        uint256 usdcTarget
    ) internal pure returns (uint256) {
        if (usdcRemaining == 0 || tokensRemaining == 0) {
            return 0;
        }

        uint256 finalPrice = (usdcTarget * 10**TOKEN_DECIMALS) / (ICO_TOKEN_ALLOCATION * RESERVE_RATIO / 10**4);
        return (usdcRemaining * 10**TOKEN_DECIMALS) / finalPrice;
    }
}