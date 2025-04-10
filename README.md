## RagaFinance Launchpad

RagaFinance Launchpad is a decentralized platform built on Ethereum that enables projects to raise funds through token sales using a Bancor bonding curve mechanism. The platform provides a secure and efficient way for projects to launch their tokens while ensuring fair price discovery and protecting both creators and investors.

### Key Features

- **Token Fundraising**: Projects can create fundraising campaigns with customizable parameters
- **Bancor Bonding Curve**: Implements a bonding curve for fair price discovery and liquidity provision
- **USDC Integration**: Uses USDC as the primary payment token
- **Security Features**: Multiple protection mechanisms against market manipulation
- **Upgradeable**: Built with upgradeability in mind using UUPS pattern

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

- Gas price limits
- Maximum price impact protection (5%)
- Slippage tolerance (1-10%) (Protection against MEV Bots)
- Daily volume limits
- Reentrancy protection
- Emergency pause functionality

### Deployment

#### Sepolia Testnet
```
Contract Address: [ADD_SEPOLIA_ADDRESS_HERE]
```

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
