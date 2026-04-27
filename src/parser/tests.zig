//! Parser Tests
//!
//! This module contains all tests for the parser.

const std = @import("std");
const Parser = @import("mod.zig").Parser;
const ast = @import("../ast/mod.zig");

test "parser - simple tag" {
    var parser = try Parser.init(std.testing.allocator, "div");
    defer parser.deinit();

    const tree = try parser.parse();
    try std.testing.expectEqual(ast.NodeType.Document, tree.type);
    try std.testing.expectEqual(@as(usize, 1), tree.data.Document.children.items.len);

    const tag = tree.data.Document.children.items[0];
    try std.testing.expectEqual(ast.NodeType.Tag, tag.type);
    try std.testing.expectEqualStrings("div", tag.data.Tag.name);
}

test "parser - tag with class" {
    var parser = try Parser.init(std.testing.allocator, "div.container");
    defer parser.deinit();

    const tree = try parser.parse();
    const tag = tree.data.Document.children.items[0];

    try std.testing.expectEqualStrings("div", tag.data.Tag.name);
    try std.testing.expectEqual(@as(usize, 1), tag.data.Tag.attributes.items.len);
    try std.testing.expectEqualStrings("class", tag.data.Tag.attributes.items[0].name);
    try std.testing.expectEqualStrings("container", tag.data.Tag.attributes.items[0].value.?);
}

test "parser - tag with id" {
    var parser = try Parser.init(std.testing.allocator, "div#main");
    defer parser.deinit();

    const tree = try parser.parse();
    const tag = tree.data.Document.children.items[0];

    try std.testing.expectEqualStrings("div", tag.data.Tag.name);
    try std.testing.expectEqual(@as(usize, 1), tag.data.Tag.attributes.items.len);
    try std.testing.expectEqualStrings("id", tag.data.Tag.attributes.items[0].name);
    try std.testing.expectEqualStrings("main", tag.data.Tag.attributes.items[0].value.?);
}

test "parser - tag with attributes" {
    var parser = try Parser.init(std.testing.allocator, "a(href=\"google.com\")");
    defer parser.deinit();

    const tree = try parser.parse();
    const tag = tree.data.Document.children.items[0];

    try std.testing.expectEqualStrings("a", tag.data.Tag.name);
    try std.testing.expectEqual(@as(usize, 1), tag.data.Tag.attributes.items.len);
    try std.testing.expectEqualStrings("href", tag.data.Tag.attributes.items[0].name);
    try std.testing.expectEqualStrings("google.com", tag.data.Tag.attributes.items[0].value.?);
}

test "parser - tag with text" {
    var parser = try Parser.init(std.testing.allocator, "p Hello World");
    defer parser.deinit();

    const tree = try parser.parse();
    const tag = tree.data.Document.children.items[0];

    try std.testing.expectEqualStrings("p", tag.data.Tag.name);
    try std.testing.expectEqual(@as(usize, 1), tag.data.Tag.children.items.len);

    const text = tag.data.Tag.children.items[0];
    try std.testing.expectEqual(ast.NodeType.Text, text.type);
    try std.testing.expectEqualStrings("Hello World", text.data.Text.content);
}

test "parser - nested tags" {
    const source =
        \\div
        \\  p Hello
    ;
    var parser = try Parser.init(std.testing.allocator, source);
    defer parser.deinit();

    const tree = try parser.parse();
    const div = tree.data.Document.children.items[0];

    try std.testing.expectEqualStrings("div", div.data.Tag.name);
    try std.testing.expectEqual(@as(usize, 1), div.data.Tag.children.items.len);

    const p = div.data.Tag.children.items[0];
    try std.testing.expectEqual(ast.NodeType.Tag, p.type);
    try std.testing.expectEqualStrings("p", p.data.Tag.name);
}

test "parser - comment" {
    var parser = try Parser.init(std.testing.allocator, "// This is a comment");
    defer parser.deinit();

    const tree = try parser.parse();
    const comment = tree.data.Document.children.items[0];

    try std.testing.expectEqual(ast.NodeType.Comment, comment.type);
    try std.testing.expectEqualStrings("This is a comment", comment.data.Comment.content);
    try std.testing.expect(comment.data.Comment.is_buffered);
}

