const std = @import("std");
const parser = @import("parser/mod.zig");
const compiler = @import("compiler/mod.zig");
const runtime = @import("runtime.zig");
const c_print = @import("c_print.zig");
const formatter = @import("formatter.zig");

const print = std.debug.print;
const eql = std.mem.eql;

// 0.16: alias conveniente
const Dir = std.Io.Dir;
const File = std.Io.File;

const VERSION = "4.0.0";

// ---------------------------------------------------------------------------
// Colored output helpers
// ---------------------------------------------------------------------------

fn printError(comptime fmt: []const u8, args: anytype) void {
    const msg = std.fmt.allocPrint(std.heap.c_allocator, fmt, args) catch return;
    defer std.heap.c_allocator.free(msg);
    const c_msg = std.heap.c_allocator.dupeZ(u8, msg) catch return;
    defer std.heap.c_allocator.free(c_msg);
    c_print.c.c_print_color(c_msg.ptr, 31); // COLOR_RED
}

fn printWarning(comptime fmt: []const u8, args: anytype) void {
    const msg = std.fmt.allocPrint(std.heap.c_allocator, fmt, args) catch return;
    defer std.heap.c_allocator.free(msg);
    const c_msg = std.heap.c_allocator.dupeZ(u8, msg) catch return;
    defer std.heap.c_allocator.free(c_msg);
    c_print.c.c_print_color(c_msg.ptr, 33); // COLOR_YELLOW
}

fn printSuccess(comptime fmt: []const u8, args: anytype) void {
    const msg = std.fmt.allocPrint(std.heap.c_allocator, fmt, args) catch return;
    defer std.heap.c_allocator.free(msg);
    const c_msg = std.heap.c_allocator.dupeZ(u8, msg) catch return;
    defer std.heap.c_allocator.free(c_msg);
    c_print.c.c_print_color(c_msg.ptr, 32); // COLOR_GREEN
}

fn printInfo(comptime fmt: []const u8, args: anytype) void {
    const msg = std.fmt.allocPrint(std.heap.c_allocator, fmt, args) catch return;
    defer std.heap.c_allocator.free(msg);
    const c_msg = std.heap.c_allocator.dupeZ(u8, msg) catch return;
    defer std.heap.c_allocator.free(c_msg);
    c_print.c.c_print_color(c_msg.ptr, 36); // COLOR_CYAN
}

// ---------------------------------------------------------------------------
// CliOptions
// ---------------------------------------------------------------------------

const CliOptions = struct {
    input_files: std.ArrayList([]const u8),
    output_path: ?[]const u8,
    variables_file: ?[]const u8,
    variables: std.StringHashMap([]const u8),
    json_variables: std.StringHashMap([]const u8),
    array_variables: std.StringHashMap([]const u8),
    watch: bool,
    pretty: bool,
    format: bool,
    minify: bool,
    verbose: bool,
    silent: bool,
    stdin: bool,
    stdout: bool,
    force: bool,
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator) CliOptions {
        return .{
            .input_files = .empty,
            .output_path = null,
            .variables_file = null,
            .variables = std.StringHashMap([]const u8).init(allocator),
            .json_variables = std.StringHashMap([]const u8).init(allocator),
            .array_variables = std.StringHashMap([]const u8).init(allocator),
            .watch = false,
            .pretty = false,
            .format = false,
            .minify = false,
            .verbose = false,
            .silent = false,
            .stdin = false,
            .stdout = false,
            .force = false,
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *CliOptions) void {
        self.input_files.deinit(self.allocator);
        self.variables.deinit();
        self.json_variables.deinit();
        self.array_variables.deinit();
    }
};

// ---------------------------------------------------------------------------
// Argument parsing
// 0.16: recibimos Init.Minimal para acceder a los args del proceso
// ---------------------------------------------------------------------------

