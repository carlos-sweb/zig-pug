# Arrays and Objects Support in zig-pug

Starting from version 0.3.5, zig-pug for Node.js/Bun includes full support for arrays and objects.

## Overview

You can now pass complex data structures to your Pug templates:

- ✅ **Arrays** - Simple and nested arrays
- ✅ **Objects** - Plain objects and nested objects
- ✅ **Mixed structures** - Objects containing arrays, arrays of objects
- ✅ **Auto-detection** - Automatically detects variable types

## API Methods

### setArray(key, value)

Set an array variable in the template context.

```javascript
const compiler = new zigpug.PugCompiler();
compiler.setArray('items', ['apple', 'banana', 'orange']);
```

**Parameters:**
- `key` (string) - Variable name
- `value` (Array) - Array to set

**Returns:** `PugCompiler` instance for chaining

### setObject(key, value)

Set an object variable in the template context.

```javascript
const compiler = new zigpug.PugCompiler();
compiler.setObject('user', {
    name: 'Alice',
    age: 30,
    email: 'alice@example.com'
});
```

**Parameters:**
- `key` (string) - Variable name
- `value` (Object) - Plain object to set (not arrays)

**Returns:** `PugCompiler` instance for chaining

### set(key, value) - Auto-detect

Automatically detects the type and calls the appropriate method.

```javascript
compiler.set('name', 'Alice');          // Calls setString()
compiler.set('age', 30);                // Calls setNumber()
compiler.set('active', true);           // Calls setBool()
compiler.set('items', [1, 2, 3]);       // Calls setArray()
compiler.set('user', { name: 'Bob' });  // Calls setObject()
```

### setVariables(variables)

Set multiple variables at once. Automatically detects types.

```javascript
compiler.setVariables({
    title: 'My Page',                   // String
    count: 42,                          // Number
    active: true,                       // Boolean
    items: ['a', 'b', 'c'],            // Array
    user: { name: 'Alice', age: 30 }   // Object
});
```

## Usage Examples

### Simple Array

**Template:**
```pug
ul
  each item in items
    li= item
```

**JavaScript:**
```javascript
const compiler = new zigpug.PugCompiler();
compiler.setArray('items', ['Apple', 'Banana', 'Orange']);
const html = compiler.compile(template);
```

**Output:**
```html
<ul><li>Apple</li><li>Banana</li><li>Orange</li></ul>
```

### Simple Object

**Template:**
```pug
div.user
  p Name: #{user.name}
  p Email: #{user.email}
  p Age: #{user.age}
```

**JavaScript:**
```javascript
compiler.setObject('user', {
    name: 'Alice Johnson',
    email: 'alice@example.com',
    age: 30
});
```

**Output:**
```html
<div class="user">
  <p>Name: Alice Johnson</p>
  <p>Email: alice@example.com</p>
  <p>Age: 30</p>
</div>
```

### Array of Objects

**Template:**
```pug
div.products
  each product in products
    div.product
      h3= product.name
      p Price: $#{product.price}
      p Stock: #{product.stock} units
```

**JavaScript:**
```javascript
compiler.setArray('products', [
    { name: 'Laptop', price: 999, stock: 5 },
    { name: 'Mouse', price: 25, stock: 50 },
    { name: 'Keyboard', price: 75, stock: 20 }
]);
```

### Nested Objects

**Template:**
```pug
div.company
  h2= company.name
  p Location: #{company.location.city}, #{company.location.country}
  p Founded: #{company.founded}
```

**JavaScript:**
```javascript
compiler.setObject('company', {
    name: 'Tech Corp',
    location: {
        city: 'San Francisco',
        country: 'USA'
    },
    founded: 2010
});
```

### Nested Arrays (Matrix)

**Template:**
```pug
table
  each row in matrix
    tr
      each cell in row
        td= cell
```

**JavaScript:**
```javascript
compiler.setArray('matrix', [
    [1, 2, 3],
    [4, 5, 6],
    [7, 8, 9]
]);
```

**Output:**
```html
<table>
  <tr><td>1</td><td>2</td><td>3</td></tr>
  <tr><td>4</td><td>5</td><td>6</td></tr>
  <tr><td>7</td><td>8</td><td>9</td></tr>
</table>
```

### Object with Array Property

**Template:**
```pug
div.blog-post
  h1= post.title
  p= post.content
  ul.tags
    each tag in post.tags
      li.tag= tag
```

**JavaScript:**
```javascript
compiler.setObject('post', {
    title: 'Introduction to Zig',
    content: 'Zig is a general-purpose programming language...',
    tags: ['programming', 'zig', 'systems']
});
```

### Complete Example

**Template:**
```pug
doctype html
html(lang="en")
  head
    title #{pageTitle}
  body
    h1 Team: #{team.name}

    div.members
      h2 Team Members
      each member in team.members
        div.member
          h3= member.name
          p Role: #{member.role}
          p Email: #{member.email}

    div.projects
      h2 Active Projects
      ul
        each project in projects
          li
            strong= project.name
            |  - #{project.status}
            if project.tags
              ul.tags
                each tag in project.tags
                  li.tag= tag
```

