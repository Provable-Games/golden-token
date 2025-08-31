pub mod encoding;
pub mod svg;

#[starknet::interface]
pub trait IGoldenToken<T> {
    fn airdrop_tokens(ref self: T);
}

#[starknet::contract]
pub mod golden_token {
    use openzeppelin_access::ownable::OwnableComponent;
    use openzeppelin_governance::votes::VotesComponent;
    use openzeppelin_introspection::src5::SRC5Component;
    use openzeppelin_token::common::erc2981::ERC2981Component;
    use openzeppelin_token::erc721::ERC721Component;
    use openzeppelin_token::erc721::interface::{
        IERC721Dispatcher, IERC721DispatcherTrait, IERC721Metadata,
    };
    use openzeppelin_utils::cryptography::nonces::NoncesComponent;
    use openzeppelin_utils::cryptography::snip12::SNIP12Metadata;
    use starknet::ContractAddress;
    use starknet::storage::{StoragePointerReadAccess, StoragePointerWriteAccess};
    use super::encoding::bytes_base64_encode;
    use super::svg::SvgTrait;

    component!(path: OwnableComponent, storage: ownable, event: OwnableEvent);
    component!(path: ERC721Component, storage: erc721, event: ERC721Event);
    component!(path: SRC5Component, storage: src5, event: SRC5Event);
    component!(path: ERC2981Component, storage: erc2981, event: ERC2981Event);
    component!(path: VotesComponent, storage: erc721_votes, event: ERC721VotesEvent);
    component!(path: NoncesComponent, storage: nonces, event: NoncesEvent);

    // Ownable Mixin
    #[abi(embed_v0)]
    impl OwnableMixinImpl = OwnableComponent::OwnableMixinImpl<ContractState>;
    impl OwnableInternalImpl = OwnableComponent::InternalImpl<ContractState>;

    // ERC721 Implementation
    #[abi(embed_v0)]
    impl ERC721Impl = ERC721Component::ERC721Impl<ContractState>;
    #[abi(embed_v0)]
    impl ERC721CamelOnlyImpl = ERC721Component::ERC721CamelOnlyImpl<ContractState>;
    impl ERC721InternalImpl = ERC721Component::InternalImpl<ContractState>;

    // SRC5 Implementation
    #[abi(embed_v0)]
    impl SRC5Impl = SRC5Component::SRC5Impl<ContractState>;
    impl SRC5InternalImpl = SRC5Component::InternalImpl<ContractState>;

    // Votes Implementation
    #[abi(embed_v0)]
    impl VotesImpl = VotesComponent::VotesImpl<ContractState>;
    impl VotesInternalImpl = VotesComponent::InternalImpl<ContractState>;

    // Nonces
    #[abi(embed_v0)]
    impl NoncesImpl = NoncesComponent::NoncesImpl<ContractState>;
    impl NoncesInternalImpl = NoncesComponent::InternalImpl<ContractState>;

    // ERC2981 Implementation
    #[abi(embed_v0)]
    impl ERC2981Impl = ERC2981Component::ERC2981Impl<ContractState>;
    #[abi(embed_v0)]
    impl ERC2981AdminOwnableImpl =
        ERC2981Component::ERC2981AdminOwnableImpl<ContractState>;
    impl ERC2981InternalImpl = ERC2981Component::InternalImpl<ContractState>;
    impl ERC2981ImmutableConfig of ERC2981Component::ImmutableConfig {
        const FEE_DENOMINATOR: u128 = 10_000; // 10,000 = 100% (so 500 = 5%)
    }

    #[storage]
    pub struct Storage {
        #[substorage(v0)]
        pub ownable: OwnableComponent::Storage,
        #[substorage(v0)]
        pub erc721: ERC721Component::Storage,
        #[substorage(v0)]
        pub src5: SRC5Component::Storage,
        #[substorage(v0)]
        pub erc2981: ERC2981Component::Storage,
        #[substorage(v0)]
        pub erc721_votes: VotesComponent::Storage,
        #[substorage(v0)]
        pub nonces: NoncesComponent::Storage,
        pub golden_token_address: ContractAddress,
        pub airdrop_count: u8,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        #[flat]
        OwnableEvent: OwnableComponent::Event,
        #[flat]
        ERC721Event: ERC721Component::Event,
        #[flat]
        SRC5Event: SRC5Component::Event,
        #[flat]
        ERC2981Event: ERC2981Component::Event,
        #[flat]
        ERC721VotesEvent: VotesComponent::Event,
        #[flat]
        NoncesEvent: NoncesComponent::Event,
    }

