//! AST Tests
//!
//! Test suite for AST node creation, memory management, and visitor pattern.
//!
//! Nota de memoria: los nodos en produccion viven en el arena del Parser.
//! En tests usamos std.testing.allocator directamente y liberamos con destroy().
//! No existe deinit() en AstNode — los ArrayListUnmanaged internos en tests
//! de nodos hoja (Text, Code, Interpolation) no necesitan deinit porque
//! no alocan hijos. Para nodos con hijos (Tag, Document) se deben vaciar
//! manualmente en tests si se usara std.testing.allocator.

const std = @import("std");
const AstNode = @import("AstNode.zig").AstNode;
const NodeType = @import("NodeType.zig").NodeType;
const Visitor  = @import("Visitor.zig").Visitor;
const VisitAction = @import("Visitor.zig").VisitAction;

test "ast - create document node" {
    const doc_node = try AstNode.create(
        std.testing.allocator,
        .Document,
        1,
        1,
        .{ .Document = .{
            .children = .empty,
            .doctype  = null,
        } },
    );
    // No deinit() — AstNode no es dueño de su memoria.
    // En produccion el arena del Parser libera todo.
    // Aqui solo liberamos el nodo en si (sin hijos alocados).
    defer std.testing.allocator.destroy(doc_node);

    try std.testing.expectEqual(NodeType.Document, doc_node.type);
    try std.testing.expectEqual(@as(usize, 1), doc_node.line);
}

test "ast - create tag node" {
    const tag_node = try AstNode.create(
        std.testing.allocator,
        .Tag,
        1,
        1,
        .{ .Tag = .{
            .name          = "div",
            .attributes    = .empty,
            .children      = .empty,
            .is_self_closing = false,
        } },
    );
    defer std.testing.allocator.destroy(tag_node);

    try std.testing.expectEqual(NodeType.Tag, tag_node.type);
    try std.testing.expectEqualStrings("div", tag_node.data.Tag.name);
}

test "ast - create text node" {
    const text_node = try AstNode.create(
        std.testing.allocator,
        .Text,
        1,
        1,
        .{ .Text = .{
            .content = "Hello World",
            .is_raw  = false,
        } },
    );
    defer std.testing.allocator.destroy(text_node);

    try std.testing.expectEqual(NodeType.Text, text_node.type);
    try std.testing.expectEqualStrings("Hello World", text_node.data.Text.content);
}

test "ast - create code node" {
    const code_node = try AstNode.create(
        std.testing.allocator,
        .Code,
        1,
        1,
        .{ .Code = .{
            .code         = "var x = 42",
            .is_buffered  = false,
            .is_unescaped = false,
        } },
    );
    defer std.testing.allocator.destroy(code_node);

    try std.testing.expectEqualStrings("var x = 42", code_node.data.Code.code);
    try std.testing.expectEqual(false, code_node.data.Code.is_buffered);
}

test "ast - create interpolation node" {
    const interp = try AstNode.create(
        std.testing.allocator,
        .Interpolation,
        1,
        1,
        .{ .Interpolation = .{
            .expression   = "user.name",
            .is_unescaped = false,
        } },
    );
    defer std.testing.allocator.destroy(interp);

    try std.testing.expectEqualStrings("user.name", interp.data.Interpolation.expression);
    try std.testing.expectEqual(false, interp.data.Interpolation.is_unescaped);
}

test "ast - visitor pattern - count nodes" {
    const Counter = struct {
        count: usize = 0,

        fn visit(ctx: *anyopaque, node: *AstNode) anyerror!VisitAction {
            const self: *@This() = @ptrCast(@alignCast(ctx));
            self.count += 1;
            _ = node;
            return .Continue;
        }
    };

    const doc_node = try AstNode.create(
        std.testing.allocator,
        .Document,
        1,
        1,
        .{ .Document = .{
            .children = .empty,
            .doctype  = null,
        } },
    );
    defer std.testing.allocator.destroy(doc_node);

    var ctx = Counter{};
    var visitor = Visitor{
        .context = &ctx,
        .visitFn = Counter.visit,
    };

    _ = try visitor.visit(doc_node);
    try std.testing.expectEqual(@as(usize, 1), ctx.count);
}

test "ast - visitor SkipChildren" {
    const Skipper = struct {
        visited: usize = 0,

        fn visit(ctx: *anyopaque, node: *AstNode) anyerror!VisitAction {
            const self: *@This() = @ptrCast(@alignCast(ctx));
            self.visited += 1;
            // Skip children of Document — Tag inside should not be visited
            if (node.type == .Document) return .SkipChildren;
            return .Continue;
        }
    };

    // Build: Document -> Tag
    const tag_node = try AstNode.create(
        std.testing.allocator,
        .Tag,
        2, 1,
        .{ .Tag = .{
            .name          = "div",
            .attributes    = .empty,
            .children      = .empty,
            .is_self_closing = false,
        } },
    );
    defer std.testing.allocator.destroy(tag_node);

    var children: std.ArrayListUnmanaged(*AstNode) = .empty;
    try children.append(std.testing.allocator, tag_node);
    defer children.deinit(std.testing.allocator);

    const doc_node = try AstNode.create(
        std.testing.allocator,
        .Document,
        1, 1,
        .{ .Document = .{
            .children = children,
            .doctype  = null,
        } },
    );
    defer std.testing.allocator.destroy(doc_node);

    var ctx = Skipper{};
    var visitor = Visitor{ .context = &ctx, .visitFn = Skipper.visit };
    _ = try visitor.visit(doc_node);

    // Only Document visited — Tag skipped
    try std.testing.expectEqual(@as(usize, 1), ctx.visited);
}

test "ast - visitor Stop" {
    const Stopper = struct {
        visited: usize = 0,

        fn visit(ctx: *anyopaque, node: *AstNode) anyerror!VisitAction {
            const self: *@This() = @ptrCast(@alignCast(ctx));
            self.visited += 1;
            _ = node;
            return .Stop;
        }
    };

    const doc_node = try AstNode.create(
        std.testing.allocator,
        .Document,
        1, 1,
        .{ .Document = .{ .children = .empty, .doctype = null } },
    );
    defer std.testing.allocator.destroy(doc_node);

    var ctx = Stopper{};
    var visitor = Visitor{ .context = &ctx, .visitFn = Stopper.visit };
    const continued = try visitor.visit(doc_node);

    try std.testing.expectEqual(false, continued);
    try std.testing.expectEqual(@as(usize, 1), ctx.visited);
}
