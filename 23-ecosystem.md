# Paso 23: Ecosystem y Comunidad

## Objetivo
Construir ecosystem de tooling y comunidad alrededor del proyecto.

---

## Tareas

### 23.1 Templates de Issues y PRs

`.github/ISSUE_TEMPLATE/bug_report.md`:
```markdown
---
name: Bug Report
about: Report a bug
---

## Description
A clear description of the bug.

## To Reproduce
Steps to reproduce:
1. ...
2. ...

## Expected Behavior
What you expected to happen.

## Actual Behavior
What actually happened.

## Environment
- OS:
- Zig version:
- zig-pug version:

## Additional Context
Any other relevant information.
```

`.github/PULL_REQUEST_TEMPLATE.md`:
```markdown
## Description
What does this PR do?

## Related Issues
Fixes #...

## Checklist
- [ ] Tests added/updated
- [ ] Documentation updated
- [ ] Changelog updated
```

### 23.2 CI/CD

`.github/workflows/ci.yml`:
```yaml
name: CI
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: goto-bus-stop/setup-zig@v2
        with:
          version: 0.11.0
      - run: zig build test
      - run: zig build
```

### 23.3 Guía de Contribución

`CONTRIBUTING.md`:
```markdown
# Contributing to zig-pug

## Getting Started
1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Run tests: `zig build test`
5. Submit a PR

## Code Style
- Follow Zig conventions
- Add tests for new features
- Update documentation

## Commit Messages
Follow conventional commits:
- feat: new feature
- fix: bug fix
- docs: documentation
- test: tests
```

### 23.4 Código de Conducta

`CODE_OF_CONDUCT.md` basado en [Contributor Covenant](https://www.contributor-covenant.org/)

### 23.5 VS Code Extension

```json
{
  "name": "zig-pug",
  "displayName": "zig-pug",
  "description": "Syntax highlighting for zig-pug templates",
  "version": "0.1.0",
  "contributes": {
    "languages": [{
      "id": "zig-pug",
      "extensions": [".zpug"],
      "configuration": "./language-configuration.json"
    }],
    "grammars": [{
      "language": "zig-pug",
      "scopeName": "source.zig-pug",
      "path": "./syntaxes/zig-pug.tmLanguage.json"
    }]
  }
}
```

### 23.6 Syntax Highlighting

Crear grammars para:
- VS Code (TextMate)
- Vim
- Emacs
- Sublime Text

### 23.7 Integraciones con Frameworks

#### Web Frameworks
```zig
// Integración con zap (Zig web framework)
pub fn zapMiddleware(r: zap.Request) !void {
    const template = try std.fs.cwd().readFileAlloc(allocator, "template.pug", 1024*1024);
    const html = try zigpug.render(template, r.context);
    try r.sendText(html);
}
```

#### Static Site Generators
Plugin para Zola, Hugo-compatible tools, etc.

### 23.8 Website del Proyecto

`zig-pug.dev`:
- Landing page
- Documentación interactiva
- Playground online
- Galería de ejemplos
- Blog

### 23.9 Social Media y Promoción

- GitHub README con badges
- Post en Ziggit forum
- Tweet/post anuncio
- Show HN en Hacker News
- Reddit r/Zig
- Article en dev.to o medium

### 23.10 Roadmap Público

`ROADMAP.md`:
```markdown
# Roadmap

## v0.2.0 (Q2 2024)
- [ ] Performance improvements
- [ ] More filters
- [ ] Better error messages

## v1.0.0 (Q3 2024)
- [ ] Stable API
- [ ] Production ready
- [ ] Full Pug compatibility

## Future
- [ ] Streaming rendering
- [ ] Hot reload
- [ ] Visual editor
```

### 23.11 Ecosystem Tools

- **zig-pug-lint**: Linter para templates
- **zig-pug-fmt**: Formatter
- **zig-pug-migrate**: Migración desde Pug
- **zig-pug-server**: Dev server con hot reload

### 23.12 Community Building

- Discord server
- GitHub Discussions
- Monthly community calls
- Contributing guide
- Good first issues labeled

---

## Entregables
- Ecosystem completo de tooling
- Comunidad activa
- Integraciones con editores
- Website del proyecto
- Roadmap público

---

## ¡Proyecto Completo!

Has completado todos los 23 pasos del plan. Ahora tienes:
- ✅ Motor de templates completo
- ✅ Parser y compiler optimizado
- ✅ Soporte TOML y JavaScript
- ✅ CLI y API pública
- ✅ Documentación exhaustiva
- ✅ Testing completo
- ✅ Ecosystem de tooling

**¡Felicidades! zig-pug está listo para convertirse en la nueva niña bonita de Silicon Valley!** 🚀
