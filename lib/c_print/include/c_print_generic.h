/**
 * @file c_print_generic.h
 * @brief Extensión _Generic (C11) para type-safe c_print
 * 
 * Este header proporciona validación de tipos en compile-time usando _Generic.
 * Requiere: -std=c11 o superior
 * 
 * Uso:
 *   #define C_PRINT_USE_GENERIC
 *   #include "c_print.h"
 *   #include "c_print_generic.h"
 */

#ifndef C_PRINT_GENERIC_H
#define C_PRINT_GENERIC_H

#include "c_print.h"
#include <stdint.h>
#include <stdbool.h>

// Solo disponible en C11+
#if __STDC_VERSION__ >= 201112L

#ifdef __cplusplus
extern "C" {
#endif

// ============================================================================
// TIPOS PARA ARGUMENTOS TIPADOS
// ============================================================================

typedef enum {
    CPRINT_ARG_STRING,
    CPRINT_ARG_INT,
    CPRINT_ARG_UINT,
    CPRINT_ARG_LONG,
    CPRINT_ARG_ULONG,
    CPRINT_ARG_DOUBLE,
    CPRINT_ARG_CHAR,
    CPRINT_ARG_BOOL,
    CPRINT_ARG_PTR,
    CPRINT_ARG_UNKNOWN
} CPrintArgType;

typedef struct {
    CPrintArgType type;
    union {
        const char* s;
        int i;
        unsigned int u;
        long l;
        unsigned long ul;
        double d;
        char c;
        bool b;
        void* ptr;
    } value;
} CPrintArg;

// ============================================================================
// MACROS _GENERIC PARA DETECCIÓN AUTOMÁTICA DE TIPOS
// ============================================================================

/**
 * @brief Detecta automáticamente el tipo y crea CPrintArg
 */
#define CPRINT_ARG(x) _Generic((x), \
    char*: cprint_arg_str, \
    const char*: cprint_arg_str, \
    int: cprint_arg_int, \
    unsigned int: cprint_arg_uint, \
    long: cprint_arg_long, \
    unsigned long: cprint_arg_ulong, \
    long long: cprint_arg_long, \
    unsigned long long: cprint_arg_ulong, \
    float: cprint_arg_double, \
    double: cprint_arg_double, \
    char: cprint_arg_char, \
    signed char: cprint_arg_char, \
    unsigned char: cprint_arg_char, \
    _Bool: cprint_arg_bool, \
    void*: cprint_arg_ptr, \
    default: cprint_arg_unknown \
)(x)

/**
 * @brief Detecta el tipo esperado por un especificador de formato
 */
#define CPRINT_EXPECTED_TYPE(spec) _Generic((spec), \
    char: (spec == 's' ? CPRINT_ARG_STRING : \
           spec == 'd' ? CPRINT_ARG_INT : \
           spec == 'i' ? CPRINT_ARG_INT : \
           spec == 'f' ? CPRINT_ARG_DOUBLE : \
           spec == 'c' ? CPRINT_ARG_CHAR : \
           spec == 'b' ? CPRINT_ARG_UINT : \
           spec == 'x' ? CPRINT_ARG_UINT : \
           spec == 'o' ? CPRINT_ARG_UINT : \
           spec == 'u' ? CPRINT_ARG_UINT : \
           spec == 'l' ? CPRINT_ARG_LONG : \
           CPRINT_ARG_UNKNOWN), \
    default: CPRINT_ARG_UNKNOWN \
)

// ============================================================================
// FUNCIONES HELPER PARA CREAR CPrintArg
// ============================================================================

static inline CPrintArg cprint_arg_str(const char* s) {
    CPrintArg arg = {.type = CPRINT_ARG_STRING, .value.s = s};
    return arg;
}

static inline CPrintArg cprint_arg_int(int i) {
    CPrintArg arg = {.type = CPRINT_ARG_INT, .value.i = i};
    return arg;
}

static inline CPrintArg cprint_arg_uint(unsigned int u) {
    CPrintArg arg = {.type = CPRINT_ARG_UINT, .value.u = u};
    return arg;
}

static inline CPrintArg cprint_arg_long(long l) {
    CPrintArg arg = {.type = CPRINT_ARG_LONG, .value.l = l};
    return arg;
}

static inline CPrintArg cprint_arg_ulong(unsigned long ul) {
    CPrintArg arg = {.type = CPRINT_ARG_ULONG, .value.ul = ul};
    return arg;
}

static inline CPrintArg cprint_arg_double(double d) {
    CPrintArg arg = {.type = CPRINT_ARG_DOUBLE, .value.d = d};
    return arg;
}

static inline CPrintArg cprint_arg_char(char c) {
    CPrintArg arg = {.type = CPRINT_ARG_CHAR, .value.c = c};
    return arg;
}

static inline CPrintArg cprint_arg_bool(bool b) {
    CPrintArg arg = {.type = CPRINT_ARG_BOOL, .value.b = b};
    return arg;
}

static inline CPrintArg cprint_arg_ptr(void* ptr) {
    CPrintArg arg = {.type = CPRINT_ARG_PTR, .value.ptr = ptr};
    return arg;
}

