#!/bin/bash
# benchmark_compare.sh — zig-pug vs pug via hyperfine
#
# Requisitos:
#   cargo install hyperfine  (o dnf install hyperfine)
#   zig build benchmark_single
#
# Uso:
#   chmod +x benchmark_compare.sh
#   ./benchmark_compare.sh

set -e

SEP="══════════════════════════════════════════════════"
RUNS=1000
WARMUP=20

echo ""
echo "$SEP"
echo "  zig-pug vs pug — Benchmark end-to-end"
echo "  Warmup: $WARMUP | Runs: $RUNS"
echo "  Mide: proceso completo (init + parse + compile + output)"
echo "$SEP"
echo ""

# Verificar dependencias
if ! command -v hyperfine &>/dev/null; then
    echo "Error: hyperfine no encontrado."
    echo "Instalar: cargo install hyperfine  o  dnf install hyperfine"
    exit 1
fi

if ! command -v node &>/dev/null; then
    echo "Error: node no encontrado."
    exit 1
fi

if ! command -v bun &>/dev/null; then
    HAS_BUN=0
else
    HAS_BUN=1
fi

# Compilar zig-pug
echo "Compilando zig-pug (ReleaseFast)..."
zig build benchmark_single
BINARY="./zig-out/bin/benchmark"
echo "  OK: $BINARY"
echo ""

if [ "$HAS_BUN" -eq 1 ]; then
    hyperfine \
	-shell=none \
        --warmup $WARMUP \
        --runs   $RUNS \
        --export-markdown benchmark_results.md \
        --export-json     benchmark_results.json \
        --command-name "pug + Node.js" "node benchmark_single.js" \
        --command-name "pug + Bun"     "bun  benchmark_single.js" \
        --command-name "zig-pug"       "$BINARY"
else
    hyperfine \
        --warmup $WARMUP \
        --runs   $RUNS \
        --export-markdown benchmark_results.md \
        --export-json     benchmark_results.json \
        --command-name "pug + Node.js" "node benchmark_single.js" \
        --command-name "zig-pug"       "$BINARY"
fi

echo ""
echo "$SEP"
echo "  Resultados: benchmark_results.md / benchmark_results.json"
echo "$SEP"
echo ""

[ -f benchmark_results.md ] && cat benchmark_results.md
