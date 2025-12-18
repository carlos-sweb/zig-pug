/**
 * @file example_builder.c
 * @brief Ejemplos completos del Builder Pattern API
 * 
 * Compilar:
 *   gcc example_builder.c src/*.c -Iinclude -o example_builder
 */

#include "c_print_builder.h"
#include <stdio.h>
#include <string.h>

// ============================================================================
// EJEMPLO 1: Uso Básico
// ============================================================================

void example_01_basic() {
    printf("\n=== EJEMPLO 1: Uso Básico ===\n\n");
    
    CPrintBuilder* b = cp_new();
    
    // Texto simple
    cp_text(b, "Hello ");
    cp_str(cp_color_str(b, "red"), "World");
    cp_text(b, "!\n");
    cp_print(b);
    
    // Con número
    cp_reset(b);
    cp_text(b, "The answer is ");
    cp_int(cp_color_str(b, "cyan"), 42);
    cp_println(b);
    
    cp_free(b);
}

// ============================================================================
// EJEMPLO 2: Type Safety - Imposible Mezclar Tipos
// ============================================================================

void example_02_type_safety() {
    printf("\n=== EJEMPLO 2: Type Safety ===\n\n");
    
    CPrintBuilder* b = cp_new();
    
    // ✅ CORRECTO: Cada función acepta el tipo correcto
    cp_str(b, "Name: ");
    cp_str(cp_color_str(b, "green"), "Alice");
    cp_text(b, ", Age: ");
    cp_int(cp_color_str(b, "yellow"), 25);
    cp_println(b);
    
    // ❌ IMPOSIBLE EN COMPILE-TIME:
    // cp_str(b, 500);        // Error: expected 'const char*', got 'int'
    // cp_int(b, "hello");    // Error: expected 'int', got 'const char*'
    
    printf("✅ Type safety garantizada en compile-time\n");
    
    cp_free(b);
}

// ============================================================================
// EJEMPLO 3: Formateo de Números
// ============================================================================

void example_03_number_formatting() {
    printf("\n=== EJEMPLO 3: Formateo de Números ===\n\n");
    
    CPrintBuilder* b = cp_new();
    
    // Separador de miles
    cp_text(b, "Population: ");
    cp_int(cp_separator(b, ','), 1234567);
    cp_println(b);
    
    // Precisión decimal
    cp_reset(b);
    cp_text(b, "Pi: ");
    cp_float(cp_precision(b, 2), 3.14159);
    cp_println(b);
    
    // Zero-padding
    cp_reset(b);
    cp_text(b, "ID: ");
    cp_int(cp_zero_pad(b, 5), 42);
    cp_println(b);
    
    // Porcentaje
    cp_reset(b);
    cp_text(b, "Progress: ");
    cp_float(cp_as_percentage(cp_precision(b, 1), true), 0.856);
    cp_println(b);
    
    // Binario con prefijo
    cp_reset(b);
    cp_text(b, "Binary: ");
    cp_binary(cp_show_prefix(b, true), 42);
    cp_println(b);
    
    // Hexadecimal con prefijo y padding
    cp_reset(b);
    cp_text(b, "Hex: ");
    cp_hex(cp_show_prefix(cp_zero_pad(b, 8), true), 255);
    cp_println(b);
    
    cp_free(b);
}

// ============================================================================
// EJEMPLO 4: Alineación y Fill Characters
// ============================================================================

void example_04_alignment() {
    printf("\n=== EJEMPLO 4: Alineación ===\n\n");
    
    CPrintBuilder* b = cp_new();
    
    // Izquierda
    cp_text(b, "|");
    cp_str(cp_align_left(b, 20), "Left");
    cp_text(b, "|\n");
    cp_print(b);
    
    // Derecha
    cp_reset(b);
    cp_text(b, "|");
    cp_str(cp_align_right(b, 20), "Right");
    cp_text(b, "|\n");
    cp_print(b);
    
    // Centro
    cp_reset(b);
    cp_text(b, "|");
    cp_str(cp_align_center(b, 20), "Center");
    cp_text(b, "|\n");
    cp_print(b);
    
    // Con fill character personalizado
    cp_reset(b);
    cp_text(b, "|");
    cp_str(cp_align_center(cp_fill_char(b, '*'), 20), "STAR");
    cp_text(b, "|\n");
    cp_print(b);
    
    cp_reset(b);
    cp_text(b, "|");
    cp_str(cp_align_right(cp_fill_char(b, '-'), 30), "RIGHT");
    cp_text(b, "|\n");
    cp_print(b);
    
    cp_free(b);
}

