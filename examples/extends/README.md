# Template Inheritance Examples (Extends/Block)

This directory demonstrates zig-pug's template inheritance feature using `extends` and `block`.

## Overview

Template inheritance allows you to build a base "skeleton" template that contains all the common elements of your site and defines **blocks** that child templates can override.

## Files

- **layout.zpug** - Base layout template with multiple blocks
- **page.zpug** - Simple page that extends the layout and replaces blocks
- **page-with-append.zpug** - Example demonstrating `append` mode
- **page-with-prepend.zpug** - Example demonstrating `prepend` mode

## How to Run

```bash
# Compile a simple page (replace mode)
zpug examples/extends/page.zpug --pretty

# Compile page with append mode
zpug examples/extends/page-with-append.zpug --pretty

# Compile page with prepend mode
zpug examples/extends/page-with-prepend.zpug --pretty
```

## Block Modes

### Replace (default)
```pug
block content
  p This replaces the default content
```

### Append
Adds content after the default block content:
```pug
block append content
  p This comes after the default
```

### Prepend
Adds content before the default block content:
```pug
block prepend content
  p This comes before the default
```

## Syntax

### Unquoted paths (recommended)
```pug
extends layout.zpug
extends ../layouts/base.zpug
```

### Quoted paths
```pug
extends "layout.zpug"
extends "../layouts/base.zpug"
```

Both syntaxes work identically.

## Key Features

1. **Multiple blocks** - Define as many blocks as you need
2. **Nested blocks** - Blocks can contain other elements
3. **Default content** - Blocks can have default content that's used if not overridden
4. **Multiple levels** - You can extend a template that itself extends another template
5. **Flexible paths** - Supports relative paths with `..` notation

## Example Output

Running `zpug page.zpug --pretty` produces:

```html
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Home Page</title>
  </head>
  <body>
    <header>
      <h1>My Website</h1>
    </header>
    <main>
      <h2>Welcome to My Site</h2>
      <p>This content replaces the default block content</p>
      <ul>
        <li>Feature 1</li>
        <li>Feature 2</li>
        <li>Feature 3</li>
      </ul>
    </main>
    <footer>
      <p>Copyright 2024 My Website</p>
    </footer>
  </body>
</html>
```

## Notes

- Block names must be valid identifiers
- You can only extend one template per file
- The `extends` statement must be the first line (excluding comments)
- Blocks in the parent template can be left empty for child templates to fill
