# Pug Template Engine - Especificación Completa

## Descripción General

Pug es un motor de templates robusto y expresivo que opera mediante un proceso de dos pasos:
1. `pug.compile()` convierte código fuente en una función JavaScript que acepta un objeto de datos ("locals")
2. La función ejecutada produce salida HTML

Las funciones compiladas pueden ser reutilizadas repetidamente con diferentes datasets para eficiencia óptima.

---

## 1. TAGS (Etiquetas)

### Sintaxis Básica
- Pug usa sintaxis basada en indentación sin corchetes angulares
- El texto al inicio de línea representa etiquetas HTML
- Las etiquetas indentadas se anidan, creando la estructura de árbol del HTML

**Ejemplo:**
```pug
div
  p Hola mundo
```
**Salida:** `<div><p>Hola mundo</p></div>`

### Anidamiento y Expansión de Bloques
- Las etiquetas se anidan mediante indentación
- Sintaxis inline compacta: `a: img` produce `<a><img /></a>`

### Etiquetas Auto-Cerradas
- Pug reconoce automáticamente elementos auto-cerrados (`img`, `meta`, `link`)
- Se renderiza como `<img />` sin sintaxis de cierre explícita
- Auto-cierre manual posible con `/` al final

### Manejo de Espacios en Blanco
- Los espacios se eliminan del inicio y fin de etiquetas
- Control fino de espacios depende de características de texto plano de Pug
- Mejora legibilidad y reduce markup repetitivo

---

## 2. ATTRIBUTES (Atributos)

### Sintaxis Básica
```pug
a(href='//google.com') Google
```
**Salida:** `<a href="//google.com">Google</a>`

- Los atributos se parecen a la sintaxis HTML pero los valores son expresiones JavaScript
- Las comas entre atributos son opcionales

### Atributos Multilínea
```pug
input(
  type='checkbox'
  name='agreement'
  checked
)
```
- Template strings de ES2015 funcionan para valores largos

### Atributos Citados
- Nombres de atributos con caracteres especiales (`[]`, `()`) necesitan comillas
- Usar `""` o `''`, o separar atributos con comas

```pug
div(class='div-class', (click)='play()')
div(class='div-class' '(click)'='play()')
```

### Interpolación de Atributos
- NO usar sintaxis antigua: `href="/#{url}"`
- Usar concatenación JavaScript: `a(href='/' + url)`
- Usar template literals: ``a(href=`/path/${variable}`)``

### Tipos Especiales de Atributos

**Atributos No Escapados:**
```pug
div(unescaped!="<code>")
```
**Salida:** `<div unescaped="<code>"></div>`

**Atributos Booleanos:**
- Por defecto `true` cuando no se especifica valor
- `false` omite el atributo completamente

**Objetos de Estilo:**
```pug
a(style={color: 'red', background: 'green'})
```

**Arrays/Objetos de Clase:**
- Soportan arrays, strings, u objetos condicionales mapeando nombres de clase a booleanos

### Sintaxis Abreviada
- **Clases:** `.classname`
- **IDs:** `#idname`
- **Etiqueta por defecto:** `div` cuando se omite

### Spread de &attributes
```pug
div#foo(data-bar="foo")&attributes({'data-foo': 'bar'})
```
**NOTA:** Los atributos aplicados usando `&attributes` NO se escapan automáticamente

---

## 3. INTERPOLATION (Interpolación)

### Interpolación de String - Escapada
Sintaxis: `#{expresión}`

- Evalúa y escapa con seguridad expresiones JavaScript
- Parsing inteligente: determina dónde terminan las expresiones
- Permite caracteres `}` sin necesidad de escape
- Soporta cualquier expresión JavaScript válida
- Permite llamadas a métodos como `.toUpperCase()`

**Ejemplo:**
```pug
p Este es #{msg.toUpperCase()}
```

**Escapar literal:**
- Usar backslashes: `\#{`
- Interpolación anidada: `#{'#{text}'}`

### Interpolación de String - No Escapada
Sintaxis: `!{expresión}`

