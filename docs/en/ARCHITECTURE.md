# Architecture: How zig-pug Evaluates Conditionals

## Overview

zig-pug uses a **two-phase architecture** for evaluating conditional expressions:

1. **Tokenizer/Parser** (Zig) - Recognize and reconstruct JavaScript expressions
2. **mujs** (C) - Evaluate JavaScript expressions

This separation of concerns is intentional and provides significant advantages.

## The Two-Phase Approach

### Phase 1: Tokenizer/Parser (Recognition)

**Responsibility:** Convert Pug syntax into JavaScript expressions as strings

**What it does:**
- Recognizes operators as tokens (`>=`, `&&`, `||`, etc.)
- Concatenates tokens to form valid JavaScript
- Adds dots for property access (`.length`, `.isPremium`)
- Adds quotes for string literals (`"active"`)
- **Does NOT evaluate** anything

**Example:**

```pug
if age >= 18 && hasLicense
  p Can drive
```

**Tokenizer generates:**
```
Ident("age") → GreaterEqual(">=") → Number("18") → And("&&") → Ident("hasLicense")
```

**Parser reconstructs:**
```
String: "age>=18&&hasLicense"
```

**Code:** `src/parser/conditionals.zig` lines 30-51

### Phase 2: mujs (Evaluation)

**Responsibility:** Evaluate JavaScript expressions and return results

**What it does:**
- Parses the JavaScript expression
- Evaluates operators (`>=`, `&&`, `||`, `==`, etc.)
- Accesses object properties (`user.isPremium`, `array.length`)
- Calls methods (`name.toUpperCase()`)
- Returns the result as a string

**Example:**

```javascript
// Receives: "age>=18&&hasLicense"
// Variables: { age: 25, hasLicense: true }
// Evaluates: 25 >= 18 && true
// Returns: "true"
```

**Code:** `src/compiler.zig` line 672

## Why This Architecture?

### ✅ Advantages

**1. Separation of Concerns**
- Parser focuses on Pug syntax
- mujs handles JavaScript semantics
- Each component has a single, clear responsibility

**2. Complete JavaScript Support**
- Any ES5.1 expression works automatically
- No need to implement JavaScript evaluation in Zig
- Methods, functions, ternary operator, etc. all work

**3. Simplicity**
- Parser just concatenates strings (very simple code)
- No complex expression evaluation logic needed
- Easy to understand and maintain

**4. Reliability**
- mujs is a proven, tested JavaScript engine
- We don't reinvent JavaScript evaluation
- Fewer bugs in expression handling

**5. Performance**
- String concatenation is extremely fast
- mujs is optimized C code
- No overhead from Zig-based evaluation

**6. Compatibility**
- Same approach as Pug.js (delegates to V8/Node.js)
- Consistent behavior with the original

### ❌ Alternative NOT Used: Evaluate in Parser

If we evaluated expressions in the parser, we would need to:

```zig
// Hypothetical - NOT IMPLEMENTED
fn evaluateCondition(tokens: []Token, variables: Variables) bool {
    // Would need to implement:
    // - Operator precedence
    // - Type conversion
    // - Property access
    // - Method calls
    // - And much more...

    // This would be reimplementing a JavaScript engine in Zig!
}
```

**Problems:**
- 🔴 Duplicate mujs functionality
- 🔴 Maintain two implementations in sync
- 🔴 Bugs in evaluation logic
- 🔴 No support for methods, functions, etc.
- 🔴 More complex code
- 🔴 Slower development

## Complete Flow Example

### Input Template

```pug
if (isAdmin || isModerator) && user.isActive
  p Access granted
else
  p Access denied
```

### Step-by-Step Processing

**1. Tokenizer** (src/tokenizer.zig)

```
LParen("(")
Ident("isAdmin")
Or("||")
Ident("isModerator")
RParen(")")
And("&&")
Ident("user")
.Id("isActive")
```

**2. Parser** (src/parser/conditionals.zig)

```
Reconstructed: "(isAdmin||isModerator)&&user.isActive"
                                           ↑
                            Added dot for .Id token
```

**3. Compiler** (src/compiler.zig)

```zig
const result = self.runtime.eval("(isAdmin||isModerator)&&user.isActive");
// result = "true" or "false"
```

**4. mujs Evaluation**

```javascript
// Variables in context:
// isAdmin = false
// isModerator = true
// user = { isActive: true }

// Evaluates:
(false || true) && true
= true && true
= true

// Returns: "true"
```

