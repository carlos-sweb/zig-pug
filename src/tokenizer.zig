//! Tokenizer module - Lexical Analysis
//!
//! This module converts Pug template source code into a stream of tokens.
//! It's the first phase of the compilation pipeline, handling:
//! - Whitespace-significant indentation (like Python)
//! - Keywords and identifiers
//! - Literals (strings, numbers, booleans)
//! - Special syntax (.class, #id, #{interpolation})
//! - Comments (// buffered, //- unbuffered)
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
//! - Comments: // for HTML comments, //- for code comments
//! - Position tracking: Every token has line and column info

const std = @import("std");

/// Token types representing all possible lexical elements in Pug templates
///
/// Tokens are organized into categories:
/// - Identifiers: Tag names, variable names
/// - Literals: Strings, numbers, booleans
/// - Symbols: Parentheses, brackets, punctuation
/// - Keywords: Control flow (if, each, mixin, etc.)
/// - Special: Indentation, comments, code markers
///
/// Example token types for "div.container#main":
/// - Ident("div")
/// - Class("container")  // .container as single token
/// - Id("main")         // #main as single token
pub const TokenType = enum {
    // Identificadores
    Ident,
    Class, // .classname
    Id, // #idname

    // Literales
    String,
    Number,
    Boolean,

    // Símbolos
    LParen, // (
    RParen, // )
    LBracket, // [
    RBracket, // ]
    LBrace, // {
    RBrace, // }
    Dot, // .
    Hash, // #
    Comma, // ,
    Colon, // :
    Pipe, // |

    // Operadores
    Assign, // =
    NotEqual, // !=
    Plus, // +
    Minus, // -

    // Keywords
    If,
    Else,
    Unless,
    Each,
    While,
    Case,
    When,
    Default,
    Mixin,
    Include,
    Extends,
    Block,
    Append,
    Prepend,
    Doctype,

    // Especiales
    Indent,
    Dedent,
    Newline,
    BufferedComment, // //
    UnbufferedComment, // //-
    BufferedCode, // =
    UnbufferedCode, // -
    UnescapedCode, // !=
    EscapedInterpol, // #{...}
    UnescapedInterpol, // !{...}

    Eof,
};

/// A single token with its type, value, and source location
///
/// Represents a lexical unit extracted from the source code.
/// Contains all information needed for parsing and error reporting.
///
/// Fields:
/// - type: The kind of token (see TokenType)
/// - value: The actual text from the source (empty for symbols like INDENT)
/// - line: 1-indexed line number where token starts
/// - column: 1-indexed column number where token starts
///
/// Example:
/// ```zig
/// const token = Token.init(.Ident, "div", 5, 3);
/// // Represents identifier "div" at line 5, column 3
/// ```
pub const Token = struct {
    type: TokenType,
    value: []const u8,
    line: usize,
    column: usize,

    /// Create a new token
    ///
    /// Parameters:
    /// - token_type: Type of token
    /// - value: Text content (slice from source)
    /// - line: Source line number (1-indexed)
    /// - column: Source column number (1-indexed)
    ///
    /// Returns: Initialized token
    ///
    /// Example:
    /// ```zig
    /// const comment = Token.init(.BufferedComment, "TODO: fix this", 10, 1);
    /// ```
    pub fn init(token_type: TokenType, value: []const u8, line: usize, column: usize) Token {
        return .{
            .type = token_type,
            .value = value,
            .line = line,
            .column = column,
        };
    }
};

