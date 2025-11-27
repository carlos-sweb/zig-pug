const std = @import("std");

//! Utility functions and error handling for zig-pug
//!
//! This module provides:
//! - Character classification functions (isWhitespace, isAlpha, etc.)
//! - Error types and error reporting
//! - Common utilities shared across the codebase

/// Check if a character is whitespace (space, tab, carriage return, or newline)
///
/// Used by tokenizer to skip whitespace between tokens.
///
/// Example:
/// ```zig
/// isWhitespace(' ')  => true
/// isWhitespace('\t') => true
/// isWhitespace('a')  => false
/// ```
pub fn isWhitespace(ch: u8) bool {
    return ch == ' ' or ch == '\t' or ch == '\r' or ch == '\n';
}

/// Check if a character is alphabetic (a-z or A-Z)
///
/// Used by tokenizer to identify the start of identifiers and keywords.
///
/// Example:
/// ```zig
/// isAlpha('a') => true
/// isAlpha('Z') => true
/// isAlpha('5') => false
/// isAlpha('_') => false
/// ```
pub fn isAlpha(ch: u8) bool {
    return (ch >= 'a' and ch <= 'z') or (ch >= 'A' and ch <= 'Z');
}

/// Check if a character is a digit (0-9)
///
/// Example:
/// ```zig
/// isDigit('5') => true
/// isDigit('a') => false
/// ```
pub fn isDigit(ch: u8) bool {
    return ch >= '0' and ch <= '9';
}

/// Check if a character is alphanumeric (letter or digit)
///
/// Used by tokenizer to continue scanning identifiers.
///
/// Example:
/// ```zig
/// isAlphanumeric('a') => true
/// isAlphanumeric('5') => true
/// isAlphanumeric('_') => false
/// isAlphanumeric('-') => false
/// ```
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

/// Comprehensive error types for all zig-pug operations
///
/// Organized by module/phase where they occur:
/// - Tokenizer errors: Character and string scanning issues
/// - Parser errors: Syntax and structure problems
/// - Compiler errors: Code generation issues
/// - Runtime errors: JavaScript evaluation problems
/// - IO errors: File system operations
/// - Memory errors: Allocation failures
pub const ZigPugError = error{
    // Tokenizer errors
    UnexpectedCharacter,  // Found invalid character in source
    InvalidIndentation,   // Inconsistent tabs/spaces
    UnterminatedString,   // Missing closing quote

    // Parser errors
    UnexpectedToken,      // Token doesn't fit grammar
    ExpectedToken,        // Required token not found
    InvalidSyntax,        // Malformed expression
    InvalidNesting,       // Incorrect indentation structure

    // Compiler errors
    UndefinedVariable,    // Variable not in scope
    TypeError,            // Type mismatch

    // Runtime errors
    DivisionByZero,       // Divide by zero in JS
    NullPointerAccess,    // Null dereference in JS

    // IO errors
    FileNotFound,         // Template file missing
    AccessDenied,         // Permission denied

    // Memory errors
    OutOfMemory,          // Allocation failed

    // Not yet implemented
    NotImplemented,       // Feature planned but not done
};

/// Error information for detailed error reporting
///
/// Contains all context needed to display helpful error messages
/// with source code location and visual indicators.
///
/// Fields:
/// - err: The error type
/// - message: Human-readable description
/// - line: 1-indexed line number
/// - column: 1-indexed column number
/// - source_line: Optional source code line for context
pub const ErrorInfo = struct {
    err: ZigPugError,
    message: []const u8,
    line: usize,
    column: usize,
    source_line: ?[]const u8,
};

/// Report an error to stderr with source context and visual indicator
///
/// Prints formatted error message with:
/// 1. Location (line and column)
/// 2. Error message
/// 3. Source code line (if available)
/// 4. Caret (^) pointing to error position
///
/// Example output:
/// ```
/// Error at line 5, column 12: Unexpected character '~'
///   p.container#main~ Hello
///               ^
/// ```
///
/// Parameters:
/// - info: ErrorInfo struct with all error details
///
/// Note: This function writes to stderr and never fails (ignores write errors)
pub fn reportError(info: ErrorInfo) void {
    var stdout_buffer: [4096]u8 = undefined;
    var stdout_writer = std.fs.File.stderr().writer(&stdout_buffer);
    const stderr = &stdout_writer.interface;

    // Print error location and message
    stderr.print("Error at line {d}, column {d}: {s}\n", .{ info.line, info.column, info.message }) catch {};

    // If source line available, show it with caret indicator
    if (info.source_line) |line| {
        stderr.print("  {s}\n", .{line}) catch {};

        // Print spaces to align caret with error column
        var i: usize = 0;
        while (i < info.column - 1) : (i += 1) {
            stderr.print(" ", .{}) catch {};
        }
        stderr.print("^\n", .{}) catch {};
    }

    stderr.flush() catch {};
}
