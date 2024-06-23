const std = @import("std");

pub const BencodeError = error{
    InvalidFormat
};

pub const BencodeParsedInteger = struct {
    value: i64,
    count: usize,
};

pub const BencodeParsedString = struct {
    value: []const u8,
    count: usize,
};

pub fn parseString(buf: []const u8) !BencodeParsedString {
    var accum: usize = 0;
    for (buf, 0..) |byte, i| {
        if (byte == ':') {
            if (accum == 0) {
                return BencodeError.InvalidFormat;
            }
            const totalLen = i + accum + 1;
            const start = i + 1;

            if (totalLen > buf.len) {
                return BencodeError.InvalidFormat;
            }
            const slice = buf[start..totalLen];
            return BencodeParsedString{ .value = slice, .count = totalLen};
        }

        if (byte < '0' or byte > '9') {
            return BencodeError.InvalidFormat;
        }

        const mulResult = @mulWithOverflow(accum, 10);
        if (mulResult[1] == 1) {
            return BencodeError.InvalidFormat;
        }

        const addResult = @addWithOverflow(mulResult[0], byte - '0');
        if (addResult[1] == 1) {
            return BencodeError.InvalidFormat;
        }
        accum = addResult[0];
    }
    return BencodeError.InvalidFormat;
}

pub fn parseInt(buf: []const u8) !BencodeParsedInteger {
    if (buf[0] != 'i') {
        return BencodeError.InvalidFormat;
    }

    var accum: i64 = 0;
    var negative: i64 = 1;

    const slice = buf[1..];
    for (slice, 0..) |byte, i| {
        if (byte == 'e') {
            const mulResult = @mulWithOverflow(accum, negative);
            if (mulResult[1] == 1) {
                return BencodeError.InvalidFormat;
            }
            accum = mulResult[0];
            return BencodeParsedInteger{ .value = accum, .count = i + 2 };
        } 

        if (i == 0 and byte == '-') {
            negative = -1;
            continue;
        }

        if (byte < '0' or byte > '9') {
            return BencodeError.InvalidFormat;
        }

        const digit = byte - '0';
        
        const mulResult = @mulWithOverflow(accum, 10);
        if (mulResult[1] == 1) {
            return BencodeError.InvalidFormat;
        }

        const addResult = @addWithOverflow(mulResult[0], digit);
        if (addResult[1] == 1) {
            return BencodeError.InvalidFormat;
        }

        accum = addResult[0];
    }
    return BencodeError.InvalidFormat;
}

test "parseString can parse a simple string" {
    const example = "4:spam";
    const parsed = try parseString(example);
    try std.testing.expectEqualSlices(u8, parsed.value, "spam");
    try std.testing.expectEqual(parsed.count, 6);
}

test "parseString can parse a simple string double digit length" {
    const example = "12:hello world!";
    const parsed = try parseString(example);
    try std.testing.expectEqualSlices(u8, parsed.value, "hello world!");
    try std.testing.expectEqual(parsed.count, 15);
}

test "parseString can parse a simple string with leading zeros" {
    const example = "04:spam";
    const parsed = try parseString(example);
    try std.testing.expectEqualSlices(u8, parsed.value, "spam");
    try std.testing.expectEqual(parsed.count, 7);
}

test "parseString fails if the length is not a number" {
    const example = "x:spam";
    try std.testing.expectError(BencodeError.InvalidFormat, parseString(example));
}

test "parseString fails if size is negative" {
    const example = "-4:spam";
    try std.testing.expectError(BencodeError.InvalidFormat, parseString(example));
}

test "parseString fails if size is zero" {
    const example = "0:spam";
    try std.testing.expectError(BencodeError.InvalidFormat, parseString(example));
}

test "parseString does not parse if there is no ':' separator" {
    const example = "4spam";
    try std.testing.expectError(BencodeError.InvalidFormat, parseString(example));
}

test "parseString fails gracefully if size is larger than actual value" {
    const example = "5:spam";
    try std.testing.expectError(BencodeError.InvalidFormat, parseString(example));
}

test "parseInt can parse a simple integer" {
    const example = "i42e";
    const parsed = try parseInt(example);
    try std.testing.expectEqual(parsed.value, 42);
    try std.testing.expectEqual(parsed.count, 4);
}

test "parseInt can parse a simple integer with negative sign" {
    const example = "i-42e";
    const parsed = try parseInt(example);
    try std.testing.expectEqual(parsed.value, -42);
    try std.testing.expectEqual(parsed.count, 5);
}

test "parseInt can parse a simple integer with leading zeros" {
    const example = "i00042e";
    const parsed = try parseInt(example);
    try std.testing.expectEqual(parsed.value, 42);
    try std.testing.expectEqual(parsed.count, 7);
}

test "parseInt does not parse if first byte is not 'i'" {
    const example = "x42e";
    try std.testing.expectError(BencodeError.InvalidFormat, parseInt(example));
}

test "parseInt does not parse if there is no 'e' at the end" {
    const example = "i42";
    try std.testing.expectError(BencodeError.InvalidFormat, parseInt(example));
}

test "parseInt does not parse if there is a non-digit character" {
    const example = "i42xe";
    try std.testing.expectError(BencodeError.InvalidFormat, parseInt(example));
}

test "parseInt does not parse if there is a non-digit character after the negative sign" {
    const example = "i-42xe";
    try std.testing.expectError(BencodeError.InvalidFormat, parseInt(example));
}

test "parseInt does not parse if negative sign is not first character" {
    const example = "i42-e";
    try std.testing.expectError(BencodeError.InvalidFormat, parseInt(example));
}

test "parseInt does not parse if negative sign is not followed by a digit" {
    const example = "i-x7e";
    try std.testing.expectError(BencodeError.InvalidFormat, parseInt(example));
}

test "parseInt does not parse if there is an overflow" {
    const example = "i9223372036854775808e";
    try std.testing.expectError(BencodeError.InvalidFormat, parseInt(example));   
}

test "parseInt does not parse if there is an overflow negative" {
    const example = "i-9223372036854775809e";
    try std.testing.expectError(BencodeError.InvalidFormat, parseInt(example));   
}