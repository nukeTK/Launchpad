##Launchpad

Launchpad is a decentralized platform built on Ethereum that enables projects to raise funds through token sales using a Bancor bonding curve mechanism. The platform provides a secure and efficient way for projects to launch their tokens while ensuring fair price discovery and protecting both creators and investors.

### Key Features

- **Token Fundraising**: Projects can create fundraising campaigns with customizable parameters
- **Bancor Bonding Curve**: Implements a bonding curve for fair price discovery and liquidity provision
- **USDC Integration**: Uses USDC as the primary payment token
- **Security Features**: Multiple protection mechanisms against market manipulation
- **Upgradeable**: Built with upgradeability in mind using UUPS pattern

### Bonding Curve Selection

The platform uses a Linear bonding curve for token price determination. Here's a detailed breakdown of the available bonding curve types and why we chose Linear:

#### Available Bonding Curve Types
1. **Linear**: Price increases linearly with token sales
2. **Step**: Price increases in discrete steps
3. **Exponential**: Price increases exponentially (not used due to zero-price issues)
4. **Hyperbolic**: Price follows hyperbolic curve (not used due to zero-price issues)

#### Why Not Exponential and Hyperbolic?
Both Exponential and Hyperbolic bonding curves face critical issues: they require initial funding to establish a starting price, and when tokensSold = 0, they can result in a price of zero (or an impractical value). This causes problems like:
- Need for significant initial capital to seed the reserve
- Division by zero errors without proper seeding
- Infinite tokens per USDC at low reserve levels
- Unstable price discovery in early stages
- Unfair market conditions without adequate initial liquidity

These issues make them unsuitable for a functioning token sale without significant formula modifications.

#### Why Not Step?
While Step functions are viable, they have some drawbacks:
- Price increases in discrete jumps rather than smoothly
- Can create artificial price barriers
- May discourage trading between price steps
- Less natural price discovery

### Why We Chose This Linear Bonding Curve Formula

The bonding curve logic is implemented in `BondingCurveLib.sol`, which uses a mathematically derived formula to calculate token pricing over time based on supply. Here's how and why this approach was chosen:

#### Problem to Solve
We needed a bonding curve that:
- Increases token price smoothly with every token minted
- Maintains precision between USDC (6 decimals) and tokens (18 decimals)
- Avoids zero-price edge cases and manipulation
- Supports predictable and fair pricing for buyers
- Requires no initial liquidity seeding or complicated bootstrapping

#### Mathematical Foundation
The linear bonding curve follows the formula:
```solidity
Price = slope × supply
```

To determine the total cost of purchasing tokens or how many tokens can be purchased with a given amount of USDC, we integrate the price function:
```solidity
Total Cost = (slope / 2) × (newSupply² - currentSupply²)
```

This enables:
- Efficient pricing calculation without loops
- Accurate output for both "buy X tokens" or "spend Y USDC" flows
- A consistent and predictable pricing model

#### Mathematical Derivation

We use a linear bonding curve defined by the formula:
```
price = slope * currentSupply
```

Where:
- `price` is the current token price in USDC (6 decimals)
- `slope = (2 * target_raise * 1e6) / (maxSupply^2)`
- `target_raise` is the total USDC we aim to raise (e.g., 1,000,000 USDC)
- `maxSupply` is the maximum number of tokens to be sold (e.g., 1,000,000 tokens)

We derive this formula to ensure that when all tokens (up to maxSupply) are sold, the total USDC raised exactly equals target_raise. This is achieved by integrating the price curve:

```
totalUSDC = ∫ from 0 to maxSupply of (slope * x) dx
         = (slope * maxSupply^2) / 2
```

Solving for slope gives:
```
slope = (2 * target_raise) / maxSupply^2
```

This mathematical design ensures:
- Early buyers get a cheaper price
- Later buyers pay a higher price as supply increases
- Predictable, capped fundraising that encourages early participation
- Fair and transparent price discovery mechanism
- No price manipulation opportunities
- Efficient gas usage through simple arithmetic operations

