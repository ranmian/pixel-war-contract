module game::math256 {

    const MAX_U256: u256 = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;

    public(package) fun try_add(x: u256, y: u256): (bool, u256) {
        if (x == MAX_U256 && y != 0) return (false, 0);

        let rem = MAX_U256 - x;
        if (y > rem) return (false, 0);

        (true, x + y)
    }

    public(package) fun try_sub(x: u256, y: u256): (bool, u256) {
        if (y > x) (false, 0) else (true, x - y)
    }

    public(package) fun try_mul(x: u256, y: u256): (bool, u256) {
        if (y == 0) return (true, 0);
        if (x > MAX_U256 / y) (false, 0) else (true, x * y)
    }

    public(package) fun try_div_down(x: u256, y: u256): (bool, u256) {
        if (y == 0) (false, 0) else (true, div_down(x, y))
    }

    public(package) fun try_div_up(x: u256, y: u256): (bool, u256) {
        if (y == 0) (false, 0) else (true, div_up(x, y))
    }

    public(package) fun try_mul_div_down(x: u256, y: u256, z: u256): (bool, u256) {
        if (z == 0) return (false, 0);
        let (pred, _) = try_mul(x, y);
        if (!pred) return (false, 0);

        (true, mul_div_down(x, y, z))
    }

    public(package) fun try_mul_div_up(x: u256, y: u256, z: u256): (bool, u256) {
        if (z == 0) return (false, 0);
        let (pred, _) = try_mul(x, y);
        if (!pred) return (false, 0);

        (true, mul_div_up(x, y, z))
    }

    public(package) fun try_mod(x: u256, y: u256): (bool, u256) {
        if (y == 0) (false, 0) else (true, x % y)
    }

    public(package) fun add(x: u256, y: u256): u256 {
        x + y
    }

    public(package) fun sub(x: u256, y: u256): u256 {
        x - y
    }

    public(package) fun mul(x: u256, y: u256): u256 {
        x * y
    }

    public(package) fun div_down(x: u256, y: u256): u256 {
        x / y
    }

    public(package) fun div_up(x: u256, y: u256): u256 {
        if (x == 0) 0 else 1 + (x - 1) / y
    }

    public(package) fun mul_div_down(x: u256, y: u256, z: u256): u256 {
        x * y / z
    }

    public(package) fun mul_div_up(x: u256, y: u256, z: u256): u256 {
        let r = mul_div_down(x, y, z);
        r + if ((x * y) % z > 0) 1 else 0
    }

    public(package) fun min(x: u256, y: u256): u256 {
        if (x < y) x else y
    }

    public(package) fun max(x: u256, y: u256): u256 {
        if (x >= y) x else y
    }

    public(package) fun clamp(x: u256, lower: u256, upper: u256): u256 {
        min(upper, max(lower, x))
    }

    public(package) fun diff(x: u256, y: u256): u256 {
        if (x > y) {
            x - y
        } else {
            y - x
        }
    }

    public(package) fun pow(mut n: u256, mut e: u256): u256 {
        if (e == 0) {
            1
        } else {
            let mut p = 1;
            while (e > 1) {
                if (e % 2 == 1) {
                    p = p * n;
                };
                e = e / 2;
                n = n * n;
            };
            p * n
        }
    }

    public(package) fun sum(nums: vector<u256>): u256 {
        let len = vector::length(&nums);
        let mut i = 0;
        let mut sum = 0;

        while (i < len){
        sum = sum + *vector::borrow(&nums, i);
        i = i + 1;
        };

        sum
    }

    public(package) fun average(x: u256, y: u256): u256 {
        (x & y) + (x ^ y) / 2
    }

    public(package) fun average_vector(nums: vector<u256>): u256{
        let len = vector::length(&nums);

        if (len == 0) return 0;

        let sum = sum(nums);

        sum / (len as u256)
    }

    public(package) fun sqrt_down(x: u256): u256 {
        if (x == 0) return 0;

        let mut result = 1 << ((log2_down(x) >> 1) as u8);

        result = (result + x / result) >> 1;
        result = (result + x / result) >> 1;
        result = (result + x / result) >> 1;
        result = (result + x / result) >> 1;
        result = (result + x / result) >> 1;
        result = (result + x / result) >> 1;
        result = (result + x / result) >> 1;

        min(result, x / result)
    }

    public(package) fun sqrt_up(x: u256): u256 {
        let r = sqrt_down(x);
        r + if (r * r < x) 1 else 0
    }

    public(package) fun log2_down(mut x: u256): u8 {
        let mut result = 0;
        if (x >> 128 > 0) {
        x = x >> 128;
        result = result + 128;
        };

        if (x >> 64 > 0) {
        x = x >> 64;
        result = result + 64;
        };

        if (x >> 32 > 0) {
        x = x >> 32;
        result = result + 32;
        };

        if (x >> 16 > 0) {
        x = x >> 16;
        result = result + 16;
        };

        if (x >> 8 > 0) {
        x = x >> 8;
        result = result + 8;
        };

        if (x >> 4 > 0) {
        x = x >> 4;
        result = result + 4;
        };

        if (x >> 2 > 0) {
        x = x >> 2;
        result = result + 2;
        };

        if (x >> 1 > 0)
        result = result + 1;

        result
    }

    public(package) fun log2_up(x: u256): u16 {
        let r = log2_down(x);
        (r as u16) + if (1 << (r as u8) < x) 1 else 0
    }

    public(package) fun log10_down(mut x: u256): u8 {
        let mut result = 0;

        if (x >= 10000000000000000000000000000000000000000000000000000000000000000) {
        x = x / 10000000000000000000000000000000000000000000000000000000000000000;
        result = result + 64;
        };

        if (x >= 100000000000000000000000000000000) {
        x = x / 100000000000000000000000000000000;
        result = result + 32;
        };

        if (x >= 10000000000000000) {
        x = x / 10000000000000000;
        result = result + 16;
        };

        if (x >= 100000000) {
        x = x / 100000000;
        result = result + 8;
        };

        if (x >= 10000) {
        x = x / 10000;
        result = result + 4;
        };

        if (x >= 100) {
        x = x / 100;
        result = result + 2;
        };

        if (x >= 10)
        result = result + 1;

        result
    }

    public(package) fun log10_up(x: u256): u8 {
        let r = log10_down(x);
        r + if (pow(10, (r as u256)) < x) 1 else 0
    }

    public(package) fun log256_down(mut x: u256): u8 {
        let mut result = 0;

        if (x >> 128 > 0) {
        x = x >> 128;
        result = result + 16;
        };

        if (x >> 64 > 0) {
        x = x >> 64;
        result = result + 8;
        };

        if (x >> 32 > 0) {
        x = x >> 32;
        result = result + 4;
        };

        if (x >> 16 > 0) {
        x = x >> 16;
        result = result + 2;
        };

        if (x >> 8 > 0)
        result = result + 1;

        result
    }

    public(package) fun log256_up(x: u256): u8 {
        let r = log256_down(x);
        r + if (1 << ((r << 3)) < x) 1 else 0
    }
}