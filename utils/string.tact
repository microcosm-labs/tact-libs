/// SPDX-License-Identifier: MIT
/// Copyright (C) Microcosm Labs 2024
/// Tact library for string manipulation
/// Author: @0kenx
/// Version: 0.0.7
///
/// Methods starting with `ss_` are for "short strings" or "string slices" that fit within the data section of one single slice.
/// Short strings shall be passed in as a `Slice`.

import "./extra.fc";

@name(xor)
native _strlib_xor(a: Int, b: Int): Int;

@name(equal_slices)
native _strlib_equalSlices(a: Slice, b: Slice): Int;

/// Splits a short string, returning the first N characters (ASCII only).
/// If the `pos` is greater than the length of the string, the entire string is returned.
/// Returns a `Slice` that can be converted to a `String` using `asString()`.
extends fun ss_lsplit_before(self: Slice, pos: Int): Slice {
    let bits_to_load: Int = min(pos*8, self.bits());
    let str_as_int: Slice = self.preloadBits(bits_to_load);
    return str_as_int;
}

inline extends fun ss_lsplit_before(self: String, pos: Int): Slice {
    return self.asSlice().ss_lsplit_before(pos);
}

/// Splits a short string, skipping the first N characters (ASCII only).
/// If the `pos` is greater than the length of the string, an empty string is returned.
/// Returns a `Slice` that can be converted to a `String` using `asString()`.
extends fun ss_lsplit_after(self: Slice, pos: Int): Slice {
    let bits: Int = self.bits();
    let bits_to_skip: Int = min(pos*8, bits);
    self.skipBits(bits_to_skip);
    let str_as_int: Slice = self.preloadBits(bits-bits_to_skip); // Note: `preloadBits` is cheaper than `loadBits`
    return str_as_int;
}

inline extends fun ss_lsplit_after(self: String, pos: Int): Slice {
    return self.asSlice().ss_lsplit_after(pos);
}

/// Splits a short string from the right, skipping the last N characters (ASCII only).
/// If the `pos` is greater than the length of the string, the entire string is returned.
/// Returns a `Slice` that can be converted to a `String` using `asString()`.
extends fun ss_rsplit_before(self: Slice, pos: Int): Slice {
    let bits_to_load: Int = max(self.bits() - pos*8 , 0);
    let str_as_int: Slice = self.preloadBits(bits_to_load);
    return str_as_int;
}

inline extends fun ss_rsplit_before(self: String, pos: Int): Slice {
    return self.asSlice().ss_rsplit_before(pos);
}

/// Splits a short string from the right, returning the last N characters (ASCII only).
/// If the `pos` is greater than the length of the string, an empty string is returned.
/// Returns a `Slice` that can be converted to a `String` using `asString()`.
extends fun ss_rsplit_after(self: Slice, pos: Int): Slice {
    let bits: Int = self.bits();
    let bits_to_skip: Int = max(self.bits() - pos*8 , 0);
    self.skipBits(bits_to_skip);
    let str_as_int: Slice = self.preloadBits(bits-bits_to_skip);
    return str_as_int;
}

inline extends fun ss_rsplit_after(self: String, pos: Int): Slice {
    return self.asSlice().ss_rsplit_after(pos);
}

/// Determines if a short string starts with a prefix.
extends fun ss_starts_with(self: Slice, prefix: Slice): Bool {
    let bits: Int = prefix.bits();
    if (bits > self.bits()) {
        return false;
    }
    return _strlib_equalSlices(prefix.preloadBits(bits), self.preloadBits(bits)) != 0;
}

inline extends fun ss_starts_with(self: String, prefix: String): Bool {
    return self.asSlice().ss_starts_with(prefix.asSlice());
}

/// Determines if a short string ends with a suffix.
extends fun ss_ends_with(self: Slice, suffix: Slice): Bool {
    let suffix_bits: Int = suffix.bits();
    let str_bits: Int = self.bits();
    if (suffix_bits > str_bits) {
        return false;
    }
    self.skipBits(str_bits - suffix_bits);
    let str_end_slice: Slice = self.preloadBits(suffix_bits);
    return _strlib_equalSlices(str_end_slice, suffix) != 0;
}

inline extends fun ss_ends_with(self: String, suffix: String): Bool {
    return self.asSlice().ss_ends_with(suffix.asSlice());
}

/// Determines if two short strings are equal.
inline extends fun eq(self: Slice, other: Slice): Bool {
    return _strlib_equalSlices(self, other) != 0;
}

