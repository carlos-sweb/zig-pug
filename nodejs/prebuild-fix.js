#!/usr/bin/env node
// Fix for node-gyp build issues in Termux/Android
// Creates necessary directories and files that make expects to exist

const fs = require('fs');
const path = require('path');

const depsDir = path.join(__dirname, 'build', 'Release', '.deps', 'Release', 'obj.target', 'zigpug');
const depsFile = path.join(depsDir, 'binding.o.d.raw');

try {
  // Create directory structure
  fs.mkdirSync(depsDir, { recursive: true });
  
  // Create empty file if it doesn't exist
  if (!fs.existsSync(depsFile)) {
    fs.writeFileSync(depsFile, '');
  }
  
  console.log('✓ Pre-build fix applied for Termux/Android compatibility');
} catch (err) {
  // Ignore errors - this is just a workaround
  console.log('⚠ Pre-build fix skipped:', err.message);
}
