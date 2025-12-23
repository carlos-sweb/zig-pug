# Compiler - HTML Generation

The **Compiler** is the final phase of the zig-pug compilation pipeline. It walks the AST and generates HTML output, handling JavaScript evaluation, template composition, and security features.

## Overview

The compiler transforms an AST into HTML by:

- **Walking the tree**: Depth-first traversal of AST nodes
- **Evaluating expressions**: JavaScript code execution via mujs runtime
- **Generating HTML**: Converting nodes to HTML strings
- **Escaping content**: Preventing XSS attacks
- **Template features**: Mixins, includes, inheritance
- **Error handling**: Structured compilation errors

## Architecture

### Location: `src/compiler/`

```
src/compiler/
├── mod.zig        # Main Compiler struct and compilation logic
├── errors.zig     # Error type definitions
├── escaping.zig   # HTML/comment escaping utilities
├── tests.zig      # Compiler test suite
└── compile/       # Future: compilation functions by node type
```

## Compiler Structure

### Compiler Struct

```zig
pub const Compiler = struct {
    allocator: std.mem.Allocator,
    runtime: *JsRuntime,                     // JavaScript engine
    output: std.ArrayList(u8),                // HTML output buffer
    indent_level: usize,                      // Current indentation
    pretty: bool,                             // Pretty-print mode
    mixins: std.StringHashMap(*AstNode),      // Mixin definitions
    base_path: ?[]const u8,                   // Base path for includes
    template_cache: ?*TemplateCache,          // Optional caching
    child_blocks: std.StringHashMap(ChildBlockInfo),  // Template inheritance
    include_comments: bool,                   // Include HTML comments
    has_errors: bool,                         // Compilation errors occurred
    errors: std.ArrayList(CompilationError),  // Error list
};
```

## Compilation Process

### Main Flow

1. **Initialize**: Create compiler with JavaScript runtime
2. **Set context**: Add variables to JS scope
3. **Compile**: Walk AST and generate HTML
4. **Return**: HTML string or error

### Node Compilation

Each AST node type has a compilation function:

```zig
compileNode(node)
  ├─> compileDocument()
  ├─> compileTag()
  ├─> compileText()
  ├─> compileInterpolation()
  ├─> compileCode()
  ├─> compileComment()
  ├─> compileConditional()
  ├─> compileLoop()
  ├─> compileCase()
  ├─> compileMixinCall()
  ├─> compileInclude()
  ├─> compileExtends()
  └─> compileBlock()
```

## Compilation Features

### 1. Tag Compilation

Converts tag nodes to HTML elements:

**Input**:
```pug
div.container#main(data-value="test")
  p Hello
```

**Output**:
```html
<div class="container" id="main" data-value="test"><p>Hello</p></div>
```

**Process**:
1. Emit opening tag: `<div`
2. Compile attributes: ` class="container" id="main" data-value="test"`
3. Close opening tag: `>`
4. Recursively compile children
5. Emit closing tag: `</div>`

### 2. Attribute Compilation

Handles different attribute types:

```pug
a(href="/home")              // Static: href="/home"
a(href=link)                 // Expression: evaluate 'link'
a(class="btn" disabled)      // Boolean: disabled (no value)
a(data-html!=content)        // Unescaped: raw HTML
```

**Security**:
- Static values: HTML-escaped
- Expressions: Evaluated, then escaped
- Unescaped (`!=`): Not escaped (use carefully!)
- Boolean: Attribute name only

### 3. Text & Interpolation

Plain text and embedded expressions:

```pug
p Hello #{name}              // Escaped interpolation
p !{rawHtml}                 // Unescaped (raw HTML)
| Plain text content
```

**Process**:
- Text: HTML-escaped by default
- `#{expr}`: Evaluate → escape → output
- `!{expr}`: Evaluate → output (no escaping)

### 4. Code Execution

JavaScript code evaluation:

```pug
= user.name                  // Output escaped
!= rawHtml                   // Output unescaped
- var x = 10                 // Execute only (no output)
```

**JavaScript Runtime**:
- Uses **mujs** (ES5.1 JavaScript engine)
- Variables set via `runtime.setVariable()`
- Expressions evaluated with `runtime.eval()`

### 5. Conditionals

If/else/unless control flow:

```pug
if admin
  button Edit
else
  p View only
```

**Process**:
1. Evaluate condition: `runtime.eval("admin")`
2. Check if truthy
3. Compile appropriate branch
4. `unless` inverts the logic

### 6. Loops

Iteration over arrays:

```pug
each item in items
  li= item

each item, index in items
  li #{index}: #{item}
```

**Process**:
1. Evaluate iterable: `runtime.eval("items")`
2. Check if array
3. For each element:
   - Set iterator variable: `runtime.setVariable("item", value)`
   - Set index variable (if specified)
   - Compile loop body
4. Compile else branch if array is empty

### 7. Case Statements

Switch-like matching:

```pug
case color
  when 'red'
    p Red
  when 'blue', 'cyan'
    p Blue-ish
  default
    p Unknown
```

**Process**:
1. Evaluate expression: `runtime.eval("color")`
2. For each when clause:
   - Check if value matches any when value
   - If match, compile body and break
3. If no match, compile default clause

### 8. Mixins

Reusable template blocks:

```pug
mixin article(title)
  article
    h1= title

+article("Hello World")
```

