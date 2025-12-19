#!/usr/bin/env ts-node
/**
 * zig-pug - TypeScript Usage Example
 *
 * This example demonstrates how to use zig-pug with TypeScript
 * with full type safety and IntelliSense support.
 */

import {
    PugCompiler,
    compile,
    compileFile,
    version,
    ZigPugCompilationError,
    CompilationErrorInfo,
    PugVariables
} from '../../nodejs';

console.log('🔷 TypeScript Example - zig-pug\n');
console.log(`Version: ${version()}\n`);

// =============================================================================
// Example 1: Simple compilation with type inference
// =============================================================================
console.log('📝 Example 1: Simple Compilation\n');

const template1: string = 'p Hello #{name}!';
const vars1: PugVariables = {
    name: 'TypeScript'
};

try {
    const html1: string = compile(template1, vars1);
    console.log('✅ Result:', html1);
} catch (error) {
    console.error('❌ Error:', (error as Error).message);
}

// =============================================================================
// Example 2: Using PugCompiler class with type safety
// =============================================================================
console.log('\n📝 Example 2: PugCompiler Class\n');

const compiler: PugCompiler = new PugCompiler();

// Method chaining with type checking
compiler
    .setString('title', 'TypeScript Page')
    .setNumber('year', 2024)
    .setBool('isPublished', true)
    .setArray('tags', ['typescript', 'zig', 'pug'])
    .setObject('author', {
        name: 'John Doe',
        email: 'john@example.com'
    });

const template2 = `
article
  h1= title
  p.year Year: #{year}
  p.status Status: #{isPublished ? 'Published' : 'Draft'}
  ul.tags
    each tag in tags
      li= tag
  .author
    p Author: #{author.name}
    p Email: #{author.email}
`;

try {
    const html2: string = compiler.compile(template2);
    console.log('✅ Compiled successfully');
    console.log(html2);
} catch (error) {
    console.error('❌ Error:', (error as Error).message);
}

// =============================================================================
// Example 3: Structured error handling with types
// =============================================================================
console.log('\n📝 Example 3: Error Handling with Types\n');

interface UserData {
    username: string;
    email: string;
    age?: number;
}

function compileUserTemplate(data: Partial<UserData>): string | null {
    const compiler = new PugCompiler();

    // Set only provided data
    if (data.username) compiler.setString('username', data.username);
    if (data.email) compiler.setString('email', data.email);
    if (data.age !== undefined) compiler.setNumber('age', data.age);

    const template = `
div.user
  p Username: #{username}
  p Email: #{email}
  if age
    p Age: #{age}
`;

    try {
        return compiler.compile(template);
    } catch (error) {
        // Type-safe error handling
        const compilationError = error as ZigPugCompilationError;

        if (compilationError.compilationErrors) {
            const { errorCount, errors } = compilationError.compilationErrors;

            console.log(`❌ Compilation failed with ${errorCount} error(s):\n`);

            errors.forEach((err: CompilationErrorInfo, index: number) => {
                console.log(`Error ${index + 1}:`);
                console.log(`  📍 Line: ${err.line}`);
                console.log(`  💬 Message: ${err.message}`);

                if (err.detail) {
                    console.log(`  ℹ️  Detail: ${err.detail}`);
                }

                if (err.hint) {
                    console.log(`  💡 Hint: ${err.hint}`);
                }

                if (err.type) {
                    console.log(`  🏷️  Type: ${err.type}`);
                }

                console.log('');
            });

            return null;
        }

        console.error('❌ Unexpected error:', compilationError.message);
        return null;
    }
}

// Test with missing data (will cause errors)
const result1 = compileUserTemplate({
    username: 'johndoe'
    // email is missing - will cause error
});

console.log(result1 ? '✅ Success' : '❌ Failed as expected\n');

// Test with complete data
const result2 = compileUserTemplate({
    username: 'johndoe',
    email: 'john@example.com',
    age: 30
});

if (result2) {
    console.log('✅ Compiled successfully:');
    console.log(result2);
}

