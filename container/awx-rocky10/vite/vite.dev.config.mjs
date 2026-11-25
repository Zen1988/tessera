import { mergeConfig, defineConfig } from 'vite';
import production from './vite.config.mjs';

const target = new URL(process.env.TARGET || 'https://localhost:8043');
if (!['http:', 'https:'].includes(target.protocol) || target.username || target.password) {
  throw new Error('TARGET must be an AWX HTTP(S) URL without credentials');
}

export default defineConfig(mergeConfig(production, {
  base: '/',
  appType: 'custom',
  publicDir: 'public',
  server: {
    host: '127.0.0.1',
    port: 3001,
    strictPort: true,
    proxy: Object.fromEntries(
      ['/api', '/websocket', '/sso', '/csp-violation/'].map((path) => [
        path, { target: target.origin, ws: path === '/websocket' },
      ]),
    ),
  },
  plugins: [{
    name: 'tao-dev-entry',
    configureServer(server) {
      return () => {
        server.middlewares.use(async (request, response, next) => {
          if (request.method !== 'GET' || !request.headers.accept?.includes('text/html')) {
            return next();
          }
          try {
            const html = await server.transformIndexHtml(request.url, `
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>TESSERA Automation Orchestrator</title>
  <link rel="icon" href="/static/media/favicon.ico">
</head>
<body><div id="app" style="height:100%"></div>
<script type="module" src="/src/index.js"></script></body>
</html>`);
            response.setHeader('Content-Type', 'text/html; charset=utf-8');
            response.end(html);
          } catch (error) {
            next(error);
          }
        });
      };
    },
  }],
}));
