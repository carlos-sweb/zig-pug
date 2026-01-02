# Pug Syntax Basics

Beginner-friendly guide to Pug template syntax fundamentals.

## Introduction

Pug is an elegant templating language that uses **indentation** instead of closing tags to define HTML structure. This makes templates cleaner and easier to read.

### Why Pug?

**Traditional HTML:**
```html
<div class="container">
  <h1>Welcome</h1>
  <p>Hello World!</p>
</div>
```

**Pug:**
```pug
.container
  h1 Welcome
  p Hello World!
```

**Benefits:**
- Less code to write
- No closing tags to forget
- Clearer visual hierarchy
- Reduced errors

## Basic Tags

### Simple Tags

```pug
div
p
h1
span
a
```

Compiles to:
```html
<div></div>
<p></p>
<h1></h1>
<span></span>
<a></a>
```

### Tags with Text

Put text directly after the tag:

```pug
h1 Welcome to zig-pug
p This is a paragraph
span Some inline text
```

Compiles to:
```html
<h1>Welcome to zig-pug</h1>
<p>This is a paragraph</p>
<span>Some inline text</span>
```

### Nesting

Use **indentation** (spaces only) to nest elements:

```pug
div
  h1 Title
  p Paragraph
  span Text
```

Compiles to:
```html
<div>
  <h1>Title</h1>
  <p>Paragraph</p>
  <span>Text</span>
</div>
```

**Important:** Use consistent indentation (2 or 4 spaces recommended). Tabs cause errors.

### Multiple Levels

```pug
div
  section
    article
      h1 Title
      p Content
```

Compiles to:
```html
<div>
  <section>
    <article>
      <h1>Title</h1>
      <p>Content</p>
    </article>
  </section>
</div>
```

## Attributes

### Basic Syntax

Attributes go in parentheses `()` after the tag:

```pug
a(href="/") Home
img(src="logo.png")
input(type="email" name="email")
```

Compiles to:
```html
<a href="/">Home</a>
<img src="logo.png">
<input type="email" name="email">
```

### Multiple Attributes

Separate with spaces:

```pug
a(href="/" class="link" target="_blank") External Link
```

Or use multi-line:

```pug
a(
  href="/"
  class="link"
  target="_blank"
) External Link
```

Both compile to:
```html
<a href="/" class="link" target="_blank">External Link</a>
```

### Boolean Attributes

Just include the attribute name:

```pug
input(type="checkbox" checked)
input(type="text" required)
button(disabled) Click
```

Compiles to:
```html
<input type="checkbox" checked>
<input type="text" required>
<button disabled>Click</button>
```

## Classes and IDs

### Class Shorthand

Use `.` followed by class name:

```pug
div.container
p.text
button.btn
```

Compiles to:
```html
<div class="container"></div>
<p class="text"></p>
<button class="btn"></button>
```

### Multiple Classes

Chain them together:

```pug
button.btn.btn-primary.active
div.container.fluid
```

Compiles to:
```html
<button class="btn btn-primary active"></button>
<div class="container fluid"></div>
```

### ID Shorthand

Use `#` followed by ID:

```pug
div#header
section#main
footer#page-footer
```

Compiles to:
```html
<div id="header"></div>
<section id="main"></section>
<footer id="page-footer"></footer>
```

### Classes and IDs Together

```pug
div.container#app
h1.title#page-title
```

Compiles to:
```html
<div class="container" id="app"></div>
<h1 class="title" id="page-title"></h1>
```

### Implicit Divs

When you start with `.` or `#`, a `<div>` is implied:

```pug
.wrapper
#header
.content.main
```

Compiles to:
```html
<div class="wrapper"></div>
<div id="header"></div>
<div class="content main"></div>
```

### Combining with Attributes

```pug
div.container(data-role="main")
p.text#intro(lang="en")
a.link(href="/")
```

Compiles to:
```html
<div class="container" data-role="main"></div>
<p class="text" id="intro" lang="en"></p>
<a class="link" href="/"></a>
```

## Text Content

