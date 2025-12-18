/**
 * @file color_parser.c
 * @brief Implementación del parseo de colores y estilos
 */

#include "color_parser.h"
#include "string_utils.h"
#include <string.h>
#include <stdlib.h>

TextColor parse_text_color(const char* color) {
    if (!color || strlen(color) == 0) return COLOR_RESET;
    
    char temp[50];
    strncpy(temp, color, sizeof(temp) - 1);
    temp[sizeof(temp) - 1] = '\0';
    to_lowercase(temp);
    
    // Colores estándar
    if (strcmp(temp, "black") == 0) return COLOR_BLACK;
    if (strcmp(temp, "red") == 0) return COLOR_RED;
    if (strcmp(temp, "green") == 0) return COLOR_GREEN;
    if (strcmp(temp, "yellow") == 0) return COLOR_YELLOW;
    if (strcmp(temp, "blue") == 0) return COLOR_BLUE;
    if (strcmp(temp, "magenta") == 0) return COLOR_MAGENTA;
    if (strcmp(temp, "cyan") == 0) return COLOR_CYAN;
    if (strcmp(temp, "white") == 0) return COLOR_WHITE;
    
    // Colores brillantes
    if (strcmp(temp, "bright_black") == 0) return COLOR_BRIGHT_BLACK;
    if (strcmp(temp, "bright_red") == 0) return COLOR_BRIGHT_RED;
    if (strcmp(temp, "bright_green") == 0) return COLOR_BRIGHT_GREEN;
    if (strcmp(temp, "bright_yellow") == 0) return COLOR_BRIGHT_YELLOW;
    if (strcmp(temp, "bright_blue") == 0) return COLOR_BRIGHT_BLUE;
    if (strcmp(temp, "bright_magenta") == 0) return COLOR_BRIGHT_MAGENTA;
    if (strcmp(temp, "bright_cyan") == 0) return COLOR_BRIGHT_CYAN;
    if (strcmp(temp, "bright_white") == 0) return COLOR_BRIGHT_WHITE;
    
    return COLOR_RESET;
}

BackgroundColor parse_bg_color(const char* color) {
    if (!color || strlen(color) == 0) return BG_RESET;
    
    char temp[50];
    strncpy(temp, color, sizeof(temp) - 1);
    temp[sizeof(temp) - 1] = '\0';
    to_lowercase(temp);
    
    // Remover prefijo "bg_" si existe
    const char* color_name = temp;
    if (strncmp(temp, "bg_", 3) == 0) {
        color_name = temp + 3;
    }
    
    // Colores estándar
    if (strcmp(color_name, "black") == 0) return BG_BLACK;
    if (strcmp(color_name, "red") == 0) return BG_RED;
    if (strcmp(color_name, "green") == 0) return BG_GREEN;
    if (strcmp(color_name, "yellow") == 0) return BG_YELLOW;
    if (strcmp(color_name, "blue") == 0) return BG_BLUE;
    if (strcmp(color_name, "magenta") == 0) return BG_MAGENTA;
    if (strcmp(color_name, "cyan") == 0) return BG_CYAN;
    if (strcmp(color_name, "white") == 0) return BG_WHITE;
    
    // Colores brillantes
    if (strcmp(color_name, "bright_black") == 0) return BG_BRIGHT_BLACK;
    if (strcmp(color_name, "bright_red") == 0) return BG_BRIGHT_RED;
    if (strcmp(color_name, "bright_green") == 0) return BG_BRIGHT_GREEN;
    if (strcmp(color_name, "bright_yellow") == 0) return BG_BRIGHT_YELLOW;
    if (strcmp(color_name, "bright_blue") == 0) return BG_BRIGHT_BLUE;
    if (strcmp(color_name, "bright_magenta") == 0) return BG_BRIGHT_MAGENTA;
    if (strcmp(color_name, "bright_cyan") == 0) return BG_BRIGHT_CYAN;
    if (strcmp(color_name, "bright_white") == 0) return BG_BRIGHT_WHITE;
    
    return BG_RESET;
}

TextStyle parse_text_style(const char* style) {
    if (!style || strlen(style) == 0) return STYLE_RESET;
    
    char temp[50];
    strncpy(temp, style, sizeof(temp) - 1);
    temp[sizeof(temp) - 1] = '\0';
    to_lowercase(temp);
    
    if (strcmp(temp, "bold") == 0) return STYLE_BOLD;
    if (strcmp(temp, "dim") == 0) return STYLE_DIM;
    if (strcmp(temp, "italic") == 0) return STYLE_ITALIC;
    if (strcmp(temp, "underline") == 0) return STYLE_UNDERLINE;
    if (strcmp(temp, "blink") == 0) return STYLE_BLINK;
    if (strcmp(temp, "reverse") == 0) return STYLE_REVERSE;
    if (strcmp(temp, "hidden") == 0) return STYLE_HIDDEN;
    if (strcmp(temp, "strikethrough") == 0) return STYLE_STRIKETHROUGH;
    
    return STYLE_RESET;
}

bool is_background_color(const char* token) {
    if (!token) return false;
    
    char temp[50];
    strncpy(temp, token, sizeof(temp) - 1);
    temp[sizeof(temp) - 1] = '\0';
    to_lowercase(temp);
    
    return strncmp(temp, "bg_", 3) == 0;
}