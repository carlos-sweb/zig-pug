const std = @import("std");
const parser = @import("parser.zig");
const compiler = @import("compiler.zig");
const runtime = @import("runtime.zig");

const VERSION = "0.2.0";

const CliOptions = struct {
    input_files: std.ArrayList([]const u8),
    output_path: ?[]const u8,
    variables_file: ?[]const u8,
    variables: std.StringHashMap([]const u8),
    watch: bool,
    pretty: bool,
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
            .watch = false,
            .pretty = false,
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
    }
};

fn printVersion() void {
    std.debug.print("zig-pug v{s}\n", .{VERSION});
    std.debug.print("Pug template engine powered by Zig and mujs\n", .{});
}

fn printHelp() void {
    const help_text =
        \\zig-pug - High-performance Pug template compiler
        \\
        \\USAGE:
        \\  zig-pug [OPTIONS] <input-files...>
        \\  zig-pug [OPTIONS] -i <input> -o <output>
        \\  zig-pug [OPTIONS] < input.pug > output.html
        \\
        \\OPTIONS:
        \\  -h, --help              Show this help message
        \\  -v, --version           Show version information
        \\  -i, --input <file>      Input .pug file (can be used multiple times)
        \\  -o, --output <path>     Output file or directory
        \\  -w, --watch             Watch files for changes and recompile
        \\  -p, --pretty            Pretty-print HTML output (with indentation)
        \\  -m, --minify            Minify HTML output (remove whitespace)
        \\  --stdin                 Read input from stdin
        \\  --stdout                Write output to stdout
        \\  -s, --silent            Suppress all output except errors
        \\  -V, --verbose           Verbose output with compilation details
        \\  -f, --force             Overwrite output files without asking
        \\
        \\VARIABLES:
        \\  --var <key>=<value>     Set template variable (can be used multiple times)
        \\  --vars <file.json>      Load variables from JSON file
        \\
        \\EXAMPLES:
        \\  # Compile single file to stdout
        \\  zig-pug template.pug
        \\
        \\  # Compile with output file
        \\  zig-pug -i template.pug -o output.html
        \\
        \\  # Compile multiple files to directory
        \\  zig-pug -i *.pug -o dist/
        \\
        \\  # Compile with variables
        \\  zig-pug template.pug --var name=Alice --var age=25
        \\
        \\  # Compile with JSON variables
        \\  zig-pug template.pug --vars data.json -o output.html
        \\
        \\  # Pretty-print output
        \\  zig-pug -p template.pug -o pretty.html
        \\
        \\  # Minify output
        \\  zig-pug -m template.pug -o minified.html
        \\
        \\  # Watch for changes
        \\  zig-pug -w -i template.pug -o output.html
        \\
        \\  # Use stdin/stdout (Unix pipe)
        \\  cat template.pug | zig-pug --stdin --stdout > output.html
        \\
        \\  # Compile with verbose output
        \\  zig-pug -V template.pug -o output.html
        \\
        \\TEMPLATE VARIABLES:
        \\  Variables can be set via:
        \\  - Command line: --var key=value
        \\  - JSON file: --vars file.json
        \\  - Environment: ZIG_PUG_VARS (JSON string)
        \\
        \\  Variable types are auto-detected:
        \\  - Numbers: --var count=42
        \\  - Booleans: --var active=true
        \\  - Strings: --var name=Alice
        \\
        \\SUPPORTED PUG SYNTAX:
        \\  - Tags: div, p, span, etc.
        \\  - Classes: .classname
        \\  - IDs: #idname
        \\  - Attributes: (href="url" class="name")
        \\  - Interpolation: #{variable}
        \\  - JavaScript: #{name.toUpperCase()}
        \\  - Conditionals: if, else, unless
        \\  - Mixins: mixin name(args)
        \\
        \\EXIT CODES:
        \\  0  Success
        \\  1  Compilation error
        \\  2  File I/O error
        \\  3  Invalid arguments
        \\
        \\DOCUMENTATION:
        \\  https://github.com/yourusername/zig-pug
        \\
    ;
    std.debug.print("{s}", .{help_text});
}