inline extends fun eq(self: String, other: String): Bool {
    return _strlib_equalSlices(self.asSlice(), other.asSlice()) != 0;
}

/// Compares two short strings.
/// Returns -1 if `self` is less than `other`, 0 if they are equal, and 1 if `self` is greater than `other` (the first non-matching char in ASCII).
extends fun ss_compare(self: Slice, other: Slice): Int {
    let self_bits: Int = self.bits();
    let other_bits: Int = other.bits();
    let bits: Int = min(self_bits, other_bits);
    while (bits > 0) {
        let self_as_int: Int = self.loadUint(min(bits, 256));
        let other_as_int: Int = other.loadUint(min(bits, 256));
        if (self_as_int < other_as_int) {
            return -1;
        } else if (self_as_int > other_as_int) {
            return 1;
        }
        bits = bits - 256;
    }
    if (self_bits < other_bits) {
        return -1;
    } else if (self_bits > other_bits) {
        return 1;
    }
    return 0;
}

inline extends fun ss_compare(self: String, other: String): Int {
    return self.asSlice().ss_compare(other.asSlice());
}

/// Compares two short strings, returning the index of the first non-matching character, characters are counted 1...m.
/// Ruturns 0 if the strings are equal, -n if `self` is less than `other` at the n-th position, and n if `self` is greater than `other` at the n-th position.
extends fun ss_diff(self: Slice, other: Slice): Int {
    let self_bits: Int = self.bits();
    let other_bits: Int = other.bits();
    let bits: Int = min(self_bits, other_bits);
    let i: Int = 0;
    while (i < bits) {
        let self_as_int: Int = self.loadUint(8);
        let other_as_int: Int = other.loadUint(8);
        if (self_as_int < other_as_int) {
            return - i / 8 - 1;
        } else if (self_as_int > other_as_int) {
            return i / 8 + 1;
        }
        i = i + 8;
    }
    if (self_bits < other_bits) {
        return - i / 8 - 1;
    } else if (self_bits > other_bits) {
        return i / 8 + 1;
    }
    return 0;
}

inline extends fun ss_diff(self: String, other: String): Int {
    return self.asSlice().ss_diff(other.asSlice());
}

/// If the string starts with a prefix, returns the string with the prefix removed.
/// Otherwise, returns the original string.
/// Returns a `Slice` that can be converted to a `String` using `asString()`.
extends fun ss_remove_prefix(self: Slice, prefix: Slice): Slice {
    if (self.ss_starts_with(prefix)) {
        return self.ss_lsplit_after(prefix.bits() / 8);
    }
    return self;
}

inline extends fun ss_remove_prefix(self: String, prefix: String): Slice {
    return self.asSlice().ss_remove_prefix(prefix.asSlice());
}

/// If the string ends with a suffix, returns the string with the suffix removed.
/// Otherwise, returns the original string.
/// Returns a `Slice` that can be converted to a `String` using `asString()`.
extends fun ss_remove_suffix(self: Slice, suffix: Slice): Slice {
    if (self.ss_ends_with(suffix)) {
        return self.ss_rsplit_before(suffix.bits() / 8);
    }
    return self;
}

inline extends fun ss_remove_suffix(self: String, suffix: String): Slice {
    return self.asSlice().ss_remove_suffix(suffix.asSlice());
}

/// Concatenates several short strings.
/// The total length of the strings must fit within 1 slice, otherwise the behavior is undefined.
/// Returns a `Slice` that can be converted to a `String` using `asString()`.
inline fun ss_concat(str1: Slice, str2: Slice): Slice {
    return beginCell().storeSlice(str1).storeSlice(str2).asSlice();
}

inline fun ss_concat3(str1: Slice, str2: Slice, str3: Slice): Slice {
    return beginCell().storeSlice(str1).storeSlice(str2).storeSlice(str3).asSlice();
}

inline fun ss_concat4(str1: Slice, str2: Slice, str3: Slice, str4: Slice): Slice {
    return beginCell().storeSlice(str1).storeSlice(str2).storeSlice(str3).storeSlice(str4).asSlice();
}

inline fun ss_concat5(str1: Slice, str2: Slice, str3: Slice, str4: Slice, str5: Slice): Slice {
    return beginCell().storeSlice(str1).storeSlice(str2).storeSlice(str3).storeSlice(str4).storeSlice(str5).asSlice();
}

