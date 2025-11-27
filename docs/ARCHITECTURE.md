# zig-pug Architecture

Complete guide to the internal architecture and execution flow of zig-pug.

---

## 📊 High-Level Flow

```
Template Source (.zpug)
        ↓
   [TOKENIZER] ← Lexical Analysis
        ↓
     Tokens
        ↓
     [PARSER] ← Syntactic Analysis
        ↓
       AST
        ↓
   [COMPILER] ← Code Generation
        ↓ (uses runtime for #{...})
        ↓
   HTML Output
```

---

## 🗂️ Source Files Overview

| File | Responsibility | Input | Output |
|------|---------------|-------|--------|
| `tokenizer.zig` | Lexical analysis | Source text | Token stream |
| `parser.zig` | Syntactic analysis | Tokens | AST |
| `ast.zig` | Data structures | - | AST definitions |
| `compiler.zig` | HTML generation | AST | HTML string |
| `runtime.zig` | JS execution | JS expressions | Values |
| `mujs_wrapper.zig` | C bindings | - | mujs FFI |
| `cache.zig` | Template caching | File paths | Cached ASTs |
| `cli.zig` | CLI interface | Arguments | Orchestration |
| `utils.zig` | Utilities | - | Helper functions |
| `lib.zig` | Public API | - | Library interface |
| `main.zig` | Entry point | - | Termux CLI |

---

## 🔄 Complete Execution Cycle

### Phase 1: CLI Input Processing

**File:** `cli.zig`

**Entry:** `pub fn main()`

```zig
1. Parse command-line arguments
   - Input files (-i, --input)
   - Output path (-o, --output)
   - Variables (--var, --vars)
   - Flags (--pretty, --format, --minify)

2. Load variables
   - Parse --var key=value pairs
   - Load --vars JSON file
   - Inject into runtime

3. Read template file
   - fs.cwd().readFileAlloc()
   - Error handling for missing files
```

**Key Functions:**
- `parseArguments()` → Parse CLI args
- `compileFile()` → Main compilation orchestrator
- `compileFromStdin()` → Handle stdin input

---

### Phase 2: Tokenization

**File:** `tokenizer.zig`

**Entry:** `Tokenizer.init(allocator, source)`

```zig
Tokenizer {
    source: []const u8,        // Original template
    pos: usize,                // Current position
    line: usize,               // Current line
    column: usize,             // Current column
    indent_stack: [],          // Track indentation levels
    pending_tokens: [],        // Buffered tokens
    at_line_start: bool,       // For indent detection
}
```

**Token Types:**
```zig
pub const TokenType = enum {
    // Identifiers
    Ident,              // tag, variable names
    Class,              // .classname
    Id,                 // #idname

    // Literals
    String,             // "text" or 'text'
    Number,             // 42, 3.14
    Boolean,            // true, false

    // Symbols
    LParen, RParen,     // ( )
    LBracket, RBracket, // [ ]
    Comma, Colon,       // , :
    Pipe,               // |

    // Keywords
    If, Else, Unless,
    Each, While,
    Case, When, Default,
    Mixin, Include, Extends,
    Block, Append, Prepend,
    Doctype,

    // Special
    Indent, Dedent,     // Indentation changes
    Newline,            // \n
    BufferedComment,    // //
    UnbufferedComment,  // //-
    BufferedCode,       // =
    UnbufferedCode,     // -
    UnescapedCode,      // !=
    EscapedInterpol,    // #{...}
    UnescapedInterpol,  // !{...}

    Eof,
};
```

**Scanning Process:**
```
1. At line start:
   - Calculate indentation (spaces/tabs)
   - Compare with indent_stack
   - Emit INDENT or DEDENT tokens

2. Skip whitespace (except newlines)

3. Detect token type by first character:
   - '\n' → Newline
   - '//' → Comment
   - '#{' → EscapedInterpol
   - '!{' → UnescapedInterpol
   - '"' or '\'' → String
   - digit → Number
   - letter → Ident or Keyword
   - symbol → Operator/Symbol

4. Scan full token value

5. Return Token{type, value, line, column}
```

**Key Functions:**
- `scan()` → Get next token
- `scanInterpolation()` → Parse #{...}
- `scanString()` → Parse quoted strings
- `scanNumber()` → Parse numbers
- `scanIdentifier()` → Parse identifiers/keywords
- `scanComment()` → Parse comments

**Example:**
```zpug
p Hello #{name}
```

Tokens:
```
Ident("p", line=1, col=1)
Ident("Hello", line=1, col=3)
EscapedInterpol("name", line=1, col=9)
Newline("\n", line=1, col=16)
```

---

