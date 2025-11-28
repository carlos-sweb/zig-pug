//! Parser module - Syntax Analysis
//!
//! This module converts a stream of tokens from the tokenizer into an
//! Abstract Syntax Tree (AST). It's the second phase of compilation.
//!
//! Flow:
//! 1. Parser.init() creates parser with source code
//! 2. parse() builds complete AST by calling parseStatement() repeatedly
//! 3. Each statement type has its own parse function
//! 4. Returns Document node with all parsed content
//!
//! Example:
//! ```zig
//! var parser = try Parser.init(allocator, "div.container\n  p Hello");
//! defer parser.deinit();
//!
//! const document = try parser.parse();
//! // document is root AST node containing the parsed tree
//! ```
//!
//! Parser responsibilities:
//! - Match tokens to grammar rules
//! - Build AST node hierarchy
//! - Handle indentation-based nesting
//! - Parse attributes, expressions, and code blocks
//! - Validate syntax structure
//!
//! Statement types parsed:
//! - Tags: div, p, span (parseTag)
//! - Comments: //, //- (parseComment)
//! - Code: =, !=, - (parseCode)
//! - Control flow: if, each, case (parseConditional, parseLoop, parseCase)
//! - Mixins: mixin, + (parseMixinDefinition, parseMixinCall)
//! - Templates: include, extends, block
//! - Doctype: doctype html
//!
//! The parser uses an arena allocator to simplify memory management for
//! the AST. All nodes are freed when parser.deinit() is called.

const std = @import("std");
const tokenizer = @import("tokenizer.zig");
const ast = @import("ast.zig");

/// Errors that can occur during parsing
///
/// - UnexpectedToken: Token doesn't match grammar expectations
/// - OutOfMemory: Allocation failed
/// - InvalidIndentation: Indentation is malformed
pub const ParserError = error{
    UnexpectedToken,
    OutOfMemory,
    InvalidIndentation,
};

