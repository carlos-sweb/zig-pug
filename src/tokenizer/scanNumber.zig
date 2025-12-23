//! Scan number literal token
//!
//! Reads integer or decimal numbers.
//! Numbers maintain current state (could be in attributes, text, etc.)
//!
//! Returns: Number token
//!
//! Examples:
//! ```
//! 42      → Number("42")
//! 3.14    → Number("3.14")
//! 0.5     → Number("0.5")
//! ```

const std = @import("std");
const Token = @import("Token.zig").Token;
const TokenType = @import("TokenType.zig").TokenType;

pub fn scanNumber(tokenizer: anytype) !Token {
    const start = tokenizer.pos;
    const start_line = tokenizer.line;
    const start_col = tokenizer.column;

    while (tokenizer.peekChar()) |ch| {
        if (std.ascii.isDigit(ch) or ch == '.') {
            _ = tokenizer.advance();
        } else {
            break;
        }
    }

    const value = tokenizer.source[start..tokenizer.pos];
    // Numbers don't change tokenizer state
    return Token.init(.Number, value, start_line, start_col);
}
