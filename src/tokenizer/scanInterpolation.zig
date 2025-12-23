//! Scan interpolation token #{...} or !{...}
//!
//! Interpolations embed JavaScript expressions in templates:
//! - #{expr} → escaped (HTML-safe)
//! - !{expr} → unescaped (raw HTML)
//!
//! Handles nested braces by counting brace depth.
//!
//! Returns: EscapedInterpol or UnescapedInterpol token
//!
//! Errors:
//! - UnterminatedString: Missing closing }
//! - UnexpectedCharacter: # or ! not followed by {
//!
//! Example:
//! ```
//! p Hello #{user.name}        // Escaped
//! div !{raw_html}              // Unescaped
//! p Count: #{items.length}     // Expression
//! ```

const std = @import("std");
const Token = @import("Token.zig").Token;
const TokenType = @import("TokenType.zig").TokenType;

pub fn scanInterpolation(tokenizer: anytype) !Token {
    const start_line = tokenizer.line;
    const start_col = tokenizer.column;

    const first_ch = tokenizer.advance().?; // # or !
    const is_unescaped = first_ch == '!';

    if (tokenizer.peekChar() != '{') {
        return error.UnexpectedCharacter;
    }
    _ = tokenizer.advance(); // {

    const start = tokenizer.pos;
    var brace_count: usize = 1;

    while (tokenizer.peekChar()) |ch| {
        if (ch == '{') {
            brace_count += 1;
        } else if (ch == '}') {
            brace_count -= 1;
            if (brace_count == 0) {
                const value = tokenizer.source[start..tokenizer.pos];
                _ = tokenizer.advance(); // }
                const token_type = if (is_unescaped) TokenType.UnescapedInterpol else TokenType.EscapedInterpol;

                // Interpolations don't change state - they can appear in text or attributes
                return Token.init(token_type, value, start_line, start_col);
            }
        }
        _ = tokenizer.advance();
    }

    return error.UnterminatedString;
}
