# AST - Abstract Syntax Tree

The **AST** (Abstract Syntax Tree) is the intermediate representation of a Pug template after parsing. It's a tree structure that represents the template's hierarchical nature and semantic meaning.

## Overview

The AST is created by the parser and consumed by the compiler. It provides:

- **Hierarchical structure**: Parent-child relationships
- **Type safety**: Each node has a specific type
- **Source location**: Line and column for error reporting
- **Immutability**: Tree doesn't change after parsing
- **Visitor pattern**: Easy tree traversal

## Architecture

### Location: `src/ast/`

```
src/ast/
├── mod.zig              # Public API and re-exports
├── NodeType.zig         # Enum of all node types
├── AstNode.zig          # Core node structure and NodeData union
├── Visitor.zig          # Visitor pattern for tree traversal
├── printer.zig          # Debug utility for visualizing trees
├── tests.zig            # AST test suite
└── nodes/               # Node type definitions
    ├── DocumentNode.zig      # Root document node
    ├── TagNode.zig           # HTML tags and attributes
    ├── TextNode.zig          # Text and interpolation
    ├── CodeNode.zig          # Code blocks and comments
    ├── ControlFlowNode.zig   # Conditionals, loops, case
    ├── MixinNode.zig         # Mixin definitions and calls
    └── TemplateNode.zig      # Include, extends, blocks
```

## Node Structure

### AstNode

Every AST node has the same structure:

```zig
pub const AstNode = struct {
    type: NodeType,        // What kind of node
    line: usize,           // Source line (1-indexed)
    column: usize,         // Source column (1-indexed)
    data: NodeData,        // Type-specific data (union)
}
```

### NodeType Enum

```zig
pub const NodeType = enum {
    Document,      // Root node
    Tag,           // HTML tag
    Text,          // Plain text
    Interpolation, // #{expr} or !{expr}
    Code,          // =, !=, - code
    Conditional,   // if/else/unless
    Loop,          // each/while
    MixinDef,      // mixin definition
    MixinCall,     // +mixin() call
    Include,       // include directive
    Block,         // block definition
    Extends,       // extends directive
    Comment,       // // or //- comment
    Case,          // case statement
    When,          // when clause
};
```

### NodeData Union

A discriminated union containing type-specific data:

```zig
pub const NodeData = union(NodeType) {
    Document: DocumentNode,
    Tag: TagNode,
    Text: TextNode,
    Interpolation: InterpolationNode,
    Code: CodeNode,
    Conditional: ConditionalNode,
    Loop: LoopNode,
    MixinDef: MixinDefNode,
    MixinCall: MixinCallNode,
    Include: IncludeNode,
    Block: BlockNode,
    Extends: ExtendsNode,
    Comment: CommentNode,
    Case: CaseNode,
    When: WhenNode,
};
```

## Node Types

### 1. DocumentNode

Root node containing all top-level nodes:

```zig
pub const DocumentNode = struct {
    children: std.ArrayListUnmanaged(*AstNode),
    doctype: ?[]const u8,  // e.g., "html", "xml"
};
```

**Example**:
```pug
doctype html
html
  body
```

### 2. TagNode

HTML tag with attributes and children:

```zig
pub const TagNode = struct {
    name: []const u8,                         // "div", "p", "span"
    attributes: std.ArrayListUnmanaged(Attribute),
    children: std.ArrayListUnmanaged(*AstNode),
    is_self_closing: bool,                    // <img />, <br />
};

pub const Attribute = struct {
    name: []const u8,
    value: ?[]const u8,
    is_unescaped: bool,      // != vs =
    is_expression: bool,     // class=myVar vs class="static"
};
```

**Example**:
```pug
div.container#main(data-value="test")
  p Content
```

### 3. TextNode & InterpolationNode

Text content and embedded expressions:

```zig
pub const TextNode = struct {
    content: []const u8,
    is_raw: bool,  // Pipe | text
};

pub const InterpolationNode = struct {
    expression: []const u8,  // JavaScript code
    is_unescaped: bool,      // !{} vs #{}
};
```

**Example**:
```pug
p Hello #{name}
p !{rawHtml}
| Plain text
```

### 4. CodeNode & CommentNode

Code execution and comments:

```zig
pub const CodeNode = struct {
    code: []const u8,
    is_buffered: bool,    // = or != (output)
    is_unescaped: bool,   // != (raw HTML)
};

pub const CommentNode = struct {
    content: []const u8,
    is_buffered: bool,    // // (in HTML) vs //- (stripped)
};
```

**Example**:
```pug
= user.name
!= rawContent
- var x = 10
// HTML comment
//- Code comment
```

### 5. ConditionalNode

If/else/unless statements:

```zig
pub const ConditionalNode = struct {
    condition: []const u8,                    // JavaScript expression
    then_branch: std.ArrayListUnmanaged(*AstNode),
    else_branch: ?std.ArrayListUnmanaged(*AstNode),
    is_unless: bool,                          // unless vs if
};
```

**Example**:
```pug
if loggedIn
  p Welcome
else
  p Login
```

### 6. LoopNode

Each/while iteration:

