//! Scan symbol or special shorthand token
//!
//! Handles:
//! - Shorthand syntax: .class and #id (in tag context)
//! - Single-character symbols: ( ) [ ] { } , : | . #
//! - Multi-character operators: != >= <= == && ||
//! - Code markers: = (buffered), - (unbuffered)
//!
//! State transitions:
//! - ( in TagStart → AttrStart
//! - ) in attributes → back to TagStart or Text
//! - .class/#id only recognized in tag context
//!
//! Returns: Appropriate symbol or shorthand token
//!
//! Errors:
//! - UnexpectedCharacter: Invalid symbol

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
    if (first_byte < 0x80) return 1;
    if (first_byte < 0xC0) return 1;
    if (first_byte < 0xE0) return 2;
    if (first_byte < 0xF0) return 3;
    return 4;
}

/// Check if a byte is valid in identifiers or text
fn isValidTextByte(byte: u8) bool {
    if (std.ascii.isAlphanumeric(byte) or byte == '_' or byte == '-') {
        return true;
    }
    if (byte >= 0x80) {
        return true;
    }
    return false;
}

pub fn scanSymbol(tokenizer: anytype) !Token {
    const start_line = tokenizer.line;
    const start_col = tokenizer.column;
    const ch = tokenizer.peekChar().?;

    // Handle .class shorthand
    if (ch == '.') {
        _ = tokenizer.advance();

        // Treat as class in tag context or at root (implicit div)
        // BUT NOT in Code context (JavaScript expressions)
        if ((tokenizer.state == .Root or tokenizer.state == .Indent or
            tokenizer.state == .TagStart or tokenizer.state == .TagClass or tokenizer.state == .TagId) and
            tokenizer.state != .Code) {
            if (tokenizer.peekChar()) |next_ch| {
                if (std.ascii.isAlphabetic(next_ch) or next_ch == '_' or next_ch == '-' or isUtf8Start(next_ch)) {
                    const start = tokenizer.pos;
                    while (tokenizer.peekChar()) |c| {
                        if (isValidTextByte(c)) {
                            if (isUtf8Start(c)) {
                                const len = utf8SequenceLength(c);
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
                    tokenizer.state = .TagClass;
                    return Token.init(.Class, value, start_line, start_col);
                }
            }
        }

        // Not in appropriate context or not followed by identifier - just a dot
        const value = tokenizer.source[tokenizer.pos - 1 .. tokenizer.pos];
        return Token.init(.Dot, value, start_line, start_col);
    }

    // Handle #id shorthand
    if (ch == '#') {
        _ = tokenizer.advance();

        // Treat as id in tag context or at root (implicit div)
        // BUT NOT in Code context (JavaScript expressions)
        if ((tokenizer.state == .Root or tokenizer.state == .Indent or
            tokenizer.state == .TagStart or tokenizer.state == .TagClass or tokenizer.state == .TagId) and
            tokenizer.state != .Code) {
            if (tokenizer.peekChar()) |next_ch| {
                if (std.ascii.isAlphabetic(next_ch) or next_ch == '_' or next_ch == '-' or isUtf8Start(next_ch)) {
                    const start = tokenizer.pos;
                    while (tokenizer.peekChar()) |c| {
                        if (isValidTextByte(c)) {
                            if (isUtf8Start(c)) {
                                const len = utf8SequenceLength(c);
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
                    tokenizer.state = .TagId;
                    return Token.init(.Id, value, start_line, start_col);
                }
            }
        }

        // Not in appropriate context - just a hash
        const value = tokenizer.source[tokenizer.pos - 1 .. tokenizer.pos];
        return Token.init(.Hash, value, start_line, start_col);
    }

    _ = tokenizer.advance();

    // Check for multi-character operators
    if (ch == '!' and tokenizer.peekChar() == '=') {
        _ = tokenizer.advance();
        const value = tokenizer.source[tokenizer.pos - 2 .. tokenizer.pos];
        tokenizer.state = .Code;  // Enter JavaScript expression context
        return Token.init(.UnescapedCode, value, start_line, start_col);
    }

    if (ch == '>' and tokenizer.peekChar() == '=') {
        _ = tokenizer.advance();
        const value = tokenizer.source[tokenizer.pos - 2 .. tokenizer.pos];
        return Token.init(.GreaterEqual, value, start_line, start_col);
    }
    if (ch == '<' and tokenizer.peekChar() == '=') {
        _ = tokenizer.advance();
        const value = tokenizer.source[tokenizer.pos - 2 .. tokenizer.pos];
        return Token.init(.LessEqual, value, start_line, start_col);
    }
    if (ch == '=' and tokenizer.peekChar() == '=') {
        _ = tokenizer.advance();
        const value = tokenizer.source[tokenizer.pos - 2 .. tokenizer.pos];
        return Token.init(.Equal, value, start_line, start_col);
    }
    if (ch == '&' and tokenizer.peekChar() == '&') {
        _ = tokenizer.advance();
        const value = tokenizer.source[tokenizer.pos - 2 .. tokenizer.pos];
        return Token.init(.And, value, start_line, start_col);
    }
    if (ch == '|' and tokenizer.peekChar() == '|') {
        _ = tokenizer.advance();
        const value = tokenizer.source[tokenizer.pos - 2 .. tokenizer.pos];
        return Token.init(.Or, value, start_line, start_col);
    }

    // State transitions for parentheses
    if (ch == '(') {
        if (tokenizer.state == .TagStart or tokenizer.state == .TagClass or tokenizer.state == .TagId) {
            tokenizer.state = .AttrStart;
        }
    } else if (ch == ')') {
        if (tokenizer.state == .AttrName or tokenizer.state == .AttrValue or tokenizer.state == .AttrStart) {
            tokenizer.state = .TagStart; // Back to tag context
        }
    } else if (ch == '=') {
        if (tokenizer.state == .AttrName) {
            tokenizer.state = .AttrEquals;
        }
    }

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
        '=' => blk: {
            tokenizer.state = .Code;  // Enter JavaScript expression context
            break :blk .BufferedCode;
        },
        '+' => .Plus,
        '-' => blk: {
            tokenizer.state = .Code;  // Enter JavaScript expression context
            break :blk .UnbufferedCode;
        },
        '>' => .Greater,
        '<' => .Less,
        '&' => .Ident, // Standalone & treated as text
        '!' => .Ident, // Standalone ! treated as text
        else => {
            std.debug.print("Unexpected character at {d}:{d}: '{c}' (0x{x})\n", .{ start_line, start_col, ch, ch });
            return error.UnexpectedCharacter;
        },
    };

    const value = tokenizer.source[tokenizer.pos - 1 .. tokenizer.pos];
    return Token.init(token_type, value, start_line, start_col);
}
