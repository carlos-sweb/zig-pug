//! AST Tests
//!
//! Test suite for AST node creation, memory management, and visitor pattern.

const std = @import("std");
const AstNode = @import("AstNode.zig").AstNode;
const NodeType = @import("NodeType.zig").NodeType;
const Visitor = @import("Visitor.zig").Visitor;

test "ast - create document node" {
    var doc_node = try AstNode.create(
        std.testing.allocator,
        .Document,
        1,
        1,
        .{ .Document = .{
            .children = .empty,
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
            .attributes = .empty,
            .children = .empty,
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
            .children = .empty,
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
