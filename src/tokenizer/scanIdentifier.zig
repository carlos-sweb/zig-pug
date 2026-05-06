//! Scan identifier or keyword token
//!
//! Reads a sequence of valid identifier characters and checks if the
//! result matches a Pug keyword. Returns the appropriate token type.
//!
//! The tokenizer does not decide whether an identifier is a tag name,
//! an attribute name, or a JS variable — that is the parser's job.
//!
//! State transition:
//!   Root/Indent → TagStart is NOT set here anymore.
//!   The tokenizer stays in Root after reading an identifier.
//!   The parser decides what the identifier means in context.
//!
//! Valid identifier characters:
//!   ASCII alphanumeric, underscore, hyphen, UTF-8 multi-byte sequences
//!
//! Examples:
//!   "div"      → Ident("div")
//!   "if"       → If
//!   "each"     → Each
//!   "true"     → Boolean
//!   "data-val" → Ident("data-val")

const std = @import("std");
const Token = @import("Token.zig").Token;
const TokenType = @import("TokenType.zig").TokenType;
const utils = @import("utils.zig");

pub fn scanIdentifier(tokenizer: anytype) !Token {
    const start = tokenizer.pos;
    const start_line = tokenizer.line;
    const start_col = tokenizer.column;

    while (tokenizer.peekChar()) |ch| {
        if (utils.isValidTextByte(ch)) {
            if (utils.isUtf8Start(ch)) {
                const len = utils.utf8SequenceLength(ch);
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

    // Keyword check — only valid when this identifier is the first meaningful
    // token on the line, OR when we are inside a known keyword structure
    // that expects more keywords (e.g. "each item IN items").
    //
    // Examples:
    //   "if condition"      → If + Ident("condition")           (line start)
    //   "p if condition"    → Ident("p") + Text("if condition") (not line start)
    //   "each item in list" → Each + Ident("item") + In + ...  (in after Each)
    const is_line_start = switch (tokenizer.last_token_type) {
        .Newline, .Indent, .Dedent, .Eof => true,
        else => false,
    };

    // "in" is recognized as keyword only inside an each loop context
    const is_each_context = tokenizer.line_started_with_keyword and
        tokenizer.last_token_type == .Ident and
        std.mem.eql(u8, value, "in");

    const token_type = if ((is_line_start or is_each_context) and value.len >= 2 and value.len <= 7)
        utils.getKeyword(value) orelse .Ident
    else
        .Ident;

    return Token.init(token_type, value, start_line, start_col);
}
