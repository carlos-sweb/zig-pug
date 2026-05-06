/// Token types for all lexical elements in Pug templates
///
/// The tokenizer's job is to recognize surface syntax only.
/// Semantic decisions (is this an attribute value? is this JS?) belong
/// to the parser, not here.
///
/// Categories:
///   Identifiers : tag names, attribute names, variable names, keywords
///   Literals    : strings (the tokenizer recognizes quotes, not types)
///   Structure   : indentation, newlines
///   Symbols     : punctuation and operators
///   Special     : interpolation, comments, code markers
pub const TokenType = enum {

    // -------------------------------------------------------------------------
    // Identifiers
    // The parser decides whether an Ident is a tag, attribute name,
    // variable, or keyword reference.
    // -------------------------------------------------------------------------
    Ident,
    Class,   // .classname  — tokenizer recognizes the dot+name pattern
    Id,      // #idname     — tokenizer recognizes the hash+name pattern

    // -------------------------------------------------------------------------
    // Literals
    // Only String is recognized at the tokenizer level (quote delimiters).
    // true, false, numbers are plain Ident — the parser decides their meaning.
    // -------------------------------------------------------------------------
    String,
    Text,    // plain text content after a tag — read until newline or interpolation

    // -------------------------------------------------------------------------
    // Symbols — punctuation
    // -------------------------------------------------------------------------
    LParen,   // (
    RParen,   // )
    LBracket, // [
    RBracket, // ]
    LBrace,   // {
    RBrace,   // }
    Dot,      // .  (when not followed by a class name)
    Hash,     // #  (when not followed by an id name)
    Comma,    // ,
    Colon,    // :
    Pipe,     // |

    // -------------------------------------------------------------------------
    // Operators
    // -------------------------------------------------------------------------
    Plus,         // +
    Minus,        // -
    Assign,       // =  (kept for parser compatibility)
    Greater,      // >
    Less,         // <
    GreaterEqual, // >=
    LessEqual,    // <=
    Equal,        // ==
    NotEqual,     // !=
    And,          // &&
    Or,           // ||
    Question,     // ?

    // -------------------------------------------------------------------------
    // Keywords — Pug control flow and template directives
    // Recognized by the tokenizer so the parser can branch without
    // re-examining string values.
    // -------------------------------------------------------------------------
    If,
    Else,
    Unless,
    Each,
    While,
    In,       // "each item in items"
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

    // -------------------------------------------------------------------------
    // Code markers
    // Signal to the parser that what follows is a JS expression.
    // -------------------------------------------------------------------------
    BufferedCode,   // =   (output escaped)
    UnescapedCode,  // !=  (output unescaped)

    // -------------------------------------------------------------------------
    // JS Statement
    // A complete JS declaration/statement introduced by a leading '-' at line
    // start. The '-' itself is consumed and NOT emitted — only the statement
    // body is returned as a single token to be passed raw to js_dostring().
    //
    // Example:
    //   - var name = "Claude"          → JsStatement("var name = \"Claude\"")
    //   - var fruits = ["a","b"];      → JsStatement("var fruits = [\"a\",\"b\"];")
    //   - var obj = {key: "val"};      → JsStatement("var obj = {key: \"val\"};")
    // -------------------------------------------------------------------------
    JsStatement,

    // -------------------------------------------------------------------------
    // Iterable
    // The expression that follows "in" in an each loop. Captured as a single
    // raw token to be evaluated by mujs at render time.
    //
    // Structure is always: Each + Ident(item) + In + Iterable(expr)
    //
    // Examples:
    //   each item in items          → Iterable("items")
    //   each item in [1,2,3]        → Iterable("[1,2,3]")
    //   each val in obj.values()    → Iterable("obj.values()")
    // -------------------------------------------------------------------------
    Iterable,

    // -------------------------------------------------------------------------
    // Interpolation
    // The tokenizer captures the entire expression inside #{ } or !{ }
    // and passes it as a single token to mujs.
    // -------------------------------------------------------------------------
    EscapedInterpol,   // #{...}
    UnescapedInterpol, // !{...}

    // -------------------------------------------------------------------------
    // Comments
    // -------------------------------------------------------------------------
    BufferedComment,   // // (rendered as HTML comment)
    UnbufferedComment, // //- (stripped from output)

    // -------------------------------------------------------------------------
    // Structure
    // -------------------------------------------------------------------------
    Indent,
    Dedent,
    Newline,

    Eof,
};
