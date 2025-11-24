# Example: Template Inheritance

**Difficulty:** ⭐⭐⭐ Advanced
**Category:** Composición
**Time:** 15 minutes

## 📝 What You'll Learn

- Template inheritance with `extends`
- Defining blocks in layouts
- Overriding blocks in child templates
- Appending and prepending to blocks
- Creating reusable page layouts

## 📄 Source Code

**Base Layout:** `examples/layouts/base.zpug`

```zpug
// Base layout for template inheritance
doctype html
html(lang="es")
  head
    title #{pageTitle}
    block head
      meta(charset="UTF-8")
      meta(name="viewport" content="width=device-width, initial-scale=1.0")

  body
    header
      nav
        a(href="/") Home
        a(href="/about") About

    main
      block content
        p Default content

    footer
      block footer
        p Copyright 2024 zig-pug
```

**Child Template:** `examples/inheritance.zpug`

```zpug
// Example: Template Inheritance in zig-pug
// This template extends the base layout

extends layouts/base.zpug

block head
  meta(charset="UTF-8")
  meta(name="viewport" content="width=device-width, initial-scale=1.0")
  link(rel="stylesheet" href="/css/page.css")

block content
  h1 Welcome to #{pageTitle}
  p This content overrides the default block.

  div.features
    h2 Features
    ul
      li Template inheritance
      li Blocks can be overridden
      li Default content if not overridden
```

## 🎯 Key Concepts

### 1. Extends Keyword

```zpug
extends layouts/base.zpug
```

**What it does:**
- Inherits the entire structure from `base.zpug`
- Allows overriding specific `block` sections
- Path is relative to the current file

**Pattern:** Child templates extend a base layout and override specific sections.

---

### 2. Defining Blocks in Layouts

```zpug
// base.zpug
html
  head
    block head
      meta(charset="UTF-8")

  body
    block content
      p Default content

    block footer
      p Copyright 2024
```

**Blocks are:**
- Named sections that can be overridden
- Can have default content
- Placeholders for child template content

---

### 3. Overriding Blocks

**Base Layout:**
```zpug
block content
  p Default content
```

**Child Template:**
```zpug
extends base.zpug

block content
  h1 My Custom Content
  p This replaces the default
```

**Result:** The default content is completely replaced.

---

### 4. Block Append

```zpug
// base.zpug
block scripts
  script(src="/js/jquery.js")

// child.zpug
extends base.zpug

block append scripts
  script(src="/js/custom.js")
```

**Generates:**
```html
<script src="/js/jquery.js"></script>
<script src="/js/custom.js"></script>
```

**Usage:** Add content after the default block content.

---

### 5. Block Prepend

```zpug
// base.zpug
block meta
  meta(name="viewport" content="width=device-width")

// child.zpug
extends base.zpug

block prepend meta
  meta(charset="UTF-8")
```

**Generates:**
```html
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width">
```

**Usage:** Add content before the default block content.

---

### 6. Multiple Level Inheritance

```zpug
// base.zpug (root)
html
  block content

// layout.zpug (extends base)
extends base.zpug

block content
  div.container
    block page-content

// page.zpug (extends layout)
extends layout.zpug

block page-content
  h1 My Page
```

**Pattern:** Build layered layouts for complex applications.

---

## 🖥️ Run This Example

```bash
# Compile the child template (it will include the base)
zpug examples/inheritance.zpug

# Pretty print
zpug -p examples/inheritance.zpug

# Compile to file
zpug examples/inheritance.zpug -o output.html
```

**Note:** Always compile the child template, not the base layout.

## 📤 Expected Output

```html
<!DOCTYPE html><html lang="es"><head><title>My Page</title><meta charset="UTF-8"><meta name="viewport" content="width=device-width, initial-scale=1.0"><link rel="stylesheet" href="/css/page.css"></head><body><header><nav><a href="/">Home</a><a href="/about">About</a></nav></header><main><h1>Welcome to My Page</h1><p>This content overrides the default block.</p><div class="features"><h2>Features</h2><ul><li>Template inheritance</li><li>Blocks can be overridden</li><li>Default content if not overridden</li></ul></div></main><footer><p>Copyright 2024 zig-pug</p></footer></body></html>
```

## ✅ Exercise

Create a three-level layout system:

**base.zpug:**
```zpug
doctype html
html
  head
    block head
      meta(charset="UTF-8")
      title Default Title

  body
    block body
      p Default body
```

**dashboard-layout.zpug:**
```zpug
extends base.zpug

block head
  meta(charset="UTF-8")
  title Dashboard
  link(rel="stylesheet" href="/css/dashboard.css")

block body
  div.dashboard
    aside.sidebar
      block sidebar
        p Default sidebar

    main.main-content
      block content
        p Default content
```

**dashboard-home.zpug:**
```zpug
extends dashboard-layout.zpug

block sidebar
  nav
    a(href="/") Home
    a(href="/settings") Settings

block content
  h1 Dashboard Home
  p Welcome back!
```

## 🔗 What's Next?

**Next Example:** [05-complete.md](05-complete.md) - Complete example combining all features

**Previous Example:** [includes.md](includes.md) - Template Includes

**Learning Path:** [INDEX.md](INDEX.md)

## 📚 Includes vs Inheritance

| Feature | Includes | Inheritance |
|---------|----------|-------------|
| **Purpose** | Insert file content | Extend layout structure |
| **Direction** | Parent pulls in child | Child extends parent |
| **Flexibility** | Insert anywhere | Override specific blocks |
| **Best for** | Partials, components | Page layouts |
| **Example** | Header, footer | Base page template |
