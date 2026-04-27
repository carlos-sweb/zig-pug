const std = @import("std");
const parser = @import("src/parser/mod.zig");
const compiler = @import("src/compiler/mod.zig");
const runtime = @import("src/runtime.zig");
const formatter = @import("src/formatter.zig"); // ← agregar esto

pub fn main(int: std.process.Init) !void {
    const io = int.io;
    var gpa: std.heap.DebugAllocator(.{}) = .init;
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const template =
        \\div.greeting
        \\  h1 Hi There!
        \\  p This is my first zig-pug template
    ;

    var js_runtime = try runtime.JsRuntime.init(allocator);
    defer js_runtime.deinit();

    var pars = try parser.Parser.init(allocator, template);
    defer pars.deinit();
    const ast = try pars.parse();

    var comp = try compiler.Compiler.init(io, allocator, js_runtime);
    defer comp.deinit();

    const html = try comp.compile(ast);
    defer allocator.free(html);

    // pretty
    const pretty_html = try formatter.prettyPrintHtml(allocator, html);
    defer allocator.free(pretty_html);

    std.debug.print("HTML Output:\n{s}\n\n", .{html});
    std.debug.print("HTML Output:\n{s}\n", .{pretty_html});
}
