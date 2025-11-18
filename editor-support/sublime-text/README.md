# zig-pug Syntax for Sublime Text 3/4

Syntax highlighting and snippets for `.zpug` files in Sublime Text.

## Features

- ✅ Syntax highlighting for all zig-pug constructs
- ✅ Tag names, classes, IDs
- ✅ Attributes in parentheses
- ✅ JavaScript interpolation `#{...}`
- ✅ Conditionals (if/else/unless)
- ✅ Mixins (definition and calls)
- ✅ Comments
- ✅ Auto-completion snippets
- ✅ Proper indentation

## Installation

### Method 1: Manual Installation

1. **Find your Sublime Text Packages directory:**
   - **Linux:** `~/.config/sublime-text/Packages/`
   - **macOS:** `~/Library/Application Support/Sublime Text/Packages/`
   - **Windows:** `%APPDATA%\Sublime Text\Packages\`

   Or use: `Preferences > Browse Packages...`

2. **Create a directory for zig-pug:**
   ```bash
   mkdir -p "Sublime Text/Packages/zig-pug"
   ```

3. **Copy the syntax files:**
   ```bash
   cp zpug.sublime-syntax "Sublime Text/Packages/zig-pug/"
   cp zpug.sublime-completions "Sublime Text/Packages/zig-pug/"
   ```

4. **Restart Sublime Text**

### Method 2: Symlink (for development)

```bash
# Linux/macOS
ln -s /path/to/zig-pug/editor-support/sublime-text \
      ~/.config/sublime-text/Packages/zig-pug

# Restart Sublime Text
```

## Usage

1. Open a `.zpug` file
2. The syntax highlighting will activate automatically
3. Or manually select: `View > Syntax > zig-pug`

## Snippets

Type these triggers and press `Tab`:

### HTML Structure

- `html5` - Complete HTML5 template
- `div.` - Div with class
- `div#` - Div with id
- `a(` - Link
- `img(` - Image
- `input(` - Input field
- `button(` - Button

### Control Flow

- `if` - If statement
- `else` - Else statement
- `unless` - Unless statement
- `each` - Each loop

### Mixins

- `mixin` - Mixin definition
- `+` - Mixin call

### Interpolation

- `#{}` - JavaScript interpolation

## Examples

### Syntax Highlighting

```zpug
doctype html
html(lang="es")
  head
    title #{pageTitle}
  body
    div.container
      h1#main-title Hello #{name}!

      if isLoggedIn
        p Welcome back!
      else
        p Please log in

      each item in items
        li= item
```

All elements will be properly highlighted:
- `doctype`, `if`, `else`, `each` - **Keywords** (purple/pink)
- `html`, `head`, `body`, `div`, `h1`, `li` - **Tags** (blue)
- `.container`, `#main-title` - **Classes/IDs** (yellow/green)
- `lang="es"` - **Attributes** (orange)
- `#{pageTitle}`, `#{name}` - **Interpolation** (embedded JavaScript)

## Color Scheme Compatibility

The syntax definition uses standard scopes that work with most color schemes:

- **Monokai** ✅
- **Solarized** ✅
- **One Dark** ✅
- **Dracula** ✅
- **Material Theme** ✅

## Customization

### Change File Icon

Create a `zig-pug.sublime-settings` file in the same directory:

```json
{
    "extensions": ["zpug"],
    "icon": "file_type_pug"
}
```

### Custom Key Bindings

Add to `Preferences > Key Bindings`:

```json
[
    {
        "keys": ["ctrl+alt+p"],
        "command": "set_file_type",
        "args": {"syntax": "Packages/zig-pug/zpug.sublime-syntax"}
    }
]
```

## Troubleshooting

### Syntax not activating

1. Check file extension is `.zpug`
2. Manually select: `View > Syntax > zig-pug`
3. Restart Sublime Text

### Snippets not working

1. Make sure `.sublime-completions` file is in Packages/zig-pug/
2. Check scope is `source.zpug`
3. Restart Sublime Text

### Colors look wrong

Try a different color scheme:
`Preferences > Color Scheme > Monokai`

## Development

To modify the syntax:

1. Edit `zpug.sublime-syntax`
2. Use [Sublime Text syntax documentation](https://www.sublimetext.com/docs/syntax.html)
3. Test with `Tools > Developer > Show Scope Name` (Ctrl+Alt+Shift+P)

## Links

- **zig-pug GitHub:** https://github.com/yourusername/zig-pug
- **Sublime Text Docs:** https://www.sublimetext.com/docs/
- **Syntax Definition:** https://www.sublimetext.com/docs/syntax.html

## License

MIT License - Same as zig-pug project
