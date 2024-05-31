module game::event {
    use std::string::String;
    use sui::event::emit;
    use sui::url;

    public struct New_Pixel_Event has copy, drop {
        global: ID,
        index: u64,
        name: String,
        image_url: Option<url::Url>,
    }

    public struct Swap_Event has copy, drop {
        index: u64,
        name: String,
        is_buy: bool,
        balance_x: u64,
        balance_y: u64,
        balance_fee: u64,
    }

    public struct Be_Leader_Event has copy, drop {
        index: u64,
        name: String,
        leader_address: address,
        be_leader_time: u64,
        balance: u64,
    }

    public struct Lose_Leader_Event has copy, drop {
        index: u64,
        name: String,
        old_leader_address: address,
    }

    public(package) fun new_pixel_event(
        global: ID,
        index: u64,
        name: String,
        image_url: Option<url::Url>,
    ) {
        emit(New_Pixel_Event {
            global,
            index,
            name,
            image_url,
        })
    }

    public(package) fun swap_event(
        index: u64,
        name: String,
        is_buy: bool,
        balance_x: u64,
        balance_y: u64,
        balance_fee: u64,
    ) {
        emit(Swap_Event {
            index,
            name,
            is_buy,
            balance_x,
            balance_y,
            balance_fee
        })
    }

    public(package) fun be_leader_event(
        index: u64,
        name: String,
        leader_address: address,
        be_leader_time: u64,
        balance: u64,
    ) {
        emit(Be_Leader_Event {
            index,
            name,
            leader_address,
            be_leader_time,
            balance,
        })
    }

    public(package) fun lose_leader_event(
        index: u64,
        name: String,
        old_leader_address: address,
    ) {
        emit(Lose_Leader_Event{
            index,
            name,
            old_leader_address
        })
    }
}