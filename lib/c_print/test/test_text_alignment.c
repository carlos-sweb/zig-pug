/**
 * @file test_text_alignment.c
 * @brief Tests unitarios para text_alignment usando redirección de stdout
 */

#include "text_alignment.h"
#include <stdio.h>
#include <string.h>
#include <assert.h>
#include <unistd.h>
#include <fcntl.h>

#define TEST(name) static void test_##name(void)
#define RUN_TEST(name) do { \
    fprintf(stderr, "  Running: %s... ", #name); \
    test_##name(); \
    fprintf(stderr, "✓\n"); \
    tests_passed++; \
} while(0)

static int tests_passed = 0;
static char captured_output[2048];

// Función para capturar stdout
static void capture_stdout_start(void) {
    fflush(stdout);
    memset(captured_output, 0, sizeof(captured_output));
}

static void capture_stdout_end(void) {
    fflush(stdout);
}

// Usar pipes para capturar stdout
static int stdout_pipe[2];
static int saved_stdout;

static void start_capture(void) {
    saved_stdout = dup(STDOUT_FILENO);
    pipe(stdout_pipe);
    dup2(stdout_pipe[1], STDOUT_FILENO);
    close(stdout_pipe[1]);
    memset(captured_output, 0, sizeof(captured_output));
}

static void end_capture(void) {
    fflush(stdout);
    
    // Restaurar stdout primero
    dup2(saved_stdout, STDOUT_FILENO);
    close(saved_stdout);
    
    // Hacer el read no bloqueante
    int flags = fcntl(stdout_pipe[0], F_GETFL, 0);
    fcntl(stdout_pipe[0], F_SETFL, flags | O_NONBLOCK);
    
    // Leer lo que haya (puede ser 0 bytes)
    ssize_t bytes_read = read(stdout_pipe[0], captured_output, sizeof(captured_output) - 1);
    if (bytes_read > 0) {
        captured_output[bytes_read] = '\0';
    }
    
    close(stdout_pipe[0]);
}

// ============================================================================
// TESTS PARA print_aligned() - LEFT
// ============================================================================

TEST(align_left_basic) {
    start_capture();
    print_aligned("Hello", ALIGN_LEFT, 10, ' ');
    end_capture();
    
    if (strcmp(captured_output, "Hello     ") != 0) {
        fprintf(stderr, "\n  Expected: 'Hello     ' (10 chars)\n");
        fprintf(stderr, "  Got:      '");
        for (size_t i = 0; i < strlen(captured_output); i++) {
            if (captured_output[i] == ' ') {
                fprintf(stderr, "·");
            } else {
                fprintf(stderr, "%c", captured_output[i]);
            }
        }
        fprintf(stderr, "' (%zu chars)\n", strlen(captured_output));
    }
    
    assert(strcmp(captured_output, "Hello     ") == 0);
}

TEST(align_left_exact_width) {
    start_capture();
    print_aligned("Hello", ALIGN_LEFT, 5, ' ');
    end_capture();
    assert(strcmp(captured_output, "Hello") == 0);
}

TEST(align_left_longer_than_width) {
    start_capture();
    print_aligned("Hello World", ALIGN_LEFT, 5, ' ');
    end_capture();
    assert(strcmp(captured_output, "Hello World") == 0);
}

TEST(align_left_custom_fill) {
    start_capture();
    print_aligned("Hi", ALIGN_LEFT, 10, '*');
    end_capture();
    assert(strcmp(captured_output, "Hi********") == 0);
}

TEST(align_left_dash_fill) {
    start_capture();
    print_aligned("Test", ALIGN_LEFT, 10, '-');
    end_capture();
    assert(strcmp(captured_output, "Test------") == 0);
}

TEST(align_left_empty_string) {
    start_capture();
    print_aligned("", ALIGN_LEFT, 5, ' ');
    end_capture();
    assert(strcmp(captured_output, "     ") == 0);
}

// ============================================================================
// TESTS PARA print_aligned() - RIGHT
// ============================================================================

TEST(align_right_basic) {
    start_capture();
    print_aligned("Hello", ALIGN_RIGHT, 10, ' ');
    end_capture();
    assert(strcmp(captured_output, "     Hello") == 0);
}

TEST(align_right_exact_width) {
    start_capture();
    print_aligned("Hello", ALIGN_RIGHT, 5, ' ');
    end_capture();
    assert(strcmp(captured_output, "Hello") == 0);
}

TEST(align_right_longer_than_width) {
    start_capture();
    print_aligned("Hello World", ALIGN_RIGHT, 5, ' ');
    end_capture();
    assert(strcmp(captured_output, "Hello World") == 0);
}

