#[allow(unused_field)]
module game::pixel {
    use std::ascii::into_bytes;
    use std::string::{Self, String};
    use std::type_name::{get, into_string};
    use sui::coin::{Self, Coin};
    use sui::balance::{Self, Balance};
    use sui::clock::{Self, Clock};
    use sui::url;
    use sui::table::{Self, Table};
    use sui::bag::{Self, Bag};
    use game::admin::AdminCap;
    use game::math256;
    use game::event;

    const E_INIT_SUPPLY_VALUE: u64 = 0;
    const E_PIXEL_HAS_EXIST: u64 = 1;
    const E_PIXEL_NOT_EXIST: u64 = 2;
    const E_LEADER_NOT_EXIST: u64 = 3;
    const E_YOU_ARE_NOT_LEADER: u64 = 4;
    const E_INVALID_SWAP_AMOUNT: u64 = 5;
    const E_INSUFFICIENT_SWAP_COIN_VALUE: u64 = 6;
    const E_INVALID_FEE_RATE_VALUE: u64 = 7;

    // const U64_MAX: u64 = 18446744073709551615;
    const COIN_SUPPLY_VALUE: u64 = 1_000_000_000_000_000_000;
    const COIN_RESERVE_RATE_VALUE: u64 = 1;
    const COIN_RESERVE_RATE_SIZE: u64 = 100;
    const FEE_BUY_RATE_VALUE: u64 = 250;
    const FEE_SELL_RATE_VALUE: u64 = 250;
    const FEE_MAX_VALUE: u64 = 1000;
    const FEE_RATE_SIZE: u64 = 10000;
    const PRICE_CONSTANT_RATE_VALUE: u64 = 36;
    const PRICE_CONSTANT_RATE_SIZE: u64 = 10000;

    public struct Pixel<phantom X, phantom Y> has store {
        global: ID,
        index: u64,
        name: String,
        image_url: Option<url::Url>,
        is_destroy: bool,
        leader: Option<Leader<X>>,
        destroy_info: Option<Destroy_Info>,
        balance_x: Balance<X>,
        balance_y: Balance<Y>,
        balance_reserve: Balance<X>,
        balance_fee_buy: Balance<Y>,
        balance_fee_sell: Balance<Y>,
        amount_x_buy: u64,
        amount_x_sell: u64,
        amount_y_buy: u64,
        amount_y_sell: u64,
    }

    public struct Leader<phantom X> has store {
        leader_address: address,
        be_leader_time: u64,
        balance: Balance<X>,
    }

    public struct Destroy_Info has store {
        epoch: u64,
        round: u64,
        source_index: u64,
        target_index: u64,
        source_address: address,
        is_source_leader: bool,
    }

    public struct Pixel_Global has key {
        id: UID,
        fee_rate_buy: u64,
        fee_rate_sell: u64,
        pixel_list: Bag,
        destroy_info_list: Table<u64, Destroy_Info>,
    }

    public struct SwapAmount has copy, store, drop {
        amount_x: u64,
        amount_y: u64,
        fee_buy: u64,
        fee_sell: u64,
    }

    fun init(ctx: &mut tx_context::TxContext) {
        let pixel_global = Pixel_Global {
            id: object::new(ctx),
            fee_rate_buy: FEE_BUY_RATE_VALUE,
            fee_rate_sell: FEE_SELL_RATE_VALUE,
            pixel_list: bag::new(ctx),
            destroy_info_list: table::new(ctx),
        };

        transfer::share_object(pixel_global);
    }
    
