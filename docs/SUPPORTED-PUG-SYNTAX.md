# Supported Pug Syntax

Complete reference for all Pug template syntax supported by zig-pug.

---

## Doctype

```zpug
doctype html
// Output: <!DOCTYPE html>

doctype xml
// Output: <!DOCTYPE xml>
```

---

## Tags and Attributes

```zpug
// Simple tags
div
p Hello
span World

// Multiple classes (concatenated)
div.box.highlight.active
// Output: <div class="box highlight active">

// Classes and IDs
div.container
p#main-text
button.btn.btn-primary#submit

// Implicit divs (NEW in v4.0.0!)
.wrapper                    // <div class="wrapper">
#header                     // <div id="header">
(data-role="main")          // <div data-role="main">
#app.container(data-v="2")  // <div id="app" class="container" data-v="2">

// Attributes (static)
a(href="https://example.com" target="_blank") Link
input(type="text" name="username" required)

// Attributes (dynamic expressions)
- var myClass = "active"
- var myUrl = "/home"
button(class=myClass) Click
a(href=myUrl) Link
// Output: <button class="active">Click</button>

// Complex expressions (v4.0.0+)
- var alertType = "success"
- var userId = 42
div(class="alert alert-"+alertType)
div(id="user-"+userId)
// Output: <div class="alert alert-success">
//         <div id="user-42">

// Operators: +, -, ., [], <, >
a(href=user.profile.url) Profile
div(data-first=items[0]) First Item

// Multiple lines
div(
  class="card"
  id="user-card"
  data-user-id="123"
)
```

---

## Buffered and Unbuffered Code

```zpug
// Unbuffered code (executes but doesn't output)
- var name = "Alice"
- var age = 30
- var doubled = age * 2

// Buffered code inline (tag= syntax)
p= name
// Output: <p>Alice</p>

h1= name.toUpperCase()
// Output: <h1>ALICE</h1>

// Unescaped buffered code (tag!=)
- var html = "<strong>Bold</strong>"
div= html
// Output: <div>&lt;strong&gt;Bold&lt;/strong&gt;</div>

div!= html
// Output: <div><strong>Bold</strong></div>
```

---

## JavaScript Interpolation

```zpug
// Simple variables
p Hello #{name}

// String methods
p #{name.toUpperCase()}
p #{email.toLowerCase()}

// Arithmetic
p Age: #{age}
p Next year: #{age + 1}
p Double: #{age * 2}

// Objects (from JSON)
p Name: #{user.name}
p Email: #{user.email}
p Age: #{user.age}

// Arrays (from JSON)
p First: #{items[0]}
p Count: #{items.length}

// Complex expressions
p Full: #{firstName + ' ' + lastName}
p Status: #{age >= 18 ? 'Adult' : 'Minor'}

// Math
p Max: #{Math.max(10, 20)}
p Random: #{Math.floor(Math.random() * 100)}
```

---

## HTML Escaping (XSS Security)

All interpolations are automatically escaped for security:

```zpug
// Escaped by default (safe)
p #{userInput}
// Input: <script>alert('xss')</script>
// Output: <p>&lt;script&gt;alert(&#39;xss&#39;)&lt;/script&gt;</p>

// Unescaped (for trusted HTML only)
p !{trustedHtml}
// Input: <strong>Bold</strong>
// Output: <p><strong>Bold</strong></p>
```

**Escaped characters:** `&` `<` `>` `"` `'`

**⚠️ Security:** Only use `!{}` with HTML you control. Never with user input.

---

## Conditionals

Full support for `if`, `else`, `else if`, and `unless` with complete JavaScript expressions:

```zpug
// Basic if/else
if isLoggedIn
  p Welcome back!
else
  p Please log in

// Multiple else if (unlimited chaining)
if score > 90
  p Grade A
else if score > 80
  p Grade B
else if score > 70
  p Grade C
else
  p Grade F

// unless (negation)
unless isAdmin
  p Access denied

// Property access
if user.isPremium
  p Premium features enabled
else
  p Upgrade to premium

// Comparison operators (>, <, >=, <=, ==)
if age >= 18
  p Adult content
else if age >= 13
  p Teen content
else
  p Kids content

// Logical operators (&&, ||)
if age >= 18 && hasLicense
  p Can drive
else
  p Cannot drive

// String equality
if status == "active"
  p Account active
else if status == "pending"
  p Pending approval
else
  p Account inactive

// Complex expressions
if (isAdmin || isModerator) && user.isActive
  p Administrative access
else
  p Regular access

// Array length checks
if items.length > 0
  p Cart has #{items.length} items
else
  p Cart is empty

// Nested conditions
if user.isActive
  if user.isPremium
    p Premium active user
  else
    p Regular active user
else
  p Inactive account
```

**Supported features:**
- ✅ Property access: `user.isPremium`, `array.length`
- ✅ Comparison operators: `>`, `<`, `>=`, `<=`, `==`
- ✅ Logical operators: `&&` (AND), `||` (OR)
- ✅ String equality: `status == "active"`
- ✅ Unlimited `else if` chaining
- ✅ Nested conditionals
- ✅ Complex combined expressions

---

## Loops

```zpug
// Each with arrays
each item in items
  li= item

// Each with index
each item, i in items
  li #{i}: #{item}

// Optional chaining in loops (NEW!)
// Safely iterate over properties that may not exist
each tag in product?.tags
  span.tag= tag

// Nested optional chaining
each item in data?.products?.featured
  li= item

// While loops
- var count = 0
while count < 5
  p Count: #{count}
  - count = count + 1
```

