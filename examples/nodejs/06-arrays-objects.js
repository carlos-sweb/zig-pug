/**
 * Example 6: Arrays and Objects Support
 * Demonstrates setting and using arrays and objects in templates
 */

const zigpug = require('../../nodejs');

console.log('=== Arrays and Objects Example ===\n');

const template = `
doctype html
html(lang="en")
  head
    title #{pageTitle}
  body
    h1 Welcome #{user.name}!

    div.user-info
      p Email: #{user.email}
      p Age: #{user.age}
      p Role: #{user.role}

    div.items-section
      h2 Shopping List
      ul.items
        each item in items
          li= item

    div.products-section
      h2 Products
      each product in products
        div.product
          h3= product.name
          p Price: $#{product.price}
          p Stock: #{product.stock}

    div.nested-section
      h2 Company Info
      p Name: #{company.name}
      p Location: #{company.location.city}, #{company.location.country}
      p Founded: #{company.founded}
`;

// Example using setArray and setObject directly
console.log('--- Method 1: Using setArray() and setObject() ---\n');

const compiler1 = new zigpug.PugCompiler();

compiler1
    .setString('pageTitle', 'Arrays & Objects Demo')
    .setObject('user', {
        name: 'Alice Johnson',
        email: 'alice@example.com',
        age: 30,
        role: 'Developer'
    })
    .setArray('items', ['Apples', 'Bananas', 'Oranges', 'Grapes'])
    .setArray('products', [
        { name: 'Laptop', price: 999, stock: 5 },
        { name: 'Mouse', price: 25, stock: 50 },
        { name: 'Keyboard', price: 75, stock: 20 }
    ])
    .setObject('company', {
        name: 'Tech Corp',
        location: {
            city: 'San Francisco',
            country: 'USA'
        },
        founded: 2010
    });

const html1 = compiler1.compile(template);
console.log('HTML Output (truncated):');
console.log(html1.substring(0, 200) + '...\n');

// Example using setVariables (auto-detects types)
console.log('--- Method 2: Using setVariables() (auto-detect) ---\n');

const compiler2 = new zigpug.PugCompiler();

const html2 = compiler2.render(template, {
    pageTitle: 'Arrays & Objects Demo',
    user: {
        name: 'Bob Smith',
        email: 'bob@example.com',
        age: 25,
        role: 'Designer'
    },
    items: ['Coffee', 'Tea', 'Milk', 'Juice'],
    products: [
        { name: 'Phone', price: 699, stock: 10 },
        { name: 'Tablet', price: 499, stock: 15 }
    ],
    company: {
        name: 'Design Studio',
        location: {
            city: 'New York',
            country: 'USA'
        },
        founded: 2015
    }
});

console.log('HTML Output (truncated):');
console.log(html2.substring(0, 200) + '...\n');

// Example with nested arrays
console.log('--- Method 3: Complex nested structures ---\n');

const complexTemplate = `
div.matrix
  each row in matrix
    div.row
      each cell in row
        span.cell= cell
`;

const compiler3 = new zigpug.PugCompiler();
compiler3.setArray('matrix', [
    [1, 2, 3],
    [4, 5, 6],
    [7, 8, 9]
]);

const html3 = compiler3.compile(complexTemplate);
console.log('Matrix HTML:');
console.log(html3);

console.log('\n✓ Arrays and objects work perfectly!');
console.log('\nSupported types:');
console.log('  - Strings: setString() or auto-detect');
console.log('  - Numbers: setNumber() or auto-detect');
console.log('  - Booleans: setBool() or auto-detect');
console.log('  - Arrays: setArray() or auto-detect');
console.log('  - Objects: setObject() or auto-detect');
console.log('  - Nested structures: Fully supported!');
