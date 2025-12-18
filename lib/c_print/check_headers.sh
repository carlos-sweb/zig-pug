#!/bin/bash
echo "Verificando inclusiones de headers..."
errors=0

for file in src/*.c; do
    echo "Analizando $file..."
    
    # Verificar que compile individualmente
    if ! gcc -c -Iinclude -Wall -Wextra -pedantic "$file" -o /dev/null 2>&1; then
        echo "  ❌ ERROR en $file"
        gcc -c -Iinclude -Wall -Wextra -pedantic "$file" -o /dev/null
        errors=$((errors + 1))
    else
        echo "  ✅ OK"
    fi
done

echo ""
if [ $errors -eq 0 ]; then
    echo "✅ Todos los archivos compilaron correctamente"
    exit 0
else
    echo "❌ $errors archivo(s) con errores"
    exit 1
fi