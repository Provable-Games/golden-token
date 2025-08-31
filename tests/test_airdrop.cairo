use core::serde::Serde;
use golden_token::{IGoldenTokenDispatcher, IGoldenTokenDispatcherTrait};
use openzeppelin_token::erc721::interface::{
    IERC721Dispatcher, IERC721DispatcherTrait, IERC721MetadataDispatcher,
    IERC721MetadataDispatcherTrait,
};
use snforge_std::{ContractClassTrait, DeclareResultTrait, declare, start_cheat_caller_address};
use starknet::ContractAddress;

// Test constants
const OWNER: felt252 = 'OWNER';

// Real mainnet golden token contract address
fn GOLDEN_TOKEN_MAINNET_ADDRESS() -> ContractAddress {
    0x04f5e296c805126637552cf3930e857f380e7c078e8f00696de4fc8545356b1d.try_into().unwrap()
}

// Deploy new golden token contract
fn deploy_golden_token() -> (IERC721Dispatcher, IERC721MetadataDispatcher, IGoldenTokenDispatcher) {
    let contract = declare("golden_token").unwrap().contract_class();
    let owner: ContractAddress = OWNER.try_into().unwrap();
    let name: ByteArray = "Golden Token V2";
    let symbol: ByteArray = "GOLDENV2";
    let golden_token_address = GOLDEN_TOKEN_MAINNET_ADDRESS();
    let royalty_receiver = owner;
    let royalty_fraction: u128 = 500; // 5%

    let mut calldata = array![];
    name.serialize(ref calldata);
    symbol.serialize(ref calldata);
    calldata.append(owner.into());
    calldata.append(golden_token_address.into());
    calldata.append(royalty_receiver.into());
    calldata.append(royalty_fraction.into());

    let (contract_address, _) = contract.deploy(@calldata).unwrap();
    (
        IERC721Dispatcher { contract_address },
        IERC721MetadataDispatcher { contract_address },
        IGoldenTokenDispatcher { contract_address },
    )
}

#[test]
#[fork("mainnet")]
fn test_airdrop_two_rounds() {
    // Deploy the new golden token contract
    let (new_golden_token, new_golden_token_metadata, golden_token_dispatcher) =
        deploy_golden_token();
    let owner: ContractAddress = OWNER.try_into().unwrap();

    // Start cheat caller address to act as owner
    start_cheat_caller_address(golden_token_dispatcher.contract_address, owner);

    golden_token_dispatcher.airdrop_tokens();
    golden_token_dispatcher.airdrop_tokens();

    // Get the original golden token contract on mainnet
    let original_golden_token = IERC721Dispatcher {
        contract_address: GOLDEN_TOKEN_MAINNET_ADDRESS(),
    };

    let mut new_token_id: u256 = 1;
    let mut airdrop_rounds = 0;

    loop {
        if airdrop_rounds == 2 {
            break;
        }

        let mut legacy_token_id = 1;
        loop {
            if legacy_token_id > 160 {
                break;
            }
            let legacy_owner = original_golden_token.owner_of(legacy_token_id);
            let new_owner = new_golden_token.owner_of(new_token_id);
            assert(new_owner == legacy_owner, 'Token ownership mismatch');
            new_token_id += 1;
            legacy_token_id += 1;
        }
        airdrop_rounds += 1;
    }

    // Verify metadata is set correctly
    let name = new_golden_token_metadata.name();
    let symbol = new_golden_token_metadata.symbol();
    assert(name == "Golden Token V2", 'Wrong token name');
    assert(symbol == "GOLDENV2", 'Wrong token symbol');
}

#[test]
#[fork("mainnet")]
fn test_token_uri_generation() {
    // Deploy the new golden token contract
    let (_, new_golden_token_metadata, golden_token_dispatcher) = deploy_golden_token();
    let owner: ContractAddress = OWNER.try_into().unwrap();

    // Start cheat caller address to act as owner and airdrop some tokens
    start_cheat_caller_address(golden_token_dispatcher.contract_address, owner);
    golden_token_dispatcher.airdrop_tokens();

    // Test token URI for just one token to avoid resource exhaustion
    let token_uri = new_golden_token_metadata.token_uri(1);

    // Verify URI is properly formatted
    assert(token_uri.len() > 100, 'Token URI too short');
}
