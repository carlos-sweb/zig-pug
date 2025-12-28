//! Attribute Parsing
//!
//! This module handles parsing of HTML attributes within parentheses.

const std = @import("std");
const ast = @import("../ast/mod.zig");
const helpers = @import("helpers.zig");

/// Parser forward declaration
pub const Parser = @import("mod.zig").Parser;

/// Parse attribute list (key="value", class=myClass)
///
/// Parses attributes within parentheses, handling:
/// - Static attributes: href="/", title="Home"
/// - Expression attributes: class=myClass, data=userData
/// - Boolean attributes: disabled, checked
///
/// Syntax: (name=value, name2=value2, ...)
pub fn parseAttributes(self: *Parser, attributes: *std.ArrayListUnmanaged(ast.Attribute)) !void {
    const arena_allocator = self.arena.allocator();
    _ = try helpers.expect(self, .LParen);

    // Atributos pueden estar en múltiples líneas
    try helpers.skipNewlines(self);

    var pending_attr_name: ?[]const u8 = null;

    while (!helpers.match(self, &.{ .RParen, .Eof })) {
        try helpers.skipNewlines(self);

        // Check for spread attributes: &attributes
        if (helpers.match(self, &.{.Hash})) {
            // Skip for now - would need special handling
            try helpers.advance(self);
            if (helpers.match(self, &.{.Ident})) {
                try helpers.advance(self);
            }
            continue;
        }

        // Parse attribute name
        if (!helpers.match(self, &.{.Ident})) {
            break;
        }
        const name_token = self.current;
        try helpers.advance(self);

        var value: ?[]const u8 = null;
        var is_unescaped = false;
        var is_expression = false;

        // Parse attribute value
        if (helpers.match(self, &.{.Assign})) {
            try helpers.advance(self);

            // Parse value - can be string, number, identifier, or complex expression
            // First, try simple single-token case for backward compatibility
            if (helpers.match(self, &.{.String})) {
                // Save original value with quotes for potential complex expression
                const original_str = self.current.value;

                // Strip quotes from simple string literals (tokenizer includes them)
                const str_val = self.current.value;
                if (str_val.len >= 2 and str_val[0] == '"' and str_val[str_val.len - 1] == '"') {
                    value = str_val[1 .. str_val.len - 1];
                } else {
                    value = str_val;
                }
                try helpers.advance(self);

                // Check if there are more tokens (operators, method calls, etc.)
                if (helpers.match(self, &.{.Plus, .Minus, .Dot, .LBracket, .LParen, .Greater, .Less, .GreaterEqual, .LessEqual, .Equal, .And, .Or, .Question})) {
                    // Complex expression - add quotes back for JavaScript
                    var expr_str = try std.fmt.allocPrint(arena_allocator, "\"{s}\"", .{original_str});
                    var paren_depth: i32 = 0; // Track parenthesis nesting for method calls

                    while (true) {
                        // Stop if we hit comma or newline (attribute separators)
                        if (helpers.match(self, &.{ .Comma, .Eof, .Newline })) break;
                        // Stop if we hit RParen and we're not inside nested parens (this closes the attributes)
                        if (helpers.match(self, &.{.RParen}) and paren_depth == 0) break;
                        if (helpers.match(self, &.{.Plus})) {
                            expr_str = try std.mem.concat(arena_allocator, u8, &[_][]const u8{ expr_str, "+" });
                            is_expression = true;
                            try helpers.advance(self);
                        } else if (helpers.match(self, &.{.Minus})) {
                            expr_str = try std.mem.concat(arena_allocator, u8, &[_][]const u8{ expr_str, "-" });
                            is_expression = true;
                            try helpers.advance(self);
                        } else if (helpers.match(self, &.{.Dot})) {
                            expr_str = try std.mem.concat(arena_allocator, u8, &[_][]const u8{ expr_str, "." });
                            is_expression = true;
                            try helpers.advance(self);
                        } else if (helpers.match(self, &.{.LBracket})) {
                            expr_str = try std.mem.concat(arena_allocator, u8, &[_][]const u8{ expr_str, "[" });
                            is_expression = true;
                            try helpers.advance(self);
                        } else if (helpers.match(self, &.{.RBracket})) {
                            expr_str = try std.mem.concat(arena_allocator, u8, &[_][]const u8{ expr_str, "]" });
                            try helpers.advance(self);
                        } else if (helpers.match(self, &.{.LParen})) {
                            expr_str = try std.mem.concat(arena_allocator, u8, &[_][]const u8{ expr_str, "(" });
                            paren_depth += 1; // Entering nested parentheses
                            try helpers.advance(self);
                        } else if (helpers.match(self, &.{.RParen})) {
                            // This is a closing paren of a method call (we already checked paren_depth in while condition)
                            expr_str = try std.mem.concat(arena_allocator, u8, &[_][]const u8{ expr_str, ")" });
                            paren_depth -= 1; // Exiting nested parentheses
                            try helpers.advance(self);
                        } else if (helpers.match(self, &.{.Greater})) {
                            expr_str = try std.mem.concat(arena_allocator, u8, &[_][]const u8{ expr_str, ">" });
                            is_expression = true;
                            try helpers.advance(self);
                        } else if (helpers.match(self, &.{.Less})) {
                            expr_str = try std.mem.concat(arena_allocator, u8, &[_][]const u8{ expr_str, "<" });
                            is_expression = true;
                            try helpers.advance(self);
                        } else if (helpers.match(self, &.{.GreaterEqual})) {
                            expr_str = try std.mem.concat(arena_allocator, u8, &[_][]const u8{ expr_str, ">=" });
                            is_expression = true;
                            try helpers.advance(self);
                        } else if (helpers.match(self, &.{.LessEqual})) {
                            expr_str = try std.mem.concat(arena_allocator, u8, &[_][]const u8{ expr_str, "<=" });
                            is_expression = true;
                            try helpers.advance(self);
                        } else if (helpers.match(self, &.{.Equal})) {
                            expr_str = try std.mem.concat(arena_allocator, u8, &[_][]const u8{ expr_str, "==" });
                            is_expression = true;
                            try helpers.advance(self);
                        } else if (helpers.match(self, &.{.And})) {
                            expr_str = try std.mem.concat(arena_allocator, u8, &[_][]const u8{ expr_str, "&&" });
                            is_expression = true;
                            try helpers.advance(self);
                        } else if (helpers.match(self, &.{.Or})) {
                            expr_str = try std.mem.concat(arena_allocator, u8, &[_][]const u8{ expr_str, "||" });
                            is_expression = true;
                            try helpers.advance(self);
                        } else if (helpers.match(self, &.{.Question})) {
                            expr_str = try std.mem.concat(arena_allocator, u8, &[_][]const u8{ expr_str, "?" });
                            is_expression = true;
                            try helpers.advance(self);
                        } else if (helpers.match(self, &.{.Colon})) {
                            expr_str = try std.mem.concat(arena_allocator, u8, &[_][]const u8{ expr_str, ":" });
                            is_expression = true;
                            try helpers.advance(self);
                        } else if (helpers.match(self, &.{.String})) {
                            // Tokenizer strips quotes, need to add them back for JavaScript
                            const str_with_quotes = try std.fmt.allocPrint(arena_allocator, "\"{s}\"", .{self.current.value});
                            expr_str = try std.mem.concat(arena_allocator, u8, &[_][]const u8{ expr_str, str_with_quotes });
                            try helpers.advance(self);
                        } else if (helpers.match(self, &.{.Number})) {
                            expr_str = try std.mem.concat(arena_allocator, u8, &[_][]const u8{ expr_str, self.current.value });
                            try helpers.advance(self);
                        } else if (helpers.match(self, &.{.Boolean})) {
                            expr_str = try std.mem.concat(arena_allocator, u8, &[_][]const u8{ expr_str, self.current.value });
                            try helpers.advance(self);
                        } else if (helpers.match(self, &.{.Ident})) {
                            // Save the identifier value in case we need it for pending attribute
                            const saved_ident_value = self.current.value;
                            expr_str = try std.mem.concat(arena_allocator, u8, &[_][]const u8{ expr_str, self.current.value });
                            is_expression = true;
                            try helpers.advance(self);

                            // Check if next token is BufferedCode (=), which means this Ident is a new attribute
                            if (helpers.match(self, &.{.BufferedCode})) {
                                // This Ident is the start of a new attribute, not part of the expression
                                // Store it as pending and don't restore current (leave it as BufferedCode)
                                pending_attr_name = saved_ident_value;
                                // Remove the Ident we added to expr_str by recalculating without it
                                expr_str = expr_str[0..(expr_str.len - saved_ident_value.len)];
                                break;
                            }

                            // Check if next token is an operator that continues the expression
                            if (!helpers.match(self, &.{.Plus, .Minus, .Dot, .LBracket, .LParen, .Greater, .Less, .GreaterEqual, .LessEqual, .Equal, .And, .Or, .Question, .Colon})) {
                                break;
                            }
                        } else {
                            break;
                        }
                    }
                    value = expr_str;
                }
            } else if (helpers.match(self, &.{.Number})) {
                value = self.current.value;
                try helpers.advance(self);
            } else if (helpers.match(self, &.{.Boolean})) {
                value = self.current.value;
                try helpers.advance(self);
            } else if (helpers.match(self, &.{.Ident})) {
                var expr_str = self.current.value;
                is_expression = true; // Identifier = expression to evaluate
                try helpers.advance(self);

                // Check for complex expressions after identifier (e.g., active ? "yes" : "no", obj.method())
                if (helpers.match(self, &.{.Plus, .Minus, .Dot, .LBracket, .LParen, .Greater, .Less, .GreaterEqual, .LessEqual, .Equal, .And, .Or, .Question})) {
                    var paren_depth: i32 = 0; // Track parenthesis nesting for method calls
                    while (true) {
                        // Stop if we hit comma or newline (attribute separators)
                        if (helpers.match(self, &.{ .Comma, .Eof, .Newline })) break;
                        // Stop if we hit RParen and we're not inside nested parens (this closes the attributes)
                        if (helpers.match(self, &.{.RParen}) and paren_depth == 0) break;
                        if (helpers.match(self, &.{.Plus})) {
                            expr_str = try std.mem.concat(arena_allocator, u8, &[_][]const u8{ expr_str, "+" });
                            try helpers.advance(self);
                        } else if (helpers.match(self, &.{.Minus})) {
                            expr_str = try std.mem.concat(arena_allocator, u8, &[_][]const u8{ expr_str, "-" });
                            try helpers.advance(self);
                        } else if (helpers.match(self, &.{.Dot})) {
                            expr_str = try std.mem.concat(arena_allocator, u8, &[_][]const u8{ expr_str, "." });
                            try helpers.advance(self);
                        } else if (helpers.match(self, &.{.LBracket})) {
                            expr_str = try std.mem.concat(arena_allocator, u8, &[_][]const u8{ expr_str, "[" });
                            try helpers.advance(self);
                        } else if (helpers.match(self, &.{.RBracket})) {
                            expr_str = try std.mem.concat(arena_allocator, u8, &[_][]const u8{ expr_str, "]" });
                            try helpers.advance(self);
                        } else if (helpers.match(self, &.{.LParen})) {
                            expr_str = try std.mem.concat(arena_allocator, u8, &[_][]const u8{ expr_str, "(" });
                            paren_depth += 1; // Entering nested parentheses
                            try helpers.advance(self);
                        } else if (helpers.match(self, &.{.RParen})) {
                            // This is a closing paren of a method call (we already checked paren_depth in while condition)
                            expr_str = try std.mem.concat(arena_allocator, u8, &[_][]const u8{ expr_str, ")" });
                            paren_depth -= 1; // Exiting nested parentheses
                            try helpers.advance(self);
                        } else if (helpers.match(self, &.{.Greater})) {
                            expr_str = try std.mem.concat(arena_allocator, u8, &[_][]const u8{ expr_str, ">" });
                            try helpers.advance(self);
                        } else if (helpers.match(self, &.{.Less})) {
                            expr_str = try std.mem.concat(arena_allocator, u8, &[_][]const u8{ expr_str, "<" });
                            try helpers.advance(self);
                        } else if (helpers.match(self, &.{.GreaterEqual})) {
                            expr_str = try std.mem.concat(arena_allocator, u8, &[_][]const u8{ expr_str, ">=" });
                            try helpers.advance(self);
                        } else if (helpers.match(self, &.{.LessEqual})) {
                            expr_str = try std.mem.concat(arena_allocator, u8, &[_][]const u8{ expr_str, "<=" });
                            try helpers.advance(self);
                        } else if (helpers.match(self, &.{.Equal})) {
                            expr_str = try std.mem.concat(arena_allocator, u8, &[_][]const u8{ expr_str, "==" });
                            try helpers.advance(self);
                        } else if (helpers.match(self, &.{.And})) {
                            expr_str = try std.mem.concat(arena_allocator, u8, &[_][]const u8{ expr_str, "&&" });
                            try helpers.advance(self);
                        } else if (helpers.match(self, &.{.Or})) {
                            expr_str = try std.mem.concat(arena_allocator, u8, &[_][]const u8{ expr_str, "||" });
                            try helpers.advance(self);
                        } else if (helpers.match(self, &.{.Question})) {
                            expr_str = try std.mem.concat(arena_allocator, u8, &[_][]const u8{ expr_str, "?" });
                            try helpers.advance(self);
                        } else if (helpers.match(self, &.{.Colon})) {
                            expr_str = try std.mem.concat(arena_allocator, u8, &[_][]const u8{ expr_str, ":" });
                            try helpers.advance(self);
                        } else if (helpers.match(self, &.{.String})) {
                            const str_with_quotes = try std.fmt.allocPrint(arena_allocator, "\"{s}\"", .{self.current.value});
                            expr_str = try std.mem.concat(arena_allocator, u8, &[_][]const u8{ expr_str, str_with_quotes });
                            try helpers.advance(self);
                        } else if (helpers.match(self, &.{.Number})) {
                            expr_str = try std.mem.concat(arena_allocator, u8, &[_][]const u8{ expr_str, self.current.value });
                            try helpers.advance(self);
                        } else if (helpers.match(self, &.{.Boolean})) {
                            expr_str = try std.mem.concat(arena_allocator, u8, &[_][]const u8{ expr_str, self.current.value });
                            try helpers.advance(self);
                        } else if (helpers.match(self, &.{.Ident})) {
                            // Save the identifier value in case we need it for pending attribute
                            const saved_ident_value = self.current.value;
                            expr_str = try std.mem.concat(arena_allocator, u8, &[_][]const u8{ expr_str, self.current.value });
                            try helpers.advance(self);

                            // Check if next token is BufferedCode (=), which means this Ident is a new attribute
                            if (helpers.match(self, &.{.BufferedCode})) {
                                // This Ident is the start of a new attribute, not part of the expression
                                // Store it as pending and don't restore current (leave it as BufferedCode)
                                pending_attr_name = saved_ident_value;
                                // Remove the Ident we added to expr_str by recalculating without it
                                expr_str = expr_str[0..(expr_str.len - saved_ident_value.len)];
                                break;
                            }

                            // Check if next token is an operator that continues the expression
                            // If not (e.g., next token is BufferedCode for a new attribute), stop here
                            if (!helpers.match(self, &.{.Plus, .Minus, .Dot, .LBracket, .LParen, .Greater, .Less, .GreaterEqual, .LessEqual, .Equal, .And, .Or, .Question, .Colon})) {
                                break;
                            }
                        } else {
                            break;
                        }
                    }
                }
                value = expr_str;
            }
        } else if (helpers.match(self, &.{.BufferedCode})) {
            // Handle = for dynamic values (same as Assign)
            try helpers.advance(self);
            is_unescaped = false;

            if (helpers.match(self, &.{.String})) {
                // Save original value with quotes for potential complex expression
                const original_str = self.current.value;

                // Strip quotes from simple string literals
                const str_val = self.current.value;
                if (str_val.len >= 2 and str_val[0] == '"' and str_val[str_val.len - 1] == '"') {
                    value = str_val[1 .. str_val.len - 1];
                } else {
                    value = str_val;
                }
                try helpers.advance(self);

                // Check for operators (complex expression with method calls)
                if (helpers.match(self, &.{.Plus, .Minus, .Dot, .LBracket, .LParen, .Greater, .Less, .GreaterEqual, .LessEqual, .Equal, .And, .Or, .Question})) {
                    // Complex expression - add quotes back for JavaScript
                    var expr_str = try std.fmt.allocPrint(arena_allocator, "\"{s}\"", .{original_str});
                    var paren_depth: i32 = 0; // Track parenthesis nesting for method calls

                    while (true) {
                        // Stop if we hit comma or newline (attribute separators)
                        if (helpers.match(self, &.{ .Comma, .Eof, .Newline })) break;
                        // Stop if we hit RParen and we're not inside nested parens (this closes the attributes)
                        if (helpers.match(self, &.{.RParen}) and paren_depth == 0) break;
                        if (helpers.match(self, &.{.Plus})) {
                            expr_str = try std.mem.concat(arena_allocator, u8, &[_][]const u8{ expr_str, "+" });
                            is_expression = true;
                            try helpers.advance(self);
                        } else if (helpers.match(self, &.{.Minus})) {
                            expr_str = try std.mem.concat(arena_allocator, u8, &[_][]const u8{ expr_str, "-" });
                            is_expression = true;
                            try helpers.advance(self);
                        } else if (helpers.match(self, &.{.Dot})) {
                            expr_str = try std.mem.concat(arena_allocator, u8, &[_][]const u8{ expr_str, "." });
                            is_expression = true;
                            try helpers.advance(self);
                        } else if (helpers.match(self, &.{.LBracket})) {
                            expr_str = try std.mem.concat(arena_allocator, u8, &[_][]const u8{ expr_str, "[" });
                            is_expression = true;
                            try helpers.advance(self);
                        } else if (helpers.match(self, &.{.RBracket})) {
                            expr_str = try std.mem.concat(arena_allocator, u8, &[_][]const u8{ expr_str, "]" });
                            try helpers.advance(self);
                        } else if (helpers.match(self, &.{.LParen})) {
                            expr_str = try std.mem.concat(arena_allocator, u8, &[_][]const u8{ expr_str, "(" });
                            paren_depth += 1; // Entering nested parentheses
                            try helpers.advance(self);
                        } else if (helpers.match(self, &.{.RParen})) {
                            // This is a closing paren of a method call (we already checked paren_depth in while condition)
                            expr_str = try std.mem.concat(arena_allocator, u8, &[_][]const u8{ expr_str, ")" });
                            paren_depth -= 1; // Exiting nested parentheses
                            try helpers.advance(self);
                        } else if (helpers.match(self, &.{.Greater})) {
                            expr_str = try std.mem.concat(arena_allocator, u8, &[_][]const u8{ expr_str, ">" });
                            is_expression = true;
                            try helpers.advance(self);
                        } else if (helpers.match(self, &.{.Less})) {
                            expr_str = try std.mem.concat(arena_allocator, u8, &[_][]const u8{ expr_str, "<" });
                            is_expression = true;
                            try helpers.advance(self);
                        } else if (helpers.match(self, &.{.GreaterEqual})) {
                            expr_str = try std.mem.concat(arena_allocator, u8, &[_][]const u8{ expr_str, ">=" });
                            is_expression = true;
                            try helpers.advance(self);
                        } else if (helpers.match(self, &.{.LessEqual})) {
                            expr_str = try std.mem.concat(arena_allocator, u8, &[_][]const u8{ expr_str, "<=" });
                            is_expression = true;
                            try helpers.advance(self);
                        } else if (helpers.match(self, &.{.Equal})) {
                            expr_str = try std.mem.concat(arena_allocator, u8, &[_][]const u8{ expr_str, "==" });
                            is_expression = true;
                            try helpers.advance(self);
                        } else if (helpers.match(self, &.{.And})) {
                            expr_str = try std.mem.concat(arena_allocator, u8, &[_][]const u8{ expr_str, "&&" });
                            is_expression = true;
                            try helpers.advance(self);
                        } else if (helpers.match(self, &.{.Or})) {
                            expr_str = try std.mem.concat(arena_allocator, u8, &[_][]const u8{ expr_str, "||" });
                            is_expression = true;
                            try helpers.advance(self);
                        } else if (helpers.match(self, &.{.Question})) {
                            expr_str = try std.mem.concat(arena_allocator, u8, &[_][]const u8{ expr_str, "?" });
                            is_expression = true;
                            try helpers.advance(self);
                        } else if (helpers.match(self, &.{.Colon})) {
                            expr_str = try std.mem.concat(arena_allocator, u8, &[_][]const u8{ expr_str, ":" });
                            is_expression = true;
                            try helpers.advance(self);
                        } else if (helpers.match(self, &.{.String})) {
                            const str_with_quotes = try std.fmt.allocPrint(arena_allocator, "\"{s}\"", .{self.current.value});
                            expr_str = try std.mem.concat(arena_allocator, u8, &[_][]const u8{ expr_str, str_with_quotes });
                            try helpers.advance(self);
                        } else if (helpers.match(self, &.{.Number})) {
                            expr_str = try std.mem.concat(arena_allocator, u8, &[_][]const u8{ expr_str, self.current.value });
                            try helpers.advance(self);
                        } else if (helpers.match(self, &.{.Boolean})) {
                            expr_str = try std.mem.concat(arena_allocator, u8, &[_][]const u8{ expr_str, self.current.value });
                            try helpers.advance(self);
                        } else if (helpers.match(self, &.{.Ident})) {
                            // Save the identifier value in case we need it for pending attribute
                            const saved_ident_value = self.current.value;
                            expr_str = try std.mem.concat(arena_allocator, u8, &[_][]const u8{ expr_str, self.current.value });
                            is_expression = true;
                            try helpers.advance(self);

                            // Check if next token is BufferedCode (=), which means this Ident is a new attribute
                            if (helpers.match(self, &.{.BufferedCode})) {
                                // This Ident is the start of a new attribute, not part of the expression
                                // Store it as pending and don't restore current (leave it as BufferedCode)
                                pending_attr_name = saved_ident_value;
                                // Remove the Ident we added to expr_str by recalculating without it
                                expr_str = expr_str[0..(expr_str.len - saved_ident_value.len)];
                                break;
                            }

                            // Check if next token is an operator that continues the expression
                            if (!helpers.match(self, &.{.Plus, .Minus, .Dot, .LBracket, .LParen, .Greater, .Less, .GreaterEqual, .LessEqual, .Equal, .And, .Or, .Question, .Colon})) {
                                break;
                            }
                        } else {
                            break;
                        }
                    }
                    value = expr_str;
                }
            } else if (helpers.match(self, &.{.Ident})) {
                var expr_str = self.current.value;
                is_expression = true;
                try helpers.advance(self);

                // Check for complex expressions after identifier (including method calls)
                if (helpers.match(self, &.{.Plus, .Minus, .Dot, .LBracket, .LParen, .Greater, .Less, .GreaterEqual, .LessEqual, .Equal, .And, .Or, .Question})) {
                    var paren_depth: i32 = 0; // Track parenthesis nesting for method calls
                    while (true) {
                        // Stop if we hit comma or newline (attribute separators)
                        if (helpers.match(self, &.{ .Comma, .Eof, .Newline })) break;
                        // Stop if we hit RParen and we're not inside nested parens (this closes the attributes)
                        if (helpers.match(self, &.{.RParen}) and paren_depth == 0) break;
                        if (helpers.match(self, &.{.Plus})) {
                            expr_str = try std.mem.concat(arena_allocator, u8, &[_][]const u8{ expr_str, "+" });
                            try helpers.advance(self);
                        } else if (helpers.match(self, &.{.Minus})) {
                            expr_str = try std.mem.concat(arena_allocator, u8, &[_][]const u8{ expr_str, "-" });
                            try helpers.advance(self);
                        } else if (helpers.match(self, &.{.Dot})) {
                            expr_str = try std.mem.concat(arena_allocator, u8, &[_][]const u8{ expr_str, "." });
                            try helpers.advance(self);
                        } else if (helpers.match(self, &.{.LBracket})) {
                            expr_str = try std.mem.concat(arena_allocator, u8, &[_][]const u8{ expr_str, "[" });
                            try helpers.advance(self);
                        } else if (helpers.match(self, &.{.RBracket})) {
                            expr_str = try std.mem.concat(arena_allocator, u8, &[_][]const u8{ expr_str, "]" });
                            try helpers.advance(self);
                        } else if (helpers.match(self, &.{.LParen})) {
                            expr_str = try std.mem.concat(arena_allocator, u8, &[_][]const u8{ expr_str, "(" });
                            paren_depth += 1; // Entering nested parentheses
                            try helpers.advance(self);
                        } else if (helpers.match(self, &.{.RParen})) {
                            // This is a closing paren of a method call (we already checked paren_depth in while condition)
                            expr_str = try std.mem.concat(arena_allocator, u8, &[_][]const u8{ expr_str, ")" });
                            paren_depth -= 1; // Exiting nested parentheses
                            try helpers.advance(self);
                        } else if (helpers.match(self, &.{.Greater})) {
                            expr_str = try std.mem.concat(arena_allocator, u8, &[_][]const u8{ expr_str, ">" });
                            try helpers.advance(self);
                        } else if (helpers.match(self, &.{.Less})) {
                            expr_str = try std.mem.concat(arena_allocator, u8, &[_][]const u8{ expr_str, "<" });
                            try helpers.advance(self);
                        } else if (helpers.match(self, &.{.GreaterEqual})) {
                            expr_str = try std.mem.concat(arena_allocator, u8, &[_][]const u8{ expr_str, ">=" });
                            try helpers.advance(self);
                        } else if (helpers.match(self, &.{.LessEqual})) {
                            expr_str = try std.mem.concat(arena_allocator, u8, &[_][]const u8{ expr_str, "<=" });
                            try helpers.advance(self);
                        } else if (helpers.match(self, &.{.Equal})) {
                            expr_str = try std.mem.concat(arena_allocator, u8, &[_][]const u8{ expr_str, "==" });
                            try helpers.advance(self);
                        } else if (helpers.match(self, &.{.And})) {
                            expr_str = try std.mem.concat(arena_allocator, u8, &[_][]const u8{ expr_str, "&&" });
                            try helpers.advance(self);
                        } else if (helpers.match(self, &.{.Or})) {
                            expr_str = try std.mem.concat(arena_allocator, u8, &[_][]const u8{ expr_str, "||" });
                            try helpers.advance(self);
                        } else if (helpers.match(self, &.{.Question})) {
                            expr_str = try std.mem.concat(arena_allocator, u8, &[_][]const u8{ expr_str, "?" });
                            try helpers.advance(self);
                        } else if (helpers.match(self, &.{.Colon})) {
                            expr_str = try std.mem.concat(arena_allocator, u8, &[_][]const u8{ expr_str, ":" });
                            try helpers.advance(self);
                        } else if (helpers.match(self, &.{.String})) {
                            const str_with_quotes = try std.fmt.allocPrint(arena_allocator, "\"{s}\"", .{self.current.value});
                            expr_str = try std.mem.concat(arena_allocator, u8, &[_][]const u8{ expr_str, str_with_quotes });
                            try helpers.advance(self);
                        } else if (helpers.match(self, &.{.Number})) {
                            expr_str = try std.mem.concat(arena_allocator, u8, &[_][]const u8{ expr_str, self.current.value });
                            try helpers.advance(self);
                        } else if (helpers.match(self, &.{.Boolean})) {
                            expr_str = try std.mem.concat(arena_allocator, u8, &[_][]const u8{ expr_str, self.current.value });
                            try helpers.advance(self);
                        } else if (helpers.match(self, &.{.Ident})) {
                            // Save the identifier value in case we need it for pending attribute
                            const saved_ident_value = self.current.value;
                            expr_str = try std.mem.concat(arena_allocator, u8, &[_][]const u8{ expr_str, self.current.value });
                            try helpers.advance(self);

                            // Check if next token is BufferedCode (=), which means this Ident is a new attribute
                            if (helpers.match(self, &.{.BufferedCode})) {
                                // This Ident is the start of a new attribute, not part of the expression
                                // Store it as pending and don't restore current (leave it as BufferedCode)
                                pending_attr_name = saved_ident_value;
                                // Remove the Ident we added to expr_str by recalculating without it
                                expr_str = expr_str[0..(expr_str.len - saved_ident_value.len)];
                                break;
                            }

                            // Check if next token is an operator that continues the expression
                            // If not (e.g., next token is BufferedCode for a new attribute), stop here
                            if (!helpers.match(self, &.{.Plus, .Minus, .Dot, .LBracket, .LParen, .Greater, .Less, .GreaterEqual, .LessEqual, .Equal, .And, .Or, .Question, .Colon})) {
                                break;
                            }
                        } else {
                            break;
                        }
                    }
                }
                value = expr_str;
            }
        } else if (helpers.match(self, &.{.UnescapedCode})) {
            // Handle != for unescaped dynamic values
            try helpers.advance(self);
            is_unescaped = true;

            if (helpers.match(self, &.{.String})) {
                // Strip quotes from simple string literals
                const str_val = self.current.value;
                if (str_val.len >= 2 and str_val[0] == '"' and str_val[str_val.len - 1] == '"') {
                    value = str_val[1 .. str_val.len - 1];
                } else {
                    value = str_val;
                }
                try helpers.advance(self);
            } else if (helpers.match(self, &.{.Ident})) {
                var expr_str = self.current.value;
                is_expression = true;
                try helpers.advance(self);

                // Check for complex expressions after identifier (including method calls)
                if (helpers.match(self, &.{.Plus, .Minus, .Dot, .LBracket, .LParen, .Greater, .Less, .GreaterEqual, .LessEqual, .Equal, .And, .Or, .Question})) {
                    var paren_depth: i32 = 0; // Track parenthesis nesting for method calls
                    while (true) {
                        // Stop if we hit comma or newline (attribute separators)
                        if (helpers.match(self, &.{ .Comma, .Eof, .Newline })) break;
                        // Stop if we hit RParen and we're not inside nested parens (this closes the attributes)
                        if (helpers.match(self, &.{.RParen}) and paren_depth == 0) break;
                        if (helpers.match(self, &.{.Plus})) {
                            expr_str = try std.mem.concat(arena_allocator, u8, &[_][]const u8{ expr_str, "+" });
                            try helpers.advance(self);
                        } else if (helpers.match(self, &.{.Minus})) {
                            expr_str = try std.mem.concat(arena_allocator, u8, &[_][]const u8{ expr_str, "-" });
                            try helpers.advance(self);
                        } else if (helpers.match(self, &.{.Dot})) {
                            expr_str = try std.mem.concat(arena_allocator, u8, &[_][]const u8{ expr_str, "." });
                            try helpers.advance(self);
                        } else if (helpers.match(self, &.{.LBracket})) {
                            expr_str = try std.mem.concat(arena_allocator, u8, &[_][]const u8{ expr_str, "[" });
                            try helpers.advance(self);
                        } else if (helpers.match(self, &.{.RBracket})) {
                            expr_str = try std.mem.concat(arena_allocator, u8, &[_][]const u8{ expr_str, "]" });
                            try helpers.advance(self);
                        } else if (helpers.match(self, &.{.LParen})) {
                            expr_str = try std.mem.concat(arena_allocator, u8, &[_][]const u8{ expr_str, "(" });
                            paren_depth += 1; // Entering nested parentheses
                            try helpers.advance(self);
                        } else if (helpers.match(self, &.{.RParen})) {
                            // This is a closing paren of a method call (we already checked paren_depth in while condition)
                            expr_str = try std.mem.concat(arena_allocator, u8, &[_][]const u8{ expr_str, ")" });
                            paren_depth -= 1; // Exiting nested parentheses
                            try helpers.advance(self);
                        } else if (helpers.match(self, &.{.Greater})) {
                            expr_str = try std.mem.concat(arena_allocator, u8, &[_][]const u8{ expr_str, ">" });
                            try helpers.advance(self);
                        } else if (helpers.match(self, &.{.Less})) {
                            expr_str = try std.mem.concat(arena_allocator, u8, &[_][]const u8{ expr_str, "<" });
                            try helpers.advance(self);
                        } else if (helpers.match(self, &.{.GreaterEqual})) {
                            expr_str = try std.mem.concat(arena_allocator, u8, &[_][]const u8{ expr_str, ">=" });
                            try helpers.advance(self);
                        } else if (helpers.match(self, &.{.LessEqual})) {
                            expr_str = try std.mem.concat(arena_allocator, u8, &[_][]const u8{ expr_str, "<=" });
                            try helpers.advance(self);
                        } else if (helpers.match(self, &.{.Equal})) {
                            expr_str = try std.mem.concat(arena_allocator, u8, &[_][]const u8{ expr_str, "==" });
                            try helpers.advance(self);
                        } else if (helpers.match(self, &.{.And})) {
                            expr_str = try std.mem.concat(arena_allocator, u8, &[_][]const u8{ expr_str, "&&" });
                            try helpers.advance(self);
                        } else if (helpers.match(self, &.{.Or})) {
                            expr_str = try std.mem.concat(arena_allocator, u8, &[_][]const u8{ expr_str, "||" });
                            try helpers.advance(self);
                        } else if (helpers.match(self, &.{.Question})) {
                            expr_str = try std.mem.concat(arena_allocator, u8, &[_][]const u8{ expr_str, "?" });
                            try helpers.advance(self);
                        } else if (helpers.match(self, &.{.Colon})) {
                            expr_str = try std.mem.concat(arena_allocator, u8, &[_][]const u8{ expr_str, ":" });
                            try helpers.advance(self);
                        } else if (helpers.match(self, &.{.String})) {
                            const str_with_quotes = try std.fmt.allocPrint(arena_allocator, "\"{s}\"", .{self.current.value});
                            expr_str = try std.mem.concat(arena_allocator, u8, &[_][]const u8{ expr_str, str_with_quotes });
                            try helpers.advance(self);
                        } else if (helpers.match(self, &.{.Number})) {
                            expr_str = try std.mem.concat(arena_allocator, u8, &[_][]const u8{ expr_str, self.current.value });
                            try helpers.advance(self);
                        } else if (helpers.match(self, &.{.Boolean})) {
                            expr_str = try std.mem.concat(arena_allocator, u8, &[_][]const u8{ expr_str, self.current.value });
                            try helpers.advance(self);
                        } else if (helpers.match(self, &.{.Ident})) {
                            // Save the identifier value in case we need it for pending attribute
                            const saved_ident_value = self.current.value;
                            expr_str = try std.mem.concat(arena_allocator, u8, &[_][]const u8{ expr_str, self.current.value });
                            try helpers.advance(self);

                            // Check if next token is BufferedCode (=), which means this Ident is a new attribute
                            if (helpers.match(self, &.{.BufferedCode})) {
                                // This Ident is the start of a new attribute, not part of the expression
                                // Store it as pending and don't restore current (leave it as BufferedCode)
                                pending_attr_name = saved_ident_value;
                                // Remove the Ident we added to expr_str by recalculating without it
                                expr_str = expr_str[0..(expr_str.len - saved_ident_value.len)];
                                break;
                            }

                            // Check if next token is an operator that continues the expression
                            // If not (e.g., next token is BufferedCode for a new attribute), stop here
                            if (!helpers.match(self, &.{.Plus, .Minus, .Dot, .LBracket, .LParen, .Greater, .Less, .GreaterEqual, .LessEqual, .Equal, .And, .Or, .Question, .Colon})) {
                                break;
                            }
                        } else {
                            break;
                        }
                    }
                }
                value = expr_str;
            }
        }
        // If no value, it's a boolean attribute (e.g., checked, disabled)

        try attributes.append(arena_allocator, .{
            .name = name_token.value,
            .value = value,
            .is_unescaped = is_unescaped,
            .is_expression = is_expression,
        });

        // Check if there's a pending attribute from expression parsing
        if (pending_attr_name) |pending_name| {
            // Current is BufferedCode (=), parse the value
            if (!helpers.match(self, &.{.BufferedCode})) {
                return error.UnexpectedToken;
            }
            try helpers.advance(self);

            // Parse the pending attribute's value (simplified - just handle common cases)
            var pending_value: ?[]const u8 = null;
            var pending_is_expression = false;

            if (helpers.match(self, &.{.String})) {
                const str_val = self.current.value;
                if (str_val.len >= 2 and str_val[0] == '"' and str_val[str_val.len - 1] == '"') {
                    pending_value = str_val[1 .. str_val.len - 1];
                } else {
                    pending_value = str_val;
                }
                try helpers.advance(self);
            } else if (helpers.match(self, &.{.Ident})) {
                pending_value = self.current.value;
                pending_is_expression = true;
                try helpers.advance(self);
            }

            try attributes.append(arena_allocator, .{
                .name = pending_name,
                .value = pending_value,
                .is_unescaped = false,
                .is_expression = pending_is_expression,
            });

            pending_attr_name = null;
        }

        try helpers.skipNewlines(self);

        // Skip comma if present (optional)
        if (helpers.match(self, &.{.Comma})) {
            try helpers.advance(self);
            try helpers.skipNewlines(self);
        }
    }

    try helpers.skipNewlines(self);
    _ = try helpers.expect(self, .RParen);
}
