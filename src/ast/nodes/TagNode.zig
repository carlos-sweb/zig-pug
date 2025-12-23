//! Tag Node
//!
//! Represents HTML tags with attributes and children.

const std = @import("std");
const AstNode = @import("../AstNode.zig").AstNode;

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
