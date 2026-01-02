# Termux/Android Support

Guide for using zig-pug on Android via Termux.

## Table of Contents

- [Overview](#overview)
- [Installation](#installation)
- [Building from Source](#building-from-source)
- [Usage](#usage)
- [Limitations](#limitations)
- [Troubleshooting](#troubleshooting)
- [Examples](#examples)

## Overview

zig-pug provides **CLI support** for Termux/Android. The CLI binary works perfectly, but the Node.js addon has limitations due to Android's security model.

### What Works

- ✅ **CLI binary** - Full functionality
- ✅ **All Pug features** - Tags, attributes, interpolation, conditionals, loops, mixins
- ✅ **JavaScript expressions** - Powered by mujs
- ✅ **File compilation** - Read .zpug files, output HTML
- ✅ **Variable passing** - --var, --array, --vars flags
- ✅ **Output formatting** - --pretty, --format, --minify

### What Doesn't Work

- ❌ **Node.js addon** - Cannot be loaded due to Android namespace restrictions
- ❌ **npm install zig-pug** - Addon compiles but won't load at runtime

**Why?** Android's security model prevents loading native libraries in certain contexts. While the addon compiles successfully, dlopen() fails with namespace errors when Node.js attempts to load it.

**Solution:** Use the standalone CLI binary instead.

## Installation

### Prerequisites

Install required packages in Termux:

```bash
# Update package list
pkg update

# Install Zig compiler
pkg install zig

# Install Git
pkg install git

# Optional: Install clang for better build performance
pkg install clang
```

### Verify Zig Installation

```bash
zig version
# Should show: 0.15.2 or compatible
```

## Building from Source

### Step 1: Clone Repository

```bash
# Clone zig-pug
git clone https://github.com/carlos-sweb/zig-pug
cd zig-pug
```

### Step 2: Build

```bash
# Build the CLI
zig build

# Verify binary exists
ls -lh zig-out/bin/zpug
```

Build time: ~30-60 seconds on modern Android devices.

### Step 3: Install (Optional)

**Option A: Add to PATH**
```bash
# Add to ~/.bashrc
echo 'export PATH="$HOME/zig-pug/zig-out/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc

# Test
zpug --version
```

**Option B: Create symlink**
```bash
# Create bin directory
mkdir -p ~/.local/bin

# Symlink binary
ln -s ~/zig-pug/zig-out/bin/zpug ~/.local/bin/zpug

# Add to PATH (if not already)
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc

# Test
zpug --version
```

**Option C: Use full path**
```bash
# No installation needed, use full path
~/zig-pug/zig-out/bin/zpug template.zpug
```

## Usage

### Basic Compilation

```bash
# Compile template to stdout
zpug template.zpug

# Compile with output file
zpug template.zpug -o output.html

# Pretty-print with indentation
zpug -F template.zpug -o output.html
```

### With Variables

**Simple variables:**
```bash
zpug template.zpug --var name=Alice --var age=25
```

**Arrays:**
```bash
zpug template.zpug --array items=apple,banana,orange
```

**JSON file:**
```bash
zpug template.zpug --vars data.json
```

### Example Session

```bash
# Create a template
cat > hello.zpug << 'EOF'
doctype html
html(lang="en")
  head
    title Hello #{name}
  body
    h1 Welcome to Termux!
    p Your name is #{name}
    p Your age is #{age}
EOF

# Compile with variables
zpug hello.zpug --var name=Alice --var age=30 -o hello.html

# View result
cat hello.html
```

Output:
```html
<!DOCTYPE html><html lang="en"><head><title>Hello Alice</title></head><body><h1>Welcome to Termux!</h1><p>Your name is Alice</p><p>Your age is 30</p></body></html>
```

### Formatted Output

```bash
# Create formatted HTML for readability
zpug hello.zpug --var name=Alice --var age=30 -F -o hello-formatted.html

# View formatted result
cat hello-formatted.html
```

Output:
```html
<!DOCTYPE html>
<html lang="en">
  <head>
    <title>Hello Alice</title>
  </head>
  <body>
    <h1>Welcome to Termux!</h1>
    <p>Your name is Alice</p>
    <p>Your age is 30</p>
  </body>
</html>
```

## Limitations

### Node.js Addon

**Problem:** The Node.js addon compiles successfully but cannot be loaded at runtime.

**Error:**
```
Error: dlopen failed: cannot locate symbol "zigpug_compile"
```

**Cause:** Android's linker namespace restrictions prevent loading certain native libraries.

**Workaround:** Use the CLI binary instead of the Node.js API.

**Example workflow:**
```bash
# Instead of Node.js:
# const html = zigpug.compile(template, data);

# Use CLI:
echo "$template" | zpug --stdin --vars data.json
```

### File Permissions

Termux runs in app-specific storage with limited permissions.

**Solutions:**

1. **Work in Termux home:**
   ```bash
   cd ~/zig-pug
   zpug template.zpug
   ```

2. **Access shared storage:**
   ```bash
   # Grant storage permission
   termux-setup-storage

   # Access downloads
   cd ~/storage/downloads
   zpug template.zpug
   ```

3. **Use absolute paths:**
   ```bash
   zpug ~/storage/downloads/template.zpug -o ~/storage/downloads/output.html
   ```

### Resource Constraints

Mobile devices have limited resources compared to desktops.

**Tips:**

1. **Optimize templates:**
   - Use minification (`-m`) for production
   - Avoid deeply nested structures
   - Limit JavaScript expression complexity

2. **Process files in batches:**
   ```bash
   # Process one at a time
   for file in templates/*.zpug; do
     zpug "$file" -o "output/$(basename "$file" .zpug).html"
   done
   ```

3. **Monitor memory:**
   ```bash
   # Check available memory
   free -h
   ```

## Troubleshooting

### Build Failures

**Error: "zig: command not found"**

**Solution:** Install Zig:
```bash
pkg install zig
```

**Error: "out of memory"**

**Solution:** Close other apps and try again. Consider using a device with more RAM (4GB+ recommended).

**Error: "permission denied"**

**Solution:** Ensure you're in your home directory or a writable location:
```bash
cd ~
git clone https://github.com/carlos-sweb/zig-pug
```

### Runtime Issues

**Error: "zpug: command not found"**

**Solution:** Use full path or add to PATH:
```bash
# Full path
~/zig-pug/zig-out/bin/zpug template.zpug

# Or add to PATH
export PATH="$HOME/zig-pug/zig-out/bin:$PATH"
```

**Error: "No such file or directory"**

**Solution:** Check file path and permissions:
```bash
# List files
ls -l template.zpug

# Check current directory
pwd

# Use absolute path
zpug ~/path/to/template.zpug
```

**Error: "Invalid UTF-8 sequence"**

**Solution:** Ensure file is UTF-8 encoded:
```bash
# Check file encoding
file template.zpug

# Convert if needed
iconv -f ISO-8859-1 -t UTF-8 template.zpug -o template-utf8.zpug
```

### Node.js Addon Issues

**Error: "dlopen failed: cannot locate symbol"**

**Explanation:** This is expected on Android. The addon cannot be loaded due to platform limitations.

**Solution:** Use the CLI binary instead.

## Examples

### Static Website Generator

```bash
#!/data/data/com.termux/files/usr/bin/bash

# Site generator script
TEMPLATES_DIR="templates"
OUTPUT_DIR="public"
DATA_FILE="data.json"

mkdir -p "$OUTPUT_DIR"

for template in "$TEMPLATES_DIR"/*.zpug; do
  filename=$(basename "$template" .zpug)
  zpug "$template" --vars "$DATA_FILE" -F -o "$OUTPUT_DIR/$filename.html"
  echo "Generated: $OUTPUT_DIR/$filename.html"
done

echo "Site generation complete!"
```

### Blog Post Compiler

```bash
#!/data/data/com.termux/files/usr/bin/bash

# Compile blog posts
POSTS_DIR="posts"
OUTPUT_DIR="public/posts"
LAYOUT="layouts/post.zpug"

mkdir -p "$OUTPUT_DIR"

for post in "$POSTS_DIR"/*.json; do
  filename=$(basename "$post" .json)
  zpug "$LAYOUT" --vars "$post" -F -o "$OUTPUT_DIR/$filename.html"
  echo "Published: $filename"
done
```

### Email Template Generator

```bash
#!/data/data/com.termux/files/usr/bin/bash

# Generate email from template
TEMPLATE="email-templates/welcome.zpug"

zpug "$TEMPLATE" \
  --var userName="Alice" \
  --var userEmail="alice@example.com" \
  --var confirmUrl="https://example.com/confirm/abc123" \
  -m -o email-output.html

echo "Email HTML generated: email-output.html"
```

### Termux Widget Integration

Create a widget to compile templates:

**File: ~/.shortcuts/compile-template.sh**
```bash
#!/data/data/com.termux/files/usr/bin/bash

cd ~/projects/website
zpug index.zpug --vars data.json -F -o index.html
termux-notification -t "Build Complete" -c "Website compiled successfully"
```

Make executable:
```bash
chmod +x ~/.shortcuts/compile-template.sh
```

Now you can trigger compilation from Termux widget!

## Performance

### Benchmark on Android

**Device:** Typical mid-range Android phone (2023)
- CPU: Snapdragon 7-series or equivalent
- RAM: 6-8GB

**Results:**
```bash
# Simple template (10 lines)
time zpug simple.zpug -o output.html
# real: ~0.05s

# Complex template (100 lines, loops, conditionals)
time zpug complex.zpug --vars data.json -o output.html
# real: ~0.15s

# Batch processing (50 templates)
time for f in templates/*.zpug; do zpug "$f" -o "output/$(basename "$f" .zpug).html"; done
# real: ~3.5s
```

**Comparison to desktop:**
- ~60-70% of desktop performance
- Still very usable for development and static site generation

## Tips & Tricks

### 1. Use Aliases

```bash
# Add to ~/.bashrc
alias pug='zpug'
alias pugf='zpug -F'   # Formatted output
alias pugm='zpug -m'   # Minified output

# Usage
pug template.zpug -o output.html
pugf template.zpug -o pretty.html
```

### 2. Create Template Library

```bash
# Template library structure
~/pug-templates/
├── layouts/
│   ├── base.zpug
│   ├── blog.zpug
│   └── email.zpug
├── components/
│   ├── header.zpug
│   ├── footer.zpug
│   └── nav.zpug
└── snippets/
    ├── button.zpug
    └── card.zpug
```

### 3. Git Integration

```bash
# Version control your templates
cd ~/my-website
git init
git add templates/ data/ scripts/
git commit -m "Initial template setup"
```

### 4. Automated Builds

Use Termux:API to trigger builds:

```bash
# Install Termux:API
pkg install termux-api

# Monitor file changes (manual trigger)
#!/data/data/com.termux/files/usr/bin/bash
while true; do
  if [ "$(find templates -newer .last-build)" ]; then
    ./build.sh
    touch .last-build
    termux-notification -t "Build" -c "Templates recompiled"
  fi
  sleep 5
done
```

### 5. Serve Locally

```bash
# Install simple HTTP server
pkg install python

# Serve compiled site
cd public
python -m http.server 8000

# Visit in browser: localhost:8000
```

## See Also

- [GETTING-STARTED.md](GETTING-STARTED.md) - Getting started guide
- [en/CLI.md](en/CLI.md) - Complete CLI documentation
- [PUG-SYNTAX.md](PUG-SYNTAX.md) - Pug syntax reference
- [NODEJS-INTEGRATION.md](NODEJS-INTEGRATION.md) - Node.js integration (desktop only)

## Support

- **Issues:** [GitHub Issues](https://github.com/carlos-sweb/zig-pug/issues)
- **Termux:** [Termux Wiki](https://wiki.termux.com/)
- **Termux Community:** [Reddit r/termux](https://www.reddit.com/r/termux/)

Happy templating on Android! 📱🚀