```zig
pub const LoopNode = struct {
    iterator: []const u8,     // "item"
    index: ?[]const u8,       // "i" (optional)
    iterable: []const u8,     // "items" or condition
    body: std.ArrayListUnmanaged(*AstNode),
    else_branch: ?std.ArrayListUnmanaged(*AstNode),
    is_while: bool,
};
```

**Example**:
```pug
each item, i in items
  li #{i}: #{item}

while hasMore
  p Loading...
```

### 7. CaseNode & WhenNode

Switch-like case matching:

```zig
pub const CaseNode = struct {
    expression: []const u8,
    cases: std.ArrayListUnmanaged(*AstNode),  // WhenNodes
    default: ?std.ArrayListUnmanaged(*AstNode),
};

pub const WhenNode = struct {
    values: std.ArrayListUnmanaged([]const u8),
    body: std.ArrayListUnmanaged(*AstNode),
};
```

**Example**:
```pug
case color
  when 'red', 'crimson'
    p Red
  default
    p Unknown
```

### 8. MixinDefNode & MixinCallNode

Reusable template blocks:

```zig
pub const MixinDefNode = struct {
    name: []const u8,
    params: std.ArrayListUnmanaged([]const u8),
    rest_param: ?[]const u8,   // ...args
    body: std.ArrayListUnmanaged(*AstNode),
};

pub const MixinCallNode = struct {
    name: []const u8,
    args: std.ArrayListUnmanaged([]const u8),
    attributes: std.ArrayListUnmanaged(Attribute),
    body: ?std.ArrayListUnmanaged(*AstNode),
};
```

**Example**:
```pug
mixin article(title, author)
  article
    h1= title
    p= author

+article("Hello", "John")
```

### 9. IncludeNode, BlockNode, ExtendsNode

Template composition:

```zig
pub const IncludeNode = struct {
    path: []const u8,
    filter: ?[]const u8,  // :markdown, etc.
};

pub const BlockMode = enum {
    Replace,   // Default
    Append,    // block append
    Prepend,   // block prepend
};

pub const BlockNode = struct {
    name: []const u8,
    mode: BlockMode,
    body: std.ArrayListUnmanaged(*AstNode),
};

pub const ExtendsNode = struct {
    path: []const u8,
};
```

**Example**:
```pug
extends layout.pug

block content
  p Child content

include header.pug
```

## Memory Management

AST nodes are allocated on an **ArenaAllocator**:

```zig
// Parser owns the arena
var parser = try Parser.init(allocator, source);
defer parser.deinit();  // Frees all nodes

const document = try parser.parse();
// All nodes freed when parser.deinit() is called
```

Benefits:
- **Fast allocation**: No per-node overhead
- **Fast deallocation**: Single free for entire tree
- **No leaks**: Impossible to forget individual nodes

## Visitor Pattern

Traverse the AST tree with custom logic:

```zig
const MyContext = struct {
    count: usize,

    fn visitNode(ctx: *anyopaque, node: *AstNode) !void {
        const self: *MyContext = @ptrCast(@alignCast(ctx));
        self.count += 1;
    }
};

var ctx = MyContext{ .count = 0 };
var visitor = Visitor{
    .context = &ctx,
    .visitFn = MyContext.visitNode,
};

try visitor.visit(document);
// ctx.count now has total node count
```

## Debug Printing

Print AST tree structure:

```zig
const printAst = @import("ast/mod.zig").printAst;

printAst(document, 0);
```

**Output**:
```
Document (line 1)
  Tag (line 1)
    name: div
    attributes:
      class="container"
      id="main"
    Tag (line 2)
      name: p
      Text (line 2)
        content: "Hello"
```

## Example AST

### Input
```pug
div.container
  p Hello #{name}
  if admin
    button Edit
```

### AST Structure
```
Document {
  children: [
    Tag {
      name: "div",
      attributes: [Attribute{name: "class", value: "container"}],
      children: [
        Tag {
          name: "p",
          children: [
            Text{content: "Hello "},
            Interpolation{expression: "name"}
          ]
        },
        Conditional {
          condition: "admin",
          then_branch: [
            Tag {
              name: "button",
              children: [Text{content: "Edit"}]
            }
          ]
        }
      ]
    }
  ]
}
```

## API Usage

### Creating Nodes

```zig
const ast = @import("ast/mod.zig");

const text_node = try ast.AstNode.create(
    allocator,
    .Text,
    5,    // line
    10,   // column
    .{ .Text = .{
        .content = "Hello",
        .is_raw = false,
    }}
);
```

### Accessing Node Data

```zig
switch (node.type) {
    .Tag => |tag| {
        std.debug.print("Tag: {s}\n", .{tag.name});
        for (tag.children.items) |child| {
            // Process children
        }
    },
    .Text => |text| {
        std.debug.print("Text: {s}\n", .{text.content});
    },
    else => {},
}
```

## Testing

Run AST tests:
```bash
zig test src/ast/tests.zig
```

Tests cover:
- Node creation
- Memory management
- Visitor pattern
- All node types

## See Also

- [Tokenizer](tokenizer.md) - Lexical analysis
- [Parser](parser.md) - Syntax analysis (creates AST)
- [Compiler](compiler.md) - HTML generation (consumes AST)
