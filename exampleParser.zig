//! exampleParser.zig — AST output for zig-pug parser
//!
//! Parsea templates de ejemplo e imprime el AST resultante.
//! Usado para verificar que el parser produce el árbol correcto
//! antes de implementar el compiler/renderer.
//!
//! Uso:
//!   zig build exampleParser

const std = @import("std");
const Parser = @import("src/parser/mod.zig").Parser;
const ast = @import("src/ast/mod.zig");

const print = std.debug.print;

const CaseJson = struct { label: []const u8, source: []const u8 };
const CasesJson = []CaseJson;

// ---------------------------------------------------------------------------
// Runner
// ---------------------------------------------------------------------------

pub fn main(init: std.process.Init) !void {
    const allocator = init.gpa;

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

    // yq -o=json pug_cases.yaml > pug_cases.json
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

        const sep = "═" ** 46;
        print("\n{s}\n", .{sep});
        print("  {s}\n", .{case.label});
        print("  source:\n", .{});

        // Print source with line numbers
        var lines = std.mem.splitScalar(u8, case.source, '\n');
        var ln: usize = 1;
        while (lines.next()) |line| {
            print("    {d:>2}: {s}\n", .{ ln, line });
            ln += 1;
        }
        print("{s}\n", .{"─" ** 46});

        var parser = Parser.init(allocator, case.source) catch |err| {
            print("[INIT ERROR] {}\n", .{err});
            failed += 1;
            continue;
        };
        defer parser.deinit();

        const root = parser.parse() catch |err| {
            print("[PARSE ERROR] {}\n", .{err});
            failed += 1;
            continue;
        };

        ast.printAstDebug(root, 0);
        passed += 1;
    }

    const total = passed + failed;
    print("\n{s}\n", .{"═" ** 46});
    print("  {d}/{d} casos exitosos", .{ passed, total });
    if (failed > 0) {
        print("  ({d} errores)\n", .{failed});
    } else {
        print("  ✓\n", .{});
    }
    print("{s}\n", .{"═" ** 46});
}
