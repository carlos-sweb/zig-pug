const std = @import("std");
const parser = @import("src/parser/mod.zig");
const compiler = @import("src/compiler/mod.zig");
const runtime = @import("src/runtime.zig");
const formatter = @import("src/formatter.zig");

pub fn main(init: std.process.Init) !void {
    const io = init.io;
    var gpa: std.heap.DebugAllocator(.{}) = .init;
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Create JavaScript runtime
    var js_runtime = try runtime.JsRuntime.init(allocator);
    defer js_runtime.deinit();

    // Set variables
    try js_runtime.setString("name", "Alice");
    try js_runtime.setNumber("age", 25);
    try js_runtime.setBool("active", true);

    // Parse template
    const source =
        \\doctype html
        \\html
        \\  body
        \\    h1= name
        \\    p Age: #{age}
    ;

    var pars = try parser.Parser.init(allocator, source);
    defer pars.deinit();
    const tree = try pars.parse();

    // Compile to HTML
    var comp = try compiler.Compiler.init(io, allocator, js_runtime);
    defer comp.deinit();
    const html = try comp.compile(tree);
    defer allocator.free(html);

    const pretty_html = try formatter.prettyPrintHtml(allocator, html);
    defer allocator.free(pretty_html);

    std.debug.print("{s}\n", .{html});
    std.debug.print("{s}\n", .{pretty_html});
}
