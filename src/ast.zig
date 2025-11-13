const std = @import("std");

// AST module - To be implemented in Step 5
// See: 05-ast-definition.md

pub const NodeType = enum {
    Document,
    // TODO: Add more node types
};

pub const AstNode = struct {
    type: NodeType,
    line: usize,
    column: usize,

    pub fn deinit(self: *AstNode, allocator: std.mem.Allocator) void {
        _ = self;
        _ = allocator;
        // TODO: Implement cleanup
    }
};

test "ast stub" {
    var node = AstNode{
        .type = .Document,
        .line = 1,
        .column = 1,
    };
    node.deinit(std.testing.allocator);
}