inline fun ss_concat6(str1: Slice, str2: Slice, str3: Slice, str4: Slice, str5: Slice, str6: Slice): Slice {
    return beginCell().storeSlice(str1).storeSlice(str2).storeSlice(str3).storeSlice(str4).storeSlice(str5).storeSlice(str6).asSlice();
}

inline fun ss_concat7(str1: Slice, str2: Slice, str3: Slice, str4: Slice, str5: Slice, str6: Slice, str7: Slice): Slice {
    return beginCell().storeSlice(str1).storeSlice(str2).storeSlice(str3).storeSlice(str4).storeSlice(str5).storeSlice(str6).storeSlice(str7).asSlice();
}

inline fun ss_concat8(str1: Slice, str2: Slice, str3: Slice, str4: Slice, str5: Slice, str6: Slice, str7: Slice, str8: Slice): Slice {
    return beginCell().storeSlice(str1).storeSlice(str2).storeSlice(str3).storeSlice(str4).storeSlice(str5).storeSlice(str6).storeSlice(str7).storeSlice(str8).asSlice();
}

inline fun ss_concat9(str1: Slice, str2: Slice, str3: Slice, str4: Slice, str5: Slice, str6: Slice, str7: Slice, str8: Slice, str9: Slice): Slice {
    return beginCell().storeSlice(str1).storeSlice(str2).storeSlice(str3).storeSlice(str4).storeSlice(str5).storeSlice(str6).storeSlice(str7).storeSlice(str8).storeSlice(str9).asSlice();
}

/// Concatenates several short strings.
inline fun string_concat(str1: String, str2: String): String {
    let b: StringBuilder = beginString();
    b.append(str1); b.append(str2);
    return b.toString();
}

inline fun string_concat3(str1: String, str2: String, str3: String): String {
    let b: StringBuilder = beginString();
    b.append(str1); b.append(str2); b.append(str3);
    return b.toString();
}

inline fun string_concat4(str1: String, str2: String, str3: String, str4: String): String {
    let b: StringBuilder = beginString();
    b.append(str1); b.append(str2); b.append(str3); b.append(str4);
    return b.toString();
}

inline fun string_concat5(str1: String, str2: String, str3: String, str4: String, str5: String): String {
    let b: StringBuilder = beginString();
    b.append(str1); b.append(str2); b.append(str3); b.append(str4); b.append(str5);
    return b.toString();
}

inline fun string_concat6(str1: String, str2: String, str3: String, str4: String, str5: String, str6: String): String {
    let b: StringBuilder = beginString();
    b.append(str1); b.append(str2); b.append(str3); b.append(str4); b.append(str5); b.append(str6);
    return b.toString();
}

inline fun string_concat7(str1: String, str2: String, str3: String, str4: String, str5: String, str6: String, str7: String): String {
    let b: StringBuilder = beginString();
    b.append(str1); b.append(str2); b.append(str3); b.append(str4); b.append(str5); b.append(str6); b.append(str7);
    return b.toString();
}

inline fun string_concat8(str1: String, str2: String, str3: String, str4: String, str5: String, str6: String, str7: String, str8: String): String {
    let b: StringBuilder = beginString();
    b.append(str1); b.append(str2); b.append(str3); b.append(str4); b.append(str5); b.append(str6); b.append(str7); b.append(str8);
    return b.toString();
}

inline fun string_concat9(str1: String, str2: String, str3: String, str4: String, str5: String, str6: String, str7: String, str8: String, str9: String): String {
    let b: StringBuilder = beginString();
    b.append(str1); b.append(str2); b.append(str3); b.append(str4); b.append(str5); b.append(str6); b.append(str7); b.append(str8); b.append(str9);
    return b.toString();
}

/// Concatenates several short strings into a Comment (prefixed with 32 0s).
inline fun string_concat_comment(str1: String, str2: String): Cell {
    let b: StringBuilder = beginComment();
    b.append(str1); b.append(str2);
    return b.toCell();
}

inline fun string_concat_comment3(str1: String, str2: String, str3: String): Cell {
    let b: StringBuilder = beginComment();
    b.append(str1); b.append(str2); b.append(str3);
    return b.toCell();
}

inline fun string_concat_comment4(str1: String, str2: String, str3: String, str4: String): Cell {
    let b: StringBuilder = beginComment();
    b.append(str1); b.append(str2); b.append(str3); b.append(str4);
    return b.toCell();
}

inline fun string_concat_comment5(str1: String, str2: String, str3: String, str4: String, str5: String): Cell {
    let b: StringBuilder = beginComment();
    b.append(str1); b.append(str2); b.append(str3); b.append(str4); b.append(str5);
    return b.toCell();
}

