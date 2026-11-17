//! Mide solo la compilación (mujs incluido). El parse queda fuera del cronómetro.
//! Plantilla: each de 200 productos, dos interpolaciones y un if por ítem.

const std = @import("std");
const Parser = @import("src/parser/mod.zig").Parser;
const Compiler = @import("src/compiler/mod.zig").Compiler;
const runtime = @import("src/runtime.zig");

const products: usize = 200;
const repeats: usize = 30;

const template =
    \\ul.products
    \\  each product in products
    \\    li.product
    \\      h2 #{product.name}
    \\      p.price $#{product.price}
    \\      if product.featured
    \\        span.badge Destacado
    \\      else
    \\        span Normal
    \\
;

fn buildContext(allocator: std.mem.Allocator) ![]u8 {
    var buf: std.ArrayListUnmanaged(u8) = .empty;
    try buf.appendSlice(allocator, "var products = [");
    var i: usize = 0;
    while (i < products) : (i += 1) {
        if (i != 0) try buf.append(allocator, ',');
        const featured = if (i % 2 == 0) "true" else "false";
        const item = try std.fmt.allocPrint(allocator, "{{name:\"Producto {d}\",price:\"{d}.00\",featured:{s}}}", .{ i + 1, (i + 1) * 10, featured });
        defer allocator.free(item);
        try buf.appendSlice(allocator, item);
    }
    try buf.appendSlice(allocator, "];\n");
    return try buf.toOwnedSlice(allocator);
}

fn nowNs(io: std.Io) i96 {
    return std.Io.Clock.Timestamp.now(io, .awake).raw.nanoseconds;
}

fn elapsedNs(io: std.Io, start: i96) u64 {
    return @intCast(nowNs(io) - start);
}

fn checksum(bytes: []const u8) u64 {
    var h: u64 = 14695981039346656037;
    for (bytes) |c| {
        h ^= c;
        h *%= 1099511628211;
    }
    return h;
}

pub fn main(init: std.process.Init) !void {
    const allocator = init.gpa;
    const io = init.io;

    const context = try buildContext(allocator);
    defer allocator.free(context);

    var js = try runtime.JsRuntime.init(allocator);
    defer js.deinit();
    const ctx = try js.eval(context);
    defer allocator.free(ctx);

    var parser = try Parser.init(allocator, template);
    defer parser.deinit();
    const root = try parser.parse();

    const t0 = nowNs(io);
    var compiler0 = try Compiler.init(io, allocator, js);
    const html0 = try compiler0.compile(root);
    compiler0.deinit();
    const cold_ns = elapsedNs(io, t0);

    var warm_ns: u64 = 0;
    var last: []const u8 = html0;
    var i: usize = 0;
    while (i < repeats) : (i += 1) {
        const t = nowNs(io);
        var compiler = try Compiler.init(io, allocator, js);
        const html = try compiler.compile(root);
        compiler.deinit();
        warm_ns += elapsedNs(io, t);
        if (i != 0) allocator.free(last);
        last = html;
    }

    std.debug.print("productos {d}, repeticiones en caliente {d}\n", .{ products, repeats });
    std.debug.print("html {d} bytes, checksum {d}\n", .{ last.len, checksum(last) });
    std.debug.print("primera compilacion {d:.3} ms\n", .{@as(f64, @floatFromInt(cold_ns)) / 1_000_000.0});
    std.debug.print("siguientes {d:.3} ms de media\n", .{@as(f64, @floatFromInt(warm_ns / repeats)) / 1_000_000.0});
    if (!std.mem.containsAtLeast(u8, last, 1, "Producto 1") or !std.mem.containsAtLeast(u8, last, 1, "Producto 200") or !std.mem.containsAtLeast(u8, last, 1, "Destacado")) {
        return error.UnexpectedHtml;
    }
    allocator.free(last);
}
