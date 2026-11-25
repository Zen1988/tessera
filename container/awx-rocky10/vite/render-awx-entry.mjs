import { constants } from 'node:fs';
import { copyFile, mkdir, readFile, readdir, writeFile } from 'node:fs/promises';
import { dirname, join } from 'node:path';

const manifest = JSON.parse(await readFile('build/static/.vite/manifest.json', 'utf8'));
const entry = manifest['src/index.js'];
if (!entry?.isEntry) throw new Error('Vite manifest has no AWX entry');

const upstream = await readFile('public/index.html', 'utf8');
let html = upstream.replace(
  /<% if \(process\.env\.NODE_ENV === 'production'\) \{ %>([\s\S]*?)<% } %>/g,
  (_, branches) => branches.split('<% } else { %>')[0],
);
if (html.includes('<%') || !html.includes('{% load static %}') ||
    !html.includes('id="app"') || !html.includes('{{ csp_nonce }}')) {
  throw new Error('Unexpected AWX entry template');
}
const staticUrl = (file) => {
  if (!/^[\w./-]+$/.test(file) || file.includes('..')) {
    throw new Error(`Invalid asset path: ${file}`);
  }
  return `{% static '${file}' %}`;
};
const css = [...new Set(Object.values(manifest).flatMap((asset) =>
  asset.css ?? (asset.file.endsWith('.css') ? [asset.file] : [])))];
html = html.replace('</head>', `${css.map((file) =>
  `<link rel="stylesheet" href="${staticUrl(file)}" />`).join('\n')}
<script type="module" nonce="{{ csp_nonce }}" src="${staticUrl(entry.file)}"></script>
</head>`);
for (const file of await readdir('public/static', { recursive: true, withFileTypes: true })) {
  if (file.isDirectory()) continue;
  if (!file.isFile()) throw new Error(`Unexpected public asset: ${file.name}`);
  const source = join(file.parentPath, file.name);
  const target = join('build', source.slice('public/'.length));
  await mkdir(dirname(target), { recursive: true });
  await copyFile(source, target, constants.COPYFILE_EXCL);
}
await writeFile('build/index.html', html);
