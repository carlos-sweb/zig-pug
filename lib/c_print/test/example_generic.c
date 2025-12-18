/**
 * @file example_generic.c
 * @brief Ejemplos de uso de _Generic (C11) con c_print
 * 
 * Compilar con C11:
 *   gcc -std=c11 example_generic.c src/*.c -Iinclude -o example_generic
 */

#define C_PRINT_USE_GENERIC
#include "c_print.h"
#include "c_print_generic.h"
#include <stdio.h>

// ============================================================================
// EJEMPLO 1: Detección Automática de Tipos
// ============================================================================

void example_01_auto_detection() {
    printf("\n=== EJEMPLO 1: Detección Automática ===\n\n");
    
    // _Generic detecta automáticamente el tipo
    C_PRINT("String: {s:green}\n", "Hello");
    C_PRINT("Integer: {d:cyan}\n", 42);
    C_PRINT("Float: {f:.2:yellow}\n", 3.14159);
    C_PRINT("Char: {c:magenta}\n", 'A');
    
    printf("\n✅ Todos los tipos detectados correctamente\n");
}

// ============================================================================
// EJEMPLO 2: Detección de Errores en Compile-Time
// ============================================================================

void example_02_compile_time_errors() {
    printf("\n=== EJEMPLO 2: Detección de Errores ===\n\n");
    
    printf("❌ Estos errores son detectados:\n\n");
    
    // Error 1: String esperado, int proporcionado
    printf("1. Pattern: {s:blue}, Value: 500\n");
    C_PRINT("   Result: {s:blue}\n", 500);
    // ⚠️ Compile warning + Runtime error message
    
    printf("\n");
    
    // Error 2: Int esperado, string proporcionado
    printf("2. Pattern: {d:red}, Value: \"hello\"\n");
    C_PRINT("   Result: {d:red}\n", "hello");
    // ⚠️ Compile warning + Runtime error message
    
    printf("\n");
    
    // Error 3: Double esperado, int proporcionado (esto puede funcionar con cast implícito)
    printf("3. Pattern: {f:.2:green}, Value: 42\n");
    C_PRINT("   Result: {f:.2:green}\n", 42);
    // ⚠️ Puede dar warning dependiendo del compilador
    
    printf("\n✅ Errores mostrados con mensajes claros\n");
}

// ============================================================================
// EJEMPLO 3: Uso Correcto con Múltiples Tipos
// ============================================================================

void example_03_multiple_types() {
    printf("\n=== EJEMPLO 3: Múltiples Tipos Correctos ===\n\n");
    
    const char* name = "Alice";
    int age = 25;
    double salary = 75000.50;
    char grade = 'A';
    
    C_PRINT("Employee: {s:cyan:bold}\n", name);
    C_PRINT("Age: {d:yellow} years\n", age);
    C_PRINT("Salary: ${f:.2:green:,}\n", salary);
    C_PRINT("Grade: {c:magenta:bold}\n", grade);
    
    printf("\n✅ Todos los tipos coinciden perfectamente\n");
}

// ============================================================================
// EJEMPLO 4: Debug de Tipos
// ============================================================================

void example_04_debug_types() {
    printf("\n=== EJEMPLO 4: Debug de Tipos ===\n\n");
    
    C_PRINT_DEBUG_TYPES("{s} {d} {f:.2} {c}",
                        "test", 42, 3.14159, 'X');
    
    printf("\n✅ Información detallada de cada argumento\n");
}

// ============================================================================
// EJEMPLO 5: Validación Manual
// ============================================================================

void example_05_manual_validation() {
    printf("\n=== EJEMPLO 5: Validación Manual ===\n\n");
    
    const char* pattern1 = "{s:red} {d:green}";
    const char* pattern2 = "{s:red} {d:green}";
    
    printf("Validando: \"%s\"\n", pattern1);
    if (c_print_validate_pattern(pattern1, 2,
                                 CPRINT_ARG("Hello"),
                                 CPRINT_ARG(42))) {
        printf("✅ Patrón válido\n");
        C_PRINT(pattern1, "Hello", 42);
        printf("\n");
    }
    
    printf("\nValidando patrón con error: \"%s\"\n", pattern2);
    if (!c_print_validate_pattern(pattern2, 2,
                                  CPRINT_ARG(500),
                                  CPRINT_ARG("World"))) {
        printf("❌ Patrón inválido (como se esperaba)\n");
    }
}

// ============================================================================
// EJEMPLO 6: Comparación con c_print() Original
// ============================================================================

void example_06_comparison() {
    printf("\n=== EJEMPLO 6: Comparación APIs ===\n\n");
    
    printf("1. c_print() original (sin validación):\n");
    c_print("   Text: {s:red}, Number: {d:green}\n", "Hello", 42);
    
    printf("\n2. C_PRINT() con _Generic (con validación):\n");
    C_PRINT("   Text: {s:red}, Number: {d:green}\n", "Hello", 42);
    
    printf("\n✅ Ambas APIs disponibles según necesidad\n");
}

