# zig-pug

A high-performance template engine inspired by Pug, implemented in Zig.

## Status

🚧 **Work in Progress** - Currently in development (Phase 1: Setup)

## Features (Planned)

- ✅ All core Pug features (tags, attributes, interpolation, conditionals, loops, mixins, etc.)
- 🆕 **Pure JavaScript blocks** - Full JavaScript support for complex logic
- 🆕 **TOML data format** - Use TOML instead of JSON for cleaner configuration
- ⚡ **Blazing fast** - Native Zig implementation for maximum performance
- 🔒 **Type-safe** - Leverage Zig's compile-time guarantees
- 🎯 **Comptime support** - Compile templates at compile-time when possible

## Requirements

- **Zig 0.15.2** or higher (CRITICAL - older versions are not compatible)

## Installation

```bash
git clone https://github.com/yourusername/zig-pug
cd zig-pug
zig build
```

## Usage (Planned)

```zig
const ZigPug = @import("zig-pug");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const template = "div.container\n  p= message";
    const data = "[site]\nmessage = \"Hello, World!\"";

    var zigpug = ZigPug.init(allocator, .{});
    const html = try zigpug.render(template, data);
    defer allocator.free(html);

    std.debug.print("{s}\n", .{html});
}
```

## Differences from Pug

| Feature | Pug | zig-pug |
|---------|-----|---------|
| Data format | JSON | TOML |
| JavaScript | Limited | Full JS blocks support |
| Runtime | Node.js | Native (or embedded JS engine) |
| Performance | Fast | Blazing fast |
| Compile-time | No | Yes (comptime support) |

## Development

```bash
# Build
zig build

# Run
zig build run

# Test
zig build test
```

## Project Structure

```
zig-pug/
├── src/
│   ├── main.zig        # Entry point
│   ├── tokenizer.zig   # Lexical analysis
│   ├── parser.zig      # Syntax analysis
│   ├── ast.zig         # Abstract Syntax Tree
│   ├── compiler.zig    # HTML compilation
│   ├── runtime.zig     # Runtime execution
│   └── utils.zig       # Utilities
├── tests/              # Test files
├── examples/           # Example templates
├── docs/               # Documentation
├── PLAN.md             # Development roadmap
├── PUG.md              # Pug feature reference
└── build.zig           # Build configuration
```

## Roadmap

See [PLAN.md](PLAN.md) for the complete development plan (23 steps across 8 phases).

**Current Phase:** Phase 1 - Setup ✅

## Contributing

Contributions are welcome! Please read [CONTRIBUTING.md](CONTRIBUTING.md) (coming soon).

## License

MIT License (see [LICENSE](LICENSE))

## Acknowledgments

- Inspired by [Pug](https://pugjs.org/)
- Built with [Zig](https://ziglang.org/)

---

**Note:** This project is in early development. APIs and features are subject to change.
# zig-pug