fn parseArguments(
    allocator: std.mem.Allocator,
    minimal: std.process.Init.Minimal,
) !CliOptions {
    var options = CliOptions.init(allocator);

    var args_iter = try minimal.args.iterateAllocator(allocator);
    defer args_iter.deinit();

    _ = args_iter.next(); // skip program name

    while (args_iter.next()) |arg| {
        if (eql(u8, arg, "-h") or eql(u8, arg, "--help")) {
            print("{s}\n", .{@embedFile("help.txt")});
            std.process.exit(0);
        } else if (eql(u8, arg, "-v") or eql(u8, arg, "--version")) {
            print("{s}\n", .{VERSION});
            std.process.exit(0);
        } else if (eql(u8, arg, "-i") or eql(u8, arg, "--input")) {
            const input_file = args_iter.next() orelse {
                printError("Error: --input requires a file path\n", .{});
                std.process.exit(3);
            };
            try options.input_files.append(allocator, input_file);
        } else if (eql(u8, arg, "-o") or eql(u8, arg, "--output")) {
            options.output_path = args_iter.next() orelse {
                printError("Error: --output requires a path\n", .{});
                std.process.exit(3);
            };
        } else if (eql(u8, arg, "--var")) {
            const var_str = args_iter.next() orelse {
                printError("Error: --var requires key=value\n", .{});
                std.process.exit(3);
            };
            var it = std.mem.splitScalar(u8, var_str, '=');
            const key = it.next() orelse {
                printError("Error: --var format is key=value\n", .{});
                std.process.exit(3);
            };
            const value = it.next() orelse {
                printError("Error: --var format is key=value\n", .{});
                std.process.exit(3);
            };
            try options.variables.put(key, value);
        } else if (eql(u8, arg, "--vars")) {
            options.variables_file = args_iter.next() orelse {
                printError("Error: --vars requires a JSON file path\n", .{});
                std.process.exit(3);
            };
        } else if (eql(u8, arg, "--array")) {
            const array_str = args_iter.next() orelse {
                printError("Error: --array requires key=val1,val2,...\n", .{});
                std.process.exit(3);
            };
            var it = std.mem.splitScalar(u8, array_str, '=');
            const key = it.next() orelse {
                printError("Error: --array format is key=val1,val2,...\n", .{});
                std.process.exit(3);
            };
            const csv_values = it.rest();
            if (csv_values.len == 0) {
                printError("Error: --array requires comma-separated values\n", .{});
                std.process.exit(3);
            }
            try options.array_variables.put(key, csv_values);
        } else if (eql(u8, arg, "--json")) {
            const json_str = args_iter.next() orelse {
                printError("Error: --json requires key=json_value\n", .{});
                std.process.exit(3);
            };
            var it = std.mem.splitScalar(u8, json_str, '=');
            const key = it.next() orelse {
                printError("Error: --json format is key=json_value\n", .{});
                std.process.exit(3);
            };
            const json_value = it.rest();
            if (json_value.len == 0) {
                printError("Error: --json requires a JSON value\n", .{});
                std.process.exit(3);
            }
            try options.json_variables.put(key, json_value);
        } else if (eql(u8, arg, "-w") or eql(u8, arg, "--watch")) {
            options.watch = true;
        } else if (eql(u8, arg, "-p") or eql(u8, arg, "--pretty")) {
            options.pretty = true;
        } else if (eql(u8, arg, "-F") or eql(u8, arg, "--format")) {
            options.format = true;
        } else if (eql(u8, arg, "-m") or eql(u8, arg, "--minify")) {
            options.minify = true;
        } else if (eql(u8, arg, "--stdin")) {
            options.stdin = true;
        } else if (eql(u8, arg, "--stdout")) {
            options.stdout = true;
        } else if (eql(u8, arg, "-s") or eql(u8, arg, "--silent")) {
            options.silent = true;
        } else if (eql(u8, arg, "-V") or eql(u8, arg, "--verbose")) {
            options.verbose = true;
        } else if (eql(u8, arg, "-f") or eql(u8, arg, "--force")) {
            options.force = true;
        } else if (std.mem.startsWith(u8, arg, "-")) {
            printError("Error: Unknown option '{s}'\n", .{arg});
            print("Use --help for usage information\n", .{});
            std.process.exit(3);
        } else {
            try options.input_files.append(allocator, arg);
        }
    }

    return options;
}

// ---------------------------------------------------------------------------
// Variable loaders
// 0.16: openFile/readToEndAlloc ahora requieren `io` como primer argumento
// ---------------------------------------------------------------------------

fn loadVariablesFromJson(
    io: std.Io,
    allocator: std.mem.Allocator,
    filepath: []const u8,
    js_runtime: *runtime.JsRuntime,
) !void {
    // 0.16: std.fs.cwd() → Dir.cwd()

    // Agregar problemas con el filepath , por ejemplo que no exista
    const content = try std.Io.Dir.cwd().readFileAlloc(io, filepath, allocator, .limited(10 * 1024 * 1024));

    const parsed = std.json.parseFromSlice(std.json.Value, allocator, content, .{}) catch |err| {
        print("Error parsing JSON file '{s}': {}\n", .{ filepath, err });
        return err;
    };
    defer parsed.deinit();

    const root = parsed.value;
    if (root != .object) {
        printError("Error: JSON root must be an object\n", .{});
        return error.InvalidJson;
    }

    var it = root.object.iterator();
    while (it.next()) |entry| {
        const key = entry.key_ptr.*;
        const value = entry.value_ptr.*;
        switch (value) {
            .string => |str| try js_runtime.setString(key, str),
            .integer => |num| try js_runtime.setNumber(key, @floatFromInt(num)),
            .float => |num| try js_runtime.setNumber(key, num),
            .bool => |b| try js_runtime.setBool(key, b),
            .array => |arr| try js_runtime.setArrayFromJson(key, arr.items),
            .object => |obj| try js_runtime.setObjectFromJson(key, obj),
            else => printWarning("Warning: Unsupported type for variable '{s}', skipping\n", .{key}),
        }
    }
}

