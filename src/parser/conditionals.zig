//! Conditional Parsing (if/else/unless)
//!
//! This module handles parsing of conditional statements.

const std = @import("std");
const ast = @import("../ast.zig");
const helpers = @import("helpers.zig");

/// Parser forward declaration
pub const Parser = @import("mod.zig").Parser;

/// Parse conditional (if/unless with optional else)
///
/// Syntax:
/// ```
/// if condition
///   p True branch
/// else
///   p False branch
/// ```
///
/// unless is inverse of if (executes when condition is false)
pub fn parseConditional(self: *Parser) anyerror!*ast.AstNode {
    const arena_allocator = self.arena.allocator();
    const is_unless = self.current.type == .Unless;
    const start_line = self.current.line;
    try helpers.advance(self); // consume 'if' or 'unless'

    // Parse condition expression (everything until newline)
    // Concatenate tokens WITHOUT spaces to preserve property access (array.length)
    // and operators (>=, <=, etc). JavaScript expressions don't require spaces.
    var condition: std.ArrayList(u8) = .{};
    while (!helpers.match(self, &.{ .Newline, .Eof })) {
        // Special handling for .Class and .Id tokens - prepend the dot
        // because tokenizer removes it from the value
        if (self.current.type == .Class or self.current.type == .Id) {
            try condition.append(arena_allocator, '.');
        }
        // Special handling for .String tokens - wrap with quotes
        // because tokenizer removes them from the value
        else if (self.current.type == .String) {
            try condition.append(arena_allocator, '"');
            try condition.appendSlice(arena_allocator, self.current.value);
            try condition.append(arena_allocator, '"');
            try helpers.advance(self);
            continue;
        }
        try condition.appendSlice(arena_allocator, self.current.value);
        try helpers.advance(self);
    }

    // Parse 'then' block
    try helpers.skipNewlines(self);
    var consequence = std.ArrayListUnmanaged(*ast.AstNode){};
    if (helpers.match(self, &.{.Indent})) {
        try helpers.advance(self);
        try self.parseChildren(&consequence);
        if (helpers.match(self, &.{.Dedent})) {
            try helpers.advance(self);
        }
    }

    // Parse 'else' block (optional)
    try helpers.skipNewlines(self);
    var alternative: ?std.ArrayListUnmanaged(*ast.AstNode) = null;
    if (helpers.match(self, &.{.Else})) {
        try helpers.advance(self);

        // Check for 'else if'
        if (helpers.match(self, &.{.If})) {
            // Parse as a nested if statement
            const else_if_node = try parseConditional(self);
            var alt_list = std.ArrayListUnmanaged(*ast.AstNode){};
            try alt_list.append(arena_allocator, else_if_node);
            alternative = alt_list;
        } else {
            // Parse regular else block
            try helpers.skipNewlines(self);
            var alt_list = std.ArrayListUnmanaged(*ast.AstNode){};
            if (helpers.match(self, &.{.Indent})) {
                try helpers.advance(self);
                try self.parseChildren(&alt_list);
                if (helpers.match(self, &.{.Dedent})) {
                    try helpers.advance(self);
                }
            }
            alternative = alt_list;
        }
    }

    return try ast.AstNode.create(
        arena_allocator,
        .Conditional,
        start_line,
        1,
        .{ .Conditional = .{
            .condition = try condition.toOwnedSlice(arena_allocator),
            .then_branch = consequence,
            .else_branch = alternative,
            .is_unless = is_unless,
        } },
    );
}
