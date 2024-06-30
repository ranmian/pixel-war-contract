module pvp::math {
    const MAX_U256: u256 = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;

    public fun add (x: u256, y: u256): u256 {
        if (x == MAX_U256 && y != 0) {
            return 0
        };

        let rem = MAX_U256 - x;
        if (y > rem) {
            return 0
        };

        x + y
    }

    public fun sub (x: u256, y: u256): u256 {
        if (y > x) {
            return 0
        };

        x - y
    }

    public fun mul (x: u256, y: u256): u256 {
        if (x == 0) {
            return 0
        };

        let value = x * y;
        if (value / x != y) {
            return 0
        };
        
        value
    }

    public fun div (x: u256, y: u256): u256 {
        if (y == 0) {
            return 0
        };

        x / y
    }

    public fun mul_div(x: u256, y: u256, z: u256): u256 {
        div(mul(x, y), z)
    }
}