TEST(align_right_custom_fill) {
    start_capture();
    print_aligned("Hi", ALIGN_RIGHT, 10, '*');
    end_capture();
    assert(strcmp(captured_output, "********Hi") == 0);
}

TEST(align_right_dash_fill) {
    start_capture();
    print_aligned("Test", ALIGN_RIGHT, 10, '-');
    end_capture();
    assert(strcmp(captured_output, "------Test") == 0);
}

TEST(align_right_numbers) {
    start_capture();
    print_aligned("42", ALIGN_RIGHT, 10, ' ');
    end_capture();
    assert(strcmp(captured_output, "        42") == 0);
}

// ============================================================================
// TESTS PARA print_aligned() - CENTER
// ============================================================================

TEST(align_center_even_padding) {
    start_capture();
    print_aligned("Hi", ALIGN_CENTER, 10, ' ');
    end_capture();
    assert(strcmp(captured_output, "    Hi    ") == 0);
}

TEST(align_center_odd_padding) {
    start_capture();
    print_aligned("Hi", ALIGN_CENTER, 9, ' ');
    end_capture();
    assert(strcmp(captured_output, "   Hi    ") == 0);
}

TEST(align_center_exact_width) {
    start_capture();
    print_aligned("Hello", ALIGN_CENTER, 5, ' ');
    end_capture();
    assert(strcmp(captured_output, "Hello") == 0);
}

TEST(align_center_custom_fill) {
    start_capture();
    print_aligned("X", ALIGN_CENTER, 9, '*');
    end_capture();
    assert(strcmp(captured_output, "****X****") == 0);
}

TEST(align_center_longer_than_width) {
    start_capture();
    print_aligned("Hello World", ALIGN_CENTER, 5, ' ');
    end_capture();
    assert(strcmp(captured_output, "Hello World") == 0);
}

TEST(align_center_title) {
    start_capture();
    print_aligned("TITLE", ALIGN_CENTER, 20, '-');
    end_capture();
    assert(strcmp(captured_output, "-------TITLE--------") == 0);
}

// ============================================================================
// TESTS PARA is_alignment()
// ============================================================================

TEST(is_alignment_left) {
    TextAlign align;
    int width;
    char fill_char;
    
    bool result = is_alignment("<20", &align, &width, &fill_char);
    assert(result == true);
    assert(align == ALIGN_LEFT);
    assert(width == 20);
    assert(fill_char == ' ');
}

TEST(is_alignment_right) {
    TextAlign align;
    int width;
    char fill_char;
    
    bool result = is_alignment(">30", &align, &width, &fill_char);
    assert(result == true);
    assert(align == ALIGN_RIGHT);
    assert(width == 30);
    assert(fill_char == ' ');
}

TEST(is_alignment_center) {
    TextAlign align;
    int width;
    char fill_char;
    
    bool result = is_alignment("^15", &align, &width, &fill_char);
    assert(result == true);
    assert(align == ALIGN_CENTER);
    assert(width == 15);
    assert(fill_char == ' ');
}

TEST(is_alignment_with_fill_char_star) {
    TextAlign align;
    int width;
    char fill_char;
    
    bool result = is_alignment("*^20", &align, &width, &fill_char);
    assert(result == true);
    assert(align == ALIGN_CENTER);
    assert(width == 20);
    assert(fill_char == '*');
}

TEST(is_alignment_with_fill_char_dash) {
    TextAlign align;
    int width;
    char fill_char;
    
    bool result = is_alignment("->30", &align, &width, &fill_char);
    assert(result == true);
    assert(align == ALIGN_RIGHT);
    assert(width == 30);
    assert(fill_char == '-');
}

TEST(is_alignment_with_fill_char_dot) {
    TextAlign align;
    int width;
    char fill_char;
    
    bool result = is_alignment(".>25", &align, &width, &fill_char);
    assert(result == true);
    assert(align == ALIGN_RIGHT);
    assert(width == 25);
    assert(fill_char == '.');
}

TEST(is_alignment_with_fill_char_equals) {
    TextAlign align;
    int width;
    char fill_char;
    
    bool result = is_alignment("=^40", &align, &width, &fill_char);
    assert(result == true);
    assert(align == ALIGN_CENTER);
    assert(width == 40);
    assert(fill_char == '=');
}

TEST(is_alignment_invalid_no_width) {
    TextAlign align;
    int width;
    char fill_char;
    
    bool result = is_alignment("<", &align, &width, &fill_char);
    assert(result == false);
}

TEST(is_alignment_invalid_no_direction) {
    TextAlign align;
    int width;
    char fill_char;
    
    bool result = is_alignment("20", &align, &width, &fill_char);
    assert(result == false);
}

