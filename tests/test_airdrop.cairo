use core::serde::Serde;
use openzeppelin_token::erc721::interface::{
    IERC721Dispatcher, IERC721DispatcherTrait, IERC721MetadataDispatcher,
    IERC721MetadataDispatcherTrait,
};
use snforge_std::{ContractClassTrait, DeclareResultTrait, declare};
use starknet::ContractAddress;

// Test constants
const OWNER: felt252 = 'OWNER';

// Real mainnet golden token contract address
fn GOLDEN_TOKEN_MAINNET_ADDRESS() -> ContractAddress {
    contract_address_const::<0x04f5e296c805126637552cf3930e857f380e7c078e8f00696de4fc8545356b1d>()
}

// Deploy new golden token contract
fn deploy_golden_token() -> (IERC721Dispatcher, IERC721MetadataDispatcher) {
    let contract = declare("golden_token").unwrap().contract_class();
    let owner = contract_address_const::<OWNER>();
    let name: ByteArray = "Golden Token V2";
    let symbol: ByteArray = "GOLDENV2";
    let base_uri: ByteArray = "https://api.provablegames.com/golden_token/";
    let golden_token_address = GOLDEN_TOKEN_MAINNET_ADDRESS();
    let royalty_receiver = owner;
    let royalty_fraction: u128 = 500; // 5%

    let mut calldata = array![];
    name.serialize(ref calldata);
    symbol.serialize(ref calldata);
    base_uri.serialize(ref calldata);
    calldata.append(owner.into());
    calldata.append(golden_token_address.into());
    calldata.append(royalty_receiver.into());
    calldata.append(royalty_fraction.into());

    let (contract_address, _) = contract.deploy(@calldata).unwrap();
    (IERC721Dispatcher { contract_address }, IERC721MetadataDispatcher { contract_address })
}

#[test]
#[fork("mainnet")]
fn test_airdrop_all_160_tokens() {
    // Deploy the new golden token contract
    let (new_golden_token, new_golden_token_metadata) = deploy_golden_token();

    // Get the original golden token contract on mainnet
    let original_golden_token = IERC721Dispatcher {
        contract_address: GOLDEN_TOKEN_MAINNET_ADDRESS(),
    };

    // Verify ALL 160 tokens were airdropped with correct ownership
    let mut token_id: u256 = 1;

    loop {
        if token_id > 160 {
            break;
        }

        // Get owners from both contracts
        let original_owner = original_golden_token.owner_of(token_id);
        let new_owner = new_golden_token.owner_of(token_id);

        // Assert exact match - no tolerance for missing tokens
        assert(new_owner == original_owner, 'Token ownership mismatch');

        token_id += 1;
    }

    // Verify metadata is set correctly
    let name = new_golden_token_metadata.name();
    let symbol = new_golden_token_metadata.symbol();
    assert(name == "Golden Token V2", 'Wrong token name');
    assert(symbol == "GOLDENV2", 'Wrong token symbol');
}


#[test]
#[should_panic(expected: ('ERC721: invalid token ID',))]
#[fork("mainnet")]
fn test_token_161_does_not_exist() {
    // Deploy the new golden token contract
    let (new_golden_token, _) = deploy_golden_token();

    // This should panic as token 161 should not exist
    new_golden_token.owner_of(161);
}

#[test]
#[fork("mainnet")]
fn test_token_uri_generation() {
    // Deploy the new golden token contract
    let (_, new_golden_token_metadata) = deploy_golden_token();

    // Test token URI for just one token to avoid resource exhaustion
    let token_uri = new_golden_token_metadata.token_uri(1);

    // Verify URI is properly formatted
    assert(token_uri.len() > 100, 'Token URI too short');
}
