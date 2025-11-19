# zpug CLI - Command Line Interface

Command-line interface for compiling Pug templates to HTML.

## Installation

### Build from Source

```bash
git clone https://github.com/yourusername/zig-pug
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
zpug template.pug
```

### Compile with Output File

```bash
zpug -i template.pug -o output.html
```

### Compile Multiple Files

```bash
zpug -i template1.pug -i template2.pug -o dist/
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
- ✅ Multiple input files
- ✅ Output to file or directory
- ✅ Variable setting via `--var` and `--vars`
- ✅ Pretty-print HTML output
- ✅ Minify HTML output
- ✅ Stdin/stdout support
- ✅ Verbose and silent modes
- ✅ File watching (planned)

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
-i, --input <file>      Input .pug file (can be used multiple times)
-o, --output <path>     Output file or directory
-w, --watch             Watch files for changes and recompile
-p, --pretty            Pretty-print HTML output (with indentation)
-m, --minify            Minify HTML output (remove whitespace)
--stdin                 Read input from stdin
--stdout                Write output to stdout
-s, --silent            Suppress all output except errors
-V, --verbose           Verbose output with compilation details
-f, --force             Overwrite output files without asking
```

### Variables

```
--var <key>=<value>     Set template variable (can be used multiple times)
--vars <file.json>      Load variables from JSON file
```

**Variable Types** (auto-detected):
- Numbers: `--var count=42`
- Booleans: `--var active=true`
- Strings: `--var name=Alice`

### Examples

#### Basic Compilation

```bash
# Compile single file to stdout
zpug template.pug

# Compile with output file
zpug -i template.pug -o output.html

# Compile multiple files to directory
zpug -i *.pug -o dist/
```

#### Using Variables

```bash
# Set variables via command line
zpug template.pug --var name=Alice --var age=25

# Load variables from JSON file
zpug template.pug --vars data.json -o output.html
```

**data.json**:
```json
{
  "name": "Alice",
  "age": 25,
  "active": true
}
```

#### Pretty-Print Output

```bash
# Pretty-print with indentation
zpug -p template.pug -o pretty.html
```

**Output**:
```html
<div class="container">
  <h1>Hello World</h1>
  <p>Welcome</p>
</div>
```

#### Minify Output

```bash
# Minify (remove whitespace)
zpug -m template.pug -o minified.html
```

**Output**:
```html
<div class="container"><h1>Hello World</h1><p>Welcome</p></div>
```

#### Using Stdin/Stdout

```bash
# Read from stdin, write to stdout
cat template.pug | zpug --stdin --stdout > output.html

# Use in pipe chain
echo "p Hello World" | zpug --stdin --stdout
```

#### Verbose Output

```bash
# Show compilation details
zpug -V template.pug -o output.html
```

**Output**:
```
Compiling: template.pug
Parsing template (245 bytes)
Compiling to HTML
Output size: 512 bytes
✓ Compiled: template.pug -> output.html
```

#### Watch Mode (Planned)

```bash
# Watch for changes and recompile
zpug -w -i template.pug -o output.html
```

## Template Examples

### Basic Template

**template.pug**:
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
zpug template.pug \
  --var pageTitle="My Page" \
  --var heading="Welcome" \
  --var message="Hello World" \
  -o index.html
```

### Using JSON Variables

**template.pug**:
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
zpug template.pug --vars variables.json -o user.html
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

## Troubleshooting

### "Error: No input files specified"

You didn't provide any input files.

**Solution**:
```bash
zpug -i template.pug
# or
zpug template.pug
```

### "Error: Cannot open file 'template.pug'"

The specified file doesn't exist or you don't have permission to read it.

**Solution**:
- Check the file path
- Verify file exists: `ls -l template.pug`
- Check permissions: `chmod +r template.pug`

### "Error: Parsing failed"

There's a syntax error in your Pug template.

**Solution**:
- Check the template syntax
- Look for unclosed tags, missing indentation, etc.
- Use `--verbose` for more details

### CLI Features Not Available

If you see "command not found" or missing options:

**Cause**: You're using the simple CLI (`main.zig`) which has fewer features.

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
TEMPLATES := $(wildcard templates/*.pug)
OUTPUTS := $(patsubst templates/%.pug,dist/%.html,$(TEMPLATES))

all: $(OUTPUTS)

dist/%.html: templates/%.pug
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
    "build:templates": "zpug -i templates/*.pug -o dist/",
    "watch:templates": "zpug -w -i templates/*.pug -o dist/"
  }
}
```

### Gulp

```javascript
const { exec } = require('child_process');
const gulp = require('gulp');

gulp.task('templates', () => {
  return exec('zpug -i templates/*.pug -o dist/');
});

gulp.task('watch', () => {
  gulp.watch('templates/*.pug', gulp.series('templates'));
});
```

## Comparison with Other Tools

| Feature | zpug | pug-cli | jade |
|---------|---------|---------|------|
| Speed | ⚡ Very Fast | Moderate | Moderate |
| File Size | ~3MB | ~50MB | ~30MB |
| Dependencies | None | Node.js + modules | Node.js + modules |
| JavaScript Support | ES5.1 (mujs) | Full ES2020+ (V8) | Full ES5+ |
| Installation | Single binary | npm install | npm install |
| Cross-platform | ✅ Yes | ✅ Yes | ✅ Yes |

## Advanced Usage

### Custom Template Variables

```bash
# Boolean values
zpug template.pug --var isDev=true --var isProd=false

# Numbers
zpug template.pug --var version=2.5 --var count=42

# Strings with spaces (quote the whole argument)
zpug template.pug --var "message=Hello World"
```

### Combining Options

```bash
# Pretty-print with variables
zpug -p template.pug \
  --var title="My Page" \
  --var year=2024 \
  -o output.html

# Minify with JSON variables
zpug -m template.pug --vars data.json -o min.html

# Verbose pretty-print
zpug -V -p template.pug -o output.html
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

**Version**: 0.2.0
**License**: MIT
**Homepage**: https://github.com/yourusername/zig-pug
