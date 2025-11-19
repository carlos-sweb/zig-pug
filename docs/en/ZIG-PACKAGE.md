# Using zig-pug as a Zig Dependency

zig-pug is configured to work with the Zig Package Manager.

## Requirements

- **Zig 0.13.0** or higher (recommended: 0.15.2)

## Installation

### Method 1: From URL (Recommended)

Add zig-pug to your `build.zig.zon`:

```zig
.{
    .name = .my_project,
    .version = "0.1.0",
    .fingerprint = 0x...,  // Your fingerprint
    .dependencies = .{
        .zig_pug = .{
            .url = "https://github.com/yourusername/zig-pug/archive/refs/tags/v0.2.0.tar.gz",
            .hash = "...",  // Obtained when running `zig build`
        },
    },
    .paths = .{
        "build.zig",
        "build.zig.zon",
        "src",
    },
}
```

### Method 2: From Local Path

For local development:

```zig
.dependencies = .{
    .zig_pug = .{
        .path = "../zig-pug",
    },
},
```

## Configure build.zig

In your `build.zig`, import the module:

```zig
const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Get the zig-pug module
    const zig_pug_dep = b.dependency("zig_pug", .{
        .target = target,
        .optimize = optimize,
    });
    const zig_pug_module = zig_pug_dep.module("zig_pug");

    // Create your executable
    const exe = b.addExecutable(.{
        .name = "my_app",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });

    // Add zig-pug as a dependency
    exe.root_module.addImport("zig_pug", zig_pug_module);

    // You also need to link with mujs
    exe.addObjectFile(zig_pug_dep.path("vendor/mujs/libmujs.a"));
    exe.addIncludePath(zig_pug_dep.path("vendor/mujs"));

    b.installArtifact(exe);
}
```

## Usage in Your Code

Once configured, you can import and use zig-pug:

```zig
const std = @import("std");
const zig_pug = @import("zig_pug");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Create runtime
    var runtime = try zig_pug.Runtime.init(allocator);
    defer runtime.deinit();

    // Set variables
    try runtime.setString("name", "Alice");
    try runtime.setNumber("age", 25);
    try runtime.setBool("isActive", true);

    // Compile template
    const template =
        \\div.greeting
        \\  h1 Hello #{name}!
        \\  p Age: #{age}
        \\  if isActive
        \\    p Status: Active
    ;

    // Tokenize
    var tokenizer = zig_pug.Tokenizer.init(template);
    const tokens = try tokenizer.tokenize(allocator);
    defer allocator.free(tokens);

    // Parse
    var parser = try zig_pug.Parser.init(allocator, tokens);
    defer parser.deinit();
    const ast = try parser.parse();

    // Compile to HTML
    var compiler = zig_pug.Compiler.init(allocator, &runtime);
    const html = try compiler.compile(ast);
    defer allocator.free(html);

    std.debug.print("{s}\n", .{html});
}
```

## Available API

### Public Modules

The `zig_pug` module exports:

- **`Tokenizer`** - Tokenizes Pug code
- **`Parser`** - Parses tokens into AST
- **`Compiler`** - Compiles AST to HTML
- **`Runtime`** - JavaScript runtime (mujs)
- **`ast`** - AST definitions

### Complete Example

```zig
const std = @import("std");
const zig_pug = @import("zig_pug");

const Tokenizer = zig_pug.Tokenizer;
const Parser = zig_pug.Parser;
const Compiler = zig_pug.Compiler;
const Runtime = zig_pug.Runtime;

pub fn compile(allocator: std.mem.Allocator, template: []const u8, vars: anytype) ![]u8 {
    // Runtime
    var runtime = try Runtime.init(allocator);
    defer runtime.deinit();

    // Set variables from struct
    inline for (std.meta.fields(@TypeOf(vars))) |field| {
        const value = @field(vars, field.name);
        switch (@TypeOf(value)) {
            []const u8, [:0]const u8 => try runtime.setString(field.name, value),
            i32, i64, f32, f64 => try runtime.setNumber(field.name, @as(f64, @floatFromInt(value))),
            bool => try runtime.setBool(field.name, value),
            else => {},
        }
    }

    // Pipeline: Tokenize -> Parse -> Compile
    var tokenizer = Tokenizer.init(template);
    const tokens = try tokenizer.tokenize(allocator);
    defer allocator.free(tokens);

    var parser = try Parser.init(allocator, tokens);
    defer parser.deinit();
    const ast = try parser.parse();

    var compiler = Compiler.init(allocator, &runtime);
    return try compiler.compile(ast);
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const template =
        \\doctype html
        \\html(lang="en")
        \\  head
        \\    title #{title}
        \\  body
        \\    h1 #{greeting}
        \\    p Welcome, #{name}!
    ;

    const html = try compile(allocator, template, .{
        .title = "My Page",
        .greeting = "Hello World",
        .name = "User",
    });
    defer allocator.free(html);

    std.debug.print("{s}\n", .{html});
}
```

## Example Project Structure

```
my-project/
├── build.zig
├── build.zig.zon
└── src/
    └── main.zig
```

### build.zig.zon

```zig
.{
    .name = .my_project,
    .version = "0.1.0",
    .fingerprint = 0xabc123...,
    .dependencies = .{
        .zig_pug = .{
            .url = "https://github.com/yourusername/zig-pug/archive/v0.2.0.tar.gz",
            .hash = "122...",
        },
    },
    .paths = .{
        "build.zig",
        "build.zig.zon",
        "src",
    },
}
```

### build.zig

See complete example above.

## Getting the Hash

The first time you run `zig build`, Zig will give you an error with the correct hash:

```bash
$ zig build
error: hash mismatch
note: expected: 122...
```

Copy the hash and add it to your `build.zig.zon`.

## Updating Version

To update to a new version:

1. Change the URL to the new tag
2. Remove the current hash
3. Run `zig build` to get the new hash
4. Add the new hash

## Limitations

### mujs (JavaScript Engine)

zig-pug includes mujs as a precompiled C library. Currently:

- Works on Linux x86_64, aarch64
- Works on macOS
- Windows may require recompiling mujs
- Other architectures may need to compile mujs manually

### Cross-compilation

For cross-compilation, you need the `libmujs.a` compiled for the target architecture.

## Troubleshooting

### "hash mismatch"

This is normal the first time. Use the hash that Zig suggests.

### "unable to find libmujs.a"

Make sure to add the lines:

```zig
exe.addObjectFile(zig_pug_dep.path("vendor/mujs/libmujs.a"));
exe.addIncludePath(zig_pug_dep.path("vendor/mujs"));
```

### Linking error

If you see errors about undefined symbols related to math (`sin`, `cos`, etc.), add:

```zig
exe.linkLibC();
```

## Resources

- **Zig Package Manager Docs:** https://ziglang.org/documentation/master/#Package-Management
- **zig-pug GitHub:** https://github.com/yourusername/zig-pug
- **zig-pug API Reference:** [docs/API-REFERENCE.md](API-REFERENCE.md)

## Support

If you have problems using zig-pug as a dependency:

1. Verify that you are using Zig 0.13.0+
2. Check that the hash is correct
3. Open an issue on GitHub with the complete error

---

**Enjoy using zig-pug in your Zig project!**
