/**
 * @file c_print_builder.c
 * @brief Implementación del Builder Pattern para c_print
 */

#include "c_print_builder.h"
#include "ansi_codes.h"
#include "color_parser.h"
#include "number_formatter.h"
#include "text_alignment.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdbool.h>

// ============================================================================
// ESTRUCTURAS INTERNAS
// ============================================================================

#define INITIAL_BUFFER_SIZE 256
#define BUFFER_GROWTH_FACTOR 2

typedef struct {
    TextColor text_color;
    BackgroundColor bg_color;
    TextStyle style;
    int precision;
    int padding;
    bool zero_pad;
    char separator;
    bool show_prefix;
    bool show_sign;
    bool as_percentage;
    TextAlign align;
    int align_width;
    char fill_char;
} FormatOptions;

struct CPrintBuilder {
    char* buffer;           // Buffer dinámico
    size_t size;            // Tamaño actual del buffer
    size_t capacity;        // Capacidad del buffer
    FormatOptions pending;  // Opciones pendientes para el próximo elemento
    bool has_pending;       // Si hay opciones pendientes
};

// ============================================================================
// FUNCIONES AUXILIARES INTERNAS
// ============================================================================

/**
 * @brief Inicializa opciones por defecto
 */
static void init_format_options(FormatOptions* opts) {
    opts->text_color = COLOR_RESET;
    opts->bg_color = BG_RESET;
    opts->style = STYLE_RESET;
    opts->precision = 6;
    opts->padding = 0;
    opts->zero_pad = false;
    opts->separator = '\0';
    opts->show_prefix = false;
    opts->show_sign = false;
    opts->as_percentage = false;
    opts->align = ALIGN_NONE;
    opts->align_width = 0;
    opts->fill_char = ' ';
}

/**
 * @brief Asegura que el buffer tenga capacidad suficiente
 */
static void ensure_capacity(CPrintBuilder* b, size_t needed) {
    if (b->size + needed >= b->capacity) {
        size_t new_capacity = (b->capacity + needed) * BUFFER_GROWTH_FACTOR;
        char* new_buffer = realloc(b->buffer, new_capacity);
        if (!new_buffer) {
            fprintf(stderr, "[CPrintBuilder] Memory allocation failed\n");
            return;
        }
        b->buffer = new_buffer;
        b->capacity = new_capacity;
    }
}

/**
 * @brief Agrega texto al buffer
 */
static void append(CPrintBuilder* b, const char* text) {
    if (!text) return;
    
    size_t len = strlen(text);
    ensure_capacity(b, len + 1);
    
    memcpy(b->buffer + b->size, text, len);
    b->size += len;
    b->buffer[b->size] = '\0';
}

/**
 * @brief Aplica formato y agrega valor al buffer
 */
static void append_formatted(CPrintBuilder* b, const char* value) {
    if (!value) return;
    
    // Aplicar colores/estilos si están configurados
    bool has_styling = (b->pending.text_color != COLOR_RESET ||
                        b->pending.bg_color != BG_RESET ||
                        b->pending.style != STYLE_RESET);
    
    if (has_styling) {
        // Capturar códigos ANSI en un buffer temporal
        char ansi_codes[64];
        snprintf(ansi_codes, sizeof(ansi_codes), "\033[");
        
        int first = 1;
        if (b->pending.style != STYLE_RESET) {
            snprintf(ansi_codes + strlen(ansi_codes), 
                    sizeof(ansi_codes) - strlen(ansi_codes), 
                    "%d", b->pending.style);
            first = 0;
        }
        
        if (b->pending.text_color != COLOR_RESET) {
            if (!first) strcat(ansi_codes, ";");
            snprintf(ansi_codes + strlen(ansi_codes), 
                    sizeof(ansi_codes) - strlen(ansi_codes), 
                    "%d", b->pending.text_color);
            first = 0;
        }
        
        if (b->pending.bg_color != BG_RESET) {
            if (!first) strcat(ansi_codes, ";");
            snprintf(ansi_codes + strlen(ansi_codes), 
                    sizeof(ansi_codes) - strlen(ansi_codes), 
                    "%d", b->pending.bg_color);
        }
        
        strcat(ansi_codes, "m");
        append(b, ansi_codes);
    }
    
    // Aplicar alineación si está configurada
    if (b->pending.align != ALIGN_NONE && b->pending.align_width > 0) {
        int text_len = strlen(value);
        
        if (text_len < b->pending.align_width) {
            int padding = b->pending.align_width - text_len;
            
            switch (b->pending.align) {
                case ALIGN_LEFT:
                    append(b, value);
                    for (int i = 0; i < padding; i++) {
                        char ch[2] = {b->pending.fill_char, '\0'};
                        append(b, ch);
                    }
                    break;
                    
                case ALIGN_RIGHT:
                    for (int i = 0; i < padding; i++) {
                        char ch[2] = {b->pending.fill_char, '\0'};
                        append(b, ch);
                    }
                    append(b, value);
                    break;
                    
                case ALIGN_CENTER: {
                    int left_pad = padding / 2;
                    int right_pad = padding - left_pad;
                    for (int i = 0; i < left_pad; i++) {
                        char ch[2] = {b->pending.fill_char, '\0'};
                        append(b, ch);
                    }
                    append(b, value);
                    for (int i = 0; i < right_pad; i++) {
                        char ch[2] = {b->pending.fill_char, '\0'};
                        append(b, ch);
                    }
                    break;
                }
                    
                default:
                    append(b, value);
                    break;
            }
        } else {
            append(b, value);
        }
    } else {
        append(b, value);
    }
    
    // Resetear estilos si se aplicaron
    if (has_styling) {
        append(b, "\033[0m");
    }
    
    // Limpiar opciones pendientes
    init_format_options(&b->pending);
    b->has_pending = false;
}