TEST(is_alignment_invalid_empty) {
    TextAlign align;
    int width;
    char fill_char;
    
    bool result = is_alignment("", &align, &width, &fill_char);
    assert(result == false);
}

TEST(is_alignment_invalid_null) {
    TextAlign align;
    int width;
    char fill_char;
    
    bool result = is_alignment(NULL, &align, &width, &fill_char);
    assert(result == false);
}

TEST(is_alignment_large_width) {
    TextAlign align;
    int width;
    char fill_char;
    
    bool result = is_alignment("<100", &align, &width, &fill_char);
    assert(result == true);
    assert(width == 100);
}

// ============================================================================
// TESTS DE INTEGRACIÓN
// ============================================================================

TEST(integration_table_borders) {
    start_capture();
    print_aligned("", ALIGN_CENTER, 50, '-');
    end_capture();
    
    assert(strlen(captured_output) == 50);
    for (size_t i = 0; i < strlen(captured_output); i++) {
        assert(captured_output[i] == '-');
    }
}

TEST(integration_menu_title) {
    start_capture();
    print_aligned(" MENU ", ALIGN_CENTER, 40, '=');
    end_capture();
    
    assert(strstr(captured_output, " MENU ") != NULL);
    assert(captured_output[0] == '=');
    assert(captured_output[strlen(captured_output) - 1] == '=');
}

TEST(integration_dot_leaders) {
    start_capture();
    print_aligned("Item", ALIGN_LEFT, 30, '.');
    end_capture();
    
    assert(strncmp(captured_output, "Item", 4) == 0);
    assert(captured_output[strlen(captured_output) - 1] == '.');
}

TEST(integration_price_alignment) {
    start_capture();
    print_aligned("$1,234.56", ALIGN_RIGHT, 15, ' ');
    end_capture();
    
    assert(strlen(captured_output) == 15);
    assert(captured_output[strlen(captured_output) - 1] == '6');
}

// ============================================================================
// TESTS DE EDGE CASES
// ============================================================================

TEST(edge_case_width_zero) {
    start_capture();
    print_aligned("Hello", ALIGN_LEFT, 0, ' ');
    end_capture();
    assert(strcmp(captured_output, "Hello") == 0);
}

TEST(edge_case_width_one) {
    start_capture();
    print_aligned("Hello", ALIGN_LEFT, 1, ' ');
    end_capture();
    assert(strcmp(captured_output, "Hello") == 0);
}

TEST(edge_case_null_text) {
    start_capture();
    print_aligned(NULL, ALIGN_LEFT, 10, ' ');
    end_capture();
    // No debe crashear
}

TEST(edge_case_very_long_text) {
    start_capture();
    char long_text[200];
    memset(long_text, 'A', 199);
    long_text[199] = '\0';
    print_aligned(long_text, ALIGN_LEFT, 10, ' ');
    end_capture();
    
    assert(strlen(captured_output) == 199);
}

TEST(edge_case_special_fill_chars) {
    start_capture();
    print_aligned("X", ALIGN_CENTER, 9, '0');
    end_capture();
    assert(strcmp(captured_output, "0000X0000") == 0);
    
    start_capture();
    print_aligned("X", ALIGN_CENTER, 9, 'A');
    end_capture();
    assert(strcmp(captured_output, "AAAAXAAAA") == 0);
}

TEST(edge_case_unicode_fill) {
    start_capture();
    print_aligned("Hi", ALIGN_CENTER, 10, '#');
    end_capture();
    assert(strlen(captured_output) == 10);
}

// ============================================================================
// TESTS DE CONSISTENCIA
// ============================================================================

TEST(consistency_all_alignments_same_width) {
    char left[100], right[100], center[100];
    
    start_capture();
    print_aligned("Test", ALIGN_LEFT, 20, ' ');
    end_capture();
    strcpy(left, captured_output);
    
    start_capture();
    print_aligned("Test", ALIGN_RIGHT, 20, ' ');
    end_capture();
    strcpy(right, captured_output);
    
    start_capture();
    print_aligned("Test", ALIGN_CENTER, 20, ' ');
    end_capture();
    strcpy(center, captured_output);
    
    assert(strlen(left) == strlen(right));
    assert(strlen(right) == strlen(center));
    assert(strlen(center) == 20);
}

TEST(consistency_fill_char_count) {
    start_capture();
    print_aligned("ABC", ALIGN_LEFT, 10, '*');
    end_capture();
    
    int star_count = 0;
    for (size_t i = 0; i < strlen(captured_output); i++) {
        if (captured_output[i] == '*') star_count++;
    }
    assert(star_count == 7);
}

// ============================================================================
// TESTS PARA FORMATOS COMPLEJOS
// ============================================================================