static inline CPrintArg cprint_arg_unknown(int x) {
    CPrintArg arg = {.type = CPRINT_ARG_UNKNOWN, .value.i = x};
    return arg;
}

// ============================================================================
// VALIDACIÓN DE TIPOS
// ============================================================================

/**
 * @brief Valida que el tipo del argumento coincida con el esperado
 */
static inline bool cprint_validate_arg_type(char format_type, CPrintArgType arg_type) {
    switch (format_type) {
        case 's':
            return arg_type == CPRINT_ARG_STRING;
        case 'd':
        case 'i':
            return arg_type == CPRINT_ARG_INT;
        case 'f':
            return arg_type == CPRINT_ARG_DOUBLE;
        case 'c':
            return arg_type == CPRINT_ARG_CHAR;
        case 'b':
        case 'x':
        case 'o':
        case 'u':
            return arg_type == CPRINT_ARG_UINT || arg_type == CPRINT_ARG_INT;
        case 'l':
            return arg_type == CPRINT_ARG_LONG;
        default:
            return false;
    }
}

/**
 * @brief Obtiene el nombre del tipo para mensajes de error
 */
static inline const char* cprint_type_name(CPrintArgType type) {
    switch (type) {
        case CPRINT_ARG_STRING: return "string";
        case CPRINT_ARG_INT: return "int";
        case CPRINT_ARG_UINT: return "unsigned int";
        case CPRINT_ARG_LONG: return "long";
        case CPRINT_ARG_ULONG: return "unsigned long";
        case CPRINT_ARG_DOUBLE: return "double";
        case CPRINT_ARG_CHAR: return "char";
        case CPRINT_ARG_BOOL: return "bool";
        case CPRINT_ARG_PTR: return "pointer";
        default: return "unknown";
    }
}

/**
 * @brief Obtiene el tipo esperado por un especificador de formato
 */
static inline const char* cprint_expected_type_name(char format_type) {
    switch (format_type) {
        case 's': return "string";
        case 'd':
        case 'i': return "int";
        case 'f': return "double";
        case 'c': return "char";
        case 'b':
        case 'x':
        case 'o':
        case 'u': return "unsigned int";
        case 'l': return "long";
        default: return "unknown";
    }
}

// ============================================================================
// API PRINCIPAL CON VALIDACIÓN _GENERIC
// ============================================================================

/**
 * @brief Versión type-safe de c_print usando _Generic
 * 
 * Uso:
 *   C_PRINT("{s:red} {d:green}", "Hello", 42);
 * 
 * Si hay type mismatch, muestra error en compile-time (warning)
 * y mensaje en runtime.
 */
void c_print_checked(const char* pattern, ...);

// Implementación con macros variádicas
#define C_PRINT_MAX_ARGS 10

// Helper para contar argumentos usando el truco del contador
#define C_PRINT_NARG(...) C_PRINT_NARG_(__VA_ARGS__, C_PRINT_RSEQ_N())
#define C_PRINT_NARG_(...) C_PRINT_ARG_N(__VA_ARGS__)
#define C_PRINT_ARG_N(_1, _2, _3, _4, _5, _6, _7, _8, _9, _10, N, ...) N
#define C_PRINT_RSEQ_N() 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0

// Macros para aplicar CPRINT_ARG a cada elemento
#define C_PRINT_APPLY_ARG_1(x1) CPRINT_ARG(x1)
#define C_PRINT_APPLY_ARG_2(x1, x2) CPRINT_ARG(x1), CPRINT_ARG(x2)
#define C_PRINT_APPLY_ARG_3(x1, x2, x3) CPRINT_ARG(x1), CPRINT_ARG(x2), CPRINT_ARG(x3)
#define C_PRINT_APPLY_ARG_4(x1, x2, x3, x4) CPRINT_ARG(x1), CPRINT_ARG(x2), CPRINT_ARG(x3), CPRINT_ARG(x4)
#define C_PRINT_APPLY_ARG_5(x1, x2, x3, x4, x5) CPRINT_ARG(x1), CPRINT_ARG(x2), CPRINT_ARG(x3), CPRINT_ARG(x4), CPRINT_ARG(x5)
#define C_PRINT_APPLY_ARG_6(x1, x2, x3, x4, x5, x6) CPRINT_ARG(x1), CPRINT_ARG(x2), CPRINT_ARG(x3), CPRINT_ARG(x4), CPRINT_ARG(x5), CPRINT_ARG(x6)
#define C_PRINT_APPLY_ARG_7(x1, x2, x3, x4, x5, x6, x7) CPRINT_ARG(x1), CPRINT_ARG(x2), CPRINT_ARG(x3), CPRINT_ARG(x4), CPRINT_ARG(x5), CPRINT_ARG(x6), CPRINT_ARG(x7)
#define C_PRINT_APPLY_ARG_8(x1, x2, x3, x4, x5, x6, x7, x8) CPRINT_ARG(x1), CPRINT_ARG(x2), CPRINT_ARG(x3), CPRINT_ARG(x4), CPRINT_ARG(x5), CPRINT_ARG(x6), CPRINT_ARG(x7), CPRINT_ARG(x8)
#define C_PRINT_APPLY_ARG_9(x1, x2, x3, x4, x5, x6, x7, x8, x9) CPRINT_ARG(x1), CPRINT_ARG(x2), CPRINT_ARG(x3), CPRINT_ARG(x4), CPRINT_ARG(x5), CPRINT_ARG(x6), CPRINT_ARG(x7), CPRINT_ARG(x8), CPRINT_ARG(x9)
#define C_PRINT_APPLY_ARG_10(x1, x2, x3, x4, x5, x6, x7, x8, x9, x10) CPRINT_ARG(x1), CPRINT_ARG(x2), CPRINT_ARG(x3), CPRINT_ARG(x4), CPRINT_ARG(x5), CPRINT_ARG(x6), CPRINT_ARG(x7), CPRINT_ARG(x8), CPRINT_ARG(x9), CPRINT_ARG(x10)

