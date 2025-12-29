/**
 * zig-pug - Pug template engine for Node.js
 * Powered by Zig and mujs
 */

const fs = require('fs');
const path = require('path');
const os = require('os');

// Detect platform and architecture
const platform = os.platform(); // 'linux', 'darwin', 'win32'
const arch = os.arch(); // 'x64', 'arm64'
const platformKey = `${platform}-${arch}`;

// Try to load prebuilt binary first
const prebuiltPath = path.join(__dirname, 'prebuilt-binaries', platformKey, 'zigpug.node');
const builtPath = path.join(__dirname, 'build', 'Release', 'zigpug.node');

let binding;

if (fs.existsSync(prebuiltPath)) {
    // Use prebuilt binary
    binding = require(prebuiltPath);
} else if (fs.existsSync(builtPath)) {
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
 * @param {Object} options - Compiler options
 * @param {boolean} options.pretty - Enable pretty-print with indentation and comments (development mode)
 * @param {boolean} options.format - Enable pretty-print without comments (readable mode)
 * @param {boolean} options.minify - Enable HTML minification (production mode)
 * @param {boolean} options.includeComments - Include HTML comments (only with pretty/format)
 */
class PugCompiler {
    constructor(options = {}) {
        this.context = binding.createContext();
        if (!this.context) {
            throw new Error('Failed to create zig-pug context');
        }

        // Default options
        this.defaultOptions = {
            pretty: options.pretty || false,
            format: options.format || false,
            minify: options.minify || false,
            includeComments: options.includeComments !== undefined
                ? options.includeComments
                : (options.pretty || false)
        };
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
     * @param {Object} options - Compilation options (overrides constructor options)
     * @param {boolean} options.pretty - Enable pretty-print with indentation and comments
     * @param {boolean} options.format - Enable pretty-print without comments
     * @param {boolean} options.minify - Enable HTML minification
     * @param {boolean} options.includeComments - Include HTML comments
     * @returns {string} - Compiled HTML
     */
    compile(template, options = {}) {
        if (typeof template !== 'string') {
            throw new TypeError('Template must be a string');
        }

        let html = binding.compile(this.context, template);
        if (!html) {
            throw new Error('Failed to compile template');
        }

        // Merge default options with compile-time options
        const finalOptions = { ...this.defaultOptions, ...options };

        // Apply formatting based on options
        if (finalOptions.minify) {
            const minified = binding.minify(html);
            if (minified) {
                html = minified;
            }
        } else if (finalOptions.pretty || finalOptions.format) {
            const includeComments = finalOptions.includeComments !== undefined
                ? finalOptions.includeComments
                : finalOptions.pretty;
            const formatted = binding.prettyPrint(html, includeComments);
            if (formatted) {
                html = formatted;
            }
        }

        return html;
    }

    /**
     * Compile a template with variables in one call
     * @param {string} template - Pug template string
     * @param {Object} variables - Variables to set before compiling
     * @param {Object} options - Compilation options (overrides constructor options)
     * @returns {string} - Compiled HTML
     */
    render(template, variables = {}, options = {}) {
        this.setVariables(variables);
        return this.compile(template, options);
    }
}

/**
 * Convenience function to compile a template with variables
 * @param {string} template - Pug template string
 * @param {Object} variables - Variables for the template
 * @param {Object} options - Compilation options
 * @returns {string} - Compiled HTML
 */
function compile(template, variables = {}, options = {}) {
    const compiler = new PugCompiler(options);
    return compiler.render(template, variables);
}

/**
 * Convenience function to compile a template from a file
 * @param {string} filename - Path to the Pug template file
 * @param {Object} variables - Variables for the template
 * @param {Object} options - Compilation options
 * @returns {string} - Compiled HTML
 */
function compileFile(filename, variables = {}, options = {}) {
    const fs = require('fs');
    const template = fs.readFileSync(filename, 'utf8');
    return compile(template, variables, options);
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
