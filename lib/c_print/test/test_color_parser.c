/**
 * @file test_color_parser.c
 * @brief Tests unitarios para el módulo color_parser
 * 
 * Este archivo demuestra cómo testear módulos individuales
 * de forma independiente.
 */

#include "color_parser.h"
#include "ansi_codes.h"
#include <stdio.h>
#include <string.h>
#include <assert.h>

// Macro para facilitar tests
#define TEST(name) static void test_##name(void)
#define RUN_TEST(name) do { \
    printf("  Running: %s... ", #name); \
    test_##name(); \
    printf("✓\n"); \
    tests_passed++; \
} while(0)

static int tests_passed = 0;

// ============================================================================
// TESTS PARA parse_text_color()
// ============================================================================

TEST(parse_text_color_standard_colors) {
    assert(parse_text_color("red") == COLOR_RED);
    assert(parse_text_color("green") == COLOR_GREEN);
    assert(parse_text_color("blue") == COLOR_BLUE);
    assert(parse_text_color("yellow") == COLOR_YELLOW);
    assert(parse_text_color("cyan") == COLOR_CYAN);
    assert(parse_text_color("magenta") == COLOR_MAGENTA);
    assert(parse_text_color("white") == COLOR_WHITE);
    assert(parse_text_color("black") == COLOR_BLACK);
}

TEST(parse_text_color_bright_colors) {
    assert(parse_text_color("bright_red") == COLOR_BRIGHT_RED);
    assert(parse_text_color("bright_green") == COLOR_BRIGHT_GREEN);
    assert(parse_text_color("bright_blue") == COLOR_BRIGHT_BLUE);
    assert(parse_text_color("bright_yellow") == COLOR_BRIGHT_YELLOW);
}

TEST(parse_text_color_case_insensitive) {
    assert(parse_text_color("RED") == COLOR_RED);
    assert(parse_text_color("Red") == COLOR_RED);
    assert(parse_text_color("rEd") == COLOR_RED);
    assert(parse_text_color("BRIGHT_GREEN") == COLOR_BRIGHT_GREEN);
}

TEST(parse_text_color_invalid_input) {
    assert(parse_text_color("invalid") == COLOR_RESET);
    assert(parse_text_color("") == COLOR_RESET);
    assert(parse_text_color(NULL) == COLOR_RESET);
    assert(parse_text_color("purple") == COLOR_RESET);  // No existe
}

// ============================================================================
// TESTS PARA parse_bg_color()
// ============================================================================

TEST(parse_bg_color_with_prefix) {
    assert(parse_bg_color("bg_red") == BG_RED);
    assert(parse_bg_color("bg_green") == BG_GREEN);
    assert(parse_bg_color("bg_blue") == BG_BLUE);
    assert(parse_bg_color("bg_bright_cyan") == BG_BRIGHT_CYAN);
}

TEST(parse_bg_color_without_prefix) {
    // Debe funcionar con o sin prefijo "bg_"
    assert(parse_bg_color("red") == BG_RED);
    assert(parse_bg_color("green") == BG_GREEN);
    assert(parse_bg_color("blue") == BG_BLUE);
}

TEST(parse_bg_color_case_insensitive) {
    assert(parse_bg_color("BG_RED") == BG_RED);
    assert(parse_bg_color("Bg_Green") == BG_GREEN);
    assert(parse_bg_color("bg_BLUE") == BG_BLUE);
}

TEST(parse_bg_color_invalid_input) {
    assert(parse_bg_color("invalid") == BG_RESET);
    assert(parse_bg_color("") == BG_RESET);
    assert(parse_bg_color(NULL) == BG_RESET);
}

// ============================================================================
// TESTS PARA parse_text_style()
// ============================================================================

