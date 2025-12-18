#!/bin/bash
#
# compile_and_test.sh - Compila y prueba todas las versiones de c_print
#

set -e  # Exit on error

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${BLUE}════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}   c_print - Complete Compilation and Testing Suite${NC}"
echo -e "${BLUE}════════════════════════════════════════════════════════════${NC}"
echo ""

# ============================================================================
# FASE 1: Limpiar build anterior
# ============================================================================

echo -e "${YELLOW}[1/6] Cleaning previous build...${NC}"
rm -rf build
echo -e "${GREEN}✓ Clean completed${NC}"
echo ""

# ============================================================================
# FASE 2: Configurar con CMake
# ============================================================================

echo -e "${YELLOW}[2/6] Configuring with CMake...${NC}"
if command -v ninja &> /dev/null; then
    echo "  Using Ninja build system"
    cmake -G Ninja -B build -DBUILD_TESTS=ON -DBUILD_EXAMPLES=ON
else
    echo "  Using Make build system"
    cmake -B build -DBUILD_TESTS=ON -DBUILD_EXAMPLES=ON
fi
echo -e "${GREEN}✓ Configuration completed${NC}"
echo ""

# ============================================================================
# FASE 3: Compilar
# ============================================================================

echo -e "${YELLOW}[3/6] Building project...${NC}"
if command -v ninja &> /dev/null; then
    ninja -C build
else
    cmake --build build
fi
echo -e "${GREEN}✓ Build completed${NC}"
echo ""

# ============================================================================
# FASE 4: Verificar archivos generados
# ============================================================================

echo -e "${YELLOW}[4/6] Verifying generated files...${NC}"

files_ok=true

# Bibliotecas
# if [ -f "build/lib/libc_print.so" ] || [ -f "build/lib/libc_print.dylib" ]; then
if [ -f "build/libc_print.so" ] || [ -f "build/libc_print.dylib" ]; then
    echo -e "  ${GREEN}✓${NC} Shared library"
else
    echo -e "  ${RED}✗${NC} Shared library NOT FOUND"
    files_ok=false
fi

if [ -f "build/libc_print.a" ]; then
    echo -e "  ${GREEN}✓${NC} Static library"
else
    echo -e "  ${RED}✗${NC} Static library NOT FOUND"
    files_ok=false
fi

# Ejemplos
for example in example_shared example_static example_builder example_generic; do
    if [ -f "build/bin/$example" ] || [ -f "build/$example" ]; then
        echo -e "  ${GREEN}✓${NC} $example"
    else
        echo -e "  ${RED}✗${NC} $example NOT FOUND"
        files_ok=false
    fi
done

# Tests
for test in test_string_utils test_color_parser test_number_formatter test_text_alignment test_builder; do
    if [ -f "build/bin/$test" ] || [ -f "build/$test" ]; then
        echo -e "  ${GREEN}✓${NC} $test"
    else
        echo -e "  ${RED}✗${NC} $test NOT FOUND"
        files_ok=false
    fi
done

if [ "$files_ok" = false ]; then
    echo -e "${RED}✗ Some files are missing${NC}"
    exit 1
fi

echo -e "${GREEN}✓ All files generated successfully${NC}"
echo ""

# ============================================================================
# FASE 5: Ejecutar Tests Unitarios
# ============================================================================

echo -e "${YELLOW}[5/6] Running unit tests...${NC}"
echo ""

test_failed=false

# Ejecutar cada test
for test in test_string_utils test_color_parser test_number_formatter test_text_alignment test_builder; do
    test_path=""
    if [ -f "build/bin/$test" ]; then
        test_path="build/bin/$test"
    elif [ -f "build/$test" ]; then
        test_path="build/$test"
    fi
    
    if [ -n "$test_path" ]; then
        echo -e "${CYAN}Running $test...${NC}"
        if $test_path; then
            echo -e "${GREEN}✓ $test passed${NC}"
            echo ""
        else
            echo -e "${RED}✗ $test FAILED${NC}"
            test_failed=true
            echo ""
        fi
    fi
