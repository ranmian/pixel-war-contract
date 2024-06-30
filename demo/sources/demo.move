module demo::demo {
    use sui::sui::SUI;
    use sui::coin::{Self, Coin};
    use sui::balance::{Self, Balance};
    use sui::table::{Self, Table};
    use sui::vec_map::{Self, VecMap};

    const E_INVALID_LAND_INDEX: u64 = 0;
    const E_LAND_INDEX_EXIST: u64 = 1;

    public struct Global has key {
        id: UID,
        sui_amount: u64,
        land_index_map: vector<u64>,
        land_list: Table<u64, Land>,
    }

    public struct Land has store {
        index: u64,
        name: vector<u8>,
        sui_balance: Balance<SUI>,
    }

    fun init(ctx: &mut TxContext) {
        let global = Global {
            id: object::new(ctx),
            sui_amount: 0,
            land_index_map: vector::empty(),
            land_list: table::new(ctx),
        };

        transfer::share_object(global);
    }

    public fun new_land(
        global: &mut Global,
        mut pay_coin: Coin<SUI>,
        index: u64, 
        name: vector<u8>,
        ctx: &mut TxContext,
    ): Coin<SUI> {
        assert!(
            vector::contains(&global.land_index_map, &index),
            E_LAND_INDEX_EXIST,
        );
        assert!(
            table::contains(&global.land_list, index),
            E_LAND_INDEX_EXIST,
        );

        vector::push_back(&mut global.land_index_map, index);

        let land = Land {
            index,
            name,
            sui_balance: coin::into_balance(coin::split(&mut pay_coin, 1_000_000_000, ctx)),
        };

        table::add(&mut global.land_list, index, land);

        if (coin::value(&pay_coin) == 0) {
            coin::destroy_zero(pay_coin);
            coin::zero(ctx)
        } else {
            pay_coin
        }
    }

    public fun update_land(
        global: &mut Global,
        ctx: &mut TxContext,
    ) {
        let map_size = vector::length(&global.land_index_map);

        let mut i = 0;
        while(i < map_size) {
            let index = *(vector::borrow<u64>(&global.land_index_map, i));

            if (!table::contains(&global.land_list, index)) {
                i = i+1;
                continue
            };

            let land = table::borrow_mut(&mut global.land_list, index);
            let land_balance_value = balance::value(&land.sui_balance);
            transfer::public_transfer(
                coin::take(&mut land.sui_balance, land_balance_value, ctx),
                tx_context::sender(ctx),
            );
            i = i+1;
        };
    }
}
