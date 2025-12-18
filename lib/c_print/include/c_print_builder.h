/**
 * @file c_print_builder.h
 * @brief Builder Pattern API - Totalmente Type-Safe
 * 
 * Esta versión elimina completamente las funciones variádicas
 * usando el patrón Builder para construcción segura.
 */

#ifndef C_PRINT_BUILDER_H
#define C_PRINT_BUILDER_H

#include "ansi_codes.h"
#include <stdbool.h>

#ifdef __cplusplus
extern "C" {
#endif

// ============================================================================
// TIPOS Y ESTRUCTURAS
// ============================================================================

typedef struct CPrintBuilder CPrintBuilder;

// ============================================================================
// CREACIÓN Y DESTRUCCIÓN
// ============================================================================

/**
 * @brief Crea un nuevo builder
 * @return Builder recién creado (debe ser liberado con cp_free)
 */
CPrintBuilder* cp_new(void);

/**
 * @brief Libera un builder
 */
void cp_free(CPrintBuilder* builder);

/**
 * @brief Resetea un builder para reutilizarlo
 */
void cp_reset(CPrintBuilder* builder);

// ============================================================================
// AGREGAR CONTENIDO (TYPE-SAFE)
// ============================================================================

/**
 * @brief Agrega texto literal (sin formato)
 */
CPrintBuilder* cp_text(CPrintBuilder* b, const char* text);

/**
 * @brief Agrega un string con formato
 */
CPrintBuilder* cp_str(CPrintBuilder* b, const char* str);

/**
 * @brief Agrega un entero con formato
 */
CPrintBuilder* cp_int(CPrintBuilder* b, int value);

/**
 * @brief Agrega un entero sin signo
 */
CPrintBuilder* cp_uint(CPrintBuilder* b, unsigned int value);

/**
 * @brief Agrega un long
 */
CPrintBuilder* cp_long(CPrintBuilder* b, long value);

/**
 * @brief Agrega un float/double
 */
CPrintBuilder* cp_float(CPrintBuilder* b, double value);

/**
 * @brief Agrega un char
 */
CPrintBuilder* cp_char(CPrintBuilder* b, char value);

/**
 * @brief Agrega un booleano (true/false)
 */
CPrintBuilder* cp_bool(CPrintBuilder* b, bool value);

/**
 * @brief Agrega un número en binario
 */
CPrintBuilder* cp_binary(CPrintBuilder* b, unsigned int value);

/**
 * @brief Agrega un número en hexadecimal
 */
CPrintBuilder* cp_hex(CPrintBuilder* b, unsigned int value);

/**
 * @brief Agrega un número en octal
 */
CPrintBuilder* cp_octal(CPrintBuilder* b, unsigned int value);

// ============================================================================
// CONFIGURACIÓN DE FORMATO (CHAINABLE)
// ============================================================================

/**
 * @brief Establece el color de texto para el siguiente elemento
 */
CPrintBuilder* cp_color(CPrintBuilder* b, TextColor color);

/**
 * @brief Establece el color de texto desde string
 */
CPrintBuilder* cp_color_str(CPrintBuilder* b, const char* color_name);

/**
 * @brief Establece el color de fondo
 */
CPrintBuilder* cp_bg(CPrintBuilder* b, BackgroundColor color);

/**
 * @brief Establece el color de fondo desde string
 */
CPrintBuilder* cp_bg_str(CPrintBuilder* b, const char* color_name);

/**
 * @brief Establece el estilo de texto
 */
CPrintBuilder* cp_style(CPrintBuilder* b, TextStyle style);

/**
 * @brief Establece el estilo desde string
 */
CPrintBuilder* cp_style_str(CPrintBuilder* b, const char* style_name);

/**
 * @brief Establece la precisión para floats
 */
CPrintBuilder* cp_precision(CPrintBuilder* b, int precision);

/**
 * @brief Establece padding con ceros
 */
CPrintBuilder* cp_zero_pad(CPrintBuilder* b, int width);

/**
 * @brief Establece padding con espacios
 */
CPrintBuilder* cp_pad(CPrintBuilder* b, int width);

/**
 * @brief Establece separador de miles
 */
CPrintBuilder* cp_separator(CPrintBuilder* b, char sep);

/**
 * @brief Muestra prefijo para números (0b, 0x, 0o)
 */
CPrintBuilder* cp_show_prefix(CPrintBuilder* b, bool show);

/**
 * @brief Muestra signo para números positivos
 */
CPrintBuilder* cp_show_sign(CPrintBuilder* b, bool show);

/**
 * @brief Formatea como porcentaje
 */
CPrintBuilder* cp_as_percentage(CPrintBuilder* b, bool show);

/**
 * @brief Alineación a la izquierda
 */
CPrintBuilder* cp_align_left(CPrintBuilder* b, int width);

/**
 * @brief Alineación a la derecha
 */
CPrintBuilder* cp_align_right(CPrintBuilder* b, int width);

/**
 * @brief Alineación al centro
 */
CPrintBuilder* cp_align_center(CPrintBuilder* b, int width);

/**
 * @brief Establece carácter de relleno para alineación
 */
CPrintBuilder* cp_fill_char(CPrintBuilder* b, char ch);

// ============================================================================
// IMPRESIÓN
// ============================================================================

/**
 * @brief Imprime el contenido construido
 */
void cp_print(CPrintBuilder* b);

/**
 * @brief Imprime y agrega newline
 */
void cp_println(CPrintBuilder* b);

/**
 * @brief Obtiene el string construido (sin imprimir)
 * @return String que debe ser liberado con free()
 */
char* cp_to_string(CPrintBuilder* b);

// ============================================================================
// UTILIDADES
// ============================================================================

/**
 * @brief Obtiene el tamaño del contenido construido
 */
size_t cp_size(const CPrintBuilder* b);

/**
 * @brief Verifica si el builder está vacío
 */
bool cp_is_empty(const CPrintBuilder* b);

// ============================================================================
// EJEMPLOS DE USO
// ============================================================================

/*
EJEMPLO 1: Uso básico con chaining
-----------------------------------------
CPrintBuilder* b = cp_new();
cp_color_str(b, "red");
cp_str(b, "Hello");
cp_text(b, " ");
cp_color_str(b, "blue");
cp_int(b, 42);
cp_println(b);
cp_free(b);


EJEMPLO 2: Chaining completo (más legible)
-----------------------------------------
CPrintBuilder* b = cp_new();
cp_println(
    cp_int(
        cp_separator(
            cp_color_str(b, "green"),
            ','
        ),
        1234567
    )
);
cp_free(b);


EJEMPLO 3: Formato complejo
-----------------------------------------
CPrintBuilder* b = cp_new();
cp_text(b, "Price: $");
cp_float(
    cp_precision(
        cp_align_right(
            cp_color_str(b, "green"),
            15
        ),
        2
    ),
    1234.56
);
cp_println(b);
cp_free(b);


EJEMPLO 4: Reutilización del builder
-----------------------------------------
CPrintBuilder* b = cp_new();
for (int i = 0; i < 10; i++) {
    cp_reset(b);
    cp_text(b, "Item ");
    cp_int(cp_color_str(b, "cyan"), i);
    cp_println(b);
}
cp_free(b);


EJEMPLO 5: Tabla formateada
-----------------------------------------
CPrintBuilder* b = cp_new();

// Header
cp_text(b, "+");
cp_text(cp_fill_char(b, '-'), "");
cp_align_center(b, 50);
cp_text(b, " TITLE ");
cp_text(b, "+\n");

// Rows
cp_text(b, "| ");
cp_str(cp_align_left(b, 30), "Item");
cp_text(b, " $");
cp_float(
    cp_precision(
        cp_align_right(
            cp_color_str(b, "green"),
            15
        ),
        2
    ),
    123.45
);
cp_text(b, " |\n");

cp_println(b);
cp_free(b);
*/

#ifdef __cplusplus
}
#endif

#endif // C_PRINT_BUILDER_H