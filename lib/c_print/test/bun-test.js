#!/usr/bin/env bun

import { dlopen, FFIType, suffix, ptr, CString } from 'bun:ffi';
import { join } from 'path';

// Determinar la ruta de la librería según el sistema operativo
// suffix es "dylib" en macOS, "so" en Linux, "dll" en Windows
const libraryPath = join(process.cwd(), 'build', `libc_print.${suffix}`);

console.log(`🔍 Cargando librería: ${libraryPath}\n`);

// Cargar la librería c_print
const lib = dlopen(libraryPath, {
  // c_print es una función variádica (varargs), lo cual es complicado en FFI
  // Por ahora, vamos a usar las funciones específicas que son más fáciles de llamar
  
  // void c_print_styled(const char* text, TextColor fg, BackgroundColor bg, TextStyle style)
  c_print_styled: {
    args: [FFIType.cstring, FFIType.i32, FFIType.i32, FFIType.i32],
    returns: FFIType.void,
  },
  
  // void c_print_color(const char* text, TextColor fg)
  c_print_color: {
    args: [FFIType.cstring, FFIType.i32],
    returns: FFIType.void,
  },
  
  // void c_print_bg(const char* text, BackgroundColor bg)
  c_print_bg: {
    args: [FFIType.cstring, FFIType.i32],
    returns: FFIType.void,
  },
  
  // void c_print_style(const char* text, TextStyle style)
  c_print_style: {
    args: [FFIType.cstring, FFIType.i32],
    returns: FFIType.void,
  },
  
  // void apply_ansi_codes(TextColor fg, BackgroundColor bg, TextStyle style)
  apply_ansi_codes: {
    args: [FFIType.i32, FFIType.i32, FFIType.i32],
    returns: FFIType.void,
  },
  
  // void reset_ansi_codes(void)
  reset_ansi_codes: {
    args: [],
    returns: FFIType.void,
  },
});

const { symbols } = lib;

// Definir enums (deben coincidir con los valores en c_print.h)

// TextColor
const TextColor = {
  COLOR_RESET: 0,
  COLOR_BLACK: 30,
  COLOR_RED: 31,
  COLOR_GREEN: 32,
  COLOR_YELLOW: 33,
  COLOR_BLUE: 34,
  COLOR_MAGENTA: 35,
  COLOR_CYAN: 36,
  COLOR_WHITE: 37,
  COLOR_BRIGHT_BLACK: 90,
  COLOR_BRIGHT_RED: 91,
  COLOR_BRIGHT_GREEN: 92,
  COLOR_BRIGHT_YELLOW: 93,
  COLOR_BRIGHT_BLUE: 94,
  COLOR_BRIGHT_MAGENTA: 95,
  COLOR_BRIGHT_CYAN: 96,
  COLOR_BRIGHT_WHITE: 97,
};

// BackgroundColor
const BackgroundColor = {
  BG_RESET: 0,
  BG_BLACK: 40,
  BG_RED: 41,
  BG_GREEN: 42,
  BG_YELLOW: 43,
  BG_BLUE: 44,
  BG_MAGENTA: 45,
  BG_CYAN: 46,
  BG_WHITE: 47,
  BG_BRIGHT_BLACK: 100,
  BG_BRIGHT_RED: 101,
  BG_BRIGHT_GREEN: 102,
  BG_BRIGHT_YELLOW: 103,
  BG_BRIGHT_BLUE: 104,
  BG_BRIGHT_MAGENTA: 105,
  BG_BRIGHT_CYAN: 106,
  BG_BRIGHT_WHITE: 107,
};

// TextStyle
const TextStyle = {
  STYLE_RESET: 0,
  STYLE_BOLD: 1,
  STYLE_DIM: 2,
  STYLE_ITALIC: 3,
  STYLE_UNDERLINE: 4,
  STYLE_BLINK: 5,
  STYLE_REVERSE: 7,
  STYLE_HIDDEN: 8,
  STYLE_STRIKETHROUGH: 9,
};

