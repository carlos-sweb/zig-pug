//! Mixin Definition and Call Parsing
//!
//! This module handles parsing of mixin definitions and calls.

const std = @import("std");
const ast = @import("../ast/mod.zig");
const helpers = @import("helpers.zig");

/// Parser forward declaration
pub const Parser = @import("mod.zig").Parser;

/// Parse mixin definition
///
/// Defines reusable template blocks with optional parameters.
///
/// Syntax:
/// ```
/// mixin card(title, content)
///   div.card
///     h3= title
///     p= content
/// ```
pub fn parseMixinDefinition(self: *Parser) anyerror!*ast.AstNode {
    const arena_allocator = self.arena.allocator();
    const start_line = self.current.line;
    try helpers.advance(self); // consume 'mixin'

    // Parse mixin name
    const name_token = try helpers.expect(self, .Ident);
    const name = name_token.value;

    // Parse parameters (optional)
    var params = std.ArrayListUnmanaged([]const u8){};
    var rest_param: ?[]const u8 = null;

    if (helpers.match(self, &.{.LParen})) {
        try helpers.advance(self); // consume '('

        while (!helpers.match(self, &.{ .RParen, .Eof })) {
            // Check for rest parameter ...name
            if (helpers.match(self, &.{.Dot})) {
                try helpers.advance(self);
                if (helpers.match(self, &.{.Dot})) {
                    try helpers.advance(self);
                    if (helpers.match(self, &.{.Dot})) {
                        try helpers.advance(self);
                        // Now we expect parameter name
                        if (helpers.match(self, &.{.Ident})) {
                            rest_param = self.current.value;
                            try helpers.advance(self);
                        }
                    }
                }
            } else if (helpers.match(self, &.{.Ident})) {
                try params.append(arena_allocator, self.current.value);
                try helpers.advance(self);
            }

            // Skip comma if present
            if (helpers.match(self, &.{.Comma})) {
                try helpers.advance(self);
            }
        }

        _ = try helpers.expect(self, .RParen);
    }

    // Parse mixin body
    try helpers.skipNewlines(self);
    var body = std.ArrayListUnmanaged(*ast.AstNode){};
    if (helpers.match(self, &.{.Indent})) {
        try helpers.advance(self);
        try self.parseChildren(&body);
        if (helpers.match(self, &.{.Dedent})) {
            try helpers.advance(self);
        }
    }

    return try ast.AstNode.create(
        arena_allocator,
        .MixinDef,
        start_line,
        1,
        .{ .MixinDef = .{
            .name = name,
            .params = params,
            .rest_param = rest_param,
            .body = body,
        } },
    );
}

/// Parse mixin call (+mixinName)
///
/// Invokes a previously defined mixin with arguments.
///
/// Syntax: +card("Title", "Content")
pub fn parseMixinCall(self: *Parser) anyerror!*ast.AstNode {
    const arena_allocator = self.arena.allocator();
    const start_line = self.current.line;
    try helpers.advance(self); // consume '+'

    // Parse mixin name
    const name_token = try helpers.expect(self, .Ident);
    const name = name_token.value;

    // Parse arguments (optional)
    var args = std.ArrayListUnmanaged([]const u8){};
    const attributes = std.ArrayListUnmanaged(ast.Attribute){};

    if (helpers.match(self, &.{.LParen})) {
        // Could be arguments or attributes
        // For simplicity, treat as arguments for now
        try helpers.advance(self); // consume '('

        while (!helpers.match(self, &.{ .RParen, .Eof })) {
            // Collect argument as string
            var arg: std.ArrayList(u8) = .{};

            while (!helpers.match(self, &.{ .Comma, .RParen, .Eof })) {
                if (arg.items.len > 0) {
                    try arg.append(arena_allocator, ' ');
                }
                // For String tokens, wrap value in quotes to preserve as JS string literal
                if (self.current.type == .String) {
                    try arg.append(arena_allocator, '"');
                    try arg.appendSlice(arena_allocator, self.current.value);
                    try arg.append(arena_allocator, '"');
                } else {
                    try arg.appendSlice(arena_allocator, self.current.value);
                }
                try helpers.advance(self);
            }

            if (arg.items.len > 0) {
                try args.append(arena_allocator, try arg.toOwnedSlice(arena_allocator));
            }

            // Skip comma if present
            if (helpers.match(self, &.{.Comma})) {
                try helpers.advance(self);
            }
        }

        _ = try helpers.expect(self, .RParen);
    }

    // Parse optional block for mixin
    try helpers.skipNewlines(self);
    var body: ?std.ArrayListUnmanaged(*ast.AstNode) = null;
    if (helpers.match(self, &.{.Indent})) {
        try helpers.advance(self);
        var block_body = std.ArrayListUnmanaged(*ast.AstNode){};
        try self.parseChildren(&block_body);
        if (helpers.match(self, &.{.Dedent})) {
            try helpers.advance(self);
        }
        body = block_body;
    }

    return try ast.AstNode.create(
        arena_allocator,
        .MixinCall,
        start_line,
        1,
        .{ .MixinCall = .{
            .name = name,
            .args = args,
            .attributes = attributes,
            .body = body,
        } },
    );
}