### Phase 3: Parsing

**File:** `parser.zig`

**Entry:** `Parser.init(allocator, source)`

```zig
Parser {
    allocator: Allocator,
    arena: ArenaAllocator,     // For AST nodes
    tokens: []Token,           // Token stream
    current: Token,            // Current token
    index: usize,              // Token index
}
```

**Parsing Strategy:** Recursive Descent

**Main Parse Functions:**

```zig
// Top-level
parse() → *AstNode               // Entry point
parseChildren() → []AstNode      // Parse indented block

// Statements
parseTag() → *AstNode            // p, div, etc.
parseDoctype() → *AstNode        // doctype html
parseText() → *AstNode           // Plain text
parseCode() → *AstNode           // - code, = code
parseComment() → *AstNode        // //, //-
parseConditional() → *AstNode    // if, else, unless
parseLoop() → *AstNode           // each item in items
parseCase() → *AstNode           // case/when
parseMixin() → *AstNode          // mixin/+mixin
parseInclude() → *AstNode        // include file
parseExtends() → *AstNode        // extends layout

// Inline content
parseInlineText() → []*AstNode   // Text with #{...}
parsePipeText() → *AstNode       // | piped text

// Attributes
parseAttributes() → []Attribute  // (href="url")
```

**Tag Parsing Example:**
```zpug
div.container#main(data-value="test") Hello #{name}
```

Parse steps:
```
1. parseTag() called
2. Expect Ident("div")
3. Loop: match Class/Id
   - Class("container") → collect
   - Id("main") → collect
4. Match LParen → parseAttributes()
   - Attribute{name="data-value", value="test"}
5. parseInlineText()
   - Text("Hello ")
   - Interpolation("name")
6. Return Tag node with:
   - name: "div"
   - attributes: [class="container", id="main", data-value="test"]
   - children: [Text("Hello "), Interpolation("name")]
```

**Key Functions:**
- `match()` → Check if current token matches type
- `expect()` → Require token type or error
- `advance()` → Move to next token
- `skipNewlines()` → Skip Newline tokens

---

### Phase 4: AST Structure

**File:** `ast.zig`

**Core Structure:**
```zig
pub const AstNode = struct {
    type: NodeType,
    line: usize,
    column: usize,
    data: NodeData,
};

pub const NodeType = enum {
    Root,
    Tag,
    Text,
    Doctype,
    Comment,
    Code,
    Interpolation,
    Conditional,
    Loop,
    Case,
    Mixin,
    MixinCall,
    Include,
    Extends,
    Block,
};

pub const NodeData = union(NodeType) {
    Root: struct {
        children: []AstNode,
    },

    Tag: struct {
        name: []const u8,
        attributes: []Attribute,
        children: []AstNode,
        is_self_closing: bool,
    },

    Text: struct {
        content: []const u8,
        is_raw: bool,           // pipe text
    },

    Interpolation: struct {
        expression: []const u8,  // "name" from #{name}
        is_unescaped: bool,     // !{} vs #{}
    },

    Code: struct {
        code: []const u8,
        is_buffered: bool,      // = vs -
        is_unescaped: bool,     // != vs =
    },

    Conditional: struct {
        condition: []const u8,
        consequent: []AstNode,
        alternate: ?[]AstNode,
        is_unless: bool,
    },

    Loop: struct {
        iterable: []const u8,   // "items"
        value_var: []const u8,  // "item"
        index_var: ?[]const u8, // optional index
        body: []AstNode,
    },

    // ... etc
};
```

**AST Example:**
```zpug
div
  p Hello
  p World
```

AST:
```
Root {
  children: [
    Tag {
      name: "div",
      attributes: [],
      children: [
        Tag {
          name: "p",
          children: [Text("Hello")]
        },
        Tag {
          name: "p",
          children: [Text("World")]
        }
      ]
    }
  ]
}
```

---

### Phase 5: Compilation

**File:** `compiler.zig`

**Entry:** `Compiler.init(allocator, runtime)`

```zig
Compiler {
    allocator: Allocator,
    runtime: *JsRuntime,        // For #{...} evaluation
    output: ArrayList(u8),      // HTML accumulator
    indent_level: usize,        // Current indent
    pretty: bool,               // Pretty-print mode
    include_comments: bool,     // Include buffered comments
    has_errors: bool,           // Error tracking
    mixins: HashMap,            // Mixin definitions
    base_path: ?[]u8,           // For includes
    template_cache: ?*Cache,    // Template cache
    child_blocks: HashMap,      // Block overrides
}
```

