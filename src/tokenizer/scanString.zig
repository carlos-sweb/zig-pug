//! Scan string literal token
//!
//! Reads quoted string (double or single quotes) with escape support.
//! In attribute context, transitions state back to AttrName after string.
//!
//! Parameters:
//! - quote: Opening quote character (' or ")
//!
//! Returns: String token with content between quotes
//!
//! Errors:
//! - UnterminatedString: Missing closing quote
//!
//! Examples:
//! ```
//! "hello"           → String("hello")
//! 'world'           → String("world")
//! "it's ok"         → String("it's ok")
//! "line\nbreak"     → String("line\nbreak") (with escape)
//! ```

const std = @import("std");
const Token = @import("Token.zig").Token;
const TokenType = @import("TokenType.zig").TokenType;
const TokenizerState = @import("TokenizerState.zig").TokenizerState;

pub fn scanString(tokenizer: anytype, quote: u8) !Token {
    const start_line = tokenizer.line;
    const start_col = tokenizer.column;
    _ = tokenizer.advance(); // Skip opening quote

    const start = tokenizer.pos;
    while (tokenizer.peekChar()) |ch| {
        if (ch == quote) {
            const value = tokenizer.source[start..tokenizer.pos];
            _ = tokenizer.advance(); // Skip closing quote

            // State transitions
            switch (tokenizer.state) {
                .AttrValue, .AttrString => {
                    // In attributes, after string we expect comma or closing paren
                    tokenizer.state = .AttrName;
                },
                else => {
                    // In other contexts, strings don't change state
                },
            }

            return Token.init(.String, value, start_line, start_col);
        }
        if (ch == '\\') {
            _ = tokenizer.advance(); // Skip escape
            if (tokenizer.peekChar()) |_| {
                _ = tokenizer.advance(); // Skip escaped char
            }
        } else {
            _ = tokenizer.advance();
        }
    }

    return error.UnterminatedString;
}
