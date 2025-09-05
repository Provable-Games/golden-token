#!/bin/bash
set -e

# Check if .env file exists
if [ ! -f ".env" ]; then
    echo "Error: .env file not found. Please copy .env.example to .env and fill in your credentials."
    exit 1
fi

# Source environment variables
source .env

# Validate authentication method - must have either keystore or private key
if [ -z "$STARKNET_KEYSTORE" ] && [ -z "$STARKNET_PRIVATE_KEY" ]; then
    echo "Error: Authentication method not configured."
    echo "You must provide either:"
    echo "  - STARKNET_KEYSTORE: Path to your keystore JSON file"
    echo "  - STARKNET_PRIVATE_KEY: Your raw private key"
    echo ""
    echo "For better security, use a keystore instead of a raw private key."
    exit 1
fi

# Validate required environment variables based on network
if [ -z "$STARKNET_ACCOUNT" ] || [ -z "$NETWORK" ] || [ -z "$STARKNET_RPC" ] || [ -z "$OWNER" ] || [ -z "$ROYALTY_RECEIVER" ] || [ -z "$ROYALTY_FRACTION" ]; then
    echo "Error: Required environment variables are missing."
    echo "The following must be set in .env:"
    echo "  - STARKNET_ACCOUNT: Your Starknet account address or path to account JSON file"
    echo "  - NETWORK: Either 'sepolia' or 'mainnet'"
    echo "  - STARKNET_RPC: RPC endpoint URL for the network"
    echo "  - OWNER: Contract owner address"
    echo "  - ROYALTY_RECEIVER: Royalty receiver address"
    echo "  - ROYALTY_FRACTION: Royalty percentage as basis points (e.g., 500 for 5%)"
    echo ""
    echo "Plus one of these authentication methods:"
    echo "  - STARKNET_KEYSTORE: Path to keystore file (recommended)"
    echo "  - STARKNET_PRIVATE_KEY: Raw private key"
    echo ""
    echo "Please copy .env.example to .env and fill in all required values."
    exit 1
fi

# Set up authentication parameters
if [ -n "$STARKNET_KEYSTORE" ]; then
    echo "Using keystore authentication: $STARKNET_KEYSTORE"
    AUTH_PARAM="--keystore $STARKNET_KEYSTORE"
    # Check if keystore password is provided via environment
    if [ -n "$STARKNET_KEYSTORE_PASSWORD" ]; then
        export STARKNET_KEYSTORE_PASSWORD
    fi
else
    echo "Using private key authentication"
    AUTH_PARAM="--private-key $STARKNET_PRIVATE_KEY"
fi

# Validate NETWORK value
if [ "$NETWORK" != "sepolia" ] && [ "$NETWORK" != "mainnet" ]; then
    echo "Error: NETWORK must be either 'sepolia' or 'mainnet'"
    exit 1
fi

echo "========================================="
echo "Deploying to: $NETWORK"
echo "========================================="
echo ""

# Set network-specific configurations
if [ "$NETWORK" = "mainnet" ]; then
    # Mainnet requires V1_GOLDEN_TOKEN_ADDRESS to be set
    if [ -z "$V1_GOLDEN_TOKEN_ADDRESS" ]; then
        echo "Error: V1_GOLDEN_TOKEN_ADDRESS must be set in .env for mainnet deployment"
        echo "This should be the address of the original Golden Token V1 contract on mainnet"
        exit 1
    fi
    GOLDEN_TOKEN_ADDRESS="$V1_GOLDEN_TOKEN_ADDRESS"
    
    # Mainnet confirmation
    echo "WARNING: This is a MAINNET deployment with real assets!"
    echo "Please confirm you want to proceed."
    read -p "Type 'yes' to continue: " confirmation
    if [ "$confirmation" != "yes" ]; then
        echo "Deployment cancelled."
        exit 1
    fi
else
    # Sepolia configurations - golden token address will be set after deploying mock
    
    # Check if account is a file path or address for Sepolia
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
fi

echo "Using RPC: $STARKNET_RPC"

