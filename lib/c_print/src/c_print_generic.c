/**
 * @file c_print_generic.c
 * @brief Implementación de la validación _Generic para c_print
 */

#include "c_print_generic.h"

#if __STDC_VERSION__ >= 201112L

#include "pattern_parser.h"
#include "ansi_codes.h"
#include "number_formatter.h"
#include "text_alignment.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdarg.h>

// ============================================================================
// EXTRACCIÓN DE ESPECIFICADORES DE FORMATO
// ============================================================================

/**
 * @brief Extrae los especificadores de formato del patrón
 */
static int extract_format_specs(const char* pattern, char specs[], int max_specs) {
    if (!pattern) return 0;
    
    int count = 0;
    const char* p = pattern;
    
    while (*p && count < max_specs) {
        if (*p == '{' && *(p + 1) != '\0') {
            // Verificar que no sea escape \{
            if (p == pattern || *(p - 1) != '\\') {
                // Encontrar el tipo de formato (primer carácter después de {)
                const char* start = p + 1;
                while (*start == ' ') start++;  // Skip whitespace
                
                if (*start && *start != '}') {
                    specs[count++] = *start;
                }
            }
        }
        p++;
    }
    
    return count;
}

// ============================================================================
// VALIDACIÓN DE PATRONES
// ============================================================================

bool c_print_validate_pattern(const char* pattern, int argc, ...) {
    if (!pattern) return false;
    
    // Extraer especificadores del patrón
    char specs[C_PRINT_MAX_ARGS];
    int expected_count = extract_format_specs(pattern, specs, C_PRINT_MAX_ARGS);
    
    // Verificar cantidad de argumentos
    if (argc != expected_count) {
        fprintf(stderr, "[C_PRINT ERROR] Argument count mismatch: expected %d, got %d\n",
                expected_count, argc);
        return false;
    }
    
    // Validar tipos
    va_list args;
    va_start(args, argc);
    
    bool valid = true;
    for (int i = 0; i < argc; i++) {
        CPrintArg arg = va_arg(args, CPrintArg);
        
        if (!cprint_validate_arg_type(specs[i], arg.type)) {
            fprintf(stderr, "[C_PRINT ERROR] Type mismatch at argument %d:\n", i);
            fprintf(stderr, "  Pattern: {%c:...}\n", specs[i]);
            fprintf(stderr, "  Expected: %s\n", cprint_expected_type_name(specs[i]));
            fprintf(stderr, "  Got: %s\n", cprint_type_name(arg.type));
            valid = false;
        }
    }
    
    va_end(args);
    return valid;
}

// ============================================================================
// DEBUG DE TIPOS
// ============================================================================

void c_print_debug_types_impl(const char* pattern, int argc, ...) {
    printf("[C_PRINT DEBUG] Pattern: %s\n", pattern);
    printf("[C_PRINT DEBUG] Argument count: %d\n", argc);
    
    va_list args;
    va_start(args, argc);
    
    for (int i = 0; i < argc; i++) {
        CPrintArg arg = va_arg(args, CPrintArg);
        
        printf("[C_PRINT DEBUG] Arg %d: %s = ", i, cprint_type_name(arg.type));
        
        switch (arg.type) {
            case CPRINT_ARG_STRING:
                printf("\"%s\"\n", arg.value.s ? arg.value.s : "(null)");
                break;
            case CPRINT_ARG_INT:
                printf("%d\n", arg.value.i);
                break;
            case CPRINT_ARG_UINT:
                printf("%u\n", arg.value.u);
                break;
            case CPRINT_ARG_LONG:
                printf("%ld\n", arg.value.l);
                break;
            case CPRINT_ARG_ULONG:
                printf("%lu\n", arg.value.ul);
                break;
            case CPRINT_ARG_DOUBLE:
                printf("%f\n", arg.value.d);
                break;
            case CPRINT_ARG_CHAR:
                printf("'%c'\n", arg.value.c);
                break;
            case CPRINT_ARG_BOOL:
                printf("%s\n", arg.value.b ? "true" : "false");
                break;
            case CPRINT_ARG_PTR:
                printf("%p\n", arg.value.ptr);
                break;
            default:
                printf("(unknown)\n");
                break;
        }
    }
    
    va_end(args);
}

// ============================================================================
// WRAPPER PRINCIPAL CON VALIDACIÓN
// ============================================================================