inline fun string_concat_comment6(str1: String, str2: String, str3: String, str4: String, str5: String, str6: String): Cell {
    let b: StringBuilder = beginComment();
    b.append(str1); b.append(str2); b.append(str3); b.append(str4); b.append(str5); b.append(str6);
    return b.toCell();
}

inline fun string_concat_comment7(str1: String, str2: String, str3: String, str4: String, str5: String, str6: String, str7: String): Cell {
    let b: StringBuilder = beginComment();
    b.append(str1); b.append(str2); b.append(str3); b.append(str4); b.append(str5); b.append(str6); b.append(str7);
    return b.toCell();
}

inline fun string_concat_comment8(str1: String, str2: String, str3: String, str4: String, str5: String, str6: String, str7: String, str8: String): Cell {
    let b: StringBuilder = beginComment();
    b.append(str1); b.append(str2); b.append(str3); b.append(str4); b.append(str5); b.append(str6); b.append(str7); b.append(str8);
    return b.toCell();
}

inline fun string_concat_comment9(str1: String, str2: String, str3: String, str4: String, str5: String, str6: String, str7: String, str8: String, str9: String): Cell {
    let b: StringBuilder = beginComment();
    b.append(str1); b.append(str2); b.append(str3); b.append(str4); b.append(str5); b.append(str6); b.append(str7); b.append(str8); b.append(str9);
    return b.toCell();
}

/// Returns the lowest index in the string where a substring is found.
/// Returns -1 if the substring is not found.
extends fun ss_find(self: Slice, sub: Slice): Int {
    let sub_bits: Int = sub.bits();
    let str_bits: Int = self.bits();
    if (sub_bits > str_bits) {
        return -1;
    }
    let i: Int = 0;
    while (i < str_bits - sub_bits + 1) {
        if (_strlib_equalSlices(self.preloadBits(sub_bits), sub) != 0) {
            return i / 8;
        }
        self.skipBits(8);
        i = i + 8;
    }
    return -1;
}

inline extends fun ss_find(self: String, sub: String): Int {
    return self.asSlice().ss_find(sub.asSlice());
}

/// Determines if a short string contains a substring.
inline extends fun ss_contains(self: Slice, sub: Slice): Bool {
    return self.ss_find(sub) != -1;
}

inline extends fun ss_contains(self: String, sub: String): Bool {
    return self.ss_find(sub) != -1;
}

/// Determines if a short string is empty or if all characters are ASCII.
/// ASCII characters are in the range 0x00 to 0x7F.
extends fun ss_is_ascii(self: Slice): Bool {
    let bits: Int = self.bits();
    let i: Int = 0;
    while (i < bits) {
        if (self.loadUint(8) > 0x7F) {
            return false;
        }
        i = i + 8;
    }
    return true;
}

inline extends fun ss_is_ascii(self: String): Bool {
    return self.asSlice().ss_is_ascii();
}

/// Determines if all characters in a short string are alphanumeric and there is at least one character.
/// Alphanumeric characters are in the ranges 0x30 to 0x39, 0x41 to 0x5A, and 0x61 to 0x7A.
extends fun ss_is_alnum(self: Slice): Bool {
    let bits: Int = self.bits();
    let i: Int = 0;
    while (i < bits) {
        let str_as_int: Int = self.loadUint(8);
        if (str_as_int < 0x30 || (str_as_int > 0x39 && str_as_int < 0x41) || (str_as_int > 0x5A && str_as_int < 0x61) || str_as_int > 0x7A) {
            return false;
        }
        i = i + 8;
    }
    return true;
}

inline extends fun ss_is_alnum(self: String): Bool {
    return self.asSlice().ss_is_alnum();
}

/// Determines if all characters in a short string are alphabetic and there is at least one character.
/// Alphabetic characters are in the ranges 0x41 to 0x5A and 0x61 to 0x7A.
extends fun ss_is_alpha(self: Slice): Bool {
    let bits: Int = self.bits();
    let i: Int = 0;
    while (i < bits) {
        let str_as_int: Int = self.loadUint(8);
        if ((str_as_int < 0x41 || str_as_int > 0x5A) && (str_as_int < 0x61 || str_as_int > 0x7A)) {
            return false;
        }
        i = i + 8;
    }
    return true;
}

inline extends fun ss_is_alpha(self: String): Bool {
    return self.asSlice().ss_is_alpha();
}


