# zig-pug Mode for CodeMirror

Syntax highlighting mode for `.zpug` files in CodeMirror.

## Features

- ✅ Syntax highlighting for all zig-pug constructs
- ✅ JavaScript interpolation support `#{...}`
- ✅ Proper indentation
- ✅ Comment toggling
- ✅ Tag, class, and ID highlighting
- ✅ Attribute parsing in parentheses
- ✅ Keywords and control flow
- ✅ Mixin support

## Installation

### NPM/Yarn

```bash
npm install codemirror
# Copy zpug.js to your project
```

### CDN

```html
<!-- CodeMirror core -->
<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/codemirror/5.65.2/codemirror.min.css">
<script src="https://cdnjs.cloudflare.com/ajax/libs/codemirror/5.65.2/codemirror.min.js"></script>

<!-- Dependencies (JavaScript, CSS, HTML modes) -->
<script src="https://cdnjs.cloudflare.com/ajax/libs/codemirror/5.65.2/mode/javascript/javascript.min.js"></script>
<script src="https://cdnjs.cloudflare.com/ajax/libs/codemirror/5.65.2/mode/css/css.min.js"></script>
<script src="https://cdnjs.cloudflare.com/ajax/libs/codemirror/5.65.2/mode/htmlmixed/htmlmixed.min.js"></script>

<!-- zig-pug mode -->
<script src="path/to/zpug.js"></script>
```

### Manual

1. Download `zpug.js`
2. Place it in your CodeMirror `mode/` directory
3. Include it after CodeMirror core and dependencies

## Usage

### Basic Setup

```html
<!DOCTYPE html>
<html>
<head>
  <link rel="stylesheet" href="codemirror.css">
  <script src="codemirror.js"></script>
  <script src="mode/javascript/javascript.js"></script>
  <script src="mode/zpug/zpug.js"></script>
</head>
<body>
  <textarea id="code"></textarea>

  <script>
    var editor = CodeMirror.fromTextArea(document.getElementById('code'), {
      mode: 'zpug',
      lineNumbers: true,
      theme: 'monokai'
    });
  </script>
</body>
</html>
```

### With Configuration

```javascript
var editor = CodeMirror.fromTextArea(document.getElementById('code'), {
  mode: 'zpug',
  theme: 'monokai',
  lineNumbers: true,
  indentUnit: 2,
  tabSize: 2,
  indentWithTabs: false,
  lineWrapping: true,
  matchBrackets: true,
  autoCloseBrackets: true,
  extraKeys: {
    "Ctrl-/": "toggleComment",
    "Cmd-/": "toggleComment"
  }
});
```

### Setting Value Programmatically

```javascript
editor.setValue(`doctype html
html(lang="en")
  head
    title #{pageTitle}
  body
    h1 Hello #{name}!`);

// Get value
var code = editor.getValue();
```

### With React

```jsx
import React, { useEffect, useRef } from 'react';
import CodeMirror from 'codemirror';
import 'codemirror/lib/codemirror.css';
import 'codemirror/theme/monokai.css';
import 'codemirror/mode/javascript/javascript';
import './zpug'; // Import the zpug mode

function ZpugEditor({ value, onChange }) {
  const textareaRef = useRef(null);
  const editorRef = useRef(null);

  useEffect(() => {
    if (!editorRef.current && textareaRef.current) {
      editorRef.current = CodeMirror.fromTextArea(textareaRef.current, {
        mode: 'zpug',
        theme: 'monokai',
        lineNumbers: true,
        indentUnit: 2
      });

      editorRef.current.on('change', (editor) => {
        onChange(editor.getValue());
      });
    }
  }, []);

  useEffect(() => {
    if (editorRef.current && value !== editorRef.current.getValue()) {
      editorRef.current.setValue(value);
    }
  }, [value]);

  return <textarea ref={textareaRef} defaultValue={value} />;
}

export default ZpugEditor;
```

### With Vue

```vue
<template>
  <div>
    <textarea ref="textarea"></textarea>
  </div>
</template>

<script>
import CodeMirror from 'codemirror';
import 'codemirror/lib/codemirror.css';
import 'codemirror/theme/monokai.css';
import 'codemirror/mode/javascript/javascript';
import './zpug';

