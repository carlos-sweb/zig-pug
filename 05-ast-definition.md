# Paso 5: Definición del AST (Abstract Syntax Tree)

## Objetivo
Definir el Abstract Syntax Tree que representa la estructura del template.

---

## Jerarquía de Nodos AST

```zig
pub const NodeType = enum {
    Document,
    Tag,
    Text,
    Attribute,
    Interpolation,
    Code,
    Conditional,
    Loop,
    MixinDef,
    MixinCall,
    Include,
    Block,
    Extends,
    Comment,
    Case,
    When,
};

pub const AstNode = struct {
    type: NodeType,
    line: usize,
    column: usize,
    data: NodeData,

    pub fn deinit(self: *AstNode, allocator: std.mem.Allocator) void {
        // Recursively free all child nodes
    }
};

pub const NodeData = union(NodeType) {
    Document: DocumentNode,
    Tag: TagNode,
    Text: TextNode,
    Attribute: AttributeNode,
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

---

## Tipos de Nodos Específicos

### DocumentNode
```zig
pub const DocumentNode = struct {
    children: std.ArrayList(*AstNode),
    doctype: ?[]const u8,
};
```

### TagNode
```zig
pub const TagNode = struct {
    name: []const u8,
    attributes: std.ArrayList(*AttributeNode),
    children: std.ArrayList(*AstNode),
    is_self_closing: bool,
};
```

### TextNode
```zig
pub const TextNode = struct {
    content: []const u8,
    is_raw: bool, // For pipe | text
};
```

### AttributeNode
```zig
pub const AttributeNode = struct {
    name: []const u8,
    value: ?*ExprNode,
    is_unescaped: bool,
};
```

### InterpolationNode
```zig
pub const InterpolationNode = struct {
    expression: *ExprNode,
    is_unescaped: bool,
};
```

### CodeNode
```zig
pub const CodeNode = struct {
    code: []const u8,
    is_buffered: bool,
    is_unescaped: bool,
};
```

### ConditionalNode
```zig
pub const ConditionalNode = struct {
    condition: *ExprNode,
    then_branch: std.ArrayList(*AstNode),
    else_branch: ?std.ArrayList(*AstNode),
    is_unless: bool,
};
```

### LoopNode
```zig
pub const LoopNode = struct {
    iterator: []const u8,
    index: ?[]const u8,
    iterable: *ExprNode,
    body: std.ArrayList(*AstNode),
    else_branch: ?std.ArrayList(*AstNode),
    is_while: bool,
};
```

### MixinDefNode & MixinCallNode
```zig
pub const MixinDefNode = struct {
    name: []const u8,
    params: std.ArrayList([]const u8),
    rest_param: ?[]const u8,
    body: std.ArrayList(*AstNode),
};

pub const MixinCallNode = struct {
    name: []const u8,
    args: std.ArrayList(*ExprNode),
    attributes: std.ArrayList(*AttributeNode),
    body: ?std.ArrayList(*AstNode),
};
```

### IncludeNode
```zig
pub const IncludeNode = struct {
    path: []const u8,
    filter: ?[]const u8,
};
```

### BlockNode & ExtendsNode
```zig
pub const BlockNode = struct {
    name: []const u8,
    mode: BlockMode,
    body: std.ArrayList(*AstNode),
};

pub const BlockMode = enum {
    Replace,
    Append,
    Prepend,
};

pub const ExtendsNode = struct {
    path: []const u8,
};
```

### CommentNode
```zig
pub const CommentNode = struct {
    content: []const u8,
    is_buffered: bool,
};
```

### CaseNode & WhenNode
```zig
pub const CaseNode = struct {
    expression: *ExprNode,
    cases: std.ArrayList(*WhenNode),
    default: ?std.ArrayList(*AstNode),
};

pub const WhenNode = struct {
    values: std.ArrayList(*ExprNode),
    body: std.ArrayList(*AstNode),
};
```

---

## Expression Nodes

```zig
pub const ExprNode = struct {
    type: ExprType,
    data: ExprData,
};

pub const ExprType = enum {
    Literal,
    Variable,
    Binary,
    Unary,
    Call,
    Member,
    Array,
    Object,
};

pub const ExprData = union(ExprType) {
    Literal: LiteralExpr,
    Variable: []const u8,
    Binary: BinaryExpr,
    Unary: UnaryExpr,
    Call: CallExpr,
    Member: MemberExpr,
    Array: ArrayExpr,
    Object: ObjectExpr,
};

pub const LiteralExpr = union(enum) {
    String: []const u8,
    Number: f64,
    Boolean: bool,
    Null: void,
};

pub const BinaryExpr = struct {
    left: *ExprNode,
    op: BinaryOp,
    right: *ExprNode,
};

pub const BinaryOp = enum {
    Add, Sub, Mul, Div, Mod,
    Eq, Ne, Lt, Le, Gt, Ge,
    And, Or,
};
```

---

## Visitor Pattern

```zig
pub const Visitor = struct {
    const Self = @This();

    visitFn: *const fn(*Self, *AstNode) anyerror!void,

    pub fn visit(self: *Self, node: *AstNode) !void {
        try self.visitFn(self, node);

        switch (node.data) {
            .Document => |doc| {
                for (doc.children.items) |child| {
                    try self.visit(child);
                }
            },
            .Tag => |tag| {
                for (tag.children.items) |child| {
                    try self.visit(child);
                }
            },
            // ... otros casos ...
            else => {},
        }
    }
};
```

---

## Pretty Printer para Debugging

```zig
pub fn printAst(node: *AstNode, indent: usize) void {
    var i: usize = 0;
    while (i < indent) : (i += 1) {
        std.debug.print("  ", .{});
    }

    std.debug.print("{s} (line {d})\n", .{@tagName(node.type), node.line});

    switch (node.data) {
        .Document => |doc| {
            for (doc.children.items) |child| {
                printAst(child, indent + 1);
            }
        },
        .Tag => |tag| {
            for (tag.children.items) |child| {
                printAst(child, indent + 1);
            }
        },
        // ... otros casos ...
        else => {},
    }
}
```

---

## Entregables
1. Módulo `ast.zig` con todos los tipos de nodos
2. Sistema de visitor pattern
3. Pretty printer para debugging
4. Documentación de cada tipo de nodo

---

## Siguiente Paso
Continuar con **06-parser-base.md** para implementar el parser básico.
