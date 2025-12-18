/**
 * @file test_string_utils.c
 * @brief Tests unitarios para el módulo string_utils
 */

#include "string_utils.h"
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
// TESTS PARA to_lowercase()
// ============================================================================

TEST(to_lowercase_basic) {
    char str[] = "HELLO";
    to_lowercase(str);
    assert(strcmp(str, "hello") == 0);
}

TEST(to_lowercase_mixed_case) {
    char str[] = "HeLLo WoRLd";
    to_lowercase(str);
    assert(strcmp(str, "hello world") == 0);
}

TEST(to_lowercase_already_lower) {
    char str[] = "hello";
    to_lowercase(str);
    assert(strcmp(str, "hello") == 0);
}

TEST(to_lowercase_with_numbers) {
    char str[] = "Test123";
    to_lowercase(str);
    assert(strcmp(str, "test123") == 0);
}

TEST(to_lowercase_with_special_chars) {
    char str[] = "Hello-World!";
    to_lowercase(str);
    assert(strcmp(str, "hello-world!") == 0);
}

TEST(to_lowercase_empty_string) {
    char str[] = "";
    to_lowercase(str);
    assert(strcmp(str, "") == 0);
}

TEST(to_lowercase_null_safe) {
    to_lowercase(NULL);  // No debe crashear
}

TEST(to_lowercase_colors) {
    char str1[] = "RED";
    to_lowercase(str1);
    assert(strcmp(str1, "red") == 0);
    
    char str2[] = "BRIGHT_BLUE";
    to_lowercase(str2);
    assert(strcmp(str2, "bright_blue") == 0);
}

// ============================================================================
// TESTS PARA is_number()
// ============================================================================

TEST(is_number_valid_integers) {
    assert(is_number("0") == true);
    assert(is_number("1") == true);
    assert(is_number("123") == true);
    assert(is_number("456789") == true);
}

TEST(is_number_invalid_strings) {
    assert(is_number("abc") == false);
    assert(is_number("12a") == false);
    assert(is_number("a12") == false);
    assert(is_number("1.5") == false);  // No es entero
}

TEST(is_number_empty_and_null) {
    assert(is_number("") == false);
    assert(is_number(NULL) == false);
}

TEST(is_number_with_spaces) {
    assert(is_number(" 123") == false);  // Espacios no permitidos
    assert(is_number("123 ") == false);
    assert(is_number("1 23") == false);
}

TEST(is_number_negative) {
    assert(is_number("-123") == false);  // Signo negativo no permitido
    assert(is_number("+123") == false);  // Signo positivo no permitido
}

TEST(is_number_special_chars) {
    assert(is_number("12,345") == false);  // Coma no permitida
    assert(is_number("12_345") == false);  // Guión bajo no permitido
}

TEST(is_number_leading_zeros) {
    assert(is_number("007") == true);     // Ceros al inicio son válidos
    assert(is_number("00000") == true);
}

TEST(is_number_large_numbers) {
    assert(is_number("999999999999") == true);
    assert(is_number("1234567890") == true);
}

// ============================================================================
// TESTS PARA trim_whitespace()
// ============================================================================

TEST(trim_whitespace_leading) {
    char str[] = "   hello";
    trim_whitespace(str);
    assert(strcmp(str, "hello") == 0);
}

TEST(trim_whitespace_trailing) {
    char str[] = "hello   ";
    trim_whitespace(str);
    assert(strcmp(str, "hello") == 0);
}

TEST(trim_whitespace_both_sides) {
    char str[] = "   hello   ";
    trim_whitespace(str);
    assert(strcmp(str, "hello") == 0);
}

TEST(trim_whitespace_middle_spaces) {
    char str[] = "  hello  world  ";
    trim_whitespace(str);
    assert(strcmp(str, "hello  world") == 0);  // Espacios del medio se mantienen
}

TEST(trim_whitespace_tabs_and_newlines) {
    char str[] = "\t\nhello\n\t";
    trim_whitespace(str);
    assert(strcmp(str, "hello") == 0);
}

TEST(trim_whitespace_only_spaces) {
    char str[] = "     ";
    trim_whitespace(str);
    assert(strcmp(str, "") == 0);
}

TEST(trim_whitespace_empty_string) {
    char str[] = "";
    trim_whitespace(str);
    assert(strcmp(str, "") == 0);
}

TEST(trim_whitespace_no_spaces) {
    char str[] = "hello";
    trim_whitespace(str);
    assert(strcmp(str, "hello") == 0);
}

TEST(trim_whitespace_null_safe) {
    trim_whitespace(NULL);  // No debe crashear
}

TEST(trim_whitespace_mixed_whitespace) {
    char str[] = " \t \n hello \r\n \t ";
    trim_whitespace(str);
    assert(strcmp(str, "hello") == 0);
}

// ============================================================================
// TESTS DE INTEGRACIÓN
// ============================================================================

TEST(integration_color_parsing) {
    // Simular parseo de color desde input de usuario
    char input[] = "  BRIGHT_RED  ";
    trim_whitespace(input);
    to_lowercase(input);
    assert(strcmp(input, "bright_red") == 0);
}