**Optional Chaining (`?.`) Features:**
- ✅ **Safe iteration** - No errors if property doesn't exist
- ✅ **Cleaner code** - Eliminates `if hasOwnProperty` checks
- ✅ **Nested support** - Works with `obj?.prop?.nested`
- ✅ **Compile-time transformation** - Converted to ES5.1 for mujs
- ✅ **Perfect for variable schemas** - APIs, e-commerce, user data

**Example - Before vs After:**

```zpug
// Before (verbose)
if product.hasOwnProperty('tags')
  each tag in product.tags
    span= tag

// After (clean)
each tag in product?.tags
  span= tag
```

**How it works:**
When you write `product?.tags`, zig-pug automatically transforms it to:
```javascript
product && product.hasOwnProperty('tags') ? product.tags : []
```

This transformation happens at compile-time, so mujs receives ES5.1-compatible code.

---

## Mixins with Arguments

```zpug
// Define mixin
mixin greeting(name)
  p Hello, #{name}!

mixin button(text, type)
  button(class=type)= text

// Use mixins
+greeting("World")
+greeting("Alice")

+button("Click me", "btn-primary")
+button("Cancel", "btn-secondary")

// Output:
// <p>Hello, World!</p>
// <p>Hello, Alice!</p>
// <button class="btn-primary">Click me</button>
// <button class="btn-secondary">Cancel</button>
```

---

## Template Inheritance (Extends/Block)

Build reusable layouts with template inheritance using `extends` and `block`:

```zpug
// layout.zpug - Base layout
doctype html
html
  head
    title
      block title
        | Default Title
  body
    header
      h1 My Website
    main
      block content
        p Default content
    footer
      block footer
        p © 2024

// page.zpug - Extends layout
extends layout.zpug

block title
  | Home Page

block content
  h2 Welcome
  p This replaces the default block content

// Output:
// <!DOCTYPE html>
// <html>
//   <head><title>Home Page</title></head>
//   <body>
//     <header><h1>My Website</h1></header>
//     <main>
//       <h2>Welcome</h2>
//       <p>This replaces the default block content</p>
//     </main>
//     <footer><p>© 2024</p></footer>
//   </body>
// </html>
```

**Block Modes:**

```zpug
// Replace (default) - Replaces parent block completely
block content
  p New content

// Append - Adds after parent block
block append content
  p Added after default

// Prepend - Adds before parent block
block prepend content
  p Added before default
```

**Path Syntax:**

```zpug
// Unquoted paths (recommended)
extends layout.zpug
extends ../layouts/base.zpug

// Quoted paths
extends "layout.zpug"
extends "../layouts/base.zpug"
```

**See [../examples/extends/](../examples/extends/) for complete working examples.**

---

## Comments

```zpug
//! Documentation comment (completely ignored)
//! Can appear before doctype declarations

// Buffered comment (visible in HTML with --pretty)
// This appears only in development mode

//- Unbuffered comment (never in HTML)
//- This is only in source, never compiled

// Security: Comments are escaped
// Comment with --> injection attempt
// Output: <!-- Comment with - -> injection attempt -->
```

**Comment Types:**

| Syntax | Name | Processed? | In HTML? | Use Case |
|--------|------|------------|----------|----------|
| `//!` | Documentation | ❌ No | ❌ No | File metadata, author notes |
| `//` | Buffered | ✅ Yes | ✅ Yes (--pretty only) | Development debugging |
| `//-` | Unbuffered | ✅ Yes | ❌ No | Code comments |

**Comment Behavior:**

- **Documentation comments (`//!`)**: Completely ignored by tokenizer (can appear before `doctype`)
- **Production mode (default)**: All buffered comments (`//`) are **stripped** for minimal file size
- **Development mode (`--pretty`)**: Buffered comments (`//`) are **included** for debugging
- **Readable mode (`--format`)**: Pretty-print without comments
- **Unbuffered comments (`//-`)**: Always stripped in all modes

```bash
# Production: no comments, minified
zpug template.zpug -o output.html

# Development: with comments and indentation
zpug --pretty template.zpug -o output.html

# Readable: indentation without comments
zpug --format template.zpug -o output.html
```

This matches industry standards (Pug, HTML minifiers) where production output is optimized and development output is readable.

---

## UTF-8 Support

Full Unicode support for international characters in all template elements:

```zpug
doctype html
html(lang="es")
  head
    title Página en Español
  body
    h1 Bienvenido 🎉

    // Spanish
    p.información Este es un párrafo con acentos: José, María, Ángel

    // Portuguese
    p.português Programação em português com ã, õ, ç

    // French
    p.français Génération française avec é, è, ê, ç

    // German
    p#größe Deutsche Größe mit ä, ö, ü, ß

    // Emoji and symbols
    p Symbols: © ™ € £ ¥ • Emoji: 🚀 ✨ 💻 🌍
```

**Supported:**
- ✅ Accented characters in text: `á é í ó ú ñ ü ç`
- ✅ Accented characters in class names: `.información`
- ✅ Accented characters in IDs: `#descripción`
- ✅ Accented characters in comments: `// útil`
- ✅ Emoji and Unicode symbols: `🎉 © ™ €`
- ✅ All UTF-8 sequences (1-4 bytes)

---

## See Also

- [PUG-SYNTAX.md](PUG-SYNTAX.md) - Complete detailed syntax guide
- [en/SYNTAX-BASICS.md](en/SYNTAX-BASICS.md) - Beginner-friendly basics
- [en/SYNTAX-ADVANCED.md](en/SYNTAX-ADVANCED.md) - Advanced features
- [en/CONDITIONALS-LOOPS.md](en/CONDITIONALS-LOOPS.md) - Control flow guide
- [GETTING-STARTED.md](GETTING-STARTED.md) - Quick start tutorial
- [../README.md](../README.md) - Main documentation
