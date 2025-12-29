//! Scan plain text content
//!
//! In Text state, reads everything until newline or interpolation.
//! This prevents .class and #id from being parsed as tokens inside text.
//!
//! Example:
//! ```pug
//! p This is text with #hashtag and .period marks
//! ```
//! In this case, #hashtag and .period should be part of text, not Id/Class tokens.
//!
//! Returns to Root state at newline.

const std = @import("std");
const Token = @import("Token.zig").Token;
const TokenType = @import("TokenType.zig").TokenType;
const TokenizerState = @import("TokenizerState.zig").TokenizerState;

pub fn scanText(tokenizer: anytype) !Token {
    const start = tokenizer.pos;
    const start_line = tokenizer.line;
    const start_col = tokenizer.column;

    // Read until newline or interpolation start
    while (tokenizer.peekChar()) |ch| {
        if (ch == '\n') {
            break;
        }

        // Stop at interpolation start
        if (ch == '#' and tokenizer.peekAhead(1) == '{') {
            break;
        }
        if (ch == '!' and tokenizer.peekAhead(1) == '{') {
            break;
        }

        _ = tokenizer.advance();
    }

    const value = tokenizer.source[start..tokenizer.pos];

    // Return to Root state at newline or EOF
    // This prevents returning empty tokens when EOF is reached
    if (tokenizer.peekChar()) |ch| {
        if (ch == '\n') {
            tokenizer.state = .Root;
        }
    } else {
        // At EOF, return to Root state
        tokenizer.state = .Root;
    }

    return Token.init(.Ident, value, start_line, start_col);
}
