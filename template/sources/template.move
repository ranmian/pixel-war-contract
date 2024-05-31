module template::template {
    use sui::coin;
    use sui::url::new_unsafe_from_bytes;

    public struct TEMPLATE has drop{}

    const DECIMALS: u8 = 6;
    const SYMBOL: vector<u8> = b"SYMBOL";
    const NAME: vector<u8> = b"NAME";
    const DESCRIPTION: vector<u8> = b"DESCRIPTION";
    const ICON_URL: vector<u8> = b"ICON_URL";
    const TREASURY_RECIPIENT: address = @0x0;

    fun init (witness: TEMPLATE, ctx: &mut TxContext) {
        let (mut treasury_cap, metadata) = coin::create_currency(
            witness,
            DECIMALS,
            SYMBOL,
            NAME,
            DESCRIPTION,
            option::some(new_unsafe_from_bytes(ICON_URL)),
            ctx
        );

        // coin::mint_and_transfer(&mut treasury_cap, 1_000_000_000_000_000_000, TREASURY_RECIPIENT, ctx);
        transfer::public_freeze_object(metadata);
        transfer::public_transfer(treasury_cap, tx_context::sender(ctx));
    }
}