test "parser - conditional (if)" {
    const source =
        \\if user
        \\  p Welcome!
    ;
    var parser = try Parser.init(std.testing.allocator, source);
    defer parser.deinit();

    const tree = try parser.parse();
    const conditional = tree.data.Document.children.items[0];

    try std.testing.expectEqual(ast.NodeType.Conditional, conditional.type);
    try std.testing.expectEqualStrings("user", conditional.data.Conditional.condition);
    try std.testing.expect(!conditional.data.Conditional.is_unless);
    try std.testing.expectEqual(@as(usize, 1), conditional.data.Conditional.then_branch.items.len);
}

test "parser - conditional (unless)" {
    const source =
        \\unless loggedIn
        \\  p Please login
    ;
    var parser = try Parser.init(std.testing.allocator, source);
    defer parser.deinit();

    const tree = try parser.parse();
    const conditional = tree.data.Document.children.items[0];

    try std.testing.expectEqual(ast.NodeType.Conditional, conditional.type);
    try std.testing.expectEqualStrings("loggedIn", conditional.data.Conditional.condition);
    try std.testing.expect(conditional.data.Conditional.is_unless);
}

test "parser - conditional with else" {
    const source =
        \\if user
        \\  p Welcome!
        \\else
        \\  p Please login
    ;
    var parser = try Parser.init(std.testing.allocator, source);
    defer parser.deinit();

    const tree = try parser.parse();
    const conditional = tree.data.Document.children.items[0];

    try std.testing.expectEqual(ast.NodeType.Conditional, conditional.type);
    try std.testing.expect(conditional.data.Conditional.else_branch != null);
    try std.testing.expectEqual(@as(usize, 1), conditional.data.Conditional.else_branch.?.items.len);
}

test "parser - loop (each)" {
    const source =
        \\each item in items
        \\  p= item
    ;
    var parser = try Parser.init(std.testing.allocator, source);
    defer parser.deinit();

    const tree = try parser.parse();
    const loop = tree.data.Document.children.items[0];

    try std.testing.expectEqual(ast.NodeType.Loop, loop.type);
    try std.testing.expect(!loop.data.Loop.is_while);
    try std.testing.expectEqual(@as(usize, 1), loop.data.Loop.body.items.len);
}

test "parser - loop (while)" {
    const source =
        \\while n < 5
        \\  p= n
    ;
    var parser = try Parser.init(std.testing.allocator, source);
    defer parser.deinit();

    const tree = try parser.parse();
    const loop = tree.data.Document.children.items[0];

    try std.testing.expectEqual(ast.NodeType.Loop, loop.type);
    try std.testing.expect(loop.data.Loop.is_while);
}

test "parser - case statement" {
    const source =
        \\case fruit
        \\  when "apple"
        \\    p It's an apple
        \\  when "orange", "lemon"
        \\    p It's citrus
        \\  default
        \\    p Unknown fruit
    ;
    var parser = try Parser.init(std.testing.allocator, source);
    defer parser.deinit();

    const tree = try parser.parse();
    const case_node = tree.data.Document.children.items[0];

    try std.testing.expectEqual(ast.NodeType.Case, case_node.type);
    try std.testing.expectEqualStrings("fruit", case_node.data.Case.expression);
    try std.testing.expectEqual(@as(usize, 2), case_node.data.Case.cases.items.len);
    try std.testing.expect(case_node.data.Case.default != null);

    // Check first when node
    const when1 = case_node.data.Case.cases.items[0];
    try std.testing.expectEqual(ast.NodeType.When, when1.type);
    try std.testing.expectEqual(@as(usize, 1), when1.data.When.values.items.len);

    // Check second when node
    const when2 = case_node.data.Case.cases.items[1];
    try std.testing.expectEqual(ast.NodeType.When, when2.type);
    try std.testing.expectEqual(@as(usize, 2), when2.data.When.values.items.len);
}

test "parser - attributes with values" {
    const source = "a(href=\"/home\" title=\"Home Page\")";
    var parser = try Parser.init(std.testing.allocator, source);
    defer parser.deinit();

    const tree = try parser.parse();
    const tag = tree.data.Document.children.items[0];

    try std.testing.expectEqual(ast.NodeType.Tag, tag.type);
    try std.testing.expectEqualStrings("a", tag.data.Tag.name);
    try std.testing.expectEqual(@as(usize, 2), tag.data.Tag.attributes.items.len);

    const attr1 = tag.data.Tag.attributes.items[0];
    try std.testing.expectEqualStrings("href", attr1.name);
    try std.testing.expectEqualStrings("/home", attr1.value.?);

    const attr2 = tag.data.Tag.attributes.items[1];
    try std.testing.expectEqualStrings("title", attr2.name);
    try std.testing.expectEqualStrings("Home Page", attr2.value.?);
}

