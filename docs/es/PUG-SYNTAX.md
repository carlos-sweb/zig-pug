# Referencia de Sintaxis Pug

[English](../en/PUG-SYNTAX.md) | Español

Guía completa de la sintaxis de plantillas Pug soportada por zig-pug.

---

## Tabla de Contenidos

1. [Etiquetas Básicas](#etiquetas-básicas)
2. [Atributos](#atributos)
3. [Clases e IDs](#clases-e-ids)
4. [Contenido de Texto](#contenido-de-texto)
5. [Interpolación](#interpolación)
6. [Condicionales](#condicionales)
7. [Bucles](#bucles)
8. [Mixins](#mixins)
9. [Herencia de Plantillas](#herencia-de-plantillas)
10. [Comentarios](#comentarios)
11. [Código](#código)

---

## Etiquetas Básicas

### Etiquetas Simples

```pug
p
div
span
h1
```

Salida:
```html
<p></p>
<div></div>
<span></span>
<h1></h1>
```

### Etiquetas Anidadas

```pug
html
  head
    title My Page
  body
    h1 Hello World
    p Welcome to zig-pug
```

Salida:
```html
<html>
  <head>
    <title>My Page</title>
  </head>
  <body>
    <h1>Hello World</h1>
    <p>Welcome to zig-pug</p>
  </body>
</html>
```

### Etiquetas Auto-Cerradas

```pug
img
br
hr
input
meta
link
```

Salida:
```html
<img/>
<br/>
<hr/>
<input/>
<meta/>
<link/>
```

---

## Atributos

### Atributos Básicos

```pug
a(href="/home") Home
img(src="logo.png" alt="Logo")
input(type="text" name="username")
```

Salida:
```html
<a href="/home">Home</a>
<img src="logo.png" alt="Logo"/>
<input type="text" name="username"/>
```

### Múltiples Atributos

```pug
a(
  href="/about"
  class="nav-link"
  target="_blank"
  rel="noopener"
) About Us
```

Salida:
```html
<a href="/about" class="nav-link" target="_blank" rel="noopener">About Us</a>
```

### Atributos Entre Comillas

```pug
div(data-value="Hello World")
a(title="Visit 'Example' site")
```

Salida:
```html
<div data-value="Hello World"></div>
<a title="Visit 'Example' site"></a>
```

### Atributos Dinámicos

```pug
//- With variables
a(href=linkUrl) Click
img(src=imagePath alt=imageAlt)

//- With expressions
div(class="btn-" + buttonType)
input(value=count * 2)
```

---

## Clases e IDs

### Abreviatura de Clase

```pug
div.container
p.text-primary
span.badge.rounded
```

Salida:
```html
<div class="container"></div>
<p class="text-primary"></p>
<span class="badge rounded"></span>
```

### Abreviatura de ID

```pug
div#header
section#main-content
footer#page-footer
```

Salida:
```html
<div id="header"></div>
<section id="main-content"></section>
<footer id="page-footer"></footer>
```

### Clase e ID Combinados

```pug
div#app.container.fluid
h1#title.text-center.fw-bold Header
```

Salida:
```html
<div id="app" class="container fluid"></div>
<h1 id="title" class="text-center fw-bold">Header</h1>
```

### Clase con Atributos

```pug
a.btn.btn-primary(href="/submit") Submit
input.form-control(type="email" name="email")
```

Salida:
```html
<a class="btn btn-primary" href="/submit">Submit</a>
<input class="form-control" type="email" name="email"/>
```

### Div Implícito (Solo Atributos)

Puedes crear un tag `<div>` usando solo atributos, sin especificar una clase o ID:

```pug
(data-role="container" data-theme="dark") Contenido
(style="color: red;") Div con estilos
```

Salida:
```html
<div data-role="container" data-theme="dark">Contenido</div>
<div style="color: red;">Div con estilos</div>
```

### Todos los Atajos de Div Implícito

```pug
//- Todos estos crean tags <div>:
.container Contenido                      // div con clase
#header Contenido                         // div con id
(data-test="value") Contenido             // div solo con atributos
.box#main(data-role="primary") Contenido  // div con los tres
```

Salida:
```html
<div class="container">Contenido</div>
<div id="header">Contenido</div>
<div data-test="value">Contenido</div>
<div id="main" class="box" data-role="primary">Contenido</div>
```

---

## Contenido de Texto

### Texto en Línea

```pug
p This is a paragraph
h1 Welcome to zig-pug
span Small text
```

Salida:
```html
<p>This is a paragraph</p>
<h1>Welcome to zig-pug</h1>
<span>Small text</span>
```

### Texto con Pipes

```pug
p
  | This is a longer paragraph.
  | It spans multiple lines.
  | Each line starts with a pipe.
```

Salida:
```html
<p>This is a longer paragraph. It spans multiple lines. Each line starts with a pipe.</p>
```

### Soporte UTF-8

```pug
p Hello 世界 🌍
p Acentos: á é í ó ú ñ ü
p Emoji: 🎉 🚀 ✨ 💯
```

Salida:
```html
<p>Hello 世界 🌍</p>
<p>Acentos: á é í ó ú ñ ü</p>
<p>Emoji: 🎉 🚀 ✨ 💯</p>
```

---

## Interpolación

### Interpolación de Variables

```pug
//- Variables: name = "Alice", age = 25
p Hello #{name}!
p You are #{age} years old.
```

Salida:
```html
<p>Hello Alice!</p>
<p>You are 25 years old.</p>
```

### Interpolación de Expresiones

```pug
//- Variables: x = 5, y = 10
p Sum: #{x + y}
p Double: #{x * 2}
p Message: #{x > 3 ? "Big" : "Small"}
```

Salida:
```html
<p>Sum: 15</p>
<p>Double: 10</p>
<p>Message: Big</p>
```

### Llamadas a Métodos

```pug
//- Variables: text = "hello"
p Uppercase: #{text.toUpperCase()}
p Length: #{text.length}
```

Salida:
```html
<p>Uppercase: HELLO</p>
<p>Length: 5</p>
```

### Escapado

```pug
//- Variables: html = "<script>alert('xss')</script>"
p Safe: #{html}
p Unsafe: !{html}
```

Salida:
```html
<p>Safe: &lt;script&gt;alert('xss')&lt;/script&gt;</p>
<p>Unsafe: <script>alert('xss')</script></p>
```

---

## Condicionales

### Sentencia If

```pug
//- Variable: isLoggedIn = true
if isLoggedIn
  p Welcome back!
```

Salida (cuando es verdadero):
```html
<p>Welcome back!</p>
```

### If-Else

```pug
//- Variable: hasPermission = false
if hasPermission
  button Edit
else
  button View Only
```

Salida:
```html
<button>View Only</button>
```

### If-Else If-Else

```pug
//- Variable: role = "admin"
if role === "admin"
  p Admin Panel
else if role === "moderator"
  p Moderator Tools
else
  p User Dashboard
```

Salida:
```html
<p>Admin Panel</p>
```

### Unless

```pug
//- Variable: isDisabled = false
unless isDisabled
  button Click Me
```

Salida:
```html
<button>Click Me</button>
```

---

## Bucles

### Each con Arrays

```pug
//- Variable: items = ["Apple", "Banana", "Cherry"]
ul
  each item in items
    li= item
```

Salida:
```html
<ul>
  <li>Apple</li>
  <li>Banana</li>
  <li>Cherry</li>
</ul>
```

### Each con Índice

```pug
//- Variable: colors = ["Red", "Green", "Blue"]
ul
  each color, index in colors
    li #{index + 1}. #{color}
```

Salida:
```html
<ul>
  <li>1. Red</li>
  <li>2. Green</li>
  <li>3. Blue</li>
</ul>
```

### Bucle While

```pug
//- Variable: n = 3
ul
  while n > 0
    li Item #{n}
    - n--
```

Salida:
```html
<ul>
  <li>Item 3</li>
  <li>Item 2</li>
  <li>Item 1</li>
</ul>
```

---

## Mixins

### Mixin Simple

```pug
mixin greeting
  p Hello World!

+greeting
+greeting
```

Salida:
```html
<p>Hello World!</p>
<p>Hello World!</p>
```

### Mixin con Argumentos

```pug
mixin button(text, type)
  button(class="btn-" + type)= text

+button("Submit", "primary")
+button("Cancel", "secondary")
```

Salida:
```html
<button class="btn-primary">Submit</button>
<button class="btn-secondary">Cancel</button>
```

### Mixin con Múltiples Parámetros

```pug
mixin card(title, description, link)
  div.card
    h3= title
    p= description
    a(href=link) Learn More

+card("Feature 1", "Amazing feature", "/feature1")
+card("Feature 2", "Another great feature", "/feature2")
```

Salida:
```html
<div class="card">
  <h3>Feature 1</h3>
  <p>Amazing feature</p>
  <a href="/feature1">Learn More</a>
</div>
<div class="card">
  <h3>Feature 2</h3>
  <p>Another great feature</p>
  <a href="/feature2">Learn More</a>
</div>
```

---

## Herencia de Plantillas

### Plantilla Base (layout.pug)

```pug
doctype html
html
  head
    title #{pageTitle}
    block styles
  body
    header
      block header
        h1 Default Header
    main
      block content
    footer
      block footer
        p © 2025
```

### Plantilla Hija (page.pug)

```pug
extends layout.pug

block header
  h1 Custom Page Header

block content
  p This is the main content
  p Another paragraph

block footer
  p Custom footer
  p Contact us
```

Salida:
```html
<!DOCTYPE html>
<html>
  <head>
    <title></title>
  </head>
  <body>
    <header>
      <h1>Custom Page Header</h1>
    </header>
    <main>
      <p>This is the main content</p>
      <p>Another paragraph</p>
    </main>
    <footer>
      <p>Custom footer</p>
      <p>Contact us</p>
    </footer>
  </body>
</html>
```

---

## Comentarios

### Comentarios de Una Línea

```pug
// This comment appears in HTML
p Visible content
//- This comment does NOT appear in HTML
p More content
```

Salida:
```html
<!-- This comment appears in HTML -->
<p>Visible content</p>
<p>More content</p>
```

### Comentarios de Documentación

```pug
//! Template: homepage.pug
//! Author: Team
//! Description: Main landing page

doctype html
html
  body
    h1 Homepage
```

Salida:
```html
<!DOCTYPE html>
<html>
  <body>
    <h1>Homepage</h1>
  </body>
</html>
```

*Nota: Los comentarios `//!` son para documentación y son ignorados por el analizador*

---

## Código

### Código con Buffer (=)

```pug
//- Variable: username = "Alice"
p= username
div= "Static text"
```

Salida:
```html
<p>Alice</p>
<div>Static text</div>
```

### Código con Buffer Sin Escapar (!=)

```pug
//- Variable: html = "<strong>Bold</strong>"
p!= html
```

Salida:
```html
<p><strong>Bold</strong></p>
```

### Código Sin Buffer (-)

```pug
- var localVar = "Hello"
- var count = 42

p #{localVar}
p Count: #{count}
```

Salida:
```html
<p>Hello</p>
<p>Count: 42</p>
```

---

## Doctype

### HTML5

```pug
doctype html
```

Salida:
```html
<!DOCTYPE html>
```

### Otros Doctypes

```pug
doctype xml
doctype transitional
doctype strict
doctype frameset
doctype 1.1
doctype basic
doctype mobile
```

---

## Mejores Prácticas

1. **Indentación** - Usa 2 espacios (consistente)
2. **Comillas** - Usa comillas dobles para atributos
3. **Variables** - Nombres claros y descriptivos
4. **Comentarios** - Documenta la lógica compleja
5. **Mixins** - Reutiliza patrones comunes
6. **Herencia** - Usa para diseños de página

---

## Ver También

- [Comenzando](GETTING-STARTED.md)
- [Referencia de API](API-REFERENCE.md)
- [Ejemplos](EXAMPLES.md)
- [Documentación CLI](CLI.md)

---

**Última Actualización:** 2025-12-16
