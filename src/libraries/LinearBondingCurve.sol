// LinearBondingCurve.sol
//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

library LinearBondingCurve {
    uint256 public constant PRECISION = 10 ** 18; // Standard 18 decimal precision

    // Calculate both base price and slope based on target parameters
    function calculateCurveParams(
        uint256 targetTokens,
        uint256 targetUsdc
    )
        internal
        pure
        returns (uint256 basePrice, uint256 slope)
    {
        // Convert USDC to 18 decimals for calculation
        uint256 targetUsdc18 = targetUsdc * 10 ** 12; // Convert from 6 to 18 decimal precision
        // Calculate average price per token
        uint256 avgPrice = (targetUsdc18 * PRECISION) / targetTokens;
        // Set base price to 75% of average price
        basePrice = (avgPrice * 75) / 100;
        // Calculate final price (125% of average price)
        uint256 finalPrice = (avgPrice * 125) / 100;
        // Calculate total price increase
        uint256 totalPriceIncrease = finalPrice - basePrice;

        // Calculate slope (price increase per token)
        slope = (totalPriceIncrease * PRECISION) / targetTokens;
    }

    function getPrice(
        uint256 tokensSold,
        uint256 targetTokens,
        uint256 basePrice,
        uint256 slope
    )
        public
        view
        returns (uint256)
    {
        require(tokensSold < targetTokens, "Sale ended");
        return basePrice + ((slope * tokensSold) / PRECISION);
    }

    function calculateTokens(
        uint256 tokensSold,
        uint256 usdcAmount,
        uint256 targetTokens,
        uint256 basePrice,
        uint256 slope
    )
        internal
        view
        returns (uint256)
    {
        uint256 price = getPrice(tokensSold, targetTokens, basePrice, slope);
        // Convert USDC amount from 6 to 18 decimals
        uint256 usdcAmount18 = usdcAmount * 10 ** 12;
        return (usdcAmount18 * PRECISION) / price;
    }
}
