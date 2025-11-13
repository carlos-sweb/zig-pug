const std = @import("std");

// Compiler module - To be implemented in Step 11
// See: 11-compiler-html.md

pub const Compiler = struct {
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator) Compiler {
        return .{
            .allocator = allocator,
        };
    }

    pub fn compile(self: *Compiler, source: []const u8) ![]const u8 {
        // TODO: Implement compilation
        _ = self;
        _ = source;
        return "";
    }
};

test "compiler stub" {
    var compiler = Compiler.init(std.testing.allocator);
    _ = try compiler.compile("test");
}