/// Determines if all characters in a short string are numeric and there is at least one character.
/// Numeric characters are in the range 0x30 to 0x39.
extends fun ss_is_digit(self: Slice): Bool {
    let bits: Int = self.bits();
    let i: Int = 0;
    while (i < bits) {
        let str_as_int: Int = self.loadUint(8);
        if (str_as_int < 0x30 || str_as_int > 0x39) {
            return false;
        }
        i = i + 8;
    }
    return true;
}

inline extends fun ss_is_digit(self: String): Bool {
    return self.asSlice().ss_is_digit();
}

/// Determines if all characters in a short string are hexadecimal and there is at least one character.
/// Hexadecimal characters are in the ranges 0x30 to 0x39, 0x41 to 0x46, and 0x61 to 0x66.
extends fun ss_is_hexdigit(self: Slice): Bool {
    let bits: Int = self.bits();
    let i: Int = 0;
    while (i < bits) {
        let str_as_int: Int = self.loadUint(8);
        if (str_as_int < 0x30 || (str_as_int > 0x39 && str_as_int < 0x41) || (str_as_int > 0x46 && str_as_int < 0x61) || str_as_int > 0x66) {
            return false;
        }
        i = i + 8;
    }
    return true;
}

inline extends fun ss_is_hexdigit(self: String): Bool {
    return self.asSlice().ss_is_hexdigit();
}

/// Determines if all characters in a short string are hexadecimal with 0x or 0X prefix and there is at least one character.
/// Hexadecimal characters are in the ranges 0x30 to 0x39, 0x41 to 0x46, 0x61 to 0x66, 0x58 and 0x78.
extends fun ss_is_hex(self: Slice): Bool {
    let bits: Int = self.bits();
    let i: Int = 0;
    while (i < bits) {
        let str_as_int: Int = self.loadUint(8);
        if (str_as_int < 0x30 || (str_as_int > 0x39 && str_as_int < 0x41) || (str_as_int > 0x46 && str_as_int < 0x61) || str_as_int > 0x66 || str_as_int != 0x58 || str_as_int != 0x78) {
            return false;
        }
        i = i + 8;
    }
    return true;
}

inline extends fun ss_is_hex(self: String): Bool {
    return self.asSlice().ss_is_hex();
}

/// Determines if all characters in a short string are lowercase and there is at least one character.
/// Lowercase characters are in the range 0x61 to 0x7A.
extends fun ss_is_lower(self: Slice): Bool {
    let bits: Int = self.bits();
    let i: Int = 0;
    while (i < bits) {
        let str_as_int: Int = self.loadUint(8);
        if (str_as_int < 0x61 || str_as_int > 0x7A) {
            return false;
        }
        i = i + 8;
    }
    return true;
}

inline extends fun ss_is_lower(self: String): Bool {
    return self.asSlice().ss_is_lower();
}

/// Determines if all characters in a short string are uppercase and there is at least one character.
/// Uppercase characters are in the range 0x41 to 0x5A.
extends fun ss_is_upper(self: Slice): Bool {
    let bits: Int = self.bits();
    let i: Int = 0;
    while (i < bits) {
        let str_as_int: Int = self.loadUint(8);
        if (str_as_int < 0x41 || str_as_int > 0x5A) {
            return false;
        }
        i = i + 8;
    }
    return true;
}

inline extends fun ss_is_upper(self: String): Bool {
    return self.asSlice().ss_is_upper();
}

/// Parses a short string as an unsigned integer.
/// `base` is the base to parse the integer in. Possible values are 0, 2, 8, 10, and 16.
/// If `base` is specified, then the string may not contain a prefix.
/// If `base` is 0, the base is determined from the prefix of the string:
/// - If the string starts with "0x" or "0X", the base is 16.
/// - If the string starts with "0b" or "0B", the base is 2.
/// - If the string starts with "0", the base is 8.
/// - Otherwise, the base is 10.
/// This function will return 0 if the string is empty or if the string does not contain a valid integer.
/// This function will try parsing characters until it encounters a non-numeric character.
extends fun ss_parse_uint(self: Slice, base: Int): Int {
    let actual_base: Int = base;
    if (base == 0) {
        if (self.ss_starts_with("0x".asSlice()) || self.ss_starts_with("0X".asSlice())) {
            actual_base = 16;
            self.skipBits(16);
        } else if (self.ss_starts_with("0b".asSlice()) || self.ss_starts_with("0B".asSlice())) {
            actual_base = 2;
            self.skipBits(16);
        } else if (self.ss_starts_with("0".asSlice())) {
            actual_base = 8;
            self.skipBits(8);
        } else {
            actual_base = 10;
        }
    }
    let res: Int = 0;
    let i: Int = 0;
    let bits: Int = self.bits();
    if (actual_base == 16) {
        res = self.ss_parse_uint_hex();
    } else if (actual_base == 10) {
        res = self.ss_parse_uint_dec();
    } else if (actual_base == 8) {
        res = self.ss_parse_uint_oct();
    } else if (actual_base == 2) {
        res = self.ss_parse_uint_bin();
    }
    return res;
}

