/**
 * zig-pug TypeScript definitions
 * Pug template engine powered by Zig
 */

/**
 * Error type classification
 */
export type ErrorType =
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

/**
 * Structured compilation error information
 */
export interface CompilationErrorInfo {
    /** Error type classification */
    type?: ErrorType;
    /** Line number where the error occurred */
    line: number;
    /** Error message */
    message: string;
    /** Additional detail/context (e.g., expression, variable name) */
    detail?: string;
    /** Hint to help fix the error */
    hint?: string;
}

/**
 * Compilation errors container
 */
export interface CompilationErrors {
    /** Total number of errors */
    errorCount: number;
    /** Array of individual error details */
    errors: CompilationErrorInfo[];
}

/**
 * Extended Error with compilation details
 */
export interface ZigPugCompilationError extends Error {
    /** Structured compilation error information */
    compilationErrors?: CompilationErrors;
}

/**
 * Supported variable types
 */
export type PugVariable = string | number | boolean | any[] | Record<string, any>;

/**
 * Variables object for template compilation
 */
export interface PugVariables {
    [key: string]: PugVariable;
}

/**
 * PugCompiler class for advanced usage with reusable context
 *
 * @example
 * ```typescript
 * const compiler = new PugCompiler();
 * compiler.set('title', 'My Page');
 * compiler.setArray('items', ['a', 'b', 'c']);
 * const html = compiler.compile('h1= title');
 * ```
 */
export class PugCompiler {
    /**
     * Create a new PugCompiler instance
     * @throws {Error} If context creation fails
     */
    constructor();

    /**
     * Set a variable (auto-detects type)
     * @param key - Variable name
     * @param value - Variable value (string, number, boolean, array, or object)
     * @returns This compiler instance for chaining
     * @throws {TypeError} If value type is not supported
     *
     * @example
     * ```typescript
     * compiler.set('name', 'John');
     * compiler.set('age', 30);
     * compiler.set('active', true);
     * compiler.set('tags', ['a', 'b']);
     * compiler.set('user', { id: 1, name: 'John' });
     * ```
     */
    set(key: string, value: PugVariable): this;

    /**
     * Set a string variable
     * @param key - Variable name
     * @param value - String value
     * @returns This compiler instance for chaining
     * @throws {TypeError} If key or value is not a string
     * @throws {Error} If setting the variable fails
     *
     * @example
     * ```typescript
     * compiler.setString('title', 'Hello World');
     * ```
     */
    setString(key: string, value: string): this;

    /**
     * Set a number variable
     * @param key - Variable name
     * @param value - Number value
     * @returns This compiler instance for chaining
     * @throws {TypeError} If key is not a string or value is not a number
     * @throws {Error} If setting the variable fails
     *
     * @example
     * ```typescript
     * compiler.setNumber('count', 42);
     * compiler.setNumber('price', 19.99);
     * ```
     */
    setNumber(key: string, value: number): this;

    /**
     * Set a boolean variable
     * @param key - Variable name
     * @param value - Boolean value
     * @returns This compiler instance for chaining
     * @throws {TypeError} If key is not a string or value is not a boolean
     * @throws {Error} If setting the variable fails
     *
     * @example
     * ```typescript
     * compiler.setBool('isActive', true);
     * compiler.setBool('hasPermission', false);
     * ```
     */
    setBool(key: string, value: boolean): this;

    /**
     * Set an array variable
     * @param key - Variable name
     * @param value - Array value
     * @returns This compiler instance for chaining
     * @throws {TypeError} If key is not a string or value is not an array
     * @throws {Error} If setting the variable fails
     *
     * @example
     * ```typescript
     * compiler.setArray('items', ['Apple', 'Banana', 'Cherry']);
     * compiler.setArray('numbers', [1, 2, 3, 4, 5]);
     * ```
     */
    setArray(key: string, value: any[]): this;

    /**
     * Set an object variable
     * @param key - Variable name
     * @param value - Plain object (not array)
     * @returns This compiler instance for chaining
     * @throws {TypeError} If key is not a string or value is not a plain object
     * @throws {Error} If setting the variable fails
     *
     * @example
     * ```typescript
     * compiler.setObject('user', {
     *     name: 'John',
     *     age: 30,
     *     email: 'john@example.com'
     * });
     * ```
     */
    setObject(key: string, value: Record<string, any>): this;

    /**
     * Set multiple variables from an object
     * @param variables - Object with key-value pairs
     * @returns This compiler instance for chaining
     *
     * @example
     * ```typescript
     * compiler.setVariables({
     *     title: 'My Page',
     *     count: 10,
     *     active: true,
     *     items: ['a', 'b']
     * });
     * ```
     */
    setVariables(variables: PugVariables): this;

    /**
     * Compile a Pug template to HTML
     * @param template - Pug template string
     * @returns Compiled HTML string
     * @throws {TypeError} If template is not a string
     * @throws {ZigPugCompilationError} If compilation fails with structured error info
     * @throws {Error} If compilation fails for other reasons
     *
     * @example
     * ```typescript
     * try {
     *     const html = compiler.compile('h1= title');
     *     console.log(html);
     * } catch (error) {
     *     if ((error as ZigPugCompilationError).compilationErrors) {
     *         const { errors } = (error as ZigPugCompilationError).compilationErrors!;
     *         errors.forEach(err => {
     *             console.error(`Line ${err.line}: ${err.message}`);
     *         });
     *     }
     * }
     * ```
     */
    compile(template: string): string;

    /**
     * Compile a template with variables in one call
     * @param template - Pug template string
     * @param variables - Variables to set before compiling
     * @returns Compiled HTML string
     * @throws {TypeError} If template is not a string
     * @throws {ZigPugCompilationError} If compilation fails
     *
     * @example
     * ```typescript
     * const html = compiler.render('h1= title', { title: 'Hello' });
     * ```
     */
    render(template: string, variables?: PugVariables): string;
}

/**
 * Compile a Pug template string to HTML (simple API)
 * @param template - Pug template string
 * @param variables - Optional variables for interpolation
 * @returns Compiled HTML string
 * @throws {ZigPugCompilationError} If compilation fails
 *
 * @example
 * ```typescript
 * const html = compile('p Hello #{name}!', { name: 'World' });
 * console.log(html); // <p>Hello World!</p>
 * ```
 */
export function compile(template: string, variables?: PugVariables): string;

/**
 * Compile a Pug template from a file
 * @param filename - Path to .pug file
 * @param variables - Optional variables for interpolation
 * @returns Compiled HTML string
 * @throws {Error} If file cannot be read
 * @throws {ZigPugCompilationError} If compilation fails
 *
 * @example
 * ```typescript
 * const html = compileFile('./views/index.pug', {
 *     title: 'Home',
 *     user: { name: 'John' }
 * });
 * ```
 */
export function compileFile(filename: string, variables?: PugVariables): string;

/**
 * Get zig-pug version string
 * @returns Version string (e.g., "0.4.0")
 *
 * @example
 * ```typescript
 * console.log(`Using zig-pug v${version()}`);
 * ```
 */
export function version(): string;

// Default export
export default {
    PugCompiler,
    compile,
    compileFile,
    version
};
