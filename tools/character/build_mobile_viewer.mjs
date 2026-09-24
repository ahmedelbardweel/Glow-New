import { build } from 'esbuild';
import { copyFile } from 'node:fs/promises';
await build({
  entryPoints: [new URL('./mobile_viewer.mjs', import.meta.url).pathname.replace(/^\/(\w:)/, '$1')],
  bundle: true, minify: true, format: 'iife', target: ['safari16', 'chrome110'],
  outfile: new URL('../../assets/3d/character_mobile.js', import.meta.url).pathname.replace(/^\/(\w:)/, '$1'),
  legalComments: 'eof',
});
await copyFile(new URL('./node_modules/three/LICENSE', import.meta.url), new URL('../../assets/3d/three-LICENSE.txt', import.meta.url));
