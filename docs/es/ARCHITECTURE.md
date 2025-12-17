# Arquitectura: Cómo zig-pug Evalúa Condicionales

## Visión General

zig-pug usa una **arquitectura de dos fases** para evaluar expresiones condicionales:

1. **Tokenizer/Parser** (Zig) - Reconocen y reconstruyen expresiones JavaScript
2. **mujs** (C) - Evalúa expresiones JavaScript

Esta separación de responsabilidades es intencional y proporciona ventajas significativas.

## El Enfoque de Dos Fases

### Fase 1: Tokenizer/Parser (Reconocimiento)

**Responsabilidad:** Convertir sintaxis Pug en expresiones JavaScript como strings

**Lo que hace:**
- Reconoce operadores como tokens (`>=`, `&&`, `||`, etc.)
- Concatena tokens para formar JavaScript válido
- Agrega puntos para acceso a propiedades (`.length`, `.isPremium`)
- Agrega comillas para literales string (`"active"`)
- **NO evalúa** nada

**Ejemplo:**

```pug
if age >= 18 && hasLicense
  p Puede conducir
```

**Tokenizer genera:**
```
Ident("age") → GreaterEqual(">=") → Number("18") → And("&&") → Ident("hasLicense")
```

**Parser reconstruye:**
```
String: "age>=18&&hasLicense"
```

**Código:** `src/parser/conditionals.zig` líneas 30-51

### Fase 2: mujs (Evaluación)

**Responsabilidad:** Evaluar expresiones JavaScript y retornar resultados

**Lo que hace:**
- Parsea la expresión JavaScript
- Evalúa operadores (`>=`, `&&`, `||`, `==`, etc.)
- Accede a propiedades de objetos (`user.isPremium`, `array.length`)
- Llama métodos (`name.toUpperCase()`)
- Retorna el resultado como string

**Ejemplo:**

```javascript
// Recibe: "age>=18&&hasLicense"
// Variables: { age: 25, hasLicense: true }
// Evalúa: 25 >= 18 && true
// Retorna: "true"
```

**Código:** `src/compiler.zig` línea 672

## ¿Por Qué Esta Arquitectura?

### ✅ Ventajas

**1. Separación de Responsabilidades**
- Parser se enfoca en sintaxis Pug
- mujs maneja semántica JavaScript
- Cada componente tiene una responsabilidad única y clara

**2. Soporte JavaScript Completo**
- Cualquier expresión ES5.1 funciona automáticamente
- No necesitamos implementar evaluación de JavaScript en Zig
- Métodos, funciones, operador ternario, etc. todos funcionan

**3. Simplicidad**
- Parser solo concatena strings (código muy simple)
- No se necesita lógica compleja de evaluación de expresiones
- Fácil de entender y mantener

**4. Confiabilidad**
- mujs es un motor JavaScript probado y testeado
- No reinventamos evaluación de JavaScript
- Menos bugs en manejo de expresiones

**5. Performance**
- Concatenación de strings es extremadamente rápida
- mujs es código C optimizado
- Sin overhead de evaluación basada en Zig

**6. Compatibilidad**
- Mismo enfoque que Pug.js (delega a V8/Node.js)
- Comportamiento consistente con el original

### ❌ Alternativa NO Usada: Evaluar en el Parser

Si evaluáramos expresiones en el parser, necesitaríamos:

```zig
// Hipotético - NO IMPLEMENTADO
fn evaluateCondition(tokens: []Token, variables: Variables) bool {
    // Tendríamos que implementar:
    // - Precedencia de operadores
    // - Conversión de tipos
    // - Acceso a propiedades
    // - Llamadas a métodos
    // - Y mucho más...

    // ¡Esto sería reimplementar un motor JavaScript en Zig!
}
```

**Problemas:**
- 🔴 Duplicar funcionalidad de mujs
- 🔴 Mantener dos implementaciones sincronizadas
- 🔴 Bugs en lógica de evaluación
- 🔴 Sin soporte para métodos, funciones, etc.
- 🔴 Código más complejo
- 🔴 Desarrollo más lento

## Ejemplo de Flujo Completo

### Template de Entrada

```pug
if (isAdmin || isModerator) && user.isActive
  p Acceso concedido
else
  p Acceso denegado
```

### Procesamiento Paso a Paso

**1. Tokenizer** (src/tokenizer.zig)

```
LParen("(")
Ident("isAdmin")
Or("||")
Ident("isModerator")
RParen(")")
And("&&")
Ident("user")
.Id("isActive")
```

**2. Parser** (src/parser/conditionals.zig)

```
Reconstruido: "(isAdmin||isModerator)&&user.isActive"
                                           ↑
                            Agregó punto para token .Id
```

**3. Compiler** (src/compiler.zig)

```zig
const result = self.runtime.eval("(isAdmin||isModerator)&&user.isActive");
// result = "true" o "false"
```

**4. Evaluación en mujs**