- Renderiza contenido HTML sin escape
- **ADVERTENCIA:** Puede ser peligroso si el contenido proviene de usuarios
- Solo usar con fuentes de contenido confiables

### Interpolación de Etiquetas
Sintaxis: `#[etiqueta contenido]`

- Inserta etiquetas Pug inline dentro de nodos de texto
- Resuelve problemas de manejo de espacios
- Preserva espacios antes y después de la etiqueta

**Ejemplo:**
```pug
p Esto tiene una palabra #[strong importante]
```

---

## 4. CODE EXECUTION (Ejecución de Código)

Pug permite incrustar JavaScript directamente en templates mediante tres tipos:

### Código No-Bufferizado
Sintaxis: `-`

- No agrega nada directamente a la salida
- Usado para flujo de control, bucles, declaraciones de variables

**Ejemplo:**
```pug
- for (var x = 0; x < 3; x++)
  li item
```

### Código Bufferizado
Sintaxis: `=`

- Evalúa expresiones JavaScript y genera resultados
- Aplica escape HTML automáticamente
- Convierte caracteres como `<` a `&lt;`
- Previene contenido malicioso

**Ejemplo:**
```pug
p= 'Este código está <escapado>!'
```

### Código Bufferizado No-Escapado
Sintaxis: `!=`

- Genera HTML sin escape
- **ADVERTENCIA DE SEGURIDAD:** No realiza ningún escape
- Inseguro para entrada de usuarios
- Riesgo de vulnerabilidades XSS
- Desarrolladores deben sanitizar inputs de usuarios

**Ejemplo:**
```pug
p!= 'Este código <em>no está</em> escapado!'
```

---

## 5. ITERATION (Iteración)

### Bucle Each

**Iteración de Array:**
```pug
each val in [1, 2, 3]
  li= val
```

**Con Índice:**
```pug
each val, index in array
  li= index + ': ' + val
```

**Iteración de Objetos:**
```pug
each val, key in object
  li= key + ': ' + val
```

**Manejo de Estado Vacío:**
```pug
each item in items
  li= item
else
  p No hay items
```

**Alias:** La palabra clave `for` funciona como alternativa intercambiable a `each`

### Bucle While
```pug
- var n = 0
while n < 4
  li= n++
```

---

## 6. CONDITIONALS (Condicionales)

### If/Else If/Else
```pug
if user.role === 'admin'
  p Acceso administrativo
else if user.role === 'member'
  p Acceso de miembro
else
  p Acceso de invitado
```

- Paréntesis opcionales
- Usa JavaScript regular

### Unless
Condicional negado equivalente a `if !`:

```pug
unless user.isAnonymous
  p Estás logueado como #{user.name}
```

Es equivalente a:
```pug
if !user.isAnonymous
  p Estás logueado como #{user.name}
```

---

## 7. CASE (Declaraciones Case)

Shorthand para `switch` de JavaScript:

```pug
- var friends = 10
case friends
  when 0
    p no tienes amigos
  when 1
    p tienes un amigo
  default
    p tienes #{friends} amigos
```

### Fall Through
- Solo ocurre cuando un bloque está completamente ausente
- Para prevenir salida en un caso específico: usar unbuffered `break`

```pug
case friends
  when 0
    - break
  when 1
    p tienes muy pocos amigos
```

### Expansión de Bloques
Sintaxis compacta con dos puntos:
```pug
case friends
  when 0: p no tienes amigos
  when 1: p tienes un amigo
  default: p tienes #{friends} amigos
```

---

## 8. MIXINS (Mixins)

Bloques reutilizables de código Pug compilados como funciones.

### Definición y Llamada
```pug
mixin list
  ul
    li foo
    li bar

+list
```

### Con Argumentos
```pug
mixin pet(name)
  li.pet= name

+pet('cat')
+pet('dog')
```

### Valores por Defecto
```pug
mixin article(title='Artículo sin título')
  .article
    h1= title
```