#### Implementation Details
The `BondingCurveLib` implements:
1. `calculateSlope`: Computes the linear slope based on max token supply and USDC target
2. `calculatePrice`: Returns the token price at a given supply
3. `calculateTokensToMint`: Computes tokens mintable for given USDC input
4. `sqrt`: Babylonian square root method used in curve inversion

All functions are carefully scaled between 6 and 18 decimals to match token and stablecoin standards and avoid precision loss.

#### Integration with Launchpad
The Launchpad is designed around this bonding curve model to:
- Allow creators to define a target USDC raise and max supply
- Dynamically compute token price as the sale progresses
- Guarantee fair treatment for all buyers (early and late)
- Prevent manipulation via slippage or gas bribes
- Optimize for gas and upgradeability via modular architecture

#### Key Advantages
- Smooth and fair token issuance
- Efficient use of math (no looping or iterative approximation)
- Constant-time computation
- Scaled precision (1e18) for Ethereum's fixed-point arithmetic
- No need for initial capital
- Simple implementation
- Transparent price calculation
- Safe from manipulation

### Token Distribution

- **Total Supply**: 1 billion tokens
- **Public Sale**: 500 million tokens
- **Creator Allocation**: 200 million tokens
- **Liquidity Pool**: 250 million tokens
- **Platform Fee**: 50 million tokens

### Fundraising Parameters

- **Minimum Target**: 100,000 USDC
- **Maximum Target**: 1 billion USDC
- **Payment Token**: USDC (6 decimals)

### Protection Mechanisms

- Reentrancy protection
- Emergency pause functionality
- Minimum purchase amount: 1 USDC
- Maximum purchase amount: Target funding amount
- Time-based restrictions
  - Sale starts at specified time
  - Sale ends when target is reached or manually ended by creator
- Input validation
  - Target funding must be whole USDC amounts
  - Target funding within min/max bounds
  - Valid token name and symbol
- Access control
  - Only creator can end sale
  - Only creator can claim creator tokens
  - Only buyers can claim their purchased tokens
- Price calculation safeguards
  - Precision handling for 18 decimal calculations
  - Overflow protection
  - Minimum price enforcement
- Token transfer restrictions
  - No transfers until sale ends
  - No transfers until tokens are claimed

### Smart Contract Architecture

#### Core Contracts
- `Launchpad.sol`: Main contract handling fundraising logic
- `LaunchpadToken.sol`: ERC20 token contract for each fundraise

#### Libraries
- `LinearBondingCurve.sol`: Implements linear bonding curve calculations

#### Key Features
- Proxy upgradeable pattern
- OpenZeppelin security standards
- Gas optimized operations
- Event logging for all key actions
- Modular design for future extensions

### Technical Parameters

- Solidity version: ^0.8.20
- Decimal precision: 18 decimals

### Deployment

#### Sepolia Testnet
| Contract | Address | Link |
| --- | --- | --- |
| Launchpad Proxy | 0x2ed0aa33fcd1a3b5b2abfa317582664686ce7cf4 | [View on Etherscan](https://sepolia.etherscan.io/address/0x2ed0aa33fcd1a3b5b2abfa317582664686ce7cf4) |
| Launchpad Implementation | 0xfabc58345ff9cacc43a3716a12520e32aa2853c8 | [View on Etherscan](https://sepolia.etherscan.io/address/0xfabc58345ff9cacc43a3716a12520e32aa2853c8) |
| Mock USDC (6 Decimals) | 0xc896d15d0100fecdbff8c84ecfe62c5976040f3e | [View on Etherscan](https://sepolia.etherscan.io/address/0xc896d15d0100fecdbff8c84ecfe62c5976040f3e) |

### Development

This project uses Foundry for development and testing.

#### Build
```shell
$ forge build
```

#### Test
```shell
$ forge test
```

#### Format
```shell
$ forge fmt
```

#### Deploy
```shell
$ forge script script/Counter.s.sol:CounterScript --rpc-url <your_rpc_url> --private-key <your_private_key>
```

### Documentation

For more detailed information about the implementation and usage, please refer to:
- [Foundry Documentation](https://book.getfoundry.sh/)
- [OpenZeppelin Documentation](https://docs.openzeppelin.com/)

### License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