// ============================================================================
// CREACIÓN Y DESTRUCCIÓN
// ============================================================================

CPrintBuilder* cp_new(void) {
    CPrintBuilder* b = malloc(sizeof(CPrintBuilder));
    if (!b) return NULL;
    
    b->buffer = malloc(INITIAL_BUFFER_SIZE);
    if (!b->buffer) {
        free(b);
        return NULL;
    }
    
    b->size = 0;
    b->capacity = INITIAL_BUFFER_SIZE;
    b->buffer[0] = '\0';
    b->has_pending = false;
    
    init_format_options(&b->pending);
    
    return b;
}

void cp_free(CPrintBuilder* builder) {
    if (!builder) return;
    
    if (builder->buffer) {
        free(builder->buffer);
    }
    free(builder);
}

void cp_reset(CPrintBuilder* builder) {
    if (!builder) return;
    
    builder->size = 0;
    builder->buffer[0] = '\0';
    builder->has_pending = false;
    init_format_options(&builder->pending);
}

// ============================================================================
// CONFIGURACIÓN DE FORMATO
// ============================================================================

CPrintBuilder* cp_color(CPrintBuilder* b, TextColor color) {
    if (!b) return NULL;
    b->pending.text_color = color;
    b->has_pending = true;
    return b;
}

CPrintBuilder* cp_color_str(CPrintBuilder* b, const char* color_name) {
    if (!b) return NULL;
    b->pending.text_color = parse_text_color(color_name);
    b->has_pending = true;
    return b;
}

CPrintBuilder* cp_bg(CPrintBuilder* b, BackgroundColor color) {
    if (!b) return NULL;
    b->pending.bg_color = color;
    b->has_pending = true;
    return b;
}

CPrintBuilder* cp_bg_str(CPrintBuilder* b, const char* color_name) {
    if (!b) return NULL;
    b->pending.bg_color = parse_bg_color(color_name);
    b->has_pending = true;
    return b;
}

CPrintBuilder* cp_style(CPrintBuilder* b, TextStyle style) {
    if (!b) return NULL;
    b->pending.style = style;
    b->has_pending = true;
    return b;
}

CPrintBuilder* cp_style_str(CPrintBuilder* b, const char* style_name) {
    if (!b) return NULL;
    b->pending.style = parse_text_style(style_name);
    b->has_pending = true;
    return b;
}

CPrintBuilder* cp_precision(CPrintBuilder* b, int precision) {
    if (!b) return NULL;
    b->pending.precision = precision;
    b->has_pending = true;
    return b;
}

CPrintBuilder* cp_zero_pad(CPrintBuilder* b, int width) {
    if (!b) return NULL;
    b->pending.padding = width;
    b->pending.zero_pad = true;
    b->has_pending = true;
    return b;
}

CPrintBuilder* cp_pad(CPrintBuilder* b, int width) {
    if (!b) return NULL;
    b->pending.padding = width;
    b->pending.zero_pad = false;
    b->has_pending = true;
    return b;
}

CPrintBuilder* cp_separator(CPrintBuilder* b, char sep) {
    if (!b) return NULL;
    b->pending.separator = sep;
    b->has_pending = true;
    return b;
}

CPrintBuilder* cp_show_prefix(CPrintBuilder* b, bool show) {
    if (!b) return NULL;
    b->pending.show_prefix = show;
    b->has_pending = true;
    return b;
}

CPrintBuilder* cp_show_sign(CPrintBuilder* b, bool show) {
    if (!b) return NULL;
    b->pending.show_sign = show;
    b->has_pending = true;
    return b;
}

CPrintBuilder* cp_as_percentage(CPrintBuilder* b, bool show) {
    if (!b) return NULL;
    b->pending.as_percentage = show;
    b->has_pending = true;
    return b;
}

CPrintBuilder* cp_align_left(CPrintBuilder* b, int width) {
    if (!b) return NULL;
    b->pending.align = ALIGN_LEFT;
    b->pending.align_width = width;
    b->has_pending = true;
    return b;
}

CPrintBuilder* cp_align_right(CPrintBuilder* b, int width) {
    if (!b) return NULL;
    b->pending.align = ALIGN_RIGHT;
    b->pending.align_width = width;
    b->has_pending = true;
    return b;
}

CPrintBuilder* cp_align_center(CPrintBuilder* b, int width) {
    if (!b) return NULL;
    b->pending.align = ALIGN_CENTER;
    b->pending.align_width = width;
    b->has_pending = true;
    return b;
}

