//! AST Node Types
//!
//! Enumeration of all possible node types in a Pug template AST.
//! Each type corresponds to a different Pug construct.

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