fn parseArguments(allocator: std.mem.Allocator) !CliOptions {
    var options = CliOptions.init(allocator);

    var args = try std.process.argsWithAllocator(allocator);
    defer args.deinit();

    // Skip program name
    _ = args.skip();

    var i: usize = 0;
    while (args.next()) |arg| {
        i += 1;

        if (std.mem.eql(u8, arg, "-h") or std.mem.eql(u8, arg, "--help")) {
            printHelp();
            std.process.exit(0);
        } else if (std.mem.eql(u8, arg, "-v") or std.mem.eql(u8, arg, "--version")) {
            printVersion();
            std.process.exit(0);
        } else if (std.mem.eql(u8, arg, "-i") or std.mem.eql(u8, arg, "--input")) {
            const input_file = args.next() orelse {
                std.debug.print("Error: --input requires a file path\n", .{});
                std.process.exit(3);
            };
            try options.input_files.append(allocator, input_file);
        } else if (std.mem.eql(u8, arg, "-o") or std.mem.eql(u8, arg, "--output")) {
            options.output_path = args.next() orelse {
                std.debug.print("Error: --output requires a path\n", .{});
                std.process.exit(3);
            };
        } else if (std.mem.eql(u8, arg, "--var")) {
            const var_str = args.next() orelse {
                std.debug.print("Error: --var requires key=value\n", .{});
                std.process.exit(3);
            };

            var it = std.mem.splitScalar(u8, var_str, '=');
            const key = it.next() orelse {
                std.debug.print("Error: --var format is key=value\n", .{});
                std.process.exit(3);
            };
            const value = it.next() orelse {
                std.debug.print("Error: --var format is key=value\n", .{});
                std.process.exit(3);
            };

            try options.variables.put(key, value);
        } else if (std.mem.eql(u8, arg, "--vars")) {
            options.variables_file = args.next() orelse {
                std.debug.print("Error: --vars requires a JSON file path\n", .{});
                std.process.exit(3);
            };
        } else if (std.mem.eql(u8, arg, "-w") or std.mem.eql(u8, arg, "--watch")) {
            options.watch = true;
        } else if (std.mem.eql(u8, arg, "-p") or std.mem.eql(u8, arg, "--pretty")) {
            options.pretty = true;
        } else if (std.mem.eql(u8, arg, "-m") or std.mem.eql(u8, arg, "--minify")) {
            options.minify = true;
        } else if (std.mem.eql(u8, arg, "--stdin")) {
            options.stdin = true;
        } else if (std.mem.eql(u8, arg, "--stdout")) {
            options.stdout = true;
        } else if (std.mem.eql(u8, arg, "-s") or std.mem.eql(u8, arg, "--silent")) {
            options.silent = true;
        } else if (std.mem.eql(u8, arg, "-V") or std.mem.eql(u8, arg, "--verbose")) {
            options.verbose = true;
        } else if (std.mem.eql(u8, arg, "-f") or std.mem.eql(u8, arg, "--force")) {
            options.force = true;
        } else if (std.mem.startsWith(u8, arg, "-")) {
            std.debug.print("Error: Unknown option '{s}'\n", .{arg});
            std.debug.print("Use --help for usage information\n", .{});
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
        std.debug.print("Error parsing JSON file '{s}': {}\n", .{ filepath, err });
        return err;
    };
    defer parsed.deinit();

    const root = parsed.value;
    if (root != .object) {
        std.debug.print("Error: JSON root must be an object\n", .{});
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
            else => {
                std.debug.print("Warning: Unsupported type for variable '{s}', skipping\n", .{key});
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
        if (std.mem.eql(u8, value, "true")) {
            try js_runtime.setBool(key, true);
            continue;
        } else if (std.mem.eql(u8, value, "false")) {
            try js_runtime.setBool(key, false);
            continue;
        }

        // Default to string
        try js_runtime.setString(key, value);
    }
}

fn compileFile(
    allocator: std.mem.Allocator,
    input_path: []const u8,
    output_path: ?[]const u8,
    js_runtime: *runtime.JsRuntime,
    options: *const CliOptions,
) !void {
    if (options.verbose) {
        std.debug.print("Compiling: {s}\n", .{input_path});
    }

    // Read input file
    const file = std.fs.cwd().openFile(input_path, .{}) catch |err| {
        std.debug.print("Error: Cannot open file '{s}': {}\n", .{ input_path, err });
        std.process.exit(2);
    };
    defer file.close();

    const source = file.readToEndAlloc(allocator, 10 * 1024 * 1024) catch |err| {
        std.debug.print("Error: Cannot read file '{s}': {}\n", .{ input_path, err });
        std.process.exit(2);
    };
    defer allocator.free(source);

    if (options.verbose) {
        std.debug.print("Parsing template ({} bytes)\n", .{source.len});
    }

    // Parse
    var pars = parser.Parser.init(allocator, source) catch |err| {
        std.debug.print("Error: Parser initialization failed: {}\n", .{err});
        std.process.exit(1);
    };
    defer pars.deinit();

    const tree = pars.parse() catch |err| {
        std.debug.print("Error: Parsing failed: {}\n", .{err});
        std.process.exit(1);
    };

    if (options.verbose) {
        std.debug.print("Compiling to HTML\n", .{});
    }

    // Compile
    var comp = compiler.Compiler.init(allocator, js_runtime) catch |err| {
        std.debug.print("Error: Compiler initialization failed: {}\n", .{err});
        std.process.exit(1);
    };
    defer comp.deinit();

    const html = comp.compile(tree) catch |err| {
        std.debug.print("Error: Compilation failed: {}\n", .{err});
        std.process.exit(1);
    };
    defer allocator.free(html);

    // Apply formatting
    const final_html = if (options.minify)
        try minifyHtml(allocator, html)
    else if (options.pretty)
        try prettyPrintHtml(allocator, html)
    else
        html;

    defer if (options.minify or options.pretty) allocator.free(final_html);

    if (options.verbose) {
        std.debug.print("Output size: {} bytes\n", .{final_html.len});
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
                    std.debug.print("Warning: File '{s}' already exists, overwriting\n", .{out_path});
                }
            } else |_| {}
        }

        const out_file = std.fs.cwd().createFile(out_path, .{}) catch |err| {
            std.debug.print("Error: Cannot create file '{s}': {}\n", .{ out_path, err });
            std.process.exit(2);
        };
        defer out_file.close();

        try out_file.writeAll(final_html);

        if (!options.silent) {
            std.debug.print("✓ Compiled: {s} -> {s}\n", .{ input_path, out_path });
        }
    }
}

