//! Scan string literal token
//!
//! Reads a quoted string (double or single quotes) with escape support.
//! The tokenizer does not interpret the string content — it captures
//! everything between the delimiters as-is and passes it to the parser.
//!
//! Parameters:
//!   quote — opening quote character ('"' or '\'')
//!
//! Returns: String token with content between quotes (quotes not included)
//!
//! Errors:
//!   UnterminatedString — closing quote never found
//!
//! Escape sequences:
//!   Any character preceded by \ is included literally.
//!   This covers \", \', \\, \n, \t and anything else.
//!
//! Examples:
//!   "hello"            →  String("hello")
//!   'world'            →  String("world")
//!   "it's ok"          →  String("it's ok")
//!   "say \"hi\""       →  String("say \"hi\"")
//!   'it\'s fine'       →  String("it\'s fine")
//!   "alert('hi')"      →  String("alert('hi')")

const Token = @import("Token.zig").Token;
const TokenType = @import("TokenType.zig").TokenType;

pub fn scanString(tokenizer: anytype, quote: u8) !Token {
    const start_line = tokenizer.line;
    const start_col = tokenizer.column;
    _ = tokenizer.advance(); // consume opening quote

    const start = tokenizer.pos;

    while (tokenizer.peekChar()) |ch| {
        if (ch == quote) {
            // Found closing quote — capture content and consume it
            const value = tokenizer.source[start..tokenizer.pos];
            _ = tokenizer.advance();
            return Token.init(.String, value, start_line, start_col);
        }
        if (ch == '\\') {
            _ = tokenizer.advance(); // consume backslash
            if (tokenizer.peekChar() != null) {
                _ = tokenizer.advance(); // consume escaped character
            }
        } else {
            _ = tokenizer.advance();
        }
    }

    return error.UnterminatedString;
}
