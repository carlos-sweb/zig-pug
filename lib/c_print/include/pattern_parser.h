/**
 * @file pattern_parser.h
 * @brief Parseo de patrones de formato {type:spec1:spec2:...}
 * 
 * Este módulo analiza patrones como {s:red:bold:>20} y extrae
 * toda la información de formato (tipo, colores, estilos, alineación, etc.)
 */

#ifndef PATTERN_PARSER_H
#define PATTERN_PARSER_H

#include "ansi_codes.h"
#include "text_alignment.h"
#include <stdbool.h>

#ifdef __cplusplus
extern "C" {
#endif

/**
 * @brief Estructura que contiene todas las especificaciones de un patrón
 */
typedef struct {
    // Tipo de formato básico
    char format_type;           // 's', 'd', 'f', 'b', 'x', 'o', 'u', 'l', 'c'
    
    // Colores y estilos
    TextColor text_color;
    BackgroundColor bg_color;
    TextStyle style;
    int has_color;
    int has_bg;
    int has_style;
    
    // Alineación
    TextAlign align;
    int width;
    int has_alignment;
    char fill_char;
    
    // Modificadores numéricos
    int precision;              // Precisión para floats (.2, .4)
    int has_precision;
    int padding;                // Ancho de padding (05, 10)
    int zero_pad;               // Si es padding con ceros
    char separator;             // Separador de miles (',' o '_')
    int has_separator;
    int show_prefix;            // Mostrar prefijo (0b, 0x, 0o)
    int show_sign;              // Mostrar signo (+, espacio)
    int truncate;               // Truncar strings
    int has_truncate;
    int as_percentage;          // Mostrar como porcentaje
} PatternStyle;

/**
 * @brief Parsea un patrón completo {type:spec1:spec2:...}
 * @param pattern String con el patrón completo (incluyendo {})
 * @param style [out] Estructura donde se guardan las especificaciones
 * @return true si el parseo fue exitoso, false en caso contrario
 * 
 * Ejemplo:
 * - parse_pattern("{s:red:bold:>20}", &style)
 * - parse_pattern("{d:05:,}", &style)
 * - parse_pattern("{f:.2:green:bg_white}", &style)
 */
bool parse_pattern(const char* pattern, PatternStyle* style);

/**
 * @brief Detecta si un token es un modificador de formato numérico
 * @param token String a analizar
 * @param style [in/out] Estructura donde se guardan los modificadores
 * @return true si se detectó un modificador válido
 * 
 * Modificadores soportados:
 * - ".2", ".4"  → precisión decimal
 * - "05", "08"  → padding con ceros
 * - "5", "10"   → padding con espacios
 * - ","         → separador de miles (coma)
 * - "_"         → separador de miles (guión bajo)
 * - "#"         → mostrar prefijo (0b, 0x, 0o)
 * - "+"         → mostrar signo siempre
 * - " "         → reservar espacio para signo
 * - "%"         → mostrar como porcentaje
 */
bool is_format_modifier(const char* token, PatternStyle* style);

#ifdef __cplusplus
}
#endif

#endif // PATTERN_PARSER_H