//! Text and Interpolation Nodes
//!
//! Represents text content and JavaScript interpolation expressions.

/// Plain text content node
///
/// Represents text that should be output as-is (with HTML escaping unless raw).
///
/// Fields:
/// - content: The text content
/// - is_raw: If true, from pipe (|) and HTML entities not escaped
///
/// Example:
/// ```zpug
/// p Hello world         // TextNode{content="Hello world", is_raw=false}
/// | <strong>Bold</strong>  // TextNode{content="<strong>...", is_raw=true}
/// ```
pub const TextNode = struct {
    content: []const u8,
    is_raw: bool, // For pipe | text (no HTML escaping)
};

/// Interpolation node for #{...} and !{...}
///
/// Represents a JavaScript expression to be evaluated and inserted into output.
///
/// Fields:
/// - expression: The JS code to evaluate (e.g., "name", "user.email", "items.length")
/// - is_unescaped: If true (!{...}), don't HTML-escape the result
///
/// Examples:
/// ```zpug
/// p Hello #{name}              // {expression="name", is_unescaped=false}
/// p Count: #{items.length}     // {expression="items.length", is_unescaped=false}
/// div!{htmlContent}            // {expression="htmlContent", is_unescaped=true}
/// ```
pub const InterpolationNode = struct {
    expression: []const u8,
    is_unescaped: bool,
};