TEST(integration_alignment_width) {
    // Verificar que un token de alineación es número
    char token1[] = "20";
    assert(is_number(token1) == true);
    
    char token2[] = "abc";
    assert(is_number(token2) == false);
}

TEST(integration_format_spec_parsing) {
    // Simular parseo de especificadores
    char spec1[] = "  BOLD  ";
    trim_whitespace(spec1);
    to_lowercase(spec1);
    assert(strcmp(spec1, "bold") == 0);
    
    char spec2[] = "BG_WHITE";
    to_lowercase(spec2);
    assert(strcmp(spec2, "bg_white") == 0);
}

// ============================================================================
// TESTS DE EDGE CASES
// ============================================================================

TEST(edge_case_very_long_string) {
    char str[1000];
    memset(str, 'A', 999);
    str[999] = '\0';
    
    to_lowercase(str);
    
    // Verificar que todos sean 'a'
    for (int i = 0; i < 999; i++) {
        assert(str[i] == 'a');
    }
}

TEST(edge_case_unicode_safety) {
    // Caracteres extendidos (Latin-1)
    char str[] = "Café";  // Tiene é (0xE9)
    to_lowercase(str);
    // No debe crashear, aunque el resultado puede variar
}

TEST(edge_case_single_char) {
    char str1[] = "A";
    to_lowercase(str1);
    assert(strcmp(str1, "a") == 0);
    
    char str2[] = "5";
    assert(is_number(str2) == true);
    
    char str3[] = " ";
    trim_whitespace(str3);
    assert(strcmp(str3, "") == 0);
}

TEST(edge_case_repeated_operations) {
    char str[] = "HELLO";
    
    // Aplicar varias veces
    to_lowercase(str);
    to_lowercase(str);
    to_lowercase(str);
    
    assert(strcmp(str, "hello") == 0);
}

// ============================================================================
// TESTS DE PERFORMANCE (informativo)
// ============================================================================

TEST(performance_large_number_validation) {
    // Validar que is_number() es eficiente
    const char* numbers[] = {
        "0", "1", "12", "123", "1234", "12345",
        "123456", "1234567", "12345678", "123456789"
    };
    
    for (int i = 0; i < 10; i++) {
        assert(is_number(numbers[i]) == true);
    }
}

// ============================================================================
// MAIN
// ============================================================================

int main(void) {
    printf("\n");
    printf("═══════════════════════════════════════════════════════════\n");
    printf("  String Utils Module - Unit Tests\n");
    printf("═══════════════════════════════════════════════════════════\n");
    printf("\n");
    
    printf("Testing to_lowercase():\n");
    RUN_TEST(to_lowercase_basic);
    RUN_TEST(to_lowercase_mixed_case);
    RUN_TEST(to_lowercase_already_lower);
    RUN_TEST(to_lowercase_with_numbers);
    RUN_TEST(to_lowercase_with_special_chars);
    RUN_TEST(to_lowercase_empty_string);
    RUN_TEST(to_lowercase_null_safe);
    RUN_TEST(to_lowercase_colors);
    printf("\n");
    
    printf("Testing is_number():\n");
    RUN_TEST(is_number_valid_integers);
    RUN_TEST(is_number_invalid_strings);
    RUN_TEST(is_number_empty_and_null);
    RUN_TEST(is_number_with_spaces);
    RUN_TEST(is_number_negative);
    RUN_TEST(is_number_special_chars);
    RUN_TEST(is_number_leading_zeros);
    RUN_TEST(is_number_large_numbers);
    printf("\n");
    
    printf("Testing trim_whitespace():\n");
    RUN_TEST(trim_whitespace_leading);
    RUN_TEST(trim_whitespace_trailing);
    RUN_TEST(trim_whitespace_both_sides);
    RUN_TEST(trim_whitespace_middle_spaces);
    RUN_TEST(trim_whitespace_tabs_and_newlines);
    RUN_TEST(trim_whitespace_only_spaces);
    RUN_TEST(trim_whitespace_empty_string);
    RUN_TEST(trim_whitespace_no_spaces);
    RUN_TEST(trim_whitespace_null_safe);
    RUN_TEST(trim_whitespace_mixed_whitespace);
    printf("\n");
    
    printf("Integration tests:\n");
    RUN_TEST(integration_color_parsing);
    RUN_TEST(integration_alignment_width);
    RUN_TEST(integration_format_spec_parsing);
    printf("\n");
    
    printf("Edge cases:\n");
    RUN_TEST(edge_case_very_long_string);
    RUN_TEST(edge_case_unicode_safety);
    RUN_TEST(edge_case_single_char);
    RUN_TEST(edge_case_repeated_operations);
    printf("\n");
    
    printf("Performance tests:\n");
    RUN_TEST(performance_large_number_validation);
    printf("\n");
    
    printf("═══════════════════════════════════════════════════════════\n");
    printf("  Results: %d tests passed ✓\n", tests_passed);
    printf("═══════════════════════════════════════════════════════════\n");
    printf("\n");
    
    return 0;
}