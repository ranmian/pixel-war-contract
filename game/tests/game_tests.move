#[test_only]
module game::game_tests {
    use std::debug;
    use sui::test_scenario::{Self, Scenario};
    use game::game;
    use game::pixel::{Self, PixelGlobal};
    use game::math256;

    const ENotImplemented: u64 = 0;

    #[test_only]
    public fun init_for_testing(scenario: &mut Scenario) {
        let sender = @game;
        pixel::init(test_scenario::ctx(scenario));

        let pixel_global = test_scenario::take_shared<PixelGlobal>(scenario);
        debug::print(&pixel_global);
    }
    
    #[test_only]
    fun test_quote_buy_amount() {
       
    }

    #[test, expected_failure(abort_code = ::game::game_tests::ENotImplemented)]
    fun test_game_fail() {
        abort ENotImplemented
    }
}
