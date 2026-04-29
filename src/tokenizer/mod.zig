//! Tokenizer module - Lexical Analysis
//!
//! Converts Pug template source code into a stream of tokens.
//! First phase of the compilation pipeline.
//!
//! Flow:
//! 1. Source code → Tokenizer.init()
//! 2. Call next() repeatedly to get tokens
//! 3. Parser consumes tokens to build AST
//!
//! Example:
//! ```zig
//! const source = "div.container\n  p Hello #{name}";
//! var tokenizer = try Tokenizer.init(allocator, source);
//! defer tokenizer.deinit();
//!
//! while (true) {
//!     const token = try tokenizer.next();
//!     if (token.type == .Eof) break;
//! }
//! ```

const std = @import("std");

// Public exports
pub const TokenizerState = @import("TokenizerState.zig").TokenizerState;
pub const TokenType     = @import("TokenType.zig").TokenType;
pub const Token         = @import("Token.zig").Token;
pub const TokenizerError = @import("TokenizerError.zig").TokenizerError;

// Scan functions
const scanIdentifier   = @import("scanIdentifier.zig").scanIdentifier;
const scanString       = @import("scanString.zig").scanString;
const scanNumber       = @import("scanNumber.zig").scanNumber;
const scanComment      = @import("scanComment.zig").scanComment;
const skipDocComment   = @import("scanComment.zig").skipDocComment;
const scanInterpolation = @import("scanInterpolation.zig").scanInterpolation;
const scanSymbol       = @import("scanSymbol.zig").scanSymbol;
const scanText         = @import("scanText.zig").scanText;

// Shared utilities (UTF-8, keyword lookup)
const utils = @import("utils.zig");