// ============================================================================
// EJEMPLO 5: Chaining - Múltiples Opciones
// ============================================================================

void example_05_chaining() {
    printf("\n=== EJEMPLO 5: Chaining Múltiple ===\n\n");
    
    CPrintBuilder* b = cp_new();
    
    // Combinar: color + alineación + separador
    cp_text(b, "Total: $");
    cp_int(
        cp_separator(
            cp_align_right(
                cp_color_str(b, "green"),
                15
            ),
            ','
        ),
        1234567
    );
    cp_println(b);
    
    // Combinar: color + fondo + estilo + precisión
    cp_reset(b);
    cp_text(b, "Price: $");
    cp_float(
        cp_precision(
            cp_style_str(
                cp_bg_str(
                    cp_color_str(b, "bright_white"),
                    "bg_blue"
                ),
                "bold"
            ),
            2
        ),
        99.99
    );
    cp_println(b);
    
    cp_free(b);
}

// ============================================================================
// EJEMPLO 6: Tabla Profesional
// ============================================================================

void example_06_table() {
    printf("\n=== EJEMPLO 6: Tabla Profesional ===\n\n");
    
    CPrintBuilder* b = cp_new();
    
    // Header
    cp_text(b, "+");
    cp_str(cp_align_center(cp_fill_char(b, '='), 60), " INVOICE #00042 ");
    cp_text(b, "+\n");
    cp_print(b);
    
    // Rows
    const char* items[] = {"Laptop", "Mouse", "Keyboard"};
    double prices[] = {1299.99, 29.99, 79.99};
    
    for (int i = 0; i < 3; i++) {
        cp_reset(b);
        cp_text(b, "| ");
        cp_str(cp_align_left(b, 30), items[i]);
        cp_text(b, " $");
        cp_float(
            cp_precision(
                cp_align_right(
                    cp_color_str(b, "green"),
                    15
                ),
                2
            ),
            prices[i]
        );
        cp_text(b, " |\n");
        cp_print(b);
    }
    
    // Separator
    cp_reset(b);
    cp_text(b, "+");
    cp_str(cp_align_center(cp_fill_char(b, '-'), 60), "");
    cp_text(b, "+\n");
    cp_print(b);
    
    // Total
    cp_reset(b);
    cp_text(b, "| ");
    cp_str(cp_align_left(cp_style_str(b, "bold"), 30), "TOTAL");
    cp_text(b, " $");
    cp_float(
        cp_precision(
            cp_align_right(
                cp_style_str(
                    cp_color_str(b, "bright_green"),
                    "bold"
                ),
                15
            ),
            2
        ),
        1409.97
    );
    cp_text(b, " |\n");
    cp_print(b);
    
    // Footer
    cp_reset(b);
    cp_text(b, "+");
    cp_str(cp_align_center(cp_fill_char(b, '='), 60), "");
    cp_text(b, "+\n");
    cp_print(b);
    
    cp_free(b);
}

// ============================================================================
// EJEMPLO 7: Dashboard de Métricas
// ============================================================================