done

if [ "$test_failed" = true ]; then
    echo -e "${RED}✗ Some tests failed${NC}"
    exit 1
fi

echo -e "${GREEN}✓ All unit tests passed${NC}"
echo ""

# ============================================================================
# FASE 6: Ejecutar Ejemplos
# ============================================================================

echo -e "${YELLOW}[6/6] Running examples...${NC}"
echo ""

examples_ok=true

# Example shared
example_path=""
if [ -f "build/bin/example_shared" ]; then
    example_path="build/bin/example_shared"
elif [ -f "build/example_shared" ]; then
    example_path="build/example_shared"
fi

if [ -n "$example_path" ]; then
    echo -e "${CYAN}═══ Example: c_print() Original (Variadic) ═══${NC}"
    if $example_path | head -20; then
        echo "..."
        echo -e "${GREEN}✓ example_shared works${NC}"
    else
        echo -e "${RED}✗ example_shared FAILED${NC}"
        examples_ok=false
    fi
    echo ""
fi

# Example builder
example_path=""
if [ -f "build/bin/example_builder" ]; then
    example_path="build/bin/example_builder"
elif [ -f "build/example_builder" ]; then
    example_path="build/example_builder"
fi

if [ -n "$example_path" ]; then
    echo -e "${CYAN}═══ Example: Builder Pattern (Type-Safe) ═══${NC}"
    if $example_path | head -30; then
        echo "..."
        echo -e "${GREEN}✓ example_builder works${NC}"
    else
        echo -e "${RED}✗ example_builder FAILED${NC}"
        examples_ok=false
    fi
    echo ""
fi

# Example generic
example_path=""
if [ -f "build/bin/example_generic" ]; then
    example_path="build/bin/example_generic"
elif [ -f "build/example_generic" ]; then
    example_path="build/example_generic"
fi

if [ -n "$example_path" ]; then
    echo -e "${CYAN}═══ Example: _Generic C11 (Compile-Time Validation) ═══${NC}"
    if $example_path | head -30; then
        echo "..."
        echo -e "${GREEN}✓ example_generic works${NC}"
    else
        echo -e "${RED}✗ example_generic FAILED${NC}"
        examples_ok=false
    fi
    echo ""
fi

if [ "$examples_ok" = false ]; then
    echo -e "${RED}✗ Some examples failed${NC}"
    exit 1
fi

# ============================================================================
# RESUMEN FINAL
# ============================================================================

echo ""
echo -e "${BLUE}════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}   ✅ ALL TESTS AND EXAMPLES PASSED SUCCESSFULLY${NC}"
echo -e "${BLUE}════════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "${CYAN}Summary:${NC}"
echo -e "  ${GREEN}✓${NC} Libraries compiled (shared + static)"
echo -e "  ${GREEN}✓${NC} 5 unit tests passed"
echo -e "  ${GREEN}✓${NC} 3 examples executed successfully"
echo ""
echo -e "${CYAN}Available APIs:${NC}"
echo -e "  1. ${YELLOW}c_print()${NC}       - Variadic API (C99+)"
echo -e "  2. ${YELLOW}C_PRINT()${NC}       - _Generic validation (C11+)"
echo -e "  3. ${YELLOW}CPrintBuilder${NC}   - Builder Pattern (100% type-safe)"
echo ""
echo -e "${CYAN}Try the examples:${NC}"
if [ -f "build/bin/example_shared" ]; then
    echo -e "  ./build/bin/example_shared"
    echo -e "  ./build/bin/example_builder"
    echo -e "  ./build/bin/example_static"
else
    echo -e "  ./build/example_shared"
    echo -e "  ./build/example_builder"
    echo -e "  ./build/example_static"
fi
echo ""
echo -e "${GREEN}🎉 Project is ready for production!${NC}"
echo ""