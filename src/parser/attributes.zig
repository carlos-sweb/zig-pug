//! Attribute Parsing
//!
//! This module handles parsing of HTML attributes within parentheses.

const std = @import("std");
const ast = @import("../ast.zig");
const helpers = @import("helpers.zig");

/// Parser forward declaration
pub const Parser = @import("mod.zig").Parser;

/// Parse attribute list (key="value", class=myClass)
///
/// Parses attributes within parentheses, handling:
/// - Static attributes: href="/", title="Home"
/// - Expression attributes: class=myClass, data=userData
/// - Boolean attributes: disabled, checked
///
/// Syntax: (name=value, name2=value2, ...)
pub fn parseAttributes(self: *Parser, attributes: *std.ArrayListUnmanaged(ast.Attribute)) !void {
    const arena_allocator = self.arena.allocator();
    _ = try helpers.expect(self, .LParen);

    // Atributos pueden estar en múltiples líneas
    try helpers.skipNewlines(self);

    while (!helpers.match(self, &.{ .RParen, .Eof })) {
        try helpers.skipNewlines(self);

        // Check for spread attributes: &attributes
        if (helpers.match(self, &.{.Hash})) {
            // Skip for now - would need special handling
            try helpers.advance(self);
            if (helpers.match(self, &.{.Ident})) {
                try helpers.advance(self);
            }
            continue;
        }

        // Parse attribute name
        if (!helpers.match(self, &.{.Ident})) {
            break;
        }
        const name_token = self.current;
        try helpers.advance(self);

        var value: ?[]const u8 = null;
        var is_unescaped = false;
        var is_expression = false;

        // Parse attribute value
        if (helpers.match(self, &.{.Assign})) {
            try helpers.advance(self);

            // Parse value - can be string, number, identifier, or expression
            if (helpers.match(self, &.{.String})) {
                value = self.current.value;
                try helpers.advance(self);
            } else if (helpers.match(self, &.{.Number})) {
                value = self.current.value;
                try helpers.advance(self);
            } else if (helpers.match(self, &.{.Boolean})) {
                value = self.current.value;
                try helpers.advance(self);
            } else if (helpers.match(self, &.{.Ident})) {
                value = self.current.value;
                is_expression = true; // Identifier = expression to evaluate
                try helpers.advance(self);
            }
        } else if (helpers.match(self, &.{.BufferedCode})) {
            // Handle = for dynamic values
            try helpers.advance(self);
            is_unescaped = false;

            if (helpers.match(self, &.{.String})) {
                value = self.current.value;
                try helpers.advance(self);
            } else if (helpers.match(self, &.{.Ident})) {
                value = self.current.value;
                is_expression = true;
                try helpers.advance(self);
            }
        } else if (helpers.match(self, &.{.UnescapedCode})) {
            // Handle != for unescaped dynamic values
            try helpers.advance(self);
            is_unescaped = true;

            if (helpers.match(self, &.{.String})) {
                value = self.current.value;
                try helpers.advance(self);
            } else if (helpers.match(self, &.{.Ident})) {
                value = self.current.value;
                is_expression = true;
                try helpers.advance(self);
            }
        }
        // If no value, it's a boolean attribute (e.g., checked, disabled)

        try attributes.append(arena_allocator, .{
            .name = name_token.value,
            .value = value,
            .is_unescaped = is_unescaped,
            .is_expression = is_expression,
        });

        try helpers.skipNewlines(self);

        // Skip comma if present (optional)
        if (helpers.match(self, &.{.Comma})) {
            try helpers.advance(self);
            try helpers.skipNewlines(self);
        }
    }

    try helpers.skipNewlines(self);
    _ = try helpers.expect(self, .RParen);
}
