//! Code and Comment Nodes
//!
//! Represents JavaScript code blocks and HTML/code comments.

/// Code node for =, !=, and - markers
///
/// Represents JavaScript code to be executed or evaluated.
///
/// Fields:
/// - code: JavaScript code string
/// - is_buffered: If true, output the result (= or !=)
/// - is_unescaped: If true, don't HTML-escape output (!=)
///
/// Examples:
/// ```zpug
/// = user.name          // {code="user.name", is_buffered=true, is_unescaped=false}
/// != rawHtml           // {code="rawHtml", is_buffered=true, is_unescaped=true}
/// - var x = 10         // {code="var x = 10", is_buffered=false, is_unescaped=false}
/// ```
pub const CodeNode = struct {
    code: []const u8,
    is_buffered: bool,
    is_unescaped: bool,
};

/// Comment node for // and //-
///
/// Represents HTML comments or code comments.
///
/// Fields:
/// - content: Comment text
/// - is_buffered: If true (//), emitted as HTML comment; if false (//-), not included
///
/// Examples:
/// ```zpug
/// // This appears in HTML       // {content="...", is_buffered=true}
/// //- This is for developers    // {content="...", is_buffered=false}
/// ```
pub const CommentNode = struct {
    content: []const u8,
    is_buffered: bool,
};
