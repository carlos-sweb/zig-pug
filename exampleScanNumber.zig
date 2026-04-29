const std = @import("std");
const Tokenizer = @import("src/tokenizer/mod.zig").Tokenizer;
const print = std.debug.print;

// Casos de prueba enfocados en detectar cuando scanNumber se invoca.
// Cubre: atributos con números sin comillas, expresiones JS, interpolación.
const cases = [_]struct { label: []const u8, source: []const u8 }{
    .{
        .label  = "atributos numéricos sin comillas",
        .source = "input(type=\"number\" value=100 min=50 max=150)",
    },
    .{
        .label  = "número con punto (posible float)",
        .source = "input(step=0.5)",
    },
    .{
        .label  = "expresión con punto — acceso a propiedad",
        .source = "div(data-value=3.items.length)",
    },
    .{
        .label  = "interpolación delega a mujs",
        .source = "input(value=#{age})",
    },
    .{
        .label  = "código JS inline con número",
        .source = "- var x = 42",
    },
    .{
        .label  = "loop con array literal",
        .source = "each item in [1,2,3]",
    },
};

pub fn main() !void {

    var gpa : std.heap.DebugAllocator(.{}) = .init;
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    


    for (cases) |case| {
        print("\n",.{});
        print("══════════════════════════════════════════════\n", .{});
        print("  {s}\n", .{case.label});
        print("  source: {s}\n", .{case.source});
        print("══════════════════════════════════════════════\n", .{});
        print("{s:<20} {s:<30} {s}\n", .{ "TOKEN TYPE", "VALUE", "LINE:COL" });
        print("──────────────────────────────────────────────\n", .{});

        var tokenizer = try Tokenizer.init(allocator, case.source);
        defer tokenizer.deinit();

        while (true) {
            const token = tokenizer.next() catch |err| {
                print("[ERROR] {}\n", .{err});
                break;
            };

            // Marcar tokens Number con *** para que sean visibles de inmediato
            const marker = if (token.type == .Number) "  *** NUMBER ***" else "";

            print("{s:<20} {s:<30} {}:{}{s}\n", .{
                @tagName(token.type),
                token.value,
                token.line,
                token.column,
                marker,
            });

            if (token.type == .Eof) break;
        }
    }

    print("\n", .{});
}
