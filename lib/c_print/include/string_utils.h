/**
 * @file string_utils.h
 * @brief Utilidades para manipulación de strings
 * 
 * Este módulo proporciona funciones auxiliares para trabajar con strings,
 * incluyendo conversión de mayúsculas/minúsculas y validación de números.
 */

#ifndef STRING_UTILS_H
#define STRING_UTILS_H

#include <stdbool.h>

#ifdef __cplusplus
extern "C" {
#endif

/**
 * @brief Convierte un string a minúsculas (in-place)
 * @param str String a convertir (será modificado)
 */
void to_lowercase(char* str);

/**
 * @brief Verifica si un string representa un número entero válido
 * @param str String a verificar
 * @return true si es un número, false en caso contrario
 */
bool is_number(const char* str);

/**
 * @brief Elimina espacios en blanco al inicio y final de un string (in-place)
 * @param str String a procesar (será modificado)
 */
void trim_whitespace(char* str);

#ifdef __cplusplus
}
#endif

#endif // STRING_UTILS_H