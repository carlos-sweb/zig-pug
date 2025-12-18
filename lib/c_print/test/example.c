#include "c_print.h"

int main() {
    printf("╔══════════════════════════════════════════════════════════════╗\n");
    printf("║          c_print - Librería de impresión con colores        ║\n");
    printf("╚══════════════════════════════════════════════════════════════╝\n\n");
    
    // ========== EJEMPLOS ORIGINALES ==========
    
    //printf("========== 1. Patrón básico - solo tipo ==========\n");
    c_print("{s:=^52}\n"," 1. Patrón básico - solo tipo ");
    c_print("Hola {s}!\n", "Mundo");
    printf("\n");
    
    printf("========== 2. Patrón con color de texto ==========\n");
    c_print("Este texto es {s:green} y esto es normal\n", "VERDE");
    printf("\n");
    
    printf("========== 3. Patrón con color de texto y fondo ==========\n");
    c_print("Esto es un mensaje {s:green:bg_white}!\n", "IMPORTANTE");
    printf("\n");
    
    printf("========== 4. Patrón completo (color, fondo y estilo) ==========\n");
    c_print("Esto es un mensaje {s:green:bg_white:italic}\n", "Verde con estilo");
    printf("\n");
    
    printf("========== 5. Múltiples patrones en una línea ==========\n");
    c_print("Usuario: {s:cyan:bg_black:bold}, Estado: {s:green::bold}, Puntos: {d:yellow}\n", 
            "JuanPerez", "ACTIVO", 1500);
    printf("\n");
    
    printf("========== 6. Diferentes tipos de datos ==========\n");
    c_print("String: {s:blue}, Entero: {d:red}, Float: {f:magenta}, Char: {c:yellow}\n",
            "Hola", 42, 3.14159, 'A');
    printf("\n");
    
    printf("========== 7. Hexadecimal y octal ==========\n");
    c_print("Hex: 0x{x:cyan}, Octal: 0{o:yellow}, Unsigned: {u:green}\n",
            255, 64, 1000);
    printf("\n");
    
    printf("========== 8. Solo estilos (sin color) ==========\n");
    c_print("Texto {s:::bold} y texto {s:::italic} y texto {s:::underline}\n",
            "NEGRITA", "CURSIVA", "SUBRAYADO");
    printf("\n");
    
    printf("========== 9. Solo color de fondo ==========\n");
    c_print("Texto con {s::bg_red} rojo y con {s::bg_blue} azul\n",
            "fondo", "fondo");
    printf("\n");
    
    printf("========== 10. Combinaciones complejas ==========\n");
    c_print("[{s:bright_green::bold}] {s:white} - Usuario: {s:cyan:bg_black}, Balance: ${f:green::bold}\n",
            "SUCCESS", "Transacción completada", "maria.garcia", 2500.50);
    printf("\n");
    
    printf("========== 11. Simulando logs de sistema ==========\n");
    c_print("[{s:bright_red::bold}] {s} en línea {d}\n", "ERROR", "Fallo de conexión", 127);
    c_print("[{s:bright_yellow::bold}] {s} al archivo\n", "WARN", "Acceso denegado");
    c_print("[{s:bright_blue::bold}] {s} correctamente\n", "INFO", "Servicio iniciado");
    c_print("[{s:bright_green::bold}] {s} en {f}ms\n", "OK", "Petición completada", 45.32);
    printf("\n");
    
    printf("========== 12. Tabla con colores ==========\n");
    c_print("┌─────────────┬──────────┬─────────┐\n");
    c_print("│ {s:cyan::bold}      │ {s:cyan::bold}   │ {s:cyan::bold}  │\n", 
            "Producto", "Cantidad", "Precio");
    c_print("├─────────────┼──────────┼─────────┤\n");
    c_print("│ {s:white}       │ {d:yellow}        │ ${f:green} │\n",
            "Laptop", 5, 999.99);
    c_print("│ {s:white}         │ {d:yellow}       │ ${f:green}  │\n",
            "Mouse", 20, 25.50);
    c_print("│ {s:white}      │ {d:yellow}       │ ${f:green}  │\n",
            "Teclado", 10, 75.00);
    c_print("└─────────────┴──────────┴─────────┘\n");
    printf("\n");
    
    printf("========== 13. Barra de progreso simulada ==========\n");
    c_print("Progreso: [{s:green:bg_green}          ] {d}%%\n", "█████", 50);
    c_print("Descarga: [{s:blue:bg_blue}    ] {d}%%\n", "████████████", 100);
    printf("\n");
    
    printf("========== 14. Escape de llaves literales ==========\n");
    c_print("Esto es una llave literal: \\{ y esta es un patrón: {s:red}\n", "ROJO");
    printf("\n");
    
    printf("========== 15. Menú interactivo ==========\n");
    c_print("{s:bright_white:bg_blue:bold}\n", "  === MENÚ PRINCIPAL ===  ");
    c_print("  {d:yellow}. {s:white}\n", 1, "Nueva partida");
    c_print("  {d:yellow}. {s:white}\n", 2, "Cargar partida");
    c_print("  {d:yellow}. {s:white}\n", 3, "Opciones");
    c_print("  {d:yellow}. {s:bright_red}\n", 4, "Salir");
    printf("\n");
    
    printf("========== 16. Indicadores de estado ==========\n");
    c_print("Servicio Web:    [{s:bright_green::bold}] Activo\n", "●");
    c_print("Base de datos:   [{s:bright_green::bold}] Activo\n", "●");
    c_print("Cache:           [{s:bright_yellow::bold}] Degradado\n", "●");
    c_print("API Externa:     [{s:bright_red::bold}] Inactivo\n", "●");
    printf("\n");
    
    printf("========== 17. Comparación: sistema antiguo vs nuevo ==========\n");
    printf("Antiguo: ");
    c_print_styled("Texto con estilo\n", COLOR_GREEN, BG_WHITE, STYLE_ITALIC);
    printf("Nuevo:   ");
    c_print("{s:green:bg_white:italic}\n", "Texto con estilo");
    printf("\n");
    
    // ========== NUEVOS EJEMPLOS CON ALINEACIÓN ==========
    
    printf("========== 18. ALINEACIÓN DE TEXTO ==========\n");
    c_print("Izquierda:  |{s:<30}|\n", "Texto");
    c_print("Derecha:    |{s:>30}|\n", "Texto");
    c_print("Centro:     |{s:^30}|\n", "Texto");
    printf("\n");
    
    c_print("Número izq: |{d:<10}|\n", 42);
    c_print("Número der: |{d:>10}|\n", 42);
    c_print("Número cen: |{d:^10}|\n", 42);
    printf("\n");
    
    printf("========== 19. ORDEN FLEXIBLE DE ESPECIFICADORES ==========\n");
    printf("Todos estos son equivalentes:\n");
    c_print("  {s:green:bg_white:bold}\n", "Opción 1");
    c_print("  {s:bold:green:bg_white}\n", "Opción 2");
    c_print("  {s:bg_white:bold:green}\n", "Opción 3");
    c_print("  {s:bold:bg_white:green}\n", "Opción 4");
    printf("\n");
    
    printf("========== 20. ALINEACIÓN CON COLORES Y ESTILOS ==========\n");
    c_print("|{s:<20:green:bold}|\n", "Verde izq");
    c_print("|{s:>20:red:bg_yellow}|\n", "Rojo der");
    c_print("|{s:^20:blue:italic}|\n", "Azul centro");
    printf("\n");
    
    c_print("|{s:bold:>25:cyan:bg_black}|\n", "Todo junto der");
    c_print("|{s:<25:bg_red:white:underline}|\n", "Todo junto izq");
    printf("\n");
    
    printf("========== 21. TABLA CON ALINEACIÓN ==========\n");
    c_print("┌────────────────────┬──────────┬──────────┐\n");
    c_print("│ {s:<18:cyan:bold} │ {s:^8:cyan:bold} │ {s:>8:cyan:bold} │\n", 
            "Producto", "Cantidad", "Precio");
    c_print("├────────────────────┼──────────┼──────────┤\n");
    c_print("│ {s:<18:white} │ {d:^8:yellow} │ ${f:>7:green} │\n",
            "Laptop", 5, 999.99);
    c_print("│ {s:<18:white} │ {d:^8:yellow} │ ${f:>7:green} │\n",
            "Mouse", 20, 25.50);
    c_print("│ {s:<18:white} │ {d:^8:yellow} │ ${f:>7:green} │\n",
            "Teclado", 10, 75.00);
    c_print("└────────────────────┴──────────┴──────────┘\n");
    printf("\n");
    
    printf("========== 22. MENÚ CENTRADO CON ALINEACIÓN ==========\n");
    c_print("{s:^50:bright_white:bg_blue:bold}\n", "MENÚ PRINCIPAL");
    c_print("{s:^50}\n", "");
    c_print("  {d:>2:yellow}. {s:<40:white}\n", 1, "Nueva partida");
    c_print("  {d:>2:yellow}. {s:<40:white}\n", 2, "Cargar partida");
    c_print("  {d:>2:yellow}. {s:<40:white}\n", 3, "Configuración");
    c_print("  {d:>2:yellow}. {s:<40:bright_red}\n", 4, "Salir");
    printf("\n");
    
    printf("========== 23. LOGS CON FORMATO Y ALINEACIÓN ==========\n");
    c_print("[{s:^8:bright_green:bold}] {s:<30} {s:>15:dim}\n", 
            "OK", "Servidor iniciado", "12:34:56");
    c_print("[{s:^8:bright_blue:bold}] {s:<30} {s:>15:dim}\n", 
            "INFO", "Conexión establecida", "12:35:12");
    c_print("[{s:^8:bright_yellow:bold}] {s:<30} {s:>15:dim}\n", 
            "WARN", "Memoria al 80%", "12:35:45");
    c_print("[{s:^8:bright_red:bold}] {s:<30} {s:>15:dim}\n", 
            "ERROR", "Fallo de conexión", "12:36:01");
    printf("\n");
    
    printf("========== 24. BARRA DE PROGRESO CON ALINEACIÓN ==========\n");
    c_print("Descarga: [{s:<40:green:bg_green}] {d:>3}%%\n", "████████████████████", 50);
    c_print("Subida:   [{s:<40:blue:bg_blue}] {d:>3}%%\n", "████████████████████████████████", 80);
    c_print("Cache:    [{s:<40:yellow:bg_yellow}] {d:>3}%%\n", "████████", 20);
    printf("\n");
    
    printf("========== 25. PANEL DE INFORMACIÓN ==========\n");
    c_print("╔════════════════════════════════════════════════╗\n");
    c_print("║ {s:^46:bright_cyan:bold} ║\n", "INFORMACIÓN DEL SISTEMA");
    c_print("╠════════════════════════════════════════════════╣\n");
    c_print("║ {s:<20:white} : {s:>23:bright_green} ║\n", "CPU", "Intel i7-9700K");
    c_print("║ {s:<20:white} : {s:>23:bright_green} ║\n", "RAM", "32 GB DDR4");
    c_print("║ {s:<20:white} : {s:>23:bright_green} ║\n", "GPU", "NVIDIA RTX 3080");
    c_print("║ {s:<20:white} : {s:>23:bright_green} ║\n", "OS", "Linux 6.1.0");
    c_print("╚════════════════════════════════════════════════╝\n");
    printf("\n");
    
    printf("========== 26. DASHBOARD DE MÉTRICAS ==========\n");
    c_print("┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓\n");
    c_print("┃ {s:^48:bright_white:bold} ┃\n", "MÉTRICAS DEL SERVIDOR");
    c_print("┣━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┫\n");
    c_print("┃ {s:<22:cyan} │ {s:>23:bright_green:bold} ┃\n", "CPU Usage", "45%");
    c_print("┃ {s:<22:cyan} │ {s:>23:bright_yellow:bold} ┃\n", "Memory Usage", "78%");
    c_print("┃ {s:<22:cyan} │ {s:>23:bright_blue:bold} ┃\n", "Disk Space", "320 GB");
    c_print("┃ {s:<22:cyan} │ {s:>23:bright_magenta:bold} ┃\n", "Active Users", "1,234");
    c_print("┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛\n");
    printf("\n");
    
    printf("========== 27. TODOS LOS TIPOS DE DATOS CON ALINEACIÓN ==========\n");
    c_print("String:    {s:>20:cyan}\n", "Hola Mundo");
    c_print("Integer:   {d:>20:green}\n", 42);
    c_print("Float:     {f:>20:yellow}\n", 3.14159);
    c_print("Char:      {c:>20:red}\n", 'A');
    c_print("Hex:       0x{x:>18:magenta}\n", 255);
    c_print("Octal:     0{o:>19:blue}\n", 64);
    c_print("Unsigned:  {u:>20:white}\n", 1000);
    printf("\n");
    
    printf("╔══════════════════════════════════════════════════════════════╗\n");
    printf("║               Fin de ejemplos - ¡Gracias!                   ║\n");
    printf("╚══════════════════════════════════════════════════════════════╝\n");


    c_print("+{s:-^62}+\n"," hola   ");
    c_print("║               Fin de ejemplos - ¡Gracias!                   ║\n");
    c_print("╚══════════════════════════════════════════════════════════════╝\n");
    
    return 0;
}