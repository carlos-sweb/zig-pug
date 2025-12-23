//! Visitor Pattern
//!
//! Generic visitor pattern implementation for traversing AST nodes.
//! Useful for implementing custom AST transformations and analysis.

const AstNode = @import("AstNode.zig").AstNode;

/// Generic visitor for traversing AST nodes
///
/// Implements the visitor pattern for AST traversal. Allows custom
/// processing of each node while automatically handling tree traversal.
///
/// Fields:
/// - context: Opaque pointer to user-defined context
/// - visitFn: Function to call for each node
///
/// Example:
/// ```zig
/// const MyContext = struct {
///     count: usize,
///
///     fn visitNode(ctx: *anyopaque, node: *AstNode) !void {
///         const self: *MyContext = @ptrCast(@alignCast(ctx));
///         self.count += 1;
///     }
/// };
///
/// var ctx = MyContext{ .count = 0 };
/// var visitor = Visitor{
///     .context = &ctx,
///     .visitFn = MyContext.visitNode,
/// };
/// try visitor.visit(root_node);
/// // ctx.count now contains total node count
/// ```
pub const Visitor = struct {
    const Self = @This();

    context: *anyopaque,
    visitFn: *const fn (*anyopaque, *AstNode) anyerror!void,

    /// Visit a node and recursively visit all its children
    ///
    /// Calls visitFn for the current node, then recursively visits
    /// all child nodes in the tree.
    ///
    /// Parameters:
    /// - node: AST node to visit
    pub fn visit(self: *Self, node: *AstNode) !void {
        try self.visitFn(self.context, node);

        switch (node.data) {
            .Document => |*doc| {
                for (doc.children.items) |child| {
                    try self.visit(child);
                }
            },
            .Tag => |*tag| {
                for (tag.children.items) |child| {
                    try self.visit(child);
                }
            },
            .Conditional => |*cond| {
                for (cond.then_branch.items) |child| {
                    try self.visit(child);
                }
                if (cond.else_branch) |*else_br| {
                    for (else_br.items) |child| {
                        try self.visit(child);
                    }
                }
            },
            .Loop => |*loop| {
                for (loop.body.items) |child| {
                    try self.visit(child);
                }
                if (loop.else_branch) |*else_br| {
                    for (else_br.items) |child| {
                        try self.visit(child);
                    }
                }
            },
            .MixinDef => |*mixin| {
                for (mixin.body.items) |child| {
                    try self.visit(child);
                }
            },
            .MixinCall => |*call| {
                if (call.body) |*body| {
                    for (body.items) |child| {
                        try self.visit(child);
                    }
                }
            },
            .Block => |*block| {
                for (block.body.items) |child| {
                    try self.visit(child);
                }
            },
            .Case => |*case_node| {
                for (case_node.cases.items) |when_node| {
                    try self.visit(when_node);
                }
                if (case_node.default) |*def| {
                    for (def.items) |child| {
                        try self.visit(child);
                    }
                }
            },
            .When => |*when| {
                for (when.body.items) |child| {
                    try self.visit(child);
                }
            },
            else => {},
        }
    }
};