    public fun new<X, Y>(
        pixel_global: &mut Pixel_Global,
        mut treasury_cap: coin::TreasuryCap<X>,
        index: u64, 
        image_url: vector<u8>,
        clock: &Clock,
        ctx: &mut tx_context::TxContext
    ) {
        assert!(coin::total_supply<X>(&treasury_cap) == 0, E_INIT_SUPPLY_VALUE);

        let coin_reserve_value = COIN_SUPPLY_VALUE * COIN_RESERVE_RATE_VALUE / COIN_RESERVE_RATE_SIZE;
        let balance_pool = balance::increase_supply<X>(coin::supply_mut<X>(&mut treasury_cap), COIN_SUPPLY_VALUE);
        let balance_reserve = balance::increase_supply<X>(coin::supply_mut<X>(&mut treasury_cap),  coin_reserve_value);

        transfer::public_transfer(treasury_cap, @0x0);

        let leader = Leader<X> {
            leader_address: tx_context::sender(ctx),
            be_leader_time: clock::timestamp_ms(clock),
            balance: balance::zero<X>(),
        };

        let global = object::uid_to_inner(&pixel_global.id);
        let pixel_name = pixel_name<X>();
        let pixel_image_url = option::some(url::new_unsafe_from_bytes(image_url));

        let pixel = Pixel<X, Y> {
            global,
            index: index,
            name: pixel_name,
            image_url: pixel_image_url,
            is_destroy: false,
            leader: option::some(leader),
            destroy_info: option::none(),
            balance_x: balance_pool,
            balance_y: balance::zero<Y>(),
            balance_reserve: balance_reserve,
            balance_fee_buy: balance::zero<Y>(),
            balance_fee_sell: balance::zero<Y>(),
            amount_x_buy: 0,
            amount_x_sell: 0,
            amount_y_buy: 0,
            amount_y_sell: 0,
        };

        let is_pixel_exist = is_pixel_exist<X, Y>(pixel_global, index);
        assert!(!is_pixel_exist, E_PIXEL_HAS_EXIST);

        bag::add(&mut pixel_global.pixel_list, index, pixel);

        event::new_pixel_event(
            global, 
            index,
            pixel_name, 
            pixel_image_url
        )
    }

    public entry fun buy<X, Y>(
        pixel_global: &mut Pixel_Global,
        index: u64,
        coin: &mut Coin<Y>,
        amount: u64,
        ctx: &mut tx_context::TxContext
    ) {
        assert!(amount > 0, E_INVALID_SWAP_AMOUNT);
        
        let coin_value = coin::value(coin);
        assert!(coin_value >= amount, E_INSUFFICIENT_SWAP_COIN_VALUE);

        let fee_rate = pixel_global.fee_rate_buy;
        let pixel = get_mut_pixel<X,Y>(pixel_global, index);
        let swap_amount = buy_amount<X,Y>(
            pixel,
            amount, 
            fee_rate
        );
        
        let split_balance_x = if (swap_amount.amount_x > 0) {
            balance::split(&mut pixel.balance_x, swap_amount.amount_x)
        } else {
            balance::zero()
        };

        balance::join(
            &mut pixel.balance_y, 
            coin::into_balance<Y>(coin::split(coin, amount, ctx))
        );

        if (swap_amount.fee_buy > 0) {
            balance::join(
                &mut pixel.balance_fee_buy,
                coin::into_balance<Y>(coin::split(coin, swap_amount.fee_buy, ctx))
            );
        };

        pixel.amount_x_buy = pixel.amount_x_buy + swap_amount.amount_x;
        pixel.amount_y_buy = pixel.amount_y_buy + amount;

        let sender = tx_context::sender(ctx);
        transfer::public_transfer(
            coin::from_balance(split_balance_x, ctx),
            sender
        );

        event::swap_event(
            pixel.index,
            pixel.name,
            true,
            swap_amount.amount_x,
            swap_amount.amount_y,
            swap_amount.fee_buy
        )
    }

    public entry fun sell<X, Y>(
        pixel_global: &mut Pixel_Global,
        index: u64,
        coin: &mut Coin<X>,
        amount: u64,
        ctx: &mut tx_context::TxContext
    ) {
        assert!(amount > 0, E_INVALID_SWAP_AMOUNT);
        
        let coin_value = coin::value(coin);
        assert!(coin_value >= amount, E_INSUFFICIENT_SWAP_COIN_VALUE);

        let fee_rate = pixel_global.fee_rate_sell;
        let pixel = get_mut_pixel<X,Y>(pixel_global, index);
        let swap_amount = sell_amount<X, Y>(
            pixel,
            amount, 
            fee_rate
        );
        
        let split_balance_y = if (swap_amount.amount_x > 0) {
            balance::split<Y>(&mut pixel.balance_y, swap_amount.amount_y)
        } else {
            balance::zero()
        };

        balance::join(
            &mut pixel.balance_x, 
            coin::into_balance<X>(coin::split(coin, amount, ctx))
        );

        if (swap_amount.fee_sell > 0) {
            balance::join(
                &mut pixel.balance_fee_sell,
                balance::split<Y>(&mut pixel.balance_y, swap_amount.fee_sell)
            );
        };

        pixel.amount_x_sell = pixel.amount_x_sell + amount;
        pixel.amount_y_sell = pixel.amount_y_sell + swap_amount.amount_y;

        let sender = tx_context::sender(ctx);
        transfer::public_transfer(
            coin::from_balance(split_balance_y, ctx),
            sender
        );

        event::swap_event(
            pixel.index,
            pixel.name,
            false,
            swap_amount.amount_x,
            swap_amount.amount_y,
            swap_amount.fee_sell
        )
    }

