const std = @import("std");

const ascii = std.ascii;
const io = std.io;
const fmt = std.fmt;
const os = std.os;
const print = warn;
const termios = os.termios;
const warn = std.debug.warn;

const STDIN_FILENO = 0;
const stdout = std.io.getStdOut().outStream();
const in_stream = std.io.getStdOut().inStream();

const VMIN = 5;
const VTIME = 6;

pub const Window = struct {
    /// the saved termios that is used to restore the terminal to its original state
    original: termios,

    /// the height (in characters) of the window
    height: usize,
    /// the width (in characters) of the window
    width: usize,
    // an idea that is not implemented (use height and width for now)
    //max: struct {
    //    x: usize,
    //    y: usize,
    //},
    //
    /// buf contains a dynamic array of characters that will be combined upon print
    buf: std.ArrayList(u8),

    allocator: *std.mem.Allocator,

    /// init puts the window in raw mode and saves the original termios for switching back to normal mode
    pub fn init(allocator: *std.mem.Allocator) !Window {
        var window = Window{
            .original = try os.tcgetattr(STDIN_FILENO),
            .buf = std.ArrayList(u8).init(allocator),

            .height = 0,
            .width = 0,

            .allocator = allocator,
        };

        var raw = window.original;

        raw.iflag &= ~(@as(u16, os.BRKINT | os.ICRNL | os.INPCK | os.ISTRIP | os.IXON));
        raw.oflag &= ~(@as(u8, os.OPOST));
        raw.cflag |= (os.CS8);
        raw.lflag &= ~(@as(u16, os.ECHO | os.ICANON | os.IEXTEN | os.ISIG));

        raw.cc[VMIN] = 0;
        raw.cc[VTIME] = 1;

        try os.tcsetattr(STDIN_FILENO, os.TCSA.FLUSH, raw);

        if (!os.isatty(STDIN_FILENO)) {
            return error.NotATTY;
        }

        // fill in the height and width information
        try window.updatehw();

        // initialize text with spaces and newlines
        //for ([]usize{ 0, 1, 2, 3, 4, 10 }) |i| {}

        try window.clear();

        // disable cursor
        _ = try stdout.write("\x1B[?25l");

        //var i: usize = 0;
        //while (i < window.height) {
        //    _ = try stdout.write("\r\n~");
        //    i += 1;
        //}

        return window;
    }

    /// updatehw gets the height and width for the window by making a syscall.
    pub fn updatehw(self: *Window) !void {
        // TODO: support other platforms and provide fallback
        var wsz: os.winsize = undefined;
        // test for failure
        if (std.os.linux.syscall3(.ioctl, @bitCast(usize, @as(isize, 0)), os.TIOCGWINSZ, @ptrToInt(&wsz)) != 0) {
            return error.WinsizeSyscallFailure;
        }

        self.height = wsz.ws_row;
        self.width = wsz.ws_col;
    }

    pub fn mvprint(self: *Window, x: usize, y: usize, text: []const u8) !void {
        var buf = try self.allocator.alloc(u8, 10); // TODO: remove allocation
        defer self.allocator.free(buf);
        _ = try fmt.bufPrint(buf, "\x1b[{};{}H", .{ x, y });

        try self.buf.appendSlice(buf);
        try self.buf.appendSlice(text);
    }

    /// erases the buffer and clears the screen, can be expensive and cause flickering
    pub fn clear(self: *Window) !void {
        self.buf.deinit();
        self.buf = std.ArrayList(u8).init(self.allocator);

        _ = try stdout.write("\x1b[2J");
        _ = try stdout.write("\x1b[H");
    }

    /// lazily prints to the screen, decreasing flickering
    pub fn erase() !void {}

    pub fn flush(self: Window) !void {
        self.buf.items;
    }

    pub fn refresh(self: Window) !void {
        var buf = try self.allocator.alloc(u8, self.buf.items.len); // TODO: remove allocator
        defer self.allocator.free(buf);

        _ = try fmt.bufPrint(buf, "{}", .{self.buf.items});
        _ = try stdout.write(buf);
    }

    pub fn end(self: *Window) !void {
        // free the memory first in case the next ones fail
        self.buf.deinit();

        // clear screen
        _ = try stdout.write("\x1b[2J");
        _ = try stdout.write("\x1b[H");

        // re-enable cursor
        _ = try stdout.write("\x1B[?25h");

        // Restore the original termios
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
