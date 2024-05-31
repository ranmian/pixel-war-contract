module game::game {
    use sui::clock::{Self, Clock};
    use game::admin::AdminCap;
    // use game::pixel::{Self, Pixel_Global, Leader, Destroy_Info};

    const ROUND_STATUS_PENDING: u8 = 0;
    const ROUND_STATUS_PLAYING: u8 = 1;
    // const ROUND_STATUS_DESTORY: u8 = 2;
    // const ROUND_STATUS_OVER: u8 = 3;

    const DEFAULT_ROUN_DURATION: u64 = 3 * 24 * 3600 * 1000;

    const E_ROUND_NOT_OVER: u64 = 0;
    const E_INVALID_ROUND: u64 = 1;
    const E_ROUND_DURATION: u64 = 2;

    public struct Game has key {
        id: UID,
        epoch: u64,
        round: u64,
        round_status: u8,
        round_start_time: u64,
        round_end_time: u64,
        pixel_count: u64,
        round_duration: u64,
    }

    fun init(ctx: &mut tx_context::TxContext) {
        let game = Game {
            id: object::new(ctx),
            epoch: 1,
            round: 0,
            round_status: ROUND_STATUS_PENDING,
            round_start_time: 0,
            round_end_time: 0,
            pixel_count: 0,
            round_duration: DEFAULT_ROUN_DURATION,
        };

        transfer::share_object(game);
    }

    public fun start_round(
        _: &AdminCap, 
        game: &mut Game, 
        clock: &Clock
    ) {
        let current_time = clock::timestamp_ms(clock);
        assert!(game.round_end_time < current_time, E_ROUND_NOT_OVER);

        if (game.round == game.pixel_count-1) {
            game.epoch = game.epoch + 1;
            game.round = 1;
        } else {
            game.round = game.round + 1;
        };
        assert!(game.round < game.pixel_count, E_INVALID_ROUND);

        game.round_start_time = current_time;
        game.round_end_time = game.round_start_time + game.round_duration;
        assert!(game.round_end_time > game.round_start_time, E_ROUND_DURATION);

        game.round_status = ROUND_STATUS_PLAYING;
    }

    // public fun destroy_pixel<X, Y, Z>(
    //     game: &mut Game,
    //     pixel_global: &mut Pixel_Global,
    //     source_index: u64,
    //     target_index: u64,
    //     ctx: &mut tx_context::TxContext
    // ) {
    //     let source_pixel = pixel::get_mut_pixel<X,Z>(pixel_global, source_index);
    //     let target_pixel = pixel::get_mut_pixel<Y,Z>(pixel_global, target_index);

    //     assert!(option::is_some(&source_pixel.leader), E_LEADER_NOT_EXIST);

    //     let sender = tx_context::sender(ctx);
    //     let leader = option::borrow_mut<Leader<X>>(&mut source_pixel.leader);
    //     assert!(leader.leader_address == sender, E_YOU_ARE_NOT_LEADER);

    //     target_pixel.is_destroy = true;
        
    //     let destroy_info = Destroy_Info {
    //         epoch: game.epoch,
    //         round: game.round,
    //         source_index: source_index,
    //         target_index: target_index,
    //         source_address: sender,
    //         is_source_leader: true,
    //     }

    //     table::add(&mut pixel_global.destroy_info_list, game.round, destroy_info);
    // }

    public fun update_pixel_count(
        _: &AdminCap, 
        game: &mut Game, 
        pixel_count: u64
    ) {
        game.pixel_count = pixel_count;
    }

    public fun update_round_duration(
        _: &AdminCap, 
        game: &mut Game, 
        round_duration: u64, 
        clock: &Clock
    ) {
        game.round_duration = round_duration;
        game.round_end_time = game.round_start_time + game.round_duration;
        assert!(game.round_end_time > game.round_start_time, E_ROUND_DURATION);
        assert!(game.round_end_time > clock::timestamp_ms(clock), E_ROUND_DURATION);
    }

    public fun get_round_duration(game: &mut Game): u64 {
        game.round_duration
    }
}