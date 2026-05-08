//! exampleCompiler.zig — HTML output for zig-pug compiler
//!
//! Compila templates de ejemplo y muestra el HTML generado.
//! Usado para verificar que el compiler produce el HTML correcto
//! antes de integrarlo en la CLI.
//!
//! Uso:
//!   zig build exampleCompiler

const std = @import("std");
const Parser = @import("src/parser/mod.zig").Parser;
const Compiler = @import("src/compiler/mod.zig").Compiler;
const runtime = @import("src/runtime.zig");

const print = std.debug.print;

// ---------------------------------------------------------------------------
// Caso de prueba
// ---------------------------------------------------------------------------

const Var = struct {
    name: []const u8,
    value: Value,
};

const Value = union(enum) {
    string: []const u8,
    boolean: bool,
    number: f64,
};

const CaseJson = struct {
    label: []const u8,
    source: []const u8,
    context: []const Var = &.{},
    expected: ?[]const u8 = null, // null = solo mostrar salida, no validar

};
const CasesJson = []CaseJson;

// ---------------------------------------------------------------------------
// Runner
// ---------------------------------------------------------------------------

pub fn main(init: std.process.Init) !void {
    const allocator = init.gpa;
    const io = init.io;
    // Parsear filtro -e:N o -e:N,M,K
    var filter: std.ArrayList(usize) = .empty;
    defer filter.deinit(allocator);

    var args_it = try init.minimal.args.iterateAllocator(allocator);
    defer args_it.deinit();
    _ = args_it.next(); // skip argv[0] (nombre del ejecutable)

    while (args_it.next()) |arg| {
        if (std.mem.startsWith(u8, arg, "-e:")) {
            var it = std.mem.splitScalar(u8, arg[3..], ',');
            while (it.next()) |num_str| {
                const n = try std.fmt.parseInt(usize, num_str, 10);
                try filter.append(allocator, n);
            }
        }
    }

    const CaseParsed = try std.json.parseFromSlice(CasesJson, allocator, @embedFile("./pug_cases.json"), .{ .ignore_unknown_fields = true });
    defer CaseParsed.deinit();

    var passed: usize = 0;
    var failed: usize = 0;

    for (CaseParsed.value, 0..) |case, i| {
        const example_num = i + 1;

        if (filter.items.len > 0) {
            const included = for (filter.items) |n| {
                if (n == example_num) break true;
            } else false;
            if (!included) continue;
        }

        const sep = "═" ** 50;
        print("\n{s}\n [{d}] {s}\n", .{ sep, i + 1, case.label });

        // Print source
        var lines = std.mem.splitScalar(u8, case.source, '\n');
        var ln: usize = 1;
        while (lines.next()) |line| {
            print("  {d:>2}: {s}\n", .{ ln, line });
            ln += 1;
        }
        print("{s}\n", .{"─" ** 50});

        // Parse
        var parser = Parser.init(allocator, case.source) catch |err| {
            print("[PARSE ERROR] {}\n", .{err});
            failed += 1;
            continue;
        };
        defer parser.deinit();

        const root = parser.parse() catch |err| {
            print("[PARSE ERROR] {}\n", .{err});
            failed += 1;
            continue;
        };

        // Runtime
        var js_runtime = runtime.JsRuntime.init(allocator) catch |err| {
            print("[RUNTIME ERROR] {}\n", .{err});
            failed += 1;
            continue;
        };
        defer js_runtime.deinit();

        // Set context variables
        for (case.context) |v| {
            const js_val = switch (v.value) {
                .string => |s| runtime.jsValueFromString(allocator, s) catch continue,
                .boolean => |b| runtime.jsValueFromBool(allocator, b) catch continue,
                .number => |n| runtime.jsValueFromNumber(allocator, n) catch continue,
            };
            js_runtime.setContext(v.name, js_val) catch {};
            var val_copy = js_val;
            val_copy.deinit(allocator);
        }

        // Compile
        var compiler = Compiler.init(io, allocator, js_runtime) catch |err| {
            print("[COMPILER INIT ERROR] {}\n", .{err});
            failed += 1;
            continue;
        };
        defer compiler.deinit();

        const html = compiler.compile(root) catch |err| {
            print("[COMPILE ERROR] {}\n", .{err});
            // Print accumulated errors if any
            for (compiler.errors.items) |e| {
                print("  → [{s}] line {d}: {s}", .{ @tagName(e.type), e.line, e.message });
                if (e.detail) |d| print(" ({s})", .{d});
                print("\n", .{});
            }
            failed += 1;
            continue;
        };
        defer allocator.free(html);

        print("HTML: {s}\n", .{html});

        // Validate if expected is set
        if (case.expected) |expected| {
            if (std.mem.eql(u8, html, expected)) {
                print("✓ OK\n", .{});
                passed += 1;
            } else {
                print("✗ FAIL\n", .{});
                print("  expected: {s}\n", .{expected});
                print("  got:      {s}\n", .{html});
                failed += 1;
            }
        } else {
            passed += 1;
        }
    }

    print("\n{s}\n", .{"═" ** 50});
    print("  {d}/{d} casos exitosos", .{ passed, passed + failed });
    if (failed > 0) {
        print("  ({d} errores)\n", .{failed});
    } else {
        print("  ✓\n", .{});
    }
    print("{s}\n", .{"═" ** 50});
}
