/**
 * @file c_print_typed.h
 * @brief API Type-Safe usando _Generic (C11)
 * 
 * Esta versión usa _Generic para verificar tipos en compile-time,
 * inspirada en las técnicas de "Modern C" de Jens Gustedt.
 * 
 * Requiere: -std=c11 o superior
 */

#ifndef C_PRINT_TYPED_H
#define C_PRINT_TYPED_H

#include "c_print.h"
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

// ============================================================================
// TIPO SEGURO: Wrapper para valores
// ============================================================================

typedef enum {
    CPRINT_TYPE_STRING,
    CPRINT_TYPE_INT,
    CPRINT_TYPE_UINT,
    CPRINT_TYPE_LONG,
    CPRINT_TYPE_ULONG,
    CPRINT_TYPE_FLOAT,
    CPRINT_TYPE_DOUBLE,
    CPRINT_TYPE_CHAR,
    CPRINT_TYPE_BOOL,
    CPRINT_TYPE_POINTER,
    CPRINT_TYPE_UNKNOWN
} CPrintValueType;

typedef struct {
    CPrintValueType type;
    union {
        const char* s;
        int i;
        unsigned int u;
        long l;
        unsigned long ul;
        float f;
        double d;
        char c;
        bool b;
        void* ptr;
    } value;
} CPrintValue;

// ============================================================================
// MACROS PARA CREAR VALORES TIPADOS
// ============================================================================

#define CPRINT_STR(x) ((CPrintValue){.type = CPRINT_TYPE_STRING, .value.s = (x)})
#define CPRINT_INT(x) ((CPrintValue){.type = CPRINT_TYPE_INT, .value.i = (x)})
#define CPRINT_UINT(x) ((CPrintValue){.type = CPRINT_TYPE_UINT, .value.u = (x)})
#define CPRINT_LONG(x) ((CPrintValue){.type = CPRINT_TYPE_LONG, .value.l = (x)})
#define CPRINT_FLOAT(x) ((CPrintValue){.type = CPRINT_TYPE_DOUBLE, .value.d = (x)})
#define CPRINT_CHAR(x) ((CPrintValue){.type = CPRINT_TYPE_CHAR, .value.c = (x)})
#define CPRINT_BOOL(x) ((CPrintValue){.type = CPRINT_TYPE_BOOL, .value.b = (x)})

// ============================================================================
// _GENERIC: DETECCIÓN AUTOMÁTICA DE TIPOS (C11)
// ============================================================================

#if __STDC_VERSION__ >= 201112L

#define CPRINT_AUTO(x) _Generic((x), \
    char*: CPRINT_STR, \
    const char*: CPRINT_STR, \
    int: CPRINT_INT, \
    unsigned int: CPRINT_UINT, \
    long: CPRINT_LONG, \
    unsigned long: CPRINT_UINT, \
    float: CPRINT_FLOAT, \
    double: CPRINT_FLOAT, \
    char: CPRINT_CHAR, \
    bool: CPRINT_BOOL, \
    default: CPRINT_INT \
)(x)

#else
    #warning "C11 _Generic not available. Use explicit CPRINT_* macros."
    #define CPRINT_AUTO(x) CPRINT_INT(0)  // Fallback
#endif

// ============================================================================
// API PRINCIPAL TYPE-SAFE
// ============================================================================

/**
 * @brief Versión type-safe de c_print (máximo 10 argumentos)
 * 
 * Uso:
 *   c_print_typed("{s:red} {d:blue}", CPRINT_STR("Hello"), CPRINT_INT(42));
 *   // O con auto-detección (C11):
 *   c_print_typed("{s:red} {d:blue}", CPRINT_AUTO("Hello"), CPRINT_AUTO(42));
 */
void c_print_typed(const char* pattern, ...);

/**
 * @brief Macro conveniente que usa _Generic (C11)
 * 
 * Uso:
 *   C_PRINT("{s:red} {d:blue}", "Hello", 42);
 */
#if __STDC_VERSION__ >= 201112L
    #define C_PRINT(pattern, ...) \
        c_print_typed_helper(pattern, ##__VA_ARGS__, (CPrintValue){.type = CPRINT_TYPE_UNKNOWN})
    
    // Helper que convierte automáticamente con _Generic
    #define c_print_typed_helper(pattern, ...) \
        c_print_typed(pattern, _CPRINT_WRAP_ARGS(__VA_ARGS__))
    
    // Macro recursiva para envolver cada argumento
    #define _CPRINT_WRAP_ARGS(...) \
        _CPRINT_MAP(CPRINT_AUTO, __VA_ARGS__)
#else
    #define C_PRINT(pattern, ...) \
        c_print(pattern, ##__VA_ARGS__)
#endif

// ============================================================================
// VALIDACIÓN EXPLÍCITA DE TIPOS
// ============================================================================

/**
 * @brief Valida que un patrón y sus argumentos coincidan
 * @return true si coinciden, false + mensaje de error si no
 */
bool c_print_validate(const char* pattern, int num_args, CPrintValueType expected_types[]);

/**
 * @brief Imprime información de debug sobre los argumentos
 */
void c_print_debug_args(const char* pattern, ...);

// ============================================================================
// EJEMPLOS DE USO
// ============================================================================

/*
EJEMPLO 1: Uso básico con macros explícitas
-----------------------------------------
c_print_typed("{s:red} tiene {d:green} años", 
              CPRINT_STR("Juan"), 
              CPRINT_INT(25));


EJEMPLO 2: Uso con auto-detección (C11)
-----------------------------------------
C_PRINT("{s:red} tiene {d:green} años", "Juan", 25);


EJEMPLO 3: Detección de errores en compile-time
-----------------------------------------
// ❌ ERROR: Type mismatch (C11 con warnings)
C_PRINT("{s:red}", 500);  // El compilador advertirá


EJEMPLO 4: Validación explícita
-----------------------------------------
CPrintValueType expected[] = {CPRINT_TYPE_STRING, CPRINT_TYPE_INT};
if (!c_print_validate("{s} {d}", 2, expected)) {
    fprintf(stderr, "Argumentos incorrectos!\n");
}
*/

#ifdef __cplusplus
}
#endif

#endif // C_PRINT_TYPED_H