module pvp::manage {
    use sui::sui::SUI;
    use sui::clock::Clock;
    use sui::coin::Coin;
    use pvp::admin::{Self, AdminCap};
    use pvp::game::{Self, GameGlobal};
    use pvp::pixel::{Self, PixelGlobal};

    fun init(ctx: &mut TxContext) {
        admin::init_admin(ctx);
        game::init_game(ctx);
        pixel::init_pixel(ctx);
    }

    public fun start_game(
        _: &AdminCap,
        game_global: &mut GameGlobal,
        clock: &Clock,
    ) {
        game::start_game(game_global, clock);
    }

    public fun migrate<T>(
        _: &AdminCap,
        pixel_global: &mut PixelGlobal,
        ctx: &mut TxContext,
    ): (Coin<SUI>, Coin<T>) {
        pixel::migrate(pixel_global, ctx)
    }

    public fun update_listing_fee(
        _: &AdminCap,
        pixel_global: &mut PixelGlobal,
        fee: u64,
    ) {
        pixel::update_listing_fee(pixel_global, fee);
    }

    public fun update_decorate_fee(
        _: &AdminCap,
        pixel_global: &mut PixelGlobal,
        fee: u64,
    ) {
        pixel::update_decorate_fee(pixel_global, fee);
    }

    public fun update_pixel_count(
        _: &AdminCap,
        game_global: &mut GameGlobal,
        pixel_count: u64,
    ) {
        game::update_pixel_count(game_global, pixel_count);
    }

    public fun update_round_duration(
        _: &AdminCap,
        game_global: &mut GameGlobal,
        round_duration: u64,
    ) {
        game::update_round_duration(game_global, round_duration);
    }
}