/// Parser - Converts token stream into Abstract Syntax Tree
///
/// Recursive descent parser that processes tokens and builds an AST.
/// Uses lookahead of 1 token (self.current) for parsing decisions.
///
/// Fields:
/// - tokenizer: Token stream source
/// - current: Current token being processed (lookahead)
/// - allocator: Base memory allocator
/// - arena: Arena allocator for AST nodes (freed on deinit)
///
/// Parsing strategy:
/// - Recursive descent: Each grammar rule has its own function
/// - Indentation-aware: INDENT/DEDENT tokens control nesting
/// - Error recovery: Prints helpful messages and returns errors
///
/// Example:
/// ```zig
/// var parser = try Parser.init(allocator, source);
/// defer parser.deinit();
///
/// const doc = try parser.parse();
/// // doc contains complete AST tree
/// ```
pub const Parser = struct {
    tokenizer: tokenizer.Tokenizer,
    current: tokenizer.Token,
    allocator: std.mem.Allocator,
    arena: std.heap.ArenaAllocator,

    /// Initialize parser with source code
    ///
    /// Creates tokenizer, advances to first token, sets up arena.
    ///
    /// Parameters:
    /// - allocator: Base allocator for parser structures
    /// - source: Complete Pug template source code
    ///
    /// Returns: Initialized parser ready to parse
    ///
    /// Example:
    /// ```zig
    /// const source = "div\n  p Hello";
    /// var parser = try Parser.init(allocator, source);
    /// defer parser.deinit();
    /// ```
    pub fn init(allocator: std.mem.Allocator, source: []const u8) !Parser {
        var tok = try tokenizer.Tokenizer.init(allocator, source);
        const current = try tok.next();

        return .{
            .tokenizer = tok,
            .current = current,
            .allocator = allocator,
            .arena = std.heap.ArenaAllocator.init(allocator),
        };
    }

    /// Free parser and all AST nodes
    ///
    /// Destroys arena allocator (freeing all AST nodes at once)
    /// and cleans up tokenizer.
    ///
    /// Example:
    /// ```zig
    /// var parser = try Parser.init(allocator, source);
    /// defer parser.deinit(); // Clean up everything
    /// ```
    pub fn deinit(self: *Parser) void {
        self.arena.deinit();
        self.tokenizer.deinit();
    }

    // ========================================================================
    // Helper Functions
    // ========================================================================

    /// Advance to next token
    ///
    /// Moves self.current to next token from tokenizer.
    fn advance(self: *Parser) !void {
        self.current = try self.tokenizer.next();
    }

    /// Expect specific token type and consume it
    ///
    /// Parameters:
    /// - expected: Token type that must be current
    ///
    /// Returns: The consumed token
    ///
    /// Errors:
    /// - UnexpectedToken: Current token doesn't match expected
    ///
    /// Example:
    /// ```zig
    /// const lparen = try self.expect(.LParen);
    /// // Now current token is whatever came after (
    /// ```
    fn expect(self: *Parser, expected: tokenizer.TokenType) !tokenizer.Token {
        if (self.current.type == expected) {
            const result = self.current;
            try self.advance();
            return result;
        }
        std.debug.print("Expected {s}, got {s} at line {d}\n", .{
            @tagName(expected),
            @tagName(self.current.type),
            self.current.line
        });
        return error.UnexpectedToken;
    }

    /// Check if current token matches any of the given types
    ///
    /// Parameters:
    /// - types: Slice of token types to check against
    ///
    /// Returns: true if current token matches any type
    ///
    /// Example:
    /// ```zig
    /// if (self.match(&.{ .Class, .Id })) {
    ///     // Current token is either Class or Id
    /// }
    /// ```
    fn match(self: *Parser, types: []const tokenizer.TokenType) bool {
        for (types) |t| {
            if (self.current.type == t) return true;
        }
        return false;
    }

    /// Skip any newline tokens
    ///
    /// Advances past all consecutive Newline tokens.
    /// Used to ignore blank lines between statements.
    fn skipNewlines(self: *Parser) !void {
        while (self.current.type == .Newline) {
            try self.advance();
        }
    }

    // ========================================================================
    // Main Parse Function
    // ========================================================================

    /// Parse complete template into AST Document node
    ///
    /// Main entry point for parsing. Processes entire source code and
    /// returns root Document node containing all parsed statements.
    ///
    /// Parsing flow:
    /// 1. Skip leading newlines
    /// 2. Check for optional doctype declaration
    /// 3. Parse statements until EOF
    /// 4. Return Document node with all children
    ///
    /// Returns: Document AST node (root of tree)
    ///
    /// Example:
    /// ```zig
    /// var parser = try Parser.init(allocator, "div\n  p Hello");
    /// defer parser.deinit();
    ///
    /// const document = try parser.parse();
    /// // document.data.Document.children contains parsed nodes
    /// ```
    ///
    /// Template structure:
    /// ```
    /// doctype html        // Optional, must be first
    /// div.container       // Statements...
    ///   p Hello
    /// ```
    pub fn parse(self: *Parser) anyerror!*ast.AstNode {
        const arena_allocator = self.arena.allocator();

        var children = std.ArrayListUnmanaged(*ast.AstNode){};
        var doctype: ?[]const u8 = null;

        try self.skipNewlines();

        // Check for doctype at the beginning
        if (self.current.type == .Doctype) {
            try self.advance(); // consume 'doctype'

            // Collect the rest of the line as doctype value
            var doctype_value = std.ArrayList(u8){};
            while (!self.match(&.{ .Newline, .Eof })) {
                if (doctype_value.items.len > 0) {
                    try doctype_value.append(arena_allocator, ' ');
                }
                try doctype_value.appendSlice(arena_allocator, self.current.value);
                try self.advance();
            }
            doctype = try doctype_value.toOwnedSlice(arena_allocator);
            try self.skipNewlines();
        }

        while (self.current.type != .Eof) {
            const child = try self.parseStatement();
            try children.append(arena_allocator, child);
            try self.skipNewlines();
        }

        return try ast.AstNode.create(
            arena_allocator,
            .Document,
            1,
            1,
            .{ .Document = .{
                .children = children,
                .doctype = doctype,
            } },
        );
    }

    /// Parse a single statement
    ///
    /// Dispatches to appropriate parse function based on current token type.
    /// This is the main switch statement that routes parsing to specific
    /// functions for each statement type.
    ///
    /// Statement types:
    /// - Tag: div, p, span → parseTag()
    /// - Pipe text: | text → parsePipeText()
    /// - Comments: //, //- → parseComment()
    /// - Code: =, !=, - → parseCode()
    /// - Conditionals: if, unless → parseConditional()
    /// - Loops: each, while → parseLoop()
    /// - Case: case/when → parseCase()
    /// - Mixins: mixin, + → parseMixinDefinition/Call()
    /// - Templates: include, extends, block
    ///
    /// Returns: AST node for the statement
    ///
    /// Errors:
    /// - UnexpectedToken: Token doesn't start a valid statement
    /// - DoctypeMustBeFirst: doctype appears after other content
    fn parseStatement(self: *Parser) anyerror!*ast.AstNode {
        return switch (self.current.type) {
            .Ident => try self.parseTag(),
            .Pipe => try self.parsePipeText(),
            .BufferedComment, .UnbufferedComment => try self.parseComment(),
            .UnbufferedCode, .BufferedCode, .UnescapedCode => try self.parseCode(),
            .If, .Unless => try self.parseConditional(),
            .Each, .While => try self.parseLoop(),
            .Case => try self.parseCase(),
            .Mixin => try self.parseMixinDefinition(),
            .Plus => try self.parseMixinCall(),
            .Include => try self.parseInclude(),
            .Extends => try self.parseExtends(),
            .Block => try self.parseBlock(),
            .Doctype => {
                std.debug.print("Error: 'doctype' must be at the beginning of the document (line {d})\n", .{self.current.line});
                std.debug.print("Hint: Move 'doctype html' to line 1, before any comments or content\n", .{});
                return error.DoctypeMustBeFirst;
            },
            else => {
                std.debug.print("Unexpected token in statement: {s} at line {d}\n", .{
                    @tagName(self.current.type),
                    self.current.line
                });
                return error.UnexpectedToken;
            },
        };
    }

    // ========================================================================
    // Tag Parsing
    // ========================================================================

    /// Parse a tag element (div, p, span, etc.)
    ///
    /// Handles complete tag syntax including:
    /// - Tag name: div
    /// - Classes: .container.main
    /// - ID: #header
    /// - Attributes: (href="/" title="Home")
    /// - Inline code: = expression
    /// - Inline text: Hello world
    /// - Child elements (via indentation)
    ///
    /// Returns: Tag AST node
    ///
    /// Syntax examples:
    /// ```
    /// div                           // Simple tag
    /// div.container#main            // With class and ID
    /// a(href="/")                   // With attributes
    /// p= message                    // With buffered code
    /// p Hello world                 // With inline text
    /// div                           // With children
    ///   p Nested content
    /// ```
    fn parseTag(self: *Parser) anyerror!*ast.AstNode {
        const token = try self.expect(.Ident);
        const arena_allocator = self.arena.allocator();

        var attributes = std.ArrayListUnmanaged(ast.Attribute){};
        var children = std.ArrayListUnmanaged(*ast.AstNode){};

        // Collect classes to concatenate them into a single attribute
        var classes = std.ArrayListUnmanaged([]const u8){};

        // Parse classes and ids (.class, #id)
        while (self.match(&.{ .Class, .Id })) {
            if (self.current.type == .Class) {
                const class_token = self.current;
                try self.advance();
                try classes.append(arena_allocator, class_token.value);
            } else if (self.current.type == .Id) {
                const id_token = self.current;
                try self.advance();
                try attributes.append(arena_allocator, .{
                    .name = "id",
                    .value = id_token.value,
                    .is_unescaped = false,
                    .is_expression = false,
                });
            }
        }

        // Add combined class attribute if any classes were found
        if (classes.items.len > 0) {
            const combined_classes = try std.mem.join(arena_allocator, " ", classes.items);
            try attributes.append(arena_allocator, .{
                .name = "class",
                .value = combined_classes,
                .is_unescaped = false,
                .is_expression = false,
            });
        }

        // Parse attributes (...)
        if (self.match(&.{.LParen})) {
            try self.parseAttributes(&attributes);
        }

        // Check for buffered/unescaped code after tag (e.g., p= value)
        if (self.match(&.{ .BufferedCode, .UnescapedCode })) {
            const code_node = try self.parseCode();
            try children.append(arena_allocator, code_node);
        } else if (!self.match(&.{ .Newline, .Indent, .Eof })) {
            // Parse inline text (puede retornar múltiples nodos: Text e Interpolation)
            const inline_nodes = try self.parseInlineText();
            try children.appendSlice(arena_allocator, inline_nodes.items);
        }

        // Parse children with indentation
        try self.skipNewlines();
        if (self.match(&.{.Indent})) {
            try self.advance(); // consume INDENT
            try self.parseChildren(&children);
            if (self.match(&.{.Dedent})) {
                try self.advance(); // consume DEDENT
            }
        }

        return try ast.AstNode.create(
            arena_allocator,
            .Tag,
            token.line,
            token.column,
            .{ .Tag = .{
                .name = token.value,
                .attributes = attributes,
                .children = children,
                .is_self_closing = false,
            } },
        );
    }

    // ========================================================================
    // Attribute Parsing
    // ========================================================================

    /// Parse attribute list (key="value", class=myClass)
    ///
    /// Parses attributes within parentheses, handling:
    /// - Static attributes: href="/", title="Home"
    /// - Expression attributes: class=myClass, data=userData
    /// - Boolean attributes: disabled, checked
    ///
    /// Syntax: (name=value, name2=value2, ...)
    fn parseAttributes(self: *Parser, attributes: *std.ArrayListUnmanaged(ast.Attribute)) !void {
        const arena_allocator = self.arena.allocator();
        _ = try self.expect(.LParen);

        // Atributos pueden estar en múltiples líneas
        try self.skipNewlines();

        while (!self.match(&.{ .RParen, .Eof })) {
            try self.skipNewlines();

            // Check for spread attributes: &attributes
            if (self.match(&.{.Hash})) {
                // Skip for now - would need special handling
                try self.advance();
                if (self.match(&.{.Ident})) {
                    try self.advance();
                }
                continue;
            }

            // Parse attribute name
            if (!self.match(&.{.Ident})) {
                break;
            }
            const name_token = self.current;
            try self.advance();

            var value: ?[]const u8 = null;
            var is_unescaped = false;
            var is_expression = false;

            // Parse attribute value
            if (self.match(&.{.Assign})) {
                try self.advance();

                // Parse value - can be string, number, identifier, or expression
                if (self.match(&.{.String})) {
                    value = self.current.value;
                    try self.advance();
                } else if (self.match(&.{.Number})) {
                    value = self.current.value;
                    try self.advance();
                } else if (self.match(&.{.Boolean})) {
                    value = self.current.value;
                    try self.advance();
                } else if (self.match(&.{.Ident})) {
                    value = self.current.value;
                    is_expression = true; // Identifier = expression to evaluate
                    try self.advance();
                }
            } else if (self.match(&.{.BufferedCode})) {
                // Handle = for dynamic values
                try self.advance();
                is_unescaped = false;

                if (self.match(&.{.String})) {
                    value = self.current.value;
                    try self.advance();
                } else if (self.match(&.{.Ident})) {
                    value = self.current.value;
                    is_expression = true;
                    try self.advance();
                }
            } else if (self.match(&.{.UnescapedCode})) {
                // Handle != for unescaped dynamic values
                try self.advance();
                is_unescaped = true;

                if (self.match(&.{.String})) {
                    value = self.current.value;
                    try self.advance();
                } else if (self.match(&.{.Ident})) {
                    value = self.current.value;
                    is_expression = true;
                    try self.advance();
                }
            }
            // If no value, it's a boolean attribute (e.g., checked, disabled)

            try attributes.append(arena_allocator, .{
                .name = name_token.value,
                .value = value,
                .is_unescaped = is_unescaped,
                .is_expression = is_expression,
            });

            try self.skipNewlines();

            // Skip comma if present (optional)
            if (self.match(&.{.Comma})) {
                try self.advance();
                try self.skipNewlines();
            }
        }

        try self.skipNewlines();
        _ = try self.expect(.RParen);
    }

    // ========================================================================
    // Text Parsing
    // ========================================================================

    fn parseInlineText(self: *Parser) anyerror!std.ArrayListUnmanaged(*ast.AstNode) {
        const arena_allocator = self.arena.allocator();
        var nodes = std.ArrayListUnmanaged(*ast.AstNode){};
        var text_buffer: std.ArrayList(u8) = .{};
        const start_line = self.current.line;
        var last_token_end_col: usize = 0;
        var has_content = false; // Track if we've processed any content

        while (!self.match(&.{ .Newline, .Eof })) {
            if (self.match(&.{ .EscapedInterpol, .UnescapedInterpol })) {
                // Add space before interpolation if there was previous content
                if (has_content and text_buffer.items.len == 0) {
                    // Previous content was an interpolation, add space
                    try text_buffer.append(arena_allocator, ' ');
                }

                // Flush accumulated text as a Text node
                if (text_buffer.items.len > 0) {
                    // Add trailing space before interpolation
                    try text_buffer.append(arena_allocator, ' ');

                    // Modern Zig: use helper constructor
                    const text_node = try ast.AstNode.text(
                        arena_allocator,
                        start_line,
                        1,
                        try text_buffer.toOwnedSlice(arena_allocator),
                    );
                    try nodes.append(arena_allocator, text_node);
                    text_buffer = .{};
                }

                // Create Interpolation node
                const is_unescaped = self.current.type == .UnescapedInterpol;
                const expr_value = self.current.value;
                const expr_line = self.current.line;
                const expr_col = self.current.column;
                last_token_end_col = expr_col + expr_value.len + 3; // #{...} = 3 extra chars
                try self.advance();

                // Modern Zig: use helper constructor
                const interp_node = try ast.AstNode.interpolation(
                    arena_allocator,
                    expr_line,
                    expr_col,
                    expr_value,
                    is_unescaped,
                );
                try nodes.append(arena_allocator, interp_node);
                has_content = true; // Mark that we have content
            } else {
                // Add space before token if we've already processed content
                // This preserves spacing between words/interpolations
                if (has_content) {
                    try text_buffer.append(arena_allocator, ' ');
                }

                // Accumulate text
                try text_buffer.appendSlice(arena_allocator, self.current.value);
                last_token_end_col = self.current.column + self.current.value.len;
                has_content = true; // Mark that we have content
                try self.advance();
            }
        }

        // Flush remaining text
        if (text_buffer.items.len > 0) {
            const text_node = try ast.AstNode.create(
                arena_allocator,
                .Text,
                start_line,
                1,
                .{ .Text = .{
                    .content = try text_buffer.toOwnedSlice(arena_allocator),
                    .is_raw = false,
                } },
            );
            try nodes.append(arena_allocator, text_node);
        }

        return nodes;
    }

    /// Parse piped text (| literal text on its own line)
    ///
    /// Pipe syntax forces text to be on its own line, useful for
    /// multi-line text blocks or when text contains special characters.
    ///
    /// Syntax: | This is literal text
    ///
    /// Example:
    /// ```
    /// p
    ///   | First line of text
    ///   | Second line of text
    /// ```
    fn parsePipeText(self: *Parser) anyerror!*ast.AstNode {
        const arena_allocator = self.arena.allocator();
        _ = try self.expect(.Pipe);

        var nodes = std.ArrayListUnmanaged(*ast.AstNode){};
        var text_buffer: std.ArrayList(u8) = .{};
        const start_line = self.current.line;
        var last_token_end_col: usize = 0;
        var has_content = false; // Track if we've processed any content

        while (!self.match(&.{ .Newline, .Eof })) {
            if (self.match(&.{ .EscapedInterpol, .UnescapedInterpol })) {
                // Add space before interpolation if there was previous content
                if (has_content and text_buffer.items.len == 0) {
                    // Previous content was an interpolation, add space
                    try text_buffer.append(arena_allocator, ' ');
                }

                // Flush accumulated text as a Text node
                if (text_buffer.items.len > 0) {
                    // Add trailing space before interpolation
                    try text_buffer.append(arena_allocator, ' ');

                    const text_node = try ast.AstNode.create(
                        arena_allocator,
                        .Text,
                        start_line,
                        1,
                        .{ .Text = .{
                            .content = try text_buffer.toOwnedSlice(arena_allocator),
                            .is_raw = true,
                        } },
                    );
                    try nodes.append(arena_allocator, text_node);
                    text_buffer = .{};
                }

                // Create Interpolation node
                const is_unescaped = self.current.type == .UnescapedInterpol;
                const expr_value = self.current.value;
                const expr_line = self.current.line;
                const expr_col = self.current.column;
                last_token_end_col = expr_col + expr_value.len + 3; // #{...} = 3 extra chars
                try self.advance();

                // Modern Zig: use helper constructor
                const interp_node = try ast.AstNode.interpolation(
                    arena_allocator,
                    expr_line,
                    expr_col,
                    expr_value,
                    is_unescaped,
                );
                try nodes.append(arena_allocator, interp_node);
                has_content = true; // Mark that we have content
            } else {
                // Add space before token if we've already processed content
                // This preserves spacing between words/interpolations
                if (has_content) {
                    try text_buffer.append(arena_allocator, ' ');
                }

                // Accumulate text
                try text_buffer.appendSlice(arena_allocator, self.current.value);
                last_token_end_col = self.current.column + self.current.value.len;
                has_content = true; // Mark that we have content
                try self.advance();
            }
        }

        // Flush remaining text
        if (text_buffer.items.len > 0) {
            const text_node = try ast.AstNode.create(
                arena_allocator,
                .Text,
                start_line,
                1,
                .{ .Text = .{
                    .content = try text_buffer.toOwnedSlice(arena_allocator),
                    .is_raw = true,
                } },
            );
            try nodes.append(arena_allocator, text_node);
        }

        // If only one node, return it directly
        if (nodes.items.len == 1) {
            return nodes.items[0];
        }

        // Multiple nodes: wrap in a Tag container with empty name (acts as fragment)
        return try ast.AstNode.create(
            arena_allocator,
            .Tag,
            start_line,
            1,
            .{ .Tag = .{
                .name = "",
                .attributes = .{},
                .children = nodes,
                .is_self_closing = false,
            } },
        );
    }

    // ========================================================================
    // Children Parsing
    // ========================================================================

    /// Parse indented child elements
    ///
    /// Handles INDENT token, parses all children until DEDENT.
    /// Used by tags, conditionals, loops, etc. to parse nested content.
    fn parseChildren(self: *Parser, children: *std.ArrayListUnmanaged(*ast.AstNode)) anyerror!void {
        const arena_allocator = self.arena.allocator();

        while (!self.match(&.{ .Dedent, .Eof })) {
            try self.skipNewlines();

            if (self.match(&.{ .Dedent, .Eof })) {
                break;
            }

            const child = try self.parseStatement();
            try children.append(arena_allocator, child);
        }
    }

    // ========================================================================
    // Comment Parsing
    // ========================================================================

    /// Parse comment (// buffered or //- unbuffered)
    ///
    /// - Buffered (//): Emitted to HTML as <!-- comment -->
    /// - Unbuffered (//-): Not included in output (code comment)
    ///
    /// Example:
    /// ```
    /// // This appears in HTML
    /// //- This is for developers only
    /// ```
    fn parseComment(self: *Parser) anyerror!*ast.AstNode {
        const arena_allocator = self.arena.allocator();
        const is_buffered = self.current.type == .BufferedComment;
        const content = self.current.value;
        const line = self.current.line;

        try self.advance();

        return try ast.AstNode.create(
            arena_allocator,
            .Comment,
            line,
            1,
            .{ .Comment = .{
                .content = content,
                .is_buffered = is_buffered,
            } },
        );
    }

    // ========================================================================
    // Code Parsing
    // ========================================================================

    /// Parse code markers (=, !=, -)
    ///
    /// - Buffered (=): Evaluate and output escaped HTML
    /// - Unescaped (!=): Evaluate and output raw HTML
    /// - Unbuffered (-): Execute code without output
    ///
    /// Example:
    /// ```
    /// = user.name          // Escaped output
    /// != rawHtml           // Unescaped output
    /// - var x = 10         // Execute only
    /// ```
    fn parseCode(self: *Parser) anyerror!*ast.AstNode {
        const arena_allocator = self.arena.allocator();
        const token = self.current;
        try self.advance();

        const is_buffered = token.type == .BufferedCode or token.type == .UnescapedCode;
        const is_unescaped = token.type == .UnescapedCode;

        // Collect code until newline
        var code: std.ArrayList(u8) = .{};
        while (!self.match(&.{ .Newline, .Eof })) {
            if (code.items.len > 0) {
                try code.append(arena_allocator, ' ');
            }
            // Preserve string quotes
            if (self.current.type == .String) {
                try code.append(arena_allocator, '"');
                try code.appendSlice(arena_allocator, self.current.value);
                try code.append(arena_allocator, '"');
            } else {
                try code.appendSlice(arena_allocator, self.current.value);
            }
            try self.advance();
        }

        return try ast.AstNode.create(
            arena_allocator,
            .Code,
            token.line,
            token.column,
            .{ .Code = .{
                .code = try code.toOwnedSlice(arena_allocator),
                .is_buffered = is_buffered,
                .is_unescaped = is_unescaped,
            } },
        );
    }

    // ========================================================================
    // Conditional Parsing (if/else/unless)
    // ========================================================================

    /// Parse conditional (if/unless with optional else)
    ///
    /// Syntax:
    /// ```
    /// if condition
    ///   p True branch
    /// else
    ///   p False branch
    /// ```
    ///
    /// unless is inverse of if (executes when condition is false)
    fn parseConditional(self: *Parser) anyerror!*ast.AstNode {
        const arena_allocator = self.arena.allocator();
        const is_unless = self.current.type == .Unless;
        const start_line = self.current.line;
        try self.advance(); // consume 'if' or 'unless'

        // Parse condition expression (everything until newline)
        var condition: std.ArrayList(u8) = .{};
        while (!self.match(&.{ .Newline, .Eof })) {
            if (condition.items.len > 0) {
                try condition.append(arena_allocator, ' ');
            }
            try condition.appendSlice(arena_allocator, self.current.value);
            try self.advance();
        }

        // Parse 'then' block
        try self.skipNewlines();
        var consequence = std.ArrayListUnmanaged(*ast.AstNode){};
        if (self.match(&.{.Indent})) {
            try self.advance();
            try self.parseChildren(&consequence);
            if (self.match(&.{.Dedent})) {
                try self.advance();
            }
        }

        // Parse 'else' block (optional)
        try self.skipNewlines();
        var alternative: ?std.ArrayListUnmanaged(*ast.AstNode) = null;
        if (self.match(&.{.Else})) {
            try self.advance();

            // Check for 'else if'
            if (self.match(&.{.If})) {
                // Parse as a nested if statement
                const else_if_node = try self.parseConditional();
                var alt_list = std.ArrayListUnmanaged(*ast.AstNode){};
                try alt_list.append(arena_allocator, else_if_node);
                alternative = alt_list;
            } else {
                // Parse regular else block
                try self.skipNewlines();
                var alt_list = std.ArrayListUnmanaged(*ast.AstNode){};
                if (self.match(&.{.Indent})) {
                    try self.advance();
                    try self.parseChildren(&alt_list);
                    if (self.match(&.{.Dedent})) {
                        try self.advance();
                    }
                }
                alternative = alt_list;
            }
        }

        return try ast.AstNode.create(
            arena_allocator,
            .Conditional,
            start_line,
            1,
            .{ .Conditional = .{
                .condition = try condition.toOwnedSlice(arena_allocator),
                .then_branch = consequence,
                .else_branch = alternative,
                .is_unless = is_unless,
            } },
        );
    }

    // ========================================================================
    // Loop Parsing (each/while)
    // ========================================================================

    /// Parse loop (each or while)
    ///
    /// Each loop syntax:
    /// ```
    /// each item in items
    ///   li= item
    /// ```
    ///
    /// While loop syntax:
    /// ```
    /// while condition
    ///   p Loop content
    /// ```
    fn parseLoop(self: *Parser) anyerror!*ast.AstNode {
        const arena_allocator = self.arena.allocator();
        const is_while = self.current.type == .While;
        const start_line = self.current.line;
        try self.advance(); // consume 'each' or 'while'

        // Parse loop expression: "item in items" or "item, index in items"
        var iterator: []const u8 = "";
        var index_var: ?[]const u8 = null;
        var iterable: []const u8 = "";

        if (!is_while) {
            // Parse iterator variable name
            if (self.match(&.{.Ident})) {
                iterator = self.current.value;
                try self.advance();
            }

            // Check for optional index variable: ", index"
            if (self.current.type == .Ident and std.mem.eql(u8, self.current.value, ",")) {
                try self.advance(); // consume ','
                if (self.match(&.{.Ident})) {
                    index_var = self.current.value;
                    try self.advance();
                }
            }

            // Expect "in" keyword
            if (self.match(&.{.Ident}) and std.mem.eql(u8, self.current.value, "in")) {
                try self.advance(); // consume 'in'
            }

            // Parse iterable expression (rest of the line)
            var iterable_expr: std.ArrayList(u8) = .{};
            while (!self.match(&.{ .Newline, .Eof })) {
                if (iterable_expr.items.len > 0) {
                    try iterable_expr.append(arena_allocator, ' ');
                }
                try iterable_expr.appendSlice(arena_allocator, self.current.value);
                try self.advance();
            }
            iterable = try iterable_expr.toOwnedSlice(arena_allocator);
        } else {
            // While loop - just collect the condition
            var expression: std.ArrayList(u8) = .{};
            while (!self.match(&.{ .Newline, .Eof })) {
                if (expression.items.len > 0) {
                    try expression.append(arena_allocator, ' ');
                }
                try expression.appendSlice(arena_allocator, self.current.value);
                try self.advance();
            }
            iterable = try expression.toOwnedSlice(arena_allocator);
        }

        // Parse loop body
        try self.skipNewlines();
        var body = std.ArrayListUnmanaged(*ast.AstNode){};
        if (self.match(&.{.Indent})) {
            try self.advance();
            try self.parseChildren(&body);
            if (self.match(&.{.Dedent})) {
                try self.advance();
            }
        }

        return try ast.AstNode.create(
            arena_allocator,
            .Loop,
            start_line,
            1,
            .{ .Loop = .{
                .iterator = iterator,
                .index = index_var,
                .iterable = iterable,
                .body = body,
                .else_branch = null,
                .is_while = is_while,
            } },
        );
    }

    // ========================================================================
    // Case Statement Parsing
    // ========================================================================

    /// Parse case/when switch statement
    ///
    /// Syntax:
    /// ```
    /// case variable
    ///   when "value1"
    ///     p First case
    ///   when "value2"
    ///     p Second case
    ///   default
    ///     p Default case
    /// ```
    fn parseCase(self: *Parser) anyerror!*ast.AstNode {
        const arena_allocator = self.arena.allocator();
        const start_line = self.current.line;
        try self.advance(); // consume 'case'

        // Parse case expression
        var expression: std.ArrayList(u8) = .{};
        while (!self.match(&.{ .Newline, .Eof })) {
            if (expression.items.len > 0) {
                try expression.append(arena_allocator, ' ');
            }
            try expression.appendSlice(arena_allocator, self.current.value);
            try self.advance();
        }

        // Parse when blocks
        try self.skipNewlines();
        var cases = std.ArrayListUnmanaged(*ast.AstNode){}; // List of WhenNodes
        var default_block: ?std.ArrayListUnmanaged(*ast.AstNode) = null;

        if (self.match(&.{.Indent})) {
            try self.advance();

            while (!self.match(&.{ .Dedent, .Eof })) {
                try self.skipNewlines();
                if (self.match(&.{ .Dedent, .Eof })) {
                    break;
                }

                if (self.match(&.{.When})) {
                    const when_line = self.current.line;
                    try self.advance(); // consume 'when'

                    // Parse when values (comma separated)
                    var values = std.ArrayListUnmanaged([]const u8){};
                    var current_value: std.ArrayList(u8) = .{};

                    while (!self.match(&.{ .Newline, .Eof })) {
                        if (self.match(&.{.Comma})) {
                            try values.append(arena_allocator, try current_value.toOwnedSlice(arena_allocator));
                            current_value = .{};
                            try self.advance();
                        } else {
                            if (current_value.items.len > 0) {
                                try current_value.append(arena_allocator, ' ');
                            }
                            try current_value.appendSlice(arena_allocator, self.current.value);
                            try self.advance();
                        }
                    }
                    if (current_value.items.len > 0) {
                        try values.append(arena_allocator, try current_value.toOwnedSlice(arena_allocator));
                    }

                    // Parse when block
                    try self.skipNewlines();
                    var block = std.ArrayListUnmanaged(*ast.AstNode){};
                    if (self.match(&.{.Indent})) {
                        try self.advance();
                        try self.parseChildren(&block);
                        if (self.match(&.{.Dedent})) {
                            try self.advance();
                        }
                    }

                    // Create WhenNode
                    const when_node = try ast.AstNode.create(
                        arena_allocator,
                        .When,
                        when_line,
                        1,
                        .{ .When = .{
                            .values = values,
                            .body = block,
                        } },
                    );
                    try cases.append(arena_allocator, when_node);

                } else if (self.match(&.{.Default})) {
                    try self.advance(); // consume 'default'
                    try self.skipNewlines();

                    // Parse default block
                    var block = std.ArrayListUnmanaged(*ast.AstNode){};
                    if (self.match(&.{.Indent})) {
                        try self.advance();
                        try self.parseChildren(&block);
                        if (self.match(&.{.Dedent})) {
                            try self.advance();
                        }
                    }
                    default_block = block;
                } else {
                    break;
                }
            }

            if (self.match(&.{.Dedent})) {
                try self.advance();
            }
        }

        return try ast.AstNode.create(
            arena_allocator,
            .Case,
            start_line,
            1,
            .{ .Case = .{
                .expression = try expression.toOwnedSlice(arena_allocator),
                .cases = cases,
                .default = default_block,
            } },
        );
    }

    // ========================================================================
    // Mixin Definition Parsing
    // ========================================================================

    /// Parse mixin definition
    ///
    /// Defines reusable template blocks with optional parameters.
    ///
    /// Syntax:
    /// ```
    /// mixin card(title, content)
    ///   div.card
    ///     h3= title
    ///     p= content
    /// ```
    fn parseMixinDefinition(self: *Parser) anyerror!*ast.AstNode {
        const arena_allocator = self.arena.allocator();
        const start_line = self.current.line;
        try self.advance(); // consume 'mixin'

        // Parse mixin name
        const name_token = try self.expect(.Ident);
        const name = name_token.value;

        // Parse parameters (optional)
        var params = std.ArrayListUnmanaged([]const u8){};
        var rest_param: ?[]const u8 = null;

        if (self.match(&.{.LParen})) {
            try self.advance(); // consume '('

            while (!self.match(&.{ .RParen, .Eof })) {
                // Check for rest parameter ...name
                if (self.match(&.{.Dot})) {
                    try self.advance();
                    if (self.match(&.{.Dot})) {
                        try self.advance();
                        if (self.match(&.{.Dot})) {
                            try self.advance();
                            // Now we expect parameter name
                            if (self.match(&.{.Ident})) {
                                rest_param = self.current.value;
                                try self.advance();
                            }
                        }
                    }
                } else if (self.match(&.{.Ident})) {
                    try params.append(arena_allocator, self.current.value);
                    try self.advance();
                }

                // Skip comma if present
                if (self.match(&.{.Comma})) {
                    try self.advance();
                }
            }

            _ = try self.expect(.RParen);
        }

        // Parse mixin body
        try self.skipNewlines();
        var body = std.ArrayListUnmanaged(*ast.AstNode){};
        if (self.match(&.{.Indent})) {
            try self.advance();
            try self.parseChildren(&body);
            if (self.match(&.{.Dedent})) {
                try self.advance();
            }
        }

        return try ast.AstNode.create(
            arena_allocator,
            .MixinDef,
            start_line,
            1,
            .{ .MixinDef = .{
                .name = name,
                .params = params,
                .rest_param = rest_param,
                .body = body,
            } },
        );
    }

    // ========================================================================
    // Mixin Call Parsing
    // ========================================================================

    /// Parse mixin call (+mixinName)
    ///
    /// Invokes a previously defined mixin with arguments.
    ///
    /// Syntax: +card("Title", "Content")
    fn parseMixinCall(self: *Parser) anyerror!*ast.AstNode {
        const arena_allocator = self.arena.allocator();
        const start_line = self.current.line;
        try self.advance(); // consume '+'

        // Parse mixin name
        const name_token = try self.expect(.Ident);
        const name = name_token.value;

        // Parse arguments (optional)
        var args = std.ArrayListUnmanaged([]const u8){};
        const attributes = std.ArrayListUnmanaged(ast.Attribute){};

        if (self.match(&.{.LParen})) {
            // Could be arguments or attributes
            // For simplicity, treat as arguments for now
            try self.advance(); // consume '('

            while (!self.match(&.{ .RParen, .Eof })) {
                // Collect argument as string
                var arg: std.ArrayList(u8) = .{};

                while (!self.match(&.{ .Comma, .RParen, .Eof })) {
                    if (arg.items.len > 0) {
                        try arg.append(arena_allocator, ' ');
                    }
                    // For String tokens, wrap value in quotes to preserve as JS string literal
                    if (self.current.type == .String) {
                        try arg.append(arena_allocator, '"');
                        try arg.appendSlice(arena_allocator, self.current.value);
                        try arg.append(arena_allocator, '"');
                    } else {
                        try arg.appendSlice(arena_allocator, self.current.value);
                    }
                    try self.advance();
                }

                if (arg.items.len > 0) {
                    try args.append(arena_allocator, try arg.toOwnedSlice(arena_allocator));
                }

                // Skip comma if present
                if (self.match(&.{.Comma})) {
                    try self.advance();
                }
            }

            _ = try self.expect(.RParen);
        }

        // Parse optional block for mixin
        try self.skipNewlines();
        var body: ?std.ArrayListUnmanaged(*ast.AstNode) = null;
        if (self.match(&.{.Indent})) {
            try self.advance();
            var block_body = std.ArrayListUnmanaged(*ast.AstNode){};
            try self.parseChildren(&block_body);
            if (self.match(&.{.Dedent})) {
                try self.advance();
            }
            body = block_body;
        }

        return try ast.AstNode.create(
            arena_allocator,
            .MixinCall,
            start_line,
            1,
            .{ .MixinCall = .{
                .name = name,
                .args = args,
                .attributes = attributes,
                .body = body,
            } },
        );
    }

    // ========================================================================
    // Include Parsing
    // ========================================================================

    /// Parse include directive
    ///
    /// Includes another template file.
    ///
    /// Syntax: include header.pug
    fn parseInclude(self: *Parser) anyerror!*ast.AstNode {
        const arena_allocator = self.arena.allocator();
        const start_line = self.current.line;
        try self.advance(); // consume 'include'

        // Parse file path
        var path: std.ArrayList(u8) = .{};
        var filter: ?[]const u8 = null;

        // Check for filter (e.g., include:markdown file.md)
        if (self.match(&.{.Colon})) {
            try self.advance();
            if (self.match(&.{.Ident})) {
                filter = self.current.value;
                try self.advance();
            }
        }

        // Parse path (rest of the line)
        while (!self.match(&.{ .Newline, .Eof })) {
            if (path.items.len > 0) {
                try path.append(arena_allocator, ' ');
            }
            try path.appendSlice(arena_allocator, self.current.value);
            try self.advance();
        }

        return try ast.AstNode.create(
            arena_allocator,
            .Include,
            start_line,
            1,
            .{ .Include = .{
                .path = try path.toOwnedSlice(arena_allocator),
                .filter = filter,
            } },
        );
    }

    // ========================================================================
    // Extends Parsing
    // ========================================================================

    /// Parse extends directive
    ///
    /// Declares that this template extends a parent layout.
    ///
    /// Syntax: extends layout.pug
    fn parseExtends(self: *Parser) anyerror!*ast.AstNode {
        const arena_allocator = self.arena.allocator();
        const start_line = self.current.line;
        try self.advance(); // consume 'extends'

        // Parse parent template path
        var path: std.ArrayList(u8) = .{};
        while (!self.match(&.{ .Newline, .Eof })) {
            if (path.items.len > 0) {
                try path.append(arena_allocator, ' ');
            }
            try path.appendSlice(arena_allocator, self.current.value);
            try self.advance();
        }

        return try ast.AstNode.create(
            arena_allocator,
            .Extends,
            start_line,
            1,
            .{ .Extends = .{
                .path = try path.toOwnedSlice(arena_allocator),
            } },
        );
    }

    // ========================================================================
    // Block Parsing
    // ========================================================================

    /// Parse block directive
    ///
    /// Defines a content block that can be overridden in child templates.
    ///
    /// Syntax:
    /// ```
    /// block content
    ///   p Default content
    /// ```
    fn parseBlock(self: *Parser) anyerror!*ast.AstNode {
        const arena_allocator = self.arena.allocator();
        const start_line = self.current.line;
        try self.advance(); // consume 'block'

        // Determine block mode
        var mode = ast.BlockMode.Replace;
        if (self.match(&.{.Append})) {
            mode = ast.BlockMode.Append;
            try self.advance();
        } else if (self.match(&.{.Prepend})) {
            mode = ast.BlockMode.Prepend;
            try self.advance();
        }

        // Parse block name
        const name_token = try self.expect(.Ident);
        const name = name_token.value;

        // Parse block body
        try self.skipNewlines();
        var body = std.ArrayListUnmanaged(*ast.AstNode){};
        if (self.match(&.{.Indent})) {
            try self.advance();
            try self.parseChildren(&body);
            if (self.match(&.{.Dedent})) {
                try self.advance();
            }
        }

        return try ast.AstNode.create(
            arena_allocator,
            .Block,
            start_line,
            1,
            .{ .Block = .{
                .name = name,
                .mode = mode,
                .body = body,
            } },
        );
    }
};

