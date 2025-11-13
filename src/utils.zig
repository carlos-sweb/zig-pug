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