fn setVariablesFromMap(
    variables: std.StringHashMap([]const u8),
    js_runtime: *runtime.JsRuntime,
) !void {
    var it = variables.iterator();
    while (it.next()) |entry| {
        const key = entry.key_ptr.*;
        const value = entry.value_ptr.*;

        if (std.fmt.parseFloat(f64, value)) |num| {
            try js_runtime.setNumber(key, num);
            continue;
        } else |_| {}

        if (eql(u8, value, "true")) {
            try js_runtime.setBool(key, true);
            continue;
        } else if (eql(u8, value, "false")) {
            try js_runtime.setBool(key, false);
            continue;
        }

        try js_runtime.setString(key, value);
    }
}

fn setJsonVariable(
    allocator: std.mem.Allocator,
    key: []const u8,
    json_str: []const u8,
    js_runtime: *runtime.JsRuntime,
) !void {
    const parsed = std.json.parseFromSlice(std.json.Value, allocator, json_str, .{}) catch |err| {
        printError("Error: Invalid JSON for key '{s}': {}\n", .{ key, err });
        print("JSON string: {s}\n", .{json_str});
        return err;
    };
    defer parsed.deinit();

    switch (parsed.value) {
        .string => |str| try js_runtime.setString(key, str),
        .integer => |num| try js_runtime.setNumber(key, @floatFromInt(num)),
        .float => |num| try js_runtime.setNumber(key, num),
        .number_string => |str| {
            if (std.fmt.parseFloat(f64, str)) |num| {
                try js_runtime.setNumber(key, num);
            } else |_| {
                try js_runtime.setString(key, str);
            }
        },
        .bool => |b| try js_runtime.setBool(key, b),
        .array => |arr| try js_runtime.setArrayFromJson(key, arr.items),
        .object => |obj| try js_runtime.setObjectFromJson(key, obj),
        .null => try js_runtime.setString(key, "null"),
    }
}

fn setArrayFromCsv(
    allocator: std.mem.Allocator,
    key: []const u8,
    csv_str: []const u8,
    js_runtime: *runtime.JsRuntime,
) !void {
    var items: std.ArrayList(std.json.Value) = .empty;
    defer {
        for (items.items) |item| {
            if (item == .string) allocator.free(item.string);
        }
        items.deinit(allocator);
    }

    var it = std.mem.splitScalar(u8, csv_str, ',');
    while (it.next()) |item_str| {
        const trimmed = std.mem.trim(u8, item_str, " \t\r\n");
        if (trimmed.len == 0) continue;

        if (std.fmt.parseFloat(f64, trimmed)) |num| {
            try items.append(allocator, .{ .float = num });
        } else |_| {
            const str_copy = try allocator.dupe(u8, trimmed);
            try items.append(allocator, .{ .string = str_copy });
        }
    }

    try js_runtime.setArrayFromJson(key, items.items);
}

// ---------------------------------------------------------------------------
// Compile helpers
// 0.16: todas las operaciones de fs reciben `io` como primer argumento
// ---------------------------------------------------------------------------

