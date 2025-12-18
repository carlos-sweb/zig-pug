/**
 * @file pattern_parser.c
 * @brief Implementación del parseo de patrones
 */

#include "pattern_parser.h"
#include "color_parser.h"
#include "string_utils.h"
#include <string.h>
#include <stdlib.h>
#include <ctype.h>

bool is_format_modifier(const char* token, PatternStyle* style) {
    if (!token || strlen(token) == 0) return false;
    
    const char* ptr = token;
    
    // Detectar precisión (.2, .4, etc.)
    if (*ptr == '.' && isdigit(*(ptr + 1))) {
        style->precision = atoi(ptr + 1);
        style->has_precision = 1;
        return true;
    }
    
    // Detectar padding con ceros (05, 08, etc.)
    if (*ptr == '0' && isdigit(*(ptr + 1))) {
        style->padding = atoi(ptr + 1);
        style->zero_pad = 1;
        return true;
    }
    
    // Detectar padding normal (solo número sin 0 al inicio)
    if (isdigit(*ptr) && *ptr != '0') {
        style->padding = atoi(ptr);
        style->zero_pad = 0;
        return true;
    }
    
    // Detectar separador de miles
    if (strcmp(token, ",") == 0) {
        style->separator = ',';
        style->has_separator = 1;
        return true;
    }
    if (strcmp(token, "_") == 0) {
        style->separator = '_';
        style->has_separator = 1;
        return true;
    }
    
    // Detectar prefijo (#)
    if (strcmp(token, "#") == 0) {
        style->show_prefix = 1;
        return true;
    }
    
    // Detectar signo (+)
    if (strcmp(token, "+") == 0) {
        style->show_sign = 1;
        return true;
    }
    
    // Detectar espacio para signo ( )
    if (strcmp(token, " ") == 0) {
        style->show_sign = 2;  // 2 = espacio
        return true;
    }
    
    // Detectar porcentaje (%)
    if (strcmp(token, "%") == 0) {
        style->as_percentage = 1;
        return true;
    }
    
    return false;
}

bool parse_pattern(const char* pattern, PatternStyle* style) {
    if (!pattern || pattern[0] != '{') return false;
    
    // Encontrar el cierre
    const char* end = strchr(pattern, '}');
    if (!end) return false;
    
    // Copiar el contenido entre {}
    int len = end - pattern - 1;
    if (len <= 0 || len >= 200) return false;
    
    char buffer[200];
    strncpy(buffer, pattern + 1, len);
    buffer[len] = '\0';
    
    // Inicializar estructura con valores por defecto
    memset(style, 0, sizeof(PatternStyle));
    style->format_type = '\0';
    style->text_color = COLOR_RESET;
    style->bg_color = BG_RESET;
    style->style = STYLE_RESET;
    style->align = ALIGN_NONE;
    style->fill_char = ' ';
    style->precision = 6;  // Precisión por defecto para floats
    
    // Dividir por ':' y procesar tokens
    char* saveptr;
    char* token = strtok_r(buffer, ":", &saveptr);
    int part = 0;
    
    while (token != NULL) {
        if (strlen(token) > 0) {
            if (part == 0) {
                // Primera parte: tipo de formato
                while (*token == ' ') token++;
                style->format_type = token[0];
            } else {
                // Resto de partes: especificadores
                // Hacer trim de espacios
                while (*token == ' ') token++;
                char* end_token = token + strlen(token) - 1;
                while (end_token > token && *end_token == ' ') {
                    *end_token = '\0';
                    end_token--;
                }
                
                // Intentar detectar qué tipo de especificador es
                TextAlign align;
                int width;
                char fill_char;
                
                // ¿Es alineación?
                if (is_alignment(token, &align, &width, &fill_char)) {
                    style->align = align;
                    style->width = width;
                    style->fill_char = fill_char;
                    style->has_alignment = 1;
                }
                // ¿Es modificador de formato?
                else if (is_format_modifier(token, style)) {
                    // Ya se procesó
                }
                // ¿Es color de fondo?
                else if (is_background_color(token)) {
                    style->bg_color = parse_bg_color(token);
                    style->has_bg = 1;
                }
                // ¿Es un estilo?
                else {
                    TextStyle parsed_style = parse_text_style(token);
                    if (parsed_style != STYLE_RESET) {
                        style->style = parsed_style;
                        style->has_style = 1;
                    } else {
                        // Debe ser un color de texto
                        TextColor parsed_color = parse_text_color(token);
                        if (parsed_color != COLOR_RESET) {
                            style->text_color = parsed_color;
                            style->has_color = 1;
                        }
                    }
                }
            }
        }
        
        token = strtok_r(NULL, ":", &saveptr);
        part++;
    }
    
    return style->format_type != '\0';
}