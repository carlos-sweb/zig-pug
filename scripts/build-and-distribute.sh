#!/usr/bin/env bash
# Script maestro: Construye TODOS los binarios y los organiza para distribución
# Uso: ./build-and-distribute.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colores
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

echo ""
echo -e "${BLUE}╔═══════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  🚀 ZIG-PUG: BUILD & DISTRIBUTE                           ║${NC}"
echo -e "${BLUE}║  Construir todo y organizar para distribución GitHub     ║${NC}"
echo -e "${BLUE}╚═══════════════════════════════════════════════════════════╝${NC}"
echo ""

# PASO 1: Construir todos los binarios
echo -e "${BLUE}PASO 1/2: Construyendo todos los binarios...${NC}"
echo ""
"$SCRIPT_DIR/build-all.sh" "$@"

echo ""
echo ""

# PASO 2: Organizar para distribución
echo -e "${BLUE}PASO 2/2: Organizando para distribución...${NC}"
echo ""
"$SCRIPT_DIR/organize-distribution.sh"

echo ""
echo -e "${GREEN}╔═══════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║  ✅ PROCESO COMPLETO FINALIZADO                           ║${NC}"
echo -e "${GREEN}╚═══════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${GREEN}Todo está listo en la carpeta bin/ para distribución!${NC}"
echo ""
