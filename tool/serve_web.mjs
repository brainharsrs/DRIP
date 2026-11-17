// Servidor estático mínimo para pré-visualizar o build web do DRIP.
//
// Uso (depois de `flutter build web`):
//     node tool/serve_web.mjs            → http://localhost:8090
//     node tool/serve_web.mjs 9000       → outra porta
//
// Não tem dependências. Serve `build/web` e devolve `index.html` para rotas
// do app (ex.: /discover), como um servidor de produção faria.

import { createServer } from 'node:http';
import { readFile, stat } from 'node:fs/promises';
import { extname, join, normalize, resolve, sep } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = resolve(fileURLToPath(new URL('../build/web', import.meta.url)));
const port = Number(process.argv[2] ?? process.env.PORT ?? 8090);

const types = {
  '.html': 'text/html; charset=utf-8',
  '.js': 'text/javascript; charset=utf-8',
  '.mjs': 'text/javascript; charset=utf-8',
  '.json': 'application/json; charset=utf-8',
  '.css': 'text/css; charset=utf-8',
  '.wasm': 'application/wasm',
  '.png': 'image/png',
  '.jpg': 'image/jpeg',
  '.svg': 'image/svg+xml',
  '.ico': 'image/x-icon',
  '.ttf': 'font/ttf',
  '.otf': 'font/otf',
  '.woff2': 'font/woff2',
  '.bin': 'application/octet-stream',
  '.symbols': 'text/plain; charset=utf-8',
};

async function resolveFile(urlPath) {
  const clean = normalize(decodeURIComponent(urlPath.split('?')[0]));
  const candidate = join(root, clean);
  // Nunca sai da pasta do build.
  if (candidate !== root && !candidate.startsWith(root + sep)) return null;
  try {
    const info = await stat(candidate);
    if (info.isFile()) return candidate;
  } catch {
    // cai no index.html abaixo
  }
  return extname(clean) ? null : join(root, 'index.html');
}

createServer(async (req, res) => {
  const file = await resolveFile(req.url ?? '/');
  if (!file) {
    res.writeHead(404).end('Não encontrado');
    return;
  }
  try {
    const body = await readFile(file);
    res.writeHead(200, {
      'Content-Type': types[extname(file)] ?? 'application/octet-stream',
      // Sem cache: cada novo build aparece na hora.
      'Cache-Control': 'no-store',
    });
    res.end(body);
  } catch {
    res.writeHead(500).end('Erro ao ler o arquivo');
  }
}).listen(port, () => {
  console.log(`DRIP web em http://localhost:${port} (servindo ${root})`);
});
