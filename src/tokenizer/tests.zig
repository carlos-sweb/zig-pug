//! Tokenizer Tests
//!
//! Test suite for the tokenizer module. Tests cover:
//! - Basic token types (identifiers, keywords, strings, numbers)
//! - Special syntax (.class, #id, comments, interpolation)
//! - Code markers (=, !=, -)
//! - Indentation tracking (INDENT/DEDENT)
//! - Symbol recognition
//!
//! Run with: zig test src/tokenizer/tests.zig

const std = @import("std");
const Tokenizer = @import("mod.zig").Tokenizer;
const TokenType = @import("TokenType.zig").TokenType;

test "tokenizer - identifiers" {
    // Test identifiers in code context (not after tags)
    // Using "- " to enter code mode where identifiers are separate tokens
    var tokenizer = try Tokenizer.init(std.testing.allocator, "- hello world123");
    defer tokenizer.deinit();

    const token1 = try tokenizer.next();
    try std.testing.expectEqual(TokenType.UnbufferedCode, token1.type);

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

test "tokenizer - each loop tokens" {
    var tokenizer = try Tokenizer.init(std.testing.allocator, "each item in items");
    defer tokenizer.deinit();

    std.debug.print("\n=== TOKENS para 'each item in items' ===\n", .{});

    var count: usize = 0;
    while (true) {
        const token = try tokenizer.next();
        count += 1;

        std.debug.print("{d}. {s:20} = '{s}'\n", .{
            count,
            @tagName(token.type),
            token.value,
        });

        if (token.type == TokenType.Eof) break;
        if (count > 20) break; // safety
    }
}

test "tokenizer - each loop with index" {
    var tokenizer = try Tokenizer.init(std.testing.allocator, "each item, i in items");
    defer tokenizer.deinit();

    // Verify correct token sequence
    const tok1 = try tokenizer.next();
    try std.testing.expectEqual(TokenType.Each, tok1.type);
    try std.testing.expectEqualStrings("each", tok1.value);

    const tok2 = try tokenizer.next();
    try std.testing.expectEqual(TokenType.Ident, tok2.type);
    try std.testing.expectEqualStrings("item", tok2.value);

    const tok3 = try tokenizer.next();
    try std.testing.expectEqual(TokenType.Comma, tok3.type);

    const tok4 = try tokenizer.next();
    try std.testing.expectEqual(TokenType.Ident, tok4.type);
    try std.testing.expectEqualStrings("i", tok4.value);

    const tok5 = try tokenizer.next();
    try std.testing.expectEqual(TokenType.In, tok5.type);
    try std.testing.expectEqualStrings("in", tok5.value);

    const tok6 = try tokenizer.next();
    try std.testing.expectEqual(TokenType.Ident, tok6.type);
    try std.testing.expectEqualStrings("items", tok6.value);
}

test "tokenizer - while loop tokens" {
    var tokenizer = try Tokenizer.init(std.testing.allocator, "while condition");
    defer tokenizer.deinit();

    const tok1 = try tokenizer.next();
    try std.testing.expectEqual(TokenType.While, tok1.type);

    const tok2 = try tokenizer.next();
    try std.testing.expectEqual(TokenType.Ident, tok2.type);
    try std.testing.expectEqualStrings("condition", tok2.value);
}
