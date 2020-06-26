const std = @import("std");
const print = std.debug.warn;

const GapBuffer = struct {
    buffer: []u32,
    leftIndex: usize,
    rightIndex: usize,

    allocator: *std.mem.Allocator,

    // the caller is responsible for freeing memory
    pub fn init(allocator: *std.mem.Allocator, buffer: []u32) !GapBuffer {
        var newbuffer = try allocator.alloc(u32, buffer.len * 2);

        for (buffer) |c, i| {
            newbuffer[i] = c;
        }

        return GapBuffer{
            .buffer = newbuffer,
            .leftIndex = buffer.len,
            .rightIndex = 0,

            .allocator = allocator,
        };
    }

    pub fn resize() void {}

    pub fn left(self: *GapBuffer) !void {
        // if (self.leftIndex == self.buffer.len + 1) {
        //     return error.StackOverflow;
        // }
        // self.leftIndex -= 1;

        // self.buffer[self.leftIndex] = self.buffer[self.rightIndex];

        // if (self.rightIndex == 0) {
        //     return error.StackUnderflow;
        // }
        // self.rightIndex -= 1;
        if (self.leftIndex == 0) {
            return error.StackUnderflow;
        }

        self.rightIndex += 1;
        self.leftIndex -= 1;

        self.buffer[self.buffer.len - self.rightIndex] = self.buffer[self.leftIndex];

        self.buffer[self.leftIndex] = 0;
    }

    pub fn right(self: *GapBuffer) !void {
        // if    (self.rightIndex == 0) {
        //     return error.StackUnderflow;
        // }
        // self.rightIndex += 1;

        // self.buffer[self.rightIndex] = self.buffer[self.leftIndex];

        // if (self.leftIndex == self.buffer.len + 1) {
        //     return error.StackOverflow;
        // }
        // self.leftIndex += 1;
        if (self.rightIndex == 0) {
            return error.StackOverflow;
        }

        self.leftIndex += 1;

        self.buffer[self.leftIndex] = self.buffer[self.buffer.len - self.rightIndex];

        self.rightIndex -= 1;
    }

    pub fn delete(self: *GapBuffer) !u32 {
        if (self.leftIndex == 0) {
            return error.StackUnderflow;
        }
        self.buffer[self.leftIndex] = 0;
        self.leftIndex -= 1;
        return self.buffer[self.leftIndex];
    }

    pub fn insert(self: *GapBuffer, item: u32) !void {
        self.buffer[self.rightIndex] = item;
        self.rightIndex += 1;
    }

    /// returns the non-buffer parts of the slice
    pub fn slice(self: GapBuffer) ![]u32 {
        var buf = try self.allocator.alloc(u32, self.buffer.len);
        //var buf = self.buffer;
        var i: usize = 0;
        print("\nLeftIndex: {}\n", .{self.leftIndex});
        while (i < self.leftIndex) : (i += 1) {
            buf[i] = self.buffer[i];
        }

        var n: usize = self.rightIndex;
        print("\nRightIndex: {}\n", .{self.rightIndex});
        print("Length: {}\n", .{self.buffer.len});
        while (n < self.buffer.len or i < self.buffer.len) : ({
            n += 1;
            i += 1;
        }) {
            print(" {} {}  {} \n", .{ i, n, self.buffer[n] });
            buf[i] = self.buffer[n];
        }

        return buf;
    }
};

test "" {
    const assert = std.debug.assert;

    //var buffer: [100]u32 = undefined;
    var buffer = [_]u32{ 2, 3, 4, 1, 5, 6, 5, 1, 5, 2, 5, 1, 58, 433, 562, 45, 253, 23, 4, 4, 1, 5, 7, 45, 50 };
    var b = try GapBuffer.init(std.testing.allocator, buffer[0..]);

    print("\n{}\n", .{b});

    assert(b.buffer[b.leftIndex - 1] == 50);

    assert(b.buffer[0] == 2);

    try b.left();
    print("Current: {}\n", .{buffer[b.leftIndex]});
    print("P: {}\n", .{b.leftIndex});
    assert(b.buffer[b.leftIndex - 1] == 45);

    for (b.buffer) |c| {
        print("{} ", .{c});
    }

    var slice = try b.slice();
    for (slice) |c| {
        print("{} ", .{c});
    }
    b.allocator.free(slice);

    print("\n", .{});

    assert((try b.delete()) == 45);

    try b.left();
    assert(b.buffer[b.leftIndex - 1] == 5);

    std.testing.allocator.free(b.buffer);
}