/// Errors that can occur during tokenization
///
/// These represent lexical errors in the source code:
/// - UnexpectedCharacter: Invalid character for current context
/// - UnterminatedString: String literal missing closing quote
/// - InvalidNumber: Malformed numeric literal
/// - OutOfMemory: Allocation failure
pub const TokenizerError = error{
    UnexpectedCharacter,
    UnterminatedString,
    InvalidNumber,
    OutOfMemory,
};

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
pub const Tokenizer = struct {
    source: []const u8,
    pos: usize,
    line: usize,
    column: usize,
    allocator: std.mem.Allocator,
    indent_stack: std.ArrayListUnmanaged(usize),
    pending_tokens: std.ArrayListUnmanaged(Token),
    at_line_start: bool,

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

    /// Peek at current character without advancing position
    ///
    /// Returns: Current character or null if at end of source
    fn peekChar(self: *Tokenizer) ?u8 {
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
    fn peekAhead(self: *Tokenizer, offset: usize) ?u8 {
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
    fn advance(self: *Tokenizer) ?u8 {
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
    fn skipWhitespaceExceptNewline(self: *Tokenizer) void {
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

    /// Scan a comment token (// or //-)
    ///
    /// Pug has two comment types:
    /// - // buffered comment → emitted to HTML
    /// - //- unbuffered comment → not in output
    ///
    /// Reads from // or //- to end of line.
    ///
    /// Returns: BufferedComment or UnbufferedComment token
    ///
    /// Example:
    /// ```
    /// // This appears in HTML
    /// //- This is a code comment
    /// ```
    fn scanComment(self: *Tokenizer) !Token {
        const start_line = self.line;
        const start_col = self.column;

        _ = self.advance(); // First /
        _ = self.advance(); // Second /

        const is_unbuffered = if (self.peekChar()) |ch| ch == '-' else false;
        if (is_unbuffered) {
            _ = self.advance(); // -
        }

        // Skip space after comment marker
        if (self.peekChar()) |ch| {
            if (ch == ' ') _ = self.advance();
        }

        const start = self.pos;
        while (self.peekChar()) |ch| {
            if (ch == '\n') break;
            _ = self.advance();
        }

        const value = self.source[start..self.pos];
        const token_type = if (is_unbuffered) TokenType.UnbufferedComment else TokenType.BufferedComment;

        return Token.init(token_type, value, start_line, start_col);
    }

    /// Scan an interpolation token #{...} or !{...}
    ///
    /// Interpolations embed JavaScript expressions in templates:
    /// - #{expr} → escaped (HTML-safe)
    /// - !{expr} → unescaped (raw HTML)
    ///
    /// Handles nested braces by counting brace depth.
    ///
    /// Returns: EscapedInterpol or UnescapedInterpol token
    ///
    /// Errors:
    /// - UnterminatedString: Missing closing }
    /// - UnexpectedCharacter: # or ! not followed by {
    ///
    /// Example:
    /// ```
    /// p Hello #{user.name}        // Escaped
    /// div !{raw_html}              // Unescaped
    /// p Count: #{items.length}     // Expression
    /// ```
    fn scanInterpolation(self: *Tokenizer) !Token {
        const start_line = self.line;
        const start_col = self.column;

        const first_ch = self.advance().?; // # or !
        const is_unescaped = first_ch == '!';

        if (self.peekChar() != '{') {
            return error.UnexpectedCharacter;
        }
        _ = self.advance(); // {

        const start = self.pos;
        var brace_count: usize = 1;

        while (self.peekChar()) |ch| {
            if (ch == '{') {
                brace_count += 1;
            } else if (ch == '}') {
                brace_count -= 1;
                if (brace_count == 0) {
                    const value = self.source[start..self.pos];
                    _ = self.advance(); // }
                    const token_type = if (is_unescaped) TokenType.UnescapedInterpol else TokenType.EscapedInterpol;
                    return Token.init(token_type, value, start_line, start_col);
                }
            }
            _ = self.advance();
        }

        return error.UnterminatedString;
    }

    /// Scan an identifier or keyword token
    ///
    /// Reads alphanumeric characters plus _ and - to form identifiers.
    /// Checks if identifier matches a keyword (if, each, mixin, etc.).
    ///
    /// Returns: Keyword token or Ident token
    ///
    /// Examples:
    /// ```
    /// div        → Ident("div")
    /// my-class   → Ident("my-class")
    /// if         → If (keyword)
    /// each       → Each (keyword)
    /// true       → Boolean (keyword)
    /// ```
    fn scanIdentifier(self: *Tokenizer) !Token {
        const start = self.pos;
        const start_line = self.line;
        const start_col = self.column;

        while (self.peekChar()) |ch| {
            if (std.ascii.isAlphanumeric(ch) or ch == '_' or ch == '-') {
                _ = self.advance();
            } else {
                break;
            }
        }

        const value = self.source[start..self.pos];

        // Check for keywords
        const token_type = getKeyword(value) orelse .Ident;
        return Token.init(token_type, value, start_line, start_col);
    }

    /// Scan a string literal token
    ///
    /// Reads quoted string (double or single quotes) with escape support.
    ///
    /// Parameters:
    /// - quote: Opening quote character (' or ")
    ///
    /// Returns: String token with content between quotes
    ///
    /// Errors:
    /// - UnterminatedString: Missing closing quote
    ///
    /// Examples:
    /// ```
    /// "hello"           → String("hello")
    /// 'world'           → String("world")
    /// "it's ok"         → String("it's ok")
    /// "line\nbreak"     → String("line\nbreak") (with escape)
    /// ```
    fn scanString(self: *Tokenizer, quote: u8) !Token {
        const start_line = self.line;
        const start_col = self.column;
        _ = self.advance(); // Skip opening quote

        const start = self.pos;
        while (self.peekChar()) |ch| {
            if (ch == quote) {
                const value = self.source[start..self.pos];
                _ = self.advance(); // Skip closing quote
                return Token.init(.String, value, start_line, start_col);
            }
            if (ch == '\\') {
                _ = self.advance(); // Skip escape
                _ = self.advance(); // Skip escaped char
            } else {
                _ = self.advance();
            }
        }

        return error.UnterminatedString;
    }

    /// Scan a number literal token
    ///
    /// Reads integer or decimal numbers.
    ///
    /// Returns: Number token
    ///
    /// Examples:
    /// ```
    /// 42      → Number("42")
    /// 3.14    → Number("3.14")
    /// 0.5     → Number("0.5")
    /// ```
    fn scanNumber(self: *Tokenizer) !Token {
        const start = self.pos;
        const start_line = self.line;
        const start_col = self.column;

        while (self.peekChar()) |ch| {
            if (std.ascii.isDigit(ch) or ch == '.') {
                _ = self.advance();
            } else {
                break;
            }
        }

        const value = self.source[start..self.pos];
        return Token.init(.Number, value, start_line, start_col);
    }

    /// Scan a symbol or special shorthand token
    ///
    /// Handles:
    /// - Shorthand syntax: .class and #id
    /// - Single-character symbols: ( ) [ ] { } , : | . #
    /// - Multi-character operators: !=
    /// - Code markers: = (buffered), - (unbuffered)
    ///
    /// Returns: Appropriate symbol or shorthand token
    ///
    /// Errors:
    /// - UnexpectedCharacter: Invalid symbol
    ///
    /// Examples:
    /// ```
    /// .container  → Class("container")
    /// #main       → Id("main")
    /// (           → LParen
    /// =           → BufferedCode
    /// !=          → UnescapedCode
    /// .           → Dot (when not followed by identifier)
    /// ```
    fn scanSymbol(self: *Tokenizer) !Token {
        const start_line = self.line;
        const start_col = self.column;
        const ch = self.peekChar().?;

        // Handle .class shorthand
        if (ch == '.') {
            _ = self.advance();
            if (self.peekChar()) |next_ch| {
                if (std.ascii.isAlphabetic(next_ch) or next_ch == '_' or next_ch == '-') {
                    const start = self.pos;
                    while (self.peekChar()) |c| {
                        if (std.ascii.isAlphanumeric(c) or c == '_' or c == '-') {
                            _ = self.advance();
                        } else {
                            break;
                        }
                    }
                    const value = self.source[start..self.pos];
                    return Token.init(.Class, value, start_line, start_col);
                }
            }
            const value = self.source[self.pos - 1 .. self.pos];
            return Token.init(.Dot, value, start_line, start_col);
        }

        // Handle #id shorthand
        if (ch == '#') {
            _ = self.advance();
            if (self.peekChar()) |next_ch| {
                if (std.ascii.isAlphabetic(next_ch) or next_ch == '_' or next_ch == '-') {
                    const start = self.pos;
                    while (self.peekChar()) |c| {
                        if (std.ascii.isAlphanumeric(c) or c == '_' or c == '-') {
                            _ = self.advance();
                        } else {
                            break;
                        }
                    }
                    const value = self.source[start..self.pos];
                    return Token.init(.Id, value, start_line, start_col);
                }
            }
            const value = self.source[self.pos - 1 .. self.pos];
            return Token.init(.Hash, value, start_line, start_col);
        }

        _ = self.advance();

        // Check for multi-character operators
        if (ch == '!' and self.peekChar() == '=') {
            _ = self.advance();
            const value = self.source[self.pos - 2 .. self.pos];
            return Token.init(.UnescapedCode, value, start_line, start_col);
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
            '=' => .BufferedCode,
            '+' => .Plus,
            '-' => .UnbufferedCode,
            '!' => .Ident, // Treat standalone ! as unexpected (will be handled as text)
            else => {
                // For any other character, treat as unexpected
                std.debug.print("Unexpected character at {d}:{d}: '{c}' (0x{x})\n", .{ start_line, start_col, ch, ch });
                return error.UnexpectedCharacter;
            },
        };

        const value = self.source[self.pos - 1 .. self.pos];
        return Token.init(token_type, value, start_line, start_col);
    }

    /// Get the next token from the source
    ///
    /// Main tokenization function called repeatedly to scan source code.
    /// Handles:
    /// 1. Pending INDENT/DEDENT tokens from indentation changes
    /// 2. Indentation tracking at line starts
    /// 3. Whitespace skipping
    /// 4. Token recognition by looking at current character
    ///
    /// Returns: Next token (type, value, line, column)
    ///
    /// Token recognition order:
    /// 1. Pending tokens (INDENT/DEDENT from previous line)
    /// 2. EOF with remaining DEDENTs
    /// 3. Newline
    /// 4. Comments (//, //-)
    /// 5. Interpolations (#{}, !{})
    /// 6. Strings (", ')
    /// 7. Numbers (0-9)
    /// 8. Identifiers/keywords (a-zA-Z_)
    /// 9. Symbols and shorthands
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
        // This ensures INDENT/DEDENT tokens are emitted BEFORE content
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

        // Newline
        if (ch == '\n') {
            self.at_line_start = true;
            const line = self.line;
            _ = self.advance();
            return Token.init(.Newline, "\n", line, 1);
        }

        // Comments //
        if (ch == '/' and self.peekAhead(1) == '/') {
            return self.scanComment();
        }

        // Interpolation #{...}
        if (ch == '#' and self.peekAhead(1) == '{') {
            return self.scanInterpolation();
        }

        // Interpolation !{...}
        if (ch == '!' and self.peekAhead(1) == '{') {
            return self.scanInterpolation();
        }

        // Strings
        if (ch == '"' or ch == '\'') {
            return self.scanString(ch);
        }

        // Numbers
        if (std.ascii.isDigit(ch)) {
            return self.scanNumber();
        }

        // Identifiers and keywords
        if (std.ascii.isAlphabetic(ch) or ch == '_') {
            return self.scanIdentifier();
        }

        // Symbols (including .class, #id, code markers)
        return self.scanSymbol();
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

// Tests
test "tokenizer - identifiers" {
    var tokenizer = try Tokenizer.init(std.testing.allocator, "div hello world123");
    defer tokenizer.deinit();

    const token1 = try tokenizer.next();
    try std.testing.expectEqual(TokenType.Ident, token1.type);
    try std.testing.expectEqualStrings("div", token1.value);

    const token2 = try tokenizer.next();
    try std.testing.expectEqual(TokenType.Ident, token2.type);
    try std.testing.expectEqualStrings("hello", token2.value);

    const token3 = try tokenizer.next();
    try std.testing.expectEqual(TokenType.Ident, token3.type);
    try std.testing.expectEqualStrings("world123", token3.value);
}

test "tokenizer - keywords" {
    var tokenizer = try Tokenizer.init(std.testing.allocator, "if else mixin");
    defer tokenizer.deinit();

    try std.testing.expectEqual(TokenType.If, (try tokenizer.next()).type);
    try std.testing.expectEqual(TokenType.Else, (try tokenizer.next()).type);
    try std.testing.expectEqual(TokenType.Mixin, (try tokenizer.next()).type);
}

test "tokenizer - strings" {
    var tokenizer = try Tokenizer.init(std.testing.allocator, "\"hello world\" 'test'");
    defer tokenizer.deinit();

    const token1 = try tokenizer.next();
    try std.testing.expectEqual(TokenType.String, token1.type);
    try std.testing.expectEqualStrings("hello world", token1.value);

    const token2 = try tokenizer.next();
    try std.testing.expectEqual(TokenType.String, token2.type);
    try std.testing.expectEqualStrings("test", token2.value);
}

test "tokenizer - numbers" {
    var tokenizer = try Tokenizer.init(std.testing.allocator, "123 45.67");
    defer tokenizer.deinit();

    const token1 = try tokenizer.next();
    try std.testing.expectEqual(TokenType.Number, token1.type);
    try std.testing.expectEqualStrings("123", token1.value);

    const token2 = try tokenizer.next();
    try std.testing.expectEqual(TokenType.Number, token2.type);
    try std.testing.expectEqualStrings("45.67", token2.value);
}

test "tokenizer - symbols" {
    var tokenizer = try Tokenizer.init(std.testing.allocator, "()[]{}");
    defer tokenizer.deinit();

    try std.testing.expectEqual(TokenType.LParen, (try tokenizer.next()).type);
    try std.testing.expectEqual(TokenType.RParen, (try tokenizer.next()).type);
    try std.testing.expectEqual(TokenType.LBracket, (try tokenizer.next()).type);
    try std.testing.expectEqual(TokenType.RBracket, (try tokenizer.next()).type);
    try std.testing.expectEqual(TokenType.LBrace, (try tokenizer.next()).type);
    try std.testing.expectEqual(TokenType.RBrace, (try tokenizer.next()).type);
}

test "tokenizer - code markers" {
    var tokenizer = try Tokenizer.init(std.testing.allocator, "= != -");
    defer tokenizer.deinit();

    try std.testing.expectEqual(TokenType.BufferedCode, (try tokenizer.next()).type);
    try std.testing.expectEqual(TokenType.UnescapedCode, (try tokenizer.next()).type);
    try std.testing.expectEqual(TokenType.UnbufferedCode, (try tokenizer.next()).type);
}

test "tokenizer - class and id" {
    var tokenizer = try Tokenizer.init(std.testing.allocator, ".container #main");
    defer tokenizer.deinit();

    const class_token = try tokenizer.next();
    try std.testing.expectEqual(TokenType.Class, class_token.type);
    try std.testing.expectEqualStrings("container", class_token.value);

    const id_token = try tokenizer.next();
    try std.testing.expectEqual(TokenType.Id, id_token.type);
    try std.testing.expectEqualStrings("main", id_token.value);
}

test "tokenizer - comments" {
    var tokenizer = try Tokenizer.init(std.testing.allocator, "// comment\n//- unbuffered");
    defer tokenizer.deinit();

    const comment1 = try tokenizer.next();
    try std.testing.expectEqual(TokenType.BufferedComment, comment1.type);
    try std.testing.expectEqualStrings("comment", comment1.value);

    _ = try tokenizer.next(); // newline

    const comment2 = try tokenizer.next();
    try std.testing.expectEqual(TokenType.UnbufferedComment, comment2.type);
    try std.testing.expectEqualStrings("unbuffered", comment2.value);
}

test "tokenizer - interpolation" {
    var tokenizer = try Tokenizer.init(std.testing.allocator, "p #{name} !{html}");
    defer tokenizer.deinit();

    _ = try tokenizer.next(); // p

    const escaped = try tokenizer.next();
    try std.testing.expectEqual(TokenType.EscapedInterpol, escaped.type);
    try std.testing.expectEqualStrings("name", escaped.value);

    const unescaped = try tokenizer.next();
    try std.testing.expectEqual(TokenType.UnescapedInterpol, unescaped.type);
    try std.testing.expectEqualStrings("html", unescaped.value);
}

test "tokenizer - indentation" {
    const source =
        \\div
        \\  p hello
        \\  p world
        \\span
    ;
    var tokenizer = try Tokenizer.init(std.testing.allocator, source);
    defer tokenizer.deinit();

    try std.testing.expectEqual(TokenType.Ident, (try tokenizer.next()).type); // div
    try std.testing.expectEqual(TokenType.Newline, (try tokenizer.next()).type); // \n
    try std.testing.expectEqual(TokenType.Indent, (try tokenizer.next()).type); // INDENT
    try std.testing.expectEqual(TokenType.Ident, (try tokenizer.next()).type); // p
    try std.testing.expectEqual(TokenType.Ident, (try tokenizer.next()).type); // hello
    try std.testing.expectEqual(TokenType.Newline, (try tokenizer.next()).type); // \n
    try std.testing.expectEqual(TokenType.Ident, (try tokenizer.next()).type); // p
    try std.testing.expectEqual(TokenType.Ident, (try tokenizer.next()).type); // world
    try std.testing.expectEqual(TokenType.Newline, (try tokenizer.next()).type); // \n
    try std.testing.expectEqual(TokenType.Dedent, (try tokenizer.next()).type); // DEDENT
    try std.testing.expectEqual(TokenType.Ident, (try tokenizer.next()).type); // span
}

test "tokenizer - eof" {
    var tokenizer = try Tokenizer.init(std.testing.allocator, "");
    defer tokenizer.deinit();

    const token = try tokenizer.next();
    try std.testing.expectEqual(TokenType.Eof, token.type);
}
