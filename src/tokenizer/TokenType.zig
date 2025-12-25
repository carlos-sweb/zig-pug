/// Token types representing all possible lexical elements in Pug templates
///
/// Tokens are organized into categories:
/// - Identifiers: Tag names, variable names
/// - Literals: Strings, numbers, booleans
/// - Symbols: Parentheses, brackets, punctuation
/// - Keywords: Control flow (if, each, mixin, etc.)
/// - Special: Indentation, comments, code markers
///
/// Example token types for "div.container#main":
/// - Ident("div")
/// - Class("container")  // .container as single token
/// - Id("main")         // #main as single token
pub const TokenType = enum {
    // Identificadores
    Ident,
    Class, // .classname
    Id, // #idname

    // Literales
    String,
    Number,
    Boolean,

    // Símbolos
    LParen, // (
    RParen, // )
    LBracket, // [
    RBracket, // ]
    LBrace, // {
    RBrace, // }
    Dot, // .
    Hash, // #
    Comma, // ,
    Colon, // :
    Pipe, // |

    // Operadores
    Assign, // =
    NotEqual, // !=
    Plus, // +
    Minus, // -
    Greater, // >
    Less, // <
    GreaterEqual, // >=
    LessEqual, // <=
    Equal, // ==
    And, // &&
    Or, // ||
    Question, // ? (ternary operator)

    // Keywords
    If,
    Else,
    Unless,
    Each,
    While,
    In, // for "each item in items"
    Case,
    When,
    Default,
    Mixin,
    Include,
    Extends,
    Block,
    Append,
    Prepend,
    Doctype,

    // Especiales
    Indent,
    Dedent,
    Newline,
    BufferedComment, // //
    UnbufferedComment, // //-
    BufferedCode, // =
    UnbufferedCode, // -
    UnescapedCode, // !=
    EscapedInterpol, // #{...}
    UnescapedInterpol, // !{...}

    Eof,
};
