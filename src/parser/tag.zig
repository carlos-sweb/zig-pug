//! Tag Parsing
//!
//! This module handles parsing of HTML tag elements.

const std = @import("std");
const ast = @import("../ast/mod.zig");
const helpers = @import("helpers.zig");
const attributes_parser = @import("attributes.zig");
const text_parser = @import("text.zig");
const code_parser = @import("code.zig");

/// Parser forward declaration
pub const Parser = @import("mod.zig").Parser;

/// Parse a tag element (div, p, span, etc.)
///
/// Handles complete tag syntax including:
/// - Tag name: div
/// - Classes: .container.main
/// - ID: #header
/// - Attributes: (href="/" title="Home")
/// - Inline code: = expression
/// - Inline text: Hello world
/// - Child elements (via indentation)
///
/// Returns: Tag AST node
///
/// Syntax examples:
/// ```
/// div                           // Simple tag
/// div.container#main            // With class and ID
/// a(href="/")                   // With attributes
/// p= message                    // With buffered code
/// p Hello world                 // With inline text
/// div                           // With children
///   p Nested content
/// ```
pub fn parseTag(self: *Parser) anyerror!*ast.AstNode {
    const token = try helpers.expect(self, .Ident);
    const arena_allocator = self.arena.allocator();

    var attributes: std.ArrayListUnmanaged(ast.Attribute) = .empty;
    var children: std.ArrayListUnmanaged(*ast.AstNode) = .empty;

    // Collect classes to concatenate them into a single attribute
    var classes: std.ArrayListUnmanaged([]const u8) = .empty;

    // Parse classes and ids (.class, #id)
    while (helpers.match(self, &.{ .Class, .Id })) {
        if (self.current.type == .Class) {
            const class_token = self.current;
            try helpers.advance(self);
            try classes.append(arena_allocator, class_token.value);
        } else if (self.current.type == .Id) {
            const id_token = self.current;
            try helpers.advance(self);
            try attributes.append(arena_allocator, .{
                .name = "id",
                .value = id_token.value,
                .is_unescaped = false,
                .is_expression = false,
            });
        }
    }

    // Add combined class attribute if any classes were found
    if (classes.items.len > 0) {
        const combined_classes = try std.mem.join(arena_allocator, " ", classes.items);
        try attributes.append(arena_allocator, .{
            .name = "class",
            .value = combined_classes,
            .is_unescaped = false,
            .is_expression = false,
        });
    }

    // Parse attributes (...)
    if (helpers.match(self, &.{.LParen})) {
        try attributes_parser.parseAttributes(self, &attributes);
    }

    // Check for buffered/unescaped code after tag (e.g., p= value)
    if (helpers.match(self, &.{ .BufferedCode, .UnescapedCode })) {
        const code_node = try code_parser.parseCode(self);
        try children.append(arena_allocator, code_node);
    } else if (!helpers.match(self, &.{ .Newline, .Indent, .Eof })) {
        // Parse inline text (puede retornar múltiples nodos: Text e Interpolation)
        const inline_nodes = try text_parser.parseInlineText(self);
        try children.appendSlice(arena_allocator, inline_nodes.items);
    }

    // Parse children with indentation
    try helpers.skipNewlines(self);
    if (helpers.match(self, &.{.Indent})) {
        try helpers.advance(self); // consume INDENT
        try self.parseChildren(&children);
        if (helpers.match(self, &.{.Dedent})) {
            try helpers.advance(self); // consume DEDENT
        }
    }

    return try ast.AstNode.create(
        arena_allocator,
        .Tag,
        token.line,
        token.column,
        .{ .Tag = .{
            .name = token.value,
            .attributes = attributes,
            .children = children,
            .is_self_closing = false,
        } },
    );
}

/// Parse implicit div tag (.class or #id without tag name)
///
/// Handles Pug shorthand syntax where .class or #id implies a div tag.
/// This is a convenience feature that makes templates more concise.
///
/// Supported syntax:
/// - .class → div.class
/// - #id → div#id
/// - #id.class → div#id.class
/// - .class(attrs) → div.class(attrs)
///
/// Returns: Tag AST node with "div" as tag name
///
/// Examples:
/// ```
/// .container              // <div class="container"></div>
/// #main                   // <div id="main"></div>
/// #main.container         // <div id="main" class="container"></div>
/// .btn.btn-primary        // <div class="btn btn-primary"></div>
/// ```
pub fn parseImplicitDiv(self: *Parser) anyerror!*ast.AstNode {
    const arena_allocator = self.arena.allocator();
    const first_token = self.current; // For line/column info

    // Use "div" as default tag name
    const tag_name = "div";

    var attributes: std.ArrayListUnmanaged(ast.Attribute) = .empty;
    var children: std.ArrayListUnmanaged(*ast.AstNode) = .empty;
    var classes: std.ArrayListUnmanaged([]const u8) = .empty;

    // Parse classes and ids (.class, #id)
    while (helpers.match(self, &.{ .Class, .Id })) {
        if (self.current.type == .Class) {
            const class_token = self.current;
            try helpers.advance(self);
            try classes.append(arena_allocator, class_token.value);
        } else if (self.current.type == .Id) {
            const id_token = self.current;
            try helpers.advance(self);
            try attributes.append(arena_allocator, .{
                .name = "id",
                .value = id_token.value,
                .is_unescaped = false,
                .is_expression = false,
            });
        }
    }

    // Add combined class attribute if any classes were found
    if (classes.items.len > 0) {
        const combined_classes = try std.mem.join(arena_allocator, " ", classes.items);
        try attributes.append(arena_allocator, .{
            .name = "class",
            .value = combined_classes,
            .is_unescaped = false,
            .is_expression = false,
        });
    }

    // Parse attributes (...)
    if (helpers.match(self, &.{.LParen})) {
        try attributes_parser.parseAttributes(self, &attributes);
    }

    // Check for buffered/unescaped code after tag (e.g., .container= value)
    if (helpers.match(self, &.{ .BufferedCode, .UnescapedCode })) {
        const code_node = try code_parser.parseCode(self);
        try children.append(arena_allocator, code_node);
    } else if (!helpers.match(self, &.{ .Newline, .Indent, .Eof })) {
        // Parse inline text
        const inline_nodes = try text_parser.parseInlineText(self);
        try children.appendSlice(arena_allocator, inline_nodes.items);
    }

    // Parse children with indentation
    try helpers.skipNewlines(self);
    if (helpers.match(self, &.{.Indent})) {
        try helpers.advance(self); // consume INDENT
        try self.parseChildren(&children);
        if (helpers.match(self, &.{.Dedent})) {
            try helpers.advance(self); // consume DEDENT
        }
    }

    return try ast.AstNode.create(
        arena_allocator,
        .Tag,
        first_token.line,
        first_token.column,
        .{ .Tag = .{
            .name = tag_name,
            .attributes = attributes,
            .children = children,
            .is_self_closing = false,
        } },
    );
}
