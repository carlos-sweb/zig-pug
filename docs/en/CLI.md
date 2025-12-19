# zpug CLI - Command Line Interface

Command-line interface for compiling Pug templates to HTML.

## Installation

### Build from Source

```bash
git clone https://github.com/carlos-sweb/zig-pug
cd zig-pug
zig build
```

The compiled binary will be in `zig-out/bin/zpug`.

### Install Globally

```bash
# Linux/macOS
sudo cp zig-out/bin/zpug /usr/local/bin/

# Or use Make
make install
```

## Basic Usage

### Compile to Stdout

```bash
zpug template.zpug
```

### Compile with Output File

```bash
zpug -i template.zpug -o output.html
```

### Compile Multiple Files

```bash
zpug -i template1.zpug -i template2.zpug -o dist/
```

## CLI Versions

zpug has two CLI versions:

### 1. Simple CLI (Current Default - `src/main.zig`)

**Features**:
- Basic template compilation
- Works on all platforms including Termux/Android
- Minimal dependencies
- No external libc requirements

**Limitations**:
- No command-line variable setting
- No pretty-print/minify options
- No file watching

**Usage**:
```bash
# Compile and output to stdout
zpug

# Uses hard-coded template in main.zig
```

This version is automatically built with `zig build`.

### 2. Full-Featured CLI (`src/cli.zig`)

**Features**:
- Multiple input files
- Output to file or directory
- Variable setting via `--var` and `--vars`
- Pretty-print HTML output
- Minify HTML output
- Stdin/stdout support
- Verbose and silent modes
- File watching (planned)

**Requirements**:
- Full libc available (glibc, musl, etc.)
- Not available in Termux/Android (libc detection issues)

**Building**:
```bash
# On Linux with glibc/musl
zig build -Droot_source_file=src/cli.zig

# On macOS
zig build -Droot_source_file=src/cli.zig

# On Windows
zig build -Droot_source_file=src/cli.zig
```

## Full CLI Reference

*Note: The following commands are for the full-featured CLI (`src/cli.zig`)*

### Options

```
-h, --help              Show help message
-v, --version           Show version information
-i, --input <file>      Input .zpug file (can be used multiple times)
-o, --output <path>     Output file or directory
-w, --watch             Watch files for changes and recompile
-p, --pretty            Pretty-print with comments (development mode)
-F, --format            Pretty-print without comments (readable mode)
-m, --minify            Minify HTML output (production mode)
--stdin                 Read input from stdin
--stdout                Write output to stdout
-s, --silent            Suppress all output except errors
-V, --verbose           Verbose output with compilation details
-f, --force             Overwrite output files without asking
```

### Variables

```
--var <key>=<value>            Set simple variable (string/number/boolean)
--array <key>=<val1>,<val2>    Set array from CSV values
--json <key>=<json>            Set variable from JSON string
--vars <file.json>             Load all variables from JSON file
```

**Variable Types:**

**Simple values** (`--var`, auto-detected):
- Numbers: `--var count=42` `--var price=19.99`
- Booleans: `--var active=true` `--var debug=false`
- Strings: `--var name=Alice` `--var title="My Page"`

**Arrays** (`--array`, CSV format):
- String arrays: `--array items=apple,banana,orange`
- Number arrays: `--array scores=95,87,92,88.5`
- Auto type detection: numbers vs strings

**Complex data** (`--json`, JSON format):
- JSON objects: `--json user='{"name":"Alice","age":30}'`
- JSON arrays: `--json items='["apple","banana"]'`
- Nested structures: `--json data='{"user":{"name":"Alice"}}'`
- All JSON types: string, number, boolean, null, array, object

### Examples

#### Basic Compilation

```bash
# Compile single file to stdout
zpug template.zpug

# Compile with output file
zpug -i template.zpug -o output.html

# Compile multiple files to directory
zpug -i *.zpug -o dist/
```

#### Using Variables

**Simple variables:**
```bash
# Set variables via command line
zpug template.zpug --var name=Alice --var age=25 --var active=true
```

