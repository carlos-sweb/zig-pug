//! Code and Comment Parsing
//!
//! This module handles parsing of code blocks and comments.

const std = @import("std");
const ast = @import("../ast/mod.zig");
const helpers = @import("helpers.zig");
const TokenType = @import("../tokenizer/mod.zig").TokenType;

/// Parser forward declaration
pub const Parser = @import("mod.zig").Parser;

/// Check if a space is needed before a token
///
/// Certain tokens should not have a space before them in JavaScript expressions.
/// For example: "item.title" not "item . title", "arr[0]" not "arr [0]"
fn needsSpaceBefore(token_type: TokenType) bool {
    return switch (token_type) {
        .Dot, .LBracket, .RBracket, .RParen, .Comma, .Colon => false,
        else => true,
    };
}

/// Check if a space is needed after a token
///
/// Certain tokens should not have a space after them in JavaScript expressions.
/// For example: "item.title" not "item. title", "fn()" not "fn( )"
fn needsSpaceAfter(token_type: TokenType) bool {
    return switch (token_type) {
        .Dot, .LBracket, .LParen => false,
        else => true,
    };
}

/// Parse comment (// buffered or //- unbuffered)
///
/// - Buffered (//): Emitted to HTML as <!-- comment -->
/// - Unbuffered (//-): Not included in output (code comment)
///
/// Example:
/// ```
/// // This appears in HTML
/// //- This is for developers only
/// ```
pub fn parseComment(self: *Parser) anyerror!*ast.AstNode {
    const arena_allocator = self.arena.allocator();
    const is_buffered = self.current.type == .BufferedComment;
    const content = self.current.value;
    const line = self.current.line;

    try helpers.advance(self);

    return try ast.AstNode.create(
        arena_allocator,
        .Comment,
        line,
        1,
        .{ .Comment = .{
            .content = content,
            .is_buffered = is_buffered,
        } },
    );
}

/// Parse code markers (=, !=, -)
///
/// - Buffered (=): Evaluate and output escaped HTML
/// - Unescaped (!=): Evaluate and output raw HTML
/// - Unbuffered (-): Execute code without output
///
/// Example:
/// ```
/// = user.name          // Escaped output
/// != rawHtml           // Unescaped output
/// - var x = 10         // Execute only
/// ```
pub fn parseCode(self: *Parser) anyerror!*ast.AstNode {
    const arena_allocator = self.arena.allocator();
    const token = self.current;
    try helpers.advance(self);

    // JsStatement already contains the full code as a single token value.
    // No need to reconstruct token by token — just return it directly.
    // Example: "- var name = \"Claude\"" → JsStatement("var name = \"Claude\"")
    if (token.type == .JsStatement) {
        return try ast.AstNode.create(
            arena_allocator,
            .Code,
            token.line,
            token.column,
            .{ .Code = .{
                .code         = token.value,
                .is_buffered  = false,
                .is_unescaped = false,
            } },
        );
    }

    const is_buffered  = token.type == .BufferedCode or token.type == .UnescapedCode;
    const is_unescaped = token.type == .UnescapedCode;

    // Collect code until newline
    var code: std.ArrayList(u8) = .empty;
    var last_token_type: ?TokenType = null;

    while (!helpers.match(self, &.{ .Newline, .Eof })) {
        // Smart spacing: only add space if needed between tokens
        if (code.items.len > 0 and last_token_type != null) {
            const needs_space = needsSpaceAfter(last_token_type.?) and
                needsSpaceBefore(self.current.type);
            if (needs_space) {
                try code.append(arena_allocator, ' ');
            }
        }

        // Preserve string quotes
        if (self.current.type == .String) {
            try code.append(arena_allocator, '"');
            try code.appendSlice(arena_allocator, self.current.value);
            try code.append(arena_allocator, '"');
        } else {
            try code.appendSlice(arena_allocator, self.current.value);
        }

        last_token_type = self.current.type;
        try helpers.advance(self);
    }

    return try ast.AstNode.create(
        arena_allocator,
        .Code,
        token.line,
        token.column,
        .{ .Code = .{
            .code = try code.toOwnedSlice(arena_allocator),
            .is_buffered = is_buffered,
            .is_unescaped = is_unescaped,
        } },
    );
}
