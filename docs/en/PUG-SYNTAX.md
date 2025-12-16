# Pug Syntax Reference

[Español](../es/PUG-SYNTAX.md) | English

Complete guide to Pug template syntax supported by zig-pug.

---

## Table of Contents

1. [Basic Tags](#basic-tags)
2. [Attributes](#attributes)
3. [Classes and IDs](#classes-and-ids)
4. [Text Content](#text-content)
5. [Interpolation](#interpolation)
6. [Conditionals](#conditionals)
7. [Loops](#loops)
8. [Mixins](#mixins)
9. [Template Inheritance](#template-inheritance)
10. [Comments](#comments)
11. [Code](#code)

---

## Basic Tags

### Simple Tags

```pug
p
div
span
h1
```

Output:
```html
<p></p>
<div></div>
<span></span>
<h1></h1>
```

### Nested Tags

```pug
html
  head
    title My Page
  body
    h1 Hello World
    p Welcome to zig-pug
```

Output:
```html
<html>
  <head>
    <title>My Page</title>
  </head>
  <body>
    <h1>Hello World</h1>
    <p>Welcome to zig-pug</p>
  </body>
</html>
```

### Self-Closing Tags

```pug
img
br
hr
input
meta
link
```

Output:
```html
<img/>
<br/>
<hr/>
<input/>
<meta/>
<link/>
```

---

## Attributes

### Basic Attributes

```pug
a(href="/home") Home
img(src="logo.png" alt="Logo")
input(type="text" name="username")
```

Output:
```html
<a href="/home">Home</a>
<img src="logo.png" alt="Logo"/>
<input type="text" name="username"/>
```

### Multiple Attributes

```pug
a(
  href="/about"
  class="nav-link"
  target="_blank"
  rel="noopener"
) About Us
```

Output:
```html
<a href="/about" class="nav-link" target="_blank" rel="noopener">About Us</a>
```

### Quoted Attributes

```pug
div(data-value="Hello World")
a(title="Visit 'Example' site")
```

Output:
```html
<div data-value="Hello World"></div>
<a title="Visit 'Example' site"></a>
```

### Dynamic Attributes

```pug
//- With variables
a(href=linkUrl) Click
img(src=imagePath alt=imageAlt)

//- With expressions
div(class="btn-" + buttonType)
input(value=count * 2)
```

---

## Classes and IDs

### Class Shorthand

```pug
div.container
p.text-primary
span.badge.rounded
```

Output:
```html
<div class="container"></div>
<p class="text-primary"></p>
<span class="badge rounded"></span>
```

### ID Shorthand

```pug
div#header
section#main-content
footer#page-footer
```

Output:
```html
<div id="header"></div>
<section id="main-content"></section>
<footer id="page-footer"></footer>
```

### Combined Class and ID

```pug
div#app.container.fluid
h1#title.text-center.fw-bold Header
```

Output:
```html
<div id="app" class="container fluid"></div>
<h1 id="title" class="text-center fw-bold">Header</h1>
```

### Class with Attributes

```pug
a.btn.btn-primary(href="/submit") Submit
input.form-control(type="email" name="email")
```

Output:
```html
<a class="btn btn-primary" href="/submit">Submit</a>
<input class="form-control" type="email" name="email"/>
```

---

## Text Content

### Inline Text

```pug
p This is a paragraph
h1 Welcome to zig-pug
span Small text
```

Output:
```html
<p>This is a paragraph</p>
<h1>Welcome to zig-pug</h1>
<span>Small text</span>
```

### Piped Text

```pug
p
  | This is a longer paragraph.
  | It spans multiple lines.
  | Each line starts with a pipe.
```

Output:
```html
<p>This is a longer paragraph. It spans multiple lines. Each line starts with a pipe.</p>
```

### UTF-8 Support

```pug
p Hello 世界 🌍
p Acentos: á é í ó ú ñ ü
p Emoji: 🎉 🚀 ✨ 💯
```

Output:
```html
<p>Hello 世界 🌍</p>
<p>Acentos: á é í ó ú ñ ü</p>
<p>Emoji: 🎉 🚀 ✨ 💯</p>
```

---

## Interpolation

### Variable Interpolation

```pug
//- Variables: name = "Alice", age = 25
p Hello #{name}!
p You are #{age} years old.
```

Output:
```html
<p>Hello Alice!</p>
<p>You are 25 years old.</p>
```

### Expression Interpolation

```pug
//- Variables: x = 5, y = 10
p Sum: #{x + y}
p Double: #{x * 2}
p Message: #{x > 3 ? "Big" : "Small"}
```

Output:
```html
<p>Sum: 15</p>
<p>Double: 10</p>
<p>Message: Big</p>
```

### Method Calls

```pug
//- Variables: text = "hello"
p Uppercase: #{text.toUpperCase()}
p Length: #{text.length}
```

Output:
```html
<p>Uppercase: HELLO</p>
<p>Length: 5</p>
```

### Escaping

```pug
//- Variables: html = "<script>alert('xss')</script>"
p Safe: #{html}
p Unsafe: !{html}
```

Output:
```html
<p>Safe: &lt;script&gt;alert('xss')&lt;/script&gt;</p>
<p>Unsafe: <script>alert('xss')</script></p>
```

---

## Conditionals

### If Statement

```pug
//- Variable: isLoggedIn = true
if isLoggedIn
  p Welcome back!
```

Output (when true):
```html
<p>Welcome back!</p>
```

### If-Else

```pug
//- Variable: hasPermission = false
if hasPermission
  button Edit
else
  button View Only
```

Output:
```html
<button>View Only</button>
```

### If-Else If-Else

```pug
//- Variable: role = "admin"
if role === "admin"
  p Admin Panel
else if role === "moderator"
  p Moderator Tools
else
  p User Dashboard
```

Output:
```html
<p>Admin Panel</p>
```

### Unless

```pug
//- Variable: isDisabled = false
unless isDisabled
  button Click Me
```

Output:
```html
<button>Click Me</button>
```

---

## Loops

### Each with Arrays

```pug
//- Variable: items = ["Apple", "Banana", "Cherry"]
ul
  each item in items
    li= item
```

Output:
```html
<ul>
  <li>Apple</li>
  <li>Banana</li>
  <li>Cherry</li>
</ul>
```

### Each with Index

```pug
//- Variable: colors = ["Red", "Green", "Blue"]
ul
  each color, index in colors
    li #{index + 1}. #{color}
```

Output:
```html
<ul>
  <li>1. Red</li>
  <li>2. Green</li>
  <li>3. Blue</li>
</ul>
```

### While Loop

```pug
//- Variable: n = 3
ul
  while n > 0
    li Item #{n}
    - n--
```

Output:
```html
<ul>
  <li>Item 3</li>
  <li>Item 2</li>
  <li>Item 1</li>
</ul>
```

---

## Mixins

### Simple Mixin

```pug
mixin greeting
  p Hello World!

+greeting
+greeting
```

Output:
```html
<p>Hello World!</p>
<p>Hello World!</p>
```

### Mixin with Arguments

```pug
mixin button(text, type)
  button(class="btn-" + type)= text

+button("Submit", "primary")
+button("Cancel", "secondary")
```

Output:
```html
<button class="btn-primary">Submit</button>
<button class="btn-secondary">Cancel</button>
```

### Mixin with Multiple Parameters

```pug
mixin card(title, description, link)
  div.card
    h3= title
    p= description
    a(href=link) Learn More

+card("Feature 1", "Amazing feature", "/feature1")
+card("Feature 2", "Another great feature", "/feature2")
```

Output:
```html
<div class="card">
  <h3>Feature 1</h3>
  <p>Amazing feature</p>
  <a href="/feature1">Learn More</a>
</div>
<div class="card">
  <h3>Feature 2</h3>
  <p>Another great feature</p>
  <a href="/feature2">Learn More</a>
</div>
```

---

## Template Inheritance

### Base Template (layout.pug)

```pug
doctype html
html
  head
    title #{pageTitle}
    block styles
  body
    header
      block header
        h1 Default Header
    main
      block content
    footer
      block footer
        p © 2025
```

### Child Template (page.pug)

```pug
extends layout.pug

block header
  h1 Custom Page Header

block content
  p This is the main content
  p Another paragraph

block footer
  p Custom footer
  p Contact us
```

Output:
```html
<!DOCTYPE html>
<html>
  <head>
    <title></title>
  </head>
  <body>
    <header>
      <h1>Custom Page Header</h1>
    </header>
    <main>
      <p>This is the main content</p>
      <p>Another paragraph</p>
    </main>
    <footer>
      <p>Custom footer</p>
      <p>Contact us</p>
    </footer>
  </body>
</html>
```

---

## Comments

### Single-Line Comments

```pug
// This comment appears in HTML
p Visible content
//- This comment does NOT appear in HTML
p More content
```

Output:
```html
<!-- This comment appears in HTML -->
<p>Visible content</p>
<p>More content</p>
```

### Documentation Comments

```pug
//! Template: homepage.pug
//! Author: Team
//! Description: Main landing page

doctype html
html
  body
    h1 Homepage
```

Output:
```html
<!DOCTYPE html>
<html>
  <body>
    <h1>Homepage</h1>
  </body>
</html>
```

*Note: `//!` comments are for documentation and are ignored by the parser*

---

## Code

### Buffered Code (=)

```pug
//- Variable: username = "Alice"
p= username
div= "Static text"
```

Output:
```html
<p>Alice</p>
<div>Static text</div>
```

### Unescaped Buffered Code (!=)

```pug
//- Variable: html = "<strong>Bold</strong>"
p!= html
```

Output:
```html
<p><strong>Bold</strong></p>
```

### Unbuffered Code (-)

```pug
- var localVar = "Hello"
- var count = 42

p #{localVar}
p Count: #{count}
```

Output:
```html
<p>Hello</p>
<p>Count: 42</p>
```

---

## Doctype

### HTML5

```pug
doctype html
```

Output:
```html
<!DOCTYPE html>
```

### Other Doctypes

```pug
doctype xml
doctype transitional
doctype strict
doctype frameset
doctype 1.1
doctype basic
doctype mobile
```

---

## Best Practices

1. **Indentation** - Use 2 spaces (consistent)
2. **Quotes** - Use double quotes for attributes
3. **Variables** - Clear, descriptive names
4. **Comments** - Document complex logic
5. **Mixins** - Reuse common patterns
6. **Inheritance** - Use for page layouts

---

## See Also

- [Getting Started](GETTING-STARTED.md)
- [API Reference](API-REFERENCE.md)
- [Examples](EXAMPLES.md)
- [CLI Documentation](CLI.md)

---

**Last Updated:** 2025-12-16
