[Espanol](README.es.md) | English

# zig-pug

A high-performance template engine inspired by [Pug](https://pugjs.org/), implemented in Zig with full JavaScript support.

```zpug
doctype html
html(lang="en")
  head
    title #{pageTitle.toUpperCase()}
  body
    h1.greeting Hello #{name}!
    p Age next year: #{age + 1}
    if isActive
      p.status Active user
    each item in items
      li= item
```

## Features

- **Complete Pug syntax** - Tags, attributes, classes, IDs, doctype
- **JavaScript ES5.1** - Interpolations with methods, operators and expressions
- **Real JavaScript engine** - Powered by [mujs](https://mujs.com/)
- **Conditionals** - if/else/unless
- **Loops** - each/while with array support
- **Mixins** - Reusable components with arguments
- **Template inheritance** - extends/block
- **JSON variables** - Full support for strings, numbers, bools, arrays, and objects
- **Attribute expressions** - Dynamic attribute values (`class=myVar`)
- **Buffered/unbuffered code** - `=`, `!=`, and `-` operators
- **Node.js addon** - Native integration via N-API
- **Bun.js compatible** - 2-5x faster than Node.js
- **Editor support** - VS Code, Sublime Text, CodeMirror
- **No dependencies** - Only Zig 0.15.2 and embedded mujs
- **Fast** - Native compilation in Zig with optimizations
- **Secure** - HTML escaping and XSS prevention
- **Works on Termux/Android** (CLI binary)
- **87 unit tests** - Comprehensive test coverage

> **Note for Termux**: The CLI binary works perfectly. The Node.js addon compiles but cannot be loaded due to Android restrictions. See [docs/en/TERMUX.md](docs/en/TERMUX.md) for details.

## Installation

### Requirements

- **Zig 0.15.2** ([download](https://ziglang.org/download/))

### Clone and build

```bash
git clone https://github.com/yourusername/zig-pug
cd zig-pug
zig build
```

### Install (optional)

```bash
# Install system-wide
make install

# Uninstall
make uninstall
```

### Run

```bash
# Run the compiled binary
./zig-out/bin/zpug template.zpug

# Or if installed
zpug template.zpug
```

## CLI - Command Line Interface

zig-pug includes a powerful command line interface:

```bash
# Compile file to stdout
zpug template.zpug

# Compile with output file
zpug -i template.zpug -o output.html

# With variables (simple)
zpug template.zpug --var name=Alice --var age=25

# With JSON variables (arrays, objects)
zpug template.zpug --vars data.json

# Pretty-print output
zpug -p template.zpug -o pretty.html

# Minify output
zpug -m template.zpug -o minified.html

# From stdin
cat template.zpug | zpug --stdin > output.html
```

**Example JSON variables file:**
```json
{
  "user": {
    "name": "Alice",
    "age": 30,
    "email": "alice@example.com"
  },
  "items": ["apple", "banana", "orange"],
  "active": true
}
```

**[See complete CLI documentation](docs/en/CLI.md)**

## Quick Start

### Example: Complete Page

**template.zpug:**
```zpug
doctype html
html(lang="en")
  head
    meta(charset="UTF-8")
    title #{pageTitle}
  body
    - var greeting = "Hello"
    h1.main-title= greeting + " " + userName

    if isLoggedIn
      p.status Welcome back, #{userName}!
      ul.menu
        each item in menuItems
          li
            a(href=item.url)= item.title
    else
      p Please log in

    mixin button(text, type)
      button(class=type)= text

    +button("Click me", "btn-primary")
```

**Compile with:**
```bash
zpug template.zpug --vars data.json -o output.html
```

**Output:**
```html
<!DOCTYPE html><html lang="en"><head><meta charset="UTF-8"><title>My Page</title></head><body><h1 class="main-title">Hello Alice</h1><p class="status">Welcome back, Alice!</p><ul class="menu"><li><a href="/home">Home</a></li><li><a href="/profile">Profile</a></li></ul><button class="btn-primary">Click me</button></body></html>
```

## Supported Pug Syntax

### Doctype

```zpug
doctype html
// Output: <!DOCTYPE html>

doctype xml
// Output: <!DOCTYPE xml>
```

### Tags and Attributes

```zpug
// Simple tags
div
p Hello
span World

// Multiple classes (concatenated)
div.box.highlight.active
// Output: <div class="box highlight active">

// Classes and IDs
div.container
p#main-text
button.btn.btn-primary#submit

// Attributes (static)
a(href="https://example.com" target="_blank") Link
input(type="text" name="username" required)

// Attributes (dynamic expressions)
- var myClass = "active"
- var myUrl = "/home"
button(class=myClass) Click
a(href=myUrl) Link
// Output: <button class="active">Click</button>

// Multiple lines
div(
  class="card"
  id="user-card"
  data-user-id="123"
)
```

### Buffered and Unbuffered Code

```zpug
// Unbuffered code (executes but doesn't output)
- var name = "Alice"
- var age = 30
- var doubled = age * 2

// Buffered code inline (tag= syntax)
p= name
// Output: <p>Alice</p>

h1= name.toUpperCase()
// Output: <h1>ALICE</h1>

// Unescaped buffered code (tag!=)
- var html = "<strong>Bold</strong>"
div= html
// Output: <div>&lt;strong&gt;Bold&lt;/strong&gt;</div>

div!= html
// Output: <div><strong>Bold</strong></div>
```

### JavaScript Interpolation

```zpug
// Simple variables
p Hello #{name}

// String methods
p #{name.toUpperCase()}
p #{email.toLowerCase()}

// Arithmetic
p Age: #{age}
p Next year: #{age + 1}
p Double: #{age * 2}

// Objects (from JSON)
p Name: #{user.name}
p Email: #{user.email}
p Age: #{user.age}

// Arrays (from JSON)
p First: #{items[0]}
p Count: #{items.length}

// Complex expressions
p Full: #{firstName + ' ' + lastName}
p Status: #{age >= 18 ? 'Adult' : 'Minor'}

// Math
p Max: #{Math.max(10, 20)}
p Random: #{Math.floor(Math.random() * 100)}
```

### HTML Escaping (XSS Security)

All interpolations are automatically escaped for security:

```zpug
// Escaped by default (safe)
p #{userInput}
// Input: <script>alert('xss')</script>
// Output: <p>&lt;script&gt;alert(&#39;xss&#39;)&lt;/script&gt;</p>

// Unescaped (for trusted HTML only)
p !{trustedHtml}
// Input: <strong>Bold</strong>
// Output: <p><strong>Bold</strong></p>
```

**Escaped characters:** `&` `<` `>` `"` `'`

**⚠️ Security:** Only use `!{}` with HTML you control. Never with user input.

### Conditionals

```zpug
// if/else
if isLoggedIn
  p Welcome back!
else
  p Please log in

// unless (negation)
unless isAdmin
  p Access denied

// Expressions
if age >= 18
  p You can vote
else if age >= 16
  p Almost there
else
  p Too young

// With variables
if user.role == "admin"
  p Admin panel
```

### Loops

```zpug
// Each with arrays
each item in items
  li= item

// Each with index
each item, i in items
  li #{i}: #{item}

// While loops
- var count = 0
while count < 5
  p Count: #{count}
  - count = count + 1
```

### Mixins with Arguments

```zpug
// Define mixin
mixin greeting(name)
  p Hello, #{name}!

mixin button(text, type)
  button(class=type)= text

// Use mixins
+greeting("World")
+greeting("Alice")

+button("Click me", "btn-primary")
+button("Cancel", "btn-secondary")

// Output:
// <p>Hello, World!</p>
// <p>Hello, Alice!</p>
// <button class="btn-primary">Click me</button>
// <button class="btn-secondary">Cancel</button>
```

### Comments

```zpug
// Buffered comment (included in HTML)
// This appears in output

//- Unbuffered comment (not in HTML)
//- This is only in source

// Security: Comments are escaped
// Comment with --> injection attempt
// Output: <!-- Comment with - -> injection attempt -->
```

## Programming API (Zig)

### Complete Example

```zig
const std = @import("std");
const parser = @import("parser.zig");
const compiler = @import("compiler.zig");
const runtime = @import("runtime.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Create JavaScript runtime
    var js_runtime = try runtime.JsRuntime.init(allocator);
    defer js_runtime.deinit();

    // Set variables
    try js_runtime.setString("name", "Alice");
    try js_runtime.setNumber("age", 25);
    try js_runtime.setBool("active", true);

    // Parse template
    const source =
        \\doctype html
        \\html
        \\  body
        \\    h1= name
        \\    p Age: #{age}
    ;

    var pars = try parser.Parser.init(allocator, source);
    defer pars.deinit();
    const tree = try pars.parse();

    // Compile to HTML
    var comp = try compiler.Compiler.init(allocator, js_runtime);
    defer comp.deinit();
    const html = try comp.compile(tree);
    defer allocator.free(html);

    std.debug.print("{s}\n", .{html});
}
```

### Working with JSON Data

```zig
// Set arrays
const items = [_][]const u8{ "apple", "banana", "orange" };
for (items) |item| {
    // Arrays are set via JavaScript code
    _ = try js_runtime.eval("var items = ['apple', 'banana', 'orange']");
}

// Set objects
_ = try js_runtime.eval("var user = {name: 'Bob', age: 30}");

// Access properties
const name = try js_runtime.eval("user.name");
defer allocator.free(name);
```

## Complete Documentation

### Getting Started
- **[GETTING-STARTED.md](docs/en/GETTING-STARTED.md)** - Step-by-step guide
- **[CLI.md](docs/en/CLI.md)** - Command line interface
- **[PUG-SYNTAX.md](docs/en/PUG-SYNTAX.md)** - Complete syntax reference

### Integration
- **[NODEJS-INTEGRATION.md](docs/en/NODEJS-INTEGRATION.md)** - Node.js integration (N-API)
- **[ZIG-PACKAGE.md](docs/en/ZIG-PACKAGE.md)** - Usage as Zig dependency
- **[TERMUX.md](docs/en/TERMUX.md)** - Compilation on Termux/Android

### Advanced
- **[LOOPS-INCLUDES-CACHE.md](docs/en/LOOPS-INCLUDES-CACHE.md)** - Loops, includes and cache
- **[API-REFERENCE.md](docs/en/API-REFERENCE.md)** - API documentation
- **[EXAMPLES.md](docs/en/EXAMPLES.md)** - Practical examples
- **[TESTS.md](docs/tests/README.md)** - Test documentation (87 tests)

## Testing

```bash
# Run all tests
zig build test

# View detailed results
zig build test --summary all
```

**Test status:** ✅ All 87 tests passing

See [docs/tests/](docs/tests/) for detailed test documentation.

## Architecture

```
Source (*.zpug)
      ↓
  Tokenizer (lexical analysis)
      ↓
   Parser (syntactic analysis)
      ↓
     AST (abstract syntax tree)
      ↓
  Compiler ← JS Runtime (mujs)
      ↓
    HTML (output)
```

## Performance Optimizations

- **HTML escaping** - Pre-calculated buffer size (single allocation)
- **JS code generation** - Pre-allocated buffers for arrays/objects
- **mujs** - Compiled with -O2 optimization
- **Release builds** - Forced ReleaseFast for mujs compatibility

## JavaScript Engine

zig-pug uses [**mujs**](https://mujs.com/) as its JavaScript engine:

- **Version**: mujs 1.3.8
- **Standard**: ES5.1 compliant
- **Size**: 590 KB
- **Dependencies**: None (only libm)
- **Used by**: MuPDF, Ghostscript

### Supported JavaScript (ES5.1)

✅ **Fully supported:**
- String methods, Number methods, Array methods
- Object property access, Arithmetic/Comparison/Logical operators
- Ternary operator, Math object, JSON object

❌ **Not supported (ES6+):**
- Arrow functions, Template literals, let/const, Async/await, Classes

**For template engines, ES5.1 is completely sufficient.**

## Project Status

### ✅ Completed (v0.2.0)

**Phase 1: Critical Bugs**
- [x] Multiple classes concatenation
- [x] Loop iterator parsing
- [x] Mixin arguments
- [x] Comment escaping (security)

**Phase 2: API & Variables**
- [x] JSON arrays support (`--vars`)
- [x] JSON objects support
- [x] Attribute expressions (`class=myVar`)
- [x] Unbuffered code (`-` lines)

**Phase 3: UX Improvements**
- [x] Error messages with line numbers and hints
- [x] Tag= and tag!= syntax
- [x] Doctype support

**Phase 4: Performance**
- [x] Optimized HTML escaping
- [x] Optimized JS code generation

**Phase 5: Testing**
- [x] 87 comprehensive unit tests
- [x] Test documentation

### 🚧 In Progress

- [ ] Pretty printing (HTML indentation)
- [ ] Watch mode (`-w`)

### 📋 Roadmap

See [PLAN.md](PLAN.md) for the complete development plan.

## Contributing

Contributions are welcome! Please:

1. Fork the project
2. Create a branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## License

MIT License - see [LICENSE](LICENSE) for details

## Acknowledgments

- [Pug](https://pugjs.org/) - Original inspiration
- [Zig](https://ziglang.org/) - Programming language
- [mujs](https://mujs.com/) - Embedded JavaScript engine
- [Artifex Software](https://artifex.com/) - Creators of mujs

## Support

- **Issues**: [GitHub Issues](https://github.com/yourusername/zig-pug/issues)
- **Discussions**: [GitHub Discussions](https://github.com/yourusername/zig-pug/discussions)

---

**Made with ❤️ using Zig 0.15.2 and mujs**
