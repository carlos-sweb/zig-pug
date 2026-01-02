# Parser

La documentación completa del parser está disponible en español:

**[../parser.es.md](../parser.es.md)**

## También Disponible

### Documentación en Español

- **[Parser (completo)](../parser.es.md)** - Análisis sintáctico completo
- **[Tokenizador](../tokenizer.es.md)** - Análisis léxico
- **[Compilador](../compiler.es.md)** - Generación de HTML
- **[AST](../ast.es.md)** - Árbol de sintaxis abstracta

### Documentación en Inglés

- [Parser (English)](../parser.md) - Complete English documentation
- [Tokenizer](../tokenizer.md) - Lexical analysis
- [Compiler](../compiler.md) - HTML generation

## Resumen

El **Parser** es la segunda fase del pipeline de compilación. Convierte el flujo de tokens en un Árbol de Sintaxis Abstracta (AST).

**Responsabilidades:**
- Análisis sintáctico (tokens → AST)
- Construcción del árbol de sintaxis
- Validación de estructura
- Detección de errores sintácticos

**Estrategia:** Descenso recursivo (Recursive Descent)

**Funciones principales:**
- `parseTag()` - Etiquetas HTML
- `parseConditional()` - if/else/unless
- `parseLoop()` - each/while
- `parseMixin()` - Definiciones y llamadas de mixins
- `parseAttributes()` - Atributos `(href="/")`
- `parseInlineText()` - Texto con `#{interpolación}`

**Manejo de errores:**
El parser proporciona mensajes de error detallados con:
- Número de línea y columna
- Token esperado vs recibido
- Sugerencias de corrección

---

**Nota:** Este es un archivo de redirección. La documentación completa en español está en: [../parser.es.md](../parser.es.md)