**Arrays (CSV format):**
```bash
# String arrays
zpug template.zpug --array fruits=apple,banana,orange,mango

# Number arrays (auto-detected)
zpug template.zpug --array scores=95,87,92,88.5

# Multiple arrays
zpug template.zpug \
  --array tags=production,stable,v2 \
  --array scores=95,87,92
```

**JSON objects:**
```bash
# Simple object
zpug template.zpug --json user='{"name":"Alice","age":30}'

# Complex nested object
zpug template.zpug --json user='{"name":"Alice","email":"alice@example.com","age":30,"role":"Developer","location":"San Francisco"}'

# Multiple objects
zpug template.zpug \
  --json user='{"name":"Alice","role":"admin"}' \
  --json stats='{"views":1500,"likes":89}'
```

**JSON arrays:**
```bash
# Simple JSON array
zpug template.zpug --json items='["apple","banana","orange"]'

# Array of numbers
zpug template.zpug --json scores='[95,87,92,88.5]'
```

**Mix all types:**
```bash
# Combine --var, --array, and --json
zpug template.zpug \
  --var title="Admin Dashboard" \
  --var version=2.5 \
  --array tags=production,stable,v2 \
  --json user='{"name":"Carlos","role":"Admin"}' \
  --json stats='{"views":1500}' \
  --pretty
```

**Load from JSON file:**
```bash
# Load variables from JSON file
zpug template.zpug --vars data.json -o output.html
```

**data.json**:
```json
{
  "name": "Alice",
  "age": 25,
  "active": true,
  "items": ["apple", "banana", "orange"],
  "user": {
    "name": "Bob",
    "email": "bob@example.com"
  }
}
```

#### Pretty-Print Output (Development Mode)

```bash
# Pretty-print with indentation and comments
zpug -p template.zpug -o dev.html
```

**Features:**
- HTML indentation for readability
- **Includes buffered comments** (`//`) for debugging
- Ideal for development and inspection

**Output**:
```html
<!-- Page header -->
<div class="container">
  <h1>Hello World</h1>
  <p>Welcome</p>
</div>
```

#### Format Output (Readable Mode)

```bash
# Pretty-print without comments
zpug -F template.zpug -o readable.html
```

**Features:**
- HTML indentation for readability
- **No comments** for cleaner output
- Ideal for code reviews and readable production

**Output**:
```html
<div class="container">
  <h1>Hello World</h1>
  <p>Welcome</p>
</div>
```

#### Minify Output (Production Mode)

```bash
# Minify (remove whitespace and comments)
zpug -m template.zpug -o minified.html

# Or default mode (same as minify)
zpug template.zpug -o output.html
```

**Features:**
- Removes all whitespace
- **Strips all buffered comments** (`//`) for minimal file size
- Ideal for production deployment

**Output**:
```html
<div class="container"><h1>Hello World</h1><p>Welcome</p></div>
```

**Note:** Default compilation (without `-p` or `-m`) uses production mode and strips comments.

#### Using Stdin/Stdout

```bash
# Read from stdin, write to stdout
cat template.zpug | zpug --stdin --stdout > output.html

# Use in pipe chain
echo "p Hello World" | zpug --stdin --stdout
```

#### Verbose Output

```bash
# Show compilation details
zpug -V template.zpug -o output.html
```

**Output**:
```
Compiling: template.zpug
Parsing template (245 bytes)
Compiling to HTML
Output size: 512 bytes
Compiled: template.zpug -> output.html
```

#### Comment Handling

zpug handles comments differently based on the compilation mode to match industry standards (Pug, HTML minifiers):

**Production Mode (Default):**
```bash
# Default: strips all buffered comments
zpug template.zpug -o output.html

# Or explicitly minify
zpug -m template.zpug -o output.html
```

**Result:** All buffered comments (`//`) are **removed** for minimal file size.

**Development Mode:**
```bash
# Pretty mode: includes comments for debugging
zpug -p template.zpug -o output.html
```

**Result:** Buffered comments (`//`) are **included** in the output as HTML comments.

