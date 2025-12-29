const std = @import("std");
const parser = @import("parser/mod.zig");
const compiler = @import("compiler/mod.zig");
const runtime = @import("runtime.zig");
const c_print = @import("c_print.zig");
const formatter = @import("formatter.zig");

const print = std.debug.print;
const eql = std.mem.eql;

const VERSION = "4.0.0";

// Helper functions for colored output
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
            .input_files = std.ArrayList([]const u8){},
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

fn parseArguments(allocator: std.mem.Allocator) !CliOptions {
    var options = CliOptions.init(allocator);
    var args = try std.process.argsWithAllocator(allocator);
    defer args.deinit();
    // Skip program name
    _ = args.skip();

    while (args.next()) |arg| {
        if (eql(u8, arg, "-h") or eql(u8, arg, "--help")) {
            print("{s}\n", .{@embedFile("help.txt")});
            std.process.exit(0);
        } else if (eql(u8, arg, "-v") or eql(u8, arg, "--version")) {
            print("{s}\n", .{VERSION});
            std.process.exit(0);
        } else if (eql(u8, arg, "-i") or eql(u8, arg, "--input")) {
            const input_file = args.next() orelse {
                printError("Error: --input requires a file path\n", .{});
                std.process.exit(3);
            };
            try options.input_files.append(allocator, input_file);
        } else if (eql(u8, arg, "-o") or eql(u8, arg, "--output")) {
            options.output_path = args.next() orelse {
                printError("Error: --output requires a path\n", .{});
                std.process.exit(3);
            };
        } else if (eql(u8, arg, "--var")) {
            const var_str = args.next() orelse {
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
            options.variables_file = args.next() orelse {
                printError("Error: --vars requires a JSON file path\n", .{});
                std.process.exit(3);
            };
        } else if (eql(u8, arg, "--array")) {
            const array_str = args.next() orelse {
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
            const json_str = args.next() orelse {
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
            // Positional argument - input file
            try options.input_files.append(allocator, arg);
        }
    }

    return options;
}

fn loadVariablesFromJson(allocator: std.mem.Allocator, filepath: []const u8, js_runtime: *runtime.JsRuntime) !void {
    const file = try std.fs.cwd().openFile(filepath, .{});
    defer file.close();

    const content = try file.readToEndAlloc(allocator, 1024 * 1024); // Max 1MB
    defer allocator.free(content);

    // Parse JSON and set variables
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
            else => {
                printWarning("Warning: Unsupported type for variable '{s}', skipping\n", .{key});
            },
        }
    }
}

fn setVariablesFromMap(variables: std.StringHashMap([]const u8), js_runtime: *runtime.JsRuntime) !void {
    var it = variables.iterator();
    while (it.next()) |entry| {
        const key = entry.key_ptr.*;
        const value = entry.value_ptr.*;

        // Try to parse as number
        if (std.fmt.parseFloat(f64, value)) |num| {
            try js_runtime.setNumber(key, num);
            continue;
        } else |_| {}

        // Try to parse as boolean
        if (eql(u8, value, "true")) {
            try js_runtime.setBool(key, true);
            continue;
        } else if (eql(u8, value, "false")) {
            try js_runtime.setBool(key, false);
            continue;
        }

        // Default to string
        try js_runtime.setString(key, value);
    }
}

fn setJsonVariable(
    allocator: std.mem.Allocator,
    key: []const u8,
    json_str: []const u8,
    js_runtime: *runtime.JsRuntime,
) !void {
    // Parse JSON
    const parsed = std.json.parseFromSlice(
        std.json.Value,
        allocator,
        json_str,
        .{},
    ) catch |err| {
        printError("Error: Invalid JSON for key '{s}': {}\n", .{ key, err });
        print("JSON string: {s}\n", .{json_str});
        return err;
    };
    defer parsed.deinit();

    const value = parsed.value;

    // Determine type and set
    switch (value) {
        .string => |str| try js_runtime.setString(key, str),
        .integer => |num| try js_runtime.setNumber(key, @floatFromInt(num)),
        .float => |num| try js_runtime.setNumber(key, num),
        .number_string => |str| {
            // Try to parse as number
            if (std.fmt.parseFloat(f64, str)) |num| {
                try js_runtime.setNumber(key, num);
            } else |_| {
                try js_runtime.setString(key, str);
            }
        },
        .bool => |b| try js_runtime.setBool(key, b),
        .array => |arr| try js_runtime.setArrayFromJson(key, arr.items),
        .object => |obj| try js_runtime.setObjectFromJson(key, obj),
        .null => {
            // Set null as string "null"
            try js_runtime.setString(key, "null");
        },
    }
}

fn setArrayFromCsv(
    allocator: std.mem.Allocator,
    key: []const u8,
    csv_str: []const u8,
    js_runtime: *runtime.JsRuntime,
) !void {
    var items = std.ArrayList(std.json.Value){};
    defer {
        // Free allocated strings
        for (items.items) |item| {
            if (item == .string) {
                allocator.free(item.string);
            }
        }
        items.deinit(allocator);
    }

    // Split by commas
    var it = std.mem.splitScalar(u8, csv_str, ',');
    while (it.next()) |item_str| {
        const trimmed = std.mem.trim(u8, item_str, " \t\r\n");

        if (trimmed.len == 0) continue;

        // Try to parse as number
        if (std.fmt.parseFloat(f64, trimmed)) |num| {
            try items.append(allocator, .{ .float = num });
        } else |_| {
            // It's a string - need to duplicate it
            const str_copy = try allocator.dupe(u8, trimmed);
            try items.append(allocator, .{ .string = str_copy });
        }
    }

    // Convert to slice and set
    try js_runtime.setArrayFromJson(key, items.items);
}

fn compileFile(
    allocator: std.mem.Allocator,
    input_path: []const u8,
    output_path: ?[]const u8,
    js_runtime: *runtime.JsRuntime,
    options: *const CliOptions,
) !void {
    if (options.verbose) {
        printInfo("Compiling: {s}\n", .{input_path});
    }

    // Read input file
    const file = std.fs.cwd().openFile(input_path, .{}) catch |err| {
        printError("Error: Cannot open file '{s}': {}\n", .{ input_path, err });
        std.process.exit(2);
    };
    defer file.close();

    const source = file.readToEndAlloc(allocator, 10 * 1024 * 1024) catch |err| {
        printError("Error: Cannot read file '{s}': {}\n", .{ input_path, err });
        std.process.exit(2);
    };
    defer allocator.free(source);

    if (options.verbose) {
        printInfo("Parsing template ({} bytes)\n", .{source.len});
    }

    // Parse
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

    if (options.verbose) {
        print("Compiling to HTML\n", .{});
    }

    // Compile
    var comp = compiler.Compiler.init(allocator, js_runtime) catch |err| {
        printError("Error: Compiler initialization failed: {}\n", .{err});
        std.process.exit(1);
    };
    defer comp.deinit();

    // Set base path for resolving relative includes and extends
    comp.setBasePath(input_path);

    // Include comments only in pretty mode (development)
    // Production (default/minify): strip comments for smaller output
    comp.include_comments = options.pretty;

    const html = comp.compile(tree) catch |err| {
        if (err == error.CompilationFailed) {
            // Display all accumulated errors with colors
            printError("\nCompilation failed with {} error(s):\n\n", .{comp.errors.items.len});
            for (comp.errors.items) |compilation_err| {
                // Error message in red
                printError("Line {d}: {s}\n", .{ compilation_err.line, compilation_err.message });

                // Detail in cyan if present
                if (compilation_err.detail) |detail| {
                    printInfo("  {s}\n", .{detail});
                }

                // Hint in yellow if present
                if (compilation_err.hint) |hint| {
                    printWarning("  Hint: {s}\n", .{hint});
                }

                printError("\n", .{});
            }
        } else {
            printError("Error: Compilation failed: {}\n", .{err});
        }
        std.process.exit(1);
    };
    defer allocator.free(html);

    // Check for compilation errors (strict mode)
    if (comp.has_errors) {
        printError("\nCompilation failed due to errors. No output generated.\n", .{});
        std.process.exit(1);
    }

    // Apply formatting
    const final_html = if (options.minify)
        try formatter.minifyHtml(allocator, html)
    else if (options.pretty or options.format)
        try formatter.prettyPrintHtml(allocator, html)
    else
        html;

    defer if (options.minify or options.pretty or options.format) allocator.free(final_html);

    if (options.verbose) {
        print("Output size: {} bytes\n", .{final_html.len});
    }

    // Write output
    if (options.stdout or output_path == null) {
        const stdout_file = std.fs.File.stdout();
        try stdout_file.writeAll(final_html);
    } else {
        const out_path = output_path.?;

        // Check if file exists
        if (!options.force) {
            if (std.fs.cwd().access(out_path, .{})) {
                if (!options.silent) {
                    printWarning("Warning: File '{s}' already exists, overwriting\n", .{out_path});
                }
            } else |_| {}
        }

        const out_file = std.fs.cwd().createFile(out_path, .{}) catch |err| {
            printError("Error: Cannot create file '{s}': {}\n", .{ out_path, err });
            std.process.exit(2);
        };
        defer out_file.close();

        try out_file.writeAll(final_html);

        if (!options.silent) {
            printSuccess("✓ Compiled: {s} -> {s}\n", .{ input_path, out_path });
        }
    }
}

// Formatting functions (minifyHtml, prettyPrintHtml, isVoidElement)
// are now imported from the shared formatter.zig module

fn compileFromStdin(allocator: std.mem.Allocator, js_runtime: *runtime.JsRuntime, options: *const CliOptions) !void {
    const stdin_file = std.fs.File.stdin();

    const source = try stdin_file.readToEndAlloc(allocator, 10 * 1024 * 1024);
    defer allocator.free(source);

    // Parse
    var pars = try parser.Parser.init(allocator, source);
    defer pars.deinit();
    const tree = try pars.parse();

    // Compile
    var comp = try compiler.Compiler.init(allocator, js_runtime);
    defer comp.deinit();

    // Include comments only in pretty mode (development)
    comp.include_comments = options.pretty;

    const html = comp.compile(tree) catch |err| {
        if (err == error.CompilationFailed) {
            // Display all accumulated errors with colors
            printError("\nCompilation failed with {} error(s):\n\n", .{comp.errors.items.len});
            for (comp.errors.items) |compilation_err| {
                // Error message in red
                printError("Line {d}: {s}\n", .{ compilation_err.line, compilation_err.message });

                // Detail in cyan if present
                if (compilation_err.detail) |detail| {
                    printInfo("  {s}\n", .{detail});
                }

                // Hint in yellow if present
                if (compilation_err.hint) |hint| {
                    printWarning("  Hint: {s}\n", .{hint});
                }

                printError("\n", .{});
            }
        } else {
            printError("Error: Compilation failed: {}\n", .{err});
        }
        std.process.exit(1);
    };
    defer allocator.free(html);

    // Check for compilation errors (strict mode)
    if (comp.has_errors) {
        printError("\nCompilation failed due to errors. No output generated.\n", .{});
        std.process.exit(1);
    }

    // Apply formatting
    const final_html = if (options.minify)
        try formatter.minifyHtml(allocator, html)
    else if (options.pretty or options.format)
        try formatter.prettyPrintHtml(allocator, html)
    else
        html;

    defer if (options.minify or options.pretty or options.format) allocator.free(final_html);

    // Output
    const stdout_file = std.fs.File.stdout();
    try stdout_file.writeAll(final_html);
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var options = try parseArguments(allocator);
    defer options.deinit();

    // Check for no input
    if (options.input_files.items.len == 0 and !options.stdin) {
        printError("Error: No input files specified\n", .{});
        print("Use --help for usage information\n", .{});
        std.process.exit(3);
    }

    // Initialize JavaScript runtime
    var js_runtime = try runtime.JsRuntime.init(allocator);
    defer js_runtime.deinit();

    // Load variables from JSON file
    if (options.variables_file) |vars_file| {
        if (options.verbose) {
            print("Loading variables from: {s}\n", .{vars_file});
        }
        try loadVariablesFromJson(allocator, vars_file, js_runtime);
    }

    // Set variables from command line
    if (options.variables.count() > 0) {
        if (options.verbose) {
            print("Setting {} command line variables\n", .{options.variables.count()});
        }
        try setVariablesFromMap(options.variables, js_runtime);
    }

    // Set array variables (--array)
    if (options.array_variables.count() > 0) {
        if (options.verbose) {
            print("Setting {} array variables from --array flags\n", .{options.array_variables.count()});
        }
        var array_it = options.array_variables.iterator();
        while (array_it.next()) |entry| {
            setArrayFromCsv(
                allocator,
                entry.key_ptr.*,
                entry.value_ptr.*,
                js_runtime,
            ) catch |err| {
                print("Error setting array '{s}': {}\n", .{ entry.key_ptr.*, err });
                std.process.exit(1);
            };
        }
    }

    // Set JSON variables (--json)
    if (options.json_variables.count() > 0) {
        if (options.verbose) {
            print("Setting {} JSON variables from --json flags\n", .{options.json_variables.count()});
        }
        var json_it = options.json_variables.iterator();
        while (json_it.next()) |entry| {
            setJsonVariable(
                allocator,
                entry.key_ptr.*,
                entry.value_ptr.*,
                js_runtime,
            ) catch |err| {
                print("Error setting JSON '{s}': {}\n", .{ entry.key_ptr.*, err });
                std.process.exit(1);
            };
        }
    }

    // Handle stdin input
    if (options.stdin) {
        try compileFromStdin(allocator, js_runtime, &options);
        return;
    }

    // Determine output path for single file
    if (options.input_files.items.len == 1 and options.output_path != null) {
        const input_file = options.input_files.items[0];
        const output_file = options.output_path.?;
        try compileFile(allocator, input_file, output_file, js_runtime, &options);
        return;
    }

    // Multiple files - output to directory or stdout
    for (options.input_files.items) |input_file| {
        const output_file = if (options.output_path) |out_dir| blk: {
            // Extract filename and change extension to .html
            var basename = std.fs.path.basename(input_file);

            // Remove .zpug or .pug extension if present
            if (std.mem.endsWith(u8, basename, ".zpug")) {
                basename = basename[0 .. basename.len - 5];
            } else if (std.mem.endsWith(u8, basename, ".pug")) {
                basename = basename[0 .. basename.len - 4];
            }

            const html_name = try std.fmt.allocPrint(allocator, "{s}/{s}.html", .{ out_dir, basename });
            break :blk html_name;
        } else null;

        defer if (output_file) |of| allocator.free(of);

        try compileFile(allocator, input_file, output_file, js_runtime, &options);
    }

    if (options.watch) {
        if (!options.silent) {
            print("\nWatching for file changes... (Ctrl+C to stop)\n", .{});
        }
        // TODO: Implement file watching
        print("Watch mode not yet implemented\n", .{});
    }
}