pub const Tokenizer = struct {
    source: []const u8,
    pos: usize,
    line: usize,
    column: usize,
    allocator: std.mem.Allocator,
    indent_stack: std.ArrayListUnmanaged(usize),
    pending_tokens: std.ArrayListUnmanaged(Token),
    at_line_start: bool,
    state: TokenizerState,

    pub fn init(allocator: std.mem.Allocator, source: []const u8) !Tokenizer {
        var tokenizer = Tokenizer{
            .source        = source,
            .pos           = 0,
            .line          = 1,
            .column        = 1,
            .allocator     = allocator,
            .indent_stack   = .empty,
            .pending_tokens = .empty,
            .at_line_start  = true,
            .state         = TokenizerState.Root,
        };
        try tokenizer.indent_stack.append(allocator, 0);
        return tokenizer;
    }

    pub fn deinit(self: *Tokenizer) void {
        self.indent_stack.deinit(self.allocator);
        self.pending_tokens.deinit(self.allocator);
    }

    // =========================================================================
    // Navigation
    // =========================================================================

    pub fn peekChar(self: *Tokenizer) ?u8 {
        if (self.pos >= self.source.len) return null;
        return self.source[self.pos];
    }

    pub fn peekAhead(self: *Tokenizer, offset: usize) ?u8 {
        const pos = self.pos + offset;
        if (pos >= self.source.len) return null;
        return self.source[pos];
    }

    pub fn advance(self: *Tokenizer) ?u8 {
        if (self.pos >= self.source.len) return null;
        const ch = self.source[self.pos];
        self.pos += 1;
        if (ch == '\n') {
            self.line += 1;
            self.column = 1;
        } else {
            self.column += 1;
        }
        return ch;
    }

    pub fn skipWhitespaceExceptNewline(self: *Tokenizer) void {
        while (self.peekChar()) |ch| {
            if (ch == ' ' or ch == '\t' or ch == '\r') {
                _ = self.advance();
            } else {
                break;
            }
        }
    }

    // =========================================================================
    // Indentation
    // =========================================================================

    fn handleIndentation(self: *Tokenizer) !void {
        if (!self.at_line_start) return;

        var indent: usize = 0;
        while (self.peekChar()) |ch| {
            if (ch == ' ') {
                indent += 1;
                _ = self.advance();
            } else if (ch == '\t') {
                return error.InvalidIndentation;
            } else {
                break;
            }
        }

        // Skip empty lines
        if (self.peekChar()) |ch| {
            if (ch == '\n') {
                self.at_line_start = true;
                return;
            }
        }

        const current_indent = self.indent_stack.items[self.indent_stack.items.len - 1];

        if (indent > current_indent) {
            try self.indent_stack.append(self.allocator, indent);
            // Insertar en orden inverso: se consume con pop() O(1)
            try self.pending_tokens.append(self.allocator, Token.init(.Indent, "", self.line, 1));
        } else if (indent < current_indent) {
            // Contar cuántos DEDENTs emitir primero
            var dedent_count: usize = 0;
            while (self.indent_stack.items.len > 0 and
                self.indent_stack.items[self.indent_stack.items.len - 1] > indent)
            {
                _ = self.indent_stack.pop();
                dedent_count += 1;
            }
            if (self.indent_stack.items.len == 0 or
                self.indent_stack.items[self.indent_stack.items.len - 1] != indent)
            {
                return error.InvalidIndentation;
            }
            // Insertar en orden inverso: el primero que se consume va al final
            var i: usize = 0;
            while (i < dedent_count) : (i += 1) {
                try self.pending_tokens.append(self.allocator, Token.init(.Dedent, "", self.line, 1));
            }
        }

        self.at_line_start = false;
    }

    // =========================================================================
    // Main dispatch
    // =========================================================================

    pub fn next(self: *Tokenizer) !Token {
        // Pending INDENT/DEDENT tokens — consumo O(1) con pop()
        if (self.pending_tokens.items.len > 0) {
            return self.pending_tokens.pop().?;
        }

        try self.handleIndentation();

        if (self.pending_tokens.items.len > 0) {
            return self.pending_tokens.pop().?;
        }

        self.skipWhitespaceExceptNewline();

        const ch = self.peekChar() orelse {
            // Flush remaining DEDENTs at EOF
            if (self.indent_stack.items.len > 1) {
                _ = self.indent_stack.pop();
                return Token.init(.Dedent, "", self.line, self.column);
            }
            return Token.init(.Eof, "", self.line, self.column);
        };

        if (ch == '\n') {
            self.at_line_start = true;
            self.state = .Root;
            const line = self.line;
            _ = self.advance();
            return Token.init(.Newline, "\n", line, 1);
        }

        // Comments (context-independent)
        if (ch == '/' and self.peekAhead(1) == '/') {
            if (self.peekAhead(2) == '!') {
                skipDocComment(self);
                return self.next();
            }
            return scanComment(self);
        }

        // Interpolation (context-independent)
        if ((ch == '#' or ch == '!') and self.peekAhead(1) == '{') {
            return scanInterpolation(self);
        }

        return switch (self.state) {
            .Root, .Indent => {
                if (ch == '"' or ch == '\'') return scanString(self, ch);
                if (std.ascii.isDigit(ch)) return scanNumber(self);
                if (std.ascii.isAlphabetic(ch) or ch == '_' or utils.isUtf8Start(ch)) return scanIdentifier(self);
                return scanSymbol(self);
            },

            .TagStart, .TagClass, .TagId => {
                if (ch == '.' or ch == '#' or ch == '(' or ch == '=' or ch == '-') return scanSymbol(self);
                if (ch == '!') {
                    if (self.peekAhead(1) == '=') return scanSymbol(self);
                }
                if (ch == ' ') {
                    _ = self.advance();
                    self.state = .Text;
                    return self.next();
                }
                self.state = .Text;
                return scanText(self);
            },

            .AttrStart, .AttrName, .AttrEquals, .AttrValue, .AttrString, .AttrJS => {
                if (ch == ')') return scanSymbol(self);
                if (ch == ',') {
                    const tok = try scanSymbol(self);
                    self.state = .AttrName;
                    return tok;
                }
                if (ch == '=') return scanSymbol(self);
                if (ch == '"' or ch == '\'') {
                    self.state = .AttrString;
                    return scanString(self, ch);
                }
                if (std.ascii.isAlphabetic(ch) or ch == '_' or ch == '-' or utils.isUtf8Start(ch)) return scanIdentifier(self);
                if (std.ascii.isDigit(ch)) return scanNumber(self);
                return scanSymbol(self);
            },

            .Text => return scanText(self),

            .Code => {
                if (ch == '"' or ch == '\'') return scanString(self, ch);
                if (std.ascii.isDigit(ch)) return scanNumber(self);
                if (std.ascii.isAlphabetic(ch) or ch == '_' or utils.isUtf8Start(ch)) return scanIdentifier(self);
                return scanSymbol(self);
            },

            .Loop => {
                if (ch == '"' or ch == '\'') return scanString(self, ch);
                if (std.ascii.isDigit(ch)) return scanNumber(self);
                if (std.ascii.isAlphabetic(ch) or ch == '_' or utils.isUtf8Start(ch)) return scanIdentifier(self);
                if (ch == ',') return scanSymbol(self);
                return scanSymbol(self);
            },
        };
    }
};
