/**
 * @file c_print_safe.c
 * @brief Versión mejorada de c_print con validación en runtime
 * 
 * Esta versión agrega verificaciones para detectar:
 * - Punteros NULL inesperados
 * - Valores sospechosos (punteros en rangos bajos)
 * - Conteo de patrones vs argumentos
 */

#include "c_print.h"
#include "pattern_parser.h"
#include "ansi_codes.h"
#include "number_formatter.h"
#include "text_alignment.h"
#include <stdlib.h>
#include <string.h>
#include <stdarg.h>
#include <stdbool.h>
#include <stdint.h>

// Macro para detectar si un puntero parece válido
#define IS_LIKELY_POINTER(ptr) ((uintptr_t)(ptr) > 0x1000)
#define IS_LIKELY_STRING(ptr) (IS_LIKELY_POINTER(ptr) && ((char*)(ptr))[0] != '\0')

// Modo debug (compilar con -DDEBUG_C_PRINT)
#ifdef DEBUG_C_PRINT
    #define DEBUG_LOG(fmt, ...) fprintf(stderr, "[c_print DEBUG] " fmt "\n", ##__VA_ARGS__)
#else
    #define DEBUG_LOG(fmt, ...) ((void)0)
#endif

/**
 * @brief Cuenta cuántos patrones {} hay en el string
 */
static int count_patterns(const char* pattern) {
    int count = 0;
    const char* p = pattern;
    
    while (*p) {
        if (*p == '{' && *(p + 1) != '\0') {
            // Verificar que no sea escape \{
            if (p == pattern || *(p - 1) != '\\') {
                count++;
            }
        }
        p++;
    }
    
    return count;
}

/**
 * @brief Valida si un puntero parece ser un string válido
 */
static bool validate_string_pointer(const void* ptr, const char* pattern_info) {
    if (ptr == NULL) {
        DEBUG_LOG("NULL pointer for pattern: %s", pattern_info);
        return false;
    }
    
    // Verificar que el puntero esté en un rango razonable
    uintptr_t addr = (uintptr_t)ptr;
    if (addr < 0x1000) {  // Valores muy bajos probablemente son ints interpretados como punteros
        DEBUG_LOG("Suspicious pointer value 0x%lx for pattern: %s", addr, pattern_info);
        return false;
    }
    
    return true;
}

/**
 * @brief Imprime un valor "seguro" cuando hay error de tipo
 */
static void print_error_value(const char* expected_type, uintptr_t raw_value) {
    printf("{?:");
    printf("%s", expected_type);
    printf(":error=0x%lx", raw_value);
    printf("}");
}

/**
 * @brief Versión segura de c_print con validaciones
 */
