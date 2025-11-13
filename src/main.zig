const std = @import("std");

pub fn main() !void {
    // Zig 0.15.x usa buffered I/O por defecto
    const stdout = std.io.getStdOut().writer();
    var buffered = std.io.bufferedWriter(stdout);
    const writer = buffered.writer();

    try writer.print("zig-pug v0.1.0\n", .{});
    try writer.print("Template engine inspired by Pug\n", .{});
    try writer.print("Built with Zig 0.15.2\n", .{});

    // IMPORTANTE en 0.15.x: siempre flush el buffer
    try buffered.flush();
}

test "basic test" {
    try std.testing.expectEqual(@as(i32, 42), 42);
}
