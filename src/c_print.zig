const std = @import("std");

// Bindings to c_print library
pub const c = struct {
    pub extern fn c_print(format: [*:0]const u8, ...) void;
    pub extern fn c_print_color(text: [*:0]const u8, color: i32) void;
};

// Text colors from ansi_codes.h
pub const Color = enum(c_int) {
    black = 0,
    red = 1,
    green = 2,
    yellow = 3,
    blue = 4,
    magenta = 5,
    cyan = 6,
    white = 7,
    bright_black = 8,
    bright_red = 9,
    bright_green = 10,
    bright_yellow = 11,
    bright_blue = 12,
    bright_magenta = 13,
    bright_cyan = 14,
    bright_white = 15,
};

// Convenience functions for common use cases
pub fn printError(comptime fmt: []const u8, args: anytype) void {
    const msg = std.fmt.allocPrint(std.heap.page_allocator, fmt, args) catch return;
    defer std.heap.page_allocator.free(msg);
    const c_msg = std.heap.page_allocator.dupeZ(u8, msg) catch return;
    defer std.heap.page_allocator.free(c_msg);
    c.c_print_color(c_msg.ptr, @intFromEnum(Color.red));
}

pub fn printWarning(comptime fmt: []const u8, args: anytype) void {
    const msg = std.fmt.allocPrint(std.heap.page_allocator, fmt, args) catch return;
    defer std.heap.page_allocator.free(msg);
    const c_msg = std.heap.page_allocator.dupeZ(u8, msg) catch return;
    defer std.heap.page_allocator.free(c_msg);
    c.c_print_color(c_msg.ptr, @intFromEnum(Color.yellow));
}

pub fn printSuccess(comptime fmt: []const u8, args: anytype) void {
    const msg = std.fmt.allocPrint(std.heap.page_allocator, fmt, args) catch return;
    defer std.heap.page_allocator.free(msg);
    const c_msg = std.heap.page_allocator.dupeZ(u8, msg) catch return;
    defer std.heap.page_allocator.free(c_msg);
    c.c_print_color(c_msg.ptr, @intFromEnum(Color.green));
}

pub fn printInfo(comptime fmt: []const u8, args: anytype) void {
    const msg = std.fmt.allocPrint(std.heap.page_allocator, fmt, args) catch return;
    defer std.heap.page_allocator.free(msg);
    const c_msg = std.heap.page_allocator.dupeZ(u8, msg) catch return;
    defer std.heap.page_allocator.free(c_msg);
    c.c_print_color(c_msg.ptr, @intFromEnum(Color.cyan));
}

// Simple colored text using pattern API
pub fn print(pattern: [:0]const u8) void {
    c.c_print(pattern.ptr);
}
