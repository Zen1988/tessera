import { readFile, readdir } from 'node:fs/promises';
import { resolve } from 'node:path';
import { transformAsync } from '@babel/core';
import { defineConfig } from 'vite';

const source = resolve('src');
const sourceAliases = (await readdir(source, { withFileTypes: true }))
  .filter((entry) => entry.isDirectory() || /\.jsx?$/.test(entry.name))
  .map((entry) => ({
    find: entry.isDirectory()
      ? new RegExp(`^${entry.name}(?=/|$)`)
      : entry.name.replace(/\.jsx?$/, ''),
    replacement: `${source}/${entry.name}`,
  }));

export default defineConfig({
  base: '/static/',
  publicDir: false,
  resolve: { alias: sourceAliases },
  plugins: [{
    name: 'tao-awx-source',
    enforce: 'pre',
    async transform(code, id) {
      if (!id.startsWith(`${source}/`) || !/\.jsx?$/.test(id)) return null;
      if (id === `${source}/setupCSP.js`) {
        // Vite does not provide webpack's nonce variable. Keep CSP reporting.
        code = code.replace(/^__webpack_nonce__ = window\.NONCE_ID;$/m, '');
      }
      if (id === `${source}/i18nLoader.js`) {
        // Vite needs the generated catalog extension to enumerate imports.
        code = code.replace('./locales/${locale}/messages`', './locales/${locale}/messages.js`');
      }
      const result = await transformAsync(code, {
        filename: id,
        babelrc: false,
        configFile: false,
        plugins: ['babel-plugin-macros', 'babel-plugin-styled-components'],
        presets: [['@babel/preset-react', { runtime: 'classic' }]],
        sourceMaps: true,
      });
      return { code: result.code, map: result.map };
    },
    async buildStart() {
      const template = await readFile('public/index.html', 'utf8');
      if (!template.includes('{{ csp_nonce }}')) {
        this.error('AWX Django CSP template missing');
      }
    },
  }],
  build: {
    outDir: 'build/static',
    emptyOutDir: true,
    manifest: true,
    modulePreload: false,
    cssCodeSplit: false,
    rollupOptions: { input: resolve('src/index.js') },
  },
});
