//! Template Directives Parsing (include/extends/block)
//!
//! This module handles parsing of template inheritance and composition.

const std = @import("std");
const ast = @import("../ast/mod.zig");
const helpers = @import("helpers.zig");

/// Parser forward declaration
pub const Parser = @import("mod.zig").Parser;

/// Parse include directive
///
/// Includes another template file.
///
/// Syntax: include header.zpug
pub fn parseInclude(self: *Parser) anyerror!*ast.AstNode {
    const arena_allocator = self.arena.allocator();
    const start_line = self.current.line;
    try helpers.advance(self); // consume 'include'

    // Parse file path
    var path: std.ArrayList(u8) = .empty;
    var filter: ?[]const u8 = null;

    // Check for filter (e.g., include:markdown file.md)
    if (helpers.match(self, &.{.Colon})) {
        try helpers.advance(self);
        if (helpers.match(self, &.{.Ident})) {
            filter = self.current.value;
            try helpers.advance(self);
        }
    }

    // Parse path (rest of the line)
    while (!helpers.match(self, &.{ .Newline, .Eof })) {
        if (self.current.type == .Class) {
            try path.append(arena_allocator, '.');
        } else if (path.items.len > 0) {
            try path.append(arena_allocator, ' ');
        }
        try path.appendSlice(arena_allocator, self.current.value);
        try helpers.advance(self);
    }

    return try ast.AstNode.create(
        arena_allocator,
        .Include,
        start_line,
        1,
        .{ .Include = .{
            .path = try path.toOwnedSlice(arena_allocator),
            .filter = filter,
        } },
    );
}

/// Parse extends directive
///
/// Declares that this template extends a parent layout.
///
/// Syntax: extends layout.zpug
pub fn parseExtends(self: *Parser) anyerror!*ast.AstNode {
    const arena_allocator = self.arena.allocator();
    const start_line = self.current.line;
    try helpers.advance(self); // consume 'extends'

    // Parse parent template path
    // Can be either a quoted string or unquoted identifier with dots
    var path: std.ArrayList(u8) = .empty;

    // Handle quoted string
    if (helpers.match(self, &.{.String})) {
        try path.appendSlice(arena_allocator, self.current.value);
        try helpers.advance(self);
    } else {
        // Handle unquoted path (e.g., layout.zpug becomes Ident("layout") + Class("zpug"))
        while (!helpers.match(self, &.{ .Newline, .Eof })) {
            // If we encounter a Class token, add a dot before it
            if (self.current.type == .Class) {
                try path.append(arena_allocator, '.');
            }
            try path.appendSlice(arena_allocator, self.current.value);
            try helpers.advance(self);
        }
    }

    return try ast.AstNode.create(
        arena_allocator,
        .Extends,
        start_line,
        1,
        .{ .Extends = .{
            .path = try path.toOwnedSlice(arena_allocator),
        } },
    );
}

/// Parse block directive
/// Parse block/append/prepend directive.
///
/// Defines a content block that can be overridden in child templates.
///
/// Syntax:
/// ```
/// block content        → mode = Replace (default)
///   p Default content
///
/// append scripts       → mode = Append
///   script(src="x.js")
///
/// prepend styles       → mode = Prepend
///   link(rel="stylesheet")
/// ```
///
/// Note: `mode` is passed by the caller because the dispatch token
/// (.Block / .Append / .Prepend) is already current when this is called.
/// Passing it as a parameter avoids re-reading a consumed token.
pub fn parseBlock(self: *Parser, mode: ast.BlockMode) anyerror!*ast.AstNode {
    const arena_allocator = self.arena.allocator();
    const start_line = self.current.line;
    try helpers.advance(self); // consume 'block' / 'append' / 'prepend'

    // Parse block name
    const name_token = try helpers.expect(self, .Ident);
    const name = name_token.value;

    // Parse block body
    try helpers.skipNewlines(self);
    var body: std.ArrayListUnmanaged(*ast.AstNode) = .empty;
    if (helpers.match(self, &.{.Indent})) {
        try helpers.advance(self);
        try self.parseChildren(&body);
        if (helpers.match(self, &.{.Dedent})) {
            try helpers.advance(self);
        }
    }

    return try ast.AstNode.create(
        arena_allocator,
        .Block,
        start_line,
        1,
        .{ .Block = .{
            .name = name,
            .mode = mode,
            .body = body,
        } },
    );
}
