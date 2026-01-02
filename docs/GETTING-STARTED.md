# Getting Started with zig-pug

Complete guide to get started with zig-pug, from installation to your first template.

## Table of Contents

- [What is zig-pug?](#what-is-zig-pug)
- [Installation](#installation)
- [Your First Template](#your-first-template)
- [Understanding Pug Syntax](#understanding-pug-syntax)
- [Working with Variables](#working-with-variables)
- [Next Steps](#next-steps)

## What is zig-pug?

zig-pug is a high-performance template engine inspired by [Pug](https://pugjs.org/), implemented in Zig with full JavaScript support. It compiles Pug templates to HTML with:

- **Clean, indentation-based syntax** - No closing tags needed
- **JavaScript expressions** - Full ES5.1 support via embedded mujs engine
- **Native performance** - Written in Zig, compiled to machine code
- **Multiple interfaces** - CLI, Node.js addon, C API, C++ API

## Installation

### Prerequisites

**For CLI usage:**
- Zig 0.15.2 ([download](https://ziglang.org/download/))
- Git

**For Node.js usage:**
- Node.js >= 14.0.0
- C/C++ compiler (GCC, Clang, or MSVC)
- Python (for node-gyp)

### Install CLI (from source)

```bash
# Clone repository
git clone https://github.com/carlos-sweb/zig-pug
cd zig-pug

# Build
zig build

# Test
./zig-out/bin/zpug examples/01-basic.zpug

# Install system-wide (optional)
make install
```

### Install Node.js Addon

```bash
npm install zig-pug
```

The native addon compiles automatically during installation.

### Verify Installation

**CLI:**
```bash
zpug --version
# zig-pug 0.4.0
```

**Node.js:**
```javascript
const zigpug = require('zig-pug');
console.log(zigpug.version());
// 0.4.0
```

## Your First Template

### Step 1: Create a Template

Create a file named `hello.zpug`:

```pug
doctype html
html(lang="en")
  head
    title Hello World
  body
    h1 Welcome to zig-pug!
    p This is your first template.
```

### Step 2: Compile with CLI

```bash
zpug hello.zpug
```

Output:
```html
<!DOCTYPE html><html lang="en"><head><title>Hello World</title></head><body><h1>Welcome to zig-pug!</h1><p>This is your first template.</p></body></html>
```

### Step 3: Format for Readability

```bash
zpug -F hello.zpug
```

Output (formatted):
```html
<!DOCTYPE html>
<html lang="en">
  <head>
    <title>Hello World</title>
  </head>
  <body>
    <h1>Welcome to zig-pug!</h1>
    <p>This is your first template.</p>
  </body>
</html>
```

### Step 4: Save to File

```bash
zpug -F hello.zpug -o hello.html
```

## Understanding Pug Syntax

### Indentation is Structure

Pug uses **indentation** (spaces only, no tabs) to define HTML nesting:

```pug
div
  h1 Title
  p Paragraph 1
  p Paragraph 2
```

Becomes:
```html
<div>
  <h1>Title</h1>
  <p>Paragraph 1</p>
  <p>Paragraph 2</p>
</div>
```

**Rules:**
- Use spaces for indentation (2 or 4 spaces recommended)
- Tabs cause errors
- Child elements must be indented

### Tags and Text

```pug
h1 This is a heading
p This is a paragraph
span This is inline text
```

### Attributes

```pug
a(href="https://ziglang.org" target="_blank") Zig Website
input(type="email" name="email" required)
img(src="logo.png" alt="Logo")
```

### Classes and IDs

```pug
// Class shorthand
div.container
p.text.highlighted

// ID shorthand
div#header
section#main-content

// Combined
div.container#app
h1.title.primary#page-title

// Implicit divs (NEW in v4.0.0!)
.wrapper        // <div class="wrapper">
#header         // <div id="header">
```

### Comments

```pug
//! Documentation comment (ignored completely)
//! Author: John Doe

doctype html
html
  body
    // Buffered comment (appears with --pretty)
    // Visible in development mode

    //- Unbuffered comment (never in output)
    //- This is for developers only

    p Content here
```

## Working with Variables

### Using CLI Variables

**Simple variables:**
```bash
zpug template.zpug --var name=Alice --var age=25
```

**Template:**
```pug
p Hello #{name}!
p You are #{age} years old.
```

**Arrays:**
```bash
zpug template.zpug --array items=apple,banana,orange
```

**Template:**
```pug
ul
  each item in items
    li= item
```

**JSON file:**
```bash
zpug template.zpug --vars data.json
```

**data.json:**
```json
{
  "title": "My Page",
  "user": {
    "name": "Alice",
    "age": 30
  },
  "items": ["apple", "banana", "orange"]
}
```

**Template:**
```pug
h1= title
p User: #{user.name}
p Age: #{user.age}
ul
  each item in items
    li= item
```

### Using Node.js API

**Simple variables:**
```javascript
const zigpug = require('zig-pug');

const html = zigpug.compile(
  'p Hello #{name}!',
  { name: 'Alice' }
);
```

**Objects and arrays:**
```javascript
const html = zigpug.compile(`
div
  h1= user.name
  p Age: #{user.age}
  ul
    each item in items
      li= item
`, {
  user: { name: 'Alice', age: 30 },
  items: ['apple', 'banana', 'orange']
});
```

**Using PugCompiler class:**
```javascript
const { PugCompiler } = require('zig-pug');

const compiler = new PugCompiler();
compiler
  .setString('name', 'Alice')
  .setNumber('age', 30)
  .setBool('active', true)
  .setArray('items', ['a', 'b', 'c'])
  .setObject('user', { id: 1, name: 'Alice' });

const html = compiler.compile('p Hello #{name}!');
```

## JavaScript Expressions

zig-pug supports **ES5.1 JavaScript** via the embedded mujs engine.

### Simple Interpolation

```pug
p Hello #{name}!
p Age: #{age}
p Active: #{isActive}
```

### String Methods

```pug
p #{name.toUpperCase()}
p #{email.toLowerCase()}
p #{text.split(' ').join('-')}
```

### Arithmetic

```pug
p Next year: #{age + 1}
p Double: #{count * 2}
p Average: #{(a + b) / 2}
```

### Object Access

```pug
p Name: #{user.name}
p Email: #{user.profile.email}
```

### Array Access

```pug
p First: #{items[0]}
p Last: #{items[items.length - 1]}
p Count: #{items.length}
```

### Ternary Operators

```pug
p Status: #{age >= 18 ? 'Adult' : 'Minor'}
p Access: #{isAdmin ? 'Granted' : 'Denied'}
```

### Math Functions

```pug
p Max: #{Math.max(10, 20, 30)}
p Random: #{Math.floor(Math.random() * 100)}
p PI: #{Math.PI.toFixed(2)}
```

## Common Patterns

### Page Layout

```pug
doctype html
html(lang="en")
  head
    meta(charset="UTF-8")
    meta(name="viewport" content="width=device-width, initial-scale=1.0")
    title #{pageTitle}
  body
    header
      h1= siteName
      nav
        a(href="/") Home
        a(href="/about") About

    main
      block content

    footer
      p © 2025 #{siteName}
```

### Conditional Content

```pug
if isLoggedIn
  p Welcome back, #{userName}!
  a(href="/logout") Logout
else
  p Please log in
  a(href="/login") Login
```

### Loops

```pug
ul.user-list
  each user in users
    li
      strong= user.name
      span Age: #{user.age}
```

### Mixins (Reusable Components)

```pug
mixin button(text, type)
  button(class="btn btn-" + type)= text

+button("Submit", "primary")
+button("Cancel", "secondary")
```

## Output Modes

zig-pug supports different output formats:

### Production (Default - Minified)

```bash
zpug template.zpug -o output.html
```

Smallest file size, no whitespace.

### Development (Pretty with Comments)

```bash
zpug -p template.zpug -o output.html
```

Indented, includes buffered comments (`//`).

### Readable (Format without Comments)

```bash
zpug -F template.zpug -o output.html
```

Indented, excludes all comments.

### Explicit Minification

```bash
zpug -m template.zpug -o output.html
```

Force minification (same as default).

## Next Steps

Now that you understand the basics:

1. **Learn more syntax:**
   - [PUG-SYNTAX.md](PUG-SYNTAX.md) - Complete syntax reference
   - [docs/en/CLI.md](en/CLI.md) - CLI documentation

2. **Integrate with Node.js:**
   - [NODEJS-INTEGRATION.md](NODEJS-INTEGRATION.md) - Node.js/Bun integration
   - [nodejs/README.md](../nodejs/README.md) - API reference

3. **Understand the internals:**
   - [ARCHITECTURE.md](ARCHITECTURE.md) - How zig-pug works
   - [tokenizer.md](tokenizer.md) - Lexical analysis
   - [parser.md](parser.md) - Syntax analysis
   - [compiler.md](compiler.md) - HTML generation

4. **Try examples:**
   - Browse [examples/](../examples/) directory
   - Run: `zpug examples/01-basic.zpug`

5. **Advanced features:**
   - [MUJS-INTEGRATION.md](MUJS-INTEGRATION.md) - JavaScript runtime
   - [c-api.md](c-api.md) - C/C++ API
   - [en/LOOPS-INCLUDES-CACHE.md](en/LOOPS-INCLUDES-CACHE.md) - Advanced features

## Troubleshooting

### "Command not found: zpug"

**Solution:** Add to PATH or use full path:
```bash
./zig-out/bin/zpug template.zpug
```

Or install system-wide:
```bash
make install
```

### "InvalidIndentation" error

**Cause:** Mixed tabs and spaces, or inconsistent indentation.

**Solution:** Use only spaces (2 or 4 per level):
```pug
div
  p Correct (2 spaces)
  p Correct (2 spaces)
```

### "Unexpected character" in interpolation

**Cause:** Unsupported ES6+ syntax.

**Solution:** Use ES5.1 syntax:
```pug
// ❌ Wrong (ES6)
p #{`Hello ${name}`}

// ✅ Correct (ES5.1)
p #{"Hello " + name}
```

### Variables not interpolating

**Cause:** Variable not set in runtime.

**Solution:** Pass variables via CLI or API:
```bash
zpug template.zpug --var name=Alice
```

```javascript
zigpug.compile(template, { name: 'Alice' });
```

## Getting Help

- **Documentation:** [docs/](../docs/)
- **Examples:** [examples/](../examples/)
- **Issues:** [GitHub Issues](https://github.com/carlos-sweb/zig-pug/issues)
- **Contributing:** [CONTRIBUTING.md](../CONTRIBUTING.md)

## Quick Reference Card

```pug
// Tags
div
p Text here
h1= variable

// Classes & IDs
.container          // <div class="container">
#header             // <div id="header">
p.text#main         // <p class="text" id="main">

// Attributes
a(href="/") Link
input(type="text" required)

// Interpolation
p Hello #{name}!
p Age: #{age + 1}

// Conditionals
if condition
  p True
else
  p False

// Loops
each item in items
  li= item

// Mixins
mixin box(title)
  div.box
    h3= title

+box("My Title")

// Comments
//! Documentation (ignored)
// Buffered (in --pretty)
//- Unbuffered (never in output)
```

Happy templating with zig-pug! 🚀