    public fun quote_buy_amount<X, Y>(
        pixel_global: &mut Pixel_Global,
        index: u64,
        amount: u64,
    ): u64 {
        assert!(amount > 0, E_INVALID_SWAP_AMOUNT);

        let fee_rate = pixel_global.fee_rate_buy;
        let pixel = get_mut_pixel<X,Y>(pixel_global, index);
        let swap_amount = buy_amount<X,Y>(
            pixel,
            amount, 
            fee_rate
        );

        swap_amount.amount_x
    }

    public fun quote_sell_amount<X, Y>(
        pixel_global: &mut Pixel_Global,
        index: u64,
        amount: u64,
    ): u64 {
        assert!(amount > 0, E_INVALID_SWAP_AMOUNT);

        let fee_rate = pixel_global.fee_rate_sell;
        let pixel = get_mut_pixel<X,Y>(pixel_global, index);
        let swap_amount = sell_amount<X, Y>(
            pixel,
            amount, 
            fee_rate
        );

        swap_amount.amount_y
    }

    public fun be_leader<X, Y>(
        pixel_global: &mut Pixel_Global,
        index: u64,
        coin: Coin<X>, 
        clock: &Clock,
        ctx: &mut tx_context::TxContext
    ) {
        let sender = tx_context::sender(ctx);
        let current_time = clock::timestamp_ms(clock);

        let pixel = get_mut_pixel<X,Y>(pixel_global, index);
        let mut _new_balance_value = coin::value(&coin);

        if (option::is_some(&pixel.leader)) {
            let leader = option::borrow_mut<Leader<X>>(&mut pixel.leader);
            let balance_value = balance::value(&leader.balance);
            if (leader.leader_address == sender) {
                _new_balance_value = _new_balance_value + balance_value;
                balance::join(&mut leader.balance, coin::into_balance<X>(coin));
                return
            } else {
                transfer::public_transfer(
                    coin::take(&mut leader.balance, balance_value, ctx),
                    leader.leader_address
                );
            };
        };

        let new_leader = Leader<X> {
            leader_address: sender,
            be_leader_time: current_time,
            balance: coin::into_balance<X>(coin),
        };
        option::fill(&mut pixel.leader, new_leader);

        event::be_leader_event(
            pixel.index,
            pixel.name,
            sender,
            current_time,
            _new_balance_value,
        )
    }

    public fun lose_leader<X, Y> (
        pixel_global: &mut Pixel_Global,
        index: u64,
        ctx: &mut tx_context::TxContext
    ) {
        let pixel = get_mut_pixel<X,Y>(pixel_global, index);

        assert!(option::is_some(&pixel.leader), E_LEADER_NOT_EXIST);
        
        let sender = tx_context::sender(ctx);
        let leader = option::borrow_mut<Leader<X>>(&mut pixel.leader);
        assert!(leader.leader_address == sender, E_YOU_ARE_NOT_LEADER);

        let balance_value = balance::value(&leader.balance);
        transfer::public_transfer(
            coin::take(&mut leader.balance, balance_value, ctx),
            leader.leader_address
        );

        event::lose_leader_event(
            pixel.index,
            pixel.name,
            sender
        )
    }