### Inline Text

```pug
h1 Welcome
p This is a paragraph
span Inline text
```

### Multi-line Text

Use `|` (pipe) for multi-line text:

```pug
p
  | First line
  | Second line
  | Third line
```

Compiles to:
```html
<p>First line Second line Third line</p>
```

### Block Text

Use `.` after tag for large text blocks:

```pug
p.
  This is a large block of text.
  It can span multiple lines.
  Whitespace is preserved.
```

### Mixing Tags and Text

```pug
p Hello
  strong world
  | !
```

Compiles to:
```html
<p>Hello<strong>world</strong>!</p>
```

## Document Type

Start HTML documents with doctype:

```pug
doctype html
html
  head
    title My Page
  body
    h1 Content
```

Compiles to:
```html
<!DOCTYPE html>
<html>
  <head>
    <title>My Page</title>
  </head>
  <body>
    <h1>Content</h1>
  </body>
</html>
```

## Comments

### HTML Comments

Use `//` for comments that appear in HTML:

```pug
// This is a comment
p Content
```

Compiles to (with `--pretty`):
```html
<!-- This is a comment -->
<p>Content</p>
```

### Code Comments

Use `//-` for comments that don't appear in HTML:

```pug
//- This comment won't appear
p Content
```

Compiles to:
```html
<p>Content</p>
```

### Documentation Comments

Use `//!` for file metadata (completely ignored):

```pug
//! Author: John Doe
//! Version: 1.0
doctype html
```

## Complete Example

Putting it all together:

```pug
doctype html
html(lang="en")
  head
    meta(charset="UTF-8")
    title My First Page
  body
    .container
      header#site-header
        h1.title Welcome

      main.content
        section.intro
          p.
            This is my first Pug template.
            It's much cleaner than HTML!

        section.links
          ul
            li
              a(href="/") Home
            li
              a(href="/about") About

      footer
        p © 2025
```

Compiles to:
```html
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="UTF-8">
    <title>My First Page</title>
  </head>
  <body>
    <div class="container">
      <header id="site-header">
        <h1 class="title">Welcome</h1>
      </header>
      <main class="content">
        <section class="intro">
          <p>This is my first Pug template. It's much cleaner than HTML!</p>
        </section>
        <section class="links">
          <ul>
            <li><a href="/">Home</a></li>
            <li><a href="/about">About</a></li>
          </ul>
        </section>
      </main>
      <footer>
        <p>© 2025</p>
      </footer>
    </div>
  </body>
</html>
```

## Common Mistakes

### 1. Using Tabs

**❌ Wrong:**
```pug
div
	p Text  // Tab character
```

**✅ Correct:**
```pug
div
  p Text  // 2 spaces
```

### 2. Inconsistent Indentation

**❌ Wrong:**
```pug
div
  p Line 1
    p Line 2  // Too much indent
```

**✅ Correct:**
```pug
div
  p Line 1
  p Line 2
```

### 3. Forgetting Parentheses for Attributes

**❌ Wrong:**
```pug
a href="/" Home
```

**✅ Correct:**
```pug
a(href="/") Home
```

### 4. Missing Space Before Text

**❌ Wrong:**
```pug
pHello  // No space
```

**✅ Correct:**
```pug
p Hello
```

## Quick Reference

```pug
// Tags
div
p Text

// Nesting
div
  p Child

// Attributes
a(href="/")

// Classes
.container
div.box

// IDs
#header
div#main

// Multiple classes
div.box.active

// Text
p Hello
p.
  Block text
| Piped text

// Comments
// HTML comment
//- Code comment
//! Documentation

// Doctype
doctype html
```

## Next Steps

- [SYNTAX-ADVANCED.md](SYNTAX-ADVANCED.md) - Advanced syntax features
- [VARIABLES.md](VARIABLES.md) - Working with variables
- [CONDITIONALS-LOOPS.md](CONDITIONALS-LOOPS.md) - Logic in templates
- [../PUG-SYNTAX.md](../PUG-SYNTAX.md) - Complete syntax reference
