/**
 * Ejemplo 4: Compilar desde archivos
 * Muestra cómo compilar templates guardados en archivos .pug
 */

const { compileFile } = require('../../nodejs');
const fs = require('fs');
const path = require('path');

console.log('=== File Compilation Example ===\n');

// Crear un template de ejemplo
const templatePath = path.join(__dirname, 'temp-template.pug');
const templateContent = `
div.card
  h2 #{title}
  p #{description}
  p Created: #{date}
`;

fs.writeFileSync(templatePath, templateContent);
console.log(`Created template file: ${templatePath}`);

// Variables
const variables = {
    title: 'Welcome Card',
    description: 'This template was loaded from a file!',
    date: new Date().toISOString().split('T')[0]
};

// Compilar desde archivo
const html = compileFile(templatePath, variables);

console.log('\nTemplate content:');
console.log(templateContent);
console.log('\nVariables:', variables);
console.log('\nCompiled HTML:');
console.log(html);

// Limpiar
fs.unlinkSync(templatePath);
console.log('\n✓ Template file compiled successfully!');