TEST(parse_text_style_all_styles) {
    assert(parse_text_style("bold") == STYLE_BOLD);
    assert(parse_text_style("dim") == STYLE_DIM);
    assert(parse_text_style("italic") == STYLE_ITALIC);
    assert(parse_text_style("underline") == STYLE_UNDERLINE);
    assert(parse_text_style("blink") == STYLE_BLINK);
    assert(parse_text_style("reverse") == STYLE_REVERSE);
    assert(parse_text_style("hidden") == STYLE_HIDDEN);
    assert(parse_text_style("strikethrough") == STYLE_STRIKETHROUGH);
}

TEST(parse_text_style_case_insensitive) {
    assert(parse_text_style("BOLD") == STYLE_BOLD);
    assert(parse_text_style("Bold") == STYLE_BOLD);
    assert(parse_text_style("bOlD") == STYLE_BOLD);
    assert(parse_text_style("UNDERLINE") == STYLE_UNDERLINE);
}

TEST(parse_text_style_invalid_input) {
    assert(parse_text_style("invalid") == STYLE_RESET);
    assert(parse_text_style("") == STYLE_RESET);
    assert(parse_text_style(NULL) == STYLE_RESET);
    assert(parse_text_style("strong") == STYLE_RESET);  // No existe
}

// ============================================================================
// TESTS PARA is_background_color()
// ============================================================================

TEST(is_background_color_detection) {
    assert(is_background_color("bg_red") == true);
    assert(is_background_color("bg_green") == true);
    assert(is_background_color("BG_BLUE") == true);
    assert(is_background_color("Bg_Yellow") == true);
    
    assert(is_background_color("red") == false);
    assert(is_background_color("green") == false);
    assert(is_background_color("bold") == false);
    assert(is_background_color("") == false);
    assert(is_background_color(NULL) == false);
}

// ============================================================================
// TESTS DE INTEGRACIÓN
// ============================================================================

TEST(integration_multiple_parses) {
    // Simular parseo de múltiples especificadores
    TextColor fg = parse_text_color("red");
    BackgroundColor bg = parse_bg_color("bg_white");
    TextStyle style = parse_text_style("bold");
    
    assert(fg == COLOR_RED);
    assert(bg == BG_WHITE);
    assert(style == STYLE_BOLD);
}

TEST(integration_edge_cases) {
    // Espacios, tabs, etc. (después del trim interno)
    assert(parse_text_color("red") == COLOR_RED);
    assert(parse_bg_color("bg_green") == BG_GREEN);
    assert(parse_text_style("bold") == STYLE_BOLD);
}

// ============================================================================
// MAIN - Ejecutor de tests
// ============================================================================

int main(void) {
    printf("\n");
    printf("═══════════════════════════════════════════════════════════\n");
    printf("  Color Parser Module - Unit Tests\n");
    printf("═══════════════════════════════════════════════════════════\n");
    printf("\n");
    
    printf("Testing parse_text_color():\n");
    RUN_TEST(parse_text_color_standard_colors);
    RUN_TEST(parse_text_color_bright_colors);
    RUN_TEST(parse_text_color_case_insensitive);
    RUN_TEST(parse_text_color_invalid_input);
    printf("\n");
    
    printf("Testing parse_bg_color():\n");
    RUN_TEST(parse_bg_color_with_prefix);
    RUN_TEST(parse_bg_color_without_prefix);
    RUN_TEST(parse_bg_color_case_insensitive);
    RUN_TEST(parse_bg_color_invalid_input);
    printf("\n");
    
    printf("Testing parse_text_style():\n");
    RUN_TEST(parse_text_style_all_styles);
    RUN_TEST(parse_text_style_case_insensitive);
    RUN_TEST(parse_text_style_invalid_input);
    printf("\n");
    
    printf("Testing is_background_color():\n");
    RUN_TEST(is_background_color_detection);
    printf("\n");
    
    printf("Integration tests:\n");
    RUN_TEST(integration_multiple_parses);
    RUN_TEST(integration_edge_cases);
    printf("\n");
    
    printf("═══════════════════════════════════════════════════════════\n");
    printf("  Results: %d tests passed ✓\n", tests_passed);
    printf("═══════════════════════════════════════════════════════════\n");
    printf("\n");
    
    return 0;
}