// ============================================================================
// Tests
// ============================================================================

test "parser - simple tag" {
    var parser = try Parser.init(std.testing.allocator, "div");
    defer parser.deinit();

    const tree = try parser.parse();
    try std.testing.expectEqual(ast.NodeType.Document, tree.type);
    try std.testing.expectEqual(@as(usize, 1), tree.data.Document.children.items.len);

    const tag = tree.data.Document.children.items[0];
    try std.testing.expectEqual(ast.NodeType.Tag, tag.type);
    try std.testing.expectEqualStrings("div", tag.data.Tag.name);
}

test "parser - tag with class" {
    var parser = try Parser.init(std.testing.allocator, "div.container");
    defer parser.deinit();

    const tree = try parser.parse();
    const tag = tree.data.Document.children.items[0];

    try std.testing.expectEqualStrings("div", tag.data.Tag.name);
    try std.testing.expectEqual(@as(usize, 1), tag.data.Tag.attributes.items.len);
    try std.testing.expectEqualStrings("class", tag.data.Tag.attributes.items[0].name);
    try std.testing.expectEqualStrings("container", tag.data.Tag.attributes.items[0].value.?);
}

test "parser - tag with id" {
    var parser = try Parser.init(std.testing.allocator, "div#main");
    defer parser.deinit();

    const tree = try parser.parse();
    const tag = tree.data.Document.children.items[0];

    try std.testing.expectEqualStrings("div", tag.data.Tag.name);
    try std.testing.expectEqual(@as(usize, 1), tag.data.Tag.attributes.items.len);
    try std.testing.expectEqualStrings("id", tag.data.Tag.attributes.items[0].name);
    try std.testing.expectEqualStrings("main", tag.data.Tag.attributes.items[0].value.?);
}

