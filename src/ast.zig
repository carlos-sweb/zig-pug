//! Abstract Syntax Tree (AST) module for zig-pug
//!
//! This module defines the data structures that represent a parsed Pug template.
//! The parser converts a token stream into an AST, which is then walked by the
//! compiler to generate HTML.
//!
//! Main components:
//! - NodeType: Enum of all possible AST node types
//! - AstNode: The actual tree node with type and data
//! - NodeData: Union containing type-specific data
//! - Attribute: Tag attribute representation
//!
//! Example AST for "div.container\n  p Hello":
//! ```
//! Document {
//!   children: [
//!     Tag {
//!       name: "div",
//!       attributes: [Attribute{name: "class", value: "container"}],
//!       children: [
//!         Tag {
//!           name: "p",
//!           children: [Text{content: "Hello"}]
//!         }
//!       ]
//!     }
//!   ]
//! }
//! ```

const std = @import("std");

// ============================================================================
// Node Types
// ============================================================================

/// All possible AST node types in a Pug template
///
/// Each type corresponds to a different Pug construct:
/// - Document: Root node containing all top-level nodes
/// - Tag: HTML tag (div, p, span, etc.)
/// - Text: Plain text content
/// - Interpolation: #{...} or !{...} expressions
/// - Code: - code or = code
/// - Conditional: if/else/unless statements
/// - Loop: each/while loops
/// - MixinDef: mixin definition
/// - MixinCall: +mixin call
/// - Include: include statement
/// - Block: block definition
/// - Extends: template inheritance
/// - Comment: // or //- comments
/// - Case: case/when statements
/// - When: individual when clause
pub const NodeType = enum {
    Document,
    Tag,
    Text,
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

// ============================================================================
// Main AST Node
// ============================================================================

/// AST Node - Core data structure representing a single node in the parse tree
///
/// Every node has:
/// - type: What kind of node (Tag, Text, etc.)
/// - line/column: Source location for error reporting
/// - data: Type-specific data (union based on type)
///
/// Nodes are allocated on the heap and form a tree structure through
/// parent-child relationships in their data fields (e.g., Tag.children).
///
/// Memory management:
/// - Nodes are created with create() which allocates on heap
/// - They must be freed with deinit() which recursively frees children
/// - Use ArenaAllocator for automatic cleanup
pub const AstNode = struct {
    type: NodeType,        // Type of this node (Tag, Text, etc.)
    line: usize,           // Source line number (1-indexed) for error messages
    column: usize,         // Source column number (1-indexed)
    data: NodeData,        // Type-specific data (union)

    /// Create a new AST node on the heap
    ///
    /// Allocates memory for the node and initializes all fields.
    /// The node must later be freed with deinit() or use an ArenaAllocator.
    ///
    /// Parameters:
    /// - allocator: Memory allocator
    /// - node_type: Type of node to create
    /// - line: Source line number
    /// - column: Source column number
    /// - data: Type-specific data (must match node_type)
    ///
    /// Returns: Pointer to newly created node
    ///
    /// Example:
    /// ```zig
    /// const text_node = try AstNode.create(
    ///     allocator,
    ///     .Text,
    ///     5,  // line 5
    ///     12, // column 12
    ///     .{ .Text = .{ .content = "Hello", .is_raw = false } }
    /// );
    /// ```
    pub fn create(allocator: std.mem.Allocator, node_type: NodeType, line: usize, column: usize, data: NodeData) !*AstNode {
        const node = try allocator.create(AstNode);
        node.* = .{
            .type = node_type,
            .line = line,
            .column = column,
            .data = data,
        };
        return node;
    }

    /// Recursively free all memory associated with this node and its children
    ///
    /// This method walks the AST tree depth-first and frees all allocated memory:
    /// 1. Recursively calls deinit() on all child nodes
    /// 2. Destroys (frees) all child node pointers
    /// 3. Frees all ArrayLists (children, attributes, etc.)
    ///
    /// Important: This does NOT free the node itself, only its contents.
    /// The caller must call allocator.destroy(node) after deinit().
    ///
    /// Alternatively, use an ArenaAllocator which frees everything at once.
    ///
    /// Parameters:
    /// - allocator: Same allocator used to create the node
    ///
    /// Example:
    /// ```zig
    /// // Manual cleanup
    /// node.deinit(allocator);
    /// allocator.destroy(node);
    ///
    /// // Or use ArenaAllocator (recommended)
    /// var arena = std.heap.ArenaAllocator.init(allocator);
    /// defer arena.deinit(); // Frees everything at once
    /// const node = try AstNode.create(arena.allocator(), ...);
    /// // No need to call deinit
    /// ```
    pub fn deinit(self: *AstNode, allocator: std.mem.Allocator) void {
        switch (self.data) {
            .Document => |*doc| {
                for (doc.children.items) |child| {
                    child.deinit(allocator);
                    allocator.destroy(child);
                }
                doc.children.deinit(allocator);
            },
            .Tag => |*tag_data| {
                tag_data.attributes.deinit(allocator);
                for (tag_data.children.items) |child| {
                    child.deinit(allocator);
                    allocator.destroy(child);
                }
                tag_data.children.deinit(allocator);
            },
            .Conditional => |*cond| {
                for (cond.then_branch.items) |child| {
                    child.deinit(allocator);
                    allocator.destroy(child);
                }
                cond.then_branch.deinit(allocator);
                if (cond.else_branch) |*else_br| {
                    for (else_br.items) |child| {
                        child.deinit(allocator);
                        allocator.destroy(child);
                    }
                    else_br.deinit(allocator);
                }
            },
            .Loop => |*loop| {
                for (loop.body.items) |child| {
                    child.deinit(allocator);
                    allocator.destroy(child);
                }
                loop.body.deinit(allocator);
                if (loop.else_branch) |*else_br| {
                    for (else_br.items) |child| {
                        child.deinit(allocator);
                        allocator.destroy(child);
                    }
                    else_br.deinit(allocator);
                }
            },
            .MixinDef => |*mixin| {
                mixin.params.deinit(allocator);
                for (mixin.body.items) |child| {
                    child.deinit(allocator);
                    allocator.destroy(child);
                }
                mixin.body.deinit(allocator);
            },
            .MixinCall => |*call| {
                call.args.deinit(allocator);
                call.attributes.deinit(allocator);
                if (call.body) |*body| {
                    for (body.items) |child| {
                        child.deinit(allocator);
                        allocator.destroy(child);
                    }
                    body.deinit(allocator);
                }
            },
            .Block => |*block| {
                for (block.body.items) |child| {
                    child.deinit(allocator);
                    allocator.destroy(child);
                }
                block.body.deinit(allocator);
            },
            .Case => |*case_node| {
                for (case_node.cases.items) |when_node| {
                    when_node.deinit(allocator);
                    allocator.destroy(when_node);
                }
                case_node.cases.deinit(allocator);
                if (case_node.default) |*def| {
                    for (def.items) |child| {
                        child.deinit(allocator);
                        allocator.destroy(child);
                    }
                    def.deinit(allocator);
                }
            },
            .When => |*when| {
                when.values.deinit(allocator);
                for (when.body.items) |child| {
                    child.deinit(allocator);
                    allocator.destroy(child);
                }
                when.body.deinit(allocator);
            },
            else => {},
        }
    }

    // ========================================================================
    // Helper Constructors - Modern Zig idiom to simplify parser code
    // ========================================================================

    /// Create a Tag node with sensible defaults
    pub fn tag(allocator: std.mem.Allocator, line: usize, column: usize, name: []const u8) !*AstNode {
        return create(allocator, .Tag, line, column, .{
            .Tag = .{
                .name = name,
                .attributes = .{},
                .children = .{},
                .is_self_closing = false,
            },
        });
    }

    /// Create a Text node
    pub fn text(allocator: std.mem.Allocator, line: usize, column: usize, content: []const u8) !*AstNode {
        return create(allocator, .Text, line, column, .{
            .Text = .{
                .content = content,
                .is_raw = false,
            },
        });
    }

    /// Create an Interpolation node (#{...})
    pub fn interpolation(allocator: std.mem.Allocator, line: usize, column: usize, expression: []const u8, is_unescaped: bool) !*AstNode {
        return create(allocator, .Interpolation, line, column, .{
            .Interpolation = .{
                .expression = expression,
                .is_unescaped = is_unescaped,
            },
        });
    }

    /// Create a Code node (-, =, !=)
    pub fn code(allocator: std.mem.Allocator, line: usize, column: usize, code_str: []const u8, is_buffered: bool, is_unescaped: bool) !*AstNode {
        return create(allocator, .Code, line, column, .{
            .Code = .{
                .code = code_str,
                .is_buffered = is_buffered,
                .is_unescaped = is_unescaped,
            },
        });
    }

    /// Create a Comment node
    pub fn comment(allocator: std.mem.Allocator, line: usize, column: usize, content: []const u8, is_buffered: bool) !*AstNode {
        return create(allocator, .Comment, line, column, .{
            .Comment = .{
                .content = content,
                .is_buffered = is_buffered,
            },
        });
    }

    /// Create an Include node
    pub fn include(allocator: std.mem.Allocator, line: usize, column: usize, path: []const u8) !*AstNode {
        return create(allocator, .Include, line, column, .{
            .Include = .{
                .path = path,
            },
        });
    }

    /// Create an Extends node
    pub fn extends(allocator: std.mem.Allocator, line: usize, column: usize, path: []const u8) !*AstNode {
        return create(allocator, .Extends, line, column, .{
            .Extends = .{
                .path = path,
            },
        });
    }
};

/// Tagged union containing type-specific data for each node type
///
/// This is a discriminated union where the active field is determined by
/// the AstNode.type field. Each variant contains a struct with the data
/// specific to that node type.
///
/// Example:
/// ```zig
/// if (node.type == .Tag) {
///     const tag = node.data.Tag;
///     std.debug.print("Tag: {s}\n", .{tag.name});
/// }
/// ```
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

// ============================================================================
// Specific Node Types
// ============================================================================

/// Root document node containing all top-level nodes
///
/// This is the root of the AST tree. All templates have exactly one Document node.
///
/// Fields:
/// - children: Top-level nodes (tags, text, etc.)
/// - doctype: Optional doctype declaration (e.g., "html")
///
/// Example:
/// ```zpug
/// doctype html
/// html
///   body
///     p Hello
/// ```
/// Creates Document with doctype="html" and one child (html tag).
pub const DocumentNode = struct {
    children: std.ArrayListUnmanaged(*AstNode),
    doctype: ?[]const u8,
};

/// HTML tag node (div, p, span, etc.)
///
/// Represents any HTML tag with its attributes and children.
///
/// Fields:
/// - name: Tag name (e.g., "div", "p", "span")
/// - attributes: List of attributes (class, id, href, etc.)
/// - children: Child nodes (nested tags, text, etc.)
/// - is_self_closing: True for void elements (img, br, input)
///
/// Example:
/// ```zpug
/// div.container#main(data-value="test")
///   p Hello
/// ```
/// Creates Tag{name="div", attributes=[class, id, data-value], children=[p tag]}
pub const TagNode = struct {
    name: []const u8,
    attributes: std.ArrayListUnmanaged(Attribute),
    children: std.ArrayListUnmanaged(*AstNode),
    is_self_closing: bool,
};

/// Plain text content node
///
/// Represents text that should be output as-is (with HTML escaping unless raw).
///
/// Fields:
/// - content: The text content
/// - is_raw: If true, from pipe (|) and HTML entities not escaped
///
/// Example:
/// ```zpug
/// p Hello world         // TextNode{content="Hello world", is_raw=false}
/// | <strong>Bold</strong>  // TextNode{content="<strong>...", is_raw=true}
/// ```
pub const TextNode = struct {
    content: []const u8,
    is_raw: bool, // For pipe | text (no HTML escaping)
};

/// HTML tag attribute
///
/// Represents a single attribute on an HTML tag.
///
/// Fields:
/// - name: Attribute name (e.g., "class", "href", "data-value")
/// - value: Attribute value (can be null for boolean attributes)
/// - is_unescaped: If true, value is not HTML-escaped (for !=)
/// - is_expression: If true, value is a JS expression to evaluate
///
/// Examples:
/// ```zpug
/// div(class="container")           // {name="class", value="container", is_expression=false}
/// div(class=myVar)                 // {name="class", value="myVar", is_expression=true}
/// input(type="checkbox" checked)   // {name="checked", value=null}
/// div(data-html!=htmlContent)      // {name="data-html", is_unescaped=true, is_expression=true}
/// ```
pub const Attribute = struct {
    name: []const u8,
    value: ?[]const u8,
    is_unescaped: bool,      // For != (don't HTML-escape)
    is_expression: bool,     // true if value should be evaluated as JS expression
};

/// Interpolation node for #{...} and !{...}
///
/// Represents a JavaScript expression to be evaluated and inserted into output.
///
/// Fields:
/// - expression: The JS code to evaluate (e.g., "name", "user.email", "items.length")
/// - is_unescaped: If true (!{...}), don't HTML-escape the result
///
/// Examples:
/// ```zpug
/// p Hello #{name}              // {expression="name", is_unescaped=false}
/// p Count: #{items.length}     // {expression="items.length", is_unescaped=false}
/// div!{htmlContent}            // {expression="htmlContent", is_unescaped=true}
/// ```
pub const InterpolationNode = struct {
    expression: []const u8,
    is_unescaped: bool,
};

pub const CodeNode = struct {
    code: []const u8,
    is_buffered: bool,
    is_unescaped: bool,
};

pub const ConditionalNode = struct {
    condition: []const u8,
    then_branch: std.ArrayListUnmanaged(*AstNode),
    else_branch: ?std.ArrayListUnmanaged(*AstNode),
    is_unless: bool,
};

pub const LoopNode = struct {
    iterator: []const u8,
    index: ?[]const u8,
    iterable: []const u8,
    body: std.ArrayListUnmanaged(*AstNode),
    else_branch: ?std.ArrayListUnmanaged(*AstNode),
    is_while: bool,
};

pub const MixinDefNode = struct {
    name: []const u8,
    params: std.ArrayListUnmanaged([]const u8),
    rest_param: ?[]const u8,
    body: std.ArrayListUnmanaged(*AstNode),
};

pub const MixinCallNode = struct {
    name: []const u8,
    args: std.ArrayListUnmanaged([]const u8),
    attributes: std.ArrayListUnmanaged(Attribute),
    body: ?std.ArrayListUnmanaged(*AstNode),
};

pub const IncludeNode = struct {
    path: []const u8,
    filter: ?[]const u8,
};

pub const BlockNode = struct {
    name: []const u8,
    mode: BlockMode,
    body: std.ArrayListUnmanaged(*AstNode),
};

pub const BlockMode = enum {
    Replace,
    Append,
    Prepend,
};

pub const ExtendsNode = struct {
    path: []const u8,
};

pub const CommentNode = struct {
    content: []const u8,
    is_buffered: bool,
};

pub const CaseNode = struct {
    expression: []const u8,
    cases: std.ArrayListUnmanaged(*AstNode), // WhenNodes
    default: ?std.ArrayListUnmanaged(*AstNode),
};

pub const WhenNode = struct {
    values: std.ArrayListUnmanaged([]const u8),
    body: std.ArrayListUnmanaged(*AstNode),
};

// ============================================================================
// Visitor Pattern
// ============================================================================

pub const Visitor = struct {
    const Self = @This();

    context: *anyopaque,
    visitFn: *const fn (*anyopaque, *AstNode) anyerror!void,

    pub fn visit(self: *Self, node: *AstNode) !void {
        try self.visitFn(self.context, node);

        switch (node.data) {
            .Document => |*doc| {
                for (doc.children.items) |child| {
                    try self.visit(child);
                }
            },
            .Tag => |*tag| {
                for (tag.children.items) |child| {
                    try self.visit(child);
                }
            },
            .Conditional => |*cond| {
                for (cond.then_branch.items) |child| {
                    try self.visit(child);
                }
                if (cond.else_branch) |*else_br| {
                    for (else_br.items) |child| {
                        try self.visit(child);
                    }
                }
            },
            .Loop => |*loop| {
                for (loop.body.items) |child| {
                    try self.visit(child);
                }
                if (loop.else_branch) |*else_br| {
                    for (else_br.items) |child| {
                        try self.visit(child);
                    }
                }
            },
            .MixinDef => |*mixin| {
                for (mixin.body.items) |child| {
                    try self.visit(child);
                }
            },
            .MixinCall => |*call| {
                if (call.body) |*body| {
                    for (body.items) |child| {
                        try self.visit(child);
                    }
                }
            },
            .Block => |*block| {
                for (block.body.items) |child| {
                    try self.visit(child);
                }
            },
            .Case => |*case_node| {
                for (case_node.cases.items) |when_node| {
                    try self.visit(when_node);
                }
                if (case_node.default) |*def| {
                    for (def.items) |child| {
                        try self.visit(child);
                    }
                }
            },
            .When => |*when| {
                for (when.body.items) |child| {
                    try self.visit(child);
                }
            },
            else => {},
        }
    }
};

// ============================================================================
// Pretty Printer (for debugging)
// ============================================================================

pub fn printAst(node: *AstNode, indent: usize) void {
    var i: usize = 0;
    while (i < indent) : (i += 1) {
        std.debug.print("  ", .{});
    }

    std.debug.print("{s} (line {d})\n", .{ @tagName(node.type), node.line });

    switch (node.data) {
        .Document => |*doc| {
            for (doc.children.items) |child| {
                printAst(child, indent + 1);
            }
        },
        .Tag => |*tag| {
            var j: usize = 0;
            while (j < indent + 1) : (j += 1) {
                std.debug.print("  ", .{});
            }
            std.debug.print("name: {s}\n", .{tag.name});

            // Print attributes if any
            if (tag.attributes.items.len > 0) {
                var k: usize = 0;
                while (k < indent + 1) : (k += 1) {
                    std.debug.print("  ", .{});
                }
                std.debug.print("attributes:\n", .{});
                for (tag.attributes.items) |attr| {
                    var l: usize = 0;
                    while (l < indent + 2) : (l += 1) {
                        std.debug.print("  ", .{});
                    }
                    if (attr.value) |val| {
                        std.debug.print("{s}=\"{s}\"\n", .{ attr.name, val });
                    } else {
                        std.debug.print("{s} (boolean)\n", .{attr.name});
                    }
                }
            }

            for (tag.children.items) |child| {
                printAst(child, indent + 1);
            }
        },
        .Text => |*text| {
            var j: usize = 0;
            while (j < indent + 1) : (j += 1) {
                std.debug.print("  ", .{});
            }
            std.debug.print("content: \"{s}\"\n", .{text.content});
        },
        .Interpolation => |*interp| {
            var j: usize = 0;
            while (j < indent + 1) : (j += 1) {
                std.debug.print("  ", .{});
            }
            std.debug.print("expr: {s}, unescaped: {}\n", .{ interp.expression, interp.is_unescaped });
        },
        .Code => |*code| {
            var j: usize = 0;
            while (j < indent + 1) : (j += 1) {
                std.debug.print("  ", .{});
            }
            std.debug.print("code: {s}\n", .{code.code});
        },
        .Comment => |*comment| {
            var j: usize = 0;
            while (j < indent + 1) : (j += 1) {
                std.debug.print("  ", .{});
            }
            std.debug.print("comment: {s}\n", .{comment.content});
        },
        .Conditional => |*cond| {
            var j: usize = 0;
            while (j < indent + 1) : (j += 1) {
                std.debug.print("  ", .{});
            }
            std.debug.print("condition: {s}\n", .{cond.condition});
            for (cond.then_branch.items) |child| {
                printAst(child, indent + 1);
            }
            if (cond.else_branch) |*else_br| {
                j = 0;
                while (j < indent + 1) : (j += 1) {
                    std.debug.print("  ", .{});
                }
                std.debug.print("else:\n", .{});
                for (else_br.items) |child| {
                    printAst(child, indent + 1);
                }
            }
        },
        .Loop => |*loop| {
            var j: usize = 0;
            while (j < indent + 1) : (j += 1) {
                std.debug.print("  ", .{});
            }
            std.debug.print("iterator: {s}, iterable: {s}\n", .{ loop.iterator, loop.iterable });
            for (loop.body.items) |child| {
                printAst(child, indent + 1);
            }
        },
        .MixinDef => |*mixin| {
            var j: usize = 0;
            while (j < indent + 1) : (j += 1) {
                std.debug.print("  ", .{});
            }
            std.debug.print("name: {s}, params: {d}\n", .{ mixin.name, mixin.params.items.len });
            if (mixin.rest_param) |rest| {
                j = 0;
                while (j < indent + 1) : (j += 1) {
                    std.debug.print("  ", .{});
                }
                std.debug.print("rest: ...{s}\n", .{rest});
            }
            for (mixin.body.items) |child| {
                printAst(child, indent + 1);
            }
        },
        .MixinCall => |*call| {
            var j: usize = 0;
            while (j < indent + 1) : (j += 1) {
                std.debug.print("  ", .{});
            }
            std.debug.print("name: {s}, args: {d}\n", .{ call.name, call.args.items.len });
            if (call.body) |*body| {
                for (body.items) |child| {
                    printAst(child, indent + 1);
                }
            }
        },
        .Include => |*inc| {
            var j: usize = 0;
            while (j < indent + 1) : (j += 1) {
                std.debug.print("  ", .{});
            }
            std.debug.print("path: {s}\n", .{inc.path});
            if (inc.filter) |filter| {
                j = 0;
                while (j < indent + 1) : (j += 1) {
                    std.debug.print("  ", .{});
                }
                std.debug.print("filter: {s}\n", .{filter});
            }
        },
        .Extends => |*ext| {
            var j: usize = 0;
            while (j < indent + 1) : (j += 1) {
                std.debug.print("  ", .{});
            }
            std.debug.print("path: {s}\n", .{ext.path});
        },
        .Block => |*block| {
            var j: usize = 0;
            while (j < indent + 1) : (j += 1) {
                std.debug.print("  ", .{});
            }
            std.debug.print("name: {s}, mode: {s}\n", .{ block.name, @tagName(block.mode) });
            for (block.body.items) |child| {
                printAst(child, indent + 1);
            }
        },
        .Case => |*case_node| {
            var j: usize = 0;
            while (j < indent + 1) : (j += 1) {
                std.debug.print("  ", .{});
            }
            std.debug.print("expression: {s}\n", .{case_node.expression});
            for (case_node.cases.items) |when_node| {
                printAst(when_node, indent + 1);
            }
            if (case_node.default) |*default| {
                j = 0;
                while (j < indent + 1) : (j += 1) {
                    std.debug.print("  ", .{});
                }
                std.debug.print("default:\n", .{});
                for (default.items) |child| {
                    printAst(child, indent + 2);
                }
            }
        },
        .When => |*when| {
            var j: usize = 0;
            while (j < indent + 1) : (j += 1) {
                std.debug.print("  ", .{});
            }
            std.debug.print("values: {d}\n", .{when.values.items.len});
            for (when.body.items) |child| {
                printAst(child, indent + 1);
            }
        },
    }
}

// ============================================================================
// Tests
// ============================================================================

test "ast - create document node" {
    var doc_node = try AstNode.create(
        std.testing.allocator,
        .Document,
        1,
        1,
        .{ .Document = .{
            .children = .{},
            .doctype = null,
        } },
    );
    defer {
        doc_node.deinit(std.testing.allocator);
        std.testing.allocator.destroy(doc_node);
    }

    try std.testing.expectEqual(NodeType.Document, doc_node.type);
    try std.testing.expectEqual(@as(usize, 1), doc_node.line);
}

test "ast - create tag node" {
    var tag_node = try AstNode.create(
        std.testing.allocator,
        .Tag,
        1,
        1,
        .{ .Tag = .{
            .name = "div",
            .attributes = .{},
            .children = .{},
            .is_self_closing = false,
        } },
    );
    defer {
        tag_node.deinit(std.testing.allocator);
        std.testing.allocator.destroy(tag_node);
    }

    try std.testing.expectEqual(NodeType.Tag, tag_node.type);
    try std.testing.expectEqualStrings("div", tag_node.data.Tag.name);
}

test "ast - create text node" {
    var text_node = try AstNode.create(
        std.testing.allocator,
        .Text,
        1,
        1,
        .{ .Text = .{
            .content = "Hello World",
            .is_raw = false,
        } },
    );
    defer {
        text_node.deinit(std.testing.allocator);
        std.testing.allocator.destroy(text_node);
    }

    try std.testing.expectEqual(NodeType.Text, text_node.type);
    try std.testing.expectEqualStrings("Hello World", text_node.data.Text.content);
}

test "ast - visitor pattern" {
    const TestContext = struct {
        count: usize,

        fn visitNode(ctx: *anyopaque, node: *AstNode) !void {
            const self: *@This() = @ptrCast(@alignCast(ctx));
            self.count += 1;
            _ = node;
        }
    };

    var doc_node = try AstNode.create(
        std.testing.allocator,
        .Document,
        1,
        1,
        .{ .Document = .{
            .children = .{},
            .doctype = null,
        } },
    );
    defer {
        doc_node.deinit(std.testing.allocator);
        std.testing.allocator.destroy(doc_node);
    }

    var ctx = TestContext{ .count = 0 };
    var visitor = Visitor{
        .context = &ctx,
        .visitFn = TestContext.visitNode,
    };

    try visitor.visit(doc_node);
    try std.testing.expectEqual(@as(usize, 1), ctx.count);
}
