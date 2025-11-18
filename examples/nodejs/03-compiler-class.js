/**
 * Ejemplo 3: Usando la clase PugCompiler
 * Muestra el uso de la API orientada a objetos con method chaining
 */

const { PugCompiler } = require('../../nodejs');

console.log('=== PugCompiler Class Example ===\n');

// Crear una instancia del compilador
const compiler = new PugCompiler();

// Establecer variables con method chaining
compiler
    .set('siteName', 'My Website')
    .set('year', 2024)
    .set('isProduction', true);

// También puedes usar métodos específicos
compiler
    .setString('author', 'John Doe')
    .setNumber('visitors', 1250)
    .setBool('showBanner', false);

const template = `
div.site-info
  h1 #{siteName}
  p © #{year} by #{author}
  p Visitors: #{visitors}

  if isProduction
    p Running in production mode
  else
    p Running in development mode

  unless showBanner
    p Banner is hidden
`;

const html = compiler.compile(template);

console.log('Template:');
console.log(template);
console.log('\nCompiled HTML:');
console.log(html);

console.log('\n✓ Method chaining works great!');
