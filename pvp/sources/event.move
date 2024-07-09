module pvp::event {
    use std::ascii;
    use std::string::String;
    use sui::url::Url;
    use sui::event::emit;

    public struct PixelListEvent has copy, drop {
        creator: address,
        index: u64,
        token_name: String,
        token_symbol: ascii::String,
        token_type: String,
        token_description: String,
        image_url: Option<Url>,
        token_balance: u64,
        sui_balance: u64,
        token_reserve: u64,
        buy_fee_rate: u64,
        sell_fee_rate: u64,
        stake_fee_rate: u64,
        fee: u64,
        target_supply_threshold: u64,
        virtual_sui_amount: u64,
    }

    public struct SwapEvent has copy, drop {
        is_buy: bool,
        sender: address,
        token_name: String,
        token_symbol: ascii::String,
        token_type: String,
        amount_in: u64,
        amount_out: u64,
        swap_fee_rate: u64,
        stake_fee_rate: u64,
        swap_fee: u64,
        stake_fee: u64,
    }

    public struct MigratePendingEvent has copy, drop {
        token_name: String,
        token_symbol: ascii::String,
        token_type: String,
        sui_reserve_amount: u64,
        token_reserve_amount: u64,
    }

    public struct StakeEvent has copy, drop {
        index: u64,
        token_name: String,
        token_symbol: ascii::String,
        token_type: String,
        stake_adddress: address,
        stake_amount: u64,
    }

    public struct UnstakeEvent has copy, drop {
        index: u64,
        token_name: String,
        token_symbol: ascii::String,
        token_type: String,
        unstake_adddress: address,
        unstake_amount: u64,
    }

    public struct ClaimStakeRewards has copy, drop {
        index: u64,
        token_name: String,
        token_symbol: ascii::String,
        token_type: String,
        sender: address,
        rewards: u64,
    }

    public struct NewLeaderEvent has copy, drop {
        index: u64,
        token_name: String,
        token_symbol: ascii::String,
        token_type: String,
        leader_address: Option<address>,
        leader_stake_amount: u64,
    }

    public struct JoinAllianceEvent has copy, drop {
        sender: address,
        source_index: u64,
        source_pixel_name: String,
        source_pixel_symbol: ascii::String,
        source_pixel_type: String,
        target_index: u64,
        target_pixel_name: String,
        target_pixel_symbol: ascii::String,
        target_pixel_type: String,
        join_fee: u64,
    }

    public struct LeaveAllianceEvent has copy, drop {
        sender: address,
        source_index: u64,
        source_pixel_name: String,
        source_pixel_symbol: ascii::String,
        source_pixel_type: String,
        target_index: u64,
        target_pixel_name: String,
        target_pixel_symbol: ascii::String,
        target_pixel_type: String,
    }

    public struct DestroyPixelEvent has copy, drop {
        win_pixel_type: String,
        win_pixel_name: String,
        win_pixel_symbol: ascii::String,
        destroy_pixel_type: String,
        destroy_pixel_name: String,
        destroy_pixel_symbol: ascii::String,
        lucky_pixel_type: String,
        lucky_pixel_name: String,
        lucy_pixel_symbol: ascii::String,
        destroy_amount: u64,
        win_amount: u64,
        lucky_amount: u64,
        sender: address,
    }

    public struct DecoratePixelEvent has copy, drop {
        sender: address,
        pixel_type: String,
        pixel_name: String,
        pixel_symbol: ascii::String,
        image_url: Url,
        fee: u64,
    }

    public fun pixel_list_event (
        creator: address,
        index: u64,
        token_name: String,
        token_symbol: ascii::String,
        token_type: String,
        token_description: String,
        image_url: Option<Url>,
        token_balance: u64,
        sui_balance: u64,
        token_reserve: u64,
        buy_fee_rate: u64,
        sell_fee_rate: u64,
        stake_fee_rate: u64,
        fee: u64,
        target_supply_threshold: u64,
        virtual_sui_amount: u64,
    ) {
        emit(PixelListEvent{
            creator,
            index,
            token_name,
            token_symbol,
            token_type,
            token_description,
            image_url,
            token_balance,
            sui_balance,
            token_reserve,
            buy_fee_rate,
            sell_fee_rate,
            stake_fee_rate,
            fee,
            target_supply_threshold,
            virtual_sui_amount,
        })
    } 

    public fun swap_event (
        is_buy: bool,
        sender: address,
        token_name: String,
        token_symbol: ascii::String,
        token_type: String,
        amount_in: u64,
        amount_out: u64,
        swap_fee_rate: u64,
        stake_fee_rate: u64,
        swap_fee: u64,
        stake_fee: u64,
    ) {
        emit(SwapEvent {
            is_buy,
            sender,
            token_name,
            token_symbol,
            token_type,
            amount_in,
            amount_out,
            swap_fee_rate,
            stake_fee_rate,
            swap_fee,
            stake_fee,
        });
    }

    public fun migrate_pending_event(
        token_name: String,
        token_symbol: ascii::String,
        token_type: String,
        sui_reserve_amount: u64,
        token_reserve_amount: u64,
    ) {
        emit(MigratePendingEvent {
            token_name,
            token_symbol,
            token_type,
            sui_reserve_amount,
            token_reserve_amount,
        })
    }

    public fun stake_event (
        index: u64,
        token_name: String,
        token_symbol: ascii::String,
        token_type: String,
        stake_adddress: address,
        stake_amount: u64,
    ) {
        emit(StakeEvent {
            index,
            token_name,
            token_symbol,
            token_type,
            stake_adddress,
            stake_amount,
        })
    }
    
    public fun unstake_event (
        index: u64,
        token_name: String,
        token_symbol: ascii::String,
        token_type: String,
        unstake_adddress: address,
        unstake_amount: u64,
    ) {
        emit(UnstakeEvent {
            index,
            token_name,
            token_symbol,
            token_type,
            unstake_adddress,
            unstake_amount,
        })
    }

    public fun new_leader_event (
        index: u64,
        token_name: String,
        token_symbol: ascii::String,
        token_type: String,
        leader_address: Option<address>,
        leader_stake_amount: u64,
    ) {
        emit(NewLeaderEvent {
            index,
            token_name,
            token_symbol,
            token_type,
            leader_address,
            leader_stake_amount,
        })
    }

    public fun claim_stake_rewards_event (
        index: u64,
        token_name: String,
        token_symbol: ascii::String,
        token_type: String,
        sender: address,
        rewards: u64,
    ) {
        emit(ClaimStakeRewards {
            index,
            token_name,
            token_symbol,
            token_type,
            sender,
            rewards,
        })
    }

    public fun join_alliance_event (
        sender: address,
        source_index: u64,
        source_pixel_name: String,
        source_pixel_symbol: ascii::String,
        source_pixel_type: String,
        target_index: u64,
        target_pixel_name: String,
        target_pixel_symbol: ascii::String,
        target_pixel_type: String,
        join_fee: u64,
    ) {
        emit(JoinAllianceEvent{
            sender,
            source_index,
            source_pixel_name,
            source_pixel_symbol,
            source_pixel_type,
            target_index,
            target_pixel_name,
            target_pixel_symbol,
            target_pixel_type,
            join_fee,
        })
    }

    public fun leave_alliance_event (
        sender: address,
        source_index: u64,
        source_pixel_name: String,
        source_pixel_symbol: ascii::String,
        source_pixel_type: String,
        target_index: u64,
        target_pixel_name: String,
        target_pixel_symbol: ascii::String,
        target_pixel_type: String,
    ) {
        emit(LeaveAllianceEvent {
            sender,
            source_index,
            source_pixel_name,
            source_pixel_symbol,
            source_pixel_type,
            target_index,
            target_pixel_name,
            target_pixel_symbol,
            target_pixel_type,
        })
    }

    public fun destroy_pixel_event(
        win_pixel_type: String,
        win_pixel_name: String,
        win_pixel_symbol: ascii::String,
        destroy_pixel_type: String,
        destroy_pixel_name: String,
        destroy_pixel_symbol: ascii::String,
        lucky_pixel_type: String,
        lucky_pixel_name: String,
        lucy_pixel_symbol: ascii::String,
        destroy_amount: u64,
        win_amount: u64,
        lucky_amount: u64,
        sender: address,
    ) {
        emit(DestroyPixelEvent {
            win_pixel_type,
            win_pixel_name,
            win_pixel_symbol,
            destroy_pixel_type,
            destroy_pixel_name,
            destroy_pixel_symbol,
            lucky_pixel_type,
            lucky_pixel_name,
            lucy_pixel_symbol,
            destroy_amount,
            win_amount,
            lucky_amount,
            sender,
        })
    }

    public fun decorate_pixel_event(
        sender: address,
        pixel_type: String,
        pixel_name: String,
        pixel_symbol: ascii::String,
        image_url: Url,
        fee: u64,
    ) {
        emit(DecoratePixelEvent{
            sender,
            pixel_type,
            pixel_name,
            pixel_symbol,
            image_url,
            fee,
        })
    }
}