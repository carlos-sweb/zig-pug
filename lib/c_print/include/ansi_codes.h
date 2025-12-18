/**
 * @file ansi_codes.h
 * @brief Gestión de códigos ANSI para terminal
 * 
 * Este módulo maneja la aplicación y reseteo de códigos ANSI para
 * colores de texto, colores de fondo y estilos de texto.
 */

#ifndef ANSI_CODES_H
#define ANSI_CODES_H

#include <stdio.h>

#ifdef __cplusplus
extern "C" {
#endif

// Códigos ANSI para colores de texto
typedef enum {
    COLOR_RESET = 0,
    COLOR_BLACK = 30,
    COLOR_RED = 31,
    COLOR_GREEN = 32,
    COLOR_YELLOW = 33,
    COLOR_BLUE = 34,
    COLOR_MAGENTA = 35,
    COLOR_CYAN = 36,
    COLOR_WHITE = 37,
    COLOR_BRIGHT_BLACK = 90,
    COLOR_BRIGHT_RED = 91,
    COLOR_BRIGHT_GREEN = 92,
    COLOR_BRIGHT_YELLOW = 93,
    COLOR_BRIGHT_BLUE = 94,
    COLOR_BRIGHT_MAGENTA = 95,
    COLOR_BRIGHT_CYAN = 96,
    COLOR_BRIGHT_WHITE = 97
} TextColor;

// Códigos ANSI para colores de fondo
typedef enum {
    BG_RESET = 0,
    BG_BLACK = 40,
    BG_RED = 41,
    BG_GREEN = 42,
    BG_YELLOW = 43,
    BG_BLUE = 44,
    BG_MAGENTA = 45,
    BG_CYAN = 46,
    BG_WHITE = 47,
    BG_BRIGHT_BLACK = 100,
    BG_BRIGHT_RED = 101,
    BG_BRIGHT_GREEN = 102,
    BG_BRIGHT_YELLOW = 103,
    BG_BRIGHT_BLUE = 104,
    BG_BRIGHT_MAGENTA = 105,
    BG_BRIGHT_CYAN = 106,
    BG_BRIGHT_WHITE = 107
} BackgroundColor;

// Códigos ANSI para estilos de texto
typedef enum {
    STYLE_RESET = 0,
    STYLE_BOLD = 1,
    STYLE_DIM = 2,
    STYLE_ITALIC = 3,
    STYLE_UNDERLINE = 4,
    STYLE_BLINK = 5,
    STYLE_REVERSE = 7,
    STYLE_HIDDEN = 8,
    STYLE_STRIKETHROUGH = 9
} TextStyle;

/**
 * @brief Aplica códigos ANSI para color de texto, fondo y estilo
 * @param fg Color de texto (TextColor)
 * @param bg Color de fondo (BackgroundColor)
 * @param style Estilo de texto (TextStyle)
 */
void apply_ansi_codes(TextColor fg, BackgroundColor bg, TextStyle style);

/**
 * @brief Resetea todos los códigos ANSI (vuelve a valores por defecto)
 */
void reset_ansi_codes(void);

#ifdef __cplusplus
}
#endif

#endif // ANSI_CODES_H