/**
 * zig-pug - Pug template engine for Node.js (ES Module version)
 * Powered by Zig and mujs
 */

import { createRequire } from 'module';
import { fileURLToPath } from 'url';
import { dirname, join } from 'path';
import { readFileSync, existsSync } from 'fs';
import os from 'os';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);
const require = createRequire(import.meta.url);

// Detect platform and architecture
const platform = os.platform(); // 'linux', 'darwin', 'win32'
const arch = os.arch(); // 'x64', 'arm64'
const platformKey = `${platform}-${arch}`;

// Try to load prebuilt binary first
const prebuiltPath = join(__dirname, 'prebuilt-binaries', platformKey, 'zigpug.node');
const builtPath = join(__dirname, 'build', 'Release', 'zigpug.node');

let binding;

if (existsSync(prebuiltPath)) {
    // Use prebuilt binary
    binding = require(prebuiltPath);
} else if (existsSync(builtPath)) {
    // Use locally built binary
    binding = require(builtPath);
} else {
    console.error('');
    console.error('zig-pug native addon not found!');
    console.error('');
    console.error(`Platform: ${platformKey}`);
    console.error('');
    console.error('The native addon needs to be built. Please run:');
    console.error('');
    console.error('  cd node_modules/zig-pug && npm run install');
    console.error('');
    console.error('Or if using Bun:');
    console.error('');
    console.error('  cd node_modules/zig-pug && bun run install');
    console.error('');
    throw new Error('zig-pug native addon not found. See instructions above.');
}

/**
 * PugCompiler class - High-level API for compiling Pug templates
 */
export class PugCompiler {
    constructor() {
        this.context = binding.createContext();
        if (!this.context) {
            throw new Error('Failed to create zig-pug context');
        }
    }

    /**
     * Set a string variable in the template context
     * @param {string} key - Variable name
     * @param {string} value - String value
     * @returns {PugCompiler} - Returns this for chaining
     */
    setString(key, value) {
        if (typeof key !== 'string') {
            throw new TypeError('Key must be a string');
        }
        if (typeof value !== 'string') {
            throw new TypeError('Value must be a string');
        }

        const success = binding.setString(this.context, key, value);
        if (!success) {
            throw new Error(`Failed to set string variable: ${key}`);
        }
        return this;
    }

    /**
     * Set a number variable in the template context
     * @param {string} key - Variable name
     * @param {number} value - Number value
     * @returns {PugCompiler} - Returns this for chaining
     */
    setNumber(key, value) {
        if (typeof key !== 'string') {
            throw new TypeError('Key must be a string');
        }
        if (typeof value !== 'number') {
            throw new TypeError('Value must be a number');
        }

        const success = binding.setNumber(this.context, key, Math.floor(value));
        if (!success) {
            throw new Error(`Failed to set number variable: ${key}`);
        }
        return this;
    }

    /**
     * Set a boolean variable in the template context
     * @param {string} key - Variable name
     * @param {boolean} value - Boolean value
     * @returns {PugCompiler} - Returns this for chaining
     */
    setBool(key, value) {
        if (typeof key !== 'string') {
            throw new TypeError('Key must be a string');
        }
        if (typeof value !== 'boolean') {
            throw new TypeError('Value must be a boolean');
        }

        const success = binding.setBool(this.context, key, value);
        if (!success) {
            throw new Error(`Failed to set boolean variable: ${key}`);
        }
        return this;
    }

    /**
     * Set an array variable in the template context
     * @param {string} key - Variable name
     * @param {Array} value - Array value
     * @returns {PugCompiler} - Returns this for chaining
     */
    setArray(key, value) {
        if (typeof key !== 'string') {
            throw new TypeError('Key must be a string');
        }
        if (!Array.isArray(value)) {
            throw new TypeError('Value must be an array');
        }

        const success = binding.setArray(this.context, key, value);
        if (!success) {
            throw new Error(`Failed to set array variable: ${key}`);
        }
        return this;
    }

    /**
     * Set an object variable in the template context
     * @param {string} key - Variable name
     * @param {Object} value - Object value (plain object, not array)
     * @returns {PugCompiler} - Returns this for chaining
     */
    setObject(key, value) {
        if (typeof key !== 'string') {
            throw new TypeError('Key must be a string');
        }
        if (typeof value !== 'object' || value === null || Array.isArray(value)) {
            throw new TypeError('Value must be a plain object');
        }

        const success = binding.setObject(this.context, key, value);
        if (!success) {
            throw new Error(`Failed to set object variable: ${key}`);
        }
        return this;
    }

    /**
     * Set a variable (automatically detects type)
     * @param {string} key - Variable name
     * @param {string|number|boolean|Array|Object} value - Value of any supported type
     * @returns {PugCompiler} - Returns this for chaining
     */
    set(key, value) {
        if (Array.isArray(value)) {
            return this.setArray(key, value);
        } else if (typeof value === 'object' && value !== null) {
            return this.setObject(key, value);
        } else if (typeof value === 'string') {
            return this.setString(key, value);
        } else if (typeof value === 'number') {
            return this.setNumber(key, value);
        } else if (typeof value === 'boolean') {
            return this.setBool(key, value);
        } else {
            throw new TypeError(`Unsupported value type for key "${key}": ${typeof value}`);
        }
    }

    /**
     * Set multiple variables from an object
     * @param {Object} variables - Object with key-value pairs
     * @returns {PugCompiler} - Returns this for chaining
     */
    setVariables(variables) {
        if (typeof variables !== 'object' || variables === null) {
            throw new TypeError('Variables must be an object');
        }

        for (const [key, value] of Object.entries(variables)) {
            this.set(key, value);
        }

        return this;
    }

    /**
     * Compile a Pug template to HTML
     * @param {string} template - Pug template string
     * @returns {string} - Compiled HTML
     */
    compile(template) {
        if (typeof template !== 'string') {
            throw new TypeError('Template must be a string');
        }

        const html = binding.compile(this.context, template);
        if (!html) {
            throw new Error('Failed to compile template');
        }

        return html;
    }

    /**
     * Compile a template with variables in one call
     * @param {string} template - Pug template string
     * @param {Object} variables - Variables to set before compiling
     * @returns {string} - Compiled HTML
     */
    render(template, variables = {}) {
        this.setVariables(variables);
        return this.compile(template);
    }
}

/**
 * Convenience function to compile a template with variables
 * @param {string} template - Pug template string
 * @param {Object} variables - Variables for the template
 * @returns {string} - Compiled HTML
 */
export function compile(template, variables = {}) {
    const compiler = new PugCompiler();
    return compiler.render(template, variables);
}

/**
 * Convenience function to compile a template from a file
 * @param {string} filename - Path to the Pug template file
 * @param {Object} variables - Variables for the template
 * @returns {string} - Compiled HTML
 */
export function compileFile(filename, variables = {}) {
    const template = readFileSync(filename, 'utf8');
    return compile(template, variables);
}

/**
 * Get the zig-pug version
 * @returns {string} - Version string
 */
export function version() {
    return binding.version();
}

// Default export for compatibility
export default {
    PugCompiler,
    compile,
    compileFile,
    version
};
