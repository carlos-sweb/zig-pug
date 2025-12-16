//! Helper functions for the parser
//!
//! This module contains utility functions used throughout the parsing process.

const std = @import("std");
const tokenizer = @import("../tokenizer.zig");

/// Parser forward declaration - full definition in mod.zig
pub const Parser = @import("mod.zig").Parser;

/// Advance to next token
///
/// Moves self.current to next token from tokenizer.
pub fn advance(self: *Parser) !void {
    self.current = try self.tokenizer.next();
}

/// Expect specific token type and consume it
///
/// Parameters:
/// - expected: Token type that must be current
///
/// Returns: The consumed token
///
/// Errors:
/// - UnexpectedToken: Current token doesn't match expected
///
/// Example:
/// ```zig
/// const lparen = try self.expect(.LParen);
/// // Now current token is whatever came after (
/// ```
pub fn expect(self: *Parser, expected: tokenizer.TokenType) !tokenizer.Token {
    if (self.current.type == expected) {
        const result = self.current;
        try advance(self);
        return result;
    }
    std.debug.print("Expected {s}, got {s} at line {d}\n", .{
        @tagName(expected),
        @tagName(self.current.type),
        self.current.line,
    });
    return error.UnexpectedToken;
}

/// Check if current token matches any of the given types
///
/// Parameters:
/// - types: Slice of token types to check against
///
/// Returns: true if current token matches any type
///
/// Example:
/// ```zig
/// if (self.match(&.{ .Class, .Id })) {
///     // Current token is either Class or Id
/// }
/// ```
pub fn match(self: *Parser, types: []const tokenizer.TokenType) bool {
    for (types) |t| {
        if (self.current.type == t) return true;
    }
    return false;
}

/// Skip any newline tokens
///
/// Advances past all consecutive Newline tokens.
/// Used to ignore blank lines between statements.
pub fn skipNewlines(self: *Parser) !void {
    while (self.current.type == .Newline) {
        try advance(self);
    }
}
