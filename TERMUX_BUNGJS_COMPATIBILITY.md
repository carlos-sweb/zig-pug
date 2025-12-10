# Termux/Android & Bun.js Compatibility Guide

## Problem Summary

The `zig-pug` npm package includes a native Node.js addon (`zigpug.node`) that **cannot be loaded in Termux/Android** due to Android namespace restrictions.

### Error in Termux

```
Error: dlopen failed: library "zigpug.node" is not accessible for the namespace "(default)"
Code: ERR_DLOPEN_FAILED
```

### Root Cause

Android restricts access to dynamically loaded libraries (`.so`, `.node` files) from applications in non-privileged namespaces. Termux falls into this category, preventing Node.js from loading native addons.

---

## ✅ Solutions

### Solution 1: Use zpug CLI (Recommended for Termux)

Instead of the npm package, use the standalone `zpug` binary compiled with Zig:

#### Installation

```bash
# Install Zig in Termux
pkg install zig

# Clone and build
git clone https://github.com/carlos-sweb/zig-pug.git
cd zig-pug
zig build

# Use the binary
./zig-out/bin/zpug template.pug
```

#### Usage

```bash
# Compile a template
./zig-out/bin/zpug template.pug

# Pretty-print mode
./zig-out/bin/zpug --pretty template.pug

# Format mode (indented without comments)
./zig-out/bin/zpug --format template.pug

# Minify mode
./zig-out/bin/zpug --minify template.pug

# Output to file
./zig-out/bin/zpug template.pug -o output.html
```

#### Example

```bash
# Create a template
cat > hello.pug << 'EOF'
doctype html
html(lang="es")
  body
    h1 ¡Hola Mundo! 🎉
EOF

# Compile
./zig-out/bin/zpug hello.pug
# Output: <!DOCTYPE html><html lang="es"><body><h1>¡Hola Mundo! 🎉</h1></body></html>
```

**Note:** The CLI doesn't support passing variables from command line. Variables must be hardcoded in templates or you need to use the npm package on a non-Android system.

---

### Solution 2: Use npm Package on Non-Android Systems

The npm package works perfectly on:

- ✅ **Linux** (x86_64, ARM64)
- ✅ **macOS** (Intel, Apple Silicon)
- ✅ **Windows** (x64)
- ✅ **WSL** (Windows Subsystem for Linux)

#### Installation

```bash
npm install zig-pug
```

#### Usage (CommonJS)

```javascript
const { PugCompiler, compile } = require('zig-pug');

// Simple compile
const html = compile('p Hello #{name}!', { name: 'World' });
console.log(html);
// <p>Hello World!</p>
```

#### Usage (ES Modules)

```javascript
import { PugCompiler, compile } from 'zig-pug';

// Simple compile
const html = compile('p Hello #{name}!', { name: 'World' });
console.log(html);
// <p>Hello World!</p>
```

---

### Solution 3: Bun.js Support

**Status:** Bun.js has the same limitation as Node.js on Android/Termux regarding native addons.

However, on **non-Android systems**, Bun.js works perfectly with `zig-pug`:

#### Installation

```bash
bun install zig-pug
```

#### Usage

```typescript
import { PugCompiler, compile } from 'zig-pug';

const compiler = new PugCompiler();
compiler
    .set('title', 'My Page')
    .set('version', 1.5)
    .setBool('isDev', false);

const html = compiler.compile('h1 #{title}');
console.log(html);
// <h1>My Page</h1>
```

**Performance:** Bun is 2-5x faster than Node.js for template compilation.

---

## ES Modules Support (v0.3.1+)

Since version **0.3.1**, `zig-pug` supports both **CommonJS** and **ES Modules**:

### Package Structure

```
zig-pug/
├── index.js          (CommonJS - module.exports)
├── index.mjs         (ES Modules - export)
└── package.json      (with "exports" field)
```

### package.json Exports

```json
{
  "type": "commonjs",
  "main": "index.js",
  "exports": {
    ".": {
      "import": "./index.mjs",
      "require": "./index.js"
    }
  }
}
```

### Import Methods

**CommonJS (Node.js):**
```javascript
const { PugCompiler } = require('zig-pug');
```

**ES Modules (Node.js, Bun, Deno):**
```javascript
import { PugCompiler } from 'zig-pug';
```

Both methods load the same native addon but use different module systems.

---

## Platform Compatibility Matrix

| Platform | npm Package | CLI Binary | Bun.js |
|----------|-------------|------------|--------|
| **Linux x86_64** | ✅ | ✅ | ✅ |
| **Linux ARM64** | ✅ | ✅ | ✅ |
| **macOS Intel** | ✅ | ✅ | ✅ |
| **macOS Apple Silicon** | ✅ | ✅ | ✅ |
| **Windows x64** | ✅ | ✅ | ✅ |
| **WSL** | ✅ | ✅ | ✅ |
| **Termux/Android** | ❌ | ✅ | ❌ |

---

## Why Native Addons Don't Work in Termux

Android uses **SELinux** and **namespace restrictions** to isolate applications. When Node.js tries to load a native addon:

1. Node.js calls `dlopen()` to load the `.node` file
2. Android's linker checks if the library is in an allowed namespace
3. Termux apps are in the `(default)` namespace, which has restricted access
4. The linker rejects the load: `"library is not accessible for the namespace"`

**Workaround:** Use statically linked binaries (like `zpug`) instead of dynamic libraries.

---

## Troubleshooting

### Error: "Cannot find module './build/Release/zigpug.node'"

**Cause:** The addon wasn't compiled during installation.

**Solution:**
```bash
cd node_modules/zig-pug
npm rebuild
```

### Error: "dlopen failed: library is not accessible"

**Cause:** You're on Android/Termux, native addons don't work.

**Solution:** Use the `zpug` CLI instead (see Solution 1).

### Error: "require is not defined in ES module scope"

**Cause:** Your `package.json` has `"type": "module"` but you're using `require()`.

**Solution:** Use `import` instead:
```javascript
// Before (CommonJS)
const { PugCompiler } = require('zig-pug');

// After (ES Modules)
import { PugCompiler } from 'zig-pug';
```

---

## Related Documentation

- **Main README:** [/root/zig-pug/README.md](../README.md)
- **Node.js README:** [/root/zig-pug/nodejs/README.md](../nodejs/README.md)
- **CLI Usage:** Run `zpug --help`
- **GitHub Issues:** https://github.com/carlos-sweb/zig-pug/issues

---

## Feature Comparison: npm vs CLI

| Feature | npm Package | CLI Binary |
|---------|-------------|------------|
| **Variables from code** | ✅ Yes | ❌ No |
| **PugCompiler class** | ✅ Yes | ❌ No |
| **File compilation** | ✅ Yes | ✅ Yes |
| **Pretty-print** | ✅ Yes | ✅ Yes |
| **Minify** | ✅ Yes | ✅ Yes |
| **UTF-8 support** | ✅ Yes | ✅ Yes |
| **Doc comments (`//!`)** | ✅ Yes | ✅ Yes |
| **Works in Termux** | ❌ No | ✅ Yes |
| **Programmatic API** | ✅ Yes | ❌ No |

**Recommendation:**
- **For Termux/Android:** Use CLI binary (`zpug`)
- **For servers/desktop:** Use npm package (`zig-pug`)

---

**Last Updated:** 2025-12-10
**Version:** 0.3.1
