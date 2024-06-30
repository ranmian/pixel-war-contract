module pvp::version {
    use pvp::constants;
    use pvp::errors;

    public fun current_version(): u64 {
        constants::version()
    }

    public fun check_version(version: u64) {
        assert!(version == current_version(), errors::invalid_version());
    }
}