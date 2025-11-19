# Loops, Includes, and Cache in zig-pug

This guide explains the advanced features of zig-pug for loops, includes, and template caching.

## Loops (each/for)

### Basic Syntax

```zpug
each item in items
  li #{item}
```

**Generated HTML:**
```html
<li>Item 1</li>
<li>Item 2</li>
<li>Item 3</li>
```

### Loop with Index

```zpug
each fruit, index in fruits
  li #{index}: #{fruit}
```

**Generated HTML:**
```html
<li>0: Apple</li>
<li>1: Banana</li>
<li>2: Orange</li>
```

### Else for Empty Arrays

```zpug
each item in emptyArray
  li #{item}
else
  p No items available
```

**HTML (if the array is empty):**
```html
<p>No items available</p>
```

### Configuring Arrays in the Runtime

**In Zig:**
```zig
// Set array in JavaScript
_ = try runtime.eval("var items = ['Apple', 'Banana', 'Orange']");
```

**In Node.js:**
```javascript
const zigpug = require('zig-pug');

const html = zigpug.compile(template, {
    items: ['Apple', 'Banana', 'Orange']
});
```

### Complete Example

```zpug
doctype html
html
  body
    h1 User List
    ul
      each user in users
        li.user
          strong #{user.name}
          span  - #{user.email}

    h2 Products
    each product, i in products
      div.product
        span.number #{i + 1}.
        span.name #{product}
    else
      p No products available
```

---

## Includes

### Syntax

```zpug
include path/to/file.zpug
```

### File Structure

```
project/
├── views/
│   ├── index.zpug        # Main template
│   └── partials/
│       ├── header.zpug   # Header partial
│       └── footer.zpug   # Footer partial
```

### Main Template

```zpug
// views/index.zpug
doctype html
html
  head
    title #{title}
  body
    include partials/header.zpug

    main.content
      h1 #{title}
      p #{content}

    include partials/footer.zpug
```

### Header Partial

```zpug
// views/partials/header.zpug
header.main-header
  nav
    a.logo(href="/") My Site
    ul.menu
      li: a(href="/") Home
      li: a(href="/about") About
```

### Footer Partial

```zpug
// views/partials/footer.zpug
footer
  p &copy; 2024 My Site
```

### Configuring Base Path

For includes to work correctly, configure the base path:

**In Zig:**
```zig
var compiler = try Compiler.init(allocator, runtime);
compiler.setBasePath("views/index.zpug");
```

**In CLI:**
```bash
zig-pug views/index.zpug -o output.html
```

The CLI automatically uses the file's directory as the base path.

### Nested Includes

Includes can contain other includes:

```zpug
// layout.zpug
doctype html
html
  head
    include partials/meta.zpug
  body
    include partials/header.zpug
    block content
    include partials/footer.zpug
```

---

## Template Cache

The cache stores compiled templates to avoid re-parsing and re-compiling.

### Benefits

- **Performance**: Avoids re-parsing unchanged templates
- **Automatic invalidation**: Detects changes by source hash
- **Statistics**: Hit rate, misses, number of entries

### Usage in Zig

```zig
const cache = @import("cache.zig");

// Create cache (0 = no limit, or specify maximum entries)
var template_cache = cache.TemplateCache.init(allocator, 100);
defer template_cache.deinit();

// Create compiler with cache
var compiler = try Compiler.init(allocator, runtime);
compiler.setCache(&template_cache);

// Compile - automatically cached
const html = try compiler.compile(ast);

// View statistics
const stats = template_cache.stats();
std.debug.print("Hits: {}, Misses: {}, Hit Rate: {d:.2}%\n",
    .{ stats.hits, stats.misses, stats.hit_rate * 100 });
```

### Manual Invalidation

```zig
// Invalidate a specific template
template_cache.invalidate("views/index.zpug");

// Clear the entire cache
template_cache.clear();
```

### Usage with Includes

When using includes, the cache stores each partial separately:

```zig
var compiler = try Compiler.init(allocator, runtime);
compiler.setBasePath("views/index.zpug");
compiler.setCache(&template_cache);

// Includes are cached individually
const html = try compiler.compile(ast);

// Each include has its own cache entry:
// - "views/partials/header.zpug"
// - "views/partials/footer.zpug"
```

### Cache in Node.js