export default {
  props: ['value'],
  data() {
    return {
      editor: null
    };
  },
  mounted() {
    this.editor = CodeMirror.fromTextArea(this.$refs.textarea, {
      mode: 'zpug',
      theme: 'monokai',
      lineNumbers: true,
      indentUnit: 2
    });

    this.editor.on('change', () => {
      this.$emit('input', this.editor.getValue());
    });

    if (this.value) {
      this.editor.setValue(this.value);
    }
  },
  watch: {
    value(newVal) {
      if (this.editor && newVal !== this.editor.getValue()) {
        this.editor.setValue(newVal);
      }
    }
  }
};
</script>
```

## Example

See [example.html](example.html) for a complete working example.

Open it in your browser to see the mode in action:

```bash
# Serve with any static server
python -m http.server 8000
# Then open http://localhost:8000/example.html
```

## Syntax Highlighting

The mode supports all zig-pug features:

```zpug
doctype html
html(lang="es")
  head
    title #{pageTitle}
  body
    // This is a comment
    div.container#main
      h1.heading Hello #{name.toUpperCase()}!

      if isLoggedIn
        p Welcome back!
      else
        p Please log in

      each item in items
        li= item

      mixin button(text, type)
        button.btn(type=type)= text

      +button('Click me', 'submit')

      - var x = 10
      = 2 + 2

      unless isAdmin
        p Access restricted
```

**Highlighted elements:**
- **Keywords:** `doctype`, `if`, `else`, `unless`, `each`, `mixin`, etc.
- **Tags:** `html`, `head`, `body`, `div`, `p`, etc.
- **Classes:** `.container`, `.heading`, `.btn`
- **IDs:** `#main`
- **Attributes:** `lang="es"`, `type=type`
- **Interpolation:** `#{pageTitle}`, `#{name.toUpperCase()}`
- **Comments:** `// This is a comment`
- **Operators:** `-`, `=`, `+`

## Themes

The mode works with all CodeMirror themes:

```javascript
editor.setOption("theme", "monokai");
// or: dracula, material, solarized, one-dark, etc.
```

**Popular themes:**
- `monokai` - Dark theme with vibrant colors
- `dracula` - Dark theme with purple accents
- `material` - Material Design inspired
- `solarized` - Light/dark solarized
- `nord` - Arctic-inspired color palette

## Configuration Options

```javascript
{
  mode: 'zpug',                // Language mode
  theme: 'monokai',            // Color theme
  lineNumbers: true,           // Show line numbers
  lineWrapping: true,          // Wrap long lines
  indentUnit: 2,               // Indent size
  tabSize: 2,                  // Tab width
  indentWithTabs: false,       // Use spaces
  matchBrackets: true,         // Highlight matching brackets
  autoCloseBrackets: true,     // Auto-close brackets
  styleActiveLine: true,       // Highlight active line
  foldGutter: true,            // Code folding
  gutters: [
    "CodeMirror-linenumbers",
    "CodeMirror-foldgutter"
  ]
}
```

## MIME Types

The mode registers these MIME types:

- `text/x-zpug`
- `text/zpug`

## Indentation

The mode provides smart indentation for:

- Tags
- Conditionals (`if`, `else`, `unless`)
- Loops (`each`, `for`, `while`)
- Mixins
- Blocks

## Development

### File Structure

```
codemirror/
├── zpug.js           # Main mode file
├── example.html      # Live example
└── README.md         # This file
```

### Testing Changes

1. Edit `zpug.js`
2. Reload `example.html`
3. Test syntax highlighting

### Contributing

1. Fork the zig-pug repository
2. Make changes in `editor-support/codemirror/zpug.js`
3. Test with `example.html`
4. Submit pull request

## Troubleshooting

### Mode not working

1. Check that dependencies are loaded:
   - `codemirror.js`
   - `mode/javascript/javascript.js`
2. Verify `zpug.js` is loaded after dependencies
3. Check browser console for errors

### Syntax not highlighting correctly

1. Ensure mode is set to `'zpug'`
2. Try a different theme
3. Check if file content is valid zpug syntax

### Indentation issues

1. Set `indentUnit` and `tabSize` to `2`
2. Set `indentWithTabs` to `false`
3. Enable `electricChars`

## Links

- **zig-pug Project:** https://github.com/yourusername/zig-pug
- **CodeMirror Docs:** https://codemirror.net/doc/manual.html
- **Mode Development:** https://codemirror.net/doc/manual.html#modeapi

## License

MIT License - Same as zig-pug project

---

**Happy coding with zig-pug!** 🎨
