const std = @import("std");

// AST module - Abstract Syntax Tree representation
// Represents the structure of a Pug template

// ============================================================================
// Node Types
// ============================================================================

pub const NodeType = enum {
    Document,
    Tag,
    Text,
    Interpolation,
    Code,
    Conditional,
    Loop,
    MixinDef,
    MixinCall,
    Include,
    Block,
    Extends,
    Comment,
    Case,
    When,
};

// ============================================================================
// Main AST Node
// ============================================================================

pub const AstNode = struct {
    type: NodeType,
    line: usize,
    column: usize,
    data: NodeData,

    pub fn create(allocator: std.mem.Allocator, node_type: NodeType, line: usize, column: usize, data: NodeData) !*AstNode {
        const node = try allocator.create(AstNode);
        node.* = .{
            .type = node_type,
            .line = line,
            .column = column,
            .data = data,
        };
        return node;
    }

    pub fn deinit(self: *AstNode, allocator: std.mem.Allocator) void {
        switch (self.data) {
            .Document => |*doc| {
                for (doc.children.items) |child| {
                    child.deinit(allocator);
                    allocator.destroy(child);
                }
                doc.children.deinit(allocator);
            },
            .Tag => |*tag| {
                tag.attributes.deinit(allocator);
                for (tag.children.items) |child| {
                    child.deinit(allocator);
                    allocator.destroy(child);
                }
                tag.children.deinit(allocator);
            },
            .Conditional => |*cond| {
                for (cond.then_branch.items) |child| {
                    child.deinit(allocator);
                    allocator.destroy(child);
                }
                cond.then_branch.deinit(allocator);
                if (cond.else_branch) |*else_br| {
                    for (else_br.items) |child| {
                        child.deinit(allocator);
                        allocator.destroy(child);
                    }
                    else_br.deinit(allocator);
                }
            },
            .Loop => |*loop| {
                for (loop.body.items) |child| {
                    child.deinit(allocator);
                    allocator.destroy(child);
                }
                loop.body.deinit(allocator);
                if (loop.else_branch) |*else_br| {
                    for (else_br.items) |child| {
                        child.deinit(allocator);
                        allocator.destroy(child);
                    }
                    else_br.deinit(allocator);
                }
            },
            .MixinDef => |*mixin| {
                mixin.params.deinit(allocator);
                for (mixin.body.items) |child| {
                    child.deinit(allocator);
                    allocator.destroy(child);
                }
                mixin.body.deinit(allocator);
            },
            .MixinCall => |*call| {
                call.args.deinit(allocator);
                call.attributes.deinit(allocator);
                if (call.body) |*body| {
                    for (body.items) |child| {
                        child.deinit(allocator);
                        allocator.destroy(child);
                    }
                    body.deinit(allocator);
                }
            },
            .Block => |*block| {
                for (block.body.items) |child| {
                    child.deinit(allocator);
                    allocator.destroy(child);
                }
                block.body.deinit(allocator);
            },
            .Case => |*case_node| {
                for (case_node.cases.items) |when_node| {
                    when_node.deinit(allocator);
                    allocator.destroy(when_node);
                }
                case_node.cases.deinit(allocator);
                if (case_node.default) |*def| {
                    for (def.items) |child| {
                        child.deinit(allocator);
                        allocator.destroy(child);
                    }
                    def.deinit(allocator);
                }
            },
            .When => |*when| {
                when.values.deinit(allocator);
                for (when.body.items) |child| {
                    child.deinit(allocator);
                    allocator.destroy(child);
                }
                when.body.deinit(allocator);
            },
            else => {},
        }
    }
};

pub const NodeData = union(NodeType) {
    Document: DocumentNode,
    Tag: TagNode,
    Text: TextNode,
    Interpolation: InterpolationNode,
    Code: CodeNode,
    Conditional: ConditionalNode,
    Loop: LoopNode,
    MixinDef: MixinDefNode,
    MixinCall: MixinCallNode,
    Include: IncludeNode,
    Block: BlockNode,
    Extends: ExtendsNode,
    Comment: CommentNode,
    Case: CaseNode,
    When: WhenNode,
};

