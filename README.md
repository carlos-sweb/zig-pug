[Espanol](README.es.md) | English

# zig-pug

A template engine inspired by [Pug](https://pugjs.org/), implemented in Zig with full JavaScript support.

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
```

## Features

- **Complete Pug syntax** - Tags, attributes, classes, IDs
- **JavaScript ES5.1** - Interpolations with methods, operators and expressions
- **Real JavaScript engine** - Powered by [mujs](https://mujs.com/)
- **Conditionals** - if/else/unless
- **Mixins** - Reusable components
- **Node.js addon** - Native integration via N-API
- **Bun.js compatible** - 2-5x faster than Node.js
- **Editor support** - VS Code, Sublime Text, CodeMirror
- **No dependencies** - Only Zig 0.15.2 and embedded mujs
- **Fast** - Native compilation in Zig
- **Works on Termux/Android** (CLI binary)

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

### Run

```bash
# Run the compiled binary
./zig-out/bin/zig-pug
```

### CLI - Command Line Interface

zig-pug includes a command line interface for compiling templates:

```bash
# Compile file to stdout
zig-pug template.zpug

# Compile with output file
zig-pug -i template.zpug -o output.html

# With variables
zig-pug template.zpug --var name=Alice --var age=25
```

**Note**: There are two CLI versions:
- **Simple** (`src/main.zig`) - Works on Termux/Android, fewer options
- **Full** (`src/cli.zig`) - Requires libc, all options (--var, --pretty, --minify, etc.)

**[See complete CLI documentation](docs/en/CLI.md)**

### Editor Support

zig-pug uses the **`.zpug`** extension for its template files, with full support in major editors:

**Visual Studio Code:**
```bash
cd editor-support/vscode
code --install-extension zig-pug-0.2.0.vsix
```

**Sublime Text 3/4:**
- Copy the files from `editor-support/sublime-text/` to your Packages folder
- Restart Sublime Text

**CodeMirror (for web editors):**
```javascript
var editor = CodeMirror.fromTextArea(textarea, {
  mode: 'zpug',
  theme: 'monokai'
});
```

All extensions include:
- Complete syntax highlighting
- Snippets for common patterns
- Auto-completion
- Smart indentation

**[See complete editor documentation](editor-support/README.md)**

### Usage in Node.js

zig-pug is also available as a native addon for Node.js:

```bash
cd nodejs
npm install
npm run build
```

**Usage example:**
```javascript
const zigpug = require('./nodejs');

const html = zigpug.compile('p Hello #{name}!', { name: 'World' });
console.log(html);
// <p>Hello World!</p>
```

**Object-oriented API:**
```javascript
const { PugCompiler } = require('./nodejs');

const compiler = new PugCompiler();
compiler
    .set('title', 'My Page')
    .set('version', 1.5)
    .setBool('isDev', false);

const html = compiler.compile('title #{title}');
```

**Express.js integration:**
```javascript
const express = require('express');
const zigpug = require('./nodejs');

app.engine('zpug', createZigPugEngine());
app.set('view engine', 'zpug');

app.get('/', (req, res) => {
    res.render('index', { title: 'Home' });
});
```

**[See complete Node.js documentation](docs/en/NODEJS-INTEGRATION.md)**

## Quick Start

### Example 1: Basic Template

**template.zpug:**
```zpug
div.container
  h1 Hello #{name}!
  p You are #{age} years old
```

**Usage in Zig:**
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

    // Parse template
    const source =
        \\div.container
        \\  h1 Hello #{name}!
        \\  p You are #{age} years old
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

**Output:**
```html
<div class="container"><h1>HelloAlice!</h1><p>You are25years old</p></div>
```

## Supported Pug Syntax

### Tags and Attributes

```zpug
// Simple tags
div
p Hello
span World

// Classes and IDs
div.container
p#main-text
button.btn.btn-primary#submit

// Attributes
a(href="https://example.com" target="_blank") Link
input(type="text" name="username" required)
img(src="photo.jpg" alt="Photo")

// Multiple lines
div(
  class="card"
  id="user-card"
  data-user-id="123"
)
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

// Objects
p Name: #{user.firstName} #{user.lastName}
p Email: #{user.email.toLowerCase()}

// Arrays
p First item: #{items[0]}
p Count: #{items.length}

// Complex expressions
p Full name: #{firstName + ' ' + lastName}
p Status: #{age >= 18 ? 'Adult' : 'Minor'}

// Math
p Max: #{Math.max(10, 20)}
p Random: #{Math.floor(Math.random() * 100)}

// JSON
p Data: #{JSON.stringify(obj)}
```

### HTML Escaping (XSS Security)

By default, all `#{}` interpolations escape HTML characters to prevent XSS attacks:

```zpug
// Automatic escaping (safe)
p #{userInput}
// Input: <script>alert('xss')</script>
// Output: <p>&lt;script&gt;alert(&#39;xss&#39;)&lt;/script&gt;</p>

// Unescaped (for trusted HTML)
p !{trustedHtml}
// Input: <strong>Bold</strong>
// Output: <p><strong>Bold</strong></p>
```

**Escaped characters:**
- `&` -> `&amp;`
- `<` -> `&lt;`
- `>` -> `&gt;`
- `"` -> `&quot;`
- `'` -> `&#39;`

**Important:** Only use `!{}` with HTML content that you control. Never use `!{}` with user input.

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
```

### Mixins

```zpug
// Define mixin
mixin button(text)
  button.btn= text

// Use mixin
+button('Click me')
+button('Submit')

// Mixin with attributes
mixin card(title, content)
  div.card
    h3= title
    p= content

+card('Hello', 'This is a card')
```

## Programming API

### JavaScript Runtime

```zig
const runtime = @import("runtime.zig");

// Initialize
var js_runtime = try runtime.JsRuntime.init(allocator);
defer js_runtime.deinit();

// Set variables
try js_runtime.setString("name", "Alice");
try js_runtime.setNumber("age", 25);
try js_runtime.setBool("active", true);
try js_runtime.setInt("count", 42);

// Evaluate expressions
const result = try js_runtime.eval("name.toUpperCase()");
defer allocator.free(result);
// result = "ALICE"

// Create objects in JavaScript
_ = try js_runtime.eval("var user = {name: 'Bob', age: 30}");
const name = try js_runtime.eval("user.name");
defer allocator.free(name);
// name = "Bob"
```

### Parser

```zig
const parser = @import("parser.zig");

// Create parser
var pars = try parser.Parser.init(allocator, source_code);
defer pars.deinit();

// Parse
const ast_tree = try pars.parse();
// ast_tree is the AST tree
```

### Compiler

```zig
const compiler = @import("compiler.zig");

// Create compiler
var comp = try compiler.Compiler.init(allocator, js_runtime);
defer comp.deinit();

// Compile AST to HTML
const html = try comp.compile(ast_tree);
defer allocator.free(html);
```

## Complete Documentation

- **[GETTING-STARTED.md](docs/en/GETTING-STARTED.md)** - Step-by-step getting started guide
- **[CLI.md](docs/en/CLI.md)** - Command line interface
- **[LOOPS-INCLUDES-CACHE.md](docs/en/LOOPS-INCLUDES-CACHE.md)** - Loops, includes and cache
- **[ZIG-PACKAGE.md](docs/en/ZIG-PACKAGE.md)** - Usage as a Zig dependency
- **[NODEJS-INTEGRATION.md](docs/en/NODEJS-INTEGRATION.md)** - Node.js integration (N-API)
- **[TERMUX.md](docs/en/TERMUX.md)** - Compilation on Termux/Android
- **[PUG-SYNTAX.md](docs/en/PUG-SYNTAX.md)** - Complete Pug syntax reference
- **[API-REFERENCE.md](docs/en/API-REFERENCE.md)** - API documentation
- **[EXAMPLES.md](docs/en/EXAMPLES.md)** - Practical examples

## Examples

### Pug Templates

See the [examples/](examples/) folder for template examples:

- `examples/basic.zpug` - Basic tags and attributes
- `examples/interpolation.zpug` - JavaScript interpolation
- `examples/conditionals.zpug` - Conditionals and logic
- `examples/mixins.zpug` - Reusable components
- `examples/loops.zpug` - Iteration with each/for
- `examples/includes.zpug` - Includes with partials

### Node.js Examples

See the [examples/nodejs/](examples/nodejs/) folder for Node.js usage examples:

- `01-basic.js` - Basic usage with `compile()`
- `02-interpolation.js` - JavaScript expressions
- `03-compiler-class.js` - Object-oriented API
- `04-file-compilation.js` - Compilation from files
- `05-express-integration.js` - Express.js integration

## Testing

```bash
# Run all tests
zig build test

# View detailed results
zig build test --summary all
```

**Test status**: All passing (13 tests)

## Architecture

```
+-------------+
|   Source    |  zpug template
|  (*.zpug)   |
+------+------+
       |
       v
+-------------+
|  Tokenizer  |  Lexical analysis
+------+------+
       |
       v
+-------------+
|   Parser    |  Syntactic analysis
+------+------+
       |
       v
+-------------+
|     AST     |  Abstract syntax tree
+------+------+
       |
       v
+-------------+       +-------------+
|  Compiler   |<------|  JS Runtime |
+------+------+       |    (mujs)   |
       |              +-------------+
       v
+-------------+
|    HTML     |  Final output
+-------------+
```

## JavaScript Engine

zig-pug uses [**mujs**](https://mujs.com/) as its JavaScript engine:

- **Version**: mujs 1.3.8
- **Standard**: ES5.1 compliant
- **Size**: 590 KB
- **Dependencies**: None (only libm)
- **Used by**: MuPDF, Ghostscript

### Supported JavaScript (ES5.1)

**Supported:**
- String methods: `toLowerCase()`, `toUpperCase()`, `substr()`, `split()`, etc.
- Number methods: `toFixed()`, `toPrecision()`
- Array methods: `map()`, `filter()`, `reduce()`, `forEach()`, etc.
- Object property access
- Arithmetic operators: `+`, `-`, `*`, `/`, `%`
- Comparison operators: `>`, `<`, `>=`, `<=`, `==`, `===`
- Logical operators: `&&`, `||`, `!`
- Ternary operator: `condition ? true : false`
- Math: `Math.max()`, `Math.min()`, `Math.round()`, etc.
- JSON: `JSON.parse()`, `JSON.stringify()`

**Not supported** (ES6+):
- Arrow functions: `() => {}`
- Template literals: `` `text ${var}` ``
- let/const (use `var`)
- Async/await
- Classes (class keyword)
- ES6 modules

**For Pug templates, ES5.1 is completely sufficient.**

## Project Status

### Completed

- [x] Tokenizer (lexical analysis)
- [x] Parser (syntactic analysis)
- [x] AST (syntax tree)
- [x] Compiler (HTML generation)
- [x] JavaScript Runtime (mujs)
- [x] Tags and attributes
- [x] Classes and IDs
- [x] JavaScript interpolation
- [x] Conditionals (if/else/unless)
- [x] Mixins
- [x] Tests

### In Development

- [x] Loops (each/for)
- [x] Includes
- [x] Template cache
- [x] Template inheritance (extends/block)
- [x] HTML escaping (XSS prevention)
- [ ] Pretty printing (HTML indentation)
- [ ] Full CLI

### Roadmap

See [PLAN.md](PLAN.md) for the complete development plan.

## Proposals (RFC)

The following features are under evaluation. Your feedback is welcome in [GitHub Discussions](https://github.com/yourusername/zig-pug/discussions).

### RFC-001: Value Filters

**Status:** Under evaluation

**Proposal:** Add filters to transform values in interpolations using pipe syntax.

```zpug
p #{name | uppercase}
p #{price | default(0)}
p #{bio | truncate(50)}
p #{tags | join(', ')}
```

**Proposed filters:**
- `uppercase`, `lowercase`, `capitalize` - Text transformation
- `truncate(n)` - Truncate text to n characters
- `default(val)` - Default value if undefined/null
- `escape` - Escape HTML
- `json` - Convert to JSON string
- `length`, `first`, `last` - Array operations
- `join(sep)`, `reverse`, `sort` - Array manipulation

**Pros:**
- Improves template expressiveness
- Implemented with mujs (no new dependencies)
- Common in other engines (Jinja2, Twig, Liquid)

**Cons:**
- JavaScript already has methods: `name.toUpperCase()`, `arr.join(',')`
- Adds complexity to the parser
- Additional syntax to learn
- Goes against zig-pug's minimalist philosophy

**Current alternative:**
```zpug
// Instead of filters, use JavaScript methods directly
p #{name.toUpperCase()}
p #{price || 0}
p #{bio.substr(0, 50)}
p #{tags.join(', ')}
```

**What do you think?** Open an issue or discussion with your use case.

---

## Contributing

Contributions are welcome! Please:

1. Fork the project
2. Create a branch for your feature (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
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

**Made with love using Zig 0.15.2 and mujs**
