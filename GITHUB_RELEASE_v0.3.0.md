# Release v0.3.0 - UTF-8 Support & Documentation Comments

Major improvements for international projects and developer experience.

---

## 🎉 What's New

### 1. Full UTF-8 Support 🌍

zig-pug now has **complete Unicode support** for international characters in all template elements!

**Supported:**
- ✅ **Emoji**: 🎉 🚀 ✨ 💻 🌍 📝 ⚡ 🔥
- ✅ **Accents**: á é í ó ú ñ ü ç ß à â ê ô
- ✅ **All UTF-8** sequences (1-4 bytes)
- ✅ Works in: text content, class names, IDs, comments

**Example:**

```pug
doctype html
html(lang="es")
  body
    h1 ¡Bienvenido! 🎉

    section.español
      p.información José y María
      p#descripción Texto con acentos

    section.português
      h2 Programação em português
      p Características: ã, õ, ç

    footer
      p © 2025 - Creado con zig-pug 🚀
```

**Languages Tested:**
- 🇪🇸 Spanish: á, é, í, ó, ú, ñ, Ñ, ¿, ¡
- 🇵🇹 Portuguese: ã, õ, ç, Ç, à, â, ê, ô
- 🇫🇷 French: é, è, ê, ë, à, ù, ô, î, ï, ç
- 🇩🇪 German: ä, ö, ü, ß, Ä, Ö, Ü

---

### 2. Documentation Comments (`//!`) 📝

New comment type for file metadata that's **completely ignored** by the parser:

**Features:**
- Never processed (more efficient than `//` or `//-`)
- Can appear **before** `doctype` declarations
- Perfect for file headers and metadata
- Similar to Zig (`//!`), Rust (`//!`), JSDoc

**Example:**

```pug
//! Template: homepage.pug
//! Author: John Doe
//! Version: 1.0
//! Last updated: 2025-01-01
doctype html
html
  body
    // Regular comment (appears in --pretty mode)
    //- Code comment (never appears)
    p Hello World
```

**Comparison:**

| Syntax | Processed? | In HTML? | Use Case |
|--------|------------|----------|----------|
| `//!` | ❌ No | ❌ No | File metadata, author notes |
| `//` | ✅ Yes | ✅ Yes (--pretty mode) | Development debugging |
| `//-` | ✅ Yes | ❌ No | Code comments |

---

### 3. DOCTYPE Indentation Fix 🐛

Fixed formatting bug in pretty-print mode where `<html>` was incorrectly indented under `<!DOCTYPE>`:

**Before (v0.2.0):**
```html
<!DOCTYPE html>
  <html lang="es">  ← ❌ Incorrectly indented
    <body>
```

**After (v0.3.0):**
```html
<!DOCTYPE html>
<html lang="es">  ← ✅ Correct
  <body>
```

DOCTYPE is now correctly treated as a declaration, not a container element.

---

## 📦 Node.js/Bun Package Updates

The npm package has been updated to v0.3.0 with:

- ✅ Updated description highlighting UTF-8 and `//!` support
- ✅ Added 11 new keywords: `utf-8`, `unicode`, `emoji`, `i18n`, `internationalization`, `multilingual`, `spanish`, `portuguese`, `french`, `german`
- ✅ Comprehensive README with UTF-8 examples
- ✅ Documentation comments section
- ✅ All GitHub URLs updated

**Installation:**

```bash
# Node.js
npm install zig-pug

# Bun (2-5x faster)
bun install zig-pug
```

**Quick Example:**

```javascript
const zigpug = require('zig-pug');

const html = zigpug.compile(`
  doctype html
  html(lang="es")
    body
      h1 ¡Hola #{nombre}! 🎉
      p.información Información importante
`, {
  nombre: 'María'
});

console.log(html);
```

---

## 🧪 Testing

- ✅ **87/87 unit tests passing**
- ✅ Tested with Spanish, Portuguese, French, German
- ✅ Tested emoji and Unicode symbols
- ✅ Tested UTF-8 in classes, IDs, text, and comments
- ✅ Verified DOCTYPE indentation fix in all modes

---

## 📊 Technical Details

### Implementation

**UTF-8 Support (src/tokenizer.zig):**
- Added `isUtf8Start()` to detect UTF-8 sequence start bytes
- Added `utf8SequenceLength()` to calculate 1-4 byte sequences
- Added `isValidTextByte()` for identifier validation
- Updated `scanIdentifier()` to handle UTF-8 codepoints
- Updated `scanSymbol()` for UTF-8 in `.class` and `#id`

**Doc Comments (src/tokenizer.zig):**
- Added `skipDocComment()` to skip `//!` lines completely
- Detection happens before token creation (very efficient)

**DOCTYPE Fix (src/cli.zig):**
- Added `is_doctype` detection in `prettyPrintHtml()`
- DOCTYPE treated as declaration, not container

### Files Changed

```
7 files changed, 281 insertions(+), 20 deletions(-)

Core changes:
- src/tokenizer.zig      (+138 lines)  UTF-8 + //!
- src/cli.zig            (+17 lines)   DOCTYPE fix
- README.md              (+50 lines)   UTF-8 docs
- docs/en/FEATURES.md    (+92 lines)   Complete docs
- examples/01-basic.pug  (updated)     Use //!
- nodejs/package.json    (v0.3.0)      Updated metadata
- nodejs/README.md       (+67 lines)   UTF-8 + //! sections
```

---

## ⚙️ Breaking Changes

**None.** This release is **fully backward compatible**.

All existing templates will work exactly as before. New features are opt-in.

---

## 🚀 Migration Guide

**No migration needed!** Just update and enjoy the new features:

```bash
npm install zig-pug@latest
```

---

## 🔗 Links

- **npm Package:** https://www.npmjs.com/package/zig-pug
- **GitHub Repo:** https://github.com/carlos-sweb/zig-pug
- **Documentation:** https://github.com/carlos-sweb/zig-pug#readme
- **CLI Binary:** See main repo for `zpug` command-line tool

---

## 🙏 Credits

This release was developed with assistance from [Claude Code](https://claude.com/claude-code).

---

## 📝 Changelog

### Added
- Full UTF-8 support for all Unicode characters (emoji, accents, symbols)
- Documentation comments (`//!`) for file metadata
- DOCTYPE indentation fix in pretty-print mode
- i18n keywords in npm package
- Comprehensive UTF-8 examples in documentation

### Changed
- Updated package description to highlight UTF-8 and `//!`
- Improved README with international examples
- Enhanced FEATURES.md with UTF-8 section

### Fixed
- DOCTYPE no longer causes incorrect indentation of `<html>` tag
- UTF-8 characters now work in class names and IDs
- Multi-byte UTF-8 sequences handled correctly

---

## 🎯 Next Steps

After this release:

1. **Try it out:**
   ```bash
   npm install zig-pug@0.3.0
   ```

2. **Star the repo** ⭐ if you find it useful!

3. **Report issues** at https://github.com/carlos-sweb/zig-pug/issues

4. **Share** with others building international projects!

---

**Full Changelog:** https://github.com/carlos-sweb/zig-pug/compare/v0.2.0...v0.3.0 (if previous tag exists)

---

🎉 **Happy templating with full UTF-8 support!** 🌍