### Rest Arguments
```pug
mixin list(id, ...items)
  ul(id=id)
    each item in items
      li= item

+list('my-list', 1, 2, 3, 4)
```

### Bloques de Mixin
```pug
mixin article(title)
  .article
    h1= title
    if block
      block
    else
      p Sin contenido

+article('Hola mundo')
  p Este es mi contenido
```

### Manejo de Atributos
- Argumento implícito `attributes` contiene atributos pasados
- Valores en `attributes` ya están escapados
- Usar `!=` para evitar escape doble
- Spread de atributos: `&attributes(attributes)`

```pug
mixin link(href, name)
  a(href=href)&attributes(attributes)= name

+link('/foo', 'foo')(class="btn")
```

---

## 9. INCLUDES (Inclusiones)

Insertan contenido de un archivo Pug en otro para reutilización de código.

### Resolución de Rutas
- **Rutas absolutas** (con `/`): resueltas relativas a `options.basedir`
- **Rutas relativas:** resueltas basándose en archivo actual
- Extensión por defecto: `.pug` cuando se omite

### Tres Métodos de Include

**1. Includes de Archivo Pug:**
```pug
include includes/head.pug
```

**2. Includes de Texto Plano:**
Archivos no-Pug se insertan como texto sin compilar:
```pug
include style.css
include script.js
```

**3. Includes Filtrados:**
Combina includes con filtros para transformación:
```pug
include:markdown-it article.md
```

---

## 10. TEMPLATE INHERITANCE (Herencia de Templates)

Sistema que permite crear estructuras de layout reutilizables.

### Bloques
Define secciones placeholder que templates hijos pueden sobrescribir:

**layout.pug:**
```pug
html
  head
    block head
      title Título por defecto
  body
    block content
    block foot
      #footer
        p Contenido del footer
```

### Extends
Templates hijos heredan de templates padres:

**page.pug:**
```pug
extends layout.pug

block head
  title Mi Página

block content
  h1 ¡Hola!
  p Contenido aquí
```

### Modificación de Bloques

**Append:** Agrega contenido después del contenido existente:
```pug
block append head
  script(src='extra.js')
```

**Prepend:** Inserta contenido antes del contenido existente:
```pug
block prepend head
  meta(name='description')
```

### Restricciones Críticas
- Solo bloques nombrados y definiciones de mixin pueden aparecer en nivel superior (sin indentar) de templates hijos
- Comentarios bufferizados no pueden aparecer en nivel superior de templates que extienden
- Variables necesitadas en templates hijos deben ser:
  - Agregadas a objetos de opciones Pug
  - Definidas en código no-bufferizado del template padre
  - Declaradas dentro de bloques en templates hijos

---

## 11. COMMENTS (Comentarios)

### Comentarios de Línea Simple

**Comentarios Bufferizados:** Aparecen en HTML renderizado
```pug
// solo algunos párrafos
```
**Salida:** `<!-- solo algunos párrafos-->`

**Comentarios No-Bufferizados:** Solo para desarrolladores, no aparecen en HTML
```pug
//- no generará salida en el markup
```

### Comentarios de Bloque
Multi-línea usando misma sintaxis:
```pug
body
  //- Notas del template aquí
  // Los lectores HTML ven esto
```

### Comentarios Condicionales
Pug no tiene sintaxis especial, pero líneas que comienzan con `<` se procesan como texto plano:
```html
<!--[if IE 8]>
<html lang="en" class="lt-ie9">
<![endif]-->
```

---

## 12. FILTERS (Filtros)

Permiten usar otros lenguajes dentro de templates Pug procesando bloques de texto plano.

### Características Clave

**Instalación:**
Filtros populares incluyen `:babel`, `:uglify-js`, `:scss`, `:markdown-it`
Basados en módulos JSTransformer, requieren instalación npm:
```bash
npm install --save jstransformer-coffee-script
```

**Sintaxis:**
```pug
:markdown-it
  # Título
  Este es **markdown**
```

Opciones pasadas en paréntesis después del nombre del filtro.

