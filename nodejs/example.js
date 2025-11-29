#!/usr/bin/env node

/**
 * Simple example showing how to use zig-pug from Node.js
 */

const pug = require('./index.js');

console.log('🎨 zig-pug Example\n');

// Example 1: Simple template
console.log('Example 1: Simple template');
const template1 = 'p Hello World';
const html1 = pug.compile(template1);
console.log(`Template: ${template1}`);
console.log(`Output:   ${html1}\n`);

// Example 2: Template with variables
console.log('Example 2: Template with variables');
const template2 = `div.card
  h1 #{title}
  p #{description}`;

const html2 = pug.compile(template2, {
    title: 'Welcome to zig-pug',
    description: 'A high-performance Pug compiler powered by Zig'
});

console.log(`Template:`);
console.log(template2);
console.log(`\nOutput:   ${html2}\n`);

// Example 3: Using ZigPugCompiler class
console.log('Example 3: Using ZigPugCompiler class for multiple compilations');
const compiler = new pug.ZigPugCompiler();

compiler.setVariables({
    siteName: 'My Website',
    year: 2024,
    active: true
});

const template3 = `footer
  p Copyright #{year} #{siteName}`;

const html3 = compiler.compile(template3);
console.log(`Template: ${template3}`);
console.log(`Output:   ${html3}\n`);

console.log('✨ Done!');
