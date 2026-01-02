# Node.js Integration

Complete guide for integrating zig-pug into Node.js and Bun.js projects.

## Table of Contents

- [Installation](#installation)
- [Quick Start](#quick-start)
- [API Reference](#api-reference)
- [Module Systems](#module-systems)
- [TypeScript Support](#typescript-support)
- [Bun.js Support](#bunjs-support)
- [Express Integration](#express-integration)
- [Performance](#performance)
- [Troubleshooting](#troubleshooting)

## Installation

### Requirements

- **Node.js** >= 14.0.0
- **C/C++ compiler:**
  - Linux/macOS: GCC or Clang
  - Windows: MSVC or MinGW-w64
- **Python** (for node-gyp)

### Install via npm

```bash
npm install zig-pug
```

The native addon compiles automatically via node-gyp during installation.

### Install via Bun

```bash
bun install zig-pug
```

Bun uses the same N-API interface as Node.js, so the addon works seamlessly.

### Install Build Tools

**Ubuntu/Debian:**
```bash
sudo apt-get install build-essential python3
```

**macOS:**
```bash
xcode-select --install
```

**Windows:**
```powershell
npm install --global windows-build-tools
```

Or install [Visual Studio Build Tools](https://visualstudio.microsoft.com/downloads/#build-tools-for-visual-studio-2022).

## Quick Start

### Simple Compilation

**CommonJS:**
```javascript
const zigpug = require('zig-pug');

const html = zigpug.compile('p Hello #{name}!', { name: 'World' });
console.log(html);
// <p>Hello World!</p>
```

**ES Modules:**
```javascript
import { compile } from 'zig-pug';

const html = compile('p Hello #{name}!', { name: 'World' });
console.log(html);
// <p>Hello World!</p>
```

### File-based Templates

```javascript
const fs = require('fs');
const zigpug = require('zig-pug');

const template = fs.readFileSync('./views/index.pug', 'utf-8');
const html = zigpug.compile(template, {
  title: 'My Page',
  user: { name: 'Alice', age: 30 }
});

console.log(html);
```

## API Reference

### `compile(template, data, options)`

Compile a Pug template to HTML.

**Parameters:**
- `template` (string) - Pug template source
- `data` (object) - Variables to interpolate
- `options` (object) - Formatting options (optional)

**Options:**
- `pretty` (boolean) - Pretty-print with comments (development)
- `format` (boolean) - Pretty-print without comments (readable)
- `minify` (boolean) - Minify HTML (production)
- `includeComments` (boolean) - Include buffered comments

**Returns:** (string) Compiled HTML

**Example:**
```javascript
const html = zigpug.compile(
  `div
    h1= title
    p= description`,
  { title: 'Hello', description: 'World' },
  { format: true }
);
```

### `compileFile(path, data, options)`

Compile a Pug file to HTML.

**Parameters:**
- `path` (string) - Path to .pug/.zpug file
- `data` (object) - Variables to interpolate
- `options` (object) - Formatting options (optional)

**Returns:** (string) Compiled HTML

**Example:**
```javascript
const { compileFile } = require('zig-pug');

const html = compileFile('./views/home.pug', {
  user: { name: 'Alice' }
}, { pretty: true });
```

### `PugCompiler` Class

Reusable compiler with state management.

**Constructor:**
```javascript
const { PugCompiler } = require('zig-pug');

const compiler = new PugCompiler(options);
```

**Constructor Options:**
- `pretty` (boolean) - Enable pretty-print with comments
- `format` (boolean) - Enable pretty-print without comments
- `minify` (boolean) - Enable HTML minification
- `includeComments` (boolean) - Include HTML comments

**Methods:**

#### `set(key, value)`

Set a variable (auto-detects type).

```javascript
compiler.set('name', 'Alice');        // String
compiler.set('age', 30);              // Number
compiler.set('active', true);         // Boolean
compiler.set('items', [1, 2, 3]);     // Array
compiler.set('user', {name: 'Bob'});  // Object
```

#### `setString(key, value)`

Set a string variable.

```javascript
compiler.setString('name', 'Alice');
```

#### `setNumber(key, value)`

Set a number variable.

```javascript
compiler.setNumber('age', 30);
compiler.setNumber('price', 19.99);
```

#### `setBool(key, value)`

Set a boolean variable.

```javascript
compiler.setBool('isActive', true);
compiler.setBool('isAdmin', false);
```

#### `setArray(key, value)`

Set an array variable.

```javascript
compiler.setArray('items', ['apple', 'banana', 'orange']);
compiler.setArray('scores', [95, 87, 92]);
```

#### `setObject(key, value)`

Set an object variable.

```javascript
compiler.setObject('user', {
  name: 'Alice',
  age: 30,
  email: 'alice@example.com'
});
```

#### `setVariables(object)`

Set multiple variables from an object.

```javascript
compiler.setVariables({
  title: 'My Page',
  count: 42,
  active: true,
  items: [1, 2, 3]
});
```

#### `compile(template, options)`

Compile a template with current variables.

```javascript
const html = compiler.compile('p Hello #{name}!');
```

**Override options per compilation:**
```javascript
// Default: minified
const compiler = new PugCompiler({ minify: true });

// Use default
const prod = compiler.compile(template);

// Override for development
const dev = compiler.compile(template, { pretty: true });
```

#### `render(template, data, options)`

Compile with variables in one call.

```javascript
const html = compiler.render(
  'p Hello #{name}!',
  { name: 'Alice' },
  { format: true }
);
```

### `version()`

Get zig-pug version.

```javascript
console.log(zigpug.version());
// "0.4.0"
```

## Module Systems

zig-pug supports both **CommonJS** and **ES Modules**.

### CommonJS (Node.js default)

```javascript
// Import entire module
const zigpug = require('zig-pug');
const html = zigpug.compile(template, data);

// Destructure
const { compile, PugCompiler } = require('zig-pug');
const html = compile(template, data);
```

### ES Modules (Node.js with "type": "module")

**package.json:**
```json
{
  "type": "module"
}
```

**Usage:**
```javascript
// Named imports
import { compile, PugCompiler, version } from 'zig-pug';

const html = compile(template, data);
const ver = version();

// Default import
import zigpug from 'zig-pug';
const html = zigpug.compile(template, data);
```

### Dual Package Support

zig-pug provides both CJS and ESM entry points:

- **CommonJS:** `index.cjs`
- **ES Modules:** `index.mjs`
- **Auto-detection:** `index.js` (works in both)

## TypeScript Support

zig-pug includes full TypeScript definitions.

### Type Definitions

**Installation:**
```bash
npm install zig-pug
# Types included, no @types package needed
```

**Basic Usage:**
```typescript
import { compile, PugCompiler, ZigPugCompilationError } from 'zig-pug';

const html: string = compile('p Hello #{name}', { name: 'TypeScript' });
```

### Available Types

```typescript
// Compiler class
const compiler: PugCompiler = new PugCompiler({ pretty: true });

// Variables type
const vars: PugVariables = {
  title: 'My Page',
  count: 42,
  active: true
};

// Options type
const options: CompilationOptions = {
  pretty: true,
  format: false,
  minify: false,
  includeComments: true
};

// Error handling
try {
  const html = compile(template, vars);
} catch (error) {
  const err = error as ZigPugCompilationError;

  if (err.compilationErrors) {
    err.compilationErrors.errors.forEach(e => {
      console.error(`Line ${e.line}: ${e.message}`);
      if (e.hint) console.error(`Hint: ${e.hint}`);
    });
  }
}
```

### Error Types

```typescript
interface CompilationErrorInfo {
  line: number;
  message: string;
  detail?: string;
  hint?: string;
  errorType?: ErrorType;
}

interface CompilationErrors {
  errorCount: number;
  errors: CompilationErrorInfo[];
}

class ZigPugCompilationError extends Error {
  compilationErrors?: CompilationErrors;
}

enum ErrorType {
  InvalidSyntax = "InvalidSyntax",
  UnexpectedToken = "UnexpectedToken",
  // ... more types
}
```

### Full Example

```typescript
import { PugCompiler, ZigPugCompilationError } from 'zig-pug';

interface User {
  name: string;
  age: number;
  email: string;
}

function renderUserProfile(user: User): string {
  const compiler = new PugCompiler({ format: true });

  compiler
    .setString('name', user.name)
    .setNumber('age', user.age)
    .setString('email', user.email);

  const template = `
  div.user-profile
    h2= name
    p Age: #{age}
    p Email: #{email}
  `;

  try {
    return compiler.compile(template);
  } catch (error) {
    const err = error as ZigPugCompilationError;
    console.error('Compilation failed:', err.message);
    throw err;
  }
}

const user: User = { name: 'Alice', age: 30, email: 'alice@example.com' };
const html = renderUserProfile(user);
```

## Bun.js Support

zig-pug works seamlessly with Bun, offering 2-5x better performance than Node.js.

### Installation

```bash
bun install zig-pug
```

### Usage

**Identical API to Node.js:**
```javascript
import { compile, PugCompiler } from 'zig-pug';

const html = compile('p Hello #{name}!', { name: 'Bun' });
console.log(html);
```

### Performance Comparison

**Node.js:**
```javascript
// 100,000 compilations: ~4500ms
const start = Date.now();
for (let i = 0; i < 100000; i++) {
  compile(template, data);
}
console.log(`Elapsed: ${Date.now() - start}ms`);
```

**Bun:**
```javascript
// 100,000 compilations: ~1800ms (2.5x faster)
const start = Date.now();
for (let i = 0; i < 100000; i++) {
  compile(template, data);
}
console.log(`Elapsed: ${Date.now() - start}ms`);
```

**Why Bun is faster:**
- Optimized N-API calls
- Better memory management
- Faster V8 integration

## Express Integration

### Basic Setup

```javascript
const express = require('express');
const zigpug = require('zig-pug');
const fs = require('fs');

const app = express();

// Load templates once at startup
const homeTemplate = fs.readFileSync('./views/home.pug', 'utf-8');
const aboutTemplate = fs.readFileSync('./views/about.pug', 'utf-8');

app.get('/', (req, res) => {
  const html = zigpug.compile(homeTemplate, {
    title: 'Home',
    user: req.session?.user
  });
  res.send(html);
});

app.get('/about', (req, res) => {
  const html = zigpug.compile(aboutTemplate, {
    title: 'About'
  }, { format: true });
  res.send(html);
});

app.listen(3000, () => {
  console.log('Server running on http://localhost:3000');
});
```

### View Engine Integration

```javascript
const express = require('express');
const zigpug = require('zig-pug');
const fs = require('fs');
const path = require('path');

const app = express();

// Configure view engine
app.set('views', './views');
app.set('view engine', 'pug');

// Custom render function
app.engine('pug', (filePath, options, callback) => {
  fs.readFile(filePath, 'utf-8', (err, template) => {
    if (err) return callback(err);

    try {
      const html = zigpug.compile(template, options, {
        format: app.get('env') !== 'production'
      });
      callback(null, html);
    } catch (compileErr) {
      callback(compileErr);
    }
  });
});

// Use with res.render()
app.get('/', (req, res) => {
  res.render('home', { title: 'Home', user: req.user });
});
```

### Caching Templates

```javascript
const templateCache = new Map();

function getCachedTemplate(filePath) {
  if (!templateCache.has(filePath)) {
    const template = fs.readFileSync(filePath, 'utf-8');
    templateCache.set(filePath, template);
  }
  return templateCache.get(filePath);
}

app.get('/', (req, res) => {
  const template = getCachedTemplate('./views/home.pug');
  const html = zigpug.compile(template, { title: 'Home' });
  res.send(html);
});
```

## Performance

### Benchmarking

```javascript
const zigpug = require('zig-pug');

const template = `
div
  h1= title
  ul
    each item in items
      li= item
`;

const data = {
  title: 'Benchmark',
  items: ['a', 'b', 'c', 'd', 'e']
};

// Warmup
for (let i = 0; i < 1000; i++) {
  zigpug.compile(template, data);
}

// Measure
const iterations = 100000;
const start = Date.now();

for (let i = 0; i < iterations; i++) {
  zigpug.compile(template, data);
}

const elapsed = Date.now() - start;
const ops = Math.floor(iterations / (elapsed / 1000));

console.log(`${iterations} compilations in ${elapsed}ms`);
console.log(`${ops.toLocaleString()} ops/sec`);
```

### Optimization Tips

1. **Reuse PugCompiler:**
   ```javascript
   // ❌ Slow (creates new context each time)
   for (let i = 0; i < 10000; i++) {
     compile(template, data);
   }

   // ✅ Fast (reuses context)
   const compiler = new PugCompiler();
   compiler.setVariables(data);
   for (let i = 0; i < 10000; i++) {
     compiler.compile(template);
   }
   ```

2. **Cache templates:**
   ```javascript
   const templateCache = new Map();

   function getTemplate(name) {
     if (!templateCache.has(name)) {
       const content = fs.readFileSync(`./views/${name}.pug`, 'utf-8');
       templateCache.set(name, content);
     }
     return templateCache.get(name);
   }
   ```

3. **Use minification in production:**
   ```javascript
   const options = {
     minify: process.env.NODE_ENV === 'production'
   };

   const html = compile(template, data, options);
   ```

4. **Use Bun.js when possible:**
   ```bash
   # 2-5x faster than Node.js
   bun run server.js
   ```

## Troubleshooting

### Installation Issues

**Error: `node-gyp rebuild` fails**

**Solution:** Install build tools:
```bash
# Ubuntu/Debian
sudo apt-get install build-essential python3

# macOS
xcode-select --install

# Windows
npm install --global windows-build-tools
```

**Error: "Cannot find module 'zig-pug'"**

**Solution:** Rebuild the addon:
```bash
cd node_modules/zig-pug
npm run build
```

### Runtime Issues

**Error: "binding.compile is not a function"**

**Cause:** Addon failed to compile or load.

**Solution:** Check addon exists:
```bash
ls node_modules/zig-pug/build/Release/
# Should see: zigpug.node
```

Rebuild if missing:
```bash
cd node_modules/zig-pug
npm run build
```

**Error: "Compilation failed" with no details**

**Solution:** Enable detailed errors:
```javascript
try {
  const html = compile(template, data);
} catch (error) {
  console.error('Error:', error.message);
  if (error.compilationErrors) {
    error.compilationErrors.errors.forEach(e => {
      console.error(`  Line ${e.line}: ${e.message}`);
      if (e.detail) console.error(`  Detail: ${e.detail}`);
      if (e.hint) console.error(`  Hint: ${e.hint}`);
    });
  }
}
```

### Platform Issues

**Termux/Android:**

The addon compiles but cannot load due to Android namespace restrictions. Use the CLI binary instead:

```bash
pkg install zig
git clone https://github.com/carlos-sweb/zig-pug
cd zig-pug
zig build
./zig-out/bin/zpug template.pug
```

See [TERMUX.md](TERMUX.md) for details.

## Examples

Complete examples are in the repository:

- **[examples/nodejs/](../examples/nodejs/)** - Node.js examples
- **[examples/bun/](../examples/bun/)** - Bun.js examples
- **[examples/nodejs/05-express-integration.js](../examples/nodejs/05-express-integration.js)** - Express integration
- **[examples/nodejs/08-typescript-example.ts](../examples/nodejs/08-typescript-example.ts)** - TypeScript example

## See Also

- [GETTING-STARTED.md](GETTING-STARTED.md) - Getting started guide
- [PUG-SYNTAX.md](PUG-SYNTAX.md) - Complete syntax reference
- [../nodejs/README.md](../nodejs/README.md) - Node.js addon documentation
- [en/API-REFERENCE.md](en/API-REFERENCE.md) - Complete API reference

## Support

- **Issues:** [GitHub Issues](https://github.com/carlos-sweb/zig-pug/issues)
- **Discussions:** [GitHub Discussions](https://github.com/carlos-sweb/zig-pug/discussions)
- **npm:** [zig-pug on npm](https://www.npmjs.com/package/zig-pug)
