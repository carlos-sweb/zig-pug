import { PugCompiler } from 'zig-pug';

const compiler = new PugCompiler();
compiler
    .set('title', 'My Page')
    .set('version', 1.5)
    .setBool('isDev', false);

const html = compiler.compile('h1 #{title}');
console.log(html);
