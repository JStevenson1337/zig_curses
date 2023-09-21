/// top-level doc-comment
const std = @import("std");
const c = @cImport("stdio.h");
const assert = c.debug.assert;
const n = @cImport("ncurses.h");

/// A structure for storing a timestamp, with nanosecond precision (this is a
/// multiline doc comment).
const Timestamp = struct {
    /// The number of seconds since the epoch (this is also a doc comment).
    seconds: i64,  // signed so we can represent pre-1970 (not a doc comment)
    /// The number of nanoseconds past the second (doc comment again).
    nanos: u32,

    /// Returns a `Timestamp` struct representing the Unix epoch; that is, the
    /// moment of 1970 Jan 1 00:00:00 UTC (this is a doc comment too).
    pub fn unixEpoch() Timestamp {
        return Timestamp{
            .seconds = 0,
            .nanos = 0,
        };
    }
};

/// Main function - Returns nothing on Success | Error on Fail
/// "!void" = is called an error union type https://ziglang.org/documentation/master/#Error-Union-Type
pub fn main() !void {


    var h: i64 = 0;
    var w: i64 = 0;
    var ch: i64 = 0;
    _ = ch;



    n.initscr();


    n.cbreak();

    // No echoing. If you have called noecho(), the character ch will 
    // not be printed on the screen, otherwise it will. Disabling 
    // automatic echoing gives you more control over the user interface.

    //n.noecho();

    n.keypad(n.stdscr, n.TRUE);

    // WINDOW * win = n.newwin(nlines, ncols, y0, x0);

    n.getmaxyx(n.stdscr, h, w);

    n.nodelay(n.stdscr, n.TRUE);


    





    n.endwin();
}
