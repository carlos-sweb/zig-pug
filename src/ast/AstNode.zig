//! AST Node - Core data structure
//!
//! Main AST node structure. Memory is managed exclusively by the Parser's
//! ArenaAllocator — nodes are never freed individually. The entire tree is
//! released at once when Parser.deinit() destroys the arena.
//!
//! Lifecycle:
//!   Parser.init()   → crea el arena
//!   Parser.parse()  → crea nodos con self.arena.allocator()
//!   Compiler.run()  → consume el árbol (solo lectura)
//!   Parser.deinit() → destruye el arena, liberando todo el árbol de una vez
//!
//! AstNode no tiene deinit() ni destroy() porque no es dueño de su memoria.
//! El dueño es siempre el Parser a través de su arena.
//!
//! DocumentNode vive aquí porque es el nodo raíz del árbol y es un struct
//! trivial de 2 campos — no justifica un archivo propio.

const std = @import("std");
const NodeType = @import("NodeType.zig").NodeType;

const TagNode        = @import("nodes/TagNode.zig").TagNode;
const TextNode       = @import("nodes/TextNode.zig").TextNode;
const InterpolationNode = @import("nodes/TextNode.zig").InterpolationNode;
const CodeNode       = @import("nodes/CodeNode.zig").CodeNode;
const CommentNode    = @import("nodes/CodeNode.zig").CommentNode;
const ConditionalNode = @import("nodes/ControlFlowNode.zig").ConditionalNode;
const LoopNode       = @import("nodes/ControlFlowNode.zig").LoopNode;
const CaseNode       = @import("nodes/ControlFlowNode.zig").CaseNode;
const WhenNode       = @import("nodes/ControlFlowNode.zig").WhenNode;
const MixinDefNode   = @import("nodes/MixinNode.zig").MixinDefNode;
const MixinCallNode  = @import("nodes/MixinNode.zig").MixinCallNode;
const IncludeNode    = @import("nodes/TemplateNode.zig").IncludeNode;
const BlockNode      = @import("nodes/TemplateNode.zig").BlockNode;
const ExtendsNode    = @import("nodes/TemplateNode.zig").ExtendsNode;

/// Nodo raíz del AST. Contiene todos los nodos top-level del template.
///
/// Es el único nodo que produce Parser.parse() — todo el árbol
/// cuelga de sus children.
///
/// Fields:
/// - children: Nodos top-level (tags, texto, control flow, etc.)
/// - doctype:  Declaración doctype opcional (e.g., "html")
///
/// Ejemplo para `doctype html\nhtml\n  body\n    p Hello`:
/// ```
/// Document {
///   doctype: "html",
///   children: [ Tag{name="html", ...} ]
/// }
/// ```
pub const DocumentNode = struct {
    children: std.ArrayListUnmanaged(*AstNode),
    doctype: ?[]const u8,
};

/// Tagged union con los datos específicos de cada tipo de nodo.
/// El campo activo siempre está determinado por AstNode.type.
pub const NodeData = union(NodeType) {
    Document:      DocumentNode,
    Tag:           TagNode,
    Text:          TextNode,
    Interpolation: InterpolationNode,
    Code:          CodeNode,
    Conditional:   ConditionalNode,
    Loop:          LoopNode,
    MixinDef:      MixinDefNode,
    MixinCall:     MixinCallNode,
    Include:       IncludeNode,
    Block:         BlockNode,
    Extends:       ExtendsNode,
    Comment:       CommentNode,
    Case:          CaseNode,
    When:          WhenNode,
};

/// Nodo del AST. Unidad mínima del árbol de sintaxis.
///
/// Todos los nodos son alocados en el arena del Parser y nunca se liberan
/// individualmente — el árbol completo vive hasta que el Parser hace deinit().
///
/// Ejemplo de uso desde el Parser:
/// ```zig
/// const node = try AstNode.create(
///     self.arena.allocator(),
///     .Text,
///     token.line,
///     token.column,
///     .{ .Text = .{ .content = token.value, .is_raw = false } },
/// );
/// ```
pub const AstNode = struct {
    type:   NodeType,
    line:   usize,
    column: usize,
    data:   NodeData,

    /// Crea un nuevo nodo en el arena del Parser.
    ///
    /// Siempre pasar `self.arena.allocator()` desde el Parser,
    /// nunca un GPA u otro allocator externo.
    pub fn create(
        allocator: std.mem.Allocator,
        node_type: NodeType,
        line:      usize,
        column:    usize,
        data:      NodeData,
    ) !*AstNode {
        const node = try allocator.create(AstNode);
        node.* = .{
            .type   = node_type,
            .line   = line,
            .column = column,
            .data   = data,
        };
        return node;
    }
};
