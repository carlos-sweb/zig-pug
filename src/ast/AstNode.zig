//! AST Node - Core data structure
//!
//! Main AST node structure with create/deinit methods and NodeData union.

const std = @import("std");
const NodeType = @import("NodeType.zig").NodeType;

// Import all node type structures
const DocumentNode = @import("nodes/DocumentNode.zig").DocumentNode;
const TagNode = @import("nodes/TagNode.zig").TagNode;
const TextNode = @import("nodes/TextNode.zig").TextNode;
const InterpolationNode = @import("nodes/TextNode.zig").InterpolationNode;
const CodeNode = @import("nodes/CodeNode.zig").CodeNode;
const CommentNode = @import("nodes/CodeNode.zig").CommentNode;
const ConditionalNode = @import("nodes/ControlFlowNode.zig").ConditionalNode;
const LoopNode = @import("nodes/ControlFlowNode.zig").LoopNode;
const CaseNode = @import("nodes/ControlFlowNode.zig").CaseNode;
const WhenNode = @import("nodes/ControlFlowNode.zig").WhenNode;
const MixinDefNode = @import("nodes/MixinNode.zig").MixinDefNode;
const MixinCallNode = @import("nodes/MixinNode.zig").MixinCallNode;
const IncludeNode = @import("nodes/TemplateNode.zig").IncludeNode;
const BlockNode = @import("nodes/TemplateNode.zig").BlockNode;
const ExtendsNode = @import("nodes/TemplateNode.zig").ExtendsNode;

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
            .Tag => |*tag| {
                tag.attributes.deinit(allocator);
                for (tag.children.items) |child| {
                    child.deinit(allocator);
                    allocator.destroy(child);
                }
                tag.children.deinit(allocator);
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
};
