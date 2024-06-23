const std = @import("std");
const bencode = @import("bencode.zig");

fn hexDump(buf: []const u8) void {
    for (buf, 0..) |byte, i| {
        if (i % 16 == 0) {
            if (i != 0) std.debug.print("\n", .{});
            std.debug.print("{x}: ", .{i});
        }
        std.debug.print("{x} ", .{byte});
    }
    std.debug.print("\n", .{});
}

fn dumpAscii(buf: []const u8) void {
    for (buf, 0..) |byte, i| {
        if (i % 16 == 0) {
            if (i != 0) std.debug.print("\n", .{});
            std.debug.print("{x}: ", .{i});
        }
        if (byte >= 32 and byte < 127) {
            std.debug.print("{c}", .{byte});
        } else {
            std.debug.print(".", .{});
        }
    }
    std.debug.print("\n", .{});
}

pub fn main() !void {
    const allocator = std.heap.page_allocator;

    const file = try std.fs.cwd().openFile("data/archlinux-2024.06.01-x86_64.iso.torrent", .{});
    defer file.close(); // Ensure the file is closed when done

    const buf = try file.readToEndAlloc(allocator, std.math.maxInt(usize));

    const slice = buf[0..10];
    hexDump(slice);
    dumpAscii(slice);

    // const example3 = "l4:spam4:eggse";
    // const example3 = "ll5:helloi42eel3:fooi7eee";
    // const example3 = "d4:spaml1:a1:bee";
    const parsed = try bencode.parseDict(buf);
    std.debug.print("{}\n", .{parsed});
}