test "parser - boolean attributes" {
    const source = "input(type=\"checkbox\" checked disabled)";
    var parser = try Parser.init(std.testing.allocator, source);
    defer parser.deinit();

    const tree = try parser.parse();
    const tag = tree.data.Document.children.items[0];

    try std.testing.expectEqual(@as(usize, 3), tag.data.Tag.attributes.items.len);

    const attr1 = tag.data.Tag.attributes.items[0];
    try std.testing.expectEqualStrings("type", attr1.name);
    try std.testing.expectEqualStrings("checkbox", attr1.value.?);

    const attr2 = tag.data.Tag.attributes.items[1];
    try std.testing.expectEqualStrings("checked", attr2.name);
    try std.testing.expect(attr2.value == null); // Boolean attribute

    const attr3 = tag.data.Tag.attributes.items[2];
    try std.testing.expectEqualStrings("disabled", attr3.name);
    try std.testing.expect(attr3.value == null); // Boolean attribute
}

test "parser - multiline attributes" {
    const source =
        \\a(
        \\  href="/home"
        \\  title="Home"
        \\)
    ;
    var parser = try Parser.init(std.testing.allocator, source);
    defer parser.deinit();

    const tree = try parser.parse();
    const tag = tree.data.Document.children.items[0];

    try std.testing.expectEqual(ast.NodeType.Tag, tag.type);
    try std.testing.expectEqual(@as(usize, 2), tag.data.Tag.attributes.items.len);

    const attr1 = tag.data.Tag.attributes.items[0];
    try std.testing.expectEqualStrings("href", attr1.name);

    const attr2 = tag.data.Tag.attributes.items[1];
    try std.testing.expectEqualStrings("title", attr2.name);
}

test "parser - attributes with commas" {
    const source = "div(class=\"foo\", id=\"bar\", data-value=\"baz\")";
    var parser = try Parser.init(std.testing.allocator, source);
    defer parser.deinit();

    const tree = try parser.parse();
    const tag = tree.data.Document.children.items[0];

    try std.testing.expectEqual(@as(usize, 3), tag.data.Tag.attributes.items.len);

    try std.testing.expectEqualStrings("class", tag.data.Tag.attributes.items[0].name);
    try std.testing.expectEqualStrings("id", tag.data.Tag.attributes.items[1].name);
    try std.testing.expectEqualStrings("data-value", tag.data.Tag.attributes.items[2].name);
}

test "parser - mixin definition" {
    const source =
        \\mixin greeting(name)
        \\  p Hello #{name}
    ;
    var parser = try Parser.init(std.testing.allocator, source);
    defer parser.deinit();

    const tree = try parser.parse();
    const mixin_def = tree.data.Document.children.items[0];

    try std.testing.expectEqual(ast.NodeType.MixinDef, mixin_def.type);
    try std.testing.expectEqualStrings("greeting", mixin_def.data.MixinDef.name);
    try std.testing.expectEqual(@as(usize, 1), mixin_def.data.MixinDef.params.items.len);
    try std.testing.expectEqualStrings("name", mixin_def.data.MixinDef.params.items[0]);
    try std.testing.expectEqual(@as(usize, 1), mixin_def.data.MixinDef.body.items.len);
}

test "parser - mixin definition with rest param" {
    const source =
        \\mixin list(...items)
        \\  ul
    ;
    var parser = try Parser.init(std.testing.allocator, source);
    defer parser.deinit();

    const tree = try parser.parse();
    const mixin_def = tree.data.Document.children.items[0];

    try std.testing.expectEqual(ast.NodeType.MixinDef, mixin_def.type);
    try std.testing.expectEqualStrings("list", mixin_def.data.MixinDef.name);
    try std.testing.expect(mixin_def.data.MixinDef.rest_param != null);
    try std.testing.expectEqualStrings("items", mixin_def.data.MixinDef.rest_param.?);
}

test "parser - mixin call" {
    const source =
        \\+greeting(John)
    ;
    var parser = try Parser.init(std.testing.allocator, source);
    defer parser.deinit();

    const tree = try parser.parse();
    const mixin_call = tree.data.Document.children.items[0];

    try std.testing.expectEqual(ast.NodeType.MixinCall, mixin_call.type);
    try std.testing.expectEqualStrings("greeting", mixin_call.data.MixinCall.name);
    try std.testing.expectEqual(@as(usize, 1), mixin_call.data.MixinCall.args.items.len);
}

