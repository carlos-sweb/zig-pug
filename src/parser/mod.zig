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
const tokenizer = @import("../tokenizer/mod.zig");
const ast = @import("../ast/mod.zig");

// Import sub-modules
const helpers = @import("helpers.zig");
const tag_parser = @import("tag.zig");
const text_parser = @import("text.zig");
const code_parser = @import("code.zig");
const conditionals_parser = @import("conditionals.zig");
const loops_parser = @import("loops.zig");
const case_parser = @import("case.zig");
const mixins_parser = @import("mixins.zig");
const templates_parser = @import("templates.zig");

// Re-export for external use
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

        try helpers.skipNewlines(self);

        // Check for doctype at the beginning
        if (self.current.type == .Doctype) {
            try helpers.advance(self); // consume 'doctype'

            // Collect the rest of the line as doctype value
            var doctype_value = std.ArrayList(u8){};
            while (!helpers.match(self, &.{ .Newline, .Eof })) {
                if (doctype_value.items.len > 0) {
                    try doctype_value.append(arena_allocator, ' ');
                }
                try doctype_value.appendSlice(arena_allocator, self.current.value);
                try helpers.advance(self);
            }
            doctype = try doctype_value.toOwnedSlice(arena_allocator);
            try helpers.skipNewlines(self);
        }

        while (self.current.type != .Eof) {
            const child = try self.parseStatement();
            try children.append(arena_allocator, child);
            try helpers.skipNewlines(self);
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
    pub fn parseStatement(self: *Parser) anyerror!*ast.AstNode {
        return switch (self.current.type) {
            .Ident => try tag_parser.parseTag(self),
            .Class, .Id, .LParen => try tag_parser.parseImplicitDiv(self),
            .Pipe => try text_parser.parsePipeText(self),
            .BufferedComment, .UnbufferedComment => try code_parser.parseComment(self),
            .UnbufferedCode, .BufferedCode, .UnescapedCode => try code_parser.parseCode(self),
            .If, .Unless => try conditionals_parser.parseConditional(self),
            .Each, .While => try loops_parser.parseLoop(self),
            .Case => try case_parser.parseCase(self),
            .Mixin => try mixins_parser.parseMixinDefinition(self),
            .Plus => try mixins_parser.parseMixinCall(self),
            .Include => try templates_parser.parseInclude(self),
            .Extends => try templates_parser.parseExtends(self),
            .Block => try templates_parser.parseBlock(self),
            .Doctype => {
                std.debug.print("Error: 'doctype' must be at the beginning of the document (line {d})\n", .{self.current.line});
                std.debug.print("Hint: Move 'doctype html' to line 1, before any comments or content\n", .{});
                return error.DoctypeMustBeFirst;
            },
            else => {
                std.debug.print("Unexpected token in statement: {s} at line {d}\n", .{
                    @tagName(self.current.type),
                    self.current.line,
                });
                return error.UnexpectedToken;
            },
        };
    }

    /// Parse indented child elements
    ///
    /// Handles INDENT token, parses all children until DEDENT.
    /// Used by tags, conditionals, loops, etc. to parse nested content.
    pub fn parseChildren(self: *Parser, children: *std.ArrayListUnmanaged(*ast.AstNode)) anyerror!void {
        const arena_allocator = self.arena.allocator();

        while (!helpers.match(self, &.{ .Dedent, .Eof })) {
            try helpers.skipNewlines(self);

            if (helpers.match(self, &.{ .Dedent, .Eof })) {
                break;
            }

            const child = try self.parseStatement();
            try children.append(arena_allocator, child);
        }
    }
};

// Import tests
test {
    _ = @import("tests.zig");
}
