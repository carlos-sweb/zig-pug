const std = @import("std");

// Tokenizer module - To be implemented in Step 3
// See: 03-tokenizer-base.md

pub const TokenType = enum {
    // TODO: Define token types
    Eof,
};

pub const Token = struct {
    type: TokenType,
    value: []const u8,
    line: usize,
    column: usize,
};

pub const Tokenizer = struct {
    source: []const u8,
    pos: usize,

    pub fn init(source: []const u8) Tokenizer {
        return .{
            .source = source,
            .pos = 0,
        };
    }

    pub fn next(self: *Tokenizer) !?Token {
        // TODO: Implement tokenization
        _ = self;
        return null;
    }
};

test "tokenizer stub" {
    var tokenizer = Tokenizer.init("test");
    _ = try tokenizer.next();
}
