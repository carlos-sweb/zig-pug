# Tokenizador

La documentación completa del tokenizador está disponible en español:

**[../tokenizer.es.md](../tokenizer.es.md)**

## También Disponible

### Documentación en Español

- **[Tokenizador (completo)](../tokenizer.es.md)** - Análisis léxico completo
- **[Parser en Español](../parser.es.md)** - Análisis sintáctico
- **[Compilador](../compiler.es.md)** - Generación de HTML
- **[AST](../ast.es.md)** - Árbol de sintaxis abstracta

### Documentación en Inglés

- [Tokenizer (English)](../tokenizer.md) - Complete English documentation
- [Parser](../parser.md) - Syntax analysis
- [Architecture](../ARCHITECTURE.md) - System architecture

## Resumen

El **Tokenizador** es la primera fase del pipeline de compilación de zig-pug. Convierte el código fuente de la plantilla Pug en un flujo de tokens que el parser puede procesar.

**Responsabilidades:**
- Análisis léxico (caracteres → tokens)
- Manejo de indentación (INDENT/DEDENT)
- Reconocimiento de palabras clave
- Extracción de interpolaciones `#{...}`
- Soporte completo UTF-8

**Tipos de tokens:**
- Identificadores (`Ident`)
- Clases (`.classname`)
- IDs (`#idname`)
- Literales (strings, números, booleanos)
- Símbolos (`(`, `)`, `,`, etc.)
- Palabras clave (`if`, `each`, `mixin`, etc.)

**Máquina de estados:**
El tokenizador usa una máquina de estados etiquetados para reconocimiento eficiente de tokens.

---

**Nota:** Este es un archivo de redirección. La documentación completa en español está en: [../tokenizer.es.md](../tokenizer.es.md)
