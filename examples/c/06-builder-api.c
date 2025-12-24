/**
 * Builder API Example - Para Geeks que dejaron el Anime 🤓
 *
 * Este ejemplo demuestra el PODER de la Builder API.
 * Aprenderás a construir arrays y objetos dinámicamente sin dolor.
 *
 * Compilar:
 *   make 06-builder-api
 *   ./06-builder-api
 */

#include <stdio.h>
#include <stdlib.h>
#include <zigpug.h>

int main(void) {
    printf("╔═══════════════════════════════════════════════════════════╗\n");
    printf("║  Builder API Demo - Enfoque Híbrido (JSON + Builder)     ║\n");
    printf("╚═══════════════════════════════════════════════════════════╝\n\n");

    // Initialize context
    ZigPugContext* ctx = zigpug_init();
    if (!ctx) {
        fprintf(stderr, "❌ Failed to initialize zig-pug\n");
        return 1;
    }

    // ========================================================================
    // PARTE 1: JSON API (Simple, estático)
    // ========================================================================
    printf("📦 PARTE 1: JSON API para datos simples/estáticos\n");
    printf("─────────────────────────────────────────────────────────────\n\n");

    // Para datos simples, JSON es perfecto
    zigpug_set_array_json(ctx, "colors", "[\"red\",\"green\",\"blue\"]");
    zigpug_set_object_json(ctx, "config", "{\"debug\":true,\"port\":8080}");

    const char* template1 =
        "h3 Colors (JSON)\n"
        "ul\n"
        "  each color in colors\n"
        "    li.color= color\n"
        "\n"
        "h3 Config (JSON)\n"
        "p Debug: #{config.debug}\n"
        "p Port: #{config.port}";

    char* html1 = zigpug_compile(ctx, template1);
    if (html1) {
        printf("HTML Output:\n%s\n\n", html1);
        zigpug_free_string(html1);
    }

    // ========================================================================
    // PARTE 2: Builder API (Dinámico, programático)
    // ========================================================================
    printf("🏗️  PARTE 2: Builder API para construcción dinámica\n");
    printf("─────────────────────────────────────────────────────────────\n\n");

    // Construyendo un array dinámicamente (ej: desde base de datos)
    ZigPugArray* numbers = zigpug_array_create(ctx);
    if (!numbers) {
        fprintf(stderr, "❌ Failed to create array\n");
        zigpug_free(ctx);
        return 1;
    }

    // Simulamos leer números de alguna fuente
    for (int i = 1; i <= 5; i++) {
        zigpug_array_add_int(numbers, i * 10);
    }

    zigpug_set_array(ctx, "numbers", numbers);
    zigpug_array_free(numbers);  // ✅ Safe to free after set

    // Compilar template
    const char* template2 =
        "h3 Numbers (Builder API)\n"
        "ul\n"
        "  each num in numbers\n"
        "    li #{num}";

    char* html2 = zigpug_compile(ctx, template2);
    if (html2) {
        printf("HTML Output:\n%s\n\n", html2);
        zigpug_free_string(html2);
    }

    // ========================================================================
    // PARTE 3: Objetos dinámicos con Builder API
    // ========================================================================
    printf("🎯 PARTE 3: Objetos dinámicos (perfecto para APIs/DB)\n");
    printf("─────────────────────────────────────────────────────────────\n\n");

    // Construyendo un usuario desde datos dinámicos
    ZigPugObject* user = zigpug_object_create(ctx);
    if (!user) {
        fprintf(stderr, "❌ Failed to create object\n");
        zigpug_free(ctx);
        return 1;
    }

    // Simulamos datos de una base de datos
    zigpug_object_set_string(user, "name", "Carlos");
    zigpug_object_set_string(user, "role", "Geek Programador");
    zigpug_object_set_int(user, "age", 25);
    zigpug_object_set_int(user, "level", 9999);
    zigpug_object_set_double(user, "score", 98.5);
    zigpug_object_set_bool(user, "admin", true);
    zigpug_object_set_bool(user, "watchingAnime", false);  // 😂

    zigpug_set_object(ctx, "user", user);
    zigpug_object_free(user);

    const char* template3 =
        "div.user-card\n"
        "  h2= user.name\n"
        "  p.role Role: #{user.role}\n"
        "  p Age: #{user.age} años\n"
        "  p Level: #{user.level}\n"
        "  p Score: #{user.score}%\n"
        "  p Admin: #{user.admin ? 'Sí' : 'No'}\n"
        "  p Viendo Anime: #{user.watchingAnime ? 'Sí' : 'No (está programando 🤓)'}";

    char* html3 = zigpug_compile(ctx, template3);
    if (html3) {
        printf("HTML Output:\n%s\n\n", html3);
        zigpug_free_string(html3);
    }

    // ========================================================================
    // PARTE 4: COMBO ÉPICO - Mixed types en array
    // ========================================================================
    printf("💥 PARTE 4: Array con tipos mixtos (strings, ints, bools, nulls)\n");
    printf("─────────────────────────────────────────────────────────────\n\n");

    ZigPugArray* mixed = zigpug_array_create(ctx);
    zigpug_array_add_string(mixed, "texto");
    zigpug_array_add_int(mixed, 42);
    zigpug_array_add_double(mixed, 3.14);
    zigpug_array_add_bool(mixed, true);
    zigpug_array_add_null(mixed);

    zigpug_set_array(ctx, "mixed", mixed);
    zigpug_array_free(mixed);

    const char* template4 =
        "h3 Mixed Array\n"
        "ul\n"
        "  each item in mixed\n"
        "    li= item";

    char* html4 = zigpug_compile(ctx, template4);
    if (html4) {
        printf("HTML Output:\n%s\n\n", html4);
        zigpug_free_string(html4);
    }

    // ========================================================================
    // PARTE 5: Caso de Uso REALISTA - Usuarios de base de datos
    // ========================================================================
    printf("🎮 PARTE 5: CASO REALISTA - Lista de usuarios (simulando DB)\n");
    printf("─────────────────────────────────────────────────────────────\n\n");

    // Simulamos 3 usuarios de una base de datos
    struct UserData {
        const char* name;
        const char* email;
        int age;
        bool premium;
    };

    struct UserData database[] = {
        {"Alice", "alice@geeks.com", 28, true},
        {"Bob", "bob@geeks.com", 22, false},
        {"Charlie", "charlie@geeks.com", 30, true},
    };
    int user_count = 3;

    // Construimos array de objetos dinámicamente
    ZigPugArray* users = zigpug_array_create(ctx);

    for (int i = 0; i < user_count; i++) {
        // Necesitamos convertir cada usuario en JSON string
        // (Nota: En la siguiente versión agregaremos zigpug_array_add_object)
        char json_buf[256];
        snprintf(json_buf, sizeof(json_buf),
            "{\"name\":\"%s\",\"email\":\"%s\",\"age\":%d,\"premium\":%s}",
            database[i].name,
            database[i].email,
            database[i].age,
            database[i].premium ? "true" : "false");

        // Por ahora usamos JSON para objetos dentro de arrays
        // TODO: Implementar zigpug_array_add_object() en v0.2.0
    }

    // Por ahora, usamos el enfoque JSON para array de objetos
    const char* users_json =
        "["
        "{\"name\":\"Alice\",\"email\":\"alice@geeks.com\",\"age\":28,\"premium\":true},"
        "{\"name\":\"Bob\",\"email\":\"bob@geeks.com\",\"age\":22,\"premium\":false},"
        "{\"name\":\"Charlie\",\"email\":\"charlie@geeks.com\",\"age\":30,\"premium\":true}"
        "]";

    zigpug_set_array_json(ctx, "users", users_json);
    zigpug_array_free(users);

    const char* template5 =
        "div.users-list\n"
        "  h2 Usuarios Geeks Registrados\n"
        "  each user in users\n"
        "    div.user\n"
        "      h3= user.name\n"
        "      p.email Email: #{user.email}\n"
        "      p.age Edad: #{user.age}\n"
        "      if user.premium\n"
        "        span.badge ⭐ Premium\n"
        "      else\n"
        "        span.badge 🆓 Free";

    char* html5 = zigpug_compile(ctx, template5);
    if (html5) {
        printf("HTML Output:\n%s\n\n", html5);
        zigpug_free_string(html5);
    }

    // ========================================================================
    // Summary
    // ========================================================================
    printf("═══════════════════════════════════════════════════════════\n");
    printf("✅ Builder API Demo completado!\n");
    printf("\n");
    printf("📚 Lo que aprendiste:\n");
    printf("  1. JSON API → Para datos simples/estáticos\n");
    printf("  2. Builder API → Para construcción dinámica\n");
    printf("  3. Arrays dinámicos → zigpug_array_create/add/set\n");
    printf("  4. Objetos dinámicos → zigpug_object_create/set\n");
    printf("  5. Tipos mixtos → strings, ints, doubles, bools, null\n");
    printf("\n");
    printf("💡 Tip: Combina ambos enfoques según tu necesidad!\n");
    printf("═══════════════════════════════════════════════════════════\n");

    // Cleanup
    zigpug_free(ctx);

    printf("\n🎓 Ahora vuelve al anime... o mejor sigue programando! 😉\n");

    return 0;
}
