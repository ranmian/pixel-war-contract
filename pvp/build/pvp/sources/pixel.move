module pvp::pixel {
    use std::ascii;
    use std::string::String;

    use sui::bag::{Self, Bag};
    use sui::balance::{Self, Balance};
    use sui::coin::{Self, Coin, CoinMetadata, TreasuryCap};
    use sui::sui::SUI;
    use sui::table::{Self, Table};
    use sui::url::Url;
    use sui::vec_map::{Self, VecMap};

    use pvp::constants;
    use pvp::errors;
    use pvp::event;
    use pvp::math;
    use pvp::utils;
    use pvp::version;

    public struct PixelGlobal has key {
        id: UID,
        version: u64,
        fee: Balance<SUI>,
        listing_fee: u64,
        decorate_fee: u64,
        migrate_fee: u64,
        buy_fee_rate: u64,
        sell_fee_rate: u64,
        stake_fee_rate: u64,
        alliance_fee_rate: u64,
        target_supply_threshold: u64,
        virtual_sui_amount: u64,
        pixel_list: Bag,
        pixel_index_list: VecMap<u64, String>,
        pixel_balance_list: Table<String, PixelBalance>,
    }

    public struct Pixel<phantom T> has store {
        version: u64,
        index: u64,
        name: String,
        symbol: ascii::String,
        image_url: Option<Url>,
        creator: address,
        is_active: bool,
        is_destroy: bool,
        token_balance: Balance<T>,
        sui_balance: Balance<SUI>,
        token_reserve: Balance<T>,
        target_supply_threshold: u64,
        virtual_sui_amount: u64,
        stake_fee: Balance<SUI>,
        stake_amount: u64,
        last_fee_index: u64,
        stake_list: Table<address, UserStake<T>>,
        stake_address_list: vector<address>,
        leader_address: Option<address>,
        leader_stake_amount: u64,
        alliance_list: VecMap<u64, String>,
        decorate_address: Option<address>,
    }

    public struct PixelBalance has store {
        is_destroy: bool,
        sui_amount: u64,
        token_amount: u64,
        stake_amount: u64,
    }

    public struct UserStake<phantom T> has key, store {
        id: UID,
        user: address,
        stake_balance: Balance<T>,
        fee_index: u64,
        rewards: u64,
    }

    public(package) fun list<T>(
        pixel_global: &mut PixelGlobal,
        mut treasury_cap: TreasuryCap<T>,
        metadata: &CoinMetadata<T>,
        mut pay_coin: Coin<SUI>,
        index: u64,
        pixel_count: u64,
        ctx: &mut TxContext,
    ): Coin<SUI> {
        assert!(
            coin::total_supply(&treasury_cap) == 0,
            errors::invalid_token_supply(),
        );
        assert!(
            coin::get_decimals(metadata) == 9,
            errors::invalid_token_decimals(),
        );
        assert!(
            index > 0 && index <= pixel_count,
            errors::invalid_pixel_index(),
        );

        let pixel_type = utils::get_pixel_type<T>();
        let token_name = coin::get_name(metadata);
        let token_symbol = coin::get_symbol(metadata);

        assert!(
            !vec_map::contains(&pixel_global.pixel_index_list, &index),
            errors::pixel_index_exist()
        );
        assert!(
            vec_map::size(&pixel_global.pixel_index_list) <= pixel_count,
            errors::pixel_count_overflow()
        );
        vec_map::insert(
            &mut pixel_global.pixel_index_list,
            index,
            pixel_type,
        );

        assert!(
            !table::contains(&pixel_global.pixel_balance_list, pixel_type),
            errors::pixel_balance_exist()
        );
        assert!(
            table::length(&pixel_global.pixel_balance_list) <= pixel_count,
            errors::pixel_count_overflow()
        );
        let pixel_balance = PixelBalance {
            is_destroy: false,
            sui_amount: 0,
            token_amount: 0,
            stake_amount: 0,
        };
        table::add(
            &mut pixel_global.pixel_balance_list,
            pixel_type,
            pixel_balance,
        );

        let total_supply = (constants::token_total_supply() as u256);
        let token_reserve_rate = (constants::token_reserve_rate() as u256);
        let token_reserve_value = math::mul_div(total_supply, token_reserve_rate, (constants::rate_size() as u256));
        let token_value = math::sub(total_supply, token_reserve_value);

        let token_balance = balance::increase_supply(coin::supply_mut(&mut treasury_cap), (token_value as u64));
        let token_reserve_balance = balance::increase_supply(
            coin::supply_mut(&mut treasury_cap),
            (token_reserve_value as u64)
        );
        transfer::public_freeze_object(treasury_cap);

        let image_url = coin::get_icon_url(metadata);
        let sender = tx_context::sender(ctx);

        let pixel = Pixel<T> {
            version: version::current_version(),
            index,
            name: token_name,
            symbol: token_symbol,
            image_url,
            creator: sender,
            is_active: true,
            is_destroy: false,
            token_balance,
            sui_balance: balance::zero(),
            token_reserve: token_reserve_balance,
            target_supply_threshold: pixel_global.target_supply_threshold,
            virtual_sui_amount: pixel_global.virtual_sui_amount,
            stake_fee: balance::zero(),
            stake_amount: 0,
            last_fee_index: 0,
            stake_list: table::new<address, UserStake<T>>(ctx),
            stake_address_list: vector::empty<address>(),
            leader_address: option::none(),
            leader_stake_amount: 0,
            alliance_list: vec_map::empty(),
            decorate_address: option::none(),
        };

        assert!(
            is_pixel_listed<T>(pixel_global, pixel_type) == false,
            errors::pixel_has_been_listed(),
        );
        assert!(
            bag::length(&pixel_global.pixel_list) <= pixel_count,
            errors::pixel_count_overflow()
        );

        bag::add(&mut pixel_global.pixel_list, pixel_type, pixel);

        event::pixel_list_event(
            sender,
            index,
            token_name,
            token_symbol,
            pixel_type,
            coin::get_description(metadata),
            image_url,
            (token_value as u64),
            0,
            (token_reserve_value as u64),
            pixel_global.buy_fee_rate,
            pixel_global.sell_fee_rate,
            pixel_global.stake_fee_rate,
            pixel_global.listing_fee,
            pixel_global.target_supply_threshold,
            pixel_global.virtual_sui_amount,
        );

        let pay_balance_value = coin::value(&pay_coin);
        assert!(
            pay_balance_value >= pixel_global.listing_fee,
            errors::insufficient_listing_fee(),
        );

        let pay_balance = coin::into_balance(
            coin::split(&mut pay_coin, pixel_global.listing_fee, ctx)
        );
        balance::join(&mut pixel_global.fee, pay_balance);

        pay_coin
    }

    public(package) fun buy<T>(
        pixel_global: &mut PixelGlobal,
        in_coin: Coin<SUI>,
        ctx: &mut TxContext,
    ): Coin<T> {
        let pixel_type = utils::get_pixel_type<T>();
        let buy_fee_rate = pixel_global.buy_fee_rate;
        let stake_fee_rate = pixel_global.stake_fee_rate;
        let sender = tx_context::sender(ctx);

        let mut in_balance = coin::into_balance(in_coin);
        let in_amount = balance::value(&in_balance);

        assert!(
            is_pixel_listed<T>(pixel_global, pixel_type) == true,
            errors::pixel_not_exist(),
        );

        let (
            pixel_status,
            pixel_name,
            pixel_symbol
        ) = {
            let pixel = bag::borrow<String, Pixel<T>>(&pixel_global.pixel_list, pixel_type);
            (
                pixel.is_active,
                pixel.name,
                pixel.symbol,
            )
        };

        assert!(
            pixel_status == true,
            errors::pixel_inactive(),
        );

        let swap_fee = get_swap_fees(in_amount, buy_fee_rate);
        let stake_fee = get_swap_fees(in_amount, stake_fee_rate);

        balance::join(&mut pixel_global.fee, balance::split(&mut in_balance, swap_fee));

        let (
            pixel_sui_amount,
            pixel_token_amount,
            out_amount,
            out_coin
        ) = {
            let pixel = bag::borrow_mut<String, Pixel<T>>(&mut pixel_global.pixel_list, pixel_type);

            balance::join(&mut pixel.stake_fee, balance::split(&mut in_balance, stake_fee));

            pixel.last_fee_index = get_last_fee_index(
                pixel.last_fee_index,
                stake_fee,
                pixel.stake_amount,
            );

            let (sui_amount, token_amount) = get_pixel_balance_values<T>(pixel);
            let out_amount = get_out_amount(
                in_amount - swap_fee - stake_fee,
                sui_amount + pixel.virtual_sui_amount,
                token_amount,
            );

            balance::join(&mut pixel.sui_balance, in_balance);

            let (pixel_sui_amount, pixel_token_amount) = get_pixel_balance_values<T>(pixel);
            assert!(
                pixel_sui_amount > 0 && pixel_token_amount > 0 && pixel_token_amount >= out_amount,
                errors::invalid_swap_amount(),
            );

            if (pixel_token_amount <= pixel.target_supply_threshold) {
                pixel.is_active = false;
                event::migrate_pending_event(
                    pixel_name,
                    pixel_symbol,
                    pixel_type,
                    pixel_sui_amount,
                    pixel_token_amount,
                );
            };

            (
                pixel_sui_amount,
                pixel_token_amount,
                out_amount,
                coin::take(&mut pixel.token_balance, out_amount, ctx)
            )
        };

        assert!(
            table::contains<String, PixelBalance>(&pixel_global.pixel_balance_list, pixel_type),
            errors::pixel_balance_not_exist(),
        );
        let pixel_balance = table::borrow_mut<String, PixelBalance>(&mut pixel_global.pixel_balance_list, pixel_type);
        pixel_balance.sui_amount = pixel_sui_amount;
        pixel_balance.token_amount = pixel_token_amount;

        event::swap_event(
            true,
            sender,
            pixel_name,
            pixel_symbol,
            pixel_type,
            in_amount,
            out_amount,
            buy_fee_rate,
            stake_fee_rate,
            swap_fee,
            stake_fee,
        );

        out_coin
    }

    public(package) fun sell<T>(
        pixel_global: &mut PixelGlobal,
        in_coin: Coin<T>,
        ctx: &mut TxContext,
    ): Coin<SUI> {
        let pixel_type = utils::get_pixel_type<T>();
        let sell_fee_rate = pixel_global.sell_fee_rate;
        let stake_fee_rate = pixel_global.stake_fee_rate;
        let sender = tx_context::sender(ctx);

        assert!(
            is_pixel_listed<T>(pixel_global, pixel_type) == true,
            errors::pixel_not_exist(),
        );

        let (
            pixel_status,
            pixel_name,
            pixel_symbol,
            pixel_sui_amount,
            pixel_token_amount,
            virtual_sui_amount
        ) = {
            let pixel = bag::borrow<String, Pixel<T>>(&pixel_global.pixel_list, pixel_type);
            let (pixel_sui_amount, pixel_token_amount) = get_pixel_balance_values<T>(pixel);
            (
                pixel.is_active,
                pixel.name,
                pixel.symbol,
                pixel_sui_amount,
                pixel_token_amount,
                pixel.virtual_sui_amount,
            )
        };

        assert!(
            pixel_status == true,
            errors::pixel_inactive(),
        );

        let in_balance = coin::into_balance(in_coin);
        let in_amount = balance::value(&in_balance);

        let out_amount = get_out_amount(
            in_amount,
            pixel_token_amount,
            pixel_sui_amount + virtual_sui_amount,
        );

        let swap_fee = get_swap_fees(out_amount, sell_fee_rate);
        let stake_fee = get_swap_fees(out_amount, stake_fee_rate);

        let mut out_balance = {
            let pixel = bag::borrow_mut<String, Pixel<T>>(&mut pixel_global.pixel_list, pixel_type);
            balance::split(&mut pixel.sui_balance, out_amount)
        };

        balance::join(&mut pixel_global.fee, balance::split(&mut out_balance, swap_fee));

        let (
            pixel_sui_amount,
            pixel_token_amount,
            out_coin
        ) = {
            let pixel = bag::borrow_mut<String, Pixel<T>>(&mut pixel_global.pixel_list, pixel_type);
            balance::join(&mut pixel.token_balance, in_balance);
            balance::join(&mut pixel.stake_fee, balance::split(&mut out_balance, stake_fee));
            pixel.last_fee_index = get_last_fee_index(
                pixel.last_fee_index,
                stake_fee,
                pixel.stake_amount,
            );

            let (pixel_sui_amount, pixel_token_amount) = get_pixel_balance_values<T>(pixel);
            assert!(
                pixel_token_amount > 0 && pixel_sui_amount > 0,
                errors::invalid_swap_amount(),
            );

            (
                pixel_sui_amount,
                pixel_token_amount,
                coin::from_balance(out_balance, ctx),
            )
        };

        assert!(
            table::contains<String, PixelBalance>(&pixel_global.pixel_balance_list, pixel_type),
            errors::pixel_balance_not_exist(),
        );
        let pixel_balance = table::borrow_mut<String, PixelBalance>(&mut pixel_global.pixel_balance_list, pixel_type);
        pixel_balance.sui_amount = pixel_sui_amount;
        pixel_balance.token_amount = pixel_token_amount;

        event::swap_event(
            false,
            sender,
            pixel_name,
            pixel_symbol,
            pixel_type,
            in_amount,
            out_amount,
            sell_fee_rate,
            stake_fee_rate,
            swap_fee,
            stake_fee,
        );

        out_coin
    }

    public(package) fun stake<T>(
        pixel_global: &mut PixelGlobal,
        stake_coin: Coin<T>,
        ctx: &mut TxContext,
    ) {
        let pixel_type = utils::get_pixel_type<T>();
        let sender = tx_context::sender(ctx);
        let stake_balance = coin::into_balance(stake_coin);
        let stake_amount = balance::value(&stake_balance);

        assert!(
            is_pixel_listed<T>(pixel_global, pixel_type) == true,
            errors::pixel_not_exist(),
        );

        let (
            pixel_status,
            pixel_index,
            pixel_name,
            pixel_symbol,
            last_fee_index,
            user_stake_amount,
            old_leader_address
        ) = {
            let pixel = bag::borrow<String, Pixel<T>>(&pixel_global.pixel_list, pixel_type);
            let user_stake_amount = if (table::contains<address, UserStake<T>>(&pixel.stake_list, sender)) {
                let user_stake = table::borrow<address, UserStake<T>>(&pixel.stake_list, sender);
                (
                    math::add(
                        (stake_amount as u256),
                        (balance::value(&user_stake.stake_balance) as u256)
                    ) as u64
                )
            } else {
                stake_amount
            };

            (
                pixel.is_active,
                pixel.index,
                pixel.name,
                pixel.symbol,
                pixel.last_fee_index,
                user_stake_amount,
                pixel.leader_address,
            )
        };
        assert!(
            pixel_status == true,
            errors::pixel_inactive(),
        );

        let pixel_stake_amount = {
            let pixel = bag::borrow_mut<String, Pixel<T>>(&mut pixel_global.pixel_list, pixel_type);

            pixel.stake_amount = (
                math::add(
                    (pixel.stake_amount as u256),
                    (stake_amount as u256)
                ) as u64
            );

            // leader
            if (option::is_none(&pixel.leader_address) || user_stake_amount > pixel.leader_stake_amount) {
                pixel.leader_address = option::some(sender);
                pixel.leader_stake_amount = user_stake_amount;
            };

            if (old_leader_address != pixel.leader_address) {
                event::new_leader_event(
                    pixel.index,
                    pixel.name,
                    pixel.symbol,
                    pixel_type,
                    pixel.leader_address,
                    pixel.leader_stake_amount,
                );
            };

            if (!vector::contains<address>(&pixel.stake_address_list, &sender)) {
                vector::push_back<address>(&mut pixel.stake_address_list, sender);
            };

            if (table::contains<address, UserStake<T>>(&pixel.stake_list, sender)) {
                let user_stake = table::borrow_mut<address, UserStake<T>>(&mut pixel.stake_list, sender);
                user_stake.rewards = get_stake_rewards(
                    user_stake.rewards,
                    balance::value(&user_stake.stake_balance),
                    user_stake.fee_index,
                    last_fee_index,
                );
                user_stake.fee_index = last_fee_index;
                balance::join(&mut user_stake.stake_balance, stake_balance);
            } else {
                let user_stake = UserStake {
                    id: object::new(ctx),
                    user: sender,
                    stake_balance,
                    fee_index: last_fee_index,
                    rewards: 0,
                };
                table::add(&mut pixel.stake_list, sender, user_stake);
            };

            pixel.stake_amount
        };

        assert!(
            table::contains<String, PixelBalance>(&pixel_global.pixel_balance_list, pixel_type),
            errors::pixel_balance_not_exist(),
        );
        let pixel_balance = table::borrow_mut<String, PixelBalance>(&mut pixel_global.pixel_balance_list, pixel_type);
        pixel_balance.stake_amount = pixel_stake_amount;

        event::stake_event(
            pixel_index,
            pixel_name,
            pixel_symbol,
            pixel_type,
            sender,
            stake_amount,
        );
    }

    public(package) fun unstake<T>(
        pixel_global: &mut PixelGlobal,
        amount: u64,
        ctx: &mut TxContext,
    ): Coin<T> {
        let pixel_type = utils::get_pixel_type<T>();
        let sender = tx_context::sender(ctx);

        assert!(
            is_pixel_listed<T>(pixel_global, pixel_type) == true,
            errors::pixel_not_exist(),
        );

        let (
            pixel_status,
            pixel_index,
            pixel_name,
            pixel_symbol,
            last_fee_index,
            old_leader_address
        ) = {
            let pixel = bag::borrow<String, Pixel<T>>(&pixel_global.pixel_list, pixel_type);
            (
                pixel.is_active,
                pixel.index,
                pixel.name,
                pixel.symbol,
                pixel.last_fee_index,
                pixel.leader_address,
            )
        };
        assert!(
            pixel_status == true,
            errors::pixel_inactive(),
        );

        let (pixel_stake_amount, unstake_coin) = {
            let pixel = bag::borrow_mut<String, Pixel<T>>(&mut pixel_global.pixel_list, pixel_type);
            // leader
            let mut leader_address: Option<address> = option::none();
            let mut leader_stake_amount = 0;
            let mut vector_length = vector::length(&pixel.stake_address_list);
            while (vector_length > 0) {
                let user = *(vector::borrow<address>(&pixel.stake_address_list, vector_length - 1));
                if (table::contains<address, UserStake<T>>(&pixel.stake_list, user)) {
                    let stake = table::borrow<address, UserStake<T>>(&pixel.stake_list, user);
                    let mut stake_amount = balance::value(&stake.stake_balance);
                    if (user == sender) {
                        stake_amount = (math::sub((stake_amount as u256), (amount as u256)) as u64);
                    };
                    if (stake_amount > leader_stake_amount) {
                        leader_address = option::some(user);
                        leader_stake_amount = stake_amount;
                    };
                };
                vector_length = vector_length - 1;
            };

            pixel.leader_address = leader_address;
            pixel.leader_stake_amount = leader_stake_amount;

            if (old_leader_address != pixel.leader_address) {
                event::new_leader_event(
                    pixel.index,
                    pixel.name,
                    pixel.symbol,
                    pixel_type,
                    pixel.leader_address,
                    pixel.leader_stake_amount,
                );
            };

            let user_stake = get_mut_stake<T>(pixel, sender);
            let user_stake_amount = balance::value(&user_stake.stake_balance);
            assert!(
                user_stake_amount >= amount,
                errors::invalid_unstake_amount(),
            );

            user_stake.rewards = get_stake_rewards(
                user_stake.rewards,
                user_stake_amount,
                user_stake.fee_index,
                last_fee_index,
            );
            user_stake.fee_index = last_fee_index;

            let splitted_balance = balance::split(&mut user_stake.stake_balance, amount);

            if (user_stake_amount == amount && user_stake.rewards == 0) {
                let UserStake {
                    id,
                    user: _,
                    stake_balance,
                    fee_index: _,
                    rewards: _,
                } = table::remove<address, UserStake<T>>(&mut pixel.stake_list, sender);
                balance::destroy_zero(stake_balance);
                object::delete(id);
            };

            (
                pixel.stake_amount,
                coin::from_balance(splitted_balance, ctx),
            )
        };

        assert!(
            table::contains<String, PixelBalance>(&pixel_global.pixel_balance_list, pixel_type),
            errors::pixel_balance_not_exist(),
        );
        let pixel_balance = table::borrow_mut<String, PixelBalance>(&mut pixel_global.pixel_balance_list, pixel_type);
        pixel_balance.stake_amount = pixel_stake_amount;

        event::unstake_event(
            pixel_index,
            pixel_name,
            pixel_symbol,
            pixel_type,
            sender,
            amount,
        );

        unstake_coin
    }

    public fun user_stake_amount<T>(
        pixel_global: &PixelGlobal,
        user: address,
    ): u64 {
        let pixel_type = utils::get_pixel_type<T>();

        if (!bag::contains_with_type<String, Pixel<T>>(&pixel_global.pixel_list, pixel_type)) {
            return (0 as u64)
        };

        let pixel = bag::borrow<String, Pixel<T>>(&pixel_global.pixel_list, pixel_type);

        if (!table::contains<address, UserStake<T>>(&pixel.stake_list, user)) {
            return (0 as u64)
        };

        let user_stake = table::borrow<address, UserStake<T>>(&pixel.stake_list, user);

        balance::value(&user_stake.stake_balance)
    }

    public fun claim_stake_rewards<T>(
        pixel_global: &mut PixelGlobal,
        ctx: &mut TxContext,
    ): Coin<SUI> {
        let pixel = get_mut_pixel<T>(pixel_global);
        assert!(
            pixel.is_active == true,
            errors::pixel_inactive(),
        );

        let last_fee_index = pixel.last_fee_index;
        let sender = tx_context::sender(ctx);

        assert!(
            is_user_staked<T>(pixel, sender) == true,
            errors::user_stake_no_exist(),
        );

        let user_stake = table::borrow<address, UserStake<T>>(&pixel.stake_list, sender);
        let user_stake_amount = balance::value(&user_stake.stake_balance);

        let rewards = get_stake_rewards(
            user_stake.rewards,
            user_stake_amount,
            user_stake.fee_index,
            last_fee_index,
        );

        assert!(
            balance::value(&pixel.stake_fee) >= rewards,
            errors::insufficient_stake_fee(),
        );
        let rewards_coin = coin::from_balance(balance::split(&mut pixel.stake_fee, rewards), ctx);

        let user_stake = table::borrow_mut<address, UserStake<T>>(&mut pixel.stake_list, sender);
        user_stake.fee_index = last_fee_index;
        user_stake.rewards = 0;

        event::claim_stake_rewards_event(
            pixel.index,
            pixel.name,
            pixel.symbol,
            utils::get_pixel_type<T>(),
            sender,
            rewards,
        );

        rewards_coin
    }

    public(package) fun decorate_pixel<T>(
        pixel_global: &mut PixelGlobal,
        mut pay_coin: Coin<SUI>,
        image_url: Url,
        ctx: &mut TxContext,
    ): Coin<SUI> {
        let sender = tx_context::sender(ctx);
        let pixel_type = utils::get_pixel_type<T>();
        let pay_balance_value = coin::value(&pay_coin);
        assert!(
            pay_balance_value >= pixel_global.decorate_fee,
            errors::insufficient_coin_amount(),
        );

        let pay_balance = coin::into_balance(
            coin::split(&mut pay_coin, pixel_global.decorate_fee, ctx)
        );
        balance::join(&mut pixel_global.fee, pay_balance);

        let pixel = get_mut_pixel<T>(pixel_global);
        pixel.image_url = option::some(image_url);
        pixel.decorate_address = option::some(sender);

        event::decorate_pixel_event(
            sender,
            pixel_type,
            pixel.name,
            pixel.symbol,
            image_url,
            pixel_global.decorate_fee,
        );

        pay_coin
    }

    public(package) fun get_winner_pixel(
        pixel_global: &PixelGlobal
    ): Option<String> {
        let size = vec_map::size(&pixel_global.pixel_index_list);
        let mut winner_pixel_type:Option<String> = option::none();
        let mut winner_sui_amount = 0;

        let mut i = 0;
        while(i < size) {
            let (_, pixel_type) = vec_map::get_entry_by_idx(&pixel_global.pixel_index_list, i);
            let pixel_type = *pixel_type;

            if (!table::contains(&pixel_global.pixel_balance_list, pixel_type)) {
                i = i + 1;
                continue
            };

            let pixel_balance = table::borrow(&pixel_global.pixel_balance_list, pixel_type);
            if (pixel_balance.sui_amount >= winner_sui_amount) {
                winner_sui_amount = pixel_balance.sui_amount;
                winner_pixel_type = option::some(pixel_type);
            };

            i = i + 1;
        };

        winner_pixel_type
    }

    public(package) fun get_alive_pixel_count(
        pixel_global: &PixelGlobal
    ): u64 {
        let size = vec_map::size(&pixel_global.pixel_index_list);
        let mut alive_count= 0;

        let mut i = 0;
        while(i < size) {
            let (_, pixel_type) = vec_map::get_entry_by_idx(&pixel_global.pixel_index_list, i);
            let pixel_type = *pixel_type;

            if (!table::contains(&pixel_global.pixel_balance_list, pixel_type)) {
                i = i + 1;
                continue
            };

            let pixel_balance = table::borrow(&pixel_global.pixel_balance_list, pixel_type);
            if (!pixel_balance.is_destroy) {
                alive_count = alive_count + 1;
            };

            i = i + 1;
        };

        alive_count
    }

    public(package) fun migrate<T>(
        pixel_global: &mut PixelGlobal,
        ctx: &mut TxContext,
    ): (Coin<SUI>, Coin<T>) {
        let migrate_fee = pixel_global.migrate_fee;
        let pixel_type = utils::get_pixel_type<T>();

        assert!(
            is_pixel_listed<T>(pixel_global, pixel_type) == true,
            errors::pixel_not_exist(),
        );

        let pixel = bag::borrow_mut<String, Pixel<T>>(&mut pixel_global.pixel_list, pixel_type);
        assert!(
            pixel.is_active == false,
            errors::pixel_active(),
        );

        if (migrate_fee > 0) {
            let migrate_fee_balance = {
                let pixel = get_mut_pixel<T>(pixel_global);
                balance::split(&mut pixel.sui_balance, migrate_fee)
            };
            balance::join(&mut pixel_global.fee, migrate_fee_balance);
        };

        let pixel = get_mut_pixel<T>(pixel_global);
        let (sui_amount, token_amount) = get_pixel_balance_values<T>(pixel);
        (
            coin::from_balance(balance::split(&mut pixel.sui_balance, sui_amount), ctx),
            coin::from_balance(balance::split<T>(&mut pixel.token_balance, token_amount), ctx)
        )
    }

    public(package) fun join_alliance<X, Y>(
        pixel_global: &mut PixelGlobal,
        ctx: &TxContext,
    ) {
        check_leader<X>(pixel_global, ctx);

        let source_pixel_type = utils::get_pixel_type<X>();
        let target_pixel_type = utils::get_pixel_type<Y>();

        assert!(
            is_pixel_listed<X>(pixel_global, source_pixel_type) == true,
            errors::pixel_not_exist(),
        );

        assert!(
            is_pixel_listed<Y>(pixel_global, target_pixel_type) == true,
            errors::pixel_not_exist(),
        );

        let alliance_fee_rate = pixel_global.alliance_fee_rate;

        let (
            alliance_fee,
            alliance_fee_amount
        ) = {
            let target_pixel = bag::borrow_mut<String, Pixel<Y>>(&mut pixel_global.pixel_list, target_pixel_type);

            let amount = (math::mul_div(
                (balance::value(&target_pixel.sui_balance) as u256),
                (alliance_fee_rate as u256),
                (constants::rate_size() as u256),
            ) as u64);

            (
                balance::split(&mut target_pixel.sui_balance, amount),
                amount,
            )
        };

        let target_pixel_index= {
            let target_pixel = bag::borrow<String, Pixel<Y>>(&pixel_global.pixel_list, target_pixel_type);
            target_pixel.index
        };

        let (
            source_pixel_index,
            source_pixel_name,
            source_pixel_symbol
        ) = {
            let source_pixel = bag::borrow_mut<String, Pixel<X>>(&mut pixel_global.pixel_list, source_pixel_type);
            assert!(
                vec_map::contains(&source_pixel.alliance_list, &target_pixel_index) == false,
                errors::have_joined_alliance(),
            );
            vec_map::insert(
                &mut source_pixel.alliance_list,
                target_pixel_index,
                target_pixel_type,
            );
            (
                source_pixel.index,
                source_pixel.name,
                source_pixel.symbol
            )
        };

        let (
            target_pixel_name,
            target_pixel_symbol
        ) = {
            let target_pixel = bag::borrow_mut<String, Pixel<Y>>(&mut pixel_global.pixel_list, source_pixel_type);
            assert!(
                vec_map::contains(&target_pixel.alliance_list, &source_pixel_index) == false,
                errors::have_joined_alliance(),
            );
            vec_map::insert(
                &mut target_pixel.alliance_list,
                source_pixel_index,
                source_pixel_type,
            );
            balance::join(
                &mut target_pixel.sui_balance,
                alliance_fee,
            );
            (
                target_pixel.name,
                target_pixel.symbol
            )
        };

        event::join_alliance_event(
            tx_context::sender(ctx),
            source_pixel_index,
            source_pixel_name,
            source_pixel_symbol,
            source_pixel_type,
            target_pixel_index,
            target_pixel_name,
            target_pixel_symbol,
            target_pixel_type,
            alliance_fee_amount,
        )
    }

    public(package) fun leave_alliance<X, Y>(
        pixel_global: &mut PixelGlobal,
        ctx: &TxContext,
    ) {
        check_leader<X>(pixel_global, ctx);

        let source_pixel_type = utils::get_pixel_type<X>();
        let target_pixel_type = utils::get_pixel_type<Y>();

        assert!(
            is_pixel_listed<X>(pixel_global, source_pixel_type) == true,
            errors::pixel_not_exist(),
        );

        assert!(
            is_pixel_listed<Y>(pixel_global, target_pixel_type) == true,
            errors::pixel_not_exist(),
        );

        let target_pixel_index= {
            let target_pixel = bag::borrow<String, Pixel<Y>>(&pixel_global.pixel_list, target_pixel_type);
            target_pixel.index
        };

        let (
            source_pixel_index,
            source_pixel_name,
            source_pixel_symbol
        ) = {
            let source_pixel = bag::borrow_mut<String, Pixel<X>>(&mut pixel_global.pixel_list, source_pixel_type);
            if (!vec_map::contains(&source_pixel.alliance_list, &target_pixel_index)) {
                vec_map::remove<u64, String>(&mut source_pixel.alliance_list, &target_pixel_index);
            };
            (
                source_pixel.index,
                source_pixel.name,
                source_pixel.symbol
            )
        };

        let (
            target_pixel_name,
            target_pixel_symbol
        ) = {
            let target_pixel = bag::borrow_mut<String, Pixel<Y>>(&mut pixel_global.pixel_list, target_pixel_type);
            if (!vec_map::contains(&target_pixel.alliance_list, &source_pixel_index)) {
                vec_map::remove<u64, String>(&mut target_pixel.alliance_list, &source_pixel_index);
            };
            (
                target_pixel.name,
                target_pixel.symbol
            )
        };

        event::leave_alliance_event(
            tx_context::sender(ctx),
            source_pixel_index,
            source_pixel_name,
            source_pixel_symbol,
            source_pixel_type,
            target_pixel_index,
            target_pixel_name,
            target_pixel_symbol,
            target_pixel_type,
        );
    }

    public fun get_pixel_leader<T>(
        pixel_global: &mut PixelGlobal
    ): Option<address> {
        let pixel_type = utils::get_pixel_type<T>();

        assert!(
            is_pixel_listed<T>(pixel_global, pixel_type) == true,
            errors::pixel_not_exist(),
        );

        let pixel = bag::borrow<String, Pixel<T>>(&pixel_global.pixel_list, pixel_type);

        pixel.leader_address
    }

    public(package) fun init_pixel(ctx: &mut TxContext) {
        let pixel_global = PixelGlobal {
            id: object::new(ctx),
            version: version::current_version(),
            target_supply_threshold: constants::target_supply_threshold(),
            virtual_sui_amount: constants::virtual_sui_amount(),
            fee: balance::zero(),
            listing_fee: constants::listing_fee(),
            decorate_fee: constants::decorate_fee(),
            migrate_fee: constants::migrate_fee(),
            buy_fee_rate: constants::buy_fee_rate(),
            sell_fee_rate: constants::sell_fee_rate(),
            stake_fee_rate: constants::stake_fee_rate(),
            alliance_fee_rate: constants::alliance_fee_rate(),
            pixel_list: bag::new(ctx),
            pixel_index_list: vec_map::empty(),
            pixel_balance_list: table::new(ctx),
        };

        transfer::share_object(pixel_global);
    }

    public(package) fun destroy_pixel<X, Y, Z>(
        pixel_global: &mut PixelGlobal,
        win_pixel_type: String,
        destroy_pixel_type: String,
        lucky_pixel_type: String,
        ctx: &TxContext,
    ) {
        let sender = tx_context::sender(ctx);

        let (
            destroy_pixel_name,
            destroy_pixel_symbol,
            destroy_amount,
            win_amount,
            win_balance,
            lucky_amount,
            lucky_balance
        ) = {
            let destroy_pixel = bag::borrow_mut<String, Pixel<Y>>(&mut pixel_global.pixel_list, destroy_pixel_type);
            let destroy_amount = balance::value(&destroy_pixel.sui_balance);
            let win_amount = (math::div((destroy_amount as u256), 2) as u64);
            let win_balance = balance::split(&mut destroy_pixel.sui_balance, win_amount);
            let lucky_amount = (math::sub((destroy_amount as u256), (win_amount as u256)) as u64);
            let lucky_balance = balance::split(&mut destroy_pixel.sui_balance, lucky_amount);
            destroy_pixel.is_destroy = true;
            destroy_pixel.is_active = false;
            (
                destroy_pixel.name,
                destroy_pixel.symbol,
                destroy_amount,
                win_amount,
                win_balance,
                lucky_amount,
                lucky_balance,
            )
        };

        let (
            win_pixel_name,
            win_pixel_symbol
        ) = {
            let win_pixel = bag::borrow_mut<String, Pixel<X>>(&mut pixel_global.pixel_list, win_pixel_type);
            assert!(
                is_alliance(&win_pixel.alliance_list, destroy_pixel_type) == false,
                errors::invalid_destroy_pixel(),
            );

            balance::join(&mut win_pixel.sui_balance, win_balance);
            (
                win_pixel.name,
                win_pixel.symbol,
            )
        };

        let (
            lucky_pixel_name,
            lucky_pixel_symbol,
        ) = {
            let lucky_pixel = bag::borrow_mut<String, Pixel<Z>>(&mut pixel_global.pixel_list, lucky_pixel_type);
            balance::join(&mut lucky_pixel.sui_balance, lucky_balance);
            (
                lucky_pixel.name,
                lucky_pixel.symbol,
            )
        };

        event::destroy_pixel_event(
            win_pixel_type,
            win_pixel_name,
            win_pixel_symbol,
            destroy_pixel_type,
            destroy_pixel_name,
            destroy_pixel_symbol,
            lucky_pixel_type,
            lucky_pixel_name,
            lucky_pixel_symbol,
            destroy_amount,
            win_amount,
            lucky_amount,
            sender,
        )
    }

    public(package) fun update_listing_fee(
        pixel_global: &mut PixelGlobal,
        fee: u64,
    ) {
        pixel_global.listing_fee = fee;
    }

    public(package) fun update_decorate_fee(
        pixel_global: &mut PixelGlobal,
        fee: u64,
    ) {
        pixel_global.decorate_fee = fee;
    }

    fun is_pixel_listed<T>(
        pixel_global: &PixelGlobal,
        pixel_type: String
    ): bool {
        bag::contains_with_type<String, Pixel<T>>(&pixel_global.pixel_list, pixel_type)
    }

    fun get_mut_pixel<T>(
        pixel_global: &mut PixelGlobal,
    ): &mut Pixel<T> {
        let pixel_type = utils::get_pixel_type<T>();

        assert!(
            is_pixel_listed<T>(pixel_global, pixel_type) == true,
            errors::pixel_not_exist(),
        );

        bag::borrow_mut<String, Pixel<T>>(&mut pixel_global.pixel_list, pixel_type)
    }

    fun is_user_staked<T>(
        pixel: &Pixel<T>,
        user: address,
    ): bool {
        table::contains<address, UserStake<T>>(&pixel.stake_list, user)
    }

    fun get_mut_stake<T>(
        pixel: &mut Pixel<T>,
        user: address,
    ): &mut UserStake<T> {
        assert!(
            is_user_staked<T>(pixel, user) == true,
            errors::user_stake_no_exist(),
        );

        table::borrow_mut<address, UserStake<T>>(&mut pixel.stake_list, user)
    }

    fun get_pixel_balance_values<T>(pixel: &Pixel<T>): (u64, u64) {
        (
            balance::value(&pixel.sui_balance),
            balance::value(&pixel.token_balance),
        )
    }

    fun get_out_amount(
        swap_amount: u64,
        in_amount: u64,
        out_amount: u64
    ): u64 {
        (math::div(
            (math::mul((swap_amount as u256), (out_amount as u256))),
            (math::add((in_amount as u256), (swap_amount as u256)))
        ) as u64)
    }

    fun get_swap_fees(
        sui_amount: u64,
        rate_value: u64,
    ): u64 {
        (math::mul_div(
            (sui_amount as u256),
            (rate_value as u256),
            (constants::rate_size() as u256)
        ) as u64)
    }

    fun get_last_fee_index(
        last_fee_index: u64,
        new_stake_fee: u64,
        total_stake_amount: u64,
    ): u64 {
        (math::add(
            (last_fee_index as u256),
            math::mul_div(
                (new_stake_fee as u256),
                (constants::stake_scale() as u256),
                (total_stake_amount as u256),
            ),
        ) as u64)
    }

    fun get_stake_rewards(
        old_rewards: u64,
        stake_amount: u64,
        fee_index: u64,
        last_fee_index: u64,
    ): u64 {
        (math::add(
            (old_rewards as u256),
            math::mul_div(
                (stake_amount as u256),
                math::sub((last_fee_index as u256), (fee_index as u256)),
                (constants::stake_scale() as u256),
            )
        ) as u64)
    }

    fun check_leader<T>(
        pixel_global: &mut PixelGlobal,
        ctx: &TxContext,
    ) {
        let apply_leader_address = get_pixel_leader<T>(pixel_global);
        let sender = tx_context::sender(ctx);
        assert!(
            apply_leader_address != option::some(sender),
            errors::you_are_not_leader(),
        );
    }

    fun is_alliance(
        alliance_list: &VecMap<u64, String>,
        pixel_type: String,
    ): bool {
        let mut flag = false;
        let mut i = 0;
        let size = vec_map::size(alliance_list);
        while(i < size) {
            let (_, value) = vec_map::get_entry_by_idx(alliance_list, i);
            if (pixel_type == *value) {
                flag = true;
                break
            };

            i = i + 1;
        };

        flag
    }
}