inline extends fun ss_parse_uint(self: String, base: Int): Int {
    return self.asSlice().ss_parse_uint(base);
}

extends fun ss_parse_uint_bin(self: Slice): Int {
    let res: Int = 0;
    let i: Int = 0;
    let bits: Int = self.bits();
    while (i < bits) {
        res = res << 1;
        let str_as_int: Int = self.loadUint(8);
        if (str_as_int >= 0x30 && str_as_int <= 0x31) {
            str_as_int = str_as_int - 0x30;
        } else {
            str_as_int = 0;
            i = bits; // break;
        }
        res = res + str_as_int;
        i = i + 8;
    }
    return res;
}

inline extends fun ss_parse_uint_bin(self: String): Int {
    return self.asSlice().ss_parse_uint_bin();
}

extends fun ss_parse_uint_oct(self: Slice): Int {
    let res: Int = 0;
    let i: Int = 0;
    let bits: Int = self.bits();
    while (i < bits) {
        res = res << 3;
        let str_as_int: Int = self.loadUint(8);
        if (str_as_int >= 0x30 && str_as_int <= 0x37) {
            str_as_int = str_as_int - 0x30;
        } else {
            str_as_int = 0;
            i = bits; // break;
        }
        res = res + str_as_int;
        i = i + 8;
    }
    return res;
}

inline extends fun ss_parse_uint_oct(self: String): Int {
    return self.asSlice().ss_parse_uint_oct();
}

extends fun ss_parse_uint_hex(self: Slice): Int {
    let res: Int = 0;
    let i: Int = 0;
    let bits: Int = self.bits();
    while (i < bits) {
        res = res << 4;
        let str_as_int: Int = self.loadUint(8);
        if (str_as_int >= 0x30 && str_as_int <= 0x39) {
            str_as_int = str_as_int - 0x30;
        } else if (str_as_int >= 0x41 && str_as_int <= 0x46) {
            str_as_int = str_as_int - 0x41 + 10;
        } else if (str_as_int >= 0x61 && str_as_int <= 0x66) {
            str_as_int = str_as_int - 0x61 + 10;
        } else {
            str_as_int = 0;
            i = bits; // break;
        }
        res = res + str_as_int;
        i = i + 8;
    }
    return res;
}

inline extends fun ss_parse_uint_hex(self: String): Int {
    return self.asSlice().ss_parse_uint_hex();
}

extends fun ss_parse_uint_dec(self: Slice): Int {
    let res: Int = 0;
    let i: Int = 0;
    let bits: Int = self.bits();
    while (i < bits) {
        res = res * 10;
        let str_as_int: Int = self.loadUint(8);
        if (str_as_int >= 0x30 && str_as_int <= 0x39) {
            str_as_int = str_as_int - 0x30;
        } else {
            str_as_int = 0;
            i = bits; // break;
        }
        res = res + str_as_int;
        i = i + 8;
    }
    return res;
}

inline extends fun ss_parse_uint_dec(self: String): Int {
    return self.asSlice().ss_parse_uint_dec();
}

/// Parses a short string as tokens.
/// A token is in the form of `integer` or `123n` interpreted as nanotons, or `integer.decimal`, `integer.` or `.decimal` interpreted as tons.
/// The number of decimal places is assumed to be 9.
/// This function will return 0 if the string is empty or if the string does not contain a valid token.
/// This function will try parsing characters until it encounters a non-valid character.
/// The output is an integer with 9 decimal places.
extends fun ss_parse_tokens(self: Slice): Int {
    let i: Int = 0;
    let integer: Int = 0;
    let decimal: Int = 0;
    let decimal_places: Int = -1;
    let bits: Int = self.bits();
    while (i < bits && decimal_places < 9) {
        let str_as_int: Int = self.loadUint(8);
        if (str_as_int >= 0x30 && str_as_int <= 0x39) {
            if (decimal_places >= 0) {
                decimal = decimal * 10 + str_as_int - 0x30;
                decimal_places = decimal_places + 1;
            } else {
                integer = integer * 10 + str_as_int - 0x30;
            }
        } else if (str_as_int == 0x2E) {  // .
            if (decimal_places >= 0) {
                i = bits; // break;
            } else {
                decimal_places = 0;
            }
        } else if (str_as_int == 0x5F) {  // underscore
            // do nothing
        } else {
            i = bits; // break;
        }
        i = i + 8;
    }
    if (decimal_places >= 0) {
        while (decimal_places < 9) {
            decimal = decimal * 10;
            decimal_places = decimal_places + 1;
        }
        return integer * 1000000000 + decimal;
    } else {
        return integer;
    }
}