```javascript
// Variables en contexto:
// isAdmin = false
// isModerator = true
// user = { isActive: true }

// Evalúa:
(false || true) && true
= true && true
= true

// Retorna: "true"
```

**5. Decisión del Compiler**

```zig
const is_true = !std.mem.eql(u8, result, "false") and
    !std.mem.eql(u8, result, "null") and
    !std.mem.eql(u8, result, "undefined") and
    !std.mem.eql(u8, result, "0") and
    result.len > 0;

// is_true = true
// Ejecuta rama "then": <p>Acceso concedido</p>
```

## Matriz de Responsabilidades

| Componente | Reconoce Operadores | Entiende Semántica | Evalúa Expresiones |
|-----------|---------------------|-------------------|-------------------|
| **Tokenizer** | ✅ Sí (como tokens) | ❌ No | ❌ No |
| **Parser** | ✅ Sí (reconstruye) | ❌ No | ❌ No |
| **Compiler** | N/A | ❌ No | ❌ No (delega) |
| **mujs** | N/A | ✅ Sí | ✅ Sí |

## Manejo Especial en el Parser

El parser realiza transformaciones mínimas para asegurar JavaScript válido:

### 1. Acceso a Propiedades (puntos)

**Tokenizer:** Los tokens `.Class` y `.Id` tienen el punto removido del `value`

**Parser:** Agrega el punto de vuelta al concatenar

```pug
if array.length > 0
```

```
Tokenizer: Ident("array"), .Class("length"), Greater(">"), Number("0")
                              ↑ value es "length", NO ".length"

Parser: "array.length>0"
              ↑ Punto agregado por parser
```

**Código:**
```zig
if (self.current.type == .Class or self.current.type == .Id) {
    try condition.append(arena_allocator, '.');
}
```

### 2. Literales String (comillas)

**Tokenizer:** Los tokens `.String` tienen las comillas removidas del `value`

**Parser:** Agrega comillas de vuelta al concatenar

```pug
if status == "active"
```

```
Tokenizer: Ident("status"), Equal("=="), .String("active")
                                           ↑ value es "active", NO "\"active\""

Parser: "status==\"active\""
                ↑        ↑ Comillas agregadas por parser
```

**Código:**
```zig
else if (self.current.type == .String) {
    try condition.append(arena_allocator, '"');
    try condition.appendSlice(arena_allocator, self.current.value);
    try condition.append(arena_allocator, '"');
    try helpers.advance(self);
    continue;
}
```

### 3. Sin Espacios Entre Tokens

**Bug anterior:** Parser agregaba espacios entre todos los tokens

```
Malo: "array . length > 0"  // SyntaxError en JavaScript
Bueno: "array.length>0"     // JavaScript válido
```

**Implementación actual:** No se insertan espacios (JavaScript no los requiere)

```zig
// Simplemente concatena valores de tokens
try condition.appendSlice(arena_allocator, self.current.value);
```

## Comparación con Pug.js

| Aspecto | Pug.js | zig-pug |
|--------|--------|---------|
| Rol del parser | Reconoce sintaxis | Reconoce sintaxis |
| Evaluador | V8 / Node.js | mujs |
| Arquitectura | Dos fases | Dos fases |
| Expresiones | JavaScript completo | JavaScript ES5.1 |
| Enfoque | ✅ Misma estrategia | ✅ Misma estrategia |

zig-pug sigue el **mismo patrón arquitectónico exacto** que Pug.js:
- Parser maneja sintaxis del template
- Motor JavaScript maneja evaluación de expresiones

## Trade-offs

### ✅ Pros

1. **Código simple del parser** - Solo concatenación de strings
2. **Soporte JS completo** - Todo lo que mujs soporta funciona
3. **Confiabilidad probada** - mujs está probado en batalla
4. **Mantenimiento fácil** - Cambios en JS no afectan al parser
5. **Buen performance** - Overhead mínimo

### ⚠️ Contras

1. **Dependencia de mujs** - No se puede cambiar de motor JS fácilmente
2. **Mensajes de error** - Vienen de mujs, no siempre claros para templates
3. **Debugging** - Más difícil rastrear evaluación de expresiones

### 🎯 Conclusión

Los pros **superan significativamente** los contras. Esta es la arquitectura correcta para un motor de templates.

## Documentación Relacionada

- [Sintaxis Condicional](PUG-SYNTAX.md#condicionales) - Documentación de condicionales para usuarios
- [Referencia API](API-REFERENCE.md) - Cómo establecer variables para condicionales
- [Ejemplos](../../examples/06-conditionals-advanced.zpug) - Ejemplos reales de condicionales

## Referencias al Código Fuente

- `src/tokenizer.zig` - Reconocimiento de tokens (líneas 778-833)
- `src/parser/conditionals.zig` - Reconstrucción de expresiones (líneas 30-51)
- `src/compiler.zig` - Evaluación de expresiones vía mujs (líneas 668-701)
- `src/runtime.zig` - Integración y evaluación de mujs