# Build the project
echo "Building project..."
scarb build

# Check if contract files exist
MAIN_CONTRACT_FILE="target/dev/golden_token_golden_token.contract_class.json"
if [ ! -f "$MAIN_CONTRACT_FILE" ]; then
    echo "Error: Main contract file not found at $MAIN_CONTRACT_FILE"
    exit 1
fi
echo "Main contract file found: $MAIN_CONTRACT_FILE"

# Deploy Mock V1 Golden Token for Sepolia only
if [ "$NETWORK" = "sepolia" ]; then
    MOCK_CONTRACT_FILE="target/dev/golden_token_MockGoldenTokenV1.contract_class.json"
    if [ ! -f "$MOCK_CONTRACT_FILE" ]; then
        echo "Error: Mock contract file not found at $MOCK_CONTRACT_FILE"
        exit 1
    fi
    echo "Mock contract file found: $MOCK_CONTRACT_FILE"
    
    echo ""
    echo "========================================="
    echo "Step 1: Deploying Mock V1 Golden Token"
    echo "========================================="
    
    # Declare mock contract
    echo "Declaring mock contract..."
    echo "Using account: $ACCOUNT_FILE"
    export STARKLI_NO_PLAIN_KEY_WARNING=true
    MOCK_DECLARE_OUTPUT=$(starkli declare --account "$ACCOUNT_FILE" $AUTH_PARAM --rpc "$STARKNET_RPC" "$MOCK_CONTRACT_FILE" 2>&1)
    echo "Mock declare output: $MOCK_DECLARE_OUTPUT"
    
    MOCK_CLASS_HASH=$(echo "$MOCK_DECLARE_OUTPUT" | grep -oE "0x[0-9a-fA-F]+" | tail -1)
    
    if [ -z "$MOCK_CLASS_HASH" ]; then
        echo "Error: Failed to extract mock class hash"
        echo "Declare output: $MOCK_DECLARE_OUTPUT"
        exit 1
    fi
    
    echo "Mock class hash: $MOCK_CLASS_HASH"
    
    # Deploy mock contract - using the account from env as owner for minting
    echo "Deploying mock contract..."
    MOCK_OWNER=$(starkli account address --account "$ACCOUNT_FILE" 2>/dev/null || echo "$STARKNET_ACCOUNT")
    MOCK_DEPLOY_OUTPUT=$(starkli deploy \
        --account "$ACCOUNT_FILE" \
        $AUTH_PARAM \
        --rpc "$STARKNET_RPC" \
        $MOCK_CLASS_HASH \
        bytearray:str:"Golden Token V1" \
        bytearray:str:"GOLDENV1" \
        "$MOCK_OWNER" 2>&1)
    
    echo "Mock deploy output: $MOCK_DEPLOY_OUTPUT"
    
    # Extract mock contract address
    GOLDEN_TOKEN_ADDRESS=$(echo "$MOCK_DEPLOY_OUTPUT" | grep -oE "0x[0-9a-fA-F]+" | tail -1)
    
    if [ -z "$GOLDEN_TOKEN_ADDRESS" ]; then
        echo "Error: Failed to extract mock contract address"
        echo "Deploy output: $MOCK_DEPLOY_OUTPUT"
        exit 1
    fi
    
    echo "Mock V1 contract deployed at: $GOLDEN_TOKEN_ADDRESS"
    
    # Wait for deployment to be confirmed
    echo "Waiting for mock contract deployment to be confirmed..."
    sleep 10
    
    # Mint test tokens to the mock contract owner
    echo "Minting 160 test tokens..."
    MINT_OUTPUT=$(starkli invoke --watch \
        --account "$ACCOUNT_FILE" \
        $AUTH_PARAM \
        --rpc "$STARKNET_RPC" \
        $GOLDEN_TOKEN_ADDRESS \
        mint_batch \
        "$MOCK_OWNER" \
        u256:160 2>&1)
    
    echo "Mint output: $MINT_OUTPUT"
    echo "Test tokens minted successfully"
    
    echo ""
    echo "========================================="
    echo "Step 2: Deploying Golden Token V2"
    echo "========================================="
