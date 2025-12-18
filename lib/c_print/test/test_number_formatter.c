/**
 * @file test_number_formatter.c
 * @brief Tests unitarios para el módulo number_formatter
 */

#include "number_formatter.h"
#include <stdio.h>
#include <string.h>
#include <assert.h>

#define TEST(name) static void test_##name(void)
#define RUN_TEST(name) do { \
    printf("  Running: %s... ", #name); \
    test_##name(); \
    printf("✓\n"); \
    tests_passed++; \
} while(0)

static int tests_passed = 0;

// ============================================================================
// TESTS PARA format_with_separator()
// ============================================================================

TEST(separator_basic_comma) {
    char buffer[100];
    format_with_separator(buffer, sizeof(buffer), 1234567, ',');
    assert(strcmp(buffer, "1,234,567") == 0);
}

TEST(separator_basic_underscore) {
    char buffer[100];
    format_with_separator(buffer, sizeof(buffer), 1234567, '_');
    assert(strcmp(buffer, "1_234_567") == 0);
}

TEST(separator_small_number) {
    char buffer[100];
    format_with_separator(buffer, sizeof(buffer), 42, ',');
    assert(strcmp(buffer, "42") == 0);  // Sin separador
}

TEST(separator_exactly_thousand) {
    char buffer[100];
    format_with_separator(buffer, sizeof(buffer), 1000, ',');
    assert(strcmp(buffer, "1,000") == 0);
}

TEST(separator_negative_number) {
    char buffer[100];
    format_with_separator(buffer, sizeof(buffer), -1234567, ',');
    assert(strcmp(buffer, "-1,234,567") == 0);
}

TEST(separator_zero) {
    char buffer[100];
    format_with_separator(buffer, sizeof(buffer), 0, ',');
    assert(strcmp(buffer, "0") == 0);
}

TEST(separator_large_number) {
    char buffer[100];
    format_with_separator(buffer, sizeof(buffer), 999999999, ',');
    assert(strcmp(buffer, "999,999,999") == 0);
}

TEST(separator_three_digits) {
    char buffer[100];
    format_with_separator(buffer, sizeof(buffer), 123, ',');
    assert(strcmp(buffer, "123") == 0);  // Sin separador
}

TEST(separator_four_digits) {
    char buffer[100];
    format_with_separator(buffer, sizeof(buffer), 1234, ',');
    assert(strcmp(buffer, "1,234") == 0);
}

TEST(separator_buffer_overflow_protection) {
    char buffer[10];  // Buffer pequeño
    format_with_separator(buffer, sizeof(buffer), 1234567890, ',');
    // No debe crashear, debe truncar apropiadamente
    assert(strlen(buffer) < sizeof(buffer));
}

// ============================================================================
// TESTS PARA format_binary()
// ============================================================================

TEST(binary_basic) {
    char buffer[100];
    format_binary(buffer, sizeof(buffer), 42, 0);
    assert(strcmp(buffer, "101010") == 0);
}

TEST(binary_with_prefix) {
    char buffer[100];
    format_binary(buffer, sizeof(buffer), 42, 1);
    assert(strcmp(buffer, "0b101010") == 0);
}

TEST(binary_zero) {
    char buffer[100];
    format_binary(buffer, sizeof(buffer), 0, 0);
    assert(strcmp(buffer, "0") == 0);
}

TEST(binary_zero_with_prefix) {
    char buffer[100];
    format_binary(buffer, sizeof(buffer), 0, 1);
    assert(strcmp(buffer, "0b0") == 0);
}

TEST(binary_one) {
    char buffer[100];
    format_binary(buffer, sizeof(buffer), 1, 0);
    assert(strcmp(buffer, "1") == 0);
}

TEST(binary_power_of_two) {
    char buffer[100];
    
    format_binary(buffer, sizeof(buffer), 2, 0);
    assert(strcmp(buffer, "10") == 0);
    
    format_binary(buffer, sizeof(buffer), 4, 0);
    assert(strcmp(buffer, "100") == 0);
    
    format_binary(buffer, sizeof(buffer), 8, 0);
    assert(strcmp(buffer, "1000") == 0);
    
    format_binary(buffer, sizeof(buffer), 16, 0);
    assert(strcmp(buffer, "10000") == 0);
}

TEST(binary_max_byte) {
    char buffer[100];
    format_binary(buffer, sizeof(buffer), 255, 0);
    assert(strcmp(buffer, "11111111") == 0);
}

TEST(binary_alternating_bits) {
    char buffer[100];
    format_binary(buffer, sizeof(buffer), 170, 1);  // 10101010
    assert(strcmp(buffer, "0b10101010") == 0);
}

