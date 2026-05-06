//! Abstract Syntax Tree (AST) module for zig-pug
//!
//! Define las estructuras del arbol de sintaxis producido por el Parser.
//!
//! Gestion de memoria:
//!   Todos los nodos viven en el ArenaAllocator del Parser.
//!   No hay deinit() en AstNode — el arena libera todo cuando
//!   Parser.deinit() es llamado.
//!
//! Flujo:
//!   Parser   -> crea nodos con arena.allocator()
//!   AST      -> arbol inmutable pasado al Compiler
//!   Compiler -> lee el arbol, genera HTML
//!   Parser.deinit() -> arena.deinit() libera todo

// Core types
pub const NodeType     = @import("NodeType.zig").NodeType;
pub const AstNode      = @import("AstNode.zig").AstNode;
pub const NodeData     = @import("AstNode.zig").NodeData;
pub const DocumentNode = @import("AstNode.zig").DocumentNode;

// Node structs
pub const TagNode          = @import("nodes/TagNode.zig").TagNode;
pub const Attribute        = @import("nodes/TagNode.zig").Attribute;
pub const TextNode         = @import("nodes/TextNode.zig").TextNode;
pub const InterpolationNode = @import("nodes/TextNode.zig").InterpolationNode;
pub const CodeNode         = @import("nodes/CodeNode.zig").CodeNode;
pub const CommentNode      = @import("nodes/CodeNode.zig").CommentNode;
pub const ConditionalNode  = @import("nodes/ControlFlowNode.zig").ConditionalNode;
pub const LoopNode         = @import("nodes/ControlFlowNode.zig").LoopNode;
pub const CaseNode         = @import("nodes/ControlFlowNode.zig").CaseNode;
pub const WhenNode         = @import("nodes/ControlFlowNode.zig").WhenNode;
pub const MixinDefNode     = @import("nodes/MixinNode.zig").MixinDefNode;
pub const MixinCallNode    = @import("nodes/MixinNode.zig").MixinCallNode;
pub const IncludeNode      = @import("nodes/TemplateNode.zig").IncludeNode;
pub const ExtendsNode      = @import("nodes/TemplateNode.zig").ExtendsNode;
pub const BlockNode        = @import("nodes/TemplateNode.zig").BlockNode;
pub const BlockMode        = @import("nodes/TemplateNode.zig").BlockMode;

// Visitor
pub const Visitor     = @import("Visitor.zig").Visitor;
pub const VisitAction = @import("Visitor.zig").VisitAction;

// Printer — usa std.debug.print, compatible con Zig 0.16
// Firmas: fn(*AstNode, usize) void
pub const printAst      = @import("printer.zig").printAst;
pub const printAstDebug = @import("printer.zig").printAstDebug;