fn compileFile(
    io: std.Io,
    allocator: std.mem.Allocator,
    input_path: []const u8,
    output_path: ?[]const u8,
    js_runtime: *runtime.JsRuntime,
    options: *const CliOptions,
) !void {
    if (options.verbose) printInfo("Compiling: {s}\n", .{input_path});

    const source = Dir.cwd().readFileAlloc(
        io,
        input_path,
        allocator,
        .limited(10 * 1024 * 1024),
    ) catch |err| {
        printError("Error: Cannot read file '{s}': {}\n", .{ input_path, err });
        std.process.exit(2);
    };
    defer allocator.free(source);

    if (options.verbose) printInfo("Parsing template ({} bytes)\n", .{source.len});

    var pars = parser.Parser.init(allocator, source) catch |err| {
        printError("Error: Parser initialization failed: {}\n", .{err});
        std.process.exit(1);
    };
    defer pars.deinit();

    const tree = pars.parse() catch |err| {
        if (err == error.InvalidIndentation) {
            const line = pars.tokenizer.line;
            printError("Error: Invalid indentation at line {d}\n", .{line});
            print("\n", .{});
            print("Indentation errors can be caused by:\n", .{});
            print("  1. Using TABS instead of SPACES (only spaces are allowed)\n", .{});
            print("  2. Inconsistent dedentation (dedent must match a previous indent level)\n", .{});
            print("\n", .{});
            print("Example of CORRECT indentation:\n", .{});
            print("  div\n", .{});
            print("    p Text      // 2 spaces\n", .{});
            print("      span      // 4 spaces (consistent)\n", .{});
            print("    p More      // back to 2 spaces (matches previous level)\n", .{});
            print("\n", .{});
            print("Example of INCORRECT indentation:\n", .{});
            print("  div\n", .{});
            print("    p Text      // 2 spaces\n", .{});
            print("   span         // 3 spaces (ERROR: doesn't match any level)\n", .{});
        } else {
            printError("Error: Parsing failed: {}\n", .{err});
        }
        std.process.exit(1);
    };

    if (options.verbose) print("Compiling to HTML\n", .{});

    var comp = compiler.Compiler.init(io, allocator, js_runtime) catch |err| {
        printError("Error: Compiler initialization failed: {}\n", .{err});
        std.process.exit(1);
    };
    defer comp.deinit();

    comp.setBasePath(input_path);

    const html = comp.compile(tree) catch |err| {
        if (err == error.CompilationFailed) {
            printError("\nCompilation failed with {} error(s):\n\n", .{comp.errors.items.len});
            for (comp.errors.items) |ce| {
                printError("Line {d}: {s}\n", .{ ce.line, ce.message });
                if (ce.detail) |d| printInfo("  {s}\n", .{d});
                if (ce.hint) |h| printWarning("  Hint: {s}\n", .{h});
                printError("\n", .{});
            }
        } else {
            printError("Error: Compilation failed: {}\n", .{err});
        }
        std.process.exit(1);
    };
    defer allocator.free(html);

    if (comp.has_errors) {
        printError("\nCompilation failed due to errors. No output generated.\n", .{});
        std.process.exit(1);
    }

    const final_html = if (options.minify)
        try formatter.minifyHtml(allocator, html)
    else if (options.pretty or options.format)
        try formatter.prettyPrintHtml(allocator, html)
    else
        html;
    defer if (options.minify or options.pretty or options.format) allocator.free(final_html);

    if (options.verbose) print("Output size: {} bytes\n", .{final_html.len});

    if (options.stdout or output_path == null) {
        // 0.16: File.stdout().writeAll(io, data)
        //try File.stdout().writeAll(io, final_html);
        try File.stdout().writeStreamingAll(io, final_html);
    } else {
        const out_path = output_path.?;

        if (!options.force) {
            // 0.16: Dir.cwd().access(io, path, opts)
            if (Dir.cwd().access(io, out_path, .{})) {
                if (!options.silent)
                    printWarning("Warning: File '{s}' already exists, overwriting\n", .{out_path});
            } else |_| {}
        }

        // 0.16: Dir.cwd().createFile(io, path, opts)
        const out_file = Dir.cwd().createFile(io, out_path, .{}) catch |err| {
            printError("Error: Cannot create file '{s}': {}\n", .{ out_path, err });
            std.process.exit(2);
        };
        defer out_file.close(io);

        // 0.16: file.writeAll(io, data)
        //try out_file.writeAll(io, final_html);
        try out_file.writeStreamingAll(io, final_html);

        if (!options.silent)
            printSuccess("✓ Compiled: {s} -> {s}\n", .{ input_path, out_path });
    }
}

