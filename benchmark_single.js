// benchmark_single.js — un solo render completo
// hyperfine lo llama N veces desde afuera
//const pug  = require("pug");
const pug = require("./nodejs/index.js");
const path = require("path");

const context = {
    pageTitle:  "Tienda Online",
    siteName:   "ZigShop",
    year:       2025,
    user:       "Carlos",
    navLinks: [
        { href: "/",        label: "Inicio"   },
        { href: "/shop",    label: "Tienda"   },
        { href: "/blog",    label: "Blog"     },
        { href: "/contact", label: "Contacto" },
    ],
    stats: [
        { value: "1,240", label: "Clientes"     },
        { value: "98%",   label: "Satisfaccion" },
        { value: "3,500", label: "Productos"    },
        { value: "24/7",  label: "Soporte"      },
    ],
    productsTitle: "Productos destacados",
    products: Array.from({ length: 20 }, (_, i) => ({
        name:         `Producto ${i + 1}`,
        description:  `Descripcion del producto ${i + 1}.`,
        price:        ((i + 1) * 49.99).toFixed(2),
        stock:        ["in_stock", "low_stock", "out_of_stock"][i % 3],
        discontinued: i % 10 === 0,
    })),
    blogPosts: Array.from({ length: 6 }, (_, i) => ({
        title:   `Entrada ${i + 1}`,
        excerpt: `Resumen de la entrada ${i + 1}.`,
        url:     `/blog/post-${i + 1}`,
        tags:    [`tag${i + 1}`, "blog"],
        open:    i === 0,
    })),
    faq: Array.from({ length: 8 }, (_, i) => ({
        question: `Pregunta ${i + 1}?`,
        answer:   `Respuesta ${i + 1}.`,
        open:     i === 0,
    }))

};

// Proceso completo: compilar template + render
const fn   = pug.compileFile(path.join(__dirname, "benchmark.pug"),context);
process.stdout.write(fn);

//const fn = pug.compileFile(path.join(__dirname,"benchmark.pug"));
//process.stdout.write(fn(context));

