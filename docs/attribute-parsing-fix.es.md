# Corrección del Parser de Atributos - Atributos Separados por Espacios con Expresiones Complejas

**Estado**: Corregido en v4.0.1
**Componente**: Parser (`src/parser/attributes.zig`)
**Tipo de Issue**: Corrección de Bug

## Descripción del Problema

Antes de esta corrección, el parser de atributos fallaba al analizar atributos separados por espacios cuando el valor del atributo anterior contenía una expresión compleja (concatenación de strings, operadores ternarios, etc.).

### Ejemplos que Fallaban

```pug
//- Fallaba: Separados por espacio después de concatenación
div(value="base"+vl name="prefix") Text

//- Fallaba: Separados por espacio después de operador ternario
div(first=c ? "yes" : "no" second="static") Content

//- Funcionaba: Separados por coma (solución temporal)
div(value="base"+vl,name="prefix") Text
```

### Mensaje de Error

```
Expected RParen, got BufferedCode at line X
Error: Parsing failed: error.UnexpectedToken
```

## Causa Raíz

La lógica de análisis de expresiones del parser consumía incorrectamente el nombre del siguiente atributo como parte de la expresión del atributo actual.

Por ejemplo, al analizar:
```pug
div(first=c ? "yes" : "no" second="static")
```

El parser:
1. Comenzaba a analizar `first=c ? "yes" : "no"`
2. Después de consumir `"no"`, encontraba el token `Ident` `second`
3. Incorrectamente agregaba `second` a la expresión: `c ? "yes" : "no"second`
4. Avanzaba al siguiente token (`=` / `BufferedCode`)
5. Fallaba porque `=` no es una continuación válida de la expresión

## Solución

### Estrategia de Implementación

La corrección implementa un **mecanismo de detección lookahead** con una **cola de atributos pendientes**:

1. **Detección Lookahead**: Al analizar un token `Ident` dentro de una expresión, verificar si el siguiente token es `BufferedCode` (`=`)
2. **Atributo Pendiente**: Si se detecta `Ident` + `=`, guardar el identificador como un "nombre de atributo pendiente" en lugar de incluirlo en la expresión
3. **Sincronización del Tokenizer**: Dejar el token actual en `BufferedCode` para una sincronización adecuada
4. **Análisis Diferido**: Después de completar el atributo actual, verificar si hay un atributo pendiente y analizarlo inmediatamente

### Cambios en el Código

**Archivo**: `src/parser/attributes.zig`

#### 1. Variable de Atributo Pendiente Agregada (Línea 27)

```zig
var pending_attr_name: ?[]const u8 = null;
```

#### 2. Manejo Mejorado de Ident en Bucles de Expresión (Líneas 142-159, 237-256, 352-371, 439-458, 547-566)

```zig
} else if (helpers.match(self, &.{.Ident})) {
    // Guardar el valor del identificador por si lo necesitamos para atributo pendiente
    const saved_ident_value = self.current.value;
    expr_str = try std.mem.concat(arena_allocator, u8, &[_][]const u8{ expr_str, self.current.value });
    is_expression = true;
    try helpers.advance(self);

    // Verificar si el siguiente token es BufferedCode (=), lo que significa que este Ident es un nuevo atributo
    if (helpers.match(self, &.{.BufferedCode})) {
        // Este Ident es el inicio de un nuevo atributo, no parte de la expresión
        // Guardarlo como pendiente y no restaurar current (dejarlo como BufferedCode)
        pending_attr_name = saved_ident_value;
        // Remover el Ident que agregamos a expr_str recalculando sin él
        expr_str = expr_str[0..(expr_str.len - saved_ident_value.len)];
        break;
    }

    // Verificar si el siguiente token es un operador que continúa la expresión
    if (!helpers.match(self, &.{.Plus, .Minus, .Dot, .LBracket, .Greater, .Less, .GreaterEqual, .LessEqual, .Equal, .And, .Or, .Question, .Colon})) {
        break;
    }
}
```

#### 3. Parser de Atributos Pendientes (Líneas 586-620)

