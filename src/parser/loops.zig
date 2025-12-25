//! Loop Parsing (each/while)
//!
//! This module handles parsing of loop statements.

const std = @import("std");
const ast = @import("../ast/mod.zig");
const helpers = @import("helpers.zig");

/// Parser forward declaration
pub const Parser = @import("mod.zig").Parser;

/// Parse loop (each or while)
///
/// Each loop syntax:
/// ```
/// each item in items
///   li= item
/// ```
///
/// While loop syntax:
/// ```
/// while condition
///   p Loop content
/// ```
pub fn parseLoop(self: *Parser) anyerror!*ast.AstNode {
    const arena_allocator = self.arena.allocator();
    const is_while = self.current.type == .While;
    const start_line = self.current.line;
    try helpers.advance(self); // consume 'each' or 'while'

    // Parse loop expression: "item in items" or "item, index in items"
    var iterator: []const u8 = "";
    var index_var: ?[]const u8 = null;
    var iterable: []const u8 = "";

    if (!is_while) {
        // Parse iterator variable name
        if (helpers.match(self, &.{.Ident})) {
            iterator = self.current.value;
            try helpers.advance(self);
        }

        // Check for optional index variable: ", index"
        if (helpers.match(self, &.{.Comma})) {
            try helpers.advance(self); // consume ','
            if (helpers.match(self, &.{.Ident})) {
                index_var = self.current.value;
                try helpers.advance(self);
            }
        }

        // Expect "in" keyword
        if (helpers.match(self, &.{.Ident}) and std.mem.eql(u8, self.current.value, "in")) {
            try helpers.advance(self); // consume 'in'
        }

        // Parse iterable expression (rest of the line)
        var iterable_expr: std.ArrayList(u8) = .{};
        while (!helpers.match(self, &.{ .Newline, .Eof })) {
            if (iterable_expr.items.len > 0) {
                try iterable_expr.append(arena_allocator, ' ');
            }
            try iterable_expr.appendSlice(arena_allocator, self.current.value);
            try helpers.advance(self);
        }
        iterable = try iterable_expr.toOwnedSlice(arena_allocator);
    } else {
        // While loop - just collect the condition
        var expression: std.ArrayList(u8) = .{};
        while (!helpers.match(self, &.{ .Newline, .Eof })) {
            if (expression.items.len > 0) {
                try expression.append(arena_allocator, ' ');
            }
            try expression.appendSlice(arena_allocator, self.current.value);
            try helpers.advance(self);
        }
        iterable = try expression.toOwnedSlice(arena_allocator);
    }

    // Parse loop body
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
        .Loop,
        start_line,
        1,
        .{ .Loop = .{
            .iterator = iterator,
            .index = index_var,
            .iterable = iterable,
            .body = body,
            .else_branch = null,
            .is_while = is_while,
        } },
    );
}
