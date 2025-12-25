#!/bin/bash
# Script para crear la discusión sobre filtros en GitHub
# Uso: ./add-discussion-filter.sh [en|es]

set -e

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Banner
echo -e "${BLUE}"
echo "╔═══════════════════════════════════════════════════════╗"
echo "║     GitHub Discussion Creator - Filter System RFC     ║"
echo "╚═══════════════════════════════════════════════════════╝"
echo -e "${NC}"

# Verificar que gh está instalado
if ! command -v gh &> /dev/null; then
    echo -e "${RED}Error: GitHub CLI (gh) no está instalado${NC}"
    echo "Instala con: apk add github-cli"
    exit 1
fi

# Verificar autenticación
echo -e "${YELLOW}Verificando autenticación...${NC}"
if ! gh auth status &> /dev/null; then
    echo -e "${RED}No estás autenticado en GitHub${NC}"
    echo -e "${YELLOW}Ejecutando autenticación...${NC}"
    gh auth login
fi

echo -e "${GREEN}✓ Autenticación correcta${NC}"
echo ""

# Determinar idioma
LANG="${1:-en}"

if [ "$LANG" = "es" ]; then
    TITLE="RFC: Sistema de Filtros mediante Archivos JavaScript Puros"
    BODY_FILE="/tmp/github-discussion-filters-es.md"
    echo -e "${BLUE}Idioma seleccionado: Español${NC}"
elif [ "$LANG" = "en" ]; then
    TITLE="RFC: Filter System via Pure JavaScript Files"
    BODY_FILE="/tmp/github-discussion-filters.md"
    echo -e "${BLUE}Idioma seleccionado: English${NC}"
else
    echo -e "${RED}Error: Idioma no válido. Usa 'en' o 'es'${NC}"
    echo "Uso: $0 [en|es]"
    exit 1
fi

# Verificar que el archivo existe
if [ ! -f "$BODY_FILE" ]; then
    echo -e "${RED}Error: No se encuentra el archivo ${BODY_FILE}${NC}"
    echo "Asegúrate de que el archivo de la discusión existe"
    exit 1
fi

echo -e "${YELLOW}Archivo de contenido: ${BODY_FILE}${NC}"
echo -e "${YELLOW}Título: ${TITLE}${NC}"
echo ""

# Confirmación
echo -e "${YELLOW}¿Crear la discusión en GitHub? (s/n)${NC}"
read -r CONFIRM

if [ "$CONFIRM" != "s" ] && [ "$CONFIRM" != "S" ]; then
    echo -e "${RED}Cancelado por el usuario${NC}"
    exit 0
fi

# Crear la discusión
echo ""
echo -e "${BLUE}Creando discusión en GitHub...${NC}"

DISCUSSION_URL=$(gh discussion create \
  --repo carlos-sweb/zig-pug \
  --category "Ideas" \
  --title "$TITLE" \
  --body-file "$BODY_FILE")

# Resultado
echo ""
echo -e "${GREEN}╔═══════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║           ✓ Discusión creada exitosamente             ║${NC}"
echo -e "${GREEN}╚═══════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${BLUE}URL de la discusión:${NC}"
echo -e "${GREEN}${DISCUSSION_URL}${NC}"
echo ""
echo -e "${YELLOW}Próximos pasos:${NC}"
echo "  1. Visita la URL de arriba"
echo "  2. Comparte la discusión en redes sociales"
echo "  3. Monitorea comentarios y feedback"
echo "  4. Responde preguntas de la comunidad"
echo ""
echo -e "${BLUE}¡Buena suerte con la discusión! 🚀${NC}"
