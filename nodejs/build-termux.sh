#!/data/data/com.termux/files/usr/bin/bash
# Script para compilar el addon en Termux
# Engaña a node-gyp para que piense que está en Linux

export npm_config_arch=arm64
export npm_config_platform=linux
export GYPFLAGS="-DOS=linux"

# Ejecutar node-gyp con configuración custom
npx node-gyp configure -- \
  -DOS=linux \
  -Dhost_os=linux \
  -Dtarget_arch=arm64

npx node-gyp build
