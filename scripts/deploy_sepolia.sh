#!/bin/bash
set -e

source .env

# Validate required environment variables
if [ -z "$STARKNET_ACCOUNT" ] || [ -z "$STARKNET_PRIVATE_KEY" ]; then
    echo "Error: STARKNET_ACCOUNT and STARKNET_PRIVATE_KEY must be set in .env"
    exit 1
fi

# Build the project
echo "Building project..."
scarb build

# Check if contract file exists
CONTRACT_FILE="target/dev/golden_token_golden_token.contract_class.json"
if [ ! -f "$CONTRACT_FILE" ]; then
    echo "Error: Contract file not found at $CONTRACT_FILE"
    exit 1
fi
echo "Contract file found: $CONTRACT_FILE"

# Constructor parameters for golden_token contract
NAME="Golden Token"
SYMBOL="GOLDEN"
OWNER="0x0689701974d95364aAd9C2306Bc322A40a27fb775b0C97733FD0e36E900b1878"  # Contract owner address
GOLDEN_TOKEN_ADDRESS="0x04f5e296c805126637552cf3930e857f380e7c078e8f00696de4fc8545356b1d"  # Original golden token address to airdrop from
ROYALTY_RECEIVER="0x0689701974d95364aAd9C2306Bc322A40a27fb775b0C97733FD0e36E900b1878"  # Royalty receiver address
ROYALTY_FRACTION="500"  # 5% royalty (500/10000)


# Contract class declaration
echo "Starting contract declaration..."
DECLARE_OUTPUT=$(starkli declare --account "$STARKNET_ACCOUNT" --private-key "$STARKNET_PRIVATE_KEY" --rpc https://api.cartridge.gg/x/starknet/sepolia "$CONTRACT_FILE" 2>&1)
echo "Declare output: $DECLARE_OUTPUT"

CLASS_HASH=$(echo "$DECLARE_OUTPUT" | grep -oE "0x[0-9a-fA-F]+" | tail -1)

if [ -z "$CLASS_HASH" ]; then
    echo "Error: Failed to extract class hash"
    echo "Declare output: $DECLARE_OUTPUT"
    exit 1
fi

# Contract deployment
echo "Starting deployment..."
echo "Deploying with parameters:"
echo "  CLASS_HASH: $CLASS_HASH"
echo "  NAME: $NAME"
echo "  SYMBOL: $SYMBOL"
echo "  OWNER: $OWNER"
echo "  GOLDEN_TOKEN_ADDRESS: $GOLDEN_TOKEN_ADDRESS"
echo "  ROYALTY_RECEIVER: $ROYALTY_RECEIVER"
echo "  ROYALTY_FRACTION: $ROYALTY_FRACTION"
echo ""

# First check account balance
echo "Checking account balance..."
ACCOUNT_ADDRESS="0x418ed348930686c844fda4556173457d3f71ae547262406d271de534af6b35e"
BALANCE_OUTPUT=$(starkli call \
    --rpc https://api.cartridge.gg/x/starknet/sepolia \
    0x049d36570d4e46f48e99674bd3fcc84644ddd6b96f7c741b1562b82f9e004dc7 \
    balanceOf \
    $ACCOUNT_ADDRESS 2>&1 || echo "Balance check failed")
echo "Account balance check: $BALANCE_OUTPUT"
echo ""

# Deploy the contract
echo "Starting starkli deploy command..."
echo "Note: This may take a few minutes..."

# Run deployment without timeout to see what happens
starkli deploy \
    --account "$STARKNET_ACCOUNT" \
    --private-key "$STARKNET_PRIVATE_KEY" \
    --rpc https://api.cartridge.gg/x/starknet/sepolia \
    $CLASS_HASH \
    bytearray:str:"$NAME" \
    bytearray:str:"$SYMBOL" \
    $OWNER \
    $GOLDEN_TOKEN_ADDRESS \
    $ROYALTY_RECEIVER \
    $ROYALTY_FRACTION

DEPLOY_EXIT_CODE=$?

if [ $DEPLOY_EXIT_CODE -ne 0 ]; then
    echo "Error: Deployment failed with exit code $DEPLOY_EXIT_CODE"
    exit 1
fi

echo ""
echo "Deployment completed successfully!"
echo "Class Hash: $CLASS_HASH"
echo ""
echo "Note: The contract will automatically airdrop tokens to the first 160 holders of the original Golden Token NFT."
