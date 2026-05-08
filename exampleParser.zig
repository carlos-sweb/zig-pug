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

pub fn main() !void {
    var gpa: std.heap.DebugAllocator(.{}) = .init;
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    // yq -o=json pug_cases.yaml > pug_cases.json
    const CaseParsed = try std.json.parseFromSlice(CasesJson, allocator, @embedFile("./pug_cases.json"), .{ .ignore_unknown_fields = true });
    defer CaseParsed.deinit();

    var passed: usize = 0;
    var failed: usize = 0;

    for (CaseParsed.value) |case| {
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
