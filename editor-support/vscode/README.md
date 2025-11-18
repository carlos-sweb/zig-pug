# zig-pug for Visual Studio Code

Syntax highlighting, snippets, and language support for `.zpug` files in Visual Studio Code.

## Features

- ✅ **Syntax Highlighting** - Full support for zig-pug syntax
- ✅ **IntelliSense** - Auto-completion for tags, keywords, and snippets
- ✅ **Snippets** - Quick templates for common patterns
- ✅ **Auto-closing** - Automatic closing of brackets, quotes, and `#{}`
- ✅ **Comment Toggle** - `Ctrl+/` for line comments
- ✅ **Indentation** - Smart indentation based on context
- ✅ **Bracket Matching** - Highlight matching brackets

## Installation

### Method 1: From VSIX (Recommended for Testing)

1. **Package the extension:**
   ```bash
   cd editor-support/vscode
   npm install -g vsce
   vsce package
   ```

2. **Install in VS Code:**
   - Open VS Code
   - Press `Ctrl+Shift+P` (or `Cmd+Shift+P` on macOS)
   - Type "Install from VSIX"
   - Select the `zig-pug-0.2.0.vsix` file

### Method 2: Development Mode

1. **Copy to extensions folder:**
   ```bash
   # Linux/macOS
   cp -r editor-support/vscode ~/.vscode/extensions/zig-pug-0.2.0

   # Windows
   xcopy editor-support\vscode %USERPROFILE%\.vscode\extensions\zig-pug-0.2.0\ /E /I
   ```

2. **Reload VS Code:**
   - Press `Ctrl+Shift+P`
   - Type "Developer: Reload Window"

### Method 3: Symlink (for development)

```bash
# Linux/macOS
ln -s /path/to/zig-pug/editor-support/vscode \
      ~/.vscode/extensions/zig-pug-0.2.0

# Reload VS Code
```

## Usage

### Syntax Highlighting

Open any `.zpug` file and the syntax highlighting will activate automatically.

**Example:**

```zpug
doctype html
html(lang="es")
  head
    title #{pageTitle}
  body
    div.container
      h1#main-title Hello #{name}!

      if isLoggedIn
        p.welcome Welcome back!
      else
        p.login Please log in
```

### Snippets

Type a trigger and press `Tab` to expand:

| Trigger | Description | Expands to |
|---------|-------------|------------|
| `html5` | HTML5 template | Complete HTML5 structure |
| `div.` | Div with class | `div.classname` |
| `div#` | Div with ID | `div#id` |
| `if` | If statement | `if condition` |
| `each` | Each loop | `each item in items` |
| `mixin` | Mixin definition | `mixin name(args)` |
| `+` | Mixin call | `+mixinName(args)` |
| `#{}` | Interpolation | `#{expression}` |
| `a` | Link | `a(href="#") Link` |
| `img` | Image | `img(src="..." alt="...")` |
| `button` | Button | `button(type="...") Text` |

**Full list of snippets:** See [snippets/zpug.json](snippets/zpug.json)

### IntelliSense

Start typing and VS Code will suggest:
- HTML tags
- zig-pug keywords (`if`, `each`, `mixin`, etc.)
- Snippet shortcuts

### Auto-completion

The extension provides smart auto-completion:

- Type `(` → automatically adds `)`
- Type `"` → automatically adds closing `"`
- Type `#{` → automatically adds closing `}`

### Comments

- **Line comment:** `Ctrl+/` (or `Cmd+/` on macOS)
- Creates `// comment`

### Indentation

The extension provides smart indentation:

- Tags, conditionals, loops, and mixins increase indent
- Automatic indent on Enter
- Properly handles nested structures

## Examples

### Complete Template

```zpug
doctype html
html(lang="es")
  head
    meta(charset="utf-8")
    meta(name="viewport" content="width=device-width, initial-scale=1")
    title #{pageTitle}

  body
    header.main-header
      nav.navbar
        ul
          each item in navItems
            li
              a(href=item.url) #{item.name}

    main.content
      div.container
        if user.isLoggedIn
          p Welcome, #{user.name.toUpperCase()}!
        else
          p Please log in

        mixin card(title, content)
          div.card
            h3.card-title= title
            p.card-content= content

        +card('Hello', 'This is a card')
        +card('World', 'This is another card')

    footer.main-footer
      p &copy; #{new Date().getFullYear()} zig-pug
```

### With JavaScript

```zpug
- var items = ['Apple', 'Banana', 'Orange']
- var isActive = true

div.fruits
  if isActive
    ul
      each fruit in items
        li #{fruit.toLowerCase()}
  else
    p No fruits available
```

## Color Themes

The extension works with all VS Code color themes:

- **Dark+** (default dark)
- **Light+** (default light)
- **Monokai**
- **Solarized Dark/Light**
- **Dracula**
- **One Dark Pro**
- **Material Theme**

## Configuration

### File Association

If `.zpug` files aren't automatically recognized:

1. Open a `.zpug` file
2. Click the language indicator in the bottom-right
3. Select "zig-pug" from the list

Or configure in `settings.json`:

```json
{
  "files.associations": {
    "*.zpug": "zpug"
  }
}
```

### Custom Keybindings

Add custom keybindings in `keybindings.json`:

```json
[
  {
    "key": "ctrl+alt+z",
    "command": "workbench.action.files.setActiveEditorLanguage",
    "args": "zpug"
  }
]
```

### Formatter Settings

```json
{
  "editor.formatOnSave": false,
  "[zpug]": {
    "editor.tabSize": 2,
    "editor.insertSpaces": true,
    "editor.detectIndentation": false
  }
}
```

## Known Issues

- **No formatter yet** - Manual formatting required (planned for future release)
- **Limited error detection** - Basic syntax checking only

## Roadmap

- [ ] Auto-formatter
- [ ] Error diagnostics
- [ ] Hover documentation
- [ ] Go to definition for mixins
- [ ] Symbol provider (outline view)
- [ ] Emmet-like abbreviations

## Contributing

Contributions are welcome!

1. Fork the repository
2. Make changes in `editor-support/vscode/`
3. Test the extension
4. Submit a pull request

## Development

### Testing Changes

```bash
# 1. Make changes to syntax/snippets
# 2. Reload VS Code
code --extensionDevelopmentPath=/path/to/zig-pug/editor-support/vscode

# Or press F5 in VS Code with the folder open
```

### Building VSIX

```bash
cd editor-support/vscode
npm install -g vsce
vsce package
```

### Publishing to Marketplace

```bash
vsce publish
```

## Links

- **zig-pug Project:** https://github.com/yourusername/zig-pug
- **VS Code Extension API:** https://code.visualstudio.com/api
- **TextMate Grammars:** https://macromates.com/manual/en/language_grammars

## License

MIT License - Same as zig-pug project

## Support

- **Issues:** https://github.com/yourusername/zig-pug/issues
- **Discussions:** https://github.com/yourusername/zig-pug/discussions

---

**Made with ❤️ for the zig-pug community**
