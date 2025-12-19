#!/usr/bin/env node
/**
 * zig-pug - Ejemplo de manejo de errores
 *
 * Este ejemplo demuestra cómo capturar y manejar errores de compilación
 * con información estructurada incluyendo línea, mensaje, detalle y consejos.
 */

const zigpug = require('../../nodejs');

console.log('🔴 Ejemplo de Manejo de Errores\n');

// =============================================================================
// Ejemplo 1: Variable no definida en interpolación
// =============================================================================
console.log('📝 Ejemplo 1: Variable no definida\n');

try {
    const template = `
div.container
  h1 Título
  p Hola #{nombre}
  p Tu edad es #{edad}
`;

    const html = zigpug.compile(template);
    console.log(html);
} catch (error) {
    console.log('❌ Error capturado:');
    console.log('Mensaje:', error.message);

    // Acceder a los errores estructurados
    if (error.compilationErrors) {
        const { errorCount, errors } = error.compilationErrors;
        console.log(`\n📊 Total de errores: ${errorCount}\n`);

        errors.forEach((err, index) => {
            console.log(`Error ${index + 1}:`);
            console.log(`  📍 Línea: ${err.line}`);
            console.log(`  💬 Mensaje: ${err.message}`);
            if (err.detail) {
                console.log(`  ℹ️  Detalle: ${err.detail}`);
            }
            if (err.hint) {
                console.log(`  💡 Consejo: ${err.hint}`);
            }
            console.log('');
        });
    }
}

// =============================================================================
// Ejemplo 2: Error en loop - iterable no definido
// =============================================================================
console.log('\n📝 Ejemplo 2: Loop con iterable no definido\n');

try {
    const template = `
ul.lista
  each item in items
    li= item
`;

    const html = zigpug.compile(template);
    console.log(html);
} catch (error) {
    if (error.compilationErrors) {
        const { errors } = error.compilationErrors;
        const err = errors[0];

        console.log('❌ Error en loop:');
        console.log(`   Línea ${err.line}: ${err.message}`);
        if (err.detail) console.log(`   ${err.detail}`);
        if (err.hint) console.log(`   ${err.hint}`);
    }
}

// =============================================================================
// Ejemplo 3: Múltiples errores en una sola compilación
// =============================================================================
console.log('\n📝 Ejemplo 3: Múltiples errores\n');

try {
    const template = `
div
  p Valor: #{valor_no_definido}
  if condicion_inexistente
    p Sí
  each item in array_no_existe
    li= item
`;

    const html = zigpug.compile(template);
    console.log(html);
} catch (error) {
    if (error.compilationErrors) {
        const { errorCount, errors } = error.compilationErrors;

        console.log(`❌ Se encontraron ${errorCount} errores:\n`);

        // Mostrar resumen de errores
        errors.forEach((err, i) => {
            console.log(`${i + 1}. Línea ${err.line}: ${err.message}`);
        });
    }
}

// =============================================================================
// Ejemplo 4: Manejo correcto - Sin errores
// =============================================================================
console.log('\n📝 Ejemplo 4: Compilación exitosa\n');

try {
    const compiler = new zigpug.PugCompiler();

    // Definir todas las variables necesarias
    compiler.set('nombre', 'Carlos');
    compiler.set('edad', 30);
    compiler.setArray('items', ['Item 1', 'Item 2', 'Item 3']);
    compiler.setBool('activo', true);

    const template = `
div.perfil
  h1 Perfil de #{nombre}
  p Edad: #{edad}
  p Estado: #{activo ? 'Activo' : 'Inactivo'}
  ul
    each item in items
      li= item
`;

    const html = compiler.compile(template);
    console.log('✅ Compilación exitosa:');
    console.log(html);
} catch (error) {
    console.log('❌ Error inesperado:', error.message);
}

// =============================================================================
// Ejemplo 5: Función helper para manejar errores
// =============================================================================
console.log('\n📝 Ejemplo 5: Helper para manejo de errores\n');

/**
 * Helper para compilar templates con manejo de errores elegante
 */
function compileTemplate(template, variables = {}) {
    try {
        const compiler = new zigpug.PugCompiler();
        compiler.setVariables(variables);
        return {
            success: true,
            html: compiler.compile(template),
            errors: null
        };
    } catch (error) {
        if (error.compilationErrors) {
            return {
                success: false,
                html: null,
                errors: error.compilationErrors.errors
            };
        }

        // Error no relacionado con compilación
        return {
            success: false,
            html: null,
            errors: [{ message: error.message }]
        };
    }
}

// Probar el helper
const result = compileTemplate(`
div
  p Usuario: #{username}
  p Email: #{email}
`, {
    username: 'johndoe'
    // Falta 'email' - causará error
});

if (result.success) {
    console.log('✅ HTML generado:', result.html);
} else {
    console.log('❌ Errores encontrados:');
    result.errors.forEach(err => {
        console.log(`   - Línea ${err.line || '?'}: ${err.message}`);
        if (err.hint) console.log(`     💡 ${err.hint}`);
    });
}

// =============================================================================
// Ejemplo 6: Validación de template antes de usar en producción
// =============================================================================
console.log('\n📝 Ejemplo 6: Validación de template\n');

/**
 * Valida un template compilándolo con datos de prueba
 */
function validateTemplate(template, testData = {}) {
    const result = compileTemplate(template, testData);

    if (result.success) {
        console.log('✅ Template válido');
        return true;
    } else {
        console.log('❌ Template inválido:');
        result.errors.forEach((err, i) => {
            console.log(`\n   Error ${i + 1}:`);
            console.log(`   📍 Línea: ${err.line}`);
            console.log(`   💬 ${err.message}`);
            if (err.detail) console.log(`   ℹ️  ${err.detail}`);
            if (err.hint) console.log(`   💡 ${err.hint}`);
        });
        return false;
    }
}

// Validar un template
const myTemplate = `
article.post
  h2= title
  p.author Por #{author}
  .content= content
`;

validateTemplate(myTemplate, {
    title: 'Ejemplo',
    author: 'Anónimo',
    content: 'Contenido de prueba'
});

console.log('\n✨ Fin de los ejemplos\n');
