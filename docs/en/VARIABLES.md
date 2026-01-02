# Working with Variables

Complete guide to variable handling in zig-pug templates.

## Table of Contents

- [Variable Sources](#variable-sources)
- [CLI Variables](#cli-variables)
- [Node.js API Variables](#nodejs-api-variables)
- [Template Variables](#template-variables)
- [Data Types](#data-types)
- [Scope Rules](#scope-rules)
- [Best Practices](#best-practices)

## Variable Sources

Variables can come from three sources:

1. **CLI flags** - `--var`, `--array`, `--vars`
2. **Node.js API** - `compile(template, data)` or `PugCompiler` methods
3. **Template code** - Unbuffered code (`-`)

All variables are available in the JavaScript runtime (mujs).

## CLI Variables

### Simple Variables

**Syntax:**
```bash
zpug template.zpug --var name=value
```

**Example:**
```bash
zpug template.zpug --var name=Alice --var age=30 --var active=true
```

**Template:**
```pug
p Name: #{name}
p Age: #{age}
p Active: #{active}
```

**Output:**
```html
<p>Name: Alice</p>
<p>Age: 30</p>
<p>Active: true</p>
```

### Array Variables

**Syntax:**
```bash
zpug template.zpug --array name=value1,value2,value3
```

**Example:**
```bash
zpug template.zpug --array items=apple,banana,orange --array scores=95,87,92
```

**Template:**
```pug
ul
  each item in items
    li= item

p Scores: #{scores.join(", ")}
```

**Output:**
```html
<ul>
  <li>apple</li>
  <li>banana</li>
  <li>orange</li>
</ul>
<p>Scores: 95, 87, 92</p>
```

### JSON Variables (Inline)

**Syntax:**
```bash
zpug template.zpug --json 'name={"key":"value"}'
```

**Example:**
```bash
zpug template.zpug --json 'user={"name":"Alice","age":30,"role":"admin"}'
```

**Template:**
```pug
p Name: #{user.name}
p Age: #{user.age}
p Role: #{user.role}
```

**Output:**
```html
<p>Name: Alice</p>
<p>Age: 30</p>
<p>Role: admin</p>
```

### JSON Variables (File)

**Syntax:**
```bash
zpug template.zpug --vars data.json
```

**data.json:**
```json
{
  "title": "My Page",
  "user": {
    "name": "Alice",
    "age": 30,
    "email": "alice@example.com"
  },
  "items": ["apple", "banana", "orange"],
  "settings": {
    "theme": "dark",
    "lang": "en"
  }
}
```

**Template:**
```pug
doctype html
html(lang=settings.lang)
  head
    title= title
  body
    h1 Welcome #{user.name}!
    p Email: #{user.email}
    ul
      each item in items
        li= item
```

### Combining Variable Sources

```bash
zpug template.zpug \
  --var siteName="My Site" \
  --array tags=prod,stable \
  --json 'user={"name":"Alice"}' \
  --vars config.json
```

All variables are merged into the JavaScript runtime.

## Node.js API Variables

### Simple Compilation

```javascript
const zigpug = require('zig-pug');

const html = zigpug.compile(
  'p Hello #{name}!',
  {
    name: 'Alice',
    age: 30,
    active: true
  }
);
```

### File Compilation

```javascript
const { compileFile } = require('zig-pug');

const html = compileFile('./template.pug', {
  title: 'My Page',
  user: { name: 'Alice', age: 30 },
  items: ['a', 'b', 'c']
});
```

### PugCompiler Class

```javascript
const { PugCompiler } = require('zig-pug');

const compiler = new PugCompiler();

// Set individual variables
compiler.setString('name', 'Alice');
compiler.setNumber('age', 30);
compiler.setBool('active', true);
compiler.setArray('items', ['a', 'b', 'c']);
compiler.setObject('user', { name: 'Alice', age: 30 });

// Or set multiple at once
compiler.setVariables({
  name: 'Alice',
  age: 30,
  active: true
});

const html = compiler.compile(template);
```

### Auto-Detection

The `set()` method auto-detects type:

```javascript
compiler.set('name', 'Alice');        // String
compiler.set('age', 30);              // Number
compiler.set('active', true);         // Boolean
compiler.set('items', [1, 2, 3]);     // Array
compiler.set('user', {name: 'Bob'});  // Object
```

## Template Variables

### Unbuffered Code

Define variables in templates using `-`:

```pug
- var greeting = "Hello"
- var name = "World"
- var message = greeting + " " + name

p= message
```

**Output:**
```html
<p>Hello World</p>
```

### Variable Assignment

```pug
- var count = 0
- count = 1
- count++
- count += 10

p Count: #{count}  // Count: 12
```

### Complex Data Structures

```pug
- var user = {
-   name: "Alice",
-   age: 30,
-   profile: {
-     email: "alice@example.com",
-     avatar: "/images/alice.jpg"
-   }
- }

- var items = [
-   {name: "Item 1", price: 10},
-   {name: "Item 2", price: 20},
-   {name: "Item 3", price: 30}
- ]
```

## Data Types

### Strings

**CLI:**
```bash
zpug template.zpug --var name=Alice --var quote="Hello World"
```

**Node.js:**
```javascript
compiler.setString('name', 'Alice');
compiler.set('name', 'Alice');  // Auto-detect
```

**Template:**
```pug
- var text = "Hello"
p= text
```

### Numbers

**CLI:**
```bash
zpug template.zpug --var age=30 --var price=19.99
```

**Node.js:**
```javascript
compiler.setNumber('age', 30);
compiler.set('age', 30);  // Auto-detect
```

**Template:**
```pug
- var count = 42
- var price = 19.99
p Count: #{count}
p Price: $#{price.toFixed(2)}
```

### Booleans

**CLI:**
```bash
zpug template.zpug --var active=true --var disabled=false
```

**Node.js:**
```javascript
compiler.setBool('active', true);
compiler.set('active', true);  // Auto-detect
```

**Template:**
```pug
- var isActive = true
if isActive
  p Active
```

### Arrays

**CLI:**
```bash
zpug template.zpug --array items=apple,banana,orange
```

**Node.js:**
```javascript
compiler.setArray('items', ['apple', 'banana', 'orange']);
compiler.set('items', ['apple', 'banana', 'orange']);  // Auto-detect
```

**Template:**
```pug
- var fruits = ["apple", "banana", "orange"]
ul
  each fruit in fruits
    li= fruit
```

### Objects

**CLI:**
```bash
zpug template.zpug --json 'user={"name":"Alice","age":30}'
```

**Node.js:**
```javascript
compiler.setObject('user', { name: 'Alice', age: 30 });
compiler.set('user', { name: 'Alice', age: 30 });  // Auto-detect
```

**Template:**
```pug
- var user = {name: "Alice", age: 30}
p Name: #{user.name}
p Age: #{user.age}
```

### Null and Undefined

```pug
- var nothing = null
- var undef = undefined

if nothing == null
  p Nothing is null

if typeof undef == "undefined"
  p Undef is undefined
```

## Scope Rules

### Global Scope

Variables defined at the root level are globally accessible:

```pug
- var global = "I'm global"

div
  p #{global}  // ✅ Works

  div
    p #{global}  // ✅ Works
```

### Function Scope

Variables defined in conditionals/loops are function-scoped (ES5.1):

```pug
- var outer = "outer"

if true
  - var inner = "inner"
  p #{outer}  // ✅ Works
  p #{inner}  // ✅ Works

p #{outer}  // ✅ Works
p #{inner}  // ✅ Works (ES5.1 - function scope, not block scope!)
```

**Note:** ES5.1 has function scope, not block scope. Variables defined in `if` blocks leak out.

### Shadowing

```pug
- var name = "Alice"

div
  - var name = "Bob"
  p #{name}  // Bob

p #{name}  // Bob (shadowed the outer variable)
```

**Note:** This shadows the outer variable permanently in ES5.1.

### Mixin Scope

Mixin parameters are local to the mixin:

```pug
mixin greeting(name)
  p Hello #{name}!

- var name = "Alice"
+greeting("Bob")
p #{name}  // Alice (mixin parameter doesn't affect outer variable)
```

## Best Practices

### 1. Provide Defaults

**CLI:**
```bash
# Use template defaults if not provided
zpug template.zpug
```

**Template:**
```pug
- var title = title || "Default Title"
- var description = description || "No description"

h1= title
p= description
```

### 2. Validate Inputs

```pug
- if (!user) throw new Error("user is required")
- if (!user.name) throw new Error("user.name is required")

p Welcome #{user.name}!
```

### 3. Type Checking

```pug
- if (typeof age != "number") throw new Error("age must be a number")
- if (!Array.isArray(items)) throw new Error("items must be an array")
```

### 4. Normalize Data

```pug
- items = items || []
- user = user || {}
- title = (title || "").trim()

h1= title || "Untitled"

each item in items
  p= item
else
  p No items
```

### 5. Document Expected Variables

```pug
//! Expected variables:
//!   - title: string (required)
//!   - description: string (optional)
//!   - user: object {name, email} (required)
//!   - items: array (optional, default: [])

- title = title || ""
- description = description || "No description"
- items = items || []

if (!user || !user.name) throw new Error("user.name is required")
```

### 6. Use Descriptive Names

**❌ Bad:**
```pug
- var a = "Alice"
- var x = 30
- var f = true
```

**✅ Good:**
```pug
- var userName = "Alice"
- var userAge = 30
- var isActive = true
```

### 7. Group Related Variables

```pug
- var config = {
-   siteName: "My Site",
-   siteUrl: "https://example.com",
-   theme: "dark",
-   lang: "en"
- }

html(lang=config.lang)
  head
    title= config.siteName
```

### 8. Avoid Magic Numbers

**❌ Bad:**
```pug
p Discount: #{price * 0.1}
```

**✅ Good:**
```pug
- var DISCOUNT_RATE = 0.1
p Discount: #{price * DISCOUNT_RATE}
```

## Common Patterns

### Configuration Object

```javascript
// Node.js
const config = {
  site: {
    name: 'My Site',
    url: 'https://example.com'
  },
  user: {
    name: 'Alice',
    role: 'admin'
  },
  features: {
    darkMode: true,
    notifications: false
  }
};

compiler.setObject('config', config);
```

```pug
// Template
doctype html
html
  head
    title= config.site.name
  body
    if config.features.darkMode
      .dark-mode
        p Welcome #{config.user.name}!
```

### Environment Variables

```javascript
// Node.js
compiler.setVariables({
  isDevelopment: process.env.NODE_ENV === 'development',
  isProduction: process.env.NODE_ENV === 'production',
  apiUrl: process.env.API_URL || 'http://localhost:3000'
});
```

```pug
// Template
if isDevelopment
  script(src="/js/debug.js")

if isProduction
  script(src="/js/analytics.js")
```

### Conditional Defaults

```pug
- var theme = theme || (isDarkMode ? "dark" : "light")
- var pageSize = pageSize || (isMobile ? 10 : 20)
```

### Array Transformations

```pug
- var items = items || []
- var activeItems = items.filter(function(item) { return item.active; })
- var sortedItems = items.sort(function(a, b) { return a.name.localeCompare(b.name); })
```

## Troubleshooting

### Variable Not Found

**Error:**
```
ReferenceError: identifier 'userName' not defined
```

**Solution:**
1. Check variable name spelling
2. Ensure variable is set before use
3. Provide default value

```pug
- var userName = userName || "Guest"
```

### Type Errors

**Error:**
```
TypeError: Cannot read property 'name' of undefined
```

**Solution:**
```pug
- var name = user && user.name ? user.name : "Unknown"
```

Or:
```pug
- if (!user) throw new Error("user is required")
p Name: #{user.name}
```

### Array Methods on Non-Arrays

**Error:**
```
TypeError: items.forEach is not a function
```

**Solution:**
```pug
- items = Array.isArray(items) ? items : []
each item in items
  p= item
```

## See Also

- [JAVASCRIPT.md](JAVASCRIPT.md) - JavaScript in templates
- [CONDITIONALS-LOOPS.md](CONDITIONALS-LOOPS.md) - Control flow
- [../GETTING-STARTED.md](../GETTING-STARTED.md) - Getting started guide
- [CLI.md](CLI.md) - CLI variable flags