void c_print_safe(const char* pattern, ...) {
    if (!pattern) {
        fprintf(stderr, "[c_print ERROR] NULL pattern\n");
        return;
    }
    
    // Contar patrones para validación básica
    int expected_args = count_patterns(pattern);
    DEBUG_LOG("Pattern has %d placeholders", expected_args);
    
    va_list args;
    va_start(args, pattern);
    
    const char* p = pattern;
    int arg_index = 0;
    
    while (*p) {
        if (*p == '{') {
            PatternStyle style;
            
            if (parse_pattern(p, &style)) {
                char value_buffer[1024];
                value_buffer[0] = '\0';
                bool error = false;
                
                arg_index++;
                
                switch (style.format_type) {
                    case 's': {
                        // Obtener el valor crudo primero
                        void* raw_ptr = va_arg(args, void*);
                        
                        // Validar que parece un puntero válido
                        if (!validate_string_pointer(raw_ptr, "string")) {
                            // Intentar interpretar como número
                            uintptr_t num_value = (uintptr_t)raw_ptr;
                            if (num_value < 10000) {
                                // Probablemente pasaron un int en lugar de string
                                snprintf(value_buffer, sizeof(value_buffer), 
                                        "{? expected string, got int=%lu}", num_value);
                                error = true;
                            } else {
                                snprintf(value_buffer, sizeof(value_buffer), 
                                        "{? invalid pointer: 0x%lx}", num_value);
                                error = true;
                            }
                        } else {
                            char* str = (char*)raw_ptr;
                            if (style.has_truncate && strlen(str) > (size_t)style.truncate) {
                                snprintf(value_buffer, sizeof(value_buffer), 
                                        "%.*s", style.truncate, str);
                            } else {
                                snprintf(value_buffer, sizeof(value_buffer), "%s", str);
                            }
                        }
                        break;
                    }
                    
                    case 'd':
                    case 'i': {
                        int num = va_arg(args, int);
                        
                        if (style.has_separator) {
                            format_with_separator(value_buffer, sizeof(value_buffer), 
                                                 num, style.separator);
                        } else if (style.padding > 0 || style.show_sign) {
                            char fmt[20] = "%";
                            if (style.show_sign == 1) strcat(fmt, "+");
                            else if (style.show_sign == 2) strcat(fmt, " ");
                            if (style.zero_pad) strcat(fmt, "0");
                            if (style.padding > 0) {
                                char width[10];
                                snprintf(width, sizeof(width), "%d", style.padding);
                                strcat(fmt, width);
                            }
                            strcat(fmt, "d");
                            snprintf(value_buffer, sizeof(value_buffer), fmt, num);
                        } else {
                            snprintf(value_buffer, sizeof(value_buffer), "%d", num);
                        }
                        break;
                    }
                    
                    case 'f': {
                        double num = va_arg(args, double);
                        
                        if (style.as_percentage) {
                            num *= 100.0;
                            if (style.has_precision) {
                                snprintf(value_buffer, sizeof(value_buffer), 
                                        "%.*f%%", style.precision, num);
                            } else {
                                snprintf(value_buffer, sizeof(value_buffer), "%.1f%%", num);
                            }
                        } else if (style.has_precision) {
                            snprintf(value_buffer, sizeof(value_buffer), 
                                    "%.*f", style.precision, num);
                        } else {
                            snprintf(value_buffer, sizeof(value_buffer), "%f", num);
                        }
                        break;
                    }
                    
                    case 'c': {
                        int ch_val = va_arg(args, int);
                        // Validar rango de char
                        if (ch_val < 0 || ch_val > 127) {
                            snprintf(value_buffer, sizeof(value_buffer), 
                                    "{? invalid char: %d}", ch_val);
                            error = true;
                        } else {
                            snprintf(value_buffer, sizeof(value_buffer), "%c", (char)ch_val);
                        }
                        break;
                    }
                    
                    case 'b': {
                        unsigned int num = va_arg(args, unsigned int);
                        format_binary(value_buffer, sizeof(value_buffer), 
                                     num, style.show_prefix);
                        break;
                    }
                    
                    case 'x': {
                        unsigned int num = va_arg(args, unsigned int);
                        format_hex(value_buffer, sizeof(value_buffer), num, 
                                  style.show_prefix, style.padding, style.zero_pad);
                        break;
                    }
                    
                    case 'o': {
                        unsigned int num = va_arg(args, unsigned int);
                        format_octal(value_buffer, sizeof(value_buffer), 
                                    num, style.show_prefix);
                        break;
                    }
                    
                    case 'u': {
                        unsigned int num = va_arg(args, unsigned int);
                        if (style.has_separator) {
                            format_with_separator(value_buffer, sizeof(value_buffer), 
                                                 num, style.separator);
                        } else {
                            snprintf(value_buffer, sizeof(value_buffer), "%u", num);
                        }
                        break;
                    }
                    
                    case 'l': {
                        long num = va_arg(args, long);
                        if (style.has_separator) {
                            format_with_separator(value_buffer, sizeof(value_buffer), 
                                                 num, style.separator);
                        } else {
                            snprintf(value_buffer, sizeof(value_buffer), "%ld", num);
                        }
                        break;
                    }
                    
                    default:
                        snprintf(value_buffer, sizeof(value_buffer), 
                                "{? unknown format: %c}", style.format_type);
                        error = true;
                        break;
                }
                
                // Aplicar estilos solo si no hubo error
                if (!error && (style.has_color || style.has_bg || style.has_style)) {
                    apply_ansi_codes(style.text_color, style.bg_color, style.style);
                } else if (error) {
                    // Mostrar errores en rojo
                    apply_ansi_codes(COLOR_RED, BG_RESET, STYLE_BOLD);
                }
                
                // Imprimir con o sin alineación
                if (style.has_alignment) {
                    print_aligned(value_buffer, style.align, style.width, style.fill_char);
                } else {
                    printf("%s", value_buffer);
                }
                
                // Resetear estilos
                if ((style.has_color || style.has_bg || style.has_style) || error) {
                    reset_ansi_codes();
                }
                
                // Avanzar hasta después del }
                while (*p && *p != '}') p++;
                if (*p == '}') p++;
                
            } else {
                putchar(*p);
                p++;
            }
        } else if (*p == '\\' && *(p + 1) == '{') {
            putchar('{');
            p += 2;
        } else {
            putchar(*p);
            p++;
        }
    }
    
    va_end(args);
}