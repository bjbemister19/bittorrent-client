const std = @import("std");

pub const VecError = error{
    PopCapacityZero,
};

pub fn Vec(comptime T: type) type {
    return struct {
        allocator: std.mem.Allocator,
        items: []T,
        capacity: usize,
        len: usize,

        const Self = @This();

        pub fn new(allocator: std.mem.Allocator) Self {
            return Self{
                .allocator = allocator,
                .items = &[_]T{},
                .capacity = 0,
                .len = 0,
            };
        }

        pub fn delete(self: *Self) void {
            if (self.capacity != 0) {
                self.allocator.free(self.items);
                self.capacity = 0;
            }
        }

        pub fn push(self: *Self, item: T) !void {
            if (self.len == self.capacity) {
                var new_capacity: usize = 1;
                if (self.capacity != 0) {
                    new_capacity = self.capacity * 2;
                }
                const new_items = try self.allocator.realloc(self.items, new_capacity);
                self.items = new_items;
                self.capacity = new_capacity;
            }
            self.items[self.len] = item;
            self.len += 1;
        }

        pub fn pop(self: *Self) !void {
            if (self.len == 0) {
                return VecError.PopCapacityZero;
            }
            self.len -= 1;
        }

        pub fn slice(self: *const Self) []const T {
            return self.items[0..self.len];
        }
    };
}

fn runTest(testFn: anytype) !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer {
        const check = gpa.deinit();
        switch (check) {
            .ok => {},
            .leak => {
                std.debug.print("Memory leak detected!\n", .{});
                std.process.exit(1);
            },
        }

    }
    
    try testFn(gpa.allocator());
}

test "Can push item into vector" {
    try runTest(struct {
        fn testFunction(allocator: std.mem.Allocator) !void {
            var vec = Vec(i32).new(allocator);
            defer vec.delete();

            try vec.push(42);
            const items = vec.slice();
            const expected = [_]i32{42};
            try std.testing.expectEqualSlices(i32, &expected, items);
        }
    }.testFunction);
}

test "Can push multiple item into vector" {
    try runTest(struct {
        fn testFunction(allocator: std.mem.Allocator) !void {
            var vec = Vec(i32).new(allocator);
            defer vec.delete();

            try vec.push(42);
            try vec.push(0);
            try vec.push(1);
            try vec.push(2);
            try vec.push(3);
            try vec.push(4);
            const items = vec.slice();
            const expected = [_]i32{42, 0, 1, 2, 3, 4};
            try std.testing.expectEqualSlices(i32, &expected, items);
        }
    }.testFunction);
}
