# Paso 22: Empaquetado y Distribución

## Objetivo
Preparar el proyecto para distribución pública.

---

## Tareas

### 22.1 Versionado Semántico

Seguir [SemVer](https://semver.org/):
- MAJOR: cambios incompatibles
- MINOR: nueva funcionalidad compatible
- PATCH: bug fixes

Crear archivo VERSION:
```
0.1.0
```

### 22.2 Changelog

Mantener CHANGELOG.md:
```markdown
# Changelog

## [0.1.0] - 2024-XX-XX
### Added
- Initial release
- Core Pug features
- TOML data support
- JavaScript blocks
- Template inheritance

### Changed
- ...

### Fixed
- ...
```

### 22.3 Releases en GitHub

Crear GitHub releases:
```bash
git tag -a v0.1.0 -m "Release v0.1.0"
git push origin v0.1.0
```

GitHub Actions para releases automáticos:
```yaml
name: Release
on:
  push:
    tags:
      - 'v*'
jobs:
  release:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Build
        run: zig build -Doptimize=ReleaseSafe
      - name: Create Release
        uses: actions/create-release@v1
```

### 22.4 Publicar en Package Managers

#### Zig Package Manager
Crear `build.zig.zon`:
```zig
.{
    .name = "zig-pug",
    .version = "0.1.0",
    .paths = .{""},
    .dependencies = .{
        // ...
    },
}
```

Publicar:
```bash
zig build --fetch
```

### 22.5 Binarios Precompilados

Compilar para múltiples plataformas:
```bash
zig build -Dtarget=x86_64-linux
zig build -Dtarget=x86_64-macos
zig build -Dtarget=x86_64-windows
zig build -Dtarget=aarch64-linux
```

### 22.6 Instaladores

#### Linux/macOS
```bash
#!/bin/bash
# install.sh
curl -fsSL https://github.com/user/zig-pug/releases/download/v0.1.0/zig-pug-linux-x64 -o /usr/local/bin/zig-pug
chmod +x /usr/local/bin/zig-pug
```

#### Windows
Chocolatey package o MSI installer

### 22.7 Docker Image

```dockerfile
FROM alpine:latest
COPY zig-pug /usr/local/bin/
ENTRYPOINT ["zig-pug"]
```

```bash
docker build -t zig-pug:0.1.0 .
docker push zig-pug:0.1.0
```

### 22.8 Documentación de Instalación

```markdown
# Installation

## From Source
\`\`\`bash
git clone https://github.com/user/zig-pug
cd zig-pug
zig build -Doptimize=ReleaseSafe
sudo cp zig-out/bin/zig-pug /usr/local/bin/
\`\`\`

## Binary Release
\`\`\`bash
curl -fsSL https://zig-pug.dev/install.sh | bash
\`\`\`

## Docker
\`\`\`bash
docker pull zig-pug:latest
\`\`\`
```

### 22.9 LICENSE

Elegir licencia apropiada:
- MIT (permisiva)
- Apache 2.0 (permisiva con patentes)
- GPL (copyleft)

### 22.10 Verificación de Release

Checklist:
- [ ] Tests pasan
- [ ] Documentación actualizada
- [ ] CHANGELOG actualizado
- [ ] VERSION actualizado
- [ ] Compilación en todas las plataformas
- [ ] Binarios funcionan
- [ ] Tag creado
- [ ] Release notes publicado

---

## Entregables
- Paquetes de distribución
- Releases públicos
- Instaladores
- Documentación de instalación

---

## Siguiente Paso
**23-ecosystem.md** para construir ecosystem y comunidad.
