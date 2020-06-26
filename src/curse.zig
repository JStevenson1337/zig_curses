const print = @import("std").debug.print;

const c = @cImport({
    // See https://github.com/ziglang/zig/issues/515
    @cDefine("_NO_CRT_STDIO_INLINE", "1");
    @cInclude("ncurses.h");
    @cInclude("stdio.h");
});
pub fn main() void {
    //    _ = c.printf("hello\n");
    _ = c.initscr();
    _ = c.mvprintw(0, 0, "Hi");
    _ = c.endwin();
    _ = c.printf("HA\n");

    print("hi\n", .{});
}