**Readable Mode:**
```bash
# Format mode: pretty-print without comments
zpug -F template.zpug -o output.html
```

**Result:** HTML is indented but buffered comments (`//`) are **removed** for cleaner output.

**Template Example:**
```zpug
doctype html
html
  // This is a buffered comment
  //- This is an unbuffered comment (never in output)
  body
    // Page content starts here
    h1 Hello World
```

**Production output** (default or `-m`):
```html
<!DOCTYPE html><html><body><h1>Hello World</h1></body></html>
```

**Development output** (`-p`):
```html
<!DOCTYPE html>
<html>
  <!-- This is a buffered comment -->
  <body>
    <!-- Page content starts here -->
    <h1>Hello World</h1>
  </body>
</html>
```

**Readable output** (`-F`):
```html
<!DOCTYPE html>
<html>
  <body>
    <h1>Hello World</h1>
  </body>
</html>
```

**Comment Types:**
- `//` - **Buffered:** Included only with `--pretty`, stripped in `--format` and production
- `//-` - **Unbuffered:** Always stripped, never appears in output

#### Watch Mode (Planned)

```bash
# Watch for changes and recompile
zpug -w -i template.zpug -o output.html
```

## Template Examples

### Basic Template

**template.zpug**:
```pug
doctype html
html
  head
    title #{pageTitle}
  body
    h1 #{heading}
    p #{message}
```

**Compile**:
```bash
zpug template.zpug \
  --var pageTitle="My Page" \
  --var heading="Welcome" \
  --var message="Hello World" \
  -o index.html
```

### Using Arrays (CSV Format)

**template.zpug**:
```pug
doctype html
html
  head
    title Fruit List
  body
    h1 My Favorite Fruits
    ul.fruit-list
      each fruit in fruits
        li.fruit= fruit
```

**Compile**:
```bash
zpug template.zpug --array fruits=apple,banana,orange,mango --pretty
```

**Output**:
```html
<!DOCTYPE html>
<html>
  <head>
    <title>Fruit List</title>
  </head>
  <body>
    <h1>My Favorite Fruits</h1>
    <ul class="fruit-list">
      <li class="fruit">apple</li>
      <li class="fruit">banana</li>
      <li class="fruit">orange</li>
      <li class="fruit">mango</li>
    </ul>
  </body>
</html>
```

### Using JSON Objects

**template.zpug**:
```pug
doctype html
html
  head
    title #{user.name} - Profile
  body
    div.profile
      h1= user.name
      p Email: #{user.email}
      p Age: #{user.age}
      p Role: #{user.role}
```

**Compile**:
```bash
zpug template.zpug --json user='{"name":"Alice Johnson","email":"alice@example.com","age":30,"role":"Senior Developer"}' --pretty
```

**Output**:
```html
<!DOCTYPE html>
<html>
  <head>
    <title>Alice Johnson - Profile</title>
  </head>
  <body>
    <div class="profile">
      <h1>Alice Johnson</h1>
      <p>Email: alice@example.com</p>
      <p>Age: 30</p>
      <p>Role: Senior Developer</p>
    </div>
  </body>
</html>
```

### Mixed Types Example

**template.zpug**:
```pug
doctype html
html
  head
    title= pageTitle
  body
    h1= pageTitle
    p Version: #{version}

    section.user
      h2 Current User
      p Name: #{user.name}
      p Role: #{user.role}

    section.tags
      h2 Active Tags
      ul
        each tag in tags
          li.tag= tag

    section.scores
      h2 Test Scores
      ul
        each score in scores
          li Score: #{score}
```

**Compile**:
```bash
zpug template.zpug \
  --var pageTitle="Admin Dashboard" \
  --var version=2.5 \
  --json user='{"name":"Carlos","role":"Admin"}' \
  --array tags=production,stable,v2 \
  --array scores=95,87,92,88.5 \
  --pretty
```

### Using JSON Variables File

**template.zpug**:
```pug
div.user-card
  h2 #{user.name}
  p Email: #{user.email}
  p Age: #{user.age}
  if user.active
    span.badge Active
```