**JavaScript:**
```javascript
const zigpug = require('zig-pug');

const html = zigpug.compile(template, {
    pageTitle: 'Engineering Team',
    team: {
        name: 'Core Engineering',
        members: [
            { name: 'Alice', role: 'Lead Developer', email: 'alice@example.com' },
            { name: 'Bob', role: 'Frontend Developer', email: 'bob@example.com' },
            { name: 'Carol', role: 'Backend Developer', email: 'carol@example.com' }
        ]
    },
    projects: [
        {
            name: 'Authentication System',
            status: 'In Progress',
            tags: ['security', 'backend']
        },
        {
            name: 'UI Redesign',
            status: 'Planning',
            tags: ['frontend', 'design', 'ux']
        }
    ]
});

console.log(html);
```

## Method Chaining

All setter methods return the compiler instance, allowing for method chaining:

```javascript
const html = new zigpug.PugCompiler()
    .setString('title', 'My App')
    .setNumber('version', 2.0)
    .setBool('production', true)
    .setArray('features', ['Fast', 'Secure', 'Scalable'])
    .setObject('author', { name: 'Alice', email: 'alice@example.com' })
    .compile(template);
```

## Convenience Methods

### compile(template, variables)

Quick compilation with variables in one call:

```javascript
const html = zigpug.compile(template, {
    items: ['a', 'b', 'c'],
    user: { name: 'Alice' }
});
```

### render(template, variables)

Same as compile, but called on a compiler instance:

```javascript
const compiler = new zigpug.PugCompiler();
const html = compiler.render(template, {
    items: ['a', 'b', 'c'],
    user: { name: 'Alice' }
});
```

## Supported Data Types

| Type | Method | Auto-detect | Example |
|------|--------|-------------|---------|
| String | `setString()` | ✅ | `'hello'` |
| Number | `setNumber()` | ✅ | `42` |
| Boolean | `setBool()` | ✅ | `true` |
| Array | `setArray()` | ✅ | `[1, 2, 3]` |
| Object | `setObject()` | ✅ | `{name: 'Alice'}` |
| Nested structures | Multiple methods | ✅ | Complex objects/arrays |

## Bun.js Support

All array and object features work identically in Bun.js:

```javascript
// Bun.js
import { PugCompiler } from 'zig-pug';

const compiler = new PugCompiler();
compiler.setArray('items', ['fast', 'native', 'awesome']);
const html = compiler.compile('each item in items\n  li= item');

console.log(html);
// <li>fast</li><li>native</li><li>awesome</li>
```

**Note:** Bun.js is 2-5x faster than Node.js!

## Type Safety

The API includes runtime type checking:

```javascript
compiler.setArray('items', 'not an array');
// TypeError: Value must be an array

compiler.setObject('user', ['not', 'an', 'object']);
// TypeError: Value must be a plain object
```

## Examples

See the `examples/` directory for complete working examples:

- `examples/nodejs/06-arrays-objects.js` - Comprehensive Node.js examples
- `examples/bun/06-arrays-objects.js` - Bun.js examples
- `nodejs/test-arrays-objects.js` - Full test suite

## Running Examples

```bash
# Node.js examples
cd examples/nodejs
node 06-arrays-objects.js

# Bun examples
cd examples/bun
bun run 06-arrays-objects.js

# Run tests
cd nodejs
node test-arrays-objects.js
```

## Performance

Array and object variables are serialized to JSON and parsed by the Zig runtime for optimal performance:

- **Fast serialization** - Native JavaScript JSON.stringify()
- **Fast parsing** - Zig's std.json parser
- **Zero-copy** - Data is referenced, not duplicated when possible

## Limitations

- Objects must be plain JavaScript objects (not class instances)
- Arrays can contain any JSON-serializable types
- Nested structures are fully supported
- ES5.1 JavaScript in templates (no arrow functions, template literals, etc.)

## Migration from CLI

If you were using JSON files with the CLI, you can easily migrate to the Node.js API:

**Before (CLI):**
```bash
zpug template.pug --vars data.json
```

**data.json:**
```json
{
  "items": ["a", "b", "c"],
  "user": {"name": "Alice"}
}
```

**After (Node.js):**
```javascript
const fs = require('fs');
const zigpug = require('zig-pug');

const template = fs.readFileSync('template.pug', 'utf-8');
const data = JSON.parse(fs.readFileSync('data.json', 'utf-8'));

const html = zigpug.compile(template, data);
```

## Troubleshooting

**Q: My arrays aren't rendering**
- Make sure you're using the `each` keyword in your template
- Verify the array is actually an array: `Array.isArray(yourArray)`

**Q: Object properties are undefined**
- Check property names match exactly (case-sensitive)
- Ensure the object is a plain object, not a class instance

**Q: Getting "Value must be an array" error**
- You're passing a non-array to `setArray()`. Use `set()` for auto-detection.

**Q: Performance with large arrays**
- JSON serialization/parsing is very fast
- Consider chunking very large datasets (10,000+ items)
- Profile your application to identify actual bottlenecks

## See Also

- [Main README](README.md) - General documentation
- [CLI Documentation](../docs/en/CLI.md) - Command-line usage
- [Examples](../examples/) - More examples
