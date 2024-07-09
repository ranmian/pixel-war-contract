module pvp::errors {
    const E_INVALID_VERSION: u64 = 1000;
    const E_INVALID_GAME_STATUS: u64 = 1001;
    const E_INVALID_WIN_PIXEL: u64 = 1002;
    const E_INVALID_LUCKY_PIXEL: u64 = 1003;
    const E_INVALID_DESTROY_PIXEL: u64 = 1004;
    const E_INVALID_ROUND_DESTROY_DURATION: u64 = 1002;
    const E_INVALID_ROUND_DURATION: u64 = 1003;
    const E_INVALID_PIXEL_COUNT: u64 = 1004;
    const E_PIXEL_COUNT_OVERFLOW: u64 = 1005;
    const E_INVALID_GAME_ROUND: u64 = 1006;
    const E_INVALID_TOKEN_SUPPLY: u64 = 1007;
    const E_INVALID_TOKEN_DECIMALS: u64 = 1008;
    const E_INSUFFICIENT_LISTING_FEE: u64 = 1009;
    const E_INVALID_PIXEL_INDEX: u64 = 1010;
    const E_PIXEL_INDEX_EXIST: u64 = 1011;
    const E_PIXEL_BALANCE_EXIST: u64 = 1012;
    const E_PIXEL_BALANCE_NOT_EXIST: u64 = 1012;
    const E_PIXEL_NOT_EXIST: u64 = 1012;
    const E_PIXEL_HAS_BEEN_LISTED: u64 = 1013;
    const E_INVALID_COIN_AMOUNT: u64 = 1014;
    const E_INSUFFICIENT_COIN_AMOUNT: u64 = 1015;
    const E_PIXEL_ACTIVE: u64 = 1017;
    const E_PIXEL_INACTIVE: u64 = 1016;
    const E_INVALID_SWAP_AMOUNT: u64 = 1018;
    const E_USER_STAKE_NO_EXIST: u64 = 1019;
    const E_INVALID_UNSTAKE_AMOUNT: u64 = 1019;
    const E_INSUFFICIENT_STAKE_FEE: u64 = 1020;
    const E_YOU_ARE_NOT_LEADER: u64 = 1021;
    const E_HAVE_JOINED_ALLIANCE: u64 = 1022;

    public fun invalid_version(): u64 {
        E_INVALID_VERSION
    }

    public fun invalid_game_status(): u64 {
        E_INVALID_GAME_STATUS
    }

    public fun invalid_win_pixel(): u64 {
        E_INVALID_WIN_PIXEL
    }

    public fun invalid_lucky_pixel(): u64 {
        E_INVALID_LUCKY_PIXEL
    }

    public fun invalid_destroy_pixel(): u64 {
        E_INVALID_DESTROY_PIXEL
    }

    public fun invalid_round_destroy_duration(): u64 {
        E_INVALID_ROUND_DESTROY_DURATION
    }

    public fun invalid_round_duration(): u64 {
        E_INVALID_ROUND_DURATION
    }

    public fun invalid_pixel_count(): u64 {
        E_INVALID_PIXEL_COUNT
    }

    public fun pixel_count_overflow(): u64 {
        E_PIXEL_COUNT_OVERFLOW
    }

    public fun invalid_game_round(): u64 {
        E_INVALID_GAME_ROUND
    }

    public fun invalid_token_supply(): u64 {
        E_INVALID_TOKEN_SUPPLY
    }

    public fun invalid_token_decimals(): u64 {
        E_INVALID_TOKEN_DECIMALS
    }

    public fun insufficient_listing_fee(): u64 {
        E_INSUFFICIENT_LISTING_FEE
    }

    public fun invalid_pixel_index(): u64 {
        E_INVALID_PIXEL_INDEX
    }

    public fun pixel_index_exist(): u64 {
        E_PIXEL_INDEX_EXIST
    }

    public fun pixel_balance_exist(): u64 {
        E_PIXEL_BALANCE_EXIST
    }

    public fun pixel_balance_not_exist(): u64 {
        E_PIXEL_BALANCE_NOT_EXIST
    }

    public fun pixel_not_exist(): u64 {
        E_PIXEL_NOT_EXIST
    }

    public fun pixel_has_been_listed(): u64 {
        E_PIXEL_HAS_BEEN_LISTED
    }

    public fun invalid_coin_amount(): u64 {
        E_INVALID_COIN_AMOUNT
    }

    public fun insufficient_coin_amount(): u64 {
        E_INSUFFICIENT_COIN_AMOUNT
    }

    public fun pixel_active(): u64 {
        E_PIXEL_ACTIVE
    }

    public fun pixel_inactive(): u64 {
        E_PIXEL_INACTIVE
    }

    public fun invalid_swap_amount(): u64 {
        E_INVALID_SWAP_AMOUNT
    }
    
    public fun user_stake_no_exist(): u64 {
        E_USER_STAKE_NO_EXIST
    }
    
    public fun invalid_unstake_amount(): u64 {
        E_INVALID_UNSTAKE_AMOUNT
    }

    public fun insufficient_stake_fee(): u64 {
        E_INSUFFICIENT_STAKE_FEE
    }

    public fun you_are_not_leader(): u64 {
        E_YOU_ARE_NOT_LEADER
    }

    public fun have_joined_alliance(): u64 {
        E_HAVE_JOINED_ALLIANCE
    }
}