# mujs Integration

Complete guide to how zig-pug integrates the mujs JavaScript engine for template evaluation.

## Table of Contents

- [Overview](#overview)
- [Why mujs?](#why-mujs)
- [Architecture](#architecture)
- [JavaScript Runtime](#javascript-runtime)
- [Supported Features](#supported-features)
- [Variable Injection](#variable-injection)
- [Expression Evaluation](#expression-evaluation)
- [Limitations](#limitations)
- [Performance](#performance)
- [Advanced Usage](#advanced-usage)

## Overview

zig-pug uses **[mujs](https://mujs.com/)** as its embedded JavaScript engine to evaluate expressions in Pug templates.

**mujs** is a lightweight JavaScript interpreter written in C:
- **Version:** 1.3.8
- **Standard:** ES5.1 compliant
- **Size:** ~590 KB
- **Dependencies:** None (only libm)
- **License:** ISC (permissive)

**Used by:** MuPDF, Ghostscript, and other production software.

## Why mujs?

### Comparison with Alternatives

| Feature | mujs | V8 | QuickJS | Duktape |
|---------|------|----|---------| --------|
| Size | 590 KB | ~20 MB | ~800 KB | ~200 KB |
| ES Standard | ES5.1 | ES2023+ | ES2020 | ES5.1 |
| Startup Time | Fast | Slow | Medium | Fast |
| Memory | Low | High | Medium | Low |
| C Integration | Simple | Complex | Medium | Simple |
| Build Time | Fast | Slow | Medium | Fast |

### Why We Chose mujs

1. **Perfect for templates:** ES5.1 is completely sufficient for template expressions
2. **Lightweight:** Small binary size, fast startup
3. **Simple integration:** Clean C API, easy to embed
4. **Proven:** Used in production by Artifex (MuPDF creators)
5. **No dependencies:** Self-contained, portable
6. **Fast enough:** Adequate performance for template evaluation

**ES6+ is not needed** for template engines. Features like arrow functions, async/await, and classes are unnecessary for simple interpolations.

## Architecture

### How It Works

```
Template with #{...}
        ↓
   [TOKENIZER] → Extracts "#{name}" as EscapedInterpol("name")
        ↓
     [PARSER] → Creates Interpolation AST node
        ↓
   [COMPILER] → Calls runtime.eval("name")
        ↓
  [mujs ENGINE] → Evaluates expression in JavaScript context
        ↓
     Result → Returned as string to compiler
        ↓
   HTML Output → Escaped and inserted into HTML
```

### Separation of Concerns

**Parser (Zig):**
- Recognizes `#{}` syntax
- Extracts expression as string
- Does NOT evaluate expressions

**mujs (C):**
- Evaluates JavaScript expressions
- Handles all operators, methods, property access
- Returns results to Zig

**Compiler (Zig):**
- Receives evaluated results
- Escapes HTML if needed
- Inserts into output

This design ensures **complete JavaScript support** without implementing a JavaScript engine in Zig.

## JavaScript Runtime

### Runtime Lifecycle

```zig
// 1. Create runtime
var runtime = try JsRuntime.init(allocator);
defer runtime.deinit();

// 2. Set variables
try runtime.setString("name", "Alice");
try runtime.setNumber("age", 30);
try runtime.setBool("active", true);

// 3. Evaluate expressions
const result = try runtime.eval("name.toUpperCase()");
// result = "ALICE"

// 4. Runtime cleaned up on deinit
```

### Runtime API (Internal)

**File:** `src/runtime.zig`

**Key Functions:**

```zig
pub const JsRuntime = struct {
    state: *mujs.js_State,
    allocator: Allocator,

    // Initialize mujs state
    pub fn init(allocator: Allocator) !*JsRuntime;

    // Clean up mujs state
    pub fn deinit(self: *JsRuntime) void;

    // Set global variables
    pub fn setGlobal(self: *JsRuntime, name: []const u8, value: []const u8) !void;
    pub fn setString(self: *JsRuntime, name: []const u8, value: []const u8) !void;
    pub fn setNumber(self: *JsRuntime, name: []const u8, value: f64) !void;
    pub fn setBool(self: *JsRuntime, name: []const u8, value: bool) !void;

    // Evaluate JavaScript expressions
    pub fn eval(self: *JsRuntime, expr: []const u8) ![]const u8;

    // Get global variables
    pub fn getGlobal(self: *JsRuntime, name: []const u8) ![]const u8;
};
```

### mujs C API Wrapper

**File:** `src/mujs_wrapper.zig`

**Core Functions:**

```zig
// Create JavaScript state
pub extern fn js_newstate(
    alloc: ?*anyopaque,
    actx: ?*anyopaque,
    flags: c_int
) ?*js_State;

// Execute JavaScript code
pub extern fn js_dostring(
    J: ?*js_State,
    source: [*c]const u8
) c_int;

// Get string from stack
pub extern fn js_getstring(
    J: ?*js_State,
    idx: c_int
) [*c]const u8;

// Set global variable
pub extern fn js_setglobal(
    J: ?*js_State,
    name: [*c]const u8
) void;

// Get global variable
pub extern fn js_getglobal(
    J: ?*js_State,
    name: [*c]const u8
) void;

// Push values to stack
pub extern fn js_pushstring(J: ?*js_State, s: [*c]const u8) void;
pub extern fn js_pushnumber(J: ?*js_State, n: f64) void;
pub extern fn js_pushboolean(J: ?*js_State, v: c_int) void;

// Error handling
pub extern fn js_trystring(
    J: ?*js_State,
    idx: c_int,
    def: [*c]const u8
) [*c]const u8;
```

## Supported Features

### ES5.1 Standard

mujs implements the **ECMAScript 5.1** standard completely.

**Supported:**

- ✅ **Variables:** `var`, function scope
- ✅ **Primitives:** strings, numbers, booleans, null, undefined
- ✅ **Objects:** property access, nested objects
- ✅ **Arrays:** literals, indexing, methods
- ✅ **Functions:** declarations, expressions, closures
- ✅ **Operators:** all arithmetic, logical, comparison, ternary
- ✅ **Control flow:** if/else, for, while, do-while, switch
- ✅ **Built-ins:** Object, Array, String, Number, Math, JSON, Date
- ✅ **Methods:** All ES5.1 string/array/object methods
- ✅ **Regular expressions:** Full regex support
- ✅ **Exceptions:** try/catch/finally

**Not Supported (ES6+):**

- ❌ `let`, `const` (use `var`)
- ❌ Arrow functions (use `function`)
- ❌ Template literals (use string concatenation)
- ❌ Classes (use prototypes)
- ❌ Promises/async/await
- ❌ Modules (import/export)
- ❌ Destructuring
- ❌ Spread operator

### Template-Relevant Features

**What matters for templates:**

```javascript
// ✅ String operations
name.toUpperCase()
email.toLowerCase()
text.replace('foo', 'bar')
text.split(' ').join('-')

// ✅ Arithmetic
age + 1
count * 2
(a + b) / 2

// ✅ Object access
user.name
user.profile.email
settings.theme.color

// ✅ Array access
items[0]
items[items.length - 1]
items.length

// ✅ Array methods
items.join(', ')
items.slice(0, 3)
numbers.map(function(x) { return x * 2; })

// ✅ Ternary operators
age >= 18 ? 'Adult' : 'Minor'
isActive ? 'Yes' : 'No'

// ✅ Logical operators
isLoggedIn && isPremium
isAdmin || isModerator

// ✅ Math functions
Math.max(10, 20)
Math.floor(Math.random() * 100)
Math.round(price * 1.1)

// ✅ JSON parsing (from --vars)
JSON.parse('{"name":"Alice"}')
```

**What's NOT needed for templates:**

```javascript
// ❌ Not needed
const items = [1, 2, 3];           // Just use var
const double = x => x * 2;         // Use function(x) { return x * 2; }
const msg = `Hello ${name}`;       // Use "Hello " + name
class User { ... }                 // Prototypes work fine
await fetch(url);                  // Templates are synchronous
```

For template engines, **ES5.1 is completely sufficient**.

## Variable Injection

### From CLI

**Simple variables:**
```bash
zpug template.zpug --var name=Alice --var age=30
```

Injects into mujs:
```javascript
var name = "Alice";
var age = 30;
```

**Arrays:**
```bash
zpug template.zpug --array items=apple,banana,orange
```

Injects:
```javascript
var items = ["apple", "banana", "orange"];
```

**JSON variables:**
```bash
zpug template.zpug --vars data.json
```

**data.json:**
```json
{
  "user": {"name": "Alice", "age": 30},
  "items": ["a", "b", "c"]
}
```

Injects:
```javascript
var user = {"name": "Alice", "age": 30};
var items = ["a", "b", "c"];
```

### From Node.js API

```javascript
const { PugCompiler } = require('zig-pug');

const compiler = new PugCompiler();

// String
compiler.setString('name', 'Alice');
// → var name = "Alice";

// Number
compiler.setNumber('age', 30);
// → var age = 30;

// Boolean
compiler.setBool('active', true);
// → var active = true;

// Array
compiler.setArray('items', ['a', 'b', 'c']);
// → var items = ["a", "b", "c"];

// Object
compiler.setObject('user', { name: 'Alice', age: 30 });
// → var user = {"name": "Alice", "age": 30};
```

### From Zig API

```zig
var runtime = try JsRuntime.init(allocator);

// Set string
try runtime.setString("name", "Alice");

// Set number
try runtime.setNumber("age", 30);

// Set boolean
try runtime.setBool("active", true);

// Set via eval (for complex values)
_ = try runtime.eval("var items = ['a', 'b', 'c']");
_ = try runtime.eval("var user = {name: 'Alice', age: 30}");
```

## Expression Evaluation

### How Evaluation Works

**Template:**
```pug
p Hello #{name.toUpperCase()}!
```

**Process:**

1. **Tokenizer** extracts: `EscapedInterpol("name.toUpperCase()")`
2. **Parser** creates: `Interpolation { expression: "name.toUpperCase()", is_unescaped: false }`
3. **Compiler** calls: `runtime.eval("name.toUpperCase()")`
4. **mujs** executes:
   ```javascript
   // Context has: var name = "Alice";
   name.toUpperCase()  // → "ALICE"
   ```
5. **mujs** returns: `"ALICE"`
6. **Compiler** escapes: `escapeHtml("ALICE")` → `"ALICE"` (no changes needed)
7. **Compiler** inserts: `<p>Hello ALICE!</p>`

### Evaluation Context

Each compilation has its own mujs state with all variables set:

```pug
- var greeting = "Hello"
- var name = "World"
p #{greeting + " " + name}!
```

mujs context:
```javascript
var greeting = "Hello";
var name = "World";
```

Evaluation of `#{greeting + " " + name}`:
```javascript
greeting + " " + name  // → "Hello World"
```

### Error Handling

**Invalid expression:**
```pug
p #{nonExistentVariable}
```

mujs throws:
```
ReferenceError: identifier 'nonExistentVariable' not defined
```

Compiler catches and reports:
```
Error at line 1, column 3:
ReferenceError: identifier 'nonExistentVariable' not defined
Hint: Make sure variable is set before use
```

## Limitations

### ES6+ Features Not Available

**No arrow functions:**
```pug
// ❌ Wrong (ES6)
each item in items.map(x => x * 2)

// ✅ Correct (ES5.1)
each item in items.map(function(x) { return x * 2; })
```

**No template literals:**
```pug
// ❌ Wrong (ES6)
p #{`Hello ${name}`}

// ✅ Correct (ES5.1)
p #{"Hello " + name}
```

**No let/const:**
```pug
// ❌ Wrong (ES6)
- const PI = 3.14

// ✅ Correct (ES5.1)
- var PI = 3.14
```

### Synchronous Only

mujs does not support asynchronous operations:

```javascript
// ❌ Not available
await fetch(url)
Promise.resolve()
setTimeout(fn, 100)
```

**Why this doesn't matter:** Templates are compiled synchronously. All data should be prepared before compilation.

### No DOM API

mujs does not provide browser APIs:

```javascript
// ❌ Not available
document.getElementById()
window.location
localStorage.getItem()
```

**Why this doesn't matter:** Templates compile to static HTML. Client-side JavaScript is separate.

## Performance

### Benchmarks

**Simple expressions:**
```
Expression: name.toUpperCase()
Evaluations: 100,000
Time: ~150ms
Rate: ~666,000 ops/sec
```

**Complex expressions:**
```
Expression: items.map(function(x) { return x * 2; }).join(', ')
Evaluations: 10,000
Time: ~180ms
Rate: ~55,000 ops/sec
```

**Object access:**
```
Expression: user.profile.settings.theme.color
Evaluations: 100,000
Time: ~120ms
Rate: ~833,000 ops/sec
```

### Optimization Tips

1. **Precompute expensive operations:**
   ```javascript
   // ❌ Slow (recalculates every time)
   p Total: #{items.reduce(function(sum, x) { return sum + x; }, 0)}

   // ✅ Fast (precomputed)
   - var total = items.reduce(function(sum, x) { return sum + x; }, 0)
   p Total: #{total}
   ```

2. **Avoid nested loops in expressions:**
   ```pug
   // ❌ Slow
   p Count: #{users.map(function(u) { return u.posts.length; }).reduce(function(a,b) { return a+b; })}

   // ✅ Fast (move to unbuffered code)
   - var postCount = users.map(function(u) { return u.posts.length; }).reduce(function(a,b) { return a+b; })
   p Count: #{postCount}
   ```

3. **Reuse runtime context:**
   ```javascript
   // Node.js API
   const compiler = new PugCompiler();
   compiler.setVariables(data);  // Set once

   // Compile multiple templates with same context
   const html1 = compiler.compile(template1);
   const html2 = compiler.compile(template2);
   ```

## Advanced Usage

### Custom JavaScript Functions

Inject custom functions into the runtime:

**CLI approach (via unbuffered code):**
```pug
- function formatCurrency(amount) { return "$" + amount.toFixed(2); }
p Price: #{formatCurrency(19.99)}
```

**Zig API approach:**
```zig
// Inject custom function
_ = try runtime.eval(
    \\function formatDate(date) {
    \\  return new Date(date).toLocaleDateString();
    \\}
);

// Use in template
const template = "p Date: #{formatDate(timestamp)}";
```

### Working with JSON Data

**Parse JSON strings:**
```pug
- var data = JSON.parse('{"name": "Alice", "age": 30}')
p Name: #{data.name}
p Age: #{data.age}
```

**Stringify objects:**
```pug
- var user = {name: "Alice", age: 30}
script.
  var userData = #{JSON.stringify(user)};
```

### Regular Expressions

```pug
- var email = "alice@example.com"
- var username = email.replace(/@.*$/, '')
p Username: #{username}
```

### Date Manipulation

```pug
- var now = new Date()
- var year = now.getFullYear()
p Copyright © #{year}

- var timestamp = 1609459200000
- var date = new Date(timestamp)
p Date: #{date.toLocaleDateString()}
```

### Math Operations

```pug
- var prices = [19.99, 29.99, 39.99]
- var total = prices.reduce(function(sum, p) { return sum + p; }, 0)
- var average = total / prices.length
- var tax = total * 0.1

p Subtotal: $#{total.toFixed(2)}
p Tax: $#{tax.toFixed(2)}
p Total: $#{(total + tax).toFixed(2)}
p Average: $#{average.toFixed(2)}
```

## See Also

- [GETTING-STARTED.md](GETTING-STARTED.md) - Getting started guide
- [PUG-SYNTAX.md](PUG-SYNTAX.md) - Complete syntax reference
- [ARCHITECTURE.md](ARCHITECTURE.md) - Architecture documentation
- [compiler.md](compiler.md) - Compiler internals
- [mujs documentation](https://mujs.com/docs/) - Official mujs docs

## External Resources

- **mujs website:** https://mujs.com/
- **ES5.1 specification:** https://262.ecma-international.org/5.1/
- **Artifex (mujs creators):** https://artifex.com/
- **MuPDF (uses mujs):** https://mupdf.com/
