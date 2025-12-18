/**
 * @file string_utils.c
 * @brief Implementación de utilidades para manipulación de strings
 */

#include "string_utils.h"
#include <ctype.h>
#include <string.h>
#include <stdlib.h>

void to_lowercase(char* str) {
    if (!str) return;
    
    for (int i = 0; str[i]; i++) {
        str[i] = tolower((unsigned char)str[i]);
    }
}

bool is_number(const char* str) {
    if (!str || *str == '\0') return false;
    
    while (*str) {
        if (!isdigit((unsigned char)*str)) return false;
        str++;
    }
    return true;
}

void trim_whitespace(char* str) {
    if (!str) return;
    
    // Eliminar espacios al inicio
    char* start = str;
    while (*start == ' ' || *start == '\t' || *start == '\n' || *start == '\r') {
        start++;
    }
    
    // Si todo son espacios
    if (*start == '\0') {
        *str = '\0';
        return;
    }
    
    // Mover contenido al inicio
    if (start != str) {
        memmove(str, start, strlen(start) + 1);
    }
    
    // Eliminar espacios al final
    char* end = str + strlen(str) - 1;
    while (end > str && (*end == ' ' || *end == '\t' || *end == '\n' || *end == '\r')) {
        *end = '\0';
        end--;
    }
}