**variables.json**:
```json
{
  "user": {
    "name": "Alice Johnson",
    "email": "alice@example.com",
    "age": 28,
    "active": true
  }
}
```

**Compile**:
```bash
zpug template.zpug --vars variables.json -o user.html
```

## Exit Codes

- `0` - Success
- `1` - Compilation error
- `2` - File I/O error
- `3` - Invalid arguments

## Performance

Compilation times (approximate):

- Small template (< 1KB): ~0.1-0.5ms
- Medium template (1-10KB): ~1-3ms
- Large template (> 10KB): ~5-10ms

*Benchmarks run on typical desktop hardware*

## Error Handling

zpug provides structured and detailed error messages with color coding to facilitate debugging.

### Error Structure

When a compilation error occurs, zpug displays:

1. **Line number** - Where the error occurred
2. **Message** - Clear description of the problem
3. **Detail** - Additional context (expression, variable, etc.)
4. **Hint** - Suggestion to fix the error

### Color Codes

Errors are shown with colors for easy reading:

- 🔴 **Red**: Error messages and line numbers
- 🔵 **Cyan**: Details and context
- 🟡 **Yellow**: Hints and suggestions

### Error Example

```bash
$ zpug template.zpug
```

**Output**:
```
Compilation failed with 2 error(s):

Line 3: Failed to evaluate interpolation
  Expression: #{username}
  Hint: Check that all variables used in the expression are defined

Line 5: Failed to evaluate loop iterable
  Iterable: items
  Hint: Make sure the array variable is defined
```

### Error Types

#### 1. Interpolation Error (Undefined variable)

**Template**:
```pug
p Hello #{name}
```

**Error**:
```
Line 1: Failed to evaluate interpolation
  Expression: #{name}
  Hint: Check that all variables used in the expression are defined
```

**Solution**: Define the variable
```bash
zpug -i template.zpug --var name="World"
```

#### 2. Loop Error (Undefined iterable)

**Template**:
```pug
each item in items
  li= item
```

**Error**:
```
Line 1: Failed to evaluate loop iterable
  Iterable: items
  Hint: Make sure the array variable is defined
```

**Solution**: Define the array
```bash
zpug -i template.zpug --var items='["a","b","c"]'
```

#### 3. Conditional Error (Invalid condition)

**Template**:
```pug
if isActive
  p Active
```

**Error**:
```
Line 1: Failed to evaluate conditional
  Condition: isActive
```

**Solution**: Define the boolean variable
```bash
zpug -i template.zpug --var isActive=true
```

#### 4. Attribute Error (Error in attribute)

**Template**:
```pug
a(href=url) Link
```

**Error**:
```
Line 1: Failed to evaluate attribute expression
  Attribute: href=url
  Hint: Make sure the variable 'url' is defined
```

**Solution**:
```bash
zpug -i template.zpug --var url="https://example.com"
```

#### 5. Include/Extends Errors

**Template**:
```pug
include partial.zpug
```

**Error**:
```
Line 1: Failed to read include file
  File: partial.zpug
  Hint: Make sure the file exists and is readable
```

**Solution**: Verify the file exists
```bash
ls partial.zpug
```

### Multiple Errors

zpug can report multiple errors in a single compilation:

```
Compilation failed with 3 error(s):

Line 2: Failed to evaluate interpolation
  Expression: #{title}
  Hint: Check that all variables used in the expression are defined

Line 5: Failed to evaluate loop iterable
  Iterable: posts
  Hint: Make sure the array variable is defined

Line 8: Failed to evaluate conditional
  Condition: isLoggedIn
```

This allows you to fix all errors at once instead of one by one.

### Verbose Mode

For additional debugging information:

```bash
zpug -i template.zpug --verbose
```

Shows:
- Generated tokens
- AST (Abstract Syntax Tree)
- Defined variables
- Detailed errors

### Errors in Stdin

When using `--stdin`, errors show the line number from the provided template:

```bash
echo 'p Hello #{undefined}' | zpug --stdin
```

