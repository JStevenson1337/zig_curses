const std = @import("std");

pub const curses = @import("src/main.zig");

const examples = .{
    .example = @import("examples/example.zig"),
    .keys = @import("examples/keys.zig"),
    .pong = @import("examples/pong.zig"),
};

const mem = std.mem;

pub fn main() anyerror!void {
    const argv = std.os.argv;

    if (argv.len == 1) {
        std.debug.warn("Usage: example NAME\n", .{});
        return;
    }

    const arg = argv[1];

    var found = false;

    found = try example(arg, "example", examples.example.main);
    if (!found)
        found = try example(arg, "pong", examples.pong.main);
    if (!found)
        found = try example(arg, "keys", examples.keys.main);

    //if (example(arg, "pong")) {
    //    std.debug.warn("Starting pong example\n", .{});
    //    try @import("examples/pong.zig").main();
    //}
}

fn example(arg: [*:0]const u8, name: []const u8, func: fn () anyerror!void) anyerror!bool {
    if (mem.eql(u8, arg[0..name.len], name)) {
        try func();
        return true;
    }

    return false;
}
