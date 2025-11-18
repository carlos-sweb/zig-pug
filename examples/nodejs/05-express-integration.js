/**
 * Ejemplo 5: Integración con Express.js
 * Muestra cómo usar zig-pug como motor de templates en Express
 */

const zigpug = require('../../nodejs');

// Función para crear un motor de templates de Express
function createExpressEngine() {
    return function(filePath, options, callback) {
        const fs = require('fs');

        fs.readFile(filePath, 'utf8', (err, template) => {
            if (err) return callback(err);

            try {
                const html = zigpug.compile(template, options);
                callback(null, html);
            } catch (compileErr) {
                callback(compileErr);
            }
        });
    };
}

// Ejemplo de uso (sin Express instalado, solo mostramos el código)
console.log('=== Express Integration Example ===\n');

console.log('To use zig-pug with Express, add this to your app:');
console.log(`
const express = require('express');
const zigpug = require('zig-pug');

const app = express();

// Register zig-pug as template engine
app.engine('pug', createExpressEngine());
app.set('view engine', 'pug');
app.set('views', './views');

// Use in routes
app.get('/', (req, res) => {
    res.render('index', {
        title: 'Home Page',
        user: req.user,
        items: [1, 2, 3]
    });
});

app.listen(3000);
`);

// Demo sin Express
const template = `
html
  head
    title #{title}
  body
    h1 #{heading}
    p #{message}
`;

const html = zigpug.compile(template, {
    title: 'Express + zig-pug',
    heading: 'Hello from Express!',
    message: 'This could be rendered by Express.js'
});

console.log('\nDemo template compilation:');
console.log(html);

console.log('\n✓ Ready for Express integration!');
