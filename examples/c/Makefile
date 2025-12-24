# Makefile for zig-pug C examples
#
# Usage:
#   make              # Build all examples
#   make 01-basic     # Build specific example
#   make run-basic    # Build and run basic example
#   make clean        # Clean build artifacts

CC = gcc
CFLAGS = -Wall -Wextra -std=c99 -I../../include
LDFLAGS = -L../../libs/$(PLATFORM) -lzig-pug -lm

# Detect platform
UNAME_S := $(shell uname -s)
UNAME_M := $(shell uname -m)

ifeq ($(UNAME_S),Linux)
    ifeq ($(UNAME_M),x86_64)
        PLATFORM = linux-x64
    else ifeq ($(UNAME_M),aarch64)
        PLATFORM = linux-arm64
    endif
else ifeq ($(UNAME_S),Darwin)
    ifeq ($(UNAME_M),arm64)
        PLATFORM = darwin-arm64
    else
        PLATFORM = darwin-x64
    endif
endif

# Source files
SOURCES = $(wildcard *.c)
TARGETS = $(SOURCES:.c=)

# Default target
all: $(TARGETS)
	@echo "Built all examples for platform: $(PLATFORM)"
	@echo "Run examples with: ./01-basic, ./02-variables, etc."

# Build individual examples
%: %.c
	$(CC) $(CFLAGS) $< -o $@ $(LDFLAGS)

# Convenience targets
01-basic: 01-basic.c
02-variables: 02-variables.c
03-arrays-objects: 03-arrays-objects.c
04-error-handling: 04-error-handling.c
05-file-template: 05-file-template.c

# Run targets
run-basic: 01-basic
	@echo "=== Running 01-basic ==="
	./01-basic

run-variables: 02-variables
	@echo "=== Running 02-variables ==="
	./02-variables

run-arrays: 03-arrays-objects
	@echo "=== Running 03-arrays-objects ==="
	./03-arrays-objects

run-errors: 04-error-handling
	@echo "=== Running 04-error-handling ==="
	./04-error-handling

run-file: 05-file-template
	@echo "=== Running 05-file-template ==="
	@echo "p Hello #{name}" > test-template.pug
	./05-file-template test-template.pug
	@rm -f test-template.pug

# Run all examples
run-all: all
	@echo "\n=== Running all examples ===\n"
	@$(MAKE) run-basic
	@echo ""
	@$(MAKE) run-variables
	@echo ""
	@$(MAKE) run-arrays
	@echo ""
	@$(MAKE) run-errors
	@echo ""
	@$(MAKE) run-file

# Clean
clean:
	rm -f $(TARGETS)
	rm -f test-template.pug

.PHONY: all clean run-basic run-variables run-arrays run-errors run-file run-all
