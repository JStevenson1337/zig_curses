const std = @import("std");
const os = std.os;
const warn = std.debug.warn;
const print = warn;
const termios = os.termios;
const ascii = std.ascii;

const STDIN_FILENO = 0;
const stdout = std.io.getStdOut().outStream();
const in_stream = std.io.getStdOut().inStream();

//pub fn new(allocator: *Allocator) !Window {}

pub const Window = struct {
    original: termios,
    height: usize,
    width: usize,
    buffer: []u8,
    /// buf contains a dynamic array of slices that will be combined upon print
    buf: std.ArrayList([]const u8),

    //allocator: *std.mem.Allocator,

    /// init puts the window in raw mode and saves the original termios for switching back to normal mode
    pub fn init(allocator: *std.mem.Allocator) !Window {
        var window = Window{
            .original = try os.tcgetattr(STDIN_FILENO),
            .buffer = "",
            .buf = undefined,
            .height = 0,
            .width = 0,
        };

        var raw = window.original;

        raw.iflag &= ~(@as(u16, os.BRKINT | os.ICRNL | os.INPCK | os.ISTRIP | os.IXON));
        raw.oflag &= ~(@as(u8, os.OPOST));
        raw.cflag |= (os.CS8);
        raw.lflag &= ~(@as(u16, os.ECHO | os.ICANON | os.IEXTEN | os.ISIG));

        // My attempt at VTIME and VMIN
        raw.cc[5] = 0;
        raw.cc[7] = 1;

        try os.tcsetattr(STDIN_FILENO, os.TCSA.FLUSH, raw);

        if (!os.isatty(STDIN_FILENO)) {
            return error.NotATTY;
        }

        const arrayList = std.ArrayList([]const u8);

        var what = "hello";
        var buf = arrayList.init(allocator);
        _ = try buf.append(what[0..]);
        _ = try buf.append("i"[0..]);
        print("What? {}\n", .{buf.items});

        window.buf = buf;

        //const wh = try getmax();
        // fill in the height and width information
        try window.updatehw();

        var text = try allocator.alloc(u8, window.height * window.width);
        //warn("{}", .{text});
        defer allocator.free(text);

        var n: usize = 0;
        while (n < window.height) : (n += 1) {
            print("{}", .{n});
            text[n] = 'h';

            //warn("{}", .{});

            if (n % window.width == 0) {
                text[n * window.width] = 'c';
            }

            // var i: usize = 0;
            // while (i < window.width) : (i += 1) {
            //     if (i == window.width) {
            //         text[n] = '\n';
            //     }
            // }
        }

        print("{}", .{text});

        // initialize text with spaces and newlines
        //for ([]usize{ 0, 1, 2, 3, 4, 10 }) |i| {}

        try window.clear();

        // disable cursor
        _ = try stdout.write("\x1B[?25l");

        var i: usize = 0;

        while (i < window.height) {
            _ = try stdout.write("\r\n~");
            i += 1;
        }

        return window;
    }

    /// updatehw gets the height and width for the window by making a syscall.
    pub fn updatehw(self: *Window) !void {
        // TODO: support other platforms and provide fallback
        var wsz: os.winsize = undefined;
        // TODO: test for false and return error
        _ = std.os.linux.syscall3(.ioctl, @bitCast(usize, @as(isize, 0)), os.TIOCGWINSZ, @ptrToInt(&wsz)) == 0;
        //const te = [2]u32{ wsz.ws_col, wsz.ws_row };
        self.height = wsz.ws_row;
        self.width = wsz.ws_col;
    }

    /// setchar puts a character at a specific point in the text based on height and width
    pub fn setchar(self: *Window, x: u32, y: u32, insert: u8) !void {
        if (x > self.width or y > self.height) {
            return error.InvalidRange;
        }

        var newlines: usize = 0;
        for (self.buffer) |char, i| {
            if (newlines == y) {
                for (self.buffer[i + 1 .. hw[1]]) |character, n| {
                    if (character == '\n' or character == '\r') {
                        break;
                    }

                    self.buffer[n] = insert;
                }
            }
        }
    }

    pub fn mvprint(self: Window, x: usize, y: usize, text: []const u8) !void {
        self.buf.append("\x1b[10;10H"[0..]);
        self.buf.append([]u8{@as(u8, x)});
        self.buf.append(text);
        self.buf.append();
        //_ = try buf.append('');
    }

    pub fn clear(self: Window) !void {
        _ = try stdout.write("\x1b[2J");
        _ = try stdout.write("\x1b[H");
    }

    pub fn erase() !void {}

    pub fn flush() !void {}

    pub fn refresh(self: Window) !void {
        _ = stdout.write(self.buffer);
    }

    pub fn end(self: Window) !void {
        // re-enable cursor
        _ = try stdout.write("\x1B[?25h");

        self.buf.deinit();

        try self.clear();
        try os.tcsetattr(STDIN_FILENO, os.TCSA.FLUSH, self.original);
    }
};

test "Window open and close" {
    var window = try Window.init(std.testing.allocator);
    try window.end();
}

pub fn readKey() !u8 {
    var c: u8 = try in_stream.readByte();
    return c;
}

test "try to read a key" {
    var window = try Window.init(std.testing.allocator);

    print("\r\nEnter a key: ", .{});
    const c: u8 = try readKey();
    print("You entered: {}\n", .{c});

    try window.end();
}