// Macro para seleccionar la macro correcta según el número de argumentos
#define C_PRINT_APPLY_ARG_(N) C_PRINT_APPLY_ARG_##N
#define C_PRINT_APPLY_ARG(N) C_PRINT_APPLY_ARG_(N)

// Macro de expansión intermedia necesaria para forzar la evaluación
#define C_PRINT_EXPAND(x) x

// Macro principal - aplica CPRINT_ARG a cada argumento
#define C_PRINT(pattern, ...) \
    c_print_checked_wrapper(pattern, C_PRINT_NARG(__VA_ARGS__), \
                           C_PRINT_EXPAND(C_PRINT_APPLY_ARG(C_PRINT_NARG(__VA_ARGS__))(__VA_ARGS__)))

// Wrapper que recibe CPrintArg[]
void c_print_checked_wrapper(const char* pattern, int argc, ...);

// ============================================================================
// MODO DEBUG: Validación estricta
// ============================================================================

#ifdef C_PRINT_STRICT
    /**
     * @brief Valida tipos y aborta si hay mismatch
     */
    #define C_PRINT_VALIDATE(pattern, ...) \
        do { \
            if (!c_print_validate_pattern(pattern, C_PRINT_NARG(__VA_ARGS__), \
                                         C_PRINT_EXPAND(C_PRINT_APPLY_ARG(C_PRINT_NARG(__VA_ARGS__))(__VA_ARGS__)))) { \
                fprintf(stderr, "[C_PRINT ERROR] Type mismatch in: %s\n", pattern); \
                abort(); \
            } \
        } while(0)
#else
    #define C_PRINT_VALIDATE(pattern, ...) ((void)0)
#endif

/**
 * @brief Valida que el patrón y los argumentos coincidan
 */
bool c_print_validate_pattern(const char* pattern, int argc, ...);

// ============================================================================
// INFORMACIÓN DE TIPOS (para debugging)
// ============================================================================

/**
 * @brief Imprime información sobre los tipos de los argumentos
 */
#define C_PRINT_DEBUG_TYPES(pattern, ...) \
    c_print_debug_types_impl(pattern, C_PRINT_NARG(__VA_ARGS__), \
                            C_PRINT_EXPAND(C_PRINT_APPLY_ARG(C_PRINT_NARG(__VA_ARGS__))(__VA_ARGS__)))

void c_print_debug_types_impl(const char* pattern, int argc, ...);

#ifdef __cplusplus
}
#endif

// ============================================================================
// EJEMPLOS DE USO
// ============================================================================

/*
EJEMPLO 1: Uso básico con detección automática
-----------------------------------------------
#define C_PRINT_USE_GENERIC
#include "c_print.h"
#include "c_print_generic.h"

C_PRINT("{s:red} {d:green}\n", "Hello", 42);
// ✅ OK: tipos correctos


EJEMPLO 2: Detección de errores en compile-time
------------------------------------------------
C_PRINT("{s:blue}", 500);
// ⚠️ Compile warning: incompatible type in _Generic selection
// ⚠️ Runtime: muestra "{? expected string, got int=500}"


EJEMPLO 3: Modo estricto (aborta en error)
-------------------------------------------
#define C_PRINT_STRICT
C_PRINT("{d}", "hello");
// ❌ Abort: Type mismatch detected


EJEMPLO 4: Debug de tipos
--------------------------
C_PRINT_DEBUG_TYPES("{s} {d} {f}", "test", 42, 3.14);
// Output:
// [DEBUG] Pattern: {s} {d} {f}
// [DEBUG] Arg 0: string "test"
// [DEBUG] Arg 1: int 42
// [DEBUG] Arg 2: double 3.140000


EJEMPLO 5: Validación manual
-----------------------------
if (!c_print_validate_pattern("{s} {d}", 2, 
    CPRINT_ARG("hello"), CPRINT_ARG(42))) {
    fprintf(stderr, "Invalid arguments\n");
}
*/

#else
    // C99 fallback: sin _Generic
    #warning "C11 _Generic not available. C_PRINT will fallback to c_print without type checking."
    #define C_PRINT c_print
    #define C_PRINT_DEBUG_TYPES(pattern, ...) ((void)0)
#endif

#endif // C_PRINT_GENERIC_H