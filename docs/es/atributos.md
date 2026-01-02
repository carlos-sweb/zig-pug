# Atributos

La documentación completa sobre atributos está disponible en inglés:

**[../en/attributes.md](../en/attributes.md)**

## Enlaces Rápidos

### Documentación en Español

Para documentación técnica en español, consulte:

- **[C API en Español](../c-api.es.md)** - Referencia completa de la API de C
- **[Compilador](../compiler.es.md)** - Generación de HTML
- **[Parser](../parser.es.md)** - Análisis sintáctico

### Documentación en Inglés

- [Attributes Guide](../en/attributes.md) - Guía completa de atributos
- [Interpolation](../en/interpolation.md) - Interpolación de texto
- [Syntax Basics](../en/SYNTAX-BASICS.md) - Sintaxis básica

## Resumen

Los atributos en zig-pug se especifican entre paréntesis después del nombre de la etiqueta:

**Básico:**
```pug
a(href="/") Inicio
img(src="logo.png" alt="Logo")
```

**Dinámico:**
```pug
- var url = "/home"
a(href=url) Enlace
```

**Múltiples líneas:**
```pug
div(
  class="container"
  id="main"
  data-role="primary"
)
```

---

**Nota:** Este es un archivo de redirección. La documentación completa está en inglés: [../en/attributes.md](../en/attributes.md)
