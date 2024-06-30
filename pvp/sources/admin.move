module pvp::admin {
    public struct AdminCap has key {
        id: UID
    }

    public(package) fun init_admin(ctx: &mut TxContext) {
        let admin_cap = AdminCap {
            id: object::new(ctx)
        };

        transfer::transfer(admin_cap, tx_context::sender(ctx));
    }
}