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
-i, --input <file>      Input .zpug file (can be used multiple times)
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
zpug template.zpug

# Compile with output file
zpug -i template.zpug -o output.html

# Compile multiple files to directory
zpug -i *.zpug -o dist/
```

#### Using Variables

```bash
# Set variables via command line
zpug template.zpug --var name=Alice --var age=25

# Load variables from JSON file
zpug template.zpug --vars data.json -o output.html
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
zpug -p template.zpug -o pretty.html
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
zpug -m template.zpug -o minified.html
```

**Output**:
```html
<div class="container"><h1>Hello World</h1><p>Welcome</p></div>
```

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
✓ Compiled: template.zpug -> output.html
```

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

### Using JSON Variables

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

## Manejo de Errores

zpug proporciona mensajes de error estructurados y detallados con códigos de color para facilitar la depuración.

### Estructura de Errores

Cuando ocurre un error de compilación, zpug muestra:

1. **Número de línea** - Dónde ocurrió el error
2. **Mensaje** - Descripción clara del problema
3. **Detalle** - Contexto adicional (expresión, variable, etc.)
4. **Consejo** - Sugerencia para solucionar el error

### Códigos de Color

Los errores se muestran con colores para facilitar la lectura:

- 🔴 **Rojo**: Mensajes de error y números de línea
- 🔵 **Cyan**: Detalles y contexto
- 🟡 **Amarillo**: Consejos y sugerencias

### Ejemplo de Error

```bash
$ zpug template.zpug
```

**Salida**:
```
Compilation failed with 2 error(s):

Line 3: Failed to evaluate interpolation
  Expression: #{username}
  Hint: Check that all variables used in the expression are defined

Line 5: Failed to evaluate loop iterable
  Iterable: items
  Hint: Make sure the array variable is defined
```

### Tipos de Errores

#### 1. Interpolation Error (Variable no definida)

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

**Solución**: Definir la variable
```bash
zpug -i template.zpug --var name="World"
```

#### 2. Loop Error (Iterable no definido)

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

**Solución**: Definir el array
```bash
zpug -i template.zpug --var items='["a","b","c"]'
```

#### 3. Conditional Error (Condición no válida)

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

**Solución**: Definir la variable booleana
```bash
zpug -i template.zpug --var isActive=true
```

#### 4. Attribute Error (Error en atributo)

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

**Solución**:
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

**Solución**: Verificar que el archivo existe
```bash
ls partial.zpug
```

### Múltiples Errores

zpug puede reportar múltiples errores en una sola compilación:

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

Esto permite corregir todos los errores de una vez en lugar de uno por uno.

### Modo Verbose

Para información adicional de depuración:

```bash
zpug -i template.zpug --verbose
```

Muestra:
- Tokens generados
- AST (Abstract Syntax Tree)
- Variables definidas
- Errores detallados

### Errores en Stdin

Cuando se usa `--stdin`, los errores muestran el número de línea del template proporcionado:

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

You didn't provide any input files.

**Solution**:
```bash
zpug -i template.zpug
# or
zpug template.zpug
```

### "Error: Cannot open file 'template.zpug'"

The specified file doesn't exist or you don't have permission to read it.

**Solution**:
- Check the file path
- Verify file exists: `ls -l template.zpug`
- Check permissions: `chmod +r template.zpug`

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
zpug template.zpug --var isDev=true --var isProd=false

# Numbers
zpug template.zpug --var version=2.5 --var count=42

# Strings with spaces (quote the whole argument)
zpug template.zpug --var "message=Hello World"
```

### Combining Options

```bash
# Pretty-print with variables
zpug -p template.zpug \
  --var title="My Page" \
  --var year=2024 \
  -o output.html

# Minify with JSON variables
zpug -m template.zpug --vars data.json -o min.html

# Verbose pretty-print
zpug -V -p template.zpug -o output.html
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
- [Main README](../../README.md) - Complete Pug syntax reference
- [Examples](../../examples/) - Template examples

---

**Version**: 0.2.0
**License**: MIT
**Homepage**: https://github.com/carlos-sweb/zig-pug
