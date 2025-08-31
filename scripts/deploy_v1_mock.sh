#!/bin/bash
set -e

# Check if .env file exists
if [ ! -f ".env" ]; then
    echo "Error: .env file not found. Please copy .env.example to .env and fill in your credentials."
    exit 1
fi

# Source environment variables
source .env

# Validate required environment variables
if [ -z "$STARKNET_ACCOUNT" ] || [ -z "$STARKNET_PRIVATE_KEY" ] || [ -z "$STARKNET_RPC" ]; then
    echo "Error: Required environment variables are missing."
    echo "The following must be set in .env:"
    echo "  - STARKNET_ACCOUNT: Your Starknet account address or path to account JSON file"
    echo "  - STARKNET_PRIVATE_KEY: Your account's private key"
    echo "  - STARKNET_RPC: RPC endpoint URL for the network"
    echo ""
    echo "Please copy .env.example to .env and fill in all required values."
    exit 1
fi

# Check if account is a file path or address
if [[ "$STARKNET_ACCOUNT" == 0x* ]]; then
    # It's an address, use the sepolia_account.json file
    ACCOUNT_FILE="sepolia_account.json"
    if [ ! -f "$ACCOUNT_FILE" ]; then
        echo "Error: Account file $ACCOUNT_FILE not found"
        exit 1
    fi
else
    # It's a file path
    ACCOUNT_FILE="$STARKNET_ACCOUNT"
fi

# RPC endpoint is required and already validated above

# Mock V1 contract class hash (already declared)
MOCK_CLASS_HASH="0x03c31af628a62197c1e63457712cb46481d65a0a5cb61de0a875f6f6dacf2a40"

# Get the account address for owner
MOCK_OWNER=$(starkli account address --account "$ACCOUNT_FILE" 2>/dev/null || echo "$STARKNET_ACCOUNT")

echo "========================================="
echo "Deploying Mock V1 Golden Token"
echo "========================================="
echo "Using account: $ACCOUNT_FILE"
echo "Using RPC: $STARKNET_RPC"
echo "Mock owner: $MOCK_OWNER"
echo ""

export STARKLI_NO_PLAIN_KEY_WARNING=true

# Deploy mock contract
echo "Deploying mock contract..."
starkli deploy \
    --account "$ACCOUNT_FILE" \
    --private-key "$STARKNET_PRIVATE_KEY" \
    --rpc "$STARKNET_RPC" \
    $MOCK_CLASS_HASH \
    bytearray:str:"Golden Token V1" \
    bytearray:str:"GOLDENV1" \
    "$MOCK_OWNER"

echo ""
echo "Mock V1 Golden Token deployed successfully!"
echo "Note: You may want to mint tokens to this contract for testing."