In Node.js, the cache is managed internally. You can enable it with options:

```javascript
const zigpug = require('zig-pug');
const { PugCompiler } = zigpug;

const compiler = new PugCompiler();
compiler.enableCache(100); // Maximum 100 entries

// Compile multiple times - uses cache
for (let i = 0; i < 1000; i++) {
    compiler.compile(template);
}

// View statistics
const stats = compiler.cacheStats();
console.log(`Hit rate: ${stats.hitRate * 100}%`);
```

### Cache Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `max_size` | Maximum number of entries (0 = unlimited) | 0 |
| Eviction | LRU (Least Recently Used) by timestamp | - |
| Validation | Source code hash | - |

### Performance Example

```zig
const iterations = 10000;

// Without cache
var start = std.time.nanoTimestamp();
for (0..iterations) |_| {
    // Parse + compile each time
}
var no_cache_time = std.time.nanoTimestamp() - start;

// With cache
var template_cache = cache.TemplateCache.init(allocator, 0);
start = std.time.nanoTimestamp();
for (0..iterations) |_| {
    // Only compiles the first time
}
var with_cache_time = std.time.nanoTimestamp() - start;

// Typical result: 10-50x faster with cache
```

---

## Complete Examples

### Example 1: Blog with Loops and Includes

```zpug
// views/blog.zpug
doctype html
html
  head
    title #{blogTitle}
  body
    include partials/header.zpug

    main.blog
      h1 #{blogTitle}

      each post in posts
        article.post
          h2 #{post.title}
          p.meta By #{post.author} - #{post.date}
          p #{post.excerpt}
          a(href="/post/#{post.id}") Read more
      else
        p No posts available

    include partials/footer.zpug
```

### Example 2: E-commerce with Cache

```zig
// Server with template cache
var template_cache = cache.TemplateCache.init(allocator, 1000);
defer template_cache.deinit();

fn handleRequest(path: []const u8) ![]const u8 {
    var compiler = try Compiler.init(allocator, runtime);
    defer compiler.deinit();

    compiler.setBasePath(path);
    compiler.setCache(&template_cache);

    const ast = try parseTemplate(path);
    return try compiler.compile(ast);
}

// First request: parse + compile (10ms)
// Subsequent requests: from cache (0.1ms)
```

### Example 3: Dynamic List

```zpug
div.shopping-cart
  h2 Your Cart (#{items.length} items)

  if items.length > 0
    ul.cart-items
      each item, i in items
        li.cart-item
          span.number #{i + 1}.
          span.name #{item.name}
          span.price $#{item.price}
          span.qty x#{item.quantity}

    div.total
      strong Total: $#{total}
  else
    p.empty Your cart is empty
    a(href="/products") View products
```

---

## Known Limitations

### Loops

- Only iterates over JavaScript arrays
- Does not support objects directly (use `Object.keys()`)
- The iterable must have a `.length` property

### Includes

- Paths are relative to the current file
- Does not support dynamic includes (path must be literal)
- Maximum 1MB per included file

### Cache

- In-memory cache (lost on restart)
- Does not support distributed cache
- Simple eviction (oldest first)

---

## Best Practices

### 1. Organize Partials

```
views/
├── layouts/
│   └── base.zpug
├── partials/
│   ├── header.zpug
│   ├── footer.zpug
│   └── sidebar.zpug
└── pages/
    ├── home.zpug
    └── about.zpug
```

### 2. Use Cache in Production

```zig
// Development: no cache (reload changes)
if (is_development) {
    compiler.setCache(null);
} else {
    compiler.setCache(&production_cache);
}
```

### 3. Avoid Deeply Nested Loops

```zpug
// Good
each category in categories
  h2 #{category.name}
  each product in category.products
    p #{product.name}

// Avoid (3+ levels)
each a in items
  each b in a.children
    each c in b.children
      each d in c.children  // Too deep
```

### 4. Small and Reusable Partials

```zpug
// partials/button.zpug
button.btn(class=type)= text

// Usage
include partials/button.zpug
```

---

## Resources

- **Examples**: `examples/loops.zpug`, `examples/includes.zpug`
- **Tests**: `src/compiler.zig` (loop and cache tests)
- **API Reference**: [docs/API-REFERENCE.md](API-REFERENCE.md)

---

**Enjoy loops, includes, and cache in zig-pug!**
