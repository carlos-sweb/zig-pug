const std = @import("std");

// Utility functions module

pub fn isWhitespace(ch: u8) bool {
    return ch == ' ' or ch == '\t' or ch == '\r' or ch == '\n';
}

pub fn isAlpha(ch: u8) bool {
    return (ch >= 'a' and ch <= 'z') or (ch >= 'A' and ch <= 'Z');
}

pub fn isDigit(ch: u8) bool {
    return ch >= '0' and ch <= '9';
}

pub fn isAlphanumeric(ch: u8) bool {
    return isAlpha(ch) or isDigit(ch);
}

test "utils - whitespace" {
    try std.testing.expect(isWhitespace(' '));
    try std.testing.expect(isWhitespace('\t'));
    try std.testing.expect(!isWhitespace('a'));
}

test "utils - alpha" {
    try std.testing.expect(isAlpha('a'));
    try std.testing.expect(isAlpha('Z'));
    try std.testing.expect(!isAlpha('1'));
}

test "utils - digit" {
    try std.testing.expect(isDigit('5'));
    try std.testing.expect(!isDigit('a'));
}

// Error handling system
pub const ZigPugError = error{
    // Tokenizer errors
    UnexpectedCharacter,
    InvalidIndentation,
    UnterminatedString,

    // Parser errors
    UnexpectedToken,
    ExpectedToken,
    InvalidSyntax,
    InvalidNesting,

    // Compiler errors
    UndefinedVariable,
    TypeError,

    // Runtime errors
    DivisionByZero,
    NullPointerAccess,

    // IO errors
    FileNotFound,
    AccessDenied,

    // Memory errors
    OutOfMemory,

    // Not yet implemented
    NotImplemented,
};

pub const ErrorInfo = struct {
    err: ZigPugError,
    message: []const u8,
    line: usize,
    column: usize,
    source_line: ?[]const u8,
};

pub fn reportError(info: ErrorInfo) void {
    var stdout_buffer: [4096]u8 = undefined;
    var stdout_writer = std.fs.File.stderr().writer(&stdout_buffer);
    const stderr = &stdout_writer.interface;

    stderr.print("Error at line {d}, column {d}: {s}\n", .{ info.line, info.column, info.message }) catch {};

    if (info.source_line) |line| {
        stderr.print("  {s}\n", .{line}) catch {};
        // Print caret pointing to error position
        var i: usize = 0;
        while (i < info.column - 1) : (i += 1) {
            stderr.print(" ", .{}) catch {};
        }
        stderr.print("^\n", .{}) catch {};
    }

    stderr.flush() catch {};
}