void example_07_dashboard() {
    printf("\n=== EJEMPLO 7: Dashboard de Métricas ===\n\n");
    
    CPrintBuilder* b = cp_new();
    
    // Title
    cp_text(b, "╔");
    cp_str(cp_align_center(cp_fill_char(b, '='), 58), "");
    cp_text(b, "╗\n");
    cp_print(b);
    
    cp_reset(b);
    cp_text(b, "║");
    cp_str(
        cp_align_center(
            cp_style_str(
                cp_color_str(b, "bright_cyan"),
                "bold"
            ),
            58
        ),
        "SYSTEM METRICS"
    );
    cp_text(b, "║\n");
    cp_print(b);
    
    cp_reset(b);
    cp_text(b, "╠");
    cp_str(cp_align_center(cp_fill_char(b, '='), 58), "");
    cp_text(b, "╣\n");
    cp_print(b);
    
    // Métricas
    struct {
        const char* label;
        const char* type;
        union { int i; double f; } value;
        const char* color;
    } metrics[] = {
        {"Active Users", "int", {.i = 123456}, "bright_green"},
        {"CPU Usage", "float", {.f = 0.67}, "bright_yellow"},
        {"Memory Usage", "float", {.f = 0.82}, "bright_red"},
        {"Disk Space Free", "float", {.f = 0.45}, "cyan"}
    };
    
    for (int i = 0; i < 4; i++) {
        cp_reset(b);
        cp_text(b, "║ ");
        cp_str(cp_align_left(b, 25), metrics[i].label);
        cp_text(b, " ");
        
        if (strcmp(metrics[i].type, "int") == 0) {
            cp_int(
                cp_separator(
                    cp_align_right(
                        cp_style_str(
                            cp_color_str(b, metrics[i].color),
                            "bold"
                        ),
                        30
                    ),
                    ','
                ),
                metrics[i].value.i
            );
        } else {
            cp_float(
                cp_as_percentage(
                    cp_precision(
                        cp_align_right(
                            cp_style_str(
                                cp_color_str(b, metrics[i].color),
                                "bold"
                            ),
                            29
                        ),
                        1
                    ),
                    true
                ),
                metrics[i].value.f
            );
        }
        
        cp_text(b, " ║\n");
        cp_print(b);
    }
    
    // Footer
    cp_reset(b);
    cp_text(b, "╚");
    cp_str(cp_align_center(cp_fill_char(b, '='), 58), "");
    cp_text(b, "╝\n");
    cp_print(b);
    
    cp_free(b);
}

// ============================================================================
// EJEMPLO 8: Reutilización del Builder
// ============================================================================

void example_08_reusability() {
    printf("\n=== EJEMPLO 8: Reutilización ===\n\n");
    
    CPrintBuilder* b = cp_new();
    
    // Imprimir múltiples líneas reutilizando el builder
    const char* names[] = {"Alice", "Bob", "Charlie", "Diana"};
    int ages[] = {25, 30, 28, 35};
    
    for (int i = 0; i < 4; i++) {
        cp_reset(b);  // Resetear entre usos
        
        cp_text(b, "[");
        cp_int(cp_color_str(b, "yellow"), i + 1);
        cp_text(b, "] ");
        cp_str(cp_color_str(b, "cyan"), names[i]);
        cp_text(b, " - Age: ");
        cp_int(cp_style_str(b, "bold"), ages[i]);
        cp_println(b);
    }
    
    cp_free(b);
}

// ============================================================================
// EJEMPLO 9: Comparación con API Variádica (Seguridad)
// ============================================================================

void example_09_safety_comparison() {
    printf("\n=== EJEMPLO 9: Seguridad de Tipos ===\n\n");
    
    printf("❌ Con c_print() variádico:\n");
    printf("   c_print(\"{s:blue}\", 500);  // SEGFAULT!\n\n");
    
    printf("✅ Con Builder Pattern:\n");
    CPrintBuilder* b = cp_new();
    
    // Esto NO compila si intentas pasar tipo incorrecto:
    // cp_str(b, 500);     // ❌ Compile error!
    // cp_int(b, "hello"); // ❌ Compile error!
    
    // Solo acepta tipos correctos:
    cp_str(cp_color_str(b, "blue"), "Hello");  // ✅ OK
    cp_text(b, " ");
    cp_int(cp_color_str(b, "green"), 500);     // ✅ OK
    cp_println(b);
    
    printf("✅ Type safety garantizada por el compilador\n");
    
    cp_free(b);
}

// ============================================================================
// MAIN
// ============================================================================

int main(void) {
    printf("╔════════════════════════════════════════════════════════╗\n");
    printf("║   CPrintBuilder - Builder Pattern Examples            ║\n");
    printf("╚════════════════════════════════════════════════════════╝\n");
    
    example_01_basic();
    example_02_type_safety();
    example_03_number_formatting();
    example_04_alignment();
    example_05_chaining();
    example_06_table();
    example_07_dashboard();
    example_08_reusability();
    example_09_safety_comparison();
    
    printf("\n✅ Todos los ejemplos ejecutados correctamente\n");
    printf("✅ Sin posibilidad de type mismatch\n");
    printf("✅ Sin segfaults por errores de tipo\n\n");
    
    return 0;
}