test "parser - tag with attributes" {
    var parser = try Parser.init(std.testing.allocator, "a(href=\"google.com\")");
    defer parser.deinit();

    const tree = try parser.parse();
    const tag = tree.data.Document.children.items[0];

    try std.testing.expectEqualStrings("a", tag.data.Tag.name);
    try std.testing.expectEqual(@as(usize, 1), tag.data.Tag.attributes.items.len);
    try std.testing.expectEqualStrings("href", tag.data.Tag.attributes.items[0].name);
    try std.testing.expectEqualStrings("google.com", tag.data.Tag.attributes.items[0].value.?);
}

test "parser - tag with text" {
    var parser = try Parser.init(std.testing.allocator, "p Hello World");
    defer parser.deinit();

    const tree = try parser.parse();
    const tag = tree.data.Document.children.items[0];

    try std.testing.expectEqualStrings("p", tag.data.Tag.name);
    try std.testing.expectEqual(@as(usize, 1), tag.data.Tag.children.items.len);

    const text = tag.data.Tag.children.items[0];
    try std.testing.expectEqual(ast.NodeType.Text, text.type);
    try std.testing.expectEqualStrings("Hello World", text.data.Text.content);
}

test "parser - nested tags" {
    const source =
        \\div
        \\  p Hello
    ;
    var parser = try Parser.init(std.testing.allocator, source);
    defer parser.deinit();

    const tree = try parser.parse();
    const div = tree.data.Document.children.items[0];

    try std.testing.expectEqualStrings("div", div.data.Tag.name);
    try std.testing.expectEqual(@as(usize, 1), div.data.Tag.children.items.len);

    const p = div.data.Tag.children.items[0];
    try std.testing.expectEqual(ast.NodeType.Tag, p.type);
    try std.testing.expectEqualStrings("p", p.data.Tag.name);
}

