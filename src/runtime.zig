const std = @import("std");

// Runtime module - To be implemented in Step 12
// See: 12-runtime.md

pub const Context = struct {
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator) Context {
        return .{
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *Context) void {
        _ = self;
        // TODO: Implement cleanup
    }
};

test "runtime stub" {
    var ctx = Context.init(std.testing.allocator);
    defer ctx.deinit();
}