fi

# Constructor parameters for golden_token contract
NAME="Golden Token"
SYMBOL="GOLDEN"
# ROYALTY_FRACTION is required and already validated above

# Contract class declaration
echo "Starting main contract declaration..."

# Set account parameter based on network
if [ "$NETWORK" = "mainnet" ]; then
    ACCOUNT_PARAM="--account $STARKNET_ACCOUNT"
    DECLARE_CMD="starkli declare $ACCOUNT_PARAM $AUTH_PARAM --rpc \"$STARKNET_RPC\" \"$MAIN_CONTRACT_FILE\""
else
    ACCOUNT_PARAM="--account $ACCOUNT_FILE"
    DECLARE_CMD="starkli declare --watch $ACCOUNT_PARAM $AUTH_PARAM --rpc \"$STARKNET_RPC\" \"$MAIN_CONTRACT_FILE\""
fi

DECLARE_OUTPUT=$(eval $DECLARE_CMD 2>&1)
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
if [ "$NETWORK" = "sepolia" ]; then
    echo "  GOLDEN_TOKEN_ADDRESS: $GOLDEN_TOKEN_ADDRESS (Mock V1)"
else
    echo "  GOLDEN_TOKEN_ADDRESS: $GOLDEN_TOKEN_ADDRESS"
fi
echo "  ROYALTY_RECEIVER: $ROYALTY_RECEIVER"
echo "  ROYALTY_FRACTION: $ROYALTY_FRACTION"
echo ""

# Deploy the contract
echo "Starting starkli deploy command..."
echo "Note: This may take a few minutes..."

if [ "$NETWORK" = "mainnet" ]; then
    starkli deploy \
        $ACCOUNT_PARAM \
        $AUTH_PARAM \
        --rpc "$STARKNET_RPC" \
        $CLASS_HASH \
        bytearray:str:"$NAME" \
        bytearray:str:"$SYMBOL" \
        $OWNER \
        $GOLDEN_TOKEN_ADDRESS \
        $ROYALTY_RECEIVER \
        $ROYALTY_FRACTION
else
    DEPLOY_OUTPUT=$(starkli deploy \
        $ACCOUNT_PARAM \
        $AUTH_PARAM \
        --rpc "$STARKNET_RPC" \
        $CLASS_HASH \
        bytearray:str:"$NAME" \
        bytearray:str:"$SYMBOL" \
        $OWNER \
        $GOLDEN_TOKEN_ADDRESS \
        $ROYALTY_RECEIVER \
        $ROYALTY_FRACTION 2>&1)
fi

DEPLOY_EXIT_CODE=$?

echo "Deploy output: $DEPLOY_OUTPUT"

if [ $DEPLOY_EXIT_CODE -ne 0 ]; then
    echo "Error: Deployment failed with exit code $DEPLOY_EXIT_CODE"
    exit 1
fi

# Extract deployed contract address
V2_CONTRACT_ADDRESS=$(echo "$DEPLOY_OUTPUT" | grep -oE "0x[0-9a-fA-F]+" | tail -1)

echo ""
echo "========================================="
echo "Deployment Summary"
echo "========================================="
if [ "$NETWORK" = "sepolia" ]; then
    echo "Network: Sepolia Testnet"
    echo "Mock V1 Contract: $GOLDEN_TOKEN_ADDRESS"
else
    echo "Network: Mainnet"
fi
echo "Golden Token V2 Contract: $V2_CONTRACT_ADDRESS"
echo "V2 Class Hash: $CLASS_HASH"
echo ""

if [ "$NETWORK" = "mainnet" ]; then
    echo "Note: The contract will automatically airdrop tokens to the first 160 holders of the original Golden Token NFT."
    echo "IMPORTANT: This is deployed on MAINNET with real assets!"
else
    echo "Note: The V2 contract will automatically airdrop tokens to the first 160 holders of the mock V1 Golden Token NFT."
    echo "The owner can trigger the airdrop by calling the airdrop_tokens function."
fi