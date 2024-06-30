module game::pixel_pool {
    use sui::sui::SUI;
    use sui::coin::{Self, TreasuryCap, CoinMetadata};
    use sui::balance::{Self, Balance};
    use sui::url::{Self, Url};
    use sui::bag::{Self, Bag};
    use sui::table::{Self, Table};
    use sui::dynamic_field as df;
    use game::admin::AdminCap;
    use game::event;

    const E_INVALID_TOTAL_SUPPLY: u64 = 0;
    const E_INVALID_DECIMALS: u64 = 1;
    const E_INSUFFICIENT_LISTING_FEE: u64 = 2;

    public struct Pixel<phantom T> has key, store {
        id: UID,
        index: u64,
        image_url: Option<Url>,
        creator: address,
        is_destroy: bool,
        is_active: bool,
        sui_balance: Balance<SUI>,
        token_balance: Balance<T>,
        token_reserve: Balance<T>,
        buy_fee_rate: u64,
        sell_fee_rate: u64,
        target_supply_threshold: u64,
        virtual_sui_amount: u64,
    }

    public struct Pixel_Global has key {
        id: UID,
        target_supply_threshold: u64,
        virtual_sui_amount: u64,
        listing_fee: u64,
        buy_fee_rate: u64,
        sell_fee_rate: u64,
        fee: Balance<SUI>,
    }

    public struct Leader has store {
        index: u64,
        leader_address: address,
        be_leader_time: u64,
        balance: u64,
    }

    public struct Destroy_Pixel has store {
        epoch: u64,
        round: u64,
        source_index: u64,
        target_index: u64,
        source_address: address,
    }
    
    fun init(ctx: &mut TxContext) {
        let pixel_global = Pixel_Global {
            id: object::new(ctx),
            target_supply_threshold: 300000000000000000,
            virtual_sui_amount: 4200000000000,
            listing_fee: 1000000000,
            buy_fee_rate: 10000,
            sell_fee_rate: 10000,
            fee: balance::zero<SUI>(),
        };

        transfer::share_object(pixel_global);
    }

    public fun list<T>(
        pixel_global: &mut Pixel_Global,
        mut treasury_cap: TreasuryCap<T>,
        metadata: &CoinMetadata<T>,
        pay_coin: coin::Coin<SUI>,
        index: u64,
        ctx: &mut TxContext,
    ): Pixel<T> {
        assert!(coin::total_supply(&treasury_cap) == 0, E_INVALID_TOTAL_SUPPLY);
        assert!(coin::get_decimals(metadata) == 9, E_INVALID_DECIMALS);

        let mut coin_balance = coin::into_balance(pay_coin);
        assert!(balance::value(&coin_balance) == pixel_global.listing_fee, E_INSUFFICIENT_LISTING_FEE);

        balance::join(&mut pixel_global.fee, balance::split(&mut coin_balance, pixel_global.listing_fee));

        let image_url = coin::get_icon_url(metadata);
        
        let token_balance = coin::mint_balance<T>(&mut treasury_cap, 1_000_000_000_000_000_000);
        let token_reserve = coin::mint_balance<T>(&mut treasury_cap, 1_000_000_000_000_000);
        transfer::public_freeze_object(treasury_cap);

        let pixel = Pixel<T> {
            id: object::new(ctx),
            index,
            image_url: image_url,
            creator: tx_context::sender(ctx),
            is_destroy: false,
            is_active: true,
            sui_balance: coin_balance,
            token_balance: token_balance,
            token_reserve: token_reserve,
            buy_fee_rate: pixel_global.buy_fee_rate,
            sell_fee_rate: pixel_global.sell_fee_rate,
            target_supply_threshold:  pixel_global.target_supply_threshold,
            virtual_sui_amount: pixel_global.virtual_sui_amount,
        };

        df::add(&mut pixel_global.id, b"pixel_list", pixel);

        pixel
    }

    public fun update_buy_fee_rate(
        _: &AdminCap,
        pixel_global: &mut Pixel_Global,
        rate: u64
    ) {
        pixel_global.buy_fee_rate = rate;
    }

    public fun update_fee_sell(
        _: &AdminCap,
        pixel_global: &mut Pixel_Global,
        rate: u64
    ) {
        pixel_global.sell_fee_rate = rate;
    }

    public fun update_listing_fee(
        _: &AdminCap,
        pixel_global: &mut Pixel_Global,
        listing_fee: u64,
    ) {
        pixel_global.listing_fee = listing_fee
    }
}