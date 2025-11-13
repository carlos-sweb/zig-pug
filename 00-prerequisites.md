# Paso 0: Prerequisitos - Instalación de Zig 0.15.2

## Objetivo
Instalar y verificar Zig 0.15.2 antes de comenzar el proyecto.

---

## Importancia de la Versión 0.15.2

**CRÍTICO:** Este proyecto requiere específicamente Zig **0.15.2** o superior de la serie 0.15.x.

### ¿Por qué 0.15.2?
- Versiones anteriores a 0.15 tienen diferencias notables en declaraciones y sintaxis
- El código escrito para versiones pre-0.15 **se rompe** en 0.15.x
- Cambios importantes en el sistema de I/O (0.15.1 "Writergate")
- La biblioteca estándar tiene cambios significativos

---

## Instalación en Termux + Alpine (ARM64)

### Verificar Instalación Actual

```bash
~/bin/zig version
```

Debe mostrar: `0.15.2`

### Si No Está Instalado o Es Versión Incorrecta

**Paso 1:** Acceder a Alpine como root
```bash
proot-distro login alpine --user root
```

**Paso 2:** Descargar Zig 0.15.2 para aarch64-linux (musl)
```bash
cd /home/termux
wget https://ziglang.org/download/0.15.2/zig-linux-aarch64-0.15.2.tar.xz
```

**Paso 3:** Extraer
```bash
tar -xf zig-linux-aarch64-0.15.2.tar.xz
```

**Paso 4:** Verificar
```bash
/home/termux/zig-aarch64-linux-0.15.2/zig version
```

Debe mostrar: `0.15.2`

**Paso 5:** Limpiar
```bash
rm zig-linux-aarch64-0.15.2.tar.xz
exit
```

**Paso 6:** Verificar desde Termux
```bash
~/bin/zig version
```

---

## Instalación en Otros Sistemas

### Linux x86_64 (musl)
```bash
wget https://ziglang.org/download/0.15.2/zig-linux-x86_64-0.15.2.tar.xz
tar -xf zig-linux-x86_64-0.15.2.tar.xz
sudo mv zig-linux-x86_64-0.15.2 /usr/local/zig
echo 'export PATH=/usr/local/zig:$PATH' >> ~/.bashrc
source ~/.bashrc
zig version
```

### macOS (ARM64)
```bash
wget https://ziglang.org/download/0.15.2/zig-macos-aarch64-0.15.2.tar.xz
tar -xf zig-macos-aarch64-0.15.2.tar.xz
sudo mv zig-macos-aarch64-0.15.2 /usr/local/zig
echo 'export PATH=/usr/local/zig:$PATH' >> ~/.zshrc
source ~/.zshrc
zig version
```

### macOS (x86_64)
```bash
wget https://ziglang.org/download/0.15.2/zig-macos-x86_64-0.15.2.tar.xz
tar -xf zig-macos-x86_64-0.15.2.tar.xz
sudo mv zig-macos-x86_64-0.15.2 /usr/local/zig
echo 'export PATH=/usr/local/zig:$PATH' >> ~/.zshrc
source ~/.zshrc
zig version
```

### Windows
1. Descargar: https://ziglang.org/download/0.15.2/zig-windows-x86_64-0.15.2.zip
2. Extraer a `C:\zig`
3. Agregar `C:\zig` al PATH
4. Verificar: `zig version`

---

## Cambios Importantes en Zig 0.15.x

### Sistema de I/O (0.15.1)
- Interfaces Reader/Writer rediseñadas
- Buffered I/O por defecto
- Necesario llamar `.flush()` explícitamente

**Antes (0.14.x):**
```zig
const stdout = std.io.getStdOut().writer();
try stdout.print("Hello\n", .{});
```

**Ahora (0.15.x):**
```zig
const stdout = std.io.getStdOut().writer();
var buffered = std.io.bufferedWriter(stdout);
const writer = buffered.writer();
try writer.print("Hello\n", .{});
try buffered.flush();
```

### Build System
- `std.Build` API actualizada
- Cambios en `.addExecutable()`
- Nueva sintaxis para módulos

### Standard Library
- Reorganización de módulos
- Nuevas funciones de allocación
- Mejoras en manejo de errores

---

## Verificación Completa

Ejecuta este comando para verificar que todo funciona:

```bash
zig zen
```

Debe mostrar el "Zen of Zig"

---

## Documentación de Zig 0.15.2

- **Oficial:** https://ziglang.org/documentation/0.15.2/
- **Release Notes 0.15.1:** https://ziglang.org/download/0.15.1/release-notes.html
- **Context7:** Agregar docs de Zig 0.15.2 para mejor contexto con AI tools

---

## Siguiente Paso

Una vez verificado que Zig 0.15.2 está instalado correctamente, continuar con **01-setup.md** para inicializar el proyecto zig-pug.

---

## Troubleshooting

### Error: "not found" al ejecutar zig
- Verificar que el binario es compatible con tu arquitectura
- En Alpine: usar versión musl, NO glibc
- Verificar permisos de ejecución: `chmod +x /path/to/zig`

### Error: "version mismatch"
- Asegurar que no hay múltiples instalaciones de Zig
- Verificar PATH: `which zig`
- Reinstalar versión correcta

### Binario no ejecuta en Alpine
- Alpine usa musl libc
- Descargar versión `-linux-` (no `-glibc-`)
- Verificar con: `ldd /path/to/zig` (debe decir "not a dynamic executable" o mostrar musl)

---

## Estado de Instalación

✅ **Zig 0.15.2 instalado y verificado**

Estás listo para comenzar el proyecto zig-pug.
