const std = @import("std");
const os = std.os;
const warn = std.debug.warn;
const termios = os.termios;
const ascii = std.ascii;

const STDIN_FILENO = 0;

// TODO: make this work
//pub fn CTRL_KEY(k: u8) u8 {
//    return ((k) & 0x1f);
//}

const Window = struct {
    original: termios,

    pub fn init() !Window {
        var original_termios = try os.tcgetattr(STDIN_FILENO);
        var raw = original_termios;

        raw.iflag &= ~(@as(u16, os.BRKINT | os.ICRNL | os.INPCK | os.ISTRIP | os.IXON));
        raw.oflag &= ~(@as(u8, os.OPOST));
        raw.cflag |= (os.CS8);
        raw.lflag &= ~(@as(u16, os.ECHO | os.ICANON | os.IEXTEN | os.ISIG));

        // My attempt at VTIME and VMIN
        raw.cc[5] = 0;
        raw.cc[7] = 1;

        try os.tcsetattr(STDIN_FILENO, os.TCSA.FLUSH, raw);

        if (!(os.isatty(STDIN_FILENO))) {
            // return error
        }

        return Window{
            .original = original_termios,
        };
    }

    pub fn getmax() ![2]i32 {
        // TODO: support other platforms and provide fallback
        var wsz: os.winsize = undefined;
        // TODO: test for false and return error
        _ = std.os.linux.syscall3(.ioctl, @bitCast(usize, @as(isize, 0)), os.TIOCGWINSZ, @ptrToInt(&wsz)) == 0;
        return [2]i32{wsz.ws_col, wsz.ws_row};
    }

    test "try to get max" {
        var hw = try getmax();
        warn("Width: {}. Height: {}\n", .{hw[0], hw[1]});
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
