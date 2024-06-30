module template::template {
    use sui::coin;
    use sui::url::new_unsafe_from_bytes;

    public struct TEMPLATE has drop{}

    const DECIMALS: u8 = 9;
    const SYMBOL: vector<u8> = b"SYMBOL";
    // const NAME: vector<u8> = b"NAME";
    const DESCRIPTION: vector<u8> = b"DESCRIPTION";
    const ICON_URL: vector<u8> = b"ICON_URL";

    fun init (witness: TEMPLATE, ctx: &mut TxContext) {
        let (treasury_cap, metadata) = coin::create_currency(
            witness,
            DECIMALS,
            SYMBOL,
            SYMBOL,
            DESCRIPTION,
            option::some(new_unsafe_from_bytes(ICON_URL)),
            ctx
        );

        transfer::public_transfer(metadata, tx_context::sender(ctx));
        transfer::public_transfer(treasury_cap, tx_context::sender(ctx));
    }
}

