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
//! - Visitor: Pattern for traversing AST trees
//! - printAst: Debug utility for visualizing trees
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

// Core types
pub const NodeType = @import("NodeType.zig").NodeType;
pub const AstNode = @import("AstNode.zig").AstNode;
pub const NodeData = @import("AstNode.zig").NodeData;

// Node structures
pub const DocumentNode = @import("nodes/DocumentNode.zig").DocumentNode;
pub const TagNode = @import("nodes/TagNode.zig").TagNode;
pub const Attribute = @import("nodes/TagNode.zig").Attribute;
pub const TextNode = @import("nodes/TextNode.zig").TextNode;
pub const InterpolationNode = @import("nodes/TextNode.zig").InterpolationNode;
pub const CodeNode = @import("nodes/CodeNode.zig").CodeNode;
pub const CommentNode = @import("nodes/CodeNode.zig").CommentNode;
pub const ConditionalNode = @import("nodes/ControlFlowNode.zig").ConditionalNode;
pub const LoopNode = @import("nodes/ControlFlowNode.zig").LoopNode;
pub const CaseNode = @import("nodes/ControlFlowNode.zig").CaseNode;
pub const WhenNode = @import("nodes/ControlFlowNode.zig").WhenNode;
pub const MixinDefNode = @import("nodes/MixinNode.zig").MixinDefNode;
pub const MixinCallNode = @import("nodes/MixinNode.zig").MixinCallNode;
pub const IncludeNode = @import("nodes/TemplateNode.zig").IncludeNode;
pub const BlockNode = @import("nodes/TemplateNode.zig").BlockNode;
pub const BlockMode = @import("nodes/TemplateNode.zig").BlockMode;
pub const ExtendsNode = @import("nodes/TemplateNode.zig").ExtendsNode;

// Utilities
pub const Visitor = @import("Visitor.zig").Visitor;
pub const printAst = @import("printer.zig").printAst;

// Tests
test {
    _ = @import("tests.zig");
}
