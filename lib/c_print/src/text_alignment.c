/**
 * @file text_alignment.c
 * @brief Implementación de alineación de texto
 */

#include "text_alignment.h"
#include "string_utils.h"
#include <stdio.h>
#include <string.h>
#include <stdlib.h>

void print_aligned(const char* text, TextAlign align, int width, char fill_char) {
    if (!text) return;
    
    int text_len = strlen(text);
    
    // Si el texto es más largo que el ancho, imprimir sin padding
    if (text_len >= width) {
        printf("%s", text);
        return;
    }
    
    int padding = width - text_len;
    
    switch (align) {
        case ALIGN_LEFT:  // <
            printf("%s", text);
            for (int i = 0; i < padding; i++) {
                printf("%c", fill_char);
            }
            break;
            
        case ALIGN_RIGHT:  // >
            for (int i = 0; i < padding; i++) {
                printf("%c", fill_char);
            }
            printf("%s", text);
            break;
            
        case ALIGN_CENTER:  // ^
            {
                int left_pad = padding / 2;
                int right_pad = padding - left_pad;
                for (int i = 0; i < left_pad; i++) {
                    printf("%c", fill_char);
                }
                printf("%s", text);
                for (int i = 0; i < right_pad; i++) {
                    printf("%c", fill_char);
                }
            }
            break;
            
        default:
            printf("%s", text);
            break;
    }
}

bool is_alignment(const char* token, TextAlign* align, int* width, char* fill_char) {
    if (!token || strlen(token) < 2) return false;
    
    const char* ptr = token;
    *fill_char = ' ';  // Por defecto espacios
    
    // Verificar si hay un carácter de relleno al inicio
    // Formato: [fill_char]<>^[width]
    if (strlen(token) >= 3 && (token[1] == '<' || token[1] == '>' || token[1] == '^')) {
        *fill_char = token[0];
        ptr = token + 1;  // Saltar el carácter de relleno
    }
    
    // Verificar el tipo de alineación
    char first = ptr[0];
    if (first == '<' || first == '>' || first == '^') {
        // Verificar que después venga un número
        if (is_number(ptr + 1)) {
            *align = (TextAlign)first;
            *width = atoi(ptr + 1);
            return true;
        }
    }
    
    return false;
}