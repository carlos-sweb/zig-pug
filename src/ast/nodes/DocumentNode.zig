//! Document Node
//!
//! Root node containing all top-level AST nodes and optional doctype declaration.

const std = @import("std");
const AstNode = @import("../AstNode.zig").AstNode;

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
