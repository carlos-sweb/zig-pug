# Publishing zig-pug to npm

This guide explains how to publish zig-pug to npm.

## Prerequisites

1. **npm account** - Create one at https://www.npmjs.com/signup
2. **npm login** - Authenticate with npm:
   ```bash
   npm login
   ```
3. **Git tag** - Version should match package.json version

## Pre-flight Checklist

Before publishing, ensure:

- [ ] All tests pass: `npm test`
- [ ] Version is bumped in `package.json`
- [ ] CHANGELOG is updated (if exists)
- [ ] README.md is up to date
- [ ] LICENSE file exists
- [ ] GitHub URLs are updated (replace `yourusername`)

## Publishing Steps

### 1. Test the Package Locally

Create a test package to verify what will be published:

```bash
cd nodejs
npm pack
```

This creates `zig-pug-<version>.tgz`. Inspect its contents:

```bash
tar -tzf zig-pug-0.2.0.tgz
```

**Verify that it includes:**
- ✅ `package/index.js`
- ✅ `package/binding.c`
- ✅ `package/binding.gyp`
- ✅ `package/common.gypi`
- ✅ `package/README.md`
- ✅ `package/LICENSE`
- ✅ `package/include/` directory
- ✅ `package/vendor/mujs/` directory

**Should NOT include:**
- ❌ `build/` directory
- ❌ `node_modules/`
- ❌ `.git/`
- ❌ Test files
- ❌ Examples

### 2. Test Installation Locally

Install the package locally in a test project:

```bash
# Create test directory
mkdir /tmp/test-zigpug
cd /tmp/test-zigpug
npm init -y

# Install from local tarball
npm install /root/zig-pug/nodejs/zig-pug-0.2.0.tgz

# Test it
node -e "const zigpug = require('zig-pug'); console.log(zigpug.version())"
```

**Expected output:** `0.2.0`

### 3. Test Compilation on Clean System

The addon must compile on a fresh install. Test with:

```bash
# Remove node_modules
rm -rf node_modules

# Fresh install (this triggers node-gyp rebuild)
npm install

# Verify it works
node -e "const zigpug = require('zig-pug'); console.log(zigpug.version())"
```

### 4. Update Version

Use npm version to bump version and create git tag:

```bash
cd nodejs

# Bump patch version (0.2.0 -> 0.2.1)
npm version patch

# Or bump minor version (0.2.0 -> 0.3.0)
npm version minor

# Or bump major version (0.2.0 -> 1.0.0)
npm version major

# Or set specific version
npm version 0.2.1
```

This will:
1. Update `package.json` version
2. Create a git commit
3. Create a git tag

### 5. Publish to npm

**Dry run first** (see what would be published):

```bash
npm publish --dry-run
```

Review the output carefully. If everything looks good:

```bash
npm publish
```

**For first-time publish**, you may need to add access:

```bash
npm publish --access public
```

### 6. Verify Publication

Check that the package is available:

```bash
# View on npm
npm view zig-pug

# Install from npm in a fresh directory
mkdir /tmp/test-npm-install
cd /tmp/test-npm-install
npm init -y
npm install zig-pug

# Test
node -e "const zigpug = require('zig-pug'); console.log(zigpug.version())"
```

### 7. Push Git Tags

Push the version tag to GitHub:

```bash
git push
git push --tags
```

### 8. Create GitHub Release

1. Go to https://github.com/yourusername/zig-pug/releases
2. Click "Create a new release"
3. Select the version tag (e.g., `v0.2.1`)
4. Add release notes
5. Publish release

## Version Guidelines

Follow [Semantic Versioning](https://semver.org/):

- **Patch** (0.2.0 -> 0.2.1): Bug fixes, no API changes
- **Minor** (0.2.0 -> 0.3.0): New features, backward compatible
- **Major** (0.2.0 -> 1.0.0): Breaking changes

## npm Scripts Reference

- `npm run build` - Build the addon manually
- `npm run clean` - Clean build artifacts
- `npm test` - Run tests
- `npm pack` - Create tarball for testing
- `npm publish` - Publish to npm

## Troubleshooting

### "You do not have permission to publish"

**Solution:** Make sure you're logged in and the package name is available:

```bash
npm login
npm whoami
```

### "package.json version already exists"

**Solution:** Bump the version:

```bash
npm version patch
```

### Files missing from package

**Solution:** Check `.npmignore` and `files` array in `package.json`:

```bash
npm pack
tar -tzf zig-pug-*.tgz
```

### Build fails on user's machine

**Solution:** Ensure all build dependencies are listed:
- Check that `binding.gyp` references are correct
- Verify `include/` and `vendor/` are in `files` array
- Test in a Docker container with clean environment

## Platform Testing

Before publishing, test on multiple platforms:

### Linux

```bash
docker run -it --rm -v $(pwd):/app node:18 bash
cd /app/nodejs
npm install
npm test
```

### macOS

```bash
npm install
npm test
```

### Windows

Use WSL or Windows with build tools:

```bash
npm install --global windows-build-tools
cd nodejs
npm install
npm test
```

## Automated Publishing (Future)

Consider using GitHub Actions for automated publishing:

```yaml
# .github/workflows/publish.yml
name: Publish to npm
on:
  release:
    types: [created]
jobs:
  publish:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - uses: actions/setup-node@v2
        with:
          node-version: 18
          registry-url: https://registry.npmjs.org/
      - run: cd nodejs && npm install
      - run: cd nodejs && npm test
      - run: cd nodejs && npm publish
        env:
          NODE_AUTH_TOKEN: ${{secrets.NPM_TOKEN}}
```

## Post-Publish Checklist

After publishing:

- [ ] Verify package on https://www.npmjs.com/package/zig-pug
- [ ] Test installation: `npm install zig-pug`
- [ ] Update README badges if needed
- [ ] Announce on social media / forums
- [ ] Close related issues on GitHub

## Support

If you encounter issues during publishing:

1. Check npm documentation: https://docs.npmjs.com/
2. Check node-gyp documentation: https://github.com/nodejs/node-gyp
3. Open an issue: https://github.com/yourusername/zig-pug/issues

---

**Remember:** Once published, a version cannot be unpublished after 24 hours. Test thoroughly before publishing!
