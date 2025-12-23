//! Tokenizer module - Lexical Analysis
//!
//! This module converts Pug template source code into a stream of tokens.
//! It's the first phase of the compilation pipeline, handling:
//! - Whitespace-significant indentation (like Python)
//! - Keywords and identifiers
//! - Literals (strings, numbers, booleans)
//! - Special syntax (.class, #id, #{interpolation})
//! - Comments (// buffered, //- unbuffered, //! documentation)
//! - Code markers (=, !=, -, |)
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
//! // Tokens: Ident("div"), Class("container"), Newline, Indent,
//! //         Ident("p"), Ident("Hello"), EscapedInterpol("name"), Eof
//! while (true) {
//!     const token = try tokenizer.next();
//!     if (token.type == .Eof) break;
//!     // Process token...
//! }
//! ```
//!
//! Key features:
//! - Indentation tracking with INDENT/DEDENT tokens (like Python)
//! - Shorthand syntax: .class and #id recognized as single tokens
//! - Interpolation: #{expr} and !{expr} parsed as single tokens
//! - Comments: // for HTML comments, //- for code comments, //! for documentation (ignored)
//! - Position tracking: Every token has line and column info

const std = @import("std");

// Public exports
pub const TokenizerState = @import("TokenizerState.zig").TokenizerState;
pub const TokenType = @import("TokenType.zig").TokenType;
pub const Token = @import("Token.zig").Token;
pub const TokenizerError = @import("TokenizerError.zig").TokenizerError;

