# Interpolación

La documentación completa sobre interpolación está disponible en inglés:

**[../en/interpolation.md](../en/interpolation.md)**

## Enlaces Rápidos

### Documentación en Español

Para documentación técnica en español, consulte:

- **[C API en Español](../c-api.es.md)** - Referencia completa de la API de C
- **[Compilador](../compiler.es.md)** - Generación de HTML
- **[Parser](../parser.es.md)** - Análisis sintáctico

### Documentación en Inglés

- [Interpolation Guide](../en/interpolation.md) - Guía completa de interpolación
- [Attributes](../en/attributes.md) - Atributos HTML
- [JavaScript](../en/JAVASCRIPT.md) - JavaScript en plantillas

## Resumen

La interpolación permite insertar expresiones JavaScript en el texto:

**Escapado (seguro):**
```pug
p Hola #{nombre}!
```

**Sin escapar (peligroso):**
```pug
p !{html}
```

**Con expresiones:**
```pug
p #{nombre.toUpperCase()}
p Precio: $#{(precio * cantidad).toFixed(2)}
```

**⚠️ Advertencia de Seguridad:**
- Siempre use `#{}` (escapado) con entrada de usuario
- Solo use `!{}` (sin escapar) con HTML que usted controla
- Riesgo de ataques XSS con `!{}`

---

**Nota:** Este es un archivo de redirección. La documentación completa está en inglés: [../en/interpolation.md](../en/interpolation.md)
