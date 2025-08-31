# GEMINI.md

## Project Overview

This project is a Starknet smart contract for an NFT collection called "Golden Token Generation 2". It is the second generation of the Golden Token NFT collection, which was originally launched on October 31st, 2023. The Generation 2 tokens are being airdropped to the original 160 Golden Token holders, with each holder receiving 7 new tokens. This will bring the total supply to 1,120 tokens.

The primary utility of the Generation 2 tokens is to provide holders with one free game of Loot Survivor per week, forever. The original Golden Tokens provided one free game per day.

The main technical improvements of Generation 2 are:

*   **Full ERC721 Compliance:** Built with OpenZeppelin 2.0.0 specifications for universal compatibility.
*   **Modern Cairo:** Upgraded to Cairo 2.11.4 from legacy Cairo contracts.
*   **Onchain Governance:** Integrated ERC721Votes enables holders to formally express views through onchain voting.
*   **Fully Onchain:** All metadata and SVG artwork are stored and generated onchain.

## Building and Running

### Prerequisites

*   [Scarb](https://docs.swmansion.com/scarb/) 2.11.4
*   [Starknet Foundry](https://github.com/foundry-rs/starknet-foundry) 0.46.0
*   [starkli](https://github.com/xJonathanLEI/starkli) CLI

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

### Deployment

Deploy to Sepolia testnet:

```bash
./scripts/deploy_sepolia.sh
```

Ensure your `.env` file contains:

*   `STARKNET_ACCOUNT`: Your Starknet account address
*   `STARKNET_PRIVATE_KEY`: Your account private key

After deployment, the owner must invoke `airdrop_tokens`:

```bash
starkli invoke <deployed_contract_address> airdrop_tokens \
    --account "$STARKNET_ACCOUNT" --private-key "$STARKNET_PRIVATE_KEY" \
    --rpc https://api.cartridge.gg/x/starknet/sepolia
```

## Development Conventions

*   **Cairo Version:** 2.11.4
*   **Framework:** Starknet
*   **Build Tool:** Scarb
*   **Testing Framework:** Starknet Foundry
*   **Code Formatting:** `scarb fmt`
*   **Dependencies:**
    *   `starknet`
    *   `openzeppelin_access`
    *   `openzeppelin_token`
    *   `openzeppelin_introspection`
    *   `openzeppelin_governance`
    *   `openzeppelin_utils`
*   **Architectural Patterns:** The contract leverages OpenZeppelin Cairo components for core NFT functionality, access control, and governance. The contract is designed to be fully on-chain, with both metadata and SVG artwork generated and stored on the blockchain.
*   **Testing Practices:** Tests are written using Starknet Foundry and are located in the `tests` directory. The tests use a forking setup from the Starknet mainnet to test against the real state of the original Golden Token contract.