    public fun update_fee_buy(
        _: &AdminCap,
        pixel_global: &mut Pixel_Global,
        fee: u64
    ) {
        assert!(fee <= FEE_MAX_VALUE, E_INVALID_FEE_RATE_VALUE);
        pixel_global.fee_rate_buy = fee;
    }

    public fun update_fee_sell(
        _: &AdminCap,
        pixel_global: &mut Pixel_Global,
        fee: u64
    ) {
        assert!(fee <= FEE_MAX_VALUE, E_INVALID_FEE_RATE_VALUE);
        pixel_global.fee_rate_sell = fee;
    }

    fun is_pixel_exist<X, Y>(
        pixel_global: &Pixel_Global,
        index: u64,
    ): bool {
        bag::contains_with_type<u64, Pixel<X, Y>>(&pixel_global.pixel_list, index)
    }

    fun buy_amount<X, Y>(
        pixel: &Pixel<X, Y>,
        swap_amount: u64,
        fee_rate: u64,
    ): SwapAmount {
        let (pool_x_amount, _) = balances(pixel);

        let (_, fee_buy) = math256::try_mul_div_down(
            swap_amount as u256,
            fee_rate as u256,
            FEE_RATE_SIZE as u256
        );

        let (_, real_amount) = math256::try_sub(swap_amount as u256, fee_buy);

        let amount_x = if (pool_x_amount == 0) {
            let (_, value) = math256::try_mul_div_down(
                real_amount,
                PRICE_CONSTANT_RATE_SIZE as u256,
                PRICE_CONSTANT_RATE_VALUE as u256,
            );
            value as u64
        } else {
            let sqrt_value = math256::sqrt_down(pool_x_amount as u256);
            let (_, mul_value) = math256::try_mul(PRICE_CONSTANT_RATE_VALUE as u256, sqrt_value);
            let (_, value) = math256::try_mul_div_down(
                real_amount, 
                PRICE_CONSTANT_RATE_SIZE as u256,
                mul_value,
            );
            value as u64
        };

        SwapAmount {
            amount_x: amount_x,
            amount_y: swap_amount,
            fee_buy: fee_buy as u64,
            fee_sell: 0,
        } 
    }
    
    fun sell_amount<X, Y>(
        pixel: &Pixel<X, Y>,
        swap_amount: u64,
        fee_rate: u64,
    ): SwapAmount {
        let (pool_x_amount, _) = balances(pixel);

        let (_, fee_sell) = math256::try_mul_div_down(
            swap_amount as u256,
            fee_rate as u256,
            FEE_RATE_SIZE as u256
        );

        let (_, real_amount) = math256::try_sub(swap_amount as u256, fee_sell);

        let amount_y = if (pool_x_amount == 0) {
            let (_, value) = math256::try_mul_div_down(
                real_amount,
                PRICE_CONSTANT_RATE_VALUE as u256,
                PRICE_CONSTANT_RATE_SIZE as u256
            );
            value as u64
        } else {
            let sqrt_value = math256::sqrt_down(pool_x_amount as u256);
            let (_, mul_value) = math256::try_mul(real_amount, sqrt_value);
            let (_, value) = math256::try_mul_div_down(
                mul_value, 
                PRICE_CONSTANT_RATE_VALUE as u256, 
                PRICE_CONSTANT_RATE_SIZE as u256
            );
            value as u64
        };
        
        SwapAmount {
            amount_x: swap_amount,
            amount_y: amount_y,
            fee_buy: 0,
            fee_sell: fee_sell as u64,
        } 
    }

    fun balances<X,Y>(pixel: &Pixel<X, Y>): (u64, u64) {
        (
            balance::value<X>(&pixel.balance_x), 
            balance::value<Y>(&pixel.balance_y)
        )
    }

    fun pixel_name<X>(): String {
        string::utf8(into_bytes(into_string(get<X>())))
    }

    public(package) fun get_mut_pixel<X, Y>(
        pixel_global: &mut Pixel_Global,
        index: u64,
    ): &mut Pixel<X, Y> {
        let is_pixel_exist = is_pixel_exist<X, Y>(pixel_global, index);
        assert!(is_pixel_exist, E_PIXEL_NOT_EXIST);

        bag::borrow_mut<u64, Pixel<X, Y>>(&mut pixel_global.pixel_list, index)
    }
}