/**
 * @file c_print.c
 * @brief Implementación principal de c_print
 * 
 * Este módulo orquesta todos los submódulos para proporcionar
 * la funcionalidad completa de impresión con formato.
 */

#include "c_print.h"
#include "ansi_codes.h"
#include "color_parser.h"
#include "pattern_parser.h"
#include "number_formatter.h"
#include "text_alignment.h"
#include <stdlib.h>
#include <string.h>
#include <stdarg.h>

// ============================================================================
// FUNCIÓN PRINCIPAL: c_print con sistema de patrones
// ============================================================================

void c_print(const char* pattern, ...) {
    if (!pattern) return;    

    va_list args;
    va_start(args, pattern);  
    
    const char* p = pattern;
    
    while (*p) {
        // Buscar el inicio de un patrón
        if (*p == '{') {
            PatternStyle style;
            
            // Intentar parsear el patrón
            if (parse_pattern(p, &style)) {
                // Buffer para el valor formateado
                char value_buffer[1024];
                value_buffer[0] = '\0';
                
                // Formatear el valor según el tipo
                switch (style.format_type) {
                    case 's': {
                        char* str = va_arg(args, char*);                        
                        if (str) {                            
                            if (style.has_truncate && strlen(str) > (size_t)style.truncate) {
                                snprintf(value_buffer, sizeof(value_buffer), "%.*s", 
                                        style.truncate, str);
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
                        char ch = (char)va_arg(args, int);
                        snprintf(value_buffer, sizeof(value_buffer), "%c", ch);
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
                        snprintf(value_buffer, sizeof(value_buffer), "{?}");
                        break;
                }
                
                // Aplicar estilos ANSI
                if (style.has_color || style.has_bg || style.has_style) {
                    apply_ansi_codes(style.text_color, style.bg_color, style.style);
                }
                
                // Imprimir con o sin alineación
                if (style.has_alignment) {
                    print_aligned(value_buffer, style.align, style.width, style.fill_char);
                } else {
                    printf("%s", value_buffer);
                }
                
                // Resetear estilos
                if (style.has_color || style.has_bg || style.has_style) {
                    reset_ansi_codes();
                }
                
                // Avanzar hasta después del }
                while (*p && *p != '}') p++;
                if (*p == '}') p++;
                
            } else {
                // No es un patrón válido, imprimir literal
                putchar(*p);
                p++;
            }
        } else if (*p == '\\' && *(p + 1) == '{') {
            // Escape para {
            putchar('{');
            p += 2;
        } else {
            // Carácter normal
            putchar(*p);
            p++;
        }
    }
    
    va_end(args);
}

// ============================================================================
// API LEGACY: Funciones tradicionales
// ============================================================================

void c_print_styled(const char* text, TextColor fg, BackgroundColor bg, TextStyle style) {
    apply_ansi_codes(fg, bg, style);
    printf("%s", text);
    reset_ansi_codes();
}

void c_print_color(const char* text, TextColor fg) {
    c_print_styled(text, fg, BG_RESET, STYLE_RESET);
}

void c_print_bg(const char* text, BackgroundColor bg) {
    c_print_styled(text, COLOR_RESET, bg, STYLE_RESET);
}

void c_print_style(const char* text, TextStyle style) {
    c_print_styled(text, COLOR_RESET, BG_RESET, style);
}

void c_print_full(const char* text, PrintOptions opts) {
    c_print_styled(text, opts.text_color, opts.bg_color, opts.style);
}

void c_printf_styled(TextColor fg, BackgroundColor bg, TextStyle style, 
                     const char* format, ...) {
    apply_ansi_codes(fg, bg, style);
    
    va_list args;
    va_start(args, format);
    vprintf(format, args);
    va_end(args);
    
    reset_ansi_codes();
}