    /// Required for hash computation.
    pub impl SNIP12MetadataImpl of SNIP12Metadata {
        fn name() -> felt252 {
            'Golden Token'
        }
        fn version() -> felt252 {
            '1.0.0'
        }
    }

    // We need to call the `transfer_voting_units` function after
    // every mint, burn and transfer.
    // For this, we use the `before_update` hook of the
    //`ERC721Component::ERC721HooksTrait`.
    // This hook is called before the transfer is executed.
    // This gives us access to the previous owner.
    impl ERC721VotesHooksImpl of ERC721Component::ERC721HooksTrait<ContractState> {
        fn before_update(
            ref self: ERC721Component::ComponentState<ContractState>,
            to: ContractAddress,
            token_id: u256,
            auth: ContractAddress,
        ) {
            let mut contract_state = self.get_contract_mut();

            // We use the internal function here since it does not check if the token
            // id exists which is necessary for mints
            let previous_owner = self._owner_of(token_id);
            contract_state.erc721_votes.transfer_voting_units(previous_owner, to, 1);
        }
    }

    /// Assigns `owner` as the contract owner.
    /// Sets the token `name` and `symbol`.
    /// Uses an empty base URI (fully onchain renderer).
    /// Sets default royalty info.
    #[constructor]
    fn constructor(
        ref self: ContractState,
        name: ByteArray,
        symbol: ByteArray,
        owner: ContractAddress,
        golden_token_address: ContractAddress,
        royalty_receiver: ContractAddress,
        royalty_fraction: u128,
    ) {
        self.ownable.initializer(owner);
        self.erc721.initializer(name, symbol, ""); // no BASE URI needed
        self.erc2981.initializer(royalty_receiver, royalty_fraction);

        self.golden_token_address.write(golden_token_address);
    }

    /// Airdrops 7 new tokens to each of the 160 Gen1 holders.
    /// This is done in 7 rounds, each round airdropping 160 tokens.
    /// This preserves the original token IDs.
    #[external(v0)]
    fn airdrop_tokens(ref self: ContractState) {
        self.ownable.assert_only_owner();

        let mut airdrop_count = self.airdrop_count.read();
        assert(airdrop_count < 7, 'Airdrop completed');

        let golden_token_dispatcher = IERC721Dispatcher {
            contract_address: self.golden_token_address.read(),
        };

        let golden_token_total: u16 = 160;
        let mut new_token_id: u16 = airdrop_count.into() * golden_token_total;

        let mut index = 0;
        while index < golden_token_total {
            index += 1;
            new_token_id += 1;

            let to = golden_token_dispatcher.owner_of(index.into());
            self.erc721.mint(to, new_token_id.into());
        }

        airdrop_count += 1;
        self.airdrop_count.write(airdrop_count);
    }

    #[abi(embed_v0)]
    impl ERC721Metadata of IERC721Metadata<ContractState> {
        fn name(self: @ContractState) -> ByteArray {
            self.erc721.name()
        }

        fn symbol(self: @ContractState) -> ByteArray {
            self.erc721.symbol()
        }

        fn token_uri(self: @ContractState, token_id: u256) -> ByteArray {
            self.erc721._require_owned(token_id);

            let mut json: ByteArray = "{";

            // Name
            json.append(@"\"name\":\"");
            json.append(@"Golden Token #");
            json.append(@format!("{}", token_id));
            json.append(@"\",");

            // Description
            json.append(@"\"description\":\"");
            json.append(SvgTrait::get_description());
            json.append(@"\",");

            // Image
            json.append(@"\"image\":\"");
            json
                .append(
                    @format!(
                        "data:image/svg+xml;base64,{}", bytes_base64_encode(SvgTrait::get_svg()),
                    ),
                );

            // End of JSON
            json.append(@"\"}");

            format!("data:application/json;base64,{}", bytes_base64_encode(json))
        }
    }
}
