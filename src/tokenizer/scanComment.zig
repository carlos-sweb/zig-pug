//! Scan comment token (// or //-)
//!
//! Pug has three comment types:
//! - // buffered comment → emitted to HTML
//! - //- unbuffered comment → not in output
//! - //! documentation comment → completely ignored (handled separately)
//!
//! Reads from // or //- to end of line.
//!
//! Returns: BufferedComment or UnbufferedComment token
//!
//! Example:
//! ```
//! // This appears in HTML
//! //- This is a code comment
//! ```

const std = @import("std");
const Token = @import("Token.zig").Token;
const TokenType = @import("TokenType.zig").TokenType;

pub fn scanComment(tokenizer: anytype) !Token {
    const start_line = tokenizer.line;
    const start_col = tokenizer.column;

    _ = tokenizer.advance(); // First /
    _ = tokenizer.advance(); // Second /

    const is_unbuffered = if (tokenizer.peekChar()) |ch| ch == '-' else false;
    if (is_unbuffered) {
        _ = tokenizer.advance(); // -
    }

    // Skip space after comment marker
    if (tokenizer.peekChar()) |ch| {
        if (ch == ' ') _ = tokenizer.advance();
    }

    const start = tokenizer.pos;
    while (tokenizer.peekChar()) |ch| {
        if (ch == '\n') break;
        _ = tokenizer.advance();
    }

    const value = tokenizer.source[start..tokenizer.pos];
    const token_type = if (is_unbuffered) TokenType.UnbufferedComment else TokenType.BufferedComment;

    // Comments don't change state
    return Token.init(token_type, value, start_line, start_col);
}

/// Skip documentation comment //!
///
/// Documentation comments are completely ignored by the parser.
/// They can appear anywhere, including before doctype declarations.
pub fn skipDocComment(tokenizer: anytype) void {
    _ = tokenizer.advance(); // First /
    _ = tokenizer.advance(); // Second /
    _ = tokenizer.advance(); // !

    // Skip the entire line
    while (tokenizer.peekChar()) |ch| {
        if (ch == '\n') break;
        _ = tokenizer.advance();
    }
}