TEST(binary_large_number) {
    char buffer[100];
    format_binary(buffer, sizeof(buffer), 65535, 0);  // 16 bits todos en 1
    assert(strcmp(buffer, "1111111111111111") == 0);
}

// ============================================================================
// TESTS PARA format_hex()
// ============================================================================

TEST(hex_basic) {
    char buffer[100];
    format_hex(buffer, sizeof(buffer), 255, 0, 0, 0);
    assert(strcmp(buffer, "ff") == 0);
}

TEST(hex_with_prefix) {
    char buffer[100];
    format_hex(buffer, sizeof(buffer), 255, 1, 0, 0);
    assert(strcmp(buffer, "0xff") == 0);
}

TEST(hex_zero) {
    char buffer[100];
    format_hex(buffer, sizeof(buffer), 0, 0, 0, 0);
    assert(strcmp(buffer, "0") == 0);
}

TEST(hex_with_padding) {
    char buffer[100];
    format_hex(buffer, sizeof(buffer), 255, 0, 4, 1);
    assert(strcmp(buffer, "00ff") == 0);
}

TEST(hex_with_prefix_and_padding) {
    char buffer[100];
    format_hex(buffer, sizeof(buffer), 255, 1, 8, 1);
    assert(strcmp(buffer, "0x0000ff") == 0);
}

TEST(hex_small_numbers) {
    char buffer[100];
    
    format_hex(buffer, sizeof(buffer), 10, 0, 0, 0);
    assert(strcmp(buffer, "a") == 0);
    
    format_hex(buffer, sizeof(buffer), 15, 0, 0, 0);
    assert(strcmp(buffer, "f") == 0);
}

TEST(hex_color_codes) {
    char buffer[100];
    
    // CORREGIDO: padding 8 significa 8 caracteres totales (incluyendo "0x")
    // Red (0xFF0000) - 8 caracteres totales = "0x" (2) + "ff0000" (6)
    format_hex(buffer, sizeof(buffer), 0xFF0000, 1, 8, 1);
    assert(strcmp(buffer, "0xff0000") == 0);
    
    // Green (0x00FF00) - 8 caracteres totales
    format_hex(buffer, sizeof(buffer), 0x00FF00, 1, 8, 1);
    assert(strcmp(buffer, "0x00ff00") == 0);
    
    // Blue (0x0000FF) - 8 caracteres totales
    format_hex(buffer, sizeof(buffer), 0x0000FF, 1, 8, 1);
    assert(strcmp(buffer, "0x0000ff") == 0);
    
    // NUEVO: Si queremos 8 dígitos hex (10 caracteres totales con "0x")
    format_hex(buffer, sizeof(buffer), 0xFF0000, 1, 10, 1);
    assert(strcmp(buffer, "0x00ff0000") == 0);
    
    format_hex(buffer, sizeof(buffer), 0x00FF00, 1, 10, 1);
    assert(strcmp(buffer, "0x0000ff00") == 0);
    
    format_hex(buffer, sizeof(buffer), 0x0000FF, 1, 10, 1);
    assert(strcmp(buffer, "0x000000ff") == 0);
    
    // CORREGIDO: Sin padding, solo el número sin ceros a la izquierda
    format_hex(buffer, sizeof(buffer), 0xFF0000, 1, 0, 0);
    assert(strcmp(buffer, "0xff0000") == 0);
    
    format_hex(buffer, sizeof(buffer), 0x00FF00, 1, 0, 0);
    assert(strcmp(buffer, "0xff00") == 0);  // CORREGIDO: sin ceros iniciales
    
    format_hex(buffer, sizeof(buffer), 0x0000FF, 1, 0, 0);
    assert(strcmp(buffer, "0xff") == 0);  // CORREGIDO: sin ceros iniciales
}

TEST(hex_powers_of_16) {
    char buffer[100];
    
    format_hex(buffer, sizeof(buffer), 16, 0, 0, 0);
    assert(strcmp(buffer, "10") == 0);
    
    format_hex(buffer, sizeof(buffer), 256, 0, 0, 0);
    assert(strcmp(buffer, "100") == 0);
}

// ============================================================================
// TESTS PARA format_octal()
// ============================================================================

TEST(octal_basic) {
    char buffer[100];
    format_octal(buffer, sizeof(buffer), 64, 0);
    assert(strcmp(buffer, "100") == 0);
}

TEST(octal_with_prefix) {
    char buffer[100];
    format_octal(buffer, sizeof(buffer), 64, 1);
    assert(strcmp(buffer, "0o100") == 0);
}

TEST(octal_zero) {
    char buffer[100];
    format_octal(buffer, sizeof(buffer), 0, 0);
    assert(strcmp(buffer, "0") == 0);
}

