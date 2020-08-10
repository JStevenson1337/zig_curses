const std = @import("std");

const print = std.debug.warn;

const curses = @import("root").curses;

const stdout = std.io.getStdOut().outStream();
const in_stream = std.io.getStdOut().inStream();

pub fn readKey() !u8 {
    var c: u8 = try in_stream.readByte();
    return c;
}

pub fn main() anyerror!void {
    var w = try curses.Window.init(std.testing.allocator);

    var c: u8 = undefined;
    while (c != 'q') {
        c = try readKey();
    }

    try w.end();
}
