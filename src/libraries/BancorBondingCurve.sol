// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

library BancorBondingCurve {
    uint256 public constant MAX_RESERVE_RATIO = 1_000_000; // 100%
    uint256 public constant DECIMALS_DIFF = 1e12; // Difference between 18 and 6 decimals
    uint256 public constant ONE = 1e18;
    uint256 public constant INITIAL_SUPPLY = 1_000_000_000 * 1e18; // 1 billion tokens with 18 decimals
    uint256 public constant TOKENS_FOR_FUNDING = 500_000_000 * 1e18; // 500 million tokens for desired funding

    /**
     * @dev Calculate tokens received for a given USDC amount
     * Formula: Return = Supply * ((1 + Deposit/Reserve)^(RR/MRR) - 1)
     */
    function calculateTokensForUSDC(
        uint256 initialSupply,    // 18 decimals
        uint256 currentReserveBalance, // 6 decimals
        uint256 usdcAmount, // 6 decimals
        uint256 targetFunding // 6 decimals
    ) internal pure returns (uint256) {
        if (usdcAmount == 0) return 0;

        // Convert to 18 decimals
        uint256 reserveBalance = currentReserveBalance * DECIMALS_DIFF;
        uint256 adjustedUsdc = usdcAmount * DECIMALS_DIFF;

        // Get dynamic reserve ratio
        uint32 dynamicRatio = getDynamicReserveRatio(currentReserveBalance, targetFunding);

        // Special case for 100% reserve ratio
        if (dynamicRatio == MAX_RESERVE_RATIO) {
            return (initialSupply * adjustedUsdc) / reserveBalance;
        }

        // Special case for first purchase
        if (reserveBalance == 0) {
            // For first purchase, calculate tokens based on target funding and TOKENS_FOR_FUNDING
            uint256 tokensPerUsdc = (TOKENS_FOR_FUNDING * DECIMALS_DIFF) / targetFunding;
            return (tokensPerUsdc * usdcAmount) / DECIMALS_DIFF;
        }

        // Calculate power using Taylor series
        uint256 baseN = adjustedUsdc + reserveBalance;
        uint256 baseD = reserveBalance;
        uint256 power = calculatePower(baseN, baseD, dynamicRatio);
        
        // Calculate tokens
        uint256 newTokenSupply = (initialSupply * power) / ONE;
        return newTokenSupply - initialSupply;
    }

    /**
     * @dev Calculate dynamic reserve ratio based on current reserve balance and target funding
     */
    function getDynamicReserveRatio(
        uint256 _reserveBalance,
        uint256 _targetFunding
    ) private pure returns (uint32) {
        if (_targetFunding == 0) return uint32(MAX_RESERVE_RATIO / 2);
        uint256 ratio = (_reserveBalance * MAX_RESERVE_RATIO) / _targetFunding;
        return uint32(ratio > MAX_RESERVE_RATIO ? MAX_RESERVE_RATIO : ratio);
    }

    /**
     * @dev Calculate power using Taylor series approximation
     * Formula: (baseN/baseD)^(exponent/MAX_RESERVE_RATIO)
     */
    function calculatePower(
        uint256 baseN,
        uint256 baseD,
        uint256 exponent
    ) private pure returns (uint256) {
        // First term: 1
        uint256 result = ONE;
        
        // Second term: exponent * (baseN/baseD - 1)
        uint256 term = ((baseN - baseD) * exponent) / MAX_RESERVE_RATIO;
        result += term;
        
        // Third term: (exponent * (exponent - 1) * (baseN/baseD - 1)^2) / 2
        if (exponent > 1) {
            uint256 term2 = ((baseN - baseD) * (baseN - baseD)) / baseD;
            term2 = (term2 * exponent * (exponent - 1)) / (2 * MAX_RESERVE_RATIO * MAX_RESERVE_RATIO);
            result += term2;
        }
        
        return result;
    }
} 