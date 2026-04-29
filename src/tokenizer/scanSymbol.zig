//! Scan symbol or special shorthand token
//!
//! Handles:
//! - Shorthand syntax: .class and #id (in tag context)
//! - Single-character symbols: ( ) [ ] { } , : | . #
//! - Multi-character operators: != >= <= == && ||
//! - Code markers: = (buffered), - (unbuffered)
//!
//! UTF-8 helpers delegated to utils.zig.

const std = @import("std");
const Token = @import("Token.zig").Token;
const TokenType = @import("TokenType.zig").TokenType;
const TokenizerState = @import("TokenizerState.zig").TokenizerState;
const utils = @import("utils.zig");

/// Scan a class name or id name after . or # has already been consumed
fn scanShorthandName(tokenizer: anytype) []const u8 {
    const start = tokenizer.pos;
    while (tokenizer.peekChar()) |c| {
        if (utils.isValidTextByte(c)) {
            if (utils.isUtf8Start(c)) {
                const len = utils.utf8SequenceLength(c);
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
    return tokenizer.source[start..tokenizer.pos];
}

/// Returns true when the current state allows .class / #id shorthand
fn isTagContext(state: TokenizerState) bool {
    return switch (state) {
        .Root, .Indent, .TagStart, .TagClass, .TagId => true,
        else => false,
    };
}

pub fn scanSymbol(tokenizer: anytype) !Token {
    const start_line = tokenizer.line;
    const start_col = tokenizer.column;
    const ch = tokenizer.peekChar().?;

    // .class shorthand
    if (ch == '.') {
        _ = tokenizer.advance();
        if (isTagContext(tokenizer.state)) {
            if (tokenizer.peekChar()) |next_ch| {
                if (std.ascii.isAlphabetic(next_ch) or next_ch == '_' or next_ch == '-' or utils.isUtf8Start(next_ch)) {
                    const value = scanShorthandName(tokenizer);
                    tokenizer.state = .TagClass;
                    return Token.init(.Class, value, start_line, start_col);
                }
            }
        }
        const value = tokenizer.source[tokenizer.pos - 1 .. tokenizer.pos];
        return Token.init(.Dot, value, start_line, start_col);
    }

    // #id shorthand
    if (ch == '#') {
        _ = tokenizer.advance();
        if (isTagContext(tokenizer.state)) {
            if (tokenizer.peekChar()) |next_ch| {
                if (std.ascii.isAlphabetic(next_ch) or next_ch == '_' or next_ch == '-' or utils.isUtf8Start(next_ch)) {
                    const value = scanShorthandName(tokenizer);
                    tokenizer.state = .TagId;
                    return Token.init(.Id, value, start_line, start_col);
                }
            }
        }
        const value = tokenizer.source[tokenizer.pos - 1 .. tokenizer.pos];
        return Token.init(.Hash, value, start_line, start_col);
    }

    _ = tokenizer.advance();

    // Multi-character operators
    if (ch == '!' and tokenizer.peekChar() == '=') {
        _ = tokenizer.advance();
        tokenizer.state = .Code;
        return Token.init(.UnescapedCode, tokenizer.source[tokenizer.pos - 2 .. tokenizer.pos], start_line, start_col);
    }
    if (ch == '>' and tokenizer.peekChar() == '=') {
        _ = tokenizer.advance();
        return Token.init(.GreaterEqual, tokenizer.source[tokenizer.pos - 2 .. tokenizer.pos], start_line, start_col);
    }
    if (ch == '<' and tokenizer.peekChar() == '=') {
        _ = tokenizer.advance();
        return Token.init(.LessEqual, tokenizer.source[tokenizer.pos - 2 .. tokenizer.pos], start_line, start_col);
    }
    if (ch == '=' and tokenizer.peekChar() == '=') {
        _ = tokenizer.advance();
        return Token.init(.Equal, tokenizer.source[tokenizer.pos - 2 .. tokenizer.pos], start_line, start_col);
    }
    if (ch == '&' and tokenizer.peekChar() == '&') {
        _ = tokenizer.advance();
        return Token.init(.And, tokenizer.source[tokenizer.pos - 2 .. tokenizer.pos], start_line, start_col);
    }
    if (ch == '|' and tokenizer.peekChar() == '|') {
        _ = tokenizer.advance();
        return Token.init(.Or, tokenizer.source[tokenizer.pos - 2 .. tokenizer.pos], start_line, start_col);
    }

    // State transitions for structural characters
    switch (ch) {
        '(' => {
            if (tokenizer.state == .TagStart or tokenizer.state == .TagClass or tokenizer.state == .TagId) {
                tokenizer.state = .AttrStart;
            }
        },
        ')' => {
            if (tokenizer.state == .AttrName or tokenizer.state == .AttrValue or tokenizer.state == .AttrStart) {
                tokenizer.state = .TagStart;
            }
        },
        '=' => {
            if (tokenizer.state == .AttrName) {
                tokenizer.state = .AttrEquals;
            }
        },
        else => {},
    }

    const value = tokenizer.source[tokenizer.pos - 1 .. tokenizer.pos];

    const token_type: TokenType = switch (ch) {
        '(' => .LParen,
        ')' => .RParen,
        '[' => .LBracket,
        ']' => .RBracket,
        '{' => .LBrace,
        '}' => .RBrace,
        ',' => .Comma,
        ':' => .Colon,
        '|' => .Pipe,
        '?' => .Question,
        '+' => .Plus,
        '>' => .Greater,
        '<' => .Less,
        '=' => blk: {
            tokenizer.state = .Code;
            break :blk .BufferedCode;
        },
        '-' => blk: {
            tokenizer.state = .Code;
            break :blk .UnbufferedCode;
        },
        '&', '!', '@', '$', '%', '^', '~', '`' => .Ident,
        else => {
            if (tokenizer.state == .TagStart or tokenizer.state == .TagClass or tokenizer.state == .TagId) {
                return Token.init(.Ident, value, start_line, start_col);
            }
            std.debug.print("Unexpected character at {d}:{d}: '{c}' (0x{x})\n", .{ start_line, start_col, ch, ch });
            return error.UnexpectedCharacter;
        },
    };

    return Token.init(token_type, value, start_line, start_col);
}
