// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

library BondingCurveLib {
    uint256 public constant USDC_DECIMALS = 1e6;
    uint256 public constant TOKEN_DECIMALS = 1e18;
    uint256 public constant SCALE = 1e18;

    /// @notice Calculate slope using reserveTarget and maxSupply
    function calculateSlope(uint256 reserveTargetUSDC, uint256 maxSupply) public pure returns (uint256) {
        uint256 reserveTarget = reserveTargetUSDC * 1e12; // 6 => 18
        return (2 * reserveTarget * SCALE) / (maxSupply * maxSupply / SCALE);
    }

    /// @notice Calculates token price at a given supply
    function calculatePrice(uint256 supply, uint256 slope) public pure returns (uint256) {
        return (slope * supply) / SCALE;
    }

    /// @notice Calculates how many tokens can be bought for a given USDC amount
    function calculateTokensToMint(
        uint256 usdcAmount, // 6 decimals
        uint256 currentSupply, // 18 decimals
        uint256 slope, // 18 decimals
        uint256 targetSupply // 18 decimals
    )
        public
        pure
        returns (uint256 tokensToMint, uint256 usdcNeeded)
    {
        uint256 ethAmount = usdcAmount * 1e12; // to 18 decimals
        // Calculate term with proper scaling
        uint256 term = (2 * ethAmount * SCALE) / slope;
        // Calculate current supply squared with proper scaling
        uint256 currentSupplySquared = (currentSupply * currentSupply) / SCALE;
        // Calculate new supply squared
        uint256 newSupplySquared = currentSupplySquared + term;
        // Calculate new supply
        uint256 newSupply = sqrt(newSupplySquared * SCALE); // Scale back to 18 decimals
        // Calculate tokens to mint
        tokensToMint = newSupply > currentSupply ? newSupply - currentSupply : 1;
        // Check if we would exceed target supply
        if (currentSupply + tokensToMint > targetSupply) {
            // Calculate remaining tokens
            uint256 remainingTokens = targetSupply - currentSupply;

            // Calculate USDC needed for remaining tokens
            uint256 newSupplyForRemaining = currentSupply + remainingTokens;
            uint256 newSupplySquaredForRemaining = (newSupplyForRemaining * newSupplyForRemaining) / SCALE;
            uint256 termForRemaining = newSupplySquaredForRemaining - currentSupplySquared;
            uint256 ethNeeded = (termForRemaining * slope) / (2 * SCALE);
            usdcNeeded = ethNeeded / 1e12; // Convert back to USDC (6 decimals)

            tokensToMint = remainingTokens;
        }
        return (tokensToMint, usdcNeeded);
    }

    /// @dev Babylonian method
    function sqrt(uint256 x) internal pure returns (uint256) {
        if (x == 0) return 0;
        uint256 z = x;
        uint256 y = (x + 1) / 2;
        while (y < z) {
            z = y;
            y = (x / y + y) / 2;
        }
        return z;
    }
}