test "parser - mixin call with block" {
    const source =
        \\+card
        \\  p Content
    ;
    var parser = try Parser.init(std.testing.allocator, source);
    defer parser.deinit();

    const tree = try parser.parse();
    const mixin_call = tree.data.Document.children.items[0];

    try std.testing.expectEqual(ast.NodeType.MixinCall, mixin_call.type);
    try std.testing.expect(mixin_call.data.MixinCall.body != null);
    try std.testing.expectEqual(@as(usize, 1), mixin_call.data.MixinCall.body.?.items.len);
}

test "parser - include" {
    const source = "include header.zpug";
    var parser = try Parser.init(std.testing.allocator, source);
    defer parser.deinit();

    const tree = try parser.parse();
    const include = tree.data.Document.children.items[0];

    try std.testing.expectEqual(ast.NodeType.Include, include.type);
    try std.testing.expectEqualStrings("header.zpug", include.data.Include.path);
    try std.testing.expect(include.data.Include.filter == null);
}

test "parser - include with filter" {
    const source = "include:markdown content.md";
    var parser = try Parser.init(std.testing.allocator, source);
    defer parser.deinit();

    const tree = try parser.parse();
    const include = tree.data.Document.children.items[0];

    try std.testing.expectEqual(ast.NodeType.Include, include.type);
    try std.testing.expectEqualStrings("content.md", include.data.Include.path);
    try std.testing.expect(include.data.Include.filter != null);
    try std.testing.expectEqualStrings("markdown", include.data.Include.filter.?);
}

test "parser - extends" {
    const source = "extends layout.zpug";
    var parser = try Parser.init(std.testing.allocator, source);
    defer parser.deinit();

    const tree = try parser.parse();
    const extends = tree.data.Document.children.items[0];

    try std.testing.expectEqual(ast.NodeType.Extends, extends.type);
    try std.testing.expectEqualStrings("layout.zpug", extends.data.Extends.path);
}

test "parser - block" {
    const source =
        \\block content
        \\  p Default content
    ;
    var parser = try Parser.init(std.testing.allocator, source);
    defer parser.deinit();

    const tree = try parser.parse();
    const block = tree.data.Document.children.items[0];

    try std.testing.expectEqual(ast.NodeType.Block, block.type);
    try std.testing.expectEqualStrings("content", block.data.Block.name);
    try std.testing.expectEqual(ast.BlockMode.Replace, block.data.Block.mode);
    try std.testing.expectEqual(@as(usize, 1), block.data.Block.body.items.len);
}

test "parser - block append" {
    const source =
        \\block append scripts
        \\  script(src="app.js")
    ;
    var parser = try Parser.init(std.testing.allocator, source);
    defer parser.deinit();

    const tree = try parser.parse();
    const block = tree.data.Document.children.items[0];

    try std.testing.expectEqual(ast.NodeType.Block, block.type);
    try std.testing.expectEqualStrings("scripts", block.data.Block.name);
    try std.testing.expectEqual(ast.BlockMode.Append, block.data.Block.mode);
}

test "parser - block prepend" {
    const source =
        \\block prepend head
        \\  meta(charset="utf-8")
    ;
    var parser = try Parser.init(std.testing.allocator, source);
    defer parser.deinit();

    const tree = try parser.parse();
    const block = tree.data.Document.children.items[0];

    try std.testing.expectEqual(ast.NodeType.Block, block.type);
    try std.testing.expectEqualStrings("head", block.data.Block.name);
    try std.testing.expectEqual(ast.BlockMode.Prepend, block.data.Block.mode);
}

test "parser - interpolation as separate node" {
    const source = "p Hello #{name}";
    var parser = try Parser.init(std.testing.allocator, source);
    defer parser.deinit();

    const tree = try parser.parse();
    const tag = tree.data.Document.children.items[0];

    try std.testing.expectEqual(ast.NodeType.Tag, tag.type);
    try std.testing.expectEqualStrings("p", tag.data.Tag.name);
    try std.testing.expectEqual(@as(usize, 2), tag.data.Tag.children.items.len);

    // First child should be Text
    const text_node = tag.data.Tag.children.items[0];
    try std.testing.expectEqual(ast.NodeType.Text, text_node.type);
    try std.testing.expectEqualStrings("Hello ", text_node.data.Text.content);

    // Second child should be Interpolation
    const interp_node = tag.data.Tag.children.items[1];
    try std.testing.expectEqual(ast.NodeType.Interpolation, interp_node.type);
    try std.testing.expectEqualStrings("name", interp_node.data.Interpolation.expression);
    try std.testing.expectEqual(false, interp_node.data.Interpolation.is_unescaped);
}

