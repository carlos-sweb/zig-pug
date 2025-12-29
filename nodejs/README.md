# zig-pug for Node.js

High-performance Pug template engine powered by Zig and mujs.

## Installation

```bash
npm install zig-pug
```

## Quick Start

```javascript
const { compile, PugCompiler } = require('zig-pug');

// Simple API
const html = compile('p Hello #{name}!', { name: 'World' });
console.log(html); // <p>Hello World!</p>

// Advanced API with reusable context
const compiler = new PugCompiler();
compiler.set('title', 'My Page');
compiler.setArray('items', ['Apple', 'Banana']);
const html = compiler.compile('h1= title');
```

## Output Formatting

zig-pug supports three output modes:

### 1. Default (Minified)

By default, HTML is minified for production use:

```javascript
const compiler = new PugCompiler();
const html = compiler.compile('div\n  h1 Hello\n  p World');
// Output: <div><h1>Hello</h1><p>World</p></div>
```

### 2. Pretty Mode (Development)

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

### 3. Format Mode (Readable)

Pretty-print without comments for readable production output:

```javascript
const compiler = new PugCompiler({ format: true });
const html = compiler.compile('div\n  h1 Hello\n  p World');
// Output: formatted HTML without comments
```

### 4. Minify Mode (Explicit)

Explicitly minify to ensure smallest file size:

```javascript
const compiler = new PugCompiler({ minify: true });
const html = compiler.compile('div\n  h1 Hello\n  p World');
// Output: <div><h1>Hello</h1><p>World</p></div>
```

## Override Options at Compile Time

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

## API Reference

See full API documentation in the [TypeScript definitions](./index.d.ts).

### Key Options

- `pretty`: Enable pretty-print with indentation and comments (development mode)
- `format`: Enable pretty-print without comments (readable mode)
- `minify`: Enable HTML minification (production mode)
- `includeComments`: Include HTML comments (only with pretty/format)

## License

MIT