**Process**:
1. **Definition**: Store mixin in `mixins` map
2. **Call**:
   - Lookup mixin by name
   - Set parameter variables
   - Compile mixin body
   - Restore previous scope

### 9. Includes

Include other templates:

```pug
include header.pug
```

**Process**:
1. Resolve path relative to `base_path`
2. Read included file
3. Parse included template
4. Compile included AST
5. Insert result into output

**Caching**:
- Uses `template_cache` if provided
- Avoids re-parsing same file

### 10. Template Inheritance

Extends/block pattern:

**layout.pug**:
```pug
html
  body
    block content
      p Default
```

**page.pug**:
```pug
extends layout.pug

block content
  p Custom content
```

**Process**:
1. Parse child template
2. Collect block definitions
3. Parse parent template
4. Replace/append/prepend blocks
5. Compile final tree

## Security Features

### HTML Escaping

Prevents XSS attacks by escaping special characters:

```
&  →  &amp;
<  →  &lt;
>  →  &gt;
"  →  &quot;
'  →  &#39;
```

**Implementation**: `escaping.escapeHtml()`

**When Applied**:
- Text content (always)
- Attribute values (always)
- Interpolations `#{expr}` (always)
- NOT on `!{expr}` or `!=` (user responsibility!)

### Comment Escaping

Prevents comment injection:

```
--  →  - -
```

Prevents premature comment closing: `<!-- comment --> <script>`

**Implementation**: `escaping.escapeComment()`

### Expression Evaluation

JavaScript code runs in isolated mujs context:

- No access to filesystem
- No access to network
- Only provided variables available
- Pure computation

## Output Modes

### Standard Mode (Minified)

Minimal HTML, no whitespace:

```html
<div><p>Hello</p></div>
```

- No indentation
- No comments (`include_comments = false`)
- Smallest file size

### Pretty Mode

Human-readable HTML with indentation:

```html
<div>
  <p>Hello</p>
</div>
```

- Indentation tracking
- Comments included (`include_comments = true`)
- Easier debugging

Enable with:
```zig
compiler.pretty = true;
compiler.include_comments = true;
```

## Error Handling

### Structured Errors

The compiler provides detailed error information:

```zig
pub const CompilationError = struct {
    type: ErrorType,
    line: usize,
    message: [:0]const u8,
    detail: ?[:0]const u8,
    hint: ?[:0]const u8,
};
```

### Error Types

- `LoopIterableEvalFailed`: Can't evaluate loop iterable
- `ConditionalEvalFailed`: Can't evaluate condition
- `InterpolationEvalFailed`: Can't evaluate interpolation
- `AttributeEvalFailed`: Can't evaluate attribute value
- `CodeExecutionFailed`: JavaScript error
- `CaseEvalFailed`: Can't evaluate case expression
- `MixinNotFound`: Undefined mixin called
- `IncludeFileNotFound`: Include file missing
- `ExtendsFileNotFound`: Parent template missing

### Error Collection

Compiler can continue on errors and collect all issues:

```zig
const html = compiler.compile(ast) catch {
    for (compiler.errors.items) |err| {
        std.debug.print("Error at line {}: {s}\n", .{
            err.line,
            err.message
        });
        if (err.detail) |detail| {
            std.debug.print("  Detail: {s}\n", .{detail});
        }
        if (err.hint) |hint| {
            std.debug.print("  Hint: {s}\n", .{hint});
        }
    }
    return error.CompilationFailed;
};
```

## API Usage

### Basic Compilation

```zig
const Compiler = @import("compiler/mod.zig").Compiler;
const JsRuntime = @import("runtime.zig").JsRuntime;

// Initialize JavaScript runtime
var js_runtime = try JsRuntime.init(allocator);
defer js_runtime.deinit();

// Set variables
try js_runtime.setVariable("name", "John");
try js_runtime.setVariable("admin", true);

// Initialize compiler
var compiler = try Compiler.init(allocator, js_runtime);
defer compiler.deinit();

// Compile AST to HTML
const html = try compiler.compile(ast);
defer allocator.free(html);
```

### With Pretty Printing

```zig
var compiler = try Compiler.init(allocator, js_runtime);
defer compiler.deinit();

compiler.pretty = true;
compiler.include_comments = true;

const html = try compiler.compile(ast);
defer allocator.free(html);
```

### With Template Cache

```zig
var cache = TemplateCache.init(allocator);
defer cache.deinit();

var compiler = try Compiler.init(allocator, js_runtime);
defer compiler.deinit();

compiler.template_cache = &cache;
compiler.base_path = "/path/to/templates";

const html = try compiler.compile(ast);
defer allocator.free(html);
```

## Performance

### Optimizations

- **Single-pass**: AST walked once
- **Buffer reuse**: Output buffer grows, not reallocated
- **Template caching**: Parsed templates cached
- **Zero-copy**: Text nodes reference source
- **Escaping**: Pre-calculates size, single allocation

### Benchmarks

Typical performance (varies by template complexity):

- Simple tag: ~100ns
- Loop (10 items): ~5µs
- Full page template: ~50-500µs

## Testing

Run compiler tests:
```bash
zig test src/compiler/tests.zig
```

Tests cover:
- All node types
- JavaScript evaluation
- Error cases
- Edge cases
- Security (XSS prevention)

## See Also

- [Tokenizer](tokenizer.md) - Lexical analysis
- [Parser](parser.md) - Syntax analysis
- [AST](ast.md) - Abstract Syntax Tree (compiler input)