// ============================================================================
// Specific Node Types
// ============================================================================

pub const DocumentNode = struct {
    children: std.ArrayListUnmanaged(*AstNode),
    doctype: ?[]const u8,
};

pub const TagNode = struct {
    name: []const u8,
    attributes: std.ArrayListUnmanaged(Attribute),
    children: std.ArrayListUnmanaged(*AstNode),
    is_self_closing: bool,
};

pub const TextNode = struct {
    content: []const u8,
    is_raw: bool, // For pipe | text
};

pub const Attribute = struct {
    name: []const u8,
    value: ?[]const u8,
    is_unescaped: bool,
};

pub const InterpolationNode = struct {
    expression: []const u8,
    is_unescaped: bool,
};

pub const CodeNode = struct {
    code: []const u8,
    is_buffered: bool,
    is_unescaped: bool,
};

pub const ConditionalNode = struct {
    condition: []const u8,
    then_branch: std.ArrayListUnmanaged(*AstNode),
    else_branch: ?std.ArrayListUnmanaged(*AstNode),
    is_unless: bool,
};

pub const LoopNode = struct {
    iterator: []const u8,
    index: ?[]const u8,
    iterable: []const u8,
    body: std.ArrayListUnmanaged(*AstNode),
    else_branch: ?std.ArrayListUnmanaged(*AstNode),
    is_while: bool,
};

pub const MixinDefNode = struct {
    name: []const u8,
    params: std.ArrayListUnmanaged([]const u8),
    rest_param: ?[]const u8,
    body: std.ArrayListUnmanaged(*AstNode),
};

pub const MixinCallNode = struct {
    name: []const u8,
    args: std.ArrayListUnmanaged([]const u8),
    attributes: std.ArrayListUnmanaged(Attribute),
    body: ?std.ArrayListUnmanaged(*AstNode),
};

pub const IncludeNode = struct {
    path: []const u8,
    filter: ?[]const u8,
};

pub const BlockNode = struct {
    name: []const u8,
    mode: BlockMode,
    body: std.ArrayListUnmanaged(*AstNode),
};

pub const BlockMode = enum {
    Replace,
    Append,
    Prepend,
};

pub const ExtendsNode = struct {
    path: []const u8,
};

pub const CommentNode = struct {
    content: []const u8,
    is_buffered: bool,
};

pub const CaseNode = struct {
    expression: []const u8,
    cases: std.ArrayListUnmanaged(*AstNode), // WhenNodes
    default: ?std.ArrayListUnmanaged(*AstNode),
};

pub const WhenNode = struct {
    values: std.ArrayListUnmanaged([]const u8),
    body: std.ArrayListUnmanaged(*AstNode),
};

// ============================================================================
// Visitor Pattern
// ============================================================================

