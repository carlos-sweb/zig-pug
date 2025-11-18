// 05-file-compilation.js - Compilar archivos .pug desde disco
// Ejecutar: bun run 05-file-compilation.js

const zigpug = require('../../nodejs');
const fs = require('fs');
const path = require('path');

console.log('=== Compilación de Archivos .pug con Bun.js ===\n');

// Función helper para compilar archivos
function compileFile(templatePath, data = {}) {
    const absolutePath = path.resolve(templatePath);
    console.log(`Leyendo: ${absolutePath}`);

    const template = fs.readFileSync(absolutePath, 'utf-8');
    return zigpug.compile(template, data);
}

// Crear un template de ejemplo
const exampleTemplate = `
doctype html
html(lang="#{lang}")
  head
    meta(charset="utf-8")
    title #{title}
    style.
      body { font-family: system-ui; max-width: 800px; margin: 40px auto; padding: 20px; }
      .user { background: #f0f0f0; padding: 20px; border-radius: 8px; margin: 10px 0; }
  body
    h1 #{title}

    div.user
      h2 #{user.name}
      p Email: #{user.email}
      p Edad: #{user.age}
      if user.age >= 18
        p.status ✓ Mayor de edad
      else
        p.status ✗ Menor de edad

    footer
      p Generado con zig-pug + Bun.js #{bunVersion}
`;

// Guardar template en archivo temporal
const tempDir = '/tmp/zigpug-examples';
const templatePath = path.join(tempDir, 'user-profile.pug');

if (!fs.existsSync(tempDir)) {
    fs.mkdirSync(tempDir, { recursive: true });
    console.log(`Creado directorio: ${tempDir}\n`);
}

fs.writeFileSync(templatePath, exampleTemplate);
console.log(`✓ Template guardado en: ${templatePath}\n`);

// Compilar el archivo con diferentes datos
console.log('=== Compilando con diferentes usuarios ===\n');

const users = [
    { name: 'Alice', email: 'alice@example.com', age: 25 },
    { name: 'Bob', email: 'bob@example.com', age: 17 },
    { name: 'Charlie', email: 'charlie@example.com', age: 30 }
];

users.forEach((user, index) => {
    console.log(`Usuario ${index + 1}: ${user.name}`);

    const html = compileFile(templatePath, {
        lang: 'es',
        title: `Perfil de ${user.name}`,
        user: user,
        bunVersion: Bun.version
    });

    // Guardar HTML compilado
    const outputPath = path.join(tempDir, `${user.name.toLowerCase()}.html`);
    fs.writeFileSync(outputPath, html);
    console.log(`  ✓ HTML generado: ${outputPath}\n`);
});

// Función para compilar múltiples archivos en batch
console.log('=== Batch Compilation ===\n');

function compileBatch(files, outputDir) {
    const results = [];
    const start = Bun.nanoseconds();

    files.forEach(({ templatePath, data, outputName }) => {
        const html = compileFile(templatePath, data);
        const outputPath = path.join(outputDir, outputName);
        fs.writeFileSync(outputPath, html);
        results.push(outputPath);
    });

    const elapsed = (Bun.nanoseconds() - start) / 1000000;
    return { results, elapsed };
}

const batchFiles = users.map((user, index) => ({
    templatePath: templatePath,
    data: {
        lang: 'es',
        title: `Perfil de ${user.name}`,
        user: user,
        bunVersion: Bun.version
    },
    outputName: `batch-${user.name.toLowerCase()}.html`
}));

const { results, elapsed } = compileBatch(batchFiles, tempDir);

console.log(`✓ Compilados ${results.length} archivos en ${elapsed.toFixed(2)}ms`);
console.log(`  (${(elapsed / results.length).toFixed(2)}ms por archivo)\n`);

results.forEach(file => {
    console.log(`  - ${file}`);
});

// Watch mode (simulado)
console.log('\n=== Watch Mode (Simulado) ===\n');

let watchCount = 0;
const MAX_WATCHES = 3;

console.log(`Observando cambios en: ${templatePath}`);
console.log('(Presiona Ctrl+C para detener)\n');

const watcher = fs.watch(templatePath, (eventType, filename) => {
    if (eventType === 'change') {
        watchCount++;
        console.log(`[${new Date().toLocaleTimeString()}] Cambio detectado, recompilando...`);

        const html = compileFile(templatePath, {
            lang: 'es',
            title: 'Perfil Actualizado',
            user: users[0],
            bunVersion: Bun.version
        });

        const outputPath = path.join(tempDir, 'watched-output.html');
        fs.writeFileSync(outputPath, html);
        console.log(`  ✓ Recompilado: ${outputPath}\n`);

        // Detener después de algunos cambios (para el ejemplo)
        if (watchCount >= MAX_WATCHES) {
            console.log('Deteniendo watch mode...\n');
            watcher.close();
            showSummary();
        }
    }
});

function showSummary() {
    console.log('=== Resumen ===\n');
    console.log(`Directorio de salida: ${tempDir}`);
    console.log('Archivos generados:');

    const files = fs.readdirSync(tempDir)
        .filter(f => f.endsWith('.html'))
        .map(f => {
            const stats = fs.statSync(path.join(tempDir, f));
            return { name: f, size: stats.size };
        });

    files.forEach(file => {
        console.log(`  - ${file.name} (${file.size} bytes)`);
    });

    console.log(`\n✓ Total: ${files.length} archivos HTML`);
    console.log('\n💡 Tip: Puedes abrir estos archivos en un navegador para ver el resultado');
}

// Si el watcher no se activa, mostrar resumen después de 2 segundos
setTimeout(() => {
    if (watchCount === 0) {
        console.log('(No se detectaron cambios)\n');
        watcher.close();
        showSummary();
    }
}, 2000);
