# Golden Token Generation 2 - NFT Collection

<div align="center">

![Golden Token](https://img.shields.io/badge/Golden%20Token%20Gen2-Fully%20Onchain%20NFTs-FFD700?style=for-the-badge)
[![Cairo](https://img.shields.io/badge/Cairo-2.11.4-orange?style=flat-square)](https://github.com/starkware-libs/cairo)
[![Starknet](https://img.shields.io/badge/Starknet-Mainnet-blue?style=flat-square)](https://starknet.io)
[![License](https://img.shields.io/badge/license-MIT-green?style=flat-square)](LICENSE)
[![Coverage](https://img.shields.io/badge/coverage-84.3%25-brightgreen?style=flat-square)](https://codecov.io)

</div>

## Overview

Golden Token Generation 2 is the successor to the original Golden Token NFT collection on Starknet—modernized for full ecosystem compatibility and built entirely on-chain. It preserves the provenance of the original while upgrading standards, tooling, and adding quality of life features.

Gen2 expands the collection by airdropping seven new ERC721 tokens to each of the 160 Gen1 holders, resulting in a total supply of 1,120. Each Gen2 token grants its holder one free Loot Survivor game per week, forever.

At a glance:

- Supply: 1,120 tokens (160 holders × 7 each)
- Distribution: Airdropped in seven rounds to current Gen1 holders at execution time
- Compatibility: OpenZeppelin ERC721 + ERC2981 on Cairo 2.11.4
- Governance: ERC721Votes for onchain voting and delegation
- Metadata: Fully on-chain JSON + SVG (no base URI, data URI returned)
- Art: Animated SVG instead of static PNG

Gen2 addresses early Gen1 limitations (pre-standard ERC721) by adopting modern standards and audited components, ensuring wallet/marketplace support, enforceable royalties, and native governance—while keeping the experience faithful to the original Golden Token vision.

## The Origin Story

The original Golden Tokens were launched on **October 31st, 2023**, alongside the inaugural release of Loot Survivor. In a true fair-launch fashion, these 160 tokens were made available through a three-week open edition mint with:

- ✅ No allowlist
- ✅ No mint limits
- ✅ No team allocation
- 💰 Cost: 75 games of Loot Survivor

Generation 1 Golden Tokens provided a simple utility: one free game of Loot Survivor per day. Generation 2 Golden Tokens now provide one free game of Loot Survivor per week.

## Generation 2: Technical Evolution & Enhanced Ecosystem

The original Golden Tokens were pioneering NFTs on Starknet, created before formal ERC721 specifications were available. This early adoption meant inconsistent compatibility - not all wallets, block explorers, and marketplaces properly support Generation 1 tokens.

Golden Token Generation 2 addresses these limitations while expanding the ecosystem:

### Technical Improvements

- **Full ERC721 Compliance**: Built with OpenZeppelin 2.0.0 specifications for universal compatibility
- **Modern Cairo**: Upgraded to Cairo 2.11.4 from 2.1.0 Cairo contracts
- **Ecosystem Compatibility**: Full support across all Starknet wallets, explorers, and marketplaces
- **Onchain Governance**: Integrated ERC721Votes enables holders to formally express views through onchain voting
- **Enhanced Security**: Latest audited OpenZeppelin components with comprehensive security patterns

### Ecosystem Enhancements

- **Increase Optionality**: Weekly games instead of daily, giving holders more flexibility
- **Expand Liquidity**: 7x supply increase (160 → 1,120 tokens) enables more trading and market activity, without changing net game issuance.
- **Preserve Legacy**: Original holders receive the entire Generation 2 supply via airdrop
- **Maintain Exclusivity**: No public mint - only original holders can receive Gen2 tokens

### Key Differences from Generation 1

| Feature                    | Generation 1 (Original) | Generation 2            |
| -------------------------- | ----------------------- | ----------------------- |
| **Cairo Version**          | 2.1.0                   | Cairo 2.11.4            |
| **ERC721 Spec**            | OpenZeppelin 0.7.0      | OpenZeppelin 2.0.0      |
| **Wallet Support**         | Limited compatibility   | Universal support       |
| **Voting**                 | Not available           | ERC721Votes integrated  |
| **Total Supply**           | 160 tokens              | 1,120 tokens            |
| **Distribution**           | Open edition mint       | Airdrop to Gen1 holders |
| **Game Frequency**         | 1 free game/day         | 1 free game/week        |
| **Tokens per Gen1 Holder** | 1                       | 7 additional            |
| **Launch Date**            | Oct 31, 2023            | TBD                     |

## Features

- 🎮 **Weekly Gaming Rights**: Each token grants one free Loot Survivor game per week in perpetuity
- 🪂 **Fair Airdrop System**: 7 rounds of airdrops, each distributing 160 tokens to original holders
- 🏛️ **Legacy Preservation**: Rewards early supporters with expanded holdings
- 🗳️ **Onchain Governance**: ERC721Votes enables formal onchain voting for ecosystem decisions
- 🔧 **Full Compatibility**: Works seamlessly with all Starknet wallets, explorers, and marketplaces
- 💰 **Creator Royalties**: 5% royalty on secondary sales via ERC2981 standard
- 🎨 **Fully Onchain**: All metadata and SVG artwork stored and generated onchain
- ⛓️ **Modern Standards**: Built with latest Cairo 2.11.4 and OpenZeppelin 2.0.0

## Technical Architecture

### Smart Contract Components

The contract leverages battle-tested OpenZeppelin Cairo components:

- **ERC721**: Core NFT functionality with metadata extension
- **Ownable**: Administrative access control
- **ERC2981**: NFT royalty standard implementation
- **Votes**: Democratic governance through NFT-based voting
- **SRC5**: Interface detection for contract introspection

### Airdrop Mechanism

The Generation 2 distribution occurs through a systematic airdrop process:

- **7 Rounds Total**: Each round airdrops 160 new tokens. This preserves original holders' token IDs.
- **1:7 Ratio**: Each original Golden Token holder receives 7 Gen2 Golden Tokens.
- **Owner Verification**: Tokens are airdropped to current holders at the time of execution. No snapshots, no merkles, no claims. This provides the most fair and transparent distribution.

## Development

### Prerequisites

- [Scarb](https://docs.swmansion.com/scarb/) 2.11.4
- [Starknet Foundry](https://github.com/foundry-rs/starknet-foundry) 0.46.0

### Building

```bash
scarb build
```

### Testing

```bash
# Run all tests
snforge test

# Run with coverage
snforge test --coverage
```

### Formatting

```bash
# Format code
scarb fmt

# Check formatting
scarb fmt --check
```

### Deployment

Deploy to Sepolia testnet:

```bash
./scripts/deploy_sepolia.sh
```

Ensure your `.env` file contains:

- `STARKNET_ACCOUNT`: Your Starknet account address
- `STARKNET_PRIVATE_KEY`: Your account private key

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- Thank you Golden Token holders for believing in Loot Survivor from day one.
- Thank you [1337 skulls](https://x.com/1337skulls) for the Golden Token artwork.

## Links

- [Original Golden Token Contract](https://voyager.online/contract/0x04f5e296c805126637552cf3930e857f380e7c078e8f00696de4fc8545356b1d)
- [Original Golden Token Source](https://github.com/BibliothecaDAO/golden-token)