TEST(octal_permissions) {
    char buffer[100];
    
    // 0755 (rwxr-xr-x)
    format_octal(buffer, sizeof(buffer), 0755, 1);
    assert(strcmp(buffer, "0o755") == 0);
    
    // 0644 (rw-r--r--)
    format_octal(buffer, sizeof(buffer), 0644, 1);
    assert(strcmp(buffer, "0o644") == 0);
    
    // 0777 (rwxrwxrwx)
    format_octal(buffer, sizeof(buffer), 0777, 1);
    assert(strcmp(buffer, "0o777") == 0);
}

TEST(octal_small_numbers) {
    char buffer[100];
    
    for (int i = 0; i < 8; i++) {
        format_octal(buffer, sizeof(buffer), i, 0);
        assert(buffer[0] == '0' + i);
        assert(buffer[1] == '\0');
    }
}

TEST(octal_eight) {
    char buffer[100];
    format_octal(buffer, sizeof(buffer), 8, 0);
    assert(strcmp(buffer, "10") == 0);  // 8 en octal es 10
}

TEST(octal_powers_of_eight) {
    char buffer[100];
    
    format_octal(buffer, sizeof(buffer), 8, 0);
    assert(strcmp(buffer, "10") == 0);
    
    format_octal(buffer, sizeof(buffer), 64, 0);
    assert(strcmp(buffer, "100") == 0);
    
    format_octal(buffer, sizeof(buffer), 512, 0);
    assert(strcmp(buffer, "1000") == 0);
}

// ============================================================================
// TESTS DE INTEGRACIÓN
// ============================================================================

TEST(integration_all_bases) {
    char buffer[100];
    unsigned int num = 42;
    
    // Decimal (con separador)
    format_with_separator(buffer, sizeof(buffer), num, ',');
    assert(strcmp(buffer, "42") == 0);
    
    // Binario
    format_binary(buffer, sizeof(buffer), num, 1);
    assert(strcmp(buffer, "0b101010") == 0);
    
    // Hexadecimal
    format_hex(buffer, sizeof(buffer), num, 1, 0, 0);
    assert(strcmp(buffer, "0x2a") == 0);
    
    // Octal
    format_octal(buffer, sizeof(buffer), num, 1);
    assert(strcmp(buffer, "0o52") == 0);
}

TEST(integration_format_consistency) {
    char buffer1[100], buffer2[100];
    
    // Formatear el mismo número de diferentes formas
    format_with_separator(buffer1, sizeof(buffer1), 1000000, ',');
    format_with_separator(buffer2, sizeof(buffer2), 1000000, '_');
    
    // Ambos deben tener la misma longitud (misma cantidad de dígitos)
    size_t len1 = strlen(buffer1);
    size_t len2 = strlen(buffer2);
    assert(len1 == len2);
}

// ============================================================================
// TESTS DE EDGE CASES
// ============================================================================

TEST(edge_case_max_values) {
    char buffer[100];
    
    // Max unsigned int (32-bit)
    format_with_separator(buffer, sizeof(buffer), 4294967295LL, ',');
    assert(strlen(buffer) > 0);
    
    // Max int (32-bit signed)
    format_with_separator(buffer, sizeof(buffer), 2147483647, ',');
    assert(strcmp(buffer, "2,147,483,647") == 0);
}

TEST(edge_case_negative_max) {
    char buffer[100];
    format_with_separator(buffer, sizeof(buffer), -2147483648LL, ',');
    assert(buffer[0] == '-');
    assert(strlen(buffer) > 1);
}

TEST(edge_case_small_buffer) {
    char buffer[5];  // Buffer muy pequeño
    
    // Debe manejar overflow sin crashear
    format_with_separator(buffer, sizeof(buffer), 123456789, ',');
    assert(strlen(buffer) < sizeof(buffer));
    
    format_binary(buffer, sizeof(buffer), 255, 1);
    assert(strlen(buffer) < sizeof(buffer));
    
    format_hex(buffer, sizeof(buffer), 255, 1, 0, 0);
    assert(strlen(buffer) < sizeof(buffer));
}

TEST(edge_case_all_ones_binary) {
    char buffer[100];
    
    // 8 bits todos en 1
    format_binary(buffer, sizeof(buffer), 0xFF, 0);
    assert(strcmp(buffer, "11111111") == 0);
    
    // 16 bits todos en 1
    format_binary(buffer, sizeof(buffer), 0xFFFF, 0);
    assert(strcmp(buffer, "1111111111111111") == 0);
}

