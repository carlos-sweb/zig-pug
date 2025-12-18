/**
 * @file debug_alignment.c
 * @brief Diagnóstico para ver qué genera print_aligned
 */

#include "text_alignment.h"
#include <stdio.h>
#include <string.h>

int main(void) {
    printf("Testing print_aligned output:\n");
    printf("Expected: 'Hello     ' (Hello + 5 spaces, total 10 chars)\n");
    printf("Actual  : '");
    print_aligned("Hello", ALIGN_LEFT, 10, ' ');
    printf("'\n");
    
    printf("\nTesting character by character:\n");
    printf("Testing with width 10:\n");
    char test[] = "Hello";
    int text_len = strlen(test);
    int width = 10;
    int padding = width - text_len;
    
    printf("Text length: %d\n", text_len);
    printf("Width: %d\n", width);
    printf("Padding needed: %d\n", padding);
    
    printf("\nManual output: '");
    printf("%s", test);
    for (int i = 0; i < padding; i++) {
        printf("%c", ' ');
    }
    printf("'\n");
    
    printf("\nTesting print_aligned:\n");
    printf("LEFT:   '");
    print_aligned("Hello", ALIGN_LEFT, 10, ' ');
    printf("'\n");
    
    printf("RIGHT:  '");
    print_aligned("Hello", ALIGN_RIGHT, 10, ' ');
    printf("'\n");
    
    printf("CENTER: '");
    print_aligned("Hello", ALIGN_CENTER, 10, ' ');
    printf("'\n");
    
    return 0;
}