// Import scan functions
const scanIdentifier = @import("scanIdentifier.zig").scanIdentifier;
const scanString = @import("scanString.zig").scanString;
const scanNumber = @import("scanNumber.zig").scanNumber;
const scanComment = @import("scanComment.zig").scanComment;
const skipDocComment = @import("scanComment.zig").skipDocComment;
const scanInterpolation = @import("scanInterpolation.zig").scanInterpolation;
const scanSymbol = @import("scanSymbol.zig").scanSymbol;
const scanText = @import("scanText.zig").scanText;
/// Tokenizer - Converts source code into a stream of tokens
///
/// State machine that scans Pug template source character by character,
/// recognizing lexical patterns and emitting tokens. Handles indentation-
/// based syntax similar to Python.
///
/// Fields:
/// - source: The complete source code being tokenized
/// - pos: Current position in source (byte offset)
/// - line: Current line number (1-indexed)
/// - column: Current column number (1-indexed)
/// - allocator: Memory allocator for dynamic data
/// - indent_stack: Stack tracking nested indentation levels
/// - pending_tokens: Queue for INDENT/DEDENT tokens
/// - at_line_start: Flag indicating if we're at the start of a line
///
/// Lifecycle:
/// 1. init() - Creates tokenizer with source code
/// 2. next() - Call repeatedly to get tokens
/// 3. deinit() - Free resources
///
/// Example:
/// ```zig
/// const source = "div.container\n  p Hello";
/// var tokenizer = try Tokenizer.init(allocator, source);
/// defer tokenizer.deinit();
///
/// const tok1 = try tokenizer.next(); // Ident("div")
/// const tok2 = try tokenizer.next(); // Class("container")
/// const tok3 = try tokenizer.next(); // Newline
/// const tok4 = try tokenizer.next(); // Indent
/// const tok5 = try tokenizer.next(); // Ident("p")
/// const tok6 = try tokenizer.next(); // Ident("Hello")
/// ```
pub fn isAlpha(ch: u8) bool {
    return (ch >= 'a' and ch <= 'z') or (ch >= 'A' and ch <= 'Z');
}

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

    /// Initialize a new tokenizer with source code
    ///
    /// Creates a tokenizer ready to scan the provided source.
    /// Initializes indentation tracking with base level 0.
    ///
    /// Parameters:
    /// - allocator: Memory allocator for token queues
    /// - source: Complete Pug template source code
    ///
    /// Returns: Initialized tokenizer
    ///
    /// Example:
    /// ```zig
    /// const source = "html\n  body\n    h1 Title";
    /// var tokenizer = try Tokenizer.init(allocator, source);
    /// defer tokenizer.deinit();
    /// ```
    pub fn init(allocator: std.mem.Allocator, source: []const u8) !Tokenizer {
        var tokenizer = Tokenizer{
            .source = source,
            .pos = 0,
            .line = 1,
            .column = 1,
            .allocator = allocator,
            .indent_stack = .{},
            .pending_tokens = .{},
            .at_line_start = true,
            .state = TokenizerState.Root,
        };
        try tokenizer.indent_stack.append(allocator, 0); // Base level
        return tokenizer;
    }

    /// Free tokenizer resources
    ///
    /// Cleans up indentation stack and pending token queue.
    ///
    /// Parameters:
    /// - self: The tokenizer to clean up
    ///
    /// Example:
    /// ```zig
    /// var tokenizer = try Tokenizer.init(allocator, source);
    /// defer tokenizer.deinit(); // Always clean up
    /// ```
    pub fn deinit(self: *Tokenizer) void {
        self.indent_stack.deinit(self.allocator);
        self.pending_tokens.deinit(self.allocator);
    }

    // ========================================================================
    // UTF-8 Support Functions
    // ========================================================================

    /// Check if a byte is the start of a UTF-8 multi-byte sequence
    ///
    /// UTF-8 encoding:
    /// - 0x00-0x7F: Single byte (ASCII)
    /// - 0x80-0xBF: Continuation byte
    /// - 0xC0-0xDF: Start of 2-byte sequence
    /// - 0xE0-0xEF: Start of 3-byte sequence
    /// - 0xF0-0xF7: Start of 4-byte sequence
    ///
    /// Returns: true if byte starts a UTF-8 sequence (>= 0xC0)
    fn isUtf8Start(byte: u8) bool {
        return byte >= 0xC0;
    }

    /// Get the length of a UTF-8 sequence from its first byte
    ///
    /// Returns: Number of bytes in the UTF-8 sequence (1-4)
    fn utf8SequenceLength(first_byte: u8) usize {
        if (first_byte < 0x80) return 1; // ASCII
        if (first_byte < 0xC0) return 1; // Invalid, treat as 1 byte
        if (first_byte < 0xE0) return 2; // 2-byte sequence
        if (first_byte < 0xF0) return 3; // 3-byte sequence
        return 4; // 4-byte sequence
    }

    /// Check if a byte is valid in identifiers or text (including UTF-8)
    ///
    /// Allows:
    /// - ASCII alphanumeric, underscore, hyphen
    /// - UTF-8 multi-byte sequences (for accented characters, etc.)
    ///
    /// Returns: true if byte can appear in identifiers/text
    fn isValidTextByte(byte: u8) bool {
        // ASCII alphanumeric, underscore, hyphen
        if (std.ascii.isAlphanumeric(byte) or byte == '_' or byte == '-') {
            return true;
        }
        // UTF-8 multi-byte start or continuation
        if (byte >= 0x80) {
            return true;
        }
        return false;
    }

    // ========================================================================
    // Character Navigation Functions
    // ========================================================================

    /// Peek at current character without advancing position
    ///
    /// Returns: Current character or null if at end of source
    pub fn peekChar(self: *Tokenizer) ?u8 {
        if (self.pos >= self.source.len) return null;
        return self.source[self.pos];
    }

    /// Peek ahead n characters without advancing position
    ///
    /// Used for lookahead to disambiguate tokens (e.g., // vs //-).
    ///
    /// Parameters:
    /// - offset: Number of characters to look ahead
    ///
    /// Returns: Character at pos+offset or null if past end
    pub fn peekAhead(self: *Tokenizer, offset: usize) ?u8 {
        const pos = self.pos + offset;
        if (pos >= self.source.len) return null;
        return self.source[pos];
    }

    /// Advance position and return current character
    ///
    /// Updates line and column counters. Newlines increment line
    /// and reset column to 1.
    ///
    /// Returns: Current character before advancing, or null if at end
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

    /// Skip horizontal whitespace (spaces, tabs) but not newlines
    ///
    /// Newlines are significant in Pug syntax, so they must be
    /// preserved as tokens. This skips only spaces and tabs.
    pub fn skipWhitespaceExceptNewline(self: *Tokenizer) void {
        while (self.peekChar()) |ch| {
            if (ch == ' ' or ch == '\t' or ch == '\r') {
                _ = self.advance();
            } else {
                break;
            }
        }
    }

    /// Handle indentation at the start of a line
    ///
    /// Tracks indentation levels and generates INDENT/DEDENT tokens
    /// similar to Python. Maintains an indentation stack to handle
    /// nested blocks correctly.
    ///
    /// Rules:
    /// - Only spaces allowed (tabs cause InvalidIndentation error)
    /// - Increased indent → emit INDENT token
    /// - Decreased indent → emit one or more DEDENT tokens
    /// - Empty lines are skipped
    ///
    /// Errors:
    /// - InvalidIndentation: Tabs used or inconsistent dedentation
    ///
    /// Example indentation handling:
    /// ```
    /// div           // base level 0
    ///   p           // indent 2 → INDENT
    ///     span      // indent 4 → INDENT
    ///   p           // back to 2 → DEDENT
    /// div           // back to 0 → DEDENT
    /// ```
    fn handleIndentation(self: *Tokenizer) !void {
        if (!self.at_line_start) return;

        var indent: usize = 0;
        while (self.peekChar()) |ch| {
            if (ch == ' ') {
                indent += 1;
                _ = self.advance();
            } else if (ch == '\t') {
                return error.InvalidIndentation; // No permitir tabs
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
            try self.pending_tokens.append(self.allocator, Token.init(.Indent, "", self.line, 1));
        } else if (indent < current_indent) {
            while (self.indent_stack.items.len > 0 and
                self.indent_stack.items[self.indent_stack.items.len - 1] > indent)
            {
                _ = self.indent_stack.pop();
                try self.pending_tokens.append(self.allocator, Token.init(.Dedent, "", self.line, 1));
            }

            if (self.indent_stack.items.len == 0 or
                self.indent_stack.items[self.indent_stack.items.len - 1] != indent)
            {
                return error.InvalidIndentation;
            }
        }

        self.at_line_start = false;
    }


    /// Get the next token from the source
    ///
    /// Uses labeled-switch pattern for efficient state machine transitions.
    /// This provides better branch prediction and cleaner state transitions.
    ///
    /// State transitions are handled directly in scan functions via continue :state.
    ///
    /// Returns: Next token (type, value, line, column)
    ///
    /// Example usage:
    /// ```zig
    /// var tokenizer = try Tokenizer.init(allocator, "div.class\n  p");
    /// defer tokenizer.deinit();
    ///
    /// while (true) {
    ///     const token = try tokenizer.next();
    ///     if (token.type == .Eof) break;
    ///     std.debug.print("{s} ", .{@tagName(token.type)});
    /// }
    /// // Output: Ident Class Newline Indent Ident Eof
    /// ```
    pub fn next(self: *Tokenizer) !Token {
        // Check for pending tokens first (INDENT/DEDENT)
        if (self.pending_tokens.items.len > 0) {
            return self.pending_tokens.orderedRemove(0);
        }

        // Handle indentation at line start
        try self.handleIndentation();

        // Check again for pending tokens after handling indentation
        if (self.pending_tokens.items.len > 0) {
            return self.pending_tokens.orderedRemove(0);
        }

        // Skip whitespace (except newlines which are significant)
        self.skipWhitespaceExceptNewline();

        const ch = self.peekChar() orelse {
            // Emit remaining DEDENT tokens at EOF
            if (self.indent_stack.items.len > 1) {
                _ = self.indent_stack.pop();
                return Token.init(.Dedent, "", self.line, self.column);
            }
            return Token.init(.Eof, "", self.line, self.column);
        };

        // Newline - resets to Root state
        if (ch == '\n') {
            self.at_line_start = true;
            self.state = .Root;
            const line = self.line;
            _ = self.advance();
            return Token.init(.Newline, "\n", line, 1);
        }

        // Comments //, //-, //! (don't depend on state)
        if (ch == '/' and self.peekAhead(1) == '/') {
            if (self.peekAhead(2) == '!') {
                skipDocComment(self);
                return self.next(); // Recursively get next token
            }
            return scanComment(self);
        }

        // Interpolation #{...} or !{...} (can appear in any context)
        if ((ch == '#' or ch == '!') and self.peekAhead(1) == '{') {
            return scanInterpolation(self);
        }

        // State-based tokenization using labeled-switch
        return switch (self.state) {
            .Root, .Indent => {
                // Special doctype handling at document start
                if (self.pos == 0 or (self.pos == 1 and self.source[0] == '\n')) {
                    if (std.mem.startsWith(u8, self.source[self.pos..], "doctype html")) {
                        self.pos += 12; // length of "doctype html"
                        self.column += 12;
                        return Token.init(.Doctype, "doctype html", self.line, 1);
                    }
                    if (std.mem.startsWith(u8, self.source[self.pos..], "doctype xml")) {
                        self.pos += 11; // length of "doctype xml"
                        self.column += 11;
                        return Token.init(.Doctype, "doctype xml", self.line, 1);
                    }
                }

                // Strings (can appear at root level in tests or expressions)
                if (ch == '"' or ch == '\'') {
                    return scanString(self, ch);
                }

                // Numbers (can appear at root level)
                if (std.ascii.isDigit(ch)) {
                    return scanNumber(self);
                }

                // At line start: expect tag name, keyword, or text
                if (std.ascii.isAlphabetic(ch) or ch == '_' or isUtf8Start(ch)) {
                    return scanIdentifier(self);
                }

                // Symbols at root level (.class, #id, operators, etc.)
                return scanSymbol(self);
            },

            .TagStart, .TagClass, .TagId => {
                // After tag name, can have: .class, #id, (attributes), or text

                if (ch == '.') return scanSymbol(self); // Handles .class
                if (ch == '#') return scanSymbol(self); // Handles #id
                if (ch == '(') return scanSymbol(self); // Transitions to AttrStart

                // After tag+class+id, remaining content is text
                if (ch == ' ') {
                    _ = self.advance();
                    self.state = .Text;
                    return self.next();
                }

                // Other characters in tag context
                if (std.ascii.isAlphabetic(ch) or ch == '_' or isUtf8Start(ch)) {
                    self.state = .Text;
                    return scanText(self);
                }

                return scanSymbol(self);
            },

            .AttrStart, .AttrName, .AttrEquals, .AttrValue, .AttrString, .AttrJS => {
                // Inside attribute parentheses

                if (ch == ')') return scanSymbol(self); // Back to TagStart
                if (ch == ',') {
                    const tok = try scanSymbol(self);
                    self.state = .AttrName; // Next attribute
                    return tok;
                }
                if (ch == '=') return scanSymbol(self); // AttrName → AttrEquals
                if (ch == '"' or ch == '\'') {
                    self.state = .AttrString;
                    return scanString(self, ch);
                }

                // Attribute names and values
                if (std.ascii.isAlphabetic(ch) or ch == '_' or ch == '-' or isUtf8Start(ch)) {
                    return scanIdentifier(self);
                }

                if (std.ascii.isDigit(ch)) return scanNumber(self);

                return scanSymbol(self);
            },

            .Text => {
                // In text mode, everything is text until newline
                return scanText(self);
            },

            .Code => {
                // In Code mode (after =, !=, -), parse JavaScript expressions
                // Similar to Root but . and # are always operators, never class/id

                // Strings
                if (ch == '"' or ch == '\'') {
                    return scanString(self, ch);
                }

                // Numbers
                if (std.ascii.isDigit(ch)) {
                    return scanNumber(self);
                }

                // Identifiers
                if (std.ascii.isAlphabetic(ch) or ch == '_' or isUtf8Start(ch)) {
                    return scanIdentifier(self);
                }

                // All other symbols (., [, ], (, ), etc.)
                return scanSymbol(self);
            },
        };
    }
};

