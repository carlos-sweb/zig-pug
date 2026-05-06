/// Tokenizer states
///
/// The tokenizer only needs to track three situations:
///
/// - Root  : start of a line — expects a tag, keyword, or comment
/// - Indent: currently measuring indentation at the start of a line
/// - Text  : reading plain text content after a tag
///
/// Everything else (attribute context, JS expressions, loop bodies)
/// is the parser's responsibility, not the tokenizer's.
pub const TokenizerState = enum {
    Root,
    Indent,
    Text,
};