fn minifyHtml(allocator: std.mem.Allocator, html: []const u8) ![]const u8 {
    var result = std.ArrayList(u8){};
    var in_tag = false;
    var last_was_space = false;

    for (html) |c| {
        if (c == '<') {
            in_tag = true;
            try result.append(allocator, c);
            last_was_space = false;
        } else if (c == '>') {
            in_tag = false;
            try result.append(allocator, c);
            last_was_space = false;
        } else if (c == ' ' or c == '\n' or c == '\r' or c == '\t') {
            if (!in_tag and !last_was_space) {
                try result.append(allocator, ' ');
                last_was_space = true;
            } else if (in_tag and c == ' ') {
                try result.append(allocator, ' ');
            }
        } else {
            try result.append(allocator, c);
            last_was_space = false;
        }
    }

    return result.toOwnedSlice(allocator);
}

fn prettyPrintHtml(allocator: std.mem.Allocator, html: []const u8) ![]const u8 {
    var result = std.ArrayList(u8){};
    var indent: usize = 0;
    var i: usize = 0;

    while (i < html.len) {
        if (html[i] == '<') {
            // Check if closing tag
            const is_closing = i + 1 < html.len and html[i + 1] == '/';
            const is_self_closing = blk: {
                var j = i;
                while (j < html.len and html[j] != '>') : (j += 1) {}
                break :blk j > 0 and html[j - 1] == '/';
            };

            if (is_closing and indent > 0) {
                indent -= 1;
            }

            // Add indentation
            try result.append(allocator, '\n');
            var j: usize = 0;
            while (j < indent * 2) : (j += 1) {
                try result.append(allocator, ' ');
            }

            // Add tag
            while (i < html.len and html[i] != '>') : (i += 1) {
                try result.append(allocator, html[i]);
            }
            if (i < html.len) {
                try result.append(allocator, html[i]); // Add '>'
                i += 1;
            }

            if (!is_closing and !is_self_closing) {
                indent += 1;
            }
        } else {
            try result.append(allocator, html[i]);
            i += 1;
        }
    }

    try result.append(allocator, '\n');
    return result.toOwnedSlice(allocator);
}

fn compileFromStdin(allocator: std.mem.Allocator, js_runtime: *runtime.JsRuntime, options: *const CliOptions) !void {
    _ = options; // TODO: Use options for minify/pretty
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
    const html = try comp.compile(tree);
    defer allocator.free(html);

    // Output
    const stdout_file = std.fs.File.stdout();
    try stdout_file.writeAll(html);
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var options = try parseArguments(allocator);
    defer options.deinit();

    // Check for no input
    if (options.input_files.items.len == 0 and !options.stdin) {
        std.debug.print("Error: No input files specified\n", .{});
        std.debug.print("Use --help for usage information\n", .{});
        std.process.exit(3);
    }

    // Initialize JavaScript runtime
    var js_runtime = try runtime.JsRuntime.init(allocator);
    defer js_runtime.deinit();

    // Load variables from JSON file
    if (options.variables_file) |vars_file| {
        if (options.verbose) {
            std.debug.print("Loading variables from: {s}\n", .{vars_file});
        }
        try loadVariablesFromJson(allocator, vars_file, js_runtime);
    }

    // Set variables from command line
    if (options.variables.count() > 0) {
        if (options.verbose) {
            std.debug.print("Setting {} command line variables\n", .{options.variables.count()});
        }
        try setVariablesFromMap(options.variables, js_runtime);
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

            // Remove .pug extension if present
            if (std.mem.endsWith(u8, basename, ".pug")) {
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
            std.debug.print("\nWatching for file changes... (Ctrl+C to stop)\n", .{});
        }
        // TODO: Implement file watching
        std.debug.print("Watch mode not yet implemented\n", .{});
    }
}
