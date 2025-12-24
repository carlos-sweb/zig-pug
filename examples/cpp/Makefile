# Makefile for zig-pug C++ examples

CXX := g++
CXXFLAGS := -std=c++11 -Wall -Wextra -I../../include

# Detect architecture and use static library
ARCH := $(shell uname -m)
ifeq ($(ARCH),aarch64)
    LIB_PATH := ../../libs/linux-arm64/libzig-pug.a
else
    LIB_PATH := ../../libs/linux-x64/libzig-pug.a
endif

LDFLAGS := $(LIB_PATH) -lc -lm -ldl -lpthread

# C++17 version (optional, for string_view support)
CXX17FLAGS := -std=c++17 -Wall -Wextra -I../../include

EXAMPLES := 01-basic 02-arrays 03-objects 04-move-semantics 05-complex-data 06-stl-integration

.PHONY: all clean run-all

all: $(EXAMPLES)

%: %.cpp
	$(CXX) $(CXXFLAGS) $< -o $@ $(LDFLAGS)

# Special targets for different C++ standards
%-cpp17: %.cpp
	$(CXX) $(CXX17FLAGS) $< -o $@ $(LDFLAGS)

clean:
	rm -f $(EXAMPLES)
	rm -f *-cpp17

run-all: all
	@echo "=== Running all C++ examples ==="
	@for example in $(EXAMPLES); do \
		echo ""; \
		echo ">>> Running $$example..."; \
		./$$example || echo "Failed: $$example"; \
		echo ""; \
	done

# Individual run targets
run-%: %
	./$<

# Help
help:
	@echo "zig-pug C++ Examples Makefile"
	@echo ""
	@echo "Targets:"
	@echo "  all         - Build all examples (C++11)"
	@echo "  clean       - Remove built examples"
	@echo "  run-all     - Build and run all examples"
	@echo "  run-<name>  - Build and run specific example"
	@echo ""
	@echo "Examples:"
	@echo "  make              # Build all"
	@echo "  make run-all      # Build and run all"
	@echo "  make run-01-basic # Build and run 01-basic"
	@echo ""
	@echo "C++ Standards:"
	@echo "  Default: C++11"
	@echo "  For C++17 with string_view: make <example>-cpp17"
