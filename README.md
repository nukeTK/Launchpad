## RagaFinance Launchpad

RagaFinance Launchpad is a decentralized platform built on Ethereum that enables projects to raise funds through token sales using a Bancor bonding curve mechanism. The platform provides a secure and efficient way for projects to launch their tokens while ensuring fair price discovery and protecting both creators and investors.

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

#### Why Linear?
The Linear bonding curve is the perfect fit for our use case because:
- **Inherent Stability**: No zero-price problems or formula modifications needed
- **Simple Implementation**: Straightforward to implement and understand
- **Fair Price Discovery**: Provides moderate rewards for early buyers (1.67x)
- **Predictable Progression**: Price changes are consistent and transparent
- **Balanced Incentives**: Rewards early participants while maintaining reasonable price progression
- **Smooth Trading**: Ensures continuous price movement without sudden jumps
- **Market Efficiency**: Facilitates natural price discovery and trading

The Linear curve aligns perfectly with our practical needs of raising funds, selling tokens, and rewarding early buyers without added complexity or potential issues.

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
- Base price: 75% of average price
- Final price: 125% of average price
- Price slope: (finalPrice - basePrice) / targetTokens

### Deployment

#### Sepolia Testnet
Contract Addresses:
Launchpad Proxy: [0x2ed0aa33fcd1a3b5b2abfa317582664686ce7cf4](https://sepolia.etherscan.io/address/0x2ed0aa33fcd1a3b5b2abfa317582664686ce7cf4)
Launchpad Implementation: [0xfabc58345ff9cacc43a3716a12520e32aa2853c8](https://sepolia.etherscan.io/address/0xfabc58345ff9cacc43a3716a12520e32aa2853c8)
Mock USDC (6 Decimals): [0xc896d15d0100fecdbff8c84ecfe62c5976040f3e](https://sepolia.etherscan.io/address/0xc896d15d0100fecdbff8c84ecfe62c5976040f3e)

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
- [Bancor Protocol Documentation](https://docs.bancor.network/)

### License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
