/**
 * @file number_formatter.h
 * @brief Formateo avanzado de números
 * 
 * Este módulo proporciona funciones para formatear números con:
 * - Separadores de miles (comas, guiones bajos)
 * - Formato binario con prefijo opcional
 * - Padding con ceros
 * - Precisión decimal
 * - Conversión a porcentajes
 */

#ifndef NUMBER_FORMATTER_H
#define NUMBER_FORMATTER_H

#include <stddef.h>

#ifdef __cplusplus
extern "C" {
#endif

/**
 * @brief Formatea un número entero con separadores de miles
 * @param buffer Buffer de salida
 * @param size Tamaño del buffer
 * @param num Número a formatear
 * @param separator Carácter separador (',' o '_')
 * 
 * Ejemplo:
 * - format_with_separator(buf, 100, 1234567, ',') → "1,234,567"
 * - format_with_separator(buf, 100, 1234567, '_') → "1_234_567"
 */
void format_with_separator(char* buffer, size_t size, long long num, char separator);

/**
 * @brief Formatea un número en representación binaria
 * @param buffer Buffer de salida
 * @param size Tamaño del buffer
 * @param num Número a convertir
 * @param show_prefix Si es 1, añade prefijo "0b"
 * 
 * Ejemplo:
 * - format_binary(buf, 100, 42, 0) → "101010"
 * - format_binary(buf, 100, 42, 1) → "0b101010"
 */
void format_binary(char* buffer, size_t size, unsigned long long num, int show_prefix);

/**
 * @brief Formatea un número hexadecimal con prefijo opcional
 * @param buffer Buffer de salida
 * @param size Tamaño del buffer
 * @param num Número a convertir
 * @param show_prefix Si es 1, añade prefijo "0x"
 * @param padding Ancho de padding (0 = sin padding)
 * @param zero_pad Si es 1, usa ceros para padding
 * 
 * Ejemplo:
 * - format_hex(buf, 100, 255, 1, 4, 1) → "0x00ff"
 * - format_hex(buf, 100, 255, 0, 0, 0) → "ff"
 */
void format_hex(char* buffer, size_t size, unsigned int num, 
                int show_prefix, int padding, int zero_pad);

/**
 * @brief Formatea un número octal con prefijo opcional
 * @param buffer Buffer de salida
 * @param size Tamaño del buffer
 * @param num Número a convertir
 * @param show_prefix Si es 1, añade prefijo "0o"
 * 
 * Ejemplo:
 * - format_octal(buf, 100, 64, 1) → "0o100"
 * - format_octal(buf, 100, 64, 0) → "100"
 */
void format_octal(char* buffer, size_t size, unsigned int num, int show_prefix);

#ifdef __cplusplus
}
#endif

#endif // NUMBER_FORMATTER_H