CPrintBuilder* cp_fill_char(CPrintBuilder* b, char ch) {
    if (!b) return NULL;
    b->pending.fill_char = ch;
    b->has_pending = true;
    return b;
}

// ============================================================================
// AGREGAR CONTENIDO (TYPE-SAFE)
// ============================================================================

CPrintBuilder* cp_text(CPrintBuilder* b, const char* text) {
    if (!b || !text) return b;
    append(b, text);
    return b;
}

CPrintBuilder* cp_str(CPrintBuilder* b, const char* str) {
    if (!b || !str) return b;
    
    // Si el string está vacío, no agregar nada
    if (str[0] == '\0') {
        return b;
    }
    
    append_formatted(b, str);
    return b;
}

CPrintBuilder* cp_int(CPrintBuilder* b, int value) {
    if (!b) return NULL;
    
    char buffer[256];
    
    if (b->pending.separator != '\0') {
        format_with_separator(buffer, sizeof(buffer), value, b->pending.separator);
    } else if (b->pending.padding > 0) {
        char fmt[32] = "%";
        if (b->pending.show_sign) strcat(fmt, "+");
        if (b->pending.zero_pad) strcat(fmt, "0");
        char width_str[16];
        snprintf(width_str, sizeof(width_str), "%d", b->pending.padding);
        strcat(fmt, width_str);
        strcat(fmt, "d");
        snprintf(buffer, sizeof(buffer), fmt, value);
    } else {
        snprintf(buffer, sizeof(buffer), "%d", value);
    }
    
    append_formatted(b, buffer);
    return b;
}

CPrintBuilder* cp_uint(CPrintBuilder* b, unsigned int value) {
    if (!b) return NULL;
    
    char buffer[256];
    
    if (b->pending.separator != '\0') {
        format_with_separator(buffer, sizeof(buffer), value, b->pending.separator);
    } else {
        snprintf(buffer, sizeof(buffer), "%u", value);
    }
    
    append_formatted(b, buffer);
    return b;
}

CPrintBuilder* cp_long(CPrintBuilder* b, long value) {
    if (!b) return NULL;
    
    char buffer[256];
    
    if (b->pending.separator != '\0') {
        format_with_separator(buffer, sizeof(buffer), value, b->pending.separator);
    } else {
        snprintf(buffer, sizeof(buffer), "%ld", value);
    }
    
    append_formatted(b, buffer);
    return b;
}

CPrintBuilder* cp_float(CPrintBuilder* b, double value) {
    if (!b) return NULL;
    
    char buffer[256];
    
    if (b->pending.as_percentage) {
        value *= 100.0;
        snprintf(buffer, sizeof(buffer), "%.*f%%", b->pending.precision, value);
    } else {
        snprintf(buffer, sizeof(buffer), "%.*f", b->pending.precision, value);
    }
    
    append_formatted(b, buffer);
    return b;
}

CPrintBuilder* cp_char(CPrintBuilder* b, char value) {
    if (!b) return NULL;
    
    char buffer[2] = {value, '\0'};
    append_formatted(b, buffer);
    return b;
}

CPrintBuilder* cp_bool(CPrintBuilder* b, bool value) {
    if (!b) return NULL;
    append_formatted(b, value ? "true" : "false");
    return b;
}

CPrintBuilder* cp_binary(CPrintBuilder* b, unsigned int value) {
    if (!b) return NULL;
    
    char buffer[256];
    format_binary(buffer, sizeof(buffer), value, b->pending.show_prefix);
    append_formatted(b, buffer);
    return b;
}

CPrintBuilder* cp_hex(CPrintBuilder* b, unsigned int value) {
    if (!b) return NULL;
    
    char buffer[256];
    format_hex(buffer, sizeof(buffer), value, 
              b->pending.show_prefix, b->pending.padding, b->pending.zero_pad);
    append_formatted(b, buffer);
    return b;
}

CPrintBuilder* cp_octal(CPrintBuilder* b, unsigned int value) {
    if (!b) return NULL;
    
    char buffer[256];
    format_octal(buffer, sizeof(buffer), value, b->pending.show_prefix);
    append_formatted(b, buffer);
    return b;
}

// ============================================================================
// IMPRESIÓN
// ============================================================================

void cp_print(CPrintBuilder* b) {
    if (!b || !b->buffer) return;
    printf("%s", b->buffer);
}

void cp_println(CPrintBuilder* b) {
    if (!b || !b->buffer) return;
    printf("%s\n", b->buffer);
}

char* cp_to_string(CPrintBuilder* b) {
    if (!b || !b->buffer) return NULL;
    
    char* result = malloc(b->size + 1);
    if (!result) return NULL;
    
    memcpy(result, b->buffer, b->size + 1);
    return result;
}

// ============================================================================
// UTILIDADES
// ============================================================================

size_t cp_size(const CPrintBuilder* b) {
    return b ? b->size : 0;
}

bool cp_is_empty(const CPrintBuilder* b) {
    return b ? (b->size == 0) : true;
}