//! Scan symbol or operator token
//!
//! Recognizes single and multi-character punctuation and operators.
//! Also handles the Pug shorthands:
//!   .classname  → Class token
//!   #idname     → Id token
//!
//! The tokenizer does not track whether it is inside an attribute list
//! or a JS expression — that context belongs to the parser.
//!
//! State transitions:
//!   After reading plain text content (|, space after tag) → Text state
//!   Everything else → no state change, stays in Root
//!
//! Examples:
//!   "("   → LParen
//!   "!="  → NotEqual
//!   ".foo" → Class("foo")
//!   "#bar" → Id("bar")
//!   "."   → Dot  (when not followed by an identifier start)
//!   "#"   → Hash (when not followed by an identifier start)

const std = @import("std");
const Token = @import("Token.zig").Token;
const TokenType = @import("TokenType.zig").TokenType;
const TokenizerState = @import("TokenizerState.zig").TokenizerState;
const utils = @import("utils.zig");

/// Read a name after . or # has been consumed
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

/// Returns true if the next character can start an identifier
fn isIdentStart(ch: u8) bool {
    return std.ascii.isAlphabetic(ch) or ch == '_' or ch == '-' or utils.isUtf8Start(ch);
}

pub fn scanSymbol(tokenizer: anytype) !Token {
    const start_line = tokenizer.line;
    const start_col = tokenizer.column;
    const ch = tokenizer.peekChar().?;

    // .classname shorthand — only outside parentheses AND not in keyword context
    // In keyword lines (if/each/while/...) a dot is always a property accessor (Dot),
    // never a CSS class shorthand.
    if (ch == '.') {
        _ = tokenizer.advance();
        if (tokenizer.paren_depth == 0 and !tokenizer.line_started_with_keyword) {
            if (tokenizer.peekChar()) |next| {
                if (isIdentStart(next)) {
                    const value = scanShorthandName(tokenizer);
                    return Token.init(.Class, value, start_line, start_col);
                }
            }
        }
        return Token.init(.Dot, ".", start_line, start_col);
    }

    // #idname shorthand — only outside parentheses
    if (ch == '#') {
        _ = tokenizer.advance();
        if (tokenizer.paren_depth == 0) {
            if (tokenizer.peekChar()) |next| {
                if (isIdentStart(next)) {
                    const value = scanShorthandName(tokenizer);
                    return Token.init(.Id, value, start_line, start_col);
                }
            }
        }
        return Token.init(.Hash, "#", start_line, start_col);
    }

    // Digits — read the full sequence and emit as Ident.
    // The tokenizer does not interpret numeric values.
    // The parser decides what a digit sequence means in context.
    //
    // A dot is consumed only if immediately followed by another digit,
    // so "0.5" → Ident("0.5") but "3.items" → Ident("3") + Class("items")
    if (std.ascii.isDigit(ch)) {
        const start = tokenizer.pos;
        while (tokenizer.peekChar()) |c| {
            if (std.ascii.isDigit(c)) {
                _ = tokenizer.advance();
            } else if (c == '.') {
                // Only consume the dot if the next character is a digit
                const next = tokenizer.peekAhead(1);
                if (next != null and std.ascii.isDigit(next.?)) {
                    _ = tokenizer.advance(); // consume dot
                } else {
                    break;
                }
            } else {
                break;
            }
        }
        const value = tokenizer.source[start..tokenizer.pos];
        return Token.init(.Ident, value, start_line, start_col);
    }

    _ = tokenizer.advance();

    // Multi-character operators
    if (ch == '!' and tokenizer.peekChar() == '=') {
        _ = tokenizer.advance();
        return Token.init(.NotEqual, "!=", start_line, start_col);
    }
    if (ch == '>' and tokenizer.peekChar() == '=') {
        _ = tokenizer.advance();
        return Token.init(.GreaterEqual, ">=", start_line, start_col);
    }
    if (ch == '<' and tokenizer.peekChar() == '=') {
        _ = tokenizer.advance();
        return Token.init(.LessEqual, "<=", start_line, start_col);
    }
    if (ch == '=' and tokenizer.peekChar() == '=') {
        _ = tokenizer.advance();
        return Token.init(.Equal, "==", start_line, start_col);
    }
    if (ch == '&' and tokenizer.peekChar() == '&') {
        _ = tokenizer.advance();
        return Token.init(.And, "&&", start_line, start_col);
    }
    if (ch == '|' and tokenizer.peekChar() == '|') {
        _ = tokenizer.advance();
        return Token.init(.Or, "||", start_line, start_col);
    }

    // Pipe at start of line means plain text block — switch to Text state
    if (ch == '|') {
        tokenizer.state = .Text;
        return Token.init(.Pipe, "|", start_line, start_col);
    }

    // Single-character symbols
    const token_type: TokenType = switch (ch) {
        '(' => blk: {
            tokenizer.paren_depth += 1;
            break :blk .LParen;
        },
        ')' => blk: {
            if (tokenizer.paren_depth > 0) tokenizer.paren_depth -= 1;
            break :blk .RParen;
        },
        '[' => .LBracket,
        ']' => .RBracket,
        '{' => .LBrace,
        '}' => .RBrace,
        ',' => .Comma,
        ':' => .Colon,
        '+' => .Plus,
        '-' => blk: {
            const is_line_start = switch (tokenizer.last_token_type) {
                .Newline, .Indent, .Dedent, .Eof => true,
                else => false,
            };
            if (is_line_start) {
                if (tokenizer.peekChar() == ' ') _ = tokenizer.advance();
                const stmt_start = tokenizer.pos;
                while (tokenizer.peekChar()) |c| {
                    if (c == '\n') break;
                    _ = tokenizer.advance();
                }
                const stmt_value = tokenizer.source[stmt_start..tokenizer.pos];
                return Token.init(.JsStatement, stmt_value, start_line, start_col);
            }
            break :blk .Minus;
        },
        '=' => .BufferedCode,
        '>' => .Greater,
        '<' => .Less,
        '?' => .Question,
        '!' => .Ident, // lone ! without { — parser decides; typically trailing punctuation
        else => {
            std.debug.print(
                "Unexpected character at {d}:{d}: '{c}' (0x{x})\n",
                .{ start_line, start_col, ch, ch },
            );
            return error.UnexpectedCharacter;
        },
    };

    const value = tokenizer.source[tokenizer.pos - 1 .. tokenizer.pos];
    return Token.init(token_type, value, start_line, start_col);
}
