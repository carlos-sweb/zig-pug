# Performance Optimization

Guide to optimizing zig-pug templates for maximum performance.

## Table of Contents

- [Understanding Performance](#understanding-performance)
- [Template Optimization](#template-optimization)
- [Runtime Optimization](#runtime-optimization)
- [Server-Side Optimization](#server-side-optimization)
- [Output Optimization](#output-optimization)
- [Benchmarking](#benchmarking)

## Understanding Performance

### Performance Characteristics

zig-pug compilation involves several phases:

```
1. Tokenization    (~10-20% of time)
2. Parsing         (~15-25% of time)
3. Compilation     (~30-40% of time)
4. JS Evaluation   (~25-35% of time)
5. HTML Escaping   (~5-10% of time)
6. Formatting      (~5-15% of time, if enabled)
```

**Key insight:** JavaScript evaluation is often the bottleneck.

### Typical Performance

**Simple templates (10-50 lines):**
- Compilation: ~0.5-2ms
- Throughput: ~500-2000 ops/sec

**Complex templates (100-500 lines):**
- Compilation: ~5-15ms
- Throughput: ~65-200 ops/sec

**Very complex (1000+ lines):**
- Compilation: ~20-50ms
- Throughput: ~20-50 ops/sec

## Template Optimization

### 1. Minimize Expressions

**❌ Slow:**
```pug
each user in users
  p Total: #{users.reduce(function(sum, u) { return sum + u.score; }, 0)}
```

Every iteration recalculates the total!

**✅ Fast:**
```pug
- var total = users.reduce(function(sum, u) { return sum + u.score; }, 0)
each user in users
  p Total: #{total}
```

### 2. Hoist Invariant Code

**❌ Slow:**
```pug
each item in items
  - var discount = 0.1
  p Price: #{item.price * (1 - discount)}
```

**✅ Fast:**
```pug
- var discount = 0.1
each item in items
  p Price: #{item.price * (1 - discount)}
```

### 3. Cache Method Results

**❌ Slow:**
```pug
each user in users
  p #{user.name.toUpperCase()}
  p Email: #{user.email.toLowerCase()}
  p Display: #{user.name.toUpperCase()}  // Duplicate call!
```

**✅ Fast:**
```pug
each user in users
  - var nameUpper = user.name.toUpperCase()
  - var emailLower = user.email.toLowerCase()
  p #{nameUpper}
  p Email: #{emailLower}
  p Display: #{nameUpper}
```

### 4. Simplify Loops

**❌ Slow:**
```pug
- var i = 0
while i < items.length
  p= items[i].name
  - i++
```

**✅ Fast:**
```pug
each item in items
  p= item.name
```

`each` is optimized internally.

### 5. Reduce Nesting

**❌ Slow:**
```pug
each category in categories
  each product in category.products
    each variant in product.variants
      each image in variant.images
        img(src=image.url)
```

**✅ Fast:**
Flatten data structure before compilation:

```javascript
// Server-side
const allImages = categories.flatMap(c =>
  c.products.flatMap(p =>
    p.variants.flatMap(v =>
      v.images
    )
  )
);

compiler.setArray('images', allImages);
```

```pug
each image in images
  img(src=image.url)
```

### 6. Use Conditionals Wisely

**❌ Slow:**
```pug
each item in items
  if item.type == "A"
    .type-a= item.name
  else if item.type == "B"
    .type-b= item.name
  else if item.type == "C"
    .type-c= item.name
```

**✅ Fast:**
Pre-filter:

```javascript
// Server-side
const itemsByType = {
  A: items.filter(i => i.type === 'A'),
  B: items.filter(i => i.type === 'B'),
  C: items.filter(i => i.type === 'C')
};

compiler.setObject('itemsByType', itemsByType);
```

```pug
.type-a
  each item in itemsByType.A
    p= item.name

.type-b
  each item in itemsByType.B
    p= item.name

.type-c
  each item in itemsByType.C
    p= item.name
```

### 7. Avoid String Concatenation in Loops

**❌ Slow:**
```pug
- var result = ""
each item in items
  - result = result + item.name + ", "
p= result
```

**✅ Fast:**
```pug
p= items.map(function(item) { return item.name; }).join(", ")
```

Or:
```pug
each item, i in items
  if i > 0
    | ,
  = item.name
```

## Runtime Optimization

### 1. Precompute Values

**❌ Slow:**
```javascript
// Computation in template
compiler.compile(template);
```

**✅ Fast:**
```javascript
// Precompute before template
const processedData = {
  fullName: user.firstName + ' ' + user.lastName,
  formattedDate: new Date(user.createdAt).toLocaleDateString(),
  discountedPrice: product.price * 0.9,
  summary: items.length + ' items'
};

compiler.setObject('data', processedData);
```

### 2. Use Efficient Data Structures

**❌ Slow:**
```javascript
// Array lookup in template
compiler.setArray('users', users);
```

```pug
// O(n) lookup!
each userId in followingIds
  - var user = users.filter(function(u) { return u.id == userId; })[0]
  p= user.name
```

**✅ Fast:**
```javascript
// Convert to object (map) for O(1) lookup
const usersById = {};
users.forEach(u => usersById[u.id] = u);

compiler.setObject('usersById', usersById);
```

```pug
// O(1) lookup!
each userId in followingIds
  - var user = usersById[userId]
  p= user.name
```

### 3. Batch Operations

**❌ Slow:**
```pug
each item in items
  - var upperName = item.name.toUpperCase()
  - var lowerEmail = item.email.toLowerCase()
  - var formatted = item.price.toFixed(2)
  p #{upperName} - #{lowerEmail} - $#{formatted}
```

**✅ Fast:**
```javascript
// Server-side batch processing
const processedItems = items.map(item => ({
  upperName: item.name.toUpperCase(),
  lowerEmail: item.email.toLowerCase(),
  formatted: item.price.toFixed(2)
}));

compiler.setArray('processedItems', processedItems);
```

```pug
each item in processedItems
  p #{item.upperName} - #{item.lowerEmail} - $#{item.formatted}
```

### 4. Limit Array Methods

**❌ Slow:**
```pug
p Count: #{items.filter(function(i) { return i.active; }).map(function(i) { return i.id; }).length}
```

**✅ Fast:**
```javascript
// Server-side
const activeCount = items.filter(i => i.active).length;
compiler.setNumber('activeCount', activeCount);
```

```pug
p Count: #{activeCount}
```

## Server-Side Optimization

### 1. Reuse Compiler Instance

**❌ Slow:**
```javascript
app.get('/page', (req, res) => {
  const html = compile(template, data);  // Creates new runtime each time!
  res.send(html);
});
```

**✅ Fast:**
```javascript
const { PugCompiler } = require('zig-pug');
const compiler = new PugCompiler();  // Reuse this!

app.get('/page', (req, res) => {
  compiler.setVariables(data);
  const html = compiler.compile(template);
  res.send(html);
});
```

**Performance gain:** ~20-40% faster.

### 2. Cache Templates

**❌ Slow:**
```javascript
app.get('/page', (req, res) => {
  const template = fs.readFileSync('./template.pug', 'utf-8');  // Read every request!
  const html = compile(template, data);
  res.send(html);
});
```

**✅ Fast:**
```javascript
// Load once at startup
const templates = {
  home: fs.readFileSync('./views/home.pug', 'utf-8'),
  about: fs.readFileSync('./views/about.pug', 'utf-8')
};

app.get('/home', (req, res) => {
  const html = compile(templates.home, data);  // No I/O!
  res.send(html);
});
```

**Performance gain:** ~50-100x faster (eliminates I/O).

### 3. Pre-compile in Production

For ultimate performance, compile templates to HTML at build time:

```javascript
// build.js
const fs = require('fs');
const { compileFile } = require('zig-pug');

const staticPages = ['about', 'terms', 'privacy'];

staticPages.forEach(page => {
  const html = compileFile(`./templates/${page}.pug`, staticData, { minify: true });
  fs.writeFileSync(`./public/${page}.html`, html);
});
```

Then serve static HTML files (nginx, CDN, etc.).

### 4. Use Bun Instead of Node.js

```bash
# Node.js
node server.js
# ~100-250k compilations/sec

# Bun
bun server.js
# ~250-600k compilations/sec (2-5x faster)
```

**Why:** Bun has optimized N-API calls and better memory management.

### 5. Enable HTTP Caching

```javascript
app.get('/page', (req, res) => {
  const html = compile(template, data);

  // Cache for 1 hour
  res.set('Cache-Control', 'public, max-age=3600');
  res.send(html);
});
```

## Output Optimization

### 1. Minify in Production

**Development:**
```javascript
const html = compile(template, data, { format: true });
```

**Production:**
```javascript
const html = compile(template, data, { minify: true });
```

**File size reduction:** ~20-40% smaller.

### 2. Avoid Pretty-Print in Production

**❌ Slow + large:**
```javascript
compile(template, data, { pretty: true });
```

- Larger file size (~30-50% bigger)
- Slower to transmit
- Slower to parse in browser
- Includes comments

**✅ Fast + small:**
```javascript
compile(template, data, { minify: true });
```

### 3. Compress Output

Enable gzip/brotli compression:

```javascript
const compression = require('compression');
app.use(compression());
```

**Size reduction:** ~60-80% smaller for HTML.

## Benchmarking

### Simple Benchmark

```javascript
const { PugCompiler } = require('zig-pug');

const template = `
div
  h1= title
  ul
    each item in items
      li= item
`;

const data = {
  title: 'Benchmark',
  items: ['a', 'b', 'c', 'd', 'e']
};

const compiler = new PugCompiler();
compiler.setVariables(data);

// Warmup
for (let i = 0; i < 1000; i++) {
  compiler.compile(template);
}

// Measure
const iterations = 100000;
const start = Date.now();

for (let i = 0; i < iterations; i++) {
  compiler.compile(template);
}

const elapsed = Date.now() - start;
const ops = Math.floor(iterations / (elapsed / 1000));

console.log(`${iterations} compilations in ${elapsed}ms`);
console.log(`${ops.toLocaleString()} ops/sec`);
```

### Comparison Benchmark

```javascript
function benchmarkApproach(name, fn, iterations = 10000) {
  // Warmup
  for (let i = 0; i < 100; i++) fn();

  const start = Date.now();
  for (let i = 0; i < iterations; i++) fn();
  const elapsed = Date.now() - start;

  console.log(`${name}: ${elapsed}ms (${Math.floor(iterations / (elapsed / 1000))} ops/sec)`);
}

// Compare different approaches
benchmarkApproach('Inline computation', () => {
  compiler.compile('p #{items.reduce(function(sum, x) { return sum + x; }, 0)}');
});

benchmarkApproach('Precomputed', () => {
  const sum = items.reduce((sum, x) => sum + x, 0);
  compiler.setNumber('sum', sum);
  compiler.compile('p #{sum}');
});
```

### Profile with Chrome DevTools

```javascript
// Start profiling
node --inspect server.js

// Open chrome://inspect in Chrome
// Click "inspect" on your Node process
// Go to "Profiler" tab
// Record profile while making requests
```

Identify bottlenecks in JavaScript evaluation or template compilation.

## Performance Checklist

### Template Level
- [ ] Expressions precomputed where possible
- [ ] Loops use `each` instead of `while`
- [ ] Invariant code hoisted out of loops
- [ ] Method results cached
- [ ] Nested loops minimized
- [ ] Data structures optimized (maps vs arrays)

### Server Level
- [ ] Compiler instance reused
- [ ] Templates cached in memory
- [ ] Static pages pre-rendered
- [ ] HTTP caching headers set
- [ ] Compression enabled (gzip/brotli)
- [ ] Using Bun instead of Node (if possible)

### Output Level
- [ ] Minification enabled in production
- [ ] Pretty-print disabled in production
- [ ] CDN used for static assets
- [ ] HTTP/2 enabled

### Monitoring
- [ ] Response times measured
- [ ] Template compilation times tracked
- [ ] Memory usage monitored
- [ ] CPU usage profiled

## Common Performance Issues

### Issue 1: Slow Template Rendering

**Symptom:** High CPU usage, slow response times.

**Diagnosis:**
```javascript
console.time('compile');
const html = compiler.compile(template);
console.timeEnd('compile');
```

**Solutions:**
1. Profile with Chrome DevTools
2. Identify slow expressions
3. Precompute on server
4. Cache results

### Issue 2: High Memory Usage

**Symptom:** Memory grows over time.

**Cause:** Creating new compiler instances.

**Solution:**
```javascript
// ❌ Creates new instance each request
app.get('/page', (req, res) => {
  const compiler = new PugCompiler();  // Memory leak!
  // ...
});

// ✅ Reuse instance
const compiler = new PugCompiler();
app.get('/page', (req, res) => {
  compiler.setVariables(data);
  // ...
});
```

### Issue 3: Slow First Request

**Symptom:** First request slow, subsequent fast.

**Cause:** Template file I/O, runtime initialization.

**Solution:**
```javascript
// Load templates at startup
const templates = {};
fs.readdirSync('./views').forEach(file => {
  templates[file] = fs.readFileSync(`./views/${file}`, 'utf-8');
});

// Warmup compiler
const compiler = new PugCompiler();
compiler.compile('p Warmup');
```

## See Also

- [SECURITY.md](SECURITY.md) - Security best practices
- [../NODEJS-INTEGRATION.md](../NODEJS-INTEGRATION.md) - Server integration
- [JAVASCRIPT.md](JAVASCRIPT.md) - JavaScript performance
