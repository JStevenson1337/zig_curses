const std = @import("std");
const print = std.debug.warn;

const curses = @import("root").curses;

// Doesn't work due to a Zig error when linking libc
const c = @cImport({
    //@cDefine("_NO_CRT_STDIO_INLINE", "1");
    //@cInclude("stdio.h");
    //@cInclude("stdlib.h");
});

pub fn main() !void {
    const DELAY = 3000;

    //_ = c.printf("%d\n", c.rand());

    var ball = .{
        .x = 10,
        .y = 10,

        .direction = enum {
            Right,
            Left,
        },
    };

    var lives: usize = 0;
    var hits: usize = 0;

    var paddle = .{
        .x = 5, // will never change
        .y = 15,

        .size = 5,
        .speed = 4,
    };

    var w = curses.Window.init(std.testing.allocator) catch |e| {
        print("Failed to initialize window: {}\n", .{e});
        return e;
    };

    var play = true;

    const maxloop = 100000000;
    var i: usize = 0;

    while (play == true and i < maxloop) : (i += 1) {
        try w.clear();
        w.mvprint(10, 10, "Hello") catch |err| {
            try w.end();
            return err;
        };
        w.refresh() catch |err| {
            try w.end();
            return err;
        };
        std.time.sleep(40000);
        //play = false;
    }

    try w.end();
}
