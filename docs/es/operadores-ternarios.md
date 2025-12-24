# Operadores Ternarios en Expresiones de Atributos

Zig-Pug soporta operadores condicionales ternarios (`? :`) en expresiones de atributos, permitiéndote escribir valores de atributos dinámicos y condicionales de forma inline.

## Tabla de Contenidos

- [Sintaxis Básica](#sintaxis-básica)
- [Ejemplos Simples](#ejemplos-simples)
- [Operadores de Comparación](#operadores-de-comparación)
- [Operadores Lógicos](#operadores-lógicos)
- [Expresiones Complejas](#expresiones-complejas)
- [Operadores Ternarios Anidados](#operadores-ternarios-anidados)
- [Mejores Prácticas](#mejores-prácticas)

## Sintaxis Básica

El operador ternario sigue la sintaxis estándar de JavaScript:

```pug
elemento(atributo=condicion ? valorSiVerdadero : valorSiFalso)
```

**Componentes:**
- `condicion`: Cualquier expresión que evalúe a un booleano
- `?`: El operador ternario
- `valorSiVerdadero`: Valor usado cuando la condición es verdadera
- `:`: Separador
- `valorSiFalso`: Valor usado cuando la condición es falsa

## Ejemplos Simples

### Variable Booleana

```pug
- var isActive = true
div(class=isActive ? "active" : "inactive")
```

**Salida:**
```html
<div class="active"></div>
```

### Con Contenido de Texto

```pug
- var loggedIn = false
button(class=loggedIn ? "logout-btn" : "login-btn") Clic aquí
```

**Salida:**
```html
<button class="login-btn">Clic aquí</button>
```

### Múltiples Atributos

```pug
- var enabled = true
button(
  class=enabled ? "btn-primary" : "btn-disabled",
  type="submit"
) Enviar
```

**Salida:**
```html
<button class="btn-primary" type="submit">Enviar</button>
```

## Operadores de Comparación

Los operadores ternarios funcionan con todos los operadores de comparación:

### Mayor Que (`>`)

```pug
- var score = 85
p(class=score > 80 ? "excelente" : "bueno") Tu puntuación
```

**Salida:**
```html
<p class="excelente">Tu puntuación</p>
```

### Menor Que (`<`)

```pug
- var temperatura = 15
div(class=temperatura < 20 ? "frio" : "calido") Clima
```

**Salida:**
```html
<div class="frio">Clima</div>
```

### Mayor o Igual (`>=`)

```pug
- var edad = 18
span(title=edad >= 18 ? "adulto" : "menor") Estado de usuario
```

**Salida:**
```html
<span title="adulto">Estado de usuario</span>
```

### Menor o Igual (`<=`)

```pug
- var stock = 5
div(data-status=stock <= 10 ? "stock-bajo" : "en-stock") Inventario
```

**Salida:**
```html
<div data-status="stock-bajo">Inventario</div>
```

### Igualdad (`==`)

```pug
- var tema = "oscuro"
body(class=tema == "oscuro" ? "modo-oscuro" : "modo-claro")
```

**Salida:**
```html
<body class="modo-oscuro"></body>
```

## Operadores Lógicos

Combina condiciones con operadores lógicos para expresiones más complejas.

### Operador AND (`&&`)

```pug
- var sesionIniciada = true
- var tienePermiso = true
div(class=sesionIniciada && tienePermiso ? "autorizado" : "no-autorizado") Contenido
```

**Salida:**
```html
<div class="autorizado">Contenido</div>
```

### Operador OR (`||`)

```pug
- var esAdmin = false
- var esModerador = true
span(data-role=esAdmin || esModerador ? "staff" : "usuario") Insignia
```

**Salida:**
```html
<span data-role="staff">Insignia</span>
```

### Operadores Lógicos Combinados

```pug
- var edad = 25
- var tieneLicencia = true
div(class=edad >= 18 && tieneLicencia ? "puede-conducir" : "no-puede-conducir") Estado de conductor
```

**Salida:**
```html
<div class="puede-conducir">Estado de conductor</div>
```

## Expresiones Complejas

### Acceso a Propiedades

```pug
- var usuario = { nombre: "Alicia", edad: 30, rol: "admin" }
span(title=usuario.edad >= 18 ? "adulto" : "menor") #{usuario.nombre}
a(href=usuario.rol == "admin" ? "/admin" : "/dashboard") Panel
```

**Salida:**
```html
<span title="adulto">Alicia</span>
<a href="/admin">Panel</a>
```

### Expresiones Aritméticas

```pug
- var conteo = 5
- var umbral = 3
p(data-level=conteo + 2 > umbral ? "alto" : "bajo") Conteo de items
```

**Salida:**
```html
<p data-level="alto">Conteo de items</p>
```

### Literales Booleanos

```pug
- var items = 0
input(type="checkbox", disabled=items < 1 ? true : false)
```

**Salida:**
```html
<input type="checkbox" disabled="true">
```

### Concatenación de Strings en Valores

```pug
- var estado = "activo"
div(class=estado == "activo" ? "estado-" + estado : "estado-inactivo") Estado
```

**Salida:**
```html
<div class="estado-activo">Estado</div>
```

## Operadores Ternarios Anidados

Puedes anidar operadores ternarios para condiciones multinivel.

### Ternario Anidado Simple

```pug
- var puntuacion = 75
p(class=puntuacion >= 90 ? "A" : puntuacion >= 70 ? "B" : "C") Calificación
```

**Salida:**
```html
<p class="B">Calificación</p>
```

### Ejemplo Anidado Complejo

```pug
- var prioridad = 2
- var urgente = false
div(
  class=prioridad == 1 ? "critico" : prioridad == 2 && urgente ? "alto" : prioridad == 2 ? "medio" : "bajo"
) Tarea
```

**Salida:**
```html
<div class="medio">Tarea</div>
```

### Multi-nivel Anidado

```pug
- var valor = 7
span(
  data-categoria=valor > 10 ? "alto" : valor > 5 ? "medio" : valor > 0 ? "bajo" : "ninguno"
) Categoría
```

**Salida:**
```html
<span data-categoria="medio">Categoría</span>
```

## Mejores Prácticas

### 1. Mantén la Legibilidad

**Bueno:**
```pug
- var activo = true
div(class=activo ? "activo" : "inactivo")
```

**Evitar (demasiado complejo):**
```pug
div(class=a && b || c ? d == e ? f : g && h ? i : j : k)
```

### 2. Usa Variables para Condiciones Complejas

**Bueno:**
```pug
- var puedeEditar = usuario.rol == "admin" || usuario.rol == "editor"
button(disabled=puedeEditar ? false : true) Editar
```

**Menos legible:**
```pug
button(disabled=usuario.rol == "admin" || usuario.rol == "editor" ? false : true)
```

### 3. Limita la Profundidad de Anidamiento

Para más de 2 niveles de anidamiento, considera usar sentencias if/else en su lugar:

**Bueno:**
```pug
- var nombreClase
- if puntuacion >= 90
  - nombreClase = "A"
- else if puntuacion >= 70
  - nombreClase = "B"
- else
  - nombreClase = "C"
p(class=nombreClase) Calificación
```

### 4. Sé Explícito con Valores Booleanos

**Bueno:**
```pug
input(disabled=conteo < 1 ? true : false)
```

**También aceptable:**
```pug
- var estaDeshabilitado = conteo < 1
input(disabled=estaDeshabilitado)
```

### 5. Usa Nombres de Variables Significativos

**Bueno:**
```pug
- var usuarioActivo = usuario.estado == "activo"
div(class=usuarioActivo ? "en-linea" : "desconectado")
```

**Evitar:**
```pug
div(class=u.e == "a" ? "on" : "off")
```

## Ejemplo Completo

Aquí hay un ejemplo comprehensivo usando varias características de operadores ternarios:

```pug
- var usuario = { nombre: "Alicia", edad: 30, rol: "admin", activo: true }
- var conteoItems = 5
- var tema = "oscuro"

.tarjeta-usuario(class=usuario.activo && conteoItems > 0 ? "usuario-activo" : "usuario-inactivo")
  h2(class=tema == "oscuro" ? "texto-claro" : "texto-oscuro") #{usuario.nombre}

  span.edad(title=usuario.edad >= 18 ? "adulto" : "menor") Edad: #{usuario.edad}

  .insignia(class=usuario.rol == "admin" ? "insignia-admin" : usuario.rol == "editor" ? "insignia-editor" : "insignia-usuario")= usuario.rol

  .items(data-status=conteoItems > 10 ? "muchos" : conteoItems > 0 ? "algunos" : "ninguno")
    | Items: #{conteoItems}

  a.enlace-panel(href=usuario.rol == "admin" || usuario.rol == "moderador" ? "/admin" : "/usuario") Panel
```

**Salida:**
```html
<div class="tarjeta-usuario usuario-activo">
  <h2 class="texto-claro">Alicia</h2>
  <span class="edad" title="adulto">Edad: 30</span>
  <div class="insignia insignia-admin">admin</div>
  <div class="items" data-status="algunos">Items: 5</div>
  <a class="enlace-panel" href="/admin">Panel</a>
</div>
```

## Ver También

- [Documentación de Atributos](atributos.md)
- [Expresiones e Interpolación](interpolacion.md)
- [Documentación del Tokenizador](tokenizador.md)
- [Documentación del Parser](parser.md)