pub const Visitor = struct {
    const Self = @This();

    context: *anyopaque,
    visitFn: *const fn (*anyopaque, *AstNode) anyerror!void,

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

// ============================================================================
// Pretty Printer (for debugging)
// ============================================================================

pub fn printAst(node: *AstNode, indent: usize) void {
    var i: usize = 0;
    while (i < indent) : (i += 1) {
        std.debug.print("  ", .{});
    }

    std.debug.print("{s} (line {d})\n", .{ @tagName(node.type), node.line });

    switch (node.data) {
        .Document => |*doc| {
            for (doc.children.items) |child| {
                printAst(child, indent + 1);
            }
        },
        .Tag => |*tag| {
            var j: usize = 0;
            while (j < indent + 1) : (j += 1) {
                std.debug.print("  ", .{});
            }
            std.debug.print("name: {s}\n", .{tag.name});

            // Print attributes if any
            if (tag.attributes.items.len > 0) {
                var k: usize = 0;
                while (k < indent + 1) : (k += 1) {
                    std.debug.print("  ", .{});
                }
                std.debug.print("attributes:\n", .{});
                for (tag.attributes.items) |attr| {
                    var l: usize = 0;
                    while (l < indent + 2) : (l += 1) {
                        std.debug.print("  ", .{});
                    }
                    if (attr.value) |val| {
                        std.debug.print("{s}=\"{s}\"\n", .{ attr.name, val });
                    } else {
                        std.debug.print("{s} (boolean)\n", .{attr.name});
                    }
                }
            }

            for (tag.children.items) |child| {
                printAst(child, indent + 1);
            }
        },
        .Text => |*text| {
            var j: usize = 0;
            while (j < indent + 1) : (j += 1) {
                std.debug.print("  ", .{});
            }
            std.debug.print("content: \"{s}\"\n", .{text.content});
        },
        .Interpolation => |*interp| {
            var j: usize = 0;
            while (j < indent + 1) : (j += 1) {
                std.debug.print("  ", .{});
            }
            std.debug.print("expr: {s}, unescaped: {}\n", .{ interp.expression, interp.is_unescaped });
        },
        .Code => |*code| {
            var j: usize = 0;
            while (j < indent + 1) : (j += 1) {
                std.debug.print("  ", .{});
            }
            std.debug.print("code: {s}\n", .{code.code});
        },
        .Comment => |*comment| {
            var j: usize = 0;
            while (j < indent + 1) : (j += 1) {
                std.debug.print("  ", .{});
            }
            std.debug.print("comment: {s}\n", .{comment.content});
        },
        .Conditional => |*cond| {
            var j: usize = 0;
            while (j < indent + 1) : (j += 1) {
                std.debug.print("  ", .{});
            }
            std.debug.print("condition: {s}\n", .{cond.condition});
            for (cond.then_branch.items) |child| {
                printAst(child, indent + 1);
            }
            if (cond.else_branch) |*else_br| {
                j = 0;
                while (j < indent + 1) : (j += 1) {
                    std.debug.print("  ", .{});
                }
                std.debug.print("else:\n", .{});
                for (else_br.items) |child| {
                    printAst(child, indent + 1);
                }
            }
        },
        .Loop => |*loop| {
            var j: usize = 0;
            while (j < indent + 1) : (j += 1) {
                std.debug.print("  ", .{});
            }
            std.debug.print("iterator: {s}, iterable: {s}\n", .{ loop.iterator, loop.iterable });
            for (loop.body.items) |child| {
                printAst(child, indent + 1);
            }
        },
        .MixinDef => |*mixin| {
            var j: usize = 0;
            while (j < indent + 1) : (j += 1) {
                std.debug.print("  ", .{});
            }
            std.debug.print("name: {s}, params: {d}\n", .{ mixin.name, mixin.params.items.len });
            if (mixin.rest_param) |rest| {
                j = 0;
                while (j < indent + 1) : (j += 1) {
                    std.debug.print("  ", .{});
                }
                std.debug.print("rest: ...{s}\n", .{rest});
            }
            for (mixin.body.items) |child| {
                printAst(child, indent + 1);
            }
        },
        .MixinCall => |*call| {
            var j: usize = 0;
            while (j < indent + 1) : (j += 1) {
                std.debug.print("  ", .{});
            }
            std.debug.print("name: {s}, args: {d}\n", .{ call.name, call.args.items.len });
            if (call.body) |*body| {
                for (body.items) |child| {
                    printAst(child, indent + 1);
                }
            }
        },
        .Include => |*inc| {
            var j: usize = 0;
            while (j < indent + 1) : (j += 1) {
                std.debug.print("  ", .{});
            }
            std.debug.print("path: {s}\n", .{inc.path});
            if (inc.filter) |filter| {
                j = 0;
                while (j < indent + 1) : (j += 1) {
                    std.debug.print("  ", .{});
                }
                std.debug.print("filter: {s}\n", .{filter});
            }
        },
        .Extends => |*ext| {
            var j: usize = 0;
            while (j < indent + 1) : (j += 1) {
                std.debug.print("  ", .{});
            }
            std.debug.print("path: {s}\n", .{ext.path});
        },
        .Block => |*block| {
            var j: usize = 0;
            while (j < indent + 1) : (j += 1) {
                std.debug.print("  ", .{});
            }
            std.debug.print("name: {s}, mode: {s}\n", .{ block.name, @tagName(block.mode) });
            for (block.body.items) |child| {
                printAst(child, indent + 1);
            }
        },
        .Case => |*case_node| {
            var j: usize = 0;
            while (j < indent + 1) : (j += 1) {
                std.debug.print("  ", .{});
            }
            std.debug.print("expression: {s}\n", .{case_node.expression});
            for (case_node.cases.items) |when_node| {
                printAst(when_node, indent + 1);
            }
            if (case_node.default) |*default| {
                j = 0;
                while (j < indent + 1) : (j += 1) {
                    std.debug.print("  ", .{});
                }
                std.debug.print("default:\n", .{});
                for (default.items) |child| {
                    printAst(child, indent + 2);
                }
            }
        },
        .When => |*when| {
            var j: usize = 0;
            while (j < indent + 1) : (j += 1) {
                std.debug.print("  ", .{});
            }
            std.debug.print("values: {d}\n", .{when.values.items.len});
            for (when.body.items) |child| {
                printAst(child, indent + 1);
            }
        },
    }
}

// ============================================================================
// Tests
// ============================================================================

test "ast - create document node" {
    var doc_node = try AstNode.create(
        std.testing.allocator,
        .Document,
        1,
        1,
        .{ .Document = .{
            .children = .{},
            .doctype = null,
        } },
    );
    defer {
        doc_node.deinit(std.testing.allocator);
        std.testing.allocator.destroy(doc_node);
    }

    try std.testing.expectEqual(NodeType.Document, doc_node.type);
    try std.testing.expectEqual(@as(usize, 1), doc_node.line);
}

test "ast - create tag node" {
    var tag_node = try AstNode.create(
        std.testing.allocator,
        .Tag,
        1,
        1,
        .{ .Tag = .{
            .name = "div",
            .attributes = .{},
            .children = .{},
            .is_self_closing = false,
        } },
    );
    defer {
        tag_node.deinit(std.testing.allocator);
        std.testing.allocator.destroy(tag_node);
    }

    try std.testing.expectEqual(NodeType.Tag, tag_node.type);
    try std.testing.expectEqualStrings("div", tag_node.data.Tag.name);
}

test "ast - create text node" {
    var text_node = try AstNode.create(
        std.testing.allocator,
        .Text,
        1,
        1,
        .{ .Text = .{
            .content = "Hello World",
            .is_raw = false,
        } },
    );
    defer {
        text_node.deinit(std.testing.allocator);
        std.testing.allocator.destroy(text_node);
    }

    try std.testing.expectEqual(NodeType.Text, text_node.type);
    try std.testing.expectEqualStrings("Hello World", text_node.data.Text.content);
}

test "ast - visitor pattern" {
    const TestContext = struct {
        count: usize,

        fn visitNode(ctx: *anyopaque, node: *AstNode) !void {
            const self: *@This() = @ptrCast(@alignCast(ctx));
            self.count += 1;
            _ = node;
        }
    };

    var doc_node = try AstNode.create(
        std.testing.allocator,
        .Document,
        1,
        1,
        .{ .Document = .{
            .children = .{},
            .doctype = null,
        } },
    );
    defer {
        doc_node.deinit(std.testing.allocator);
        std.testing.allocator.destroy(doc_node);
    }

    var ctx = TestContext{ .count = 0 };
    var visitor = Visitor{
        .context = &ctx,
        .visitFn = TestContext.visitNode,
    };

    try visitor.visit(doc_node);
    try std.testing.expectEqual(@as(usize, 1), ctx.count);
}
