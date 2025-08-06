pub mod encoding;
pub mod svg;

#[starknet::contract]
pub mod golden_token {
    use openzeppelin_access::ownable::OwnableComponent;
    use openzeppelin_introspection::src5::SRC5Component;
    use openzeppelin_token::common::erc2981::ERC2981Component;
    use openzeppelin_token::erc721::interface::{
        IERC721Dispatcher, IERC721DispatcherTrait, IERC721Metadata,
    };
    use openzeppelin_token::erc721::{ERC721Component, ERC721HooksEmptyImpl};
    use starknet::ContractAddress;
    use super::encoding::bytes_base64_encode;
    use super::svg::SvgTrait;

    component!(path: OwnableComponent, storage: ownable, event: OwnableEvent);
    component!(path: ERC721Component, storage: erc721, event: ERC721Event);
    component!(path: SRC5Component, storage: src5, event: SRC5Event);
    component!(path: ERC2981Component, storage: erc2981, event: ERC2981Event);

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
    }

    /// Assigns `owner` as the contract owner.
    /// Sets the token `name` and `symbol`.
    /// Sets the base URI.
    /// Sets default royalty info.
    #[constructor]
    fn constructor(
        ref self: ContractState,
        name: ByteArray,
        symbol: ByteArray,
        base_uri: ByteArray,
        owner: ContractAddress,
        golden_token_address: ContractAddress,
        royalty_receiver: ContractAddress,
        royalty_fraction: u128,
    ) {
        self.ownable.initializer(owner);
        self.erc721.initializer(name, symbol, base_uri);
        self.erc2981.initializer(royalty_receiver, royalty_fraction);

        InternalTrait::airdrop_tokens(ref self, golden_token_address);
    }


    // Internal implementations
    #[generate_trait]
    impl InternalImpl of InternalTrait {
        /// Internal function to airdrop tokens during contract construction
        fn airdrop_tokens(ref self: ContractState, golden_token_address: ContractAddress) {
            let golden_token_dispatcher = IERC721Dispatcher {
                contract_address: golden_token_address,
            };

            let mut token_id = 1;
            while token_id <= 160 {
                let to = golden_token_dispatcher.owner_of(token_id);
                self.erc721.mint(to, token_id);
                token_id += 1;
            }
        }
    }

    // Custom ERC721Metadata Implementation
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
            json.append(@"One free game, every day, forever");
            json.append(@"\",");

            // Image
            json.append(@"\"image\":\"");
            json
                .append(
                    @format!(
                        "data:image/svg+xml;base64,{}",
                        bytes_base64_encode(SvgTrait::generate_svg()),
                    ),
                );

            // End of JSON
            json.append(@"\"}");

            format!("data:application/json;base64,{}", bytes_base64_encode(json))
        }
    }
}
