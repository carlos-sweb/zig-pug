//! Attribute Parsing
//!
//! Parses HTML attribute lists within parentheses:
//!   (name=value, name2=value2, ...)
//!
//! Attribute value types:
//!   - Static string:    href="/"          → value = "/", is_expression = false
//!   - Expression:       class=myClass      → value = "myClass", is_expression = true
//!   - Interpolation:    value=#{age + 1}   → value = "age + 1", is_expression = true
//!   - Boolean:          disabled           → value = null
//!   - Unescaped:        content!=rawHtml   → is_unescaped = true
//!
//! The key insight: after `=` (BufferedCode), we call a single `parseExprValue`
//! function regardless of what follows. It accumulates tokens until a natural
//! boundary (Comma, RParen, Newline, Eof) while tracking paren depth.

const std = @import("std");
const ast = @import("../ast/mod.zig");
const helpers = @import("helpers.zig");
const tokenizer = @import("../tokenizer/mod.zig");

pub const Parser = @import("mod.zig").Parser;

// ---------------------------------------------------------------------------
// Expression accumulator
// ---------------------------------------------------------------------------

/// Token types that terminate an attribute value expression.
/// A RParen only terminates when paren_depth == 0 (checked separately).
const EXPR_TERMINATORS = &[_]tokenizer.TokenType{ .Comma, .Newline, .Eof };

/// Accumulate tokens into a JS expression string until a boundary is reached.
///
/// Handles:
///   - Nested parentheses (method calls): name.toLowerCase()
///   - Operators: +, -, *, /, >, <, >=, <=, ==, &&, ||, ?, :
///   - Strings: adds quotes back for JS  →  "hello"
///   - Identifiers, numbers, booleans
///   - EscapedInterpol / UnescapedInterpol passthrough
///
/// Stops at: Comma, Newline, Eof, or unmatched RParen (paren_depth == 0).
fn parseExprValue(self: *Parser, initial: []const u8) ![]const u8 {
    const alloc = self.arena.allocator();
    var buf: std.ArrayListUnmanaged(u8) = .empty;
    try buf.appendSlice(alloc, initial);

    var paren_depth: i32 = 0;

    while (true) {
        // Terminate at boundary tokens
        if (helpers.match(self, EXPR_TERMINATORS)) break;

        // RParen closes the attribute list unless we are inside nested parens
        if (self.current.type == .RParen and paren_depth == 0) break;

        switch (self.current.type) {
            // Grouping
            .LParen => {
                try buf.append(alloc, '(');
                paren_depth += 1;
                try helpers.advance(self);
            },
            .RParen => {
                // paren_depth > 0 here (checked above)
                try buf.append(alloc, ')');
                paren_depth -= 1;
                try helpers.advance(self);
            },
            .LBracket => {
                try buf.append(alloc, '[');
                try helpers.advance(self);
            },
            .RBracket => {
                try buf.append(alloc, ']');
                try helpers.advance(self);
            },
            .LBrace => {
                try buf.append(alloc, '{');
                try helpers.advance(self);
            },
            .RBrace => {
                try buf.append(alloc, '}');
                try helpers.advance(self);
            },

            // Arithmetic
            .Plus => {
                try buf.append(alloc, '+');
                try helpers.advance(self);
            },
            .Minus => {
                try buf.append(alloc, '-');
                try helpers.advance(self);
            },

            // Property access
            .Dot => {
                try buf.append(alloc, '.');
                try helpers.advance(self);
            },

            // Comparison
            .Greater => {
                try buf.appendSlice(alloc, ">");
                try helpers.advance(self);
            },
            .Less => {
                try buf.appendSlice(alloc, "<");
                try helpers.advance(self);
            },
            .GreaterEqual => {
                try buf.appendSlice(alloc, ">=");
                try helpers.advance(self);
            },
            .LessEqual => {
                try buf.appendSlice(alloc, "<=");
                try helpers.advance(self);
            },
            .Equal => {
                try buf.appendSlice(alloc, "==");
                try helpers.advance(self);
            },
            .NotEqual => {
                try buf.appendSlice(alloc, "!=");
                try helpers.advance(self);
            },

            // Logical
            .And => {
                try buf.appendSlice(alloc, "&&");
                try helpers.advance(self);
            },
            .Or => {
                try buf.appendSlice(alloc, "||");
                try helpers.advance(self);
            },

            // Ternary
            .Question => {
                try buf.append(alloc, '?');
                try helpers.advance(self);
            },
            .Colon => {
                try buf.append(alloc, ':');
                try helpers.advance(self);
            },

            // Literals
            .String => {
                // Tokenizer strips quotes — add them back for JS
                const s = try std.fmt.allocPrint(alloc, "\"{s}\"", .{self.current.value});
                try buf.appendSlice(alloc, s);
                try helpers.advance(self);
            },
            .Ident => {
                try buf.appendSlice(alloc, self.current.value);
                try helpers.advance(self);
            },

            // Interpolation — pass raw expression, wrap in mujs call site
            .EscapedInterpol => {
                const s = try std.fmt.allocPrint(alloc, "#{{{s}}}", .{self.current.value});
                try buf.appendSlice(alloc, s);
                try helpers.advance(self);
            },
            .UnescapedInterpol => {
                const s = try std.fmt.allocPrint(alloc, "!{{{s}}}", .{self.current.value});
                try buf.appendSlice(alloc, s);
                try helpers.advance(self);
            },

            else => break,
        }
    }

    return buf.toOwnedSlice(alloc);
}