TEST(complex_invoice_line) {
    start_capture();
    print_aligned("Total", ALIGN_LEFT, 30, '.');
    end_capture();
    
    assert(strncmp(captured_output, "Total", 5) == 0);
    assert(captured_output[strlen(captured_output) - 1] == '.');
    assert(strlen(captured_output) == 30);
}

TEST(complex_separator_line) {
    start_capture();
    print_aligned("", ALIGN_CENTER, 60, '=');
    end_capture();
    
    for (size_t i = 0; i < strlen(captured_output); i++) {
        assert(captured_output[i] == '=');
    }
    assert(strlen(captured_output) == 60);
}

TEST(complex_title_with_borders) {
    start_capture();
    print_aligned(" REPORT ", ALIGN_CENTER, 50, '-');
    end_capture();
    
    assert(strstr(captured_output, " REPORT ") != NULL);
    assert(captured_output[0] == '-');
    assert(captured_output[strlen(captured_output) - 1] == '-');
}

// ============================================================================
// MAIN
// ============================================================================

int main(void) {
    fprintf(stderr, "\n");
    fprintf(stderr, "═══════════════════════════════════════════════════════════\n");
    fprintf(stderr, "  Text Alignment Module - Unit Tests\n");
    fprintf(stderr, "═══════════════════════════════════════════════════════════\n");
    fprintf(stderr, "\n");
    
    fprintf(stderr, "Testing print_aligned() - LEFT:\n");
    RUN_TEST(align_left_basic);
    RUN_TEST(align_left_exact_width);
    RUN_TEST(align_left_longer_than_width);
    RUN_TEST(align_left_custom_fill);
    RUN_TEST(align_left_dash_fill);
    RUN_TEST(align_left_empty_string);
    fprintf(stderr, "\n");
    
    fprintf(stderr, "Testing print_aligned() - RIGHT:\n");
    RUN_TEST(align_right_basic);
    RUN_TEST(align_right_exact_width);
    RUN_TEST(align_right_longer_than_width);
    RUN_TEST(align_right_custom_fill);
    RUN_TEST(align_right_dash_fill);
    RUN_TEST(align_right_numbers);
    fprintf(stderr, "\n");
    
    fprintf(stderr, "Testing print_aligned() - CENTER:\n");
    RUN_TEST(align_center_even_padding);
    RUN_TEST(align_center_odd_padding);
    RUN_TEST(align_center_exact_width);
    RUN_TEST(align_center_custom_fill);
    RUN_TEST(align_center_longer_than_width);
    RUN_TEST(align_center_title);
    fprintf(stderr, "\n");
    
    fprintf(stderr, "Testing is_alignment():\n");
    RUN_TEST(is_alignment_left);
    RUN_TEST(is_alignment_right);
    RUN_TEST(is_alignment_center);
    RUN_TEST(is_alignment_with_fill_char_star);
    RUN_TEST(is_alignment_with_fill_char_dash);
    RUN_TEST(is_alignment_with_fill_char_dot);
    RUN_TEST(is_alignment_with_fill_char_equals);
    RUN_TEST(is_alignment_invalid_no_width);
    RUN_TEST(is_alignment_invalid_no_direction);
    RUN_TEST(is_alignment_invalid_empty);
    RUN_TEST(is_alignment_invalid_null);
    RUN_TEST(is_alignment_large_width);
    fprintf(stderr, "\n");
    
    fprintf(stderr, "Integration tests:\n");
    RUN_TEST(integration_table_borders);
    RUN_TEST(integration_menu_title);
    RUN_TEST(integration_dot_leaders);
    RUN_TEST(integration_price_alignment);
    fprintf(stderr, "\n");
    
    fprintf(stderr, "Edge cases:\n");
    RUN_TEST(edge_case_width_zero);
    RUN_TEST(edge_case_width_one);
    RUN_TEST(edge_case_null_text);
    RUN_TEST(edge_case_very_long_text);
    RUN_TEST(edge_case_special_fill_chars);
    RUN_TEST(edge_case_unicode_fill);
    fprintf(stderr, "\n");
    
    fprintf(stderr, "Consistency tests:\n");
    RUN_TEST(consistency_all_alignments_same_width);
    RUN_TEST(consistency_fill_char_count);
    fprintf(stderr, "\n");
    
    fprintf(stderr, "Complex formats:\n");
    RUN_TEST(complex_invoice_line);
    RUN_TEST(complex_separator_line);
    RUN_TEST(complex_title_with_borders);
    fprintf(stderr, "\n");
    
    fprintf(stderr, "═══════════════════════════════════════════════════════════\n");
    fprintf(stderr, "  Results: %d tests passed ✓\n", tests_passed);
    fprintf(stderr, "═══════════════════════════════════════════════════════════\n");
    fprintf(stderr, "\n");
    
    return 0;
}