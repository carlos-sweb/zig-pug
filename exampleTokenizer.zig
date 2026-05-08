const std = @import("std");
const Tokenizer = @import("src/tokenizer/mod.zig").Tokenizer;
const print = std.debug.print;

const CaseJson = struct { label: []const u8, source: []const u8 };
const CasesJson = []CaseJson;

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

    for (CaseParsed.value, 0..) |case, i| {
        const example_num = i + 1;

        if (filter.items.len > 0) {
            const included = for (filter.items) |n| {
                if (n == example_num) break true;
            } else false;
            if (!included) continue;
        }

        print("\n", .{});
        print("══════════════════════════════════════════════\n", .{});
        print("  [{d}] {s}\n", .{ example_num, case.label });
        print("  source:\n{s}\n", .{case.source});
        print("══════════════════════════════════════════════\n", .{});
        print("{s:<15} {s:<30} {s}\n", .{ "TOKEN TYPE", "VALUE", "LINE:COL" });
        print("──────────────────────────────────────────────\n", .{});

        var tokenizer = try Tokenizer.init(allocator, case.source);
        defer tokenizer.deinit();

        while (true) {
            const token = tokenizer.next() catch |err| {
                print("[ERROR] {}\n", .{err});
                break;
            };

            print("{s:<22} {s:<30} {}:{}\n", .{
                @tagName(token.type),
                token.value,
                token.line,
                token.column,
            });

            if (token.type == .Eof) break;
        }
    }

    print("\n", .{});
}
