const std = @import("std");

// Parser module - To be implemented in Step 6
// See: 06-parser-base.md

pub const Parser = struct {
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator) Parser {
        return .{
            .allocator = allocator,
        };
    }

    pub fn parse(self: *Parser, source: []const u8) !void {
        // TODO: Implement parsing
        _ = self;
        _ = source;
    }
};

test "parser stub" {
    var parser = Parser.init(std.testing.allocator);
    try parser.parse("test");
}
