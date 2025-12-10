# 🚀 Instrucciones de Publicación - zig-pug v0.3.0

Todo está preparado y listo para publicar. Sigue estos pasos en orden.

---

## ✅ Estado Actual

**Completado:**
- ✅ Versión actualizada a 0.3.0
- ✅ package.json actualizado (descripción, keywords, URLs)
- ✅ README de nodejs/ actualizado con UTF-8 y //!
- ✅ Addon N-API compilado (419 KB)
- ✅ Paquete npm creado: `zig-pug-0.3.0.tgz` (287 KB)
- ✅ Commits creados (2 commits nuevos)
- ✅ Tag v0.3.0 creado con descripción completa
- ✅ Texto para GitHub Release preparado

**Commits pendientes de push:**
```
9cb74dc chore(npm): Prepare package for v0.3.0 release
d6cd710 feat: Add UTF-8 support, doc comments (//!), and fix DOCTYPE indentation
```

---

## 📋 Pasos para Publicar

### PASO 1: Push a GitHub 🔄

```bash
cd /root/zig-pug

# Push commits
git push origin main

# Push tag
git push origin v0.3.0

# Verificar en GitHub
# https://github.com/carlos-sweb/zig-pug
# https://github.com/carlos-sweb/zig-pug/releases
```

**Verificación:**
- [ ] Commits aparecen en GitHub
- [ ] Tag v0.3.0 aparece en /releases

---

### PASO 2: Crear GitHub Release 📦

1. **Ir a GitHub:**
   - URL: https://github.com/carlos-sweb/zig-pug/releases/new

2. **Configurar Release:**
   - **Tag:** `v0.3.0` (seleccionar del dropdown)
   - **Title:** `v0.3.0 - UTF-8 Support & Documentation Comments`
   - **Description:** Copiar desde `/root/zig-pug/GITHUB_RELEASE_v0.3.0.md`

3. **Assets (opcional):**
   - Puedes adjuntar `zig-pug-0.3.0.tgz` si quieres

4. **Publicar:**
   - Click en "Publish release"

**Verificación:**
- [ ] Release v0.3.0 visible en GitHub
- [ ] Descripción se ve correcta con ejemplos

---

### PASO 3: Publicar a npm 📤

```bash
cd /root/zig-pug/nodejs

# 1. Login a npm (si no lo has hecho)
npm login
# Te pedirá:
# - Username
# - Password
# - Email
# - OTP (si tienes 2FA)

# 2. Verificar login
npm whoami
# Debe mostrar tu usuario

# 3. DRY RUN (revisar qué se publicará)
npm publish --dry-run
# Revisar:
# - Versión: 0.3.0
# - Archivos: 46 files
# - Tamaño: ~287 KB

# 4. PUBLICAR A NPM
npm publish

# Si hay error de permisos y es tu primer publish:
# npm publish --access public
```

**Verificación:**
- [ ] Comando `npm publish` exitoso
- [ ] Paquete visible en https://www.npmjs.com/package/zig-pug
- [ ] Versión 0.3.0 aparece como "latest"

---

### PASO 4: Verificar Instalación 🧪

```bash
# Crear directorio de prueba
mkdir -p /tmp/test-zig-pug-v0.3.0
cd /tmp/test-zig-pug-v0.3.0

# Inicializar proyecto
npm init -y

# Instalar desde npm
npm install zig-pug

# Verificar versión
npm list zig-pug
# Debe mostrar: zig-pug@0.3.0

# Probar (en Linux/macOS, no Termux)
node -e "
const zigpug = require('zig-pug');
console.log('Version:', zigpug.version());
const html = zigpug.compile('p ¡Hola #{nombre}! 🎉', {nombre: 'Carlos'});
console.log('HTML:', html);
"

# Output esperado:
# Version: 0.3.0
# HTML: <p>¡Hola Carlos! 🎉</p>
```

**Verificación:**
- [ ] Instalación exitosa desde npm
- [ ] Versión correcta (0.3.0)
- [ ] UTF-8 funciona (¡, 🎉)

---

### PASO 5: Anunciar Release 📢

**Lugares para anunciar:**

1. **GitHub Release** ✅ (Ya hecho en PASO 2)

2. **Twitter/X:**
   ```
   🎉 Just released zig-pug v0.3.0!

   ✨ Full UTF-8 support (emoji 🚀, accents á é ñ)
   ✨ Documentation comments (//!)
   🐛 DOCTYPE indentation fix

   Perfect for international projects! 🌍

   npm install zig-pug@0.3.0

   https://github.com/carlos-sweb/zig-pug

   #nodejs #pug #zig #webdev #i18n
   ```

