//! Tokenizer — Lexical Analysis
//!
//! Converts Pug template source into a flat stream of tokens.
//! This is the first phase of the compilation pipeline.
//!
//! Responsibilities:
//!   - Recognize surface syntax: tags, classes, ids, strings, symbols
//!   - Track indentation and emit Indent/Dedent tokens
//!   - Recognize Pug keywords
//!   - Recognize interpolation #{...} and !{...}
//!   - Recognize comments // and //-
//!
//! NOT the tokenizer's responsibility:
//!   - Understanding attribute context
//!   - Interpreting JS expressions
//!   - Deciding what follows = in an attribute
//!   - Any semantic meaning beyond surface character patterns
//!
//! Usage:
//!   var tokenizer = try Tokenizer.init(allocator, source);
//!   defer tokenizer.deinit();
//!   while (true) {
//!       const token = try tokenizer.next();
//!       if (token.type == .Eof) break;
//!   }

const std = @import("std");

pub const TokenizerState = @import("TokenizerState.zig").TokenizerState;
pub const TokenType      = @import("TokenType.zig").TokenType;
pub const Token          = @import("Token.zig").Token;
pub const TokenizerError = @import("TokenizerError.zig").TokenizerError;

const scanIdentifier    = @import("scanIdentifier.zig").scanIdentifier;
const scanString        = @import("scanString.zig").scanString;
const scanComment       = @import("scanComment.zig").scanComment;
const skipDocComment    = @import("scanComment.zig").skipDocComment;
const scanInterpolation = @import("scanInterpolation.zig").scanInterpolation;
const scanSymbol        = @import("scanSymbol.zig").scanSymbol;
const scanText          = @import("scanText.zig").scanText;

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
    paren_depth: usize,
    after_space: bool,              // true when skipWhitespace consumed at least one space
    last_token_type: TokenType,     // type of the last emitted token
    line_started_with_keyword: bool, // true when the first token of the line was a keyword

    pub fn init(allocator: std.mem.Allocator, source: []const u8) !Tokenizer {
        var tokenizer = Tokenizer{
            .source           = source,
            .pos              = 0,
            .line             = 1,
            .column           = 1,
            .allocator        = allocator,
            .indent_stack     = .empty,
            .pending_tokens   = .empty,
            .at_line_start    = true,
            .state            = .Root,
            .paren_depth      = 0,
            .after_space      = false,
            .last_token_type  = .Eof,
            .line_started_with_keyword = false,
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
        const pos_before = self.pos;
        while (self.peekChar()) |ch| {
            if (ch == ' ' or ch == '\t' or ch == '\r') {
                _ = self.advance();
            } else {
                break;
            }
        }
        self.after_space = self.pos > pos_before;
    }

    // =========================================================================
    // Indentation — emits Indent/Dedent tokens
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

        const current = self.indent_stack.items[self.indent_stack.items.len - 1];

        if (indent > current) {
            try self.indent_stack.append(self.allocator, indent);
            try self.pending_tokens.append(self.allocator, Token.init(.Indent, "", self.line, 1));
        } else if (indent < current) {
            var count: usize = 0;
            while (self.indent_stack.items.len > 0 and
                self.indent_stack.items[self.indent_stack.items.len - 1] > indent)
            {
                _ = self.indent_stack.pop();
                count += 1;
            }
            if (self.indent_stack.items.len == 0 or
                self.indent_stack.items[self.indent_stack.items.len - 1] != indent)
            {
                return error.InvalidIndentation;
            }
            var i: usize = 0;
            while (i < count) : (i += 1) {
                try self.pending_tokens.append(self.allocator, Token.init(.Dedent, "", self.line, 1));
            }
        }

        self.at_line_start = false;
    }

    // =========================================================================
    // Main dispatch — 3 states only
    // =========================================================================

    pub fn next(self: *Tokenizer) !Token {
        // Pending Indent/Dedent tokens — O(1) with pop()
        if (self.pending_tokens.items.len > 0) {
            return self.pending_tokens.pop().?;
        }

        try self.handleIndentation();

        if (self.pending_tokens.items.len > 0) {
            return self.pending_tokens.pop().?;
        }

        self.skipWhitespaceExceptNewline();

        const ch = self.peekChar() orelse {
            // Flush remaining Dedents at EOF
            if (self.indent_stack.items.len > 1) {
                _ = self.indent_stack.pop();
                return Token.init(.Dedent, "", self.line, self.column);
            }
            return Token.init(.Eof, "", self.line, self.column);
        };

        // Newline — reset to Root
        if (ch == '\n') {
            self.at_line_start = true;
            self.state = .Root;
            self.after_space = false;
            self.last_token_type = .Newline;
            self.line_started_with_keyword = false;
            const line = self.line;
            _ = self.advance();
            return Token.init(.Newline, "\n", line, 1);
        }

        // Comments — context independent
        if (ch == '/' and self.peekAhead(1) == '/') {
            if (self.peekAhead(2) == '!') {
                skipDocComment(self);
                return self.next();
            }
            return scanComment(self);
        }

        // Interpolation — context independent
        if ((ch == '#' or ch == '!') and self.peekAhead(1) == '{') {
            const was_text = self.last_token_type == .Text or
                self.last_token_type == .EscapedInterpol or
                self.last_token_type == .UnescapedInterpol;
            const token = try scanInterpolation(self);
            self.last_token_type = token.type;
            // If we were in text context, restore Text state so trailing
            // content like "!" in "#{name}!" is consumed as text not a symbol.
            if (was_text) self.state = .Text;
            return token;
        }

        return switch (self.state) {

            .Root, .Indent => {
                // Space after a tag (Ident/Class/Id) outside parentheses → plain text
                // Only when the line did NOT start with a keyword — keywords never
                // introduce text content, they introduce directive arguments.
                if (self.after_space and
                    self.paren_depth == 0 and
                    !self.line_started_with_keyword and
                    (self.last_token_type == .Ident or
                     self.last_token_type == .Class or
                     self.last_token_type == .Id or
                     self.last_token_type == .RParen))
                {
                    self.state = .Text;
                    const token = try scanText(self);
                    self.last_token_type = token.type;
                    return token;
                }
                if (ch == '"' or ch == '\'') {
                    const token = try scanString(self, ch);
                    self.last_token_type = token.type;
                    return token;
                }

                // After "in" — capture the rest of the line as Iterable.
                // Must be checked BEFORE isAlphabetic so simple variable names
                // like "items" are captured whole, not scanned as Ident.
                if (self.last_token_type == .In) {
                    const iter_line = self.line;
                    const iter_col = self.column;
                    const iter_start = self.pos;
                    while (self.peekChar()) |c| {
                        if (c == '\n') break;
                        _ = self.advance();
                    }
                    const iter_value = self.source[iter_start..self.pos];
                    self.last_token_type = .Iterable;
                    return Token.init(.Iterable, iter_value, iter_line, iter_col);
                }

                // After "include" or "extends" — capture the path as Text.
                // Paths contain '/' which is not a valid symbol token.
                // Example: include partials/header → Text("partials/header")
                if (self.last_token_type == .Include or self.last_token_type == .Extends) {
                    const path_line = self.line;
                    const path_col = self.column;
                    const path_start = self.pos;
                    while (self.peekChar()) |c| {
                        if (c == '\n') break;
                        _ = self.advance();
                    }
                    const path_value = self.source[path_start..self.pos];
                    self.last_token_type = .Text;
                    return Token.init(.Text, path_value, path_line, path_col);
                }

                if (std.ascii.isAlphabetic(ch) or ch == '_' or utils.isUtf8Start(ch)) {
                    const token = try scanIdentifier(self);
                    self.last_token_type = token.type;
                    // Track if the first token of this line was a keyword
                    if (!self.line_started_with_keyword) {
                        self.line_started_with_keyword = utils.isKeywordType(token.type);
                    }
                    return token;
                }

                const token = try scanSymbol(self);
                self.last_token_type = token.type;
                return token;
            },

            .Text => {
                const token = try scanText(self);
                self.last_token_type = token.type;
                return token;
            },

        };
    }
};