```
Line 1: Failed to evaluate interpolation
  Expression: #{undefined}
  Hint: Check that all variables used in the expression are defined
```

## Troubleshooting

### "Error: No input files specified"

You did not provide any input files.

**Solution**:
```bash
zpug -i template.zpug
# or
zpug template.zpug
```

### "Error: Cannot open file 'template.zpug'"

The specified file does not exist or you do not have permission to read it.

**Solution**:
- Check the file path
- Verify file exists: `ls -l template.zpug`
- Check permissions: `chmod +r template.zpug`

### "Error: Parsing failed"

There is a syntax error in your Pug template.

**Solution**:
- Check the template syntax
- Look for unclosed tags, missing indentation, etc.
- Use `--verbose` for more details

### CLI Features Not Available

If you see "command not found" or missing options:

**Cause**: You are using the simple CLI (`main.zig`) which has fewer features.

**Solution**: Build the full CLI if your platform supports it:
```bash
# Edit build.zig to use cli.zig as root_source_file
zig build
```

Or use the Node.js integration which has full features:
```bash
cd nodejs
npm install
npm run build
node examples/01-basic.js
```

## Integration with Build Tools

### Make

**Makefile**:
```makefile
TEMPLATES := $(wildcard templates/*.zpug)
OUTPUTS := $(patsubst templates/%.zpug,dist/%.html,$(TEMPLATES))

all: $(OUTPUTS)

dist/%.html: templates/%.zpug
	@mkdir -p dist
	zpug -i $< -o $@

clean:
	rm -rf dist/
```

### npm Scripts

**package.json**:
```json
{
  "scripts": {
    "build:templates": "zpug -i templates/*.zpug -o dist/",
    "watch:templates": "zpug -w -i templates/*.zpug -o dist/"
  }
}
```

### Gulp

```javascript
const { exec } = require('child_process');
const gulp = require('gulp');

gulp.task('templates', () => {
  return exec('zpug -i templates/*.zpug -o dist/');
});

gulp.task('watch', () => {
  gulp.watch('templates/*.zpug', gulp.series('templates'));
});
```

## Comparison with Other Tools

| Feature | zpug | pug-cli | jade |
|---------|---------|---------|------|
| Speed | Very Fast | Moderate | Moderate |
| File Size | ~3MB | ~50MB | ~30MB |
| Dependencies | None | Node.js + modules | Node.js + modules |
| JavaScript Support | ES5.1 (mujs) | Full ES2020+ (V8) | Full ES5+ |
| Installation | Single binary | npm install | npm install |
| Cross-platform | Yes | Yes | Yes |

## Advanced Usage

### Custom Template Variables

```bash
# Boolean values
zpug template.zpug --var isDev=true --var isProd=false

# Numbers
zpug template.zpug --var version=2.5 --var count=42

# Strings with spaces (quote the whole argument)
zpug template.zpug --var "message=Hello World"
```

### Combining Options

```bash
# Pretty-print with variables (development)
zpug -p template.zpug \
  --var title="My Page" \
  --var year=2024 \
  -o output.html

# Format with variables (readable)
zpug -F template.zpug \
  --var title="My Page" \
  --var year=2024 \
  -o output.html

# Minify with JSON variables (production)
zpug -m template.zpug --vars data.json -o min.html

# Verbose format output
zpug -V -F template.zpug -o output.html
```

## Future Features

Planned for future releases:

- [ ] File watching (`--watch`)
- [ ] Source maps generation
- [ ] Include file support
- [ ] Template inheritance
- [ ] Custom filter plugins
- [ ] Batch compilation with parallel processing
- [ ] Configuration file support (.pugrc)

## See Also

- [Getting Started Guide](./GETTING-STARTED.md) - Step-by-step tutorial
- [Node.js Integration](./NODEJS-INTEGRATION.md) - Use zpug in Node.js
- [Main README](../README.md) - Complete Pug syntax reference
- [Examples](../examples/) - Template examples

---

**Version**: 0.3.0
**License**: MIT
**Homepage**: https://github.com/carlos-sweb/zig-pug
