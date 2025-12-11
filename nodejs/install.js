#!/usr/bin/env node
/**
 * Installation script for zig-pug
 * Builds the native addon if it doesn't exist
 */

const { execSync, spawnSync } = require('child_process');
const fs = require('fs');
const path = require('path');
const os = require('os');

// Detect platform
const platform = os.platform();
const arch = os.arch();
const platformKey = `${platform}-${arch}`;

// Check if prebuilt binary exists
const prebuiltPath = path.join(__dirname, 'prebuilt-binaries', platformKey, 'zigpug.node');
if (fs.existsSync(prebuiltPath)) {
    console.log(`✓ zig-pug: Using prebuilt binary for ${platformKey}`);
    process.exit(0);
}

// Check if addon already built
const addonPath = path.join(__dirname, 'build', 'Release', 'zigpug.node');
if (fs.existsSync(addonPath)) {
    console.log('✓ zig-pug native addon already built');
    process.exit(0);
}

console.log('Building zig-pug native addon...');

// Try to find node-gyp (local or global)
let nodeGyp = 'node-gyp';

// Check for local node-gyp first
const localNodeGyp = path.join(__dirname, 'node_modules', '.bin', 'node-gyp');
if (fs.existsSync(localNodeGyp)) {
    nodeGyp = localNodeGyp;
}

try {
    // Run node-gyp rebuild
    const result = spawnSync(nodeGyp, ['rebuild'], {
        cwd: __dirname,
        stdio: 'inherit',
        shell: true
    });

    if (result.status !== 0) {
        throw new Error(`node-gyp exited with code ${result.status}`);
    }

    console.log('✓ zig-pug native addon built successfully');
} catch (error) {
    console.error('✗ Failed to build zig-pug native addon');
    console.error('');
    console.error('This package requires node-gyp and build tools to be installed.');
    console.error('Please install node-gyp:');
    console.error('');
    console.error('  npm install -g node-gyp');
    console.error('');
    console.error('Or install it locally in this package:');
    console.error('');
    console.error('  cd node_modules/zig-pug && npm install');
    console.error('');
    console.error('For more information: https://github.com/nodejs/node-gyp#installation');
    console.error('');
    process.exit(1);
}
