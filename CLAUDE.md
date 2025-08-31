# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Cairo smart contract project for the Golden Token NFT collection on Starknet. The contract implements a fully onchain NFT with 160 tokens that provide users one free Loot Survivor game daily, with support for airdrops, voting, and royalties.

## Development Commands

### Building and Testing
```bash
# Build the project
scarb build

# Run all tests
snforge test

# Run tests with specific features
snforge test --workspace --features fuzzing --fuzzer-runs 500 --coverage --max-n-steps 4294967295

# Format code
scarb fmt

# Check formatting
scarb fmt --check --workspace
```

### Deployment
```bash
# Deploy to Sepolia testnet
./scripts/deploy_sepolia.sh
```

## Architecture

### Contract Structure
The main contract (`src/lib.cairo`) uses OpenZeppelin components:
- **ERC721Component**: NFT functionality with minting and transfer
- **OwnableComponent**: Access control for admin functions
- **VotesComponent**: ERC721 voting mechanism that tracks voting power
- **ERC2981Component**: Royalty standard with 5% default (500/10000)
- **SRC5Component**: Interface detection
- **NoncesComponent**: Nonce tracking for signatures

### Key Features
- **Airdrop System**: `airdrop_tokens()` function distributes tokens to original Golden Token holders in batches of 160, limited to 7 rounds
- **Onchain Metadata**: Token URIs are generated onchain with base64-encoded JSON and SVG images
- **Voting Integration**: Implements ERC721Votes through hooks that transfer voting units on mint/burn/transfer

### Testing Approach
Tests use `snforge` with mainnet forking to test against real Golden Token contract data. Coverage threshold is 80% enforced via CI.

## Important Implementation Details

- Token IDs are calculated as: `airdrop_round * 160 + token_index`
- Voting power transfers are handled automatically via `ERC721VotesHooksImpl`
- Royalty fraction is immutable at 10,000 denominator (500 = 5%)
- Constructor requires: name, symbol, base_uri, owner, golden_token_address, royalty_receiver, royalty_fraction

## Dependencies
- Cairo 2.11.4 
- Starknet Foundry 0.46.0
- OpenZeppelin Cairo Contracts 2.0.0