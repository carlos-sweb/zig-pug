/**
 * zig-pug - Pug template engine for Node.js
 * Powered by Zig and mujs
 */

const binary = require('@mapbox/node-pre-gyp');
const path = require('path');
const fs = require('fs');

// Try to find precompiled binary first, fallback to development build
let binding;
try {
    const binding_path = binary.find(path.resolve(path.join(__dirname, './package.json')));
    binding = require(binding_path);
} catch (err) {
    // Fallback to development build location
    const dev_path = path.join(__dirname, 'build', 'Release', 'zigpug.node');
    if (fs.existsSync(dev_path)) {
        binding = require(dev_path);
    } else {
        throw new Error(
            'zig-pug native addon not found. ' +
            'Please build it with: cd .. && zig build node'
        );
    }
}

/**
 * PugCompiler class - High-level API for compiling Pug templates
 */
class PugCompiler {
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
     * Set a variable (automatically detects type)
     * @param {string} key - Variable name
     * @param {string|number|boolean} value - Value of any supported type
     * @returns {PugCompiler} - Returns this for chaining
     */
    set(key, value) {
        if (typeof value === 'string') {
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
function compile(template, variables = {}) {
    const compiler = new PugCompiler();
    return compiler.render(template, variables);
}

/**
 * Convenience function to compile a template from a file
 * @param {string} filename - Path to the Pug template file
 * @param {Object} variables - Variables for the template
 * @returns {string} - Compiled HTML
 */
function compileFile(filename, variables = {}) {
    const fs = require('fs');
    const template = fs.readFileSync(filename, 'utf8');
    return compile(template, variables);
}

/**
 * Get the zig-pug version
 * @returns {string} - Version string
 */
function version() {
    return binding.version();
}

module.exports = {
    PugCompiler,
    compile,
    compileFile,
    version
};
