/// Errors that can occur during tokenization
///
/// These represent lexical errors in the source code:
/// - UnexpectedCharacter: Invalid character for current context
/// - UnterminatedString: String literal missing closing quote
/// - InvalidNumber: Malformed numeric literal
/// - OutOfMemory: Allocation failure
pub const TokenizerError = error{
    UnexpectedCharacter,
    UnterminatedString,
    InvalidNumber,
    OutOfMemory,
};
