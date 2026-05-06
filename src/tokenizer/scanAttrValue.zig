//! Scan unquoted attribute value token
//!
//! ## Why this module exists
//!
//! In HTML all attribute values are strings — the browser interprets "100"
//! as a number when needed. Zig-pug does not perform arithmetic on those
//! values; it writes them directly into the HTML or passes them to mujs
//! for JS evaluation.
//!
//! For that reason there is no point in classifying `100` as `.Number`
//! inside an attribute. This module captures them as `.AttrValue` (plain
//! text) without attempting any interpretation.
//!
//! ## What it reads
//!
//! Reads characters until an attribute delimiter is found:
//!   )        →  end of attribute list
//!   ,        →  next attribute
//!   space / tab  →  attribute separator without comma
//!   \n       →  end of line
//!   EOF      →  end of source
//!
//! Everything between the `=` and one of those delimiters is the value,
//! regardless of whether it contains digits, dots, letters or hyphens.
//!
//! ## Examples
//!
//! ```
//! input(value=100)         →  AttrValue("100")
//! input(step=0.5)          →  AttrValue("0.5")
//! div(data-v=3.x.y)        →  AttrValue("3.x.y")
//! input(min=50 max=150)    →  AttrValue("50")  AttrValue("150")
//! input(disabled=true)     →  AttrValue("true")
//! ```
//!
//! ## What it does NOT handle
//!
//! - Quoted strings: `value="hello"` → handled by `scanString`
//! - Interpolation: `value=#{expr}` → handled by `scanInterpolation`
//!   (intercepted before reaching this module in `mod.zig`)

const Token = @import("Token.zig").Token;
const TokenType = @import("TokenType.zig").TokenType;
const TokenizerState = @import("TokenizerState.zig").TokenizerState;

pub fn scanAttrValue(tokenizer: anytype) !Token {
    const start = tokenizer.pos;
    const start_line = tokenizer.line;
    const start_col = tokenizer.column;

    while (tokenizer.peekChar()) |ch| {
        switch (ch) {
            // Delimiters: stop without consuming
            ')', ',', ' ', '\t', '\n' => break,
            else => _ = tokenizer.advance(),
        }
    }

    const value = tokenizer.source[start..tokenizer.pos];

    // After reading the value return to AttrName so the next token
    // can be another attribute name, a comma, or the closing )
    tokenizer.state = .AttrName;

    return Token.init(.AttrValue, value, start_line, start_col);
}