test "parser - comment" {
    var parser = try Parser.init(std.testing.allocator, "// This is a comment");
    defer parser.deinit();

    const tree = try parser.parse();
    const comment = tree.data.Document.children.items[0];

    try std.testing.expectEqual(ast.NodeType.Comment, comment.type);
    try std.testing.expectEqualStrings("This is a comment", comment.data.Comment.content);
    try std.testing.expect(comment.data.Comment.is_buffered);
}

test "parser - conditional (if)" {
    const source =
        \\if user
        \\  p Welcome!
    ;
    var parser = try Parser.init(std.testing.allocator, source);
    defer parser.deinit();

    const tree = try parser.parse();
    const conditional = tree.data.Document.children.items[0];

    try std.testing.expectEqual(ast.NodeType.Conditional, conditional.type);
    try std.testing.expectEqualStrings("user", conditional.data.Conditional.condition);
    try std.testing.expect(!conditional.data.Conditional.is_unless);
    try std.testing.expectEqual(@as(usize, 1), conditional.data.Conditional.then_branch.items.len);
}

test "parser - conditional (unless)" {
    const source =
        \\unless loggedIn
        \\  p Please login
    ;
    var parser = try Parser.init(std.testing.allocator, source);
    defer parser.deinit();

    const tree = try parser.parse();
    const conditional = tree.data.Document.children.items[0];

    try std.testing.expectEqual(ast.NodeType.Conditional, conditional.type);
    try std.testing.expectEqualStrings("loggedIn", conditional.data.Conditional.condition);
    try std.testing.expect(conditional.data.Conditional.is_unless);
}