// ---------------------------------------------------------------------------
// Public entry point
// ---------------------------------------------------------------------------

/// Parse attribute list `(key=value, key2=value2, ...)` into `attributes`.
///
/// Handles:
///   - BufferedCode  (=)  → escaped expression
///   - UnescapedCode (!=) → unescaped expression
///   - No operator        → boolean attribute (disabled, checked, …)
///   - Multiline attrs    → newlines inside () are skipped
pub fn parseAttributes(
    self: *Parser,
    attributes: *std.ArrayListUnmanaged(ast.Attribute),
) !void {
    const alloc = self.arena.allocator();
    _ = try helpers.expect(self, .LParen);
    try helpers.skipNewlines(self);

    while (!helpers.match(self, &.{ .RParen, .Eof })) {
        try helpers.skipNewlines(self);
        if (helpers.match(self, &.{ .RParen, .Eof })) break;

        // ── Attribute name ─────────────────────────────────────────────────
        if (!helpers.match(self, &.{.Ident})) break;
        const name = self.current.value;
        try helpers.advance(self);

        // ── Optional value ─────────────────────────────────────────────────
        var value: ?[]const u8 = null;
        var is_unescaped = false;
        var is_expression = false;

        if (helpers.match(self, &.{ .BufferedCode, .UnescapedCode })) {
            is_unescaped = self.current.type == .UnescapedCode;
            try helpers.advance(self); // consume = or !=

            // Determine initial fragment and whether it's an expression
            if (helpers.match(self, &.{.String})) {
                // Static string — but may continue as expression (e.g. "foo" + bar)
                const raw = self.current.value; // already stripped by tokenizer
                try helpers.advance(self);

                if (helpers.match(self, &.{ .Plus, .Dot, .LBracket, .LParen, .Greater, .Less, .GreaterEqual, .LessEqual, .Equal, .NotEqual, .And, .Or, .Question })) {
                    // String is start of a compound expression — re-quote for JS
                    const quoted = try std.fmt.allocPrint(alloc, "\"{s}\"", .{raw});
                    value = try parseExprValue(self, quoted);
                    is_expression = true;
                } else {
                    value = raw; // plain static string
                }
            } else if (helpers.match(self, &.{.EscapedInterpol})) {
                // #{expr} — mujs expression
                value = self.current.value;
                is_expression = true;
                try helpers.advance(self);
            } else if (helpers.match(self, &.{.Ident})) {
                // Identifier or start of complex expression
                const initial = self.current.value;
                try helpers.advance(self);
                value = try parseExprValue(self, initial);
                is_expression = true;
            }
            // else: value remains null (malformed, skip gracefully)
        }
        // else: boolean attribute — value stays null

        try attributes.append(alloc, .{
            .name = name,
            .value = value,
            .is_unescaped = is_unescaped,
            .is_expression = is_expression,
        });

        try helpers.skipNewlines(self);

        // Optional comma separator
        if (helpers.match(self, &.{.Comma})) {
            try helpers.advance(self);
            try helpers.skipNewlines(self);
        }
    }

    try helpers.skipNewlines(self);
    _ = try helpers.expect(self, .RParen);
}
