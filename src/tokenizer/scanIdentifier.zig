//! Scan identifier or keyword token
//!
//! Reads alphanumeric characters plus _ and - to form identifiers.
//! Behavior depends on current tokenizer state:
//! - Root/Indent: Tag name → transition to TagStart
//! - TagStart: Continuation of tag
//! - AttrStart/AttrName: Attribute name
//! - Text: Part of text content
//!
//! Keyword resolution delegated to utils.getKeyword().

const std = @import("std");
const Token = @import("Token.zig").Token;
const TokenType = @import("TokenType.zig").TokenType;
const TokenizerState = @import("TokenizerState.zig").TokenizerState;
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
    const token_type = utils.getKeyword(value) orelse .Ident;

    switch (tokenizer.state) {
        .Root, .Indent => {
            if (token_type == .Ident) {
                tokenizer.state = .TagStart;
            } else if (token_type == .Each or token_type == .While) {
                tokenizer.state = .Loop;
            }
        },
        .Loop => {
            if (token_type == .In) {
                tokenizer.state = .Code;
            }
        },
        .AttrStart, .AttrEquals => {
            tokenizer.state = .AttrName;
        },
        else => {},
    }

    return Token.init(token_type, value, start_line, start_col);
}
