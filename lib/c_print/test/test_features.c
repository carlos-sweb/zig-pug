#include "c_print.h"

int main() {
    printf("╔══════════════════════════════════════════════════════════════╗\n");
    printf("║     c_print - Prueba de Nuevas Características               ║\n");
    printf("╚══════════════════════════════════════════════════════════════╝\n\n");
    
    // ========== 1. PRECISIÓN EN FLOATS ==========
    printf("========== 1. PRECISIÓN EN FLOATS (.N) ==========\n");
    c_print("Pi sin precisión:     {f}\n", 3.14159265359);
    c_print("Pi con .2:            {f:.2}\n", 3.14159265359);
    c_print("Pi con .4:            {f:.4}\n", 3.14159265359);
    c_print("Pi con .8:            {f:.8}\n", 3.14159265359);
    c_print("Precio con .2:        ${f:.2}\n", 99.999);
    c_print("Con color:            {f:.2:green:bold}\n", 3.14159);
    printf("\n");
    
    // ========== 2. PADDING CON CEROS ==========
    printf("========== 2. PADDING CON CEROS (0N) ==========\n");
    c_print("ID sin padding:       {d}\n", 42);
    c_print("ID con 05:            {d:05}\n", 42);
    c_print("ID con 08:            {d:08}\n", 42);
    c_print("Hex con 04:           {x:04}\n", 255);
    c_print("Hex con 08:           {x:08}\n", 255);
    c_print("Con color:            {d:06:cyan:bold}\n", 123);
    printf("\n");
    
    // ========== 3. SEPARADORES DE MILES ==========
    printf("========== 3. SEPARADORES DE MILES (, o _) ==========\n");
    c_print("Sin separador:        {d}\n", 1234567);
    c_print("Con coma (,):         {d:,}\n", 1234567);
    c_print("Con guión bajo (_):   {d:_}\n", 1234567);
    c_print("Número grande:        {d:,}\n", 1000000000);
    c_print("Con color:            ${d:,:green:bold}\n", 5000000);
    printf("\n");
    
    // ========== 4. BINARIO ==========
    printf("========== 4. FORMATO BINARIO (b y #b) ==========\n");
    c_print("42 en binario:        {b}\n", 42);
    c_print("42 con prefijo:       {#b}\n", 42);
    c_print("255 en binario:       {b}\n", 255);
    c_print("255 con prefijo:      {#b}\n", 255);
    c_print("Con color:            {#b:cyan:bold}\n", 170);
    printf("\n");
    
    // ========== 5. PREFIJOS PARA HEX Y OCTAL ==========
    printf("========== 5. PREFIJOS (#) ==========\n");
    c_print("Hex sin prefijo:      {x}\n", 255);
    c_print("Hex con prefijo:      {#x}\n", 255);
    c_print("Octal sin prefijo:    {o}\n", 64);
    c_print("Octal con prefijo:    {#o}\n", 64);
    c_print("Con padding y #:      {#x:08}\n", 255);
    printf("\n");
    
    // ========== 6. PORCENTAJES ==========
    printf("========== 6. PORCENTAJES (%%) ==========\n");
    c_print("Sin porcentaje:       {f}\n", 0.856);
    c_print("Como porcentaje:      {f:%}\n", 0.856);
    c_print("Con precisión .1:     {f:.1%}\n", 0.856);
    c_print("Con precisión .2:     {f:.2%}\n", 0.5);
    c_print("Con color:            {f:.1%:green:bold}\n", 0.95);
    printf("\n");
    
    // ========== 7. SIGNOS SIEMPRE VISIBLES ==========
    printf("========== 7. SIGNOS (+) ==========\n");
    c_print("Sin signo:            {d}\n", 42);
    c_print("Con signo +:          {d:+}\n", 42);
    c_print("Negativo con +:       {d:+}\n", -42);
    c_print("Temperatura:          {d:+}°C\n", 25);
    c_print("Diferencia:           {d:+}\n", -10);
    printf("\n");
    
    // ========== 8. COMBINACIONES COMPLEJAS ==========
    printf("========== 8. COMBINACIONES COMPLEJAS ==========\n");
    c_print("Precio:               ${f:.2:,}\n", 1234567.89);
    c_print("ID formateado:        {d:06:cyan}\n", 42);
    c_print("Porcentaje:           {f:.1%:green:bold}\n", 0.856);
    c_print("Hex con todo:         {#x:08:yellow}\n", 4095);
    c_print("Número grande:        {d:,:_>15:bright_green}\n", 9876543);
    printf("\n");
    
    // ========== 9. TABLA CON FORMATO MEJORADO ==========
    printf("========== 9. TABLA CON FORMATO MEJORADO ==========\n");
    c_print("+{s:-^20}+{s:-^15}+{s:-^15}+\n", "", "", "");
    c_print("| {s:^20:cyan:bold} | {s:^15:cyan:bold} | {s:^15:cyan:bold} |\n", 
            "Producto", "Cantidad", "Precio");
    c_print("+{s:-^20}+{s:-^15}+{s:-^15}+\n", "", "", "");
    c_print("| {s:<20} | {d:^15:,} | ${f:>13:.2:green:bold} |\n",
            "Laptop Gaming", 1234, 1599.99);
    c_print("| {s:<20} | {d:^15:,} | ${f:>13:.2:green:bold} |\n",
            "Mouse Inalámbrico", 5678, 49.99);
    c_print("| {s:<20} | {d:^15:,} | ${f:>13:.2:green:bold} |\n",
            "Teclado Mecánico", 9012, 149.99);
    c_print("+{s:-^20}+{s:-^15}+{s:-^15}+\n", "", "", "");
    printf("\n");
    
    // ========== 10. FACTURA PROFESIONAL ==========
    printf("========== 10. FACTURA PROFESIONAL ==========\n");
    c_print("+{s:=^50:bright_white:bold}+\n", " FACTURA #00042 ");
    c_print("| {s:.<28} ${f:>17:.2:bright_green:bold} |\n", "Subtotal", 8250.50);
    c_print("| {s:.<28} ${f:>17:.2:yellow} |\n", "Descuento (10%)", 825.05);
    c_print("| {s:.<28} ${f:>17:.2:yellow} |\n", "IVA (21%)", 1559.25);
    c_print("+{s:-^50}+\n", "");
    c_print("| {s:.<28:bold} ${f:>17:.2:bright_cyan:bold} |\n", "TOTAL A PAGAR", 8984.70);
    c_print("+{s:=^50:bright_white:bold}+\n", "");
    printf("\n");
    
    // ========== 11. ESTADÍSTICAS ==========
    printf("========== 11. PANEL DE ESTADÍSTICAS ==========\n");
    c_print("╔{s:═^58}╗\n", "");
    c_print("║ {s:^58:bright_cyan:bold} ║\n", "ESTADÍSTICAS DEL SISTEMA");
    c_print("╠{s:═^58}╣\n", "");
    c_print("║ {s:.<25} {d:>30:,:bright_green:bold} ║\n", "Usuarios activos", 123456);
    c_print("║ {s:.<25} {d:>30:,:bright_green:bold} ║\n", "Peticiones/día", 9876543);
    c_print("║ {s:.<25} {f:>29:.1%:bright_yellow:bold} ║\n", "Uso de CPU", 0.67);
    c_print("║ {s:.<25} {f:>29:.1%:bright_yellow:bold} ║\n", "Uso de Memoria", 0.82);
    c_print("║ {s:.<25} ${f:>28:.2:bright_cyan:bold} ║\n", "Ingresos mensuales", 456789.50);
    c_print("╚{s:═^58}╝\n", "");
    printf("\n");
    
    // ========== 12. DATOS TÉCNICOS ==========
    printf("========== 12. DATOS TÉCNICOS ==========\n");
    c_print("ID del proceso:       {d:08:cyan}\n", 1234);
    c_print("Código de error:      {#x:08:red:bold}\n", 404);
    c_print("Flags (binario):      {#b:yellow}\n", 170);
    c_print("Permisos (octal):     {#o:green}\n", 755);
    c_print("Offset:               {d:+:dim}\n", -128);
    printf("\n");
    
    // ========== 13. MÉTRICAS DE RENDIMIENTO ==========
    printf("========== 13. MÉTRICAS DE RENDIMIENTO ==========\n");
    c_print("┌{s:─^40}┐\n", " RENDIMIENTO ");
    c_print("│ Tiempo de respuesta: {f:.2:green:bold}ms {s:>14} │\n", 45.67, "");
    c_print("│ Throughput: {d:,:yellow:bold} req/s {s:>16} │\n", 12345, "");
    c_print("│ Tasa de éxito: {f:.2%:bright_green:bold} {s:>18} │\n", 0.9987, "");
    c_print("│ Latencia p99: {f:.2:cyan:bold}ms {s:>19} │\n", 156.89, "");
    c_print("└{s:─^40}┘\n", "");
    printf("\n");
    
    // ========== 14. TEMPERATURA Y SENSORES ==========
    printf("========== 14. SENSORES Y ALERTAS ==========\n");
    c_print("🌡️  Temperatura CPU:    {d:+:red:bold}°C\n", 78);
    c_print("🌡️  Temperatura GPU:    {d:+:yellow:bold}°C\n", 65);
    c_print("💾 Espacio libre:       {d:,:green} GB\n", 512000);
    c_print("⚡ Energía consumida:   {f:.1:yellow} kWh\n", 245.7);
    c_print("📊 Progreso:            {f:.1%:bright_blue:bold}\n", 0.678);
    printf("\n");
    
    // ========== 15. CÓDIGO DE COLORES HEXADECIMAL ==========
    printf("========== 15. CÓDIGOS DE COLOR ==========\n");
    c_print("Rojo:    {#x:08:red}\n", 0xFF0000);
    c_print("Verde:   {#x:08:green}\n", 0x00FF00);
    c_print("Azul:    {#x:08:blue}\n", 0x0000FF);
    c_print("Cian:    {#x:08:cyan}\n", 0x00FFFF);
    c_print("Magenta: {#x:08:magenta}\n", 0xFF00FF);
    printf("\n");
    
    printf("╔══════════════════════════════════════════════════════════════╗\n");
    printf("║                  FIN DE LAS PRUEBAS                          ║\n");
    printf("╚══════════════════════════════════════════════════════════════╝\n");
    
    return 0;
}