# zigcurses

A simple Zig library containing basic functions for making a TUI.

Goals:
1. Implement simple games with it (such as porting my other ncurses games)
2. Port https://github.com/Akuli/curses-minesweeper to zigcurses
3. Export as a C library and write an example game in C using zigcurses
4. Write a `vi` or `mg` clone with a zigcurses backend

Ideas:
- Use Zig's `comptime` feature to enable designing user interfaces that are processed at compile time
