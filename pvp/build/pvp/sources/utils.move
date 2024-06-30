module pvp::utils {
    use std::ascii::into_bytes;
    use std::string::{Self, String};
    use std::type_name::{get, into_string};

    public fun get_pixel_type<T>(): String {
        string::utf8(into_bytes(into_string(get<T>())))
    }
}