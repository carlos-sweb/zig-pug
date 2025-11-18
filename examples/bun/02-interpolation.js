// 02-interpolation.js - Expresiones JavaScript complejas con Bun.js
// Ejecutar: bun run 02-interpolation.js

const zigpug = require('../../nodejs');

console.log('=== Interpolación JavaScript con zig-pug ===\n');

// Template con expresiones complejas
const template = `
doctype html
html(lang="es")
  head
    title #{pageTitle.toUpperCase()}
  body
    div.user-card
      h1 #{firstName} #{lastName}
      p.email Email: #{email.toLowerCase()}
      p.age Edad: #{age}
      p.next-year El próximo año: #{age + 1}
      p.status Status: #{age >= 18 ? 'Adulto' : 'Menor'}

    div.math
      h2 Cálculos Matemáticos
      p Max(10, 25): #{Math.max(10, 25)}
      p Min(10, 25): #{Math.min(10, 25)}
      p Random: #{Math.floor(Math.random() * 100)}

    div.strings
      h2 Manipulación de Strings
      p Mayúsculas: #{firstName.toUpperCase()}
      p Minúsculas: #{lastName.toLowerCase()}
      p Nombre completo: #{firstName + ' ' + lastName}
`;

const data = {
    pageTitle: 'perfil de usuario',
    firstName: 'Alice',
    lastName: 'Johnson',
    email: 'ALICE.JOHNSON@EXAMPLE.COM',
    age: 25
};

console.log('Data:');
console.log(JSON.stringify(data, null, 2));
console.log('');

const html = zigpug.compile(template, data);

console.log('HTML generado:');
console.log(html);

// Ejemplo con objetos anidados
console.log('\n=== Objetos Anidados ===\n');

const nestedTemplate = `
div.user
  h1 #{user.name}
  p Location: #{user.location.city}, #{user.location.country}
  p Skills: #{user.skills.length} skills
  p First skill: #{user.skills[0]}
`;

const nestedData = {
    user: {
        name: 'Bob',
        location: {
            city: 'San Francisco',
            country: 'USA'
        },
        skills: ['JavaScript', 'Python', 'Zig']
    }
};

const nestedHtml = zigpug.compile(nestedTemplate, nestedData);
console.log('HTML con objetos anidados:');
console.log(nestedHtml);
