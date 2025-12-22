const TokenType = @import("./TokenType.zig").TokenType;
/// A single token with its type, value, and source location
///
/// Represents a lexical unit extracted from the source code.
/// Contains all information needed for parsing and error reporting.
///
/// Fields:
/// - type: The kind of token (see TokenType)
/// - value: The actual text from the source (empty for symbols like INDENT)
/// - line: 1-indexed line number where token starts
/// - column: 1-indexed column number where token starts
///
/// Example:
/// ```zig
/// const token = Token.init(.Ident, "div", 5, 3);
/// // Represents identifier "div" at line 5, column 3
/// ```
pub const Token = struct {
    type: TokenType,
    value: []const u8,
    line: usize,
    column: usize,

    /// Create a new token
    ///
    /// Parameters:
    /// - token_type: Type of token
    /// - value: Text content (slice from source)
    /// - line: Source line number (1-indexed)
    /// - column: Source column number (1-indexed)
    ///
    /// Returns: Initialized token
    ///
    /// Example:
    /// ```zig
    /// const comment = Token.init(.BufferedComment, "TODO: fix this", 10, 1);
    /// ```
    pub fn init(token_type: TokenType, value: []const u8, line: usize, column: usize) Token {
        return .{
            .type = token_type,
            .value = value,
            .line = line,
            .column = column,
        };
    }
};