TEST(edge_case_hex_letters) {
    char buffer[100];
    
    // Verificar que usa minúsculas
    format_hex(buffer, sizeof(buffer), 0xABCD, 0, 0, 0);
    assert(strcmp(buffer, "abcd") == 0);
    
    format_hex(buffer, sizeof(buffer), 0xDEADBEEF, 1, 0, 0);
    assert(strcmp(buffer, "0xdeadbeef") == 0);
}

// ============================================================================
// TESTS DE CONSISTENCIA
// ============================================================================

TEST(consistency_decimal_hex_octal) {
    char buf_hex[100], buf_oct[100];
    
    // 64 en diferentes bases
    format_hex(buf_hex, sizeof(buf_hex), 64, 0, 0, 0);
    format_octal(buf_oct, sizeof(buf_oct), 64, 0);
    
    // Hex: 40, Octal: 100
    assert(strcmp(buf_hex, "40") == 0);
    assert(strcmp(buf_oct, "100") == 0);
}

TEST(consistency_binary_conversions) {
    char buffer[100];
    
    // Verificar algunas conversiones conocidas
    struct {
        unsigned int num;
        const char* binary;
    } tests[] = {
        {1, "1"},
        {2, "10"},
        {3, "11"},
        {4, "100"},
        {7, "111"},
        {8, "1000"},
        {15, "1111"},
        {16, "10000"},
        {31, "11111"},
        {32, "100000"},
        {63, "111111"},
        {64, "1000000"}
    };
    
    for (size_t i = 0; i < sizeof(tests) / sizeof(tests[0]); i++) {
        format_binary(buffer, sizeof(buffer), tests[i].num, 0);
        assert(strcmp(buffer, tests[i].binary) == 0);
    }
}

// ============================================================================
// MAIN
// ============================================================================

int main(void) {
    printf("\n");
    printf("═══════════════════════════════════════════════════════════\n");
    printf("  Number Formatter Module - Unit Tests\n");
    printf("═══════════════════════════════════════════════════════════\n");
    printf("\n");
    
    printf("Testing format_with_separator():\n");
    RUN_TEST(separator_basic_comma);
    RUN_TEST(separator_basic_underscore);
    RUN_TEST(separator_small_number);
    RUN_TEST(separator_exactly_thousand);
    RUN_TEST(separator_negative_number);
    RUN_TEST(separator_zero);
    RUN_TEST(separator_large_number);
    RUN_TEST(separator_three_digits);
    RUN_TEST(separator_four_digits);
    RUN_TEST(separator_buffer_overflow_protection);
    printf("\n");
    
    printf("Testing format_binary():\n");
    RUN_TEST(binary_basic);
    RUN_TEST(binary_with_prefix);
    RUN_TEST(binary_zero);
    RUN_TEST(binary_zero_with_prefix);
    RUN_TEST(binary_one);
    RUN_TEST(binary_power_of_two);
    RUN_TEST(binary_max_byte);
    RUN_TEST(binary_alternating_bits);
    RUN_TEST(binary_large_number);
    printf("\n");
    
    printf("Testing format_hex():\n");
    RUN_TEST(hex_basic);
    RUN_TEST(hex_with_prefix);
    RUN_TEST(hex_zero);
    RUN_TEST(hex_with_padding);
    RUN_TEST(hex_with_prefix_and_padding);
    RUN_TEST(hex_small_numbers);
    RUN_TEST(hex_color_codes);
    RUN_TEST(hex_powers_of_16);
    printf("\n");
    
    printf("Testing format_octal():\n");
    RUN_TEST(octal_basic);
    RUN_TEST(octal_with_prefix);
    RUN_TEST(octal_zero);
    RUN_TEST(octal_permissions);
    RUN_TEST(octal_small_numbers);
    RUN_TEST(octal_eight);
    RUN_TEST(octal_powers_of_eight);
    printf("\n");
    
    printf("Integration tests:\n");
    RUN_TEST(integration_all_bases);
    RUN_TEST(integration_format_consistency);
    printf("\n");
    
    printf("Edge cases:\n");
    RUN_TEST(edge_case_max_values);
    RUN_TEST(edge_case_negative_max);
    RUN_TEST(edge_case_small_buffer);
    RUN_TEST(edge_case_all_ones_binary);
    RUN_TEST(edge_case_hex_letters);
    printf("\n");
    
    printf("Consistency tests:\n");
    RUN_TEST(consistency_decimal_hex_octal);
    RUN_TEST(consistency_binary_conversions);
    printf("\n");
    
    printf("═══════════════════════════════════════════════════════════\n");
    printf("  Results: %d tests passed ✓\n", tests_passed);
    printf("═══════════════════════════════════════════════════════════\n");
    printf("\n");
    
    return 0;
}