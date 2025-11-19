.PHONY: help build run test clean cross install uninstall binaries docs

# Default target
help:
	@echo "zpug - Makefile"
	@echo ""
	@echo "Available targets:"
	@echo "  make build          - Build the CLI for current platform"
	@echo "  make run            - Build and run the CLI"
	@echo "  make test           - Run all tests"
	@echo "  make clean          - Clean build artifacts"
	@echo "  make cross          - Build for all platforms"
	@echo "  make binaries       - Build and package release binaries"
	@echo "  make install        - Install zpug to /usr/local/bin"
	@echo "  make uninstall      - Remove zpug from /usr/local/bin"
	@echo "  make docs           - Generate documentation"
	@echo ""
	@echo "Cross-compilation targets:"
	@echo "  make linux-x86_64   - Build for Linux x86_64"
	@echo "  make linux-arm64    - Build for Linux ARM64"
	@echo "  make windows        - Build for Windows x86_64"
	@echo "  make macos-intel    - Build for macOS Intel"
	@echo "  make macos-arm      - Build for macOS Apple Silicon"
	@echo ""

# Build for current platform
build:
	@echo "Building zig-pug..."
	zig build

# Build and run
run:
	@echo "Building and running zig-pug..."
	zig build run

# Run tests
test:
	@echo "Running tests..."
	zig build test

# Clean build artifacts
clean:
	@echo "Cleaning build artifacts..."
	rm -rf zig-out/
	rm -rf .zig-cache/

# Cross-compile for all platforms
cross:
	@echo "Building for all platforms..."
	zig build cross-all

# Individual platform targets
linux-x86_64:
	@echo "Building for Linux x86_64..."
	zig build cross-linux-x86_64

linux-arm64:
	@echo "Building for Linux ARM64..."
	zig build cross-linux-aarch64

windows:
	@echo "Building for Windows x86_64..."
	zig build cross-windows-x86_64

macos-intel:
	@echo "Building for macOS Intel..."
	zig build cross-macos-x86_64

macos-arm:
	@echo "Building for macOS Apple Silicon..."
	zig build cross-macos-aarch64

# Build and package release binaries
binaries:
	@echo "Building release binaries..."
	./build-binaries.sh

# Install to system
install: build
	@echo "Installing zpug to /usr/local/bin..."
	@cp zig-out/bin/zpug /usr/local/bin/
	@echo "Installed successfully"
	@echo "Run 'zpug --help' to get started"

# Uninstall from system
uninstall:
	@echo "Removing zpug from /usr/local/bin..."
	@rm -f /usr/local/bin/zpug
	@echo "Uninstalled successfully"

# Generate documentation
docs:
	@echo "Documentation is available in:"
	@echo "  - README.md"
	@echo "  - docs/GETTING-STARTED.md"
	@echo "  - docs/NODEJS-INTEGRATION.md"
	@echo "  - docs/CLI.md"