fn compileFromStdin(
    io: std.Io,
    allocator: std.mem.Allocator,
    js_runtime: *runtime.JsRuntime,
    options: *const CliOptions,
) !void {

    // 0.16: File.stdin().readToEndAlloc(io, allocator, max)
    var read_buf: [4096]u8 = undefined;
    var reader = File.stdin().reader(io, &read_buf);
    const source = try reader.interface.readAlloc(allocator, 10 * 1024 * 1024);
    defer allocator.free(source);

    var pars = try parser.Parser.init(allocator, source);
    defer pars.deinit();
    const tree = try pars.parse();

    var comp = try compiler.Compiler.init(io, allocator, js_runtime);
    defer comp.deinit();

    const html = comp.compile(tree) catch |err| {
        if (err == error.CompilationFailed) {
            printError("\nCompilation failed with {} error(s):\n\n", .{comp.errors.items.len});
            for (comp.errors.items) |ce| {
                printError("Line {d}: {s}\n", .{ ce.line, ce.message });
                if (ce.detail) |d| printInfo("  {s}\n", .{d});
                if (ce.hint) |h| printWarning("  Hint: {s}\n", .{h});
                printError("\n", .{});
            }
        } else {
            printError("Error: Compilation failed: {}\n", .{err});
        }
        std.process.exit(1);
    };
    defer allocator.free(html);

    if (comp.has_errors) {
        printError("\nCompilation failed due to errors. No output generated.\n", .{});
        std.process.exit(1);
    }

    const final_html = if (options.minify)
        try formatter.minifyHtml(allocator, html)
    else if (options.pretty or options.format)
        try formatter.prettyPrintHtml(allocator, html)
    else
        html;
    defer if (options.minify or options.pretty or options.format) allocator.free(final_html);

    //try File.stdout().writeAll(io, final_html);
    try File.stdout().writeStreamingAll(io, final_html);
}

// ---------------------------------------------------------------------------
// Entry point
//
// 0.16: main recibe std.process.Init
//   - init.gpa     → allocator con leak checking en debug
//   - init.io      → interfaz I/O (necesaria para todas las ops de archivo)
//   - init.minimal → acceso raw a args y environ
// ---------------------------------------------------------------------------

pub fn main(init: std.process.Init) !void {
    const allocator = init.gpa;
    const io = init.io;

    var options = try parseArguments(allocator, init.minimal);
    defer options.deinit();

    if (options.input_files.items.len == 0 and !options.stdin) {
        printError("Error: No input files specified\n", .{});
        print("Use --help for usage information\n", .{});
        std.process.exit(3);
    }

    var js_runtime = try runtime.JsRuntime.init(allocator);
    defer js_runtime.deinit();

    if (options.variables_file) |vars_file| {
        if (options.verbose) print("Loading variables from: {s}\n", .{vars_file});
        try loadVariablesFromJson(io, allocator, vars_file, js_runtime);
    }

    if (options.variables.count() > 0) {
        if (options.verbose)
            print("Setting {} command line variables\n", .{options.variables.count()});
        try setVariablesFromMap(options.variables, js_runtime);
    }

    if (options.array_variables.count() > 0) {
        if (options.verbose)
            print("Setting {} array variables from --array flags\n", .{options.array_variables.count()});
        var array_it = options.array_variables.iterator();
        while (array_it.next()) |entry| {
            setArrayFromCsv(allocator, entry.key_ptr.*, entry.value_ptr.*, js_runtime) catch |err| {
                print("Error setting array '{s}': {}\n", .{ entry.key_ptr.*, err });
                std.process.exit(1);
            };
        }
    }

    if (options.json_variables.count() > 0) {
        if (options.verbose)
            print("Setting {} JSON variables from --json flags\n", .{options.json_variables.count()});
        var json_it = options.json_variables.iterator();
        while (json_it.next()) |entry| {
            setJsonVariable(allocator, entry.key_ptr.*, entry.value_ptr.*, js_runtime) catch |err| {
                print("Error setting JSON '{s}': {}\n", .{ entry.key_ptr.*, err });
                std.process.exit(1);
            };
        }
    }

    if (options.stdin) {
        try compileFromStdin(io, allocator, js_runtime, &options);
        return;
    }

    if (options.input_files.items.len == 1 and options.output_path != null) {
        try compileFile(io, allocator, options.input_files.items[0], options.output_path.?, js_runtime, &options);
        return;
    }

    for (options.input_files.items) |input_file| {
        const output_file: ?[]const u8 = if (options.output_path) |out_dir| blk: {
            var basename = std.fs.path.basename(input_file);
            if (std.mem.endsWith(u8, basename, ".zpug")) {
                basename = basename[0 .. basename.len - 5];
            } else if (std.mem.endsWith(u8, basename, ".pug")) {
                basename = basename[0 .. basename.len - 4];
            }
            break :blk try std.fmt.allocPrint(allocator, "{s}/{s}.html", .{ out_dir, basename });
        } else null;

        defer if (output_file) |of| allocator.free(of);

        try compileFile(io, allocator, input_file, output_file, js_runtime, &options);
    }

    if (options.watch) {
        if (!options.silent)
            print("\nWatching for file changes... (Ctrl+C to stop)\n", .{});
        print("Watch mode not yet implemented\n", .{});
    }
}
