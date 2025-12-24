# Parser - Syntax Analysis

The **Parser** is the second phase of the zig-pug compilation pipeline. It converts the token stream from the tokenizer into an Abstract Syntax Tree (AST) that represents the template's structure.

## Overview

The parser consumes tokens and builds a hierarchical tree structure that represents the template. It handles:

- **Recursive descent parsing** for grammar rules
- **Indentation-based nesting** (block structure)
- **Attribute parsing** with expressions
- **Control flow structures** (if/else, loops, case)
- **Template features** (mixins, includes, extends)
- **Error recovery** with helpful messages

## Architecture

### Location: `src/parser/`

```
src/parser/
├── mod.zig           # Main Parser struct and entry point
├── helpers.zig       # Common parser utilities (advance, expect, match)
├── tag.zig           # HTML tag parsing
├── text.zig          # Text and interpolation parsing
├── code.zig          # Code blocks and comments
├── attributes.zig    # Attribute parsing
├── conditionals.zig  # if/else/unless statements
├── loops.zig         # each/while loops
├── case.zig          # case/when statements
├── mixins.zig        # Mixin definitions and calls
├── templates.zig     # include/extends/block directives
└── tests.zig         # Parser test suite
```

## Parsing Strategy

### Recursive Descent

The parser uses **recursive descent** where each grammar rule has its own function:

```zig
parseStatement()
  ├─> parseTag()
  ├─> parseConditional()
  ├─> parseLoop()
  ├─> parseCode()
  └─> parseMixinCall()
```

### Indentation Awareness

The parser uses `INDENT`/`DEDENT` tokens to understand block structure:

```pug
if condition
  INDENT
    p Content    # Nested in 'if' block
  DEDENT
p Outside        # Not nested
```

## Parser Components

### 1. Main Parser (`mod.zig`)

**Parser Struct**:
```zig
pub const Parser = struct {
    tokenizer: tokenizer.Tokenizer,  // Token source
    current: tokenizer.Token,        // Lookahead token
    allocator: std.mem.Allocator,    // Base allocator
    arena: std.heap.ArenaAllocator,  // AST node arena
}
```

**Main Functions**:
- `init()`: Initialize parser with source code
- `parse()`: Parse complete template → Document node
- `parseStatement()`: Parse single statement
- `deinit()`: Clean up parser and all AST nodes

### 2. Tags (`tag.zig`)

Parses HTML tags with attributes and children:

```pug
div.container#main(data-value="test")
  p Content
```

**Functions**:
- `parseTag()`: Parse tag with name
- `parseImplicitDiv()`: Parse `.class` / `#id` without tag
- Handles: tag names, classes, IDs, attributes, children

### 3. Attributes (`attributes.zig`)

Parses attribute lists inside parentheses:

```pug
a(href="/home" class="link" target="_blank")
input(type="checkbox" checked)
div(class=myVar data-count=items.length)
```

**Attribute Types**:
- **Literal**: `href="/home"` (static string)
- **Expression**: `class=myVar` (JavaScript variable)
- **Complex Expression**: `class="alert alert-"+type` (string concatenation)
- **Boolean**: `checked` (no value)
- **Unescaped**: `data-html!=content` (raw HTML)

**Complex Expressions** (v4.0.0+):

Attributes now support complex JavaScript expressions with operators:

```pug
// String concatenation
div(class="alert alert-"+alertType)

// Multiple concatenations
div(class="btn btn-"+size+" btn-"+variant)

// Numeric concatenation
div(id="user-"+userId)

// Object property access
a(href=user.profile.url)

// Array access
div(data-first=items[0])
```

**Supported Operators**:
- `+` - Addition/concatenation
- `-` - Subtraction
- `.` - Property access
- `[]` - Array/object access
- `<`, `>`, `<=`, `>=`, `==` - Comparison operators
- `&&`, `||` - Logical operators
- `?`, `:` - Ternary conditional operator

**Ternary Operators** (v0.4.0+):

Attributes support full ternary conditional expressions:

```pug
// Simple ternary
div(class=isActive ? "active" : "inactive")

// With comparisons
p(data-level=count > 3 ? "high" : "low")

// With equality
button(class=theme == "dark" ? "btn-dark" : "btn-light")

// With logical operators
div(class=isLoggedIn && hasPermission ? "authorized" : "unauthorized")

// With property access
span(title=user.age >= 18 ? "adult" : "minor")

// Nested ternary
div(data-status=count > 10 ? "high" : count > 5 ? "medium" : "low")
```

The parser handles ternary operators by:
1. Recognizing `?` and `:` tokens in attribute expressions
2. Building complex expression strings with proper operator precedence
3. Supporting all comparison (`>`, `<`, `>=`, `<=`, `==`) and logical (`&&`, `||`) operators
4. Allowing nested ternary expressions for multi-level conditionals

See [Ternary Operators Documentation](en/ternary-operators.md) for detailed examples and best practices.

**Important**: Complex expressions with operators like `+` should start with a string literal or identifier.

### 4. Text & Interpolation (`text.zig`)

Parses text content and embedded expressions:

```pug
p Hello #{name}, you have #{count} messages
p !{rawHtml}
| Plain text with pipe
```

