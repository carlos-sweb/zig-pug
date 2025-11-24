# Example: Template Includes

**Difficulty:** ⭐⭐⭐ Advanced
**Category:** Composición
**Time:** 12 minutes

## 📝 What You'll Learn

- Including external template files
- Organizing templates into partials
- Sharing code between templates
- Building modular template structures
- Managing reusable components

## 📄 Source Code

**Main File:** `examples/includes.zpug`

```zpug
// Example: Includes in zig-pug

doctype html
html(lang="es")
  head
    title #{pageTitle}
    style.
      body { font-family: system-ui; margin: 0; }
      .main-header { background: #333; color: white; padding: 1rem; }
      .navbar { display: flex; align-items: center; gap: 2rem; }
      .logo { color: white; font-weight: bold; text-decoration: none; }
      .nav-menu { display: flex; list-style: none; gap: 1rem; }
      .nav-menu a { color: white; text-decoration: none; }
      .content { padding: 2rem; }
      .main-footer { background: #f5f5f5; padding: 1rem; text-align: center; }

  body
    // Include header partial
    include partials/header.zpug

    main.content
      h1 #{pageTitle}
      p Welcome to #{siteName}!

      div.features
        h2 Features
        ul
          each feature in features
            li #{feature}

    // Include footer partial
    include partials/footer.zpug
```

**Header Partial:** `examples/partials/header.zpug`

```zpug
// Partial: Header component
header.main-header
  nav.navbar
    a.logo(href="/") zig-pug
    ul.nav-menu
      li
        a(href="/") Home
      li
        a(href="/about") About
      li
        a(href="/contact") Contact
```

**Footer Partial:** `examples/partials/footer.zpug`

```zpug
// Partial: Footer component
footer.main-footer
  p &copy; 2024 zig-pug
  p Made with ❤️ using Zig
```

## 🎯 Key Concepts

### 1. Basic Include

```zpug
include partials/header.zpug
```

**What it does:**
- Inserts the entire content of `header.zpug` at this location
- Path is relative to the current file
- The included file is compiled inline

**Note:** Think of `include` as copy-pasting the file content.

---

### 2. Organizing with Partials

**Directory Structure:**
```
examples/
  includes.zpug          (main file)
  partials/
    header.zpug          (reusable header)
    footer.zpug          (reusable footer)
    sidebar.zpug         (reusable sidebar)
```

**Benefits:**
- **DRY Principle**: Don't repeat header/footer code
- **Maintainability**: Update once, changes everywhere
- **Organization**: Clean file structure

---

### 3. Variable Scope

```zpug
// Main file
- var siteName = "My Site"

include partials/header.zpug
```

```zpug
// header.zpug can access siteName
h1= siteName
```

**Important:** Included files share the same variable scope as the parent.

---

### 4. Multiple Includes

```zpug
doctype html
html
  head
    include partials/meta.zpug
    include partials/styles.zpug

  body
    include partials/header.zpug
    include partials/sidebar.zpug

    main
      block content

    include partials/footer.zpug
    include partials/scripts.zpug
```

**Pattern:** Common in large applications to separate concerns.

---

### 5. Including Non-Pug Files

```zpug
// Include raw HTML
include:html partials/analytics.html

// Include CSS
style
  include:css styles/main.css

// Include JavaScript
script
  include:js scripts/app.js
```

**Syntax:** `include:filter filename`

**Usage:** Embed static files directly into templates.

---

## 🖥️ Run This Example

```bash
# Compile to stdout
zpug examples/includes.zpug

# Pretty print
zpug -p examples/includes.zpug

# Compile to file
zpug examples/includes.zpug -o output.html
```

**Note:** Make sure partial files exist in the correct relative path.

## 📤 Expected Output

```html
<!DOCTYPE html><html lang="es"><head><title>My Website</title><style>body { font-family: system-ui; margin: 0; }
.main-header { background: #333; color: white; padding: 1rem; }
.navbar { display: flex; align-items: center; gap: 2rem; }
.logo { color: white; font-weight: bold; text-decoration: none; }
.nav-menu { display: flex; list-style: none; gap: 1rem; }
.nav-menu a { color: white; text-decoration: none; }
.content { padding: 2rem; }
.main-footer { background: #f5f5f5; padding: 1rem; text-align: center; }</style></head><body><header class="main-header"><nav class="navbar"><a class="logo" href="/">zig-pug</a><ul class="nav-menu"><li><a href="/">Home</a></li><li><a href="/about">About</a></li><li><a href="/contact">Contact</a></li></ul></nav></header><main class="content"><h1>My Website</h1><p>Welcome to zig-pug!</p><div class="features"><h2>Features</h2><ul><li>Fast compilation</li><li>Pug syntax</li><li>Template reuse</li></ul></div></main><footer class="main-footer"><p>&copy; 2024 zig-pug</p><p>Made with ❤️ using Zig</p></footer></body></html>
```

## ✅ Exercise

Create a blog layout with includes:

**Structure:**
```
blog/
  index.zpug
  partials/
    head.zpug
    navigation.zpug
    sidebar.zpug
    footer.zpug
```

**index.zpug:**
```zpug
doctype html
html
  include partials/head.zpug

  body
    include partials/navigation.zpug

    div.container
      main.content
        h1 Blog Posts
        each post in posts
          article
            h2= post.title
            p= post.excerpt

      include partials/sidebar.zpug

    include partials/footer.zpug
```

## 🔗 What's Next?

**Next Example:** [inheritance.md](inheritance.md) - Learn template inheritance with extends

**Previous Example:** [04-mixins.md](04-mixins.md) - Mixins

**Learning Path:** [INDEX.md](INDEX.md)
