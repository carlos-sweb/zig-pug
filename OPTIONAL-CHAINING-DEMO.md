# ✨ Optional Chaining en TODO zig-pug - IMPLEMENTADO

## 🎯 Feature Implementada

Ahora puedes usar **optional chaining (`?.`)** en **TODOS LOS CONTEXTOS** de zig-pug:
- ✅ Interpolaciones: `#{user?.name}`
- ✅ Código buffered: `p= user?.name`
- ✅ Atributos: `div(class=user?.theme)`
- ✅ Loops: `each item in user?.items`
- ✅ Condicionales: `if user?.profile?.bio`

## 📝 Sintaxis

```pug
//- En condicionales (if/unless)
if user?.profile?.bio
  p= user.profile.bio

unless user?.suspended
  p Welcome!

//- En loops
each item in obj?.property
  li= item

//- En interpolaciones
p #{user?.name}
p #{user?.profile?.bio}

//- En código buffered
h1= user?.name
p= product?.description

//- En atributos
a(href=user?.website)
div(class=item?.className)
```

## 🔧 Cómo Funciona

### Antes (sin optional chaining):
```pug
if product.hasOwnProperty('tags')
  each tag in product.tags
    li= tag
```

### Ahora (con optional chaining):
```pug
each tag in product?.tags
  li= tag
```

## 🚀 Transformación Interna

Cuando escribes `product?.tags`, zig-pug **automáticamente** lo transforma a:

```javascript
product && product.hasOwnProperty('tags') ? product.tags : []
```

Esta transformación ocurre **antes** de enviar el código a mujs, por lo que:
- ✅ Compatible con ES5.1 (mujs)
- ✅ No requiere cambios en mujs
- ✅ Sintaxis moderna para el usuario

## 📊 Ejemplos

### Ejemplo 1: Interpolaciones

**Template:**
```pug
p Usuario: #{user?.name}
p Bio: #{user?.profile?.bio}
p Ciudad: #{user?.profile?.location?.city}
```

**JavaScript Context:**
```javascript
var user = {
  name: "Alice",
  profile: {bio: "Engineer", location: {city: "NYC"}}
};
```

**HTML Generado:**
```html
<p>Usuario: Alice</p>
<p>Bio: Engineer</p>
<p>Ciudad: NYC</p>
```

Si `user` no tiene `profile`:
```html
<p>Usuario: Alice</p>
<p>Bio: </p>
<p>Ciudad: </p>
```
**Sin errores** ✅

### Ejemplo 2: Código Buffered

**Template:**
```pug
h1= user?.name
p= product?.description
div= item?.details?.summary
```

### Ejemplo 3: Atributos

**Template:**
```pug
a(href=user?.website target="_blank") Website
div(class=product?.category?.slug)
img(src=item?.image?.url alt=item?.image?.alt)
```

### Ejemplo 4: Producto con tags opcionales (Loops)

**Template:**
```pug
ul.tags
  each tag in product?.tags
    li.tag= tag
```

**JavaScript Context:**
```javascript
var product = {name: "Laptop", tags: ["electronics", "tech"]};
```

**HTML Generado:**
```html
<ul class="tags">
  <li class="tag">electronics</li>
  <li class="tag">tech</li>
</ul>
```

### Ejemplo 2: Producto sin tags (no error)

**JavaScript Context:**
```javascript
var product = {name: "Book"};  // No tiene 'tags'
```

**HTML Generado:**
```html
<ul class="tags"></ul>
```

**Sin errores** ✅ - El loop simplemente no se ejecuta.

### Ejemplo 3: Optional Chaining Anidado

**Template:**
```pug
each item in data?.products?.featured
  li= item
```

**Transformado a:**
```javascript
data && data.hasOwnProperty('products') &&
data.products.hasOwnProperty('featured') ?
data.products.featured : []
```

## 🧪 Tests Incluidos

```bash
zig test src/compiler/optional_chaining.zig
```

**Resultados:**
```
✅ optional chaining - simple case
✅ optional chaining - nested case
✅ optional chaining - no operator
✅ optional chaining - with regular dot
✅ optional chaining - three levels
All 5 tests passed.
```

## 📁 Archivos Modificados

1. **`src/compiler/optional_chaining.zig`** (NUEVO)
   - Función `transformOptionalChaining()`
   - Detecta `?.` y transforma a ES5.1

2. **`src/compiler/mod.zig`** (MODIFICADO)
   - Línea 60: Import del transformer
   - Aplicación de transformación en 5 contextos:
     - `compileConditional()`: Condicionales if/unless
     - `compileLoop()`: Loops each/while
     - `compileInterpolation()`: Interpolaciones #{}
     - `compileCode()`: Código buffered (p=)
     - `compileTag()`: Atributos (div(class=))

## 🎨 Casos de Uso Reales

### E-commerce con productos variables
```pug
each product in products
  div.product
    h3= product.name
    //- Algunos productos tienen imágenes, otros no
    each img in product?.images
      img(src=img)
    //- Algunos tienen reviews, otros no
    each review in product?.reviews
      p.review= review.text
```

### Blog con metadata opcional
```pug
each post in posts
  article
    h2= post.title
    //- No todos los posts tienen tags
    each tag in post?.tags
      span.tag= tag
    //- No todos tienen categorías
    each cat in post?.categories
      span.category= cat
```

### Condicionales con datos opcionales
```pug
//- Mostrar bio solo si existe
if user?.profile?.bio
  div.bio
    h3 Biografía
    p= user.profile.bio

//- Mostrar notificaciones si están habilitadas
if user?.settings?.notifications
  div.notifications
    p 🔔 Tienes notificaciones habilitadas

//- Unless para verificar que NO existe algo
unless user?.suspended
  div.welcome
    p Bienvenido, #{user.name}!

//- Antes (verbose)
if user && user.hasOwnProperty('profile') && user.profile.hasOwnProperty('bio')
  p= user.profile.bio

//- Después (limpio)
if user?.profile?.bio
  p= user.profile.bio
```

## 💡 Ventajas

1. **Código más limpio** - No necesitas `if hasOwnProperty` antes de cada loop
2. **Menos errores** - No falla si la propiedad no existe
3. **Sintaxis moderna** - Usa ES2020 syntax aunque mujs sea ES5.1
4. **Sin dependencias** - Transformación nativa en Zig
5. **Performance** - Transformación en compile-time, no runtime

## ⚙️ Implementación Técnica

**Complejidad:** 3/10 ✅
**Archivos nuevos:** 1 (~165 líneas)
**Archivos modificados:** 1 (~10 líneas)
**Tests:** 5 tests unitarios

## 🎯 Siguiente Paso

¡Ya está listo para usar! Prueba en tu proyecto:

```bash
zig build
```

---

**Implementado por:** Claude Code 🤖
**Dificultad real:** 3/10 (como prometido)
**Estado:** ✅ COMPLETADO