3. **Reddit:**
   - r/node - "Released zig-pug v0.3.0: High-performance Pug with UTF-8 support"
   - r/javascript - "zig-pug v0.3.0: Native Pug template engine with full Unicode"
   - r/Zig - "zig-pug v0.3.0: Pug template engine written in Zig"

4. **Dev.to Article:**
   ```markdown
   Title: "zig-pug v0.3.0: Building International Web Apps with Full UTF-8 Support"

   Tags: nodejs, pug, zig, webdev, i18n

   Content: Explain UTF-8 features, show examples in Spanish/Portuguese/etc.
   ```

5. **Hacker News:**
   - Submit: "Show HN: zig-pug v0.3.0 - Pug template engine with UTF-8 and native performance"
   - URL: https://github.com/carlos-sweb/zig-pug

**Verificación:**
- [ ] Al menos 1 anuncio publicado

---

## 📊 Checklist Final

### Pre-Publicación
- [x] Versión actualizada (0.3.0)
- [x] package.json actualizado
- [x] README actualizado
- [x] Addon compilado
- [x] Paquete npm creado
- [x] Commits creados
- [x] Tag v0.3.0 creado
- [x] GitHub Release texto preparado

### Publicación
- [ ] Push a GitHub (main + tag)
- [ ] GitHub Release creado
- [ ] npm publish exitoso
- [ ] Instalación verificada

### Post-Publicación
- [ ] Paquete visible en npmjs.com
- [ ] Release visible en GitHub
- [ ] Al menos 1 anuncio publicado
- [ ] Documentación actualizada

---

## 🆘 Troubleshooting

### Error: npm login falla

```bash
# Re-login
npm logout
npm login

# Verificar
npm whoami
```

### Error: npm publish - Permission denied

```bash
# Para primer publish
npm publish --access public

# Verificar permisos
npm owner ls zig-pug
```

### Error: git push - Authentication failed

```bash
# Opción 1: HTTPS con token
# Crear Personal Access Token en GitHub
# Settings → Developer settings → Personal access tokens
# Usar token como password

# Opción 2: SSH
git remote set-url origin git@github.com:carlos-sweb/zig-pug.git
git push origin main
git push origin v0.3.0
```

### Error: Tag ya existe en GitHub

```bash
# Eliminar tag local
git tag -d v0.3.0

# Eliminar tag remoto (cuidado!)
git push origin :refs/tags/v0.3.0

# Recrear tag
git tag -a v0.3.0 -m "..."
git push origin v0.3.0
```

---

## 📁 Archivos Importantes

```
/root/zig-pug/
├── nodejs/
│   ├── package.json              ← v0.3.0, URLs actualizadas
│   ├── README.md                 ← UTF-8 + //! docs
│   ├── zig-pug-0.3.0.tgz        ← Paquete npm listo
│   └── build/Release/zigpug.node ← Addon compilado
│
├── GITHUB_RELEASE_v0.3.0.md     ← Texto para GitHub Release
└── PUBLISH_INSTRUCTIONS.md       ← Este archivo
```

---

## 🎯 Resumen de Comandos Rápidos

```bash
# 1. Push a GitHub
cd /root/zig-pug
git push origin main
git push origin v0.3.0

# 2. Publicar a npm
cd /root/zig-pug/nodejs
npm login
npm publish

# 3. Verificar
npm install -g zig-pug@0.3.0
npm view zig-pug version
# Debe mostrar: 0.3.0
```

---

## 🎊 ¡Éxito!

Si completaste todos los pasos:

✅ **zig-pug v0.3.0 está publicado!**
- GitHub: https://github.com/carlos-sweb/zig-pug
- npm: https://www.npmjs.com/package/zig-pug
- Release: https://github.com/carlos-sweb/zig-pug/releases/tag/v0.3.0

**Usuarios ahora pueden:**
```bash
npm install zig-pug
# o
bun install zig-pug
```

**Y usar UTF-8:**
```javascript
const zigpug = require('zig-pug');
const html = zigpug.compile(`
  h1 ¡Hola #{nombre}! 🎉
  p.información Información importante
`, { nombre: 'María' });
```

---

## 📝 Próximos Pasos (Futuro)

Ideas para v0.4.0:
- [ ] Reemplazar mujs con zig-expr (evaluador nativo Zig)
- [ ] Reducir tamaño binario (~200 KB)
- [ ] Watch mode para desarrollo
- [ ] Source maps
- [ ] Más helpers (date, array, string)

---

**¡Felicitaciones por el release! 🚀🎉**

Generated with [Claude Code](https://claude.com/claude-code)
