module game::utils {
    const MIST_PER_SUI: u64 = 1_000_000_000;

    public(package) fun mist(value: u64): u64 {
        MIST_PER_SUI * value
    }
}