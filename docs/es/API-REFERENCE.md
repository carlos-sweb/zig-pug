# Referencia de la API

[English](../en/API-REFERENCE.md) | Español

Documentación completa de la API para zig-pug.

---

## Tabla de Contenidos

1. [API de Node.js](#api-de-nodejs)
   - [Clase PugCompiler](#clase-pugcompiler)
   - [Funciones Independientes](#funciones-independientes)
2. [API de CLI](#api-de-cli)
3. [API del Paquete Zig](#api-del-paquete-zig)

---

## API de Node.js

### Instalación

```bash
npm install zig-pug
```

### Importación

#### CommonJS

```javascript
const { PugCompiler, compile, compileFile } = require('zig-pug');
```

#### Módulos ES

```javascript
import { PugCompiler, compile, compileFile } from 'zig-pug';
```

---

## Clase PugCompiler

La clase principal para compilar plantillas Pug con variables.

### Constructor

```javascript
new PugCompiler()
```

Crea una nueva instancia del compilador con un contexto de variables vacío.

**Ejemplo:**

```javascript
const compiler = new PugCompiler();
```

---

### Métodos

#### `set(key, value)`

Establece una variable de tipo string o number.

**Parámetros:**
- `key` (string) - Nombre de la variable
- `value` (string | number) - Valor de la variable

**Devuelve:** `PugCompiler` (encadenable)

**Ejemplo:**

```javascript
compiler.set('title', 'My Page');
compiler.set('year', 2025);
compiler.set('version', 1.5);
```

**Encadenable:**

```javascript
compiler
  .set('name', 'Alice')
  .set('age', 30)
  .set('score', 95.5);
```

---

#### `setBool(key, value)`

Establece una variable booleana.

**Parámetros:**
- `key` (string) - Nombre de la variable
- `value` (boolean) - Valor booleano

**Devuelve:** `PugCompiler` (encadenable)

**Ejemplo:**

```javascript
compiler.setBool('isActive', true);
compiler.setBool('hasPermission', false);
```

**Encadenable:**

```javascript
compiler
  .setBool('isLoggedIn', true)
  .setBool('isDarkMode', false);
```

---

#### `setArray(key, value)`

Establece una variable de tipo array.

**Parámetros:**
- `key` (string) - Nombre de la variable
- `value` (Array) - Array de strings, números o booleanos

**Devuelve:** `PugCompiler` (encadenable)

**Ejemplo:**

```javascript
compiler.setArray('items', ['Apple', 'Banana', 'Cherry']);
compiler.setArray('numbers', [1, 2, 3, 4, 5]);
compiler.setArray('flags', [true, false, true]);
```

**Arrays mixtos:**

```javascript
// Nota: Los arrays pueden contener tipos mixtos
compiler.setArray('mixed', ['text', 42, true]);
```

---

#### `setObject(key, value)`

Establece una variable de tipo objeto.

**Parámetros:**
- `key` (string) - Nombre de la variable
- `value` (Object) - Objeto con valores string, number o boolean

**Devuelve:** `PugCompiler` (encadenable)

**Ejemplo:**

```javascript
compiler.setObject('user', {
  name: 'Alice',
  age: 30,
  isAdmin: true
});

compiler.setObject('config', {
  theme: 'dark',
  fontSize: 14,
  autoSave: true
});
```

**Objetos anidados:**

```javascript
// Nota: Los objetos anidados están soportados
compiler.setObject('settings', {
  ui: {
    theme: 'dark',
    lang: 'en'
  },
  features: {
    notifications: true,
    autoplay: false
  }
});
```

---

#### `compile(template)`

Compila una cadena de plantilla Pug a HTML.

**Parámetros:**
- `template` (string) - Código de plantilla Pug

**Devuelve:** `string` - HTML compilado

**Lanza:** `Error` si la compilación falla

**Ejemplo:**

```javascript
const compiler = new PugCompiler();
compiler.set('name', 'World');

const html = compiler.compile('p Hello #{name}!');
console.log(html);
// <p>Hello World!</p>
```

**Con variables:**

```javascript
const compiler = new PugCompiler();
compiler
  .set('title', 'My Blog')
  .set('author', 'Alice')
  .setBool('published', true)
  .setArray('tags', ['javascript', 'node', 'pug']);

const template = `
doctype html
html
  head
    title= title
  body
    h1= title
    p By #{author}
    if published
      p.status Published
    ul
      each tag in tags
        li= tag
`;

const html = compiler.compile(template);
```

---

#### `compileFile(filePath)`

Compila un archivo de plantilla Pug a HTML.

**Parámetros:**
- `filePath` (string) - Ruta al archivo .pug

**Devuelve:** `string` - HTML compilado

**Lanza:** `Error` si el archivo no se encuentra o la compilación falla

**Ejemplo:**

```javascript
const compiler = new PugCompiler();
compiler.set('pageTitle', 'Home Page');

const html = compiler.compileFile('templates/home.pug');
```

---

## Funciones Independientes

Funciones de conveniencia para compilación rápida sin crear una instancia del compilador.

### `compile(template, variables)`

Compila una cadena de plantilla con variables.

**Parámetros:**
- `template` (string) - Código de plantilla Pug
- `variables` (Object) - Objeto de variables opcional

**Devuelve:** `string` - HTML compilado

**Ejemplo:**

```javascript
const { compile } = require('zig-pug');

const html = compile('p Hello #{name}!', { name: 'Alice' });
console.log(html);
// <p>Hello Alice!</p>
```

**Con múltiples variables:**

```javascript
const html = compile(
  `
  h1= title
  p Count: #{count}
  if active
    p.status Active
  `,
  {
    title: 'Dashboard',
    count: 42,
    active: true
  }
);
```

---

### `compileFile(filePath, variables)`

Compila un archivo de plantilla con variables.

**Parámetros:**
- `filePath` (string) - Ruta al archivo .pug
- `variables` (Object) - Objeto de variables opcional

**Devuelve:** `string` - HTML compilado

**Ejemplo:**

```javascript
const { compileFile } = require('zig-pug');

const html = compileFile('templates/page.pug', {
  title: 'About Us',
  year: 2025
});
```

---

## Referencia de Tipos de Variables

### Tipos Soportados

| Tipo | Método | Ejemplo |
|------|--------|---------|
| **String** | `set()` | `compiler.set('name', 'Alice')` |
| **Number** | `set()` | `compiler.set('age', 30)` |
| **Boolean** | `setBool()` | `compiler.setBool('active', true)` |
| **Array** | `setArray()` | `compiler.setArray('items', [1,2,3])` |
| **Object** | `setObject()` | `compiler.setObject('user', {name: 'Alice'})` |

### Acceso a Variables en Plantillas

```pug
//- Interpolación de strings
p Hello #{name}

//- Operaciones numéricas
p Age in 5 years: #{age + 5}

//- Condiciones booleanas
if isActive
  p Active

//- Iteración de arrays
each item in items
  li= item

//- Propiedades de objetos
p Name: #{user.name}
p Age: #{user.age}
```

---

## API de CLI

### Instalación

```bash
# Clonar y compilar
git clone https://github.com/carlos-sweb/zig-pug
cd zig-pug
zig build
```

### Uso Básico

```bash
zpug template.pug
zpug template.pug -o output.html
zpug --help
```

### Opciones

| Opción | Descripción |
|--------|-------------|
| `--help, -h` | Muestra mensaje de ayuda |
| `--version, -v` | Muestra la versión |
| `--output, -o` | Ruta del archivo de salida |
| `--pretty, -p` | Imprime HTML con formato |
| `--minify, -m` | Minifica la salida |
| `--format, -f` | Formato (indentado sin comentarios) |
| `--vars` | Archivo JSON con variables |

### Ejemplos

**Compilación básica:**

```bash
zpug template.pug
```

**Con formato:**

```bash
zpug template.pug --pretty
```

**Con archivo de salida:**

```bash
zpug template.pug -o output.html
```

**Con variables:**

```bash
# Crear vars.json
echo '{"title": "My Page", "year": 2025}' > vars.json

# Compilar con variables
zpug template.pug --vars vars.json
```

**Minificado:**

```bash
zpug template.pug --minify -o dist/page.html
```

---

## API del Paquete Zig

Para usar zig-pug como una dependencia de Zig.

### Instalación

**build.zig.zon:**

```zig
.{
    .name = "my-project",
    .version = "0.1.0",
    .dependencies = .{
        .zig_pug = .{
            .url = "https://github.com/carlos-sweb/zig-pug/archive/main.tar.gz",
        },
    },
}
```

**build.zig:**

```zig
const zig_pug = b.dependency("zig_pug", .{
    .target = target,
    .optimize = optimize,
});

exe.addModule("zig_pug", zig_pug.module("zig_pug"));
```

### Uso

```zig
const std = @import("std");
const zig_pug = @import("zig_pug");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Compilar plantilla
    const template = "p Hello #{name}!";
    const html = try zig_pug.compile(allocator, template);
    defer allocator.free(html);

    std.debug.print("{s}\n", .{html});
}
```

Consulta [ZIG-PACKAGE.md](ZIG-PACKAGE.md) para la documentación completa de la API de Zig.

---

## Manejo de Errores

### Node.js

Todos los métodos lanzan errores estándar de JavaScript:

```javascript
try {
  const html = compiler.compile('invalid pug syntax !!!');
} catch (error) {
  console.error('Compilation failed:', error.message);
}
```

### CLI

Devuelve un código de salida diferente de cero en caso de error:

```bash
zpug invalid.pug
# Código de salida: 1
```

---

## Consejos de Rendimiento

1. **Reutiliza las instancias del compilador** - Crea una vez, compila muchas veces
2. **Usa funciones independientes** - Para compilaciones puntuales
3. **Precompila plantillas** - En producción, compila en tiempo de construcción
4. **Minimiza las variables** - Solo pasa lo que sea necesario

**Bueno:**

```javascript
const compiler = new PugCompiler();
for (const item of items) {
  compiler.set('name', item.name);
  const html = compiler.compile(template);
  // Usar html
}
```

**Mejor:**

```javascript
const template = `each item in items\n  li= item`;
const html = compile(template, { items: items.map(i => i.name) });
```

---

## Ver También

- [Comenzando](GETTING-STARTED.md)
- [Guía de Sintaxis Pug](PUG-SYNTAX.md)
- [Ejemplos](EXAMPLES.md)
- [Integración con Node.js](NODEJS-INTEGRATION.md)

---

**Última Actualización:** 2025-12-16
**Versión:** 0.3.7