// ============================================================================
// EJEMPLO 7: Formateo Avanzado con Validación
// ============================================================================

void example_07_advanced_formatting() {
    printf("\n=== EJEMPLO 7: Formateo Avanzado ===\n\n");
    
    // Separador de miles
    C_PRINT("Population: {d:,:cyan}\n", 1234567);
    
    // Precisión decimal
    C_PRINT("Pi: {f:.4:yellow}\n", 3.14159265);
    
    // Porcentaje
    C_PRINT("Progress: {f:.1%:green}\n", 0.856);
    
    // Binario con prefijo
    C_PRINT("Binary: {b:#:magenta}\n", 42);
    
    // Hexadecimal con prefijo y padding
    C_PRINT("Hex: {x:#:08:red}\n", 255);
    
    printf("\n✅ Formateo avanzado con type safety\n");
}

// ============================================================================
// EJEMPLO 8: Tabla con Validación
// ============================================================================

void example_08_table() {
    printf("\n=== EJEMPLO 8: Tabla con Validación ===\n\n");
    
    C_PRINT("+{s:-^60}+\n", " SALES REPORT ");
    C_PRINT("| {s:<30} | {s:>25} |\n", "Product", "Revenue");
    C_PRINT("+{s:-^60}+\n", "");
    
    // Datos
    const char* products[] = {"Laptop", "Mouse", "Keyboard"};
    double revenues[] = {1299.99, 29.99, 79.99};
    
    for (int i = 0; i < 3; i++) {
        C_PRINT("| {s:<30:cyan} | ${f:>23:.2:green:bold} |\n",
                products[i], revenues[i]);
    }
    
    C_PRINT("+{s:=^60}+\n", "");
    
    printf("\n✅ Tabla formateada con type safety\n");
}

// ============================================================================
// EJEMPLO 9: Error de Cantidad de Argumentos
// ============================================================================

void example_09_argument_count() {
    printf("\n=== EJEMPLO 9: Detección de Argumentos Faltantes ===\n\n");
    
    printf("Patrón: {s:red} {d:green} {f:.2:blue}\n");
    printf("Argumentos: solo 2 (faltan 1)\n\n");
    
    // Esto debería mostrar error
    C_PRINT("Result: {s:red} {d:green} {f:.2:blue}\n", "Test", 42);
    // ⚠️ Muestra: "Result: Test 42 {? missing argument}"
    
    printf("\n✅ Error de cantidad detectado\n");
}

// ============================================================================
// EJEMPLO 10: Tipos Numéricos Mixtos
// ============================================================================

void example_10_numeric_types() {
    printf("\n=== EJEMPLO 10: Tipos Numéricos ===\n\n");
    
    int i = 42;
    unsigned int u = 100;
    long l = 1234567890L;
    float f = 3.14f;
    double d = 2.71828;
    
    C_PRINT("int:      {d:cyan}\n", i);
    C_PRINT("unsigned: {u:green}\n", u);
    C_PRINT("long:     {l:,:yellow}\n", l);
    C_PRINT("float:    {f:.2:magenta}\n", (double)f);  // Cast explícito
    C_PRINT("double:   {f:.5:red}\n", d);
    
    printf("\n✅ Todos los tipos numéricos soportados\n");
}

// ============================================================================
// MAIN
// ============================================================================

int main(void) {
    printf("╔════════════════════════════════════════════════════════════╗\n");
    printf("║  c_print with _Generic (C11) - Type-Safe Examples         ║\n");
    printf("╚════════════════════════════════════════════════════════════╝\n");
    
    #if __STDC_VERSION__ >= 201112L
        printf("\n✅ C11 _Generic support detected\n");
    #else
        printf("\n⚠️  C11 not available, using fallback\n");
        printf("    Compile with: -std=c11\n");
        return 1;
    #endif
    
    example_01_auto_detection();
    example_02_compile_time_errors();
    example_03_multiple_types();
    example_04_debug_types();
    example_05_manual_validation();
    example_06_comparison();
    example_07_advanced_formatting();
    example_08_table();
    example_09_argument_count();
    example_10_numeric_types();
    
    printf("\n╔════════════════════════════════════════════════════════════╗\n");
    printf("║  Resumen de Beneficios                                     ║\n");
    printf("╚════════════════════════════════════════════════════════════╝\n");
    printf("\n");
    printf("✅ Detección de tipos en compile-time\n");
    printf("✅ Warnings del compilador en type mismatch\n");
    printf("✅ Mensajes de error claros en runtime\n");
    printf("✅ Compatible con c_print() original\n");
    printf("✅ Sin overhead en runtime (solo validación)\n");
    printf("✅ IDE autocomplete mejorado\n");
    printf("\n");
    
    return 0;
}