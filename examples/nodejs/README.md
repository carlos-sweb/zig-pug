# zig-pug Node.js Examples

Examples showing how to use zig-pug in Node.js applications.

## 📋 Prerequisites

1. **Node.js 14+** installed
2. **node-gyp** and build tools:
   ```bash
   npm install -g node-gyp
   ```

3. **Build the addon**:
   ```bash
   cd nodejs
   npm install
   npm run build
   ```

## 🚀 Running the Examples

Each example can be run directly with Node.js:

```bash
# From the examples/nodejs directory
node 01-basic.js
node 02-interpolation.js
node 03-compiler-class.js
node 04-file-compilation.js
node 05-express-integration.js
```

## 📚 Examples Overview

### 01-basic.js - Basic Usage
**Simplest way to use zig-pug**

```javascript
const zigpug = require('zig-pug');

const html = zigpug.compile(template, variables);
```

**Learn**: Quick start, compile function

---

### 02-interpolation.js - JavaScript Interpolation
**Using JavaScript expressions in templates**

```javascript
const template = `
p #{name.toUpperCase()}
p Age next year: #{age + 1}
p Status: #{age >= 18 ? 'Adult' : 'Minor'}
`;
```

**Learn**: String methods, arithmetic, ternary operators

---

### 03-compiler-class.js - Compiler Class
**Object-oriented API with method chaining**

```javascript
const { PugCompiler } = require('zig-pug');

const compiler = new PugCompiler();
compiler
    .set('name', 'Alice')
    .set('age', 25)
    .compile(template);
```

**Learn**: PugCompiler class, method chaining, variable setting

---

### 04-file-compilation.js - File Compilation
**Loading templates from .pug files**

```javascript
const { compileFile } = require('zig-pug');

const html = compileFile('template.pug', variables);
```

**Learn**: compileFile(), working with files

---

### 05-express-integration.js - Express.js Integration
**Using zig-pug as Express template engine**

```javascript
app.engine('pug', zigpugEngine());
app.set('view engine', 'pug');

app.get('/', (req, res) => {
    res.render('index', { title: 'Home' });
});
```

**Learn**: Express integration, custom template engine

---

## 🔧 API Reference

### compile(template, variables)

Compile a Pug template string with variables.

```javascript
const html = zigpug.compile('p Hello #{name}!', { name: 'World' });
```

**Parameters**:
- `template` (string): Pug template
- `variables` (object): Variables for interpolation

**Returns**: `string` - Compiled HTML

---

### compileFile(filename, variables)

Compile a Pug template from a file.

```javascript
const html = zigpug.compileFile('./views/index.pug', { title: 'Home' });
```

**Parameters**:
- `filename` (string): Path to .pug file
- `variables` (object): Variables for interpolation

**Returns**: `string` - Compiled HTML

---

### PugCompiler

Class for advanced usage with reusable context.

```javascript
const compiler = new PugCompiler();

// Set variables
compiler.set(key, value);              // Auto-detect type
compiler.setString(key, value);         // String
compiler.setNumber(key, value);         // Number
compiler.setBool(key, value);           // Boolean
compiler.setVariables({ key: value }); // Multiple variables

// Compile
const html = compiler.compile(template);

// Or compile with variables
const html = compiler.render(template, variables);
```

**Methods**:
- `set(key, value)` - Set variable (auto-detect type)
- `setString(key, value)` - Set string variable
- `setNumber(key, value)` - Set number variable
- `setBool(key, value)` - Set boolean variable
- `setVariables(object)` - Set multiple variables
- `compile(template)` - Compile template
- `render(template, variables)` - Set variables and compile

---

### version()

Get zig-pug version.

```javascript
console.log(zigpug.version()); // "0.2.0"
```

**Returns**: `string` - Version string

---

## 💡 Tips

### 1. Reuse Compiler Instances

If compiling multiple templates with same variables:

```javascript
const compiler = new PugCompiler();
compiler.setVariables(commonVars);

const page1 = compiler.compile(template1);
const page2 = compiler.compile(template2);
```

### 2. Error Handling

Wrap in try-catch:

```javascript
try {
    const html = zigpug.compile(template, vars);
} catch (err) {
    console.error('Compilation failed:', err.message);
}
```

### 3. Performance

For best performance:
- Reuse compiler instances
- Load templates once, compile many times
- Use object spread for variables instead of multiple `set()` calls

### 4. TypeScript Support

Create `zigpug.d.ts`:

```typescript
declare module 'zig-pug' {
    export class PugCompiler {
        set(key: string, value: string | number | boolean): this;
        setString(key: string, value: string): this;
        setNumber(key: string, value: number): this;
        setBool(key: string, value: boolean): this;
        setVariables(vars: Record<string, any>): this;
        compile(template: string): string;
        render(template: string, vars?: Record<string, any>): string;
    }

    export function compile(template: string, vars?: Record<string, any>): string;
    export function compileFile(filename: string, vars?: Record<string, any>): string;
    export function version(): string;
}
```

## 🐛 Troubleshooting

### "Cannot find module 'zig-pug'"

Build the addon first:
```bash
cd nodejs
npm install
npm run build
```

### "Error: Failed to create zig-pug context"

Check that libmujs.a exists:
```bash
ls -la ../vendor/mujs/libmujs.a
```

### "gyp ERR! build error"

Install build tools:
```bash
# Ubuntu/Debian
sudo apt-get install build-essential

# macOS
xcode-select --install

# Windows
npm install --global windows-build-tools
```

## 📖 More Resources

- [Main README](../../README.md)
- [Getting Started Guide](../../docs/GETTING-STARTED.md)
- [Node.js Integration Docs](../../docs/NODEJS-INTEGRATION.md)
- [Pug Syntax Reference](../../README.md#-sintaxis-pug-soportada)

---

**Need help?** Open an issue on [GitHub](https://github.com/yourusername/zig-pug/issues)
