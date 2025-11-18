// 04-bun-server.js - HTTP Server con Bun.serve() y zig-pug
// Ejecutar: bun run 04-bun-server.js
// Luego visita: http://localhost:3000

const zigpug = require('../../nodejs');

let requestCount = 0;

// Template para la página principal
const homeTemplate = `
doctype html
html(lang="es")
  head
    meta(charset="utf-8")
    title #{title}
    style.
      body { font-family: system-ui; max-width: 800px; margin: 40px auto; padding: 20px; }
      .header { background: #f0f0f0; padding: 20px; border-radius: 8px; }
      .stats { margin: 20px 0; }
      .badge { display: inline-block; background: #0070f3; color: white; padding: 4px 12px; border-radius: 4px; margin-right: 8px; }
      pre { background: #f5f5f5; padding: 16px; border-radius: 4px; overflow-x: auto; }
  body
    div.header
      h1 #{title}
      p ⚡ Powered by Bun.js #{bunVersion}

    div.stats
      h2 Estadísticas
      p
        span.badge Requests: #{requests}
      p
        span.badge Runtime: Bun.js
      p
        span.badge Template Engine: zig-pug

    div.demo
      h2 Demo
      p Este servidor usa zig-pug para compilar templates en tiempo real.
      p Cada vez que recargas la página, el contador aumenta.

    div.endpoints
      h2 Endpoints Disponibles
      ul
        li
          a(href="/") Home
        li
          a(href="/about") About
        li
          a(href="/user/alice") User Profile (Alice)
        li
          a(href="/user/bob") User Profile (Bob)
        li
          a(href="/api/stats") API Stats (JSON)
`;

// Template para About
const aboutTemplate = `
doctype html
html(lang="es")
  head
    meta(charset="utf-8")
    title About - zig-pug + Bun
    style.
      body { font-family: system-ui; max-width: 800px; margin: 40px auto; padding: 20px; }
  body
    h1 About zig-pug
    p Motor de templates inspirado en Pug, implementado en Zig.
    p
      a(href="/") ← Volver al inicio
`;

// Template para User Profile
const userTemplate = `
doctype html
html(lang="es")
  head
    meta(charset="utf-8")
    title #{username} - User Profile
    style.
      body { font-family: system-ui; max-width: 800px; margin: 40px auto; padding: 20px; }
      .profile { background: #f0f0f0; padding: 20px; border-radius: 8px; margin: 20px 0; }
  body
    h1 User Profile
    div.profile
      h2 #{username}
      p ID: #{userId}
      p Member since: 2024
    p
      a(href="/") ← Volver al inicio
`;

const server = Bun.serve({
    port: 3000,
    fetch(req) {
        requestCount++;
        const url = new URL(req.url);

        // Route: Home
        if (url.pathname === '/') {
            const html = zigpug.compile(homeTemplate, {
                title: 'Bun + zig-pug Server',
                requests: requestCount,
                bunVersion: Bun.version
            });
            return new Response(html, {
                headers: { 'Content-Type': 'text/html; charset=utf-8' }
            });
        }

        // Route: About
        if (url.pathname === '/about') {
            const html = zigpug.compile(aboutTemplate, {});
            return new Response(html, {
                headers: { 'Content-Type': 'text/html; charset=utf-8' }
            });
        }

        // Route: User Profile
        if (url.pathname.startsWith('/user/')) {
            const username = url.pathname.split('/')[2];
            const html = zigpug.compile(userTemplate, {
                username: username,
                userId: Math.floor(Math.random() * 10000)
            });
            return new Response(html, {
                headers: { 'Content-Type': 'text/html; charset=utf-8' }
            });
        }

        // Route: API Stats (JSON)
        if (url.pathname === '/api/stats') {
            return Response.json({
                runtime: 'Bun.js',
                version: Bun.version,
                templateEngine: 'zig-pug',
                requests: requestCount,
                uptime: process.uptime()
            });
        }

        // 404
        return new Response('Not Found', { status: 404 });
    },
});

console.log('');
console.log('🚀 Servidor corriendo en http://localhost:3000');
console.log('');
console.log('Endpoints disponibles:');
console.log('  - http://localhost:3000/');
console.log('  - http://localhost:3000/about');
console.log('  - http://localhost:3000/user/alice');
console.log('  - http://localhost:3000/api/stats');
console.log('');
console.log('Presiona Ctrl+C para detener el servidor');
console.log('');