test "parser - conditional with else" {
    const source =
        \\if user
        \\  p Welcome!
        \\else
        \\  p Please login
    ;
    var parser = try Parser.init(std.testing.allocator, source);
    defer parser.deinit();

    const tree = try parser.parse();
    const conditional = tree.data.Document.children.items[0];

    try std.testing.expectEqual(ast.NodeType.Conditional, conditional.type);
    try std.testing.expect(conditional.data.Conditional.else_branch != null);
    try std.testing.expectEqual(@as(usize, 1), conditional.data.Conditional.else_branch.?.items.len);
}

test "parser - loop (each)" {
    const source =
        \\each item in items
        \\  p= item
    ;
    var parser = try Parser.init(std.testing.allocator, source);
    defer parser.deinit();

    const tree = try parser.parse();
    const loop = tree.data.Document.children.items[0];

    try std.testing.expectEqual(ast.NodeType.Loop, loop.type);
    try std.testing.expect(!loop.data.Loop.is_while);
    try std.testing.expectEqual(@as(usize, 1), loop.data.Loop.body.items.len);
}

test "parser - loop (while)" {
    const source =
        \\while n < 5
        \\  p= n
    ;
    var parser = try Parser.init(std.testing.allocator, source);
    defer parser.deinit();

    const tree = try parser.parse();
    const loop = tree.data.Document.children.items[0];

    try std.testing.expectEqual(ast.NodeType.Loop, loop.type);
    try std.testing.expect(loop.data.Loop.is_while);
}