**5. Compiler Decision**

```zig
const is_true = !std.mem.eql(u8, result, "false") and
    !std.mem.eql(u8, result, "null") and
    !std.mem.eql(u8, result, "undefined") and
    !std.mem.eql(u8, result, "0") and
    result.len > 0;

// is_true = true
// Executes "then" branch: <p>Access granted</p>
```

## Responsibility Matrix

| Component | Recognizes Operators | Understands Semantics | Evaluates Expressions |
|-----------|---------------------|----------------------|----------------------|
| **Tokenizer** | ✅ Yes (as tokens) | ❌ No | ❌ No |
| **Parser** | ✅ Yes (rebuilds) | ❌ No | ❌ No |
| **Compiler** | N/A | ❌ No | ❌ No (delegates) |
| **mujs** | N/A | ✅ Yes | ✅ Yes |

## Special Handling in Parser

The parser performs minimal transformations to ensure valid JavaScript:

### 1. Property Access (dots)

**Tokenizer:** `.Class` and `.Id` tokens have the dot removed from `value`

**Parser:** Adds the dot back when concatenating

```pug
if array.length > 0
```

```
Tokenizer: Ident("array"), .Class("length"), Greater(">"), Number("0")
                              ↑ value is "length", NOT ".length"

Parser: "array.length>0"
              ↑ Dot added by parser
```

**Code:**
```zig
if (self.current.type == .Class or self.current.type == .Id) {
    try condition.append(arena_allocator, '.');
}
```

### 2. String Literals (quotes)

**Tokenizer:** `.String` tokens have quotes removed from `value`

**Parser:** Adds quotes back when concatenating

```pug
if status == "active"
```

```
Tokenizer: Ident("status"), Equal("=="), .String("active")
                                           ↑ value is "active", NOT "\"active\""

Parser: "status==\"active\""
                ↑        ↑ Quotes added by parser
```

**Code:**
```zig
else if (self.current.type == .String) {
    try condition.append(arena_allocator, '"');
    try condition.appendSlice(arena_allocator, self.current.value);
    try condition.append(arena_allocator, '"');
    try helpers.advance(self);
    continue;
}
```

### 3. No Spaces Between Tokens

**Previous bug:** Parser added spaces between all tokens

```
Bad: "array . length > 0"  // SyntaxError in JavaScript
Good: "array.length>0"     // Valid JavaScript
```

**Current implementation:** No spaces inserted (JavaScript doesn't require them)

```zig
// Simply concatenate token values
try condition.appendSlice(arena_allocator, self.current.value);
```

## Comparison with Pug.js

| Aspect | Pug.js | zig-pug |
|--------|--------|---------|
| Parser role | Recognizes syntax | Recognizes syntax |
| Evaluator | V8 / Node.js | mujs |
| Architecture | Two-phase | Two-phase |
| Expressions | Full JavaScript | ES5.1 JavaScript |
| Approach | ✅ Same strategy | ✅ Same strategy |

zig-pug follows the **exact same architectural pattern** as Pug.js:
- Parser handles template syntax
- JavaScript engine handles expression evaluation

## Trade-offs

### ✅ Pros

1. **Simple parser code** - Just string concatenation
2. **Complete JS support** - Everything mujs supports works
3. **Proven reliability** - mujs is battle-tested
4. **Easy maintenance** - Changes in JS don't affect parser
5. **Good performance** - Minimal overhead

### ⚠️ Cons

1. **mujs dependency** - Can't easily swap JavaScript engines
2. **Error messages** - Come from mujs, not always clear for templates
3. **Debugging** - Harder to trace expression evaluation

### 🎯 Conclusion

The pros **significantly outweigh** the cons. This is the correct architecture for a template engine.

## Related Documentation

- [Conditional Syntax](PUG-SYNTAX.md#conditionals) - User-facing conditional documentation
- [API Reference](API-REFERENCE.md) - How to set variables for conditionals
- [Examples](../../examples/06-conditionals-advanced.zpug) - Real-world conditional examples

## Source Code References

- `src/tokenizer.zig` - Token recognition (lines 778-833)
- `src/parser/conditionals.zig` - Expression reconstruction (lines 30-51)
- `src/compiler.zig` - Expression evaluation via mujs (lines 668-701)
- `src/runtime.zig` - mujs integration and evaluation
