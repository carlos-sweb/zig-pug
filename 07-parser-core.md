# Paso 7: Parser de Características Core

## Objetivo
Implementar parsing de características principales: interpolación, código, condicionales, loops, comentarios, case statements.

---

## Tareas

### 7.1 Parser de Interpolación
- Interpolación escapada `#{expr}`
- Interpolación no escapada `!{expr}`
- Interpolación de tags `#[tag]`

### 7.2 Parser de Código
- Código no-bufferizado `-`
- Código bufferizado `=`
- Código no-escapado `!=`

### 7.3 Parser de Condicionales
- `if` / `else if` / `else`
- `unless`

### 7.4 Parser de Loops
- `each` con índice
- `while`
- Bloques `else` para iteraciones vacías

### 7.5 Parser de Comentarios
- Comentarios bufferizados `//`
- Comentarios no-bufferizados `//-`
- Comentarios de bloque

### 7.6 Parser de Case Statements
- `case` expression
- `when` values
- `default`
- Fall-through

### 7.7 Parser de Atributos Avanzados
- Atributos multilínea
- Spread `&attributes`
- Objetos de estilo y clase

---

## Entregables
- Parser con características core implementadas
- Tests exhaustivos
- Validación de sintaxis

---

## Siguiente Paso
**08-parser-advanced.md** para características avanzadas (mixins, includes, herencia).
