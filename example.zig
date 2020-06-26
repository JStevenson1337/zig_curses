const std = @import("std");
const ascii = std.ascii;
const print = std.debug.warn;

const curses = @import("src/main.zig");

pub fn main() anyerror!void {
    const in_stream = std.io.getStdOut().inStream();

    var w = try curses.Window.init(std.testing.allocator);
    while (true) {
        var c: u8 = undefined;
        c = try in_stream.readByte();

        if (ascii.isCntrl(c)) {
            print("It's control! {}\r\n", .{c});
            var text = "hi\n";

            try w.mvprint(0, 0, text[0..]);
        } else {
            print("{}\r\n", .{c});
        }

        if (ascii.isCntrl(c) and c == 'q') {
            break;
        }

        if (c == 'c') {
            try w.clear();
        }
        //warn("{}\n", .{CTRL_KEY(c)});
        if (c == 17) {
            break;
        }
    }

    try w.end();
}
