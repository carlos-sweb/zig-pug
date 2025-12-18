/**
 * @file color_parser.h
 * @brief Parseo de colores y estilos desde strings
 * 
 * Este módulo convierte strings como "red", "bg_green", "bold"
 * a sus correspondientes enums de ANSI codes.
 */

#ifndef COLOR_PARSER_H
#define COLOR_PARSER_H

#include "ansi_codes.h"
#include <stdbool.h>

#ifdef __cplusplus
extern "C" {
#endif

/**
 * @brief Convierte un string a un color de texto
 * @param color String con el nombre del color ("red", "green", etc.)
 * @return TextColor correspondiente o COLOR_RESET si no se reconoce
 * 
 * Colores soportados:
 * - Estándar: black, red, green, yellow, blue, magenta, cyan, white
 * - Brillantes: bright_black, bright_red, bright_green, etc.
 */
TextColor parse_text_color(const char* color);

/**
 * @brief Convierte un string a un color de fondo
 * @param color String con el nombre del color (puede incluir "bg_" o no)
 * @return BackgroundColor correspondiente o BG_RESET si no se reconoce
 * 
 * Ejemplos válidos:
 * - "bg_red", "bg_green"
 * - "red", "green" (se asume prefijo bg_)
 */
BackgroundColor parse_bg_color(const char* color);

/**
 * @brief Convierte un string a un estilo de texto
 * @param style String con el nombre del estilo
 * @return TextStyle correspondiente o STYLE_RESET si no se reconoce
 * 
 * Estilos soportados:
 * - bold, dim, italic, underline, blink, reverse, hidden, strikethrough
 */
TextStyle parse_text_style(const char* style);

/**
 * @brief Verifica si un string es un color de fondo (comienza con "bg_")
 * @param token String a verificar
 * @return true si comienza con "bg_", false en caso contrario
 */
bool is_background_color(const char* token);

#ifdef __cplusplus
}
#endif

#endif // COLOR_PARSER_H