**Compilation Process:**
```
1. compile(ast) → Walk AST nodes

2. For each node type:
   - Tag → compileTag()
   - Text → compileText()
   - Interpolation → compileInterpolation()
   - Code → compileCode()
   - Conditional → compileConditional()
   - Loop → compileLoop()
   - Comment → compileComment()
   - etc.

3. Output accumulates in output: ArrayList(u8)

4. Return HTML string
```

**Key Compilation Functions:**

```zig
// Tag compilation
compileTag(node) {
    1. Write opening tag: <tagname
    2. Compile attributes: attr="value"
    3. Close opening tag: >
    4. Recursively compile children
    5. Write closing tag: </tagname>
}

// Interpolation compilation
compileInterpolation(node) {
    1. Get expression: "name"
    2. Evaluate with runtime: runtime.eval("name")
    3. Escape HTML if needed
    4. Append to output
}

// Conditional compilation
compileConditional(node) {
    1. Evaluate condition: runtime.eval("isLoggedIn")
    2. Check truthiness
    3. Compile consequent if true
    4. Compile alternate if false
}

// Loop compilation
compileLoop(node) {
    1. Evaluate iterable: runtime.eval("items")
    2. Parse as JSON array
    3. For each item:
       - Set loop variable in runtime
       - Set index variable if present
       - Compile loop body
}
```

**HTML Escaping:**
```zig
escapeHtml(text) {
    & → &amp;
    < → &lt;
    > → &gt;
    " → &quot;
    ' → &#39;
}
```

**Attribute Compilation:**
```zig
compileAttribute(attr) {
    if attr.is_expression {
        // Dynamic: (class=myClass)
        value = runtime.eval(attr.value)
    } else {
        // Static: (class="container")
        value = attr.value
    }

    if attr.is_unescaped {
        append(value)
    } else {
        append(escapeHtml(value))
    }
}
```

---

### Phase 6: JavaScript Runtime

**File:** `runtime.zig`

**Entry:** `JsRuntime.init(allocator)`

```zig
JsRuntime {
    state: *mujs.js_State,   // mujs C state
    allocator: Allocator,
}
```

**Key Operations:**

```zig
// Evaluate expression
eval(expr: []u8) → []u8 {
    1. mujs.js_dostring(state, expr)
    2. Get result from stack
    3. Convert to string
    4. Return Zig string
}

// Set variable
setGlobal(name, value) {
    1. Convert value to JS type
    2. mujs.js_setglobal(state, name)
}

// Get variable
getGlobal(name) → []u8 {
    1. mujs.js_getglobal(state, name)
    2. Convert from stack to string
}
```

**mujs Integration:**
```zig
// File: mujs_wrapper.zig
// C function declarations for mujs

pub extern fn js_newstate(
    alloc: ?*anyopaque,
    actx: ?*anyopaque,
    flags: c_int
) ?*js_State;

pub extern fn js_dostring(
    J: ?*js_State,
    source: [*c]const u8
) c_int;

pub extern fn js_getstring(
    J: ?*js_State,
    idx: c_int
) [*c]const u8;
```

**Example Usage:**
```zig
var runtime = try JsRuntime.init(allocator);
try runtime.setGlobal("name", "Alice");
const result = try runtime.eval("name.toUpperCase()");
// result = "ALICE"
```

---

### Phase 7: Template Caching

**File:** `cache.zig`

**Purpose:** Cache parsed ASTs to avoid re-parsing

```zig
TemplateCache {
    allocator: Allocator,
    cache: HashMap([]u8, CachedTemplate),
}

CachedTemplate {
    ast: *AstNode,
    mtime: i128,           // File modification time
    dependencies: [][]u8,  // Included files
}
```

**Cache Flow:**
```
1. Check if file in cache
2. Compare mtime with cached mtime
3. If unchanged:
   - Return cached AST
4. If changed:
   - Parse new AST
   - Update cache
   - Track dependencies
```

**Key Functions:**
```zig
get(path) → ?*AstNode
put(path, ast, mtime)
invalidate(path)
```

---

## 🎯 Extension Points

### 1. Custom Built-in Functions

**Location:** `compiler.zig:compileInterpolation()`

**Add to runtime before compilation:**
```zig
// In cli.zig, before comp.compile()
_ = try js_runtime.eval(
    \\function formatDate(date) {
    \\  return new Date(date).toLocaleDateString();
    \\}
    \\function uppercase(str) {
    \\  return str.toUpperCase();
    \\}
);
```

### 2. Custom Tag Types

**Location:** `parser.zig:parseTag()`

**Check for custom syntax:**
```zig
if (std.mem.eql(u8, tag_name, "custom")) {
    return parseCustomTag();
}
```

### 3. Custom Filters

