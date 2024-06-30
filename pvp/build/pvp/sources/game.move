module pvp::game {
    use std::string::String;

    use sui::clock::{Self, Clock};
    use sui::coin::{Coin, CoinMetadata, TreasuryCap};
    use sui::sui::SUI;
    use sui::url::Url;

    use pvp::constants;
    use pvp::errors;
    use pvp::pixel::{Self, PixelGlobal};
    use pvp::utils;
    use pvp::version;

    public struct GameGlobal has key {
        id: UID,
        version: u64,
        epoch: u64,
        round: u64,
        status: u8,
        pixel_count: u64,
        round_start_time: u64,
        round_duration: u64,
        destroy_duration: u64,
        last_win_pixel: Option<String>,
        last_destroy_pixel: Option<String>,
        last_lucky_pixel: Option<String>,
    }

    public fun list<T>(
        game_global: &GameGlobal,
        pixel_global: &mut PixelGlobal,
        treasury_cap: TreasuryCap<T>,
        metadata: &CoinMetadata<T>,
        pay_coin: Coin<SUI>,
        index: u64,
        ctx: &mut TxContext,
    ): Coin<SUI> {
        pixel::list(pixel_global, treasury_cap, metadata, pay_coin, index, game_global.pixel_count, ctx)
    }

    public fun buy<T>(
        game_global: &mut GameGlobal,
        pixel_global: &mut PixelGlobal,
        swap_coin: Coin<SUI>,
        clock: &Clock,
        ctx: &mut TxContext,
    ): Coin<T> {
        check_game_end(game_global, pixel_global, clock);

        pixel::buy(pixel_global, swap_coin, ctx)
    }

    public fun sell<T>(
        game_global: &mut GameGlobal,
        pixel_global: &mut PixelGlobal,
        swap_coin: Coin<T>,
        clock: &Clock,
        ctx: &mut TxContext,
    ): Coin<SUI> {
        check_game_end(game_global, pixel_global, clock);

        pixel::sell(pixel_global, swap_coin, ctx)
    }

    public fun stake<T>(
        game_global: &mut GameGlobal,
        pixel_global: &mut PixelGlobal,
        stake_coin: Coin<T>,
        clock: &Clock,
        ctx: &mut TxContext,
    ) {
        check_game_end(game_global, pixel_global, clock);

        pixel::stake(pixel_global, stake_coin, ctx);
    }

    public fun unstake<T>(
        game_global: &mut GameGlobal,
        pixel_global: &mut PixelGlobal,
        amount: u64,
        clock: &Clock,
        ctx: &mut TxContext,
    ): Coin<T> {
        check_game_end(game_global, pixel_global, clock);

        pixel::unstake(pixel_global, amount, ctx)
    }

    public fun destroy<X, Y, Z>(
        game_global: &mut GameGlobal,
        pixel_global: &mut PixelGlobal,
        clock: &Clock,
        ctx: &mut TxContext
    ) {
        check_game_end(game_global, pixel_global, clock);

        assert!(
            game_global.status == constants::game_round_status_end(),
            errors::invalid_game_status(),
        );

        let win_pixel_type = utils::get_pixel_type<X>();
        let destroy_pixel_type = utils::get_pixel_type<Y>();
        let lucky_pixel_type = utils::get_pixel_type<Z>();

        game_global.last_destroy_pixel = option::some(destroy_pixel_type);
        game_global.last_lucky_pixel = option::some(lucky_pixel_type);

        assert!(
            option::is_some(&game_global.last_win_pixel) && option::some(
                win_pixel_type
            ) == game_global.last_win_pixel,
            errors::invalid_win_pixel(),
        );
        assert!(
            game_global.last_win_pixel != game_global.last_destroy_pixel,
            errors::invalid_destroy_pixel(),
        );

        let remain_round = game_global.pixel_count - game_global.round;
        assert!(
            (remain_round >= 2 && game_global.last_lucky_pixel != game_global.last_win_pixel && game_global.last_lucky_pixel != game_global.last_destroy_pixel) || (remain_round == 1 && game_global.last_lucky_pixel != game_global.last_win_pixel && game_global.last_lucky_pixel == game_global.last_destroy_pixel),
            errors::invalid_lucky_pixel(),
        );

        let current_time = clock::timestamp_ms(clock);
        let round_end_time = game_global.round_start_time + game_global.round_duration + game_global.destroy_duration;
        let sender = tx_context::sender(ctx);

        if (current_time <= round_end_time) {
            let leader = pixel::get_pixel_leader<X>(pixel_global);
            assert!(
                leader == option::some(sender),
                errors::you_are_not_leader(),
            );
        };

        pixel::destroy_pixel<X, Y, Z>(pixel_global, win_pixel_type, destroy_pixel_type, lucky_pixel_type, ctx);

        assert!(
            game_global.status == constants::game_round_status_end(),
            errors::invalid_game_status(),
        );

        if (game_global.round == game_global.pixel_count - 1) {
            game_global.epoch = game_global.epoch + 1;
        };

        game_global.round = game_global.round + 1;

        assert!(
            game_global.round + 1 == game_global.pixel_count,
            errors::invalid_game_round()
        );

        game_global.round_start_time = current_time;
        game_global.status = constants::game_round_status_playing();
    }

    public fun apply_alliance<X, Y>(
        game_global: &GameGlobal,
        pixel_global: &mut PixelGlobal,
        target_index: u64,
        clock: &Clock,
        ctx: &mut TxContext,
    ) {
        check_game_time(game_global, clock);

        pixel::apply_alliance<X, Y>(
            pixel_global,
            target_index,
            ctx,
        );
    }

    public fun accept_alliance<X, Y>(
        game_global: &GameGlobal,
        pixel_global: &mut PixelGlobal,
        apply_index: u64,
        clock: &Clock,
        ctx: &mut TxContext,
    ) {
        check_game_time(game_global, clock);

        pixel::accept_alliance<X, Y>(
            pixel_global,
            apply_index,
            ctx,
        );
    }

    public fun refuse_alliance<T>(
        game_global: &mut GameGlobal,
        pixel_global: &mut PixelGlobal,
        target_index: u64,
        clock: &Clock,
        ctx: &mut TxContext,
    ) {
        check_game_time(game_global, clock);

        pixel::refuse_alliance<T>(
            pixel_global,
            target_index,
            ctx,
        );
    }

    public fun break_alliance<X, Y>(
        game_global: &GameGlobal,
        pixel_global: &mut PixelGlobal,
        index: u64,
        clock: &Clock,
        ctx: &mut TxContext,
    ) {
        check_game_time(game_global, clock);

        pixel::break_alliance<X, Y>(
            pixel_global,
            index,
            ctx,
        );
    }

    public fun decorate<T>(
        pixel_global: &mut PixelGlobal,
        pay_coin: Coin<SUI>,
        image_url: Url,
        ctx: &mut TxContext,
    ): Coin<SUI> {
        pixel::decorate_pixel<T>(pixel_global, pay_coin, image_url, ctx)
    }

    public(package) fun init_game(ctx: &mut TxContext) {
        let game_global = GameGlobal {
            id: object::new(ctx),
            version: version::current_version(),
            epoch: 0,
            round: 0,
            status: constants::game_round_status_pending(),
            pixel_count: constants::pixel_count(),
            round_start_time: 0,
            round_duration: constants::round_duration(),
            destroy_duration: constants::destroy_duration(),
            last_win_pixel: option::none(),
            last_destroy_pixel: option::none(),
            last_lucky_pixel: option::none(),
        };

        transfer::share_object(game_global);
    }

    public(package) fun start_game(
        game_global: &mut GameGlobal,
        clock: &Clock,
    ) {
        game_global.epoch = 1;
        game_global.round = 1;
        game_global.status = constants::game_round_status_playing();
        game_global.round_start_time = clock::timestamp_ms(clock);
    }

    public(package) fun update_pixel_count(
        game_global: &mut GameGlobal,
        pixel_count: u64
    ) {
        assert!(
            pixel_count > 0 && game_global.round < pixel_count,
            errors::invalid_pixel_count(),
        );

        game_global.pixel_count = pixel_count;
    }

    public(package) fun update_round_duration(
        game_global: &mut GameGlobal,
        round_duration: u64,
    ) {
        assert!(
            round_duration > 0,
            errors::invalid_round_duration(),
        );

        game_global.round_duration = round_duration;
    }

    fun check_game_time(
        game_global: &GameGlobal,
        clock: &Clock,
    ) {
        let current_time = clock::timestamp_ms(clock);
        let round_end_time = game_global.round_start_time + game_global.round_duration;
        assert!(
            game_global.status == constants::game_round_status_playing() && round_end_time > current_time,
            errors::invalid_game_status(),
        );
    }

    fun check_game_end(
        game_global: &mut GameGlobal,
        pixel_global: &PixelGlobal,
        clock: &Clock,
    ) {
        let current_time = clock::timestamp_ms(clock);
        let round_end_time = game_global.round_start_time + game_global.round_duration;
        if (
            current_time >= round_end_time && game_global.status == constants::game_round_status_playing()
        ) {
            game_global.status = constants::game_round_status_end();
            game_global.last_win_pixel = pixel::get_winner_pixel(pixel_global);
        };
    }
}
