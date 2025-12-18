/**
 * @file number_formatter.c
 * @brief Implementación del formateo avanzado de números
 */

#include "number_formatter.h"
#include <stdio.h>
#include <string.h>

void format_with_separator(char* buffer, size_t size, long long num, char separator) {
    char temp[100];
    snprintf(temp, sizeof(temp), "%lld", num);
    
    int len = strlen(temp);
    int negative = (temp[0] == '-') ? 1 : 0;
    int digits = len - negative;
    int commas = (digits - 1) / 3;
    int total = len + commas;
    
    // Si no cabe en el buffer, copiar sin formato
    if (total >= (int)size) {
        strncpy(buffer, temp, size - 1);
        buffer[size - 1] = '\0';
        return;
    }
    
    // Insertar separadores desde el final
    int src = len - 1;
    int dst = total;
    buffer[dst--] = '\0';
    
    int count = 0;
    while (src >= negative) {
        if (count == 3) {
            buffer[dst--] = separator;
            count = 0;
        }
        buffer[dst--] = temp[src--];
        count++;
    }
    
    // Copiar signo negativo si existe
    if (negative) {
        buffer[0] = '-';
    }
}

void format_binary(char* buffer, size_t size, unsigned long long num, int show_prefix) {
    // Validar que el buffer sea válido
    if (!buffer || size == 0) {
        return;
    }
    
    // Necesitamos al menos 2 bytes (1 char + null terminator)
    if (size < 2) {
        buffer[0] = '\0';
        return;
    }
    
    char temp[100];
    int idx = 0;
    
    // Caso especial: cero
    if (num == 0) {
        if (show_prefix) {
            snprintf(buffer, size, "0b0");
        } else {
            snprintf(buffer, size, "0");
        }
        return;
    }
    
    // Convertir a binario (dígitos en orden inverso)
    unsigned long long n = num;
    while (n > 0) {
        temp[idx++] = (n & 1) ? '1' : '0';
        n >>= 1;
    }
    
    // Calcular espacio necesario
    int prefix_len = show_prefix ? 2 : 0;  // "0b"
    int total_needed = prefix_len + idx + 1;  // +1 para null terminator
    
    // Si no cabe, truncar apropiadamente
    if ((size_t)total_needed > size) {
        // Calcular cuántos dígitos podemos incluir
        int available_digits = size - prefix_len - 1;
        
        if (available_digits <= 0) {
            // No hay espacio ni para un dígito
            buffer[0] = '\0';
            return;
        }
        
        // Truncar el número de dígitos
        idx = available_digits;
    }
    
    // Construir resultado
    int offset = 0;
    if (show_prefix) {
        if (size < 3) {  // No hay espacio para "0b" + al menos un dígito
            buffer[0] = '\0';
            return;
        }
        buffer[offset++] = '0';
        buffer[offset++] = 'b';
    }
    
    // Copiar dígitos en orden correcto (con verificación de límites)
    for (int i = idx - 1; i >= 0 && offset < (int)size - 1; i--) {
        buffer[offset++] = temp[i];
    }
    buffer[offset] = '\0';
}

void format_hex(char* buffer, size_t size, unsigned int num, 
                int show_prefix, int padding, int zero_pad) {
    // Validar que el buffer sea válido
    if (!buffer || size == 0) {
        return;
    }
    
    if (show_prefix) {
        if (padding > 0 && zero_pad) {
            // Verificar que el padding no cause overflow
            // padding incluye el "0x", así que padding-2 son los dígitos hex
            if (padding > 2) {
                snprintf(buffer, size, "0x%0*x", padding - 2, num);
            } else {
                snprintf(buffer, size, "0x%x", num);
            }
        } else {
            snprintf(buffer, size, "0x%x", num);
        }
    } else {
        if (padding > 0 && zero_pad) {
            snprintf(buffer, size, "%0*x", padding, num);
        } else {
            snprintf(buffer, size, "%x", num);
        }
    }
}

void format_octal(char* buffer, size_t size, unsigned int num, int show_prefix) {
    // Validar que el buffer sea válido
    if (!buffer || size == 0) {
        return;
    }
    
    if (show_prefix) {
        snprintf(buffer, size, "0o%o", num);
    } else {
        snprintf(buffer, size, "%o", num);
    }
}