//! Scan identifier or keyword token
//!
//! Reads alphanumeric characters plus _ and - to form identifiers.
//! Behavior depends on current tokenizer state:
//! - Root/Indent: Tag name → transition to TagStart
//! - TagStart: Continuation of tag
//! - AttrStart/AttrName: Attribute name
//! - Text: Part of text content
//!
//! Checks if identifier matches a keyword (if, each, mixin, etc.).

const std = @import("std");
const Token = @import("Token.zig").Token;
const TokenType = @import("TokenType.zig").TokenType;
const TokenizerState = @import("TokenizerState.zig").TokenizerState;

/// Check if a byte is the start of a UTF-8 multi-byte sequence
fn isUtf8Start(byte: u8) bool {
    return byte >= 0xC0;
}

/// Get the length of a UTF-8 sequence from its first byte
fn utf8SequenceLength(first_byte: u8) usize {
    if (first_byte < 0x80) return 1; // ASCII
    if (first_byte < 0xC0) return 1; // Invalid, treat as 1 byte
    if (first_byte < 0xE0) return 2; // 2-byte sequence
    if (first_byte < 0xF0) return 3; // 3-byte sequence
    return 4; // 4-byte sequence
}

/// Check if a byte is valid in identifiers or text (including UTF-8)
fn isValidTextByte(byte: u8) bool {
    // ASCII alphanumeric, underscore, hyphen
    if (std.ascii.isAlphanumeric(byte) or byte == '_' or byte == '-') {
        return true;
    }
    // UTF-8 multi-byte start or continuation
    if (byte >= 0x80) {
        return true;
    }
    return false;
}

/// Check if identifier is a keyword
fn getKeyword(ident: []const u8) ?TokenType {
    const keywords = std.StaticStringMap(TokenType).initComptime(.{
        .{ "if", .If },
        .{ "else", .Else },
        .{ "unless", .Unless },
        .{ "each", .Each },
        .{ "while", .While },
        .{ "case", .Case },
        .{ "when", .When },
        .{ "default", .Default },
        .{ "mixin", .Mixin },
        .{ "include", .Include },
        .{ "extends", .Extends },
        .{ "block", .Block },
        .{ "append", .Append },
        .{ "prepend", .Prepend },
        .{ "doctype", .Doctype },
        .{ "true", .Boolean },
        .{ "false", .Boolean },
    });
    return keywords.get(ident);
}

pub fn scanIdentifier(tokenizer: anytype) !Token {
    const start = tokenizer.pos;
    const start_line = tokenizer.line;
    const start_col = tokenizer.column;

    while (tokenizer.peekChar()) |ch| {
        // Allow ASCII alphanumeric, underscore, hyphen, and UTF-8 sequences
        if (isValidTextByte(ch)) {
            // If UTF-8 multi-byte, advance by full sequence length
            if (isUtf8Start(ch)) {
                const len = utf8SequenceLength(ch);
                var i: usize = 0;
                while (i < len and tokenizer.peekChar() != null) : (i += 1) {
                    _ = tokenizer.advance();
                }
            } else {
                _ = tokenizer.advance();
            }
        } else {
            break;
        }
    }

    const value = tokenizer.source[start..tokenizer.pos];

    // Check for keywords first to determine if this is a tag or keyword
    const token_type = getKeyword(value) orelse .Ident;

    // State transitions based on current state
    switch (tokenizer.state) {
        .Root, .Indent => {
            // At start of line: could be tag name or keyword
            // If not a keyword, it's a tag → always transition to TagStart
            // Keywords: each/while need Code state for their expressions
            if (token_type == .Ident) {
                tokenizer.state = .TagStart;
            } else if (token_type == .Each or token_type == .While) {
                // Loop keywords need Code state to avoid treating iterator as tag
                tokenizer.state = .Code;
            }
        },
        .TagStart => {
            // After tag name, could be continuation (rare) or text
            // Stay in TagStart for now, next token will determine
        },
        .AttrStart, .AttrEquals => {
            // Inside attributes, this is an attribute name or value
            tokenizer.state = .AttrName;
        },
        .Text => {
            // Already in text mode, stay there
        },
        else => {
            // In other states, identifiers maintain state
        },
    }

    return Token.init(token_type, value, start_line, start_col);
}
