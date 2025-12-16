# API Reference

[Español](../es/API-REFERENCE.md) | English

Complete API documentation for zig-pug.

---

## Table of Contents

1. [Node.js API](#nodejs-api)
   - [PugCompiler Class](#pugcompiler-class)
   - [Standalone Functions](#standalone-functions)
2. [CLI API](#cli-api)
3. [Zig Package API](#zig-package-api)

---

## Node.js API

### Installation

```bash
npm install zig-pug
```

### Importing

#### CommonJS

```javascript
const { PugCompiler, compile, compileFile } = require('zig-pug');
```

#### ES Modules

```javascript
import { PugCompiler, compile, compileFile } from 'zig-pug';
```

---

## PugCompiler Class

The main class for compiling Pug templates with variables.

### Constructor

```javascript
new PugCompiler()
```

Creates a new compiler instance with an empty variable context.

**Example:**

```javascript
const compiler = new PugCompiler();
```

---

### Methods

#### `set(key, value)`

Set a string or number variable.

**Parameters:**
- `key` (string) - Variable name
- `value` (string | number) - Variable value

**Returns:** `PugCompiler` (chainable)

**Example:**

```javascript
compiler.set('title', 'My Page');
compiler.set('year', 2025);
compiler.set('version', 1.5);
```

**Chainable:**

```javascript
compiler
  .set('name', 'Alice')
  .set('age', 30)
  .set('score', 95.5);
```

---

#### `setBool(key, value)`

Set a boolean variable.

**Parameters:**
- `key` (string) - Variable name
- `value` (boolean) - Boolean value

**Returns:** `PugCompiler` (chainable)

**Example:**

```javascript
compiler.setBool('isActive', true);
compiler.setBool('hasPermission', false);
```

**Chainable:**

```javascript
compiler
  .setBool('isLoggedIn', true)
  .setBool('isDarkMode', false);
```

---

#### `setArray(key, value)`

Set an array variable.

**Parameters:**
- `key` (string) - Variable name
- `value` (Array) - Array of strings, numbers, or booleans

**Returns:** `PugCompiler` (chainable)

**Example:**

```javascript
compiler.setArray('items', ['Apple', 'Banana', 'Cherry']);
compiler.setArray('numbers', [1, 2, 3, 4, 5]);
compiler.setArray('flags', [true, false, true]);
```

**Mixed arrays:**

```javascript
// Note: Arrays can contain mixed types
compiler.setArray('mixed', ['text', 42, true]);
```

---

#### `setObject(key, value)`

Set an object variable.

**Parameters:**
- `key` (string) - Variable name
- `value` (Object) - Object with string, number, or boolean values

**Returns:** `PugCompiler` (chainable)

**Example:**

```javascript
compiler.setObject('user', {
  name: 'Alice',
  age: 30,
  isAdmin: true
});

compiler.setObject('config', {
  theme: 'dark',
  fontSize: 14,
  autoSave: true
});
```

**Nested objects:**

```javascript
// Note: Nested objects are supported
compiler.setObject('settings', {
  ui: {
    theme: 'dark',
    lang: 'en'
  },
  features: {
    notifications: true,
    autoplay: false
  }
});
```

---

#### `compile(template)`

Compile a Pug template string to HTML.

**Parameters:**
- `template` (string) - Pug template code

**Returns:** `string` - Compiled HTML

**Throws:** `Error` if compilation fails

**Example:**

```javascript
const compiler = new PugCompiler();
compiler.set('name', 'World');

const html = compiler.compile('p Hello #{name}!');
console.log(html);
// <p>Hello World!</p>
```

**With variables:**

```javascript
const compiler = new PugCompiler();
compiler
  .set('title', 'My Blog')
  .set('author', 'Alice')
  .setBool('published', true)
  .setArray('tags', ['javascript', 'node', 'pug']);

const template = `
doctype html
html
  head
    title= title
  body
    h1= title
    p By #{author}
    if published
      p.status Published
    ul
      each tag in tags
        li= tag
`;

const html = compiler.compile(template);
```

---

#### `compileFile(filePath)`

Compile a Pug template file to HTML.

**Parameters:**
- `filePath` (string) - Path to .pug file

**Returns:** `string` - Compiled HTML

**Throws:** `Error` if file not found or compilation fails

**Example:**

```javascript
const compiler = new PugCompiler();
compiler.set('pageTitle', 'Home Page');

const html = compiler.compileFile('templates/home.pug');
```

---

## Standalone Functions

Convenience functions for quick compilation without creating a compiler instance.

### `compile(template, variables)`

Compile a template string with variables.

**Parameters:**
- `template` (string) - Pug template code
- `variables` (Object) - Optional variables object

**Returns:** `string` - Compiled HTML

**Example:**

```javascript
const { compile } = require('zig-pug');

const html = compile('p Hello #{name}!', { name: 'Alice' });
console.log(html);
// <p>Hello Alice!</p>
```

**With multiple variables:**

```javascript
const html = compile(
  `
  h1= title
  p Count: #{count}
  if active
    p.status Active
  `,
  {
    title: 'Dashboard',
    count: 42,
    active: true
  }
);
```

---

### `compileFile(filePath, variables)`

Compile a template file with variables.

**Parameters:**
- `filePath` (string) - Path to .pug file
- `variables` (Object) - Optional variables object

**Returns:** `string` - Compiled HTML

**Example:**

```javascript
const { compileFile } = require('zig-pug');

const html = compileFile('templates/page.pug', {
  title: 'About Us',
  year: 2025
});
```

---

## Variable Types Reference

### Supported Types

| Type | Method | Example |
|------|--------|---------|
| **String** | `set()` | `compiler.set('name', 'Alice')` |
| **Number** | `set()` | `compiler.set('age', 30)` |
| **Boolean** | `setBool()` | `compiler.setBool('active', true)` |
| **Array** | `setArray()` | `compiler.setArray('items', [1,2,3])` |
| **Object** | `setObject()` | `compiler.setObject('user', {name: 'Alice'})` |

### Variable Access in Templates

```pug
//- String interpolation
p Hello #{name}

//- Number operations
p Age in 5 years: #{age + 5}

//- Boolean conditions
if isActive
  p Active

//- Array iteration
each item in items
  li= item

//- Object properties
p Name: #{user.name}
p Age: #{user.age}
```

---

## CLI API

### Installation

```bash
# Clone and build
git clone https://github.com/carlos-sweb/zig-pug
cd zig-pug
zig build
```

### Basic Usage

```bash
zpug template.pug
zpug template.pug -o output.html
zpug --help
```

### Options

| Option | Description |
|--------|-------------|
| `--help, -h` | Show help message |
| `--version, -v` | Show version |
| `--output, -o` | Output file path |
| `--pretty, -p` | Pretty-print HTML |
| `--minify, -m` | Minify output |
| `--format, -f` | Format (indented without comments) |
| `--vars` | JSON file with variables |

### Examples

**Basic compilation:**

```bash
zpug template.pug
```

**Pretty-print:**

```bash
zpug template.pug --pretty
```

**With output file:**

```bash
zpug template.pug -o output.html
```

**With variables:**

```bash
# Create vars.json
echo '{"title": "My Page", "year": 2025}' > vars.json

# Compile with variables
zpug template.pug --vars vars.json
```

**Minified:**

```bash
zpug template.pug --minify -o dist/page.html
```

---

## Zig Package API

For using zig-pug as a Zig dependency.

### Installation

**build.zig.zon:**

```zig
.{
    .name = "my-project",
    .version = "0.1.0",
    .dependencies = .{
        .zig_pug = .{
            .url = "https://github.com/carlos-sweb/zig-pug/archive/main.tar.gz",
        },
    },
}
```

**build.zig:**

```zig
const zig_pug = b.dependency("zig_pug", .{
    .target = target,
    .optimize = optimize,
});

exe.addModule("zig_pug", zig_pug.module("zig_pug"));
```

### Usage

```zig
const std = @import("std");
const zig_pug = @import("zig_pug");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Compile template
    const template = "p Hello #{name}!";
    const html = try zig_pug.compile(allocator, template);
    defer allocator.free(html);

    std.debug.print("{s}\n", .{html});
}
```

See [ZIG-PACKAGE.md](ZIG-PACKAGE.md) for complete Zig API documentation.

---

## Error Handling

### Node.js

All methods throw standard JavaScript errors:

```javascript
try {
  const html = compiler.compile('invalid pug syntax !!!');
} catch (error) {
  console.error('Compilation failed:', error.message);
}
```

### CLI

Returns non-zero exit code on error:

```bash
zpug invalid.pug
# Exit code: 1
```

---

## Performance Tips

1. **Reuse compiler instances** - Create once, compile many times
2. **Use standalone functions** - For one-off compilations
3. **Precompile templates** - In production, compile at build time
4. **Minimize variables** - Only pass what's needed

**Good:**

```javascript
const compiler = new PugCompiler();
for (const item of items) {
  compiler.set('name', item.name);
  const html = compiler.compile(template);
  // Use html
}
```

**Better:**

```javascript
const template = `each item in items\n  li= item`;
const html = compile(template, { items: items.map(i => i.name) });
```

---

## See Also

- [Getting Started](GETTING-STARTED.md)
- [Pug Syntax Guide](PUG-SYNTAX.md)
- [Examples](EXAMPLES.md)
- [Node.js Integration](NODEJS-INTEGRATION.md)

---

**Last Updated:** 2025-12-16
**Version:** 0.3.7
