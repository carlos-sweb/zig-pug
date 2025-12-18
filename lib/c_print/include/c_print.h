/**
 * @file c_print.h
 * @brief API pública de c_print - Colored Text Printing Library
 * @version 1.0.0
 * 
 * Biblioteca para impresión de texto con colores, estilos y formato avanzado
 * en terminal usando códigos ANSI.
 */

#ifndef C_PRINT_H
#define C_PRINT_H

#include <stdio.h>
#include <stdarg.h>

// Importar tipos públicos de los módulos
#include "ansi_codes.h"
#include "text_alignment.h"

#ifdef __cplusplus
extern "C" {
#endif

/**
 * @brief Estructura para opciones de impresión (API legacy)
 */
typedef struct {
    TextColor text_color;
    BackgroundColor bg_color;
    TextStyle style;
} PrintOptions;

// ============================================================================
// API PRINCIPAL: Sistema de patrones moderno
// ============================================================================

/**
 * @brief Imprime texto con formato usando patrones {type:spec1:spec2:...}
 * @param pattern String con el patrón de formato
 * @param ... Argumentos variables según los tipos en el patrón
 * 
 * Sintaxis de patrones:
 * - {s:...} → string
 * - {d:...} → int
 * - {f:...} → float/double
 * - {c:...} → char
 * - {b:...} → binario
 * - {x:...} → hexadecimal
 * - {o:...} → octal
 * - {u:...} → unsigned int
 * - {l:...} → long
 * 
 * Especificadores (en cualquier orden):
 * - Colores: red, green, blue, cyan, magenta, yellow, white, black, bright_*
 * - Fondos: bg_red, bg_green, bg_blue, etc.
 * - Estilos: bold, italic, underline, dim, blink, reverse, strikethrough
 * - Alineación: <N (izq), >N (der), ^N (centro)
 * - Fill char: *^20, ->30, .>25
 * - Precisión: .2, .4 (para floats)
 * - Padding: 05, 08 (con ceros)
 * - Separadores: , o _
 * - Prefijos: # (0b, 0x, 0o)
 * - Signo: +
 * - Porcentaje: %
 * 
 * Ejemplos:
 * @code
 * c_print("Hello {s:green:bold}!\n", "World");
 * c_print("Price: ${f:.2:,}\n", 1234.56);
 * c_print("ID: {d:05:cyan}\n", 42);
 * c_print("|{s:*^30}|\n", "TITLE");
 * c_print("Progress: {f:.1%:green}\n", 0.75);
 * @endcode
 */
void c_print(const char* pattern, ...);

// ============================================================================
// API LEGACY: Funciones tradicionales (compatibilidad)
// ============================================================================

/**
 * @brief Imprime texto con color, fondo y estilo
 * @param text Texto a imprimir
 * @param fg Color de texto
 * @param bg Color de fondo
 * @param style Estilo de texto
 */
void c_print_styled(const char* text, TextColor fg, BackgroundColor bg, TextStyle style);

/**
 * @brief Imprime texto solo con color de texto
 * @param text Texto a imprimir
 * @param fg Color de texto
 */
void c_print_color(const char* text, TextColor fg);

/**
 * @brief Imprime texto solo con color de fondo
 * @param text Texto a imprimir
 * @param bg Color de fondo
 */
void c_print_bg(const char* text, BackgroundColor bg);

/**
 * @brief Imprime texto solo con estilo
 * @param text Texto a imprimir
 * @param style Estilo de texto
 */
void c_print_style(const char* text, TextStyle style);

/**
 * @brief Imprime texto usando estructura de opciones
 * @param text Texto a imprimir
 * @param opts Opciones de formato (PrintOptions)
 */
void c_print_full(const char* text, PrintOptions opts);

/**
 * @brief Printf con formato y estilos ANSI
 * @param fg Color de texto
 * @param bg Color de fondo
 * @param style Estilo de texto
 * @param format String de formato estilo printf
 * @param ... Argumentos variables para el formato
 */
void c_printf_styled(TextColor fg, BackgroundColor bg, TextStyle style, 
                     const char* format, ...);

// ============================================================================
// FUNCIONES AUXILIARES PÚBLICAS
// ============================================================================

/**
 * @brief Convierte string a TextColor
 * @param color Nombre del color ("red", "green", etc.)
 * @return TextColor correspondiente o COLOR_RESET si no se reconoce
 */
TextColor parse_text_color(const char* color);

/**
 * @brief Convierte string a BackgroundColor
 * @param color Nombre del color ("bg_red", "red", etc.)
 * @return BackgroundColor correspondiente o BG_RESET si no se reconoce
 */
BackgroundColor parse_bg_color(const char* color);

/**
 * @brief Convierte string a TextStyle
 * @param style Nombre del estilo ("bold", "italic", etc.)
 * @return TextStyle correspondiente o STYLE_RESET si no se reconoce
 */
TextStyle parse_text_style(const char* style);

#ifdef __cplusplus
}
#endif

#endif // C_PRINT_H