inline extends fun ss_parse_tokens(self: String): Int {
    return self.asSlice().ss_parse_tokens();
}

/// Parses a short string as an Address in EQ or UQ format.
/// Parses the first 48 chars if input is longer.
/// Returns the address as a `Slice` that can be loaded using `loadAddress`.
/// Note: TON EQ/UQ addresses are 48 characters long and are encoded in base64url (RFC4548 ch.5).
/// It decodes to 288 bits (36 bytes) and has format: 
/// <E/U 1 byte> <chain id 1 byte> <addr 32 bytes> <crc 2 bytes>
/// Address in Slice is stored as 267 bits: https://docs.ton.org/develop/data-formats/msg-tlb#addr_std10
/// <11 bits> <size 256 bits>
/// Note: The checksum is not verified.
extends fun ss_parse_address(self: Slice): Slice {
    let bits: Int = self.bits();
    require(bits >= 384, "Strlib::ss_parse_address: Invalid address");
    let addr_dec: Slice = self.preloadBits(384).fromBase64();
    addr_dec.skipBits(16);
    let addr: Int = addr_dec.preloadUint(256);
    return beginCell().storeUint(1024, 11).storeUint(addr, 256).asSlice();
}

inline extends fun ss_parse_address(self: String): Slice {
    return self.asSlice().ss_parse_address();
}

/// Convert a short string as an Address in EQ or UQ format to an address in hex format.
/// Parses the first 48 chars if input is longer.
/// `prefix` is whether the output should have a "0:" prefix.
/// Returns the address as a `Slice` that can be converted to a `String` using `asString()`.
/// Note: The checksum is not verified.
/// Note: Only supports workchain 0.
extends fun ss_address_to_hex(self: Slice, prefix: Bool): Slice {
    let bits: Int = self.bits();
    require(bits >= 384, "Strlib::ss_address_to_hex: Invalid address");
    let addr_dec: Slice = self.preloadBits(384).fromBase64();
    addr_dec.skipBits(16);
    let addr: Int = addr_dec.preloadUint(256);
    if (prefix) {
        return ss_concat("0:".asSlice(), addr.to_hex(64, false));
    }
    return addr.to_hex(64, false);
}

inline extends fun ss_address_to_hex(self: String, prefix: Bool): Slice {
    return self.asSlice().ss_address_to_hex(prefix);
}

/// Converts an Address to a EQ/UQ string.
/// `bounceable` is whether the address is bounceable (EQ) or non-bounceable (UQ).
/// Returns a `Slice` that can be converted to a `String` using `asString()`.
extends fun to_base64(self: Address, bounceable: Bool): Slice {
    let b: Builder = beginCell();
    if (bounceable) {
        b = b.storeUint(4352, 16);
    } else {
        b = b.storeUint(20736, 16);
    }
    let s: Slice = self.asSlice();
    s.skipBits(11);
    let addr: Int = s.preloadUint(256);
    b = b.storeUint(addr, 256);
    b = b.storeUint(_strlib_crc16(b.asSlice()), 16);
    return b.asSlice().toBase64();
}

/// Converts an Address to a hex string.
/// `prefix` is whether the output should have a "0:" prefix.
/// Returns a `Slice` that can be converted to a `String` using `asString()`.
extends fun to_hex(self: Address, prefix: Bool): Slice {
    let s: Slice = self.asSlice();
    s.skipBits(11);
    let addr: Int = s.preloadUint(256);
    if (prefix) {
        return ss_concat("0:".asSlice(), addr.to_hex(64, false));
    }
    return addr.to_hex(64, false);
}

