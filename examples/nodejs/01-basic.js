/**
 * Ejemplo 1: Uso Básico de zig-pug en Node.js
 * Muestra cómo compilar un template simple con la función compile()
 */

const zigpug = require('../../nodejs');

console.log('=== zig-pug Basic Example ===\n');

// Template Pug simple
const template = `
div.greeting
  h1 Hello World!
  p This is zig-pug running in Node.js
  p Version: #{version}
`;

// Variables para el template
const variables = {
    version: '0.2.0'
};

// Compilar
const html = zigpug.compile(template, variables);

console.log('Template:');
console.log(template);
console.log('\nCompiled HTML:');
console.log(html);

console.log('\n✓ Success!');
