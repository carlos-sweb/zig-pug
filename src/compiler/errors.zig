//! Compiler Error Types
//!
//! Error handling structures for structured compilation error reporting.

const std = @import("std");

/// Error type classification for structured error reporting
pub const ErrorType = enum {
    LoopIterableEvalFailed,
    ConditionalEvalFailed,
    InterpolationEvalFailed,
    AttributeEvalFailed,
    CodeExecutionFailed,
    CaseEvalFailed,
    MixinNotFound,
    IncludeFileNotFound,
    IncludeParseError,
    ExtendsFileNotFound,
    ExtendsParseError,
};

/// Structured compilation error with details for consumer presentation
///
/// Provides detailed error information that can be presented to users
/// or consumed by tools.
///
/// Fields:
/// - type: Error category
/// - line: Source line number where error occurred
/// - message: Human-readable error description (null-terminated for C API)
/// - detail: Optional additional context (e.g., "Iterable: users")
/// - hint: Optional suggestion for fixing the error
pub const CompilationError = struct {
    type: ErrorType,
    line: usize,
    message: [:0]const u8,  // Null-terminated for C API compatibility
    detail: ?[:0]const u8,  // e.g., "Iterable: users" or "Condition: x > 0"
    hint: ?[:0]const u8,    // e.g., "Make sure the variable is defined"

    /// Free error message strings
    pub fn deinit(self: *CompilationError, allocator: std.mem.Allocator) void {
        allocator.free(self.message);
        if (self.detail) |d| allocator.free(d);
        if (self.hint) |h| allocator.free(h);
    }
};

/// Errors that can occur during compilation
///
/// - OutOfMemory: Allocation failed
/// - CompilationFailed: Compilation errors occurred (check errors list)
/// - RuntimeError: JavaScript evaluation error
/// - InvalidNode: Malformed AST node
/// - MixinNotFound: Called undefined mixin
/// - IncludeFileNotFound: Include file doesn't exist
/// - IncludeParseError: Include file has syntax errors
/// - LoopIterableNotArray: Loop target isn't an array
/// - ExtendsFileNotFound: Parent template doesn't exist
/// - ExtendsParseError: Parent template has syntax errors
pub const CompilerError = error{
    OutOfMemory,
    CompilationFailed,
    RuntimeError,
    InvalidNode,
    MixinNotFound,
    IncludeFileNotFound,
    IncludeParseError,
    LoopIterableNotArray,
    ExtendsFileNotFound,
    ExtendsParseError,
};