test "parser - case statement" {
    const source =
        \\case fruit
        \\  when "apple"
        \\    p It's an apple
        \\  when "orange", "lemon"
        \\    p It's citrus
        \\  default
        \\    p Unknown fruit
    ;
    var parser = try Parser.init(std.testing.allocator, source);
    defer parser.deinit();

    const tree = try parser.parse();
    const case_node = tree.data.Document.children.items[0];

    try std.testing.expectEqual(ast.NodeType.Case, case_node.type);
    try std.testing.expectEqualStrings("fruit", case_node.data.Case.expression);
    try std.testing.expectEqual(@as(usize, 2), case_node.data.Case.cases.items.len);
    try std.testing.expect(case_node.data.Case.default != null);

    // Check first when node
    const when1 = case_node.data.Case.cases.items[0];
    try std.testing.expectEqual(ast.NodeType.When, when1.type);
    try std.testing.expectEqual(@as(usize, 1), when1.data.When.values.items.len);

    // Check second when node
    const when2 = case_node.data.Case.cases.items[1];
    try std.testing.expectEqual(ast.NodeType.When, when2.type);
    try std.testing.expectEqual(@as(usize, 2), when2.data.When.values.items.len);
}

test "parser - attributes with values" {
    const source = "a(href=\"/home\" title=\"Home Page\")";
    var parser = try Parser.init(std.testing.allocator, source);
    defer parser.deinit();

    const tree = try parser.parse();
    const tag = tree.data.Document.children.items[0];

    try std.testing.expectEqual(ast.NodeType.Tag, tag.type);
    try std.testing.expectEqualStrings("a", tag.data.Tag.name);
    try std.testing.expectEqual(@as(usize, 2), tag.data.Tag.attributes.items.len);

    const attr1 = tag.data.Tag.attributes.items[0];
    try std.testing.expectEqualStrings("href", attr1.name);
    try std.testing.expectEqualStrings("/home", attr1.value.?);

    const attr2 = tag.data.Tag.attributes.items[1];
    try std.testing.expectEqualStrings("title", attr2.name);
    try std.testing.expectEqualStrings("Home Page", attr2.value.?);
}

test "parser - boolean attributes" {
    const source = "input(type=\"checkbox\" checked disabled)";
    var parser = try Parser.init(std.testing.allocator, source);
    defer parser.deinit();

    const tree = try parser.parse();
    const tag = tree.data.Document.children.items[0];

    try std.testing.expectEqual(@as(usize, 3), tag.data.Tag.attributes.items.len);

    const attr1 = tag.data.Tag.attributes.items[0];
    try std.testing.expectEqualStrings("type", attr1.name);
    try std.testing.expectEqualStrings("checkbox", attr1.value.?);

    const attr2 = tag.data.Tag.attributes.items[1];
    try std.testing.expectEqualStrings("checked", attr2.name);
    try std.testing.expect(attr2.value == null); // Boolean attribute

    const attr3 = tag.data.Tag.attributes.items[2];
    try std.testing.expectEqualStrings("disabled", attr3.name);
    try std.testing.expect(attr3.value == null); // Boolean attribute
}

test "parser - multiline attributes" {
    const source =
        \\a(
        \\  href="/home"
        \\  title="Home"
        \\)
    ;
    var parser = try Parser.init(std.testing.allocator, source);
    defer parser.deinit();

    const tree = try parser.parse();
    const tag = tree.data.Document.children.items[0];

    try std.testing.expectEqual(ast.NodeType.Tag, tag.type);
    try std.testing.expectEqual(@as(usize, 2), tag.data.Tag.attributes.items.len);

    const attr1 = tag.data.Tag.attributes.items[0];
    try std.testing.expectEqualStrings("href", attr1.name);

    const attr2 = tag.data.Tag.attributes.items[1];
    try std.testing.expectEqualStrings("title", attr2.name);
}

test "parser - attributes with commas" {
    const source = "div(class=\"foo\", id=\"bar\", data-value=\"baz\")";
    var parser = try Parser.init(std.testing.allocator, source);
    defer parser.deinit();

    const tree = try parser.parse();
    const tag = tree.data.Document.children.items[0];

    try std.testing.expectEqual(@as(usize, 3), tag.data.Tag.attributes.items.len);

    try std.testing.expectEqualStrings("class", tag.data.Tag.attributes.items[0].name);
    try std.testing.expectEqualStrings("id", tag.data.Tag.attributes.items[1].name);
    try std.testing.expectEqualStrings("data-value", tag.data.Tag.attributes.items[2].name);
}

test "parser - mixin definition" {
    const source =
        \\mixin greeting(name)
        \\  p Hello #{name}
    ;
    var parser = try Parser.init(std.testing.allocator, source);
    defer parser.deinit();

    const tree = try parser.parse();
    const mixin_def = tree.data.Document.children.items[0];

    try std.testing.expectEqual(ast.NodeType.MixinDef, mixin_def.type);
    try std.testing.expectEqualStrings("greeting", mixin_def.data.MixinDef.name);
    try std.testing.expectEqual(@as(usize, 1), mixin_def.data.MixinDef.params.items.len);
    try std.testing.expectEqualStrings("name", mixin_def.data.MixinDef.params.items[0]);
    try std.testing.expectEqual(@as(usize, 1), mixin_def.data.MixinDef.body.items.len);
}

test "parser - mixin definition with rest param" {
    const source =
        \\mixin list(...items)
        \\  ul
    ;
    var parser = try Parser.init(std.testing.allocator, source);
    defer parser.deinit();

    const tree = try parser.parse();
    const mixin_def = tree.data.Document.children.items[0];

    try std.testing.expectEqual(ast.NodeType.MixinDef, mixin_def.type);
    try std.testing.expectEqualStrings("list", mixin_def.data.MixinDef.name);
    try std.testing.expect(mixin_def.data.MixinDef.rest_param != null);
    try std.testing.expectEqualStrings("items", mixin_def.data.MixinDef.rest_param.?);
}

test "parser - mixin call" {
    const source =
        \\+greeting(John)
    ;
    var parser = try Parser.init(std.testing.allocator, source);
    defer parser.deinit();

    const tree = try parser.parse();
    const mixin_call = tree.data.Document.children.items[0];

    try std.testing.expectEqual(ast.NodeType.MixinCall, mixin_call.type);
    try std.testing.expectEqualStrings("greeting", mixin_call.data.MixinCall.name);
    try std.testing.expectEqual(@as(usize, 1), mixin_call.data.MixinCall.args.items.len);
}

test "parser - mixin call with block" {
    const source =
        \\+card
        \\  p Content
    ;
    var parser = try Parser.init(std.testing.allocator, source);
    defer parser.deinit();

    const tree = try parser.parse();
    const mixin_call = tree.data.Document.children.items[0];

    try std.testing.expectEqual(ast.NodeType.MixinCall, mixin_call.type);
    try std.testing.expect(mixin_call.data.MixinCall.body != null);
    try std.testing.expectEqual(@as(usize, 1), mixin_call.data.MixinCall.body.?.items.len);
}

