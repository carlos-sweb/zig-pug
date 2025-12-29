import { compileFile } from './nodejs/index.js';
import * as fs from 'fs';

// Variables para el template
const variables = {
    users: ['Alice', 'Bob', 'Charlie'],
    fruits: ['Apple', 'Banana', 'Orange'],
    products: ['Laptop', 'Phone']
};

// Compilar con pretty: true
const htmlPretty = compileFile('examples/loops.zpug', variables, { pretty: true });

console.log('=== API with pretty: true ===');
console.log(htmlPretty);
console.log('');

// Compilar con format: true (similar a -F del CLI)
const htmlFormat = compileFile('examples/loops.zpug', variables, { format: true });

console.log('=== API with format: true ===');
console.log(htmlFormat);