test "parser - multiple interpolations" {
    const source = "p #{greeting} #{name}!";
    var parser = try Parser.init(std.testing.allocator, source);
    defer parser.deinit();

    const tree = try parser.parse();
    const tag = tree.data.Document.children.items[0];

    try std.testing.expectEqual(@as(usize, 4), tag.data.Tag.children.items.len);

    // First: Interpolation
    try std.testing.expectEqual(ast.NodeType.Interpolation, tag.data.Tag.children.items[0].type);
    try std.testing.expectEqualStrings("greeting", tag.data.Tag.children.items[0].data.Interpolation.expression);

    // Second: Interpolation
    try std.testing.expectEqual(ast.NodeType.Interpolation, tag.data.Tag.children.items[1].type);
    try std.testing.expectEqualStrings("name", tag.data.Tag.children.items[1].data.Interpolation.expression);

    // Third: Text
    try std.testing.expectEqual(ast.NodeType.Text, tag.data.Tag.children.items[2].type);
    try std.testing.expectEqualStrings("!", tag.data.Tag.children.items[2].data.Text.content);
}

test "parser - unescaped interpolation" {
    const source = "div !{htmlContent}";
    var parser = try Parser.init(std.testing.allocator, source);
    defer parser.deinit();

    const tree = try parser.parse();
    const tag = tree.data.Document.children.items[0];

    try std.testing.expectEqual(@as(usize, 1), tag.data.Tag.children.items.len);

    const interp_node = tag.data.Tag.children.items[0];
    try std.testing.expectEqual(ast.NodeType.Interpolation, interp_node.type);
    try std.testing.expectEqualStrings("htmlContent", interp_node.data.Interpolation.expression);
    try std.testing.expectEqual(true, interp_node.data.Interpolation.is_unescaped);
}

test "parser - interpolation with JavaScript expression" {
    const source = "p #{name.toLowerCase()}";
    var parser = try Parser.init(std.testing.allocator, source);
    defer parser.deinit();

    const tree = try parser.parse();
    const tag = tree.data.Document.children.items[0];

    try std.testing.expectEqual(@as(usize, 1), tag.data.Tag.children.items.len);

    const interp_node = tag.data.Tag.children.items[0];
    try std.testing.expectEqual(ast.NodeType.Interpolation, interp_node.type);
    try std.testing.expectEqualStrings("name.toLowerCase()", interp_node.data.Interpolation.expression);
}

test "parser - pipe text with interpolation" {
    const source =
        \\div
        \\  | Hello #{name}!
    ;
    var parser = try Parser.init(std.testing.allocator, source);
    defer parser.deinit();

    const tree = try parser.parse();
    const div_tag = tree.data.Document.children.items[0];

    try std.testing.expectEqual(@as(usize, 1), div_tag.data.Tag.children.items.len);

    const pipe_container = div_tag.data.Tag.children.items[0];
    // When there are multiple nodes, parsePipeText wraps them in a Tag container
    try std.testing.expectEqual(ast.NodeType.Tag, pipe_container.type);
    try std.testing.expectEqual(@as(usize, 3), pipe_container.data.Tag.children.items.len);

    // First: Text "Hello"
    try std.testing.expectEqual(ast.NodeType.Text, pipe_container.data.Tag.children.items[0].type);
    try std.testing.expectEqualStrings("Hello ", pipe_container.data.Tag.children.items[0].data.Text.content);

    // Second: Interpolation "name"
    try std.testing.expectEqual(ast.NodeType.Interpolation, pipe_container.data.Tag.children.items[1].type);
    try std.testing.expectEqualStrings("name", pipe_container.data.Tag.children.items[1].data.Interpolation.expression);

    // Third: Text "!" (note: has trailing space due to token processing)
    try std.testing.expectEqual(ast.NodeType.Text, pipe_container.data.Tag.children.items[2].type);
    try std.testing.expectEqualStrings("!", pipe_container.data.Tag.children.items[2].data.Text.content);
}
