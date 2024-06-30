module pvp::constants {
    const VERSION: u64 = 1;
    const PIXEL_COUNT: u64 = 900;
    const GAME_ROUND_STATUS_PENDING: u8 = 0;
    const GAME_ROUND_STATUS_PLAYING: u8 = 1;
    const GAME_ROUND_STATUS_END: u8 = 2;
    const ROUN_DURATION: u64 = 7 * 24 * 3600 * 1000;
    const DESTROY_DURATION: u64 = 3600 * 1000;

    const TARGET_SUPPLY_THRESHOLD: u64 = 200_000_000_000_000_000;
    const VIRTUAL_SUI_AMOUNT: u64 = 4_200_000_000_000;

    const LISTING_FEE: u64 = 19_900_000_000;
    const DECORATE_FEE: u64 = 5_000_000_000;
    const MIGRATE_FEE: u64 = 100_000_000_000;
    const RATE_SIZE: u64 = 1_000_000;
    const BUY_FEE_RATE: u64 = 20_000;
    const SELL_FEE_RATE: u64 = 20_000;
    const STAKE_FEE_RATE: u64 = 5_000;
    const ALLIANCE_FEE_RATE: u64 = 50_000;

    const TOKEN_TOTAL_SUPPLY: u64 = 1_000_000_000_000_000_000;
    const TOKEN_RESERVE_RATE: u64 = 10_000;

    const STAKE_SCALE: u64 = 1_000_000_000_000_000_000;

    public fun version(): u64 {
        VERSION
    }

    public fun pixel_count(): u64 {
        PIXEL_COUNT
    }

    public fun game_round_status_pending(): u8 {
        GAME_ROUND_STATUS_PENDING
    }

    public fun game_round_status_playing(): u8 {
        GAME_ROUND_STATUS_PLAYING
    }

    public fun game_round_status_end(): u8 {
        GAME_ROUND_STATUS_END
    }

    public fun round_duration(): u64 {
        ROUN_DURATION
    }

    public fun destroy_duration(): u64 {
        DESTROY_DURATION
    }

    public fun listing_fee(): u64 {
        LISTING_FEE
    }
    
    public fun decorate_fee(): u64 {
        DECORATE_FEE
    }
    
    public fun migrate_fee(): u64 {
        MIGRATE_FEE
    }

    public fun rate_size(): u64 {
        RATE_SIZE
    }

    public fun buy_fee_rate(): u64 {
        BUY_FEE_RATE
    }

    public fun sell_fee_rate(): u64 {
        SELL_FEE_RATE
    }

    public fun stake_fee_rate(): u64 {
        STAKE_FEE_RATE
    }
    
    public fun alliance_fee_rate(): u64 {
        ALLIANCE_FEE_RATE
    }

    public fun target_supply_threshold(): u64 {
        TARGET_SUPPLY_THRESHOLD
    }

    public fun virtual_sui_amount(): u64 {
        VIRTUAL_SUI_AMOUNT
    }

    public fun token_total_supply(): u64 {
        TOKEN_TOTAL_SUPPLY
    }

    public fun token_reserve_rate(): u64 {
        TOKEN_RESERVE_RATE
    }

    public fun stake_scale(): u64 {
        STAKE_SCALE
    }
}