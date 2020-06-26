const std = @import("std");
const warn = std.debug.warn;
const mem = std.mem;
const assert = std.debug.assert;

pub const Stack = struct {
    buffer: []u8,
    index: usize,

    pub fn init(buffer: []u8) Stack {
        return Stack{
            .buffer = buffer,
            .index = 0,
        };
    }

    pub fn pop(self: *Stack) !u8 {
        if (self.index == 0) return error.StackUnderflow;
        self.index -= 1;
        return self.buffer[self.index];
    }

    pub fn push(self: *Stack, item: u8) !void {
        if (self.index == 0xff) return error.StackOverflow;
        self.buffer[self.index] = item;
        self.index += 1;
    }

    /// slice returns a slice of the array ending at the current index
    pub fn slice(self: Stack) []u8 {
        return self.buffer[0..self.index];
    }
};

test "test stack" {
    var buffer: [100]u8 = undefined;
    var stack = Stack.init(buffer[0..]);

    try stack.push('h');
    try stack.push('e');
    try stack.push('l');
    try stack.push('l');
    try stack.push('o');
    try stack.push('!');

    assert(mem.eql(u8, stack.buffer[0..6], "hello!"));
    warn("\n{}\n", .{stack.slice()});

    const char = try stack.pop();
    assert(char == '!');

    try stack.push('?');
    assert(mem.eql(u8, stack.buffer[0..6], "hello?"));
    warn("\n{}\n", .{stack.slice()});

    _ = try stack.pop();
    _ = try stack.pop();
    _ = try stack.pop();

    _ = try stack.pop();
    _ = try stack.pop();
    _ = try stack.pop();
    _ = try stack.pop();

    warn("\n{}\n", .{stack.slice()});
}
