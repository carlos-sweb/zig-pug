/**
 * Ejemplo 2: Interpolación de JavaScript
 * Muestra métodos de strings, números y expresiones complejas
 */

const zigpug = require('../../nodejs');

console.log('=== JavaScript Interpolation Example ===\n');

const template = `
div.user-profile
  h1 Welcome #{name.toUpperCase()}!

  div.info
    p Name: #{name}
    p Email: #{email.toLowerCase()}
    p Age: #{age}
    p Next year: #{age + 1}
    p Double age: #{age * 2}

  div.status
    p Is adult: #{age >= 18 ? 'Yes' : 'No'}
    p Account active: #{isActive}
`;

const variables = {
    name: 'Alice Johnson',
    email: 'ALICE.JOHNSON@EXAMPLE.COM',
    age: 25,
    isActive: true
};

const html = zigpug.compile(template, variables);

console.log('Variables:', variables);
console.log('\nCompiled HTML:');
console.log(html);

console.log('\n✓ All JavaScript expressions work!');
