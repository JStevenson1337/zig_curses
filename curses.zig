const std = @import("std");
const os = std.os;
const warn = std.debug.warn;
const termios = os.termios;
const ascii = std.ascii;

const STDIN_FILENO = 0;

// I need to figure out how to implement this
//pub fn CTRL_KEY(k: u8) u8 {
//    return ((k) & 0x1f);
//}

const Window = struct {
    original: termios,

    pub fn init() !Window {
        var original_termios = try os.tcgetattr(STDIN_FILENO);
        var raw = original_termios;

        raw.iflag &= ~(@as(u8, os.BRKINT) | @as(u16, os.ICRNL) |
                           @as(u8, os.INPCK) | @as(u8, os.ISTRIP) | @as(u16, os.IXON));
        raw.oflag &= ~(@as(u8, os.OPOST));
        raw.cflag |= (os.CS8);
        raw.lflag &= ~(@as(u8, os.ECHO) | @as(u8, os.ICANON) |
                           @as(u16, os.IEXTEN) | @as(u8, os.ISIG));

        // My attempt at VTIME and VMIN
        raw.cc[5] = 0;
        raw.cc[7] = 1;

        try os.tcsetattr(STDIN_FILENO, os.TCSA.FLUSH, raw);

        return Window{
            .original = original_termios,
        };
    }

    pub fn end(self: Window) !void {
        try os.tcsetattr(0, os.TCSA.FLUSH, self.original);
    }
};

test "Window open and close" {
    var window = try Window.init();
    try window.end();
}

pub fn readKey() !u8 {
    const in_stream = std.io.getStdOut().inStream();
    var c: u8 = try in_stream.readByte();
    return c;
}

test "try to read a key" {
    var window = try Window.init();

    warn("\r\nEnter a key: ", .{});
    var c: u8 = try readKey();
    warn("You entered: {}\n", .{c});
    
    try window.end();
}

// An example for main -- to be moved to an example directory
pub fn main() !void {
    const in_stream = std.io.getStdOut().inStream();

    var w = try Window.init();
    while (true) {
        var c: u8 = undefined;
        c = try in_stream.readByte();

        if (ascii.isCntrl(c)) {
            warn("It's control! {}\r\n", .{c});
        } else {
            warn("{}\r\n", .{c});
        }

        if (ascii.isCntrl(c) and c == 'q') {
            break;
        }
        //warn("{}\n", .{CTRL_KEY(c)});
        if (c == 17) {
            break;
        }
    }

    try w.end();
}