```zig
// Verificar si hay un atributo pendiente del análisis de expresiones
if (pending_attr_name) |pending_name| {
    // Current es BufferedCode (=), analizar el valor
    if (!helpers.match(self, &.{.BufferedCode})) {
        return error.UnexpectedToken;
    }
    try helpers.advance(self);

    // Analizar el valor del atributo pendiente (simplificado - solo manejar casos comunes)
    var pending_value: ?[]const u8 = null;
    var pending_is_expression = false;

    if (helpers.match(self, &.{.String})) {
        const str_val = self.current.value;
        if (str_val.len >= 2 and str_val[0] == '"' and str_val[str_val.len - 1] == '"') {
            pending_value = str_val[1 .. str_val.len - 1];
        } else {
            pending_value = str_val;
        }
        try helpers.advance(self);
    } else if (helpers.match(self, &.{.Ident})) {
        pending_value = self.current.value;
        pending_is_expression = true;
        try helpers.advance(self);
    }

    try attributes.append(arena_allocator, .{
        .name = pending_name,
        .value = pending_value,
        .is_unescaped = false,
        .is_expression = pending_is_expression,
    });

    pending_attr_name = null;
}
```

## Casos de Prueba

Todos los siguientes casos de prueba ahora funcionan:

### 1. Concatenación de Strings con Separador de Espacio

```pug
- var vl = "value"
div(value="base"+vl name="prefix") Text
```

**Salida**: `<div value="basevalue" name="prefix">Text</div>`

### 2. Múltiples Atributos Separados por Espacio con Concatenación

```pug
- var a = "foo"
- var b = "bar"
div(first="pre"+a second="mid"+b) Text
```

**Salida**: `<div first="prefoo" second="midbar">Text</div>`

### 3. Operador Ternario con Atributo Separado por Espacio (Valor String)

```pug
- var c = true
div(first=c ? "yes" : "no" second="static") Content
```

**Salida**: `<div first="yes" second="static">Content</div>`

### 4. Operador Ternario con Atributo Separado por Espacio (Valor Identificador)

```pug
- var c = true
- var s = "static"
div(first=c ? "yes" : "no" second=s) Content
```

**Salida**: `<div first="yes" second="static">Content</div>`

### 5. Separados por Coma (Sigue Funcionando)

```pug
- var vl = "value"
div(value="base"+vl,name="prefix") Text
```

**Salida**: `<div value="basevalue" name="prefix">Text</div>`

## Detalles Técnicos

### Ejemplo de Flujo de Tokens

Para `div(first=c ? "yes" : "no" second="static")`:

```
Tokens:
1. Ident("div")
2. LParen
3. Ident("first")
4. Assign (=)
5. Ident("c")
6. Question (?)
7. String("yes")
8. Colon (:)
9. String("no")
10. Ident("second")  ← Anteriormente consumido como parte de la expresión
11. BufferedCode (=) ← Punto de detección
12. String("static")
13. RParen
```

**Antes de la Corrección**:
- El token 10 (`second`) se agregaba a la expresión
- El token 11 (`=`) causaba un error del parser

**Después de la Corrección**:
- El token 10 (`second`) activa un lookahead al token 11
- Detecta el patrón `Ident` + `BufferedCode`
- Guarda `"second"` como atributo pendiente
- El token actual permanece en `BufferedCode` (token 11)
- Después de completar el primer atributo, se analiza el atributo pendiente

### Lista de Operadores para Continuación de Expresión

El parser reconoce estos operadores como continuaciones válidas de expresión:
- Aritméticos: `Plus`, `Minus`
- Acceso a propiedades: `Dot`, `LBracket`
- Comparación: `Greater`, `Less`, `GreaterEqual`, `LessEqual`, `Equal`
- Lógicos: `And`, `Or`
- Ternario: `Question`, `Colon`

## Compatibilidad hacia Atrás

Esta corrección es **100% compatible hacia atrás**:
- Todas las plantillas existentes continúan funcionando
- Los atributos separados por coma siguen funcionando como antes
- No hay cambios disruptivos en la API o sintaxis
- Todas las pruebas existentes pasan sin modificación

## Archivos Relacionados

- `src/parser/attributes.zig` - Implementación principal
- `CHANGELOG.md` - Entrada en el registro de cambios
- `docs/attribute-parsing-fix.md` - Versión en inglés de este documento

## Referencias

- Commit: `4b9ba9f` - Fix attribute parser to support space-separated attributes in expressions
- Pull Request: Por determinar
- Issue: Por determinar