// Wrapper functions para una API más amigable en JavaScript
const cprint = {
  // Imprimir con color de texto
  color(text, color) {
    symbols.c_print_color(text, color);
  },
  
  // Imprimir con color de fondo
  bg(text, bgColor) {
    symbols.c_print_bg(text, bgColor);
  },
  
  // Imprimir con estilo
  style(text, style) {
    symbols.c_print_style(text, style);
  },
  
  // Imprimir con todo: color, fondo y estilo
  styled(text, color, bgColor, style) {
    symbols.c_print_styled(text, color, bgColor, style);
  },
  
  // Helper para colores comunes
  red(text) {
    symbols.c_print_color(text, TextColor.COLOR_RED);
  },
  
  green(text) {
    symbols.c_print_color(text, TextColor.COLOR_GREEN);
  },
  
  yellow(text) {
    symbols.c_print_color(text, TextColor.COLOR_YELLOW);
  },
  
  blue(text) {
    symbols.c_print_color(text, TextColor.COLOR_BLUE);
  },
  
  cyan(text) {
    symbols.c_print_color(text, TextColor.COLOR_CYAN);
  },
  
  magenta(text) {
    symbols.c_print_color(text, TextColor.COLOR_MAGENTA);
  },
  
  white(text) {
    symbols.c_print_color(text, TextColor.COLOR_WHITE);
  },
  
  // Helpers para estilos comunes
  bold(text, color = TextColor.COLOR_RESET) {
    symbols.c_print_styled(text, color, BackgroundColor.BG_RESET, TextStyle.STYLE_BOLD);
  },
  
  italic(text, color = TextColor.COLOR_RESET) {
    symbols.c_print_styled(text, color, BackgroundColor.BG_RESET, TextStyle.STYLE_ITALIC);
  },
  
  underline(text, color = TextColor.COLOR_RESET) {
    symbols.c_print_styled(text, color, BackgroundColor.BG_RESET, TextStyle.STYLE_UNDERLINE);
  },
};

// ========== EJEMPLOS DE USO ==========

console.log("╔══════════════════════════════════════════════════════════════╗");
console.log("║         c_print desde Bun usando FFI                         ║");
console.log("╚══════════════════════════════════════════════════════════════╝\n");

console.log("========== 1. Colores básicos ==========");
cprint.red("Texto en rojo\n");
cprint.green("Texto en verde\n");
cprint.yellow("Texto en amarillo\n");
cprint.blue("Texto en azul\n");
cprint.cyan("Texto en cyan\n");
cprint.magenta("Texto en magenta\n");
console.log();

console.log("========== 2. Estilos ==========");
cprint.bold("Texto en negrita\n");
cprint.italic("Texto en cursiva\n");
cprint.underline("Texto subrayado\n");
console.log();

console.log("========== 3. Combinaciones ==========");
cprint.styled(
  "Texto con todo: verde, fondo blanco, negrita\n",
  TextColor.COLOR_GREEN,
  BackgroundColor.BG_WHITE,
  TextStyle.STYLE_BOLD
);

cprint.styled(
  "Error crítico\n",
  TextColor.COLOR_BRIGHT_RED,
  BackgroundColor.BG_BLACK,
  TextStyle.STYLE_BOLD
);

cprint.styled(
  "Éxito\n",
  TextColor.COLOR_BRIGHT_GREEN,
  BackgroundColor.BG_RESET,
  TextStyle.STYLE_BOLD
);
console.log();

console.log("========== 4. Simulación de logs ==========");
cprint.styled("[INFO] ", TextColor.COLOR_BRIGHT_BLUE, BackgroundColor.BG_RESET, TextStyle.STYLE_BOLD);
console.log("Servidor iniciado correctamente");

cprint.styled("[WARN] ", TextColor.COLOR_BRIGHT_YELLOW, BackgroundColor.BG_RESET, TextStyle.STYLE_BOLD);
console.log("Memoria al 80%");

