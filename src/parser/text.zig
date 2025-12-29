//! Text Parsing
//!
//! This module handles parsing of inline text and piped text blocks.

const std = @import("std");
const ast = @import("../ast/mod.zig");
const helpers = @import("helpers.zig");

/// Parser forward declaration
pub const Parser = @import("mod.zig").Parser;

pub fn parseInlineText(self: *Parser) anyerror!std.ArrayListUnmanaged(*ast.AstNode) {
    const arena_allocator = self.arena.allocator();
    var nodes = std.ArrayListUnmanaged(*ast.AstNode){};
    var text_buffer: std.ArrayList(u8) = .{};
    const start_line = self.current.line;
    var last_token_end_col: usize = 0;
    var has_content = false; // Track if we've processed any content

    while (!helpers.match(self, &.{ .Newline, .Eof })) {
        if (helpers.match(self, &.{ .EscapedInterpol, .UnescapedInterpol })) {
            // Add space before interpolation if there was previous content
            if (has_content and text_buffer.items.len == 0) {
                // Previous content was an interpolation, add space
                try text_buffer.append(arena_allocator, ' ');
            }

            // Flush accumulated text as a Text node
            if (text_buffer.items.len > 0) {
                // Add trailing space before interpolation
                try text_buffer.append(arena_allocator, ' ');

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
                text_buffer = .{};
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
            has_content = true; // Mark that we have content
        } else {
            // Skip empty tokens (can occur when EOF is reached without newline)
            if (self.current.value.len == 0) {
                try helpers.advance(self);
                continue;
            }

            // Add space before token if we've already processed content
            // This preserves spacing between words/interpolations
            if (has_content) {
                try text_buffer.append(arena_allocator, ' ');
            }

            // Accumulate text
            try text_buffer.appendSlice(arena_allocator, self.current.value);
            last_token_end_col = self.current.column + self.current.value.len;
            has_content = true; // Mark that we have content
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

    var nodes = std.ArrayListUnmanaged(*ast.AstNode){};
    var text_buffer: std.ArrayList(u8) = .{};
    const start_line = self.current.line;
    var last_token_end_col: usize = 0;
    var has_content = false; // Track if we've processed any content

    while (!helpers.match(self, &.{ .Newline, .Eof })) {
        if (helpers.match(self, &.{ .EscapedInterpol, .UnescapedInterpol })) {
            // Add space before interpolation if there was previous content
            if (has_content and text_buffer.items.len == 0) {
                // Previous content was an interpolation, add space
                try text_buffer.append(arena_allocator, ' ');
            }

            // Flush accumulated text as a Text node
            if (text_buffer.items.len > 0) {
                // Add trailing space before interpolation
                try text_buffer.append(arena_allocator, ' ');

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
                text_buffer = .{};
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
            has_content = true; // Mark that we have content
        } else {
            // Skip empty tokens (can occur when EOF is reached without newline)
            if (self.current.value.len == 0) {
                try helpers.advance(self);
                continue;
            }

            // Add space before token if we've already processed content
            // This preserves spacing between words/interpolations
            if (has_content) {
                try text_buffer.append(arena_allocator, ' ');
            }

            // Accumulate text
            try text_buffer.appendSlice(arena_allocator, self.current.value);
            last_token_end_col = self.current.column + self.current.value.len;
            has_content = true; // Mark that we have content
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
            .attributes = .{},
            .children = nodes,
            .is_self_closing = false,
        } },
    );
}
