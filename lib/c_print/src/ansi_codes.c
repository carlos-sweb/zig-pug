/**
 * @file ansi_codes.c
 * @brief Implementación de gestión de códigos ANSI
 */

#include "ansi_codes.h"

void apply_ansi_codes(TextColor fg, BackgroundColor bg, TextStyle style) {
    printf("\033[");
    
    int first = 1;
    
    // Aplicar estilo si no es RESET
    if (style != STYLE_RESET) {
        printf("%d", style);
        first = 0;
    }
    
    // Aplicar color de texto si no es RESET
    if (fg != COLOR_RESET) {
        if (!first) printf(";");
        printf("%d", fg);
        first = 0;
    }
    
    // Aplicar color de fondo si no es RESET
    if (bg != BG_RESET) {
        if (!first) printf(";");
        printf("%d", bg);
    }
    
    printf("m");
}

void reset_ansi_codes(void) {
    printf("\033[0m");
}