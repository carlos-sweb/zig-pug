//! Code and Comment Parsing
//!
//! This module handles parsing of code blocks and comments.

const std = @import("std");
const tokenizer = @import("../tokenizer.zig");
const ast = @import("../ast.zig");
const helpers = @import("helpers.zig");

/// Parser forward declaration
pub const Parser = @import("mod.zig").Parser;

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

    const is_buffered = token.type == .BufferedCode or token.type == .UnescapedCode;
    const is_unescaped = token.type == .UnescapedCode;

    // Collect code until newline
    var code: std.ArrayList(u8) = .{};
    while (!helpers.match(self, &.{ .Newline, .Eof })) {
        if (code.items.len > 0) {
            try code.append(arena_allocator, ' ');
        }
        // Preserve string quotes
        if (self.current.type == .String) {
            try code.append(arena_allocator, '"');
            try code.appendSlice(arena_allocator, self.current.value);
            try code.append(arena_allocator, '"');
        } else {
            try code.appendSlice(arena_allocator, self.current.value);
        }
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
