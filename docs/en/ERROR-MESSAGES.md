# Error Messages and Debugging

Complete guide to understanding and resolving zig-pug errors.

## Table of Contents

- [Error Types](#error-types)
- [Common Errors](#common-errors)
- [Debugging Strategies](#debugging-strategies)
- [Error Handling](#error-handling)

## Error Types

### Tokenizer Errors

Errors during lexical analysis (tokenization).

#### InvalidIndentation

**Error:**
```
InvalidIndentation: Mixed tabs and spaces or inconsistent indentation
```

**Cause:** Using tabs instead of spaces, or inconsistent indentation levels.

**Example:**
```pug
div
  p Line 1
	p Line 2  // Tab character - ERROR!
```

**Solution:**
```pug
div
  p Line 1
  p Line 2  // Use spaces consistently
```

#### UnterminatedString

**Error:**
```
UnterminatedString: String not closed
```

**Cause:** Missing closing quote in string.

**Example:**
```pug
p(title="Hello World) Text  // Missing closing "
```

**Solution:**
```pug
p(title="Hello World") Text
```

#### UnexpectedCharacter

**Error:**
```
UnexpectedCharacter: Invalid character in context
```

**Cause:** Character not allowed in current context.

**Example:**
```pug
p @invalid
```

**Solution:**
Check syntax - ensure special characters are properly escaped or in correct context.

### Parser Errors

Errors during syntax analysis (parsing).

#### UnexpectedToken

**Error:**
```
UnexpectedToken: Expected 'RParen' but got 'Newline'
```

**Cause:** Missing closing parenthesis or brace.

**Example:**
```pug
div(class="container"
  p Content  // Missing ) - ERROR!
```

**Solution:**
```pug
div(class="container")
  p Content
```

#### ExpectedToken

**Error:**
```
ExpectedToken: Expected 'Ident' after 'each'
```

**Cause:** Incorrect syntax structure.

**Example:**
```pug
each in items  // Missing variable name - ERROR!
  li Item
```

**Solution:**
```pug
each item in items
  li= item
```

### Compiler Errors

Errors during HTML generation.

#### UndefinedVariable

**Error:**
```
ReferenceError: identifier 'userName' not defined
```

**Cause:** Variable not set before use.

**Example:**
```pug
p Hello #{userName}!
```

**Solution:**
```bash
# CLI
zpug template.zpug --var userName=Alice

# Node.js
compiler.setString('userName', 'Alice');
```

#### TypeError

**Error:**
```
TypeError: Cannot read property 'name' of undefined
```

**Cause:** Accessing property of undefined/null value.

**Example:**
```pug
p Name: #{user.name}
// Error if user is undefined
```

**Solution:**
```pug
// Provide default
p Name: #{user && user.name ? user.name : "Unknown"}

// Or validate
- if (!user) throw new Error("user is required")
p Name: #{user.name}
```

## Common Errors

### 1. Indentation Errors

**Problem:**
```pug
div
  p Line 1
    p Line 2  // Extra indent - ERROR!
```

**Error:**
```
UnexpectedIndent: Indentation increased without nesting
```

**Solution:**
Use consistent indentation (2 or 4 spaces per level):
```pug
div
  p Line 1
  p Line 2
```

### 2. Missing Parentheses

**Problem:**
```pug
a href="/home" Home  // Missing () - ERROR!
```

**Error:**
```
UnexpectedToken: Expected 'LParen' for attributes
```

**Solution:**
```pug
a(href="/home") Home
```

### 3. Undefined Variables

**Problem:**
```pug
p Hello #{name}!
```

**Error:**
```
ReferenceError: identifier 'name' not defined
```

**Solution:**
```bash
zpug template.zpug --var name=Alice
```

Or in template:
```pug
- var name = name || "Guest"
p Hello #{name}!
```

### 4. Type Errors

**Problem:**
```pug
p #{items.length}
```

**Error:**
```
TypeError: Cannot read property 'length' of undefined
```

**Solution:**
```pug
- items = items || []
p #{items.length}
```

Or:
```pug
p #{items ? items.length : 0}
```

### 5. Syntax Errors in Expressions

**Problem:**
```pug
p #{name.toUpperCase(}  // Missing ) - ERROR!
```

**Error:**
```
SyntaxError: Unexpected token
```

**Solution:**
```pug
p #{name.toUpperCase()}
```

### 6. Loop Errors

**Problem:**
```pug
each item items  // Missing 'in' - ERROR!
  p= item
```

**Error:**
```
ExpectedToken: Expected 'In' keyword
```

**Solution:**
```pug
each item in items
  p= item
```

### 7. Mixin Errors

**Problem:**
```pug
mixin greeting
  p Hello!

+greeting("Alice")  // Mixin doesn't expect arguments - ERROR!
```

**Error:**
```
Error: Too many arguments
```

**Solution:**
```pug
mixin greeting(name)
  p Hello #{name}!

+greeting("Alice")
```

### 8. Include Errors

**Problem:**
```pug
include header.zpug  // File doesn't exist - ERROR!
```

**Error:**
```
FileNotFound: Cannot find 'header.zpug'
```

**Solution:**
- Check file path is correct
- Use relative or absolute paths
- Ensure file exists

### 9. Comment Errors

**Problem:**
```pug
//! This should be before doctype
doctype html  // ERROR if //! appears after
```

**Error:**
```
UnexpectedToken: Documentation comments must appear before doctype
```

**Solution:**
```pug
//! Documentation comment
doctype html
```

### 10. Special Character Errors

**Problem:**
```pug
p #{text.split('@').join('')}  // @ may cause issues
```

**Error:**
Depends on context.

**Solution:**
Escape special characters or use different approach:
```pug
- var cleaned = text.replace(/@/g, '')
p #{cleaned}
```

## Debugging Strategies

### 1. Check Line Numbers

Errors include line and column information:

```
Error at line 15, column 8:
UnexpectedToken: Expected 'RParen' but got 'Newline'
```

Open template and go to line 15, column 8.

### 2. Isolate the Problem

Comment out sections to find the error:

```pug
div
  //- p Line 1
  //- p Line 2
  p Line 3  // Test this line
```

### 3. Validate Variables

```pug
// At top of template
- if (typeof userName == "undefined") throw new Error("userName is undefined")
- if (typeof items == "undefined") throw new Error("items is undefined")
```

### 4. Use Default Values

```pug
- userName = userName || "Guest"
- items = items || []
- config = config || {}
```

### 5. Add Debug Output

```pug
- console.log("userName:", userName)
- console.log("items:", items)
```

Or in HTML:
```pug
//- Debug info
p Debug: userName = #{typeof userName}
p Debug: items.length = #{items ? items.length : "undefined"}
```

### 6. Test in Isolation

Create minimal test case:

```pug
// test.zpug
p #{userName}
```

```bash
zpug test.zpug --var userName=Test
```

### 7. Check Documentation

Refer to relevant documentation:
- [SYNTAX-BASICS.md](SYNTAX-BASICS.md) - Basic syntax
- [SYNTAX-ADVANCED.md](SYNTAX-ADVANCED.md) - Advanced features
- [JAVASCRIPT.md](JAVASCRIPT.md) - JavaScript expressions

## Error Handling

### In Templates

**Validate inputs:**
```pug
- if (!user) throw new Error("user is required")
- if (!user.name) throw new Error("user.name is required")
- if (typeof items != "object") throw new Error("items must be array")
```

**Provide defaults:**
```pug
- title = title || "Untitled"
- description = description || "No description"
- items = items || []
```

**Graceful degradation:**
```pug
if user && user.name
  p Hello #{user.name}!
else
  p Hello Guest!
```

### In Node.js

**Try-catch:**
```javascript
const { PugCompiler } = require('zig-pug');

try {
    const compiler = new PugCompiler();
    compiler.setString('name', 'Alice');
    const html = compiler.compile(template);
    console.log(html);
} catch (error) {
    console.error('Compilation failed:', error.message);

    if (error.compilationErrors) {
        error.compilationErrors.errors.forEach(err => {
            console.error(`  Line ${err.line}: ${err.message}`);
            if (err.hint) console.error(`  Hint: ${err.hint}`);
        });
    }
}
```

**Error details:**
```javascript
catch (error) {
    // error.message - Main error message
    // error.compilationErrors - Structured errors
    // error.compilationErrors.errorCount - Number of errors
    // error.compilationErrors.errors[] - Array of errors
    //   .line - Line number
    //   .message - Error message
    //   .detail - Additional details
    //   .hint - Suggested fix
    //   .errorType - Error classification
}
```

### In Production

**Log errors:**
```javascript
app.get('/page', (req, res) => {
    try {
        const html = compiler.compile(template, data);
        res.send(html);
    } catch (error) {
        console.error('Template compilation error:', error);

        // Send user-friendly error
        res.status(500).send('Internal Server Error');
    }
});
```

**Fallback template:**
```javascript
const errorTemplate = 'p An error occurred. Please try again later.';

app.get('/page', (req, res) => {
    try {
        const html = compiler.compile(template, data);
        res.send(html);
    } catch (error) {
        console.error(error);
        const fallback = compiler.compile(errorTemplate);
        res.status(500).send(fallback);
    }
});
```

## Error Prevention

### 1. Validate Data

```javascript
function validateUser(user) {
    if (!user) throw new Error('User is required');
    if (!user.name) throw new Error('User name is required');
    if (typeof user.age !== 'number') throw new Error('User age must be number');
    return true;
}

validateUser(data.user);
compiler.setObject('user', data.user);
```

### 2. Use TypeScript

```typescript
interface User {
    name: string;
    age: number;
    email: string;
}

const user: User = {
    name: 'Alice',
    age: 30,
    email: 'alice@example.com'
};

compiler.setObject('user', user);
```

### 3. Lint Templates

Check templates for common issues:

```bash
# Check all templates
find templates -name "*.pug" -exec zpug {} \; > /dev/null
```

### 4. Use Defaults

```pug
//! Default values for optional variables
- title = title || "Untitled"
- description = description || ""
- items = items || []
- user = user || {}
```

### 5. Document Requirements

```pug
//! Required variables:
//!   - title: string
//!   - user: {name: string, email: string}
//! Optional variables:
//!   - description: string (default: "")
//!   - items: array (default: [])
```

## Getting Help

If you encounter an error you can't resolve:

1. **Check documentation** - Search for error message
2. **Check examples** - See working examples in `examples/`
3. **Run tests** - Verify installation with `zig build test`
4. **Create minimal reproduction** - Isolate the problem
5. **Report issue** - [GitHub Issues](https://github.com/carlos-sweb/zig-pug/issues)

**Include in issue:**
- Error message (full output)
- Template code (minimal example)
- zig-pug version (`zpug --version`)
- Zig version (`zig version`)
- OS and version
- Steps to reproduce

## See Also

- [CONTRIBUTING.md](../../CONTRIBUTING.md) - Contributing guidelines
- [SYNTAX-BASICS.md](SYNTAX-BASICS.md) - Basic syntax
- [TESTS.md](TESTS.md) - Testing guide
- [../GETTING-STARTED.md](../GETTING-STARTED.md) - Getting started
