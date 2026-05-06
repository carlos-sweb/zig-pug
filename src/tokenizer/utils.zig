//! Shared utilities for the tokenizer
//!
//! Centralizes helpers used across all scan*.zig modules:
//! - UTF-8 byte classification
//! - Identifier/text byte validation
//! - Keyword lookup table (single source of truth)
//!
//! Usage:
//! ```zig
//! const utils = @import("utils.zig");
//! if (utils.isUtf8Start(ch)) { ... }
//! if (utils.getKeyword("if")) |kw| { ... }
//! ```

const std = @import("std");
const TokenType = @import("TokenType.zig").TokenType;

// ============================================================================
// UTF-8 Support
// ============================================================================

/// Check if a byte is the start of a UTF-8 multi-byte sequence
///
/// UTF-8 encoding:
/// - 0x00-0x7F: Single byte (ASCII)
/// - 0x80-0xBF: Continuation byte
/// - 0xC0-0xDF: Start of 2-byte sequence
/// - 0xE0-0xEF: Start of 3-byte sequence
/// - 0xF0-0xF7: Start of 4-byte sequence
pub fn isUtf8Start(byte: u8) bool {
    return byte >= 0xC0;
}

/// Get the length of a UTF-8 sequence from its first byte
pub fn utf8SequenceLength(first_byte: u8) usize {
    if (first_byte < 0x80) return 1; // ASCII
    if (first_byte < 0xC0) return 1; // Invalid continuation byte, treat as 1
    if (first_byte < 0xE0) return 2;
    if (first_byte < 0xF0) return 3;
    return 4;
}

/// Check if a byte is valid inside an identifier or text (including UTF-8)
///
/// Allows:
/// - ASCII alphanumeric, underscore, hyphen
/// - UTF-8 multi-byte start or continuation bytes
pub fn isValidTextByte(byte: u8) bool {
    if (std.ascii.isAlphanumeric(byte) or byte == '_' or byte == '-') return true;
    if (byte >= 0x80) return true;
    return false;
}

// ============================================================================
// Keyword Lookup — single source of truth
// ============================================================================

/// Check if an identifier matches a Pug keyword.
///
/// Returns the corresponding TokenType if it's a keyword, null otherwise.
///
/// Keywords:
/// - Control flow : if, else, unless, each, while, case, when, default
/// - Template     : mixin, include, extends, block, append, prepend
/// - Loop         : in  (used in "each item in items")
/// - Special      : doctype, true, false
///
/// Example:
/// ```zig
/// utils.getKeyword("if")    // → .If
/// utils.getKeyword("each")  // → .Each
/// utils.getKeyword("in")    // → .In
/// utils.getKeyword("true")  // → .Boolean
/// utils.getKeyword("div")   // → null
/// ```
pub fn getKeyword(ident: []const u8) ?TokenType {
    const map = std.StaticStringMap(TokenType).initComptime(.{
        .{ "if",      .If },
        .{ "else",    .Else },
        .{ "unless",  .Unless },
        .{ "each",    .Each },
        .{ "while",   .While },
        .{ "in",      .In },
        .{ "case",    .Case },
        .{ "when",    .When },
        .{ "default", .Default },
        .{ "mixin",   .Mixin },
        .{ "include", .Include },
        .{ "extends", .Extends },
        .{ "block",   .Block },
        .{ "append",  .Append },
        .{ "prepend",  .Prepend },
        .{ "doctype",  .Doctype },
    });
    return map.get(ident);
}

/// Returns true if the given TokenType is a Pug directive keyword.
/// Used by the tokenizer to prevent Text activation after keyword lines.
pub fn isKeywordType(token_type: TokenType) bool {
    return switch (token_type) {
        .If, .Else, .Unless,
        .Each, .While, .In,
        .Case, .When, .Default,
        .Mixin, .Include, .Extends,
        .Block, .Append, .Prepend,
        .Doctype => true,
        else => false,
    };
}