**Location:** `compiler.zig:compileText()`

**Add filter processing:**
```zig
if (node.data.Text.has_filter) {
    content = applyFilter(content, node.filter_name);
}
```

### 4. Source Maps

**Location:** `compiler.zig`

**Track source positions:**
```zig
SourceMap {
    mappings: []Mapping,
}

Mapping {
    generated_line: usize,
    generated_column: usize,
    source_line: usize,
    source_column: usize,
}
```

### 5. Custom Output Formats

**Location:** `compiler.zig:compile()`

**Choose format:**
```zig
fn compile(ast, format: OutputFormat) {
    switch (format) {
        .html => compileToHtml(ast),
        .jsx => compileToJsx(ast),
        .markdown => compileToMarkdown(ast),
    }
}
```

### 6. Plugins System

**Create:** `src/plugins.zig`

```zig
Plugin {
    name: []const u8,

    // Hooks
    beforeParse: ?fn(*Parser) void,
    afterParse: ?fn(*AstNode) void,
    beforeCompile: ?fn(*Compiler) void,
    afterCompile: ?fn([]u8) void,
}

PluginManager {
    plugins: []Plugin,

    fn runHook(name: []const u8, data: anytype) {
        for (plugins) |plugin| {
            if (plugin.hooks.get(name)) |hook| {
                hook(data);
            }
        }
    }
}
```

---

## 🐛 Debugging Guide

### Enable Debug Output

**In tokenizer.zig:**
```zig
pub fn scan(self: *Tokenizer) !Token {
    const token = try self.scanNext();
    std.debug.print("Token: {s} = '{s}'\n", .{
        @tagName(token.type),
        token.value
    });
    return token;
}
```

**In parser.zig:**
```zig
pub fn parse(self: *Parser) !*AstNode {
    const ast = try self.parseRoot();
    try self.printAst(ast, 0);
    return ast;
}

fn printAst(node: *AstNode, depth: usize) void {
    var i: usize = 0;
    while (i < depth) : (i += 1) {
        std.debug.print("  ", .{});
    }
    std.debug.print("{s}\n", .{@tagName(node.type)});
    // ... recurse children
}
```

**In compiler.zig:**
```zig
fn compileNode(self: *Compiler, node: *AstNode) !void {
    std.debug.print("Compiling: {s}\n", .{@tagName(node.type)});
    // ... existing code
}
```

### Common Issues

**1. Indentation errors:**
- Check `tokenizer.zig:handleIndentation()`
- Verify indent_stack logic

**2. Missing interpolation output:**
- Check `runtime.zig:eval()` return value
- Verify mujs error handling

**3. Wrong HTML structure:**
- Print AST before compilation
- Verify parser.zig logic

**4. Escape issues:**
- Check `compiler.zig:escapeHtml()`
- Verify is_unescaped flags

---

## 📈 Performance Optimization Points

### 1. String Building
**Current:** `ArrayList(u8).append()`
**Optimize:** Pre-allocate based on AST size estimate

### 2. Runtime Calls
**Current:** `runtime.eval()` per interpolation
**Optimize:** Batch evaluate all expressions

### 3. Token Scanning
**Current:** Character-by-character
**Optimize:** SIMD-accelerated scanning

### 4. AST Allocation
**Current:** ArenaAllocator
**Already optimal:** Arena is fast for this use case

### 5. Cache Lookup
**Current:** HashMap with string keys
**Optimize:** Intern strings, use integer keys

---

## 🔬 Testing Strategy

### Unit Tests

**Per-module tests:**
```zig
// In tokenizer.zig
test "tokenize simple tag" {
    var tok = try Tokenizer.init(test_alloc, "p Hello");
    const t1 = try tok.scan();
    try expect(t1.type == .Ident);
    try expect(std.mem.eql(u8, t1.value, "p"));
}
```

**Integration tests:**
```zig
// In tests/integration.zig
test "compile full template" {
    const source = "p Hello #{name}";
    const html = try compileFull(source, .{.name = "World"});
    try expect(std.mem.eql(u8, html, "<p>Hello World</p>"));
}
```

### CLI Tests

**Location:** `tests/cli/*.zpug`

**Run:** `./zig-out/bin/zpug tests/cli/01-basic.zpug`

---

## 📚 Resources

- **Zig docs:** https://ziglang.org/documentation/
- **mujs docs:** https://mujs.com/docs/
- **Pug syntax:** https://pugjs.org/
- **AST design:** https://en.wikipedia.org/wiki/Abstract_syntax_tree

---

**Generated:** 2025-11-24
**Version:** 0.3.0
**Maintainer:** zig-pug team