**Nota de Rendimiento:**
Los filtros se renderizan en tiempo de compilación, haciéndolos rápidos, pero no pueden soportar contenido u opciones dinámicas.

### Características Avanzadas

**Filtros Anidados:**
Múltiples filtros en la misma línea. Procesamiento en orden inverso:
```pug
:coffee-script:babel
```

**Filtros Personalizados:**
Crear filtros personalizados mediante opción `filters` en API de Pug.

**Includes Filtrados:**
```pug
include:markdown-it article.md
```

---

## 13. PLAIN TEXT (Texto Plano)

Existen tres formas de agregar texto plano en Pug:

### Texto Inline
```pug
p Este es texto plano inline
```

### Texto de Bloque
Prefijo con pipe `|`:
```pug
p
  | El pipe siempre va al inicio de su propia línea,
  | no en medio.
```

### Texto de Bloque con Etiqueta en Línea
Todo después de la etiqueta en la misma línea se trata como texto:
```pug
p Este es texto plano con un tag inline.
```

---

## 14. DOCTYPES

Sintaxis abreviada para declaraciones de tipo de documento:

```pug
doctype html
```
**Salida:** `<!DOCTYPE html>`

Otros doctypes comunes:
- `doctype xml` → `<?xml version="1.0" encoding="utf-8" ?>`
- `doctype transitional` → DOCTYPE XHTML 1.0 Transitional
- `doctype strict` → DOCTYPE XHTML 1.0 Strict
- `doctype frameset` → DOCTYPE XHTML 1.0 Frameset
- `doctype 1.1` → DOCTYPE XHTML 1.1
- `doctype basic` → DOCTYPE XHTML Basic 1.1
- `doctype mobile` → DOCTYPE XHTML Mobile 1.2

También se pueden especificar doctypes personalizados:
```pug
doctype html PUBLIC "-//W3C//DTD XHTML Basic 1.1//EN"
```

---

## RESUMEN DE CARACTERÍSTICAS PARA IMPLEMENTACIÓN

### Características Core (Prioridad Alta)
1. Tags con indentación
2. Atributos (básicos, multilínea, spread)
3. Texto plano (inline, block, pipe)
4. Interpolación de strings (escapada y no-escapada)
5. Código bufferizado y no-bufferizado
6. Iteración (each, while)
7. Condicionales (if/else/unless)
8. Comentarios (bufferizados y no-bufferizados)

### Características Avanzadas (Prioridad Media)
9. Case statements
10. Mixins (con argumentos, bloques, atributos)
11. Includes (Pug, texto plano)
12. Template inheritance (extends, blocks, append/prepend)

### Características Adicionales (Prioridad Baja)
13. Filtros (básicos, anidados, personalizados)
14. Doctypes
15. Interpolación de etiquetas
16. Includes filtrados

---

## DIFERENCIAS PROPUESTAS PARA ZIG-PUG

### 1. Sección de JavaScript Puro
- El parser entenderá bloques especiales marcados como JavaScript puro
- Sintaxis propuesta: `js.` o similar prefix para indicar JavaScript sin restricciones
- Permitirá:
  - Condicionales if/else completos
  - Loops for/while/do-while
  - Llamadas a funciones
  - Definición de variables
  - Operaciones complejas

### 2. Formato TOML para Datos
- En lugar de pasar objetos JavaScript/JSON
- Los datos del template se pasarán en formato TOML
- Beneficios:
  - Más legible para configuraciones
  - Tipado más fuerte
  - Mejor para archivos de configuración
  - Sintaxis más limpia

**Ejemplo:**
```toml
[user]
name = "Juan"
role = "admin"
friends = 10

[settings]
theme = "dark"
notifications = true
```

### 3. Mejoras Adicionales Propuestas
- Parser escrito en Zig para máximo rendimiento
- Compilación en tiempo de compilación cuando sea posible
- Sistema de tipos más estricto
- Mejor manejo de errores con mensajes descriptivos
- Integración nativa con ecosystem de Zig