/// Converts an integer to a hex string.
/// `num` is the integer to convert.
/// `nibbles` is the number of nibbles(4-bits, or a hex character) the output should have.
/// `prefix` is whether the output should have a "0x" prefix.
/// If `nibbles` is less than the number of nibbles needed to represent `num`, the output will have the MSBs truncated.
/// If `nibbles` is 0 then the output will have the minimum number of nibbles needed to represent `num`.
/// If `nibbles` is greater than the number of nibbles needed to represent `num`, the output will be left-padded with 0s.
/// Returns a `Slice` that can be converted to a `String` using `asString()`.
extends fun to_hex(self: Int, nibbles: Int, prefix: Bool): Slice {
    let b: Builder = beginCell();
    if (prefix) {
        b = b.storeUint(12408, 16); // "0x"
    }
    if (nibbles == 0) {
        let n: Int = self;
        while (n > 0) {
            n = n >> 4;
            nibbles = nibbles + 1;
        }
    }
    let i: Int = 0;
    while (i < nibbles) {
        let nibble: Int = (self >> (4 * (nibbles - i - 1))) & 0xF;
        if (nibble < 10) {
            b = b.storeUint(nibble + 48, 8); // 0-9
        } else {
            b = b.storeUint(nibble + 87, 8); // a-f
        }
        i = i + 1;
    }
    return b.asSlice();
}

/// Converts a Slice to a hex string.
/// `prefix` is whether the output should have a "0x" prefix.
/// Returns a `Slice` that can be converted to a `String` using `asString()`.
extends fun to_hex(self: Slice, prefix: Bool): Slice {
    let b: Builder = beginCell();
    if (prefix) {
        b = b.storeUint(12408, 16); // "0x"
    }
    let bits: Int = self.bits();
    if (bits % 4 != 0) {
        let first_nibble: Int = self.loadUint(bits % 4);
        if (first_nibble < 10) {
            b = b.storeUint(first_nibble + 48, 8); // 0-9
        } else {
            b = b.storeUint(first_nibble + 87, 8); // a-f
        }
    }
    repeat (bits / 4) {
        let nibble: Int = self.loadUint(4);
        if (nibble < 10) {
            b = b.storeUint(nibble + 48, 8); // 0-9
        } else {
            b = b.storeUint(nibble + 87, 8); // a-f
        }
    }
    return b.asSlice();
}

inline extends fun to_hex(self: String, prefix: Bool): Slice {
    return self.asSlice().to_hex(prefix);
}


/// Converts a short string to a base64url string.
/// The inverse of Tact's `fromBase64` function.
/// The input is raw data bits in a `Slice`.
/// Returns a base64url string in a `Slice`.
extends fun toBase64(self: Slice): Slice {
    let size: Int = self.bits() / 6;
    require(size <= 128, "Strlib::toBase64: Base64 string too long");
    let result: Builder = beginCell();

    repeat (size) {
        let code: Int = self.loadUint(6);
        result = result.storeUint(_strlib_to_base64_convert(code), 8);
    }
    // Convert residual bits
    size = self.bits();
    if (size > 0) {
        let code2: Int = self.preloadUint(size) << (6 - size);
        result = result.storeUint(_strlib_to_base64_convert(code2), 8);
        size = 4 - result.bits() % 32 / 8;
    }
    // Add padding
    repeat (size) {
        result = result.storeUint(61, 8); // padding '='
    }
    return result.asSlice();
}

inline fun _strlib_to_base64_convert(code: Int): Int {
    if (code < 26) {
        return code + 65;
    } else if (code >= 26 && code < 52) {
        return code + 97 - 26;
    } else if (code >= 52 && code < 62) {
        return code + 48 - 52;
    } else if (code == 62) {
        return 45;
    } else if (code == 63) {
        return 95;
    }
    return 0;
}

/// # Panic
/// This crc16 panics if the input is not a multiple of 8 bits.
fun _strlib_crc16(data: Slice): Int {
    let reg: Int = 0;
    let d: Slice = beginCell().storeSlice(data).storeUint(0, 16).asSlice();
    let bits: Int = d.bits();
    require(bits % 8 == 0, "Strlib::_strlib_crc16: Invalid data");
    repeat (bits / 8) {
        let byte: Int = d.loadUint(8);
        let mask: Int = 0x80;
        while (mask > 0) {
            reg = reg << 1;
            if (byte & mask > 0) {
                reg = reg + 1;
            }
            mask = mask >> 1;
            if (reg > 0xFFFF) {
                reg = reg & 0xFFFF;
                reg = _strlib_xor(reg, 0x1021);
            }
        }
    }
    return reg;
}
