// Simple Mock ERC721 contract for testing Golden Token v2
#[starknet::contract]
mod MockGoldenTokenV1 {
    use openzeppelin_introspection::src5::SRC5Component;
    use openzeppelin_token::erc721::{ERC721Component, ERC721HooksEmptyImpl};
    use starknet::storage::{StoragePointerReadAccess, StoragePointerWriteAccess};
    use starknet::{ContractAddress, get_caller_address};

    component!(path: ERC721Component, storage: erc721, event: ERC721Event);
    component!(path: SRC5Component, storage: src5, event: SRC5Event);

    // ERC721 Mixin
    #[abi(embed_v0)]
    impl ERC721MixinImpl = ERC721Component::ERC721MixinImpl<ContractState>;
    impl ERC721InternalImpl = ERC721Component::InternalImpl<ContractState>;

    #[storage]
    struct Storage {
        #[substorage(v0)]
        erc721: ERC721Component::Storage,
        #[substorage(v0)]
        src5: SRC5Component::Storage,
        next_token_id: u256,
        owner: ContractAddress,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        #[flat]
        ERC721Event: ERC721Component::Event,
        #[flat]
        SRC5Event: SRC5Component::Event,
    }

    #[constructor]
    fn constructor(
        ref self: ContractState, name: ByteArray, symbol: ByteArray, owner: ContractAddress,
    ) {
        self.erc721.initializer(name, symbol, "");
        self.owner.write(owner);
        self.next_token_id.write(1);
    }

    #[external(v0)]
    fn mint_batch(ref self: ContractState, to: ContractAddress, amount: u256) {
        // Only owner can mint
        assert(get_caller_address() == self.owner.read(), 'Only owner can mint');

        let mut current_id = self.next_token_id.read();
        let end_id = current_id + amount;

        loop {
            if current_id >= end_id {
                break;
            }

            self.erc721.mint(to, current_id);
            current_id += 1;
        }

        self.next_token_id.write(end_id);
    }

    #[external(v0)]
    fn get_owner(self: @ContractState) -> ContractAddress {
        self.owner.read()
    }
}
