//! Mixin Nodes
//!
//! Represents mixin definitions and calls for reusable template blocks.

const std = @import("std");
const AstNode = @import("../AstNode.zig").AstNode;
const Attribute = @import("TagNode.zig").Attribute;

/// Mixin definition node
///
/// Represents a reusable template block with parameters.
///
/// Fields:
/// - name: Mixin name
/// - params: List of parameter names
/// - rest_param: Optional rest parameter for variable arguments (e.g., "...args")
/// - body: Nodes that make up the mixin template
///
/// Example:
/// ```zpug
/// mixin article(title, author)
///   article
///     h1= title
///     p by #{author}
///
/// mixin list(items...)
///   ul
///     each item in items
///       li= item
/// ```
pub const MixinDefNode = struct {
    name: []const u8,
    params: std.ArrayListUnmanaged([]const u8),
    rest_param: ?[]const u8,
    body: std.ArrayListUnmanaged(*AstNode),
};

/// Mixin call node
///
/// Represents a call to a previously defined mixin.
///
/// Fields:
/// - name: Name of mixin to call
/// - args: List of argument expressions
/// - attributes: Attributes to pass to mixin (for attribute blocks)
/// - body: Optional block content to pass to mixin
///
/// Example:
/// ```zpug
/// +article("Title", "Author")
///
/// +link(href="/home")(class="nav-link")
///   span Home
/// ```
pub const MixinCallNode = struct {
    name: []const u8,
    args: std.ArrayListUnmanaged([]const u8),
    attributes: std.ArrayListUnmanaged(Attribute),
    body: ?std.ArrayListUnmanaged(*AstNode),
};
