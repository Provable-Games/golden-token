<div align="center">

# Golden Token V2

![golden_token](https://github.com/user-attachments/assets/5a0047fa-1ee8-4ad6-9ffc-beecd70a7c5f)

</div>

## Overview

Golden Token V2 is the successor to the original Golden Token NFT collection on Starknet, modernized for full ecosystem compatibility and built entirely on-chain. V2 preserves the provenance of the original via a fully onchain airdrop while upgrading to modern standards and tooling.

V2 expands the collection by airdropping seven new ERC721 tokens to each of the 160 V1 holders, resulting in a total supply of 1,120. Each V2 token grants its holder one free Loot Survivor game per week, forever.

At a glance:

- Supply: 1,120 tokens (160 holders × 7 each)
- Distribution: Airdropped in seven rounds to current V1 holders at execution time
- Compatibility: OpenZeppelin ERC721 + ERC2981 on Cairo 2.11.4
- Governance: ERC721Votes for onchain voting and delegation
- Metadata: Fully on-chain JSON + SVG (no base URI, data URI returned)
- Art: Animated SVG instead of static PNG

V2 addresses early V1 limitations (pre-standard ERC721) by adopting modern standards and audited components, ensuring wallet/marketplace support, enforceable royalties, and native governance—while keeping the experience faithful to the original Golden Token vision.

## The Origin Story

The original Golden Tokens were launched on **October 31st, 2023**, alongside the inaugural release of Loot Survivor. In a true fair-launch fashion, Golden Tokens were made available through a three-week open edition mint with:

- ✅ No allowlist
- ✅ No mint limits
- ✅ No team allocation
- 💰 Cost: 75 games' worth of Loot Survivor

V1 Golden Tokens provided a simple utility: one free game of Loot Survivor per day. V2 Golden Tokens now provide one free game of Loot Survivor per week.

## V2: Technical Evolution & Enhanced Ecosystem

The original Golden Tokens were pioneering NFTs on Starknet, created before formal ERC721 specifications were available. This early adoption meant inconsistent compatibility - not all wallets, block explorers, and marketplaces properly support V1 tokens.

Golden Token V2 addresses these limitations while expanding the ecosystem:

### Technical Improvements

- **Full ERC721 Compliance**: Built with OpenZeppelin 2.0.0 specifications for universal compatibility
- **Modern Cairo**: Upgraded to Cairo 2.11.4 from 2.1.0 Cairo contracts
- **Ecosystem Compatibility**: Full support across all Starknet wallets, explorers, and marketplaces
- **Onchain Governance**: Integrated ERC721Votes enables holders to formally express views through onchain voting
- **Enhanced Security**: Latest audited OpenZeppelin components with comprehensive security patterns

### Ecosystem Enhancements

- **Increase Optionality**: Weekly games instead of daily, giving holders more flexibility
- **Expand Liquidity**: 7x supply increase (160 → 1,120 tokens) enables more trading and market activity
- **Preserve Legacy**: Original holders receive the entire V2 supply via airdrop
- **Maintain Exclusivity**: No public mint - only original holders can receive V2 tokens

### Key Differences from V1

| Feature            | V1                    | V2                     |
| ------------------ | --------------------- | ---------------------- |
| **Cairo Version**  | Cairo 2.1.0           | Cairo 2.11.4           |
| **ERC721 Spec**    | OpenZeppelin 0.7.0    | OpenZeppelin 2.0.0     |
| **Wallet Support** | Limited compatibility | Universal support      |
| **Voting**         | N/A                   | ERC721Votes integrated |
| **Total Supply**   | 160 tokens            | 1,120 tokens           |
| **Distribution**   | Open edition mint     | Airdrop to V1 holders  |
| **Game Frequency** | 1 free game/day       | 1 free game/week       |
| **Launch Date**    | October 31, 2023      | September 5th, 2025    |

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

- **ERC721Component**: Core NFT functionality with metadata extension
- **OwnableComponent**: Administrative access control
- **ERC2981Component**: NFT royalty standard implementation (5% on secondary sales)
- **VotesComponent**: Democratic governance through NFT-based voting
- **SRC5Component**: Interface detection for contract introspection
- **NoncesComponent**: Signature replay protection

### Airdrop Mechanism

The V2 distribution occurs through a systematic airdrop process:

- **7 Rounds Total**: Each round airdrops 160 new tokens to match the original collection size
- **1:7 Ratio**: Each original Golden Token holder receives 7 V2 Golden Tokens
- **Owner Verification**: Tokens are airdropped to current holders at the time of execution. No snapshots, no merkle trees, no manual claims required

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

# Run tests with mainnet forking (for integration tests)
snforge test --fork-url https://api.cartridge.gg/x/starknet/mainnet
```

### Formatting

```bash
# Format code
scarb fmt

# Check formatting
scarb fmt --check
```

### Deployment

1. **Setup Environment Variables**

   Copy the example environment file and add your credentials:

   ```bash
   cp .env.example .env
   ```

   Edit `.env` and add:

   - `STARKNET_ACCOUNT`: Your Starknet account address
   - `STARKNET_PRIVATE_KEY`: Your account private key

2. **Deploy to Sepolia testnet**

   ```bash
   ./scripts/deploy_sepolia.sh
   ```

3. **Deploy to mainnet** (use with caution)

   ```bash
   ./scripts/deploy_mainnet.sh
   ```

⚠️ **Security Note**: Never commit your `.env` file to version control. The `.env` file is already included in `.gitignore` for your protection.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- Thank you Golden Token holders for day one support of Loot Survivor.
- Thank you [1337 skulls](https://x.com/1337skulls) for the Golden Token artwork.

## Links

- [V1 Golden Token Contract](https://voyager.online/contract/0x04f5e296c805126637552cf3930e857f380e7c078e8f00696de4fc8545356b1d)
- [V1 Golden Token Source](https://github.com/BibliothecaDAO/golden-token)
- [V2 Golden Token Contract](https://voyager.online/nft-contract/0x027838dea749f41c6f8a44fcfa791788e6101080c1b3cd646a361f653ad10e2d)
- [Golden Token Ordinal Inscription](https://ordinals.com/inscription/372174547f83a8f288a8bac916841829de05e8817f102eed3f9b854aa2926398i0)
- [Loot Survivor Game](https://lootsurvivor.io)
