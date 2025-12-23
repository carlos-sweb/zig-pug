//! Template Inheritance Nodes
//!
//! Represents include, extends, and block directives for template composition.

const std = @import("std");
const AstNode = @import("../AstNode.zig").AstNode;

/// Include node
///
/// Represents inclusion of another template file.
///
/// Fields:
/// - path: Path to template file to include
/// - filter: Optional filter to apply (e.g., ":markdown")
///
/// Example:
/// ```zpug
/// include header.zpug
/// include:markdown content.md
/// ```
pub const IncludeNode = struct {
    path: []const u8,
    filter: ?[]const u8,
};

/// Block mode for template inheritance
///
/// Determines how child blocks interact with parent blocks.
///
/// Modes:
/// - Replace: Child block completely replaces parent block (default)
/// - Append: Child block content is added after parent block content
/// - Prepend: Child block content is added before parent block content
pub const BlockMode = enum {
    Replace,
    Append,
    Prepend,
};

/// Block node for template inheritance
///
/// Represents a named content block that can be overridden in child templates.
///
/// Fields:
/// - name: Block name
/// - mode: How child blocks should interact with this block
/// - body: Default content if not overridden
///
/// Example:
/// ```zpug
/// block content
///   p Default content
///
/// block append scripts
///   script(src="extra.js")
///
/// block prepend head
///   meta(name="author")
/// ```
pub const BlockNode = struct {
    name: []const u8,
    mode: BlockMode,
    body: std.ArrayListUnmanaged(*AstNode),
};

/// Extends node for template inheritance
///
/// Represents inheritance from a parent template.
///
/// Fields:
/// - path: Path to parent template
///
/// Example:
/// ```zpug
/// extends layout.zpug
///
/// block content
///   p Child content
/// ```
pub const ExtendsNode = struct {
    path: []const u8,
};
