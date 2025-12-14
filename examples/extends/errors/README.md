# Common Errors with Extends/Block

This directory contains examples of common errors when using template inheritance (`extends` and `block`).

## Error Examples

### 1. File Not Found (`01-file-not-found.zpug`)

**Error:** Trying to extend a file that doesn't exist.

```zpug
extends nonexistent.zpug
```

**Error Message:**
```
Error reading extends file './nonexistent.zpug': error.FileNotFound
Error: Compilation failed: error.ExtendsFileNotFound
```

**Solution:**
- Make sure the file path is correct
- Check that the file exists in the expected location
- Use absolute or relative paths correctly

---

### 2. Extends Not First (`02-extends-not-first.zpug`)

**Error:** Placing `extends` after other content (like `doctype`).

```zpug
doctype html      ❌ Wrong: content before extends

extends layout.zpug
```

**Problem:**
The `extends` directive is ignored and both files are rendered, causing:
- Duplicate DOCTYPE declarations
- Content from both templates mixed incorrectly
- Invalid HTML structure

**Correct:**
```zpug
extends layout.zpug   ✅ Correct: extends must be first

block content
  p My content
```

**Rule:** `extends` must ALWAYS be the first line in your template (comments are allowed before it).

---

### 3. Undefined Block (`03-undefined-block.zpug`)

**Behavior:** Overriding a block that doesn't exist in the parent.

```zpug
extends layout.zpug

block nonexistent     ⚠️ This block doesn't exist in parent
  h1 This content will be ignored
```

**What Happens:**
- No error is thrown
- The block content is silently ignored
- Parent's default blocks are used

**This is NOT an error**, but it might indicate:
- Typo in block name
- Misunderstanding of parent template structure

**Solution:**
- Check the parent template's block names
- Use `block content`, `block title`, etc. (whatever the parent defines)

---

### 4. Duplicate Doctype (`04-duplicate-doctype.zpug`)

**Error:** Having doctype before `extends` creates duplicate doctypes.

```zpug
doctype html      ❌ Creates first doctype

extends layout.zpug    # Parent also has doctype html

block content
  p Content
```

**Output:**
```html
<!DOCTYPE html><!DOCTYPE html><html>...
```

**Problem:**
- Invalid HTML (two DOCTYPE declarations)
- Parent's doctype + child's doctype
- Browsers may render incorrectly

**Solution:**
```zpug
extends layout.zpug    ✅ Let parent handle doctype

block content
  p Content
```

---

## Best Practices

### ✅ DO:

1. **Always put `extends` first:**
   ```zpug
   extends layout.zpug

   block content
     p Content
   ```

2. **Use descriptive block names:**
   ```zpug
   block content
   block header
   block footer
   ```

3. **Check parent template for available blocks:**
   ```zpug
   // Check layout.zpug to see what blocks are defined
   extends layout.zpug

   block content    // Must match parent's block name
     p My content
   ```

4. **Use quotes for paths with special characters:**
   ```zpug
   extends "path/to/my-layout.zpug"
   extends "../layouts/base.zpug"
   ```

### ❌ DON'T:

1. **Don't put content before extends:**
   ```zpug
   ❌ doctype html
   ❌ p Hello
   extends layout.zpug
   ```

2. **Don't use doctype in child templates:**
   ```zpug
   extends layout.zpug
   ❌ doctype html
   ```

3. **Don't assume block names - check the parent:**
   ```zpug
   extends layout.zpug
   ❌ block sidebar  // Does parent have this block?
   ```

---

## Testing These Examples

Run any example to see the error:

```bash
# Test file not found error
zpug 01-file-not-found.zpug

# Test extends not first (generates invalid HTML)
zpug 02-extends-not-first.zpug

# Test undefined block (no error, content ignored)
zpug 03-undefined-block.zpug --pretty

# Test duplicate doctype
zpug 04-duplicate-doctype.zpug
```

---

## Parent Template Structure

The `layout.zpug` in this directory defines these blocks:

```zpug
doctype html
html(lang="en")
  head
    meta(charset="UTF-8")
    meta(name="viewport" content="width=device-width, initial-scale=1.0")
    title
      block title          # Block 1: title
        | Default Title
  body
    header
      block header         # Block 2: header
        h1 My Website
    main
      block content        # Block 3: content
        p This is default content
    footer
      block footer         # Block 4: footer
        p Copyright 2024 My Website
```

**Available blocks:** `title`, `header`, `content`, `footer`

---

## Quick Reference

| Error | Symptom | Fix |
|-------|---------|-----|
| File not found | `error.FileNotFound` | Check file path |
| Extends not first | Duplicate doctypes, mixed content | Move `extends` to line 1 |
| Undefined block | Content silently ignored | Use correct block name from parent |
| Duplicate doctype | `<!DOCTYPE html><!DOCTYPE html>` | Remove doctype from child |

---

## See Also

- [Parent directory](../) - Working examples
- [README.md](../README.md) - Template inheritance documentation
- [Main documentation](../../../README.md) - Full zig-pug syntax
