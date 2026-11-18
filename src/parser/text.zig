//! Text Parsing
//!
//! This module handles parsing of inline text and piped text blocks.

const std = @import("std");
const ast = @import("../ast/mod.zig");
const helpers = @import("helpers.zig");

/// Parser forward declaration
pub const Parser = @import("mod.zig").Parser;

/// Spaces that skipWhitespaceExceptNewline dropped between two tokens.
/// last_end is the exclusive end column of the previous token, or 0 at the start of the line.
fn appendColumnGap(buffer: *std.ArrayList(u8), allocator: std.mem.Allocator, column: usize, last_end: usize) !void {
    if (last_end == 0 or column <= last_end) return;
    var gap = column - last_end;
    while (gap > 0) : (gap -= 1) {
        try buffer.append(allocator, ' ');
    }
}

pub fn parseInlineText(self: *Parser) anyerror!std.ArrayListUnmanaged(*ast.AstNode) {
    const arena_allocator = self.arena.allocator();
    var nodes: std.ArrayListUnmanaged(*ast.AstNode) = .empty;
    var text_buffer: std.ArrayList(u8) = .empty;
    const start_line = self.current.line;
    var last_token_end_col: usize = 0;

    while (!helpers.match(self, &.{ .Newline, .Eof })) {
        if (helpers.match(self, &.{ .EscapedInterpol, .UnescapedInterpol })) {
            // A space between #{a} and #{b} never becomes a token. Recover it from columns.
            if (text_buffer.items.len == 0) {
                try appendColumnGap(&text_buffer, arena_allocator, self.current.column, last_token_end_col);
            }

            // Flush accumulated text as a Text node
            if (text_buffer.items.len > 0) {
                const text_node = try ast.AstNode.create(
                    arena_allocator,
                    .Text,
                    start_line,
                    1,
                    .{ .Text = .{
                        .content = try text_buffer.toOwnedSlice(arena_allocator),
                        .is_raw = false,
                    } },
                );
                try nodes.append(arena_allocator, text_node);
                text_buffer = .empty;
            }

            // Create Interpolation node
            const is_unescaped = self.current.type == .UnescapedInterpol;
            const expr_value = self.current.value;
            const expr_line = self.current.line;
            const expr_col = self.current.column;
            last_token_end_col = expr_col + expr_value.len + 3; // #{...} = 3 extra chars
            try helpers.advance(self);

            const interp_node = try ast.AstNode.create(
                arena_allocator,
                .Interpolation,
                expr_line,
                expr_col,
                .{ .Interpolation = .{
                    .expression = expr_value,
                    .is_unescaped = is_unescaped,
                } },
            );
            try nodes.append(arena_allocator, interp_node);
        } else {
            // Skip empty tokens (can occur when EOF is reached without newline)
            if (self.current.value.len == 0) {
                try helpers.advance(self);
                continue;
            }

            // Space after an interpolation was skipped before this text token.
            if (text_buffer.items.len == 0) {
                try appendColumnGap(&text_buffer, arena_allocator, self.current.column, last_token_end_col);
            }

            // Accumulate text
            try text_buffer.appendSlice(arena_allocator, self.current.value);
            last_token_end_col = self.current.column + self.current.value.len;
            try helpers.advance(self);
        }
    }

    // Flush remaining text
    if (text_buffer.items.len > 0) {
        const text_node = try ast.AstNode.create(
            arena_allocator,
            .Text,
            start_line,
            1,
            .{ .Text = .{
                .content = try text_buffer.toOwnedSlice(arena_allocator),
                .is_raw = false,
            } },
        );
        try nodes.append(arena_allocator, text_node);
    }

    return nodes;
}

/// Parse piped text (| literal text on its own line)
///
/// Pipe syntax forces text to be on its own line, useful for
/// multi-line text blocks or when text contains special characters.
///
/// Syntax: | This is literal text
///
/// Example:
/// ```
/// p
///   | First line of text
///   | Second line of text
/// ```
pub fn parsePipeText(self: *Parser) anyerror!*ast.AstNode {
    const arena_allocator = self.arena.allocator();
    _ = try helpers.expect(self, .Pipe);

    var nodes: std.ArrayListUnmanaged(*ast.AstNode) = .empty;
    var text_buffer: std.ArrayList(u8) = .empty;
    const start_line = self.current.line;
    var last_token_end_col: usize = 0;

    while (!helpers.match(self, &.{ .Newline, .Eof })) {
        if (helpers.match(self, &.{ .EscapedInterpol, .UnescapedInterpol })) {
            if (text_buffer.items.len == 0) {
                try appendColumnGap(&text_buffer, arena_allocator, self.current.column, last_token_end_col);
            }

            // Flush accumulated text as a Text node. The space before #{ is already in the text token.
            if (text_buffer.items.len > 0) {
                const text_node = try ast.AstNode.create(
                    arena_allocator,
                    .Text,
                    start_line,
                    1,
                    .{ .Text = .{
                        .content = try text_buffer.toOwnedSlice(arena_allocator),
                        .is_raw = true,
                    } },
                );
                try nodes.append(arena_allocator, text_node);
                text_buffer = .empty;
            }

            // Create Interpolation node
            const is_unescaped = self.current.type == .UnescapedInterpol;
            const expr_value = self.current.value;
            const expr_line = self.current.line;
            const expr_col = self.current.column;
            last_token_end_col = expr_col + expr_value.len + 3; // #{...} = 3 extra chars
            try helpers.advance(self);

            const interp_node = try ast.AstNode.create(
                arena_allocator,
                .Interpolation,
                expr_line,
                expr_col,
                .{ .Interpolation = .{
                    .expression = expr_value,
                    .is_unescaped = is_unescaped,
                } },
            );
            try nodes.append(arena_allocator, interp_node);
        } else {
            // Skip empty tokens (can occur when EOF is reached without newline)
            if (self.current.value.len == 0) {
                try helpers.advance(self);
                continue;
            }

            if (text_buffer.items.len == 0) {
                try appendColumnGap(&text_buffer, arena_allocator, self.current.column, last_token_end_col);
            }

            // Accumulate text
            try text_buffer.appendSlice(arena_allocator, self.current.value);
            last_token_end_col = self.current.column + self.current.value.len;
            try helpers.advance(self);
        }
    }

    // Flush remaining text
    if (text_buffer.items.len > 0) {
        const text_node = try ast.AstNode.create(
            arena_allocator,
            .Text,
            start_line,
            1,
            .{ .Text = .{
                .content = try text_buffer.toOwnedSlice(arena_allocator),
                .is_raw = true,
            } },
        );
        try nodes.append(arena_allocator, text_node);
    }

    // If only one node, return it directly
    if (nodes.items.len == 1) {
        return nodes.items[0];
    }

    // Multiple nodes: wrap in a Tag container with empty name (acts as fragment)
    return try ast.AstNode.create(
        arena_allocator,
        .Tag,
        start_line,
        1,
        .{ .Tag = .{
            .name = "",
            .attributes = .empty,
            .children = nodes,
            .is_self_closing = false,
        } },
    );
}
