/**
 * @file text_alignment.h
 * @brief Alineación de texto con caracteres de relleno
 * 
 * Este módulo maneja la alineación de texto (izquierda, derecha, centro)
 * con soporte para caracteres de relleno personalizados.
 */

#ifndef TEXT_ALIGNMENT_H
#define TEXT_ALIGNMENT_H

#include <stdbool.h>


#ifdef __cplusplus
extern "C" {
#endif

// Tipos de alineación
typedef enum {
    ALIGN_NONE = 0,
    ALIGN_LEFT = '<',
    ALIGN_RIGHT = '>',
    ALIGN_CENTER = '^'
} TextAlign;

/**
 * @brief Imprime texto con alineación y carácter de relleno
 * @param text Texto a imprimir
 * @param align Tipo de alineación (ALIGN_LEFT, ALIGN_RIGHT, ALIGN_CENTER)
 * @param width Ancho total del campo
 * @param fill_char Carácter para rellenar espacios vacíos
 * 
 * Ejemplos:
 * - print_aligned("Hello", ALIGN_LEFT, 10, ' ')  → "Hello     "
 * - print_aligned("Hello", ALIGN_RIGHT, 10, ' ') → "     Hello"
 * - print_aligned("Hello", ALIGN_CENTER, 10, '*') → "**Hello***"
 */
void print_aligned(const char* text, TextAlign align, int width, char fill_char);

/**
 * @brief Detecta si un token representa alineación
 * @param token String a analizar (ej: "<20", ">30", "*^15")
 * @param align [out] Tipo de alineación detectado
 * @param width [out] Ancho detectado
 * @param fill_char [out] Carácter de relleno detectado
 * @return true si se detectó alineación válida, false en caso contrario
 * 
 * Formatos válidos:
 * - "<20"  → izquierda, ancho 20, relleno ' '
 * - ">30"  → derecha, ancho 30, relleno ' '
 * - "^15"  → centro, ancho 15, relleno ' '
 * - "*^20" → centro, ancho 20, relleno '*'
 * - "->40" → derecha, ancho 40, relleno '-'
 */
bool is_alignment(const char* token, TextAlign* align, int* width, char* fill_char);

#ifdef __cplusplus
}
#endif

#endif // TEXT_ALIGNMENT_H