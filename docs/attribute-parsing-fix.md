# Attribute Parsing Fix - Space-separated Attributes with Complex Expressions

**Status**: Fixed in v4.0.1
**Component**: Parser (`src/parser/attributes.zig`)
**Issue Type**: Bug Fix

## Problem Description

Prior to this fix, the attribute parser would fail when parsing space-separated attributes where the previous attribute's value contained a complex expression (string concatenation, ternary operators, etc.).

### Failing Examples

```pug
//- Failed: Space-separated after string concatenation
div(value="base"+vl name="prefix") Text

//- Failed: Space-separated after ternary operator
div(first=c ? "yes" : "no" second="static") Content

//- Worked: Comma-separated (workaround)
div(value="base"+vl,name="prefix") Text
```

### Error Message

```
Expected RParen, got BufferedCode at line X
Error: Parsing failed: error.UnexpectedToken
```

## Root Cause

The parser's expression parsing logic would incorrectly consume the next attribute's name as part of the current attribute's expression.

For example, when parsing:
```pug
div(first=c ? "yes" : "no" second="static")
```

The parser would:
1. Start parsing `first=c ? "yes" : "no"`
2. After consuming `"no"`, encounter the `Ident` token `second`
3. Incorrectly add `second` to the expression: `c ? "yes" : "no"second`
4. Advance to the next token (`=` / `BufferedCode`)
5. Fail because `=` is not a valid continuation of the expression

## Solution

### Implementation Strategy

The fix implements a **lookahead detection mechanism** with a **pending attribute queue**:

1. **Lookahead Detection**: When parsing an `Ident` token within an expression, check if the next token is `BufferedCode` (`=`)
2. **Pending Attribute**: If `Ident` + `=` detected, store the identifier as a "pending attribute name" instead of including it in the expression
3. **Tokenizer Synchronization**: Leave the current token at `BufferedCode` for proper synchronization
4. **Deferred Parsing**: After completing the current attribute, check for pending attribute and parse it immediately

### Code Changes

**File**: `src/parser/attributes.zig`

#### 1. Added Pending Attribute Variable (Line 27)

```zig
var pending_attr_name: ?[]const u8 = null;
```

#### 2. Enhanced Ident Handling in Expression Loops (Lines 142-159, 237-256, 352-371, 439-458, 547-566)

```zig
} else if (helpers.match(self, &.{.Ident})) {
    // Save the identifier value in case we need it for pending attribute
    const saved_ident_value = self.current.value;
    expr_str = try std.mem.concat(arena_allocator, u8, &[_][]const u8{ expr_str, self.current.value });
    is_expression = true;
    try helpers.advance(self);

    // Check if next token is BufferedCode (=), which means this Ident is a new attribute
    if (helpers.match(self, &.{.BufferedCode})) {
        // This Ident is the start of a new attribute, not part of the expression
        // Store it as pending and don't restore current (leave it as BufferedCode)
        pending_attr_name = saved_ident_value;
        // Remove the Ident we added to expr_str by recalculating without it
        expr_str = expr_str[0..(expr_str.len - saved_ident_value.len)];
        break;
    }

    // Check if next token is an operator that continues the expression
    if (!helpers.match(self, &.{.Plus, .Minus, .Dot, .LBracket, .Greater, .Less, .GreaterEqual, .LessEqual, .Equal, .And, .Or, .Question, .Colon})) {
        break;
    }
}
```

#### 3. Pending Attribute Parser (Lines 586-620)

```zig
// Check if there's a pending attribute from expression parsing
if (pending_attr_name) |pending_name| {
    // Current is BufferedCode (=), parse the value
    if (!helpers.match(self, &.{.BufferedCode})) {
        return error.UnexpectedToken;
    }
    try helpers.advance(self);

    // Parse the pending attribute's value (simplified - just handle common cases)
    var pending_value: ?[]const u8 = null;
    var pending_is_expression = false;

    if (helpers.match(self, &.{.String})) {
        const str_val = self.current.value;
        if (str_val.len >= 2 and str_val[0] == '"' and str_val[str_val.len - 1] == '"') {
            pending_value = str_val[1 .. str_val.len - 1];
        } else {
            pending_value = str_val;
        }
        try helpers.advance(self);
    } else if (helpers.match(self, &.{.Ident})) {
        pending_value = self.current.value;
        pending_is_expression = true;
        try helpers.advance(self);
    }

    try attributes.append(arena_allocator, .{
        .name = pending_name,
        .value = pending_value,
        .is_unescaped = false,
        .is_expression = pending_is_expression,
    });

    pending_attr_name = null;
}
```

## Test Cases

All the following test cases now pass:

### 1. String Concatenation with Space Separator

```pug
- var vl = "value"
div(value="base"+vl name="prefix") Text
```

**Output**: `<div value="basevalue" name="prefix">Text</div>`

### 2. Multiple Space-separated Attributes with Concatenation

```pug
- var a = "foo"
- var b = "bar"
div(first="pre"+a second="mid"+b) Text
```

**Output**: `<div first="prefoo" second="midbar">Text</div>`

### 3. Ternary Operator with Space-separated Attribute (String Value)

```pug
- var c = true
div(first=c ? "yes" : "no" second="static") Content
```

**Output**: `<div first="yes" second="static">Content</div>`

### 4. Ternary Operator with Space-separated Attribute (Identifier Value)

```pug
- var c = true
- var s = "static"
div(first=c ? "yes" : "no" second=s) Content
```

**Output**: `<div first="yes" second="static">Content</div>`

### 5. Comma-separated (Still Works)

```pug
- var vl = "value"
div(value="base"+vl,name="prefix") Text
```

**Output**: `<div value="basevalue" name="prefix">Text</div>`

## Technical Details

### Token Flow Example

For `div(first=c ? "yes" : "no" second="static")`:

```
Tokens:
1. Ident("div")
2. LParen
3. Ident("first")
4. Assign (=)
5. Ident("c")
6. Question (?)
7. String("yes")
8. Colon (:)
9. String("no")
10. Ident("second")  ← Previously consumed as part of expression
11. BufferedCode (=) ← Detection point
12. String("static")
13. RParen
```

**Before Fix**:
- Token 10 (`second`) was added to expression
- Token 11 (`=`) caused parser error

**After Fix**:
- Token 10 (`second`) triggers lookahead to token 11
- Detects `Ident` + `BufferedCode` pattern
- Stores `"second"` as pending attribute
- Current token stays at `BufferedCode` (token 11)
- After completing first attribute, pending attribute is parsed

### Operator List for Expression Continuation

The parser recognizes these operators as valid expression continuations:
- Arithmetic: `Plus`, `Minus`
- Property access: `Dot`, `LBracket`
- Comparison: `Greater`, `Less`, `GreaterEqual`, `LessEqual`, `Equal`
- Logical: `And`, `Or`
- Ternary: `Question`, `Colon`

## Backward Compatibility

This fix is **100% backward compatible**:
- All existing templates continue to work
- Comma-separated attributes still work as before
- No breaking changes to the API or syntax
- All existing tests pass without modification

## Related Files

- `src/parser/attributes.zig` - Main implementation
- `CHANGELOG.md` - Change log entry
- `docs/attribute-parsing-fix.es.md` - Spanish version of this document

## References

- Commit: `4b9ba9f` - Fix attribute parser to support space-separated attributes in expressions
- Pull Request: TBD
- Issue: TBD
