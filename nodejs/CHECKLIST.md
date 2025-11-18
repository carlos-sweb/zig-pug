# Pre-Publish Checklist

Complete esta lista antes de publicar a npm.

## 🔧 Configuración Inicial (Solo Una Vez)

- [ ] Crear cuenta en https://www.npmjs.com/signup
- [ ] Verificar email de npm
- [ ] Ejecutar `npm login` desde línea de comandos
- [ ] Verificar login: `npm whoami`

## 📝 Antes de Cada Publicación

### 1. Actualizar URLs de GitHub

Reemplazar `yourusername` con tu usuario real de GitHub en:

- [ ] `package.json` - repository.url
- [ ] `package.json` - bugs.url
- [ ] `package.json` - homepage
- [ ] `package.json` - binary.host
- [ ] `README.md` - Todos los enlaces a GitHub
- [ ] `PUBLISHING.md` - Referencias a repositorio

**Buscar y reemplazar:**
```bash
cd /root/zig-pug/nodejs
grep -r "yourusername" .
# Reemplazar manualmente o con sed:
# sed -i 's/yourusername/TU_USUARIO/g' package.json README.md PUBLISHING.md
```

### 2. Verificar Versión

- [ ] Verificar que la versión en `package.json` es correcta
- [ ] Versión sigue Semantic Versioning (MAJOR.MINOR.PATCH)
- [ ] Versión no existe ya en npm: `npm view zig-pug versions`

### 3. Verificar Archivos

- [ ] `LICENSE` existe en `/root/zig-pug/nodejs/`
- [ ] `README.md` existe y está actualizado
- [ ] `binding.gyp` usa rutas locales (no `../`)
- [ ] `include/zigpug.h` existe
- [ ] `vendor/mujs/libmujs.a` existe

**Comando de verificación:**
```bash
cd /root/zig-pug/nodejs
ls -la LICENSE README.md binding.gyp
ls -la include/zigpug.h
ls -la vendor/mujs/libmujs.a
```

### 4. Probar Compilación Local

- [ ] Limpiar build anterior: `npm run clean`
- [ ] Compilar: `npm run build`
- [ ] Sin errores de compilación
- [ ] Archivo `build/Release/zigpug.node` creado

**Comandos:**
```bash
cd /root/zig-pug/nodejs
npm run clean
npm run build
ls -lh build/Release/zigpug.node
```

### 5. Probar el Paquete

- [ ] Crear paquete de prueba: `npm pack`
- [ ] Verificar tamaño razonable (~280-300 KB)
- [ ] Inspeccionar contenido: `tar -tzf zig-pug-*.tgz | less`
- [ ] Verificar que incluye 46 archivos (aprox)

**Archivos críticos que DEBEN estar:**
- `package/index.js`
- `package/binding.c`
- `package/binding.gyp`
- `package/common.gypi`
- `package/include/zigpug.h`
- `package/vendor/mujs/libmujs.a`
- `package/vendor/mujs/mujs.h`

### 6. Probar Instalación

- [ ] Instalar en directorio temporal
- [ ] Compilación automática exitosa
- [ ] (Opcional) Probar carga del módulo en Linux/macOS

**Comandos:**
```bash
mkdir -p /tmp/test-npm
cd /tmp/test-npm
npm init -y
npm install /root/zig-pug/nodejs/zig-pug-*.tgz

# En Linux/macOS (no funcionará en Termux):
# node -e "const zigpug = require('zig-pug'); console.log(zigpug.version())"
```

### 7. Documentación

- [ ] README.md actualizado con features actuales
- [ ] Ejemplos de código funcionan
- [ ] Links a documentación correctos
- [ ] Screenshots/GIFs actualizados (si aplica)

### 8. Git

- [ ] Todos los cambios committeados
- [ ] Working directory limpio: `git status`
- [ ] Branch correcto (main/master)
- [ ] Sincronizado con remote: `git push`

## 🚀 Publicación

### Opción A: Publicación Manual

```bash
cd /root/zig-pug/nodejs

# 1. Bumppear versión y crear tag
npm version patch  # o minor, o major

# 2. Dry run (revisar qué se publicará)
npm publish --dry-run

# 3. Publicar
npm publish

# 4. Push tags
cd ..
git push
git push --tags
```

### Opción B: Publicación con Script

Ver `PUBLISHING.md` para guía detallada paso a paso.

## ✅ Post-Publicación

- [ ] Verificar en npm: https://www.npmjs.com/package/zig-pug
- [ ] Probar instalación desde npm: `npm install zig-pug`
- [ ] Crear GitHub Release con el tag
- [ ] Actualizar CHANGELOG (si existe)
- [ ] Anunciar en redes sociales / foros

## 🐛 Si Algo Sale Mal

### Publicación incorrecta (primeras 72 horas)

```bash
# Despublicar versión (solo posible en primeras 72 horas)
npm unpublish zig-pug@0.2.0

# O deprecar
npm deprecate zig-pug@0.2.0 "Broken release, use 0.2.1 instead"
```

### Error de permisos

```bash
# Verificar login
npm whoami

# Re-login si es necesario
npm logout
npm login
```

### Archivos faltantes

- Verificar `.npmignore`
- Verificar `files` array en `package.json`
- Ejecutar `npm pack` y revisar contenido

## 📊 Métricas Recomendadas

Después de publicar, monitorear:

- **Downloads:** https://npm-stat.com/charts.html?package=zig-pug
- **Dependencies:** https://www.npmjs.com/browse/depended/zig-pug
- **Issues:** GitHub issues reportados
- **Stars:** GitHub stars

## 🔄 Actualización de Versión

### Patch (Bug fixes)

```bash
npm version patch  # 0.2.0 -> 0.2.1
```

### Minor (New features, backward compatible)

```bash
npm version minor  # 0.2.0 -> 0.3.0
```

### Major (Breaking changes)

```bash
npm version major  # 0.2.0 -> 1.0.0
```

## 📚 Recursos

- **npm Docs:** https://docs.npmjs.com/
- **Semantic Versioning:** https://semver.org/
- **Publishing Guide:** `PUBLISHING.md` en este directorio
- **npm Best Practices:** https://docs.npmjs.com/packages-and-modules/contributing-packages-to-the-registry

---

**Última actualización:** 2024-11-18
