import { compileFile } from './index.js';

const variables = {
    users: ['Alice', 'Bob', 'Charlie'],
    fruits: ['Apple', 'Banana', 'Orange'],
    products: ['Laptop', 'Phone']
};

const htmlPretty = compileFile('./../examples/loops.zpug', variables, { pretty: true });
console.log('=== API with pretty: true ===');
console.log(htmlPretty);