// =============================================================================
// Example 4: Generic helper function with types
// =============================================================================
console.log('\n📝 Example 4: Generic Helper Function\n');

interface CompilationResult<T = string> {
    success: boolean;
    html?: T;
    errors?: CompilationErrorInfo[];
}

function safeCompile<T extends PugVariables>(
    template: string,
    variables?: T
): CompilationResult {
    try {
        const html = compile(template, variables);
        return {
            success: true,
            html
        };
    } catch (error) {
        const compilationError = error as ZigPugCompilationError;

        if (compilationError.compilationErrors) {
            return {
                success: false,
                errors: compilationError.compilationErrors.errors
            };
        }

        return {
            success: false,
            errors: [{
                line: 0,
                message: compilationError.message
            }]
        };
    }
}

const result: CompilationResult = safeCompile(
    'h1= title\np= description',
    {
        title: 'TypeScript Example',
        description: 'Safe compilation with types'
    }
);

if (result.success && result.html) {
    console.log('✅ Success:', result.html);
} else if (result.errors) {
    console.log('❌ Errors found:');
    result.errors.forEach(err => {
        console.log(`  Line ${err.line}: ${err.message}`);
    });
}

// =============================================================================
// Example 5: Type-safe template builder
// =============================================================================
console.log('\n📝 Example 5: Type-Safe Template Builder\n');

class TemplateBuilder {
    private compiler: PugCompiler;
    private template: string = '';

    constructor() {
        this.compiler = new PugCompiler();
    }

    addVariable(key: string, value: PugVariables[string]): this {
        this.compiler.set(key, value);
        return this;
    }

    setTemplate(template: string): this {
        this.template = template;
        return this;
    }

    build(): CompilationResult {
        if (!this.template) {
            return {
                success: false,
                errors: [{
                    line: 0,
                    message: 'No template provided'
                }]
            };
        }

        try {
            const html = this.compiler.compile(this.template);
            return {
                success: true,
                html
            };
        } catch (error) {
            const compilationError = error as ZigPugCompilationError;

            if (compilationError.compilationErrors) {
                return {
                    success: false,
                    errors: compilationError.compilationErrors.errors
                };
            }

            return {
                success: false,
                errors: [{
                    line: 0,
                    message: compilationError.message
                }]
            };
        }
    }
}

const builder = new TemplateBuilder();
const builderResult = builder
    .addVariable('product', 'TypeScript Book')
    .addVariable('price', 29.99)
    .addVariable('inStock', true)
    .setTemplate(`
div.product
  h2= product
  p.price $#{price}
  if inStock
    p.status In Stock
  else
    p.status Out of Stock
`)
    .build();

if (builderResult.success && builderResult.html) {
    console.log('✅ Built successfully:');
    console.log(builderResult.html);
} else if (builderResult.errors) {
    console.log('❌ Build failed:');
    builderResult.errors.forEach(err => {
        console.log(`  ${err.message}`);
    });
}

// =============================================================================
// Example 6: Async compilation wrapper
// =============================================================================
console.log('\n📝 Example 6: Async Wrapper\n');

async function compileAsync(
    template: string,
    variables?: PugVariables
): Promise<string> {
    return new Promise((resolve, reject) => {
        try {
            const html = compile(template, variables);
            resolve(html);
        } catch (error) {
            reject(error);
        }
    });
}

async function asyncExample(): Promise<void> {
    try {
        const html = await compileAsync(
            'div.async\n  p= message',
            { message: 'Async compilation works!' }
        );
        console.log('✅ Async result:', html);
    } catch (error) {
        const err = error as ZigPugCompilationError;
        console.error('❌ Async error:', err.message);

        if (err.compilationErrors) {
            err.compilationErrors.errors.forEach(e => {
                console.error(`  Line ${e.line}: ${e.message}`);
            });
        }
    }
}

asyncExample().then(() => {
    console.log('\n✨ TypeScript examples completed!\n');
});
