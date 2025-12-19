# TypeScript Usage Guide

Complete guide for using zig-pug with TypeScript.

## Prerequisites

```bash
npm install --save-dev typescript @types/node ts-node
```

## Type Definitions

zig-pug includes comprehensive TypeScript definitions (`index.d.ts`) that provide:

- ✅ Full IntelliSense support
- ✅ Type-safe API
- ✅ Error type definitions
- ✅ Compile-time type checking
- ✅ JSDoc documentation

## Quick Start

### Basic Import

```typescript
import { compile, PugCompiler } from 'zig-pug';

// Simple compilation
const html: string = compile('p Hello #{name}', { name: 'World' });
```

### Using PugCompiler

```typescript
import { PugCompiler } from 'zig-pug';

const compiler: PugCompiler = new PugCompiler();

// Type-safe method chaining
compiler
    .setString('title', 'My Page')    // Only accepts string
    .setNumber('count', 42)            // Only accepts number
    .setBool('active', true)           // Only accepts boolean
    .setArray('items', [1, 2, 3])      // Only accepts array
    .setObject('user', { id: 1 });     // Only accepts object

const html: string = compiler.compile(template);
```

## Error Handling

### Type-Safe Error Catching

```typescript
import { compile, ZigPugCompilationError } from 'zig-pug';

try {
    const html = compile(template, variables);
} catch (error) {
    // Type assertion for error handling
    const err = error as ZigPugCompilationError;

    if (err.compilationErrors) {
        const { errorCount, errors } = err.compilationErrors;

        console.error(`Compilation failed with ${errorCount} error(s)`);

        errors.forEach(e => {
            console.error(`Line ${e.line}: ${e.message}`);
            if (e.detail) console.error(`  Detail: ${e.detail}`);
            if (e.hint) console.error(`  Hint: ${e.hint}`);
            if (e.type) console.error(`  Type: ${e.type}`);
        });
    } else {
        console.error('Unexpected error:', err.message);
    }
}
```

### Error Types

```typescript
import { CompilationErrorInfo, ErrorType } from 'zig-pug';

// Individual error information
interface CompilationErrorInfo {
    type?: ErrorType;
    line: number;
    message: string;
    detail?: string;
    hint?: string;
}

// Error type classification
type ErrorType =
    | 'LoopIterableEvalFailed'
    | 'ConditionalEvalFailed'
    | 'InterpolationEvalFailed'
    | 'AttributeEvalFailed'
    | 'CodeExecutionFailed'
    | 'CaseEvalFailed'
    | 'MixinNotFound'
    | 'IncludeFileNotFound'
    | 'IncludeParseError'
    | 'ExtendsFileNotFound'
    | 'ExtendsParseError';
```

## Advanced Patterns

### Generic Helper Function

```typescript
import { compile, PugVariables, ZigPugCompilationError } from 'zig-pug';

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
        return { success: true, html };
    } catch (error) {
        const err = error as ZigPugCompilationError;

        if (err.compilationErrors) {
            return {
                success: false,
                errors: err.compilationErrors.errors
            };
        }

        return {
            success: false,
            errors: [{ line: 0, message: err.message }]
        };
    }
}

// Usage
const result = safeCompile('h1= title', { title: 'Hello' });

if (result.success && result.html) {
    console.log(result.html);
} else if (result.errors) {
    result.errors.forEach(err => {
        console.error(`Error at line ${err.line}: ${err.message}`);
    });
}
```

### Type-Safe Template Builder

```typescript
import { PugCompiler, PugVariables } from 'zig-pug';

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
        // Implementation
    }
}
```

### Async Wrapper

```typescript
import { compile, PugVariables } from 'zig-pug';

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

// Usage with async/await
async function renderPage() {
    try {
        const html = await compileAsync(
            'h1= title',
            { title: 'Async Page' }
        );
        return html;
    } catch (error) {
        const err = error as ZigPugCompilationError;
        console.error('Compilation failed:', err.message);
        throw err;
    }
}
```

### Strongly-Typed Variables

```typescript
import { compile } from 'zig-pug';

// Define your data model
interface PageData {
    title: string;
    description: string;
    author: {
        name: string;
        email: string;
    };
    tags: string[];
    publishDate: Date;
}

function renderPage(data: PageData): string {
    // Variables are type-checked
    const html = compile(
        `
article
  h1= title
  p.description= description
  .author
    p= author.name
    p= author.email
  ul.tags
    each tag in tags
      li= tag
`,
        {
            ...data,
            publishDate: data.publishDate.toISOString()
        }
    );

    return html;
}

// TypeScript ensures correct data structure
const html = renderPage({
    title: 'My Article',
    description: 'Article description',
    author: {
        name: 'John Doe',
        email: 'john@example.com'
    },
    tags: ['typescript', 'pug'],
    publishDate: new Date()
});
```

## tsconfig.json

Recommended TypeScript configuration:

```json
{
  "compilerOptions": {
    "target": "ES2020",
    "module": "commonjs",
    "lib": ["ES2020"],
    "outDir": "./dist",
    "rootDir": "./src",
    "strict": true,
    "esModuleInterop": true,
    "skipLibCheck": true,
    "forceConsistentCasingInFileNames": true,
    "resolveJsonModule": true,
    "moduleResolution": "node",
    "types": ["node"]
  },
  "include": ["src/**/*"],
  "exclude": ["node_modules"]
}
```

## IntelliSense Features

When using zig-pug with TypeScript in VS Code or other editors:

### Autocomplete

Type `compiler.` and get:
- `set()` - Auto-detect type
- `setString()` - String values
- `setNumber()` - Number values
- `setBool()` - Boolean values
- `setArray()` - Array values
- `setObject()` - Object values
- `setVariables()` - Multiple variables
- `compile()` - Compile template
- `render()` - Compile with variables

### Parameter Info

Hover over methods to see:
- Parameter types
- Return types
- JSDoc descriptions
- Usage examples

### Type Checking

```typescript
const compiler = new PugCompiler();

// ✅ Valid
compiler.setString('name', 'John');
compiler.setNumber('age', 30);

// ❌ Type error
compiler.setString('name', 123); // Error: number not assignable to string
compiler.setNumber('age', 'thirty'); // Error: string not assignable to number
```

## Examples

See `08-typescript-example.ts` for complete working examples including:

1. Simple compilation with type inference
2. PugCompiler class usage
3. Structured error handling
4. Generic helper functions
5. Type-safe template builder
6. Async compilation wrapper

## Troubleshooting

### Types not found

If TypeScript can't find the types:

1. Check `node_modules/zig-pug/index.d.ts` exists
2. Try `npm install` again
3. Add to `tsconfig.json`:
   ```json
   {
     "compilerOptions": {
       "typeRoots": ["./node_modules/@types", "./node_modules/zig-pug"]
     }
   }
   ```

### Compilation errors

Make sure you're using:
- TypeScript >= 4.0
- Node.js >= 14.0.0

### Import errors

Use the correct import syntax:

```typescript
// ✅ Correct
import { compile, PugCompiler } from 'zig-pug';

// ❌ Incorrect
import compile from 'zig-pug';
```

## Resources

- [TypeScript Handbook](https://www.typescriptlang.org/docs/handbook/intro.html)
- [Type Definitions Guide](https://www.typescriptlang.org/docs/handbook/declaration-files/introduction.html)
- [zig-pug Examples](https://github.com/carlos-sweb/zig-pug/tree/main/examples/nodejs)
