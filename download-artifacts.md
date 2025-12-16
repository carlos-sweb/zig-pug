# Instrucciones para Descargar Artifacts de GitHub Actions

## Paso 1: Verificar que el Workflow haya Terminado

1. Ve a: https://github.com/carlos-sweb/zig-pug/actions
2. Busca el workflow "Build Node.js Addon" más reciente
3. Verifica que todos los jobs hayan terminado con éxito (✓ verde)

## Paso 2: Descargar el Artifact "all-node-addons"

### Opción A: Desde la Web

1. Haz clic en el workflow run más reciente
2. Desplázate hasta la sección "Artifacts" al final de la página
3. Haz clic en "all-node-addons" para descargarlo
4. Se descargará un archivo ZIP: `all-node-addons.zip`

### Opción B: Con GitHub CLI (si tienes gh instalado)

```bash
# Instalar gh CLI (si no lo tienes)
# En Termux:
pkg install gh

# Autenticarte
gh auth login

# Listar workflows recientes
gh run list --workflow=build-node-addon.yml

# Descargar artifacts del run más reciente
gh run download --name all-node-addons
```

## Paso 3: Extraer los Artifacts

```bash
# Si descargaste desde la web
unzip all-node-addons.zip -d artifacts/

# Los archivos estarán en:
# artifacts/nodejs/prebuilt-binaries/linux-x64/zigpug.node
# artifacts/nodejs/prebuilt-binaries/darwin-x64/zigpug.node
# artifacts/nodejs/prebuilt-binaries/darwin-arm64/zigpug.node
# artifacts/nodejs/prebuilt-binaries/win32-x64/zigpug.node
```

## Paso 4: Copiar los .node a tu Proyecto

```bash
# Copiar todos los .node
cp -r artifacts/nodejs/prebuilt-binaries/* nodejs/prebuilt-binaries/

# O copiar uno por uno:
cp artifacts/nodejs/prebuilt-binaries/linux-x64/zigpug.node nodejs/prebuilt-binaries/linux-x64/
cp artifacts/nodejs/prebuilt-binaries/darwin-x64/zigpug.node nodejs/prebuilt-binaries/darwin-x64/
cp artifacts/nodejs/prebuilt-binaries/darwin-arm64/zigpug.node nodejs/prebuilt-binaries/darwin-arm64/
cp artifacts/nodejs/prebuilt-binaries/win32-x64/zigpug.node nodejs/prebuilt-binaries/win32-x64/
```

## Paso 5: Verificar que los .node Existen

```bash
ls -lh nodejs/prebuilt-binaries/*/zigpug.node

# Deberías ver algo como:
# -rw-r--r-- 1 user user 2.4M Dec 16 14:00 nodejs/prebuilt-binaries/darwin-arm64/zigpug.node
# -rw-r--r-- 1 user user 2.4M Dec 16 14:00 nodejs/prebuilt-binaries/darwin-x64/zigpug.node
# -rw-r--r-- 1 user user 2.4M Dec 16 14:00 nodejs/prebuilt-binaries/linux-x64/zigpug.node
# -rw-r--r-- 1 user user 2.4M Dec 16 14:00 nodejs/prebuilt-binaries/win32-x64/zigpug.node
```

## Paso 6: Verificar que Git los Reconoce

```bash
git status

# Deberías ver:
# new file:   nodejs/prebuilt-binaries/darwin-arm64/zigpug.node
# new file:   nodejs/prebuilt-binaries/darwin-x64/zigpug.node
# new file:   nodejs/prebuilt-binaries/linux-x64/zigpug.node
# new file:   nodejs/prebuilt-binaries/win32-x64/zigpug.node
```

Si ves los archivos `.node` en `git status`, significa que el `.gitignore` está funcionando correctamente y permitiendo estos archivos.

## Paso 7: Commitear y Pushear

```bash
# Agregar todos los .node
git add nodejs/prebuilt-binaries/

# Crear commit
git commit -m "Add prebuilt binaries for all platforms

Includes compiled .node binaries from GitHub Actions:
- linux-x64
- darwin-x64 (macOS Intel)
- darwin-arm64 (macOS Apple Silicon)
- win32-x64

Users can now install without compiling:
npm install zig-pug  # Just works!
"

# Pushear
git push
```

## ¿Qué Sucede Después?

Una vez que hagas push:

1. Los `.node` estarán en el repositorio git
2. Cuando publiques a npm (`npm publish`), los `.node` se incluirán automáticamente
3. Los usuarios que instalen el paquete recibirán los `.node` precompilados
4. Ya no necesitarán node-gyp ni compilar nada

## Verificación Final

Para probar que funciona:

```bash
# En otro directorio temporal
mkdir /tmp/test-zigpug
cd /tmp/test-zigpug
npm init -y

# Si ya publicaste a npm:
npm install zig-pug

# Si no, puedes probar localmente:
npm install /ruta/a/zig-pug/nodejs

# Probar que funciona:
node -e "const pug = require('zig-pug'); console.log(pug.compile('p Hello'));"
# Debería imprimir: <p>Hello</p>
```

---

**Notas Importantes:**

- Los archivos `.node` son binarios específicos de cada plataforma
- Cada uno pesa ~2-3 MB
- En total agregarás ~10-12 MB al repositorio
- Esto es normal y esperado para paquetes nativos
- Los usuarios lo agradecerán porque no tendrán que compilar nada