**Functions**:
- `parseText()`: Plain text until newline
- `parseInterpolation()`: `#{expr}` or `!{expr}`

### 5. Code Blocks (`code.zig`)

Parses JavaScript code execution:

```pug
= user.name           // Buffered (output escaped)
!= rawHtml            // Unescaped (output raw)
- var x = 10          // Unbuffered (execute only)
// HTML comment
//- Code comment (not in output)
```

**Functions**:
- `parseCode()`: Parse `=`, `!=`, `-` statements
- `parseComment()`: Parse `//` and `//-` comments

### 6. Conditionals (`conditionals.zig`)

Parses if/else/unless control flow:

```pug
if loggedIn
  p Welcome back!
else if guest
  p Hello guest
else
  p Please login

unless admin
  p Access denied
```

**Functions**:
- `parseConditional()`: Parse if/unless with branches
- Handles: `if`, `else if`, `else`, `unless`

### 7. Loops (`loops.zig`)

Parses iteration constructs:

```pug
each item in items
  li= item

each item, index in items
  li #{index}: #{item}

while hasMore
  p Loading...
```

**Functions**:
- `parseLoop()`: Parse each/while loops
- Supports: iterators, index variables, else branches

### 8. Case Statements (`case.zig`)

Parses switch-like case matching:

```pug
case color
  when 'red'
    p Red color
  when 'blue', 'cyan'
    p Blue-ish
  default
    p Unknown
```

**Functions**:
- `parseCase()`: Parse case statement
- `parseWhen()`: Parse when clauses

### 9. Mixins (`mixins.zig`)

Parses reusable template blocks:

```pug
mixin article(title, author)
  article
    h1= title
    p by #{author}

+article("Hello", "John")
```

**Functions**:
- `parseMixinDefinition()`: Parse mixin with parameters
- `parseMixinCall()`: Parse `+mixinName(args)`

### 10. Template Inheritance (`templates.zig`)

Parses include/extends/block directives:

```pug
extends layout.pug

block content
  p Child content

include header.pug
```

**Functions**:
- `parseInclude()`: Parse include directive
- `parseExtends()`: Parse extends directive
- `parseBlock()`: Parse block definition

### 11. Helper Functions (`helpers.zig`)

Common parsing utilities:

```zig
advance(parser)              // Move to next token
expect(parser, TokenType)    // Consume expected token or error
match(parser, []TokenType)   // Check if current matches any type
```

## Parsing Flow

### Example: Tag Parsing

**Input**:
```pug
div.container#main(data-value="test")
  p Hello
```

**Parsing Steps**:

1. **parseStatement()** sees `Ident("div")`
2. Calls **parseTag()**
3. Consumes tag name: `"div"`
4. Sees `.Class` → adds class attribute
5. Sees `#Id` → adds id attribute
6. Sees `(` → calls **parseAttributes()**
7. Parses `data-value="test"`
8. Sees `Newline` then `Indent`
9. Recursively parses children
10. Returns **TagNode** with all data

### Example: Conditional Parsing

**Input**:
```pug
if user
  p Welcome
else
  p Login
```

**Parsing Steps**:

1. **parseStatement()** sees `If` keyword
2. Calls **parseConditional()**
3. Parses condition: `"user"`
4. Sees `Newline` then `Indent`
5. Parses then-branch children
6. Sees `Dedent` then `Else`
7. Parses else-branch children
8. Returns **ConditionalNode**

## Error Handling

The parser provides detailed error messages:

```
Error at line 5, column 10:
Expected ')' but found ','
  div(class="box",
                  ^
```

**Error Types**:
- `UnexpectedToken`: Wrong token in context
- `InvalidIndentation`: Inconsistent indentation
- `OutOfMemory`: Allocation failed

## Memory Management

The parser uses an **ArenaAllocator** for AST nodes:

```zig
var parser = try Parser.init(allocator, source);
defer parser.deinit();  // Frees ALL AST nodes at once
```

Benefits:
- **Fast**: No individual node cleanup
- **Simple**: Single deinit() call
- **Safe**: No memory leaks

## Smart Spacing

The parser intelligently handles whitespace in code expressions:

```pug
= item.title       // → "item.title" (no spaces around '.')
= arr[0]          // → "arr[0]" (no spaces around '[')
= x + y           // → "x + y" (spaces around '+')
```

Uses `needsSpaceBefore()` and `needsSpaceAfter()` to determine spacing.

## API Usage

### Basic Parsing

```zig
const Parser = @import("parser/mod.zig").Parser;

var parser = try Parser.init(allocator, source);
defer parser.deinit();

const document = try parser.parse();
// document is root AST node
```

### Error Handling

```zig
const document = parser.parse() catch |err| {
    std.debug.print("Parse error: {}\n", .{err});
    return err;
};
```

## Testing

Run parser tests:
```bash
zig test src/parser/tests.zig
```

Tests cover:
- All statement types
- Nesting and indentation
- Attributes and expressions
- Edge cases
- Error recovery

## See Also

- [Tokenizer](tokenizer.md) - Lexical analysis (previous phase)
- [AST](ast.md) - Abstract Syntax Tree structure
- [Compiler](compiler.md) - HTML generation (next phase)
