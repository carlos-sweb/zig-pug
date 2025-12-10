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
- ✅ **Bun.js compatible** - 2-5x faster than Node.js
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

### `compile(template, data)`

Compile a template with data.

**Parameters:**
- `template` (string) - Pug template source
- `data` (object) - Variables to interpolate

**Returns:** (string) Compiled HTML

```javascript
const html = zigpug.compile(
    'p Hello #{name}!',
    { name: 'Alice' }
);
```

### `PugCompiler`

Reusable compiler with state.

```javascript
const { PugCompiler } = require('zig-pug');

const compiler = new PugCompiler();
compiler.set('key', 'value');      // String/Number
compiler.setBool('flag', true);    // Boolean

const html = compiler.compile(template);
```

**Methods:**
- `set(key, value)` - Set string or number variable
- `setBool(key, value)` - Set boolean variable
- `compile(template)` - Compile template with current variables

### `version()`

Get zig-pug version.

```javascript
console.log(zigpug.version()); // "0.2.0"
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
git clone https://github.com/yourusername/zig-pug
cd zig-pug
zig build

# Use CLI
./zig-out/bin/zig-pug template.pug
```

See [docs/TERMUX.md](https://github.com/yourusername/zig-pug/blob/main/docs/TERMUX.md) for details.

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

## Examples

See the [examples](https://github.com/yourusername/zig-pug/tree/main/examples) directory:

- **Node.js**: `examples/nodejs/`
- **Bun.js**: `examples/bun/`
- **Express**: `examples/nodejs/05-express-integration.js`

## Documentation

- **[Getting Started](https://github.com/yourusername/zig-pug/blob/main/docs/GETTING-STARTED.md)**
- **[Node.js Integration](https://github.com/yourusername/zig-pug/blob/main/docs/NODEJS-INTEGRATION.md)**
- **[Pug Syntax Reference](https://github.com/yourusername/zig-pug/blob/main/docs/PUG-SYNTAX.md)**
- **[API Reference](https://github.com/yourusername/zig-pug/blob/main/docs/API-REFERENCE.md)**

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

If you encounter compilation errors, please [open an issue](https://github.com/yourusername/zig-pug/issues) with:
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

MIT License - see [LICENSE](https://github.com/yourusername/zig-pug/blob/main/LICENSE) for details.

## Credits

- **[Pug](https://pugjs.org/)** - Original inspiration
- **[Zig](https://ziglang.org/)** - Programming language
- **[mujs](https://mujs.com/)** - Embedded JavaScript engine
- **[Artifex Software](https://artifex.com/)** - Creators of mujs

## Links

- **GitHub**: https://github.com/yourusername/zig-pug
- **npm**: https://www.npmjs.com/package/zig-pug
- **Issues**: https://github.com/yourusername/zig-pug/issues
- **Documentation**: https://github.com/yourusername/zig-pug#readme

---

Made with ❤️ using Zig 0.15.2 and mujs
