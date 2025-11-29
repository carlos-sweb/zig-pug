# zig-pug

High-performance Pug template engine powered by Zig and mujs - Native N-API addon with ES5.1 JavaScript support.

[![npm version](https://img.shields.io/npm/v/zig-pug.svg)](https://www.npmjs.com/package/zig-pug)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

## Features

- **Blazing Fast**: Written in Zig with native N-API bindings
- **Lightweight**: ~500KB total (includes mujs JavaScript engine)
- **Modern**: Zig 0.15 best practices with StaticStringMap O(1) lookups
- **Secure**: Built-in XSS protection with automatic HTML escaping
- **Simple API**: Easy-to-use JavaScript interface
- **Cross-Platform**: Precompiled binaries for Linux, macOS, and Windows
- **Node.js Compatible**: Works with Node.js 14+ and Bun.js

## Installation

```bash
npm install zig-pug
```

Precompiled binaries are automatically downloaded for your platform. If no binary is available, it will build from source (requires Zig 0.15+).

## Quick Start

```javascript
const { compile } = require('zig-pug');

// Simple template
const html = compile('h1 Hello, World!');
console.log(html); // <h1>Hello, World!</h1>

// With variables
const html2 = compile('h1 Hello, #{name}!', { name: 'Alice' });
console.log(html2); // <h1>Hello, Alice!</h1>
```

## API Reference

### compile(template, variables)

Compile a Pug template string to HTML.

```javascript
const { compile } = require('zig-pug');

const html = compile('p Hello, #{name}!', { name: 'Bob' });
console.log(html); // <p>Hello, Bob!</p>
```

**Parameters:**
- `template` (string): Pug template string
- `variables` (object, optional): Variables to interpolate

**Returns:** Compiled HTML string

### compileFile(filename, variables)

Compile a Pug template file to HTML.

```javascript
const { compileFile } = require('zig-pug');

const html = compileFile('./views/index.pug', {
  title: 'My Page',
  user: 'Alice'
});
```

**Parameters:**
- `filename` (string): Path to Pug template file
- `variables` (object, optional): Variables to interpolate

**Returns:** Compiled HTML string

### ZigPugCompiler Class

For multiple compilations, use the `ZigPugCompiler` class to reuse the context:

```javascript
const { ZigPugCompiler } = require('zig-pug');

const compiler = new ZigPugCompiler();

// Set variables
compiler.setString('name', 'Alice');
compiler.setNumber('age', 30);
compiler.setBool('premium', true);

// Or set multiple at once
compiler.setVariables({
  name: 'Bob',
  age: 25,
  premium: false
});

// Compile templates
const html1 = compiler.compile('p Hello, #{name}!');
const html2 = compiler.compile('p Age: #{age}');
```

**Methods:**
- `setString(key, value)` - Set a string variable
- `setNumber(key, value)` - Set a number variable
- `setBool(key, value)` - Set a boolean variable
- `set(key, value)` - Auto-detect type and set variable
- `setVariables(obj)` - Set multiple variables from object
- `compile(template)` - Compile template with current variables
- `render(template, variables)` - Set variables and compile in one call

### version()

Get the zig-pug version.

```javascript
const { version } = require('zig-pug');
console.log(version()); // 0.2.0
```

## Pug Syntax Support

### Tags

```pug
div
  p Hello, World!
  span.class-name#id-name Text content
```

```html
<div>
  <p>Hello, World!</p>
  <span class="class-name" id="id-name">Text content</span>
</div>
```

### Attributes

```pug
a(href="https://example.com" target="_blank") Link
input(type="text" name="username" required)
```

```html
<a href="https://example.com" target="_blank">Link</a>
<input type="text" name="username" required />
```

### Interpolation

```pug
p Hello, #{name}!
p Age: #{age}
p Premium: #{premium}
```

With variables: `{ name: 'Alice', age: 30, premium: true }`

```html
<p>Hello, Alice!</p>
<p>Age: 30</p>
<p>Premium: true</p>
```

### HTML Escaping

Automatic XSS protection:

```javascript
const html = compile('p #{userInput}', {
  userInput: '<script>alert("XSS")</script>'
});
// <p>&lt;script&gt;alert(&quot;XSS&quot;)&lt;/script&gt;</p>
```

### Void Elements

Self-closing tags are handled automatically:

```pug
br
hr
img(src="logo.png")
input(type="text")
```

```html
<br />
<hr />
<img src="logo.png" />
<input type="text" />
```

## Usage Examples

### Express Integration

```javascript
const express = require('express');
const { compileFile } = require('zig-pug');
const app = express();

app.get('/', (req, res) => {
  const html = compileFile('./views/index.pug', {
    title: 'Home Page',
    user: req.user
  });
  res.send(html);
});

app.listen(3000);
```

### Koa Integration

```javascript
const Koa = require('koa');
const { compileFile } = require('zig-pug');
const app = new Koa();

app.use(async ctx => {
  const html = compileFile('./views/index.pug', {
    title: 'Home Page',
    path: ctx.path
  });
  ctx.body = html;
});

app.listen(3000);
```

### Bun.js Integration

```javascript
import { compile } from 'zig-pug';

Bun.serve({
  port: 3000,
  fetch(req) {
    const html = compile('h1 Hello from Bun!');
    return new Response(html, {
      headers: { 'Content-Type': 'text/html' }
    });
  }
});
```

## Performance

zig-pug is designed for performance:

- **O(1) lookups**: StaticStringMap for void element checks
- **Optimized I/O**: Writer pattern reduces allocations
- **Native code**: Zig compiles to machine code
- **Lightweight**: No heavy dependencies
- **Fast startup**: mujs has minimal overhead

## Security

- **Automatic HTML escaping**: All interpolated values are escaped by default
- **XSS prevention**: Built-in protection against cross-site scripting
- **Safe parsing**: Zig's memory safety prevents buffer overflows
- **No eval()**: Templates are compiled, not evaluated

## Building from Source

If precompiled binaries are not available for your platform:

### Prerequisites

- Node.js 14+
- Zig 0.15+
- Python 3
- C compiler (gcc/clang)

### Build Steps

From the repository root:

```bash
# Build the addon (builds library + addon + copies library to build dir)
zig build node

# Or from nodejs directory
cd nodejs && npm run build
```

### Running Examples and Tests

```bash
# From nodejs directory
npm test        # Run test suite
npm run example # Run example

# Or directly with node (after building)
node test/test.js
node example.js
```

**Note:** The build process automatically copies `libzigpug.so` to the `build/Release/` directory, so you don't need to set `LD_LIBRARY_PATH` manually.

See [BUILD_GUIDE.md](BUILD_GUIDE.md) for detailed build instructions.

## Architecture

```
┌─────────────────────────────────────────────┐
│  Node.js Application                        │
│  (your code)                                │
└────────────┬────────────────────────────────┘
             │ require('zig-pug')
             ↓
┌─────────────────────────────────────────────┐
│  N-API Addon (binding.c)                    │
│  - JavaScript API wrapper                   │
└────────────┬────────────────────────────────┘
             │ FFI calls
             ↓
┌─────────────────────────────────────────────┐
│  libzigpug.so (Zig + mujs)                  │
│  - Tokenizer → Parser → Compiler → HTML    │
└─────────────────────────────────────────────┘
```

## Contributing

Contributions are welcome! Please see the main repository for contributing guidelines.

## License

MIT License - see [LICENSE](LICENSE) for details.

## Links

- [GitHub Repository](https://github.com/carlos-sweb/zig-pug)
- [npm Package](https://www.npmjs.com/package/zig-pug)
- [Issue Tracker](https://github.com/carlos-sweb/zig-pug/issues)
- [Build Guide](BUILD_GUIDE.md)

## Credits

- Built by [carlos-sweb](https://github.com/carlos-sweb)
- Powered by [Zig](https://ziglang.org/) and [mujs](https://mujs.com/)
- Inspired by the original [Pug](https://pugjs.org/) template engine
