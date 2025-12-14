# Example 01: Basic Tags and Attributes

**Difficulty:** ⭐ Easy
**Category:** Fundamentos
**Time:** 5 minutes

## 📝 What You'll Learn

- Basic tag syntax
- Classes with `.` notation
- IDs with `#` notation
- Attributes with `()`
- Nesting with indentation
- HTML doctype

## 📄 Source Code

**File:** `examples/01-basic.zpug`

```zpug
// Ejemplo 1: Tags y atributos básicos
// Este ejemplo muestra la sintaxis básica de Pug

doctype html
html(lang="es")
  head
    meta(charset="UTF-8")
    title Mi Primera Página
  body
    h1 Bienvenido a zig-pug
    p Este es un párrafo simple
    p.destacado Este párrafo tiene una clase
    p#importante Este párrafo tiene un ID
    div.container
      p Contenido dentro de un div
```

## 🎯 Key Concepts

### 1. Doctype Declaration

```zpug
doctype html
```

**Generates:**
```html
<!DOCTYPE html>
```

**Note:** Always start HTML documents with `doctype html` for HTML5.

---

### 2. Tags with Attributes

```zpug
html(lang="es")
meta(charset="UTF-8")
```

**Generates:**
```html
<html lang="es">
<meta charset="UTF-8">
```

**Syntax:** `tag(attribute="value")`

---

### 3. Tags with Text Content

```zpug
title Mi Primera Página
h1 Bienvenido a zig-pug
p Este es un párrafo simple
```

**Generates:**
```html
<title>Mi Primera Página</title>
<h1>Bienvenido a zig-pug</h1>
<p>Este es un párrafo simple</p>
```

**Syntax:** `tag Content goes here`

---

### 4. Classes with Dot Notation

```zpug
p.destacado Este párrafo tiene una clase
```

**Generates:**
```html
<p class="destacado">Este párrafo tiene una clase</p>
```

**Syntax:** `tag.className`

---

### 5. IDs with Hash Notation

```zpug
p#importante Este párrafo tiene un ID
```

**Generates:**
```html
<p id="importante">Este párrafo tiene un ID</p>
```

**Syntax:** `tag#idName`

---

### 6. Nesting with Indentation

```zpug
div.container
  p Contenido dentro de un div
```

**Generates:**
```html
<div class="container">
  <p>Contenido dentro de un div</p>
</div>
```

**Rule:** Use **2 spaces** or **1 tab** for each level of nesting.

---

## 🖥️ Run This Example

```bash
# Compile to stdout
zpug examples/01-basic.zpug

# Compile to file
zpug examples/01-basic.zpug -o output.html

# Pretty print
zpug -p examples/01-basic.zpug
```

## 📤 Expected Output

```html
<!DOCTYPE html><html lang="es"><head><meta charset="UTF-8"><title>Mi Primera Página</title></head><body><h1>Bienvenido a zig-pug</h1><p>Este es un párrafo simple</p><p class="destacado">Este párrafo tiene una clase</p><p id="importante">Este párrafo tiene un ID</p><div class="container"><p>Contenido dentro de un div</p></div></body></html>
```

## ✅ Exercise

Try creating your own basic page:

```zpug
doctype html
html(lang="en")
  head
    meta(charset="UTF-8")
    title My First Page
  body
    h1 Hello World
    p.intro This is my first zig-pug template
    div#content
      p Some content here
```

## 🔗 What's Next?

**Next Example:** [02-interpolation.md](02-interpolation.md) - Learn how to use variables and JavaScript expressions

**Learning Path:** [INDEX.md](INDEX.md)