void c_print_checked_wrapper(const char* pattern, int argc, ...) {
    if (!pattern) return;
    
    // Extraer especificadores
    char specs[C_PRINT_MAX_ARGS];
    int expected_count = extract_format_specs(pattern, specs, C_PRINT_MAX_ARGS);
    
    // Validar cantidad de argumentos (warning si no coincide)
    if (argc != expected_count) {
        fprintf(stderr, "[C_PRINT WARNING] Expected %d args, got %d\n", 
                expected_count, argc);
    }
    
    // Obtener argumentos
    va_list args;
    va_start(args, argc);
    
    CPrintArg typed_args[C_PRINT_MAX_ARGS];
    for (int i = 0; i < argc && i < C_PRINT_MAX_ARGS; i++) {
        typed_args[i] = va_arg(args, CPrintArg);
    }
    va_end(args);
    
    // Validar y procesar
    const char* p = pattern;
    int arg_index = 0;
    
    while (*p) {
        if (*p == '{') {
            PatternStyle style;
            
            if (parse_pattern(p, &style)) {
                char value_buffer[1024];
                value_buffer[0] = '\0';
                bool error = false;
                
                // Verificar que no nos pasemos de argumentos
                if (arg_index >= argc) {
                    snprintf(value_buffer, sizeof(value_buffer), 
                            "{? missing argument for '%c'}", style.format_type);
                    error = true;
                } else {
                    CPrintArg arg = typed_args[arg_index];
                    
                    // Validar tipo
                    if (!cprint_validate_arg_type(style.format_type, arg.type)) {
                        snprintf(value_buffer, sizeof(value_buffer),
                                "{? expected %s, got %s}",
                                cprint_expected_type_name(style.format_type),
                                cprint_type_name(arg.type));
                        error = true;
                    } else {
                        // Formatear según el tipo
                        switch (style.format_type) {
                            case 's':
                                if (arg.value.s) {
                                    snprintf(value_buffer, sizeof(value_buffer), 
                                            "%s", arg.value.s);
                                }
                                break;
                                
                            case 'd':
                            case 'i':
                                if (style.has_separator) {
                                    format_with_separator(value_buffer, sizeof(value_buffer),
                                                         arg.value.i, style.separator);
                                } else if (style.padding > 0) {
                                    char fmt[32] = "%";
                                    if (style.show_sign) strcat(fmt, "+");
                                    if (style.zero_pad) strcat(fmt, "0");
                                    char width[16];
                                    snprintf(width, sizeof(width), "%d", style.padding);
                                    strcat(fmt, width);
                                    strcat(fmt, "d");
                                    snprintf(value_buffer, sizeof(value_buffer), fmt, arg.value.i);
                                } else {
                                    snprintf(value_buffer, sizeof(value_buffer), 
                                            "%d", arg.value.i);
                                }
                                break;
                                
                            case 'f':
                                if (style.as_percentage) {
                                    double val = arg.value.d * 100.0;
                                    snprintf(value_buffer, sizeof(value_buffer),
                                            "%.*f%%", style.precision, val);
                                } else if (style.has_precision) {
                                    snprintf(value_buffer, sizeof(value_buffer),
                                            "%.*f", style.precision, arg.value.d);
                                } else {
                                    snprintf(value_buffer, sizeof(value_buffer),
                                            "%f", arg.value.d);
                                }
                                break;
                                
                            case 'c':
                                snprintf(value_buffer, sizeof(value_buffer), 
                                        "%c", arg.value.c);
                                break;
                                
                            case 'b':
                                format_binary(value_buffer, sizeof(value_buffer),
                                             arg.value.u, style.show_prefix);
                                break;
                                
                            case 'x':
                                format_hex(value_buffer, sizeof(value_buffer), arg.value.u,
                                          style.show_prefix, style.padding, style.zero_pad);
                                break;
                                
                            case 'o':
                                format_octal(value_buffer, sizeof(value_buffer),
                                            arg.value.u, style.show_prefix);
                                break;
                                
                            case 'u':
                                if (style.has_separator) {
                                    format_with_separator(value_buffer, sizeof(value_buffer),
                                                         arg.value.u, style.separator);
                                } else {
                                    snprintf(value_buffer, sizeof(value_buffer),
                                            "%u", arg.value.u);
                                }
                                break;
                                
                            case 'l':
                                if (style.has_separator) {
                                    format_with_separator(value_buffer, sizeof(value_buffer),
                                                         arg.value.l, style.separator);
                                } else {
                                    snprintf(value_buffer, sizeof(value_buffer),
                                            "%ld", arg.value.l);
                                }
                                break;
                                
                            default:
                                snprintf(value_buffer, sizeof(value_buffer),
                                        "{? unknown format: %c}", style.format_type);
                                error = true;
                                break;
                        }
                    }
                    
                    arg_index++;
                }
                
                // Aplicar estilos
                if (!error && (style.has_color || style.has_bg || style.has_style)) {
                    apply_ansi_codes(style.text_color, style.bg_color, style.style);
                } else if (error) {
                    apply_ansi_codes(COLOR_RED, BG_RESET, STYLE_BOLD);
                }
                
                // Imprimir
                if (style.has_alignment) {
                    print_aligned(value_buffer, style.align, style.width, style.fill_char);
                } else {
                    printf("%s", value_buffer);
                }
                
                // Resetear estilos
                if ((style.has_color || style.has_bg || style.has_style) || error) {
                    reset_ansi_codes();
                }
                
                // Avanzar
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
}

// ============================================================================
// FUNCIÓN c_print_checked (interfaz simple)
// ============================================================================

void c_print_checked(const char* pattern, ...) {
    if (!pattern) return;
    
    // Contar argumentos esperados
    char specs[C_PRINT_MAX_ARGS];
    int expected = extract_format_specs(pattern, specs, C_PRINT_MAX_ARGS);
    
    // Esta función es un placeholder - la validación real está en C_PRINT() macro
    (void)expected;  // Suprimir warning
    
    // Procesar con validación básica
    va_list args;
    va_start(args, pattern);
    
    // Llamar a la implementación original (sin validación estricta de tipos)
    // ya que no podemos acceder a CPrintArg desde va_list directo
    vprintf(pattern, args);
    
    va_end(args);
}

#endif // __STDC_VERSION__ >= 201112L