# zig-pug Features

Complete list of all features implemented in zig-pug.

## ✅ Core Template Features

### Tags and Elements

```zpug
// Basic tags
div
p Hello World
span.text Some text

// Nested tags
div
  p First paragraph
  p Second paragraph
```

**Status:** ✅ Fully implemented

---

### Classes and IDs

```zpug
// Single class
div.container

// Multiple classes (concatenated properly)
button.btn.primary.large

// ID
div#main-content

// Combined
div.container#app.main
```

**Status:** ✅ Fully implemented (Phase 1 - Fixed class concatenation)

**Changes:**
- Before: `<div class="btn" class="primary">` (duplicate attributes)
- After: `<div class="btn primary">` (single concatenated attribute)

---

### Attributes

```zpug
// Static attributes
a(href="/home" target="_blank") Link
input(type="text" name="username" required)

// Dynamic attributes (expressions)
button(class=myClass id=myId) Click
div(data-id=userId) Content

// Multiline attributes
div(
  class="card"
  id="user-card"
  data-user-id="123"
)
```

**Status:** ✅ Fully implemented (Phase 2 - Added expression evaluation)

**Features:**
- Static values with quotes: `href="url"`
- Dynamic expressions: `class=variable`
- Automatic HTML escaping for safety

---

### Doctype

```zpug
doctype html
html
  head
    title My Page
```

**Output:**
```html
<!DOCTYPE html><html><head><title>My Page</title></head></html>
```

**Status:** ✅ Fully implemented (Fixed in latest commit)

**Supported doctypes:**
- `doctype html` → `<!DOCTYPE html>`
- `doctype xml` → `<!DOCTYPE xml>`
- Any custom doctype value

---

## 🔄 JavaScript Integration

### Interpolation

```zpug
// Variables
p Hello #{name}

// String methods
p #{name.toUpperCase()}
p #{email.toLowerCase()}

// Arithmetic
p Age: #{age + 1}
p Double: #{count * 2}

// Object properties
p Name: #{user.firstName}
p Email: #{user.email}

// Array access
p First: #{items[0]}
p Length: #{items.length}

// Complex expressions
p Result: #{price * quantity + tax}
p Status: #{age >= 18 ? "Adult" : "Minor"}
```

**Status:** ✅ Fully implemented

**Supported:**
- All ES5.1 JavaScript expressions
- String methods, math operations
- Object property access
- Array indexing
- Ternary operators

---

### Buffered Code

```zpug
// Inline expression after tag
p= name
div= user.email
h1= title.toUpperCase()

// Escaped output
p= userInput  // HTML escaped
div= "<script>alert('xss')</script>"  // Safe

// Unescaped output (trusted HTML only)
div!= trustedHtml
p!= "<strong>Bold</strong>"
```

**Status:** ✅ Fully implemented (Phase 3)

**Output:**
```html
<p>John</p>
<div>&lt;script&gt;alert(&#39;xss&#39;)&lt;/script&gt;</div>
<div><strong>Bold</strong></div>
```

---

### Unbuffered Code

```zpug
// Variable declarations
- var name = "Alice"
- var count = 42
- var items = ["a", "b", "c"]

// Use in interpolation
p Hello #{name}
p Count: #{count}

// Complex operations
- var total = price * quantity
- var discount = total * 0.1
p Final price: #{total - discount}
```

**Status:** ✅ Fully implemented (Phase 2)

**Features:**
- Execute JavaScript without output
- Define variables for later use
- Preserve string quotes properly

---

## 🎛️ Control Flow

### Conditionals

```zpug
// if/else
if isLoggedIn
  p Welcome back!
else
  p Please log in

// unless (negation)
unless hasPermission
  p Access denied

// else if
if age >= 18
  p Adult
else if age >= 13
  p Teenager
else
  p Child

// Expressions
if count > 0
  p Items available
```

**Status:** ✅ Fully implemented

**Features:**
- Full expression evaluation
- Nested conditionals
- unless as if negation

---

### Loops

```zpug
// each with arrays
each item in items
  li= item

// With index
each item, i in items
  li #{i}: #{item}

// While loops
while count < 10
  p= count++
```

**Status:** ✅ Fully implemented (Phase 1 - Fixed iterator parsing)

**Changes:**
- Before: Iterator was always empty
- After: Properly extracts variable names from "each item in items"

---

## 🔧 Reusable Components

### Mixins

```zpug
// Define mixin
mixin button(text, type)
  button(class=type)= text

// Use mixin
+button("Click me", "primary")
+button("Cancel", "secondary")

// Mixin with body
mixin card(title)
  div.card
    h3= title
    block

+card("My Card")
  p Card content here
```

**Status:** ✅ Fully implemented (Phase 1 - Added argument support)

**Features:**
- Parameters with values
- Argument binding to JS runtime
- Rest parameters support
- Nested content with block

---

### Template Inheritance