/// Check if identifier is a keyword
///
/// Matches identifiers against known Pug keywords and special values.
///
/// Parameters:
/// - ident: Identifier string to check
///
/// Returns: TokenType if keyword, null if regular identifier
///
/// Keywords recognized:
/// - Control flow: if, else, unless, each, while, case, when, default
/// - Template: mixin, include, extends, block, append, prepend
/// - Special: doctype, true, false
///
/// Example:
/// ```zig
/// getKeyword("if")    → .If
/// getKeyword("each")  → .Each
/// getKeyword("true")  → .Boolean
/// getKeyword("div")   → null
/// ```
fn getKeyword(ident: []const u8) ?TokenType {
    const keywords = std.StaticStringMap(TokenType).initComptime(.{
        .{ "if", .If },
        .{ "else", .Else },
        .{ "unless", .Unless },
        .{ "each", .Each },
        .{ "while", .While },
        .{ "case", .Case },
        .{ "when", .When },
        .{ "default", .Default },
        .{ "mixin", .Mixin },
        .{ "include", .Include },
        .{ "extends", .Extends },
        .{ "block", .Block },
        .{ "append", .Append },
        .{ "prepend", .Prepend },
        .{ "doctype", .Doctype },
        .{ "true", .Boolean },
        .{ "false", .Boolean },
    });
    return keywords.get(ident);
}