test "parser - include" {
    const source = "include header.pug";
    var parser = try Parser.init(std.testing.allocator, source);
    defer parser.deinit();

    const tree = try parser.parse();
    const include = tree.data.Document.children.items[0];

    try std.testing.expectEqual(ast.NodeType.Include, include.type);
    try std.testing.expectEqualStrings("header.pug", include.data.Include.path);
    try std.testing.expect(include.data.Include.filter == null);
}

test "parser - include with filter" {
    const source = "include:markdown content.md";
    var parser = try Parser.init(std.testing.allocator, source);
    defer parser.deinit();

    const tree = try parser.parse();
    const include = tree.data.Document.children.items[0];

    try std.testing.expectEqual(ast.NodeType.Include, include.type);
    try std.testing.expectEqualStrings("content.md", include.data.Include.path);
    try std.testing.expect(include.data.Include.filter != null);
    try std.testing.expectEqualStrings("markdown", include.data.Include.filter.?);
}

test "parser - extends" {
    const source = "extends layout.pug";
    var parser = try Parser.init(std.testing.allocator, source);
    defer parser.deinit();

    const tree = try parser.parse();
    const extends = tree.data.Document.children.items[0];

    try std.testing.expectEqual(ast.NodeType.Extends, extends.type);
    try std.testing.expectEqualStrings("layout.pug", extends.data.Extends.path);
}

test "parser - block" {
    const source =
        \\block content
        \\  p Default content
    ;
    var parser = try Parser.init(std.testing.allocator, source);
    defer parser.deinit();

    const tree = try parser.parse();
    const block = tree.data.Document.children.items[0];

    try std.testing.expectEqual(ast.NodeType.Block, block.type);
    try std.testing.expectEqualStrings("content", block.data.Block.name);
    try std.testing.expectEqual(ast.BlockMode.Replace, block.data.Block.mode);
    try std.testing.expectEqual(@as(usize, 1), block.data.Block.body.items.len);
}

test "parser - block append" {
    const source =
        \\block append scripts
        \\  script(src="app.js")
    ;
    var parser = try Parser.init(std.testing.allocator, source);
    defer parser.deinit();

    const tree = try parser.parse();
    const block = tree.data.Document.children.items[0];

    try std.testing.expectEqual(ast.NodeType.Block, block.type);
    try std.testing.expectEqualStrings("scripts", block.data.Block.name);
    try std.testing.expectEqual(ast.BlockMode.Append, block.data.Block.mode);
}

test "parser - block prepend" {
    const source =
        \\block prepend head
        \\  meta(charset="utf-8")
    ;
    var parser = try Parser.init(std.testing.allocator, source);
    defer parser.deinit();

    const tree = try parser.parse();
    const block = tree.data.Document.children.items[0];

    try std.testing.expectEqual(ast.NodeType.Block, block.type);
    try std.testing.expectEqualStrings("head", block.data.Block.name);
    try std.testing.expectEqual(ast.BlockMode.Prepend, block.data.Block.mode);
}

test "parser - interpolation as separate node" {
    const source = "p Hello #{name}";
    var parser = try Parser.init(std.testing.allocator, source);
    defer parser.deinit();

    const tree = try parser.parse();
    const tag = tree.data.Document.children.items[0];

    try std.testing.expectEqual(ast.NodeType.Tag, tag.type);
    try std.testing.expectEqualStrings("p", tag.data.Tag.name);
    try std.testing.expectEqual(@as(usize, 2), tag.data.Tag.children.items.len);

    // First child should be Text
    const text_node = tag.data.Tag.children.items[0];
    try std.testing.expectEqual(ast.NodeType.Text, text_node.type);
    try std.testing.expectEqualStrings("Hello", text_node.data.Text.content);

    // Second child should be Interpolation
    const interp_node = tag.data.Tag.children.items[1];
    try std.testing.expectEqual(ast.NodeType.Interpolation, interp_node.type);
    try std.testing.expectEqualStrings("name", interp_node.data.Interpolation.expression);
    try std.testing.expectEqual(false, interp_node.data.Interpolation.is_unescaped);
}

test "parser - multiple interpolations" {
    const source = "p #{greeting} #{name}!";
    var parser = try Parser.init(std.testing.allocator, source);
    defer parser.deinit();

    const tree = try parser.parse();
    const tag = tree.data.Document.children.items[0];

    try std.testing.expectEqual(@as(usize, 3), tag.data.Tag.children.items.len);

    // First: Interpolation
    try std.testing.expectEqual(ast.NodeType.Interpolation, tag.data.Tag.children.items[0].type);
    try std.testing.expectEqualStrings("greeting", tag.data.Tag.children.items[0].data.Interpolation.expression);

    // Second: Interpolation
    try std.testing.expectEqual(ast.NodeType.Interpolation, tag.data.Tag.children.items[1].type);
    try std.testing.expectEqualStrings("name", tag.data.Tag.children.items[1].data.Interpolation.expression);

    // Third: Text
    try std.testing.expectEqual(ast.NodeType.Text, tag.data.Tag.children.items[2].type);
    try std.testing.expectEqualStrings("!", tag.data.Tag.children.items[2].data.Text.content);
}

test "parser - unescaped interpolation" {
    const source = "div !{htmlContent}";
    var parser = try Parser.init(std.testing.allocator, source);
    defer parser.deinit();

    const tree = try parser.parse();
    const tag = tree.data.Document.children.items[0];

    try std.testing.expectEqual(@as(usize, 1), tag.data.Tag.children.items.len);

    const interp_node = tag.data.Tag.children.items[0];
    try std.testing.expectEqual(ast.NodeType.Interpolation, interp_node.type);
    try std.testing.expectEqualStrings("htmlContent", interp_node.data.Interpolation.expression);
    try std.testing.expectEqual(true, interp_node.data.Interpolation.is_unescaped);
}

test "parser - interpolation with JavaScript expression" {
    const source = "p #{name.toLowerCase()}";
    var parser = try Parser.init(std.testing.allocator, source);
    defer parser.deinit();

    const tree = try parser.parse();
    const tag = tree.data.Document.children.items[0];

    try std.testing.expectEqual(@as(usize, 1), tag.data.Tag.children.items.len);

    const interp_node = tag.data.Tag.children.items[0];
    try std.testing.expectEqual(ast.NodeType.Interpolation, interp_node.type);
    try std.testing.expectEqualStrings("name.toLowerCase()", interp_node.data.Interpolation.expression);
}

test "parser - pipe text with interpolation" {
    const source =
        \\div
        \\  | Hello #{name}!
    ;
    var parser = try Parser.init(std.testing.allocator, source);
    defer parser.deinit();

    const tree = try parser.parse();
    const div_tag = tree.data.Document.children.items[0];

    try std.testing.expectEqual(@as(usize, 1), div_tag.data.Tag.children.items.len);

    const pipe_container = div_tag.data.Tag.children.items[0];
    // When there are multiple nodes, parsePipeText wraps them in a Tag container
    try std.testing.expectEqual(ast.NodeType.Tag, pipe_container.type);
    try std.testing.expectEqual(@as(usize, 3), pipe_container.data.Tag.children.items.len);

    // First: Text "Hello"
    try std.testing.expectEqual(ast.NodeType.Text, pipe_container.data.Tag.children.items[0].type);
    try std.testing.expectEqualStrings("Hello", pipe_container.data.Tag.children.items[0].data.Text.content);

    // Second: Interpolation "name"
    try std.testing.expectEqual(ast.NodeType.Interpolation, pipe_container.data.Tag.children.items[1].type);
    try std.testing.expectEqualStrings("name", pipe_container.data.Tag.children.items[1].data.Interpolation.expression);

    // Third: Text "!" (note: has trailing space due to token processing)
    try std.testing.expectEqual(ast.NodeType.Text, pipe_container.data.Tag.children.items[2].type);
    try std.testing.expectEqualStrings("! ", pipe_container.data.Tag.children.items[2].data.Text.content);
}
