//! Compiler Tests
//!
//! Test suite for HTML compilation from AST.

const std = @import("std");
const Compiler = @import("mod.zig").Compiler;
const Parser = @import("../parser/mod.zig").Parser;
const runtime = @import("../runtime.zig");

test "compiler - simple tag" {
    const source = "p Hello World";
    var parser = try Parser.init(std.testing.allocator, source);
    defer parser.deinit();

    const tree = try parser.parse();

    var js_runtime = try runtime.JsRuntime.init(std.testing.allocator);
    defer js_runtime.deinit();

    var threaded: std.Io.Threaded = .init(std.testing.allocator, .{});
    defer threaded.deinit();
    const io = threaded.io();

    var compiler = try Compiler.init(io, std.testing.allocator, js_runtime);
    defer compiler.deinit();

    const html = try compiler.compile(tree);
    defer std.testing.allocator.free(html);

    try std.testing.expectEqualStrings("<p>Hello World</p>", html);
}

test "compiler - nested tags" {
    const source =
        \\div
        \\  p Hello
        \\  p World
    ;
    var parser = try Parser.init(std.testing.allocator, source);
    defer parser.deinit();

    const tree = try parser.parse();

    var js_runtime = try runtime.JsRuntime.init(std.testing.allocator);
    defer js_runtime.deinit();

    var threaded: std.Io.Threaded = .init(std.testing.allocator, .{});
    defer threaded.deinit();
    const io = threaded.io();

    var compiler = try Compiler.init(io, std.testing.allocator, js_runtime);
    defer compiler.deinit();

    const html = try compiler.compile(tree);
    defer std.testing.allocator.free(html);

    try std.testing.expectEqualStrings("<div><p>Hello</p><p>World</p></div>", html);
}

test "compiler - attributes" {
    const source = "a(href=\"/home\" class=\"link\") Home";
    var parser = try Parser.init(std.testing.allocator, source);
    defer parser.deinit();

    const tree = try parser.parse();

    var js_runtime = try runtime.JsRuntime.init(std.testing.allocator);
    defer js_runtime.deinit();

    var threaded: std.Io.Threaded = .init(std.testing.allocator, .{});
    defer threaded.deinit();
    const io = threaded.io();

    var compiler = try Compiler.init(io, std.testing.allocator, js_runtime);
    defer compiler.deinit();

    const html = try compiler.compile(tree);
    defer std.testing.allocator.free(html);

    try std.testing.expectEqualStrings("<a href=\"/home\" class=\"link\">Home</a>", html);
}
