# Editor Support for zig-pug (.zpug files)

Syntax highlighting and language support for `.zpug` files in popular code editors.

## 🎨 Supported Editors

| Editor | Status | Features |
|--------|--------|----------|
| **Visual Studio Code** | ✅ Complete | Syntax highlighting, snippets, IntelliSense, auto-closing |
| **Sublime Text 3/4** | ✅ Complete | Syntax highlighting, snippets, auto-completion |
| **CodeMirror** | ✅ Complete | Syntax highlighting, indentation, web-based editors |
| Vim/Neovim | ⚠️ Coming soon | TreeSitter grammar planned |
| Emacs | ⚠️ Coming soon | Major mode planned |
| Atom | ⚠️ Coming soon | Grammar and snippets planned |

## Quick Links

- **[Visual Studio Code](#visual-studio-code)** - Most popular, recommended for beginners
- **[Sublime Text](#sublime-text)** - Lightweight and fast
- **[CodeMirror](#codemirror)** - For web-based editors

## Visual Studio Code

### Installation

```bash
cd editor-support/vscode
code --install-extension zig-pug-0.2.0.vsix
```

Or copy to extensions folder:

```bash
cp -r vscode ~/.vscode/extensions/zig-pug-0.2.0
```

### Features

- ✅ Full syntax highlighting
- ✅ IntelliSense auto-completion
- ✅ 30+ code snippets
- ✅ Bracket matching and auto-closing
- ✅ Comment toggling (`Ctrl+/`)
- ✅ Smart indentation

### Documentation

See [vscode/README.md](vscode/README.md) for complete documentation.

### Screenshots

**Syntax Highlighting:**
```zpug
doctype html
html(lang="es")
  head
    title #{pageTitle}
  body
    div.container
      if isLoggedIn
        p Welcome #{user.name}!
```

## Sublime Text

### Installation

**Manual:**

1. Open Sublime Text
2. Go to `Preferences > Browse Packages`
3. Create folder `zig-pug`
4. Copy `sublime-text/*.sublime-*` files to that folder
5. Restart Sublime Text

**Symlink (for development):**

```bash
ln -s /path/to/zig-pug/editor-support/sublime-text \
      ~/.config/sublime-text/Packages/zig-pug
```

### Features

- ✅ Syntax highlighting with `.sublime-syntax`
- ✅ Auto-completion snippets
- ✅ Works with all color schemes
- ✅ Proper indentation

### Documentation

See [sublime-text/README.md](sublime-text/README.md) for complete documentation.

## CodeMirror

### Installation

**NPM:**

```bash
npm install codemirror
# Copy zpug.js to your project
```

**CDN:**

```html
<script src="https://cdnjs.cloudflare.com/ajax/libs/codemirror/5.65.2/codemirror.min.js"></script>
<script src="path/to/zpug.js"></script>
```

### Usage

```javascript
var editor = CodeMirror.fromTextArea(document.getElementById('code'), {
  mode: 'zpug',
  theme: 'monokai',
  lineNumbers: true
});
```

### Features

- ✅ Syntax highlighting
- ✅ Indentation support
- ✅ JavaScript interpolation
- ✅ Works with React, Vue, Angular

### Documentation

See [codemirror/README.md](codemirror/README.md) for complete documentation.

### Live Example

Open [codemirror/example.html](codemirror/example.html) in your browser for a live demo.

## File Extension

All editors recognize files with the `.zpug` extension:

```
template.zpug
layout.zpug
components/header.zpug
```

## Features Comparison

| Feature | VS Code | Sublime Text | CodeMirror |
|---------|---------|--------------|------------|
| Syntax Highlighting | ✅ | ✅ | ✅ |
| Snippets | ✅ | ✅ | ❌ |
| Auto-completion | ✅ | ✅ | ❌ |
| IntelliSense | ✅ | ❌ | ❌ |
| Auto-closing brackets | ✅ | ❌ | ✅* |
| Comment toggling | ✅ | ❌ | ✅* |
| Indentation | ✅ | ✅ | ✅ |
| Web-based | ❌ | ❌ | ✅ |

*With configuration

## Syntax Elements

All editors highlight these zig-pug elements:

### Tags
```zpug
html
head
body
div
p
```

### Classes and IDs
```zpug
div.container
div#main
p.text.large
```

### Attributes
```zpug
a(href="/" target="_blank")
input(type="text" name="username")
img(src="image.jpg" alt="Image")
```

### JavaScript Interpolation
```zpug
p Hello #{name}!
p Age: #{age + 1}
p Email: #{email.toLowerCase()}
```

### Conditionals
```zpug
if isLoggedIn
  p Welcome!
else
  p Please log in
```

### Loops
```zpug
each item in items
  li= item
```

### Mixins
```zpug
mixin button(text)
  button.btn= text

+button('Click me')
```

### Comments
```zpug
// This is a comment
```

## Color Schemes

All syntax definitions use semantic scopes that work with popular color schemes:

**VS Code:**
- Dark+ (default)
- Light+ (default)
- Monokai
- Solarized Dark/Light
- Dracula
- One Dark Pro
- Material Theme

**Sublime Text:**
- Monokai
- Solarized
- Dracula
- Material Theme
- Any standard color scheme

**CodeMirror:**
- monokai
- dracula
- material
- solarized
- nord
- Any CodeMirror theme

## Development

### Contributing

Contributions are welcome! To add support for a new editor:

1. Fork the repository
2. Create a new directory in `editor-support/`
3. Implement the syntax definition
4. Add documentation (README.md)
5. Test thoroughly
6. Submit a pull request

### Testing

Each editor has its own testing method:

**VS Code:**
```bash
code --extensionDevelopmentPath=/path/to/zig-pug/editor-support/vscode
```

**Sublime Text:**
- Save changes and reload
- Use `Tools > Developer > Show Scope Name` to debug

**CodeMirror:**
- Open `example.html` in browser
- Edit `zpug.js` and refresh

### File Structure

```
editor-support/
├── README.md                 # This file
├── vscode/                   # VS Code extension
│   ├── package.json
│   ├── syntaxes/
│   ├── snippets/
│   └── README.md
├── sublime-text/             # Sublime Text package
│   ├── zpug.sublime-syntax
│   ├── zpug.sublime-completions
│   └── README.md
└── codemirror/               # CodeMirror mode
    ├── zpug.js
    ├── example.html
    └── README.md
```

## Roadmap

### Planned Features

- [ ] **VS Code:** Auto-formatter
- [ ] **VS Code:** Error diagnostics
- [ ] **VS Code:** Go to definition for mixins
- [ ] **Sublime Text:** Build system integration
- [ ] **CodeMirror:** Linting support
- [ ] **Vim:** TreeSitter grammar
- [ ] **Emacs:** Major mode
- [ ] **Atom:** Grammar and snippets
- [ ] **JetBrains IDEs:** Plugin

### Community Requests

Have a favorite editor not listed? Open an issue or contribute!

## Troubleshooting

### VS Code: Extension not working

1. Check `.zpug` file extension
2. Reload window: `Ctrl+Shift+P` → "Reload Window"
3. Check installed extensions: `Ctrl+Shift+X`

### Sublime Text: Syntax not recognized

1. Open `.zpug` file
2. `View > Syntax > zig-pug`
3. Or manually select from bottom-right

### CodeMirror: Mode not found

1. Ensure dependencies are loaded (JavaScript mode)
2. Check `zpug.js` is included after CodeMirror
3. Set mode to `'zpug'` or `'text/x-zpug'`

## Links

- **zig-pug Project:** https://github.com/carlos-sweb/zig-pug
- **npm Package:** https://www.npmjs.com/package/zig-pug
- **Documentation:** [docs/](../docs/)
- **Examples:** [examples/](../examples/)

## Support

- **Issues:** https://github.com/carlos-sweb/zig-pug/issues
- **Discussions:** https://github.com/carlos-sweb/zig-pug/discussions

## License

MIT License - Same as zig-pug project

---

**Made with ❤️ for the zig-pug community**

Choose your favorite editor and start coding with `.zpug` files today! 🎨