cprint.styled("[ERROR] ", TextColor.COLOR_BRIGHT_RED, BackgroundColor.BG_RESET, TextStyle.STYLE_BOLD);
console.log("Conexión perdida");

cprint.styled("[SUCCESS] ", TextColor.COLOR_BRIGHT_GREEN, BackgroundColor.BG_RESET, TextStyle.STYLE_BOLD);
console.log("Operación completada");
console.log();

console.log("========== 5. Tabla de colores ==========");
const colors = [
  { name: "Negro", code: TextColor.COLOR_BLACK },
  { name: "Rojo", code: TextColor.COLOR_RED },
  { name: "Verde", code: TextColor.COLOR_GREEN },
  { name: "Amarillo", code: TextColor.COLOR_YELLOW },
  { name: "Azul", code: TextColor.COLOR_BLUE },
  { name: "Magenta", code: TextColor.COLOR_MAGENTA },
  { name: "Cyan", code: TextColor.COLOR_CYAN },
  { name: "Blanco", code: TextColor.COLOR_WHITE },
];

colors.forEach(({ name, code }) => {
  cprint.color(`${name.padEnd(15)}`, code);
  console.log();
});
console.log();

console.log("========== 6. Colores brillantes ==========");
const brightColors = [
  { name: "Rojo brillante", code: TextColor.COLOR_BRIGHT_RED },
  { name: "Verde brillante", code: TextColor.COLOR_BRIGHT_GREEN },
  { name: "Amarillo brillante", code: TextColor.COLOR_BRIGHT_YELLOW },
  { name: "Azul brillante", code: TextColor.COLOR_BRIGHT_BLUE },
  { name: "Magenta brillante", code: TextColor.COLOR_BRIGHT_MAGENTA },
  { name: "Cyan brillante", code: TextColor.COLOR_BRIGHT_CYAN },
  { name: "Blanco brillante", code: TextColor.COLOR_BRIGHT_WHITE },
];

brightColors.forEach(({ name, code }) => {
  cprint.color(`${name.padEnd(25)}`, code);
  console.log();
});
console.log();

console.log("========== 7. Menú interactivo ==========");
cprint.styled(
  "  === MENÚ PRINCIPAL ===  \n",
  TextColor.COLOR_BRIGHT_WHITE,
  BackgroundColor.BG_BLUE,
  TextStyle.STYLE_BOLD
);
cprint.color("  1. ", TextColor.COLOR_YELLOW);
console.log("Nueva partida");
cprint.color("  2. ", TextColor.COLOR_YELLOW);
console.log("Cargar partida");
cprint.color("  3. ", TextColor.COLOR_YELLOW);
console.log("Opciones");
cprint.color("  4. ", TextColor.COLOR_BRIGHT_RED);
console.log("Salir");
console.log();

console.log("========== 8. Indicadores de estado ==========");
cprint.styled("●", TextColor.COLOR_BRIGHT_GREEN, BackgroundColor.BG_RESET, TextStyle.STYLE_BOLD);
console.log(" Servicio Web: Activo");
cprint.styled("●", TextColor.COLOR_BRIGHT_GREEN, BackgroundColor.BG_RESET, TextStyle.STYLE_BOLD);
console.log(" Base de datos: Activo");
cprint.styled("●", TextColor.COLOR_BRIGHT_YELLOW, BackgroundColor.BG_RESET, TextStyle.STYLE_BOLD);
console.log(" Cache: Degradado");
cprint.styled("●", TextColor.COLOR_BRIGHT_RED, BackgroundColor.BG_RESET, TextStyle.STYLE_BOLD);
console.log(" API Externa: Inactivo");
console.log();

console.log("╔══════════════════════════════════════════════════════════════╗");
console.log("║                 Fin de ejemplos - ¡Gracias!                  ║");
console.log("╚══════════════════════════════════════════════════════════════╝");

// Exportar para uso como módulo
export { cprint, TextColor, BackgroundColor, TextStyle, symbols };