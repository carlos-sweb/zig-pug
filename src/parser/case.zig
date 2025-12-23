//! Case Statement Parsing
//!
//! This module handles parsing of case/when switch statements.

const std = @import("std");
const ast = @import("../ast/mod.zig");
const helpers = @import("helpers.zig");

/// Parser forward declaration
pub const Parser = @import("mod.zig").Parser;

/// Parse case/when switch statement
///
/// Syntax:
/// ```
/// case variable
///   when "value1"
///     p First case
///   when "value2"
///     p Second case
///   default
///     p Default case
/// ```
pub fn parseCase(self: *Parser) anyerror!*ast.AstNode {
    const arena_allocator = self.arena.allocator();
    const start_line = self.current.line;
    try helpers.advance(self); // consume 'case'

    // Parse case expression
    var expression: std.ArrayList(u8) = .{};
    while (!helpers.match(self, &.{ .Newline, .Eof })) {
        if (expression.items.len > 0) {
            try expression.append(arena_allocator, ' ');
        }
        try expression.appendSlice(arena_allocator, self.current.value);
        try helpers.advance(self);
    }

    // Parse when blocks
    try helpers.skipNewlines(self);
    var cases = std.ArrayListUnmanaged(*ast.AstNode){}; // List of WhenNodes
    var default_block: ?std.ArrayListUnmanaged(*ast.AstNode) = null;

    if (helpers.match(self, &.{.Indent})) {
        try helpers.advance(self);

        while (!helpers.match(self, &.{ .Dedent, .Eof })) {
            try helpers.skipNewlines(self);
            if (helpers.match(self, &.{ .Dedent, .Eof })) {
                break;
            }

            if (helpers.match(self, &.{.When})) {
                const when_line = self.current.line;
                try helpers.advance(self); // consume 'when'

                // Parse when values (comma separated)
                var values = std.ArrayListUnmanaged([]const u8){};
                var current_value: std.ArrayList(u8) = .{};

                while (!helpers.match(self, &.{ .Newline, .Eof })) {
                    if (helpers.match(self, &.{.Comma})) {
                        try values.append(arena_allocator, try current_value.toOwnedSlice(arena_allocator));
                        current_value = .{};
                        try helpers.advance(self);
                    } else {
                        if (current_value.items.len > 0) {
                            try current_value.append(arena_allocator, ' ');
                        }
                        try current_value.appendSlice(arena_allocator, self.current.value);
                        try helpers.advance(self);
                    }
                }
                if (current_value.items.len > 0) {
                    try values.append(arena_allocator, try current_value.toOwnedSlice(arena_allocator));
                }

                // Parse when block
                try helpers.skipNewlines(self);
                var block = std.ArrayListUnmanaged(*ast.AstNode){};
                if (helpers.match(self, &.{.Indent})) {
                    try helpers.advance(self);
                    try self.parseChildren(&block);
                    if (helpers.match(self, &.{.Dedent})) {
                        try helpers.advance(self);
                    }
                }

                // Create WhenNode
                const when_node = try ast.AstNode.create(
                    arena_allocator,
                    .When,
                    when_line,
                    1,
                    .{ .When = .{
                        .values = values,
                        .body = block,
                    } },
                );
                try cases.append(arena_allocator, when_node);
            } else if (helpers.match(self, &.{.Default})) {
                try helpers.advance(self); // consume 'default'
                try helpers.skipNewlines(self);

                // Parse default block
                var block = std.ArrayListUnmanaged(*ast.AstNode){};
                if (helpers.match(self, &.{.Indent})) {
                    try helpers.advance(self);
                    try self.parseChildren(&block);
                    if (helpers.match(self, &.{.Dedent})) {
                        try helpers.advance(self);
                    }
                }
                default_block = block;
            } else {
                break;
            }
        }

        if (helpers.match(self, &.{.Dedent})) {
            try helpers.advance(self);
        }
    }

    return try ast.AstNode.create(
        arena_allocator,
        .Case,
        start_line,
        1,
        .{ .Case = .{
            .expression = try expression.toOwnedSlice(arena_allocator),
            .cases = cases,
            .default = default_block,
        } },
    );
}