```zpug
// base.zpug
html
  head
    block head
      title Default Title
  body
    block content

// page.zpug
extends base.zpug

block head
  title My Page

block content
  p Page content
```

**Status:** ✅ Fully implemented

**Features:**
- extends directive
- block definition and override
- append/prepend to blocks

---

### Includes

```zpug
// main.zpug
html
  head
    include partials/head.zpug
  body
    include partials/header.zpug
    div.content
      p Main content
    include partials/footer.zpug
```

**Status:** ✅ Fully implemented

---

## 🔒 Security Features

### HTML Escaping

```zpug
// Automatic escaping (default)
p #{userInput}
// <script> → &lt;script&gt;

// Manual escaping control
p= safeText      // Escaped
p!= trustedHtml  // Not escaped
```

**Status:** ✅ Fully implemented (Phase 3 + Phase 4 optimization)

**Escaped characters:**
- `&` → `&amp;`
- `<` → `&lt;`
- `>` → `&gt;`
- `"` → `&quot;`
- `'` → `&#39;`

**Optimization:** Pre-calculated buffer size for single allocation

---

### Comment Escaping

```zpug
// Buffered comment (visible in HTML)
// This is a comment

// Unbuffered comment (not in HTML)
//- This won't appear

// Injection prevention
// Comment with --> dangerous
```

**Status:** ✅ Fully implemented (Phase 1)

**Security:**
- Escapes `--` to `- -` to prevent premature comment closing
- Prevents `-->` injection attacks

---

## 📦 CLI & Variables

### Command Line Interface

```bash
# Basic usage
zpug template.zpug

# With output file
zpug -i template.zpug -o output.html

# Variables
zpug template.zpug --var name=Alice --var age=25

# JSON file variables
zpug template.zpug --vars data.json

# Pretty print
zpug -p template.zpug

# Minify
zpug -m template.zpug
```

**Status:** ✅ Fully implemented

---

### Variable Types

```bash
# Strings
--var name=Alice

# Numbers
--var age=25 --var price=19.99

# Booleans
--var active=true --var disabled=false

# Arrays (JSON file)
{
  "items": ["apple", "banana", "orange"]
}

# Objects (JSON file)
{
  "user": {
    "name": "Alice",
    "age": 30,
    "email": "alice@example.com"
  }
}
```

**Status:** ✅ Fully implemented (Phase 2)

**Features:**
- String, number, boolean primitives
- JSON arrays with iteration support
- JSON objects with property access
- Automatic type detection

---

## ⚡ Performance

### Optimizations

**HTML Escaping:**
- Pre-calculated buffer size
- Single allocation instead of multiple
- AssumeCapacity methods

**JS Code Generation:**
- Pre-estimated array/object sizes
- Reduced allocations for arrays and objects
- Efficient string building

**Status:** ✅ Implemented (Phase 4)

**Benchmarks:** Not yet measured

---

## 🧪 Testing

**Test Coverage:**
- 87 unit tests
- All passing ✅
- Coverage: Core features, edge cases, security

**Test Categories:**
- Tokenizer tests
- Parser tests
- Compiler tests
- Runtime tests
- Integration tests

**Status:** ✅ Comprehensive (Phase 5)

---

## 📊 Feature Comparison

| Feature | Status | Phase |
|---------|--------|-------|
| Tags & Attributes | ✅ | Core |
| Classes (multiple) | ✅ | Phase 1 |
| IDs | ✅ | Core |
| Doctype | ✅ | Latest |
| Interpolation | ✅ | Core |
| Code (=, !=, -) | ✅ | Phase 2-3 |
| Conditionals | ✅ | Core |
| Loops | ✅ | Phase 1 |
| Mixins | ✅ | Phase 1 |
| Includes | ✅ | Core |
| Extends/Block | ✅ | Core |
| HTML Escaping | ✅ | Phase 3-4 |
| Attribute Expressions | ✅ | Phase 2 |
| JSON Variables | ✅ | Phase 2 |
| Arrays | ✅ | Phase 2 |
| Objects | ✅ | Phase 3 |
| Error Messages | ✅ | Phase 3 |
| Optimizations | ✅ | Phase 4 |
| 87 Tests | ✅ | Phase 5 |

---

## 🚀 Coming Soon

### Planned Features

- [ ] Watch mode (CLI flag exists but not implemented)
- [ ] Source maps
- [ ] Template cache (implemented but not used in CLI)
- [ ] Prettier HTML output (indentation)

### Under Consideration

- [ ] Filters (pipe syntax)
- [ ] Custom doctypes
- [ ] Async template loading

---

## 📝 Summary

**Production Ready:**
- All core Pug features
- Full JavaScript support (ES5.1)
- Security (XSS prevention)
- Performance optimizations
- 87 comprehensive tests

**Recommended for:**
- Static site generation
- Server-side rendering
- Build tools
- CLI applications
- Node.js/Bun.js projects
