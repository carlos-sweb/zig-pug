# zig-pug

High-performance Pug template engine powered by Zig and mujs.

[![npm version](https://img.shields.io/npm/v/zig-pug.svg)](https://www.npmjs.com/package/zig-pug)
[![license](https://img.shields.io/npm/l/zig-pug.svg)](https://github.com/carlos-sweb/zig-pug/blob/main/LICENSE)

## Features

- ✅ **Pug syntax** - Tags, attributes, classes, IDs
- ✅ **JavaScript expressions** - ES5.1 interpolation powered by mujs
- ✅ **Full UTF-8 support** - Emoji 🎉, accents (á é ñ ü), all Unicode
- ✅ **Documentation comments** - `//!` for file metadata (ignored by parser)
- ✅ **Conditionals** - if/else/unless
- ✅ **Mixins** - Reusable components
- ✅ **Dual package** - CommonJS (`require`) and ES Modules (`import`)
- ✅ **TypeScript support** - Full type definitions included
- ✅ **Bun.js compatible** - 2-5x faster than Node.js
- ✅ **Structured errors** - Detailed error messages with line numbers, hints, and context
- ✅ **Output formatting** - Minify, pretty-print, or format modes
- ⚡ **Native performance** - Written in Zig, compiled to native code
- 🔋 **Zero dependencies** - Only Zig and embedded mujs
- 🌍 **i18n ready** - Spanish, Portuguese, French, German, and more

## Installation

```bash
npm install zig-pug
```

**Requirements:**
- Node.js >= 14.0.0
- C/C++ compiler (GCC, Clang, or MSVC)
- Python (for node-gyp)

The addon will compile automatically during installation.

## Quick Start

### Simple API

**CommonJS (Node.js):**
```javascript
const zigpug = require('zig-pug');

const html = zigpug.compile('p Hello #{name}!', { name: 'World' });
console.log(html);
// <p>Hello World!</p>
```

**ES Modules (Node.js, Bun):**
```javascript
import { compile } from 'zig-pug';

const html = compile('p Hello #{name}!', { name: 'World' });
console.log(html);
// <p>Hello World!</p>
```

### Object-Oriented API

**CommonJS (Node.js):**
```javascript
const { PugCompiler } = require('zig-pug');

const compiler = new PugCompiler();
compiler
    .set('title', 'My Page')
    .set('version', 1.5)
    .setBool('isDev', false);

const html = compiler.compile('h1 #{title}');
console.log(html);
// <h1>My Page</h1>
```

**ES Modules (Node.js, Bun):**
```javascript
import { PugCompiler } from 'zig-pug';

const compiler = new PugCompiler();
compiler
    .set('title', 'My Page')
    .set('version', 1.5)
    .setBool('isDev', false);

const html = compiler.compile('h1 #{title}');
console.log(html);
// <h1>My Page</h1>
```

## Output Formatting

zig-pug supports multiple output modes to suit different use cases:

### Default (Minified)

By default, HTML is minified for production use:

```javascript
const compiler = new PugCompiler();
const html = compiler.compile('div\n  h1 Hello\n  p World');
// Output: <div><h1>Hello</h1><p>World</p></div>
```

### Pretty Mode (Development)

Pretty-print with indentation and HTML comments for debugging:

```javascript
const compiler = new PugCompiler({ pretty: true });
const html = compiler.compile('div\n  h1 Hello\n  p World');
// Output:
// <div>
//   <h1>Hello</h1>
//   <p>World</p>
// </div>
```

### Format Mode (Readable)

Pretty-print without comments for readable production output:

```javascript
const compiler = new PugCompiler({ format: true });
const html = compiler.compile('div\n  h1 Hello\n  p World');
// Output: formatted HTML without comments
```

### Minify Mode (Explicit)

Explicitly minify to ensure smallest file size:

```javascript
const compiler = new PugCompiler({ minify: true });
const html = compiler.compile('div\n  h1 Hello\n  p World');
// Output: <div><h1>Hello</h1><p>World</p></div>
```

### Override Options at Compile Time

The hybrid approach allows you to set default options in the constructor and override them per compilation:

```javascript
// Create compiler with minify by default
const compiler = new PugCompiler({ minify: true });
compiler.set('title', 'Hello');

// Production build (uses default minify)
const prod = compiler.compile('h1= title');

// Debug build (overrides with pretty)
const debug = compiler.compile('h1= title', { pretty: true });

// Readable build (overrides with format)
const readable = compiler.compile('h1= title', { format: true });
```

### Express Integration

```javascript
const express = require('express');
const zigpug = require('zig-pug');
const fs = require('fs');

const app = express();

// Load template once at startup
const homeTemplate = fs.readFileSync('./views/home.pug', 'utf-8');

app.get('/', (req, res) => {
    const html = zigpug.compile(homeTemplate, {
        title: 'Home',
        user: req.user
    });
    res.send(html);
});

app.listen(3000);
```

## Bun.js Support

zig-pug works seamlessly with Bun, the ultra-fast JavaScript runtime:

```bash
bun install zig-pug
bun run app.js
```

**Performance:** Bun is 2-5x faster than Node.js for template compilation.

See [examples/bun/](https://github.com/carlos-sweb/zig-pug/tree/main/examples/bun) for complete examples.

## TypeScript Support

zig-pug includes full TypeScript definitions for enhanced development experience with IntelliSense and type safety.

### Basic Usage

```typescript
import { compile, PugCompiler, ZigPugCompilationError } from 'zig-pug';

// Simple compilation with type inference
const html: string = compile('p Hello #{name}', { name: 'TypeScript' });

// Using PugCompiler class with formatting options
const compiler: PugCompiler = new PugCompiler({ pretty: true });
compiler
    .setString('title', 'My Page')
    .setNumber('count', 42)
    .setBool('active', true);

const result: string = compiler.compile('h1= title');
```

### Error Handling with Types

```typescript
try {
    const html = compile(template, variables);
} catch (error) {
    const err = error as ZigPugCompilationError;

    if (err.compilationErrors) {
        const { errorCount, errors } = err.compilationErrors;

        errors.forEach(e => {
            console.error(`Line ${e.line}: ${e.message}`);
            if (e.detail) console.error(`  Detail: ${e.detail}`);
            if (e.hint) console.error(`  Hint: ${e.hint}`);
        });
    }
}
```

### Available Types

- `PugCompiler` - Main compiler class
- `PugVariables` - Type for template variables
- `CompilationOptions` - Formatting options (pretty, format, minify)
- `CompilationErrorInfo` - Individual error information
- `CompilationErrors` - Collection of compilation errors
- `ZigPugCompilationError` - Extended Error with compilation details
- `ErrorType` - Error type classification enum

See [examples/nodejs/08-typescript-example.ts](https://github.com/carlos-sweb/zig-pug/tree/main/examples/nodejs/08-typescript-example.ts) for complete TypeScript examples.

## Pug Syntax

### Tags and Attributes

```pug
div.container
  h1#title Hello World
  p.text(data-id="123") Content
  a(href="/" target="_blank") Link
```

### JavaScript Interpolation

```pug
p Hello #{name}!
p Age: #{age + 1}
p Email: #{email.toLowerCase()}
p Status: #{age >= 18 ? 'Adult' : 'Minor'}
p Max: #{Math.max(10, 20)}
```

**Supported JavaScript (ES5.1):**
- String methods: `toLowerCase()`, `toUpperCase()`, `split()`, etc.
- Math: `Math.max()`, `Math.min()`, `Math.random()`, etc.
- Operators: `+`, `-`, `*`, `/`, `%`, `&&`, `||`, `?:`
- Object/Array access: `obj.prop`, `arr[0]`, `arr.length`

### Conditionals

```pug
if isLoggedIn
  p Welcome back!
else
  p Please log in

unless isAdmin
  p Access denied
```

### Mixins

```pug
mixin button(text)
  button.btn= text

+button('Click me')
+button('Submit')
```

### UTF-8 & Unicode Support

Full support for international characters, emoji, and symbols:

```pug
//! File: index.pug
//! Author: Carlos
doctype html
html(lang="es")
  head
    title #{titulo}
  body
    h1 ¡Bienvenido! 🎉

    section.español
      p.información Información sobre José y María
      p#descripción Este párrafo tiene ID con acento

    section.português
      h2 Programação em português
      p Características: ã, õ, ç

    section.français
      h2 Génération française
      p Avec é, è, ê, ç

    footer
      p © 2025 - Creado con zig-pug 🚀
```

**Supported everywhere:**
- ✅ Text content: `p José, María, Ángel`
- ✅ Class names: `.información .português`
- ✅ ID attributes: `#descripción #größe`
- ✅ Comments: `// útil para depuración`
- ✅ Emoji: `h1 Hello 🎉 🚀 ✨`
- ✅ Symbols: `p © ™ € £ ¥`

### Documentation Comments

Use `//!` for file metadata that won't appear in output:

```pug
//! Template: homepage.pug
//! Author: John Doe
//! Version: 1.0
//! Description: Main landing page
doctype html
html
  body
    // Regular comment (appears in --pretty mode)
    //- Code comment (never appears)
```

| Syntax | Name | In HTML? | Use Case |
|--------|------|----------|----------|
| `//!` | Documentation | ❌ Never | File metadata, notes |
| `//` | Buffered | ✅ Dev mode | Development debugging |
| `//-` | Unbuffered | ❌ Never | Code comments |

## API Reference

### `compile(template, data, options)`

Compile a template with data and formatting options.

**Parameters:**
- `template` (string) - Pug template source
- `data` (object) - Variables to interpolate
- `options` (object) - Formatting options (optional)
  - `pretty` (boolean) - Enable pretty-print with comments
  - `format` (boolean) - Enable pretty-print without comments
  - `minify` (boolean) - Enable HTML minification
  - `includeComments` (boolean) - Include HTML comments

**Returns:** (string) Compiled HTML

```javascript
const html = zigpug.compile(
    'p Hello #{name}!',
    { name: 'Alice' },
    { pretty: true }
);
```

### `PugCompiler`

Reusable compiler with state and formatting options.

```javascript
const { PugCompiler } = require('zig-pug');

const compiler = new PugCompiler({ pretty: true });
compiler.set('key', 'value');      // String/Number
compiler.setBool('flag', true);    // Boolean

const html = compiler.compile(template);
```

**Constructor Options:**
- `pretty` (boolean) - Enable pretty-print with indentation and comments
- `format` (boolean) - Enable pretty-print without comments
- `minify` (boolean) - Enable HTML minification
- `includeComments` (boolean) - Include HTML comments

**Methods:**
- `set(key, value)` - Set string, number, array, or object variable (auto-detects type)
- `setString(key, value)` - Set string variable
- `setNumber(key, value)` - Set number variable
- `setBool(key, value)` - Set boolean variable
- `setArray(key, value)` - Set array variable
- `setObject(key, value)` - Set object variable
- `setVariables(object)` - Set multiple variables from an object
- `compile(template, options)` - Compile template with current variables
- `render(template, variables, options)` - Compile template with variables in one call

### `version()`

Get zig-pug version.

```javascript
console.log(zigpug.version()); // "0.4.0"
```

## Platform Support

### Supported Platforms

- ✅ **Linux** (x64, ARM64)
- ✅ **macOS** (x64, Apple Silicon)
- ✅ **Windows** (x64)
- ✅ **Bun.js** (all platforms)

### Termux/Android

The addon compiles on Termux but cannot be loaded due to Android namespace restrictions. Use the standalone CLI binary instead:

```bash
# Install Zig
pkg install zig

# Clone and build
git clone https://github.com/carlos-sweb/zig-pug
cd zig-pug
zig build

# Use CLI
./zig-out/bin/zig-pug template.pug
```

See [docs/TERMUX.md](https://github.com/carlos-sweb/zig-pug/blob/main/docs/TERMUX.md) for details.

## Performance

### Benchmark

```javascript
const iterations = 10000;
const start = Date.now();

for (let i = 0; i < iterations; i++) {
    zigpug.compile(template, data);
}

const elapsed = Date.now() - start;
console.log(`${iterations} in ${elapsed}ms`);
// ~100-250k ops/sec depending on runtime
```

### Tips

1. **Reuse PugCompiler** - Faster than creating new context each time
2. **Pre-load templates** - Read files once at startup
3. **Use Bun.js** - 2-5x faster than Node.js
4. **Use minify in production** - Smaller output, faster rendering

## Examples

See the [examples](https://github.com/carlos-sweb/zig-pug/tree/main/examples) directory:

- **Node.js**: `examples/nodejs/`
- **Bun.js**: `examples/bun/`
- **Express**: `examples/nodejs/05-express-integration.js`
- **TypeScript**: `examples/nodejs/08-typescript-example.ts`

## Documentation

- **[Getting Started](https://github.com/carlos-sweb/zig-pug/blob/main/docs/GETTING-STARTED.md)**
- **[Node.js Integration](https://github.com/carlos-sweb/zig-pug/blob/main/docs/NODEJS-INTEGRATION.md)**
- **[Pug Syntax Reference](https://github.com/carlos-sweb/zig-pug/blob/main/docs/PUG-SYNTAX.md)**
- **[API Reference](https://github.com/carlos-sweb/zig-pug/blob/main/docs/API-REFERENCE.md)**

## Troubleshooting

### Installation fails

**Error:** `node-gyp rebuild` fails

**Solution:** Install build tools:

```bash
# Ubuntu/Debian
sudo apt-get install build-essential python3

# macOS
xcode-select --install

# Windows
npm install --global windows-build-tools
```

### Module not found

**Error:** `Cannot find module 'zig-pug'`

**Solution:** Rebuild the addon:

```bash
cd node_modules/zig-pug
npm run build
```

### Compilation errors

If you encounter compilation errors, please [open an issue](https://github.com/carlos-sweb/zig-pug/issues) with:
- Your OS and version
- Node.js version (`node --version`)
- Complete error output

## Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Run tests: `npm test`
5. Submit a pull request

## License

MIT License - see [LICENSE](https://github.com/carlos-sweb/zig-pug/blob/main/LICENSE) for details.

## Credits

- **[Pug](https://pugjs.org/)** - Original inspiration
- **[Zig](https://ziglang.org/)** - Programming language
- **[mujs](https://mujs.com/)** - Embedded JavaScript engine
- **[Artifex Software](https://artifex.com/)** - Creators of mujs

## Links

- **GitHub**: https://github.com/carlos-sweb/zig-pug
- **npm**: https://www.npmjs.com/package/zig-pug
- **Issues**: https://github.com/carlos-sweb/zig-pug/issues
- **Documentation**: https://github.com/carlos-sweb/zig-pug#readme

---

Made with ❤️ using Zig 0.15.2 and mujs
