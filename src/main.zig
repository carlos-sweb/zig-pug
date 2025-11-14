const std = @import("std");
const tokenizer = @import("tokenizer.zig");
const ast = @import("ast.zig");
const parser = @import("parser.zig");

pub fn main() !void {
    var stdout_buffer: [4096]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;

    try stdout.print("zig-pug v0.1.0\n", .{});
    try stdout.print("Template engine inspired by Pug\n", .{});
    try stdout.print("Built with Zig 0.15.2\n", .{});
    try stdout.print("\n", .{});

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Demo del tokenizer
    try stdout.print("=== Tokenizer Demo ===\n", .{});
    const source = "div.container#main\n  p Hello #{name}\n  // comment\n  span World";
    try stdout.print("Source:\n{s}\n\n", .{source});

    var tok = try tokenizer.Tokenizer.init(allocator, source);
    defer tok.deinit();

    try stdout.print("Tokens:\n", .{});

    while (true) {
        const token = try tok.next();
        if (token.type == .Eof) break;
        try stdout.print("  [{d}:{d}] {s:18} = '{s}'\n", .{
            token.line,
            token.column,
            @tagName(token.type),
            token.value,
        });
    }

    try stdout.print("\n", .{});

    // Demo del AST
    try stdout.print("=== AST Demo ===\n", .{});

    // Crear un árbol AST simple de ejemplo
    var doc_node = try ast.AstNode.create(
        allocator,
        .Document,
        1,
        1,
        .{ .Document = .{
            .children = .{},
            .doctype = null,
        } },
    );
    defer {
        doc_node.deinit(allocator);
        allocator.destroy(doc_node);
    }

    // Agregar un tag hijo
    const tag_node = try ast.AstNode.create(
        allocator,
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
    try doc_node.data.Document.children.append(allocator, tag_node);

    // Agregar texto como hijo del tag
    const text_node = try ast.AstNode.create(
        allocator,
        .Text,
        1,
        5,
        .{ .Text = .{
            .content = "Hello World",
            .is_raw = false,
        } },
    );
    try tag_node.data.Tag.children.append(allocator, text_node);

    try stdout.print("AST Structure:\n", .{});
    try stdout.flush();

    ast.printAst(doc_node, 0);

    try stdout.print("\n", .{});

    // Demo del Parser
    try stdout.print("=== Parser Demo ===\n", .{});
    const pug_source =
        \\mixin greeting(name)
        \\  p Hello #{name}
        \\div.container#main
        \\  h1 Hello World
        \\  a(href="/home" title="Home Page") Go Home
        \\  input(type="checkbox" checked disabled)
        \\  +greeting(User)
        \\  p Welcome to zig-pug
        \\  // This is a comment
        \\  if loggedIn
        \\    p User is logged in
        \\  else
        \\    p Please log in
        \\  each item in items
        \\    li= item
        \\  case fruit
        \\    when apple
        \\      p It is an apple
        \\    default
        \\      p Unknown
        \\  block content
        \\    p Default block content
    ;
    try stdout.print("Pug Source:\n{s}\n\n", .{pug_source});

    var pug_parser = try parser.Parser.init(allocator, pug_source);
    defer pug_parser.deinit();

    const parsed_tree = try pug_parser.parse();

    try stdout.print("Parsed AST:\n", .{});
    try stdout.flush();

    ast.printAst(parsed_tree, 0);

    try stdout.flush();
}

test "basic test" {
    try std.testing.expectEqual(@as(i32, 42), 42);
}
