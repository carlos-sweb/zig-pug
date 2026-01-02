# Pug Syntax Reference

Complete reference for the Pug template syntax supported by zig-pug.

## Table of Contents

- [Document Type](#document-type)
- [Tags](#tags)
- [Attributes](#attributes)
- [Classes and IDs](#classes-and-ids)
- [Text Content](#text-content)
- [Interpolation](#interpolation)
- [Code](#code)
- [Comments](#comments)
- [Conditionals](#conditionals)
- [Loops](#loops)
- [Mixins](#mixins)
- [Template Inheritance](#template-inheritance)
- [Includes](#includes)
- [Special Features](#special-features)

## Document Type

### Basic Doctype

```pug
doctype html
```

Output:
```html
<!DOCTYPE html>
```

### XML Doctype

```pug
doctype xml
```

Output:
```html
<?xml version="1.0" encoding="utf-8" ?>
```

### Custom Doctype

```pug
doctype custom
```

Output:
```html
<!DOCTYPE custom>
```

## Tags

### Basic Tags

```pug
div
p
h1
span
```

Output:
```html
<div></div>
<p></p>
<h1></h1>
<span></span>
```

### Self-Closing Tags

zig-pug automatically handles void elements:

```pug
img
br
hr
input
meta
```

Output:
```html
<img>
<br>
<hr>
<input>
<meta>
```

**Void elements (self-closing):**
`area`, `base`, `br`, `col`, `embed`, `hr`, `img`, `input`, `link`, `meta`, `param`, `source`, `track`, `wbr`

### Nested Tags

Use indentation (spaces only) to create nesting:

```pug
div
  h1
  p
  span
```

Output:
```html
<div>
  <h1></h1>
  <p></p>
  <span></span>
</div>
```

**Important:** Use only spaces for indentation (2 or 4 recommended). Tabs cause errors.

## Attributes

### Basic Attributes

```pug
a(href="/") Home
img(src="logo.png" alt="Logo")
input(type="email" name="email" required)
```

Output:
```html
<a href="/">Home</a>
<img src="logo.png" alt="Logo">
<input type="email" name="email" required>
```

### Multi-line Attributes

```pug
div(
  class="container"
  id="main"
  data-user-id="123"
  data-role="admin"
)
```

Output:
```html
<div class="container" id="main" data-user-id="123" data-role="admin"></div>
```

### Dynamic Attributes

Use `=` for expressions:

```pug
- var myClass = "active"
- var myUrl = "/home"
button(class=myClass) Click
a(href=myUrl) Link
```

Output:
```html
<button class="active">Click</button>
<a href="/home">Link</a>
```

### Attribute Concatenation

```pug
- var alertType = "success"
- var userId = 42
div(class="alert alert-" + alertType)
div(id="user-" + userId)
```

Output:
```html
<div class="alert alert-success"></div>
<div id="user-42"></div>
```

### Ternary in Attributes

```pug
- var isActive = true
div(class=isActive ? "active" : "inactive")
```

Output:
```html
<div class="active"></div>
```

### Object/Array Access in Attributes

```pug
- var user = {name: "Alice", role: "admin"}
- var urls = ["/home", "/about", "/contact"]

div(data-name=user.name data-role=user.role)
a(href=urls[0]) Home
```

Output:
```html
<div data-name="Alice" data-role="admin"></div>
<a href="/home">Home</a>
```

## Classes and IDs

### Class Shorthand

```pug
div.container
p.text
button.btn.btn-primary
```

Output:
```html
<div class="container"></div>
<p class="text"></p>
<button class="btn btn-primary"></button>
```

### ID Shorthand

```pug
div#header
section#main
footer#page-footer
```

Output:
```html
<div id="header"></div>
<section id="main"></section>
<footer id="page-footer"></footer>
```

### Combined Classes and IDs

```pug
div.container#app
h1.title.primary#page-title
```

Output:
```html
<div class="container" id="app"></div>
<h1 class="title primary" id="page-title"></h1>
```

### Implicit Divs (v4.0.0+)

When you start with `.` or `#`, a `div` is implied:

```pug
.wrapper
  .content
    #header
      h1 Title
```

Output:
```html
<div class="wrapper">
  <div class="content">
    <div id="header">
      <h1>Title</h1>
    </div>
  </div>
</div>
```

### Classes with Attributes

```pug
div.container(data-role="main")
p.text#intro(lang="en")
```

Output:
```html
<div class="container" data-role="main"></div>
<p class="text" id="intro" lang="en"></p>
```

## Text Content

### Inline Text

```pug
h1 Welcome to zig-pug
p This is a paragraph
span Some text
```

Output:
```html
<h1>Welcome to zig-pug</h1>
<p>This is a paragraph</p>
<span>Some text</span>
```

### Piped Text

Use `|` for multi-line text:

```pug
p
  | First line
  | Second line
  | Third line
```

Output:
```html
<p>First line Second line Third line</p>
```

### Block Text

```pug
p.
  This is a block of text.
  It can span multiple lines.
  All whitespace is preserved.
```

Output:
```html
<p>This is a block of text. It can span multiple lines. All whitespace is preserved.</p>
```

### Text with Tags

```pug
p Hello
  strong world
  | !
```

Output:
```html
<p>Hello<strong>world</strong>!</p>
```

## Interpolation

### Escaped Interpolation

Use `#{}` for HTML-escaped output (safe):

```pug
- var name = "Alice"
- var age = 30
p Hello #{name}!
p Age: #{age}
```

Output:
```html
<p>Hello Alice!</p>
<p>Age: 30</p>
```

**XSS protection:**
```pug
- var userInput = "<script>alert('xss')</script>"
p User said: #{userInput}
```

Output (escaped):
```html
<p>User said: &lt;script&gt;alert(&#39;xss&#39;)&lt;/script&gt;</p>
```

### Unescaped Interpolation

Use `!{}` for raw HTML (dangerous - use only with trusted content):

```pug
- var html = "<strong>Bold</strong>"
p Safe: #{html}
p Raw: !{html}
```

Output:
```html
<p>Safe: &lt;strong&gt;Bold&lt;/strong&gt;</p>
<p>Raw: <strong>Bold</strong></p>
```

**⚠️ Security Warning:** Never use `!{}` with user input. Only use with HTML you control.

### String Methods

```pug
- var name = "alice"
- var email = "ALICE@EXAMPLE.COM"
p #{name.toUpperCase()}
p #{email.toLowerCase()}
p #{name.replace('a', 'A')}
```

Output:
```html
<p>ALICE</p>
<p>alice@example.com</p>
<p>Alice</p>
```

### Arithmetic

```pug
- var age = 30
- var count = 10
p Next year: #{age + 1}
p Double: #{count * 2}
p Average: #{(count + age) / 2}
```

Output:
```html
<p>Next year: 31</p>
<p>Double: 20</p>
<p>Average: 20</p>
```

### Object Access

```pug
- var user = {name: "Alice", age: 30, profile: {email: "alice@example.com"}}
p Name: #{user.name}
p Age: #{user.age}
p Email: #{user.profile.email}
```

Output:
```html
<p>Name: Alice</p>
<p>Age: 30</p>
<p>Email: alice@example.com</p>
```

### Array Access

```pug
- var items = ["apple", "banana", "orange"]
p First: #{items[0]}
p Last: #{items[items.length - 1]}
p Count: #{items.length}
```

Output:
```html
<p>First: apple</p>
<p>Last: orange</p>
<p>Count: 3</p>
```

### Ternary Operators

```pug
- var age = 30
- var isActive = true
p Status: #{age >= 18 ? "Adult" : "Minor"}
p Access: #{isActive ? "Granted" : "Denied"}
```

Output:
```html
<p>Status: Adult</p>
<p>Access: Granted</p>
```

### Math Functions

```pug
p Max: #{Math.max(10, 20, 30)}
p Min: #{Math.min(10, 20, 30)}
p Random: #{Math.floor(Math.random() * 100)}
p PI: #{Math.PI.toFixed(2)}
```

Output (random value varies):
```html
<p>Max: 30</p>
<p>Min: 10</p>
<p>Random: 42</p>
<p>PI: 3.14</p>
```

## Code

### Unbuffered Code

Use `-` for code that executes but doesn't output:

```pug
- var greeting = "Hello"
- var name = "World"
- var message = greeting + " " + name
p= message
```

Output:
```html
<p>Hello World</p>
```

### Buffered Code (Escaped)

Use `=` for code that outputs (HTML-escaped):

```pug
- var name = "Alice"
p= name
h1= name.toUpperCase()
```

Output:
```html
<p>Alice</p>
<h1>ALICE</h1>
```

### Buffered Code (Unescaped)

Use `!=` for raw HTML output:

```pug
- var html = "<strong>Bold</strong>"
div= html
div!= html
```

Output:
```html
<div>&lt;strong&gt;Bold&lt;/strong&gt;</div>
<div><strong>Bold</strong></div>
```

## Comments

### Documentation Comments

Use `//!` for documentation (completely ignored by tokenizer):

```pug
//! Template: homepage.pug
//! Author: John Doe
//! Version: 1.0
doctype html
html
  body
    p Content
```

**Note:** `//!` comments can appear before `doctype` and are never included in output.

### Buffered Comments

Use `//` for comments that appear in development mode:

```pug
// This is a comment
div
  // Another comment
  p Content
```

**With `--pretty` flag:**
```html
<!-- This is a comment -->
<div>
  <!-- Another comment -->
  <p>Content</p>
</div>
```

**Without `--pretty` (production):**
```html
<div><p>Content</p></div>
```

### Unbuffered Comments

Use `//-` for comments that never appear in output:

```pug
//- This comment is never in HTML
div
  //- Developer note: refactor this
  p Content
```

Output (always):
```html
<div><p>Content</p></div>
```

### Comment Comparison

| Syntax | Name | Processed? | In HTML? | Use Case |
|--------|------|------------|----------|----------|
| `//!` | Documentation | ❌ No | ❌ Never | File metadata, author notes |
| `//` | Buffered | ✅ Yes | ✅ Dev mode only | Development debugging |
| `//-` | Unbuffered | ✅ Yes | ❌ Never | Code comments |

## Conditionals

### Basic If/Else

```pug
- var isLoggedIn = true
if isLoggedIn
  p Welcome back!
else
  p Please log in
```

Output:
```html
<p>Welcome back!</p>
```

### Else If

```pug
- var score = 85
if score > 90
  p Grade A
else if score > 80
  p Grade B
else if score > 70
  p Grade C
else
  p Grade F
```

Output:
```html
<p>Grade B</p>
```

### Unless (Negation)

```pug
- var isAdmin = false
unless isAdmin
  p Access denied
```

Output:
```html
<p>Access denied</p>
```

### Comparison Operators

```pug
- var age = 30
if age >= 18
  p Adult
else if age >= 13
  p Teen
else
  p Child
```

Supported operators: `>`, `<`, `>=`, `<=`, `==`

### Logical Operators

```pug
- var age = 30
- var hasLicense = true
if age >= 18 && hasLicense
  p Can drive
else
  p Cannot drive
```

Supported: `&&` (AND), `||` (OR)

### String Equality

```pug
- var status = "active"
if status == "active"
  p Account active
else if status == "pending"
  p Pending approval
else
  p Account inactive
```

### Property Access

```pug
- var user = {isPremium: true, isActive: true}
if user.isPremium
  p Premium features enabled
else
  p Upgrade to premium
```

### Complex Expressions

```pug
- var isAdmin = true
- var isModerator = false
- var user = {isActive: true}
if (isAdmin || isModerator) && user.isActive
  p Administrative access
else
  p Regular access
```

## Loops

### Each (Arrays)

```pug
- var items = ["apple", "banana", "orange"]
ul
  each item in items
    li= item
```

Output:
```html
<ul>
  <li>apple</li>
  <li>banana</li>
  <li>orange</li>
</ul>
```

### Each with Index

```pug
- var items = ["apple", "banana", "orange"]
ul
  each item, i in items
    li #{i}: #{item}
```

Output:
```html
<ul>
  <li>0: apple</li>
  <li>1: banana</li>
  <li>2: orange</li>
</ul>
```

### Each with Objects

```pug
- var users = [{name: "Alice", age: 30}, {name: "Bob", age: 25}]
ul
  each user in users
    li #{user.name} (#{user.age})
```

Output:
```html
<ul>
  <li>Alice (30)</li>
  <li>Bob (25)</li>
</ul>
```

### While Loops

```pug
- var count = 0
ul
  while count < 3
    li Count: #{count}
    - count = count + 1
```

Output:
```html
<ul>
  <li>Count: 0</li>
  <li>Count: 1</li>
  <li>Count: 2</li>
</ul>
```

## Mixins

### Basic Mixin

```pug
mixin greeting(name)
  p Hello, #{name}!

+greeting("World")
+greeting("Alice")
```

Output:
```html
<p>Hello, World!</p>
<p>Hello, Alice!</p>
```

### Mixins with Multiple Arguments

```pug
mixin button(text, type)
  button(class="btn btn-" + type)= text

+button("Submit", "primary")
+button("Cancel", "secondary")
```

Output:
```html
<button class="btn btn-primary">Submit</button>
<button class="btn btn-secondary">Cancel</button>
```

### Mixin with Default Values

```pug
mixin link(text, url)
  - url = url || "#"
  a(href=url)= text

+link("Home", "/")
+link("Placeholder")
```

Output:
```html
<a href="/">Home</a>
<a href="#">Placeholder</a>
```

## Template Inheritance

### Base Layout

**layout.zpug:**
```pug
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
        p © 2025
```

### Extending Layout

**page.zpug:**
```pug
extends layout.zpug

block title
  | Home Page

block content
  h2 Welcome
  p This replaces the default content
```

Output:
```html
<!DOCTYPE html>
<html>
  <head>
    <title>Home Page</title>
  </head>
  <body>
    <header>
      <h1>My Website</h1>
    </header>
    <main>
      <h2>Welcome</h2>
      <p>This replaces the default content</p>
    </main>
    <footer>
      <p>© 2025</p>
    </footer>
  </body>
</html>
```

### Block Modes

**Replace (default):**
```pug
block content
  p New content
```

**Append:**
```pug
block append content
  p Added after default
```

**Prepend:**
```pug
block prepend content
  p Added before default
```

## Includes

### Basic Include

**header.zpug:**
```pug
header
  h1 Site Title
  nav
    a(href="/") Home
    a(href="/about") About
```

**index.zpug:**
```pug
doctype html
html
  body
    include header.zpug
    main
      p Content here
```

## Special Features

### UTF-8 Support

Full Unicode support:

```pug
doctype html
html(lang="es")
  head
    title Página en Español
  body
    h1 ¡Bienvenido! 🎉
    p.información José, María, Ángel
    .português
      p Programação: ã, õ, ç
    #größe
      p Deutsche: ä, ö, ü, ß
```

**Supported:**
- ✅ Accented characters in text
- ✅ Accented characters in class/ID names
- ✅ Emoji and symbols
- ✅ All UTF-8 sequences (1-4 bytes)

### Multiple Classes

Classes are concatenated:

```pug
div.box.highlight.active
```

Output:
```html
<div class="box highlight active"></div>
```

### Data Attributes

```pug
div(data-user-id="123" data-role="admin" data-status="active")
```

Output:
```html
<div data-user-id="123" data-role="admin" data-status="active"></div>
```

## Quick Reference

```pug
// Document
doctype html

// Tags
div
p Text
h1= variable

// Classes & IDs
.container
#header
p.text#main

// Attributes
a(href="/" target="_blank")
div(class=myVar id="main")

// Text
p Hello world
p.
  Block text
|Piped text

// Interpolation
p #{name}
p !{html}

// Code
- var x = 10
p= x
p!= html

// Comments
//! Documentation
// Buffered
//- Unbuffered

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

+box("Title")

// Inheritance
extends layout.zpug
block content
  p Content
```

## See Also

- [GETTING-STARTED.md](GETTING-STARTED.md) - Getting started guide
- [NODEJS-INTEGRATION.md](NODEJS-INTEGRATION.md) - Node.js integration
- [MUJS-INTEGRATION.md](MUJS-INTEGRATION.md) - JavaScript runtime
- [en/CLI.md](en/CLI.md) - CLI documentation
- [Official Pug documentation](https://pugjs.org/) - Original Pug reference
