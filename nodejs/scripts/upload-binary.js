#!/usr/bin/env node

/**
 * Upload precompiled binaries to GitHub Releases
 *
 * Usage:
 *   GITHUB_TOKEN=xxx node scripts/upload-binary.js
 *
 * Requirements:
 *   - GITHUB_TOKEN environment variable with repo access
 *   - Tag must exist in GitHub (e.g., v0.2.0)
 */

const { execSync } = require('child_process');
const fs = require('fs');
const path = require('path');

const REPO_OWNER = 'carlos-sweb';
const REPO_NAME = 'zig-pug';

// Read package.json for version
const pkg = require('../package.json');
const version = pkg.version;
const tag = `v${version}`;

// Get binary configuration
const binary = pkg.binary;

// Determine current platform
const platform = process.platform;
const arch = process.arch;
const node_abi = process.versions.modules; // Node ABI version

// Generate binary filename
const binaryName = binary.package_name
  .replace('{module_name}', binary.module_name)
  .replace('{version}', version)
  .replace('{node_abi}', `node-v${node_abi}`)
  .replace('{platform}', platform)
  .replace('{arch}', arch);

console.log(`📦 Uploading binary for zig-pug v${version}`);
console.log(`   Platform: ${platform}-${arch}`);
console.log(`   Node ABI: ${node_abi}`);
console.log(`   Binary: ${binaryName}`);
console.log('');

// Check for GITHUB_TOKEN
if (!process.env.GITHUB_TOKEN) {
  console.error('❌ Error: GITHUB_TOKEN environment variable not set');
  console.error('');
  console.error('Generate a token at: https://github.com/settings/tokens');
  console.error('Required scopes: repo');
  console.error('');
  console.error('Usage: GITHUB_TOKEN=xxx node scripts/upload-binary.js');
  process.exit(1);
}

// Check if tag exists
console.log(`🔍 Checking if tag ${tag} exists...`);
try {
  execSync(`git rev-parse ${tag}`, { stdio: 'ignore' });
  console.log(`   ✅ Tag ${tag} found\n`);
} catch (error) {
  console.error(`❌ Tag ${tag} not found`);
  console.error(`   Create it with: git tag ${tag} && git push origin ${tag}`);
  process.exit(1);
}

// Package the binary
console.log('📦 Packaging binary...');
try {
  execSync('npm run package', { stdio: 'inherit' });
  console.log('   ✅ Binary packaged\n');
} catch (error) {
  console.error('❌ Failed to package binary');
  process.exit(1);
}

// Find the tarball
const buildDir = path.join(__dirname, '..', 'build', 'stage', version);
const tarballPath = path.join(buildDir, binaryName);

if (!fs.existsSync(tarballPath)) {
  console.error(`❌ Tarball not found: ${tarballPath}`);
  process.exit(1);
}

console.log(`📤 Uploading to GitHub Releases...`);
console.log(`   Repository: ${REPO_OWNER}/${REPO_NAME}`);
console.log(`   Release: ${tag}`);
console.log(`   File: ${binaryName}`);
console.log('');

// Use GitHub CLI (gh) to upload
try {
  // Check if release exists, create if not
  try {
    execSync(`gh release view ${tag} --repo ${REPO_OWNER}/${REPO_NAME}`, { stdio: 'ignore' });
    console.log(`   ✅ Release ${tag} exists`);
  } catch {
    console.log(`   Creating release ${tag}...`);
    execSync(
      `gh release create ${tag} --repo ${REPO_OWNER}/${REPO_NAME} --title "Release ${tag}" --notes "Release ${tag}"`,
      { stdio: 'inherit' }
    );
  }

  // Upload the binary
  execSync(
    `gh release upload ${tag} "${tarballPath}" --repo ${REPO_OWNER}/${REPO_NAME} --clobber`,
    { stdio: 'inherit' }
  );

  console.log('');
  console.log('✨ Upload successful!');
  console.log('');
  console.log(`📋 Binary URL:`);
  console.log(`   https://github.com/${REPO_OWNER}/${REPO_NAME}/releases/download/${tag}/${binaryName}`);
  console.log('');
} catch (error) {
  console.error('❌ Upload failed');
  console.error('');
  console.error('Make sure you have GitHub CLI installed:');
  console.error('  https://cli.github.com/');
  console.error('');
  console.error('Or use the GitHub web interface to upload manually.');
  process.exit(1);
}
